extends Node
class_name GlobalState

const SaveDataScript := preload("res://scripts/save_data.gd")

signal player_damaged(new_health: int)
signal player_died
signal score_changed(new_score: int)
signal seal_collected(seal_id: String, count: int)
signal shrine_collected(shrine_id: String, count: int)
signal region_discovered(region_name: String)
signal boss_gate_opened

var score := 0
var health := 5
var max_health := 5
var star_ammo := 18
var max_star_ammo := 32
var collected_seals := {"library": false, "garden": false, "crypt": false}
var collected_shrines := {}
var discovered_regions := {}
var highest_score := 0
var highest_seals := 0


func _ready() -> void:
	var data := SaveDataScript.load_data()
	highest_score = int(data.get("highest_score", 0))
	highest_seals = int(data.get("highest_seals", 0))


func reset_run() -> void:
	score = 0
	max_health = 5
	health = max_health
	star_ammo = 18
	max_star_ammo = 32
	collected_seals = {"library": false, "garden": false, "crypt": false}
	collected_shrines.clear()
	discovered_regions.clear()
	score_changed.emit(score)


func add_score(amount: int) -> void:
	score += amount
	if score > highest_score:
		highest_score = score
		_save_progress()
	score_changed.emit(score)


func damage_player(amount: int) -> void:
	health = maxi(0, health - amount)
	player_damaged.emit(health)
	if health <= 0:
		player_died.emit()


func restore_player() -> void:
	health = max_health
	player_damaged.emit(health)


func collect_seal(seal_id: String) -> int:
	if collected_seals.get(seal_id, false):
		return seal_count()
	collected_seals[seal_id] = true
	var count := seal_count()
	if count > highest_seals:
		highest_seals = count
		_save_progress()
	seal_collected.emit(seal_id, count)
	if count >= 3:
		boss_gate_opened.emit()
	return count


func seal_count() -> int:
	var count := 0
	for id in collected_seals:
		if collected_seals[id]:
			count += 1
	return count


func collect_shrine(shrine_id: String) -> int:
	if collected_shrines.get(shrine_id, false):
		return shrine_count()
	collected_shrines[shrine_id] = true
	var count := shrine_count()
	shrine_collected.emit(shrine_id, count)
	return count


func shrine_count() -> int:
	var count := 0
	for id in collected_shrines:
		if collected_shrines[id]:
			count += 1
	return count


func discover_region(region_name: String) -> void:
	if discovered_regions.get(region_name, false):
		return
	discovered_regions[region_name] = true
	region_discovered.emit(region_name)


func _save_progress() -> void:
	SaveDataScript.save({
		"highest_score": highest_score,
		"highest_seals": highest_seals
	})
