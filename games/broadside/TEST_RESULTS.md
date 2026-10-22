# M1 validation — 2026-10-22

Environment: native Windows x64; Godot `4.5.2.stable.official.6ce3de25a`; Compatibility renderer, OpenGL 3.3.0, NVIDIA GeForce GTX 1660 Ti / driver 457.49. Python 3.12.2 + jsonschema 4.26.0; Node 22.14.0; npm 10.9.2; Vite 6.4.5; Cargo 1.99.1 (5f94df478 2026-08-27); Git 2.49.0.windows.1.

## Successful checks

Commands below run from repository root unless otherwise stated. `godot` denotes the downloaded official `Godot_v4.5.2-stable_win64_console.exe`; Python denotes the workspace virtual environment. Godot's `_sc_` self-contained editor mode and a workspace `APPDATA` override kept test writes inside the sandbox. These are test-environment accommodations, not required player setup.

| Exact command / arguments | Result |
|---|---|
| `godot --headless --path games/broadside --editor --quit` | Imported all scenes/resources/scripts, no errors |
| `godot --headless --path games/broadside --quit-after 30` | Main menu loaded, exit 0 |
| `godot --headless --fixed-fps 60 --path games/broadside --script res://tests/combat_test.gd` | **41 checks passed**, exit 0 |
| `godot --headless --fixed-fps 60 --path games/broadside --script res://tests/ai_test.gd` | **7 checks passed**, exit 0; 180 simulated seconds plus 30 recovery; 74 broadside-side salvos; peak 6 live projectiles |
| `python games/broadside/tests/manifest_test.py` | Actual Draft 2020-12 Game Dock schema validation passed |
| `./games/broadside/tests/run.ps1 -Godot <absolute-console-exe> -Python <absolute-venv-python>` | All above succeeded through the checked-in runner |
| `godot --path games/broadside --resolution 1280x720 --script res://tests/capture.gd -- <absolute-PNG>` | Native rendered gameplay capture, no errors |
| Same capture at `--resolution 800x450` and `--resolution 1920x1080` | Both native renders succeeded; screenshots inspected |
| `godot --headless --path games/broadside --export-release "Windows Desktop" <absolute-output>/Broadside.exe` | Windows x64 release export succeeded with official matching templates |
| `Broadside.exe --quit-after 60 --log-file <absolute-log>` | Native exported program starts independently; exit 0, OpenGL initialized, no errors |
| `Broadside.exe --script <absolute-source>/tests/capture.gd --log-file <absolute-log> -- <absolute-PNG>` | External test harness loaded **exported** scenes, started combat/fired and captured native rendered output; exit 0. Test harness is not shipped in PCK |
| `Broadside.exe --fixed-fps 60 --script <absolute-source>/tests/combat_test.gd --log-file <absolute-log>` | All **41 checks also passed in the native Windows release executable**, exit 0 |
| `npm install --package-lock=false`, then `npm run build` in `launcher` | Frontend TypeScript/Vite production build passed; no launcher sources changed |
| `cargo test --manifest-path launcher/src-tauri/Cargo.toml --offline` | Both existing Rust tests passed; no failures |

Combat checks drive real input and scenes: both throttle/brake layouts, representative turns, menu focus/selection, GUI mouse hit testing, forbidden Q/E/mouse firing, fresh Space vs held/repeated Space, independently ready batteries, fixed direction despite mouse movement, automatic reload, self exclusion, projectile damage/expiry/terrain interception, ship collision, frozen hulls/AI/projectiles/reload on pause, resume without leaking menu Space into combat, sinking, both outcomes, restart health reset, and return to menu.

AI checks use actual physics/projectiles. They verify maneuvering, repeated salvos, visible prefire state, damage to the player, bounded projectiles, no firing at a rock-occluded target and escape from a direct island approach. Accelerated `--fixed-fps` simulation is **not a measured 60 FPS benchmark**.

## Failures encountered and resolved

- First editor import reported sandbox-denied writes to normal Godot editor settings folders. Reran cleanly with self-contained editor data and workspace APPDATA; no player install permissions are claimed.
- Initial `npm ci` failed because this repository has no package lock. `npm install --package-lock=false` initially encountered an EPERM creating `node_modules/@types`; after creating that directory in the workspace, install and build passed. No lockfile or launcher dependency change is included.
- System Python lacked `jsonschema`; installed the pinned validator in an isolated workspace virtual environment and reran successfully.
- Initial GUI mouse test used canvas coordinates as window pixels; headless Godot reports a 64x64 window. Corrected the test to apply the viewport transform; actual menu click now passes. No production UI workaround was required.
- Initial PowerShell export smoke log read raced the GUI executable startup. Repeated with `Start-Process -WindowStyle Hidden -Wait -PassThru`; explicit exit code 0 and log were verified.

## Still needs human acceptance

- Human keyboard playtesting for feel, balance, target visibility at distance and satisfaction. Scripted smoke tests and captures do not replace this.
- Manual resizing while playing; automated captures cover the three requested sizes, not every aspect ratio or DPI configuration.
- Installed Game Dock **Refresh → Play** with the exported package. Manifest and launcher unit tests passed, but no end-to-end GUI launcher installation is claimed.
- Final painterly asset/audio polish, economy, saves, shop, additional classes and fleets are intentionally not implemented. M2/M3 require review first.

Native executable/PCK and screenshots are local review outputs, not committed build artifacts. The PR must remain unmerged pending hands-on review.
