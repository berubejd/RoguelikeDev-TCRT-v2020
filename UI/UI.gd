extends CanvasLayer

export (int) var life_width = 14

onready var addstat = $Experience/AddStat
onready var addstat_animation = $Experience/AddStat/AnimationPlayer
onready var addstat_background = $Experience/AddStat/ColorRect
onready var current_health_container = $Health/CurrentHealth
onready var experience_bar = $Experience/ProgressBar
onready var experience_label = $Experience/Label
onready var max_health_container = $Health/MaxHealth
onready var player = Globals.player

# Fake Item attributes to use the inventory tooltip
var id = "Congrats!"
var type_description = "Level Up"
var description = "You have level points to spend!  Click me!"


func _ready():
# warning-ignore:return_value_discarded
	UiSignals.connect("display_ui", self, "display_ui")
# warning-ignore:return_value_discarded
	UiSignals.connect("hide_ui", self, "hide_ui")
# warning-ignore:return_value_discarded
	UiSignals.connect("update_experience", self, "update_experience")
# warning-ignore:return_value_discarded
	UiSignals.connect("update_health", self, "update_health")


func display_ui():
	for element in get_children():
		element.visible = true


func hide_ui():
	for element in get_children():
		element.visible = false


func update_experience(level, current_xp, needed_xp):
	experience_label.text = "Level " + str(level) + " - " + str(current_xp) + " / " + str(needed_xp)
	experience_bar.value = current_xp
	experience_bar.max_value = needed_xp


func update_experience_indicator():
	yield(get_tree(), "idle_frame")

	if Globals.player and Globals.player.level_points > 0:
		if not addstat.visible:
			addstat.visible = true
			addstat_animation.play("Pulse")
	else:
		addstat.visible = false
		addstat_animation.stop()


func update_health(current_health, max_health):
	current_health_container.rect_size.x = (current_health / 10.0) * float(life_width)
	max_health_container.rect_size.x = (max_health / 10.0) * float(life_width)


func _on_AddStat_mouse_entered():
	addstat_background.color = Color("ffffff")

	# Overload item tooltip
	InventorySignals.emit_signal("display_tooltip", self)


func _on_AddStat_mouse_exited():
	addstat_background.color = Color("000000")

	InventorySignals.emit_signal("hide_tooltip")


func _on_AddStat_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		# Hide tooltip before opening the popup window
		InventorySignals.emit_signal("hide_tooltip")

		# Signal the pause menu to popup
		UiSignals.emit_signal("display_pausemenu")


func _on_Timer_timeout():
	update_experience_indicator()
