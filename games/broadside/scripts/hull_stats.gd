class_name HullStats
extends Resource
## One shared definition; runtime HP/speed always belong to each ship instance.
@export var title: String = "Sloop"
@export var max_health: float = 100.0
@export var top_speed: float = 165.0
@export var reverse_speed: float = 22.0
@export var acceleration: float = 42.0
@export var braking: float = 60.0
@export var drag: float = 7.0
@export var water_resistance: float = 0.0003
@export var turn_rate: float = 0.85
@export var rudder_acceleration: float = 1.35
@export_range(0.0, 1.0) var stationary_steering: float = 0.12
@export var lateral_drag: float = 3.5
@export var max_drift: float = 18.0
