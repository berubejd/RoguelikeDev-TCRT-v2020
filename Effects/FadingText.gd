extends Position2D

export (Color) var border_color = Color.black
export (float) var duration = 1.0
export (float) var min_scale = 0.3

onready var value = $Value
onready var timer = $Timer


func initialize(new_text: String, new_duration: float = duration, color: Color = border_color):
	$Value.text = new_text
	$Value.get_font("font").set_outline_color(color)

	duration = new_duration


func _ready():
	# Set and start duration for text
	timer.wait_time = duration
	timer.start()


func _on_Timer_timeout():
	queue_free()

