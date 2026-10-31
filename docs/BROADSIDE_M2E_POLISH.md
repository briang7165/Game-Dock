# Broadside M2-E: Harbor Clarity, Smart Repairs, Enemy Bosses & Sea-Shanty Audio

**User direction: October 30, 2026.** Parent PR: #11, branch feature/broadside-m2d-fleet. Do not start solely from main; stacked M2 campaign PRs are still open. Preserve M2-D's per-ship upgrades, ship naming, migration and installed Game Dock workflow.

## 1. Remove duplicate upgrade-detail overlay (highest priority)

Source inspection: games/broadside/scripts/shipyard_ui.gd creates upgrade cards with BOTH native long tooltip_text = estimate_text(...) and its own detail box updated by mouse_entered/focus_entered. On click, inspect() reparents the existing detail panel into a modal with a nearly opaque full-screen background (alpha 0.9), and 720px minimum width. This likely causes the confusing dark/red-looking overlay, duplicate verbose text, and layout jumping.

Replace this with exactly ONE consistent, permanent upgrade-details area, either docked beside the upgrades or beneath cards on narrow screens. No moving existing nodes to an overlay. No giant native tooltip repeating the same text. One short hover/focus summary and selected detail panel; a click arms a purchase within the SAME detail area, showing Confirm Purchase and Cancel, with no second pop-up. Purchase remains a separate deliberate action and must revalidate gold, selected ship, save revision, equipment slots and tier. Esc cancels pending purchase; hovering other cards cannot accidentally change the pending quote. Accessible by mouse and keyboard. Keep original icons and ship portraits. No sudden scroll-to-top or focus jumps when switching tabs, inspecting items, repairing, confirming or canceling.

Use short names and one-sentence explanations, then a small “What changes?” line and price; offer optional more detailed current→next stats rather than always displaying 10 lines of numbers. Unaffordable/maxed/locked items remain inspectable, with a simple explanation of why unavailable. Never overlap text or cover the selected ship; no unreadable red on dark/cream. Reflow responsive layout rather than forcing three columns with existing minimum widths 235 + 355 + 535 at 800×450. Verify at 800×450, 1280×720, 1920×1080, 2560×1440 and fullscreen. No combat mouse changes.

## 2. Write upgrade descriptions for a 12-year-old

Every upgrade and weapon gets a short plain-language primary explanation of what it does. Avoid leading with sailor jargon, difficult abbreviations, formula dumps or raw percentages.

Examples (keep numeric effects accurate to actual game code):
- Carronades (Close-Range Cannons): “Hit much harder when an enemy is close, but cannot shoot as far.”
- Long Guns: “Shoot at ships farther away. Your crew takes longer to reload.”
- Chain Shot: “Two cannonballs joined by a chain. They slow down an enemy ship for a little while but hurt its hull less.”
- Extra Cannons: “Adds another cannon on each side, so pressing Space fires more shots.”
- Gunnery Training: “Your crew loads the cannons faster.”
- Fine Sails: “Helps your ship speed up and sail faster.”
- Balanced Rudder: “Makes your ship turn more easily so you can line up cannon shots.”
- Lookout: “Lets you spot ships farther away and see more ocean.”
- Reinforced Prow: “The front of your ship becomes stronger for ramming enemies.”
- Carpenter: “Your ship's repair expert fixes a little damage after you win.”
- Salvage Hold: “Bring back more gold and treasure from battles.”
- Hull Plating: “Helps you survive more hits, but makes your ship heavier and slower.”
- Repair: “Fix your ship before the next fight. You can save your money and sail with damage if you want.”

Always show a small accurate before/after impact or drawback, plus tier and cost. Show weapon tradeoffs in kid-friendly language. Do not claim an effect the code doesn't implement.

## 3. Repair FIRST: permanently visible at the harbor top

The header in shipyard_ui.gd currently shows active ship stats, while “Repair hull” appears only in the Defense & Repairs category. Move primary repair into a fixed, always-visible **top status/repair bar** immediately below the active ship/captain header and ABOVE all scrolling upgrade content.

Show active ship name, actual HP / maximum HP, a health bar, missing HP, total repair price and gold balance. Primary button “Repair Active Ship — X Gold” (or “Hull Ready” if full). If no money, tell player clearly and allow leaving damaged. Add “Sail Without Repairs” / “Keep Damage” as an explicit, honest choice. Repair should be the suggested default after battle but **never auto-spend gold** or auto-repair just because the player opens the harbor. Repair confirmation uses the same clean in-place checkout, no dark modal. When active ship changes, pinned repair status changes to that new active ship; selecting/inspecting a different ship must NOT silently change which one repairs.

Retain optional “Repair Selected Owned Ship” action in selected ship's separate fleet detail if useful; label it distinctly to avoid mistaken purchases. The pinned bar never scrolls away when changing categories or scrolling upgrade inventory. Preserve defeat recovery/no-softlock economic rules, repair quotes and save backups.

## 4. Zoom out more, especially menus — without tiny text

Battle camera default now about 0.72; test 0.64–0.66 as a new configurable starting point. Preserve readable projectiles/ships, camera bounds, ocean coverage, off-screen arrows, clipping above the separate bottom HUD, proper broadside timing and no distant unseen sniper shots.

For shipyard, voyage map and menu: scene Camera2D zoom will NOT fix GUI crowding. Improve space use and responsive scaling: reduce needless empty areas, support wider menu layout, balanced scroll regions, a stable header, readable short labels, and no oversized stacked panels. Optional UI density scale only if still readable; maintain sensible fonts and nonoverlapping hit targets in windowed/fullscreen.

## 5. Enemy movement diversity and REAL boss specialty moves

Existing games/broadside/scripts/voyage_director.gd gives the bosses names, but maps boss roles back to ordinary raider/hunter/heavy patterns in configure(). Fix by keeping unique boss role identity and implementing proper, tunable, modular tactics in enemy_ship.gd (or tactics/ability components).

- Raider: fast circling/flanking, briefly closes for a volley then disengages.
- Hunter: prefers long-distance positioning and leads the player's movement within fair limits; backs away from close danger.
- Heavy: slow, sturdy, sets up deliberate powerful broadsides; holds a firing zone rather than always chasing.
- Tidewarden boss: clearly telegraphed **Double Volley**, two spaced cannon attacks with a notable cooldown.
- Ashwake Corsair boss: telegraphed **Rigging Breaker**, chain shot briefly slows player movement/turning on a successful hit, with visible status countdown.
- Storm Regent boss: telegraphed **Squall Charge**, short straight-line speed/turn maneuver before a strong broadside; no teleport or undodgeable map-wide attack.

Separate behavior phases, obvious warning effects and original cue sounds, cooldowns and real vulnerabilities, no unfair instant hits or shots through island cover, no off-screen untelegraphed sniping, no giant HP sponge. Player still moves WASD/arrows, Space to fire, automatic reload, Esc pause, no mouse in combat. Add scripted tests of each role/ability; human balance review remains separate.

## 6. Fun original classic sea-shanty music

Current games/broadside/scripts/audio_synth.gd produces only a synthesized “Sable Channel Jig” through one repeating audio stream. Make the atmosphere more like a lively, singable **original** pirate sea shanty, without reproducing any existing copyrighted recording/melody.

Compose one or a few catchy original instrumental tunes/arrangements: concertina/accordion-like melody, fiddle or whistle responses, plucked bass, stomps/handclaps/wooden drum pulse, and a swinging 6/8 nautical rhythm (or steady march). Harbor/map is warm, cheerful and calmer; battle is bolder/energetic; bosses get dramatic rhythmic variation. Reuse the same original theme across variants if practical. Seamless looping and crossfades, no clipping/pops, low CPU, SFX audible above music. Preserve independent volume/mute settings and gameplay effects. Do not promise musical quality based only on automated audio sample checks; provide listening feedback/testing and iterate.

## 7. Delivery priorities and tests

Implement as M2-E in at least two logical reviewed increments (one PR with separately testable commits acceptable if clean):
- M2-E1: repair-first fixed top bar, stable shipyard details, tooltip/modal elimination, plain explanations, responsive menu; preserve fleet save migration, quote confirmation, no double billing.
- M2-E2: wider battle camera/menu polish, varied enemy behavior, named boss special attacks, original shanty-style soundtrack.

Mandatory tests: one visible description only on hover/focus/click, no reparented modal, no text overlap on multiple resolutions; pinned top repairs do not move when scrolling/tab switching; active vs inspected repair correctness; confirm/cancel charged at most once; old campaign save fully preserved; unique bosses actually use their signature moves with sound/visual telegraph/cooldown; no offscreen firing cheat; projectiles and existing game remain playable; music looping/mute/crossfades, test logs and screenshots. Include a simple description of how audio was auditioned or why listening remains manual.

Build and publish a new standalone playable Broadside Windows ZIP containing **Broadside.exe + Broadside.pck + game.json** via existing workflow, with version updated, and verify it can replace Game Dock's current game files without deleting user://campaign.json. Separate installer from game. No automatic PR merge; base a new PR on the latest M2-D branch PR #11 to preserve the work, and report dependencies. Existing PR stack #4→#7→#8→#9→#10→#11 is currently not merged. Avoid extensive unrelated refactors.
