extends TextureRect
class_name Item

### TODO
# Find solution for z ordering on drag?
# Stackables
# Money for recycled items?
# Animated textures?

const FIREBALL = preload("res://Effects/Fireball/FireballSpell.tscn")
const LIGHTNING = preload("res://Effects/Lightning/Lightning.tscn")

# Inventory Item Example
#	"wand": {
#		"icon": "res://Inventory/Sprites/Item_28.png",
#		"type": SlotType.SLOT_MAIN_HAND,
#		"stackable": false,
#		"stack_limit": 1,
#		"description": "This is a well-worn apprentice's wand."
#		"value": 10,
#		"click": [ "shoot", [5, 1] ],
#		"damage": 6,
#		"cooldown": 20.0,
#		"bonus": "spell_power",
#		"bonus_amount": 1
#	},

# Define item variables
var id: String
var icon: String
var type
var type_description: String
var stackable: bool
var stack_limit: int
var description: String
var value: int
var has_action: bool
var action: String
var action_params: Dictionary = {}
var action_cooldown: float
var bonus: String
var bonus_amount: int
var damage: int

# Define item manipulation variables
var held: = false
var offset: Vector2 = Vector2.ZERO
var orig_icon_pos: Vector2 = Vector2.ZERO

# Pointers to various inventory areas
onready var bag = get_tree().get_root().find_node("Bag", true, false)
onready var equipment = get_tree().get_root().find_node("Equipment", true, false)
onready var hotbar = get_tree().get_root().find_node("HotBar", true, false)
onready var recycle = get_tree().get_root().find_node("Recycle", true, false)

# Pointer to the Effects node for the world
onready var effects = get_tree().get_root().find_node("Effects", true, false)


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

	if temp_item["cooldown"]:
		action_cooldown = temp_item["cooldown"]

	if temp_item["bonus"]:
		bonus = temp_item["bonus"]
		bonus_amount = temp_item["bonus_amount"]

	if temp_item["damage"]:
		damage = temp_item["damage"]


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
						var slot_success = yield(slot.add_item(self), "completed")

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

		elif event.button_index == BUTTON_RIGHT:
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


func click() -> bool:
	var result = false

	if has_action:
		result = call(action, action_params)

	return result

func return_item():
	rect_global_position = orig_icon_pos


func action_eat(_params = null) -> bool:
	print("Nom nom!")
	queue_free()
	
	return true


func action_heal(params) -> bool:
	# Params = target, amount
	var target_pointer = get_tree().get_root().find_node(params["target"], true, false)
	if target_pointer.current_health:
		if target_pointer.current_health < target_pointer.max_health:
			target_pointer.current_health += params["amount"]
			queue_free()
			return true

	return false


func action_lightning(params) -> bool:
	# Params = distance, damage
	var lightning_instance = LIGHTNING.instance()
	lightning_instance.spell_damage = Globals.player.spell_power
	lightning_instance.initialize(Globals.player.find_node("Spell").get_global_position(), Globals.player.weapon.rotation_degrees, params["distance"])

	effects.add_child(lightning_instance)
	lightning_instance.shoot()

	return true


func action_fireball(params = null) -> bool:
	# Params = duration, damage
	var fireball_instance = FIREBALL.instance()
	fireball_instance.spell_damage = Globals.player.spell_power
	fireball_instance.initialize(Globals.player.find_node("Spell").get_global_position(), Globals.player.weapon.rotation_degrees, params["duration"])
	
	effects.add_child(fireball_instance)
	
	return true
