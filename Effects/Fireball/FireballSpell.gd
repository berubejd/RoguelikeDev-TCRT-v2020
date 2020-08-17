extends RigidBody2D

export var explosion_duration := 0.5
export var explosion_scene: PackedScene = preload("res://Effects/Fireball/Explosion.tscn")
export var duration := 1.0
export var speed := 120
export var spell_damage := 0

onready var duration_timer = $DurationTimer
onready var explosion_container: Node = self
onready var effect := $FireBallEffect

# Yes, I know this isn't a real term for something caught in an explosion
var exploded_list: Array
var is_exploding := false


func initialize(new_position, new_rotation, new_duration):
	position = new_position
	rotation_degrees = new_rotation
	duration = new_duration


func _ready():
	apply_impulse(Vector2(), Vector2(speed,0).rotated(rotation))
	duration_timer.start(duration)


func explode() -> void:
	if is_exploding:
		return
	else:
		is_exploding = true

	var explosion := explosion_scene.instance()
	
	explosion_container.add_child(explosion)
	explosion.global_position = global_position


	for exploded in exploded_list:
		if exploded.get("current_health"):
			exploded.current_health -= spell_damage

	yield(get_tree().create_timer(explosion_duration), "timeout")
	queue_free()


func _on_Area2D_body_entered(body):
	if not body == self:
		linear_velocity = Vector2.ZERO
		$Area2D.set_deferred("monitorable", false)
		effect.visible = false

		explode()


func _on_BlastArea_body_entered(body):
	if not body == self and not body in exploded_list:
		exploded_list.append(body)


func _on_BlastArea_body_exited(body):
	if body in exploded_list:
		exploded_list.erase(body)
