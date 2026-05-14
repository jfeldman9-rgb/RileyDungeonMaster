extends CharacterBody3D
class_name PlayerController

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

var state: State = State.IDLE
var facing_direction := Vector3.FORWARD
var dash_timer := 0.0
var action_timer := 0.0


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
	var speed := move_speed * (dash_speed_multiplier if state == State.DASHING else 1.0)
	var target_velocity := move * speed
	var accel := acceleration if target_velocity.length() > 0.01 else deceleration
	velocity.x = lerpf(velocity.x, target_velocity.x, minf(1.0, accel * delta))
	velocity.z = lerpf(velocity.z, target_velocity.z, minf(1.0, accel * delta))
	move_and_slide()
	if move.length() > 0.05:
		facing_direction = move.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(facing_direction.x, facing_direction.z), minf(1.0, 18.0 * delta))


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
	slice_requested.emit()


func request_dash() -> void:
	set_state(State.DASHING)
	dash_timer = dash_duration
	dash_requested.emit()


func request_star() -> void:
	set_state(State.THROWING)
	action_timer = throw_duration
	star_requested.emit()
