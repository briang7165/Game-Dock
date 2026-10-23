# Broadside M1.4 — Battlefield View, Fullscreen, Docked HUD and Location Name
**User feedback: 2026-10-23. Approved as the next focused combat/UI refinement.**
This is a narrowly scoped usability update to the **existing** playable Godot game on [PR #4](https://github.com/briang7165/Game-Dock/pull/4), not the M2 campaign implementation. Preserve all previously approved M1.1–M1.3 combat features and balances.

## Problem observed in current source
Verified on branch feature/broadside-m1-combat:
- `games/broadside/scripts/encounter_stats.gd` defaults `camera_zoom = 0.8`, applied in `arena.gd` as `Camera2D.zoom`.
- `games/broadside/scripts/battle_hud.gd` sets a 144px bottom panel with 16px bottom and side insets inside a full-screen `Control`, so the *world behind the panel is rendered under it*. Merely changing `offset_top` or alpha would NOT solve the actual occlusion.
- `games/broadside/project.godot` defines 1280x720 viewport and `window/stretch/mode="canvas_items"`, with resizable window. There is no verified fullscreen/ultrawide-aware layout or explicit gameplay-versus-footer viewport split.
- `games/broadside/scripts/enemy_indicators.gd` locates arrows against the **entire** current `Control`, with hardcoded bottom offset: `center.y - 184.0`. That must be generalized if we reserve footer space or resize/aspect changes.
- The arena title `The Sable Channel` is currently in the **main menu text** only; there is no in-battle place-name treatment that can carry over into the Endless Odyssey campaign.

## 1. Camera framing: modest additional zoom-out
- Begin with `camera_zoom = 0.72` (was 0.80; approximately 11% more world width/height visible at same viewport size), then inspect actual frames at 1280x720, 1920x1080, 2560x1440 and an ultrawide screen if supported. Use a configurable resource; values are test presets, not immutable.
- Account for the new reduced-height *gameplay area* due to docked footer. The target is a bit more horizontal/overall battlefield awareness than M1.3; avoid undoing zoom-out by shrinking the world play area. Tune camera zoom and UI footer height *together*.
- Keep player ship visible/readable, enemy indicators, long-range cannonball leading/dodging, coastline, camera smoothing, projectile effects, and island silhouettes.
- Correct camera limits and screen-edge clamping for large and non-16:9 windows so no unwanted solid-color strips outside the ocean appear. The area displayed must be covered by the water/map art; do not make arena walls or collisions resize based on window.

## 2. Fullscreen and window resizing
- Provide a dependable **Windowed** and **Borderless Fullscreen** (or standard Fullscreen where Godot/platform requires) selector under Settings, preserving previous audio settings and keyboard/mouse menu navigation.
- Save display preference locally under Godot user://, restore on launch, and provide an easy exit/restore-windowed pathway (via Settings; optional F11 toggle if tested). Avoid trapping the user in a mis-scaled display.
- Maintain correct canvas/world position, camera center and cursor/menu interaction through window resize and mode change. No stretching ships nonuniformly or distorting the ocean; maintain stable aspect-ratio rendering or show intentional wider world on wider displays.
- On fullscreen monitors, adapt to available screen dimensions rather than treating 1280x720 as a literal physical UI rectangle. Make text/buttons/HUD safe at 1280x720, 1920x1080, 2560x1440, 800x450 when legible, and monitor-native non-16:9 sizes.
- If fullscreen is already technically supported by the Godot engine but needs no explicit toggle, still validate/responsibly expose appropriate display option and **state actual tests**. Do not claim monitor hardware validation unless performed.

## 3. Dedicated **bottom console** with zero map occlusion
**Central requirement:** Battlefield water, ships, projectiles and islands render only in the *playable region above* the footer. The health/reload console must sit in its own reserved bottom region, not float on the ocean.

Implementation should be a responsive top/bottom layout, e.g. Godot `VBoxContainer` or equivalent partition with a game-rendering `SubViewportContainer/SubViewport` in the top expandable slot and the HUD `PanelContainer` in the bottom fixed/min height slot; OR another sound approach that truly clips/restricts the arena's rendered region. Use a clean architecture and explain why chosen. Do not simply move an overlay farther down or make it transparent.
- Ocean/arena view occupies **all available area above** footer and continues to use camera follow. Footer height approximately 100–132 logical pixels (responsive and content-driven), reduced from the current 144 + insets if helpful; must not collapse the battlefield in short windows.
- HUD spans bottom width intentionally (not as a centered floating panel over water). Weathered deep-navy/wood/brass instrument panel visually separates it from game water; subtle border at top.
- **Port reload meter** left, **hull-health meter** center, **starboard reload meter** right. Accurate numeric HP, independent reload fill, READY status, critical warning and responsive scaling. Keep existing M1.2 damage flash/health-change feedback. All informational: no in-battle mouse controls.
- Give the battlefield top area a clean top-left location title (see section 4), and a low-key top-right hostile health indicator or other legible secondary enemy status, without intrusive overlays.
- Off-screen enemy arrows must be clamped to **only the gameplay region**, never the footer; prevent overlapping with title/enemy HP and each other. Distance and facing remain correct with new camera/aspect viewport.
- Hide any unwanted interactive mouse hitboxes in the battle HUD; mouse remains unused for aiming/firing.
- Fullscreen and windowed rendering should not crop ships/projectiles near the lower edge behind the footer.

## 4. Give each battle/map location a title
- First current arena location: **The Sable Channel**. Display an **illustrated nautical place-name banner**, e.g. `THE SABLE CHANNEL` with optional descriptive subtitle `Trade Winds • Rocky Islets`, for ~2–3 seconds as a battle-entry title card or neat in-scene upper-left toast, easing/fading away automatically. It should *not* obscure the ship or interfere with player input.
- Keep location name accessible from pause menu and, if subtle, small fixed map heading; do not leave a giant opaque title permanently over combat.
- Name must come from an **encounter/location data field** rather than hard-coded everywhere: `EncounterStats.location_name` and optional `location_subtitle` (or a more suitable typed location resource), with default current setting. In M2, selected destination/chart node supplies name without refactoring combat HUD.
- Later named destinations (examples for data/mockups, not yet actual unlocked content): `Reefrunner Pass`, `Widowmaker Shoals`, `Blackwater Reach`, `Stormwatch Cay`, `The Drowned Passage`. No need to build world map during this M1.4 refinement.
- Spell/readability, alpha fades, no overlapping enemy panel or new bottom HUD. Pause must freeze fading if fade occurs in gameplay and keep location name visible in pause info.

## 5. Preserve core gameplay and scope
- Preserve WASD/arrows for sailing, Space to fire the one cannon per side, automatic independent reload, Escape pause, enemy AI/telegraphs, mid-range visible cannonballs, off-screen enemy arrows, ocean music/SFX and separate audio controls.
- Preserve **M1.3 fragile sloop tuning** (currently code review indicates player/enemy 60 HP, 16 cannonball damage in PR #4), hull and ramming crash damage for both ships, and bottom HUD numbers.
- Preserve standalone Godot export and Game Dock manifest integration. No new dependencies, third-party assets, telemetry or microtransactions.
- Do not implement gold, upgrades, captain naming or endless voyage as part of this tiny battle UI pass. Those are tracked in [Issue #5](https://github.com/briang7165/Game-Dock/issues/5).

## 6. Tests and deliverables
1. Visual screenshot (ideally actual Godot captures) at **windowed 1280x720**, **fullscreen/large 1920x1080**, and 2560x1440 if environment supports it, confirming camera shows more terrain and scene remains centered.
2. Demonstrate HUD entirely below **top gameplay viewport bottom edge** (pixel/layout/geometry assertion preferable); world does not render behind bottom console.
3. Reload bars and hull text update correctly while camera moves; health bar responds to impact; win/loss/pause/resume still work.
4. Enemy arrow at bottom edge clamps above footer, including while resizing; title banner remains nonblocking.
5. Opening title shows `The Sable Channel` once when entering battle, then fades within 2–3 seconds; scene metadata available for later voyage system; pause menu can display location.
6. Windowed ↔ fullscreen ↔ windowed does not distort sprites, clip menus, misplace scene/camera, or trap pointer focus. Test actual display transition if possible; otherwise mark **manual** test required.
7. UI remains usable with WASD, arrows, Enter/Space and mouse in menus, but not in combat; test against accidental Space firing through menu transitions.
8. Report test commands, results and any unverified hardware/fullscreen aspects. Open/update PR #4 where appropriate, do not auto-merge, and ask user for hands-on visual review before proceeding to M2.

**Player-facing design:** They should look at *more ocean*, not less, and never have their combat HUD cover the playable map. Every battle should feel like arriving somewhere with its own name.
