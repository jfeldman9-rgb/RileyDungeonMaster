extends CharacterBody3D
class_name PlayerController

const NinjaStarProjectileScript := preload("res://scripts/ninja_star_projectile.gd")
const SLASH_FX := preload("res://assets/generated/slash_fx.png")
const DASH_SWIRL := preload("res://assets/generated/dash_swirl.png")
const RILEY_BACK := preload("res://assets/generated/riley_back.png")
const RILEY_FRONT := preload("res://assets/generated/riley_front.png")

signal slice_requested
signal dash_requested
signal star_requested
signal enemy_sliced(position: Vector3)
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
var sword_light: OmniLight3D
var sword_node: Node3D
var sword_base_position := Vector3.ZERO
var sword_base_rotation := Vector3.ZERO
var painted_sprite: Sprite3D


func _ready() -> void:
	floor_snap_length = 0.45
	_add_hero_shadow_and_rim()
	sword_light = find_child("SwordLight", true, false) as OmniLight3D
	sword_node = find_child("Sword", true, false) as Node3D
	if sword_node:
		sword_base_position = sword_node.position
		sword_base_rotation = sword_node.rotation
	painted_sprite = find_child("PaintedBack", true, false) as Sprite3D


func _add_hero_shadow_and_rim() -> void:
	if has_node("HeroContactShadow"):
		return
	var shadow := MeshInstance3D.new()
	shadow.name = "HeroContactShadow"
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.62
	shadow_mesh.bottom_radius = 0.62
	shadow_mesh.height = 0.012
	shadow_mesh.radial_segments = 28
	shadow.mesh = shadow_mesh
	shadow.position = Vector3(0.0, 0.035, 0.0)
	shadow.scale = Vector3(1.25, 1.0, 0.72)
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.36)
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = shadow_mat
	add_child(shadow)
	var rim := OmniLight3D.new()
	rim.name = "HeroRimLight"
	rim.position = Vector3(0.0, 1.35, 0.85)
	rim.light_color = Color(0.45, 0.82, 1.0)
	rim.light_energy = 0.42
	rim.omni_range = 3.2
	add_child(rim)


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
	_update_painted_facing()
	_update_sword_pose(delta)
	_update_sword_light(delta)


func _update_painted_facing() -> void:
	if not painted_sprite:
		return
	var camera_forward := Vector3(sin(camera_yaw), 0.0, -cos(camera_yaw)).normalized()
	var facing_camera := facing_direction.dot(camera_forward) < -0.15
	painted_sprite.texture = RILEY_FRONT if facing_camera else RILEY_BACK
	painted_sprite.modulate = Color(1.0, 1.0, 1.0, 0.74 if facing_camera else 0.62)


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
	_spawn_slash_fx()
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
		_spawn_hit_pop(enemy_3d.global_position + Vector3.UP * 0.65)
		enemy_sliced.emit(enemy_3d.global_position)
		enemy_3d.queue_free()
		_add_score(15)
		break
	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		if not is_instance_valid(projectile) or not projectile is Node3D:
			continue
		var projectile_3d := projectile as Node3D
		var to_projectile := projectile_3d.global_position - global_position
		to_projectile.y = 0.0
		if to_projectile.length() > slice_range + 0.45:
			continue
		if facing_direction.dot(to_projectile.normalized()) < slice_arc_dot:
			continue
		_spawn_hit_pop(projectile_3d.global_position)
		enemy_sliced.emit(projectile_3d.global_position)
		projectile_3d.queue_free()
		_add_score(5)
		break


func _spawn_ninja_star() -> void:
	var star := Node3D.new()
	star.name = "NinjaStarProjectile"
	star.set_script(NinjaStarProjectileScript)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.92, 1.0)
	material.metallic = 0.55
	material.roughness = 0.22
	material.emission_enabled = true
	material.emission = Color(0.34, 0.72, 1.0)
	material.emission_energy_multiplier = 0.55
	for i in range(4):
		var blade := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.42, 0.045, 0.11)
		blade.mesh = mesh
		blade.rotation_degrees.y = float(i) * 90.0
		blade.material_override = material
		star.add_child(blade)
	var hub := MeshInstance3D.new()
	var hub_mesh := SphereMesh.new()
	hub_mesh.radius = 0.08
	hub_mesh.height = 0.16
	hub_mesh.radial_segments = 8
	hub_mesh.rings = 4
	hub.mesh = hub_mesh
	hub.material_override = material
	star.add_child(hub)
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
	var swirl := Sprite3D.new()
	swirl.texture = DASH_SWIRL
	swirl.pixel_size = 0.01
	swirl.global_position = global_position + Vector3.UP * 0.18 - facing_direction * 0.35
	swirl.rotation_degrees.x = -90.0
	swirl.modulate = Color(0.55, 0.86, 1.0, 0.42)
	get_tree().current_scene.add_child(swirl)
	var swirl_tween := swirl.create_tween()
	swirl_tween.tween_property(swirl, "scale", Vector3(1.7, 1.7, 1.7), 0.2)
	swirl_tween.parallel().tween_property(swirl, "modulate:a", 0.0, 0.2)
	swirl_tween.finished.connect(swirl.queue_free)


func _spawn_slash_fx() -> void:
	var slash := Sprite3D.new()
	slash.texture = SLASH_FX
	slash.pixel_size = 0.0085
	slash.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	slash.global_position = global_position + Vector3.UP * 0.95 + facing_direction * 0.9
	slash.rotation.y = atan2(facing_direction.x, facing_direction.z)
	slash.modulate = Color(0.55, 0.9, 1.0, 0.86)
	get_tree().current_scene.add_child(slash)
	var tween := slash.create_tween()
	tween.tween_property(slash, "scale", Vector3(1.65, 1.65, 1.65), 0.16)
	tween.parallel().tween_property(slash, "modulate:a", 0.0, 0.16)
	tween.finished.connect(slash.queue_free)


func _update_sword_light(delta: float) -> void:
	if not sword_light:
		return
	var attack_boost := 1.0 if state == State.ATTACKING else 0.0
	var dash_boost := 0.45 if state == State.DASHING else 0.0
	var target_energy := 1.2 + attack_boost * 4.4 + dash_boost * 1.5
	var target_range := 4.2 + attack_boost * 2.8 + dash_boost * 1.4
	sword_light.light_energy = lerpf(sword_light.light_energy, target_energy, minf(1.0, 18.0 * delta))
	sword_light.omni_range = lerpf(sword_light.omni_range, target_range, minf(1.0, 14.0 * delta))


func _update_sword_pose(delta: float) -> void:
	if not sword_node:
		return
	var target_pos := sword_base_position
	var target_rot := sword_base_rotation
	if state == State.ATTACKING:
		var t := 1.0 - clampf(action_timer / maxf(0.001, attack_duration), 0.0, 1.0)
		var arc := sin(t * PI)
		target_pos += Vector3(0.12, 0.04, -0.18) * arc
		target_rot = sword_base_rotation + Vector3(0.18 * arc, 1.8 * (t - 0.5), -1.05 * arc)
	elif state == State.DASHING:
		target_pos += Vector3(0.08, -0.05, -0.12)
		target_rot = sword_base_rotation + Vector3(0.22, 0.2, -0.35)
	sword_node.position = sword_node.position.lerp(target_pos, minf(1.0, 24.0 * delta))
	sword_node.rotation.x = lerp_angle(sword_node.rotation.x, target_rot.x, minf(1.0, 24.0 * delta))
	sword_node.rotation.y = lerp_angle(sword_node.rotation.y, target_rot.y, minf(1.0, 24.0 * delta))
	sword_node.rotation.z = lerp_angle(sword_node.rotation.z, target_rot.z, minf(1.0, 24.0 * delta))


func _add_score(amount: int) -> void:
	if has_node("/root/GameState"):
		var state := get_node("/root/GameState")
		if state.has_method("add_score"):
			state.call("add_score", amount)


func _spawn_hit_pop(origin: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.32
	ring_mesh.outer_radius = 0.37
	ring_mesh.ring_segments = 30
	ring.mesh = ring_mesh
	ring.global_position = origin
	ring.look_at(origin + Vector3.UP, Vector3.FORWARD)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.55, 1.0, 0.45, 0.78)
	material.emission_enabled = true
	material.emission = Color(0.35, 1.0, 0.25)
	material.emission_energy_multiplier = 1.0
	ring.material_override = material
	get_tree().current_scene.add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(3.0, 3.0, 3.0), 0.22)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.22)
	tween.finished.connect(ring.queue_free)
