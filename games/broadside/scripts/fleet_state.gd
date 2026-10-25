class_name FleetState
extends RefCounted
## The flat active-ship projection keeps combat independent of harbor bookkeeping.
const FIELDS: Array[String] = ["ship", "health", "upgrades", "weapon", "owned_weapons"]
static func bare(id: String) -> Dictionary:
	return {"ship":"The "+id.capitalize(),"health":Shipyard.HULLS[id].hp,"upgrades":{},"weapon":"standard","owned_weapons":["standard"]}
static func capture(data: Dictionary) -> void:
	var vessel: Dictionary = data.fleet[data.hull]
	for key: String in FIELDS:
		vessel[key] = data.get(key,"standard" if key == "weapon" else ["standard"]) if key != "upgrades" else data.upgrades.duplicate(true)
	if not vessel.owned_weapons.has(vessel.weapon): vessel.owned_weapons.append(vessel.weapon)
static func project(data: Dictionary, id: String) -> void:
	data.hull = id
	for key: String in FIELDS:
		var value: Variant = data.fleet[id][key]
		data[key] = value.duplicate(true) if value is Dictionary or value is Array else value
static func view(data: Dictionary, id: String) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if not result.get("fleet",{}).has(id):
		result.fleet[id] = bare(id)
	project(result,id)
	return result
static func migrate(legacy: Dictionary) -> Dictionary:
	var next: Dictionary = legacy.duplicate(true)
	next.version = 2
	next.revision = 0
	next.owned_weapons = ["standard"]
	next.fleet = {"sloop":bare("sloop")}
	next.fleet[next.hull] = bare(next.hull)
	capture(next)
	project(next,next.hull)
	return next
