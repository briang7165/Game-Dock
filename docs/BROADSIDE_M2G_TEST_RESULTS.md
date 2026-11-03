# Broadside M2-G — purchase, navigation and visual QC

Version 0.2.6-m2g. Based on PR #15 / `feature/broadside-m2f-voyage-harbor` at `31de2b2`, not main. No merge performed.

## Actual fixes

- Removed category-slot purchase gates, slot counts and slot-based remaining-level calculations. Every compatible fitting can coexist at its own hull-specific cap. Frigate and galleon sails/rudders now permit the same three tiers as smaller ships; larger hulls retain more guns and generally equal or higher caps. Existing above-cap purchases remain effective and are never removed.
- Selecting an unowned Fleet card now prepares its estimate directly in the pinned checkout. Previously, the purchase action was below the scrolling fleet list; selecting the card alone only displayed a comparison with Confirm disabled. Owned ships expose a pinned Make Active action. Neither inspection nor navigation spends gold.
- Validation and the detail panel share exact shortage, ownership, tier/cannon-capacity, compatibility and saved-battle reasons. Quotes are revision-checked, confirmation charges once, write errors remain visible, and a saved battle points back to the Voyage Chart to resume.
- Removed the four invisible solid boundary walls. A smooth inward water current works through normal movement, with visible inward foam arrows. Player steering remains under player control. AI uses a separate edge-return state with hysteresis; route points stay inside that trigger.
- Added a shared deterministic visibility graph around island envelopes, shoulder/lookahead sensing, persistent routes, shore escape and physical-contact recovery. Broadside alignment and actual terrain-blocked projectiles remain mandatory. Charge abilities yield to obstructed water and boundaries.
- Enemy health meters use actual health/max health, disappear on sinking, remain upright over ships, and give bosses a wider gold bar and name.
- Reload meters update when the real clocks tick, fire or change loadout. Removed the ProgressBar's integer rounding, which could show a full meter before firing was possible. Non-ready text never rounds to 100% or 0.0 seconds. Both sides remain independent and require a fresh Space press.
- Per-ship saved armor, sails, rudder, lookout and prow ranks reach the renderer. Gun barrels match real gun count. Chain shot visibly links two balls and highlights rigging impacts; long/close-range weapons have different trails/size/color. Five deterministic layouts, varied matching island polygons, and calm/windy/misty/rainy/stormy water effects use original lightweight drawing code. Weather is cosmetic and draws behind combat objects; no obscuring screen flash or altered music settings.

## Saves and installation

The version-2 fleet schema and `%APPDATA%/Broadside` location are unchanged. No campaign reset or extra purchase is required. Names, gold, salvage, fleet loadouts, upgrades and progress remain saved. Existing migration/archive checks still run. Loadout validation retains old purchased ranks; the global allowed maxima have not been reduced.

The ZIP still contains exactly `Broadside.exe`, `Broadside.pck`, and `game.json` at its root (`id=broadside`, `executable=Broadside.exe`). This preserves the existing installation-helper input contract. The user's installed helper/library was not modified or run against their live installation. Close Broadside and replace all three matching files together; leave the separate save directory untouched.

## Reproducible verification

Godot 4.5.2 official with matching Windows templates; native OpenGL compatibility renderer on NVIDIA GTX 1660 Ti. Python 3.12/jsonschema 4.26.0. Node 22.14/npm 10.9.2/Vite 6.4.5; Cargo 1.99.1. Tests use isolated APPDATA directories, never the player's live campaign.

- `games/broadside/tests/run.ps1 -Godot <4.5.2-console> -Python <python-with-jsonschema>`: final complete local run passed **510 assertions across 17 suites**, plus editor import, boot and manifest validation. This includes the prior 393 checks and M2-G purchase 43, combat 27, navigation 47.
- Purchase tests drive real GUI clicks for brig at exactly 320 and at 488 gold, frigate at 800, galleon at 1500, confirm, Make Active and disk reload. They also buy every fitting tier and weapon across all four permanent hulls; check exact 312-gold shortage, active-battle restrictions, cancellation, preserved purchases and duplicate-confirm rejection.
- Reload tests examine 270 ticks for each of four weapons at two gunnery ranks, with gunner crew, both sides, a pre-ready fractional tick, same-tick firing, changing loadout fractions, pause and fresh/held/echoed Space.
- Navigation tests cover all six roles across five layouts, three-ship traffic, all four player edges, all six enemy roles at an edge, and the Regent charge. They require safe graph paths, physical escape, a recovered firing lane, bounded contact stalls and no current damage. The deliberately late head-on starts can require a long detour for heavy hulls; the slowest clear lane in the final headless run was about 43 seconds, with no two-second sampled contact stall. This is not a claim that every human-played fight or possible ship arrangement is proven trap-free.
- Native exported Windows suites passed 271 assertions across fleet, GUI, viewport/fullscreen, odyssey, bosses, harbor, voyage, purchases and reload/combat. Screenshot layout checks passed at 800x450, 1280x720, 1920x1080 and requested 2560x1440 (Windows clamps the windowed client to 2560x1415); fullscreen harbor captured at 2560x1440. Native navigation acceleration has not produced a result and is not counted as passed; its 47 checks passed in the source suite. Additional native performance/audio results, if completed, are recorded in the delivery review bundle and PR.
- `npm run build` passed; `cargo test --offline --manifest-path launcher/src-tauri/Cargo.toml` passed 2/2. Launcher code is unchanged.
- `packaging/build-windows.ps1` passed the release export, exported-runtime boot and exact three-file ZIP check.

Development tests exposed route/edge conflicts, premature recovery during ordinary turns and several slow obstacle approaches; these were corrected before the final source run. One earlier failed navigation run also hit the previously observed Godot shutdown signal 11; it is not counted as a successful process. The final complete source run exited cleanly. The old projectile-expiry fixture now waits the configured lifetime rather than relying on impact with a removed boundary wall. The boss-special fixture explicitly uses clear water; obstruction cancellation is covered separately by the navigation suite. Capture checks use explicit failure branches so release exports cannot compile them away as debug-only assertions.

## Human playtest still needed

Judge enemy aggressiveness and long detours around islands, especially galleons and crowded fights; current strength and feel while steering at an edge; upgrade/readout clarity at the user's Windows DPI; and visual weather/weapon readability over longer sessions. Automated scripts do not establish universal performance, human win rates or guarantee every terrain/ship arrangement. Reuse the existing installation helper with the new matched ZIP and verify the user's own saved fleet after launch.
