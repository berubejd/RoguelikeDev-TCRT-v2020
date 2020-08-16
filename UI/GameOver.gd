extends CanvasLayer

onready var animation = $TransitionLayer/AnimationPlayer
onready var continue_button = $ContinueButton


func _ready():
	pass


func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_ContinueButton_pressed()


func _on_ContinueButton_pressed():
	# Play transistion animation
	animation.play("Fade")
	yield(animation, "animation_finished")

	# Change scene to the start menu
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://UI/Start.tscn")


func _on_ContinueButton_mouse_entered():
	continue_button.grab_focus()


func _on_ContinueButton_mouse_exited():
	continue_button.release_focus()
