extends Node2D

onready var animation = $AnimatedSprite

func _ready():
	# Switch up 
	animation.frame = randi() % 4
	animation.speed_scale = rand_range(0.9, 1.1)
