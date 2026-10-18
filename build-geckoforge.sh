#!/usr/bin/env bash
set -e

# ============================================
# 1. SETUP: Use /tmp for space & stability
# ============================================
export WORK_DIR="/tmp/GeckoForge"
export SRC_DIR="$WORK_DIR/geckoforge"
export SCCACHE_DIR="/tmp/sccache"
mkdir -p "$WORK_DIR" "$SCCACHE_DIR"

echo "--- [1/6] Installing system dependencies ---"
sudo apt update && sudo apt install -y curl python3 python3-venv git make libnotify-bin

echo "--- [2/6] Bootstrapping Firefox source ---"
cd "$WORK_DIR"
# Official method: download bootstrap.py separately, then run it.
curl -L -o bootstrap.py https://raw.githubusercontent.com/mozilla-firefox/firefox/refs/heads/main/python/mozboot/bin/bootstrap.py
python3 bootstrap.py --no-interactive
# This will clone the source into $WORK_DIR/geckoforge (or a similarly named directory).
# If the directory name differs, adjust SRC_DIR accordingly.
if [ ! -d "$SRC_DIR" ]; then
    # Bootstrap may have created a directory named 'mozilla-unified' or 'firefox'
    SRC_DIR=$(find "$WORK_DIR" -maxdepth 1 -type d -name "firefox*" -o -name "mozilla-unified" | head -1)
    if [ -z "$SRC_DIR" ]; then
        echo "Error: Source directory not found after bootstrap."
        exit 1
    fi
fi
cd "$SRC_DIR"

# ============================================
# 2. PRE-BUILD ADJUSTMENTS (mozconfig)
# ============================================
echo "--- [3/6] Writing custom mozconfig ---"
cat > mozconfig << 'EOF'
# Build Firefox for Desktop (Full build)
ac_add_options --enable-application=browser
ac_add_options --disable-artifact-builds

# --- PRIVACY & STABILITY ---
# Disable telemetry and data reporting at compile time.
# Per Mozilla docs, telemetry is disabled when MOZ_TELEMETRY_REPORTING is NOT defined.
# We simply omit it. Also disable crash reporter and updater.
ac_add_options --disable-crashreporter
ac_add_options --disable-default-browser-agent
ac_add_options --disable-updater
ac_add_options --enable-hardening
# Explicitly unset data reporting defines (optional, but clear).
ac_add_options MOZ_DATA_REPORTING=
ac_add_options MOZ_SERVICES_HEALTHREPORT=
# Note: MOZ_TELEMETRY_REPORTING is intentionally left undefined.

# --- SPEED & PERFORMANCE ---
ac_add_options --enable-optimize
ac_add_options --disable-debug
ac_add_options --enable-release
ac_add_options --enable-rust-simd
# PGO is optional; omit for reliability in headless Codespaces.
# ac_add_options MOZ_PGO=1

# --- UI & UX ---
ac_add_options --allow-addon-sideload
ac_add_options --with-unsigned-addon-scopes=app,system

# --- SCCACHE ---
ac_add_options --with-ccache=sccache
EOF

# ============================================
# 3. BUILD
# ============================================
echo "--- [4/6] Building Firefox (This will take a long time) ---"
export SCCACHE_DIR="$SCCACHE_DIR"
./mach build

# ============================================
# 4. POST-BUILD: HARDENING & UI
# ============================================
echo "--- [5/6] Applying Betterfox Privacy Hardening ---"
# Create a temporary profile explicitly to avoid fragile find commands.
TEMP_PROFILE="$WORK_DIR/temp-profile"
mkdir -p "$TEMP_PROFILE"
# Run headless once to initialize the profile. Pass arguments after '--'.
./mach run -- --headless --profile "$TEMP_PROFILE" &
BROWSER_PID=$!
sleep 15
kill $BROWSER_PID 2>/dev/null || true

# Use the temporary profile directly (or copy to the default location if desired).
PROFILE_DIR="$TEMP_PROFILE"
if [ -d "$PROFILE_DIR" ]; then
    echo "Profile initialized at: $PROFILE_DIR"
    curl -L -o "$PROFILE_DIR/user.js" https://raw.githubusercontent.com/yokoffing/Betterfox/main/user.js
    echo "Betterfox user.js installed."
    mkdir -p "$PROFILE_DIR/chrome"
fi

echo "--- [6/6] UI Theme Setup (Optional) ---"
# Uncomment and set URLs to your preferred theme.
# curl -L -o "$PROFILE_DIR/chrome/userChrome.css" <URL>
# curl -L -o "$PROFILE_DIR/chrome/userContent.css" <URL>

echo "=========================================="
echo "Build Complete! To run your browser:"
echo "cd $SRC_DIR && ./mach run"
echo "Your profile is at: $PROFILE_DIR"
echo "=========================================="
