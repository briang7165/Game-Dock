# M1.1 refinement — implementation and validation

User-authorized scope: [Gameplay Refinement Update](../../docs/BROADSIDE_M11_REFINEMENT.md). Continued the existing `feature/broadside-m1-combat` branch and PR #4; no merge, economy, purchases, campaign or fleets. Existing launcher code and visual construction remain unchanged.

## Initial tuning

| Parameter | M1 | M1.1 |
|---|---:|---:|
| Forward speed (world units/sec) | 180 | 165 |
| Acceleration | 95 | 42 |
| Reverse cap | 45 | 22 |
| Braking acceleration | 95 | 60 |
| Coasting resistance | 48 constant | 7 + 0.0003 × speed² |
| Full-speed turn cap (rad/sec) | 1.6 | 0.85 |
| Stationary steering fraction | 0.5 | 0.12 |
| Rudder acceleration (rad/sec²) | instantaneous | 1.35 |
| Maximum sideways drift | none | 18, with exponential water damping |
| Cannonball speed | 430 | 300 |
| Projectile lifetime | 2.0 sec | 2.9 sec |
| Approximate range | 860 | 870 |
| Enemy prefire warning | 0.7 sec | 0.9 sec |
| Camera zoom | 1.0 | 0.8 (25% more visible width/height) |

These values live in the hull/cannon/encounter Resource scripts and can be overridden in `.tres` Inspector resources. AI retains fixed broadside firing and local obstacle avoidance. Its warning now tolerates small rudder-lag changes, while rechecking cover/range and alignment at release. It does not predict or guide shots for the player.

Offscreen coral arrows read enemy positions only. They show distance, respect a HUD-safe edge inset and disappear for onscreen/dead vessels. A four-marker cap with overlap suppression prepares the display for later fleets without implementing multiple enemies.

## Offline audio

`audio_synth.gd` creates the original **Sable Channel Jig**: 16 bars of 6/8 melody, reed-like harmonics, plucked bass and percussion at 124 BPM (~23.23 seconds). Ocean/wake noise, deep cannon booms, wooden/stone impacts, splashes, sinking, menu selection and victory/defeat cues are also original synthesized PCM. No commercial soundtrack, external sample, network request, or generated binary asset is committed. Audio is prepared once at boot and reused across battles.

`data/audio.tres` exposes sample rate, tempo, individual effect gains, mix levels and fades. Separate Music/SFX buses have volume and mute controls; `user://audio_settings.cfg` persists only audio preferences. Mute preserves the slider's chosen level. Music continues smoothly through menus with lower gain, pauses duck it, wake gain follows speed, simultaneous same-kind events are coalesced per physics frame, and transient players are capped. Ordinary window/menu exit lets the audio mixer finish before tree destruction.

## Actual results

Windows x64, Godot **4.5.2.stable.official.6ce3de25a**, NVIDIA GTX 1660 Ti / OpenGL 3.3.0 / driver 457.49. Python 3.12.2 + jsonschema 4.26.0; Node 22.14.0, npm 10.9.2, Vite 6.4.5, Cargo 1.99.1. Godot ran self-contained with workspace APPDATA to keep test preferences separate from the user's real game preferences.

From repository root (`godot` denotes the absolute official console executable):

| Command | Result |
|---|---|
| `godot --headless --path games/broadside --editor --quit` | Import/parse passed |
| `godot --headless --path games/broadside --script res://tests/boot_test.gd` | Real main menu boot and orderly shutdown passed |
| `godot --headless --fixed-fps 60 --path games/broadside --script res://tests/combat_test.gd` | **41 passed**: controls, no mouse/Q/E fire, fresh press vs repeat, separate reloads, real collisions, pause, outcomes and restart |
| `godot --headless --fixed-fps 60 --path games/broadside --script res://tests/ai_test.gd` | **7 passed** over 180 simulated combat seconds plus recovery; 46 side salvos, peak 6 projectiles |
| `godot --headless --fixed-fps 60 --path games/broadside --script res://tests/refinement_test.gd` | **50 passed**: momentum, rudder lag, drift bounds, reverse, camera, medium/long-range dodge vs manual lead, indicator geometry/lifecycle, music/effects, keyboard/mouse audio settings, independent mute, persistence, pause return |
| `python games/broadside/tests/manifest_test.py` | Current `0.1.1-m11` manifest passes actual Game Dock schema |
| `./games/broadside/tests/run.ps1 -Godot <absolute-console-exe> -Python <venv-python>` | Combined import/boot/combat/AI/refinement/schema checks passed; final additions to refinement suite separately rerun |
| `godot --path games/broadside --script res://tests/audio_playback_test.gd` | **26 real seconds**, music wrapped once; nonzero mix, peak 0.3943, RMS 0.0383; no clipping/errors |
| `godot --path games/broadside --resolution 800x450 --script res://tests/capture.gd -- <absolute-PNG> settings` | Native settings render inspected, readable |
| Same capture at `1280x720` with `indicator`, and `1920x1080` combat | Native renders inspected; directional marker and wider arena visible |
| `godot --headless --path games/broadside --export-release "Windows Desktop" <absolute-output>/Broadside.exe` | Official matching templates produced Windows x64 EXE + PCK |
| Exported `Broadside.exe --fixed-fps 60 --script <absolute-source>/tests/combat_test.gd --log-file <log>` | **41 passed**, native Windows release executable, exit 0 |
| Exported `Broadside.exe --fixed-fps 60 --script <absolute-source>/tests/refinement_test.gd --log-file <log>` | **50 passed**, native Windows release executable, exit 0 |
| Exported `Broadside.exe --script <absolute-source>/tests/audio_playback_test.gd --log-file <log>` | Real 26-second release audio test passed: one wrap, peak 0.3556, RMS 0.0317, exit 0 |
| `npm run build` in `launcher` | TypeScript/Vite build passed |
| `cargo test --manifest-path src-tauri/Cargo.toml --offline` in `launcher` | Both existing Rust tests passed |

External test scripts are harnesses, excluded from the shipped PCK; they exercise exported scenes/scripts. The normal package launches directly without the harness or Godot editor. Source CI runs the headless tests, including the new refinement suite. Native mixer testing remains a separate real-time command, not a claim of human listening approval.

## Issues found and corrected

- Heavier steering initially prevented AI fire because its old prefire sequence cancelled at every small alignment change. The warning now remains latched until release, with fresh cover and alignment checks; the full AI suite then passed.
- The old turn-direction check allowed only 0.25 seconds to reverse the rudder. Updated to 0.75 seconds and added explicit lag/cap checks, rather than restoring instant turning.
- A conditional audio-note array failed typed assignment; changed to an explicitly constructed packed integer array and reran all audio paths.
- Abrupt `--quit-after` while loops are active reports engine audio playback references at shutdown. Normal close/menu exit and the supported boot/test paths now stop audio and give the real-time mixer time to release references. Final supported test runs have no such warning. Forced engine termination still bypasses that orderly shutdown.

## Remaining human checks

Play feel and subjective soundtrack/volume approval cannot be established by automated tests. Please assess turning radius, stopping distance, leading at range, enemy pressure, ship readability at 0.8 zoom and music repetition. Manual Game Dock installation/Refresh/Play and interactive window resizing are still not claimed. The schema, package basename and complete EXE/PCK convention remain compatible. No later progression systems were started.
