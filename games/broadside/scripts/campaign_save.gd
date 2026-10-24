class_name CampaignSave
extends RefCounted
const VERSION: int = 1
var path: String = "user://campaign.json"
var data: Dictionary = {}
var error: String = ""

static func clean_name(value: String, fallback: String) -> String:
	var result: String = ""
	for character: String in value:
		if character.unicode_at(0) >= 32 and character.unicode_at(0) != 127:
			result += character
	result = result.strip_edges().left(28)
	return fallback if result.is_empty() else result

static func fresh(captain: String, ship: String, pennant: int = 0, voyage_seed: int = 0) -> Dictionary:
	return {"version":VERSION,"captain":clean_name(captain,"Captain Rowan"),"ship":clean_name(ship,"The Wayfarer"),"pennant":clampi(pennant,0,2),"seed":voyage_seed if voyage_seed != 0 else randi_range(1,2147483646),"chapter":1,"stop":0,"attempt":0,"active":false,"route":0,"gold":0,"salvage":0,"weapon":"standard","crew":"none","ships_sunk":0,"gold_earned":0,"journal":[],"hull":"sloop","upgrades":{},"health":60.0,"wins":0,"losses":0,"bosses":0}

func valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var d: Dictionary = value
	if d.get("version") != VERSION:
		return false
	for key: String in ["captain","ship","hull"]:
		if not d.get(key) is String or d[key].length() > 64:
			return false
	for key: String in ["pennant","seed","chapter","stop","attempt","route","gold","health","wins","losses","bosses"]:
		if not (d.get(key) is float or d.get(key) is int) or not is_finite(float(d[key])) or d[key] < 0 or d[key] > 2147483646:
			return false
	for key: String in ["pennant","seed","chapter","stop","attempt","route","gold","wins","losses","bosses"]:
		if float(d[key]) != floorf(float(d[key])): return false
	if not d.get("upgrades") is Dictionary: return false
	if not VoyageDirector.CREW.has(d.get("crew","none")): return false
	if not d.get("journal",[]) is Array or d.get("journal",[]).size() > 8: return false
	for entry: Variant in d.get("journal",[]):
		if not entry is String or entry.length() > 180: return false
	for key: String in ["ships_sunk","gold_earned"]:
		var count: Variant = d.get(key,0)
		if not (count is int or count is float) or not is_finite(float(count)) or count < 0 or count > 1000000000: return false
	for key: String in d.get("upgrades",{}):
		if not Shipyard.UPGRADES.has(key): return false
		var value_rank: Variant = d.upgrades[key]
		if not (value_rank is int or value_rank is float) or not is_finite(float(value_rank)) or float(value_rank) != floorf(float(value_rank)) or value_rank < 0 or value_rank > int(Shipyard.UPGRADES[key].max): return false
	if not Shipyard.WEAPONS.has(d.get("weapon","standard")): return false
	var salvage: Variant = d.get("salvage",0)
	if not (salvage is int or salvage is float) or not is_finite(float(salvage)) or salvage < 0 or salvage > 1000000000: return false
	return d.chapter >= 1 and d.stop < 5 and d.route < 3 and d.pennant < 3 and d.hull in ["sloop","brig","frigate","galleon"] and d.get("active") is bool and d.get("upgrades") is Dictionary

func read_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path,FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var parsed: Variant = parser.data
	return parsed if valid(parsed) else {}

func load_game() -> bool:
	error = ""
	data = read_file(path)
	if not data.is_empty():
		return true
	data = read_file(path+".bak")
	if not data.is_empty():
		error = "Recovered the previous safe save from backup."
		return true
	if FileAccess.file_exists(path):
		error = "Save unavailable or from an unsupported version. Original files preserved; start a new voyage only after confirmation."
	return false

func commit(next: Dictionary) -> bool:
	error = ""
	if not valid(next):
		error = "Invalid campaign state; save was not changed."
		return false
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		error = "Cannot write campaign save. Check available storage and folder access."
		return false
	file.store_string(JSON.stringify(next))
	file.flush()
	file.close()
	if read_file(path+".tmp").is_empty():
		error = "Save verification failed; previous files preserved."
		return false
	# Never replace the good backup with a corrupt main file.
	if not read_file(path).is_empty():
		if DirAccess.copy_absolute(path,path+".bak") != OK:
			error = "Cannot create campaign backup."
			return false
	if DirAccess.rename_absolute(path+".tmp",path) != OK:
		error = "Cannot replace campaign save; backup preserved."
		return false
	data = next.duplicate(true)
	return true

func begin_encounter(route: int = 0) -> bool:
	var next: Dictionary = data.duplicate(true)
	if not next.active:
		next.attempt = (int(next.attempt)+1) % 1000000000
		next.route = clampi(route,0,2)
	next.active = true
	return commit(next)

func settle(victory: bool, health: float, sunk: int = 1) -> bool:
	if data.is_empty() or not data.active:
		return false
	var next: Dictionary = data.duplicate(true)
	next.active = false
	next.health = maxf(0,health)
	if victory:
		next.wins = mini(int(next.wins)+1,1000000000)
		if int(next.stop) == 4:
			next.bosses = mini(int(next.bosses)+1,1000000000)
		next.stop = (int(next.stop)+1)%5
		if int(next.stop) == 0:
			next.chapter = int(next.chapter)%1000000000+1
	else:
		next.losses = mini(int(next.losses)+1,1000000000)
	if victory:
		var reward: int = VoyageDirector.reward(data)
		next.gold = mini(1000000000,int(next.gold)+reward)
		next.gold_earned = mini(1000000000,int(data.get("gold_earned",0))+reward)
		next.salvage = mini(1000000000,int(data.get("salvage",0))+2+Shipyard.rank(data,"cargo")+int(data.route))
		next.health = clampf(health+5*Shipyard.rank(data,"carpenter")+(8 if data.get("crew","none") == "carpenter" else 0),1,Shipyard.hull_for(data).max_health)
	else:
		# Rescue never removes upgrades or the hull. Starter gets a full emergency refit.
		next.gold = maxi(0,int(next.gold)-mini(25,int(next.gold)/4))
		next.health = maxf(60,Shipyard.hull_for(data).max_health*0.45)
		next.salvage = mini(1000000000,int(data.get("salvage",0))+1)
	next.ships_sunk = mini(1000000000,int(data.get("ships_sunk",0))+maxi(0,sunk))
	var entries: Array = data.get("journal",[]).duplicate()
	entries.append("Chapter %d • %s • %s%s" % [int(data.chapter),VoyageDirector.ROUTES[int(data.route)],"Victory" if victory else "Rescued",(" against "+VoyageDirector.encounter(data).boss_name) if int(data.stop) == 4 else ""])
	while entries.size() > 8: entries.pop_front()
	next.journal = entries
	return commit(next)
