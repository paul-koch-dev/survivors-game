extends CanvasLayer

@onready var stats_grid = $CenterContainer/PanelContainer/MarginContainer/VBox/StatsGrid

func _ready() -> void:
	# 1. Menü beim Start verstecken
	hide()
	
	# 2. Verbinden mit dem EventBus
	if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("player_died"):
		EventBus.player_died.connect(show_game_over)
		
	# 3. Buttons verbinden (Pfade ggf. anpassen)
	var btn_restart = $CenterContainer/PanelContainer/MarginContainer/VBox/ButtonBox/BtnRestart
	var btn_quit = $CenterContainer/PanelContainer/MarginContainer/VBox/ButtonBox/BtnQuit
	
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)


func show_game_over() -> void:
	# 1. Spiel pausieren
	get_tree().paused = true
	
	# 2. Stats dynamisch ins Menü laden
	_populate_stats()
	
	# 3. Menü anzeigen
	show()


func _populate_stats() -> void:
	# Mache das Grid leer (falls wir es mehrmals aufrufen)
	for child in stats_grid.get_children():
		child.queue_free()
		
	# Hole die Stats (Passe den Pfad zu deiner Stats-Node an, oder nutze Autoload!)
	# Wenn deine stats.gd z.B. als Singleton "GameStats" läuft, schreibe hier GameStats.get_stats()
	var stats_node = get_tree().root.get_node_or_null("Game/Stats") 
	if not stats_node:
		return
		
	var final_stats = stats_node.get_stats()
	
	# Gehe durch alle Stats aus dem Dictionary
	for key in final_stats.keys():
		var value = final_stats[key]
		
		# Wenn der Wert ein Dictionary ist (wie "loot"), dröseln wir es auf!
		if typeof(value) == TYPE_DICTIONARY:
			for sub_key in value.keys():
				var nice_name = format_name(sub_key)
				add_stat_row(nice_name, str(value[sub_key]))
		# Bei Überlebenszeit machen wir ein schönes MM:SS Format daraus
		elif key == "survival_time":
			var minutes = int(value) / 60
			var seconds = int(value) % 60
			add_stat_row("Zeit überlebt", "%02d:%02d" % [minutes, seconds])
		# Alles andere (Kills, XP, Score)
		else:
			add_stat_row(format_name(key), str(value))


# Hilfsfunktion: Fügt eine neue Zeile (Name links, Wert rechts) ins Grid ein
func add_stat_row(stat_name: String, stat_value: String) -> void:
	# Linkes Label (Name)
	var name_label = Label.new()
	name_label.text = stat_name + ":"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Rechtes Label (Wert)
	var value_label = Label.new()
	value_label.text = stat_value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Schiebt den Wert ganz nach rechts
	
	# Ins Grid werfen (Godot ordnet es automatisch zweispaltig an!)
	stats_grid.add_child(name_label)
	stats_grid.add_child(value_label)


# Hilfsfunktion: Macht aus "score" -> "Score" und "survival_time" -> "Survival Time"
func format_name(key: String) -> String:
	var words = key.split("_")
	var formatted = ""
	for word in words:
		formatted += word.capitalize() + " "
	return formatted.strip_edges()


# --- BUTTON LOGIK ---

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene() # Lädt das Level neu

func _on_quit_pressed() -> void:
	get_tree().quit() # Beendet das Spiel