extends Node

# Hier definierst du alle globalen Events deines Spiels:
signal item_collected(type: String, specific_name: String)
signal player_health_changed(new_health: int)
signal level_up(level: int)
signal player_died()
signal enemy_died(xp_amount: int)
