# Broadside M2-G — Purchase Clarity, No Slots, Smarter AI, Boundary Safety, Health/Reload HUD and Visual Variety

**Owner-requested follow-up: November 1, 2026.** Current baseline: the M2-F feature branch feature/broadside-m2f-voyage-harbor, PR #15 (open and unmerged). Branch subsequent work from M2-F, NOT main alone. Preserve all previous stages, the original sea-shanty score, unique bosses, campaign and Game Dock packaging.

## Outcomes required
- Buying any available upgrade/ship is straightforward and reliable. If a purchase cannot be made, show the **specific and accurate reason**, plus what to do about it. No unexplained dead Buy buttons.
- Remove generic **category equipment slots entirely**. If an upgrade is offered for that ship, the user can purchase it to that ship's own maximum tier, subject only to gold, actual hull/gunport capacity, active-battle restriction, specific hard compatibility/owned/equipped rules. Bigger ships have genuinely higher upgrade potential, cannon ports and/or distinct unlocks. No arbitrary slots that block a listed item. Per-ship purchases remain separately saved.
- Enemies handle rocks and arena edges with real avoidance / unsticking; player does not hit an invisible hard wall and spend time stuck.
- Show every enemy's actual hull health in combat; one or several enemies must be readable.
- Port/starboard reload meters and labels match *real firing availability* precisely, including after weapon/gunner changes and first shot.
- Improve visible ship/equipment/shot, island and weather variety without regressing collision geometry, visibility or performance.

## Code-level observations from inspected PR #15
1. Shipyard.availability() in games/broadside/scripts/shipyard.gd returns "Incompatible • category slots full" based on used()/slots() for unpurchased upgrades; it also returns "firepower slots full" when equipping special weapons. This is an explicit cause of some affordable-looking unavailable items.
2. The remaining_levels() and capacity_text() labels and ship cards still revolve around "equipment slots" even though owner wants no slots. They need replacement by real tier progress / gunports.
3. M2-F shipyard_ui.gd supports quotes and in-place Confirm, but blocked purchases still receive generic feedback via Shipyard.confirm(): "Unavailable. Check ship ownership, gold, slots and tier limits." Differentiate specific causes and show them on hover/focus/click.
4. Hull prices from HULLS: Brig 320 gold, Frigate 800, Galleon 1500. HULL purchase must be allowed whenever enough gold is held and the ship isn't already owned, provided the user is truly in harbor. Do not make ownership of a previous class a hidden prerequisite. If the player already owns a ship, offer a distinct "Make Active" rather than an impossible buy. If a campaign state is flagged "active encounter", explain and offer safe resume/cancel flow rather than silently disabling.
5. Arena creates four StaticBody2D boundary walls (arena.gd, near lines 19–28); enemy_ship.gd uses a single forward raycast + a 2.5-second backing/turning recovery. It can repeat the same collision route. There are no separate edge/current recovery rules.
6. battle_hud.gd battery_state() reads battery.remaining / battery.stats.reload_seconds; actual firing uses CannonBattery.ready() and consume(). Verify synchronization by testing firing on the same frame as READY, holding Space, reload/weapon changes, and pause.
7. Existing battle HUD shows player hull + separate reload bars but no enemy HP meter; boss status is text only.
8. Current hull art adds larger hull/masts, but armor and ammo effects are barely visually differentiated; island locations/theming are repetitive.

## A. Remove slot restrictions but retain meaningful per-ship upgrade limits
- Delete category-slot gating as a **purchase blocker** from Shipyard.availability(), weapon selection and underlying preview/confirm code. No user-facing equipment slot counts or slot-full reason for **any item that remains offered**.
- Maintain tiers capped per hull class, specific max cannon ports/hull capacity, distinct hull characteristics (sloop fast/fragile, brig balanced, frigate guns/fast broadside, galleon heavy). Make larger vessels offer **equal or more capacity for most upgrades** and more upgrade options. Review current LIMITS: some frigate/galleon tiers are *lower* than sloop tiers; revise thoughtfully so upgrading to larger ships feels meaningful without removing small-ship agility. Make all cap changes data-driven.
- Armor, rudder, sail, gunners, lookout, prow, carpenter, cargo upgrades may all coexist at their valid individual tier caps. Specialized ammunition/weapon choice is an **equipped loadout** rather than a category-slot consumer. Allow all ammo types to be acquired, then one active ammo type per ship as already designed. Owned ammo can be equipped without paying again.
- If an upgrade does not actually work on a given hull, hide it or show a clear simple ship restriction, but don't let a player buy an unusable item. Do not silently strip old already-purchased upgrades/weapon loadouts.
- When reading an M2-D/E/F save, preserve all per-ship upgrades including currently purchased above revised limits; either make caps >= old purchased max or preserve legacy tiers losslessly, without suppressing existing effects. Do not charge again or silently reset.

## B. Exact purchase explanations, affordability and next-hull purchases
- For every potential purchase show dynamic total **GOLD**, exact cost, gold shortfall if any, equipped/owned status, current rank, max rank and what changes. E.g.: "Costs 800 gold. You have 488. Need 312 more gold." "Already MAXED (3/3)." "Already own this ship — select Make Active." "Finish your current battle before shopping." "This ship has only 2 cannon ports per side — maximum already reached." "Your save changed; select again to refresh the price." The reason must exactly match server/data purchase validation, not a guessed UI message.
- For disabled/unavailable buttons, preserve hover and keyboard focus to show a compact tooltip or a small adjacent nonblocking message/side-panel reason; also show on click when appropriate. Avoid Godot disabled-button tooltip limitation: use an inspectable wrapper/details control or a separate "Why unavailable?" action rather than an unreachable disabled click. No opaque modal or duplicate hover details.
- Fix the "I have enough for the next ship but Buy won't work" flow **end to end**: Select an unowned vessel in Fleet, see gold and hull price, click Buy, review and Confirm, purchase once, add it to permanent fleet, optionally Make Active, and return to Fleet with correct balances; all other owned ships/upgrades preserved. Verify a 320-gold brig buy when player has exactly 320 and again 488; 800-gold frigate at 800; 1500-gold galleon at 1500. A ship being inspected but not owned should not require owning all lower tiers. Test via real UI clicks, not catalog functions alone.
- Ensure quote/offer in shipyard does not block navigation and that hidden Confirm is not the only way to proceed; Escape/back cancels. Save errors must be surfaced plainly. No purchases happen on hover/inspect alone or twice on repeat Confirm.
- Add explicit small banner "Purchase complete: [ship/upgrade]" or actionable reason, update all tiers/costs immediately.

## C. Better enemy navigation / stuck recovery
- Improve obstacle sensing beyond a single forward ray: multiple lookahead rays / shape casts + separation from terrain; evaluate starboard/port clearance; maintain stable avoidance direction and avoid turning toward same rock repeatedly.
- Include a simple deterministic path planner (waypoints/steering around islands) or safe local navigation integrated with finite arena layouts; do not require a fully dynamic navmesh for a few static rocks if waypoints are sufficient.
- Track displacement/time, repeated contacts, failed progress, edge proximity; when stuck, select new safe intermediate waypoint; back away intelligently; do not oscillate forever. Tests for rocks near islands, 2–3 opponents, different hull turn radii/boss special charge, narrow passages and repeated obstacles.
- Enemies must maintain actual fixed broadside weapon alignment and not phase through islands, shoot through rocks or cheat their speed. AI should still threaten the player without being pinballed by environment.

## D. Friendly map edges, no invisible wall trapping
- Replace current hard invisible boundary walls with a visually signaled **soft sea-current boundary** or a wide navigable transition zone that smoothly pushes/steers ships back toward the arena when near the edge. No repeated wall collision, no invisible instant crash damage. For the player, keep steering control; no jarring forced 180-degree rotation. For AI, set inward waypoints early.
- User offered two options: crossing edge to opposite side (screen-wrap) or automatically turning back. Prefer **soft inward current / gradual guided turn** initially, because full world-wrap complicates camera tracking, projectiles and visible islands. May optionally use seamless wrap later only if camera, shots, obstacles, spawns and enemy pursuit all wrap coherently; NEVER half-implement wrap.
- Visible outer-water cue (current arrows/waves, nautical map edge, distant fog) signals boundary approaching. Ensure camera limits/render never show a blank rectangular void after zoom-out and enemy arrows still show correct locations.
- Tests: player at edge under full throttle, enemy at edge, boss charge near edge, cannonballs near boundary, camera fullscreen and multiple resolutions; no stuck time > reasonable few seconds; no infinite looping or damage spam.

## E. Enemy health bars and correct reload indicators
- Each enemy has a world-space health meter visible near or above its sprite in combat when in range/onscreen, color/number or percent readable, updates immediately after damage, hides at zero/sinking and does not cause clutter during multi-ship fights. Highlight boss name and bigger distinctive boss-health bar; off-screen arrow may show enemy health %, but must not hide ship orientation or dominate the HUD. Don't infer health from enemy class: bind to actual health/max_health.
- Player port and starboard meters continue to read actual CannonBattery.remaining and reload_seconds. READY label must mean pressing Space **right now** will produce at least one projectile from that side in normal playable state. If not ready, show accurate seconds to next shot; bars must match countdown and not stay full during cooldown. Partial readiness of one side does not suppress the other.
- Special weapons, faster reload, changing selected ship, boss effects, and pause must not cause stale timers or invalid UI state. Holding Space never auto-fires when the counter reaches zero (fresh press required), and HUD should communicate this. Use "Space to fire when ready" if useful.
- Add automated frame-level tests: fire → consumes → bar resets → countdown progresses → READY at the same physics tick as actual can_fire; press before READY does not fire; press at READY does; reloading both sides independently; timer freezes when paused; modified gunnery and ammo stats reflect their real timing. If update order creates one-frame mismatch, fix the lifecycle/update order, not by adding fake visual delay.

## F. Upgrade-specific visual feedback + rocks/weather variety
- **Armor:** visible wood/iron plating or reinforcing bands change with rank, without hiding ship outline.
- **Additional cannons:** visible and correctly numbered gun ports/barrels on each side corresponding to actual projectile count.
- **Weapon type:** chain shot renders as distinctive two linked balls or a chain-link projectile with visible impact/rigging-slow effect; long guns and close-range cannonballs have distinct subtle colors, sizes/trails/impact effects matching actual stats and without player confusion. Cannonball appearance should not be identical for every weapon.
- **Sails/rudder:** simple rigging/sail shape details change with rank where readable at gameplay zoom; lookout platform for installed lookout; prow plating for reinforced ram; no fake art upgrades with no gameplay effect.
- Upgrade art must read **per individual ship** using saved fleet loadout, and visibly switch when changing active ships. Keep art lightweight/original/procedural and accessible at zoom 0.64–0.66.
- More island/rock sizes, silhouettes, coastline arrangements and sea color/biomes. Physical collider should match island art, safe passage and enemy escape path verified; avoid randomly blocking spawn or creating unsailable chokepoints.
- Vary visuals of **weather**: calm/windy/misty/rainy/stormy according to encounters, using original low-cost particle/shader effects and ambient sounds. Weather may provide modest fair gameplay variation later; first prioritize good readability and performance; don't obscure incoming cannonballs or health UI. Sea-shanty music and SFX remain audible; preserve volume/mute.
- Avoid flashy effects that interfere with broadside leading, enemy projectiles, offscreen arrows or purchase screens.

## G. Shipyard/UI and regression acceptance
1. Shipyard displays **all compatible upgrades** per hull, with no generic category slots; specific per-hull level and cannon caps remain. Users can eventually buy everything offered, and all purchased levels persist.
2. Every unavailable item shows **actual reason** on hover/focus/click; exact shortage stated. Unowned ships of affordable price are purchasable end-to-end; owns multiple permanent ships and can activate one without losing another.
3. Player/enemy can get away from all map edges and rocks without being trapped; island and ram damage remain fair and visible.
4. Enemy HP (including bosses and multi-ship encounters) is readable, updated on damage, and disappears when ship sinks.
5. Reload bar and actual fire permission agree at every tested frame and for both batteries under changed upgrades.
6. Armor, additional cannons and chain shot show distinguishable visual state; island and weather variety is visible on the battlefield.
7. No regressions in campaign progression, saved captain/ship, stored gold/salvage, permanent fleet, M2-F full-page map and automatic next battle, boss abilities, shanty music, Game Dock detection.
8. Open **new dependent PR from feature/broadside-m2f-voyage-harbor** (PR #15), not main; no auto merge. Test headless Godot plus native Windows exported game, 800x450/1280x720/1920x1080/2560x1440 screenshots, click-through shops, AI obstacle stress, HUD frame timing, save migration and packaging.
9. Publish new matched Windows ZIP with Broadside.exe/Broadside.pck/game.json (version e.g. 0.2.6-m2g); use existing Game Dock installer helper and leave user:// files intact. Report exactly what ran and which human checks remain.

**Prioritize:** M2-G1 purchases/caps/precise reasons + ship bug, M2-G2 AI/map boundaries + enemy HP/reload, M2-G3 visuals/weather. Finish game-breaking issues before art polish.
