# Game Dock repository — coding agent instructions

This repository contains the **Tauri/Rust/React Game Dock launcher** and independent standalone games. Preserve launcher/game separation and require verifiable tests.

## Latest requested milestone: Broadside M2-E (October 30, 2026)

Use docs/BROADSIDE_M2E_POLISH.md and GitHub Issue #12 to refine the existing M2-D campaign (base feature/broadside-m2d-fleet / PR #11, **not main alone**). First: clean duplicate tooltip + opaque reparented upgrade modal in shipyard_ui.gd, make all upgrade descriptions clear to a 12-year-old, pin active-ship repair atop the harbor with optional sail-damaged (no automatic purchase). Then: zoom out slightly more / use responsive menu layout, give enemy classes distinct movement and bosses real telegraphed special moves, replace dull soundtrack with a fun original sea-shanty-style arrangement. Preserve permanent per-ship saved upgrades, existing captain/voyage and Game Dock installation ZIP. Deliver tested PRs, never auto-merge.

## General guardrails
- Read README.md, docs/ARCHITECTURE.md and relevant game-specific spec BEFORE changes.
- Work on a feature branch, open a pull request, **never auto-merge** or force-push main.
- Do not remove or rework launcher code to implement a game. Keep games independent.
- Prefer reusable, typed, documented components, tests and small clear commits.
- Do not fetch unlicensed copyrighted assets, commit binaries/build artifacts, secrets, or require paid services.
- Report exact tool versions, commands, tests run, and unverified steps. Do not claim native Windows execution based on a headless build.
- Do not overwrite unexpected local changes; inspect the repository first.

## Full Broadside campaign now authorized (2026-10-23)

The owner has approved the playable M1.4 version and requested **full Endless Odyssey implementation** from Issue #5. The prior stopping condition 'await permission to begin M2' is superseded; implement the already-approved M2-A/B/C features as separate tested, reviewable PRs, respecting branch dependencies and never auto-merging PR #4 or future PRs. See `docs/BROADSIDE_ENDLESS_ODYSSEY.md`. For easy Windows installation, also implement Issue #6: package an actual standalone playable **Broadside.exe + Broadside.pck + game.json** ZIP as a dedicated Broadside artifact, not the Game Dock installer; see `docs/BROADSIDE_INSTALL_IN_GAME_DOCK.md`. Do not falsely claim the full game is built before tests and review.

## Latest playable-combat visual feedback: Broadside M1.4 (2026-10-23)

Read `docs/BROADSIDE_M14_VIEWPORT_HUD_LOCATION.md`: modest camera zoom-out (0.80 → ~0.72 test), responsive **windowed and fullscreen** framing, separate *reserved* gameplay viewport **above** a bottom-anchored HUD (no ocean drawn behind meters), and a location name card for **The Sable Channel** driven by encounter data. Enemy offscreen arrows must stay in the playfield. Implement as a narrowly scoped improvement to existing PR #4, not as an excuse to begin M2. Preserve M1.3 combat and audio.

## New campaign direction: Endless Odyssey (2026-10-23)

Read **docs/BROADSIDE_ENDLESS_ODYSSEY.md** for user-approved campaign vision and implementation gates: fragile 60-HP starter test / 16-damage cannonball test, short first duels; named captain and ship; endless chart-linked nautical adventure with skippable sailing interludes between self-contained battles; meaningful shipyard upgrades beyond gun count/HP, and distinct purchasable hulls. **Do not implement the entire campaign in active PR #4**. Only small M1.3 tuning may go there; split M2-A, M2-B and M2-C into reviewed PRs after combat approval. All existing no-mouse-in-combat, Space fire, auto-reload, dual WASD/arrows and music/indicator/HUD/impact requirements still apply.

## Current priority: Broadside M1.2

Read `docs/BROADSIDE_M12_FEEDBACK.md` for the latest user-requested refinement. The starter sloop has **one cannon on each broadside**, future shipyard upgrades add guns; game HUD has a **bottom-anchored hull-health bar and two independent cannon reload bars**; substantial rocky-island impacts cause crash damage, and ship-on-ship rams cause damage to **both** ships with impact-speed thresholds and safeguards against per-frame repeat damage. Update the existing Broadside PR #4 if still open, and do not implement the full economy yet.

## Active Broadside design contract
For any work under games/broadside:
1. Read docs/BROADSIDE_DESIGN_DRAFT.md (approved design v1.0) and docs/CODEX_BROADSIDE_BUILD.md, plus GitHub issue #3.
2. Arcade-tactical top-down 2D pirate naval battle, Godot 4.x, original painterly pirate art, open-water plus rocky islets.
3. **Movement:** WASD and arrows interchangeable. **Space:** fire loaded fixed port/starboard batteries, reload automatically on independent timers. **Escape:** pause/resume.
4. **NO mouse combat control or aim**, no click-to-shoot, no Q/E fire, no manual reload, no Space-to-repair. The player must turn/position the ship to line up broadsides. Mouse and keyboard both work in menus/shop.
5. Player controls one ship; enemies scale by class and number. Planned purchase hierarchy: **sloop -> brig -> frigate -> galleon** with genuine ship silhouette/stat/cannon changes.
6. First Codex PR is **M1 working combat vertical slice**. Stop for hands-on user review before PR2 economy/class shop or PR3 art polish.
7. Standalone Windows export and game.json must conform to specs/game-manifest.schema.json, with separate Godot user:// saves.

These choices override earlier prototype instructions describing mouse aim, Q/E firing or in-combat repair.
