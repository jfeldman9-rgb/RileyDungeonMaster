extends RefCounted
class_name SaveData

const SAVE_PATH := "user://riley_open_world_save.cfg"


static func save(data: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for key in data:
		cfg.set_value("save", str(key), data[key])
	cfg.save(SAVE_PATH)


static func load_data() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	var result := {}
	for key in cfg.get_section_keys("save"):
		result[key] = cfg.get_value("save", key)
	return result
