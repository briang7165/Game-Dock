# M1.2 validation — 2026-10-23

Implements the approved M1.2 specification in existing PR #4. No M2/M3, shop, economy, launcher changes, or replacement artwork/audio.

## Environment and results

Windows x64; Godot 4.5.2.stable.official.6ce3de25a with matching official export templates; NVIDIA GTX 1660 Ti, OpenGL 3.3.0 driver 457.49. Python 3.12.2/jsonschema 4.26.0, Node 22.14.0/npm 10.9.2, Cargo 1.99.1. Isolated workspace APPDATA kept test audio settings separate from player preferences.

From repository root, `godot` below denotes the official console executable:

| Command | Result |
|---|---|
| `./games/broadside/tests/run.ps1 -Godot <godot> -Python <venv-python>` | Full runner passed, including import, boot and manifest schema |
| `godot --headless --fixed-fps 60 --path games/broadside --script res://tests/combat_test.gd` | 39 checks passed; fresh Space fires two total projectiles, held/repeat/mouse cannot fire; pause, projectile collisions and outcomes |
| Same command with `ai_test.gd` | 7 checks passed; 180 simulated combat seconds plus 30-second recovery; 46 side salvos, peak two projectiles. Both hulls replenished during combat soak so crash damage does not truncate navigation coverage |
| Same command with `refinement_test.gd` | 50 checks passed; prior handling, camera, trajectories, indicators and audio/settings behavior |
| Same command with `m12_test.gd` | 31 checks passed: separate loadouts/capacity, independent HUD values, smooth health/critical flash/pause, actual gentle and strong rock contacts, sustained contact, rearming, two-hull ram damage, relative speed/callback symmetry, deduplication, pause, lethal rock crash and mutual sinking |
| `python games/broadside/tests/manifest_test.py` | Version 0.1.2-m12 passes actual Game Dock schema |
| `godot --path games/broadside --resolution <size> --script res://tests/capture.gd -- <absolute-png> hud` | Native renders inspected at 800x450, 1280x720, 1920x1080; critical health, one ready battery, one loading battery and enemy arrow remain readable and separate |
| `godot --headless --path games/broadside --export-release "Windows Desktop" <absolute-output>/Broadside.exe` | Windows x64 EXE/PCK export passed |
| `npm run build` in launcher | TypeScript/Vite build passed |
| `cargo test --offline` in launcher/src-tauri | Both Rust tests passed. Initial `--locked` attempt could not run because repository has no Cargo.lock; offline run generated a temporary lock, removed afterward |

The standard runner fails on script/error output as well as nonzero exit. Native export harness results are included with the downloadable package. Human gameplay balance, subjective sound approval and Game Dock's interactive install/Refresh/Play remain manual review items; no headless result is presented as human playtesting.

## Tuning and behavior

Both starting sloops explicitly equip one cannon per side. Sloop capacity is two per side for later reviewed upgrades; loadout validation preserves reload progress and does not alter another ship's equipment. The current drawn muzzle loop and projectile loop read the same equipped gun count.

The bottom Control/Container HUD has independent battery meters, READY or countdown/percentage text, animated numeric hull health, damage highlight and an explicit critical warning at 25% HP. Enemy health remains secondary at the top; directional arrows reserve space above the HUD. HUD controls ignore mouse/focus input.

Crash damage uses normal closing speed: threshold 35 units/s, 0.22 HP per excess unit/s, maximum 32 HP. Shared unordered contact pairs require 0.75 seconds cooldown AND 0.12 seconds genuine separation before rearming, with a three-unit contact margin. Ship rams snapshot both velocities before resolution and damage both once. Rock and solid arena-bound impacts share terrain rules. Both sinking animations run on a lethal ram, with one defeat result if both hulls sink.

Please play the new build and review HUD readability, single-cannon duel pacing, rock crash severity and ramming tradeoffs before any later milestone.
