extends Control
class_name UIManager

@export var state_path: NodePath

var state: GlobalState


func _ready() -> void:
	state = get_node_or_null(state_path) as GlobalState
	if state:
		state.score_changed.connect(_on_score_changed)
		state.player_damaged.connect(_on_player_damaged)


func show_message(_title: String, _subtitle: String = "") -> void:
	pass


func set_objective_hint(_text: String) -> void:
	pass


func _on_score_changed(_new_score: int) -> void:
	pass


func _on_player_damaged(_new_health: int) -> void:
	pass
