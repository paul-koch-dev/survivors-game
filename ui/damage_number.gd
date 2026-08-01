class_name DamageNumber
extends Label

static func spawn(amount: float, target_pos: Vector2, is_player_damage: bool = false, is_crit: bool = false) -> void:
	var label = Label.new()
	label.text = str(roundi(amount))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 100
	
	# --- 1. SCHRIFTGRÖSSEN VIEL GRÖSSER ---
	var font_size = 32               # Standard-Schaden an Gegnern (vorher 18)
	var color = Color(1.0, 1.0, 1.0) # Weiß
	
	if is_player_damage:
		color = Color(1.0, 0.2, 0.2) # Knallrot
		font_size = 38               # Spieler-Schaden (vorher 20)
	elif is_crit:
		color = Color(1.0, 0.85, 0.1) # Goldgelb
		font_size = 48                # Kritischer Treffer (vorher 24)
		label.text += "!"

	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8) # Dickerer Rand für fette Schrift

	var tree = Engine.get_main_loop() as SceneTree
	if not tree or not tree.current_scene:
		return
		
	tree.current_scene.add_child(label)

	# Etwas breitere Streuung für größere Zahlen
	var random_x = randf_range(-24.0, 24.0)
	var start_pos = target_pos + Vector2(random_x, -20.0)
	label.global_position = start_pos

	# --- 2. POP-IN ANIMATION & HOCHFLIEGEN ---
	# Setzt den Drehpunkt in die Mitte der Zahl für den Pop-Effekt
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(0.3, 0.3)

	var tween = label.create_tween().set_parallel(true)
	
	# Ploppt beim Treffer kurz fett auf (Scale Boost)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)

	# Fliegt höher nach oben
	tween.tween_property(label, "global_position:y", start_pos.y - 65.0, 0.6)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# Blendet sanft aus
	tween.tween_property(label, "modulate:a", 0.0, 0.3)\
		.set_delay(0.35)

	# Räumt sich automatisch auf
	tween.chain().tween_callback(label.queue_free)