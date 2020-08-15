extends Position2D

export (Color) var border_color = Color.black
export (float) var duration = 1.0
export (float) var min_scale = 0.3
export (int) var speed = 20

onready var value = $Value
onready var timer = $Timer

var gravity = Vector2.DOWN
var mass = 50
var velocity = Vector2.ZERO


func initialize(new_text, color = border_color):
	$Value.text = new_text
	$Value.get_font("font").set_outline_color(color)


func _ready():
	# Set text direction
	velocity = Vector2(rand_range(-30, 30), -20)

	# Set and start duration for text
	timer.wait_time = duration
	timer.start()


func _physics_process(delta):
	velocity += gravity * mass * delta
	position += velocity * delta
	
	var new_scale = 1 - ( duration - timer.time_left / duration * 1 - min_scale )
	value.rect_scale = Vector2(new_scale, new_scale)


func _on_Timer_timeout():
	queue_free()
