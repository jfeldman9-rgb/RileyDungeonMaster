extends Node3D
class_name CameraRig

@export var target_path: NodePath
@export var follow_distance := 13.2
@export var follow_height := 8.35
@export var look_ahead := 7.2
@export var smoothing := 8.6
@export var rotate_speed := 1.65
@export var portrait_height_bonus := 5.6
@export var portrait_distance_bonus := 6.6
@export var landscape_fov := 62.0
@export var portrait_fov := 68.0

var yaw := 0.0
var target: Node3D
var camera: Camera3D
var shake_timer := 0.0
var shake_strength := 0.0


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
	call_deferred("_connect_feedback_signals")


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
	if shake_timer > 0.0:
		shake_timer = maxf(0.0, shake_timer - delta)
		desired += Vector3(randf_range(-1.0, 1.0), randf_range(-0.45, 0.45), randf_range(-1.0, 1.0)) * shake_strength
		shake_strength = lerpf(shake_strength, 0.0, minf(1.0, 6.0 * delta))
	global_position = global_position.lerp(desired, minf(1.0, smoothing * delta))
	camera.fov = lerpf(camera.fov, portrait_fov if portrait else landscape_fov, minf(1.0, 3.0 * delta))
	camera.look_at(target.global_position + forward * look_ahead + Vector3.UP * 1.35)


func shake(duration: float, strength: float) -> void:
	shake_timer = maxf(shake_timer, duration)
	shake_strength = maxf(shake_strength, strength)


func _connect_feedback_signals() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var player := scene.get_node_or_null("RileyPlayer")
	if player:
		_connect_if_present(player, "enemy_sliced", Callable(self, "_on_enemy_sliced"))
		_connect_if_present(player, "dash_requested", Callable(self, "_on_dash_requested"))
	var objectives := scene.get_node_or_null("WorldObjectives")
	if objectives:
		_connect_if_present(objectives, "kenzie_shield_hit", Callable(self, "_on_shield_hit"))
	if has_node("/root/GameState"):
		var state := get_node("/root/GameState")
		_connect_if_present(state, "player_damaged", Callable(self, "_on_player_damaged"))


func _connect_if_present(source: Object, signal_name: String, callable: Callable) -> void:
	if source.has_signal(signal_name) and not source.is_connected(signal_name, callable):
		source.connect(signal_name, callable)


func _on_enemy_sliced(_position: Vector3) -> void:
	shake(0.08, 0.08)


func _on_dash_requested() -> void:
	shake(0.06, 0.045)


func _on_shield_hit(_remaining: int) -> void:
	shake(0.24, 0.18)


func _on_player_damaged(_new_health: int) -> void:
	shake(0.22, 0.16)
