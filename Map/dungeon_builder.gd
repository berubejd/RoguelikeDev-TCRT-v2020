extends Node
class_name Dungeon_Builder

# Track rooms and doors
var data = {}
var doorPos = {}
var rooms = []
var corridors = []

# Limit size of map (dimensions are twice this)
var limitX = 64
var limitY = 32

# Instance a random number generator with range
var rng = RandomNumberGenerator.new()


func _ready():
	rng.randomize()


# Helper functions
func _key(x, y):
	return str(x) + ":" + str(y)


func _get_data(x, y):
	return data.get(_key(x, y))


func _set_data(x, y, val):
	if x < -limitX or limitX < x:
		return
	
	if y < -limitY or limitY < y:
		return

	data[_key(x, y)] = val


func _remove_data(x, y, _val):
	data.erase(_key(x, y))


func in_limits(room):
	return room.x > -limitX && room.x + room.w < limitX && room.y > -limitY && room.y + room.w < limitY


func nearby_corridor(x, y, direction, width):
	var x_delta = 0
	var y_delta = 0
	
	# Determine direction to check
	if direction == "n" or direction == "s":
		x_delta = width

	if direction == "e" or direction == "w":
		y_delta = width

	for i in range(x - x_delta, x + x_delta + 1):
		for j in range(y - y_delta, y + y_delta + 1):
			var result = _get_data(i, j)
			if result and result.get("isCorridor"):
				print("In corridor")
				return true

	return false


# Map generation functions
func add_room(x, y, w, h):
	var room = {
		"x": x,
		"y": y,
		"w": w,
		"h": h,
		"readyWalls": {"n":true, "e":true, "s":true, "w":true},
		"isRoom": true
	}

	if not in_limits(room):
		return
		
	rooms.push_back(room)

	for _x in range(x, x+w):
		for _y in range(y, y+h):
			_set_data(_x, _y, room);


func add_random_corridor(room, length, connecting):
	var x
	var y
	var dirX
	var dirY
	
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
	if k == "n":
		x = floor(room["x"] + room["w"] / 2)
		y = room["y"]
		dirX = 0
		dirY = -1

	if k == "s":
		x = floor(room["x"] + room["w"] / 2)
		y = room["y"] + room["h"] - 1
		dirX = 0
		dirY = 1

	if k == "e":
		x = room["x"] + room["w"] - 1
		y = floor(room["y"] + room["h"] / 2)
		dirX = 1
		dirY = 0

	if k == "w":
		x = room["x"]
		y = floor(room["y"] + room["h"] / 2)
		dirX = -1
		dirY = 0

	# Check to see if the new corridor is going to intersect anything
	var todo = []
	var touchedAnotherRoom = false

	for _i in range(length):
		x += dirX
		y += dirY

		# Ensure we're not outside of the map (This pad is to ensure we can create a room at the end of this)
		# Getting some dead-end corridors?  Upped to 8 from 5...
		var pad = 8

		if not in_limits({ "x": x, "y": y - pad, "w": 1, "h": 1}):
			return
	
		if not in_limits({ "x": x, "y": y + pad, "w": 1, "h": 1}):
			return
	
		if not in_limits({ "x": x - pad, "y": y, "w": 1, "h": 1}):
			return
	
		if not in_limits({ "x": x + pad, "y": y, "w": 1, "h": 1}):
			return

		# Check for nearby corridors
		# if connecting and nearby_corridor(x, y, k, 2):
		#	print("Killing path")
		#	return

		# Grab room data, if available
		var r = _get_data(x, y)
	
		if not r:
			todo.append({ "x": x,  "y": y, "val": { "isCorridor": true, "x": x, "y": y, "w": 1, "h": 1 }})
		else:
			touchedAnotherRoom = true
			break
		
	if touchedAnotherRoom or not connecting:
		for i in range(0, todo.size()):
			var t = todo[i]
			_set_data(t["x"], t["y"], t["val"])
			corridors.push_back({ "x": t["x"],  "y": t["y"] })

		if not touchedAnotherRoom:
			return { "x": x, "y": y }
		else:
			return

	return { "x": x, "y": y }



func get_random_room():
	return rooms[floor(rng.randi_range(0, rooms.size() - 1))]
