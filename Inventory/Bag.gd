extends GridContainer

var slots = null


func _ready():
	# Wait for scene tree has been built before trying to collet children
	yield(get_tree(), "idle_frame")

	# Create array of slots in bag
	slots = self.get_children()


func get_free_slot(item_id):
	var stack_limit = Inventory.get_item(item_id)["stack_limit"]

	# Find a slot with the same item and available stack limit first
	for slot in slots:
		if slot.item and slot.item.id == item_id and slot.item.stack_size < stack_limit:
			return slot

	# No existing slots so find an empty slot
	for slot in slots:
		if !slot.item:
			return slot
