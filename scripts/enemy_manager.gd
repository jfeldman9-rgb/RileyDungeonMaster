extends Node
class_name EnemyManager

const BROCCOLI_BRUTE := preload("res://assets/generated/broccoli_brute_scary.png")
const BROCCOLI_RUNNER := preload("res://assets/generated/broccoli_runner_scary.png")
const BROCCOLI_CASTER := preload("res://assets/generated/broccoli_caster_scary.png")
const BROCCOLI_KNIGHT := preload("res://assets/generated/broccoli_knight_scary.png")
const BROCCOLI_A := preload("res://assets/generated/broccoli_a.png")
const BROCCOLI_B := preload("res://assets/generated/broccoli_b.png")
const BROCCOLI_C := preload("res://assets/generated/broccoli_c.png")

signal enemy_spawned(enemy: Node3D)
signal enemy_removed(enemy: Node3D)
signal broccoli_projectile_fired(position: Vector3)

@export var max_active_enemies := 12
@export var spawn_radius := 28.0
@export var despawn_radius := 60.0
@export var player_path: NodePath
@export var world_path: NodePath
@export var pool_path: NodePath
@export var spawn_interval := 2.8
@export var enemy_move_speed := 2.2
@export var enemy_agro_radius := 34.0
@export var contact_damage_cooldown := 1.2
@export var active := false

var active_enemies: Array[Node3D] = []
var spawn_zones: Array[Area3D] = []
var player: Node3D
var world: Node3D
var pool: Node
var spawn_timer := 0.0
var active_projectiles: Array[Node3D] = []


func _ready() -> void:
	player = get_node_or_null(player_path) as Node3D
	world = get_node_or_null(world_path) as Node3D
	pool = get_node_or_null(pool_path)
	for child in get_children():
		if child is Area3D:
			spawn_zones.append(child)
	if pool:
		pool.prewarm("broccoli_enemy", make_placeholder_enemy, mini(max_active_enemies, 8))


func _process(delta: float) -> void:
	if not active or not player:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		try_spawn_from_nearby_zone()
	update_enemy_motion(delta)
	update_projectiles(delta)
	cull_far_enemies()


func register_enemy(enemy: Node3D) -> void:
	if enemy in active_enemies:
		return
	enemy.add_to_group("enemy")
	active_enemies.append(enemy)
	enemy_spawned.emit(enemy)


func remove_enemy(enemy: Node3D) -> void:
	active_enemies.erase(enemy)
	enemy_removed.emit(enemy)
	if is_instance_valid(enemy):
		if pool:
			pool.release("broccoli_enemy", enemy)
		else:
			enemy.queue_free()


func active_count() -> int:
	return active_enemies.size()


func try_spawn_from_nearby_zone() -> void:
	if active_enemies.size() >= max_active_enemies:
		return
	var zone := nearest_spawn_zone()
	if not zone:
		return
	var enemy := (pool.acquire("broccoli_enemy", make_placeholder_enemy) as Node3D) if pool else make_placeholder_enemy()
	var parent := world if world else get_tree().current_scene
	if enemy.get_parent():
		enemy.reparent(parent)
	else:
		parent.add_child(enemy)
	enemy.global_position = random_point_near(zone.global_position, 3.5)
	_configure_enemy_for_zone(enemy, zone.name)
	register_enemy(enemy)


func nearest_spawn_zone() -> Area3D:
	var best: Area3D
	var best_dist := INF
	for zone in spawn_zones:
		if not is_instance_valid(zone):
			continue
		var d := zone.global_position.distance_to(player.global_position)
		if d < spawn_radius and d < best_dist:
			best = zone
			best_dist = d
	return best


func cull_far_enemies() -> void:
	for i in range(active_enemies.size() - 1, -1, -1):
		var enemy := active_enemies[i]
		if not is_instance_valid(enemy):
			active_enemies.remove_at(i)
			continue
		if enemy.global_position.distance_to(player.global_position) > despawn_radius:
			remove_enemy(enemy)


func update_enemy_motion(delta: float) -> void:
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			continue
		var to_player := player.global_position - enemy.global_position
		to_player.y = 0.0
		var attack_cooldown := float(enemy.get_meta("attack_cooldown", 0.0))
		if attack_cooldown > 0.0:
			enemy.set_meta("attack_cooldown", maxf(0.0, attack_cooldown - delta))
		if to_player.length() <= 1.1 and attack_cooldown <= 0.0:
			_damage_player()
			enemy.set_meta("attack_cooldown", contact_damage_cooldown)
		if to_player.length() > enemy_agro_radius or to_player.length() < 0.1:
			continue
		if bool(enemy.get_meta("can_shoot", false)):
			var shoot_cooldown := float(enemy.get_meta("shoot_cooldown", 0.0))
			if shoot_cooldown > 0.0:
				enemy.set_meta("shoot_cooldown", maxf(0.0, shoot_cooldown - delta))
			elif to_player.length() <= 18.0:
				enemy.set_meta("shoot_cooldown", randf_range(2.1, 3.4))
				_spawn_broccoli_projectile(enemy.global_position + Vector3.UP * 1.15, player.global_position + Vector3.UP * 0.75)
		var dir := to_player.normalized()
		var speed := float(enemy.get_meta("move_speed", enemy_move_speed))
		enemy.global_position += dir * speed * delta
		enemy.rotation.y = lerp_angle(enemy.rotation.y, atan2(dir.x, dir.z), minf(1.0, 9.0 * delta))


func update_projectiles(delta: float) -> void:
	for i in range(active_projectiles.size() - 1, -1, -1):
		var projectile := active_projectiles[i]
		if not is_instance_valid(projectile):
			active_projectiles.remove_at(i)
			continue
		var life := float(projectile.get_meta("life", 0.0)) - delta
		projectile.set_meta("life", life)
		var velocity := projectile.get_meta("velocity", Vector3.ZERO) as Vector3
		projectile.global_position += velocity * delta
		projectile.rotate_y(delta * 5.5)
		projectile.rotate_z(delta * 4.0)
		if player and projectile.global_position.distance_to(player.global_position + Vector3.UP * 0.7) <= 0.72:
			_damage_player()
			_remove_projectile(projectile, i)
			continue
		if life <= 0.0 or (player and projectile.global_position.distance_to(player.global_position) > despawn_radius):
			_remove_projectile(projectile, i)


func _remove_projectile(projectile: Node3D, index: int) -> void:
	active_projectiles.remove_at(index)
	if is_instance_valid(projectile):
		projectile.queue_free()


func _spawn_broccoli_projectile(origin: Vector3, target: Vector3) -> void:
	var projectile := Node3D.new()
	projectile.name = "BroccoliProjectile"
	var sprite := Sprite3D.new()
	var textures := [BROCCOLI_A, BROCCOLI_B, BROCCOLI_C]
	sprite.texture = textures[randi() % textures.size()]
	sprite.pixel_size = 0.009
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.modulate = Color(0.9, 1.0, 0.72, 0.95)
	projectile.add_child(sprite)
	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.22
	core_mesh.height = 0.36
	core_mesh.radial_segments = 8
	core_mesh.rings = 4
	core.mesh = core_mesh
	core.material_override = _make_enemy_material(Color(0.15, 0.48, 0.12), Color(0.1, 0.55, 0.08), 0.65)
	projectile.add_child(core)
	var light := OmniLight3D.new()
	light.light_color = Color(0.36, 1.0, 0.24)
	light.light_energy = 0.45
	light.omni_range = 3.8
	projectile.add_child(light)
	var dir := (target - origin).normalized()
	projectile.global_position = origin
	projectile.set_meta("velocity", dir * randf_range(7.0, 9.5))
	projectile.set_meta("life", 3.2)
	var parent := world if world else get_tree().current_scene
	parent.add_child(projectile)
	active_projectiles.append(projectile)
	broccoli_projectile_fired.emit(origin)


func _damage_player() -> void:
	if has_node("/root/GameState"):
		var state := get_node("/root/GameState")
		if state.has_method("damage_player"):
			state.call("damage_player", 1)


func make_placeholder_enemy() -> Node3D:
	var enemy := Node3D.new()
	enemy.name = "PooledEnemyPlaceholder"
	var shadow := MeshInstance3D.new()
	shadow.name = "MonsterContactShadow"
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.56
	shadow_mesh.bottom_radius = 0.56
	shadow_mesh.height = 0.012
	shadow_mesh.radial_segments = 18
	shadow.mesh = shadow_mesh
	shadow.position.y = 0.025
	shadow.scale = Vector3(1.15, 1.0, 0.72)
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.32)
	shadow.material_override = shadow_mat
	enemy.add_child(shadow)
	var stalk_mat := _make_enemy_material(Color(0.36, 0.42, 0.16), Color(0.08, 0.18, 0.04), 0.22)
	var floret_mat := _make_enemy_material(Color(0.12, 0.42, 0.13), Color(0.02, 0.22, 0.04), 0.42)

	for i in range(3):
		var leg := MeshInstance3D.new()
		leg.name = "MonsterLeg%d" % i
		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.07
		leg_mesh.bottom_radius = 0.1
		leg_mesh.height = 0.62
		leg_mesh.radial_segments = 7
		leg.mesh = leg_mesh
		var angle := TAU * float(i) / 3.0
		leg.position = Vector3(cos(angle) * 0.22, 0.32, sin(angle) * 0.22)
		leg.rotation_degrees = Vector3(14.0, rad_to_deg(angle), 0.0)
		leg.material_override = stalk_mat
		enemy.add_child(leg)

	var body := MeshInstance3D.new()
	body.name = "MonsterCore"
	var mesh := SphereMesh.new()
	mesh.radius = 0.46
	mesh.height = 0.72
	mesh.radial_segments = 12
	mesh.rings = 6
	body.mesh = mesh
	body.material_override = floret_mat
	body.position.y = 0.82
	enemy.add_child(body)

	for i in range(6):
		var bulb := MeshInstance3D.new()
		bulb.name = "MonsterFloret%d" % i
		var bulb_mesh := SphereMesh.new()
		bulb_mesh.radius = 0.18 + float(i % 3) * 0.035
		bulb_mesh.height = bulb_mesh.radius * 1.7
		bulb_mesh.radial_segments = 9
		bulb_mesh.rings = 5
		bulb.mesh = bulb_mesh
		var angle := TAU * float(i) / 6.0
		bulb.position = Vector3(cos(angle) * 0.34, 1.0 + sin(float(i) * 1.4) * 0.13, sin(angle) * 0.26)
		bulb.material_override = floret_mat
		enemy.add_child(bulb)

	var eye_mat := _make_enemy_material(Color(0.95, 0.95, 0.7), Color(0.75, 1.0, 0.22), 1.2)
	for x in [-0.13, 0.13]:
		var eye := MeshInstance3D.new()
		eye.name = "MonsterEye"
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.045
		eye_mesh.height = 0.09
		eye_mesh.radial_segments = 8
		eye_mesh.rings = 4
		eye.mesh = eye_mesh
		eye.position = Vector3(x, 0.88, -0.42)
		eye.material_override = eye_mat
		enemy.add_child(eye)

	var card := Sprite3D.new()
	card.name = "MonsterCard"
	card.texture = BROCCOLI_BRUTE
	card.pixel_size = 0.0042
	card.position = Vector3(0.0, 1.2, 0.12)
	card.modulate = Color(1, 1, 1, 0.72)
	card.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	enemy.add_child(card)
	var glow := OmniLight3D.new()
	glow.name = "MonsterGlow"
	glow.position.y = 0.9
	glow.light_color = Color(0.25, 0.8, 0.24)
	glow.light_energy = 0.4
	glow.omni_range = 3.4
	enemy.add_child(glow)
	return enemy


func _make_enemy_material(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.66
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material


func _configure_enemy_for_zone(enemy: Node3D, zone_name: String) -> void:
	var color := Color(0.18, 0.52, 0.16)
	var emission := Color(0.08, 0.35, 0.08)
	var texture := BROCCOLI_BRUTE
	var scale := 1.0
	var speed := enemy_move_speed
	if "Garden" in zone_name:
		color = Color(0.7, 0.18, 0.1)
		emission = Color(0.45, 0.08, 0.02)
		texture = BROCCOLI_RUNNER
		scale = 0.82
		speed = enemy_move_speed * 1.35
	elif "Library" in zone_name:
		color = Color(0.16, 0.28, 0.74)
		emission = Color(0.06, 0.14, 0.55)
		texture = BROCCOLI_CASTER
		scale = 0.95
		speed = enemy_move_speed * 0.88
	elif "Crypt" in zone_name or "Tower" in zone_name:
		color = Color(0.33, 0.24, 0.12)
		emission = Color(0.35, 0.2, 0.04)
		texture = BROCCOLI_KNIGHT
		scale = 1.35
		speed = enemy_move_speed * 0.7
	enemy.scale = Vector3.ONE * scale
	enemy.set_meta("move_speed", speed)
	enemy.set_meta("can_shoot", "Library" in zone_name or "Tower" in zone_name)
	enemy.set_meta("shoot_cooldown", randf_range(0.8, 2.4))
	var body := enemy.find_child("*", false, false) as MeshInstance3D
	if body:
		var material := body.material_override as StandardMaterial3D
		if material:
			material = material.duplicate()
			material.albedo_color = color
			material.emission = emission
			body.material_override = material
	var card := enemy.find_child("MonsterCard", false, false) as Sprite3D
	if card:
		card.texture = texture
		card.pixel_size = 0.0046 / scale
	var glow := enemy.find_child("MonsterGlow", false, false) as OmniLight3D
	if glow:
		glow.light_color = emission.lightened(0.45)
		glow.light_energy = 0.34 + scale * 0.18


func random_point_near(center: Vector3, radius: float) -> Vector3:
	var angle := randf() * TAU
	var r := randf() * radius
	return center + Vector3(cos(angle) * r, 0.0, sin(angle) * r)
