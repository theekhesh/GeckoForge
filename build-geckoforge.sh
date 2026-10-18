#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# GeckoForge — Privacy-hardened, branded Firefox build
# Builds in /tmp (uses your 39G free disk, not /workspaces)
# ============================================================

WORK_DIR="/tmp/GeckoForge"
SCCACHE_DIR="/tmp/sccache"
LOGO_DIR="$WORK_DIR/logos"
BRANDING_NAME="geckoforge"

# ---- helpers ----
info() { printf "\033[1;36m[GeckoForge]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m  ✓\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m  !\033[0m %s\n" "$*"; }
die()  { printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2; exit 1; }

# ------------------------------------------------------------
# Stage 0 — Preflight: disk check
# ------------------------------------------------------------
AVAIL_GB=$(df -BG /tmp | awk 'NR==2 {print $4}' | tr -d 'G')
info "Free space on /tmp: ${AVAIL_GB}G"
if [ "${AVAIL_GB:-0}" -lt 30 ]; then
    warn "/tmp needs 30G+ for a full Firefox build (Mozilla's recommendation)."
    warn "Free space with:  sudo rm -rf /workspaces/GeckoForge"
    die "Insufficient disk."
fi

# ------------------------------------------------------------
# Stage 1 — System dependencies
# ------------------------------------------------------------
info "Installing system dependencies"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    curl python3 python3-venv git make \
    libnotify-bin librsvg2-bin imagemagick

# Pick correct ImageMagick command (v6 → convert, v7 → magick)
if command -v magick >/dev/null 2>&1; then IM=magick; else IM=convert; fi
ok "Using ImageMagick: $IM"

# ------------------------------------------------------------
# Stage 2 — Bootstrap Firefox source
# ------------------------------------------------------------
mkdir -p "$WORK_DIR" "$SCCACHE_DIR" "$LOGO_DIR"
cd "$WORK_DIR"

if [ -d "$WORK_DIR/geckoforge/.git" ]; then
    info "Reusing existing source at $WORK_DIR/geckoforge"
    SRC_DIR="$WORK_DIR/geckoforge"
elif [ -d "$WORK_DIR/firefox/.git" ]; then
    info "Reusing existing source at $WORK_DIR/firefox"
    SRC_DIR="$WORK_DIR/firefox"
else
    info "Bootstrapping Firefox source (you may be prompted — see notes)"
    curl -fsSL -o bootstrap.py \
        https://raw.githubusercontent.com/mozilla-firefox/firefox/refs/heads/main/python/mozboot/bin/bootstrap.py

    # --no-interactive skips most prompts; answer any remaining as:
    #   application choice → 2 (Firefox for Desktop)
    #   sccache            → y
    #   build telemetry    → n
    python3 bootstrap.py --no-interactive --application-choice=browser

    # Discover source directory (bootstrap names it after the repo)
    if [ -d "$WORK_DIR/geckoforge" ]; then
        SRC_DIR="$WORK_DIR/geckoforge"
    elif [ -d "$WORK_DIR/firefox" ]; then
        SRC_DIR="$WORK_DIR/firefox"
    else
        SRC_DIR=$(find "$WORK_DIR" -maxdepth 1 -type d -name "mozilla-unified" | head -1 || true)
    fi
    [ -z "${SRC_DIR:-}" ] && die "Could not find source dir after bootstrap."
fi
ok "Source: $SRC_DIR"
cd "$SRC_DIR"

# ------------------------------------------------------------
# Stage 3 — Generate GeckoForge logos
# ------------------------------------------------------------
info "Generating GeckoForge logo set"

# --- Variant 2 "Quick" (used for 16–48px: tongue survives downscaling)
cat > "$LOGO_DIR/logo-small.svg" << 'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="ember2" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%"   stop-color="#FFC46B"/>
      <stop offset="50%"  stop-color="#FF7A1A"/>
      <stop offset="100%" stop-color="#E23A00"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.82" cy="0.22" r="0.55">
      <stop offset="0%"   stop-color="#FF7A1A" stop-opacity="0.30"/>
      <stop offset="100%" stop-color="#151221" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="128" height="128" rx="30" fill="#151221"/>
  <rect width="128" height="128" rx="30" fill="url(#glow)"/>
  <path d="M90 45 A 32 32 0 1 0 90 83 L 90 64 L 64 64"
        stroke="url(#ember2)" stroke-width="13" fill="none"
        stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M96 21 C 101 17, 106 14, 111 12
           M111 12 L 116 10
           M111 12 L 115 16"
        stroke="#E23A00" stroke-width="1.8" fill="none" stroke-linecap="round"/>
  <path d="M92 46 C 97 37, 101 31, 98 22 C 95 15, 86 16, 85 24 C 84 31, 87 39, 92 46 Z"
        fill="url(#ember2)"/>
  <circle cx="91"   cy="30"   r="2.3" fill="#151221"/>
  <circle cx="91.6" cy="29.4" r="0.8" fill="#FFC46B"/>
</svg>
SVG

# --- Variant 3 "Instinct" (used for 64px+: scale texture + rim light)
cat > "$LOGO_DIR/logo-large.svg" << 'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="ember2" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%"   stop-color="#FFC46B"/>
      <stop offset="50%"  stop-color="#FF7A1A"/>
      <stop offset="100%" stop-color="#E23A00"/>
    </linearGradient>
    <linearGradient id="headLight" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#FFE2A8"/>
      <stop offset="60%"  stop-color="#FFC46B" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.82" cy="0.22" r="0.55">
      <stop offset="0%"   stop-color="#FF7A1A" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#151221" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="128" height="128" rx="30" fill="#151221"/>
  <rect width="128" height="128" rx="30" fill="url(#glow)"/>
  <path d="M90 45 A 32 32 0 1 0 90 83 L 90 64 L 64 64"
        stroke="url(#ember2)" stroke-width="13" fill="none"
        stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M85 49 A 26 26 0 1 0 85 79"
        stroke="#E23A00" stroke-width="1.1" fill="none"
        stroke-dasharray="1.5 4" opacity="0.55"/>
  <path d="M96 21 C 101 17, 106 14, 111 12
           M111 12 L 116 10
           M111 12 L 115 16"
        stroke="#E23A00" stroke-width="1.8" fill="none" stroke-linecap="round"/>
  <path d="M92 46 C 97 37, 101 31, 98 22 C 95 15, 86 16, 85 24 C 84 31, 87 39, 92 46 Z"
        fill="url(#ember2)"/>
  <path d="M98 22 C 95 15, 86 16, 85 24"
        stroke="url(#headLight)" stroke-width="1.5" fill="none" stroke-linecap="round"/>
  <circle cx="91"   cy="30"   r="2.3" fill="#151221"/>
  <circle cx="91.6" cy="29.4" r="0.8" fill="#FFC46B"/>
</svg>
SVG

# Keep a copy for the desktop launcher & repo
cp "$LOGO_DIR/logo-large.svg" "$WORK_DIR/geckoforge-logo.svg"

# Rasterise: small sizes from Variant 2, large from Variant 3
mkdir -p "$LOGO_DIR/png"
for size in 16 22 24 32 48; do
    rsvg-convert -w "$size" -h "$size" "$LOGO_DIR/logo-small.svg" \
        -o "$LOGO_DIR/png/default${size}.png"
done
for size in 64 128 256 512 1024; do
    rsvg-convert -w "$size" -h "$size" "$LOGO_DIR/logo-large.svg" \
        -o "$LOGO_DIR/png/default${size}.png"
done
rsvg-convert -w 256 -h 256 "$LOGO_DIR/logo-large.svg" -o "$LOGO_DIR/png/firefox.png"
rsvg-convert -w 64  -h 64  "$LOGO_DIR/logo-large.svg" -o "$LOGO_DIR/png/firefox64.png"
rsvg-convert -w 192 -h 192 "$LOGO_DIR/logo-large.svg" -o "$LOGO_DIR/png/about-logo.png"
rsvg-convert -w 320 -h 64  "$LOGO_DIR/logo-large.svg" -o "$LOGO_DIR/png/about-wordmark.png"
"$IM" "$LOGO_DIR/png/default16.png" "$LOGO_DIR/png/default32.png" \
      "$LOGO_DIR/png/default48.png" "$LOGO_DIR/favicon.ico"
ok "Generated $(ls "$LOGO_DIR/png" | wc -l) PNGs + favicon.ico"

# ------------------------------------------------------------
# Stage 4 — Create branding directory & wire in icons
# ------------------------------------------------------------
info "Creating custom branding: browser/branding/$BRANDING_NAME"
BRANDING_DST="browser/branding/$BRANDING_NAME"
[ -d "$BRANDING_DST" ] || cp -r browser/branding/unofficial "$BRANDING_DST"

cp "$LOGO_DIR"/png/default*.png "$BRANDING_DST/content/"
cp "$LOGO_DIR/png/firefox.png"   "$BRANDING_DST/content/firefox.png"
cp "$LOGO_DIR/png/firefox64.png" "$BRANDING_DST/content/firefox64.png"
[ -f "$BRANDING_DST/content/about-logo.png" ] && \
    cp "$LOGO_DIR/png/about-logo.png" "$BRANDING_DST/content/about-logo.png"
[ -f "$BRANDING_DST/content/about-wordmark.png" ] && \
    cp "$LOGO_DIR/png/about-wordmark.png" "$BRANDING_DST/content/about-wordmark.png"
cp "$LOGO_DIR/logo-large.svg"    "$BRANDING_DST/logo.svg"
ok "Icons installed into $BRANDING_DST/content/"

# ------------------------------------------------------------
# Stage 5 — Rebrand configure.sh (safe set-or-append)
# ------------------------------------------------------------
info "Updating branding strings in configure.sh"
CONFIG_FILE="$BRANDING_DST/configure.sh"
NEW_APP_ID=$(python3 -c "import uuid; print('{'+str(uuid.uuid4()).upper()+'}')")

set_or_append() {
    local file="$1" key="$2" val="$3"
    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$file"
    else
        echo "${key}=${val}" >> "$file"
    fi
}
set_or_append "$CONFIG_FILE" MOZ_APP_DISPLAYNAME  GeckoForge
set_or_append "$CONFIG_FILE" MOZ_APP_NAME         geckoforge
set_or_append "$CONFIG_FILE" MOZ_APP_VERSION      1.0
set_or_append "$CONFIG_FILE" MOZ_APP_ID           "$NEW_APP_ID"
set_or_append "$CONFIG_FILE" MOZ_APP_UA_NAME      GeckoForge
set_or_append "$CONFIG_FILE" MOZ_UA_BRAND_NAME    GeckoForge
ok "App ID: $NEW_APP_ID"

# ------------------------------------------------------------
# Stage 6 — Write mozconfig
# ------------------------------------------------------------
info "Writing mozconfig"
cat > mozconfig << EOF
# ===== GeckoForge build configuration =====
ac_add_options --enable-application=browser
ac_add_options --disable-artifact-builds

# --- Branding ---
ac_add_options --with-branding=browser/branding/$BRANDING_NAME

# --- Privacy (compile-time) ---
# Telemetry is disabled by NOT defining MOZ_TELEMETRY_REPORTING,
# MOZ_SERVICES_HEALTHREPORT, or MOZ_CRASHREPORTER. When none are defined,
# MOZ_DATA_REPORTING is false and the reporting code paths are stripped.
ac_add_options --disable-crashreporter
ac_add_options --disable-default-browser-agent
ac_add_options --disable-updater
ac_add_options --enable-hardening

# --- Speed ---
ac_add_options --enable-optimize
ac_add_options --enable-release
ac_add_options --enable-rust-simd

# --- Extensions ---
ac_add_options --allow-addon-sideload
ac_add_options --with-unsigned-addon-scopes=app,system

# --- Build cache ---
ac_add_options --with-ccache=sccache
EOF
ok "mozconfig written"

# ------------------------------------------------------------
# Stage 7 — Build
# ------------------------------------------------------------
info "Building Firefox (45 min – 3 h depending on machine)"
export SCCACHE_DIR
./mach build
ok "Build complete"

# ------------------------------------------------------------
# Stage 8 — Profile + privacy hardening
# ------------------------------------------------------------
info "Setting up profile & applying Betterfox"
PROFILE_DIR="$WORK_DIR/profile"
mkdir -p "$PROFILE_DIR/chrome"

# Betterfox user.js (applied on every startup — survives updates)
curl -fsSL -o "$PROFILE_DIR/user.js" \
    https://raw.githubusercontent.com/yokoffing/Betterfox/main/user.js

# Custom new-tab logo (CSS-only, survives better than xulstore tweaks)
cat > "$PROFILE_DIR/chrome/userContent.css" << EOF
@-moz-document url("about:home"), url("about:newtab") {
  .logo-and-wordmark .logo {
    background-image: url("file://$LOGO_DIR/logo-large.svg") !important;
    background-size: contain !important;
    background-repeat: no-repeat !important;
  }
}
EOF
ok "Betterfox + new-tab logo applied to $PROFILE_DIR"

# ------------------------------------------------------------
# Stage 9 — Desktop launcher (portable if copied off Codespaces)
# ------------------------------------------------------------
info "Installing desktop launcher"
OBJ_DIR=$(find "$SRC_DIR" -maxdepth 1 -type d -name "obj-*" | head -1)
FIREFOX_BIN="$OBJ_DIR/dist/bin/firefox"

APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$APPS" "$ICONS"
cp "$LOGO_DIR/png/default256.png" "$ICONS/geckoforge.png"

cat > "$APPS/geckoforge.desktop" << EOF
[Desktop Entry]
Name=GeckoForge
Comment=Privacy-hardened Firefox build
Exec=$FIREFOX_BIN --profile "$PROFILE_DIR" %u
Icon=geckoforge
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF
ok "Launcher at $APPS/geckoforge.desktop"

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------
echo
echo "════════════════════════════════════════════════════════════"
echo "  GeckoForge build complete"
echo "════════════════════════════════════════════════════════════"
echo "  Source:     $SRC_DIR"
echo "  Binary:     $FIREFOX_BIN"
echo "  Profile:    $PROFILE_DIR"
echo "  Logos:      $LOGO_DIR"
echo "  Branding:   $SRC_DIR/$BRANDING_DST"
echo
echo "  Run headless:  $FIREFOX_BIN --headless --profile \"$PROFILE_DIR\""
echo "  Run with GUI:  $FIREFOX_BIN --profile \"$PROFILE_DIR\""
echo "                 (needs Xvfb + VNC set up — see earlier notes)"
echo
echo "  ⚠  /tmp is wiped on Codespace restart. Push branding changes:"
echo "       cd $SRC_DIR && git add browser/branding/$BRANDING_NAME"
echo "                    git commit -m 'Add GeckoForge branding'"
echo "                    git push"
echo "════════════════════════════════════════════════════════════"
