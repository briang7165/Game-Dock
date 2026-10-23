# Broadside M1.2 — Player-Requested Gameplay Refinements
**Approved feedback: 2026-10-22.** Apply to the in-progress Broadside game in [PR #4](https://github.com/briang7165/Game-Dock/pull/4) using its current implementation. This is a *small incremental patch*, not a rewrite and not authorization to implement the entire dock economy.

**Design precedence:** This explicit M1.2 update extends and overrides earlier M1/M1.1 defaults where they differ. In particular, a starting sloop may NOT spawn with three cannons on each side.

## 1. Starter sloop has **one cannon per broadside**
- Player starter sloop equips **one visible, functioning cannon on port and one on starboard** (one *per side*, two total). This preserves our single Space-to-fire-both-loaded-sides scheme. NO three-gun volley at the start.
- The one-cannon choice must affect both *visual gun-port count* and *actual cannonball count*: pressing Space when both sides are loaded produces a maximum of **two projectiles, one from each side**. Reload remains **automatic and independent** per side.
- Future upgrades increase the number of installed guns per side within the purchased hull's capacity. E.g. the sloop can earn a second port/starboard gun through the later shipyard/upgrade system; larger ships can support more. Capacity, prices, firing behavior and art should be data-driven, not hard-coded in the HUD.
- For M1.2, do **not** fabricate an upgrade shop. Set the initial loadout correctly and provide upgrade-ready configuration/API for subsequent M2.
- Balance the current AI opponent for a fair duel; it need not inherit player equipment automatically, but don't unknowingly leave a massively overpowered three-gun enemy against a one-gun player. Enemy gun counts should be explicitly configurable per hull/loadout.
- Current PR inspection: `games/broadside/scripts/cannon_stats.gd` defaults to `gun_count = 3`, and both player and enemy use the same `games/broadside/data/cannons.tres` resource. Avoid a global blind number change if different enemy loadouts are desired. Consider distinct `data/player_sloop_cannons.tres` and `data/enemy_sloop_cannons.tres` resources or equivalent per-ship loadout assignments.

## 2. Replace battle's text-only HUD with an attractive **bottom status bar**
- Current PR: `games/broadside/scripts/main.gd` creates a multi-line label at top-left containing hull values and reload text. Replace with a clean, viewport-anchored UI at the **bottom**.
- Center / prominent: **HULL HEALTH** as a clear horizontal progress bar, numeric current/maximum HP, smooth drain animation and appropriate damage flash/low-health warning. Keep contrasts readable; not dependent on red/green alone.
- Flanking or nearby: **PORT CANNON** and **STARBOARD CANNON** recharge bars/radial segments that actually fill according to each independent battery's remaining reload time. Read **READY** when ready and show remaining duration/percentage while loading. Clear labels and visual cues for the two sides; NO weapon aiming HUD or mouse combat.
- Keep enemy HP indication visible but secondary (small upper status or above enemy when on screen). Existing off-screen enemy arrows must remain legible and must not overlap the new bottom HUD.
- Anchor/margins must work at 1280x720, 1920x1080 and smaller resizable sizes, safe against clipping. UI uses painterly pirate/navy/brass aesthetic and doesn't obscure the boats. Use proper Control/Container/ProgressBar architecture rather than a giant manually formatted label.
- Mouse remains **menu-only**; bottom HUD is informative, not a combat button. Menus keyboard- and mouse-accessible.

## 3. Rocks/reefs/islands damage hulls on meaningful physical collisions
- At low relative **impact-normal speed**, a gentle touch or scrape should cause little or no hull damage; strong contact with an island/rock should reduce player/enemy health. Don't damage on every physics frame of sustained contact.
- Compute impact severity using velocity **before movement resolution** and collision normal/relative closing speed (not simply ship cruising speed during an unrelated glancing slide). Preserve access to pre-impact velocity as needed.
- Add a tunable minimum impact threshold, scaling, cap and per-contact/per-pair cooldown, approximately 0.5–1 second as a reasonable starting value. A repeated genuine new collision can damage again; continuous contact cannot instantly drain HP.
- Recognize terrain using existing collision layers (layer 1) or typed obstacle node. Ensure other walls/bounds behave sensibly; at minimum physical rocky islets and reefs cause crash damage.
- Hit feedback should include appropriate localized effect/sound, brief flash, and HUD HP change; existing `take_damage()` and sinking/win/lose events must still operate.

## 4. Ship-to-ship collisions damage **both vessels**
- If the player rams an enemy, apply collision damage to **both ships** based on **relative closing velocity** and optionally configurable class/mass/armor parameters. Enemy colliding with player should behave identically. Do not assume only the initiator takes damage.
- Gentle sideswipes do negligible or no damage; high-speed direct rams inflict clearly greater damage. Damage may differ by hull protection later, but BOTH receive nonzero damage for a substantial impact.
- One impact should be handled **once for the pair**. Avoid damage being counted twice if each ship's physics tick registers the same collision; use shared pair/contact bookkeeping with a short collision cooldown, including safe handling when one vessel sinks.
- Avoid allowing slow contact to farm damage, collision traps, health values dropping below zero, or ghost collision while paused / after sinking.

## 5. Preserve what the user already likes
- Keep the existing **M1.1** heavier ship handling, slower readable cannonballs, improved zoom, off-screen enemy indicators, original offline arcade pirate music and sound effects.
- Movement: WASD/arrow keys; **Space** fires loaded fixed broadsides; automatic reload; **Escape** pause; no mouse aiming or click-to-shoot.
- Keep Game Dock executable/manifest compatibility; no launcher refactor, no shipyard or gold economy in this focused patch.
- Reuse sound system for impacts rather than introducing a new audio subsystem unless necessary.

## 6. Acceptance tests / evidence
1. New battle spawns player with exactly one port gun and one starboard gun; visual cannons match actual projectiles. With both ready, one Space press yields one cannonball per side (two total). Holding Space does not autofire. Both reload independently.
2. Enemy equipment is configurable independent of player loadout; duel remains fair/playable.
3. Bottom HUD shows real current/max HP, separate port/starboard reload fill and READY states; bars update after shots and impacts and scale across multiple window sizes.
4. Controlled low-speed touches with islands do not cause catastrophic health loss; strong head-on impact causes meaningful damage; sustained contact does not drain health every frame.
5. A substantial ship-to-ship ram damages **both** ships once per collision event; standing alongside causes no continuous damage. Collisions by enemies have same outcome.
6. Crash damage can sink a ship and correctly trigger existing win/lose path without crashes.
7. Physics and UI correctly pause with Esc; collision damage does not continue while paused.
8. Tests are added/updated under `games/broadside/tests/` with concrete execution logs (Godot version, commands, results). Capture an in-game screenshot where possible for bottom HUD review.
9. Update relevant docs and PR #4 instead of creating an unrelated giant feature. Ask for player hands-on feedback once updated.

**Design intent:** A sloop should feel scrappy and under-equipped at first, with additional guns as an exciting *earned* upgrade. The HUD should be polished and readable, while careless navigation has consequences without punishing minor accidental scrapes.
