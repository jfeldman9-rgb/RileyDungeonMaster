extends Control
class_name UIManager

const RILEY_PORTRAIT := preload("res://assets/generated/riley_portrait.png")
const KENZIE_PORTRAIT := preload("res://assets/generated/kenzie_portrait.png")

@export var state_path: NodePath

var state: Node
var score_label: Label
var health_label: Label
var heart_label: Label
var seal_label: Label
var region_label: Label
var objective_label: Label
var message_label: Label
var gate_progress: ProgressBar
var damage_flash: ColorRect
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
	_build_damage_flash()
	_build_adventure_frames()
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
	_build_portraits()


func _build_damage_flash() -> void:
	damage_flash = ColorRect.new()
	damage_flash.name = "DamageFlash"
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.color = Color(0.9, 0.02, 0.0, 0.0)
	add_child(damage_flash)


func _build_portraits() -> void:
	var portrait := TextureRect.new()
	portrait.name = "RileyPortrait"
	portrait.texture = RILEY_PORTRAIT
	portrait.position = Vector2(18, 146)
	portrait.custom_minimum_size = Vector2(74, 74)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(portrait)
	var kenzie := TextureRect.new()
	kenzie.name = "KenziePortrait"
	kenzie.texture = KENZIE_PORTRAIT
	kenzie.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	kenzie.offset_left = -92
	kenzie.offset_right = -18
	kenzie.offset_top = 18
	kenzie.offset_bottom = 92
	kenzie.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	kenzie.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	kenzie.modulate = Color(1.0, 0.85, 1.0, 0.86)
	add_child(kenzie)


func _build_adventure_frames() -> void:
	var portrait_panel := PanelContainer.new()
	portrait_panel.name = "AdventurePortraitPanel"
	portrait_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	portrait_panel.offset_left = 18
	portrait_panel.offset_right = 254
	portrait_panel.offset_top = -112
	portrait_panel.offset_bottom = -18
	portrait_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.01, 0.012, 0.018, 0.76), Color(0.78, 0.86, 1.0, 0.28)))
	add_child(portrait_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	portrait_panel.add_child(row)

	var portrait := TextureRect.new()
	portrait.texture = RILEY_PORTRAIT
	portrait.custom_minimum_size = Vector2(76, 76)
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 6)
	row.add_child(stats)
	var name_label := _make_label("RILEY", 14, Color(0.74, 0.92, 1.0))
	stats.add_child(name_label)
	heart_label = _make_label("<3 <3 <3 <3 <3", 18, Color(1.0, 0.22, 0.18))
	stats.add_child(heart_label)
	var stamina := ProgressBar.new()
	stamina.custom_minimum_size = Vector2(112, 12)
	stamina.max_value = 100
	stamina.value = 72
	stamina.show_percentage = false
	stats.add_child(stamina)

	var action_panel := PanelContainer.new()
	action_panel.name = "ActionPanel"
	action_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_panel.offset_left = -342
	action_panel.offset_right = -18
	action_panel.offset_top = -100
	action_panel.offset_bottom = -18
	action_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.012, 0.014, 0.022, 0.72), Color(0.95, 0.82, 1.0, 0.25)))
	add_child(action_panel)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	action_panel.add_child(action_row)
	for label_text in ["SLICE", "DASH", "STAR"]:
		action_row.add_child(_make_action_chip(label_text))

	var boss_panel := PanelContainer.new()
	boss_panel.name = "BossBanner"
	boss_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_panel.offset_left = 390
	boss_panel.offset_right = -390
	boss_panel.offset_top = 18
	boss_panel.offset_bottom = 58
	boss_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.012, 0.032, 0.72), Color(0.85, 0.35, 1.0, 0.35)))
	add_child(boss_panel)
	var boss_text := _make_label("KENZIE TOWER", 15, Color(1.0, 0.82, 1.0))
	boss_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var boss_box := VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 3)
	boss_panel.add_child(boss_box)
	boss_box.add_child(boss_text)
	gate_progress = ProgressBar.new()
	gate_progress.custom_minimum_size = Vector2(320, 9)
	gate_progress.max_value = 3
	gate_progress.value = 0
	gate_progress.show_percentage = false
	boss_box.add_child(gate_progress)


func _make_action_chip(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(96, 62)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.055, 0.11, 0.88), Color(1.0, 1.0, 1.0, 0.18)))
	var label := _make_label(text, 13, Color(0.94, 0.92, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


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
		var best := int(state.get("highest_score")) if state else 0
		score_label.text = "Score %d    Best %d" % [_new_score, best]


func _on_player_damaged(_new_health: int) -> void:
	if health_label:
		var max_health := int(state.get("max_health")) if state else 5
		health_label.text = "Health %d/%d" % [_new_health, max_health]
	if heart_label:
		var hearts := ""
		var max_hearts := int(state.get("max_health")) if state else 5
		for i in range(max_hearts):
			hearts += "<3 " if i < _new_health else "-- "
		heart_label.text = hearts.strip_edges()
	if _new_health <= 0:
		show_message("RILEY DOWN", "Retreat to the clearing and try again.")
	else:
		show_message("HIT", "Broccoli monster got through.")
	if damage_flash:
		var tween := damage_flash.create_tween()
		tween.tween_property(damage_flash, "color:a", 0.32, 0.055)
		tween.tween_property(damage_flash, "color:a", 0.0, 0.34)


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
	if gate_progress:
		gate_progress.value = count
