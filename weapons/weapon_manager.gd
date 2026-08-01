class_name WeaponManager
extends Node2D

# Liste aller aktuell ausgerüsteten Waffen des Spielers
@export var equipped_weapons: Array[BaseWeapon] = []

func _ready() -> void:
	# Erfasst alle Waffen, die bereits unter dem WeaponManager hängen (z.B. Gun & Sword)
	for child in get_children():
		if child is BaseWeapon and not equipped_weapons.has(child):
			equipped_weapons.append(child)
			
	_activate_all_weapons()

# Stellt sicher, dass ALLE Waffen sichtbar sind und ihre Angriffs-Timer laufen
func _activate_all_weapons() -> void:
	for weapon in equipped_weapons:
		if is_instance_valid(weapon):
			weapon.visible = true
			if weapon.attack_timer:
				weapon.attack_timer.paused = false

# Neue Waffe hinzufügen (z. B. später über den Level-Up Shop)
func add_weapon(weapon_instance: BaseWeapon) -> void:
	add_child(weapon_instance)
	equipped_weapons.append(weapon_instance)
	
	weapon_instance.visible = true
	if weapon_instance.attack_timer:
		weapon_instance.attack_timer.paused = false