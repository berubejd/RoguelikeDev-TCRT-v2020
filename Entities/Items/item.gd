extends Area2D

const fading_text = preload("res://Effects/FadingText.tscn")

export (String) var item_id


func _ready():
	pass


func _on_item_body_entered(_body):
	set_deferred("monitoring", false)
	InventorySignals.emit_signal("pickup_item", item_id)
	# Should this be here or in the actual pickup method of inventory?
	display_fading_text()
	queue_free()


func display_fading_text():
	var fading_text_instance = fading_text.instance()
	var message = "Found "+ item_id + "!"
	var duration = 2.0
	
	fading_text_instance.initialize(message, duration)
	get_tree().get_root().find_node("StatusTextAnchor", true, false).add_child(fading_text_instance)
