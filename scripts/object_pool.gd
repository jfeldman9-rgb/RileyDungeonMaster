extends Node
class_name ObjectPool

var pools: Dictionary = {}


func prewarm(key: String, factory: Callable, count: int) -> void:
	if not pools.has(key):
		pools[key] = []
	for i in range(count):
		var node := factory.call() as Node
		node.process_mode = Node.PROCESS_MODE_DISABLED
		_set_node_visible(node, false)
		add_child(node)
		pools[key].append(node)


func acquire(key: String, factory: Callable) -> Node:
	if not pools.has(key):
		pools[key] = []
	var pool: Array = pools[key]
	var node: Node = pool.pop_back() if pool.size() > 0 else factory.call()
	if node.get_parent() != self:
		add_child(node)
	node.process_mode = Node.PROCESS_MODE_INHERIT
	_set_node_visible(node, true)
	return node


func release(key: String, node: Node) -> void:
	if not pools.has(key):
		pools[key] = []
	node.process_mode = Node.PROCESS_MODE_DISABLED
	_set_node_visible(node, false)
	if node.get_parent() != self:
		node.reparent(self)
	pools[key].append(node)


func _set_node_visible(node: Node, is_visible: bool) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visible = is_visible
	elif node is Node3D:
		(node as Node3D).visible = is_visible
