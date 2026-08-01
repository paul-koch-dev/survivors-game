class_name RangedWeapon
extends BaseWeapon

@export_group("Ranged Setup")
@export var projectile_scene: PackedScene = preload("res://weapons/bullet.tscn")
@export var detection_area: Area2D

var bonus_bullet_speed: float = 0.0

func get_base_bullet_speed() -> float:
	return data.projectile_speed if data else 1000.0

func get_effective_bullet_speed() -> float:
	return get_base_bullet_speed() + bonus_bullet_speed

func _execute_attack() -> void:
	if not is_instance_valid(detection_area):
		detection_area = get_node_or_null("DetectionArea") as Area2D

	var target = _find_target()
	if target:
		look_at(target.global_position)
		_spawn_projectile()

func _find_target() -> Node2D:
	if not is_instance_valid(detection_area):
		return null

	var bodies = detection_area.get_overlapping_bodies()
	for body in bodies:
		if is_instance_valid(body) and body != self and not body.is_in_group("player"):
			if body.has_method("take_damage"):
				return body
	return null

func _spawn_projectile() -> void:
	if not projectile_scene:
		projectile_scene = load("res://weapons/bullet.tscn") as PackedScene
		
	if not projectile_scene:
		return
		
	var bullet = projectile_scene.instantiate()
	
	var spawn_pos = global_position
	var spawn_rot = global_rotation
	
	var shooting_point = get_node_or_null("WeaponPivot/Pistol/ShootingPoint")
	if is_instance_valid(shooting_point):
		spawn_pos = shooting_point.global_position
		spawn_rot = shooting_point.global_rotation

	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(bullet)
	else:
		get_parent().add_child(bullet)

	bullet.global_position = spawn_pos
	bullet.global_rotation = spawn_rot

	if "speed" in bullet:
		bullet.speed = get_effective_bullet_speed()
	if "damage" in bullet:
		bullet.damage = get_effective_damage()
	if "max_distance" in bullet:
		bullet.max_distance = get_effective_range()