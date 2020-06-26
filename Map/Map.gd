extends TileMap

# TileSet indexes for walls and floors
const TILE_IDX_UNSET = -1
const TILE_IDX_WALL = 0
const TILE_IDX_FLOOR = 1

# Dungeon complexity
export (int) var complexity = 3

# Room size range
export (int) var min_room_size = 4
export (int) var max_room_size = 10

# Corridor size range
export (int) var min_corridor_length = 5
export (int) var max_corridor_length = 10

# Instance a random number generator with range
var rng = RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	var dungeon = Dungeon_Builder.new()
	
	dungeon.add_room(-4, -4, 8, 8)
	
	for _i in range(complexity * 8):
		var newRoom = dungeon.add_random_corridor(dungeon.get_random_room(), rng.randi_range(min_corridor_length, max_corridor_length), false)
		if newRoom:
			# Attempt to create room at end of corridor
			var w = rng.randi_range(min_room_size, max_room_size);
			var h = rng.randi_range(min_room_size, max_room_size);
			dungeon.add_room(newRoom["x"], newRoom["y"], w, h)

	for i in range(10 + complexity * 2):
		var newRoom = dungeon.add_random_corridor(dungeon.get_random_room(), rng.randi_range(10, 20), true)
		if newRoom:
			print("Loop2: Room " + str(i) + " created at : " + str(newRoom) + ".")

	# "Completed" dungeon generation
	print("Total rooms created: " + str(dungeon.rooms.size()))
	print("Total corridors created: " + str(dungeon.corridors.size()))

	for room in dungeon.rooms:
		_add_floor(room["x"], room["y"], room["w"], room["h"])
		_add_walls(room["x"], room["y"], room["w"], room["h"])

	for room in dungeon.corridors:
		_add_floor(room["x"], room["y"], 1, 1)
		_add_walls(room["x"], room["y"], 1, 1)


func _add_floor(left, top, width, height):
	for y in range(top, top + height):
		for x in range(left, left + width):
			set_cell(x, y, TILE_IDX_FLOOR, false, false, false, Vector2(rng.randi_range(0, 3), rng.randi_range(0, 2)))


func _add_walls(left, top, width, height):
	for y in range(top - 2, top + height + 2):
		for x in range(left - 2, left + width + 2):
			# if get_cell(x, y) == TILE_IDX_UNSET:
			if not get_cell(x, y) == TILE_IDX_FLOOR:
				# Wall space is only 1 tile wide so remove and replace with a floor
				if get_cell(x-1, y) == TILE_IDX_FLOOR and get_cell(x+1, y) == TILE_IDX_FLOOR:
					_add_floor(x, y, 1, 1)
					# Create a column tile to put here?
					continue				
				if get_cell(x, y-1) == TILE_IDX_FLOOR and get_cell(x, y+1) == TILE_IDX_FLOOR:
					_add_floor(x, y, 1, 1)
					# Create a column tile to put here?
					continue		

				# Normal walls

				# Southern facing wall
				if get_cell(x, y+1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(rng.randi_range(1, 4), 0))
					# Add a torch (or an animated/regular banner?)
#					if rng.randf() <= 0.2:
#						_add_torch(x, y)
					continue

				# Northern facing wall
				if get_cell(x, y-1) == TILE_IDX_FLOOR:
					# Upper left corner
					if get_cell(x-1, y) == TILE_IDX_FLOOR:
						set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(0, 5))
					# Upper right corner
					elif get_cell(x+1, y) == TILE_IDX_FLOOR:
						set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(5, 5))
					# Standard northern wall
					else:
						set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(rng.randi_range(1, 2),rng.randi_range(4, 5)))
					continue

				# Eastern facing wall
				if get_cell(x+1, y) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(0, rng.randi_range(0, 3)))
					continue

				# Western facing wall
				if get_cell(x-1, y) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(5, rng.randi_range(0, 3)))
					continue

				# Diagonals

				# Lower left corner
				if get_cell(x+1, y-1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(0, 4))
					continue

				# Lower right corner
				if get_cell(x-1, y-1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(5, 4))
					continue

				# Upper left corner
				if get_cell(x+1, y+1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(0, 0))
					continue

				# Upper right corner
				if get_cell(x-1, y+1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(5, 0))
					continue
