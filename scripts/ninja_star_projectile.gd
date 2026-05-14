extends Node3D
class_name NinjaStarProjectile

@export var speed := 18.0
@export var max_range := 42.0
@export var pierce_targets := 2
@export var trail_interval := 0.045

var direction := Vector3.FORWARD
var traveled := 0.0
var hits := 0
var trail_timer := 0.0


func launch(origin: Vector3, launch_direction: Vector3) -> void:
	global_position = origin
	direction = launch_direction.normalized()
	look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	var step := speed * delta
	global_position += direction * step
	traveled += step
	rotate_y(delta * 28.0)
	trail_timer -= delta
	if trail_timer <= 0.0:
		trail_timer = trail_interval
		_spawn_trail()
	_check_enemy_hits()
	if traveled >= max_range:
		queue_free()


func _check_enemy_hits() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		var enemy_3d := enemy as Node3D
		if enemy_3d.global_position.distance_to(global_position) > 0.75:
			continue
		hits += 1
		_add_score(10)
		enemy_3d.queue_free()
		if hits >= pierce_targets:
			queue_free()
			return


func _spawn_trail() -> void:
	var mote := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	mote.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.85, 1.0, 0.7)
	material.emission_enabled = true
	material.emission = Color(0.55, 0.85, 1.0)
	material.emission_energy_multiplier = 0.7
	mote.material_override = material
	mote.global_position = global_position
	get_tree().current_scene.add_child(mote)
	var tween := mote.create_tween()
	tween.tween_property(mote, "scale", Vector3.ZERO, 0.22)
	tween.finished.connect(mote.queue_free)


func _add_score(amount: int) -> void:
	if has_node("/root/GameState"):
		var state := get_node("/root/GameState")
		if state.has_method("add_score"):
			state.call("add_score", amount)
