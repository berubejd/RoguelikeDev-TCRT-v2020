extends GridContainer

var slots = null


func _ready():
	# Wait for scene tree has been built before trying to collet children
	yield(get_tree(), "idle_frame")

	# Create array of slots in bag
	slots = self.get_children()


func get_free_slot():
	for slot in get_children():
		if !slot.item:
			return slot
