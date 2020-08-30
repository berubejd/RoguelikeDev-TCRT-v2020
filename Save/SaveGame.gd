extends Node

const SAVE_PATH = "res://savegame.json"

# warning-ignore:unused_signal
signal save_game


func _ready():
# warning-ignore:return_value_discarded
	connect("save_game", self, "save_game")


func save_game():
	# Wait for an idle frame to make sure all the signals (and associated yields) have completed
	yield(get_tree(), "idle_frame")

	# Open or create new save file
	var save_file = File.new()
	save_file.open(SAVE_PATH, File.WRITE)

	# All the nodes to save are in a group called "persistent" (set in the editor, in the node tab of the inspector)
	var save_dict = {}

	# Collect and call the "save" method on every node in the group
	var backup_list = get_tree().get_nodes_in_group("Backup")
	for node in backup_list:
		# Save the requested node's information under a key representing their node path
		save_dict[node.name] = node.save_state()

		# if node.name == "Inventory":
			# print(save_dict[node.name])

	# Store the collected information into the file in JSON format
	save_file.store_line(to_json(save_dict))
	save_file.close()


func load_game():
	# Verify file exists and open if available
	var save_file = File.new()
	if not save_file.file_exists(SAVE_PATH):
		print("The save file does not exist.")
		return
	save_file.open(SAVE_PATH, File.READ)

	# Convert JSON back to dictionary
	Globals.save_data = parse_json(save_file.get_as_text())

	save_file.close()
