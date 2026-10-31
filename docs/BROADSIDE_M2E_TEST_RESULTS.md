# M2-E validation — 0.2.4-m2e

Dependent on PR #11 (`feature/broadside-m2d-fleet`, a42b1da); no merge performed. Implementation is split into E1 shipyard/repairs and E2 tactics/music/camera commits. Issue #12 is the design reference.

## Implemented

- One permanent checkout, no opaque modal/reparenting/native upgrade tooltips. Price and Confirm/Cancel remain outside the scrolling description. Plain names, short explanations, optional numerical details. Existing transaction revalidation and per-vessel save format unchanged.
- Pinned active-ship HP/missing HP/repair quote directly beneath header. Repair is recommended/focused on arrival damaged, but neither opening harbor nor inspecting a quote spends gold. Keep Damage goes to chart. Inactive fleet inspection cannot redirect the primary repair.
- 0.65 battle zoom; physical-pixel responsive harbor and compact two-column main menu; chart layout fits smaller windows with scrolling when necessary. HUD and ocean still occupy separate viewports.
- Raiders flank/circle/disengage during reload; hunters lead movement (bounded) and retreat when close; heavies hold a firing zone. Tidewarden Double Volley (1.6s warning, 0.9s gap, 13s cooldown), Corsair Rigging Breaker (1.8s warning, 2s slow on actual hit, 14s cooldown), Regent Squall Charge (2s warning, 1.1s straight dash, extra 1s broadside warning, 16s cooldown). All have 2s recovery; cover, range and visibility are rechecked before shots. Player guns/controls/fragile starter balance unchanged.
- Original 16-bar 6/8 theme **Lanterns on the Rolling Tide**, with synthesized concertina-style reeds, fiddle/whistle response, plucked bass, stomps/claps and boss percussion. Three synchronized arrangements crossfade; no downloads/samples/services. Existing SFX and separate saved volume/mute controls remain.

## Actual local results (Windows)

Godot 4.5.2 stable official / matching Windows export templates, OpenGL compatibility, NVIDIA GTX 1660 Ti. Python 3.12 + jsonschema 4.26.0; Node 22.14 / npm 10.9.2 / Vite 6.4.5; Cargo 1.99.1. All Godot runs use isolated test APPDATA, never the player's campaign.

Commands: `games/broadside/tests/run.ps1 -Godot <4.5.2-console> -Python <test-venv-python>`; individual `--headless --fixed-fps 60 --script res://tests/<suite>_test.gd`; `games/broadside/packaging/build-windows.ps1`; exported `Broadside.exe --script <absolute-test-harness>` without `--headless` for native tests.

- Source assertions: combat 39, AI 7, refinement 53, impacts 31, balance 20, viewport 43, campaign 17, shipyard 27, odyssey 28, fleet 27, shipyard GUI 19, new M2-E 44. Every suite has an individual clean exit with all assertions passing across the documented runs. M2-E exercises real projectiles/slow expiration, actual dash motion, warnings/cues, cooldowns, offscreen cancellation and music transitions.
- **Full runner is not clean:** two combined runs hit intermittent native signal 11 on shutdown, after combat 39/39 and later balance 20/20 respectively. Similar shutdown failures were recorded in M2-D. Do not interpret passing assertions as a passing process or hide errors. Root cause is unconfirmed; no engine upgrade or ignored failures introduced.
- Actual exported Windows EXE: fleet 27/27, GUI 19/19, viewport 45/45 (including fullscreen), odyssey 28/28, M2-E 44/44: **163 assertions, zero failures, clean process exits**.
- Native real-time 26-second mixer check: one complete loop, all three arrangements/crossfades and SFX, peak 0.3967, RMS 0.0405, 2,635,776 channel samples, clean exit. Exported three WAV audition files. Automated sample/mixer checks are not a human listening review: subjective melody, timbre and mix still need ears/headphones.
- Windows release export, exported boot and exact three-file ZIP passed. Package version 0.2.4-m2e. `npm run build` passed; Rust `cargo test --offline --manifest-path launcher/src-tauri/Cargo.toml` passed 2/2. Launcher source untouched.

## Screenshot and resize validation

Native captures: 800×450 upgrade checkout and chart/main menu; 1280×720 pinned repair/inventory; 1920×1080 inactive brig comparison; 2560×1440 fullscreen. A 2560×1440 window request is clamped by Windows to a 2560×1415 client area on this monitor; the fullscreen capture verifies the exact 1440 height. Capture harness checks repair above scrolling inventory, price/Confirm non-overlap and visible checkout controls.

The first fullscreen harbor capture exposed a removed menu still subscribed to viewport resize before deferred deletion (debug null-viewport errors; exported unhandled exception). Fixed with an in-tree guard on menu/harbor resize callbacks. Added immediate resize during menu transition to the real GUI suite; source and exported GUI both pass 19/19, and exported fullscreen now captures and exits cleanly. This specific fix is not presented as the root cause of the separate headless shutdown issue.

## Review needs

Human playtest: purchase flow with your existing fleet; reading comfort and scaling on your display; all three bosses against moving human players; pacing/avoidability; enjoyable shanty timbre and SFX audibility on speakers/headphones. Existing migration, backups, currency, purchases and no-softlock recovery are regression-tested, not replaced. GitHub Actions results and downloadable artifact are linked in the PR once available.
