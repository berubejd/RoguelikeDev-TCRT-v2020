extends KinematicBody2D
class_name Player

const floating_text = preload("res://Effects/FloatingText.tscn")

enum {
	DEATH,
	TRANSITION,
	NORMAL,
	HIT,
	ATTACK
}

export (int) var ACCELERATION = 10
export (int) var FRICTION = 3
export (int) var KNOCKBACK = 60
export (int) var level_up_base = 200
export (int) var level_up_factor = 175
export (float) var unarmed_cooldown = 0.5

onready var animation_player = $AnimationPlayer
onready var camera = $Camera2D
onready var hit_timer = $HitTimer
onready var pointer = $WeaponPivot/Weapon/WeaponSprite
onready var spell = $WeaponPivot/Spell
onready var sprite = $Sprite
onready var state = NORMAL
onready var stun_timer = $StunTimer
onready var transition_player = $TransitionLayer/AnimationPlayer
onready var weapon = $WeaponPivot
onready var weapon_area = $WeaponPivot/Weapon/CollisionShape2D
onready var weapon_sprite = $WeaponPivot/Weapon/WeaponSprite
onready var weapon_timer = $WeaponPivot/Weapon/AttackTimer
onready var weapon_animation = $WeaponPivot/Weapon/AnimationPlayer

var velocity = Vector2.ZERO

var attacker_direction: Vector2

# Stats
var power setget set_power, get_power
var power_base: int = 2
var power_bonus: int = 0
var spell_power setget set_spell_power, get_spell_power
var spell_power_base: int = 0
var spell_power_bonus: int = 0
var defense setget set_defense, get_defense
var defense_base: int = 1
var defense_bonus: int = 0
var max_health setget set_max_health, get_max_health
var max_health_base: int = 20
var max_health_bonus: int = 0
var current_health: int = get_max_health() setget update_health
var max_speed setget set_max_speed, get_max_speed
var max_speed_base: int = 60
var max_speed_bonus: int = 0
var level: int = 1
var level_points: int = 0
var xp: int = 0 setget add_xp
var gold: int = 0 setget update_gold

# Equipped combat items
var equipped_weapon = null
var equipped_spell = null

# Only way to actually avoid UI clicks from activating inside the game...
var play_area = Rect2(1, 1, 277, 156)

# warning-ignore:unused_signal
signal spell_result(result)


func _ready():
	if Globals.save_data:
		load_state(Globals.save_data[name])
		var _ret = Globals.save_data.erase(name)
	else:
		InventorySignals.emit_signal("init_inventory")

	update_health(current_health)
	update_gold(gold)

	# Signal UI to update
	UiSignals.emit_signal("update_health", current_health, get_max_health())
	UiSignals.emit_signal("update_experience", level, xp, experience_to_next_level())

	# warning-ignore:return_value_discarded
	connect("spell_result", self, "spell_result")

	# warning-ignore:return_value_discarded
	InventorySignals.connect("item_equipped", self, "equip_item")
	# warning-ignore:return_value_discarded
	InventorySignals.connect("item_removed", self, "remove_item")


func _physics_process(_delta):
	match state:
		DEATH:
			# Remove any remaining movement when dead
			velocity = Vector2.ZERO
			
			# audiostream.stream = load("Some death resource")
			# audiostream.play()

			if animation_player.has_animation("Death"):
				animation_player.play("Death")
				# A yield in _process or _physics_process doesn't actually do anything
				# yield(animation_player, "animation_finished")
				if not animation_player.is_connected("animation_finished", self, "transition"):
					var _ret = animation_player.connect("animation_finished", self, "transition")
			else:
				transition()

		TRANSITION:
			pass

		NORMAL:
			var input_vector = Vector2.ZERO

			# Rotate weapon pivot to direction of mouse
			weapon.look_at(get_global_mouse_position())

			# Zoom for testing
			if Input.is_action_just_released("wheel_down"):
				camera.zoom.x += 0.25
				camera.zoom.y += 0.25

			if Input.is_action_just_released('wheel_up') and camera.zoom.x > 1 and camera.zoom.y > 1:
				camera.zoom.x -= 0.25
				camera.zoom.y -= 0.25

			if Input.is_action_just_pressed("clicked") and play_area.has_point(get_viewport().get_mouse_position()):
				if equipped_weapon:
					if equipped_weapon.owner.activate_item_cooldown():
						weapon_animation.play("Attack")
				else:
					if weapon_timer.is_stopped():
						weapon_timer.start(unarmed_cooldown)
						weapon_animation.play("Attack")

			if Input.is_action_just_released("clicked"):
				weapon_area.disabled = true

			if Input.is_action_just_pressed("r_clicked") and play_area.has_point(get_viewport().get_mouse_position()):
				if equipped_spell and equipped_spell.has_action and equipped_spell.owner.cooldown.is_stopped():
					weapon.visible = false
					var _ret = yield(equipped_spell.owner.activate_item(), "completed")
					weapon.visible = true

			# Gather key input into new input_vector
			input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
			input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
			input_vector = input_vector.normalized()

			if input_vector != Vector2.ZERO:
				# Face sprite in direction of movement if were moving left or right
				if ! input_vector.x == 0:
					if input_vector.x < 0:
						sprite.flip_h = true
					else:
						sprite.flip_h = false

				# Play walk animation as we're moving
				sprite.play("Walk")
				velocity = velocity.move_toward(input_vector * (max_speed_base + max_health_bonus), ACCELERATION)
			else:
				# No movement so go back to idle
				sprite.play("Idle")
				velocity = velocity.move_toward(Vector2.ZERO, FRICTION)

		HIT:
			if stun_timer.is_stopped():
				state = NORMAL

		ATTACK:
			pass

	velocity = move_and_slide(velocity)


func add_xp(value):
	xp += value

	# Signal UI to display experience gain - Too spammy?
	# var message = "You have gained " + str(value) + " experience"
	# UiSignals.emit_signal("display_message", message)

	if xp >= experience_to_next_level():
		xp -= experience_to_next_level()
		level += 1
		level_points += 1

		# Signal UI to display level up message
		UiSignals.emit_signal("display_message", "Congratulations!  You have leveled up!")

		# Signal SaveGame that there is a player change that needs to trigger a save
		SaveGame.emit_signal("save_game")

	# Signal UI to update experience UI
	UiSignals.emit_signal("update_experience", level, xp, experience_to_next_level())


func experience_to_next_level():
	return level_up_base + (level * level_up_factor)


func damage_taken(direction):
	if current_health <= 0:
		state = DEATH
	else:
		hit_timer.start(1)
		
		velocity = direction * KNOCKBACK
		if animation_player.has_animation("Hit"):
			animation_player.play("Hit")
		# audiostream.stream = load("res://Sound/Hurt.wav")
		# audiostream.play()


func spell_result(result):
	if result.hit:
		if result.current_health == null or result.current_health <= 0:
			add_xp(result.xp_value)


func update_health(value):
	# No reason to update health since we're dead already
	if state == DEATH or state == TRANSITION:
		return

	# Set and display floating text
	var health_change = display_floating_health(value)

	# Handle health change
	if hit_timer.is_stopped() and value < current_health:
		hit_timer.start(1)

		current_health += health_change

		damage_taken(attacker_direction)

		if not state == DEATH:
			stun(.5)
	else:
		current_health = value

	current_health = int(clamp(current_health, 0, get_max_health())) # Casting to int to alleviate 'narrowing conversion' warning
	UiSignals.emit_signal("update_health", current_health, get_max_health())


func display_floating_health(value) -> int:
	var border_color = Color.black
	var health_change = value - current_health

	# Verify effect of defense
	if health_change < 0:
		health_change = min(health_change + get_defense(), -1)

	# If change is 0 it is probably the setget firing during ready
	if not health_change == 0:
		# Determine border color
		if health_change < 0:
			border_color = Color.red
		else:
			border_color = Color.darkgreen

		var floating_text_instance = floating_text.instance()
		floating_text_instance.initialize(str(health_change), border_color)
		add_child(floating_text_instance)

	return health_change


func get_max_health():
	return max_health_base + max_health_bonus


func set_max_health(value):
	# Add the new health gained to current_health, as well
	current_health += value - get_max_health()
	max_health_base = value - max_health_bonus
	UiSignals.emit_signal("update_health", current_health, get_max_health())


func get_power():
	var total_base: int

	if equipped_weapon and equipped_weapon.damage:
		total_base = power_base + equipped_weapon.damage
	else:
		total_base = power_base

	return total_base + power_bonus


func set_power(value):
	power_base = value - power_bonus if not equipped_weapon else value - equipped_weapon.damage - power_bonus


func get_spell_power():
	var total_base: int

	if equipped_spell and equipped_spell.action_params:
		total_base = spell_power_base + equipped_spell.action_params["damage"]
	else:
		total_base = spell_power_base
		
	return total_base + spell_power_bonus


func set_spell_power(value):

	if equipped_spell:
		value = value - equipped_spell.action_params["damage"] - spell_power_bonus
	else:
		value = value - spell_power_bonus

	spell_power_base = value


func get_defense():
	return defense_base + defense_bonus


func set_defense(value):
	defense_base = value - defense_bonus


func get_max_speed():
	return max_speed_base + max_speed_bonus


func set_max_speed(value):
	max_speed_base = value - max_speed_bonus


func update_gold(value):
	gold = value

	# Signal UI for gold update
	UiSignals.emit_signal("update_gold", gold)


func has_bonus(stat: String) -> int:
	return get(stat + "_bonus")


func _on_Weapon_body_entered(body):
	body.attacker_direction = (body.global_position - position).normalized()
	body.current_health -= get_power()

	# If target is out of health then award xp to player
	if body.current_health <= 0:
		add_xp(body.xp_value)


func stun(duration: = 0.3):
	stun_timer.start(duration)
	state = HIT


func transition(_anim="None"):
	if state == DEATH:
		# Prevent death animation from replaying
		state = TRANSITION

		# Set end_game information
		Globals.end_game["level"] = level
		Globals.end_game["total_xp"] = level_up_base + ((level - 1) * level_up_factor) + xp
		Globals.end_game["gold"] = gold

		# Fade out and load game over screen
		transition_player.play("Fade")
		yield(transition_player, "animation_finished")
		# warning-ignore:return_value_discarded
		get_tree().change_scene("res://UI/GameOver.tscn")


func equip_item(item):
	if not item:
		# This should never happen
		return

	if item.type == Inventory.SlotType.SLOT_MAIN_HAND:
		weapon_sprite.texture = load(item.icon)
		weapon_sprite.visible = true
		equipped_weapon = item

	if item.type == Inventory.SlotType.SLOT_SPELL:
		equipped_spell = item

	if item.bonus:
		match item.bonus:
			"power":
				power_bonus += item.bonus_amount
			"spell_power":
				spell_power_bonus += item.bonus_amount
			"defense":
				defense_bonus += item.bonus_amount
			"health":
				# Signal UI after health increase to update health bar
				max_health_bonus += item.bonus_amount
				UiSignals.emit_signal("update_health", current_health, get_max_health())
			"speed":
				max_speed_bonus += item.bonus_amount


func remove_item(item):
	if not item:
		# This should never happen
		return

	if item.type == Inventory.SlotType.SLOT_MAIN_HAND:
		weapon_sprite.visible = false
		equipped_weapon = null

	if item.type == Inventory.SlotType.SLOT_SPELL:
		equipped_spell = null

	if item.bonus:
		match item.bonus:
			"power":
				# warning-ignore:narrowing_conversion
				power_bonus = max(0, power_bonus - item.bonus_amount)
			"spell_power":
				# warning-ignore:narrowing_conversion
				spell_power_bonus = max(0, spell_power_bonus - item.bonus_amount)
			"defense":
				# warning-ignore:narrowing_conversion
				defense_bonus = max(0, defense_bonus - item.bonus_amount)
			"health":
				# warning-ignore:narrowing_conversion
				max_health_bonus = max(0, max_health_bonus - item.bonus_amount)
			"speed":
				# warning-ignore:narrowing_conversion
				max_speed_bonus = max(0, max_speed_bonus - item.bonus_amount)


func save_state():
	var data = {
		"position": {
			"x": position.x,
			"y": position.y
		},
		"current_health": current_health,
		"defense_base": defense_base,
		"level": level,
		"level_points": level_points,
		"max_health_base": max_health_base,
		"max_speed_base": max_speed_base,
		"power_base": power_base,
		"spell_power_base": spell_power_base,
		"xp": xp,
		"gold": gold
	}

	return data


func load_state(data):
	for attribute in data:
		if attribute == "position":
			position = Vector2(data["position"]["x"], data["position"]["y"])
		elif attribute == "current_health":
			# Need to avoid the setter on current_health so set directly and call player_update
			current_health = data[attribute]
			UiSignals.emit_signal("update_health", current_health, get_max_health())
		else:
			set(attribute, data[attribute])

	# Trigger the inventory load now so that any signals will be called on the player
	InventorySignals.emit_signal("load_inventory")
