extends Control

# Constant for returned error values
const INV_ERROR = -1

# Preloads
const fading_text = preload("res://Effects/FadingText.tscn")
const item_preload = preload("res://Inventory/Item.tscn")

# Inventory Containers
onready var hotbar = $HotBar
onready var equipment = $Equipment
onready var bag = $Bag


func _ready():
	# warning-ignore:return_value_discarded
	InventorySignals.connect("pickup_item", self, "pickup_item")
	# warning-ignore:return_value_discarded
	InventorySignals.connect("init_inventory", self, "award_initial_inventory")
	# warning-ignore:return_value_discarded
	InventorySignals.connect("load_inventory", self, "load_inventory")


func _process(_delta):
	pass


func pickup_item(item_id: String, count: int = 1, autoequip: bool = true, save: bool = true, announce = true) -> bool:
	# Make this yieldable and avoid an item which is in progress and isn't completely slotted
	yield(get_tree(), "idle_frame")

	var type = Inventory.get_item(item_id)["type"]
	var slot = null

	# Only try to equip items if asked to, they aren't "typeless", and there isn't something already equipped
	if autoequip and type != Inventory.SlotType.SLOT_DEFAULT:
		for _slot in get_tree().get_nodes_in_group("InventorySlot"):
			slot = _slot
			if slot.slotType == type and (not slot.item or slot.item.stack_size < slot.item.stack_limit):
				var result = yield(put_away_item(item_id, count, slot, save, announce), "completed")
				# Item failed to be put in this selected slot
				if result == INV_ERROR:
					continue
				# Some of the items picked up were able to be put away but some are left
				else:
					count = result

					# Nothing else to put away so exit from loop
					if count == 0:
						break

	# Either this item was sent to the bag directly or can't fit in an equipment slot
	while count:
		# Find a slot that is empty or of the same type and not full yet
		slot = bag.get_free_slot(item_id)

		if slot:
			var result = yield(put_away_item(item_id, count, slot, save, announce), "completed")

			# Item put away
			if result == 0:
				break
			# Item failed to be put in this selected slot
			elif result == INV_ERROR:
				return false
			# Some of the items picked up were able to be put away but some are left
			else:
				count = result

		else:
			# Does this need to be updated for stacked items?
			var value = Inventory.get_item(item_id)["value"]
			Globals.player.gold += value

			var message = "Received " + str(value) + " gold for " + item_id + "!"
			UiSignals.emit_signal("display_message", message)

			SaveGame.emit_signal("save_game")

			return false

	return true


func put_away_item(item_id, count, slot, save, announce, override = false):
	yield(get_tree(), "idle_frame")

	var item_instance = item_preload.instance()

	# Initialize the new item
	if not item_instance.initialize(item_id, count):
		return INV_ERROR

	count = yield(slot.add_item(item_instance, override), "completed")

	if save:
		SaveGame.emit_signal("save_game")

	if announce:
		var message = "Found "+ item_id + "!"
		UiSignals.emit_signal("display_message", message)

	return count


func award_initial_inventory():
	# Create inventory items on a new game
	yield(pickup_item("slightly bent dagger", 1, true, false, false), "completed")
	yield(pickup_item("hooded novice cloak", 1, true, false, false), "completed")
	SaveGame.emit_signal("save_game")


func load_inventory():
	var data = Globals.save_data[name]

	if data:
		load_state(data)

	var _ret = Globals.save_data.erase(name)


func save_state():
	var data = {}

	for _slot in get_tree().get_nodes_in_group("InventorySlot"):
		if _slot.item:
			data[_slot.name] = {
				"id": _slot.item.id,
				"count": _slot.item.stack_size
				}

	return data


func load_state(data):
	for slot_name in data.keys():
		var _slot = find_node(slot_name)
		var new_item = data[slot_name]

		if _slot:
			if _slot.item:
				var old_item = _slot.clear_slot()
				old_item.queue_free()

			yield(put_away_item(new_item["id"], new_item["count"], _slot, false, false, true), "completed")
