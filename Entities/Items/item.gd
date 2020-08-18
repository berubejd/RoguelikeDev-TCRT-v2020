extends Area2D

const floating_text = preload("res://Effects/FloatingText.tscn")

export (String) var item_id


func _ready():
	pass


func _on_item_body_entered(_body):
	set_deferred("monitoring", false)
	InventorySignals.emit_signal("pickup_item", item_id)
	display_floating_text()
	queue_free()


func display_floating_text():
	var border_color = Color.blue
	var floating_text_instance = floating_text.instance()
	floating_text_instance.initialize(item_id, border_color)
	Globals.player.add_child(floating_text_instance)
