extends Node2D

const PINETREE_SCENE = preload("res://pinetree.tscn")

# Einstellungen
@export var max_trees: int = 10
@export var min_interval: float = 8.0
@export var max_interval: float = 15.0

var current_tree_count: int = 0
var spawn_timer: Timer

func _ready() -> void:
	# --- NEU: EventBus verbinden ---
	# Wir prüfen zur Sicherheit, ob das Signal existiert, um Fehler zu vermeiden
	if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("player_died"):
		EventBus.player_died.connect(_on_player_died)

	# 1. Timer initialisieren
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true # Läuft nur einmal pro Durchgang
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	# Ersten Timer-Durchlauf starten
	schedule_next_spawn()


# Plant den nächsten Spawn mit zufälliger Zeit
func schedule_next_spawn() -> void:
	# Wenn das Limit erreicht ist, starten wir keinen neuen Timer!
	if current_tree_count >= max_trees:
		print("Maximalanzahl an Bäumen erreicht (", max_trees, "). Timer stoppt.")
		return

	# Zufälliges Intervall zwischen Min und Max berechnen
	var random_wait_time = randf_range(min_interval, max_interval)
	spawn_timer.wait_time = random_wait_time
	spawn_timer.start()
	print("Nächster Baum spawnt in ", snappedf(random_wait_time, 0.1), " Sekunden.")


func _on_spawn_timer_timeout() -> void:
	spawn_random_tree()
	# Nach dem Spawn direkt das nächste zufällige Intervall planen
	schedule_next_spawn()


func spawn_random_tree() -> void:
	if current_tree_count >= max_trees:
		return

	var tree_instance = PINETREE_SCENE.instantiate()
	
	var screen_size = get_viewport_rect().size
	var random_x = randf_range(0, screen_size.x)
	var random_y = randf_range(0, screen_size.y)
	tree_instance.global_position = Vector2(random_x, random_y)
	
	# TRICK: Wir verbinden uns mit dem automatischen Godot-Signal 'tree_exited'.
	# Es wird gefeuert, sobald der Baum mit queue_free() gelöscht wird!
	tree_instance.tree_exited.connect(_on_tree_destroyed)
	
	add_child(tree_instance)
	current_tree_count += 1
	print("Baum gespawnt. Aktuell im Spiel: ", current_tree_count, "/", max_trees)


# Wird automatisch aufgerufen, sobald EIN beliebiger Baum gelöscht wird
func _on_tree_destroyed() -> void:
	current_tree_count -= 1
	print("Baum zerstört! Aktuell im Spiel: ", current_tree_count, "/", max_trees)
	
	# Falls der Timer gestoppt war (weil das Limit voll war), starten wir ihn jetzt wieder!
	if spawn_timer.is_stopped() and current_tree_count < max_trees:
		schedule_next_spawn()


# --- NEU: Die Funktion, die aufgerufen wird, wenn der Spieler stirbt ---
func _on_player_died() -> void:
	print("Das Spiel hat bemerkt: Der Spieler ist gestorben!")
	
	# 1. Spawner stoppen (keine neuen Bäume mehr!)
	if spawn_timer and not spawn_timer.is_stopped():
		spawn_timer.stop()
		
	# 2. Hier kannst du später das Spiel pausieren oder ein Menü zeigen
	get_tree().paused = true
	%GameOverMenu.visible = true