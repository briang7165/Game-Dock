# Broadside — M1.1 combat refinement

A standalone, offline Godot **4.5.2 stable** 2D game. Open `project.godot` in that version and press **F6 on Main.tscn or F5**. Choose **Set sail**. No plugins, accounts, external art, or Game Dock installation are needed. This is a playable combat prototype awaiting human review, not the final art pass.

M1.1 follows the [user's refinement brief](../../docs/BROADSIDE_M11_REFINEMENT.md): heavier momentum/rudder response, slower readable cannonballs, wider camera, offscreen hostile arrows, and original offline music/SFX. The existing combat, scene structure and controls remain. [M1.1 validation and tuning notes](M11_TEST_RESULTS.md) supersede M1's baseline results for this update.

## Play

| Action | Controls |
|---|---|
| Accelerate | W / Up |
| Brake, then light reverse | S / Down |
| Turn left / right | A D / Left Right |
| Fire every currently loaded broadside | Fresh Space press |
| Reload | Automatic, separately for port and starboard |
| Pause / resume | Escape |
| Menu focus | WASD / arrows, or mouse hover |
| Select | Enter / Space / mouse click |
| Results → main menu | Escape |

Your teal pennant identifies your sloop; the enemy has a red pennant. Turn your **side** toward the enemy: cannon ports fire perpendicular to the bow. Holding Space never fires successive salvos. Q/E and mouse movement/clicks do nothing in combat. A gold muzzle glow warns that the enemy is about to fire. Rocks block ships and shots. Sink the enemy to win; restart from either result. There is no economy, repair, class shop, or campaign persistence in M1.

Carry momentum through turns and brake early. At 400 world units, cannonballs now take about 1.33 seconds to arrive: aim ahead of a moving ship by turning/positioning your hull. Coral edge arrows show offscreen enemies and distance; they disappear when the enemy enters view or sinks. No tracking shots or aiming assist are added.

**Settings**, available from the main and pause menus, provides separate Music and Sound Effects sliders plus mute switches. W/S or Up/Down moves focus; A/D or Left/Right adjusts a slider; Enter/Space toggles switches; mouse clicks/drags work too. Escape returns to the previous menu and preserves pause. Preferences live in `user://audio_settings.cfg`. The continuous music mix fades down in menus/pause, and wake volume responds to ship speed.

## Structure and tuning

- `Main.tscn` / `main.gd`: focused menu, HUD, pause and scene lifecycle. Combat is a pausable subtree; menus always process.
- `Arena.tscn`: safe spawns, three rocky islands, solid boundaries, smooth player camera, battle result and short sinking animation.
- Player/EnemyShip scenes inherit `BroadsideShip`: capsule hull, arcade acceleration/drag and turn rate; enemy controls only its own throttle/heading.
- `CannonBattery`: independent reload clocks and visible muzzle locations. `Cannonball`: fixed swept trajectory, source exclusion, finite life, terrain interception.
- `data/sloop.tres`, `cannons.tres`, `encounter.tres`: editable Godot resources for HP, acceleration, speed, turn, guns, spread, damage, bullet speed/lifetime, AI range, throttle and telegraph. Runtime state is per-instance, never stored in shared resources. These are extension points for later reviewed hull classes, not M2 implementations.
- Physics layers: 1 terrain; 2 ships. Projectiles sweep both layers and exclude their source RID to prevent self-hit/tunnelling.
- `hull_stats.gd`: acceleration, braking, coasting drag, water resistance, turn cap/rudder acceleration, stationary steering and bounded lateral drift. `encounter_stats.gd`: camera zoom, AI warning time and longer obstacle lookahead for the heavier hull.
- `audio.gd` / `audio_synth.gd`: original PCM synthesis once at boot; persistent Music/SFX buses, capped transient voices, independent volume/mute and orderly mixer shutdown. `data/audio.tres` exposes tempo, gains and fade time. `enemy_indicators.gd` only reads ship positions; it cannot steer or aim weapons.
- AI uses broadside alignment, terrain line-of-sight, forward obstacle probes and reverse/turn recovery. This is local steering rather than a general path planner.

## Tests

From repository root, with Godot 4.5.2 and Python 3.12 available:

```powershell
python -m pip install jsonschema==4.26.0
./games/broadside/tests/run.ps1 -Godot 'C:/Tools/Godot/Godot_v4.5.2-stable_win64_console.exe'
```

Or run individually:

```text
godot --headless --path games/broadside --editor --quit
godot --headless --path games/broadside --script res://tests/boot_test.gd
godot --headless --fixed-fps 60 --path games/broadside --script res://tests/combat_test.gd
godot --headless --fixed-fps 60 --path games/broadside --script res://tests/ai_test.gd
godot --headless --fixed-fps 60 --path games/broadside --script res://tests/refinement_test.gd
python games/broadside/tests/manifest_test.py
```

The AI suite simulates 180 seconds of combat plus 30 seconds of obstacle recovery. It does not certify human play feel or hardware FPS. `tests/run.ps1` fails on nonzero exit **or** Godot script/error output. A dedicated Windows CI workflow runs the same checks. For optional real renderer screenshots:

The optional native audio check takes 26 real seconds (no `--fixed-fps`): `godot --path games/broadside --script res://tests/audio_playback_test.gd`. It measures a music wrap, nonzero mixed audio and peak below clipping, including every effect. It does not claim subjective listening approval.

```text
godot --path games/broadside --resolution 1280x720 --script res://tests/capture.gd -- C:/Temp/broadside.png
```

Use 800x450 and 1920x1080 as additional capture sizes. See [actual test evidence](TEST_RESULTS.md) for results and remaining manual checks.

## Windows standalone export

1. Install the **4.5.2 stable export templates** using Godot's Editor → Manage Export Templates. Templates must match the editor. Official downloads: https://godotengine.org/download/archive/4.5.2-stable/.
2. Create `games/broadside/build/` (ignored by Git).
3. Project → Export → **Windows Desktop**, x86_64 → Export Project, destination `build/Broadside.exe`. Or from repository root:

```powershell
New-Item -ItemType Directory games/broadside/build -Force
godot --headless --path games/broadside --export-release 'Windows Desktop' build/Broadside.exe
Copy-Item games/broadside/packaging/game.json games/broadside/build/game.json
```

4. Keep **Broadside.exe + Broadside.pck + game.json together**. The preset deliberately uses a separate PCK. Do not copy only the EXE. No editor or launcher is required to double-click the exported EXE. The M1 package is unsigned.
5. Zip those three files for a manual playtest; never commit generated exports, `.godot/`, or editor caches. Code-signing/release distribution belongs to the later reviewed packaging phase.

## Game Dock compatibility

Open Game Dock **Settings** to find its games directory (do not assume a hardcoded AppData path). Create `broadside` there and copy all three exported files into it. In **My Library**, **Refresh**, select Broadside, then **Play**. The manifest is validated against the repository's `specs/game-manifest.schema.json`; its executable is the basename `Broadside.exe`, with no arguments or nested path. The existing launcher requires no changes.

Godot uses a separate `user://` directory configured as `Broadside` (normally `%APPDATA%/Broadside` on Windows). Only audio preferences are saved in M1.1; no campaign save is written. Later saves must also use that location, never the installation directory.

## Art and review boundary

All ship, sail, cannon, sea, foam, rock, smoke and impact illustrations are original procedural source in `scripts/ship_base.gd`, `ocean.gd`, `island.gd`, and `effect.gd`. They use navy/teal water, brown timber, canvas and brass accents. The original 16-bar, 6/8 **Sable Channel Jig** score and all foley are synthesized in `audio_synth.gd`; no third-party recordings or commercial melodies are used. No downloaded third-party artwork/audio, asset attribution requirements, or paid dependencies. This is painterly-intent **prototype** art; no final texture polish is claimed. Godot's built-in font is used. Repository licensing remains as stated in the root README; this does not introduce a new blanket source license.

After playing, review steering weight, turning radius, volley speed/damage, enemy pressure, readability and island spacing. **M2 and M3 remain gated on your hands-on approval.**
