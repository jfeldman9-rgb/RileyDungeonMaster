extends Control
class_name UIManager

@export var state_path: NodePath

var state: Node
var score_label: Label
var health_label: Label
var seal_label: Label
var region_label: Label
var objective_label: Label
var message_label: Label
var story_panel: PanelContainer
var story_title: Label
var story_body: Label
var message_timer := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	state = get_node_or_null(state_path)
	if not state and has_node("/root/GameState"):
		state = get_node("/root/GameState")
	if state:
		state.score_changed.connect(_on_score_changed)
		state.player_damaged.connect(_on_player_damaged)
		if state.has_signal("seal_collected"):
			state.seal_collected.connect(_on_seal_collected)
		if state.has_signal("boss_gate_opened"):
			state.boss_gate_opened.connect(_on_boss_gate_opened)
		_on_score_changed(int(state.get("score")))
		_on_player_damaged(int(state.get("health")))
		_refresh_seals()
	set_objective_hint("Explore the valley. Collect the Library, Garden, and Crypt seals.")


func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0 and message_label:
			message_label.modulate.a = 0.0


func _input(event: InputEvent) -> void:
	if story_panel and story_panel.visible and event.is_action_pressed("ui_accept"):
		story_panel.visible = false


func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.name = "HudPanel"
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(360, 118)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.026, 0.72)
	style.border_color = Color(0.75, 0.78, 1.0, 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	objective_label = _make_label("Explore", 15, Color(0.95, 0.92, 0.78))
	box.add_child(objective_label)
	region_label = _make_label("Starting Clearing", 13, Color(0.78, 0.72, 1.0))
	box.add_child(region_label)
	seal_label = _make_label("Seals 0/3", 13, Color(0.62, 0.82, 1.0))
	box.add_child(seal_label)
	health_label = _make_label("Health 5/5", 13, Color(1.0, 0.42, 0.38))
	box.add_child(health_label)
	score_label = _make_label("Score 0", 13, Color(0.82, 1.0, 0.62))
	box.add_child(score_label)

	message_label = _make_label("", 28, Color(1.0, 0.92, 0.45))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	message_label.offset_top = 118
	message_label.offset_bottom = 190
	message_label.modulate.a = 0.0
	add_child(message_label)
	_build_story_panel()


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _build_story_panel() -> void:
	story_panel = PanelContainer.new()
	story_panel.visible = false
	story_panel.custom_minimum_size = Vector2(620, 260)
	story_panel.set_anchors_preset(Control.PRESET_CENTER)
	story_panel.offset_left = -310
	story_panel.offset_right = 310
	story_panel.offset_top = -130
	story_panel.offset_bottom = 130
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.015, 0.035, 0.92)
	style.border_color = Color(0.86, 0.72, 0.34, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	story_panel.add_theme_stylebox_override("panel", style)
	add_child(story_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	story_panel.add_child(box)
	story_title = _make_label("", 30, Color(1.0, 0.84, 0.35))
	story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(story_title)
	story_body = _make_label("", 18, Color(0.92, 0.92, 0.88))
	story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(story_body)


func show_message(_title: String, _subtitle: String = "") -> void:
	if not message_label:
		return
	message_label.text = _title + ("\n" + _subtitle if _subtitle != "" else "")
	message_label.modulate.a = 1.0
	message_timer = 2.4


func show_story_card(title: String, body: String) -> void:
	if not story_panel:
		return
	story_title.text = title
	story_body.text = body
	story_panel.visible = true


func set_objective_hint(_text: String) -> void:
	if objective_label:
		objective_label.text = _text


func set_region_name(_text: String) -> void:
	if region_label:
		region_label.text = "Area: %s" % _text


func _on_score_changed(_new_score: int) -> void:
	if score_label:
		score_label.text = "Score %d" % _new_score


func _on_player_damaged(_new_health: int) -> void:
	if health_label:
		var max_health := int(state.get("max_health")) if state else 5
		health_label.text = "Health %d/%d" % [_new_health, max_health]
	if _new_health <= 0:
		show_message("RILEY DOWN", "Retreat to the clearing and try again.")
	else:
		show_message("HIT", "Broccoli monster got through.")


func _on_seal_collected(seal_id: String, count: int) -> void:
	_refresh_seals()
	show_message("SEAL FOUND", "%s seal collected (%d/3)" % [seal_id.capitalize(), count])


func _on_boss_gate_opened() -> void:
	_refresh_seals()
	set_objective_hint("Kenzie Tower is open. Cross the valley and climb the ruins.")
	show_message("KENZIE GATE OPEN", "The tower shield has fallen.")


func _refresh_seals() -> void:
	if not seal_label or not state:
		return
	var count := int(state.call("seal_count")) if state.has_method("seal_count") else 0
	var gate := "Open" if count >= 3 else "Locked"
	seal_label.text = "Seals %d/3    Kenzie Gate: %s" % [count, gate]
