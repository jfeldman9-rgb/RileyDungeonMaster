extends Node
class_name EnemyManager

signal enemy_spawned(enemy: Node3D)
signal enemy_removed(enemy: Node3D)

@export var max_active_enemies := 12
@export var spawn_radius := 28.0
@export var despawn_radius := 60.0
@export var player_path: NodePath

var active_enemies: Array[Node3D] = []
var player: Node3D


func _ready() -> void:
	player = get_node_or_null(player_path) as Node3D


func register_enemy(enemy: Node3D) -> void:
	if enemy in active_enemies:
		return
	active_enemies.append(enemy)
	enemy_spawned.emit(enemy)


func remove_enemy(enemy: Node3D) -> void:
	active_enemies.erase(enemy)
	enemy_removed.emit(enemy)
	if is_instance_valid(enemy):
		enemy.queue_free()


func active_count() -> int:
	return active_enemies.size()
