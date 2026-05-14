extends Node
class_name LODManager

@export var camera_path: NodePath
@export var near_distance := 28.0
@export var far_distance := 70.0

var camera: Camera3D
var tracked_nodes: Array[Node3D] = []


func _ready() -> void:
	camera = get_node_or_null(camera_path) as Camera3D


func register(node: Node3D) -> void:
	if node not in tracked_nodes:
		tracked_nodes.append(node)


func unregister(node: Node3D) -> void:
	tracked_nodes.erase(node)


func _process(_delta: float) -> void:
	if not camera:
		return
	for node in tracked_nodes:
		if not is_instance_valid(node):
			continue
		var distance := camera.global_position.distance_to(node.global_position)
		node.visible = distance <= far_distance
		if node is MeshInstance3D:
			(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if distance <= near_distance else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
