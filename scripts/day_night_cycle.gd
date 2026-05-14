extends Node
class_name DayNightCycle

signal time_of_day_changed(normalized_time: float)

@export var active := false
@export var sun_path: NodePath
@export var moon_path: NodePath
@export var day_duration_seconds := 360.0
@export var start_time := 0.28
@export var rain_particles_path: NodePath
@export var weather_change_interval := 75.0

var sun: DirectionalLight3D
var moon: DirectionalLight3D
var rain_particles: GPUParticles3D
var time_of_day := 0.0
var weather_timer := 0.0


func _ready() -> void:
	time_of_day = start_time
	sun = get_node_or_null(sun_path) as DirectionalLight3D
	moon = get_node_or_null(moon_path) as DirectionalLight3D
	rain_particles = get_node_or_null(rain_particles_path) as GPUParticles3D
	_apply_lighting()


func _process(delta: float) -> void:
	if not active:
		return
	time_of_day = fposmod(time_of_day + delta / maxf(1.0, day_duration_seconds), 1.0)
	weather_timer -= delta
	if weather_timer <= 0.0:
		weather_timer = weather_change_interval
		_toggle_weather()
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
