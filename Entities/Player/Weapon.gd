extends Area2D

const hit_effect = preload("res://Effects/HitEffect.tscn")

onready var weapon_position = $WeaponSprite

func play_hit_effect():
	var effect = hit_effect.instance()
	var main = get_tree().current_scene
	main.add_child(effect)
	effect.global_position = weapon_position.global_position
