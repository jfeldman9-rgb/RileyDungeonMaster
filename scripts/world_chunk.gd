extends Node3D
class_name WorldChunk

@export var chunk_size := 48.0
@export var chunk_coord := Vector2i.ZERO
@export var seed := 1337

var generated := false


func generate(coord: Vector2i, size: float, world_seed: int = 1337) -> void:
	chunk_coord = coord
	chunk_size = size
	seed = world_seed
	position = Vector3(coord.x * size, 0.0, coord.y * size)
	if generated:
		return
	generated = true
	_build_terrain()
	_build_landmark_markers()


func _build_terrain() -> void:
	var terrain := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(chunk_size, chunk_size)
	terrain.mesh = mesh
	terrain.rotation_degrees.x = -90.0
	terrain.material_override = _make_material(Color(0.055, 0.095, 0.06))
	add_child(terrain)


func _build_landmark_markers() -> void:
	var chunk_hash: int = abs(hash(str(chunk_coord) + str(seed)))
	if chunk_hash % 5 != 0:
		return
	var marker := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.34
	mesh.height = 2.2
	mesh.radial_segments = 8
	marker.mesh = mesh
	marker.position = Vector3(0.0, 1.1, 0.0)
	marker.material_override = _make_material(Color(0.25, 0.22, 0.18))
	add_child(marker)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material
