extends CanvasLayer

const fading_text = preload("res://Effects/FadingText.tscn")

export (int) var life_width = 14

onready var addstat = $Experience/AddStat
onready var addstat_animation = $Experience/AddStat/AnimationPlayer
onready var addstat_background = $Experience/AddStat/ColorRect
onready var current_health_container = $Health/CurrentHealth
onready var exit_arrow = $ExitArrow
onready var exit_arrow_pointer = $ExitArrow/Arrow
onready var experience_bar = $Experience/ProgressBar
onready var experience_label = $Experience/Label
onready var gold_label = $Gold/HBoxContainer/Label
onready var max_health_container = $Health/MaxHealth
onready var player = Globals.player
onready var save_player = $SaveIndicator/AnimationPlayer
onready var status_text = $StatusTextAnchor

# Fake Item attributes to use the inventory tooltip
var id = "Congrats!"
var type_description = "Level Up"
var description = "You have level points to spend!  Click me!"

var exit_position = null


func _ready():
	# warning-ignore:return_value_discarded
	UiSignals.connect("display_ui", self, "display_ui")
	# warning-ignore:return_value_discarded
	UiSignals.connect("hide_ui", self, "hide_ui")
	# warning-ignore:return_value_discarded
	UiSignals.connect("update_experience", self, "update_experience")
	# warning-ignore:return_value_discarded
	UiSignals.connect("update_health", self, "update_health")
	# warning-ignore:return_value_discarded
	UiSignals.connect("update_gold", self, "update_gold")
	# warning-ignore:return_value_discarded
	UiSignals.connect("display_exit_arrow", self, "display_exit_arrow")
	# warning-ignore:return_value_discarded
	UiSignals.connect("hide_exit_arrow", self, "hide_exit_arrow")
	# warning-ignore:return_value_discarded
	SaveGame.connect("save_game", self, "enable_save_indicator")
	# warning-ignore:return_value_discarded
	UiSignals.connect("display_message", self, "display_fading_text")


func _physics_process(_delta):
	if exit_position:
		exit_arrow_pointer.rect_rotation = rad2deg(Globals.player.global_position.angle_to_point(exit_position + Vector2(8, 8))) - 90
	else:
		# Ensure the arrow stays hidden even though the displau_ui method may try to enable it
		exit_arrow.visible = false


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


func update_gold(gold):
	print(gold)
	gold_label.text = str(gold)


func display_exit_arrow(position):
	if not exit_arrow.visible == true:
		exit_arrow.visible = true
		exit_position = position
		display_exit_notification()


func display_exit_notification():
	var message = "Exit discovered!"
	display_fading_text(message)


func hide_exit_arrow():
	exit_arrow.visible = false
	exit_position = null


func enable_save_indicator():
	save_player.play("Blink")


func display_fading_text(message):
	var fading_text_instance = fading_text.instance()
	var duration = 2.0

	fading_text_instance.initialize(message, duration)
	get_tree().get_root().find_node("StatusTextAnchor", true, false).add_child(fading_text_instance)


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
