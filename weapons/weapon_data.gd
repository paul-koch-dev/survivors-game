class_name WeaponData
extends Resource

@export var id: String = "pistol" # ID zur Identifikation (z. B. "pistol", "sword")
@export var weapon_name: String = "Pistole"
@export var icon: Texture2D

@export_group("Stats")
@export var base_damage: float = 10.0
@export var base_attack_speed: float = 1.0
@export var base_range: float = 200.0
@export var projectile_speed: float = 1000.0