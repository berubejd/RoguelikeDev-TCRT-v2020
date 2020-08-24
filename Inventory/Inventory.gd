extends Control

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


func pickup_item(item_id, autoequip = true, save = true, announce = true):
	# Make this yieldable and avoid an item which is in progress and isn't completely slotted
	yield(get_tree(), "idle_frame")

	var type = Inventory.get_item(item_id)["type"]
	var slot = null
	
	# Only try to equip items if asked to, they aren't "typeless", and there isn't something already equipped
	if autoequip and type != Inventory.SlotType.SLOT_DEFAULT:
		for _slot in get_tree().get_nodes_in_group("InventorySlot"):
			if _slot.slotType == type and not _slot.item:
				slot = _slot

	# This is a little messy checking again but the item will need a slot if it entered then failed the earlier test
	if not slot:
		slot = bag.get_free_slot()

	if slot:
		var item_instance = item_preload.instance()
		item_instance.initialize(item_id)
		slot.add_item(item_instance)

		if save:
			SaveGame.emit_signal("save_game")

		if announce:
			var message = "Found "+ item_id + "!"
			UiSignals.emit_signal("display_message", message)

		return true
	else:
		var value = Inventory.get_item(item_id)["value"]
		Globals.player.gold += value

		var message = "Received " + str(value) + " gold for " + item_id + "!"
		UiSignals.emit_signal("display_message", message)

		return false


func award_initial_inventory():
	# Create inventory items on a new game
	yield(pickup_item("slightly bent dagger", true, false, false), "completed")
	yield(pickup_item("hooded novice cloak", true, false, false), "completed")
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
			data[_slot.name] = _slot.item.id

	return data


func load_state(data):
	for slot_name in data.keys():
		var _slot = find_node(slot_name)
		if _slot:
			var item_instance = item_preload.instance()
			item_instance.initialize(data[slot_name])
			
			if _slot.item:
				var old_item = _slot.clear_slot()
				old_item.queue_free()

			yield(_slot.add_item(item_instance), "completed")
