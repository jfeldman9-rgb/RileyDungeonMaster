extends CharacterBody3D
class_name PlayerController

signal slice_requested
signal dash_requested
signal star_requested

enum State { IDLE, RUNNING, ATTACKING, DASHING, THROWING }

@export var move_speed := 6.6
@export var dash_speed_multiplier := 2.6
@export var acceleration := 16.0
@export var deceleration := 22.0

var state: State = State.IDLE
var facing_direction := Vector3.FORWARD
var dash_timer := 0.0


func set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state


func movement_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func update_state_from_motion(input: Vector2) -> void:
	if state in [State.ATTACKING, State.DASHING, State.THROWING]:
		return
	set_state(State.RUNNING if input.length() > 0.05 else State.IDLE)


func request_slice() -> void:
	set_state(State.ATTACKING)
	slice_requested.emit()


func request_dash() -> void:
	set_state(State.DASHING)
	dash_requested.emit()


func request_star() -> void:
	set_state(State.THROWING)
	star_requested.emit()
