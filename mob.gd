extends CharacterBody2D

const SMOKE_EXPLOSION = preload("res://smoke_explosion/smoke_explosion.tscn")
const PICKUP_SCENE = preload("res://pickup.tscn")

@onready var player = get_tree().get_first_node_in_group("player")

@onready var health_bar = %HealthBar
@onready var level_label = %LevelLabel

signal slime_died(xp_amount: int)

@export_group("Base Stats (Level 1)")
@export var base_speed: float = 100.0
@export var base_damage: int = 10
@export var base_health: int = 5
@export var base_xp: int = 10

@export_group("Growth Factors (Per Level)")
@export var speed_growth: float = 25.0    
@export var damage_growth: float = 0.5   
@export var health_growth: float = 1.5   
@export var xp_multiplier: float = 1.3   

@export_group("Coin Drops (Balancing)")
@export var base_max_coins: int = 1        
@export var max_coins_growth: float = 0.2     
@export var base_coin_chance: float = 0.30    
@export var coin_chance_growth: float = 0.015 
@export var max_coin_chance: float = 0.50     
@export var spawn_spread_radius: float = 175.0 

var speed: float = 100.0
var damage: int = 1
var health: int = 2
var xp_amount: int = 10
var current_level: int = 1

var max_health: int = 2

var is_recoiling: bool = false
var can_attack: bool = true
@export var recoil_force: float = 300.0   
@export var attack_cooldown: float = 0.8 

func _ready() -> void:
	if has_node("Slime"):
		$Slime.play_walk()
	
	initialize_slime(current_level)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	if is_recoiling:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
	else:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed

	move_and_slide()
	_check_for_player_collision()

func _check_for_player_collision() -> void:
	if not can_attack or is_recoiling:
		return

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider == player or (collider and collider.is_in_group("player")):
			attack(collider)
			break

func attack(target_player: Node2D) -> void:
	can_attack = false
	is_recoiling = true

	if target_player.has_method("take_damage"):
		target_player.take_damage(damage)

	var bounce_direction = player.global_position.direction_to(global_position)
	velocity = bounce_direction * recoil_force

	get_tree().create_timer(0.2).timeout.connect(func(): 
		is_recoiling = false 
	)

	get_tree().create_timer(attack_cooldown).timeout.connect(func(): 
		can_attack = true 
	)

func deal_damage() -> void:
	if can_attack and not is_recoiling and is_instance_valid(player):
		attack(player)

func take_damage(amount: int) -> void:
	DamageNumber.spawn(amount, global_position, false)
	health -= amount
	
	if health_bar:
		health_bar.value = health

	if health <= 0:
		die()
	elif has_node("Slime"):
		$Slime.play_hurt()

func initialize_slime(level: int) -> void:
	current_level = level
	var level_offset = current_level - 1
	
	speed = base_speed + (level_offset * speed_growth)
	damage = roundi(base_damage + (level_offset * damage_growth))
	
	max_health = roundi(base_health + (level_offset * health_growth))
	health = max_health 
	
	var multiplied_xp = float(base_xp) * pow(xp_multiplier, level_offset)
	xp_amount = roundi(multiplied_xp)
	
	_update_ui_elements()

func set_level(level: int) -> void:
	initialize_slime(level)

func _update_ui_elements() -> void:
	if level_label:
		level_label.text = "Lvl " + str(current_level)
		
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

func die() -> void:
	var smoke_explosion = SMOKE_EXPLOSION.instantiate()
	smoke_explosion.global_position = global_position
	get_parent().add_child(smoke_explosion)

	_spawn_coin_drops()

	slime_died.emit(xp_amount)
	
	if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("enemy_died"):
		EventBus.enemy_died.emit(xp_amount)

	queue_free()

func _spawn_coin_drops() -> void:
	var level_offset = current_level - 1
	var max_possible_coins = roundi(base_max_coins + (level_offset * max_coins_growth))
	var current_chance = clampf(base_coin_chance + (level_offset * coin_chance_growth), 0.0, max_coin_chance)
	
	var coins_to_spawn: int = 0
	for i in range(max_possible_coins):
		if randf() < current_chance:
			coins_to_spawn += 1
			
	for i in range(coins_to_spawn):
		var pickup_instance = PICKUP_SCENE.instantiate()
		
		var random_angle = randf() * TAU
		var random_dist = randf_range(30.0, spawn_spread_radius)
		var random_offset = Vector2.RIGHT.rotated(random_angle) * random_dist
		
		pickup_instance.global_position = global_position + random_offset
		pickup_instance.setup("coin") 
		get_parent().add_child(pickup_instance)