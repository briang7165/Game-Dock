# Broadside M2-D validation — 2026-10-24

Build: `0.2.3-m2d`, branch `feature/broadside-m2d-fleet`, based on PR #10 commit `6b5123d962099c6598b597bc2ad314235010e724`. No merges. The game and launcher remain separate.

## Environment and commands

Windows x64; Godot `4.5.2.stable.official.6ce3de25a` with matching official export templates; NVIDIA GTX 1660 Ti, OpenGL 3.3 compatibility rendering, driver 457.49. Python 3.12.2 / jsonschema 4.26.0; Node 22.14.0 / npm 10.9.2 / Vite 6.4.5; Cargo 1.99.1. Test saves use isolated APPDATA directories, not the player's campaign.

```powershell
$env:APPDATA = '<isolated-test-folder>'
./games/broadside/tests/run.ps1 -Godot '<Godot 4.5.2 console exe>' -Python '<Python with jsonschema>'
./games/broadside/packaging/build-windows.ps1 -Godot '<Godot 4.5.2 console exe>' -OutputDirectory '<output-folder>'
# From launcher/:
npm run build
$env:CARGO_HOME = '<existing Cargo cache>'
cargo test --offline --manifest-path src-tauri/Cargo.toml
```

## Results

The complete source runner exited 0: import, boot, schema and **308 assertions**, all passing:

| Suite | Assertions |
|---|---:|
| Combat | 39 |
| AI soak | 7 |
| Refinement/audio controls | 50 |
| Impacts | 31 |
| Starter balance | 20 |
| Headless viewport | 43 |
| Voyage/save campaign | 17 |
| Existing shipyard/effects | 27 |
| Routes/fleets/bosses | 28 |
| New fleet/migration | 27 |
| New shipyard GUI input | 19 |

The final visual-only parchment/wood styling change was subsequently tested in native source and the actual exported executable. Both passed all 19 GUI checks.

New tests exercise permanent ownership; independent upgrades, health, names and weapons; inactive-ship purchases; switching into real ship data; class/category limits; duplicate-confirmation rejection; free re-equipping of purchased weapons; save reopening; encounter locks; rescue writeback; byte-identical legacy backup; preserved over-limit tiers and progress; early M2-A fields; conflicting archives; backup creation failure; and refusal to overwrite a future-version save using an older backup.

GUI tests use real `Input.parse_input_event` keyboard and mouse hit testing, not just emitted button signals. They cover focus descriptions/icons, Enter/Space selection, Cancel-first confirmation, Escape cancellation, WASD/arrows, mouse purchases, inactive ships, category filtering, numerical economy effects, scrolling and return to chart without starting battle.

## Actual Windows export

The package script exported the game, booted **Broadside.exe**, and verified the ZIP has exactly three root files: `Broadside.exe`, `Broadside.pck`, `game.json`. No Godot installation is required by the player.

The exported EXE was then run with the source test harnesses against its packaged game resources, using native Windows rendering (not `--headless`):

- Fleet/migration: **27/27**.
- Shipyard real GUI input: **19/19**.
- Native viewport/window/fullscreen/ultrawide: **45/45**.
- Campaign routes, real fleet combat, bosses and crew: **28/28**.
- Real-time audio: **passed**, one music loop; peak **0.3582**, RMS **0.0316**, **2,624,512** samples, no clipping threshold violation.

All these processes exited 0 without engine/script errors. Launcher TypeScript/Vite production build passed; both Rust safety tests passed offline. A manual click-through launch via the installed Game Dock UI was not performed; manifest/schema/package layout and launcher build/tests are verified.

## Screenshots

Actual exported-game PNGs, visually inspected and dimensions verified from PNG headers:

- `Broadside-M2D-yard-1280x720.png`: fleet/active header and fittings, 1280×720.
- `Broadside-M2D-comparison-1920x1080.png`: active upgraded sloop versus owned brig, scrolled comparisons, 1920×1080.
- `Broadside-M2D-upgrade-800x450.png`: confirmation panel at the minimum window size, 800×450.
- `Broadside-M2D-fullscreen.png`: native fullscreen, 2560×1440.

Delivered separately with the playable build; generated screenshots and binaries are not committed. Reproduce using the exported EXE with `--script <absolute path to tests/shipyard_capture.gd> -- <absolute PNG output> fleet|compare|upgrade [fullscreen]`. Add `--resolution 1280x720`, `1920x1080` or `800x450` before `--` for window captures. The header/footer stay visible while the fitting/gallery content scrolls. Modal estimates fit at the minimum size and block input behind them.

## Failures found and limits

Development tests caught JSON integer/float comparison assumptions in the new migration assertions, and a noisy JSON parser path when checking a corrupt primary save. Both were corrected; corruption recovery and migration tests pass. A deliberate archive-path collision now returns a controlled save error without altering the original.

Several earlier runs hit the existing intermittent Godot 4.5.2 C++ signal-11 shutdown crash, including after successful AI/refinement assertions and editor import. The runner still treats every nonzero exit and engine error as a failure; no retry or ignore was added. A later complete source run and all listed exported-native tests passed. Root cause of that intermittent engine shutdown remains unproven and is not claimed fixed.

Human long-session balancing and accessibility review are still needed. Old saves contain only the last owned hull/equipment state, so migration cannot reconstruct previously replaced hulls or unequipped weapons absent from the file; the active hull, starter and every recorded purchase are retained. See `BROADSIDE_M2D_FLEET_SHIPYARD.md` for capacity rules and rollback instructions.
