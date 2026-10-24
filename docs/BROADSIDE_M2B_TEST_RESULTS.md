# M2-B shipyard verification — 2026-10-23

Depends on M2-A PR #8. Adds persistent gold/salvage, paid repairs, free defeat recovery, four hulls with distinct silhouettes/colliders/handling/gunports, nine ranked upgrades, and standard/long/carronade weapon tradeoffs. Purchase estimates do not mutate state; confirmation revalidates price and availability. Equipment follows the captain when changing hulls.

Godot 4.5.2 official Windows x64; Python 3.12 / jsonschema 4.26.0.

- `tests/run.ps1 -Godot <console.exe> -Python <python.exe>`: import, boot, schema and **234 assertions passed** (207 previous + 27 shipyard).
- `packaging/build-windows.ps1 -Godot <console.exe> -OutputDirectory <output>`: release export, actual EXE boot and exact three-file ZIP validation passed.
- Actual exported EXE with native rendering, `--script <absolute shipyard_test.gd>`: **27 passed**, normal exit.
- Actual exported shipyard capture at 1280x720 inspected: scrolling inventory, prices, identity, hull health and navigation all visible.

The first disk round-trip assertion compared dictionaries containing JSON floats with native integers; changed it to check persisted hull, weapon, gold and upgrade ranks explicitly. No product defect was hidden by the correction.

Package: `Broadside-windows-x64-0.2.1-m2b.zip`. Same install/upgrade process as M2-A; version-1 M2-A saves default missing salvage/weapon fields safely. Human pacing/balance review remains outstanding. Branching routes, enemy groups and crew follow in M2-C.
