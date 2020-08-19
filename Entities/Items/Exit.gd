extends Area2D

signal exit_entered

func _ready():
	pass


func _on_Exit_body_entered(body):
	if body == Globals.player:
		emit_signal("exit_entered")


func _on_DetectionRadius2_body_entered(_body):
	UiSignals.emit_signal("display_exit_arrow", global_position)
