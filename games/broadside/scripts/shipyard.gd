class_name Shipyard
extends RefCounted
## Pure catalog and transactions: previews never mutate saves; purchases commit once.
const HULLS: Dictionary = {
	"sloop":{"price":0,"hp":60.0,"speed":165.0,"turn":0.85,"accel":42.0,"guns":1,"capacity":2,"size":Vector2(1,1),"note":"Nimble single-mast scout; fragile but cheap to repair."},
	"brig":{"price":320,"hp":96.0,"speed":155.0,"turn":0.72,"accel":37.0,"guns":2,"capacity":3,"size":Vector2(1.12,1.18),"note":"Twin-mast raider; balanced speed and two guns per side."},
	"frigate":{"price":800,"hp":144.0,"speed":175.0,"turn":0.59,"accel":32.0,"guns":3,"capacity":4,"size":Vector2(1.16,1.38),"note":"Long, swift hunter; three guns, wider turning circle."},
	"galleon":{"price":1500,"hp":208.0,"speed":125.0,"turn":0.46,"accel":25.0,"guns":4,"capacity":6,"size":Vector2(1.42,1.52),"note":"Broad, heavy flagship; four guns and a deliberate helm."}}
const UPGRADES: Dictionary = {
	"cannons":{"price":150,"max":2,"name":"Extra Cannons","note":"Adds one cannon on each side, so each broadside fires more shots. Uses a gunport."},
	"gunners":{"price":100,"max":3,"name":"Faster Reloading","note":"Your crew loads the cannons faster, so you can shoot again sooner."},
	"sails":{"price":90,"max":3,"name":"Fine Sails","note":"Catch fleeing ships: speed up sooner and sail faster."},
	"rudder":{"price":80,"max":3,"name":"Better Rudder","note":"Turn more easily to line up shots or dodge danger."},
	"lookout":{"price":70,"max":2,"name":"Lookout","note":"See more ocean around your ship and spot trouble sooner."},
	"prow":{"price":110,"max":2,"name":"Strong Bow","note":"Ram enemy ships harder and take less damage from ship crashes. Rocks still hurt."},
	"carpenter":{"price":90,"max":3,"name":"Repair Expert","note":"Fixes a little damage after you win. Does not repair during a fight."},
	"cargo":{"price":100,"max":3,"name":"Treasure Hold","note":"Bring back more gold and salvage from each victory."},
	"armor":{"price":120,"max":3,"name":"Stronger Hull","note":"Survive more hits, but the extra weight makes you slower to sail and turn."}}
const WEAPONS: Dictionary = {
	"chain":{"price":220,"name":"Chain Shot","note":"Slows an enemy for a moment, but hurts its hull less. Useful for escaping or lining up another shot."},
	"standard":{"price":0,"name":"Round Shot","note":"Regular cannonballs. Balanced damage, range and reload time, with no special effect."},
	"long":{"price":180,"name":"Long-Range Cannons","note":"Reach ships farther away, but take longer to reload. Keep your distance."},
	"carronade":{"price":180,"name":"Close-Range Cannons","note":"Carronades hit harder up close, but cannot shoot far and reload a little slower. Get close before firing."}}

const CATEGORIES: Dictionary = {
	"Firepower":["cannons","gunners"], "Sailing & Handling":["sails","rudder"],
	"Defense & Repairs":["armor","prow","carpenter"], "Utility & Economy":["lookout","cargo"]}
const LIMITS: Dictionary = {
	"sloop":{"tiers":[1,3,3,3,2,2,2,2,2],"slots":[2,2,2,1]},
	"brig":{"tiers":[1,3,3,3,2,2,3,3,3],"slots":[3,2,3,2]},
	"frigate":{"tiers":[1,3,2,2,2,2,3,3,3],"slots":[3,2,3,2]},
	"galleon":{"tiers":[2,3,2,2,2,2,3,3,3],"slots":[3,2,3,2]}}
static func tier_limit(data: Dictionary, id: String) -> int:
	return int(LIMITS[data.hull].tiers[UPGRADES.keys().find(id)])
static func slots(data: Dictionary, category: String) -> int:
	return int(LIMITS[data.hull].slots[CATEGORIES.keys().find(category)])
static func used(data: Dictionary, category: String) -> int:
	var count: int = 0
	for id: String in CATEGORIES[category]:
		if rank(data,id) > 0: count += 1
	if category == "Firepower" and data.get("weapon","standard") != "standard": count += 1
	return count
static func capacity_text(data: Dictionary) -> String:
	var count: int = 0
	var capacity: int = 0
	for category: String in CATEGORIES:
		count += used(data,category)
		capacity += slots(data,category)
	return "%d / %d equipment slots" % [count,capacity]

static func rank(data: Dictionary, key: String) -> int:
	return int(data.upgrades.get(key,0))

static func hull_for(data: Dictionary) -> HullStats:
	var spec: Dictionary = HULLS[data.hull]
	var hull: HullStats = preload("res://data/sloop.tres").duplicate()
	hull.title = str(data.hull).capitalize()
	hull.cannon_capacity = int(spec.capacity)
	hull.max_health = float(spec.hp)+18*rank(data,"armor")
	hull.top_speed = float(spec.speed)*(1+0.07*rank(data,"sails"))*(1-0.04*rank(data,"armor"))
	hull.turn_rate = float(spec.turn)*(1+0.08*rank(data,"rudder"))*(1-0.03*rank(data,"armor"))
	hull.acceleration = float(spec.accel)*(1+0.06*rank(data,"sails"))
	if data.get("crew","none") == "navigator": hull.top_speed *= 1.08
	hull.rudder_acceleration *= 1+0.12*rank(data,"rudder")
	return hull

static func guns_for(data: Dictionary) -> CannonStats:
	var guns: CannonStats = preload("res://data/player_sloop_cannons.tres").duplicate()
	guns.gun_count = mini(int(HULLS[data.hull].guns)+rank(data,"cannons"),int(HULLS[data.hull].capacity))
	guns.reload_seconds *= 1-0.08*rank(data,"gunners")
	if data.get("crew","none") == "gunner": guns.reload_seconds *= 0.9
	match data.get("weapon","standard"):
		"chain":
			guns.damage = 10
			guns.slow_seconds = 2
		"long":
			guns.projectile_lifetime *= 1.35
			guns.reload_seconds *= 1.25
		"carronade":
			guns.damage = 23
			guns.projectile_lifetime *= 0.65
			guns.reload_seconds *= 1.1
	return guns

static func price(data: Dictionary, kind: String, id: String) -> int:
	match kind:
		"hull": return int(HULLS[id].price) if HULLS.has(id) else -1
		"upgrade": return int(UPGRADES[id].price)*(rank(data,id)+1) if UPGRADES.has(id) else -1
		"weapon": return (0 if data.get("owned_weapons",["standard"]).has(id) else int(WEAPONS[id].price)) if WEAPONS.has(id) else -1
		"repair": return ceili(maxf(0,hull_for(data).max_health-float(data.health))*0.5)
	return -1

static func availability(data: Dictionary, kind: String, id: String, selected: String = "") -> String:
	var vessel_id: String = data.hull if selected.is_empty() else selected
	if data.active: return "Incompatible • finish the saved encounter"
	if not HULLS.has(vessel_id): return "Incompatible ship"
	if kind == "hull":
		if not HULLS.has(id): return "Incompatible hull"
		if data.fleet.has(id): return "Installed • already owned"
	else:
		if not data.fleet.has(vessel_id): return "Incompatible • purchase this ship first"
	var vessel: Dictionary = FleetState.view(data,vessel_id)
	if kind == "upgrade":
		if not UPGRADES.has(id): return "Incompatible upgrade"
		if rank(vessel,id) >= tier_limit(vessel,id): return "Maximum level • installed"
		for category: String in CATEGORIES:
			if id in CATEGORIES[category] and rank(vessel,id) == 0 and used(vessel,category) >= slots(vessel,category): return "Incompatible • category slots full"
	elif kind == "weapon":
		if not WEAPONS.has(id): return "Incompatible weapon"
		if vessel.weapon == id: return "Installed"
		if id != "standard" and vessel.weapon == "standard" and used(vessel,"Firepower") >= slots(vessel,"Firepower"): return "Incompatible • firepower slots full"
	elif kind == "repair":
		if price(vessel,kind,id) == 0: return "Installed • hull fully repaired"
	elif kind != "hull": return "Incompatible transaction"
	var cost: int = price(vessel,kind,id)
	if int(data.gold) < cost: return "Unaffordable"
	return "Available"

static func preview(data: Dictionary, kind: String, id: String, selected: String = "") -> Dictionary:
	if availability(data,kind,id,selected) != "Available": return {}
	var next: Dictionary = data.duplicate(true)
	var vessel_id: String = data.hull if selected.is_empty() else selected
	var vessel: Dictionary = FleetState.view(data,vessel_id)
	var cost: int = price(vessel,kind,id)
	match kind:
		"hull": next.fleet[id] = FleetState.bare(id)
		"upgrade":
			vessel.upgrades[id] = rank(vessel,id)+1
			if id == "armor": vessel.health += 18
		"weapon":
			vessel.weapon = id
			if not vessel.owned_weapons.has(id): vessel.owned_weapons.append(id)
		"repair": vessel.health = hull_for(vessel).max_health
	if kind != "hull":
		FleetState.capture(vessel)
		next.fleet[vessel_id] = vessel.fleet[vessel_id].duplicate(true)
	FleetState.project(next,data.hull)
	next.gold = int(data.gold)-cost
	return next

static func quote(data: Dictionary, kind: String, id: String, selected: String = "") -> Dictionary:
	return {"revision":data.revision,"kind":kind,"id":id,"selected":data.hull if selected.is_empty() else selected}
static func confirm(save: CampaignSave, offer: Dictionary) -> bool:
	if offer.get("revision",-1) != save.data.revision:
		save.error = "Estimate expired. Select the item again; nothing was charged."
		return false
	var next: Dictionary = preview(save.data,offer.get("kind",""),offer.get("id",""),offer.get("selected",""))
	if next.is_empty():
		save.error = "Unavailable. Check ship ownership, gold, slots and tier limits."
		return false
	return save.commit(next)
static func purchase(save: CampaignSave, kind: String, id: String, selected: String = "") -> bool:
	return confirm(save,quote(save.data,kind,id,selected))
static func activate(save: CampaignSave, id: String) -> bool:
	if save.data.active or not save.data.fleet.has(id): return false
	var next: Dictionary = save.data.duplicate(true)
	FleetState.project(next,id)
	return save.commit(next)
static func rename_ship(save: CampaignSave, id: String, title: String) -> bool:
	if save.data.active or not save.data.fleet.has(id): return false
	var next: Dictionary = save.data.duplicate(true)
	next.fleet[id].ship = CampaignSave.clean_name(title,"The "+id.capitalize())
	FleetState.project(next,save.data.hull)
	return save.commit(next)

static func apply(ship: BroadsideShip, data: Dictionary) -> void:
	ship.hull = hull_for(data)
	ship.set_cannon_loadout(guns_for(data))
	ship.health = clampf(float(data.health),1,ship.hull.max_health)
	ship.ship_class = data.hull
	ship.pennant = int(data.pennant)
	ship.prow_rank = rank(data,"prow")
	ship.resize_hull(HULLS[data.hull].size)
