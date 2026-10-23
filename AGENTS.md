# Game Dock repository — coding agent instructions

This repository contains the **Tauri/Rust/React Game Dock launcher** and independent standalone games. Preserve launcher/game separation and require verifiable tests.

## General guardrails
- Read README.md, docs/ARCHITECTURE.md and relevant game-specific spec BEFORE changes.
- Work on a feature branch, open a pull request, **never auto-merge** or force-push main.
- Do not remove or rework launcher code to implement a game. Keep games independent.
- Prefer reusable, typed, documented components, tests and small clear commits.
- Do not fetch unlicensed copyrighted assets, commit binaries/build artifacts, secrets, or require paid services.
- Report exact tool versions, commands, tests run, and unverified steps. Do not claim native Windows execution based on a headless build.
- Do not overwrite unexpected local changes; inspect the repository first.

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
