extends Node3D
class_name WorldObjectiveManager

const KENZIE_FRONT := preload("res://assets/generated/kenzie_front.png")
const BROCCOLI_SHIELD := preload("res://assets/generated/broccoli_shield.png")
const STONE_TILE_A := preload("res://assets/generated/stone_tile_a.png")
const STONE_TILE_B := preload("res://assets/generated/stone_tile_b.png")

@export var player_path: NodePath
@export var ui_path: NodePath
@export var collect_radius := 2.2

signal seal_pickup_collected(seal_id: String)
signal kenzie_shield_hit(remaining: int)
signal kenzie_saved

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
var boss_active := false
var boss_shield_hp := 5
var kenzie_avatar: Node3D
var kenzie_shield: Node3D
var kenzie_shield_visuals: Array[Node3D] = []
var water_segments: Array[MeshInstance3D] = []


func _ready() -> void:
	player = get_node_or_null(player_path) as Node3D
	if player and player.has_signal("slice_requested"):
		player.slice_requested.connect(_on_player_slice)
	ui = get_node_or_null(ui_path)
	if has_node("/root/GameState"):
		state = get_node("/root/GameState")
		if state.has_method("reset_run"):
			state.call("reset_run")
		if state.has_signal("player_died"):
			state.player_died.connect(_on_player_died)
	_build_valley_backdrop()
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
	_update_boss_visuals(delta)
	_update_water(delta)


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
		_add_seal_beacon(pickup, def["color"] as Color)
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
	for step in range(9):
		_add_box(tower, Vector3(0.0, 0.16 + float(step) * 0.09, 11.5 - float(step) * 1.25), Vector3(8.8 - float(step) * 0.28, 0.28, 1.1), Color(0.22, 0.18, 0.23))
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
	kenzie_avatar = kenzie
	var kenzie_sprite := Sprite3D.new()
	kenzie_sprite.name = "KenziePaintedDetail"
	kenzie_sprite.texture = KENZIE_FRONT
	kenzie_sprite.pixel_size = 0.006
	kenzie_sprite.position = Vector3(0.0, 7.55, -1.78)
	kenzie_sprite.modulate = Color(1, 1, 1, 0.9)
	kenzie_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	tower.add_child(kenzie_sprite)
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
	kenzie_shield = shield
	kenzie_shield_visuals.append(shield)
	var shield_sprite := Sprite3D.new()
	shield_sprite.name = "BroccoliShieldPaintedDetail"
	shield_sprite.texture = BROCCOLI_SHIELD
	shield_sprite.pixel_size = 0.009
	shield_sprite.position = kenzie.position
	shield_sprite.modulate = Color(0.8, 1.0, 0.75, 0.6)
	shield_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	tower.add_child(shield_sprite)
	kenzie_shield_visuals.append(shield_sprite)
	_add_kenzie_aura(tower)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 7.5, -1.5)
	light.light_color = Color(0.75, 0.28, 1.0)
	light.light_energy = 3.4
	light.omni_range = 42.0
	tower.add_child(light)
	var sky_spire := MeshInstance3D.new()
	var spire_mesh := CylinderMesh.new()
	spire_mesh.top_radius = 0.2
	spire_mesh.bottom_radius = 1.6
	spire_mesh.height = 15.0
	spire_mesh.radial_segments = 7
	sky_spire.mesh = spire_mesh
	sky_spire.position = Vector3(0.0, 14.2, -1.5)
	sky_spire.material_override = _make_emissive_material(Color(0.18, 0.08, 0.32), 0.18)
	tower.add_child(sky_spire)
	var beacon := OmniLight3D.new()
	beacon.position = Vector3(0.0, 15.5, -1.5)
	beacon.light_color = Color(0.85, 0.35, 1.0)
	beacon.light_energy = 4.8
	beacon.omni_range = 56.0
	tower.add_child(beacon)


func _add_kenzie_aura(parent: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "KenzieAura"
	particles.position = Vector3(0.0, 7.4, -1.5)
	particles.amount = 90
	particles.lifetime = 1.4
	particles.emitting = true
	particles.visibility_aabb = AABB(Vector3(-6, -4, -6), Vector3(12, 10, 12))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 1.5
	process.direction = Vector3(0, 1, 0)
	process.spread = 85.0
	process.initial_velocity_min = 0.4
	process.initial_velocity_max = 1.6
	process.gravity = Vector3(0, 0.25, 0)
	process.scale_min = 0.045
	process.scale_max = 0.12
	particles.process_material = process
	var mote_mesh := SphereMesh.new()
	mote_mesh.radius = 0.06
	mote_mesh.height = 0.12
	particles.draw_pass_1 = mote_mesh
	parent.add_child(particles)


func _add_seal_beacon(parent: Node3D, color: Color) -> void:
	var beam := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.38
	mesh.height = 9.0
	mesh.radial_segments = 18
	beam.mesh = mesh
	beam.position = Vector3.UP * 4.5
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, 0.24)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.72
	material.roughness = 0.5
	beam.material_override = material
	parent.add_child(beam)

	var halo := MeshInstance3D.new()
	var halo_mesh := TorusMesh.new()
	halo_mesh.inner_radius = 1.35
	halo_mesh.outer_radius = 1.48
	halo_mesh.ring_segments = 44
	halo.mesh = halo_mesh
	halo.position = Vector3.UP * 2.8
	halo.rotation_degrees.x = 90.0
	halo.material_override = _make_emissive_material(color, 0.9)
	parent.add_child(halo)

	var light := OmniLight3D.new()
	light.position = Vector3.UP * 3.2
	light.light_color = color
	light.light_energy = 1.9
	light.omni_range = 16.0
	parent.add_child(light)


func _build_valley_backdrop() -> void:
	var ring_radius := 118.0
	for i in range(30):
		var angle := TAU * float(i) / 30.0
		var radius := ring_radius + sin(float(i) * 1.73) * 16.0
		var height := 16.0 + float(i % 7) * 2.7
		var width := 9.0 + float(i % 5) * 2.1
		var mountain := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = width * 0.18
		mesh.bottom_radius = width
		mesh.height = height
		mesh.radial_segments = 5
		mountain.mesh = mesh
		mountain.position = Vector3(cos(angle) * radius, height * 0.5 - 1.0, sin(angle) * radius - 36.0)
		mountain.rotation_degrees.y = rad_to_deg(angle) + 18.0
		mountain.material_override = _make_emissive_material(Color(0.12, 0.13, 0.16).lerp(Color(0.22, 0.20, 0.24), float(i % 3) * 0.22), 0.02)
		add_child(mountain)
	_build_watercourse()


func _build_watercourse() -> void:
	for i in range(12):
		var water := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(7.0 + sin(float(i)) * 1.4, 0.035, 11.0)
		water.mesh = mesh
		water.position = Vector3(-22.0 + sin(float(i) * 0.7) * 8.0, 0.05, 24.0 - float(i) * 12.0)
		water.rotation_degrees.y = -18.0 + sin(float(i) * 0.9) * 18.0
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.08, 0.22, 0.32, 0.62)
		mat.roughness = 0.08
		mat.metallic = 0.3
		mat.emission_enabled = true
		mat.emission = Color(0.04, 0.18, 0.28)
		mat.emission_energy_multiplier = 0.16
		water.material_override = mat
		add_child(water)
		water.set_meta("base_y", water.position.y)
		water.set_meta("phase", float(i) * 0.8)
		water_segments.append(water)


func _update_water(_delta: float) -> void:
	var time := Time.get_ticks_msec() * 0.001
	for water in water_segments:
		if not is_instance_valid(water):
			continue
		var base_y := float(water.get_meta("base_y", 0.05))
		var phase := float(water.get_meta("phase", 0.0))
		water.position.y = base_y + sin(time * 1.7 + phase) * 0.018
		water.scale.x = 1.0 + sin(time * 0.9 + phase) * 0.025


func _add_box(parent: Node, center: Vector3, size: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = center
	node.material_override = _make_stone_material(color)
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
	node.material_override = _make_stone_material(color)
	parent.add_child(node)


func _collect_seal(seal_id: String, pickup: Node3D) -> void:
	pickup.visible = false
	seal_pickup_collected.emit(seal_id)
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
	boss_active = true
	boss_shield_hp = 5
	if ui:
		ui.show_message("KENZIE TOWER", "Break the broccoli shield.")
		ui.set_objective_hint("Boss prototype: slash Kenzie's shield five times.")


func _on_player_slice() -> void:
	if not boss_active or not player:
		return
	var tower_flat := Vector2(22.0, -108.0)
	var player_flat := Vector2(player.global_position.x, player.global_position.z)
	if player_flat.distance_to(tower_flat) > 11.0:
		return
	boss_shield_hp = maxi(0, boss_shield_hp - 1)
	kenzie_shield_hit.emit(boss_shield_hp)
	if ui:
		ui.show_message("SHIELD HIT", "%d/5 shield layers remain." % boss_shield_hp)
	if boss_shield_hp <= 0:
		boss_active = false
		kenzie_saved.emit()
		for visual in kenzie_shield_visuals:
			if is_instance_valid(visual):
				visual.visible = false
		if ui:
			ui.show_message("KENZIE SAVED", "Bubby, you saved me! Candy time.")
			ui.set_objective_hint("Prototype complete: final cutscene handoff ready.")
			if ui.has_method("show_story_card"):
				ui.call("show_story_card", "KENZIE SAVED", "The broccoli shield breaks apart in green sparks. Kenzie lowers her staff and smiles.\n\n\"Bubby, you saved me! Thank you, my ninja hero. Now let's go eat some candy!\"")


func _update_boss_visuals(delta: float) -> void:
	if kenzie_shield and kenzie_shield.visible:
		kenzie_shield.rotate_y(delta * (1.5 + float(5 - boss_shield_hp) * 0.55))
		kenzie_shield.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.06)
	for visual in kenzie_shield_visuals:
		if is_instance_valid(visual) and visual != kenzie_shield and visual.visible:
			visual.rotate_y(delta * (1.2 + float(5 - boss_shield_hp) * 0.4))
	if kenzie_avatar:
		kenzie_avatar.position.y = 7.4 + sin(Time.get_ticks_msec() * 0.003) * 0.18


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


func _make_stone_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color.lightened(0.08)
	var brightness := (color.r + color.g + color.b) / 3.0
	material.albedo_texture = STONE_TILE_A if brightness < 0.35 else STONE_TILE_B
	material.roughness = 0.76
	material.metallic = 0.02
	material.emission_enabled = true
	material.emission = color.darkened(0.25)
	material.emission_energy_multiplier = 0.035
	return material


func _on_player_died() -> void:
	if not player:
		return
	player.global_position = Vector3(0.0, 2.5, 14.0)
	if state and state.has_method("restore_player"):
		state.call("restore_player")
	if ui:
		ui.show_message("RETURNED TO CLEARING", "Kenzie is still waiting at the tower.")
		ui.set_objective_hint("Recover, then choose another route through the valley.")
