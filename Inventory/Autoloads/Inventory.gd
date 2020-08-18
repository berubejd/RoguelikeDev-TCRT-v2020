extends Node

enum SlotType {
	SLOT_DEFAULT = 0,
	SLOT_HEAD,
	SLOT_BACK,
	SLOT_CHEST,
	SLOT_FEET,
	SLOT_RING,
	SLOT_MAIN_HAND,
	SLOT_SPELL,
	SLOT_POTION,
	SLOT_FOOD
}

enum KeyBind {
	None = -1,
	KEY_0 = 48,
	KEY_1,
	KEY_2,
	KEY_3,
	KEY_4,
	KEY_5,
	KEY_6,
	KEY_7,
	KEY_8,
	KEY_9,
}

const ITEMS = {
	"slightly bent dagger": {
		"icon": "res://Inventory/Sprites/dagger.png",
		"type": SlotType.SLOT_MAIN_HAND,
		"stackable": false,
		"stack_limit": 1,
		"description": "It's sharp enough... I guess.",
		"value": 10,
		"click": null,
		"damage": 2,
		"cooldown": .75,
		"bonus": "power",
		"bonus_amount": 1
	},
	"staff of striking": {
		"icon": "res://Inventory/Sprites/staff.png",
		"type": SlotType.SLOT_MAIN_HAND,
		"stackable": false,
		"stack_limit": 1,
		"description": "Well, it's a fancy stick.",
		"value": 10,
		"click": null,
		"damage": 4,
		"cooldown": 1.2,
		"bonus": "spell_power",
		"bonus_amount": 1
	},
	"one-half ring": {
		"icon": "res://Inventory/Sprites/ring.png",
		"type": SlotType.SLOT_RING,
		"stackable": false,
		"stack_limit": 1,
		"description": "A rather plain looking ring.",
		"value": 10,
		"click": null,
		"damage": null,
		"cooldown": null,
		"bonus": "health",
		"bonus_amount": 5
	},
	"meat": {
		"icon": "res://Inventory/Sprites/meat.png",
		"type": SlotType.SLOT_FOOD,
		"stackable": true,
		"stack_limit": 5,
		"description": "Meat of unknown origin.",
		"value": 10,
		"click": [
			"action_eat", {}
			],
		"damage": null,
		"cooldown": 120.0,
		"bonus": null,
		"bonus_amount": null
	},
	"potion of health": {
		"icon": "res://Inventory/Sprites/potion_health.png",
		"type": SlotType.SLOT_POTION,
		"stackable": true,
		"stack_limit": 5,
		"description": "The liquid in this bottle is thick and glows slightly.",
		"value": 10,
		"click": [
			"action_heal", {
				"target": "Player",
				"amount": 4
				}
			],
		"damage": null,
		"cooldown": 20.0,
		"bonus": null,
		"bonus_amount": null
	},
	"call lightning": {
		"icon": "res://Inventory/Sprites/lightning.png",
		"type": SlotType.SLOT_SPELL,
		"stackable": false,
		"stack_limit": 1,
		"description": "Sort of like static electricity.",
		"value": 10,
		"click": [
			"action_lightning", {
				"distance": 50,
				"damage": 10
				}
			],
		"damage": null,
		"cooldown": 5.0,
		"bonus": null,
		"bonus_amount": null
	},
	"fireball": {
		"icon": "res://Inventory/Sprites/fire.png",
		"type": SlotType.SLOT_SPELL,
		"stackable": false,
		"stack_limit": 1,
		"description": "Who doesn't like setting things on fire?",
		"value": 10,
		"click": [
			"action_fireball", {
				"duration": 0.5,
				"damage": 6
				}
			],
		"damage": null,
		"cooldown": 4.0,
		"bonus": null,
		"bonus_amount": null
	},
	"ring": {
		"icon": "res://Inventory/Sprites/gem_ring.png",
		"type": SlotType.SLOT_RING,
		"stackable": false,
		"stack_limit": 1,
		"description": "Twice the ring as other rings.",
		"value": 10,
		"click": null,
		"damage": null,
		"cooldown": null,
		"bonus": "health",
		"bonus_amount": 10
	},
	"gem topped scepter": {
		"icon": "res://Inventory/Sprites/gem_topped_scepter.png",
		"type": SlotType.SLOT_MAIN_HAND,
		"stackable": false,
		"stack_limit": 1,
		"description": "The gem atop this scepter glows faintly from within.",
		"value": 10,
		"click": null,
		"damage": 4,
		"cooldown": 1.2,
		"bonus": "spell_power",
		"bonus_amount": 2
	},
	"hooded novice cloak": {
		"icon": "res://Inventory/Sprites/hooded_novice_cloak.png",
		"type": SlotType.SLOT_BACK,
		"stackable": false,
		"stack_limit": 1,
		"description": "Years of abuse can be seen.. and smelled... in this cloak",
		"value": 10,
		"click": null,
		"damage": null,
		"cooldown": null,
		"bonus": null,
		"bonus_amount": null
	},
	"padded vest": {
		"icon": "res://Inventory/Sprites/padded_vest.png",
		"type": SlotType.SLOT_CHEST,
		"stackable": false,
		"stack_limit": 1,
		"description": "This vest is better than nothing, at least.",
		"value": 10,
		"click": null,
		"damage": null,
		"cooldown": null,
		"bonus": "defense",
		"bonus_amount": 1
	},
	"short sword": {
		"icon": "res://Inventory/Sprites/short_sword.png",
		"type": SlotType.SLOT_MAIN_HAND,
		"stackable": false,
		"stack_limit": 1,
		"description": "A light and fast sword.",
		"value": 10,
		"click": null,
		"damage": 3,
		"cooldown": 1.0,
		"bonus": "power",
		"bonus_amount": 1
	},
	"leather skullcap": {
		"icon": "res://Inventory/Sprites/skullcap.png",
		"type": SlotType.SLOT_HEAD,
		"stackable": false,
		"stack_limit": 1,
		"description": "A stylish leather bean cover.",
		"value": 10,
		"click": null,
		"damage": null,
		"cooldown": null,
		"bonus": "defense",
		"bonus_amount": 1
	},
	"boar spear": {
		"icon": "res://Inventory/Sprites/spear.png",
		"type": SlotType.SLOT_MAIN_HAND,
		"stackable": false,
		"stack_limit": 1,
		"description": "A razor-sharp blade adorns this stout staff.",
		"value": 10,
		"click": null,
		"damage": 5,
		"cooldown": 1.1,
		"bonus": "defense",
		"bonus_amount": 1
	},
	"worn boots": {
		"icon": "res://Inventory/Sprites/worn_boots.png",
		"type": SlotType.SLOT_FEET,
		"stackable": false,
		"stack_limit": 1,
		"description": "A well-worn, but well cares for, pair of leather boots.",
		"value": 10,
		"click": null,
		"damage": null,
		"cooldown": null,
		"bonus": "speed",
		"bonus_amount": 5
	},
}

func get_item(item_id):
	if item_id in ITEMS:
		return ITEMS[item_id]
	else:
		return null


func get_type(slot_type):
	var description = null

	match slot_type:
		0: description = "Stuff"
		1: description = "Head"
		2: description = "Back"
		3: description = "Chest"
		4: description = "Feet"
		5: description = "Ring"
		6: description = "Main-Hand"
		7: description = "Spell"
		8: description = "Potion"
		9: description = "Food"

	return description
