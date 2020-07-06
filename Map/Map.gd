extends TileMap

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

# Monster count
export (int) var max_monsters_per_room = 3

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
const FOUNTAIN = preload("res://Entities/Decoration/Fountain.tscn")

# Furniture
const STORAGE = [
	preload("res://Entities/Decoration/Barrel.tscn"),
	preload("res://Entities/Decoration/Crate_1.tscn"),
	preload("res://Entities/Decoration/Crate_2.tscn")
	]
const BOOKSHELF = preload("res://Entities/Decoration/Bookshelf.tscn")
const TABLE_LARGE = preload("res://Entities/Decoration/TableLarge.tscn")
const TABLE_SMALL = preload("res://Entities/Decoration/TableSmall.tscn")
const CAULDRON = preload("res://Entities/Decoration/Cauldron.tscn")

# Exit
const EXIT = preload("res://Entities/Items/Exit.tscn")

# Monsters
const GENERIC_MOB = preload("res://Entities/Mobs/Mob.tscn")

# Entity group pointers
onready var decorations = $Entities/Decorations
onready var bones = $Entities/Bones
onready var mobs = $Entities/Mobs

# Start and Exit level rooms
var start_room
var exit_room


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

	# Try adding corridors first to see if it resolves the strange "corner missing" issue
	for room in dungeon.corridors:
		_add_floor(room["x"], room["y"], 1, 1)
		_add_walls(room["x"], room["y"], 1, 1)

	# Add rooms and corridors to tilemap
	for room in dungeon.rooms:
		_add_floor(room["x"], room["y"], room["w"], room["h"])
		_add_walls(room["x"], room["y"], room["w"], room["h"])

	# Rerunning this room because I am losing a corner for some reason.  Come back and fix this.
	_add_walls(dungeon.rooms[0]["x"], dungeon.rooms[0]["y"], dungeon.rooms[0]["w"], dungeon.rooms[0]["h"])

	# Set up start room
	start_room = dungeon.rooms[randi() % len(dungeon.rooms)]

	# Decorate rooms
	for room in dungeon.rooms:
		var add_mobs = true
		
		if room == start_room:
			add_mobs = false
		
		_populate_room(room["x"], room["y"], room["w"], room["h"], add_mobs)

	# Add exit	
	while true:
		exit_room = dungeon.rooms[randi() % len(dungeon.rooms)]
		if not exit_room == start_room:
			break
	
	# Place exit
	var exit_cell = _get_random_floor_cell(exit_room["x"], exit_room["y"], exit_room["w"], exit_room["h"], true, true)
	var exit_result = _place_object(EXIT, $Darkness, exit_cell.x, exit_cell.y)
	if not exit_result:
		print("F*CK")


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
func _populate_room(left, top, width, height, add_mobs = true):
	# Determine what type of room this is
	var room_type = rng.randi_range(0, 10)
	
	# Hold list of possible monsters for the room
	var room_monsters: Array
	
	# Yes, I am re-using this variable.  Ewwww.
	if room_type <= 1:
		room_type = "empty"
		room_monsters = [GENERIC_MOB]
	elif room_type <= 6:
		room_type = "ruins"
		room_monsters = [GENERIC_MOB]
	elif room_type <= 8:
		room_type = "storage"
		room_monsters = [GENERIC_MOB]
	elif room_type == 9:
		room_type = "lab"
		room_monsters = [GENERIC_MOB]
		
		# Place a single cauldron in labs
		var random_tile = _get_random_floor_cell(left, top, width, height, true)
		_place_object(CAULDRON, decorations, random_tile.x, random_tile.y)
	else:
		room_type = "library"
		room_monsters = [GENERIC_MOB]

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
									if chance == 100:
										# Still to common so cut it in half again rather than increase the random range
										if rng.randf() > 0.5:
											_place_object(FOUNTAIN, decorations, x, y)

										continue

									elif chance <= 6:
										ROCKS.shuffle()
										_place_object(ROCKS[0], decorations, x, y)
										continue

									elif chance <= 16:
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
									continue

								elif chance <= 13:
									BONES.shuffle()

									# Flips some bone decorations for variety
									var flip = false

									if rng.randf() > 0.5:
										flip = true

									_place_object(BONES[0], bones, x, y, flip)

						"lab":
							if not near_corridor:
								var chance = rng.randi_range(1, 100)
								
								if not near_wall:
									if height > 5 and width > 5:
										if (
											(x == left + 1 or x == left + width - 2) and
											(y == top + 1 or y == top + height - 2)
										):
											_place_object(CANDLEHOLDER, decorations, x, y)
											continue
										else:
											if x == left + (width / 2) - 1 and y == top + (height / 2):
												if _is_clear(x + 1, y) and _is_clear(x + 2, y):
													_place_object(TABLE_LARGE, decorations, x, y)
													_place_object(CANDLEHOLDER, decorations, x + 2, y)
									else:
										if x == left + int(width / 2) - 1 and y == top + int(height / 2):
											if _is_clear(x + 1, y):
												_place_object(TABLE_LARGE, decorations, x, y)
										elif chance <= 4:
											_place_object(CANDLEHOLDER, decorations, x, y)
											continue

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

								# This is going to be a table or bookshelf.  Check for table first.
								if (
									# Determined to be a potential spot for a table above
									table_space and
									# Check next tile is clear, as well
									_is_clear((x + 1) * GRID_SIZE + 8, y * GRID_SIZE + 8) and
									# Perform corridor verification for the space after the end of the table
									not _is_corridor(x + 2, y) and
									# Perform wall verification for the space after the end of the table
									not get_cell(x + 2, y) == TILE_IDX_WALL and
									# We don't want *all* tables just because it could be one...
									rng.randi_range(1, 100) < 20
									):

									decoration = TABLE_LARGE.instance()
									
									# Place this directly due to the offset on the y position
									decoration.position.x = x * GRID_SIZE + table_offset
									decoration.position.y = y * GRID_SIZE - 6
									decorations.add_child(decoration)
								else:
									if _is_clear(x * GRID_SIZE + 8, y * GRID_SIZE + 8):
										var flip = false
									
										if rng.randf() > 0.85:
											flip = true
										
										_place_object(BOOKSHELF, decorations, x, y, flip)

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

	# Populate room with monsters
	if add_mobs:
		var room_sq = width * height
		var max_sq = pow(max_room_size, 2)
		var max_monsters = ceil((room_sq / max_sq) * max_monsters_per_room)
		
		for _monster in range(max_monsters):
			var monster_cell = _get_random_floor_cell(left, top, width, height, true, false, true)
			room_monsters.shuffle()
			_place_object(room_monsters[0], mobs, monster_cell.x, monster_cell.y)


# Return a random floor cell within a specific range
func _get_random_floor_cell(left, top, width, height, clear_check = false, avoid_corridor = true, avoid_wall = false):
	# Build an array of all floor tiles inside given rect
	var cells = []
	var chosen_cell
	for y in range(top, top + height):
		for x in range(left, left + width):
			if get_cell(x, y) == TILE_IDX_FLOOR: cells.push_back({"x": x, "y": y})
			
	# Pick one at random
	while true:
		chosen_cell = cells[rng.randi_range(0, cells.size() - 1)]
		
		if clear_check and not _is_clear(chosen_cell.x * GRID_SIZE + 8, chosen_cell.y * GRID_SIZE + 8):
			continue

		if avoid_corridor and _nearby_corridor(chosen_cell.x, chosen_cell.y):
			continue

		if avoid_wall and _nearby_wall(chosen_cell.x, chosen_cell.y):
			continue

		return chosen_cell


# Check if the target position is free of collision objects
func _is_clear(x, y, report_collision = false):
	var world = get_world_2d().get_direct_space_state()
	var results = world.intersect_point(Vector2(x, y))
	
	if not results:
		return true
	else:
		if report_collision:
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
	if get_cell(x, y) == TILE_IDX_WALL:
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
	# if get_cell(x, y - 1) == TILE_IDX_WALL or get_cell(x, y + 1) == TILE_IDX_WALL or get_cell(x - 1, y) == TILE_IDX_WALL or get_cell(x + 1, y) == TILE_IDX_WALL:
	if _is_wall(x, y - 1) or _is_wall(x, y + 1) or _is_wall(x - 1, y) or _is_wall(x + 1, y):
		return true
	else:
		return false


# Place object on the map
func _place_object(object_scene, object_group, x, y, flip = false):
	if not _is_clear(x * GRID_SIZE + 8, y * GRID_SIZE + 8):
		print("Blocking placement from _place_object")
		return false

	var new_object = object_scene.instance()

	new_object.position.x = x * GRID_SIZE
	new_object.position.y = y * GRID_SIZE

	if flip and new_object.get_node_or_null("Sprite"):
		new_object.get_node("Sprite").flip_h = true

	object_group.add_child(new_object)
	
	return true

