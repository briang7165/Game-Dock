class_name VoyageDirector
extends RefCounted
const ROUTES: Array[String] = ["Trade Winds","Reef Passage","Blackwater Run"]
const THEMES: Array[String] = ["Tropical Atolls","Ashen Coast","Misty Reaches","Stormward Sea"]
const BOSSES: Array[String] = ["The Tidewarden","Ashwake Corsair","The Storm Regent"]
const CREW: Dictionary = {
	"none":"No specialist — original sailing and gunnery.",
	"gunner":"Master gunner — reload 10% faster.",
	"navigator":"Navigator — 8% faster sailing and wider lookout.",
	"carpenter":"Carpenter — repair 8 hull after victories.",
	"quartermaster":"Quartermaster — 15% more prize gold."}

static func reward(data: Dictionary) -> int:
	var base: int = 80+15*int(data.stop)+(100 if int(data.stop) == 4 else 0)
	return roundi(base*(1+0.35*int(data.route))*(1+0.2*Shipyard.rank(data,"cargo"))*(1.15 if data.get("crew","none") == "quartermaster" else 1.0))

static func encounter(data: Dictionary) -> EncounterStats:
	var result := EncounterStats.new()
	result.campaign = true
	result.theme = posmod(int(data.chapter)-1,THEMES.size())
	result.layout = posmod(int(data.seed)+int(data.chapter)*7+int(data.stop)*13+int(data.route)*19,3)
	result.location_name = preload("res://scripts/voyage_chart.gd").NAMES[int(data.stop)]
	if int(data.chapter) > 1:
		result.location_name = ["Emerald","Ember","Fogbound","Thunder"][result.theme]+" "+["Strait","Reef","Shoals","Reach","Crown"][int(data.stop)]
	result.location_subtitle = "Chapter %d • %s • %s" % [int(data.chapter),THEMES[result.theme],ROUTES[int(data.route)]]
	var chapter: int = mini(int(data.chapter),6)
	var route: int = int(data.route)
	result.enemy_roles = ["raider"]
	if int(data.stop) == 4:
		result.boss_name = BOSSES[posmod(int(data.chapter)-1,3)]
		result.enemy_roles.assign([["warden"],["corsair"],["regent"]][posmod(int(data.chapter)-1,3)])
		if route == 2 and chapter >= 2: result.enemy_roles.append("raider")
	elif int(data.chapter) > 1 or int(data.stop) >= 3:
		result.enemy_roles.assign([["raider"],["hunter","raider"],["heavy","hunter","raider"]][route])
		if chapter < 3 and result.enemy_roles.size() > 2: result.enemy_roles.resize(2)
	elif route == 2:
		result.enemy_roles = ["hunter"]
	result.difficulty = chapter
	result.route = route
	return result

static func islands(encounter_data: EncounterStats) -> Array[Vector2]:
	# Wide connected lanes, no rocks within 180 units of any spawn. Fixed safe
	# templates vary by seed; no unbounded random placement can trap a vessel.
	var layouts: Array = [
		[Vector2(-420,-230),Vector2(120,210),Vector2(570,-280)],
		[Vector2(-650,-320),Vector2(-80,-310),Vector2(150,310),Vector2(680,260)],
		[Vector2(-610,290),Vector2(-120,-320),Vector2(170,320),Vector2(650,-340)]]
	var result: Array[Vector2] = []
	result.assign(layouts[encounter_data.layout])
	if encounter_data.route == 1:
		result.append(Vector2(-850,-550))
		result.append(Vector2(850,550))
	return result

static func configure(ship: BroadsideShip, role: String, info: EncounterStats) -> void:
	var data: Dictionary = CampaignSave.fresh("Enemy","Enemy")
	data.hull = "sloop"
	if role in ["heavy","warden"]: data.hull = "brig"
	if role in ["hunter","corsair"]: data.hull = "frigate"
	if role == "regent": data.hull = "galleon"
	Shipyard.apply(ship,data)
	ship.role = role
	ship.hull.max_health = 60 if role == "raider" else (64 if role == "hunter" else 80)
	ship.guns.gun_count = 1 if role in ["raider","hunter"] else 2
	ship.guns.reload_seconds = 3.6 if role == "heavy" else 3.0
	ship.tactics = ship.tactics.duplicate()
	if role == "hunter":
		ship.tactics.ai_range = 560
		ship.guns.projectile_lifetime *= 1.2
		ship.guns.reload_seconds = 3.8
	if role in ["warden","corsair","regent"]:
		ship.hull.max_health = minf(160,78+5*(info.difficulty-1)+12*info.route)
		ship.guns.gun_count = 1 if info.difficulty == 1 and info.route == 0 else 2
		ship.guns.reload_seconds = 3.8
		ship.tactics.ai_telegraph = 1.2
		ship.ability = BossAbility.new(role)
	ship.health = ship.hull.max_health
	ship.set_cannon_loadout(ship.guns)
	ship.modulate = Color("ffd0b1") if not info.boss_name.is_empty() else Color.WHITE
