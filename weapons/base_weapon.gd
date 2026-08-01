class_name BaseWeapon
extends Node2D

@export_group("Weapon Config")
@export var weapon_id: String = "pistol"
@export var database: WeaponDatabase = preload("res://weapons/weapon_database.tres")

@export_group("Debug Visuals")
@export var show_debug_range: bool = true
@export var debug_color: Color = Color(0.2, 0.8, 1.0, 0.4)

var data: WeaponData

var bonus_damage: float = 0.0
var bonus_attack_speed: float = 0.0
var bonus_range: float = 0.0

var attack_timer: Timer

func _ready() -> void:
	_load_weapon_data()
	_setup_timer()
	_on_ready_weapon()
	update_range_shape()

func _load_weapon_data() -> void:
	if database:
		data = database.get_weapon(weapon_id)
	if not data:
		push_warning("Waffe '" + name + "' hat keine Daten für ID '" + weapon_id + "' in weapon_database.tres gefunden!")

func get_base_damage() -> float:
	return data.base_damage if data else 10.0

func get_base_attack_speed() -> float:
	return data.base_attack_speed if data else 1.0

func get_base_range() -> float:
	return data.base_range if data else 200.0

func get_weapon_name() -> String:
	return data.weapon_name if data else "Waffe"

# NEU: Verrechnet Waffen-Schaden mit dem globalen Schaden-Multiplikator aus stats.gd
func get_effective_damage() -> float:
	var global_damage_mult: float = 1.0
	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	
	if stats_node and stats_node.has_method("get_effective_stat"):
		var stat_dmg = stats_node.get_effective_stat("damage")
		if stat_dmg > 0:
			global_damage_mult = stat_dmg
			
	return maxf(1.0, (get_base_damage() + bonus_damage) * global_damage_mult)

func get_effective_range() -> float:
	var global_bonus: float = 0.0
	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	
	if stats_node and stats_node.has_method("get_effective_stat"):
		var stat_rng = stats_node.get_effective_stat("range")
		if stat_rng > 0:
			global_bonus = stat_rng
			
	return maxf(10.0, get_base_range() + bonus_range + global_bonus)

func get_effective_cooldown() -> float:
	var global_speed_mult: float = 1.0
	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	
	if stats_node and stats_node.has_method("get_effective_stat"):
		var stat_spd = stats_node.get_effective_stat("attack_speed")
		if stat_spd > 0:
			global_speed_mult = stat_spd
			
	var total_aps = maxf(0.05, (get_base_attack_speed() + bonus_attack_speed) * global_speed_mult)
	return maxf(0.02, 1.0 / total_aps)

func _process(_delta: float) -> void:
	if show_debug_range:
		queue_redraw()

func _draw() -> void:
	var current_range = get_effective_range()
	if show_debug_range and current_range > 0:
		_draw_dashed_circle(Vector2.ZERO, current_range, debug_color, 1.5, 16)

func _draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float, dash_count: int) -> void:
	var step = TAU / dash_count
	var dash_angle = step * 0.6
	for i in range(dash_count):
		var start_a = i * step
		var end_a = start_a + dash_angle
		draw_arc(center, radius, start_a, end_a, 6, color, width, true)

func update_range_shape() -> void:
	var current_rng = get_effective_range()
	
	for child in get_children():
		if child is Area2D:
			for col in child.get_children():
				if col is CollisionShape2D and col.shape is CircleShape2D:
					if not col.shape.resource_local_to_scene:
						col.shape = col.shape.duplicate()
					col.shape.radius = current_rng
	queue_redraw()

func _setup_timer() -> void:
	attack_timer = Timer.new()
	attack_timer.one_shot = false
	add_child(attack_timer)
	attack_timer.timeout.connect(attack)
	update_cooldown()
	attack_timer.start()

func update_cooldown() -> void:
	if attack_timer:
		attack_timer.wait_time = get_effective_cooldown()

func _on_ready_weapon() -> void:
	pass

func attack() -> void:
	update_cooldown()
	update_range_shape()
	_execute_attack()

func _execute_attack() -> void:
	pass