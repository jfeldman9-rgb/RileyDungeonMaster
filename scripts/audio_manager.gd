extends Node
class_name AudioManager

@export var music_player_path: NodePath
@export var combat_player_path: NodePath
@export var fade_speed := 4.0

var music_player: AudioStreamPlayer
var combat_player: AudioStreamPlayer
var combat_intensity := 0.0


func _ready() -> void:
	music_player = get_node_or_null(music_player_path) as AudioStreamPlayer
	combat_player = get_node_or_null(combat_player_path) as AudioStreamPlayer


func set_combat_active(active: bool) -> void:
	combat_intensity = 1.0 if active else 0.0


func _process(delta: float) -> void:
	if combat_player:
		var target_db := -10.0 if combat_intensity > 0.5 else -80.0
		combat_player.volume_db = lerpf(combat_player.volume_db, target_db, minf(1.0, fade_speed * delta))


func play_landmark_sound(stream: AudioStream, at: Node3D) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.unit_size = 8.0
	player.max_distance = 42.0
	at.add_child(player)
	player.play()
	return player
