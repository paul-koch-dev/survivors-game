extends Area2D

var speed: float = 1000.0
var max_distance: float = 1000.0
var damage: float = 10.0
var travelled_distance: float = 0.0

func _physics_process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta

	travelled_distance += speed * delta

	if travelled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body == self:
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif not body is Area2D:
		queue_free()