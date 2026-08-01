extends StaticBody2D

const MOB_SCENE = preload("res://mob.tscn")

@export_group("Spawner Settings")
@export var spawn_interval: float = 5.0
@export var level: int = 1
@export var damage_for_next_level: float = 20

var damage_taken: float = 0
var timer: Timer

@onready var progress_bar = $ProgressBar if has_node("ProgressBar") else null
@onready var label = $Label if has_node("Label") else null


func _ready() -> void:
	add_to_group("spawners")

	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(spawn)
	timer.wait_time = spawn_interval
	timer.start()

	_update_ui()


func spawn() -> void:
	var mob_instance = MOB_SCENE.instantiate()
	mob_instance.global_position = global_position
	get_parent().add_child(mob_instance)
	
	if mob_instance.has_method("initialize_slime"):
		mob_instance.initialize_slime(level)


func take_damage(amount: int) -> void:
	DamageNumber.spawn(amount, global_position, false)
	damage_taken += amount
	_update_ui()

	if damage_taken >= damage_for_next_level:
		level_up_spawner()


func level_up_spawner() -> void:
	level += 1
	damage_taken = 0
	damage_for_next_level *= 1.3
	spawn_interval = maxf(1.0, spawn_interval - 0.5)
	
	if timer:
		timer.wait_time = spawn_interval

	_update_ui()


func _update_ui() -> void:
	if progress_bar:
		progress_bar.max_value = damage_for_next_level
		progress_bar.value = damage_taken

	if label:
		label.text = "Lvl %d" % level