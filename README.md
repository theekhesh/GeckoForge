# 🦎 GeckoForge

A privacy-focused, performance-tuned Firefox build — forged from source.

GeckoForge is a custom-compiled build of Mozilla Firefox, assembled from the
official Firefox source tree and hardened for privacy, speed, and stability.
It exists for people who want a browser they can fully trust: one built on
their own machine, from auditable source, with no vendor telemetry baked in.

## Why GeckoForge?

Modern browsers ship with telemetry, crash reporters, update checkers, and
data-collection services enabled by default. Even "private" forks often
inherit these components or rely on pre-built binaries. GeckoForge takes a
different path — it starts from the upstream source and removes or disables
these components *before* compilation, so the resulting binary simply does
not contain the code paths that would phone home.

## Design Pillars

| Pillar        | How GeckoForge delivers it |
|---------------|----------------------------|
| 🔒 **Privacy**   | Telemetry, crash reporting, and the updater are disabled at compile time. Betterfox `user.js` applies runtime hardening (tracking protection, HTTPS-by-default, cookie isolation, fingerprint resistance) on top. |
| ⚡ **Speed**     | Release-optimized build (`--enable-release`, `--enable-optimize`, Rust SIMD). `sccache` cuts rebuild time dramatically. |
| ⚖️ **Stability** | Built from unmodified upstream Firefox source. Hardening uses Betterfox's "minimum effective dose" philosophy to avoid site breakage. |
| 🎨 **UI**        | Ships with a clean profile pre-configured for `userChrome.css` / `userContent.css` theming — drop in any Firefox theme (MauveWolf, MaterialFox, etc.) to make it yours. |

## What Makes It Different

- **Compiled from source**, not repackaged from a vendor binary.
- **No telemetry code paths** — removed at build time, not just disabled.
- **Reproducible in GitHub Codespaces** — no local toolchain required.
- **Upstream-first** — no fork drift; you build the real Firefox engine.
- **Fully yours** — every preference and theme is under your control.

## Building

GeckoForge builds in a Codespace using the `build-geckoforge.sh` script,
which clones the Firefox source into `/tmp`, writes a hardened `mozconfig`,
compiles the browser, and installs the Betterfox profile automatically.

> ⚠️ A full build requires **8 GB+ RAM**, **20 GB+ free disk**, and
> **45 minutes to several hours** depending on machine size. Build artifacts
> in `/tmp` are not persistent across Codespace restarts — push your
> changes to GitHub to preserve them.

## Status

GeckoForge is a personal, source-built browser. It is not a fork, not a
distribution, and not affiliated with Mozilla. It is Firefox — rebuilt
with intent.

## License

Firefox source code is licensed under the [Mozilla Public License 2.0](https://www.mozilla.org/MPL/2.0/).
GeckoForge's build scripts and configuration are released under the same terms.
