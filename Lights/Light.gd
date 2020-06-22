extends Light2D

onready var tween_brightness = $Brightness
onready var tween_position = $Position

onready var _light_orig_brightness = self.energy
onready var _light_old_brightness = _light_orig_brightness
onready var _light_orig_pos = self.position
onready var _light_old_pos = _light_orig_pos


func _on_Timer_timeout():
	# Slightly Adjust position around center of original position
	var light_new_pos = Vector2(rand_range(_light_orig_pos.x - 1, _light_orig_pos.x + 1), rand_range(_light_orig_pos.y - 1, _light_orig_pos.y + 1))
	tween_position.interpolate_property(self, "position", _light_old_pos, light_new_pos, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_position.start()
	_light_old_pos = light_new_pos

	# Slightly adjust brightness
	var light_new_brightness = rand_range(_light_orig_brightness * .98, _light_orig_brightness * 1.02)
	tween_brightness.interpolate_property(self, "energy", _light_old_brightness, light_new_brightness, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_brightness.start()
	_light_old_brightness = light_new_brightness
	
