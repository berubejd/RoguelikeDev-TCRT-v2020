extends RayCast2D

export (int, 1, 10) var flashes := 3
export (float, 0.0, 3.0) var flash_time := 0.1
export (int, 0, 10) var bounces_max := 3
export var lightning_jolt: PackedScene = preload("res://Effects/LightningBeam/LightningJolt.tscn")

var target_point := Vector2.ZERO

onready var jump_area := $JumpArea

onready var player = get_tree().get_root().find_node("Player", true, false)

func _process(_delta):
	target_point = to_global(cast_to)

	if is_colliding():
		target_point = get_collision_point()

	jump_area.global_position = target_point

func shoot():
	var _target_point = target_point

	var _primary_body = get_collider()
	var _secondary_bodies = jump_area.get_overlapping_bodies()

	if _primary_body:
		_target_point = _primary_body.global_position
		_secondary_bodies.erase(_primary_body)

		for _flash in range(flashes):
			var _start = global_position

			var _new_jolt = lightning_jolt.instance()
			add_child(_new_jolt)
			_new_jolt.create(_start, target_point)

			_start = _target_point
			for _i in range(min(bounces_max, _secondary_bodies.size())):
				var _body = _secondary_bodies[_i]

				_new_jolt = lightning_jolt.instance()
				add_child(_new_jolt)
				_new_jolt.create(_start, _body.global_position)

				_start = _body.global_position

			yield(get_tree().create_timer(flash_time), "timeout")

		if _primary_body.current_health:
			_primary_body.current_health -= 10

		player.emit_signal("spell_result", {
			"hit": true,
			"current_health": _primary_body.current_health if _primary_body.current_health else null,
			"xp_value": _primary_body.xp_value if _primary_body.xp_value else null
			})

	else:
		player.emit_signal("spell_result", { "hit": false, "current_health": null, "xp_value": null })
