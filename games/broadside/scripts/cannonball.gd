extends Node2D
## Swept segment per physics tick prevents tunnelling through thin terrain.
var source: BroadsideShip
var stats: CannonStats
var direction: Vector2
var age: float = 0.0

func _physics_process(delta: float) -> void:
	var destination: Vector2 = position + direction * stats.projectile_speed * delta
	var query := PhysicsRayQueryParameters2D.create(position, destination, 3, [source.get_rid()])
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	age += delta
	if not hit.is_empty():
		position = hit.position
		if hit.collider is BroadsideShip:
			hit.collider.take_damage(stats.damage)
			hit.collider.rigging_slow = maxf(hit.collider.rigging_slow,stats.slow_seconds)
			get_parent().sound("wood", position)
		else:
			get_parent().sound("rock", position)
		get_parent().effect(position, Color("8de4dd") if stats.slow_seconds > 0 else Color("d6bb86"), 24.0 if stats.slow_seconds > 0 else 18.0)
		queue_free()
		return
	position = destination
	if age >= stats.projectile_lifetime:
		get_parent().sound("splash", position)
		get_parent().effect(position, Color("a1d7cf"), 22.0)
		queue_free()
	queue_redraw()

func _draw() -> void:
	var chain: bool = stats.slow_seconds > 0
	var color := Color("8de4dd") if chain else (Color("f6ad7a") if stats.weapon_style == "carronade" else Color("ffe8ae"))
	var trail: float = 36 if stats.weapon_style == "long" else 22
	draw_line(-direction*trail,Vector2.ZERO,Color(color,0.65),3.0,true)
	if chain:
		var cross: Vector2 = direction.orthogonal()*9
		draw_line(-cross,cross,Color("172f3b"),5,true)
		draw_line(-cross,cross,color,2,true)
		for at: Vector2 in [-cross,cross]:
			draw_circle(at,6,Color("18313b"))
			draw_circle(at,4,color)
	else:
		draw_circle(Vector2.ZERO,8 if stats.weapon_style == "carronade" else 7,Color("21333b"))
		draw_circle(Vector2.ZERO,6 if stats.weapon_style == "carronade" else 5,color)
