# M1.3 fragile-sloop balance — 2026-10-23

This focused update completes the next automated-validation step for PR #4 under the approved Endless Odyssey specification and Issue #5. The campaign is not started: M2-A requires the existing combat PR to be reviewed and merged by the user. M1.3 balance still requires player review.

## Preset and rationale

| Value | M1.2 | M1.3 test preset |
|---|---:|---:|
| Player and enemy starting HP | 100 | 60 |
| Player and enemy cannonball damage | 12 | 16 |
| Clean cannonball hits to sink | 9 | 4 |
| Guns per side | 1 | 1 |
| Independent reload | 3 s | 3 s |
| AI warning before firing | 0.9 s | 0.9 s |
| Crash damage per excess normal-speed unit | 0.22 | 0.12 |
| Maximum damage per genuine impact | 32 | 18 |

Hull and separate player/enemy cannon resources explicitly hold the new preset. The existing ship handling, AI alignment/obstacle behavior, 300-unit/s projectiles, range, camera, artwork and audio are unchanged. Keeping the AI's same one-gun loadout, health, damage, warning and reload avoids an asymmetric starting duel. A full-speed 165-unit/s perpendicular terrain impact costs at most 15.6 HP before movement drag; an extreme head-on ram caps at 18 HP per ship (30% of a fresh hull). Minor touches remain harmless, and contact still needs both cooldown and separation before another damage event.

## Executed source checks

Windows x64; Godot **4.5.2.stable.official.6ce3de25a**, matching official export templates, NVIDIA GTX 1660 Ti / OpenGL 3.3.0 / driver 457.49. Python 3.12.2 with jsonschema 4.26.0. Tests use isolated workspace APPDATA.

From repository root:

```powershell
./games/broadside/tests/run.ps1 -Godot <absolute-Godot-console.exe> -Python <absolute-venv-python.exe>
```

Passed import, real main-scene boot, 39 combat checks, 7 AI checks, 50 M1.1 checks, 31 M1.2 checks, 20 new balance checks, and manifest schema validation for 0.1.3-m13. No script errors or failed assertions in the final run. The AI soak still fires 46 side salvos with peak two projectiles over 180 simulated combat seconds, followed by obstacle recovery.

The new suite can also run independently:

```text
godot --headless --fixed-fps 60 --path games/broadside --script res://tests/balance_test.gd
```

Both directions use actual cannonball collisions against a stationary target 300 units away. Observed HP after hits is **44, 28, 12, 0**, with the correct victory/defeat result. The fourth hit is observed by **11.0 simulated seconds** in this deliberately perfect-alignment firing scenario. This is mechanical lethality evidence, not the duration of a normal maneuvering duel.

A separate live-AI observation with an idle, non-firing player resolves in **75.30 simulated seconds**: player 0 HP, enemy 56.73 HP. This includes real AI navigation, projectiles and collision damage; it is one deterministic passive-player observation, not a human-playtest average. The requested 45–90 second ordinary-player target remains unverified until hands-on review.

Existing regression coverage confirms gentle rock approaches survive, significant crashes and rams damage appropriately, sustained rock/ship contact cannot farm damage, separation rearms collisions, duplicate callbacks deduplicate, both ships can sink safely, and pause/restart/keyboard-only combat/HUD/audio settings still work.

## Native Windows and packaging

```text
godot --path games/broadside --resolution 1280x720 --script res://tests/capture.gd -- <absolute-preview.png> hud
godot --headless --path games/broadside --export-release "Windows Desktop" <absolute-output>/Broadside.exe
Broadside.exe --fixed-fps 60 --script <absolute-source>/tests/balance_test.gd --log-file <absolute-log>
Broadside.exe --fixed-fps 60 --script <absolute-source>/tests/m12_test.gd --log-file <absolute-log>
```

Native 1280x720 capture inspected: enemy 60/60 HP, player 12/60 HP with critical warning, separate ready/loading meters and offscreen arrow clear of HUD. Window layout code is unchanged from the three-resolution M1.2 inspection. The new version exports separately from the preserved M1.2 build. Package includes Broadside.exe, Broadside.pck and game.json; external test harnesses are excluded from the PCK.

See the accompanying native test logs for release-executable results. Game Dock schema/basename conventions are verified; interactive install/Refresh/Play and subjective gameplay/audio approval remain manual checks. No launcher changes or save migration are introduced.

Final release validation: exported Broadside.exe ran with the native renderer; balance_test.gd passed 20/20 and m12_test.gd passed 31/31, both exit 0. A separate headless release balance run also passed 20/20. Launcher npm run build passed (Node 22.14.0/npm 10.9.2/Vite 6.4.5), and cargo test --offline passed both existing Rust tests (Cargo 1.99.1). Temporary launcher build metadata/lock files were removed; launcher source is unchanged.
