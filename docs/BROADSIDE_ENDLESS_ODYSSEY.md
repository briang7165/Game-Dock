# Broadside — Endless Odyssey Campaign & Progression Specification
**User direction approved: 2026-10-23.** This extends, but does not replace, the established keyboard-only arcade-tactical combat, painterly visual style, one cannon per broadside starter, bottom HUD, island collision damage, offscreen enemy arrows, and music/SFX.

Status: approved game vision; the specific numerical balancing values below are **starting targets to test**, not final fixed balance. Codex must preserve a functional game throughout incremental implementation. Related: docs/BROADSIDE_DESIGN_DRAFT.md, docs/BROADSIDE_M12_FEEDBACK.md, docs/CODEX_BROADSIDE_BUILD.md, GitHub PR #4.

## Near-term combat presentation refinement (M1.4)

Before full chart/campaign implementation, finish the [zoom/fullscreen/true bottom HUD/location-title pass](BROADSIDE_M14_VIEWPORT_HUD_LOCATION.md) in combat PR #4. Every battle has a named place supplied by encounter data, starting with `The Sable Channel`, and map view/HUD do not overlap. Later the Endless Odyssey travel chart supplies those location names; don't hard-code names into a HUD-only text widget.

## North star

The player is a named pirate captain, sailing a named ship on an **endless, chapter-based sea odyssey**. Start fragile and poorly armed. Win fast, risky encounters, recover treasure and salvage, chart new waters, and transform your small ship into a vessel with unique advantages. **Choices** matter: speed versus armor; broadside force versus reload time; riskier voyages versus safe rewards; crew utility versus direct combat power. Between discrete battles, a short cinematic **chart/sailing interlude** visually carries the player's ship forward. This is NOT an enormous seamless open world.

## 1. Combat duration and early fragility — immediate M1.3 tuning

Current code on open PR #4 uses an initial 100-HP sloop, baseline gun damage 12, three-second reload and one cannon per side. User says early combat takes too long to win OR lose. Later upgraded hulls/weapons/armor should create stronger survivability and longer tactical encounters.

**Initial playtest preset (not final):**
- New-game starter **sloop: 60 max HP**, one cannon PORT and one STARBOARD (two guns total), light/no armor.
- Baseline **cannonball: 16 damage** (tune both player/enemy; approximately four clean hits to defeat an unarmored 60-HP sloop). Maintain individual reload timers, ~2.5–3 seconds initially and fixed outward broadside fire. **Never** revert to 3 starting guns per side.
- Tune enemy HP/accuracy/reload, navigation, steering, islands and projectile effects jointly for fair but risky duels, not just stat changes. A novice can win; no instant-sniping enemy.
- First 1–3 battles: target approximately **45–90 seconds of active combat** during ordinary player playtesting, not a guaranteed hard timer. Early victory/defeat should feel achievable in a handful of successful volleys. Provide a fair telegraph and avoid repeated ram-contact damage.
- Midgame fights after upgrades: typically ~60–150s; dangerous late encounters ~2–3 min; bosses ~2–4 min. Growth in survivability must be *earned*, while enemy behavior/difficulty becomes richer. Longer fights by player investment, not just enormous identical HP bars.
- Keep existing impact-speed-scaled island and ship-to-ship crash damage with sensible **relative HP caps** for starter (e.g. a normal but significant crash hurts without regularly killing from full HP). Rock scrapes and sustained contact do not repeatedly damage.
- Store difficulty/balance tuning in Resources or data files; include test evidence for shot-to-sink counts with representative loadouts and timed manual/scripted encounter observations. Never falsely claim average duration from only headless automated tests.

**Important backward compatibility:** do not retroactively edit a saved hull on load into a negative-health state. Introduce campaign only in the follow-on PR, with predictable migrations.

## 2. New Game — ship and captain identity

- First new campaign prompts **Captain Name** and **Ship Name**, with readable defaults (e.g., Captain Rowan, The Wayfarer) if left blank. These are entirely fictional defaults, not the real user's name.
- Names editable later in the Dock / Captain's Cabin; save locally. Limit names to ~24–32 visible characters; trim whitespace, validate unsupported control characters, handle Unicode/diacritics if Godot fonts allow; provide sensible fallback.
- Show captain's name, ship's name and ship class on the voyage chart, dock header and post-battle summary; optionally on the ship pennant/nameplate when legible.
- Names do not grant gameplay bonuses; ship-class upgrade **retains ship name by default**, offering optional renaming.
- Low-cost customization: pennant/sail insignia or color chosen at new game or dock, visually consistent with pirate aesthetic. This must remain legible against enemy pennants.
- No online accounts, external name services or telemetry. Name and cosmetics persisted under Godot user:// with other campaign state.

## 3. Endless Odyssey voyage map and cinematic travel

The map is a **narrative/progression layer BETWEEN individual battle arenas**, not infinite open-water geometry.

### Core flow
New Game (name captain/ship) → Chart of the Seas → Choose next destination when enabled → Short sailing/chart transition → Tactical battle → Victory/Loss result with earned rewards → Dock/Shipyard or continue voyage → Chart → next encounter. The current combat engine remains the actual battle simulation; do not replace it with a map battle.

### Initial version
- A visually rich **illustrated parchment sea chart** (overhead islands, coastlines, compass rose, dotted route, location names, waves).
- Show the player's purchased **actual hull class/silhouette or ship icon** traversing the line between stops, perhaps as a 3–6 second skippable transition; pan/zoom weather and daylight changes give a sense of travel.
- Travel transition offers Continue/Skip (Enter/Space/Esc as clearly signaled) and always works without mouse. No long mandatory repeated loading cutscene. Ocean/wind audio leads into battle music.
- Markers for battles, sheltered harbors, hazards, ruins/treasure, elite opponents and boss islands. Start with a linear 5-stop chapter and a clear boss at stop 5, then introduce simple **two- or three-way route choices** with risk/reward tradeoffs when core flow is stable.
- Infinite voyage means **procedurally/generated encounter sequences or reusable chapter templates with increasing chapter numbers**. It DOES NOT require allocating a physically infinite map. Persist run seed, voyage/chapter/stop index, route choice and encounter data.
- Pseudorandom map segments must be deterministic for a given campaign seed, with varied island/battle layouts, naming pools, biomes/themes and rewards. Guarantee valid path to the next encounter, safe boat spawn locations and bounded enemy counts/difficulty.
- Sample route labels: Trade Winds (easier / moderate reward), Reef Passage (rock hazards / better salvage), Blackwater Run (elite pirate hunter / rare loot). Introduce only after base voyage works.
- Difficulty increases by more enemy behaviors/hulls, staggered salvos, navigational hazard tradeoffs and some stat growth with **caps**; do not multiply HP endlessly until basic cannon becomes ineffective.
- Provide a **Voyage Journal** or log of distance/stops sailed, ships sunk, treasure, chapters completed and memorable boss encounters. Only summary counters initially.

### Skip/failure/progression rules
- Losing a battle does not erase purchased ships, upgrades, cosmetics or names. Offer retry at an affordable cost OR retreat to dock / easier encounter so the player is not permanently trapped.
- Save at safe transitions (after result/reward, purchases, and map selections), not continuously to the installation folder. Protect against replaying a reward after crashes or repeatedly claiming a one-time event.
- Prevent "infinite" level numbering/save overflow by use of safe integer handling and difficulty soft-caps. More variety > unlimited enemy HP.

## 4. Shipyard, repair economy and four ship classes

**Hull sequence:** Sloop → Brig → Frigate → Galleon, with genuinely distinct visual silhouettes, mast/sail shape, hull/cannon port number, size/turning radius/HP and available equipment slots. Do not create the next ship just by enlarging the sprite.

- Gold from victory; modest salvage on losses/abandoned danger; repairs cost gold. Keep enough comeback income/free minimum repair for players never to get softlocked.
- Every hull class has increasing baseline protection and hard per-side gun **capacity**, but buying a new class does not silently give the player every possible cannon or upgrade for free.
- Sloop starts **one cannon per side**; purchasing a second gun/side (when capacity allows) should visibly place ports on the artwork AND produce an extra cannonball on that side. Higher class opens more capacity rather than immediately granting a full barrage.
- Show real purchase price, gold owned, new stats and tradeoffs BEFORE clicking Confirm; keyboard and mouse menu parity.
- Provide at least one viable advancement path without relying solely on armor/health or raw gun damage.

### Diversified meaningful upgrades: candidate catalog (data-driven, bounded and testable)

**Weapon configuration (beyond quantity):**
1. Additional cannons / cannon ports (more shots per salvo; slower/heavier is an optional tradeoff).
2. Faster-trained gun crews (shorter automatic reload; never require a reload button).
3. Long guns (more range and velocity, but higher reload and/or poorer turn precision); deck loadout selected in dock, Space still fires.
4. Carronades (short-range heavier impacts, more spread; ideal for close combat).
5. Chain shot equipment (reduced hull damage but briefly impairs enemy speed/turning; selectable at dock, NOT a new mouse-aim mode or permanent debilitating lock).
6. Improved powder/shot rigging (modest damage or projectile spread changes, with meaningful cost and possible overheat/safety tradeoffs).

**Sailing and navigation:**
7. Sails and rigging (improved top speed and acceleration; not instantaneous "go-kart" response).
8. Rudder/keel (tighter deliberate turn radius / reduced drift; preserve weight of sailing).
9. Lookout/spyglass (better offscreen enemy indicators and earlier enemy telegraph or map reveal).
10. Navigator/charts (reveals hazard/reward hints on route selection or a once-per-chapter reroute).

**Defense / utility:**
11. Hull reinforcement/armor (reduces cannon damage, but adds weight and worsens turn/acceleration in visible stats).
12. Reinforced prow (higher enemy ram damage and/or reduced self-collision damage; not a free unbeatable melee attack).
13. Ship's carpenter / repair tools (lower dock repair cost or limited automatic BETWEEN-battle repair; no Space repair during combat).
14. Extra cargo holds / salvage nets (better gold/salvage payouts but optional small speed penalty).

**Captain and crew choices (light RPG flavor, not an uncontrolled class tree):**
15. Gunner, navigator, carpenter, quartermaster crew appointments (choose 1–2 active roles/slots from earned unlocks, granting distinct bounded bonuses).
16. Optional captain skills earned through voyage milestones: sharp-eyed lookout, dependable quartermaster, brave helmsman, or shipwright's touch. Prefer 1 choice per milestone to a giant stat tree.
17. Captain titles earned from bosses/chapter streaks (e.g. "Reefbreaker", "Stormrunner"), cosmetic and displayed with name, no monetization.

**Design integrity:** Ship purchases, passive perks and installed equipment must materially affect behavior and/or art. Avoid upgrades that are only "+2% damage" with no noticeable effect. Limit repetitive stacking; present tradeoffs and preview behavior, not only numbers. Early shop must include at least one weapon, one handling/navigation and one economy/utility choice, not just cannons + armor.

**Recommended first playable economy set:** extra cannon, trained gunners (reload), rudder upgrade, sails/rigging, hull reinforcement, carpenter repair discount, reinforced prow, lookout and cargo/salvage bonus; ship class purchases when gold permits. Defer ammo variants and complex crew skill trees until balance passes. Use small catalog then deepen.

## 5. Interesting encounters and variation, staged later
- Encounters: standard duel, ambush among reefs, merchant-defense rescue, bounty hunter ship, chase/interception, boss in stormy waters; objectives must remain compatible with current controls.
- Island themes: tropical green atolls, volcanic rock, misty channel, stormy sea. Terrain still blocks movement/shots.
- Safe harbors and rare encounters create moments between battles; minor text story panels and captain's log add continuity without expensive cinematic dialogue.
- Distinct enemies and telegraphed behaviors (raider flanks, heavy holds firing position, hunter stalks, escort formation). Avoid unfair off-screen enemy fire; indicators and warning cues remain essential.
- Atmospheric music can crossfade from short voyage theme into battle track. Reuse original/legal music and SFX; no licensed soundtrack cost.
- Optional cosmetic figureheads/flag colors via achievements; do not make paid or premium store.

## 6. UX requirements
- **All battle controls unchanged:** WASD OR arrows move, Space fires fixed loaded broadsides, automatic independent reload, Esc pauses. No mouse combat/aim/targeting. Ship collisions damage both where appropriate.
- **All menus/map/dock/name entry:** mouse AND keyboard navigation; WASD/arrows focus, Enter or Space confirms, Esc backs out. While typing name, WASD/arrows/Space must function as text input, NOT inadvertently navigate or trigger game actions; Escape cancels where sensible.
- Bottom battle HUD remains health + two reload bars; optional separate ship name/level badge that does not reduce readability. Off-screen enemies retain indicators.
- Map, cutscenes, dock and save screens have accessible contrast, scaled layout, no forced long intermission.
- Make the captain/ship naming flow straightforward and **skippable with defaults**.

## 7. Data, persistence and technical architecture
- Existing Godot 4 project under games/broadside; standalone Windows x64 executable, Game Dock manifest unchanged.
- Components encouraged: CampaignState/SaveManager, ShipCatalog, UpgradeCatalog, Economy, DockUI, CaptainIdentity, VoyageDirector, RouteGenerator (seeded), MapUI, TravelInterlude, EncounterFactory, EnemyLoadout. Keep interfaces clean and unit-testable.
- Save versioned data under Godot user:// (not next to .exe), atomic replacement/backup or temp+rename where practical. Include migration handling for future schema revisions and resilience to corrupt saves.
- Keep campaign state separate from live battle nodes and save-safe IDs for hull class, equipment, naming, voyage and rewards.
- Do not make the project need online services. Generated procedural art/maps and free licensed assets only; document licenses.
- Avoid changing launcher without actual integration requirement. Export and packaging run independently. Verify no main-branch unreviewed PR is overwritten.
- Exact test results and screenshots must accompany review PR; don't claim Windows installed release without testing.

## 8. Codex execution gates

### M1.3 — first small balance PR or change to current PR #4, *before* economy
- [ ] Starting 60 HP / ~16 damage as tunable **test preset**, enemy rebalanced, no more than one cannon per side on fresh sloop.
- [ ] Early duels terminate with roughly 4 clean hits under baseline stats, without early-game accidental one-shot collisions; independent reload, slower cannonballs, ship weight and impact logic unaffected.
- [ ] Tests cover configured hit count, death/victory on shorter HP pools, survival after minor terrain scrape, big ram damage both.
- [ ] Human playtesting confirms the feel; note the measured player experience vs simulated test.
- [ ] Preserve all M1.2 code, HUD, sounds and packaging.

### M2-A — campaign foundation (separate PR after existing combat branch is reviewed/merged)
- [ ] New Game asks captain and ship names with defaults, shows them consistently and persists through restart/ship purchase.
- [ ] Versioned campaign save / resume and safe new game confirmation.
- [ ] Sea-chart between battles showing voyage chapter/stop, ship marker, skippable sailing/travel interlude, return to current battle unchanged.
- [ ] Win/loss → result → chart/dock → next battle loop, no softlocks, no duplicate gold.
- [ ] Linear 5-stop first chapter ending with one slightly distinct boss scenario; endless continuation through recycled/generated chapters (not gigantic open world).

### M2-B — meaningful progression and purchasing (next PR after M2-A)
- [ ] Reward gold, repairs, upgrades in functional shipyard with mouse+keyboard menu support.
- [ ] Visually distinct sloop/brig/frigate/galleon, real gun port caps and movement/HP tradeoffs.
- [ ] First catalog includes cannon count, gunnery/reload, sails, rudder, carpenter, lookout, reinforced prow and salvage tradeoffs; all change game or tactical decisions visibly.
- [ ] End-to-end test of purchased second gun physically spawning more projectiles and persisting to next voyage, with retained ship/captain names.
- [ ] Loss recovery, currency safeguards, no infinite stacking or accidental double rewards.

### M2-C — voyage depth (after core economy is fun)
- [ ] 2–3 branching route choices, deterministic safe map layout, variety of enemy ship classes and environmental hazards.
- [ ] Specialized loadouts, ammo tradeoffs, crew perks, ship cosmetics, journal and chapter boss variety.
- [ ] Test long-term chapter progression without runaway HP/speed/currency and without impossible maps.

### M3 — final visual/audio/release polish
- [ ] Painterly original ship, chart, dock, ocean and terrain art; captain identity embellishments.
- [ ] Effects/music crossfades, polish, performance, versioned Windows game exports, real Game Dock integration verification.

## 9. Explicit prohibitions and quality gates
- Do NOT build one giant "entire campaign" commit/PR, auto-merge PR #4, overwrite working combat or implement mouse aiming.
- Do NOT add subscription/premium currency/microtransactions or online account requirements.
- Do NOT put permanent ship/captain naming exclusively in launcher; Broadside runs independently.
- Do NOT assume a seamless infinite open-world map is required; discrete battle scenes linked by map/travel cinematics are the approved structure.
- Do NOT ship superficial stat-only shops; meaningful upgrades need real behavior and visible feedback.
- Deliver small tested working steps and report what is truly verified, what remains manual and what awaits user playtest.
