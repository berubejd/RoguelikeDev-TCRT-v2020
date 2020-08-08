extends Node2D

const PLAYER = preload("res://Entities/Player/Player.tscn")
const MAP = preload("res://Map/Map.tscn")

onready var animation = $TransitionLayer/AnimationPlayer
onready var levels = $Levels
onready var level_label = $TransitionLayer/LevelDisplay
onready var transition_layer = $TransitionLayer
onready var transition_layer_color = $TransitionLayer/ColorRect

var load_saved_game = false


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS

	if load_saved_game:
		SaveGame.load_game()
		
		if Globals.save_data:
			# Set dungeon level 1 lower to account for the 'level_reveal' increment
			Globals.dungeon_level = Globals.save_data["Map"]["dungeon_level"] - 1
			load_saved_game = false
		else:
			print("Something went wrong.")
			get_tree().quit()

	randomize()
	new_game_transition()


func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		SaveGame.save_game()


func create_map():
	# Ensure we can use yield on this function
	yield(get_tree(), "idle_frame")

	# Detach player, if present
	if Globals.player and Globals.player.is_inside_tree():
		$Map/Entities.remove_child(Globals.player)

	# Delete the existing map, if present
	if Globals.map and Globals.map.is_inside_tree():
		remove_child($Map)
		Globals.map.queue_free()
		yield(get_tree().create_timer(0.25), "timeout")

	# Create new map and attach to World
	Globals.map = MAP.instance()
	# Color modulate level here before adding?
	add_child(Globals.map)

	# Connect to map exit
	var _return = find_node("Exit", true, false).connect("exit_entered", self, "level_transition")

	# Place player in start room and attach to $Map
	var start_room = $Map.start_room
	var player_cell = Globals.map._get_random_floor_cell(start_room["room"], true, true, true)

	# This may be a temporary placement
	if not Globals.player or not is_instance_valid(Globals.player):
		Globals.player = PLAYER.instance()

	Globals.player.position = Globals.map.map_to_world(player_cell) + Vector2(8, 8)
	$Map/Entities.add_child(Globals.player)

	# Map generation complete so save
	SaveGame.emit_signal("save_game")


func new_game_transition():
	# Set screen to black rather than fade in
	transition_layer_color.color = Color("000000")

	# Increment and display dungeon level
	yield(level_reveal(), "completed")
	
	# Call map creation
	yield(create_map(), "completed")

	# Fade in and unpause the game
	yield(level_fade_in(), "completed")


func level_transition():
	# Pause the game and fade out
	yield(level_fade_out(), "completed")

	# Create the new map and reset player
	if Globals.player.state == 0: # 0 is the DEATH state
		Globals.player.queue_free()
	else:
		Globals.player.velocity = Vector2.ZERO

	# Increment and display dungeon level
	yield(level_reveal(), "completed")
	
	# Call map creation
	yield(create_map(), "completed")

	# Fade in and unpause the game
	yield(level_fade_in(), "completed")


func level_fade_out():
	# Pause the game and fade out
	get_tree().paused = true
	animation.play("Fade")
	yield(animation, "animation_finished")


func level_reveal():
	# Increment and display dungeon level
	Globals.dungeon_level += 1
	level_label.text = "Level " + str(Globals.dungeon_level)
	animation.play("LevelReveal")
	yield(animation, "animation_finished")


func level_fade_in():
	# Fade in and unpause the game
	animation.play_backwards("Fade")
	yield(animation, "animation_finished")
	get_tree().paused = false
