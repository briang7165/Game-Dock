# M1.4 viewport, console and location validation — 2026-10-23

Implements the approved M1.4 specification in existing PR #4. No campaign, economy, combat-stat or physics changes. The M1.3 build remains separately preserved.

## Architecture and framing

`battle_view.gd` partitions a full-size VBox into an expanding battlefield Control and a 120-logical-pixel footer. The battlefield owns a stretching SubViewportContainer/SubViewport containing the actual arena. The HUD is a sibling rendered by the root viewport, not an ocean overlay. Geometry assertions verify the two rectangles share an edge with zero intersection and that the render target matches only the battlefield. The player, islands and cannonballs cannot render beneath the meters.

At 1280x720 the battlefield is exactly 1280x600, footer 1280x120. Camera zoom 0.72 exposes about 1778 world units horizontally versus 1600 at 0.8 (11.1% more). Unobstructed height is about 833 units versus about 700 above the previous overlay (19% more). Wider aspect ratios expand logical width; uniform scaling allows only subpixel integer-viewport rounding (tested within 0.1%). Collision walls stay fixed. The original ocean brush pattern covers the camera's actual visible bounds, including water beyond walls on very wide views, avoiding blank strips without resizing the arena.

Indicators occupy the battlefield overlay, using its true size and the arena's viewport canvas transform. Their lower edge no longer has a hardcoded footer offset. Top padding reserves room for the location and secondary enemy health.

`EncounterStats` supplies location name/subtitle. The entry title eases in, holds, then fades completely at 2.8 seconds; pause freezes its clock and shows the location in pause details. `start_battle(encounter)` accepts another location resource (tested with Reefrunner Pass) without changing UI code. No voyage destinations are unlocked.

Settings retains all audio controls and adds a keyboard/mouse Fullscreen toggle; off restores Windowed. Godot's standard `MODE_FULLSCREEN` is used, with local preference in `user://display_settings.cfg`. Previous window size and position are restored on exit. The minimum window is 800x450; aspect expansion preserves framing on larger and wider displays.

## Executed tests

Windows x64; Godot **4.5.2.stable.official.6ce3de25a**, matching official Windows templates; NVIDIA GTX 1660 Ti / OpenGL 3.3.0 / driver 457.49. Python 3.12.2/jsonschema 4.26.0. Isolated workspace APPDATA prevents tests overwriting player preferences.

| Command (repository root; godot is the official console executable) | Result |
|---|---|
| `./games/broadside/tests/run.ps1 -Godot <absolute-godot> -Python <venv-python>` | Final complete run passed import, boot, 190 assertions and manifest schema |
| Existing combat / AI / M1.1 / M1.2 / M1.3 suites | 39 / 7 / 50 / 31 / 20 passed; fragile balance, physics, rams, sound settings, controls and outcomes preserved |
| `godot --headless --fixed-fps 60 --path games/broadside --script res://tests/viewport_test.gd` | 43 passed: partition, render target, aspect scaling, indicator bounds, metadata, title lifecycle/pause, display persistence, keyboard/mouse setting hit tests and no leaked firing |
| Native console-engine viewport suite | Actual fullscreen transition validated at monitor-native 2560x1440 and restored Windowed; first version 43 passed before two additional mouse assertions |
| `godot --headless --path games/broadside --export-release "Windows Desktop" <output>/Broadside.exe` | Version 0.1.4-m14 Windows x64 EXE/PCK export passed |
| Exported `Broadside.exe --fixed-fps 60 --script <source>/tests/combat_test.gd --log-file <log>` | Native OpenGL renderer: 39 passed, exit 0 |
| Exported executable with `tests/viewport_test.gd` | Native OpenGL renderer: 45 passed, exit 0, including fullscreen mode entry/exit and mouse toggle after resizing |

One earlier headless viewport run passed its assertions but crashed inside Godot at shutdown while other capture processes were active. No cause was established. An isolated repeat and the final full sequential runner exited cleanly, as did the native release tests. This initial failure is not counted as a successful run.

## Screenshot evidence

Actual rendered captures are included in the separate screenshot deliverable and Windows ZIP:

- 800x450, 1280x720, 1920x1080, 2560x1440 and 2560x1080 windowed captures: critical 12/60 HP, independent loading/ready meters, bottom enemy arrow above footer, visible entry title.
- `fullscreen.png`: actual fullscreen on the available 2560x1440 monitor.
- `settings-800x450.png`: all sound/display controls and Back fit within the smallest supported window.

Reproduce with:

```text
godot --path games/broadside --resolution 1920x1080 --script res://tests/capture.gd -- <absolute-PNG> hud
godot --path games/broadside --script res://tests/capture.gd -- <absolute-PNG> fullscreen
```

Screenshots were visually inspected for clear footer separation, readable ships/meters/title and complete ocean coverage. Ultrawide was a window/render-size test on the available monitor, not a claim of physical ultrawide-monitor hardware validation. High-DPI/multi-monitor configurations and interactive Game Dock install/Refresh/Play remain user checks. Please review framing and text size on your preferred display before the campaign phase.

Launcher verification also passed: npm run build (Node 22.14.0/npm 10.9.2/Vite 6.4.5) and cargo test --offline (Cargo 1.99.1, both Rust tests). Temporary build metadata and generated Cargo.lock were removed; launcher source is unchanged.
