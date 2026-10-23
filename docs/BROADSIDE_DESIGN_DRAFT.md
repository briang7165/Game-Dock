# Broadside — Approved Game Specification v1.0

**Approved 2026-10-22.** Status: game design decided; implementation pending. For Codex execution see docs/CODEX_BROADSIDE_BUILD.md and Issue #3. This document supersedes the earlier provisional draft. Do not substitute mouse-aim or other past control ideas.

## New approved vision: Endless Odyssey (2026-10-23)

Read **[Endless Odyssey campaign design](BROADSIDE_ENDLESS_ODYSSEY.md)** for the newest user direction. Early sloop/AI should be more fragile to make first duels faster, starting balance **test** at approximately 60 player HP and 16 cannonball damage, then tuning. The long-term game features naming **captain and ship**, a skippable map/chart voyage cutscene between discrete battles, continuing **endless chapters**, a dock/shipyard with genuinely diverse tactical upgrades (sails, rudder, gunnery, hull, lookout, crew, utility and equipment loadout tradeoffs), distinct purchasable hull classes and enemy variety. Keep **one cannon per broadside** on a new sloop; advanced power is earned. Implement in stages after M1.2 with tests; this supplements all previously confirmed controls/art/terrain.

## Latest approved refinement: M1.2 (2026-10-22)

**Read [M1.2 starter cannon, bottom HUD and collision damage spec](BROADSIDE_M12_FEEDBACK.md) before implementing or modifying M1.1.** The starting sloop must have **ONE cannon on EACH side**, rather than three per side, with earned additional cannons planned for M2. Replace text-only battle HUD with a **bottom-anchored hull-health bar and separate visual port/starboard automatic-reload bars**. Rocky-island crashes damage hulls with severity based on impact speed. **Ship-to-ship rams damage both vessels**, without damage repeating every frame while in contact. This explicitly supersedes any earlier generic defaults about starting weapon count, HUD or collision damage. Preserve all other approved control and art choices.

## 1. Vision / scope
- Original, offline, single-player **top-down 2D pirate naval combat** game.
- **Arcade-tactical** handling: responsive acceleration and turns with modest momentum/drag and a meaningful turning radius; no realistic sail/wind simulation.
- The player always commands **exactly one ship** against 1 to several enemy ships as levels advance.
- **Skill is alignment**: maneuver your hull to line up fixed port/starboard cannons with enemy ships, then time shots. Cannonballs are fast, visible, missable and dodgeable at useful distances.
- Persistent gold, repairs, incremental ship improvements and purchase of bigger ship classes are defining parts of the game, delivered after the combat vertical slice.
- Runs standalone on Windows x64, and later through Game Dock with existing manifest contract. No login, subscription, network requirement or telemetry.

## 2. Locked keyboard / mouse controls

| Action | Keys |
| --- | --- |
| Throttle up | W or Up arrow |
| Brake / slow / light reverse | S or Down arrow |
| Turn port / left | A or Left arrow |
| Turn starboard / right | D or Right arrow |
| Fire loaded cannons | **Spacebar** |
| Reload | **Automatic** |
| Pause / resume | **Escape** |
| Menus / after-battle dock | Mouse click/hover OR WASD/arrows to move focus, Enter/Space select, Escape back |

**No mouse use in battle:** mouse movement, click, aim crosshair, target assist or homing behavior MUST NOT affect firing. NO Q/E fire keys; NO manual reload key; Space is never repair. The player must align the side of the ship with enemies.

**Space firing behavior:** each *new press* of Space launches a fixed-direction salvo from **both ready broadsides** (port and starboard) simultaneously. Each side has its own automatic reload timer. If only one side is loaded, that side fires; holding Space does NOT repeatedly fire as soon as reload completes. Shots emerge from visible cannon ports along each broadside and travel outward approximately perpendicular to the ship's forward axis. Minor per-gun spread is acceptable, but no swiveling turret, player aim vector, target lock or guided projectiles. This is the initial single-button interpretation; player feedback may refine it later.

## 3. Handling and combat
- Use Godot CharacterBody2D or similarly controlled physical hull movement; ship speed, acceleration, turn rate, drag and reverse are configurable and framerate-independent.
- Ship has weight but responds quickly: steering and throttle matter, no instant 180-degree rotation.
- Port and starboard batteries have gun counts, cooldown, muzzle placement, velocity, damage and spread configurable per ship.
- Cannonballs use real collision, lifetime/culling, shot ownership, visible flight, water splashes, hull impact effects, and rocky-island collision. No hit-scan or instantly teleported damage.
- Fast and observable projectiles, especially at range. Tune enemy telegraphs (e.g. visible flash or smoke build-up) and projectile speed for fairness; evasion via maneuvering should be possible when positioned correctly. Not every point-blank shot must be dodgeable.
- Separate port/starboard reload status in HUD. No finite ammo stock initially.
- Direct hits damage hull; 0 HP sinks ship. Victory when all enemies are sunk, defeat when player is sunk. Provide restart and pause menus.
- Enemy AI approaches workable broadside range, turns its hull into firing alignment, fires on cooldown, seeks alternate angles, avoids solid rocks, and has recovery if stuck. Initial prototype: one enemy, later fleets/tactical roles.
- Prevent shots from damaging the firing ship; use reliable hit filtering/collision layers, no unbounded projectiles, no boats sticking permanently in rocks.

## 4. Visual and physical design — Option B painterly pirate
- **Hand-painted / illustrated 2D overhead style**, not pixel art, not 3D, not photorealism.
- Rich ocean blues/teals, layered painterly wave texture, foam/wakes, tan canvas sails, weathered brown wooden hulls, muzzle flash, smoke, splashes, cannon recoil and visible hit damage.
- Dark navy/sea-green/brass interface with tasteful parchment accents; complement Game Dock without copying its UI wholesale.
- Prioritize readable outlines: every ship's class and allegiance recognizable at gameplay zoom, adequate UI contrast and sizes.
- Temporary original procedural/vector art is fine for FIRST playable PR; do not call it final art. Never reuse proprietary game art or unknown-license image downloads. Document licenses for any reused free assets.
- Ship-class progression must change actual **silhouette and scale**, mast/sail arrangement, cannon ports and color detailing, not just a numeric stats panel or recolor.

## 5. Battlefield — Option B islands and rocks
- Open-water arena with **rocky islets, reefs and occasional obstacles**. First playable scene: 1–3 small rocky islands with generous channels/open water, no clutter.
- Ships cannot pass through terrain; cannonballs collide with rocks. Collision outlines should match art.
- Spawn in safe water away from islands; route/steer enemies around obstacles and avoid hopeless traps.
- Smooth following camera, accessible arena bounds and well-scaled heads-up display.
- Later: multiple arena layouts and thematic lighting, with fair obstacle placements and possible safe path checks.

## 6. Ship purchases and progression — core to long-term game
Player starts in a **sloop** and earns gold by winning fights. Between battles, the player visits a dock to repair, buy upgrades or save up for a bigger class.

| Hull | Role / look | Trade-off |
| --- | --- | --- |
| Sloop | Small agile starter, few visible cannon ports, simple mast | Fast and nimble, low hull HP and firepower |
| Brig | More deck length, two masts, more broadside cannons | Balanced mobility/firepower |
| Frigate | Long imposing hull, multiple gun ports/decks | Strong guns and armor but slower steering |
| Galleon | Very large multi-mast ship, many cannon ports | Highest capacity/HP, largest turn radius |

Actual gold prices, hull stats, damage numbers and unlock thresholds should be data-driven and tuned after gameplay feedback, not hard-coded throughout scripts.

**Upgrades:** additional cannon slots/count subject to hull capacity, cannon damage/reload, sails/top speed/acceleration, rudder/turn rate, hull HP/armor, repair effectiveness. Show stats before/after a purchase; purchases materially affect visuals where practical.

**Persistence:** purchased ship classes and global technology improvements survive defeat and transfer to newly purchased hulls subject to the new hull's equipment capacity. Save after purchases/battles using Godot user:// in a versioned file (not adjacent to .exe). Provide safe new game/continue/reset and protect against corrupted save data. Repairs cost gold between battles; prevent softlocks with affordable basic repairs or repeatable encounter/salvage earnings.

**Progression:** early enemies use sloops/brigs; later add frigates, galleons, and more enemy ships. Enemy roles: small skirmisher (quick/fragile), regular broadside fighter, heavy gunship (slow/hard-hitting), boss/escort combinations. Prefer smarter positioning, ship-class variety and fleet composition over simply multiplying HP. Target an encounter boss every five levels once that system exists. Display battle stats such as shots, hits, accuracy, damage, reward.

**Menus:** new/continue, battle intro, in-battle pause, victory/defeat, **dock and shipyard** shop with ship previews, prices, current funds, repairs, upgrades, next battle. All menu controls accessible with mouse and WASD/arrows + Enter/Space + Esc. No mouse use for battle.

## 7. Godot project structure & technical quality
- Godot **4.x stable**, GDScript, scene/resource based architecture; target 60 FPS on typical Windows desktop.
- All game content in games/broadside/ of briang7165/Game-Dock. Game Dock launcher remains independent; do not alter launcher unnecessarily.
- Recommended scenes/scripts: MainMenu, Arena, PlayerShip, EnemyShip, ShipBase, CannonBattery, Cannonball, Island, HUD, PauseMenu; later Dock, Shop/ShipCatalog, UpgradeSystem, CampaignSave, EncounterDirector.
- Typed GDScript, small reusable modules, editable hull/cannon/level resources, consistent named input actions, explicit collision layers; no giant single-file implementation.
- Windowed/resizable: test at 1280×720 and 1920×1080 and smaller window.
- Support pause semantics, independent timers, deliberate input mapping, readably scaled menus.
- Store code/source art, test scripts, project config, Windows export preset, licensing info and README in Git. Exclude .godot cache/build binaries.
- Add headless Godot project-load tests and logic tests where practical. No fabricated test claims; document actual commands/results.
- No internet services, ads, paid assets, subscriptions or external account authentication.

## 8. Packaging with Game Dock
- Produce standalone Windows x64 Broadside.exe and any required Godot .pck/assets, with a per-game manifest conforming to specs/game-manifest.schema.json (id = broadside, executable = Broadside.exe).
- The complete executable package works by double-click independently of Game Dock.
- For Game Dock, copy complete export (including required .pck if separate) and game.json to the launcher games/broadside install folder; refresh and launch.
- Store saved games in a user-data folder, not in installation directory.
- Check all manifest JSON field constraints, executable filename and paths. Do not implement a launcher updater or auto-download as part of first game work.

## 9. Codex phases and acceptance gates

### Phase A / FIRST PR: one-on-one combat vertical slice
- [ ] Godot project opens and runs; introductory menu starts a battle.
- [ ] WASD OR arrows control the same throttle/steering; response is arcade-tactical.
- [ ] Space on key press fires both **loaded fixed broadsides**; each independently reloads automatically; no mouse aiming, Q/E firing, manual reload or Space repair.
- [ ] Player and one AI enemy both move, fire, take damage, sink, and show win/lose/restart.
- [ ] Fast visible cannonballs collide with enemy ships, islands and water correctly, with basic smoke/splashes and no friendly-self hits.
- [ ] One to three rocky islets with physical collisions, navigable arena and playable enemy obstacle behavior.
- [ ] Clear readable port/starboard reload HUD, health, pause, keyboard/mouse accessible menus.
- [ ] Original painterly-intent **prototype** art and visible ship silhouettes; data resources prepared for later classes, not full shipyard yet.
- [ ] Headless validation logs/results and honest standalone Windows export instructions; actual export if feasible.
- [ ] Focused pull request; do not merge into main without review.

### Phase B / SECOND PR: dock, ship purchase, savings, and enemy tiers
- [ ] Earn gold, pay for repairs or upgrades, save for one of 4 visually distinct hull classes (sloop/brig/frigate/galleon).
- [ ] Every class has distinct real cannon slot counts/handling/durability and visual silhouette.
- [ ] Dock shop works with keyboard and mouse, including disabled unaffordable actions, previews and purchase confirmations.
- [ ] Persistent save, battle summary, replay economy without softlocks.
- [ ] Enemy ship classes and multi-enemy encounters, balanced progression and miniboss.

### Phase C / THIRD PR: stronger artwork, effects, audio, and packaging
- [ ] Painterly ships, island details, richer water effects, original/licensed sounds.
- [ ] Tune collision, responsiveness, enemy accuracy, scaling, save migration, performance.
- [ ] Standalone Windows release ZIP and launcher integration verification on player's PC.

**Precedence:** User-confirmed controls and art choice above outrank older chats/drafts. Prefer incremental working software with passing tests to claiming a finished game without actual execution.
