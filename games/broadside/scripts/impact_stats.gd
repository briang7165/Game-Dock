class_name ImpactStats
extends Resource
@export var minimum_speed: float = 35.0
@export var damage_per_speed: float = 0.22
@export var maximum_damage: float = 32.0
@export var cooldown_seconds: float = 0.75
@export var separation_seconds: float = 0.12
@export var contact_margin: float = 3.0

func damage_for_speed(closing_speed: float) -> float:
	return clampf((closing_speed-minimum_speed)*damage_per_speed,0.0,maximum_damage)
