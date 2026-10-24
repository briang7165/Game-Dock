class_name Shipyard
extends RefCounted
## Pure catalog and transactions: previews never mutate saves; purchases commit once.
const HULLS: Dictionary = {
	"sloop":{"price":0,"hp":60.0,"speed":165.0,"turn":0.85,"accel":42.0,"guns":1,"capacity":2,"size":Vector2(1,1),"note":"Nimble single-mast scout; fragile but cheap to repair."},
	"brig":{"price":320,"hp":96.0,"speed":155.0,"turn":0.72,"accel":37.0,"guns":2,"capacity":3,"size":Vector2(1.12,1.18),"note":"Twin-mast raider; balanced speed and two guns per side."},
	"frigate":{"price":800,"hp":144.0,"speed":175.0,"turn":0.59,"accel":32.0,"guns":3,"capacity":4,"size":Vector2(1.16,1.38),"note":"Long, swift hunter; three guns, wider turning circle."},
	"galleon":{"price":1500,"hp":208.0,"speed":125.0,"turn":0.46,"accel":25.0,"guns":4,"capacity":6,"size":Vector2(1.42,1.52),"note":"Broad, heavy flagship; four guns and a deliberate helm."}}
const UPGRADES: Dictionary = {
	"cannons":{"price":150,"max":2,"name":"Extra broadside gun","note":"+1 cannon per side, limited by your hull's gunports."},
	"gunners":{"price":100,"max":3,"name":"Gunnery training","note":"Reload 8% faster per rank."},
	"sails":{"price":90,"max":3,"name":"Fine canvas","note":"Top speed +7%, acceleration +6% per rank."},
	"rudder":{"price":80,"max":3,"name":"Balanced rudder","note":"Turn rate +8%, rudder response +12% per rank."},
	"lookout":{"price":70,"max":2,"name":"Lookout platform","note":"Camera reveals 5% more sea per rank."},
	"prow":{"price":110,"max":2,"name":"Reinforced prow","note":"Ship rams deal +20% and hurt you 15% less per rank."},
	"carpenter":{"price":90,"max":3,"name":"Ship's carpenter","note":"Restore 5 hull after each victory per rank."},
	"cargo":{"price":100,"max":3,"name":"Salvage hold","note":"Recover +20% gold and +1 salvage per victory per rank."},
	"armor":{"price":120,"max":3,"name":"Hull plating","note":"+18 hull, but -4% speed and -3% turning per rank."}}
const WEAPONS: Dictionary = {
	"standard":{"price":0,"note":"Round shot: 16 damage, standard range and reload."},
	"long":{"price":180,"note":"Long guns: +35% range, but reload 25% slower."},
	"carronade":{"price":180,"note":"Carronades: 23 damage, but -35% range and +10% reload time."}}

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
	hull.rudder_acceleration *= 1+0.12*rank(data,"rudder")
	return hull

static func guns_for(data: Dictionary) -> CannonStats:
	var guns: CannonStats = preload("res://data/cannons.tres").duplicate()
	guns.gun_count = mini(int(HULLS[data.hull].guns)+rank(data,"cannons"),int(HULLS[data.hull].capacity))
	guns.reload_seconds *= 1-0.08*rank(data,"gunners")
	match data.get("weapon","standard"):
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
		"weapon": return int(WEAPONS[id].price) if WEAPONS.has(id) else -1
		"repair": return ceili(maxf(0,hull_for(data).max_health-float(data.health))*0.5)
	return -1

static func preview(data: Dictionary, kind: String, id: String) -> Dictionary:
	var next: Dictionary = data.duplicate(true)
	var cost: int = price(data,kind,id)
	if data.active or cost < 0 or int(data.gold) < cost:
		return {}
	match kind:
		"hull":
			if id == data.hull: return {}
			next.hull = id
			next.health = hull_for(next).max_health
		"upgrade":
			if rank(data,id) >= int(UPGRADES[id].max): return {}
			if id == "cannons" and guns_for(data).gun_count >= hull_for(data).cannon_capacity: return {}
			next.upgrades[id] = rank(data,id)+1
			if id == "armor": next.health += 18
		"weapon":
			if data.get("weapon","standard") == id: return {}
			next.weapon = id
		"repair":
			if cost == 0: return {}
			next.health = hull_for(next).max_health
		_: return {}
	next.gold = int(data.gold)-cost
	return next

static func purchase(save: CampaignSave, kind: String, id: String) -> bool:
	var next: Dictionary = preview(save.data,kind,id)
	if next.is_empty():
		save.error = "Unavailable: check gold, rank, gunports or finish the current encounter."
		return false
	return save.commit(next)

static func apply(ship: BroadsideShip, data: Dictionary) -> void:
	ship.hull = hull_for(data)
	ship.set_cannon_loadout(guns_for(data))
	ship.health = clampf(float(data.health),1,ship.hull.max_health)
	ship.ship_class = data.hull
	ship.pennant = int(data.pennant)
	ship.prow_rank = rank(data,"prow")
	ship.resize_hull(HULLS[data.hull].size)
