extends KinematicBody2D

enum {
	HIDDEN,
	IDLE,
	WALK,
	HIT,
	DEATH,
	ATTACK
}

export var ACCELERATION = 5
export var FRICTION = 3
export var MAX_HEALTH = 100
export var MAX_SPEED = 20
export (int) var WAIT_SECS = 5
export (int) var WALK_SECS = 4

onready var animation = $Sprite
onready var state = HIDDEN if animation.animation == "Hidden" else IDLE
onready var timer = $Timer
onready var weapon = $Weapon/WeaponPivot

var current_health = MAX_HEALTH
var motion = Vector2.ZERO
var walking_direction


func _ready():
	randomize()
	if not state == HIDDEN:
		timer.start()


func _physics_process(_delta):
	match state:
		HIDDEN:
			pass

		IDLE:
			motion = motion.move_toward(Vector2.ZERO, FRICTION)

		WALK:
			if is_on_wall():
				# Generate a new random direction
				walking_direction = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)).normalized()
				timer.start(1)

			motion = motion.move_toward(walking_direction * MAX_SPEED, ACCELERATION)

		HIT:
			pass

		DEATH:
			pass

		ATTACK:
			pass

	animate()	
	motion = move_and_slide(motion)


#func _on_Aggro_body_entered(_body):
#	if state == HIDDEN:
#		if animation.frames.has_animation("Emerge"):
#			animation.play("Emerge")
#			connect_animation_signal()
#		state = IDLE
#		timer.start()


func _on_Timer_timeout():
	var timeout
	
	match state:
		IDLE:
			walking_direction = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)).normalized()
			state = WALK
			timeout = randi() % WALK_SECS

		WALK:
			state = IDLE
			timeout = randi() % WAIT_SECS

		_:
			timeout = randi()%6

	timer.start(timeout + 1)


#func _on_HitBox_body_entered(_body):
#	get_tree().call_group("Gamestate", "hurt")


func animate():
	# Let 'Hit' or 'Emerge' animations complete
	var current_animation = animation.get_animation()
	if current_animation == 'Hit' or current_animation == 'Emerge':
		return

	if motion != Vector2.ZERO:
		# Face sprite in direction of movement if were moving left or right
		if ! motion.x == 0:
			if motion.x < 0:
				animation.flip_h = true
			else:
				animation.flip_h = false

		# Play walk animation as we're moving
		animation.play("Walk")
	else:
		# No movement so go back to idle
		if state == HIDDEN:
			animation.play("Hidden")
		else:
			animation.play("Idle")


func connect_animation_signal():
	if not animation.is_connected("animation_finished", self, "finished_animation"):
		var _ret = animation.connect("animation_finished", self, "finished_animation")


func finished_animation():
	if animation.is_connected("animation_finished", self, "finished_animation"):
		animation.disconnect("animation_finished", self, "finished_animation")
	animation.play("Idle")


func hit(_damage=1):
	# Uncomment this check once things are sorted
	# life -= damage
	if current_health <= 0:
		# Better done with an AnimationPlayer?
		# audiostream.stream = load("Some death resource")
		# audiostream.play()
		if animation.frames.has_animation("Death"):
			animation.play("Death")
		# Need to track completion of animation then queue_free() somewhere
		pass
	else:
		# Probably a knockback here instead of a jump of some sort
		# motion.y = -JUMP * hurt_modifier
		if animation.frames.has_animation("Hit"):
			animation.play("Hit")
		# audiostream.stream = load("res://Sound/Hurt.wav")
		# audiostream.play()
	
	connect_animation_signal()


#	var input_vector = Vector2.ZERO
#
#	# Rotate weapon pivot to direction of mouse
#	# weapon.look_at(get_global_mouse_position())
#
#	# Gather key input into new input_vector
#	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
#	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
#	input_vector = input_vector.normalized()
#
#	if input_vector != Vector2.ZERO:
#		# Face sprite in direction of movement if were moving left or right
#		if ! input_vector.x == 0:
#			if input_vector.x < 0:
#				sprite.flip_h = true
#			else:
#				sprite.flip_h = false
#
#		# Play walk animation as we're moving
#		sprite.play("Walk")
#		motion = motion.move_toward(input_vector * MAX_SPEED, ACCELERATION)
#	else:
#		# No movement so go back to idle
#		sprite.play("Idle")
#		motion = motion.move_toward(Vector2.ZERO, FRICTION)
#
#	motion = move_and_slide(motion)
