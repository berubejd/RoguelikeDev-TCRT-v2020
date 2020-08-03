extends Popup

onready var label_name = $Panel/Label_name
onready var label_type = $Panel/Label_type
onready var label_desc = $Panel/Label_description
onready var label_value = $Panel/Label_value


func _ready():
# warning-ignore:return_value_discarded
	InventorySignals.connect("display_tooltip", self, "display_tooltip")
# warning-ignore:return_value_discarded
	InventorySignals.connect("hide_tooltip", self, "hide_tooltip")


func display_tooltip(item):
	visible = true
	label_name.text = item.id
	label_type.text = "- " + item.type_description + " -"
	label_desc.text = item.description
	
	if "value" in item:
		label_value.visible = true
		label_value.text = "Value: " + str(item.value) + " g"
	else:
		label_value.visible = false


func hide_tooltip():
	hide()
