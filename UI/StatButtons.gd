extends Control

### TODO
# This is supposed to support preview of point allocation
# So, both add and remove buttons and mouseover tooltips for what the change
# will be.

export (String) var parent
export (int) var increment = 0
export (String) var node_name = ""
export (String) var points_variable = ""

onready var addstat = $AddStat
onready var addstat_background = $AddStat/ColorRect
onready var removestat = $RemoveStat
onready var removestat_background = $RemoveStat/ColorRect

var node_pointer


func _process(_delta):
	if not node_pointer:
		node_pointer = get_tree().get_root().find_node(node_name, true, false)
		if not node_pointer:
			return

	if points_variable and node_pointer.get(points_variable):
		addstat.visible = true
	else:
		addstat.visible = false


func _on_AddStat_mouse_entered():
	addstat_background.color = Color("ffffff")


func _on_AddStat_mouse_exited():
	addstat_background.color = Color("000000")


func _on_AddStat_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var parent_node = get_parent().find_node(parent)
		if parent_node:
			var ret = parent_node.add(increment)
			if ret:
				update_points()


func _on_RemoveStat_mouse_entered():
	removestat_background.color = Color("ffffff")


func _on_RemoveStat_mouse_exited():
	removestat_background.color = Color("000000")


func _on_RemoveStat_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var parent_node = get_parent().find_node(parent)
		if parent_node:
			var ret = parent_node.remove(increment)
			if ret:
				update_points()


func update_points():
	# Decrease available points
	node_pointer.set(points_variable, node_pointer.get(points_variable) - 1)
	
	# Signal Pause Menu that there has been a change
	var parent_node = find_parent("PauseMenu")
	parent_node.emit_signal("update_character_ui")
	
	# Signal SaveGame that there is a player change that needs to trigger a save
	SaveGame.emit_signal("save_game")
