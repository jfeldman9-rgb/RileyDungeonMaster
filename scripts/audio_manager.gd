extends Node
class_name AudioManager

@export var music_player_path: NodePath
@export var combat_player_path: NodePath
@export var fade_speed := 4.0
@export var music_volume_db := -18.0
@export var combat_volume_db := -14.0
@export var sfx_volume_db := -6.0

var music_player: AudioStreamPlayer
var combat_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var enemy_manager: Node
var combat_intensity := 0.0
var connected_scene: Node


func _ready() -> void:
	music_player = get_node_or_null(music_player_path) as AudioStreamPlayer
	combat_player = get_node_or_null(combat_player_path) as AudioStreamPlayer
	if not music_player:
		music_player = _make_player("AdventureMusic", music_volume_db)
	if not combat_player:
		combat_player = _make_player("CombatLayer", -80.0)
	if not ambient_player:
		ambient_player = _make_player("ValleyAmbience", -25.0)
	if not sfx_player:
		sfx_player = _make_player("SfxPlayer", sfx_volume_db)
	music_player.stream = make_music_stream()
	combat_player.stream = make_combat_stream()
	ambient_player.stream = make_wind_stream()
	music_player.play()
	combat_player.play()
	ambient_player.play()
	call_deferred("_connect_scene_signals")


func _exit_tree() -> void:
	for player in [music_player, combat_player, ambient_player, sfx_player]:
		if player:
			player.stop()


func _make_player(player_name: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = volume_db
	add_child(player)
	return player


func _connect_scene_signals() -> void:
	var scene := get_tree().current_scene
	if not scene or scene == connected_scene:
		return
	connected_scene = scene
	var player := scene.get_node_or_null("RileyPlayer")
	if player:
		_connect_if_present(player, "slice_requested", Callable(self, "_on_slice"))
		_connect_if_present(player, "dash_requested", Callable(self, "_on_dash"))
		_connect_if_present(player, "star_requested", Callable(self, "_on_star"))
		_connect_if_present(player, "enemy_sliced", Callable(self, "_on_enemy_sliced"))
	enemy_manager = scene.get_node_or_null("EnemyManager")
	if enemy_manager:
		_connect_if_present(enemy_manager, "enemy_spawned", Callable(self, "_on_enemy_spawned"))
		_connect_if_present(enemy_manager, "enemy_removed", Callable(self, "_on_enemy_removed"))
		_connect_if_present(enemy_manager, "broccoli_projectile_fired", Callable(self, "_on_broccoli_projectile_fired"))
	var objectives := scene.get_node_or_null("WorldObjectives")
	if objectives:
		_connect_if_present(objectives, "seal_pickup_collected", Callable(self, "_on_seal_pickup"))
		_connect_if_present(objectives, "kenzie_shield_hit", Callable(self, "_on_shield_hit"))
		_connect_if_present(objectives, "kenzie_saved", Callable(self, "_on_kenzie_saved"))
	if has_node("/root/GameState"):
		var state := get_node("/root/GameState")
		_connect_if_present(state, "player_damaged", Callable(self, "_on_player_damaged"))
		_connect_if_present(state, "boss_gate_opened", Callable(self, "_on_boss_gate_opened"))
		_connect_if_present(state, "region_discovered", Callable(self, "_on_region_discovered"))


func _connect_if_present(source: Object, signal_name: String, callable: Callable) -> void:
	if not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callable):
		source.connect(signal_name, callable)


func set_combat_active(active: bool) -> void:
	combat_intensity = 1.0 if active else 0.0


func _process(delta: float) -> void:
	if not connected_scene:
		_connect_scene_signals()
	if enemy_manager and enemy_manager.has_method("active_count"):
		combat_intensity = 1.0 if int(enemy_manager.call("active_count")) > 0 else 0.0
	if combat_player:
		var target_db := combat_volume_db if combat_intensity > 0.5 else -80.0
		combat_player.volume_db = lerpf(combat_player.volume_db, target_db, minf(1.0, fade_speed * delta))


func play_sfx(kind: String) -> void:
	if not sfx_player:
		return
	sfx_player.stream = make_sfx_stream(kind)
	sfx_player.volume_db = sfx_volume_db
	sfx_player.play()


func play_spatial_sfx(kind: String, at: Node3D, volume_db := -5.0) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = make_sfx_stream(kind)
	player.volume_db = volume_db
	player.unit_size = 8.0
	player.max_distance = 46.0
	at.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player


func play_landmark_sound(stream: AudioStream, at: Node3D) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.unit_size = 8.0
	player.max_distance = 42.0
	at.add_child(player)
	player.play()
	return player


func _on_slice() -> void:
	play_sfx("slice")


func _on_dash() -> void:
	play_sfx("dash")


func _on_star() -> void:
	play_sfx("star")


func _on_enemy_sliced(_position: Vector3) -> void:
	play_sfx("enemy_death")


func _on_enemy_spawned(enemy: Node3D) -> void:
	set_combat_active(true)
	if enemy:
		play_spatial_sfx("enemy_stagger", enemy, -12.0)


func _on_enemy_removed(_enemy: Node3D) -> void:
	pass


func _on_broccoli_projectile_fired(_position: Vector3) -> void:
	play_sfx("broccoli_throw")


func _on_seal_pickup(_seal_id: String) -> void:
	play_sfx("powerup")


func _on_shield_hit(_remaining: int) -> void:
	play_sfx("shield_crack")


func _on_kenzie_saved() -> void:
	set_combat_active(false)
	play_sfx("win")


func _on_player_damaged(new_health: int) -> void:
	play_sfx("over" if new_health <= 0 else "hit")


func _on_boss_gate_opened() -> void:
	play_sfx("boss_phase")


func _on_region_discovered(_region_name: String) -> void:
	play_sfx("region")


func make_music_stream() -> AudioStreamWAV:
	var melody := [
		220.0, 0.0, 261.63, 0.0, 293.66, 329.63, 0.0, 261.63,
		196.0, 0.0, 246.94, 0.0, 261.63, 293.66, 0.0, 220.0,
		164.81, 0.0, 220.0, 246.94, 261.63, 0.0, 196.0, 0.0,
		220.0, 0.0, 329.63, 293.66, 261.63, 246.94, 220.0, 0.0
	]
	return make_wave_stream(melody, 0.34, -0.68, true, 0.24)


func make_combat_stream() -> AudioStreamWAV:
	var pulse := [
		110.0, 0.0, 146.83, 0.0, 110.0, 164.81, 0.0, 98.0,
		110.0, 0.0, 196.0, 146.83, 110.0, 0.0, 98.0, 0.0
	]
	return make_wave_stream(pulse, 0.16, -0.56, true, 0.42)


func make_wind_stream() -> AudioStreamWAV:
	var sample_rate := 22050
	var seconds := 9.0
	var frames := int(sample_rate * seconds)
	var data := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = 88137
	var drift := 0.0
	for i in range(frames):
		var t := float(i) / float(sample_rate)
		drift = lerpf(drift, rng.randf_range(-1.0, 1.0), 0.012)
		var wave := sin(t * TAU * 0.18) * 0.35 + sin(t * TAU * 0.07 + 1.6) * 0.45
		var amp := (drift * 0.22 + wave * 0.18) * 0.045
		var sample := clampi(int(amp * 32767.0), -32768, 32767)
		if sample < 0:
			sample = 65536 + sample
		data.append(sample & 0xff)
		data.append((sample >> 8) & 0xff)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


func make_sfx_stream(kind: String) -> AudioStreamWAV:
	match kind:
		"slice":
			return make_wave_stream([1244.5, 932.33, 698.46], 0.045, -0.18, false, 0.65)
		"dash":
			return make_wave_stream([392.0, 587.33, 783.99, 1174.66], 0.04, -0.24, false, 0.55)
		"hit":
			return make_wave_stream([164.81, 123.47, 92.5], 0.08, -0.16, false, 0.55)
		"star":
			return make_wave_stream([880.0, 1174.66, 1567.98], 0.032, -0.28, false, 0.7)
		"broccoli_throw":
			return make_wave_stream([196.0, 246.94, 196.0], 0.035, -0.34, false, 0.52)
		"powerup":
			return make_wave_stream([523.25, 659.25, 783.99, 1046.5], 0.045, -0.24, false, 0.6)
		"enemy_stagger":
			return make_wave_stream([320.0, 180.0], 0.03, -0.22, false, 0.52)
		"enemy_death":
			return make_wave_stream([220.0, 160.0, 110.0, 80.0], 0.04, -0.18, false, 0.55)
		"boss_phase":
			return make_wave_stream([196.0, 261.63, 392.0, 523.25, 659.25], 0.06, -0.14, false, 0.7)
		"shield_crack":
			return make_wave_stream([880.0, 660.0, 440.0, 220.0], 0.055, -0.2, false, 0.7)
		"win":
			return make_wave_stream([523.25, 659.25, 783.99, 1046.5, 1318.51], 0.09, -0.18, false, 0.64)
		"over":
			return make_wave_stream([220.0, 185.0, 146.83, 110.0], 0.12, -0.16, false, 0.45)
		"region":
			return make_wave_stream([261.63, 329.63, 392.0], 0.07, -0.36, false, 0.38)
		_:
			return make_wave_stream([440.0], 0.08, -0.3, false, 0.5)


func make_wave_stream(notes: Array, note_duration: float, volume: float, loop := false, harmonic_mix := 0.34) -> AudioStreamWAV:
	var sample_rate := 22050
	var data := PackedByteArray()
	var phase := 0.0
	for freq in notes:
		var frames := int(sample_rate * note_duration)
		for i in range(frames):
			var amp := 0.0
			if float(freq) > 0.0:
				var env := minf(1.0, float(i) / 320.0) * minf(1.0, float(frames - i) / 900.0)
				var tone := sin(phase) + harmonic_mix * sin(phase * 2.0) + harmonic_mix * 0.38 * sin(phase * 3.0)
				amp = tone * env * pow(10.0, volume)
				phase += TAU * float(freq) / float(sample_rate)
			var sample := clampi(int(amp * 32767.0), -32768, 32767)
			if sample < 0:
				sample = 65536 + sample
			data.append(sample & 0xff)
			data.append((sample >> 8) & 0xff)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream
