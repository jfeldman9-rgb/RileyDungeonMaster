extends Node
class_name DayNightCycle

signal time_of_day_changed(normalized_time: float)

@export var active := false
@export var sun_path: NodePath
@export var moon_path: NodePath
@export var follow_target_path: NodePath
@export var day_duration_seconds := 360.0
@export var start_time := 0.28
@export var rain_particles_path: NodePath
@export var weather_change_interval := 75.0

var sun: DirectionalLight3D
var moon: DirectionalLight3D
var follow_target: Node3D
var rain_particles: GPUParticles3D
var time_of_day := 0.0
var weather_timer := 0.0


func _ready() -> void:
	time_of_day = start_time
	sun = get_node_or_null(sun_path) as DirectionalLight3D
	moon = get_node_or_null(moon_path) as DirectionalLight3D
	follow_target = get_node_or_null(follow_target_path) as Node3D
	rain_particles = get_node_or_null(rain_particles_path) as GPUParticles3D
	if not rain_particles:
		_create_default_rain()
	_apply_lighting()


func _process(delta: float) -> void:
	if not active:
		return
	time_of_day = fposmod(time_of_day + delta / maxf(1.0, day_duration_seconds), 1.0)
	weather_timer -= delta
	if weather_timer <= 0.0:
		weather_timer = weather_change_interval
		_toggle_weather()
	if rain_particles and follow_target:
		rain_particles.global_position = follow_target.global_position + Vector3.UP * 18.0
	_apply_lighting()
	time_of_day_changed.emit(time_of_day)


func _apply_lighting() -> void:
	var angle := time_of_day * TAU
	var daylight := clampf(sin(angle), 0.0, 1.0)
	if sun:
		sun.rotation_degrees = Vector3(-15.0 - daylight * 70.0, time_of_day * 360.0, 0.0)
		sun.light_energy = lerpf(0.05, 1.15, daylight)
		sun.visible = daylight > 0.03
	if moon:
		moon.rotation_degrees = Vector3(-75.0, time_of_day * 360.0 + 180.0, 0.0)
		moon.light_energy = lerpf(0.45, 0.08, daylight)
		moon.visible = daylight < 0.8


func _toggle_weather() -> void:
	if not rain_particles:
		return
	rain_particles.emitting = randf() < 0.35


func _create_default_rain() -> void:
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "ProceduralRain"
	rain_particles.amount = 260
	rain_particles.lifetime = 1.25
	rain_particles.visibility_aabb = AABB(Vector3(-36.0, -18.0, -36.0), Vector3(72.0, 36.0, 72.0))
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 8.0
	process.initial_velocity_min = 18.0
	process.initial_velocity_max = 24.0
	process.gravity = Vector3(0.0, -2.0, 0.0)
	process.scale_min = 0.7
	process.scale_max = 1.15
	rain_particles.process_material = process
	var drop := BoxMesh.new()
	drop.size = Vector3(0.025, 0.85, 0.025)
	rain_particles.draw_pass_1 = drop
	rain_particles.emitting = false
	add_child(rain_particles)
