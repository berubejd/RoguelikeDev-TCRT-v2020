extends Node2D

onready var animation = $AnimationPlayer

func clear():
	var current = animation.get_current_animation()
	
	match current:
		"Alert":
			$Alert.visible = false
		"Chase":
			$Chase.visible = false
			
	animation.stop()
