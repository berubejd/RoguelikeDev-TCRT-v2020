extends Area2D

export (String) var item_id


func _ready():
	pass


func _on_item_body_entered(_body):
	set_deferred("monitoring", false)
	InventorySignals.emit_signal("pickup_item", item_id)
	queue_free()
