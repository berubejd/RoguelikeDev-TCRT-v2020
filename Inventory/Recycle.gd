extends TextureRect

# Fake Item attributes
var id = "Item Grinder"
var type_description = "Recycling"
var description = "Items dropped here will one day award you gold.  Today, though, they just disappear."



func _ready():
# warning-ignore:return_value_discarded
	connect("mouse_entered", self, "mouse_enter")
# warning-ignore:return_value_discarded
	connect("mouse_exited", self, "mouse_exit")


func mouse_enter():
	# Overload item tooltip
	InventorySignals.emit_signal("display_tooltip", self)


func mouse_exit():
	InventorySignals.emit_signal("hide_tooltip")
