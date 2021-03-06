extends Panel
class_name Slot

const INV_ERROR = -1

export(Inventory.SlotType) var slotType = Inventory.SlotType.SLOT_DEFAULT;
export(Inventory.KeyBind) var keyBind = null
export(Color) var clickColor = Color(1, 1, 1, 1)

var item = null
var item_cooldown = 0
var orig_color = Color(0, 0, 0, 0)

onready var bag = get_tree().get_root().find_node("Bag", true, false)
onready var keylabel = $KeyLabel
onready var typelabel = $TypeLabel
onready var stylebox = get_stylebox("panel")
onready var cooldown = $CooldownTimer
onready var progress = $ZIndexController/CooldownDisplay


func _ready():
	# warning-ignore:return_value_discarded
	connect("mouse_entered", self, "mouse_enter_slot")
	# warning-ignore:return_value_discarded
	connect("mouse_exited", self, "mouse_exit_slot")
	
	# Setup labels
	typelabel.text = Inventory.get_type(slotType)
	typelabel.visible = false
	
	if keyBind:
		keylabel.text = Inventory.KeyBind.keys()[keyBind - 48 + 1].split("_", true)[1]
	else:
		keylabel.visible = false

	# Save original border color
	orig_color = stylebox.border_color

	# Handle "disabled" slots
	if slotType == Inventory.SlotType.SLOT_DISABLED:
		self_modulate = Color(1.0, 1.0, 1.0, 0.6)
		set_process_unhandled_key_input(false)


func _process(_delta):
	if item:
		typelabel.visible = false
	else:
		if slotType != Inventory.SlotType.SLOT_DEFAULT:
			typelabel.visible = true

	# Manage display of cooldown
	if not cooldown.is_stopped():
		progress.value = (cooldown.time_left / item_cooldown) * 100


func _gui_input(event : InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				pass
			else:
				pass


func _unhandled_key_input(event):
	if event.scancode == keyBind:
		if event.pressed and not event.is_echo():
				var _ret = activate_item(true)
		else:
			stylebox.border_color = orig_color


func activate_item(from_key = false) -> bool:
	var result: bool = false

	# Highlight border on action
	stylebox.border_color = clickColor

	# Call attached action if not in cooldown
	if item and item.has_action and cooldown.is_stopped():
		# Call item action
		if item.click():
			var _ret = activate_item_cooldown()

		result = true

	# Handle border color if this didn't come in via a key bind
	if not from_key and stylebox.border_color == clickColor:
		yield(get_tree().create_timer(0.2), "timeout")
		stylebox.border_color = orig_color

	return result


func activate_item_cooldown() -> bool:
	# If the cooldown timer is running then return false
	if not cooldown.is_stopped():
		return false

	# If this item has a cooldown, trigger it
	if item.action_cooldown > 0:
		item_cooldown = item.action_cooldown
		cooldown.start(item.action_cooldown)

	return true


func add_item(new_item, override = false) -> int:
	# Make this yieldable
	yield(get_tree(), "idle_frame")

	# Return if this is the wrong slot type for the item
	if not override and not slotType == Inventory.SlotType.SLOT_DEFAULT and not slotType == new_item.type:
		return INV_ERROR

	# Return immediately if the item to be added is already in this slot
	if item == new_item:
		return INV_ERROR

	if item:
		# If items have the same id but are not the same item then attempt to combine them
		if item.id == new_item.id and item.stackable:
			var original_stack_size = item.stack_size
			item.stack_size = min(item.stack_size + new_item.stack_size, item.stack_limit)
			new_item.stack_size -= item.stack_size - original_stack_size

			if not new_item.owner or new_item.stack_size == 0:
				new_item.queue_free()

			return 0 if not new_item.get("stack_size") else new_item.stack_size

		# If slot is occupied by a different item move current item to a different free slot first
		else:
			return swap_slots(item, new_item)

	# Clear out the older owner information if this was previously slotted
	if new_item.owner:
		new_item.owner.clear_slot()

	item = new_item
	add_child(item)
	item.set_owner(self)

	# Reset position in case item was dragged to a new slot
	item.reset_position()

	if not slotType == Inventory.SlotType.SLOT_DEFAULT:
		InventorySignals.emit_signal("item_equipped", self.item)

	if new_item.stack_size > new_item.stack_limit:
		var trim = new_item.stack_size - new_item.stack_limit
		new_item.stack_size = new_item.stack_limit
		return trim
	else:
		return 0


func clear_slot():
	var old_item = null
	if item:
		old_item = item
	item = null

	for child in get_children():
		if child is Item:
			remove_child(child)

	if not slotType == Inventory.SlotType.SLOT_DEFAULT:
		InventorySignals.emit_signal("item_removed", old_item)

	return old_item


func mouse_enter_slot():
	if self.item:
		InventorySignals.emit_signal("display_tooltip", self.item)


func mouse_exit_slot():
	InventorySignals.emit_signal("hide_tooltip")


func swap_slots(current_item, new_item):
	var current_item_handle = current_item
	var current_item_destination = null

	if new_item.owner.slotType == Inventory.SlotType.SLOT_DEFAULT:
		# Swap slots if the new_item is coming from the bag
		current_item_destination = new_item.owner
	else:
		# if new_item is somewhere other than the bag then find a new slot in the bag if available
		current_item_destination = bag.get_free_slot(current_item.id)

		if not current_item_destination:
			return INV_ERROR

	# Clean up slot and item
	current_item_handle.clear_item()
	clear_slot()

	# Add new item to this slot
	var new_item_remaining_count = yield(add_item(new_item), "completed")

	# Add original item to the newly opened slot
	var current_item_remaining_count = yield(current_item_destination.add_item(current_item_handle), "completed")

	if new_item_remaining_count != 0 or current_item_remaining_count != 0:
		print("WTF?")

	return 0
