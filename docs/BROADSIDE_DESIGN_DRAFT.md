# Broadside — Game Design Draft v0.1

Status: PROPOSAL for discussion and Codex implementation. Gameplay numbers and art style are not final. First create a *playable vertical slice*, not an entire game.

## Vision
Broadside is a single-player, top-down 2D pirate naval arena game for Windows. The player commands exactly one ship against escalating enemy fleets. Skill comes from ship positioning, leading cannon shots, firing arcs and hull management. Fast cannonballs should be visible, telegraphed and dodgeable through anticipation/maneuver rather than point-and-click hitscan. Later, earned gold funds repairs and lasting upgrades. It must run standalone without Game Dock.

## Platform / engineering decisions
- Engine: Godot 4.x stable, GDScript with typed variables where practical; no paid assets or subscriptions.
- Repository: keep a separate Godot project at `games/broadside/` within `briang7165/Game-Dock` for now. Do not change launcher infrastructure just to run gameplay.
- Engine independence: provide a standalone Windows `Broadside.exe` and per-install `game.json` matching `specs/game-manifest.schema.json` and `docs/ARCHITECTURE.md`.
- Use a scene-based architecture with small scripts and testable combat calculations. Do not use large monolithic scripts or fragile editor-only manual steps.
- Windows x64 first; controls via keyboard + mouse. Target 60 FPS on an ordinary laptop/desktop. Support windowed mode and resizable viewport.
- All required source scenes/scripts/assets must be stored in Git; build artifacts and generated Godot cache must be ignored. No third-party copyrighted art/sound unless properly licensed and documented.
- Prepare headless project load/test commands and a Windows export preset/documentation. If an actual export cannot be verified, report the limitation instead of claiming success.
- Do not add online accounts, telemetry, cloud saves or network dependencies.

## Recommended visual approach
Top-down, clean, slightly illustrated ocean with subtle waves/foam and readable ship silhouettes. Clear port/starboard broadside directions, muzzle flash, smoke, cannonball tracers, hit effects and damage feedback. Placeholder art should still be deliberate and readable; visual polish can continue after the core encounter feels good. Avoid copying art from existing commercial games.

## Intended controls (provisional)
- W / S: increase or decrease throttle, slow reverse optional.
- A / D: steer; momentum/turn rate depend on velocity and ship handling.
- Mouse: aiming position/direction for cannon fire.
- Left mouse click: fire eligible port or starboard broadside toward cursor only if within broadside firing arc; show arcs and invalid aim clearly.
- Space: emergency repair when available (later milestone).
- Escape: pause/restart/quit to title.
A ship cannot fire straight forward if using traditional broadsides. No 360-degree turret.

## Combat rules (vertical slice)
- One player ship and one AI enemy in a bounded ocean arena.
- Both ships move with momentum and drag, turn at limited speed, collide with boundaries and each other without getting stuck.
- Cannonballs travel visibly in world space. Shots can miss; compute hit via collision; include a reload cooldown and hit feedback. Make projectile speed configurable.
- Use speed and firing telegraphs to make avoidance based on positioning and anticipation viable; tune after hands-on feedback.
- Both ships have hull health; direct hits deal damage. Destroying enemy gives win; player destruction gives loss. Restart resets encounter.
- Enemy tries to reach a workable firing distance, turn its broadside toward player, fire at intervals, and avoid getting stuck.
- HUD: own/enemy HP, reload status, simple crosshair and broadside arc, pause, win/loss overlay.
- Include audio on/off setting; original/generated or license-free sound only. No sound dependency required for test.

## V0.1 / acceptance criteria — request to Codex
- [ ] Godot project loads and starts without manual editor scene repair.
- [ ] Keyboard controls move/turn one ship; cursor aims legal broadside fire.
- [ ] Cannonballs have visible trajectories, cooldown, collision, and damage.
- [ ] An enemy navigates and fires back.
- [ ] Either ship can sink; win/loss and restart work.
- [ ] UI scales at 1280x720, 1920x1080 and a smaller resizable window.
- [ ] Game runs standalone independently of launcher.
- [ ] Headless project-load/tests run (where tooling available).
- [ ] Windows export preset included and export attempted/documented honestly.
- [ ] README gives exact Windows setup/run/export steps; report tested vs untested.
- [ ] No destructive changes to launcher or existing project files; use a focused PR and do not merge without review.

## V0.2 — progression after combat playtest
- 5-level progression with varied enemy mixes and miniboss at level 5.
- Gold and salvage earned per encounter; paid repairs at dock, limited in-combat repair.
- Ship upgrades: cannon count/damage/reload, sails/speed, rudder/turning, hull/armor, repair crew.
- Separate save data from installed executable, with versioned saved-game schema.
- Distinct enemy roles (agile skirmisher, heavy cannon ship, armored bruiser), capped enemy count for readable encounters.
- Track skill metrics: hits, shots fired, accuracy, damage sustained and gold.
- Later: endless progression, optional difficulty, more ship visuals, cannon ammunition varieties.

## Design questions to refine with player feedback
1. Arcade handling vs heavier momentum (default: responsive arcade/tactical hybrid).
2. Camera: strict top-down vs slightly angled drawn perspective (default: top-down).
3. Cannon targeting: mouse-directed legal broadside arc vs keys for port/starboard (default: mouse arc).
4. Upgrades: buy between encounters vs earn random choices (default: buy with gold).
5. Mission pattern: level arenas vs ocean map (default: level arenas first).
