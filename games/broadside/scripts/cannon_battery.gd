class_name CannonBattery
extends RefCounted
## Separate instances deliberately own independent reload clocks.
var remaining: float = 0.0
var stats: CannonStats
var side: float

func _init(definition: CannonStats, direction: float) -> void:
	stats = definition
	side = direction

func tick(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)

func ready() -> bool:
	return remaining <= 0.0

func consume() -> bool:
	if not ready():
		return false
	remaining = stats.reload_seconds
	return true

func muzzle(index: int) -> Vector2:
	return Vector2(side * 25.0, (index - (stats.gun_count - 1) * 0.5) * 16.0)
