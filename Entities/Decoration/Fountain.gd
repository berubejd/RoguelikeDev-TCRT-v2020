extends StaticBody2D

onready var light = $Light

func _on_Area2D_body_entered(_body):
	# This should include a signal to act on the player
	light.enabled = false
