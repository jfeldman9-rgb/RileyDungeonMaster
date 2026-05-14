extends Node
class_name EnemyManager

signal enemy_spawned(enemy: Node3D)
signal enemy_removed(enemy: Node3D)

@export var max_active_enemies := 12
@export var spawn_radius := 28.0
@export var despawn_radius := 60.0
@export var player_path: NodePath
@export var world_path: NodePath
@export var pool_path: NodePath
@export var spawn_interval := 2.8
@export var active := false

var active_enemies: Array[Node3D] = []
var spawn_zones: Array[Area3D] = []
var player: Node3D
var world: Node3D
var pool: Node
var spawn_timer := 0.0


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
	cull_far_enemies()


func register_enemy(enemy: Node3D) -> void:
	if enemy in active_enemies:
		return
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


func make_placeholder_enemy() -> Node3D:
	var enemy := Node3D.new()
	enemy.name = "PooledEnemyPlaceholder"
	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.42
	mesh.height = 0.84
	body.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.52, 0.16)
	material.emission_enabled = true
	material.emission = Color(0.08, 0.35, 0.08)
	material.emission_energy_multiplier = 0.35
	body.material_override = material
	body.position.y = 0.5
	enemy.add_child(body)
	return enemy


func random_point_near(center: Vector3, radius: float) -> Vector3:
	var angle := randf() * TAU
	var r := randf() * radius
	return center + Vector3(cos(angle) * r, 0.0, sin(angle) * r)
