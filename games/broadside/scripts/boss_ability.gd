class_name BossAbility
extends RefCounted
## Bounded, interruptible boss phases. Every release rechecks visibility, cover and alignment.
const SPECS: Dictionary = {
	"warden":{"name":"Double Volley","tell":1.6,"cooldown":13.0,"cue":"boss_bell"},
	"corsair":{"name":"Rigging Breaker","tell":1.8,"cooldown":14.0,"cue":"boss_chain"},
	"regent":{"name":"Squall Charge","tell":2.0,"cooldown":16.0,"cue":"boss_charge"}}
var role: String
var phase: String = "ready"
var timer: float = 0.0
var cooldown: float = 6.0
var charge_heading: float = 0.0
var activations: int = 0
var salvos: int = 0
func _init(kind: String = "warden") -> void: role = kind
func caption() -> String:
	if phase == "ready": return "%s • ready in %.0fs" % [SPECS[role].name,ceilf(cooldown)]
	if phase == "rest": return "Recovering • strike now!"
	return "%s! %s %.1fs" % [SPECS[role].name,{"warn":"WARNING","second":"SECOND VOLLEY","charge":"CHARGING","release":"HEAVY BROADSIDE"}.get(phase,""),maxf(0,timer)]
func finish() -> void:
	phase = "rest"
	timer = 2.0
	cooldown = SPECS[role].cooldown
func shoot(ship: Node, special: String = "") -> void:
	var original: CannonStats = ship.guns.duplicate()
	var loadout: CannonStats = original.duplicate()
	if special == "chain": loadout.damage = 10; loadout.slow_seconds = 2
	if special == "heavy": loadout.damage = 20
	ship.set_cannon_loadout(loadout)
	if ship.fire_loaded() > 0: salvos += 1
	ship.set_cannon_loadout(original)
func tick(ship: Node, delta: float, safe: bool, aligned: bool) -> bool:
	cooldown = maxf(0,cooldown-delta)
	if phase == "ready":
		if cooldown > 0 or not safe or not aligned or not (ship.port.ready() or ship.starboard.ready()): return false
		phase = "warn"
		timer = SPECS[role].tell
		activations += 1
		ship.arena.sound(SPECS[role].cue,ship.global_position)
		ship.warning = 0
		return true
	if phase == "rest":
		timer -= delta
		if timer <= 0: phase = "ready"
		return true
	if not safe:
		finish()
		return true
	timer -= delta
	if timer > 0: return true
	match phase:
		"warn":
			if not aligned: finish(); return true
			match role:
				"warden":
					shoot(ship)
					phase = "second"
					timer = 0.9
				"corsair": shoot(ship,"chain"); finish()
				"regent":
					phase = "charge"
					timer = 1.1
					charge_heading = ship.rotation
		"second":
			if aligned:
				ship.port.remaining = 0
				ship.starboard.remaining = 0
				shoot(ship)
			finish()
		"charge":
			phase = "release"
			timer = 1.0
			ship.arena.sound("boss_bell",ship.global_position)
		"release":
			if aligned: shoot(ship,"heavy")
			finish()
	return true
