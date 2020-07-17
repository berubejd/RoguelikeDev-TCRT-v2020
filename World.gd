extends Node2D

const PLAYER = preload("res://Entities/Player/Player.tscn")
const MAP = preload("res://Map/Map.tscn")

onready var animation = $TransitionLayer/AnimationPlayer
onready var transition_layer = $TransitionLayer



func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS

	randomize()

	Globals.player = PLAYER.instance()
	create_map()


func create_map():
	# Free existing map instance
	if get_node_or_null("Map"):
		$Map/Entities.remove_child(Globals.player)
		remove_child($Map)
		Globals.map.queue_free()

	# Create new map and attach to World
	Globals.map = MAP.instance()

	# Color modulate?

	add_child(Globals.map)
	
	# Connect to map exit
	var _return = find_node("Exit", true, false).connect("exit_entered", self, "map_exited")

	# Place player in start room and attach to $Map
	var start_room = $Map.start_room
	var player_cell = Globals.map._get_random_floor_cell(start_room["room"], true, true, true)
	Globals.player.position = Globals.map.map_to_world(player_cell)
	
	$Map/Entities.add_child(Globals.player)


func map_exited():
	# Pause the game and fade out
	get_tree().paused = true
	animation.play("Fade")
	yield(animation, "animation_finished")

	# Create the new map and reset player movement
	call_deferred("create_map")
	Globals.player.velocity = Vector2.ZERO

	# Fade in and unpause the game
	animation.play_backwards("Fade")
	yield(animation, "animation_finished")
	get_tree().paused = false

