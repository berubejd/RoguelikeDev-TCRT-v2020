extends TileMap

# Temp?
const DIRECTIONS = {
	"NORTH": { "x": 0, "y": -1},
	"EAST": { "x": 1, "y": 0},
	"SOUTH": { "x": 0, "y": 1},
	"WEST": { "x": -1, "y": 0}
}

# TileSet indexes for walls and floors
const TILE_IDX_UNSET = -1
const TILE_IDX_WALL = 0
const TILE_IDX_FLOOR = 1

# Tileset size
const GRID_SIZE = 16

# Dungeon reference
var dungeon

# Dungeon complexity
export (int) var complexity = 1

# Room size range
export (int) var min_room_size = 4
export (int) var max_room_size = 10

# Corridor size range
export (int) var min_corridor_length = 5
export (int) var max_corridor_length = 15

# Instance a random number generator with range
var rng = RandomNumberGenerator.new()

# Preloads

# Lights
const TORCH = preload("res://Entities/Decoration/Torch.tscn")
const TORCH_EAST = preload("res://Entities/Decoration/TorchLeft.tscn")
const TORCH_WEST = preload("res://Entities/Decoration/TorchRight.tscn")
const TORCH_SOUTH = preload("res://Entities/Decoration/TorchBottom.tscn")
const CANDLEHOLDER = preload("res://Entities/Decoration/CandleHolder.tscn")

# Decorations - Is this a bad idea?
const BONES = [
	preload("res://Entities/Decoration/Bones.tscn"),
	preload("res://Entities/Decoration/Skull.tscn"),
	preload("res://Entities/Decoration/Skull_2.tscn")
	]
const ROCKS = [
	preload("res://Entities/Decoration/RockSmall.tscn"),
	preload("res://Entities/Decoration/RockSmall.tscn"),
	preload("res://Entities/Decoration/RockLarge.tscn")
	]

# Furniture
const STORAGE = [
	preload("res://Entities/Decoration/Barrel.tscn"),
	preload("res://Entities/Decoration/Crate_1.tscn"),
	preload("res://Entities/Decoration/Crate_2.tscn")
	]
const BOOKSHELF = preload("res://Entities/Decoration/Bookshelf.tscn")
const TABLE_LARGE = preload("res://Entities/Decoration/TableLarge.tscn")
const TABLE_SMALL = preload("res://Entities/Decoration/TableSmall.tscn")

onready var decorations = $Entities/Decorations
onready var bones = $Entities/Bones


func _ready():
	rng.randomize()
	dungeon = Dungeon_Builder.new()
	
	dungeon.add_room(-4, -4, 8, 8)
	
	for _i in range(complexity * 8):
		var newRoom = dungeon.add_random_corridor(dungeon.get_random_room(), rng.randi_range(min_corridor_length, max_corridor_length), false)
		if newRoom:
			# Attempt to create room at end of corridor
			var w = rng.randi_range(min_room_size, max_room_size);
			var h = rng.randi_range(min_room_size, max_room_size);
			dungeon.add_room(newRoom["x"], newRoom["y"], w, h)

	for _i in range(10 + complexity * 2):
		var _newRoom = dungeon.add_random_corridor(dungeon.get_random_room(), rng.randi_range(10, 20), true)

	# "Completed" dungeon generation
	print("Total rooms created: " + str(dungeon.rooms.size()))
	print("Total corridor tiles created: " + str(dungeon.corridors.size()))

	# Add rooms and corridors to tilemap
	for room in dungeon.rooms:
		_add_floor(room["x"], room["y"], room["w"], room["h"])
		_add_walls(room["x"], room["y"], room["w"], room["h"])

	for room in dungeon.corridors:
		_add_floor(room["x"], room["y"], 1, 1)
		_add_walls(room["x"], room["y"], 1, 1)

	# Rerunning this room because I am losing a corner for some reason.  Come back and fix this.
	_add_walls(dungeon.rooms[0]["x"], dungeon.rooms[0]["y"], dungeon.rooms[0]["w"], dungeon.rooms[0]["h"])

	# Decorate rooms
	for room in dungeon.rooms:
		_decorate_room(room["x"], room["y"], room["w"], room["h"])


# Add floor tiles to tilemap based on generated dungeon map
func _add_floor(left, top, width, height):
	for y in range(top, top + height):
		for x in range(left, left + width):
			set_cell(x, y, TILE_IDX_FLOOR, false, false, false, Vector2(rng.randi_range(0, 3), rng.randi_range(0, 2)))


# Add walls to tilemap given assigned tile index
func _add_walls(left, top, width, height):
	for y in range(top - 1, top + height + 1):
		for x in range(left - 1, left + width + 1):
			if not get_cell(x, y) == TILE_IDX_FLOOR:
				# Wall space is only 1 tile wide so remove and replace with a floor
				if get_cell(x - 1, y) == TILE_IDX_FLOOR and get_cell(x+1, y) == TILE_IDX_FLOOR:
					_add_floor(x, y, 1, 1)
					continue				
				if get_cell(x, y - 1) == TILE_IDX_FLOOR and get_cell(x, y+1) == TILE_IDX_FLOOR:
					_add_floor(x, y, 1, 1)
					continue		

				# Normal walls

				# Southern facing wall
				if get_cell(x, y + 1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(rng.randi_range(1, 4), 0))
					continue

				# Northern facing wall
				if get_cell(x, y - 1) == TILE_IDX_FLOOR:
					# Upper left corner
					if get_cell(x - 1, y) == TILE_IDX_FLOOR:
						set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(0, 5))
					# Upper right corner
					elif get_cell(x + 1, y) == TILE_IDX_FLOOR:
						set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(5, 5))
					# Standard northern wall
					else:
						set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(rng.randi_range(1, 2),rng.randi_range(4, 5)))
					continue

				# Eastern facing wall
				if get_cell(x + 1, y) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(0, rng.randi_range(0, 3)))
					continue

				# Western facing wall
				if get_cell(x - 1, y) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(5, rng.randi_range(0, 3)))
					continue

				# Diagonals

				# Lower left corner
				if get_cell(x + 1, y - 1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(0, 4))
					continue

				# Lower right corner
				if get_cell(x - 1, y - 1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(5, 4))
					continue

				# Upper left corner
				if get_cell(x + 1, y + 1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(0, 0))
					continue

				# Upper right corner
				if get_cell(x - 1, y + 1) == TILE_IDX_FLOOR:
					set_cell(x, y, TILE_IDX_WALL, false, false, false, Vector2(5, 0))
					continue


# Add appropriate torch to given wall
func _add_torch(x, y, facing):
	var torch_node
	
	match facing:
		"s":
			torch_node = TORCH
		"w":
			torch_node = TORCH_WEST
		"e":
			torch_node = TORCH_EAST
		"n":
			torch_node = TORCH_SOUTH

	_place_object(torch_node, decorations, x, y)


# Place decorations within a given room
func _decorate_room(left, top, width, height):
	# Determine what type of room this is
	var room_type = rng.randi_range(0, 10)
	
	# Yes, I am re-using this variable.  Ewwww.
	if room_type <= 1:
		room_type = "empty"
	elif room_type <= 6:
		room_type = "ruins"
	elif room_type <= 8:
		room_type = "storage"
	elif room_type == 9:
		room_type = "lab"
	else:
		room_type = "library"

	print(room_type)

	# Decorate room based on tile and room type
	for y in range(top - 1, top + height + 2):
		for x in range(left - 1, left + width + 2):
			match get_cell(x, y):
				TILE_IDX_FLOOR:
					# Exit early since we won't be placing anything
					if room_type == "empty" or not _is_clear(x * GRID_SIZE + 8, y * GRID_SIZE + 8):
						continue

					var near_corridor = _nearby_corridor(x, y)
					var near_wall = _nearby_wall(x, y)

					var decoration

					match room_type:
						"ruins":
							if not near_corridor:
								var chance = rng.randi_range(1, 100)

								if near_wall:
									if chance <= 10:
										ROCKS.shuffle()
										_place_object(ROCKS[0], decorations, x, y)

								else:
									if chance <= 5:
										ROCKS.shuffle()
										_place_object(ROCKS[0], decorations, x, y)

									elif chance <= 15:
										BONES.shuffle()

										# Flips some bone decorations for variety
										var flip = false

										if rng.randf() > 0.5:
											flip = true

										_place_object(BONES[0], bones, x, y, flip)

						"storage":
							if not near_corridor and not near_wall:
								var chance = rng.randi_range(1, 100)
								
								if chance <= 10:
									STORAGE.shuffle()
									_place_object(STORAGE[0], decorations, x, y)
								elif chance <= 13:
									BONES.shuffle()

									# Flips some bone decorations for variety
									var flip = false

									if rng.randf() > 0.5:
										flip = true

									_place_object(BONES[0], bones, x, y, flip)

						"lab":
							pass
							
							var table
							
							if not near_corridor:
								var chance = rng.randi_range(1, 100)
								
								if near_wall:
									pass

								else:
									if chance <= 4:
										_place_object(CANDLEHOLDER, decorations, x, y)

									if chance <= 15:
										var r_dir = DIRECTIONS.keys()
										while true:
											r_dir.shuffle()
											# print(DIRECTIONS[r_dir[0]])
											if rng.randf() > 0.5:
												table = TABLE_LARGE
											else:
												table = TABLE_SMALL

											_place_object(table, decorations, x, y)

						"library":
							if (
								# Not the top row but the bottom is okay because of the way bookshelf collision is set up
								y > top and y < top + height and 
								# Not along the side walls
								x > left and x < left + width - 1 and 
								# Every other row
								not int(top - y) % 2 == 0 # and
								):

								var row_width = width - 2
								var shelf_pos = int(x - left)
								var table_space = false
								var table_offset = 0

								# Have tables take the entire row - XX
								if row_width == 2:
									if shelf_pos == 1:
										table_space = true

								# Have tables take the entire row - XXX
								if row_width == 3 and shelf_pos == 1:
									table_space = true
									table_offset = 9

								# Anything is appropriate for tables - XXXX
								if row_width == 4:
									table_space = true

								# Open up middle row - XX XX or XXX XXX
								if (row_width == 5 or row_width == 7):
									if shelf_pos == int(row_width / 2) + 1:
										continue
									else:
										if row_width == 5 and (shelf_pos == 1 or shelf_pos == 4):
											table_space = true

										if row_width == 7 and (shelf_pos == 1 or shelf_pos == 5):
											table_space = true
											table_offset = 9

								# Open up space after the first shelf and before the last - X XX X
								if row_width == 6:
									if (shelf_pos == 2 or shelf_pos == 5):
										continue
									else:
										if shelf_pos == 3:
											table_space = true

								# Create aisles of two shelves - XX XX XX
								if row_width == 8:
									if shelf_pos % 3 == 0:
										continue
									else:
										if shelf_pos == 4:
											table_space = true
								
								# Correct this behavior!
								if (
									# Determined to be a potential spot above
									table_space and
									# Check next tile is clear, as well
									_is_clear((x + 1) * GRID_SIZE + 8, y * GRID_SIZE + 8) and
									# Since we skip corridor verification earlier check it for both tiles now
									not _is_corridor(x + 2, y) and
									# Since we skip wall verification earlier check it for both tiles now
									not get_cell(x + 2, y) == TILE_IDX_WALL and
									# We don't want *all* tables...
									rng.randi_range(1, 100) < 20
									):

									decoration = TABLE_LARGE.instance()
									
									# Place this directly due to the offset on the y position
									decoration.position.x = x * GRID_SIZE + table_offset
									decoration.position.y = y * GRID_SIZE - 6
									decorations.add_child(decoration)
								else:
									_place_object(BOOKSHELF, decorations, x, y)

				TILE_IDX_WALL:
					# Southern facing wall
					if get_cell(x, y + 1) == TILE_IDX_FLOOR:
						if _is_corridor(x + 1, y) or _is_corridor(x - 1, y):
							if rng.randf() <= 1: #0.5:
								_add_torch(x, y, "s")

					# Northern facing wall
					if get_cell(x, y - 1) == TILE_IDX_FLOOR:
						if _is_corridor(x + 1, y) or _is_corridor(x - 1, y):
							if rng.randf() <= 1: #0.5:
								_add_torch(x, y - 1, "n")

					# Eastern facing wall
					if get_cell(x + 1, y) == TILE_IDX_FLOOR:
						if _is_corridor(x, y + 1) or _is_corridor(x, y - 1):
							if rng.randf() <= 1: #0.5:
								_add_torch(x + 1, y, "e")

					# Western facing wall
					if get_cell(x - 1, y) == TILE_IDX_FLOOR:
						if _is_corridor(x, y + 1) or _is_corridor(x, y - 1):
							if rng.randf() <= 1: #0.5:
								_add_torch(x - 1, y, "w")


# Return a random floor cell within a specific range
func _get_random_floor_cell(left, top, width, height):
	# Build an array of all floor tiles inside given rect
	var cells = []
	for y in range(top, top + height):
		for x in range(left, left + width):
			if get_cell(x, y) == TILE_IDX_FLOOR: cells.push_back({"x": x, "y": y})
			
	# Pick one at random
	return cells[rng.randi_range(0, cells.size()-1)]


# Check if the target position is free of collision objects
func _is_clear(x, y):
	var world = get_world_2d().get_direct_space_state()
	var results = world.intersect_point(Vector2(x, y))
	
	if not results:
		return true
	else:
		print(x, ":", y, " ", results)
		return false


# Check for corridor at specific x, y coordinates
func _is_corridor(x, y):
	if  dungeon._get_data(x, y) && dungeon._get_data(x, y).get("isCorridor"):
		return true
	else:
		return false


# Check for wall at specific x, y coordinates
func _is_wall(x, y):
	if get_cell(x, y - 1) == TILE_IDX_WALL:
		return true
	else:
		return false


# Check for corridor in cardinal direction
func _nearby_corridor(x, y):
	if _is_corridor(x, y - 1) or _is_corridor(x, y + 1) or _is_corridor(x - 1, y) or _is_corridor(x + 1, y):
		return true
	else:
		return false


# Check for wall in cardinal directions
func _nearby_wall(x, y):
	if get_cell(x, y - 1) == TILE_IDX_WALL or get_cell(x, y + 1) == TILE_IDX_WALL or get_cell(x - 1, y) == TILE_IDX_WALL or get_cell(x + 1, y) == TILE_IDX_WALL:
	# if _is_wall(x, y - 1) or _is_wall(x, y + 1) or _is_wall(x - 1, y) or _is_wall(x + 1, y):
		return true
	else:
		return false


# Place object ont the map
func _place_object(object_scene, object_group, x, y, flip = false):
	var new_object = object_scene.instance()

	new_object.position.x = x * GRID_SIZE
	new_object.position.y = y * GRID_SIZE

	if flip and new_object.get_node_or_null("Sprite"):
		new_object.get_node("Sprite").flip_h = true

	object_group.add_child(new_object)

