# Codex Task Book — Broadside (Godot 4.x / Game Dock)

**Start here.** This document is intended to be given verbatim to Codex. Source of truth: [approved Broadside specification](BROADSIDE_DESIGN_DRAFT.md). Tracker: [Game Dock issue #3](https://github.com/briang7165/Game-Dock/issues/3). Last design lock: 2026-10-22.

## 0. Operating instructions for the coding agent
You are implementing an original Windows desktop game in the existing repository **briang7165/Game-Dock**. Work in a new feature branch, open a focused pull request, do not auto-merge. **Do not rewrite Game Dock's launcher.** Read root README.md, docs/ARCHITECTURE.md, specs/game-manifest.schema.json and docs/BROADSIDE_DESIGN_DRAFT.md first, before modifying code. The latest approved game-spec rules win over old issues or suggestions.

### Absolute gameplay decisions
- Single player ship in top-down 2D, **arcade-tactical** motion.
- **WASD and arrow keys are interchangeable movement controls**.
- **Space = fire** (fresh key press fires currently loaded port/starboard batteries, fixed outward firing directions, independent **automatic** reload); **Esc = pause/resume**.
- **NO mouse in combat**; NO aiming cursor/aim assist, NO click-to-fire, NO Q/E fire buttons, NO Space-to-repair. Player must line up actual broadside.
- Menus, victory screen and future dock MUST support mouse **and** keyboard focus with arrow/WASD, Enter/Space and Escape.
- **Painterly pirate** original illustrated visual direction: wood/canvas/navy/teal/brass, not pixel art or photoreal 3D. Temporary handmade/procedural placeholder art is acceptable in PR1, not final asset quality.
- **Battles feature open ocean with rocky islets/reefs**, valid solid collisions and projectile interception.
- Long-term progression requires gold earned from fights, repair at dock, purchasable real ship classes **sloop -> brig -> frigate -> galleon**, incrementally upgradeable cannons/sails/rudder/hull/repair crew, and increasing enemy ship classes/counts. Design the code for this from PR1; deliver purchase/shop/progression in PR2 after hands-on combat review.

### Constraints
- Target Godot 4.x stable with **typed GDScript**, original graphics where feasible, and free/no-subscription dependencies only.
- Independent Windows x64 game at games/broadside/; run without Game Dock. No online or cloud features.
- Local game saves belong in Godot user://, never next to the executable.
- Use a game.json manifest validated against specs/game-manifest.schema.json for integration; executable basename Broadside.exe.
- No destructive operations, no secrets, no arbitrary executable download/run, no launcher architecture refactor.
- Do not claim Windows running/packaging tests unless actually executed; state environments, exact versions, command, results and blockers.

## 1. First implementation assignment — PR1 playable vertical slice
Goal: a genuine playable **one-on-one** tactical sailing battle (not slides/screenshots/mockups), with one to three rocky islets and fair enemy positioning. Must be satisfying enough for human hands-on feedback.

### Create a complete Godot project
Suggested structure (change only with good technical reason):

    games/broadside/
      project.godot
      export_presets.cfg
      README.md
      scenes/
        MainMenu.tscn
        Arena.tscn
        PlayerShip.tscn
        EnemyShip.tscn
        Cannonball.tscn
        Island.tscn
        HUD.tscn
      scripts/
        ship_base.gd
        player_ship.gd
        enemy_ship.gd
        cannon_battery.gd
        cannonball.gd
        arena.gd
        battle_state.gd
      data/
        hull_stats/ ...
        cannon_stats/ ...
      assets/
        original/ ...
      tests/
      packaging/
        game.json

Scene and script names may vary, but maintain clean responsibilities and testable collision/damage/firing code. User should not need to manually fix broken editor scene references.

### Implement, in dependency order
1. Project boot, main menu, battle scene, camera, renderer settings and visible open-water map with rocky obstacle art/collisions.
2. Controlled ship with speed/acceleration/turning/drag; both control layouts work simultaneously.
3. Two separate cannon batteries with visible cannon ports; Space performs a one-shot-per-keypress **loaded sides** salvo; independent cooldown and automatic reload timers; no cursor control.
4. Projectile physics with spawn positions, velocity, finite lifetime, hit ownership, water splash, island hit and ship hull damage; visible short smoke/fire/hit effects; no diagonal homing.
5. One AI ship that navigates and aligns **its own** broadside before firing, does not shoot through solid rocks, telegraphs attacks, and recovers from blocked paths.
6. HUD showing player/enemy health and **port/starboard cooldowns**, win/lose summary, restart and Esc pause.
7. Usable menu focus via WASD, arrows, Enter/Space and mouse. Game should not keep moving/firing while paused.
8. Adjustable gameplay resource values so human playtesting can tune bullet speed, cannon spread, turn rate, HP and AI aggressiveness.
9. Original illustrated placeholders emphasizing wooden hull/sails/rocky islets with colors/layout outlined in spec. Do not spend most time on textures before mechanics work.
10. Engine-headless load checks, scripted gameplay sanity checks where feasible, Windows export preset and packaging README.

### Explicit negative tests
- Combat mouse position/click cannot redirect projectiles or fire cannons.
- Q/E do not trigger cannon fire. Space does not repair.
- Fire with Space while one side reloading: ready side fires, reloading side does not; both reload automatically; holding Space is not automatic barrage.
- Cannonballs must not pass through rocky obstacles or damage their source vessel.
- On pause, boat physics, shots and enemy AI stop.
- Main menu, pause and end screen remain keyboard navigable even without mouse.
- Exported game must run independently of Game Dock.

### Required PR1 deliverables
- Complete Godot source project committed; no .godot cache or generated binaries.
- README: Godot version; how to open/play in editor; controls; headless test/import command; how to export Windows standalone; how to integrate with Game Dock manually.
- Export preset with correct Windows x64 executable name; note export templates required. Include complete files needed for release (.exe and separate .pck when applicable), plus packaging/game.json.
- Any reused external free artwork/audio has documented license and attribution.
- Test evidence with exact successful/failed commands and unresolved issues; avoid phantom success.
- PR description with screenshots/short capture if environment supports it and list of remaining limitations.
- **STOP after PR1**, seek user's feel/visual feedback before starting ship economy, class upgrades or multiple enemies.

## 2. Planned PR2 (do not start until PR1 reviewed)
Build the long-term progression system according to approved specification:
- Distinct sloop, brig, frigate, galleon assets/silhouettes and stats; tier purchase costs.
- A dock/shipyard UI with total gold, shop cards, previews, stats delta, repair cost, disable unaffordable buttons and clear purchase confirmation.
- Upgrade categories: cannons count/capacity/reload/damage, sail acceleration/speed, rudder maneuvering, hull/armor, repair efficiency.
- Bought upgrades carry forward (within new ship hull capacity); save in user:// with schema and failure recovery.
- Encounter progression and smarter/more enemy ship variants including bosses; award gold for wins and some salvage on losses, keep economic retry viable.
- HUD/battle result includes money earned, ships sunk and shot accuracy.
- Use data-driven configurations and balance tests; verify menu keyboard & mouse parity.

## 3. Planned PR3 polish / distribution
- Replace procedural placeholders with cohesive original painterly 2D assets and animations.
- Refine ocean and island art, cannon sounds/impacts (original or attribution-compliant licenses), accessibility and difficulty.
- Produce versioned standalone Windows ZIP, complete game.json, and test manually in Game Dock.
- Existing Game Dock installer remains independent of this project.

## 4. Verification commands and evidence
Where Godot executable exists, run headless parse/import/load checks e.g.:

    godot --headless --path games/broadside --editor --quit
    godot --headless --path games/broadside --quit-after 30
    godot --headless --path games/broadside --export-release "Windows Desktop" <absolute-output-path>/Broadside.exe

Use appropriate Godot invocation/executable for the environment. Export requires Windows export templates; if not installed, record the missing dependency and include detailed instructions to finish on Windows. Never include a fictitious compile result.

Test at least:
- 1280x720, 1920x1080, and a smaller resizable window.
- Every control both WASD and arrow layouts, Space, Escape; mouse only in menus.
- Ships/islets/projectiles collide correctly without getting stuck.
- Win, loss, restart, pause/resume, no crash on main-menu transitions.
- Performance/physics stability over a few minutes of play.
- Windows standalone executable opens directly (when Windows runner/tester available).
- Game Dock discovers valid game.json and launches full export (when user's Windows setup is available).

## 5. GitHub work method
1. Inspect current working tree and any pending feature work; avoid overwriting existing user changes.
2. Create branch name like feature/broadside-m1-combat.
3. Implement **small reviewable commits**, run tests and document exact results.
4. Open PR to main, include screenshots and a checklist referencing Issue #3.
5. Stop and request player feedback; do not merge or move to PR2 automatically.
6. Update linked documentation and issue checkboxes ONLY for verified, completed tasks.

## 6. Success definition
PR1 is successful only if the player can steer a readable ship, **line up its side with an enemy**, press **Space**, see cannonballs travel and potentially hit/miss, take/dodge incoming fire, and win/lose/restart with mouse-free combat. The structure should make shipyard and hull progression practical in the next phase.

**Do not replace requested functionality with a static image/mock game, and do not claim “production ready” after merely loading the Godot editor.**
