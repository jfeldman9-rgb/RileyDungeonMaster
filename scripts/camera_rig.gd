extends Node3D
class_name CameraRig

@export var target_path: NodePath
@export var follow_distance := 12.0
@export var follow_height := 8.5
@export var look_ahead := 6.0
@export var smoothing := 8.0
@export var rotate_speed := 1.65
@export var portrait_height_bonus := 4.0
@export var portrait_distance_bonus := 4.5

var yaw := 0.0
var target: Node3D
var camera: Camera3D


func _ready() -> void:
	target = get_node_or_null(target_path) as Node3D
	camera = find_child("Camera3D", true, false) as Camera3D
	if target and camera:
		var forward := Vector3(sin(yaw), 0.0, -cos(yaw)).normalized()
		var portrait := get_viewport().get_visible_rect().size.y > get_viewport().get_visible_rect().size.x
		var distance := follow_distance + (portrait_distance_bonus if portrait else 0.0)
		var height := follow_height + (portrait_height_bonus if portrait else 0.0)
		global_position = target.global_position - forward * distance + Vector3.UP * height
		camera.look_at(target.global_position + forward * look_ahead + Vector3.UP)


func _process(delta: float) -> void:
	if not target or not camera:
		return
	if Input.is_key_pressed(KEY_Q):
		yaw -= rotate_speed * delta
	if Input.is_key_pressed(KEY_E):
		yaw += rotate_speed * delta
	if target.has_method("set_camera_yaw"):
		target.call("set_camera_yaw", yaw)
	var forward := Vector3(sin(yaw), 0.0, -cos(yaw)).normalized()
	var portrait := get_viewport().get_visible_rect().size.y > get_viewport().get_visible_rect().size.x
	var distance := follow_distance + (portrait_distance_bonus if portrait else 0.0)
	var height := follow_height + (portrait_height_bonus if portrait else 0.0)
	var desired := target.global_position - forward * distance + Vector3.UP * height
	global_position = global_position.lerp(desired, minf(1.0, smoothing * delta))
	camera.look_at(target.global_position + forward * look_ahead + Vector3.UP)
