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
export (int) var complexity: = 1
export (int) var level_scale: = 3

# Room size range
export (int) var min_room_size: = 4
export (int) var max_room_size: = 10

# Corridor size range
export (int) var min_corridor_length: = 5
export (int) var max_corridor_length: = 15

# Monster count
# export (int) var max_monsters_per_room: = 3
var max_monsters_per_room

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

# Items
const POTION_HEALTH = preload("res://Entities/Items/potion_health.tscn")

# Entity group pointers
onready var decorations = $Entities/Decorations
onready var bones = $Entities/Bones
onready var items = $Entities/Items
onready var mobs = $Entities/Mobs

# Start and Exit level rooms
var start_room = null
var exit_room = null
var exit_cell = null

# SaveGame map references
var entities = null


func _ready():
	pause_mode = Node.PAUSE_MODE_STOP
	
	max_monsters_per_room = _from_dungeon_level([[2, 0], [3, 4], [5, 6]], Globals.dungeon_level)

# warning-ignore:integer_division
	var scaled_complexity = complexity + floor(Globals.dungeon_level / level_scale)

	rng.randomize()
	dungeon = Dungeon_Builder.new()
	
	if not Globals.save_data:
		dungeon.add_room(Rect2(-4, -4, 8, 8))
		
		for _i in range(scaled_complexity * 8):
			var new_room = dungeon.add_random_corridor(dungeon.get_random_room(), rng.randi_range(min_corridor_length, max_corridor_length), false)
			if new_room:
				# Attempt to create room at end of corridor
				var w = rng.randi_range(min_room_size, max_room_size);
				var h = rng.randi_range(min_room_size, max_room_size);
				dungeon.add_room(Rect2(new_room.x, new_room.y, w, h))
	
		for _i in range(10 + scaled_complexity * 2):
			var _new_room = dungeon.add_random_corridor(dungeon.get_random_room(), rng.randi_range(10, 20), true)
	
		# "Completed" dungeon generation
		print("Total rooms created: " + str(dungeon.rooms.size()))
		print("Total corridor tiles created: " + str(dungeon.corridors.size()))
	else:
		load_state(Globals.save_data[name])

	# Try adding corridors first to see if it resolves the strange "corner missing" issue
	for corridor_cell in dungeon.corridors:
		_add_floor(Rect2(corridor_cell.x, corridor_cell.y, 1, 1))
		_add_walls(Rect2(corridor_cell.x, corridor_cell.y, 1, 1))

	# Add rooms and corridors to tilemap
	for room in dungeon.rooms:
		_add_floor(room["room"])
		_add_walls(room["room"])

	# Rerunning this room because I am losing a corner for some reason.  Come back and fix this since it still doesn't work.
	_add_walls(dungeon.rooms[0]["room"])

	# Set up start room
	if not start_room:
		start_room = dungeon.rooms[randi() % len(dungeon.rooms)]

	# Decorate rooms
	if not entities:
		for room in dungeon.rooms:
			var add_mobs: = true
			
			if room == start_room:
				add_mobs = false
			
			_populate_room(room["room"], add_mobs)
	else:
		load_entities(Globals.save_data[name])

	# Add exit	
	if not exit_cell:
		while true:
			exit_room = dungeon.rooms[randi() % len(dungeon.rooms)]
			if not exit_room == start_room:
				break
		
		# Place exit
		exit_cell = _get_random_floor_cell(exit_room["room"], true, true)

	var exit_result = _place_object(EXIT, $Darkness, exit_cell)
	if not exit_result:
		print("F*CK")

	if Globals.save_data.has(name):
		var _ret = Globals.save_data.erase(name)


# Add floor tiles to tilemap based on generated dungeon map
func _add_floor(room: Rect2):
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			set_cell(x, y, TILE_IDX_FLOOR, false, false, false, Vector2(rng.randi_range(0, 3), rng.randi_range(0, 2)))


# Add walls to tilemap given assigned tile index
func _add_walls(room: Rect2):
	for y in range(room.position.y - 1, room.end.y + 1):
		for x in range(room.position.x - 1, room.end.x + 1):
			if not get_cell(x, y) == TILE_IDX_FLOOR:
				# Wall space is only 1 tile wide so remove and replace with a floor
				if get_cell(x - 1, y) == TILE_IDX_FLOOR and get_cell(x+1, y) == TILE_IDX_FLOOR:
					_add_floor(Rect2(x, y, 1, 1))
					continue
				if get_cell(x, y - 1) == TILE_IDX_FLOOR and get_cell(x, y+1) == TILE_IDX_FLOOR:
					_add_floor(Rect2(x, y, 1, 1))
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
func _add_torch(position, facing):
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

	_place_object(torch_node, decorations, position)


# Place decorations within a given room
func _populate_room(room: Rect2, add_mobs = true):
	# Determine what type of room this is
	var room_chance = {"ruins": 50, "storage": 20, "lab": 10, "library": 10, "empty": 10}
	var room_type = _random_choice_from_dict(room_chance)

	# Hold list of possible monsters for the room
	var room_monsters: Dictionary

	match room_type:
		"ruins", "storage", "library", "empty":
			room_monsters = {GENERIC_MOB: 100}
		"lab":
			room_monsters = {GENERIC_MOB: 100}
			
			# Place a single cauldron in labs
			var cauldron_cell = _get_random_floor_cell(room, true)
			_place_object(CAULDRON, decorations, cauldron_cell)
	
			# Place a single potion as well
			var potion_cell = _get_random_floor_cell(room, true, false, true)
			_place_object(POTION_HEALTH, items, potion_cell)

	# Decorate room based on tile and room type
	for y in range(room.position.y - 1, room.end.y + 2):
		for x in range(room.position.x - 1, room.end.x + 2):
			match get_cell(x, y):
				TILE_IDX_FLOOR:
					# Exit early since we won't be placing anything
					if room_type == "empty" or not _is_clear(map_to_world(Vector2(x, y)) + Vector2(8, 8)):
						continue

					var near_corridor = _nearby_corridor(Vector2(x, y))
					var near_wall = _nearby_wall(Vector2(x, y))

					match room_type:
						"ruins":
							if not near_corridor:
								var chance = rng.randi_range(1, 100)

								if near_wall:
									if chance <= 10:
										ROCKS.shuffle()
										_place_object(ROCKS[0], decorations, Vector2(x, y))

								else:
									if chance == 100:
										# Still to common so cut it in half again rather than increase the random range
										if rng.randf() > 0.5:
											_place_object(FOUNTAIN, decorations, Vector2(x, y))

										continue

									elif chance <= 6:
										ROCKS.shuffle()
										_place_object(ROCKS[0], decorations, Vector2(x, y))
										continue

									elif chance <= 16:
										BONES.shuffle()

										# Flips some bone decorations for variety
										var flip = false
										if rng.randf() > 0.5:
											flip = true

										_place_object(BONES[0], bones, Vector2(x, y), flip)

						"storage":
							if not near_corridor and not near_wall:
								var chance = rng.randi_range(1, 100)
								
								if chance <= 10:
									STORAGE.shuffle()
									_place_object(STORAGE[0], decorations, Vector2(x, y))
									continue

								elif chance <= 13:
									BONES.shuffle()

									# Flips some bone decorations for variety
									var flip = false

									if rng.randf() > 0.5:
										flip = true

									_place_object(BONES[0], bones, Vector2(x, y), flip)

						"lab":
							if not near_corridor:
								var chance = rng.randi_range(1, 100)
								
								if not near_wall:
									if room.size.y > 5 and room.size.x > 5:
										if (
											(x == room.position.x + 1 or x == room.end.x - 2) and
											(y == room.position.y + 1 or y == room.end.y - 2)
										):
											_place_object(CANDLEHOLDER, decorations, Vector2(x, y))
											continue

										if x == room.position.x + int(room.size.x / 2) - 1 and y == room.position.y + int(room.size.y / 2):
											if _is_clear(Vector2(x + 1, y)) and _is_clear(Vector2(x + 2, y)):
												_place_object(TABLE_LARGE, decorations, Vector2(x, y))
												_place_object(CANDLEHOLDER, decorations, Vector2(x + 2, y))
									else:
										if x == room.position.x + int(room.size.x / 2) - 1 and y == room.position.y + int(room.size.y / 2):
											if _is_clear(Vector2(x + 1, y)):
												_place_object(TABLE_LARGE, decorations, Vector2(x, y))
										elif chance <= 4:
											_place_object(CANDLEHOLDER, decorations, Vector2(x, y))
											continue

						"library":
							if (
								# Not the top row but the bottom is okay because of the way bookshelf collision is set up
								y > room.position.y and y < room.end.y and 
								# Not along the side walls
								x > room.position.x and x < room.end.x - 1 and 
								# Every other row
								not int(room.position.y - y) % 2 == 0 # and
								):

								var row_width = room.size.x - 2
								var shelf_pos = int(x - room.position.x)
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
									_is_clear(Vector2((x + 1) * GRID_SIZE + 8, y * GRID_SIZE + 8)) and
									# Perform corridor verification for the space after the end of the table
									not _is_corridor(Vector2(x + 2, y)) and
									# Perform wall verification for the space after the end of the table
									not get_cell(x + 2, y) == TILE_IDX_WALL and
									# We don't want *all* tables just because it could be one...
									rng.randi_range(1, 100) < 20
									):

									var decoration = TABLE_LARGE.instance()
									
									# Place this directly due to the offset on the y position
									decoration.position.x = x * GRID_SIZE + table_offset
									decoration.position.y = y * GRID_SIZE - 6
									decorations.add_child(decoration)
								else:
									if _is_clear(map_to_world(Vector2(x, y)) + Vector2(8, 8)):
										var flip = false
									
										if rng.randf() > 0.85:
											flip = true
										
										_place_object(BOOKSHELF, decorations, Vector2(x, y), flip)

				TILE_IDX_WALL:
					# Southern facing wall
					if get_cell(x, y + 1) == TILE_IDX_FLOOR:
						if _is_corridor(Vector2(x + 1, y)) or _is_corridor(Vector2(x - 1, y)):
							_add_torch(Vector2(x, y), "s")

					# Northern facing wall
					if get_cell(x, y - 1) == TILE_IDX_FLOOR:
						if _is_corridor(Vector2(x + 1, y)) or _is_corridor(Vector2(x - 1, y)):
							_add_torch(Vector2(x, y - 1), "n")

					# Eastern facing wall
					if get_cell(x + 1, y) == TILE_IDX_FLOOR:
						if _is_corridor(Vector2(x, y + 1)) or _is_corridor(Vector2(x, y - 1)):
							_add_torch(Vector2(x + 1, y), "e")

					# Western facing wall
					if get_cell(x - 1, y) == TILE_IDX_FLOOR:
						if _is_corridor(Vector2(x, y + 1)) or _is_corridor(Vector2(x, y - 1)):
							_add_torch(Vector2(x - 1, y), "w")

	# Populate room with monsters
	if add_mobs:
		var room_sq = room.size.x * room.size.y
		var max_sq = pow(max_room_size, 2)
		var max_monsters = ceil((room_sq / max_sq) * max_monsters_per_room)
		
		for _monster in range(max_monsters):
			var monster_cell = _get_random_floor_cell(room, true, false, true)
			# room_monsters.shuffle()
			# _place_object(room_monsters[0], mobs, monster_cell)
			var monster = _random_choice_from_dict(room_monsters)
			_place_object(monster, mobs, monster_cell)


# Return a random floor cell within a specific range
func _get_random_floor_cell(room: Rect2, clear_check: bool = false, avoid_corridor: bool = true, avoid_wall: bool = false):
	# Build an array of all floor tiles inside given rect
	var cells = []
	var chosen_cell
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			if get_cell(x, y) == TILE_IDX_FLOOR:
				cells.push_back(Vector2(x, y))
			
	# Pick one at random
	while true:
		chosen_cell = cells[rng.randi_range(0, cells.size() - 1)]
		
		if clear_check and not _is_clear(map_to_world(Vector2(chosen_cell.x, chosen_cell.y)) + Vector2(8, 8)):
			continue

		if avoid_corridor and _nearby_corridor(Vector2(chosen_cell.x, chosen_cell.y)):
			continue

		if avoid_wall and _nearby_wall(Vector2(chosen_cell.x, chosen_cell.y)):
			continue

		return chosen_cell


# Check if the target position is free of collision objects
func _is_clear(position: Vector2, report_collision: bool = false):
	var world = get_world_2d().get_direct_space_state()
	var results = world.intersect_point(position)
	
	if not results:
		return true
	else:
		if report_collision:
			print(position.x, ":", position.y, " ", results)

		return false


# Check for corridor at specific x, y coordinates
func _is_corridor(position: Vector2):
	if dungeon.get_data(position.x, position.y) && dungeon.get_data(position.x, position.y).get("isCorridor"):
		return true
	else:
		return false


# Check for wall at specific x, y coordinates
func _is_wall(position: Vector2):
	if get_cellv(position) == TILE_IDX_WALL:
		return true
	else:
		return false


# Check for corridor in cardinal direction
func _nearby_corridor(position: Vector2):
	if _is_corridor(position + Vector2.UP) or _is_corridor(position + Vector2.DOWN) or _is_corridor(position + Vector2.LEFT) or _is_corridor(position + Vector2.RIGHT):
		return true
	else:
		return false


# Check for wall in cardinal directions
func _nearby_wall(position: Vector2):
	if _is_wall(position + Vector2.UP) or _is_wall(position + Vector2.DOWN) or _is_wall(position + Vector2.LEFT) or _is_wall(position + Vector2.RIGHT):
		return true
	else:
		return false


# Place object on the map
func _place_object(object_scene, object_group, position: Vector2, flip: bool = false):
	if not _is_clear(map_to_world(position) + Vector2(8, 8)):
		print("Blocking placement from _place_object")
		return false

	var new_object = object_scene.instance()
	
	new_object.global_position = map_to_world(position)

	if flip and new_object.get_node_or_null("Sprite"):
		new_object.get_node("Sprite").flip_h = true

	object_group.add_child(new_object)
	
	return true


func _random_choice_index(chances):
	var random_chance = rng.randi_range(1, _sum(chances))

	var running_sum = 0
	var choice = 0
	for w in chances:
		running_sum += w

		if random_chance <= running_sum:
			return choice
		choice += 1


func _random_choice_from_dict(choice_dict):
	var choices = Array(choice_dict.keys())
	var chances = Array(choice_dict.values())

	return choices[_random_choice_index(chances)]


func _from_dungeon_level(table, dungeon_level):
	var t_table = table.duplicate(true)
	t_table.invert()

	for element in t_table:
		var value = element[0]
		var level = element[1]
		
		if dungeon_level >= level:
			return value

	return 0


func _sum(array):
	var sum = 0
	for element in array:
		sum += element
	return sum


func load_entities(data):
	for entity in data["entities"]:
		var current_entity = data["entities"][entity]
		var new_entity = load(current_entity["resource"])
		var new_group = find_node(current_entity["group"])
		var new_position = world_to_map(Vector2(current_entity["position"]["x"], current_entity["position"]["y"]))

		_place_object(new_entity, new_group, new_position, current_entity["flip"])


func save_state():
	var data = {
		"dungeon_level": Globals.dungeon_level,
		"rooms": dungeon.rooms,
		"corridors": dungeon.corridors,
		"start_room": start_room,
		"exit_room": exit_room,
		"exit_cell": exit_cell,
		"entities": {}
	}

	for entity_group in $Entities.get_children():
		if not entity_group is Player:
			for child in entity_group.get_children():
				data["entities"][child.name] = {
					"resource": child.filename,
					"group": entity_group.name,
					"position": {
						"x": child.position.x,
						"y": child.position.y
					},
					"flip": true if child.get_node_or_null("Sprite") and child.get_node("Sprite").flip_h else false
				}

	return data


func load_state(data):
	# Regex for Vector2
	var r_vect2 = RegEx.new()
	r_vect2.compile("(-?\\d+), (-?\\d+)")

	# Regex for Rect2
	var r_rect2 = RegEx.new()
	r_rect2.compile("(-?\\d+), (-?\\d+), (-?\\d+), (-?\\d+)")
	
	for attribute in data:
		if attribute == "dungeon_level":
			Globals.dungeon_level = data[attribute]
		elif attribute == "rooms":
			var new_room
			for room in data[attribute]:
				var result = r_rect2.search(room["room"])
				new_room = Rect2(result.get_string(1), result.get_string(2), result.get_string(3), result.get_string(4))
				room["room"] = new_room
			dungeon.rooms = data[attribute]
		elif attribute == "corridors":
			var new_corridors = []
			for cell in data[attribute]:
				var result = r_vect2.search(cell)
				new_corridors.append(Vector2(result.get_string(1), result.get_string(2)))
			dungeon.corridors = new_corridors
		elif attribute == "exit_room" or attribute == "start_room":
			var result = r_rect2.search(data[attribute]["room"])
			data[attribute]["room"] = Rect2(result.get_string(1), result.get_string(2), result.get_string(3), result.get_string(4))
			set(attribute, data[attribute])
		elif attribute == "exit_cell":
			var result = r_vect2.search(data[attribute])
			exit_cell = Vector2(result.get_string(1), result.get_string(2))
		else:
			set(attribute, data[attribute])
