# Codex Production Assignment — Broadside Endless Odyssey + Game Dock Distribution

**Owner approved full campaign development: 2026-10-23.** This is a single master task that delegates implementation across reviewable milestones, not a request for a giant untested change.

## Codebase and approved design
Repository: `briang7165/Game-Dock`.
- **M1.4 combat pull request**: https://github.com/briang7165/Game-Dock/pull/4 (currently open; Godot and Windows tests passed; user approves existing gameplay).
- **Endless Odyssey spec**: `docs/BROADSIDE_ENDLESS_ODYSSEY.md`.
- **All existing game controls / balance / artwork**: `docs/BROADSIDE_DESIGN_DRAFT.md`, `docs/BROADSIDE_M12_FEEDBACK.md`, `docs/BROADSIDE_M14_VIEWPORT_HUD_LOCATION.md`.
- **Agent engineering guardrails**: `AGENTS.md` and `docs/CODEX_BROADSIDE_BUILD.md`.
- **Game Dock manifest**: `specs/game-manifest.schema.json` and `docs/ARCHITECTURE.md`.
- **User install instructions**: `docs/BROADSIDE_INSTALL_IN_GAME_DOCK.md`.
- **Implementation trackers**: Issue #5 (campaign), Issue #6 (playable Windows export packaging).

## The product to deliver
A standalone **Broadside** pirate adventure for Windows. Captain chooses their own name and ship name, commands one ship (WASD/arrows), fires side-mounted cannons with Space (automatic independent reloads), and pauses with Escape. Mouse is **menus only**, never aim/firing. Begin with a **fragile 60-HP sloop with exactly one cannon on each side**; early fights are quick and risky, later upgrades substantially transform survival and damage without becoming endless HP sponge fights. Keep user-approved sailor-like inertia, cannon leading/dodging, island and collision damage, zoomed-out ocean, dedicated bottom HUD and location titles, offscreen enemy arrows, original nautical music/effects.

Build the **Endless Odyssey campaign**:
- New Game / Continue: ship/captain naming (with safe defaults), pennant customization and versioned local save.
- Chart of the Seas: illustrated parchment map showing next stops and risk/reward, 3–6 second skippable sailing transition *between self-contained battles*; chapter bosses and indefinitely continuing stages; deterministic/generated encounters within safe and fair limits.
- Rewards / dock: earn gold/salvage, repair, choose meaningful upgrades and save for purchasable visually unique sloop/brig/frigate/galleon ships.
- Diverse upgrades: cannon quantity, range vs reload tradeoffs, reload training, sails, rudder, lookout, reinforced prow/collision effect, carpenter, cargo/salvage, armor with movement cost and small specialist crew perks.
- Encounter variety: distinct enemy roles, rock/reef battlefields, themed destinations and route types; clear first chapters and increasing variety, not just multiplier health.
- Game menus keyboard+mouse, combat keyboard-only. Player cannot get economically stranded after losing.
- No subscriptions, accounts, licensed commercial media, telemetry or network dependency. User's campaign data persists in Godot `user://`, **not** beside the EXE or inside Game Dock.

## Stage plan (continue implementing approved phases without re-asking design permission)
1. **Close out M1.4 baseline**, verify compatibility with main, and submit current PR #4 for owner's merge review; DO NOT auto-merge. If user hasn't merged it, do not overwrite main or lose feature work. A dependent feature branch with explicit PR dependencies is acceptable.
2. **M2-A: identity + campaign + sea chart + between-battle transitions**. Playable, persisted, with tests and screenshots in a standalone PR.
3. **M2-B: shipyard + meaningful upgrades + hull classes + economy**. Persistent purchases and visible class differences; tests verify cannon counts, shop safeguards and saved states. Separate PR.
4. **M2-C: voyage depth**: branching route selection, themed stops, boss encounters, multi-enemy encounters/roles, crew/ship cosmetics and journal. Separate PR.
5. **Packaging (Issue #6) — prioritize early and maintain throughout**: Publish an actually playable versioned Windows x64 ZIP containing matched `Broadside.exe`, `Broadside.pck` and `game.json`. Set up official Godot export-template install and a standalone Broadside artifact in GitHub Actions (distinct from `game-dock-windows-setup`). Provide tested install/upgrade steps into **My Library → Open games folder → broadside → Refresh → Play**; optional easy-install helper. No Godot editor needed on the player's PC once Windows ZIP is available.
6. **M3 polish**: original painterly visuals, distinct ships/islands, nautical UI/map, sound mixing, performance, difficulty and Windows release-quality packaging.

## Acceptance at each stage
- Existing keyboard controls, pause, fixed broadsides/auto-reload and no-mouse-combat remain correct.
- Godot headless import, runtime tests and schema validation pass; include exact versions/commands and failure history.
- Actual screenshots/windowed + fullscreen checks and real exported Windows execution whenever environment permits, with manual player validation gaps clearly labeled.
- No broken Game Dock launcher, unchanged manifest security checks and stable standalone package.
- Do not replace this with mock screens or claim completion without implemented code.
- Create code review PR(s) with commit/release notes, test logs, and binary download instructions. **Do not merge automatically**, but do not interrupt work for already-approved design features if a staged/dependent branch allows continued progress safely.
- Once packaging exists, provide the user a straightforward **exact artifact download path** in the run and a simple game folder copy/refresh/play workflow. Never confuse the launcher installer with the game ZIP.

## Final deliverable
A full playable and tested Broadside Endless Odyssey game, saved campaign, compelling shipyard progression, distinct enemy/route encounters, and a standalone Windows ZIP that the owner can put in Game Dock and launch from its taskbar-pinned icon. Report shipped features, unshipped features, actual testing and precise install/update instructions.
