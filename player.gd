extends CharacterBody2D

var speed: float = 600.0
var health_max: float = 100.0
var health: float = 100.0
var armor: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_fetch_stats_from_manager()


func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	if velocity.length() > 0:
		$HappyBoo.play_walk_animation()
	else:
		$HappyBoo.play_idle_animation()

	_check_hurt_box()


func _check_hurt_box() -> void:
	if health <= 0:
		return

	var overlapping_bodies = $HurtBox.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.has_method("deal_damage"):
			body.deal_damage()


# --- SCHADEN & HEILUNG ---

func take_damage(amount: float) -> void:
	DamageNumber.spawn(amount, global_position, true)
	if health <= 0:
		return

	var effective_damage = maxf(1.0, amount - armor)
	health = clampf(health - effective_damage, 0.0, health_max)
	
	_sync_health_to_stats()
	
	if health <= 0:
		if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("player_died"):
			EventBus.player_died.emit()


func heal(amount: float) -> void:
	if health <= 0:
		return
		
	health = clampf(health + amount, 0.0, health_max)
	_sync_health_to_stats()


# --- HELFER-FUNKTIONEN ---

func _fetch_stats_from_manager() -> void:
	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	if stats_node and "player_stats" in stats_node:
		var p_stats = stats_node.player_stats
		speed = p_stats.get("speed", speed)
		health_max = p_stats.get("health_max", health_max)
		armor = p_stats.get("armor", armor)
		health = p_stats.get("health", health_max)


func _sync_health_to_stats() -> void:
	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	if stats_node and stats_node.has_method("set_stat"):
		stats_node.set_stat("health", health)