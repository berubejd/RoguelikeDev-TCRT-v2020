extends Area2D

signal exit_entered

func _ready():
	pass


func _on_Exit_body_entered(body):
	if body == Globals.player:
		emit_signal("exit_entered")
