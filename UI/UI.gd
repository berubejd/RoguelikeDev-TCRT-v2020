extends CanvasLayer

export (int) var life_width = 14

onready var current_health_container = $Health/CurrentHealth
onready var max_health_container = $Health/MaxHealth

onready var player = Globals.player


func _ready():
	add_to_group("player_update")


func update_health(current_health, max_health):
	current_health_container.rect_size.x = (current_health / 10.0) * float(life_width)
	max_health_container.rect_size.x = (max_health / 10.0) * float(life_width)
