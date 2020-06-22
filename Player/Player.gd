extends KinematicBody2D

export var ACCELERATION = 10
export var FRICTION = 3
export var MAX_SPEED = 60

onready var sprite = $Sprite
onready var weapon = $WeaponPivot

var velocity = Vector2.ZERO


func _ready():
#	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pass


func _process(_delta):
	var input_vector = Vector2.ZERO
	
	# Rotate weapon pivot to direction of mouse
	weapon.look_at(get_global_mouse_position())
	
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
	
	velocity = move_and_slide(velocity)
