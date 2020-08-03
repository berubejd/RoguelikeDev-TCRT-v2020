extends TextureRect
class_name Item

### TODO
# Find solution for z ordering on drag?
# Stackables
# Money for recycled items?
# Animated textures?

# Inventory Item Example
#	"wand": {
#		"icon": "res://Inventory/Sprites/Item_28.png",
#		"type": SlotType.SLOT_MAIN_HAND,
#		"stackable": false,
#		"stack_limit": 1,
#		"description": "This is a well-worn apprentice's wand."
#		"value": 10,
#		"click": [ "shoot", [5, 1] ]
#	},

# Define item variables
var id: String = ""
var icon: String = ""
var type = null
var type_description: String = ""
var stackable: bool = false
var stack_limit: int = 1
var description: String = ""
var value: int = 0
var has_action: bool = false
var action: String = ""
var action_params: Array = []

# Define item manipulation variables
var held: = false
var offset: Vector2 = Vector2.ZERO
var orig_icon_pos: Vector2 = Vector2.ZERO

# Pointers to various inventory areas
onready var bag = get_tree().get_root().find_node("Bag", true, false)
onready var equipment = get_tree().get_root().find_node("Equipment", true, false)
onready var hotbar = get_tree().get_root().find_node("HotBar", true, false)
onready var recycle = get_tree().get_root().find_node("Recycle", true, false)


func initialize(item_id):
	var temp_item = Inventory.get_item(item_id)

	id = item_id
	icon = temp_item["icon"]
	type = temp_item["type"]
	stackable = temp_item["stackable"]
	stack_limit = temp_item["stack_limit"]
	description = temp_item["description"]
	value = temp_item["value"]
	type_description = Inventory.get_type(type)

	texture = load(icon)

	if temp_item["click"]:
		has_action = true
		action = temp_item["click"][0]
		action_params = temp_item["click"][1]


func _process(_delta):
	if held:
		var cursor_pos = get_global_mouse_position()
		rect_global_position = cursor_pos + offset

	if owner and owner.item == null:
		print("Owning slot has lost it's item reference!")


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:

				# Block press from interacting with slot
				accept_event()

				# Setup drag variables
				held = true
				orig_icon_pos = rect_global_position
				offset = rect_global_position - get_global_mouse_position()
				# Hide the tooltip if the item is about to be dragged
				InventorySignals.emit_signal("hide_tooltip")

			else:
				held = false
				
				# Iterate over slots to find if any contain the mouse right now
				for slot in get_tree().get_nodes_in_group("InventorySlot"):
					if slot.get_global_rect().has_point(get_global_mouse_position()):
						var slot_success = slot.add_item(self)

						if slot_success:
							# Found new slot and moved item so exit input event before we return the item to the original slot
							return

				# Check if dropped on recycle icon
				if recycle.get_global_rect().has_point(get_global_mouse_position()):
					print("Poof!")
					owner.clear_slot()
					clear_item()
					queue_free()

				return_item()

		elif  event.button_index == BUTTON_RIGHT:
			if owner.slotType != Inventory.SlotType.SLOT_DEFAULT:
				var slot = bag.get_free_slot()
				if slot:
					slot.add_item(self)
			elif not type == Inventory.SlotType.SLOT_DEFAULT:
				for slot in get_tree().get_nodes_in_group("InventorySlot"):
					if slot.slotType == type:
						slot.add_item(self)

			InventorySignals.emit_signal("hide_tooltip")


func clear_item():
	var old_owner = null
	if owner:
		old_owner = owner
	owner = null
	return old_owner

func click():
	if has_action:
		call(action, action_params)


func return_item():
	rect_global_position = orig_icon_pos


func action_eat(_params = null):
	print("Nom nom!")
	queue_free()

func action_heal(params):
	var target = params[0]
	var heal_amount = params[1]
	
	var target_pointer = get_tree().get_root().find_node(target, true, false)
	if target_pointer.current_health:
		if target_pointer.current_health < target_pointer.max_health:
			target_pointer.current_health += heal_amount
			queue_free()
