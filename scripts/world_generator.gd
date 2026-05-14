extends Node3D
class_name WorldGenerator

const WorldChunkScript := preload("res://scripts/world_chunk.gd")

@export var active := false
@export var player_path: NodePath
@export var chunk_size := 48.0
@export var load_radius := 1
@export var unload_radius := 2
@export var fade_transition_time := 0.35
@export var world_seed := 1337

var loaded_chunks: Dictionary = {}
var active_chunks_container: Node3D
var player: Node3D
var current_chunk := Vector2i(999999, 999999)


func _ready() -> void:
	active_chunks_container = Node3D.new()
	active_chunks_container.name = "ActiveChunks"
	add_child(active_chunks_container)
	player = get_node_or_null(player_path) as Node3D
	if active:
		_refresh_chunks()


func _process(_delta: float) -> void:
	if not active:
		return
	var next_chunk := world_to_chunk(player.global_position if player else Vector3.ZERO)
	if next_chunk != current_chunk:
		current_chunk = next_chunk
		_refresh_chunks()


func world_to_chunk(world_position: Vector3) -> Vector2i:
	return Vector2i(floori(world_position.x / chunk_size), floori(world_position.z / chunk_size))


func _refresh_chunks() -> void:
	var center := world_to_chunk(player.global_position if player else Vector3.ZERO)
	for x in range(center.x - load_radius, center.x + load_radius + 1):
		for y in range(center.y - load_radius, center.y + load_radius + 1):
			_load_chunk(Vector2i(x, y))
	for coord in loaded_chunks.keys():
		var c: Vector2i = coord
		if abs(c.x - center.x) > unload_radius or abs(c.y - center.y) > unload_radius:
			_unload_chunk(c)


func _load_chunk(coord: Vector2i) -> void:
	if loaded_chunks.has(coord):
		return
	var chunk = WorldChunkScript.new()
	chunk.name = "Chunk_%s_%s" % [coord.x, coord.y]
	active_chunks_container.add_child(chunk)
	chunk.generate(coord, chunk_size, world_seed)
	loaded_chunks[coord] = chunk


func _unload_chunk(coord: Vector2i) -> void:
	var chunk := loaded_chunks.get(coord) as Node3D
	loaded_chunks.erase(coord)
	if is_instance_valid(chunk):
		chunk.queue_free()
