extends CharacterBody3D
class_name PlayerController

const NinjaStarProjectileScript := preload("res://scripts/ninja_star_projectile.gd")

signal slice_requested
signal dash_requested
signal star_requested
signal state_changed(new_state: State)

enum State { IDLE, RUNNING, ATTACKING, DASHING, THROWING }

@export var move_speed := 6.6
@export var dash_speed_multiplier := 2.6
@export var acceleration := 16.0
@export var deceleration := 22.0
@export var attack_duration := 0.18
@export var throw_duration := 0.18
@export var dash_duration := 0.22
@export var camera_yaw := 0.0
@export var slice_range := 2.1
@export var slice_arc_dot := 0.25
@export var gravity := 28.0

var state: State = State.IDLE
var facing_direction := Vector3.FORWARD
var dash_direction := Vector3.FORWARD
var dash_timer := 0.0
var action_timer := 0.0
var dash_trail_timer := 0.0


func _ready() -> void:
	floor_snap_length = 0.45


func set_camera_yaw(next_yaw: float) -> void:
	camera_yaw = next_yaw


func set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(state)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("slice"):
		request_slice()
	if Input.is_action_just_pressed("dash"):
		request_dash()
	if Input.is_action_just_pressed("throw_star"):
		request_star()
	var input := movement_input()
	update_state_timers(delta)
	update_state_from_motion(input)
	var move := camera_relative_move(input)
	if state == State.DASHING and move.length() <= 0.05:
		move = dash_direction
	var speed := move_speed * (dash_speed_multiplier if state == State.DASHING else 1.0)
	var target_velocity := move * speed
	if state == State.ATTACKING and action_timer > attack_duration * 0.5:
		target_velocity += facing_direction * 4.2
	var accel := acceleration if target_velocity.length() > 0.01 else deceleration
	velocity.x = lerpf(velocity.x, target_velocity.x, minf(1.0, accel * delta))
	velocity.z = lerpf(velocity.z, target_velocity.z, minf(1.0, accel * delta))
	if is_on_floor():
		velocity.y = -0.05
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	if move.length() > 0.05:
		facing_direction = move.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(facing_direction.x, facing_direction.z), minf(1.0, 18.0 * delta))
	rotation.z = lerpf(rotation.z, -input.x * 0.06, minf(1.0, 12.0 * delta))
	if state == State.DASHING:
		dash_trail_timer -= delta
		if dash_trail_timer <= 0.0:
			dash_trail_timer = 0.055
			_spawn_dash_afterimage()


func update_state_timers(delta: float) -> void:
	if action_timer > 0.0:
		action_timer = maxf(0.0, action_timer - delta)
		if action_timer <= 0.0 and state in [State.ATTACKING, State.THROWING]:
			set_state(State.IDLE)
	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		if dash_timer <= 0.0 and state == State.DASHING:
			set_state(State.IDLE)


func movement_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func camera_relative_move(input: Vector2) -> Vector3:
	if input.length() <= 0.01:
		return Vector3.ZERO
	var forward := Vector3(sin(camera_yaw), 0.0, -cos(camera_yaw)).normalized()
	var right := Vector3(cos(camera_yaw), 0.0, sin(camera_yaw)).normalized()
	var move := forward * -input.y + right * input.x
	return move.normalized() if move.length() > 1.0 else move


func update_state_from_motion(input: Vector2) -> void:
	if state in [State.ATTACKING, State.DASHING, State.THROWING]:
		return
	set_state(State.RUNNING if input.length() > 0.05 else State.IDLE)


func request_slice() -> void:
	set_state(State.ATTACKING)
	action_timer = attack_duration
	_apply_slice_hit()
	slice_requested.emit()


func request_dash() -> void:
	dash_direction = facing_direction
	set_state(State.DASHING)
	dash_timer = dash_duration
	dash_trail_timer = 0.0
	dash_requested.emit()


func request_star() -> void:
	set_state(State.THROWING)
	action_timer = throw_duration
	_spawn_ninja_star()
	star_requested.emit()


func _apply_slice_hit() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		var enemy_3d := enemy as Node3D
		var to_enemy := enemy_3d.global_position - global_position
		to_enemy.y = 0.0
		if to_enemy.length() > slice_range:
			continue
		if facing_direction.dot(to_enemy.normalized()) < slice_arc_dot:
			continue
		enemy_3d.queue_free()
		break


func _spawn_ninja_star() -> void:
	var star := Node3D.new()
	star.name = "NinjaStarProjectile"
	star.set_script(NinjaStarProjectileScript)
	var blade := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.16
	mesh.outer_radius = 0.26
	mesh.ring_segments = 18
	blade.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.92, 1.0)
	material.metallic = 0.55
	material.roughness = 0.22
	material.emission_enabled = true
	material.emission = Color(0.34, 0.72, 1.0)
	material.emission_energy_multiplier = 0.55
	blade.material_override = material
	star.add_child(blade)
	get_tree().current_scene.add_child(star)
	star.call("launch", global_position + Vector3.UP * 0.8 + facing_direction * 0.65, facing_direction)


func _spawn_dash_afterimage() -> void:
	var ghost := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.34
	mesh.height = 1.38
	ghost.mesh = mesh
	ghost.global_position = global_position + Vector3.UP * 0.7
	ghost.global_rotation = global_rotation
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.35, 0.72, 1.0, 0.32)
	material.emission_enabled = true
	material.emission = Color(0.2, 0.55, 1.0)
	material.emission_energy_multiplier = 0.7
	ghost.material_override = material
	get_tree().current_scene.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tween.finished.connect(ghost.queue_free)
