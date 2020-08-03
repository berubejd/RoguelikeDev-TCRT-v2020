extends Control

# Preloads
var item_preload = preload("res://Inventory/Item.tscn")

# Inventory Containers
onready var hotbar = $HotBar
onready var equipment = $Equipment
onready var bag = $Bag


func _ready():
# warning-ignore:return_value_discarded
	InventorySignals.connect("pickup_item", self, "pickup_item")
	
	pickup_item("slightly bent dagger")
	pickup_item("wand of striking")
	pickup_item("one-half ring")
	pickup_item("meat", false)


func _process(_delta):
	pass


func pickup_item(item_id, autoequip = true):
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

		return true
	else:
		return false
