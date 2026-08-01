extends CanvasLayer

@onready var stats_label = %StatsLabel
@onready var health_bar = %HealthBar
@onready var health_label = %HealthLabel
@onready var armor_label = %ArmorLabel
var player: Node2D = null

# ==========================================
# 1. BALANCING CONFIG (GLOBALE SPIELER-BASISWERTE)
# ==========================================
@export_group("Base Stats (Balancing Config)")
@export var base_stats: Dictionary = {
	# Spieler & Survivability
	"speed": 600.0,
	"health_max": 100.0,
	"armor": 0.0,
	"luck": 1.0,
	"crit_chance": 0.05,
	"pickup_range": 100.0,
	"regen": 0.0,
	"xp_multiplier": 1.0,
	"fruit_heal": 15.0,
	"coin_value": 10.0,
	"heal_on_level_up": 20.0,
	
	# Globale Waffen-Modifikationen
	"attack_speed": 1.0,
	"range": 0.0,
	"damage": 1.0  # <-- NEU: Globaler Schaden-Multiplikator (1.0 = 100%)
}

# ==========================================
# 2. UPGRADE MODIFIERS (SHOP / LEVEL UP)
# ==========================================
var upgrade_additions: Dictionary = {}
var upgrade_multipliers: Dictionary = {}

# ==========================================
# 3. RUNTIME STATS & RESSOURCEN
# ==========================================
var current_health: float = 100.0
var effective_stats: Dictionary = {}

var score: int = 0
var kills: int = 0
var level: int = 1
var xp: int = 0
var stonks: int = 0

@export_group("Level Up Settings")
@export var base_xp_required: int = 100
@export var xp_growth_exponent: float = 1.35
var xp_next_level: int = 100

var survival_time: float = 0.0
var is_game_active: bool = true

var collected_loot: Dictionary = {
	"coin": 0,
	"fruit": 0
}
var collected_items: Array = []


func _ready() -> void:
	EventBus.item_collected.connect(_on_item_collected)
	
	if EventBus.has_signal("enemy_died"):
		EventBus.enemy_died.connect(_on_enemy_died)
		
	if EventBus.has_signal("player_died"):
		EventBus.player_died.connect(_on_player_died)
		
	xp_next_level = _calculate_xp_next_level(level)
	
	recalculate_effective_stats()
	current_health = get_effective_stat("health_max")
	
	_apply_stats_to_player()
	update_ui()


func _get_player() -> Node2D:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	return player


# ==========================================
# 4. BERECHNUNG DER EFFEKTIVEN WERTE
# ==========================================
func recalculate_effective_stats() -> void:
	for stat_name in base_stats.keys():
		var base_val: float = base_stats[stat_name]
		var add_val: float = upgrade_additions.get(stat_name, 0.0)
		var mult_val: float = upgrade_multipliers.get(stat_name, 0.0)
		
		var final_val: float = (base_val + add_val) * (1.0 + mult_val)
		effective_stats[stat_name] = final_val

	var max_hp = get_effective_stat("health_max")
	current_health = clampf(current_health, 0.0, max_hp)

func get_effective_stat(stat_name: String) -> float:
	return effective_stats.get(stat_name, base_stats.get(stat_name, 0.0))


# ==========================================
# 5. UPGRADES HINZUFÜGEN
# ==========================================
func add_upgrade_flat(stat_name: String, amount: float) -> void:
	if not upgrade_additions.has(stat_name):
		upgrade_additions[stat_name] = 0.0
		
	upgrade_additions[stat_name] += amount
	recalculate_effective_stats()
	_apply_stats_to_player()
	update_ui()

func add_upgrade_mult(stat_name: String, amount: float) -> void:
	if not upgrade_multipliers.has(stat_name):
		upgrade_multipliers[stat_name] = 0.0
		
	upgrade_multipliers[stat_name] += amount
	recalculate_effective_stats()
	_apply_stats_to_player()
	update_ui()


# ==========================================
# 6. GENERAL STATS & RESSOURCEN
# ==========================================
func add_stat(stat_name: String, amount: float) -> void:
	match stat_name:
		"score": score += int(amount)
		"kills": kills += int(amount)
		"level": level += int(amount)
		"stonks": stonks += int(amount)
		"xp":    add_xp(amount)
		"health":
			var max_hp = get_effective_stat("health_max")
			current_health = clampf(current_health + amount, 0.0, max_hp)
		_:
			add_upgrade_flat(stat_name, amount)
			return

	update_ui()

func set_stat(stat_name: String, value: float) -> void:
	match stat_name:
		"score": score = int(value)
		"kills": kills = int(value)
		"level": level = int(value)
		"stonks": stonks = int(value)
		"xp":    xp = int(value)
		"health":
			var max_hp = get_effective_stat("health_max")
			current_health = clampf(value, 0.0, max_hp)
		_:
			push_warning("set_stat für dynamische Upgrades nicht empfohlen. Nutze add_upgrade_flat/mult!")
			return

	update_ui()

func _apply_stats_to_player() -> void:
	var target_player = _get_player()
	if not is_instance_valid(target_player):
		return
		
	for stat_name in effective_stats:
		if stat_name in target_player:
			target_player.set(stat_name, effective_stats[stat_name])
			
	if "health" in target_player:
		target_player.set("health", current_health)


# ==========================================
# 7. DIE STOPPUHR & UI
# ==========================================
func _process(delta: float) -> void:
	if is_game_active and not get_tree().paused:
		survival_time += delta
		update_ui()

func get_time_string() -> String:
	var minutes: int = int(survival_time) / 60
	var seconds: int = int(survival_time) % 60
	return "%02d:%02d" % [minutes, seconds]

func update_ui() -> void:
	if stats_label:
		stats_label.text = "Time: %s\nScore: %d | Kills: %d\n📈 Stonks: %d\nLvl: %d (XP: %d/%d)" % [
			get_time_string(), score, kills, stonks, level, xp, xp_next_level
		]

	if health_bar:
		var max_hp: int = int(get_effective_stat("health_max"))
		var cur_hp: int = int(current_health)
		
		health_bar.max_value = max_hp
		health_bar.value = cur_hp

		if health_label:
			health_label.text = "%d / %d" % [cur_hp, max_hp]

	if armor_label:
		var armor_val = get_effective_stat("armor")
		armor_label.text = "🛡️ Armor: %d" % int(armor_val)


# ==========================================
# 8. XP & LEVEL-UP LOGIK
# ==========================================
func _calculate_xp_next_level(target_level: int) -> int:
	return roundi(base_xp_required * pow(target_level, xp_growth_exponent))

func add_xp(amount: float) -> void:
	var multiplier: float = get_effective_stat("xp_multiplier")
	var final_xp_gained: int = roundi(amount * multiplier)
	
	xp += final_xp_gained
	while xp >= xp_next_level:
		xp -= xp_next_level
		_trigger_level_up()

	update_ui()

func _trigger_level_up() -> void:
	level += 1
	xp_next_level = _calculate_xp_next_level(level)
	
	var heal_percent: float = get_effective_stat("heal_on_level_up")
	if heal_percent > 0.0:
		var max_hp: float = get_effective_stat("health_max")
		var heal_amount: float = max_hp * (heal_percent / 100.0)
		add_stat("health", heal_amount)

	_vacuum_all_pickups()
	
	if has_node("%LevelUpMenu"):
		%LevelUpMenu.show_level_up()


func _vacuum_all_pickups() -> void:
	var target_player = _get_player()
	if not is_instance_valid(target_player):
		return

	var pickups = get_tree().get_nodes_in_group("pickups")
	for pickup in pickups:
		if is_instance_valid(pickup) and pickup.has_method("collect_via_magnet"):
			pickup.collect_via_magnet(target_player)


# ==========================================
# 9. EVENT-HANDLING & EXPORTS
# ==========================================
func _on_item_collected(type: String, specific_name: String) -> void:
	if collected_loot.has(type):
		collected_loot[type] += 1
	else:
		collected_loot[type] = 1

	if type == "fruit":
		var heal_val: float = get_effective_stat("fruit_heal")
		var max_hp: float = get_effective_stat("health_max")

		if current_health >= max_hp:
			add_stat("score", heal_val)
		else:
			add_stat("health", heal_val)

	elif type == "coin":
		var stonks_gained: float = get_effective_stat("coin_value")
		add_stat("stonks", stonks_gained)

	if type == "upgrade":
		collected_items.append(specific_name)

func _on_enemy_died(xp_amount: int) -> void:
	add_xp(xp_amount)
	add_stat("kills", 1)
	add_stat("score", xp_amount * 5)

func _on_player_died() -> void:
	is_game_active = false

func _on_btn_pause_pressed() -> void:
	if has_node("%LevelUpMenu"):
		%LevelUpMenu.toggle_pause()

func get_stats() -> Dictionary:
	return {
		"score": score,
		"stonks": stonks,
		"kills": kills,
		"level": level,
		"xp": xp,
		"survival_time": survival_time,
		"loot": collected_loot
	}