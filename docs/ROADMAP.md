# Game Dock roadmap

## v0.1 — Launcher foundation
- [x] Repository structure and game manifest v1
- [x] React library, overview and settings screen source
- [x] Rust game discovery, executable validation and launch commands
- [x] Manual Harbor Test build/install script
- [x] GitHub Actions Windows build workflow
- [ ] Verify CI compilation and installer artifact
- [ ] Verify desktop application on Windows
- [ ] Launch Harbor Test end-to-end on user's PC
- [ ] Test portable zip versus NSIS installer

## v0.2 — Practical library
- [ ] Controlled install and uninstall with explicit confirmation
- [ ] Locally imported game support
- [ ] Game artwork and descriptions with caching
- [ ] Game-specific settings and launch diagnostics

## v0.3 — Distribution
- [ ] Verified GitHub release downloads and safe staging
- [ ] Integrity checks, backup and rollback
- [ ] Update notifications with opt-in downloads
- [ ] Launcher-only, complete bundle, standalone game packaging

## Broadside (separate game project)
- [ ] Standalone playable Godot ship combat prototype
- [ ] Weapon/hull handling, AI enemy, win/lose loop
- [ ] Damage, upgrades, save files, progressive levels
