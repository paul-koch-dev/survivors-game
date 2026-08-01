class_name WeaponDatabase
extends Resource

# Array lässt sich im Inspektor ohne Bugs und Fehler befüllen!
@export var weapons: Array[WeaponData] = []

# Sucht die Waffe anhand ihrer ID heraus
func get_weapon(target_id: String) -> WeaponData:
	for weapon in weapons:
		if weapon and weapon.id == target_id:
			return weapon
	return null