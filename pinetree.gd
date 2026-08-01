extends StaticBody2D

# Lade die Szene als Datei vor
const PICKUP_SCENE = preload("res://pickup.tscn")

var health: int = 1

func take_damage(amount: int):
    health -= amount
    if health <= 0:
        die()

func die():
    $PineTree.visible = false
    $GroundShadow.visible = false
    $CollisionShape2D.disabled = true

    # 1. Instanziieren
    var pickup_instance = PICKUP_SCENE.instantiate()
    
    # 2. Position setzen (global_position sorgt für exakte Welt-Kordinaten)
    pickup_instance.global_position = global_position
    
    # 3. Typ festlegen (z.B. "fruit" oder "coin")
    pickup_instance.setup("fruit")
    
    # 4. In der Spielwelt (beim Eltern-Knoten des Baums) spawnen
    get_parent().add_child(pickup_instance)

    queue_free()  # Entferne den Baum aus der Szene