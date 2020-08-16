extends Area2D


func _ready():
	pass


func _on_item_body_entered(_body):
	InventorySignals.emit_signal("pickup_item", "potion of health")
	queue_free()
