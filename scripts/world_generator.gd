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
@export var max_chunk_loads_per_refresh := 4
@export var lod_manager_path: NodePath

var loaded_chunks: Dictionary = {}
var pending_loads: Array[Vector2i] = []
var active_chunks_container: Node3D
var player: Node3D
var lod_manager: Node
var current_chunk := Vector2i(999999, 999999)


func _ready() -> void:
	active_chunks_container = Node3D.new()
	active_chunks_container.name = "ActiveChunks"
	add_child(active_chunks_container)
	player = get_node_or_null(player_path) as Node3D
	lod_manager = get_node_or_null(lod_manager_path)
	if active:
		_refresh_chunks()


func _process(_delta: float) -> void:
	if not active:
		return
	var next_chunk := world_to_chunk(player.global_position if player else Vector3.ZERO)
	if next_chunk != current_chunk:
		current_chunk = next_chunk
		_refresh_chunks()
	elif pending_loads.size() > 0:
		_process_pending_loads()


func world_to_chunk(world_position: Vector3) -> Vector2i:
	return Vector2i(floori(world_position.x / chunk_size), floori(world_position.z / chunk_size))


func _refresh_chunks() -> void:
	var center := world_to_chunk(player.global_position if player else Vector3.ZERO)
	var desired: Dictionary = {}
	for x in range(center.x - load_radius, center.x + load_radius + 1):
		for y in range(center.y - load_radius, center.y + load_radius + 1):
			var coord := Vector2i(x, y)
			desired[coord] = true
			if not loaded_chunks.has(coord) and coord not in pending_loads:
				pending_loads.append(coord)
	_process_pending_loads()
	for coord in loaded_chunks.keys():
		var c: Vector2i = coord
		if abs(c.x - center.x) > unload_radius or abs(c.y - center.y) > unload_radius:
			_unload_chunk(c)


func _process_pending_loads() -> void:
	var loads_this_refresh := mini(max_chunk_loads_per_refresh, pending_loads.size())
	for i in range(loads_this_refresh):
		_load_chunk(pending_loads.pop_front())


func _load_chunk(coord: Vector2i) -> void:
	if loaded_chunks.has(coord):
		return
	var chunk = WorldChunkScript.new()
	chunk.name = "Chunk_%s_%s" % [coord.x, coord.y]
	active_chunks_container.add_child(chunk)
	chunk.generate(coord, chunk_size, world_seed)
	if lod_manager and lod_manager.has_method("register"):
		lod_manager.call("register", chunk)
	_fade_chunk_in(chunk)
	loaded_chunks[coord] = chunk


func _unload_chunk(coord: Vector2i) -> void:
	var chunk := loaded_chunks.get(coord) as Node3D
	loaded_chunks.erase(coord)
	if is_instance_valid(chunk):
		if lod_manager and lod_manager.has_method("unregister"):
			lod_manager.call("unregister", chunk)
		_fade_chunk_out(chunk)


func _fade_chunk_in(chunk: Node3D) -> void:
	chunk.scale = Vector3(1.0, 0.02, 1.0)
	var tween := create_tween()
	tween.tween_property(chunk, "scale", Vector3.ONE, fade_transition_time).set_trans(Tween.TRANS_SINE)


func _fade_chunk_out(chunk: Node3D) -> void:
	var tween := create_tween()
	tween.tween_property(chunk, "scale", Vector3(1.0, 0.02, 1.0), fade_transition_time).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(chunk.queue_free)
