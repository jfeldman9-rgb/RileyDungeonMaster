extends Node3D
class_name WorldChunk

@export var chunk_size := 48.0
@export var chunk_coord := Vector2i.ZERO
@export var seed := 1337
@export var terrain_resolution := 18
@export var tree_count := 34
@export var grass_count := 130

var generated := false
var noise := FastNoiseLite.new()

const LANDMARKS := [
	{"name": "Starting Clearing", "kind": "clearing", "position": Vector3(0.0, 0.0, 14.0), "color": Color(0.22, 0.32, 0.13)},
	{"name": "Broken Courtyard", "kind": "courtyard", "position": Vector3(4.0, 0.0, -38.0), "color": Color(0.55, 0.48, 0.36)},
	{"name": "Moon Library", "kind": "library", "position": Vector3(-62.0, 0.0, -34.0), "color": Color(0.25, 0.32, 0.72)},
	{"name": "Poison Garden", "kind": "garden", "position": Vector3(58.0, 0.0, -26.0), "color": Color(0.28, 0.75, 0.24)},
	{"name": "Old Stone Bridge", "kind": "bridge", "position": Vector3(2.0, 0.0, -72.0), "color": Color(0.42, 0.38, 0.34)},
	{"name": "Crown Crypt", "kind": "crypt", "position": Vector3(-32.0, 0.0, -86.0), "color": Color(0.66, 0.54, 0.26)},
	{"name": "Kenzie Tower", "kind": "tower", "position": Vector3(22.0, 0.0, -104.0), "color": Color(0.78, 0.24, 0.95)}
]

const PATH_SEGMENTS := [
	[Vector3(0.0, 0.0, 14.0), Vector3(8.0, 0.0, -12.0)],
	[Vector3(8.0, 0.0, -12.0), Vector3(4.0, 0.0, -38.0)],
	[Vector3(4.0, 0.0, -38.0), Vector3(-62.0, 0.0, -34.0)],
	[Vector3(4.0, 0.0, -38.0), Vector3(58.0, 0.0, -26.0)],
	[Vector3(4.0, 0.0, -38.0), Vector3(2.0, 0.0, -72.0)],
	[Vector3(2.0, 0.0, -72.0), Vector3(-32.0, 0.0, -86.0)],
	[Vector3(2.0, 0.0, -72.0), Vector3(22.0, 0.0, -104.0)]
]


func generate(coord: Vector2i, size: float, world_seed: int = 1337) -> void:
	chunk_coord = coord
	chunk_size = size
	seed = world_seed
	position = Vector3(coord.x * size, 0.0, coord.y * size)
	if generated:
		return
	generated = true
	_configure_noise()
	_build_terrain()
	_build_path_marks()
	_build_foliage()
	_build_scattered_adventure_props()
	_build_landmark_markers()


func _configure_noise() -> void:
	noise.seed = seed + chunk_coord.x * 92821 + chunk_coord.y * 68917
	noise.frequency = 0.035
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.45


func sample_height(local_x: float, local_z: float) -> float:
	var world_x := local_x + float(chunk_coord.x) * chunk_size
	var world_z := local_z + float(chunk_coord.y) * chunk_size
	return noise.get_noise_2d(world_x, world_z) * 1.15


func _build_terrain() -> void:
	var terrain := MeshInstance3D.new()
	terrain.mesh = _make_terrain_mesh()
	terrain.material_override = _make_material(Color(0.18, 0.28, 0.13), 0.9)
	add_child(terrain)
	terrain.create_trimesh_collision()


func _make_terrain_mesh() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var half := chunk_size * 0.5
	for z in range(terrain_resolution + 1):
		for x in range(terrain_resolution + 1):
			var px := lerpf(-half, half, float(x) / float(terrain_resolution))
			var pz := lerpf(-half, half, float(z) / float(terrain_resolution))
			vertices.append(Vector3(px, sample_height(px, pz), pz))
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(x) / float(terrain_resolution), float(z) / float(terrain_resolution)))
	for z in range(terrain_resolution):
		for x in range(terrain_resolution):
			var i := z * (terrain_resolution + 1) + x
			indices.append_array([i, i + 1, i + terrain_resolution + 1, i + 1, i + terrain_resolution + 2, i + terrain_resolution + 1])
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_path_marks() -> void:
	for segment in PATH_SEGMENTS:
		var from: Vector3 = segment[0]
		var to: Vector3 = segment[1]
		var length := from.distance_to(to)
		var steps := maxi(2, int(length / 4.5))
		var dir := (to - from).normalized()
		for i in range(steps + 1):
			var t := float(i) / float(steps)
			var world_pos := from.lerp(to, t)
			if not _contains_world_point(world_pos):
				continue
			var local_pos := Vector3(world_pos.x - position.x, 0.0, world_pos.z - position.z)
			local_pos.y = sample_height(local_pos.x, local_pos.z) + 0.045
			_add_path_slab(local_pos, dir, 3.8 + sin(t * PI) * 1.4)


func _add_path_slab(local_pos: Vector3, dir: Vector3, width: float) -> void:
	var path := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.05, 4.8)
	path.mesh = mesh
	path.position = local_pos
	path.rotation.y = atan2(dir.x, dir.z)
	path.material_override = _make_material(Color(0.18, 0.13, 0.075), 0.96)
	add_child(path)


func _build_foliage() -> void:
	_build_tree_multimesh()
	_build_grass_multimesh()


func _build_scattered_adventure_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + chunk_coord.x * 31013 + chunk_coord.y * 41017
	for i in range(10):
		var lx := rng.randf_range(-chunk_size * 0.47, chunk_size * 0.47)
		var lz := rng.randf_range(-chunk_size * 0.47, chunk_size * 0.47)
		if _near_major_path(Vector3(lx + position.x, 0.0, lz + position.z), 3.2):
			continue
		var scale := rng.randf_range(0.65, 1.9)
		if rng.randf() < 0.62:
			_add_rock(Vector3(lx, sample_height(lx, lz) + 0.28 * scale, lz), scale, rng)
		else:
			_add_ruin_shard(Vector3(lx, sample_height(lx, lz) + 0.42 * scale, lz), scale, rng)


func _near_major_path(world_pos: Vector3, radius: float) -> bool:
	for segment in PATH_SEGMENTS:
		var a: Vector3 = segment[0]
		var b: Vector3 = segment[1]
		var ab := b - a
		var denom := maxf(0.001, ab.length_squared())
		var t := clampf((world_pos - a).dot(ab) / denom, 0.0, 1.0)
		if world_pos.distance_to(a.lerp(b, t)) <= radius:
			return true
	return false


func _add_rock(local_pos: Vector3, scale: float, rng: RandomNumberGenerator) -> void:
	var body := StaticBody3D.new()
	body.position = local_pos
	body.rotation_degrees = Vector3(rng.randf_range(-8.0, 8.0), rng.randf_range(0.0, 360.0), rng.randf_range(-8.0, 8.0))
	add_child(body)
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.55 * scale
	mesh.height = 0.9 * scale
	mesh.radial_segments = 7
	mesh.rings = 4
	rock.mesh = mesh
	rock.scale = Vector3(rng.randf_range(0.8, 1.7), rng.randf_range(0.55, 1.1), rng.randf_range(0.8, 1.5))
	rock.material_override = _make_material(Color(0.17, 0.16, 0.15), 0.88)
	body.add_child(rock)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55 * scale
	shape.shape = sphere
	body.add_child(shape)


func _add_ruin_shard(local_pos: Vector3, scale: float, rng: RandomNumberGenerator) -> void:
	var body := StaticBody3D.new()
	body.position = local_pos
	body.rotation_degrees = Vector3(rng.randf_range(-9.0, 9.0), rng.randf_range(0.0, 360.0), rng.randf_range(-14.0, 14.0))
	add_child(body)
	var shard := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(rng.randf_range(0.8, 1.8), rng.randf_range(0.65, 1.7), rng.randf_range(0.22, 0.55)) * scale
	shard.mesh = mesh
	shard.material_override = _make_material(Color(0.20, 0.18, 0.16), 0.84)
	body.add_child(shard)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = mesh.size
	shape.shape = box
	body.add_child(shape)


func _build_tree_multimesh() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.62
	mesh.height = 2.3
	mesh.radial_segments = 7
	var mm := MultiMesh.new()
	mm.mesh = mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = tree_count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + chunk_coord.x * 13007 + chunk_coord.y * 17011
	for i in range(tree_count):
		var lx := rng.randf_range(-chunk_size * 0.48, chunk_size * 0.48)
		var lz := rng.randf_range(-chunk_size * 0.48, chunk_size * 0.48)
		var density := noise.get_noise_2d(lx + position.x, lz + position.z)
		if density < -0.1:
			lx += chunk_size * 2.0
		var scale := rng.randf_range(0.75, 1.55)
		var t := Transform3D(Basis().scaled(Vector3(scale, scale, scale)), Vector3(lx, sample_height(lx, lz) + 1.1 * scale, lz))
		t.basis = t.basis.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		mm.set_instance_transform(i, t)
	var inst := MultiMeshInstance3D.new()
	inst.name = "TreeMultiMesh"
	inst.multimesh = mm
	inst.material_override = _make_material(Color(0.035, 0.15, 0.055), 0.9)
	add_child(inst)


func _build_grass_multimesh() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.08, 0.28, 0.08)
	var mm := MultiMesh.new()
	mm.mesh = mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = grass_count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + chunk_coord.x * 19001 + chunk_coord.y * 23003
	for i in range(grass_count):
		var lx := rng.randf_range(-chunk_size * 0.49, chunk_size * 0.49)
		var lz := rng.randf_range(-chunk_size * 0.49, chunk_size * 0.49)
		var scale := rng.randf_range(0.6, 1.4)
		var t := Transform3D(Basis().scaled(Vector3(scale, scale, scale)), Vector3(lx, sample_height(lx, lz) + 0.16 * scale, lz))
		t.basis = t.basis.rotated(Vector3.UP, rng.randf_range(0.0, TAU))
		mm.set_instance_transform(i, t)
	var inst := MultiMeshInstance3D.new()
	inst.name = "GrassMultiMesh"
	inst.multimesh = mm
	inst.material_override = _make_material(Color(0.09, 0.22, 0.08), 0.95)
	add_child(inst)


func _build_landmark_markers() -> void:
	for landmark in LANDMARKS:
		var world_pos: Vector3 = landmark["position"] as Vector3
		if _contains_world_point(world_pos):
			_build_landmark(str(landmark["kind"]), str(landmark["name"]), world_pos, landmark["color"] as Color)


func _contains_world_point(world_pos: Vector3) -> bool:
	var min_x := position.x - chunk_size * 0.5
	var max_x := position.x + chunk_size * 0.5
	var min_z := position.z - chunk_size * 0.5
	var max_z := position.z + chunk_size * 0.5
	return world_pos.x >= min_x and world_pos.x < max_x and world_pos.z >= min_z and world_pos.z < max_z


func _build_landmark(kind: String, landmark_name: String, world_pos: Vector3, color: Color) -> void:
	var local_pos := Vector3(world_pos.x - position.x, 0.0, world_pos.z - position.z)
	local_pos.y = sample_height(local_pos.x, local_pos.z)
	if kind == "tower":
		_build_tower_landmark(local_pos, color)
	elif kind == "bridge":
		_build_bridge_landmark(local_pos, color)
	elif kind == "courtyard":
		_build_courtyard_landmark(local_pos, color)
	elif kind == "library":
		_build_library_landmark(local_pos, color)
	elif kind == "garden":
		_build_garden_landmark(local_pos, color)
	elif kind == "crypt":
		_build_crypt_landmark(local_pos, color)
	else:
		_build_clearing_landmark(local_pos, color)


func _build_clearing_landmark(center: Vector3, color: Color) -> void:
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 5.0
	ring_mesh.outer_radius = 5.28
	ring_mesh.ring_segments = 48
	ring.mesh = ring_mesh
	ring.position = center + Vector3.UP * 0.06
	ring.rotation_degrees.x = 90.0
	ring.material_override = _make_emissive_material(color, 0.18)
	add_child(ring)


func _build_tower_landmark(center: Vector3, color: Color) -> void:
	_add_box(center + Vector3(0.0, 0.38, 0.0), Vector3(9.0, 0.75, 9.0), Color(0.21, 0.18, 0.22))
	_add_box(center + Vector3(0.0, 1.0, -2.8), Vector3(6.0, 0.5, 3.0), Color(0.28, 0.22, 0.32))
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		_add_column(center + Vector3(cos(angle) * 4.2, 2.0, sin(angle) * 4.2), 0.42, 4.0, color)
	var light := OmniLight3D.new()
	light.position = center + Vector3(0.0, 4.8, 0.0)
	light.light_color = color
	light.light_energy = 2.1
	light.omni_range = 18.0
	add_child(light)


func _build_courtyard_landmark(center: Vector3, color: Color) -> void:
	_build_clearing_landmark(center, color)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var offset := Vector3(cos(angle) * 6.0, 0.0, sin(angle) * 4.8)
		_add_column(center + offset + Vector3.UP * 1.2, 0.28, randf_range(1.5, 3.2), Color(0.38, 0.34, 0.29))
	_add_box(center + Vector3(0.0, 0.3, -5.6), Vector3(9.5, 0.6, 1.2), Color(0.25, 0.22, 0.19))
	_add_box(center + Vector3(-4.7, 1.2, -5.6), Vector3(0.8, 2.3, 1.0), Color(0.22, 0.20, 0.18))
	_add_box(center + Vector3(4.7, 1.2, -5.6), Vector3(0.8, 2.3, 1.0), Color(0.22, 0.20, 0.18))


func _build_bridge_landmark(center: Vector3, color: Color) -> void:
	for i in range(7):
		_add_box(center + Vector3(0.0, 0.24, -4.5 + i * 1.5), Vector3(6.4, 0.32, 1.1), Color(0.25, 0.23, 0.20))
	for x in [-3.8, 3.8]:
		for z in [-4.8, 4.8]:
			_add_column(center + Vector3(x, 1.05, z), 0.28, 2.1, color)


func _build_library_landmark(center: Vector3, color: Color) -> void:
	_add_box(center + Vector3(0.0, 0.3, 0.0), Vector3(8.5, 0.6, 5.5), Color(0.14, 0.15, 0.24))
	for x in [-3.2, -1.1, 1.1, 3.2]:
		_add_column(center + Vector3(x, 1.75, -2.3), 0.28, 3.5, Color(0.32, 0.34, 0.55))
	_add_box(center + Vector3(0.0, 3.55, -2.3), Vector3(8.8, 0.45, 0.8), Color(0.16, 0.17, 0.28))
	_build_clearing_landmark(center + Vector3(0.0, 0.08, 0.0), color)


func _build_garden_landmark(center: Vector3, color: Color) -> void:
	_build_clearing_landmark(center, color)
	for i in range(10):
		var angle := TAU * float(i) / 10.0
		var offset := Vector3(cos(angle) * 5.2, 0.0, sin(angle) * 4.0)
		_add_tree(center + offset, 1.35, Color(0.05, 0.28, 0.08))
	var puddle := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 3.4
	mesh.bottom_radius = 3.4
	mesh.height = 0.035
	mesh.radial_segments = 28
	puddle.mesh = mesh
	puddle.position = center + Vector3(0.0, 0.07, 0.0)
	puddle.material_override = _make_emissive_material(Color(0.08, 0.42, 0.12, 0.72), 0.22)
	add_child(puddle)


func _build_crypt_landmark(center: Vector3, color: Color) -> void:
	_add_box(center + Vector3(0.0, 0.42, 0.0), Vector3(7.5, 0.85, 6.2), Color(0.13, 0.12, 0.12))
	_add_box(center + Vector3(0.0, 1.7, -1.4), Vector3(5.2, 2.4, 2.6), Color(0.18, 0.16, 0.13))
	_add_box(center + Vector3(0.0, 3.15, -1.4), Vector3(5.8, 0.5, 3.1), Color(0.23, 0.19, 0.13))
	for x in [-3.4, 3.4]:
		_add_column(center + Vector3(x, 1.55, 2.2), 0.36, 3.1, color)


func _add_box(center: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = center
	add_child(body)
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _make_material(color, 0.82)
	body.add_child(node)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)


func _add_column(center: Vector3, radius: float, height: float, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = center
	add_child(body)
	var marker := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.2
	mesh.height = height
	mesh.radial_segments = 8
	marker.mesh = mesh
	marker.material_override = _make_material(color, 0.82)
	body.add_child(marker)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius * 1.2
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)


func _add_tree(center: Vector3, scale: float, color: Color) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18 * scale
	trunk_mesh.bottom_radius = 0.28 * scale
	trunk_mesh.height = 1.8 * scale
	trunk.mesh = trunk_mesh
	trunk.position = center + Vector3.UP * (0.9 * scale)
	trunk.material_override = _make_material(Color(0.18, 0.10, 0.045), 0.9)
	add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := CylinderMesh.new()
	crown_mesh.bottom_radius = 1.05 * scale
	crown_mesh.top_radius = 0.0
	crown_mesh.height = 2.2 * scale
	crown_mesh.radial_segments = 9
	crown.mesh = crown_mesh
	crown.position = center + Vector3.UP * (2.55 * scale)
	crown.material_override = _make_material(color, 0.92)
	add_child(crown)


func _make_material(color: Color, roughness := 0.88) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_material(color, 0.72)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
