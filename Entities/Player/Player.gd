extends KinematicBody2D

enum {
	DEATH,
	NORMAL,
	HIT,
	ATTACK
}

export var ACCELERATION = 10
export var FRICTION = 3
export var KNOCKBACK = 60
export var MAX_SPEED = 60

onready var animation_player = $AnimationPlayer
onready var camera = $Camera2D
onready var hit_timer = $HitTimer
onready var sprite = $Sprite
onready var state = NORMAL
onready var stun_timer = $StunTimer
onready var weapon = $WeaponPivot
onready var weapon_area = $WeaponPivot/Weapon/CollisionShape2D
onready var weapon_timer = $WeaponPivot/Weapon/AttackTimer
onready var weapon_animation = $WeaponPivot/Weapon/AnimationPlayer
onready var pointer = $WeaponPivot/Weapon/WeaponSprite

var velocity = Vector2.ZERO

var attacker_direction: Vector2
var defense: int = 2
var max_health: int = 30 setget update_max_health
var current_health: int = max_health setget update_health
var power: int = 5


func _ready():
	update_health(current_health)


func _physics_process(_delta):
	match state:
		DEATH:
			# audiostream.stream = load("Some death resource")
			# audiostream.play()

			if animation_player.has_animation("Death"):
				animation_player.play("Death")
				# A yield in _process or _physics_process doesn't actually do anything
				# yield(animation_player, "animation_finished")
				# Disable loop to allow animation to complete before map_exited() call
				if not animation_player.is_connected("animation_finished", self, "transition"):
					var _ret = animation_player.connect("animation_finished", self, "transition")
			else:
				transition()



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

			if Input.is_action_just_pressed("clicked"):
				if weapon_timer.is_stopped():
					weapon_timer.start(.2)
					weapon_animation.play("Attack")

			if Input.is_action_just_released("clicked"):
				weapon_area.disabled = true

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
				velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION)
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


func update_health(value):
	if hit_timer.is_stopped() and value < current_health:
		hit_timer.start(1)

		current_health = value
	
		damage_taken(attacker_direction)
		
		if not state == DEATH:
			stun(.5)
	else:
		current_health = value


	current_health = int(clamp(current_health, 0, max_health)) # Casting to int to alleviate 'narrowing conversion' warning
	get_tree().call_group("player_update", "update_health", current_health, max_health)


func update_max_health(value):
	max_health = value
	get_tree().call_group("player_update", "update_health", current_health, max_health)


func _on_Weapon_body_entered(body):
	body.attacker_direction = (body.global_position - position).normalized()
	body.current_health -= power


func stun(duration: = 0.3):
	stun_timer.start(duration)
	state = HIT


func transition(_anim="None"):
	if state == DEATH:
		get_tree().get_root().find_node("Main", true, false).map_exited()
