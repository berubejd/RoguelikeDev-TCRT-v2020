extends Node

onready var animation = $TransitionLayer/AnimationPlayer
onready var popup = $PopupLayer/Popup
onready var level_label = $PopupLayer/Popup/LevelLabel
onready var load_button = $PopupLayer/Popup/LoadButton
onready var mainmenu_button = $PopupLayer/Popup/MainButton
onready var points_label = $PopupLayer/Popup/PointsLabel
onready var resume_button = $PopupLayer/Popup/ResumeButton

# warning-ignore:unused_signal
signal update_character_ui

func _ready():
	resume_button.grab_focus()
	$PopupLayer/AnimationPlayer.play("Pulse")
	
# warning-ignore:return_value_discarded
	connect("update_character_ui", self, "update_controls")

# warning-ignore:return_value_discarded
	UiSignals.connect("display_pausemenu", self, "pause_game")


func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		if not popup.visible:
			pause_game()
		elif popup.visible:
			resume_game()


func pause_game():
	# Pause game
	get_tree().paused = true
	
	# Enable process and physics process 
	set_process(true)
	set_physics_process(true)

	# Disable other UI elements
	UiSignals.emit_signal("hide_ui")
	InventorySignals.emit_signal("hide_tooltip")

	# Disable player input.  Necessary?
	var player = get_tree().get_root().find_node("Player", true, false)
	if player:
		player.set_process_input(false)

	# Update UI
	update_controls()

	# Show menu
	popup.popup()


func resume_game():
	# Unpause game
	get_tree().paused = false

	# Enable other UI elements
	UiSignals.emit_signal("display_ui")

	# Enable Player input
	var player = get_tree().get_root().find_node("Player", true, false)
	if player:
		player.set_process_input(true)

	# Disable process and physics process 
	set_process(false)
	set_physics_process(false)

	# hide menu
	popup.hide()


func update_controls():
	# Update Labels
	level_label.text = "Level " + str(Globals.player.level)
	points_label.text = "Points to Spend: " + str(Globals.player.level_points)

	# Update controls with methods
	for control in popup.get_children():
		if control.has_method("update"):
			control.update()


func _on_control_exited():
	pass


func _on_ResumeButton_entered():
	if not resume_button.has_focus():
		resume_button.grab_focus()


func _on_ResumeButton_pressed():
	resume_game()


func _on_LoadButton_entered():
	if not load_button.has_focus():
		load_button.grab_focus()


func _on_LoadButton_pressed():
	# Play transistion animation
	animation.play("Fade")
	yield(animation, "animation_finished")

	# Get handle to current main scene in order to free it later
	var old_main = get_tree().get_current_scene()

	# Load, configure, and add the main instance
	var main = load("res://Main.tscn")
	var main_instance = main.instance()
	main_instance.load_saved_game = true
	main_instance.connect("tree_entered", get_tree(), "set_current_scene", [main_instance], CONNECT_ONESHOT)
	get_tree().get_root().call_deferred("add_child", main_instance)
	get_tree().paused = false

	# Disable process and physics process 
	set_process(false)
	set_physics_process(false)

	# Clean up
	old_main.queue_free()


func _on_MainButton_entered():
	if not mainmenu_button.has_focus():
		mainmenu_button.grab_focus()


func _on_MainButton_pressed():
	# Play transistion animation
	animation.play("Fade")
	yield(animation, "animation_finished")

	# Change scene to the start menu
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://UI/Start.tscn")
	get_tree().paused = false

	# Disable process and physics process 
	set_process(false)
	set_physics_process(false)
