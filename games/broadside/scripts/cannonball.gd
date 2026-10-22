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
		get_parent().effect(position, Color("d6bb86"), 18.0)
		queue_free()
		return
	position = destination
	if age >= stats.projectile_lifetime:
		get_parent().effect(position, Color("a1d7cf"), 22.0)
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_line(-direction * 14.0, Vector2.ZERO, Color(0.95,0.83,0.56,0.65), 3.0, true)
	draw_circle(Vector2.ZERO, 4.0, Color("ffe0a0"))
