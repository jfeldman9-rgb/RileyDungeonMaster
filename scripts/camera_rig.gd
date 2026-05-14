extends Node3D
class_name CameraRig

@export var target_path: NodePath
@export var follow_distance := 12.0
@export var follow_height := 8.5
@export var look_ahead := 6.0
@export var smoothing := 8.0

var yaw := 0.0
var target: Node3D
var camera: Camera3D


func _ready() -> void:
	target = get_node_or_null(target_path) as Node3D
	camera = find_child("Camera3D", true, false) as Camera3D


func _process(delta: float) -> void:
	if not target or not camera:
		return
	var forward := Vector3(sin(yaw), 0.0, -cos(yaw)).normalized()
	var desired := target.global_position - forward * follow_distance + Vector3.UP * follow_height
	global_position = global_position.lerp(desired, minf(1.0, smoothing * delta))
	camera.look_at(target.global_position + forward * look_ahead + Vector3.UP)
