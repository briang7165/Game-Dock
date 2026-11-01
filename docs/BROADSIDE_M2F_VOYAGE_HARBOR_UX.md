# Broadside M2-F — Full-Page Voyage Map, Clear Shipyard and Linear Progression

Owner feedback: October 31, 2026. Screenshots from the installed M2-E game show a tiny top-strip chart, tiny price/currency labels and the upgrade-to-Fleet tab getting stuck. Continue from feature/broadside-m2e-polish / PR #13, NOT main alone. Preserve the entire saved fleet, campaign, boss moves and sea-shanty audio.

## User outcomes (must all work)

1. NO route-choice difficulty buttons: a single automatic next destination that steadily gets harder as chapters advance, making purchases and upgrades useful or needed for ordinary progress, without a permanent unwinnable or zero-gold trap.
2. Chart of the Seas uses most of the available screen instead of a 180-pixel ribbon at the top with empty space below.
3. Gold and salvage are huge and clear at the top of harbor, Fleet, Crew and Voyage Chart, updating immediately after a purchase, sale, repair or victory. Every upgrade and ship card visibly shows its exact next price without needing to hover or click.
4. Every upgrade shows large filled/empty tier pips (for example ●○○ = level 1 of 3) and a clear label such as "2 upgrades left" or "MAXED". Bigger ship classes have more upgrade room/cannon capacity where intended. Use separate tags "Not owned/Owned/Equipped" for weapon loadouts with no tiers.
5. Clicking a weapon like Long-Range Cannons and then Fleet, Crew, a different category or Voyage Chart MUST work immediately. Inspection is not a transaction and does not trap the player. Only Confirm Purchase charges gold.
6. Make layout BIGGER and SIMPLER: readable headings, larger buttons, fewer duplicated labels, no empty unused space, good fullscreen scaling. Retain 12-year-old-readable explanations and simple original icons/pictures.

## Diagnosed code (check actual branch before implementation)

- games/broadside/scripts/shipyard_ui.gd inspect() creates offer = Shipyard.quote(). show_page(), show_category(), select_ship() immediately RETURN when offer is nonempty ("Confirm or cancel your estimate first"). This is the direct likely cause of the user's stuck Fleet tab. The user cannot easily find Cancel because it sits in the right panel. Replace blocking behavior with cancellation of any unconfirmed quote on navigation, or selection-only inspection state; 0 gold spent.
- shipyard_ui.gd update_header() places gold and salvage in a small multiline heading label (18pt). Upgrade_card() shows name and x/y but NOT a visible price, status or explicit remaining upgrades. Buttons are minimum height 32. fit_window() does inverse viewport final transform scaling: audit real fullscreen/DPI text sizes rather than blanket shrinking.
- games/broadside/scripts/voyage_chart.gd uses custom_minimum_size Vector2(0,180); campaign.gd show_chart() adds chart to generic ScrollContainer/VBox with no vertical expand flag. Thus chart is tiny top strip. Redesign layout, not just stretch old 5 labels without changing map composition.
- games/broadside/scripts/campaign.gd show_chart() currently renders 3 route buttons Trade Winds / Reef Passage / Blackwater Run; campaign_save.gd persists route and voyage_director.gd scales enemies/rewards based on route. User wants one automatic next level and gradual challenge instead. Update UX AND data/encounter/reward logic together, preserving existing active-encounter saves and journal/currency.

## 1. Full-page Chart of the Seas

Use a dedicated screen/root layout (not the compressed generic column) with a compact top ship/captain/chapter/currency header, a beautiful parchment route chart using approximately 65–80% of available viewport height, and a bottom section with NEXT DESTINATION and clear Set Sail / Visit Harbor / Journal buttons. Use Control size flags SIZE_EXPAND_FILL, responsive anchors and safe padding, no world map hidden under buttons. At 1920x1080, chart should dominate the page. At 1280x720, all stops and route labels legible; 800x450 and ultrawide reflow gracefully.

Illustrate an interesting winding path across BOTH x and y, varied geography/terrain and location names, current ship marker, completed stops/check marks, next stop highlight and a visibly special fifth-stop boss. Do NOT simply enlarge the thin horizontal line; use the canvas. Preserve chapter themes and original painterly style. Make 4-second map sailing transition use the larger chart; show ship moving along path, allow skip Enter/Space/Esc.

Show NEXT DESTINATION: level/stop within chapter, location name, threat preview/enemy type, expected gold reward and perhaps "Recommended: repair / better cannon / stronger hull" based on actual encounter, without requiring a menu of difficulty choices. Big button "Set Sail to [Location]".

## 2. Single progression path and practical economy

Remove risk selection buttons from campaign screen. Each step of the voyage is automatically generated from current chapter, stop and seed. First two encounters approachable with starter 60 HP and one cannon/side. Subsequent encounters introduce roles and hazards gradually; every fifth encounter has a named boss with special move. Higher chapters unlock stronger AI, more/faster threats and occasional fleets. Maintain capped health/stat escalation, telegraphs/obstacle fairness, avoid late-game absurd damage-sponge fights and offscreen snipers.

Gold payouts increase in line with challenge and shipyard prices so normal progression encourages meaningful investment in guns, sails, rudder, defense, crew and bigger hulls; stronger ships should help but not guarantee wins. No silent hard paywall. Keep retry/recovery/salvage/catch-up opportunities so the player can rebuild if short on gold and choose a highly upgraded small ship if skilled. End-result screen shows the next stop and buttons for Set Sail or Harbor.

Implement deterministic stage templates and reward calculation no longer dependent on a user-chosen route; preserve or normalize legacy route for an in-progress saved battle so no old saves are corrupted or unexpectedly changed. Update chapter/journal labels.

## 3. Readable fixed currency / repair header

At top-right show a prominently styled icon and dynamic GOLD total in approximately 28–32px text, salvage nearby in approximately 17–20px. The provided screenshot showed 488 gold, 16 salvage; these are examples, not hard-coded amounts. Show header in Harbor, Upgrades, Fleet, Crew and Voyage Chart. Update after ship purchase, upgrade, repair, sale and reward.

Keep active ship name, hull HP bar, repair cost and Repair Active Ship fixed above scrolling content; no automatic spending. Add a clear salvage sale button such as "Sell 16 salvage for 192 gold" with explicit confirmation; price from actual game economy.

## 4. Upgrade cards with pips, remaining tiers and prices

Use clear filled and unfilled circles from each ship's actual tier_limit: 0/3 = ○○○, 1/3 = ●○○, 3/3 = ●●● + MAXED. Always include textual "1 of 3" and "2 left"; no reliance on color alone. Item icon, short plain-language effect, cost of NEXT upgrade, and availability right on card. Show "Not enough gold" / "Slots full" where applicable, while allowing inspection. Separate category equipment slots from individual upgrade tier dots and show total slots clearly. Bigger ships must actually have sensible and generally higher potential, per-class data-driven limits, while preserving smaller ship mobility/identity.

Non-tier equipment (Long Guns, Chain Shot, Close-Range Cannons, Round Shot) should show Not Owned / Owned / Equipped instead of fake pips. Display price if not owned; if owned, "Equip Free". A maxed upgrade shows MAXED not a misleading price; fully repaired active hull shows Hull Ready.

Use the single stable details/Confirm/Cancel area from M2-E, no duplicate opaque overlay. Clicking a card shows details but no payment; all purchases require explicit confirmation and stale-quote validation. Focus/hover text shouldn't change an already selected quote accidentally.

## 5. FIX trapped Fleet tab and any purchase navigation bugs

Do not refuse navigation merely because there is an unpaid offer. Clicking Fleet, Crew, another category, a different ship or Voyage Chart or Back should cancel the unpaid quote safely (no gold deduction) and switch screen immediately. Keep an optional small "Unpurchased estimate canceled" message. Escape cancels only the pending offer, otherwise normal Back. Make Cancel accessible near checkout when needed and not offscreen. Ensure no invisible Control intercepts input; Mouse and WASD/arrows+Enter+Space both work. Avoid recreating focused nodes mid-press; where required call_deferred after callback.

Automated integration should simulate: select Long-Range Cannons -> click Fleet; select Close-Range -> click Crew; inspect Upgrades -> switch category; select unavailable/maxed -> Fleet; pending quote -> Voyage Chart; keyboard versions. All should navigate; gold unchanged unless Confirm Purchase clicked; no duplicate charge on double-confirm or stale quote.

## 6. Responsive UI / readable menu density

Aim for 46–54px button height and roughly 17–20px text where possible; 24px+ section titles and 28px+ money. Use adequate card spacing and larger hitboxes without enormous wasted space. Verify 800x450, 1280x720, 1920x1080, 2560x1440/fullscreen and wider screens. Audit shipyard_ui.gd fit_window() scale math on high DPI: don't simply counteract Godot's scaling and make desktop labels tiny. Reflow content as needed, use independent scroll only where essential; pinned header always visible. Preserve original nautical visuals.

## 7. Save safety, testing and delivery

Existing CampaignSave v2 / FleetState and user:// data must preserve all ships, per-hull upgrades/health/loadouts, captain/ship names, chapter/stops, gold, salvage, journal and boss counts. Preserve active legacy route battle if underway; provide tested safe migration or compatible route field. Do not reset the user's campaign to apply the single-path route model. Never remove user save backup. Continue existing no-mouse-in-combat controls, music, boss moves, collisions and Game Dock integration.

Implement staged work: M2-F1 first fix trapped tabs, pinned readable gold/repair and upgrade pips/prices; M2-F2 replace chart with full-page map and automatic progression. Open a NEW dependent PR based on feature/broadside-m2e-polish (PR #13) and do not auto-merge stacked PRs or main. Run real Godot tests, exported Windows boot and gameplay verification, screenshots plus human click-through checklist. Publish a matched Broadside.exe / Broadside.pck / game.json downloadable Windows ZIP with a new version (e.g. 0.2.5-m2f) that existing Game Dock installer helper can install without touching saves.

## Acceptance

Player sees gold and salvage immediately, every upgrade's next price and tier bubbles/remaining count, all ships' upgrade caps and current repair cost. Clicking an upgrade then Fleet ALWAYS works, with no payment unless Confirm. Chart fills almost entire screen and offers ONE automatically harder next encounter instead of easy/medium/hard choices; successful campaign progress encourages buying and upgrading ships.
