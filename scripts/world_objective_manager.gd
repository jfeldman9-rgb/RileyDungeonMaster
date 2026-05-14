extends Node3D
class_name WorldObjectiveManager

@export var player_path: NodePath
@export var ui_path: NodePath
@export var collect_radius := 2.2

const SEAL_DEFS := {
	"library": {"name": "Moon Library Seal", "position": Vector3(-62.0, 1.0, -34.0), "color": Color(0.35, 0.55, 1.0)},
	"garden": {"name": "Poison Garden Seal", "position": Vector3(58.0, 1.0, -26.0), "color": Color(0.38, 1.0, 0.28)},
	"crypt": {"name": "Crown Crypt Seal", "position": Vector3(-32.0, 1.0, -86.0), "color": Color(1.0, 0.75, 0.25)}
}

const REGION_POINTS := [
	{"name": "Starting Clearing", "position": Vector3(0.0, 0.0, 14.0), "radius": 24.0},
	{"name": "Broken Courtyard", "position": Vector3(4.0, 0.0, -38.0), "radius": 24.0},
	{"name": "Moon Library", "position": Vector3(-62.0, 0.0, -34.0), "radius": 24.0},
	{"name": "Poison Garden", "position": Vector3(58.0, 0.0, -26.0), "radius": 24.0},
	{"name": "Old Stone Bridge", "position": Vector3(2.0, 0.0, -72.0), "radius": 18.0},
	{"name": "Crown Crypt", "position": Vector3(-32.0, 0.0, -86.0), "radius": 24.0},
	{"name": "Kenzie Tower Approach", "position": Vector3(22.0, 0.0, -104.0), "radius": 28.0}
]

var player: Node3D
var ui: Node
var state: Node
var pickups: Dictionary = {}
var gate: Node3D
var tower_reached := false
var current_region := ""


func _ready() -> void:
	player = get_node_or_null(player_path) as Node3D
	ui = get_node_or_null(ui_path)
	if has_node("/root/GameState"):
		state = get_node("/root/GameState")
		if state.has_method("reset_run"):
			state.call("reset_run")
	_build_seal_pickups()
	_build_distant_kenzie_tower()
	_build_kenzie_gate()


func _process(delta: float) -> void:
	if not player:
		return
	for seal_id in pickups.keys():
		var pickup := pickups[seal_id] as Node3D
		if not is_instance_valid(pickup) or not pickup.visible:
			continue
		pickup.rotate_y(delta * 1.8)
		pickup.position.y = 1.0 + sin(Time.get_ticks_msec() * 0.004 + float(hash(seal_id) % 100)) * 0.18
		if pickup.global_position.distance_to(player.global_position) <= collect_radius:
			_collect_seal(str(seal_id), pickup)
	_update_region_label()
	_check_tower_reached()


func _build_seal_pickups() -> void:
	for seal_id in SEAL_DEFS:
		var def: Dictionary = SEAL_DEFS[seal_id]
		var pickup := Node3D.new()
		pickup.name = "%sSealPickup" % str(seal_id).capitalize()
		pickup.position = def["position"] as Vector3
		add_child(pickup)

		var orb := MeshInstance3D.new()
		var orb_mesh := SphereMesh.new()
		orb_mesh.radius = 0.55
		orb_mesh.height = 1.1
		orb.mesh = orb_mesh
		orb.material_override = _make_emissive_material(def["color"] as Color, 1.25)
		pickup.add_child(orb)

		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.85
		ring_mesh.outer_radius = 0.94
		ring_mesh.ring_segments = 32
		ring.mesh = ring_mesh
		ring.rotation_degrees.x = 90.0
		ring.material_override = _make_emissive_material(def["color"] as Color, 0.75)
		pickup.add_child(ring)
		pickups[seal_id] = pickup


func _build_kenzie_gate() -> void:
	gate = Node3D.new()
	gate.name = "KenzieTowerGate"
	gate.position = Vector3(22.0, 0.0, -92.0)
	add_child(gate)
	for x in [-2.4, -1.2, 0.0, 1.2, 2.4]:
		var bar := StaticBody3D.new()
		bar.position = Vector3(x, 1.75, 0.0)
		gate.add_child(bar)
		var mesh_node := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.12
		mesh.bottom_radius = 0.14
		mesh.height = 3.5
		mesh.radial_segments = 8
		mesh_node.mesh = mesh
		mesh_node.material_override = _make_emissive_material(Color(0.65, 0.22, 0.95), 0.28)
		bar.add_child(mesh_node)
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = 0.16
		cylinder.height = 3.5
		shape.shape = cylinder
		bar.add_child(shape)
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(6.2, 0.42, 0.55)
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(0.0, 3.55, 0.0)
	lintel.material_override = _make_emissive_material(Color(0.45, 0.16, 0.72), 0.35)
	gate.add_child(lintel)


func _build_distant_kenzie_tower() -> void:
	var tower := Node3D.new()
	tower.name = "DistantKenzieTower"
	tower.position = Vector3(22.0, 0.0, -108.0)
	add_child(tower)
	_add_box(tower, Vector3(0.0, 0.5, 0.0), Vector3(15.0, 1.0, 15.0), Color(0.18, 0.15, 0.20))
	_add_box(tower, Vector3(0.0, 2.1, 0.0), Vector3(9.0, 3.2, 8.0), Color(0.24, 0.20, 0.28))
	_add_box(tower, Vector3(0.0, 5.2, -1.5), Vector3(5.4, 3.4, 4.6), Color(0.18, 0.14, 0.23))
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		_add_column(tower, Vector3(cos(angle) * 7.2, 2.5, sin(angle) * 7.2), 0.34, 5.0, Color(0.46, 0.22, 0.72))
	var kenzie := MeshInstance3D.new()
	var kenzie_mesh := CapsuleMesh.new()
	kenzie_mesh.radius = 0.55
	kenzie_mesh.height = 2.0
	kenzie.mesh = kenzie_mesh
	kenzie.position = Vector3(0.0, 7.4, -1.5)
	kenzie.material_override = _make_emissive_material(Color(0.65, 0.2, 0.95), 1.1)
	tower.add_child(kenzie)
	var shield := MeshInstance3D.new()
	var shield_mesh := TorusMesh.new()
	shield_mesh.inner_radius = 1.4
	shield_mesh.outer_radius = 1.48
	shield_mesh.ring_segments = 48
	shield.mesh = shield_mesh
	shield.rotation_degrees.x = 90.0
	shield.position = kenzie.position
	shield.material_override = _make_emissive_material(Color(0.3, 1.0, 0.34), 1.35)
	tower.add_child(shield)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 7.5, -1.5)
	light.light_color = Color(0.75, 0.28, 1.0)
	light.light_energy = 3.4
	light.omni_range = 42.0
	tower.add_child(light)


func _add_box(parent: Node, center: Vector3, size: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = center
	node.material_override = _make_emissive_material(color, 0.08)
	parent.add_child(node)


func _add_column(parent: Node, center: Vector3, radius: float, height: float, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.22
	mesh.height = height
	mesh.radial_segments = 8
	node.mesh = mesh
	node.position = center
	node.material_override = _make_emissive_material(color, 0.1)
	parent.add_child(node)


func _collect_seal(seal_id: String, pickup: Node3D) -> void:
	pickup.visible = false
	if state and state.has_method("collect_seal"):
		state.call("collect_seal", seal_id)
	if state and state.has_method("seal_count") and int(state.call("seal_count")) >= 3:
		_open_gate()
	elif ui:
		ui.set_objective_hint("Find the remaining dungeon seals. Kenzie Tower is still locked.")


func _open_gate() -> void:
	if gate and gate.visible:
		gate.visible = false
	if ui:
		ui.set_objective_hint("Kenzie Tower is open. Reach the raised platform.")


func _check_tower_reached() -> void:
	if tower_reached:
		return
	var has_all_seals := state and state.has_method("seal_count") and int(state.call("seal_count")) >= 3
	if not has_all_seals:
		return
	if player.global_position.distance_to(Vector3(22.0, player.global_position.y, -108.0)) > 8.0:
		return
	tower_reached = true
	if ui:
		ui.show_message("KENZIE TOWER", "Boss arena hook reached. Next migration: full shield fight.")
		ui.set_objective_hint("Prototype milestone reached: Kenzie fight handoff point.")


func _update_region_label() -> void:
	var best_name := "Open Valley"
	var best_dist := INF
	for region in REGION_POINTS:
		var pos: Vector3 = region["position"] as Vector3
		var dist := Vector2(player.global_position.x - pos.x, player.global_position.z - pos.z).length()
		if dist < float(region["radius"]) and dist < best_dist:
			best_dist = dist
			best_name = str(region["name"])
	if best_name == current_region:
		return
	current_region = best_name
	if state and state.has_method("discover_region"):
		state.call("discover_region", best_name)
	if ui and ui.has_method("set_region_name"):
		ui.call("set_region_name", best_name)


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.42
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
