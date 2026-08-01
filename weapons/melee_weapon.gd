class_name MeleeWeapon
extends BaseWeapon

@export_group("Melee Setup")
@export var hit_area: Area2D
@export var swing_animation_player: AnimationPlayer

@export_group("Slash Visuals")
@export var slash_color: Color = Color(0.2, 0.9, 1.0, 0.4) # Neon-Cyan / Hellblau
@export var slash_arc_deg: float = 120.0                   # 120° Schwungbereich
@export var slash_duration: float = 0.15                   # Dauer der Anzeige in Sek.

var slash_alpha: float = 0.0
var slash_tween: Tween

func _process(delta: float) -> void:
	super._process(delta)
	if slash_alpha > 0.0:
		queue_redraw()

func _draw() -> void:
	super._draw()
	if slash_alpha > 0.0:
		_draw_slash_effect()

func _execute_attack() -> void:
	if not is_instance_valid(hit_area):
		hit_area = get_node_or_null("HitArea") as Area2D

	var target_dir = _get_best_attack_direction()
	
	if target_dir != Vector2.ZERO:
		rotation = target_dir.angle()

	# Startet den visuellen Hieb-Bogen
	_trigger_slash_visual()

	if swing_animation_player and swing_animation_player.has_animation("swing"):
		swing_animation_player.play("swing")
	else:
		_perform_instant_swing_visual()

	_deal_area_damage()

# Zündet den Aufblitz-Effekt und lässt ihn weich ausfaden
func _trigger_slash_visual() -> void:
	if slash_tween:
		slash_tween.kill()
		
	slash_alpha = 1.0
	queue_redraw()

	slash_tween = create_tween()
	slash_tween.tween_property(self, "slash_alpha", 0.0, slash_duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

# Zeichnet den gefüllten Schwung-Bogen mit einer hellen Außenkante
func _draw_slash_effect() -> void:
	var radius = get_effective_range()
	var half_arc = deg_to_rad(slash_arc_deg / 2.0)
	
	var current_color = slash_color
	current_color.a *= slash_alpha

	# Poly-Punkte für die gefüllte Trefferfläche
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	
	var segments = 16
	for i in range(segments + 1):
		var angle = lerpf(-half_arc, half_arc, float(i) / segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	# 1. Halbtransparente Fläche zeichnen
	draw_polygon(points, PackedColorArray([current_color]))
	
	# 2. Leuchtende Außenkante zeichnen
	var edge_color = Color(1.0, 1.0, 1.0, minf(1.0, slash_alpha * 1.5))
	draw_arc(Vector2.ZERO, radius, -half_arc, half_arc, 16, edge_color, 3.0, true)

func _get_best_attack_direction() -> Vector2:
	if not is_instance_valid(hit_area):
		return Vector2.ZERO

	var bodies = hit_area.get_overlapping_bodies()
	var valid_targets: Array[Node2D] = []

	for body in bodies:
		if is_instance_valid(body) and body != self and not body.is_in_group("player"):
			if body.has_method("take_damage"):
				valid_targets.append(body)

	if valid_targets.is_empty():
		return Vector2.ZERO

	var avg_pos = Vector2.ZERO
	for target in valid_targets:
		avg_pos += target.global_position

	avg_pos /= valid_targets.size()
	return global_position.direction_to(avg_pos)

func _perform_instant_swing_visual() -> void:
	var base_rot = rotation
	var tween = create_tween()
	
	tween.tween_property(self, "rotation", base_rot - deg_to_rad(60), 0.04)
	tween.tween_property(self, "rotation", base_rot + deg_to_rad(60), 0.1)
	tween.tween_property(self, "rotation", base_rot, 0.05)

func _deal_area_damage() -> void:
	if not is_instance_valid(hit_area):
		return

	var targets = hit_area.get_overlapping_bodies()
	for body in targets:
		if is_instance_valid(body) and body.has_method("take_damage") and not body.is_in_group("player"):
			body.take_damage(get_effective_damage())