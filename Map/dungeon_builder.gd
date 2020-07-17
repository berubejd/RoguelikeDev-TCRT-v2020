extends Node
class_name Dungeon_Builder

# Track rooms and doors
var data = {}
var doorPos = {}
var rooms = []
var corridors = []

# Limit size of map (dimensions are twice this)
var limit_x = 64
var limit_y = 32
var borders = Rect2(-limit_x, -limit_y, limit_x * 2, limit_y * 2)

# Set up map padding to keep rooms and corridors inside map
var padding = 8

# Instance a random number generator with range
var rng = RandomNumberGenerator.new()


func _ready():
	rng.randomize()


# Helper functions
func _key(x, y):
	return str(x) + ":" + str(y)


func get_data(x, y):
	return data.get(_key(x, y))


func _set_data(x, y, val):
	if borders.has_point(Vector2(x, y)):
		data[_key(x, y)] = val
	else:
		return


func _remove_data(x, y, _val):
	data.erase(_key(x, y))


func in_limits(room: Rect2):
	return borders.encloses(room)


# Map generation functions
func add_room(new_room: Rect2):
	var room = {
		"room": new_room,
		"readyWalls": {"n": true, "e": true, "s": true, "w": true},
		"isRoom": true
	}

	if not in_limits(new_room):
		return

	rooms.push_back(room)

	for x in range(new_room.position.x, new_room.end.x):
		for y in range(new_room.position.y, new_room.end.y):
			_set_data(x, y, room)


func add_random_corridor(room, length: int, connecting: bool):
	var position: Vector2
	var direction: Vector2
	
	randomize()
	
	var readyWalls = room["readyWalls"]
	if readyWalls.size() == 0:
		return false

	# Select a wall to create a corridor from and remove it so we don't use it again
	var k = readyWalls.keys()
	k.shuffle()
	k = k[0]
	
	room["readyWalls"].erase(k)

	# Set up the direction to send corridor based on chosen wall
	var starting_room: Rect2 = room["room"]

	if k == "n":
		position = Vector2(floor(starting_room.position.x + starting_room.size.x / 2), starting_room.position.y)
		direction = Vector2.UP

	if k == "s":
		position = Vector2(floor(starting_room.position.x + starting_room.size.x / 2), starting_room.position.y + starting_room.size.y - 1)
		direction = Vector2.DOWN

	if k == "e":
		position = Vector2(starting_room.position.x + starting_room.size.x - 1, floor(starting_room.position.y + starting_room.size.y / 2))
		direction = Vector2.RIGHT

	if k == "w":
		position = Vector2(starting_room.position.x, floor(starting_room.position.y + starting_room.size.y / 2))
		direction = Vector2.LEFT

	# Check to see if the new corridor is going to intersect anything
	var todo: = []
	var touchedAnotherRoom: = false

	for _i in range(length):
		position = position + direction

		# Ensure we are not outside the map
		if not in_limits(Rect2(position.x, position.y, 1, 1).grow(padding)):
			return

		# Grab room data, if available
		var r = get_data(position.x, position.y)
	
		if not r:
			todo.append({ "position": position, "val": { "isCorridor": true, "room": Rect2(position.x, position.y, 1, 1) }})
		else:
			touchedAnotherRoom = true
			break

	if touchedAnotherRoom or not connecting:
		for i in range(todo.size()):
			var t = todo[i]
			var t_pos = t["position"]
			_set_data(t_pos.x, t_pos.y, t["val"])
			corridors.push_back(t_pos)

		if not touchedAnotherRoom:
			return position
		else:
			return

	return position


func get_random_room():
	return rooms[rng.randi_range(0, rooms.size() - 1)]
