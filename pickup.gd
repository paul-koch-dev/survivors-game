extends Area2D

signal item_collected(type: String, specific_name: String)

@onready var sprite = $ItemSprite

var item_type: String = "fruit"
var specific_item_name: String = ""

func setup(p_type: String) -> void:
	item_type = p_type
	if is_node_ready():
		update_texture()

func _ready() -> void:
	add_to_group("pickups")
	update_texture()
	body_entered.connect(_on_body_entered)

func update_texture() -> void:
	var png_path = get_png_path(item_type)
	if png_path:
		sprite.texture = load(png_path)

func get_png_path(type: String):
	var paths_dict: Dictionary = {}

	match type:
		"fruit":
			paths_dict = {
				"apple_cider": "res://trees/fruits/apple_cider.png",
				"apple_jelly": "res://trees/fruits/apple_jelly.png",
				"apple_pie": "res://trees/fruits/apple_pie.png",
				"apple": "res://trees/fruits/apple.png",
				"apricot": "res://trees/fruits/apricot.png",
				"apricot_cake": "res://trees/fruits/apricot_cake.png",
				"banana": "res://trees/fruits/banana.png",
				"cherry": "res://trees/fruits/cherry.png"
			}
		"coin":
			paths_dict = {
				"coin1": "res://icons/emerald.png",
			}
		_:
			return null

	if paths_dict.size() > 0:
		var keys = paths_dict.keys()
		var random_key = keys[randi() % keys.size()]
		specific_item_name = random_key
		return paths_dict[random_key]
	else:
		return null

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("item_collected"):
			EventBus.item_collected.emit(item_type, specific_item_name)
		queue_free()


# ==========================================
# MAGNET-EFFEKT (NUR FÜR MÜNZEN)
# ==========================================
func collect_via_magnet(target_node: Node2D) -> void:
	if item_type != "coin" or not is_instance_valid(target_node):
		return

	# Erlaubt Bewegung trotz Pause-Zustand (get_tree().paused = true)
	process_mode = Node.PROCESS_MODE_ALWAYS

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	var tween = create_tween().set_parallel(true)

	var target_pos = target_node.global_position
	tween.tween_property(self, "global_position", target_pos, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.4)

	tween.finished.connect(func():
		if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("item_collected"):
			EventBus.item_collected.emit(item_type, specific_item_name)
		queue_free()
	)

	