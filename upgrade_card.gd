extends PanelContainer

signal selected(upgrade_data: Dictionary)

@onready var rarity_label = %RarityLabel
@onready var icon_label = %IconLabel
@onready var title_label = %TitleLabel
@onready var description_label = %DescriptionLabel
@onready var btn_select = %BtnSelect

var current_upgrade_data: Dictionary = {}

func _ready() -> void:
	btn_select.pressed.connect(_on_btn_select_pressed)

func setup(upgrade_data: Dictionary, rarity_info: Dictionary, player_stonks: int) -> void:
	current_upgrade_data = upgrade_data
	
	title_label.text = upgrade_data.get("title", "Upgrade")
	icon_label.text = upgrade_data.get("icon", "✨")
	rarity_label.text = rarity_info.get("name", "GEWÖHNLICH").to_upper()
	description_label.text = upgrade_data.get("description", "")
	
	var cost: int = upgrade_data.get("cost", 0)
	
	if player_stonks >= cost:
		btn_select.disabled = false
		btn_select.text = "Kaufen (%d 📈)" % cost
	else:
		btn_select.disabled = true
		btn_select.text = "Zu teuer (%d 📈)" % cost
	
	var border_color: Color = rarity_info.get("color", Color.GRAY)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.12, 0.12, 0.14, 0.95)
	style_box.border_color = border_color
	style_box.set_border_width_all(3)
	style_box.set_corner_radius_all(8)
	
	add_theme_stylebox_override("panel", style_box)
	rarity_label.add_theme_color_override("font_color", border_color)

func _on_btn_select_pressed() -> void:
	selected.emit(current_upgrade_data)