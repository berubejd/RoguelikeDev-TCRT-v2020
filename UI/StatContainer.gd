extends HBoxContainer

### TODO
# The internal values are to allow for application and accept phases which
# I'm not going to implement fully at this time, unfortunately.
# Also, changed stats should be green or whatever until accepted.

export (String) var stat = ""
export (String) var node_name = ""
export (String) var variable_1 = ""
export (String) var variable_2 = ""

onready var label = $Stat
onready var value = $Value

var internal_value_1
var internal_value_2


func _ready():
	pass


func add(increment):
	var node_pointer = get_tree().get_root().find_node(node_name, true, false)
	if not node_pointer:
		print("Unable to find node ", node_name)
		return

	if variable_2:
		node_pointer.set(variable_2, internal_value_2 + increment)
	else:
		node_pointer.set(variable_1, internal_value_1 + increment)

	var parent = find_parent("PauseMenu")
	parent.emit_signal("update_character_ui")
	return true


func remove(increment):
	var node_pointer = get_tree().get_root().find_node(node_name, true, false)
	if not node_pointer:
		print("Unable to find node ", node_name)
		return

	if variable_2:
		node_pointer.set(variable_2, internal_value_2 - increment)
	else:
		node_pointer.set(variable_1, internal_value_1 - increment)

	var parent = find_parent("PauseMenu")
	parent.emit_signal("update_character_ui")
	return true


func update():
	# Set up stat label
	if stat:
		label.text = stat + ":"
	else:
		 label.text = "Stat:"

	var node_pointer = get_tree().get_root().find_node(node_name, true, false)
	if not node_pointer:
		print("Unable to find node ", node_name)
		return

	# Set up values
	if variable_1:
		internal_value_1 = node_pointer.get(variable_1)
	else:
		internal_value_1 = 0

	if variable_2:
		internal_value_2 = node_pointer.get(variable_2)
	else:
		internal_value_2 = 0

	value.text = str(internal_value_1)
	
	if variable_2:
		value.text = value.text + " / " + str(internal_value_2)
