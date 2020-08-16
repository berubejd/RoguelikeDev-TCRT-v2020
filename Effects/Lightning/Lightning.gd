extends RayCast2D

export (int, 1, 10) var flashes := 3
export (float, 0.0, 3.0) var flash_time := 0.1
export var lightning_bolt: PackedScene = preload("res://Effects/Lightning/LightningBolt.tscn")
export var max_distance := 0
export var spell_damage := 0

var target_point := Vector2.ZERO

onready var player = Globals.player


func initialize(new_position, new_rotation, new_distance):
	position = new_position
	rotation_degrees = new_rotation
	cast_to.x = new_distance


func _ready():
	target_point = to_global(cast_to)


func shoot() -> void:
	var _target_point = target_point

	force_raycast_update()
	if is_colliding():
		target_point = get_collision_point()

	var _primary_body = get_collider()

	if _primary_body:
		_target_point = _primary_body.global_position

		if _primary_body.get("current_health"):
			_primary_body.current_health -= spell_damage

			player.emit_signal("spell_result", {
				"hit": true,
				"current_health": _primary_body.current_health if _primary_body.current_health else null,
				"xp_value": _primary_body.xp_value if _primary_body.xp_value else null
				})

	else:
		player.emit_signal("spell_result", { "hit": false, "current_health": null, "xp_value": null })

	for _flash in range(flashes):
		var _start = global_position

		var _new_bolt = lightning_bolt.instance()
		add_child(_new_bolt)
		_new_bolt.create(_start, target_point)

		_start = _target_point

		yield(get_tree().create_timer(flash_time), "timeout")

	queue_free()
