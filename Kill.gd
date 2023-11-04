extends Area3D
const SPAWN_RANDOM := 5.0

func _on_body_exited(body):
	var pos := Vector2.from_angle(randf() * 2 * PI)
	body.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
