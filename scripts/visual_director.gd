extends Node
class_name VisualDirector

@export var world_environment_path: NodePath
@export var sun_path: NodePath
@export var moon_path: NodePath


func _ready() -> void:
	_apply_environment()
	_apply_lighting()


func _apply_environment() -> void:
	var world_environment := get_node_or_null(world_environment_path) as WorldEnvironment
	if not world_environment:
		return
	if not world_environment.environment:
		world_environment.environment = Environment.new()
	var env := world_environment.environment
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.08, 0.09, 0.18)
	sky_material.sky_horizon_color = Color(0.32, 0.22, 0.38)
	sky_material.ground_bottom_color = Color(0.035, 0.04, 0.055)
	sky_material.ground_horizon_color = Color(0.18, 0.16, 0.20)
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.08
	var sky := Sky.new()
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.fog_enabled = true
	env.fog_density = 0.008
	env.fog_light_color = Color(0.42, 0.36, 0.52)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.16, 0.24)
	env.ambient_light_energy = 0.38
	env.set("volumetric_fog_enabled", true)
	env.set("volumetric_fog_density", 0.015)
	env.set("volumetric_fog_albedo", Color(0.34, 0.30, 0.46))
	env.set("volumetric_fog_emission", Color(0.04, 0.03, 0.09))
	env.set("volumetric_fog_emission_energy", 0.42)
	env.set("glow_enabled", true)
	env.set("glow_intensity", 1.3)
	env.set("glow_bloom", 0.55)
	env.set("glow_strength", 1.2)
	env.set("ssao_enabled", true)
	env.set("ssao_radius", 3.2)
	env.set("ssao_intensity", 3.1)
	env.set("ssao_power", 1.65)
	env.set("adjustment_enabled", true)
	env.set("adjustment_brightness", 0.96)
	env.set("adjustment_contrast", 1.24)
	env.set("adjustment_saturation", 1.18)
	env.set("dof_blur_far_enabled", true)
	env.set("dof_blur_far_distance", 64.0)
	env.set("dof_blur_far_transition", 28.0)
	env.set("dof_blur_amount", 0.1)


func _apply_lighting() -> void:
	var sun := get_node_or_null(sun_path) as DirectionalLight3D
	if sun:
		sun.light_color = Color(1.0, 0.72, 0.42)
		sun.light_energy = 1.75
		sun.shadow_enabled = true
		sun.directional_shadow_max_distance = 180.0
	var moon := get_node_or_null(moon_path) as DirectionalLight3D
	if moon:
		moon.light_color = Color(0.38, 0.48, 1.0)
		moon.light_energy = 0.45
		moon.shadow_enabled = true
