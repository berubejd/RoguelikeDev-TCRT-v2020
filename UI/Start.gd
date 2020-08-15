extends Node2D

export (int) var distance = 10

const MAP = preload("res://Map/Map.tscn")

onready var animation = $TransitionLayer/AnimationPlayer
onready var camera = $Camera2D
onready var camera_tween = $Camera2D/CameraMovement
onready var info_label = $CanvasLayer/Menu/InfoLabel
onready var info_label_text = info_label.text
onready var new_game_button = $CanvasLayer/Menu/NewGame
onready var load_game_button = $CanvasLayer/Menu/LoadGame
onready var quit_game_button = $CanvasLayer/Menu/QuitGame

var camera_destination
var map
var rooms


func _ready():
	randomize()
	create_map()

	new_game_button.grab_focus()

	map = Globals.map
	rooms = Globals.map.dungeon.rooms

	move_camera(map.start_room)


func _physics_process(_delta):
	if camera.get_camera_position().distance_to(camera_destination) < distance:
		move_camera()


func create_map():
	# Create new map and attach to World
	Globals.map = MAP.instance()
	Globals.map.complexity = 10
	Globals.map.max_corridor_length = 25
	# Color modulate level here before adding?
	add_child(Globals.map)


func move_camera(origin_room = null, destination_room = null):
	var camera_origin = get_world_position(origin_room) if origin_room else camera.get_camera_position()
	camera_destination = get_world_position(destination_room) if destination_room else get_world_position()


	if not camera.get_camera_position() == camera_origin:
		camera.position = camera_origin

	var travel_distance = camera_origin.distance_to(camera_destination)

	camera_tween.interpolate_property(camera, "position",
		camera_origin, camera_destination, travel_distance / 30,
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	camera_tween.start()

func get_world_position(room = null) -> Vector2:
		if not room:
			room = rooms[randi() % len(rooms)]

		var random_cell = map._get_random_floor_cell(room["room"])
		return map.map_to_world(Vector2(random_cell.x, random_cell.y))


func _on_control_exited():
	info_label.text = info_label_text


func _on_NewGame_entered():
	info_label.text = "Start a new game.  This will overwrite any existing saved games!"
	if not new_game_button.has_focus():
		new_game_button.grab_focus()


func _on_NewGame_pressed():
	animation.play("Fade")
	yield(animation, "animation_finished")
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Main.tscn")


func _on_LoadGame_entered():
	info_label.text = "Load a previous game, if available"
	if not load_game_button.has_focus():
		load_game_button.grab_focus()


func _on_LoadGame_pressed():
	animation.play("Fade")
	yield(animation, "animation_finished")
	
	var main = load("res://Main.tscn")
	var main_instance = main.instance()
	main_instance.load_saved_game = true
	main_instance.connect("tree_entered", get_tree(), "set_current_scene", [main_instance], CONNECT_ONESHOT)
	get_tree().get_root().call_deferred("add_child", main_instance)
	queue_free()


func _on_QuitGame_entered():
	info_label.text = "Exit the game"
	if not quit_game_button.has_focus():
		quit_game_button.grab_focus()


func _on_QuitGame_pressed():
	get_tree().quit()
