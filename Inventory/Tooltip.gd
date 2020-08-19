extends Popup

onready var label_name = $Panel/Label_name
onready var label_type = $Panel/Label_type
onready var label_desc = $Panel/Label_description
onready var label_damage = $Panel/Label_damage
onready var label_value = $Panel/Label_value
onready var label_bonus = $Panel/Label_bonus


func _ready():
# warning-ignore:return_value_discarded
	InventorySignals.connect("display_tooltip", self, "display_tooltip")
# warning-ignore:return_value_discarded
	InventorySignals.connect("hide_tooltip", self, "hide_tooltip")


func display_tooltip(item):
	visible = true
	label_name.text = item.id
	label_type.text = "- " + item.type_description + " -"
	label_desc.text = item.description
	
	
	if item.type_description == "Main-Hand" or item.type_description == "Spell":
		var damage = null

		if item.type_description == "Main-Hand":
			damage = item.damage

		if item.type_description == "Spell" and "damage" in item.action_params:
			damage = item.action_params["damage"]

		if damage and item.get("action_cooldown"):
			label_damage.visible = true
			label_damage.text = "Damage: " + str(damage) + " Speed: " + str(item.action_cooldown).pad_decimals(2)
	else:
		label_damage.visible = false
	
	
	if "value" in item:
		label_value.visible = true
		label_value.text = "Value: " + str(item.value) + " g"
	else:
		label_value.visible = false

	if "bonus" in item and not item.bonus == "":
		label_bonus.visible = true
		if item.bonus_amount > 0:
			label_bonus.set("custom_colors/font_color", Color.green)
			label_bonus.text = item.bonus.capitalize() + " +" + str(item.bonus_amount)
		elif item.bonus_amount < 0:
			label_bonus.set("custom_colors/font_color", Color.red)
			label_bonus.text = item.bonus.capitalize() + " " + str(item.bonus_amount)
	else:
		label_bonus.visible = false

func hide_tooltip():
	hide()
