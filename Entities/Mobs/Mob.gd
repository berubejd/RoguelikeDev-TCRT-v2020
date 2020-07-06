extends KinematicBody2D

enum {
	HIDDEN,
	IDLE,
	WALK,
	HIT,
	DEATH,
	ALERT,
	CHASE,
	ATTACK
}

# This needs to come out, too
const hit_effect = preload("res://Effects/HitEffect.tscn")

export var ACCELERATION = 5
export var FRICTION = 3
export var MAX_HEALTH = 3
export var MAX_SPEED = 20
export (int) var WAIT_SECS = 5
export (int) var WALK_SECS = 4

onready var alert_timer = $Aggro/AlertTimer
onready var animation = $Sprite
onready var animation_player = $AnimationPlayer
onready var bubble = $Bubble
onready var bubble_player = $Bubble/AnimationPlayer
onready var state = HIDDEN if animation.animation == "Hidden" else IDLE
onready var stun_timer = $HitBox/StunTimer
onready var wander_timer = $WanderTimer
onready var weapon = $Weapon/WeaponPivot

var current_health = MAX_HEALTH
var motion = Vector2.ZERO
var target
var walking_direction


func _ready():
	randomize()
	if not state == HIDDEN:
		wander_timer.start()


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
				wander_timer.start(1)

			motion = motion.move_toward(walking_direction * MAX_SPEED, ACCELERATION)

		HIT:
			if stun_timer.is_stopped():
				state = CHASE
			else:
				motion = motion.move_toward(Vector2.ZERO, FRICTION)

		DEATH:
			pass

		ALERT:
			# This should verify player is "seeable" or their trail is then transition with that target else go back to idle
			state = CHASE

		CHASE:
			if target:
				walking_direction = (target.position - position).normalized()
				motion = motion.move_toward(walking_direction * MAX_SPEED, ACCELERATION) 
			else:
				# This would go to ALERT to try to find player
				state = IDLE

		ATTACK:
			pass

	animate()	
	motion = move_and_slide(motion)


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

	wander_timer.start(timeout + 1)


func animate():
	# Let 'Hit' or 'Emerge' animations complete
	var current_animation = animation.get_animation()
	if current_animation == 'Hit' or current_animation == 'Emerge' or current_animation == 'Death':
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

	if state == DEATH:
		queue_free()

	animation.play("Idle")


func hit(direction, damage=1):
	current_health -= damage
	if current_health <= 0:
		state = DEATH
		# audiostream.stream = load("Some death resource")
		# audiostream.play()
		if animation.frames.has_animation("Death"):
			animation.play("Death")
		else:
			queue_free()
	else:
		motion = direction * 100
		if animation.frames.has_animation("Hit"):
			animation.play("Hit")
		elif animation_player.has_animation("Hit"):
			animation_player.play("Hit")
		# audiostream.stream = load("res://Sound/Hurt.wav")
		# audiostream.play()
	
	connect_animation_signal()


func _on_Aggro_body_entered(body):
	if state == HIDDEN:
		if animation.frames.has_animation("Emerge"):
			animation.play("Emerge")
			connect_animation_signal()

	state = ALERT
	# This would be alert until player is seen then transition to chase
	# bubble_player.play("Alert")
	bubble_player.play("Chase")
	target = body
	alert_timer.start(3)


func _on_Aggro_body_exited(_body):
	target = null
	# This should probably only end prematurely if the time ran out on alert
	# bubble.clear()


func _on_HitBox_area_entered(area):
	var knockback_direction = (position - area.global_position).normalized()
	# This is all garbage
	var effect = hit_effect.instance()
	var main = get_tree().current_scene
	main.add_child(effect)
	effect.global_position = global_position
	hit(knockback_direction)
	stun()


func stun(duration: = 0.3):
	stun_timer.start(duration)
	state = HIT
