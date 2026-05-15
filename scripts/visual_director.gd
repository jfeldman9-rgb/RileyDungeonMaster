extends Node
class_name VisualDirector

@export var world_environment_path: NodePath
@export var sun_path: NodePath
@export var moon_path: NodePath

var horizon_root: Node3D


func _ready() -> void:
	_apply_environment()
	_apply_lighting()
	call_deferred("_build_horizon_accents")


func _process(delta: float) -> void:
	if not horizon_root:
		return
	var time := Time.get_ticks_msec() * 0.001
	for child in horizon_root.get_children():
		if not child is Node3D:
			continue
		var node := child as Node3D
		var base := node.get_meta("base_pos", node.position) as Vector3
		var drift := float(node.get_meta("drift", 0.0))
		var phase := float(node.get_meta("phase", 0.0))
		node.position = base + Vector3(sin(time * drift + phase) * 2.2, sin(time * drift * 0.7 + phase) * 0.28, 0.0)


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
	env.fog_density = 0.007
	env.fog_light_color = Color(0.46, 0.38, 0.58)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.17, 0.26)
	env.ambient_light_energy = 0.44
	env.set("volumetric_fog_enabled", true)
	env.set("volumetric_fog_density", 0.015)
	env.set("volumetric_fog_albedo", Color(0.34, 0.30, 0.46))
	env.set("volumetric_fog_emission", Color(0.04, 0.03, 0.09))
	env.set("volumetric_fog_emission_energy", 0.42)
	env.set("glow_enabled", true)
	env.set("glow_intensity", 1.55)
	env.set("glow_bloom", 0.72)
	env.set("glow_strength", 1.32)
	env.set("ssao_enabled", true)
	env.set("ssao_radius", 3.2)
	env.set("ssao_intensity", 3.1)
	env.set("ssao_power", 1.65)
	env.set("adjustment_enabled", true)
	env.set("adjustment_brightness", 0.96)
	env.set("adjustment_contrast", 1.28)
	env.set("adjustment_saturation", 1.26)
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


func _build_horizon_accents() -> void:
	var parent := get_parent() as Node3D
	if not parent or parent.has_node("VisualHorizonAccents"):
		return
	var root := Node3D.new()
	root.name = "VisualHorizonAccents"
	parent.add_child(root)
	horizon_root = root
	_add_cloud_band(root, Vector3(-52.0, 34.0, -142.0), Vector3(72.0, 4.8, 0.1), Color(0.38, 0.30, 0.56, 0.20))
	_add_cloud_band(root, Vector3(36.0, 29.0, -128.0), Vector3(88.0, 5.2, 0.1), Color(0.62, 0.36, 0.46, 0.16))
	_add_cloud_band(root, Vector3(-86.0, 24.0, -96.0), Vector3(50.0, 3.6, 0.1), Color(0.24, 0.32, 0.55, 0.18))
	_add_cloud_band(root, Vector3(92.0, 23.0, -82.0), Vector3(54.0, 4.0, 0.1), Color(0.32, 0.26, 0.48, 0.18))
	_add_moon_disc(root)


func _add_cloud_band(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var band := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	band.mesh = mesh
	band.position = pos
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 0.18
	band.material_override = material
	band.set_meta("base_pos", pos)
	band.set_meta("drift", randf_range(0.035, 0.075))
	band.set_meta("phase", randf() * TAU)
	parent.add_child(band)


func _add_moon_disc(parent: Node3D) -> void:
	var moon := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 4.5
	mesh.height = 9.0
	mesh.radial_segments = 24
	mesh.rings = 12
	moon.mesh = mesh
	moon.position = Vector3(-72.0, 48.0, -132.0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.72, 0.78, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.46, 0.56, 1.0)
	material.emission_energy_multiplier = 0.52
	moon.material_override = material
	moon.set_meta("base_pos", moon.position)
	moon.set_meta("drift", 0.018)
	moon.set_meta("phase", 1.7)
	parent.add_child(moon)
