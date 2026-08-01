extends CanvasLayer

const UPGRADE_CARD_SCENE = preload("res://upgrade_card.tscn")

@export var cards_to_offer: int = 3

@onready var header_title = %HeaderTitle
@onready var stonks_display = %StonksDisplay
@onready var stats_grid = %StatsGrid
@onready var spawner_list = %SpawnerList
@onready var cards_container = %CardsContainer

@onready var btn_resume = %BtnResume
@onready var btn_restart = %BtnRestart
@onready var btn_quit = %BtnQuit

var current_offered_cards: Array[Dictionary] = []

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

const RARITY_DATA = {
	Rarity.COMMON: {
		"name": "Gewöhnlich",
		"color": Color("#a0a0a0"),
		"weight": 65.0,
		"multiplier": 1.0,
		"cost": 10
	},
	Rarity.RARE: {
		"name": "Selten",
		"color": Color("#3a86ef"),
		"weight": 25.0,
		"multiplier": 1.6,
		"cost": 25
	},
	Rarity.EPIC: {
		"name": "Episch",
		"color": Color("#8338ec"),
		"weight": 8.0,
		"multiplier": 2.5,
		"cost": 50
	},
	Rarity.LEGENDARY: {
		"name": "Legendär",
		"color": Color("#ffbe0b"),
		"weight": 2.0,
		"multiplier": 4.0,
		"cost": 100
	}
}

# --- UPGRADE POOL (REIN GLOBALE STATS) ---
const UPGRADES_POOL: Array[Dictionary] = [
	{
		"id": "max_hp",
		"stat_name": "health_max",
		"title": "Vitalität",
		"type": "flat",
		"base_val": 15.0,
		"unit": " HP",
		"icon": "❤️"
	},
	{
		"id": "damage_mult",
		"stat_name": "damage",
		"title": "Kraft",
		"type": "mult",
		"base_val": 0.10, # +10% Schaden
		"unit": "% Schaden",
		"icon": "⚔️"
	},
	{
		"id": "range_flat",
		"stat_name": "range",
		"title": "Scharfschütze",
		"type": "flat",
		"base_val": 40.0,
		"unit": " Reichweite",
		"icon": "🎯"
	},
	{
		"id": "speed_flat",
		"stat_name": "speed",
		"title": "Leichtfuß",
		"type": "flat",
		"base_val": 40.0,
		"unit": " Tempo",
		"icon": "👟"
	},
	{
		"id": "armor_flat",
		"stat_name": "armor",
		"title": "Panzerung",
		"type": "flat",
		"base_val": 0.2,
		"unit": " Rüstung",
		"icon": "🛡️"
	},
	{
		"id": "attack_speed_mult",
		"stat_name": "attack_speed",
		"title": "Kugelhagel",
		"type": "mult",
		"base_val": 0.10, # +10% Angriffs-Tempo
		"unit": "% Angriffs-Tempo",
		"icon": "⚡"
	},
	{
		"id": "luck_flat",
		"stat_name": "luck",
		"title": "Glückspilz",
		"type": "flat",
		"base_val": 0.2,
		"unit": " Glück",
		"icon": "🍀"
	},
	{
		"id": "coin_value_flat",
		"stat_name": "coin_value",
		"title": "Gier",
		"type": "flat",
		"base_val": 3.0,
		"unit": " Stonks/Münze",
		"icon": "📈"
	},
	{
		"id": "heal_on_level_flat",
		"stat_name": "heal_on_level_up",
		"title": "Regeneration",
		"type": "flat",
		"base_val": 10.0,
		"unit": "% Level-Heal",
		"icon": "🧪"
	}
]


func _ready() -> void:
	hide()
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("item_collected"):
		EventBus.item_collected.connect(_on_item_collected)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func _on_item_collected(type: String, _specific_name: String) -> void:
	if visible and type == "coin":
		_refresh_menu_content()

func toggle_pause() -> void:
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

	if visible:
		var stats_node = get_tree().root.get_node_or_null("Game/Stats")
		var lvl = stats_node.level if stats_node else 1
		header_title.text = "⏸️ PAUSE (Lvl %d)" % lvl
		_refresh_menu_content()

func show_level_up() -> void:
	get_tree().paused = true
	visible = true
	
	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	var lvl = stats_node.level if stats_node else 1
	header_title.text = "🎉 LEVEL UP! (Lvl %d)" % lvl
	
	_generate_new_offer_pool()
	_refresh_menu_content()

func _refresh_menu_content() -> void:
	_update_stats_panel()
	_update_spawners_panel()
	_render_cards()


# ==========================================
# SPIELER STATS RENDEREN
# ==========================================
func _update_stats_panel() -> void:
	for child in stats_grid.get_children():
		child.queue_free()

	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	if not stats_node:
		return

	stonks_display.text = "📈 Stonks: %d" % stats_node.stonks

	var spd_val = stats_node.get_effective_stat("attack_speed")
	var speed_mult_percent = roundi(spd_val * 100.0)
	
	var dmg_val = stats_node.get_effective_stat("damage")
	var damage_mult_percent = roundi(dmg_val * 100.0)
	
	var global_range_bonus = int(stats_node.get_effective_stat("range"))

	var stats_to_show = [
		["Level", str(stats_node.level)],
		["Leben Max", str(int(stats_node.get_effective_stat("health_max")))],
		["Schaden", str(damage_mult_percent) + "%"],
		["Angriffs-Tempo", str(speed_mult_percent) + "%"],
		["Reichweite", "+" + str(global_range_bonus)],
		["Tempo", str(int(stats_node.get_effective_stat("speed")))],
		["Rüstung", str(int(stats_node.get_effective_stat("armor")))],
		["Glück", str(snappedf(stats_node.get_effective_stat("luck"), 0.1))],
		["Level-Heal", str(int(stats_node.get_effective_stat("heal_on_level_up"))) + "%"]
	]

	for item in stats_to_show:
		var lbl_name = Label.new()
		lbl_name.text = item[0] + ":"
		lbl_name.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

		var lbl_val = Label.new()
		lbl_val.text = item[1]
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		stats_grid.add_child(lbl_name)
		stats_grid.add_child(lbl_val)


# ==========================================
# SPAWNER ÜBERSICHT RENDEREN
# ==========================================
func _update_spawners_panel() -> void:
	for child in spawner_list.get_children():
		child.queue_free()

	var spawners = get_tree().get_nodes_in_group("spawners")

	if spawners.is_empty():
		var lbl = Label.new()
		lbl.text = "Keine aktiven Spawner."
		spawner_list.add_child(lbl)
		return

	for spawner in spawners:
		var box = VBoxContainer.new()
		
		var title = Label.new()
		title.text = "📍 " + spawner.name
		title.add_theme_font_size_override("font_size", 14)
		box.add_child(title)

		var info_text = ""
		if "level" in spawner:
			info_text += "• Level: " + str(spawner.level) + "\n"
		if "spawn_interval" in spawner:
			info_text += "• Intervall: " + str(snappedf(spawner.spawn_interval, 0.1)) + "s\n"
		if "damage_taken" in spawner and "damage_for_next_level" in spawner:
			info_text += "• HP Upgrade: " + str(spawner.damage_taken) + " / " + str(spawner.damage_for_next_level)

		var lbl_info = Label.new()
		lbl_info.text = info_text
		lbl_info.add_theme_font_size_override("font_size", 12)
		lbl_info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		box.add_child(lbl_info)

		spawner_list.add_child(box)


# ==========================================
# DYNAMISCHER SHOP
# ==========================================
func _generate_new_offer_pool() -> void:
	current_offered_cards.clear()
	
	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	var player_luck: float = 1.0
	var player_level: int = 1
	
	if stats_node:
		player_luck = stats_node.get_effective_stat("luck")
		player_level = stats_node.level

	var level_cost_multiplier: float = pow(1.08, player_level - 1)

	var available_pool = UPGRADES_POOL.duplicate()
	available_pool.shuffle()

	var count = min(cards_to_offer, available_pool.size())

	for i in range(count):
		var base_upgrade = available_pool[i]
		var rarity = _roll_rarity(player_luck)
		var rarity_info = RARITY_DATA[rarity]

		var final_val: float = base_upgrade["base_val"] * rarity_info["multiplier"]
		
		var base_cost: float = rarity_info["cost"]
		var final_cost: int = roundi(base_cost * level_cost_multiplier)

		var desc_text = ""
		if base_upgrade["type"] == "mult":
			var percent_val = roundi(final_val * 100.0)
			desc_text = ("+" if percent_val > 0 else "") + str(percent_val) + base_upgrade["unit"]
		else:
			var int_or_float = roundi(final_val) if final_val == int(final_val) else snappedf(final_val, 0.1)
			desc_text = ("+" if final_val > 0 else "") + str(int_or_float) + base_upgrade["unit"]

		var card_data = {
			"instance_id": randi(),
			"stat_name": base_upgrade["stat_name"],
			"type": base_upgrade["type"],
			"value": final_val,
			"cost": final_cost,
			"rarity_key": rarity,
			"title": base_upgrade["title"],
			"icon": base_upgrade["icon"],
			"description": desc_text
		}
		
		current_offered_cards.append(card_data)


func _render_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()

	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	var player_stonks: int = 0
	if stats_node:
		player_stonks = stats_node.stonks

	if current_offered_cards.is_empty():
		var lbl = Label.new()
		lbl.text = "Keine weiteren Angebote im Shop."
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		cards_container.add_child(lbl)
		return

	for card_data in current_offered_cards:
		var rarity_info = RARITY_DATA[card_data["rarity_key"]]
		var card_instance = UPGRADE_CARD_SCENE.instantiate()
		cards_container.add_child(card_instance)
		
		card_instance.setup(card_data, rarity_info, player_stonks)
		card_instance.selected.connect(_on_card_selected)


func _roll_rarity(luck: float) -> Rarity:
	var weight_common = maxf(10.0, RARITY_DATA[Rarity.COMMON]["weight"] / luck)
	var weight_rare = RARITY_DATA[Rarity.RARE]["weight"] * luck
	var weight_epic = RARITY_DATA[Rarity.EPIC]["weight"] * (luck * 1.2)
	var weight_legendary = RARITY_DATA[Rarity.LEGENDARY]["weight"] * (luck * 1.5)

	var total_weight = weight_common + weight_rare + weight_epic + weight_legendary
	var roll = randf_range(0.0, total_weight)

	if roll <= weight_legendary:
		return Rarity.LEGENDARY
	elif roll <= weight_legendary + weight_epic:
		return Rarity.EPIC
	elif roll <= weight_legendary + weight_epic + weight_rare:
		return Rarity.RARE
	else:
		return Rarity.COMMON


# KAUF-LOGIK
func _on_card_selected(upgrade_data: Dictionary) -> void:
	var stats_node = get_tree().root.get_node_or_null("Game/Stats")
	if not stats_node:
		return
		
	var cost = upgrade_data["cost"]
	
	if stats_node.stonks >= cost:
		stats_node.add_stat("stonks", -cost)
		
		var stat_name = upgrade_data["stat_name"]
		var amount = upgrade_data["value"]
		
		if upgrade_data["type"] == "mult":
			stats_node.add_upgrade_mult(stat_name, amount)
		else:
			stats_node.add_upgrade_flat(stat_name, amount)

		if stat_name == "range":
			_update_all_weapon_shapes()

		for i in range(current_offered_cards.size() - 1, -1, -1):
			if current_offered_cards[i]["instance_id"] == upgrade_data["instance_id"]:
				current_offered_cards.remove_at(i)
				break

		_refresh_menu_content()

func _update_all_weapon_shapes() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var weapon_manager = player.get_node_or_null("WeaponManager")
		if weapon_manager:
			for weapon in weapon_manager.get_children():
				if weapon.has_method("update_range_shape"):
					weapon.update_range_shape()


# BUTTON ACTIONS
func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()