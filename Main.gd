extends Node2D

const PLAYER = preload("res://Entities/Player/Player.tscn")
const MAP = preload("res://Map/Map.tscn")

onready var animation = $TransitionLayer/AnimationPlayer
onready var levels = $Levels
onready var transition_layer = $TransitionLayer


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS

	randomize()
	create_map()


func create_map():
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
	var _return = find_node("Exit", true, false).connect("exit_entered", self, "map_exited")

	# Place player in start room and attach to $Map
	var start_room = $Map.start_room
	var player_cell = Globals.map._get_random_floor_cell(start_room["room"], true, true, true)

	# This may be a temporary placement
	if not Globals.player or not is_instance_valid(Globals.player):
		Globals.player = PLAYER.instance()

	Globals.player.position = Globals.map.map_to_world(player_cell) + Vector2(8, 8)
	$Map/Entities.add_child(Globals.player)


func map_exited():
	print("Entered")
	# Pause the game and fade out
	get_tree().paused = true
	animation.play("Fade")
	yield(animation, "animation_finished")

	# Create the new map and reset player
	if Globals.player.state == 0: # 0 is the DEATH state
		Globals.player.queue_free()
	else:
		Globals.player.velocity = Vector2.ZERO

	# Call map creation
	yield(create_map(), "completed")

	# Fade in and unpause the game
	animation.play_backwards("Fade")
	yield(animation, "animation_finished")
	get_tree().paused = false