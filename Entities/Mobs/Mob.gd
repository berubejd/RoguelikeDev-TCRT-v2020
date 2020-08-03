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

const hit_effect = preload("res://Effects/HitEffect.tscn")

export var ACCELERATION = 5
export var FRICTION = 3
export var MAX_HEALTH = 10
export var MAX_SPEED = 20
export (int) var WAIT_SECS = 5
export (int) var WALK_SECS = 4

onready var alert_timer = $Aggro/AlertTimer
onready var attack_timer = $Weapon/WeaponPivot/Weapon/AttackTimer
onready var animation = $Sprite
onready var animation_player = $AnimationPlayer
onready var bubble = $Bubble
onready var bubble_player = $Bubble/AnimationPlayer
onready var hit_timer = $HitTimer
onready var state = HIDDEN if animation.animation == "Hidden" else IDLE
onready var stun_timer = $HitBox/StunTimer
onready var wander_timer = $WanderTimer
onready var weapon = $Weapon/WeaponPivot
onready var weapon_shape = $Weapon/WeaponPivot/Weapon/CollisionShape2D

var attacker_direction: Vector2
var current_health: int = MAX_HEALTH setget update_health
var defense: int = 0
var death = preload("res://Effects/Explosion.tscn")
var power: int = 3
var target
var target_list: Array
var velocity: = Vector2.ZERO
var walking_direction: Vector2

func _ready():
	randomize()
	if not state == HIDDEN:
		wander_timer.start()


func _physics_process(_delta):
	match state:
		HIDDEN:
			pass

		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION)

		WALK:
			if is_on_wall():
				# Generate a new random direction
				walking_direction = Vector2(rand_range(-1.0, 1.0), rand_range(-1.0, 1.0)).normalized()
				wander_timer.start(1)

			velocity = velocity.move_toward(walking_direction * MAX_SPEED, ACCELERATION)

		HIT:
			if stun_timer.is_stopped():
				state = CHASE
			else:
				velocity = velocity.move_toward(Vector2.ZERO, FRICTION)

		DEATH:
			# audiostream.stream = load("Some death resource")
			# audiostream.play()

			if animation.frames.has_animation("Death"):
				animation.play("Death")
			else:
				queue_free()

				var death_instance = death.instance()
				death_instance.position = global_position
				death_instance.modulate = Color('55cf40')
				death_instance.emitting = true
				get_tree().get_root().find_node("Effects", true, false).add_child(death_instance)

		ALERT:
			# This should verify player is "seeable" or their trail is then transition with that target else go back to idle
			state = CHASE
			weapon_shape.disabled = false

		CHASE:
			if target:
				weapon.look_at(target.position)
				walking_direction = (target.position - position).normalized()
				velocity = velocity.move_toward(walking_direction * MAX_SPEED, ACCELERATION) 
			else:
				# This would go to ALERT to try to find player
				state = IDLE
				weapon_shape.disabled = true

		ATTACK:
			if attack_timer.is_stopped() and target_list.size():
				for body in target_list:
					damage_target(body)

				attack_timer.start(1)

			if not target_list.size():
				state = CHASE

	animate()
	velocity = move_and_slide(velocity)


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

	if velocity != Vector2.ZERO:
		# Face sprite in direction of movement if were moving left or right
		if ! velocity.x == 0:
			if velocity.x < 0:
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


func damage_taken(direction):
	play_hit_effect()

	if current_health <= 0:
		state = DEATH
		return
	else:
		hit_timer.start(1)
		
		velocity = direction * 100
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


func play_hit_effect():
	var effect = hit_effect.instance()
	var main = get_tree().current_scene
	main.add_child(effect)
	effect.global_position = global_position


func stun(duration: = 0.3):
	stun_timer.start(duration)
	state = HIT


func damage_target(body):
	body.attacker_direction = (body.global_position - position).normalized()
	body.current_health -= power


func _on_Weapon_body_entered(body):
	if not body in target_list:
		target_list.append(body)
		state = ATTACK

		if attack_timer.is_stopped():
			damage_target(body)
			attack_timer.start(1)


func _on_Weapon_body_exited(body):
	if body in target_list:
		target_list.erase(body)


func update_health(value):
	if hit_timer.is_stopped() and value <= current_health:
		current_health = value

		var knockback_direction: Vector2

		if attacker_direction:
			knockback_direction = attacker_direction
		else:
			if target:
				knockback_direction = (position - target.global_position).normalized()

		damage_taken(knockback_direction)
		
		if not state == DEATH:
			stun()
