# Broadside — Endless Odyssey

Standalone, offline Godot 4.5.2 pirate adventure for Windows x64. The campaign is implemented in dependent review PRs; no automatic merges. No accounts, plugins, paid media or network connection are required to play.

## Play without Godot

Download the **broadside-windows-x64** artifact from a successful **Broadside playable Windows ZIP** Actions run. Extract the artifact wrapper, then the versioned Broadside ZIP. Keep `Broadside.exe`, `Broadside.pck`, and `game.json` together. Double-click Broadside.exe, or use Game Dock **My Library → Open games folder → broadside → Refresh → Play**. [Install and upgrade instructions](../../docs/BROADSIDE_INSTALL_IN_GAME_DOCK.md).

Choose **New voyage** for captain/ship naming and pennant color, or **Continue voyage** to resume. Blank names use fictional defaults. **Set sail — practice** preserves the approved Sable Channel duel separately from the campaign.

| Action | Controls |
|---|---|
| Throttle / brake and reverse | W/S or Up/Down |
| Turn | A/D or Left/Right |
| Fire both loaded broadsides | Fresh Space press |
| Reload | Automatic, independent per side |
| Pause | Escape |
| Menus | WASD/arrows, Enter/Space; mouse also supported |
| Name entry | Type normally; Tab switches fields |
| Skip four-second sailing | Enter/Space/Escape |

No mouse combat or aiming. Turn the hull to align fixed port/starboard guns. Start at **60 HP, one gun per side, 16-damage shot**. Gold muzzle warnings precede enemy fire. Momentum, rudder response, rock/ship collision damage, music/SFX, 0.72 camera and the separate bottom HUD remain from M1.4.

## Voyage and shipyard

Five destinations form each chapter; the fifth is a flagship. Chapters continue indefinitely with capped difficulty, three rotating bosses, four sea themes and safe deterministic reef templates. Trade Winds offers safer duels, Reef Passage adds hazards/salvage, and Blackwater offers elite groups and better gold. Campaign enemies must be onscreen to begin a volley. Sink every hostile to win.

Lantern Harbor sells sloop, brig, frigate and galleon hulls with different silhouettes, mast arrangements, colliders, handling and gun capacities. Purchases preview price and stat changes before confirmation. Upgrade cannons, gunners, sails, rudder, lookout, prow, carpenter, cargo and armor. Armor costs speed/turning. Long guns, carronades and chain shot offer range/reload/damage tradeoffs. Chain shot slows rigging temporarily; no extra combat buttons.

After three victories, appoint one specialist: gunner, navigator, carpenter or quartermaster. Appointments are free between encounters. The journal retains summary counters, earned titles and the eight most recent results. Pennants remain editable in Captain's papers.

Victories pay gold and salvage; repairs cost gold, and salvage can be traded. Defeat retains purchases and identity, provides a free seaworthy refit plus salvage, and unlocks safer routes. No permanent economic lockout. Exiting during battle resumes the same encounter from its starting state; it does not save every projectile or grant unfinished rewards.

## Saves and settings

Versioned campaign JSON lives in Godot `user://campaign.json`, with a safe `.bak` backup and temporary replacement file. On Windows this custom user directory is normally `%APPDATA%/Broadside`, outside the installation. Unsupported/corrupt saves are preserved; a valid backup can recover the previous safe state. M2-A/B saves remain readable with defaults for later fields. Replacing a voyage requires confirmation.

Audio sliders/mute and fullscreen/windowed settings have separate persisted files. Window minimum 800×450, logical canvas 1280×720, aspect expansion for wide windows. Battlefield is a clipped subviewport above a reserved 120-unit HUD; meters never cover world pixels.

## Architecture and tests

- `campaign.gd`: identity, chart/travel, harbor and result flow.
- `campaign_save.gd`: validation, atomic saves, idempotent rewards and recovery.
- `shipyard.gd`: bounded catalog, purchase previews/transactions and real loadouts.
- `voyage_director.gd`: deterministic routes, capped encounter roles, themes and bosses.
- `ship_base.gd`, `arena.gd`, `enemy_ship.gd`: original sailing/combat extended for purchased hulls and enemy groups.
- `impact_tracker.gd`: contact-pair cooldown plus separation; `audio.gd`/`audio_synth.gd`: existing original synthesis.

Run from repository root:

```powershell
python -m pip install jsonschema==4.26.0
./games/broadside/tests/run.ps1 -Godot 'C:/Tools/Godot/Godot_v4.5.2-stable_win64_console.exe'
```

The runner checks import, boot, combat, AI soak, refinements, impacts, balance, viewport, campaign, shipyard, odyssey and manifest; any engine error or nonzero exit fails. Optional native tests: `tests/audio_playback_test.gd`, `tests/viewport_test.gd`; screenshots: `tests/campaign_capture.gd` with output path and chart/harbor/fleet/boss mode. Use isolated APPDATA for test saves. See the M2-A/B/C test reports in `docs/` for evidence and limits; scripted checks do not establish average human battle duration.

## Build

Install official Godot **4.5.2 stable** and matching export templates. Run:

```powershell
./games/broadside/packaging/build-windows.ps1 -Godot 'C:/Tools/Godot/Godot_v4.5.2-stable_win64_console.exe' -OutputDirectory 'C:/Builds/Broadside'
```

The script exports Windows x64, boots the exported executable, validates the manifest and packages exactly three root files. GitHub Actions performs the same independent Broadside build with checksum-pinned official downloads. It does not build the Game Dock installer. Generated binaries/caches are not committed. The package is unsigned.

All illustrations and music/effects are original code-generated work; no external media were downloaded. Human review of pacing, balance and long-session play remains necessary before calling this a final release.

## M2-D fleet management

The harbor now retains one independently named/equipped vessel of each class. Buy without replacing your active ship, inspect comparisons, upgrade inactive vessels and switch freely outside encounters. Original portraits reuse the battle renderer. See [fleet rules and safe save migration](../../docs/BROADSIDE_M2D_FLEET_SHIPYARD.md) and [M2-D test results](../../docs/BROADSIDE_M2D_TEST_RESULTS.md). The runner also includes fleet/migration and real GUI input suites.
