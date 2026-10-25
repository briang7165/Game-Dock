# Broadside M2-D — fleet and shipyard

This milestone builds on PR #10 (`feature/broadside-m2c-odyssey`). It does not merge or replace the existing campaign branch. Windows package: `0.2.3-m2d`.

## Using the harbor

The active vessel stays in the header while you scroll. Inspect Sloop, Brig, Frigate or Galleon in the illustrated fleet gallery. Buying a hull adds it to the fleet without changing your active vessel. **Make active** switches ships for free outside an encounter. Each class has one permanent vessel; no selling or duplicate hull purchases.

Each ship retains its name, condition, upgrade tiers and purchased weapon loadouts. You can rename, repair and upgrade an inactive ship. Captain identity, pennant, gold, salvage, chapter, journal and the explicitly labeled captain-wide specialist berth are shared. Captain's papers rename the active ship; the selected ship's Name control can rename an inactive one.

Four fitting categories expose all existing functioning upgrades. Hover/focus shows descriptions; selecting opens a separate estimate with an original icon, selected vessel, tier, before/after stats, gold and salvage cost, remaining balance, availability, Confirm and Cancel. Cancel initially has keyboard focus. Escape cancels the estimate before returning to the chart. Mouse clicks, WASD/arrows, Enter/Space and scrolling work in the harbor. Navigation never starts combat or buys an upgrade.

The portraits instantiate the actual `BroadsideShip` renderer with the selected ship's real cannon configuration and hull size, with movement/collisions disabled. Artwork, fittings icons, compass framing and interface styling are original procedural Godot graphics. No external media or changes to existing audio, sailing, combat controls, battlefield HUD or encounter generation.

## Capacity rules

A slot represents a distinct installed upgrade family, not each rank. A nonstandard equipped weapon occupies one Firepower slot. Owning an unequipped weapon does not consume a slot; swapping owned weapons costs zero. All current purchases use gold (shown alongside zero salvage cost). Salvage remains exchangeable at the existing 12 gold rate.

| Class | Gunports per side | Firepower / Sailing / Defense / Utility slots | Cannons / Gunners / Sails / Rudder / Lookout / Prow / Carpenter / Cargo / Armor tier caps |
|---|---:|---|---|
| Sloop | 2 | 2 / 2 / 2 / 1 | 1 / 3 / 3 / 3 / 2 / 2 / 2 / 2 / 2 |
| Brig | 3 | 3 / 2 / 3 / 2 | 1 / 3 / 3 / 3 / 2 / 2 / 3 / 3 / 3 |
| Frigate | 4 | 3 / 2 / 3 / 2 | 1 / 3 / 2 / 2 / 2 / 2 / 3 / 3 / 3 |
| Galleon | 6 | 3 / 2 / 3 / 2 | 2 / 3 / 2 / 2 / 2 / 2 / 3 / 3 / 3 |

The starter remains 60 HP / 16 damage / one cannon per side. Smaller ships keep cheaper hull/repair costs and stronger maneuverability. Armor still reduces speed/turning; larger hulls are not universally superior. Comparison bars show active versus selected installed stats and signed differences, plus selected base stats and separately labeled potential HP/gunports. Potential values are not installed equipment, and category slots limit combinations.

## Version 1 → version 2 save migration

Normal Windows save location remains `%APPDATA%/Broadside/campaign.json`, outside the installation. Tests use isolated APPDATA.

1. Validate the existing version 1 save (or its valid recovery backup).
2. Copy its **exact bytes** to `campaign.json.v1.bak` before writing version 2. Verify the archive bytes. Never overwrite an existing archive with different contents. Backup failure stops migration and preserves the original.
3. Preserve all existing currency, progress, identity, condition, equipment and other campaign fields. Assign the old active ship's installed upgrades and weapon to that vessel. Retain a bare starter sloop if the active vessel is a larger class.
4. Preserve grandfathered upgrades even above new per-class or category limits. Show the installed tier/count as-is. New purchases still obey current caps; no refund, truncation or silent downgrade. Actual cannon rendering/firing retains the preexisting gunport clamp.
5. Atomically verify/write the new save, retaining the rolling `.bak` backup as well. Unsupported future versions are preserved and never replaced by an older recovery backup.

Version 1 did not record a collection of previously replaced hulls or unequipped weapons. Migration cannot infer that history; it retains the known active vessel, starter and all recorded installed purchases. Version 2 records future ownership permanently.

For rollback to an older build, close the game, copy the **current** save folder somewhere safe, then restore the archived version 1 file as `campaign.json`. Older builds cannot read the new fleet format. Do not delete the archive when upgrading the game binaries.

## Implementation contract

`FleetState` owns ship snapshots and the active flat projection consumed by existing combat. `CampaignSave.commit` updates that projection into the active vessel, validates all fleet members, verifies the temporary file, backs up the prior valid save and atomically replaces it. Loading projects the canonical owned active vessel back into combat fields.

`Shipyard.preview` never mutates its input. Quotes carry a save revision and selected vessel. Confirmation rechecks ownership, encounter lock, price, tier and category capacity against current state, then commits once. Reusing a quote or confirming after any intervening save is rejected without charge. Repairs and purchased-weapon re-equipping use the same transaction path.

See `BROADSIDE_M2D_TEST_RESULTS.md` for actual validation and the separate Windows build workflow for a downloadable EXE/PCK/manifest ZIP.
