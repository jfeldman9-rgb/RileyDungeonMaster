extends Node3D

const PLAYER_START_Z := 24.0
const GOAL_Z := -34.0
const CORRIDOR_HALF_WIDTH := 12.0
const GREAT_HALL_Z_MAX := 1.5
const GREAT_HALL_Z_MIN := -5.5
const KENZIE_GATE_Z := -24.0
const PROJECTILE_SCENE_LIMIT := 44.0
const ASSET_PATH := "res://assets/generated/"
const CAMPAIGN_SECONDS := 3600.0
const FINAL_CUTSCENE_FLOOR := 10

# Seal pickup world positions (one per landmark wing)
const LIBRARY_SEAL_POS  := Vector3(-11.5, 0.64, -8.0)
const GARDEN_SEAL_POS   := Vector3( 11.0, 0.64,  4.0)
const CRYPT_SEAL_POS    := Vector3(-10.5, 0.64,-18.2)

const SHRINE_DATA := [
	{"id": "swift", "title": "Swift Shrine", "pos": Vector3(16.4, 0.58, 11.6), "color": Color(0.35, 0.85, 1.0), "reward": "speed"},
	{"id": "star", "title": "Starfall Shrine", "pos": Vector3(-17.0, 0.58, 2.2), "color": Color(0.72, 0.55, 1.0), "reward": "stars"},
	{"id": "heart", "title": "Hero Shrine", "pos": Vector3(12.6, 0.58, -19.2), "color": Color(1.0, 0.24, 0.32), "reward": "heart"},
]

# Explorable overworld regions. These are intentionally broad, overlapping
# adventure spaces: clearing, winding path, courtyard, bridge, and temple.
# cx/cz = centre, hw/hz = half-extents on the X/Z axes.
const WORLD_REGIONS := [
	{"name": "Starting Clearing", "cx":  0.0, "cz": 22.0,  "hw": 13.5, "hz": 8.7, "shape": "ellipse"},
	{"name": "Ancient Crossroads", "cx": 0.0, "cz": 12.0,  "hw": 11.0, "hz": 7.0, "shape": "ellipse"},
	{"name": "Westbend Trail",    "cx": -5.8, "cz": 13.5,  "hw":  8.8, "hz": 6.0, "shape": "ellipse"},
	{"name": "Old Forest Path",   "cx":  4.8, "cz":  6.0,  "hw":  9.4, "hz": 6.5, "shape": "ellipse"},
	{"name": "Garden Shortcut",   "cx": 10.0, "cz": 11.0,  "hw":  5.4, "hz": 7.8, "shape": "ellipse"},
	{"name": "Swift Shrine Grove", "cx": 16.4, "cz": 11.6,  "hw":  4.8, "hz": 4.4, "shape": "ellipse"},
	{"name": "Poison Garden",     "cx": 12.0, "cz":  3.2,  "hw":  7.5, "hz": 6.6, "shape": "ellipse"},
	{"name": "Broken Switchback", "cx": -3.2, "cz": -1.8,  "hw":  9.0, "hz": 6.6, "shape": "ellipse"},
	{"name": "Library Cut",       "cx": -9.8, "cz":  0.0,  "hw":  5.6, "hz": 8.6, "shape": "ellipse"},
	{"name": "Starfall Hollow",   "cx":-17.0, "cz":  2.2,  "hw":  4.8, "hz": 4.4, "shape": "ellipse"},
	{"name": "Moon Library",      "cx":-13.0, "cz": -8.0,  "hw":  7.0, "hz": 6.0, "shape": "ellipse"},
	{"name": "Ruined Courtyard",  "cx":  0.0, "cz": -10.0, "hw": 15.0, "hz": 9.4, "shape": "ellipse"},
	{"name": "River Ford",        "cx": 11.0, "cz": -8.5,  "hw":  6.8, "hz": 7.0, "shape": "ellipse"},
	{"name": "Crypt Ravine",      "cx": -8.4, "cz":-13.4,  "hw":  7.2, "hz": 7.6, "shape": "ellipse"},
	{"name": "Crown Crypt",       "cx":-12.2, "cz":-20.0,  "hw":  7.2, "hz": 6.4, "shape": "ellipse"},
	{"name": "North Ridge",       "cx":  7.0, "cz":-17.0,  "hw":  7.2, "hz": 6.4, "shape": "ellipse"},
	{"name": "Hero Shrine Ridge", "cx": 12.6, "cz":-19.2,  "hw":  4.8, "hz": 4.4, "shape": "ellipse"},
	{"name": "Bridge Gate",       "cx":  0.0, "cz":-24.0,  "hw":  9.4, "hz": 6.2, "shape": "box"},
	{"name": "Temple Overlook",   "cx":  0.0, "cz":-29.2,  "hw":  7.6, "hz": 4.2, "shape": "ellipse"},
	{"name": "Kenzie Temple",     "cx":  0.0, "cz":-34.0,  "hw":  8.6, "hz": 6.2, "shape": "ellipse"},
]

const MISSIONS := [
	{"name": "Valley Approach", "brief": "Explore the clearing and survive the opening swarm", "duration": 420.0, "kills": 10, "fruit": 0, "powerups": 1},
	{"name": "Broccoli Barracks", "brief": "Defeat broccoli brutes", "duration": 540.0, "kills": 28, "fruit": 0, "powerups": 3},
	{"name": "Fruit Vault", "brief": "Clear the fruit monsters", "duration": 600.0, "kills": 42, "fruit": 12, "powerups": 5},
	{"name": "Torch Maze", "brief": "Hold the lane under pressure", "duration": 660.0, "kills": 62, "fruit": 24, "powerups": 7},
	{"name": "Crown Siege", "brief": "Break Kenzie's vegetable army", "duration": 780.0, "kills": 88, "fruit": 38, "powerups": 9},
	{"name": "Temple Duel", "brief": "Reach Kenzie's platform and shatter the shield", "duration": 600.0, "kills": 110, "fruit": 50, "powerups": 10}
]

const FLOOR_THEMES := [
	{"name": "Stone Vault", "fog": Color(0.2, 0.16, 0.28), "ambient": Color(0.14, 0.14, 0.2), "key": Color(0.72, 0.78, 1.0), "torch": Color(1.0, 0.55, 0.18)},
	{"name": "Bone Corridor", "fog": Color(0.3, 0.28, 0.22), "ambient": Color(0.2, 0.18, 0.14), "key": Color(0.95, 0.86, 0.62), "torch": Color(0.9, 0.82, 0.55)},
	{"name": "Poison Vault", "fog": Color(0.12, 0.24, 0.14), "ambient": Color(0.08, 0.16, 0.1), "key": Color(0.5, 0.95, 0.55), "torch": Color(0.32, 1.0, 0.38)},
	{"name": "Crown Chamber", "fog": Color(0.25, 0.12, 0.38), "ambient": Color(0.17, 0.1, 0.22), "key": Color(0.85, 0.55, 1.0), "torch": Color(0.85, 0.25, 1.0)}
]

const SIDE_CHAMBERS := [
	{"z": -2.0, "side": -1, "name": "Moon Library", "tint": Color(0.12, 0.09, 0.16)},
	{"z": -7.8, "side": 1, "name": "Poison Garden", "tint": Color(0.09, 0.13, 0.12)},
	{"z": -12.6, "side": -1, "name": "Crown Crypt", "tint": Color(0.16, 0.11, 0.08)},
	{"z": 4.2, "side": 1, "name": "Training Annex", "tint": Color(0.1, 0.1, 0.16)}
]


func in_great_hall(z: float) -> bool:
	return z >= GREAT_HALL_Z_MIN and z <= GREAT_HALL_Z_MAX

var game_running := false
var won := false
var score := 0
var health := 5
var max_health := 5
var player_speed := 6.6
var player_z := PLAYER_START_Z
var attack_timer := 0.0
var attack_cooldown := 0.0
var invuln_timer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var boss_zone := false
var boss_health := 5
var boss_max_health := 5
var broccoli_timer := 0.0
var taunt_timer := 0.0
var message_timer := 0.0
var voice_id := ""
var next_voice_time := 0.0
var keyboard_slice_latched := false
var keyboard_dash_latched := false
var keyboard_throw_latched := false
var run_time := 0.0
var mission_index := 0
var monster_timer := 0.0
var powerup_timer := 0.0
var star_cooldown := 0.0
var star_ammo := 18
var max_star_ammo := 32
var monsters_defeated := 0
var fruit_defeated := 0
var powerups_collected := 0
var aim_direction := Vector3(0, 0, -1)
var riley_level := 1
var riley_xp := 0
var xp_to_next := 60
var slash_damage := 2
var star_damage := 2
var star_speed := 11.5
var combo_count := 0
var combo_timer := 0.0
var powerup_boost_timer := 0.0
var shield_hits := 0
var dungeon_floor := 1
var floors_cleared := 0
var floor_transition_cooldown := 0.0
var star_regen_timer := 0.0
var director_heat := 0.0
var boss_battle_active := false
var boss_attack_timer := 0.0
var boss_minion_timer := 0.0
var boss_phase := 1
var camera_shake_timer := 0.0
var camera_shake_intensity := 0.0
var hit_stop_pending := false
var player_velocity := Vector3.ZERO
var attack_lunge_dir := Vector3.ZERO
var dash_trail_timer := 0.0
var player_hit_flash_timer := 0.0
var kenzie_robe_timer := 0.0
var dungeon_animatables: Array[Node3D] = []
var camera_yaw := 0.0
var target_camera_yaw := 0.0
var input_locked := false
var victory_cutscene_active := false
var victory_cutscene_timer := 0.0
var victory_cutscene_stage := 0
var victory_cutscene_frame := 0
var event_timer := 18.0
var event_name := ""
var event_time_left := 0.0
var event_progress := 0.0
var event_goal := 0.0
var event_nodes: Array[Node3D] = []

var player: Node3D
var player_arm: Node3D
var sword: Node3D
var sword_light: OmniLight3D
var player_damage_light: OmniLight3D
var player_art: Sprite3D
var player_shadow: MeshInstance3D
var kenzie: Node3D
var kenzie_staff: Node3D
var kenzie_aura_light: OmniLight3D
var kenzie_shield: Node3D
var kenzie_art: Sprite3D
var kenzie_shadow: MeshInstance3D
var camera: Camera3D
var world_environment: WorldEnvironment
var key_light: DirectionalLight3D
var torch_lights: Array[OmniLight3D] = []
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var projectiles: Array[Node3D] = []
var particles: Array[Node3D] = []
var rings: Array[Node3D] = []
var monsters: Array[Node3D] = []
var powerups: Array[Node3D] = []
var ninja_stars: Array[Node3D] = []

var collected_seals := {"library": false, "garden": false, "crypt": false}
var kenzie_gate_open := false
var seal_nodes: Array[Node3D] = []
var shrine_nodes: Array[Node3D] = []
var kenzie_gate_node: Node3D
var region_label: Label
var seal_label: Label
var objective_hint_label: Label
var discovered_regions := {}
var collected_shrines := {}
var last_region_name := ""

var joystick_active := false
var joystick_id := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var last_joystick_tap_ms := 0

var hud: CanvasLayer
var start_screen: Control
var over_screen: Control
var victory_cutscene_screen: Control
var cutscene_image_panel: ColorRect
var cutscene_riley_image: TextureRect
var cutscene_kenzie_image: TextureRect
var cutscene_title_label: Label
var cutscene_caption_label: Label
var cutscene_continue_label: Label
var controls_layer: Control
var score_label: Label
var health_label: Label
var boss_label: Label
var boss_sub_label: Label
var boss_bar: ProgressBar
var boss_name_label: Label
var mission_label: Label
var mission_progress_label: Label
var star_label: Label
var level_label: Label
var xp_meter: ProgressBar
var combo_label: Label
var ability_label: Label
var damage_flash: ColorRect
var health_hearts_label: Label
var health_meter: ProgressBar
var message_label: Label
var sub_message_label: Label
var joystick_base: Panel
var joystick_knob: Panel
var slice_button: Button
var dash_button: Button
var star_button: Button

var kenzie_taunts := [
	"Welcome to my dungeon, Riley.",
	"Slice faster, tiny ninja.",
	"The broccoli is faster than your excuses.",
	"Your glasses are fogging from fear.",
	"Dungeon master rule one: dodge the vegetables.",
	"Advance, Riley. I am getting bored.",
	"The broccoli legion obeys me.",
	"Come closer if you want the boss fight.",
	"My broccoli shield is legally unstoppable.",
	"I wrote this dungeon in purple ink and bad intentions.",
	"Riley, your sword is shiny. That is not a strategy.",
	"The broccoli has formed a committee. It voted against you.",
	"You are one dodge away from dignity.",
	"My crown says boss. Your face says tutorial.",
	"This hallway has seen better ninjas.",
	"The torches are rooting for me.",
	"Careful. The floor tiles remember every mistake.",
	"I am not throwing vegetables. I am conducting them.",
	"Your dash is available, which is more than I can say for your confidence.",
	"Broccoli spell, level three: emotional damage.",
	"I put extra drama in this corridor just for you.",
	"Your glasses are reflecting defeat beautifully.",
	"The dungeon master has notes. So many notes.",
	"Run closer. My shield needs exercise.",
	"I made this boss bar red so you would feel urgency.",
	"Every broccoli here trained for this moment.",
	"Your ninja outfit is cute. Ineffective, but cute.",
	"This is not a snack break. This is a boss fight.",
	"The crown is real. The mercy is decorative.",
	"I see you approaching, and frankly, I object.",
	"Your sword swings like it needs a permission slip.",
	"Welcome to vegetable weather.",
	"My staff glows because it is judging you.",
	"The broccoli shield accepts no refunds.",
	"Did your ninja academy teach vegetable avoidance, or was that extra credit?",
	"I expected a shadow warrior and got a hallway jogger.",
	"Your stealth mode is very sparkly.",
	"That headband is doing most of the work.",
	"Careful, the broccoli can smell hesitation.",
	"My robe has more boss energy than your entire dash.",
	"You swing like the sword is asking a question.",
	"I have seen quieter ninjas in marching bands.",
	"Your ninja vanish trick needs more vanish.",
	"The dungeon tiles are filing a complaint about your footwork.",
	"I summon broccoli. You summon panic.",
	"My shield has vegetables and confidence. Dangerous combination.",
	"Riley, blink twice if the sword is too heavy.",
	"Your ninja pose is excellent. Your survival plan is still loading.",
	"The broccoli asked for a challenge. I said maybe later.",
	"I hope your glasses have boss-fight insurance.",
	"I put the master in dungeon master and the crunch in lunch.",
	"You are approaching with the grace of a dropped backpack.",
	"That slice was almost a sentence.",
	"Your sword is brave. Try to keep up with it.",
	"I have a crown, a staff, and a vegetable army. You have homework energy.",
	"The broccoli shield is gluten free and victory full.",
	"Did you bring smoke bombs, or just dramatic breathing?",
	"My dungeon has a strict no timid ninjas policy.",
	"Your dash leaves a trail of maybe.",
	"Even the torches are whispering, yikes.",
	"Your ninja rank today is apprentice salad spinner.",
	"I graded that swing. It got a polite sticker.",
	"The broccoli legion is not impressed by black pajamas.",
	"If confidence were damage, you would still be warming up.",
	"Try slicing the broccoli, not negotiating with it.",
	"I can hear your sneakers thinking about retreat.",
	"Your sword technique is ninety percent whoops.",
	"This is a boss fight, not a hallway tour.",
	"I installed extra drama beams so your defeat photographs well.",
	"The crown is small, but the attitude is enormous.",
	"Riley, the vegetables are winning the eye contact contest.",
	"Your ninja handbook skipped the chapter called move.",
	"Do not worry, I will tell the broccoli to go easy. I will be lying.",
	"Your stance says hero. Your timing says lunchbox.",
	"My spellbook has doodles tougher than that swing.",
	"The broccoli is airborne because it believes in itself.",
	"Your shadow is trying to sneak away without you.",
	"Karate chop? More like karate maybe.",
	"You call that a dash? The banners waved faster.",
	"Every time you miss, my crown gets shinier.",
	"I respect your courage. I question your route.",
	"The broccoli shield has layers, unlike your plan.",
	"Your sword just asked me for a better wielder.",
	"This dungeon was balanced for one ninja. Sadly, you brought half.",
	"Try a battle cry. Maybe the broccoli will laugh itself apart.",
	"My staff says zap. Your face says oh no.",
	"The floor cracks are spelling dodge.",
	"Even my banners have better posture.",
	"Your secret technique appears to be walking into vegetables.",
	"Riley, I have boss music and you have squeaky shoes.",
	"The broccoli comes with vitamins and consequences.",
	"If you were any stealthier, I might still see you.",
	"I am adding this fight to my scrapbook under easy chaos.",
	"Your ninja aura is buffering.",
	"Please hold still. The broccoli needs target practice.",
	"My dungeon has three rules: dodge, slice, and do not embarrass the sword.",
	"Your glasses make you look smart. Prove them right.",
	"The broccoli union demands better opponents.",
	"Did you train under a master, or a swivel chair?",
	"That slash had enthusiasm. Accuracy is next semester.",
	"You are so close to becoming mildly threatening.",
	"The shield is cracking, but my sarcasm is reinforced.",
	"I would monologue longer, but the broccoli is impatient.",
	"Riley, this is where ninjas usually do ninja things.",
	"My crown just whispered, not today.",
	"That was not a dodge. That was decorative drifting.",
	"You brought a sword to a broccoli fight. Bold and confusing.",
	"The dungeon master remains undefeated in dramatic pointing.",
	"I hope your ninja insurance covers produce.",
	"Your battle plan is mostly vibes.",
	"If you win, I will deny this fight was canon.",
	"Come on, Riley. The shield wants a worthy crack.",
	"The broccoli storm has entered its silly phase.",
	"I believe in you just enough to keep taunting.",
	"Congratulations, you have unlocked advanced vegetable trouble.",
	"My final form is still wearing the crown.",
	"Do not blink. Actually, do blink. Your glasses are fogging.",
	"I named that broccoli Sir Crunch.",
	"Your sword shines brighter when it is disappointed.",
	"The dungeon says thank you for the comedy.",
	"I would call you a shadow, but shadows dodge better.",
	"Riley, the ninja part is supposed to happen before the impact.",
	"This is my boss room, my rules, my broccoli.",
	"Approach the crown, tiny ninja, if you dare."
]

var riley_lines := [
	"Karate chop!",
	"Kiiya!",
	"Ninja slice!",
	"Shadow step!",
	"Silent but sharp!",
	"Broccoli, meet blade!",
	"Hi-yah!",
	"Too slow, vegetables!",
	"Glasses on. Focus up.",
	"Ninja mode!",
	"Dash slash!",
	"Cutting through!",
	"Not today, broccoli!",
	"Secret sword technique!",
	"Kenzie, your shield is toast!",
	"Swift as a shadow!",
	"Chop chop!",
	"Blade of homework justice!",
	"I trained for this!",
	"Snack attack denied!",
	"Stealth strike!",
	"Here comes Riley!",
	"One ninja, no fear!",
	"Broccoli cannot stop me!",
	"Kiyaa karate combo!"
]

var slice_lines := [
	"Clean slice.",
	"Broccoli deleted.",
	"Good cut.",
	"Kenzie noticed. Barely.",
	"Keep advancing.",
	"Cut and move."
]

var hit_lines := [
	"Broccoli impact.",
	"You got vegetable checked.",
	"Use the sword, Riley.",
	"Dodge or slice. Pick one."
]


func _ready() -> void:
	randomize()
	choose_voice()
	build_world()
	build_ui()
	build_audio()
	reset_world()
	apply_floor_theme()
	update_hud()


func _process(delta: float) -> void:
	poll_keyboard_actions()
	update_message(delta)
	update_kenzie(Time.get_ticks_msec() / 1000.0, delta)

	if victory_cutscene_active:
		update_victory_cutscene(delta)
	elif game_running:
		run_time += delta
		combo_timer = maxf(0.0, combo_timer - delta)
		if combo_timer <= 0.0:
			combo_count = 0
		powerup_boost_timer = maxf(0.0, powerup_boost_timer - delta)
		floor_transition_cooldown = maxf(0.0, floor_transition_cooldown - delta)
		update_director(delta)
		update_missions()
		update_dungeon_event(delta)
		update_player(delta)
		update_exploration(delta)
		update_seals(delta)
		update_shrines(delta)
		update_projectiles(delta)
		update_monsters(delta)
		update_powerups(delta)
		update_ninja_stars(delta)
		update_boss_battle(delta)
		update_taunts(delta)

	update_particles(delta)
	update_torch_flicker()
	update_dungeon_animatables(delta)
	update_shadows()
	update_camera(delta)
	update_sprite_facings()
	update_hud()


func _input(event: InputEvent) -> void:
	if victory_cutscene_active:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			advance_victory_cutscene()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.pressed:
			advance_victory_cutscene()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if not game_running and (start_screen.visible or over_screen.visible):
			start_game()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey and event.pressed and not event.echo and game_running and not input_locked:
		if event.keycode == KEY_SPACE:
			attack()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SHIFT:
			dash()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F:
			throw_ninja_star()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_B:
			debug_start_boss_preview()
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if not game_running and (start_screen.visible or over_screen.visible):
			start_game()
			get_viewport().set_input_as_handled()
			return

	if input_locked:
		return
	if event.is_action_pressed("slice"):
		attack()
	if event.is_action_pressed("dash"):
		dash()

	if event is InputEventScreenTouch:
		handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		handle_screen_drag(event)


func poll_keyboard_actions() -> void:
	if input_locked:
		keyboard_slice_latched = Input.is_action_pressed("slice")
		keyboard_dash_latched = Input.is_action_pressed("dash")
		keyboard_throw_latched = Input.is_action_pressed("throw_star")
		return
	var slice_down := Input.is_action_pressed("slice")
	var dash_down := Input.is_action_pressed("dash")
	var throw_down := Input.is_action_pressed("throw_star")
	if game_running and slice_down and not keyboard_slice_latched:
		attack()
	if game_running and dash_down and not keyboard_dash_latched:
		dash()
	if game_running and throw_down and not keyboard_throw_latched:
		throw_ninja_star()
	keyboard_slice_latched = slice_down
	keyboard_dash_latched = dash_down
	keyboard_throw_latched = throw_down


func build_world() -> void:
	var environment := WorldEnvironment.new()
	world_environment = environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.014, 0.012, 0.028)
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.16, 0.28)
	env.fog_density = 0.018
	env.set("volumetric_fog_enabled", true)
	env.set("volumetric_fog_density", 0.028)
	env.set("volumetric_fog_albedo", Color(0.32, 0.27, 0.45))
	env.set("volumetric_fog_emission", Color(0.08, 0.04, 0.13))
	env.set("volumetric_fog_emission_energy", 0.45)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.1, 0.1, 0.16)
	env.ambient_light_energy = 0.28   # was 0.62 — dark dungeon contrast
	env.set("glow_enabled", true)
	env.set("glow_intensity", 1.6)    # was 0.9 — richer bloom on emissives
	env.set("glow_bloom", 0.72)       # was 0.42
	env.set("glow_strength", 1.2)
	env.set("ssao_enabled", true)
	env.set("ssao_intensity", 3.2)    # was 1.65 — deeper corner shadows
	env.set("ssao_radius", 3.5)       # was 2.4
	env.set("ssao_power", 1.8)
	env.set("adjustment_enabled", true)
	env.set("adjustment_contrast", 1.22)   # was 1.12
	env.set("adjustment_saturation", 1.28) # was 1.18
	env.set("adjustment_brightness", 0.92) # slight darken to taste
	# Depth of field — soft far blur pulls dungeon depth forward
	env.set("dof_blur_far_enabled", true)
	env.set("dof_blur_far_distance", 24.0)
	env.set("dof_blur_far_transition", 10.0)
	env.set("dof_blur_amount", 0.14)
	environment.environment = env
	add_child(environment)

	var ambient := DirectionalLight3D.new()
	key_light = ambient
	ambient.name = "KeyLight"
	ambient.light_color = Color(0.72, 0.78, 1.0)
	ambient.light_energy = 0.72   # was 0.45 — compensate for darker ambient
	ambient.rotation_degrees = Vector3(-58, 20, 0)
	ambient.shadow_enabled = true
	add_child(ambient)

	var hero_light := SpotLight3D.new()
	hero_light.name = "HeroRimLight"
	hero_light.position = Vector3(-2.4, 6.4, 5.4)
	hero_light.rotation_degrees = Vector3(-62, -22, 0)
	hero_light.light_color = Color(0.54, 0.72, 1.0)
	hero_light.light_energy = 8.0
	hero_light.spot_range = 24
	hero_light.spot_angle = 36
	hero_light.shadow_enabled = true
	add_child(hero_light)

	var boss_light := OmniLight3D.new()
	boss_light.name = "BossPurpleLight"
	boss_light.position = Vector3(0, 3.1, GOAL_Z + 0.65)
	boss_light.light_color = Color(0.85, 0.24, 1.0)
	boss_light.light_energy = 9.2   # boosted for darker ambient
	boss_light.omni_range = 18
	boss_light.shadow_enabled = true
	add_child(boss_light)

	var lane_light := SpotLight3D.new()
	lane_light.name = "LaneMoonBeam"
	lane_light.position = Vector3(0, 9.5, -6.0)
	lane_light.rotation_degrees = Vector3(-78, 0, 0)
	lane_light.light_color = Color(0.55, 0.65, 1.0)
	lane_light.light_energy = 6.4   # was 4.8
	lane_light.spot_range = 28
	lane_light.spot_angle = 25
	lane_light.shadow_enabled = true
	add_child(lane_light)

	var front_fill := OmniLight3D.new()
	front_fill.name = "PlayerReadableFill"
	front_fill.position = Vector3(0, 3.2, 6.8)
	front_fill.light_color = Color(0.35, 0.55, 1.0)
	front_fill.light_energy = 1.35
	front_fill.omni_range = 9
	add_child(front_fill)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = 68.0
	camera.current = true
	camera.position = Vector3(0, 6.4, 20.0)
	add_child(camera)

	build_dungeon()
	build_riley()
	build_kenzie()


func build_dungeon() -> void:
	build_open_world()
	return

	var floor_node := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(12, 32)
	floor_node.mesh = floor_mesh
	floor_node.material_override = make_material(Color(0.055, 0.049, 0.058), 0.92, 0.06)
	floor_node.rotation_degrees.x = -90
	floor_node.position.z = -3
	add_child(floor_node)

	for z_index in range(0, 16):
		var z := 8.0 - z_index * 2.0
		for x_index in range(0, 6):
			var x := -5.0 + x_index * 2.0
			var warm := 0.07 + randf() * 0.045
			var tile_color := Color(warm * 1.08, warm * 0.95, warm * 0.85)
			var tile := add_box(Vector3(x + randf_range(-0.05, 0.05), 0.015 + randf() * 0.025, z + randf_range(-0.04, 0.04)), Vector3(randf_range(1.72, 1.92), randf_range(0.035, 0.075), randf_range(1.72, 1.92)), tile_color)
			tile.rotation_degrees.y = randf_range(-1.2, 1.2)

	for side in [-1, 1]:
		for z_index in range(0, 17):
			var z := 8.0 - z_index * 1.65
			# Great Hall occupies this zone — no narrow walls here
			if z >= GREAT_HALL_Z_MIN and z <= GREAT_HALL_Z_MAX:
				continue
			for row in range(0, 5):
				var y := 0.42 + row * 1.0
				var depth := randf_range(0.26, 0.48)
				var tint := randf_range(0.08, 0.145)
				var block := add_box(
					Vector3(side * 6.05, y, z + randf_range(-0.06, 0.06)),
					Vector3(depth, randf_range(0.78, 1.08), randf_range(1.35, 1.78)),
					Color(tint * 1.18, tint * 1.02, tint * 0.92)
				)
				block.rotation_degrees.y = randf_range(-1.5, 1.5)

	add_box(Vector3(0, 2.7, -18.3), Vector3(12, 5.4, 0.4), Color(0.13, 0.1, 0.1))

	for z in range(7, -18, -5):
		# Skip narrow corridor arch posts inside the Great Hall
		if z >= GREAT_HALL_Z_MIN and z <= GREAT_HALL_Z_MAX:
			continue
		add_box(Vector3(-5.65, 2.5, z), Vector3(0.35, 5.0, 0.35), Color(0.13, 0.11, 0.11))
		add_box(Vector3(5.65, 2.5, z), Vector3(0.35, 5.0, 0.35), Color(0.13, 0.11, 0.11))
		add_arch_detail(z)

	for z in range(6, -17, -4):
		# Great Hall has its own lighting — skip narrow-wall torches here
		if z >= GREAT_HALL_Z_MIN and z <= GREAT_HALL_Z_MAX:
			continue
		add_torch(Vector3(-5.78, 2.45, z))
		add_torch(Vector3(5.78, 2.45, z))
		add_banner(Vector3(-5.72, 3.25, z - 1.2), 90)
		add_banner(Vector3(5.72, 3.25, z - 1.2), -90)
		add_wall_art(ASSET_PATH + "banner_a.png", Vector3(-5.72, 3.0, z - 1.2), 0.006, -90)
		add_wall_art(ASSET_PATH + "banner_b.png", Vector3(5.72, 3.0, z - 1.2), 0.006, 90)

	for z in [-13.5, -10.0, -6.5]:
		add_light_beam(Vector3(-1.3, 3.8, z), -16)
		add_light_beam(Vector3(1.4, 3.5, z - 0.8), 14)

	for z in range(6, -16, -3):
		add_floor_edge_trim(z)
		if z >= GREAT_HALL_Z_MIN and z <= GREAT_HALL_Z_MAX:
			continue  # Great Hall floor is clean stone — no rubble
		add_rubble_cluster(Vector3(randf_range(-4.35, -3.25), 0.13, z + randf_range(-0.6, 0.6)))
		add_rubble_cluster(Vector3(randf_range(3.25, 4.35), 0.13, z + randf_range(-0.6, 0.6)))

	for chamber in SIDE_CHAMBERS:
		add_side_chamber(float(chamber["z"]), int(chamber["side"]), chamber["tint"], String(chamber["name"]))
	add_upper_gallery(-4.8)
	add_upper_gallery(-11.8)
	build_great_hall()
	add_map_landmarks()

	for z in range(7, -15, -2):
		add_box(Vector3(0, 0.082, z - 0.38), Vector3(0.12, 0.045, 1.15), Color(0.15, 0.1, 0.2), true)
		add_box(Vector3(-2.15, 0.079, z + 0.24), Vector3(0.06, 0.035, 0.76), Color(0.16, 0.12, 0.08), true)
		add_box(Vector3(2.15, 0.079, z + 0.24), Vector3(0.06, 0.035, 0.76), Color(0.16, 0.12, 0.08), true)

	var dais := MeshInstance3D.new()
	var dais_mesh := CylinderMesh.new()
	dais_mesh.top_radius = 2.4
	dais_mesh.bottom_radius = 2.8
	dais_mesh.height = 0.55
	dais_mesh.radial_segments = 28
	dais.mesh = dais_mesh
	dais.material_override = make_material(Color(0.16, 0.11, 0.22), 0.74, 0.12)
	dais.position = Vector3(0, 0.58, -15.5)
	add_child(dais)

	for step in range(4):
		add_box(Vector3(0, 0.18 + step * 0.17, -13.0 - step * 0.72), Vector3(5.6 - step * 0.42, 0.25, 0.72), Color(0.12, 0.1, 0.12))

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 2.58
	ring_mesh.outer_radius = 2.66
	ring.mesh = ring_mesh
	ring.material_override = make_glow_material(Color(0.85, 0.3, 1.0), 0.65)
	ring.rotation_degrees.x = 90
	ring.position = Vector3(0, 0.98, -15.5)
	add_child(ring)

	build_kenzie_gate()
	add_boss_backdrop()
	build_ceiling()

	for i in range(16):
		add_puddle(Vector3(randf_range(-3.9, 3.9), 0.055, randf_range(-14.2, 6.7)), randf_range(0.28, 0.72), randf_range(0.45, 1.25))

	for i in range(120):
		add_mote(Vector3(randf_range(-4.7, 4.7), randf_range(1.4, 4.5), randf_range(-16.5, 6.2)))
	# Ground-level mist motes — smaller, cooler tint, stay near floor
	for i in range(55):
		add_ground_mist_mote(Vector3(randf_range(-4.2, 4.2), randf_range(0.06, 0.28), randf_range(-15.0, 7.0)))

	for i in range(22):
		var decal := make_sprite3d(ASSET_PATH + "stone_tile_%s.png" % ["a", "b", "c", "d"][i % 4], randf_range(0.006, 0.009), Vector3(randf_range(-3.8, 3.8), 0.066, randf_range(-14.5, 6.8)), false)
		decal.rotation_degrees = Vector3(-90, randf_range(-8, 8), 0)
		decal.modulate = Color(0.75, 0.72, 0.78, randf_range(0.25, 0.55))
		add_child(decal)


func build_open_world() -> void:
	# Outdoor adventure topology: a small fantasy valley with a visible temple
	# destination. This replaces the old room/corridor dungeon shell.
	var terrain := MeshInstance3D.new()
	var terrain_mesh := PlaneMesh.new()
	terrain_mesh.size = Vector2(54, 76)
	terrain.mesh = terrain_mesh
	terrain.material_override = make_material(Color(0.055, 0.095, 0.06), 0.88, 0.0)
	terrain.rotation_degrees.x = -90
	terrain.position = Vector3(0, -0.035, -5.0)
	add_child(terrain)

	add_open_area_disc(Vector3(0, 0.012, 22.0), Vector2(18.5, 12.0), Color(0.095, 0.13, 0.075), 36)
	add_path_ribbon([
		Vector3(0, 0.018, 22.0),
		Vector3(-4.8, 0.035, 14.3),
		Vector3(4.5, 0.065, 6.5),
		Vector3(-3.0, 0.095, -1.0),
		Vector3(0.0, 0.12, -9.4),
		Vector3(0.0, 0.14, -20.6),
		Vector3(0.0, 0.18, -32.0)
	])
	add_path_ribbon([
		Vector3(0.5, 0.03, 20.0),
		Vector3(9.0, 0.045, 14.0),
		Vector3(12.0, 0.055, 4.0),
		Vector3(7.0, 0.07, -3.0),
		Vector3(1.0, 0.09, -9.0)
	])
	add_path_ribbon([
		Vector3(-3.5, 0.035, 13.5),
		Vector3(-10.0, 0.055, 4.0),
		Vector3(-13.0, 0.07, -8.0),
		Vector3(-9.0, 0.08, -13.0),
		Vector3(-12.2, 0.09, -20.0),
		Vector3(-2.0, 0.12, -23.4)
	])
	add_path_ribbon([
		Vector3(4.0, 0.08, -10.0),
		Vector3(9.0, 0.095, -16.8),
		Vector3(3.5, 0.13, -23.0)
	])
	add_open_area_disc(Vector3(0, 0.05, -10.0), Vector2(25.5, 16.5), Color(0.105, 0.098, 0.086), 42)
	add_open_area_disc(Vector3(0, 0.1, -33.5), Vector2(14.5, 10.0), Color(0.12, 0.10, 0.13), 34)
	add_open_area_disc(Vector3(12.0, 0.045, 3.2), Vector2(13.0, 10.5), Color(0.06, 0.13, 0.065), 28)
	add_open_area_disc(Vector3(-13.0, 0.055, -8.0), Vector2(12.0, 10.0), Color(0.085, 0.076, 0.11), 28)
	add_open_area_disc(Vector3(-12.2, 0.07, -20.0), Vector2(12.5, 9.5), Color(0.10, 0.082, 0.064), 28)
	add_open_area_disc(Vector3(7.0, 0.075, -17.0), Vector2(10.5, 8.8), Color(0.08, 0.105, 0.095), 24)
	add_open_area_disc(Vector3(16.4, 0.065, 11.6), Vector2(8.0, 6.5), Color(0.055, 0.125, 0.105), 20)
	add_open_area_disc(Vector3(-17.0, 0.065, 2.2), Vector2(8.0, 6.5), Color(0.075, 0.065, 0.12), 20)
	add_open_area_disc(Vector3(12.6, 0.08, -19.2), Vector2(8.0, 6.5), Color(0.12, 0.07, 0.07), 20)

	build_starting_clearing()
	build_winding_valley()
	build_open_world_shortcuts()
	build_exploration_layer()
	build_optional_shrines()
	build_ruined_courtyard()
	build_bridge_gate_transition()
	build_temple_platform()
	build_kenzie_gate()

	for i in range(22):
		add_puddle(Vector3(randf_range(-8.8, 8.8), 0.06, randf_range(-13.0, 18.0)), randf_range(0.24, 0.72), randf_range(0.55, 1.4))

	for i in range(90):
		add_mote(Vector3(randf_range(-18.0, 18.0), randf_range(0.65, 5.2), randf_range(-35.0, 25.0)))

	for i in range(45):
		add_ground_mist_mote(Vector3(randf_range(-15.0, 15.0), randf_range(0.06, 0.28), randf_range(-30.0, 18.0)))


func add_open_area_disc(origin: Vector3, size: Vector2, color: Color, segments: int) -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.04
	mesh.radial_segments = segments
	disc.mesh = mesh
	disc.material_override = make_material(color, 0.86, 0.02)
	disc.position = origin
	disc.scale = Vector3(size.x * 0.5, 1.0, size.y * 0.5)
	add_child(disc)


func add_path_ribbon(points: Array[Vector3]) -> void:
	for i in range(points.size()):
		var p := points[i]
		add_open_area_disc(p, Vector2(6.0 + randf() * 1.8, 4.0 + randf() * 1.2), Color(0.145, 0.125, 0.09), 18)
		if i > 0:
			var prev := points[i - 1]
			var mid := (prev + p) * 0.5
			var delta := p - prev
			var slab := add_box(mid + Vector3(0, 0.01, 0), Vector3(5.3, 0.05, delta.length() + 1.2), Color(0.125, 0.105, 0.08))
			slab.rotation_degrees.y = rad_to_deg(atan2(delta.x, delta.z))
			for s in range(3):
				var stone := add_box(
					mid + Vector3(randf_range(-2.0, 2.0), 0.055, randf_range(-delta.length() * 0.42, delta.length() * 0.42)).rotated(Vector3.UP, atan2(delta.x, delta.z)),
					Vector3(randf_range(0.7, 1.6), 0.045, randf_range(0.55, 1.3)),
					Color(0.19 + randf() * 0.035, 0.18 + randf() * 0.025, 0.16 + randf() * 0.02)
				)
				stone.rotation_degrees.y = randf_range(-20, 20) + slab.rotation_degrees.y


func build_starting_clearing() -> void:
	for i in range(22):
		var a := TAU * float(i) / 22.0
		var radius := randf_range(8.6, 11.0)
		var pos := Vector3(cos(a) * radius, 0.0, 22.0 + sin(a) * radius * 0.66)
		if sin(a) < -0.55 and absf(cos(a)) < 0.35:
			continue
		add_tree(pos, randf_range(0.8, 1.35))
	for i in range(16):
		var a := TAU * float(i) / 16.0 + 0.2
		add_rock(Vector3(cos(a) * randf_range(9.0, 12.0), 0.18, 22.0 + sin(a) * randf_range(5.5, 8.0)), Vector3(randf_range(0.8, 1.8), randf_range(0.35, 0.9), randf_range(0.7, 1.5)))
	add_broken_wall(Vector3(-4.8, 0.55, 17.2), 12)
	add_broken_wall(Vector3(4.8, 0.55, 17.0), -10)
	add_landmark_obelisk(Vector3(0, 0.2, 15.3), Color(0.38, 0.68, 1.0))


func build_winding_valley() -> void:
	var left_cliffs := [
		Vector3(-9.5, 0.35, 14.5), Vector3(-3.0, 0.4, 7.0),
		Vector3(-10.0, 0.5, 1.0), Vector3(-8.0, 0.55, -5.0)
	]
	var right_cliffs := [
		Vector3(4.0, 0.35, 16.0), Vector3(10.0, 0.4, 8.0),
		Vector3(4.5, 0.5, 0.8), Vector3(8.8, 0.55, -4.8)
	]
	for p in left_cliffs + right_cliffs:
		for i in range(6):
			add_rock(p + Vector3(randf_range(-1.8, 1.8), randf_range(0.0, 0.5), randf_range(-1.8, 1.8)), Vector3(randf_range(1.4, 3.2), randf_range(0.9, 2.4), randf_range(1.2, 2.8)))
	for i in range(32):
		var z := randf_range(-2.5, 15.5)
		var side := -1.0 if randf() < 0.5 else 1.0
		add_tree(Vector3(side * randf_range(6.8, 14.0), 0.0, z), randf_range(0.75, 1.35))
	for i in range(7):
		add_box(Vector3(randf_range(-5.5, 5.5), 0.32, randf_range(0.0, 13.5)), Vector3(randf_range(0.7, 1.4), randf_range(0.6, 1.3), randf_range(0.6, 1.2)), Color(0.12, 0.10, 0.095))
	add_arcane_circle(Vector3(11.0, 0.11, 4.0), Color(0.4, 1.0, 0.42))
	add_crystal_cluster(Vector3(12.6, 0.18, 2.4), Color(0.45, 1.0, 0.36))


func build_open_world_shortcuts() -> void:
	# Side routes that make the valley explorable instead of a single path.
	# These are deliberately visible loops: garden trail, library cut, crypt
	# ravine, and north ridge all reconnect to the courtyard/bridge.
	for z in [11.0, 8.0, 5.0, 2.0]:
		add_tree(Vector3(15.5, 0.0, z), randf_range(0.85, 1.25))
		add_tree(Vector3(6.2, 0.0, z + randf_range(-0.5, 0.5)), randf_range(0.7, 1.1))
	for i in range(9):
		add_rock(Vector3(randf_range(6.0, 15.8), 0.18, randf_range(-2.5, 13.5)), Vector3(randf_range(0.55, 1.5), randf_range(0.3, 0.95), randf_range(0.55, 1.4)))
	add_ruined_arch(Vector3(9.4, 0.0, -2.2), -34)
	add_broken_wall(Vector3(10.4, 0.45, -5.2), -24)

	for z in [5.5, 2.5, -0.5, -3.5, -6.5]:
		add_box(Vector3(-7.2, 0.18, z), Vector3(1.6, 0.24, 0.9), Color(0.13, 0.115, 0.10))
		add_rock(Vector3(-15.5 + randf_range(-0.8, 0.8), 0.24, z + randf_range(-0.6, 0.6)), Vector3(randf_range(0.9, 1.9), randf_range(0.55, 1.25), randf_range(0.9, 1.8)))
	add_ruined_arch(Vector3(-8.9, 0.0, 1.2), 42)
	add_landmark_obelisk(Vector3(-13.9, 0.18, -4.5), Color(0.58, 0.48, 1.0))

	for i in range(6):
		add_box(Vector3(-8.8 - float(i) * 0.52, 0.16 + float(i) * 0.06, -13.0 - float(i) * 1.02), Vector3(4.8 - float(i) * 0.18, 0.16, 0.68), Color(0.12, 0.10, 0.09))
	add_broken_wall(Vector3(-6.4, 0.45, -16.2), 28)
	add_landmark_obelisk(Vector3(-4.0, 0.18, -22.0), Color(1.0, 0.72, 0.28))

	for i in range(10):
		add_rock(Vector3(randf_range(3.6, 12.0), 0.22, randf_range(-21.2, -12.0)), Vector3(randf_range(0.65, 1.8), randf_range(0.45, 1.2), randf_range(0.65, 1.8)))
	for z in [-13.8, -16.8, -19.8]:
		add_tree(Vector3(12.2, 0.0, z), randf_range(0.65, 1.05))
		add_box(Vector3(5.1, 0.18, z), Vector3(1.1, 0.22, 1.1), Color(0.12, 0.105, 0.095))
	add_ruined_arch(Vector3(6.6, 0.0, -21.7), -18)


func build_optional_shrines() -> void:
	add_path_ribbon([
		Vector3(11.2, 0.055, 13.0),
		Vector3(16.4, 0.07, 11.6)
	])
	add_path_ribbon([
		Vector3(-10.5, 0.055, 3.0),
		Vector3(-17.0, 0.07, 2.2)
	])
	add_path_ribbon([
		Vector3(7.4, 0.10, -17.6),
		Vector3(12.6, 0.10, -19.2)
	])
	for shrine in SHRINE_DATA:
		add_adventure_shrine(shrine)
	for i in range(10):
		add_tree(Vector3(randf_range(13.4, 19.4), 0.0, randf_range(8.7, 14.2)), randf_range(0.65, 1.05))
	for i in range(8):
		add_rock(Vector3(randf_range(-19.5, -14.5), 0.18, randf_range(-0.7, 5.0)), Vector3(randf_range(0.6, 1.5), randf_range(0.4, 1.0), randf_range(0.6, 1.5)))
	for i in range(8):
		add_rock(Vector3(randf_range(10.0, 15.4), 0.2, randf_range(-22.0, -16.4)), Vector3(randf_range(0.6, 1.6), randf_range(0.4, 1.15), randf_range(0.6, 1.6)))


func build_exploration_layer() -> void:
	# Navigation and optional-place dressing. This pass makes the map read as
	# a hub with three real routes rather than one forward route with detours.
	add_open_area_disc(Vector3(0.0, 0.06, 12.0), Vector2(12.5, 8.0), Color(0.118, 0.105, 0.075), 24)
	add_signpost(Vector3(0.0, 0.12, 12.0), [
		"West: Moon Library",
		"East: Poison Garden",
		"North: Temple Gate"
	])
	add_camp(Vector3(-5.2, 0.08, 10.1), Color(0.42, 0.68, 1.0))
	add_camp(Vector3(7.6, 0.08, 9.8), Color(0.42, 1.0, 0.45))
	add_seal_landmark("LIBRARY SEAL", LIBRARY_SEAL_POS + Vector3(-1.2, 0.0, 1.4), Color(0.55, 0.45, 1.0))
	add_seal_landmark("GARDEN SEAL", GARDEN_SEAL_POS + Vector3(1.3, 0.0, -1.2), Color(0.42, 1.0, 0.36))
	add_seal_landmark("CRYPT SEAL", CRYPT_SEAL_POS + Vector3(-1.0, 0.0, -1.2), Color(1.0, 0.72, 0.28))
	add_side_gate_marker(Vector3(-6.6, 0.12, 4.8), -45, Color(0.55, 0.45, 1.0))
	add_side_gate_marker(Vector3(7.5, 0.12, 6.8), 34, Color(0.42, 1.0, 0.36))
	add_side_gate_marker(Vector3(-6.2, 0.12, -15.6), 22, Color(1.0, 0.72, 0.28))
	for i in range(4):
		add_box(Vector3(-1.8 + float(i) * 1.2, 0.16, 8.6 + sin(float(i)) * 0.25), Vector3(0.72, 0.20, 0.96), Color(0.14, 0.125, 0.10))
	for i in range(4):
		add_box(Vector3(5.2 + float(i) * 0.8, 0.14, -5.2 - float(i) * 0.7), Vector3(0.68, 0.18, 0.9), Color(0.10, 0.13, 0.10))


func build_ruined_courtyard() -> void:
	for x in [-8.0, -4.0, 4.0, 8.0]:
		for z in [-14.2, -8.0, -3.8]:
			var broken_height := randf_range(1.2, 3.7)
			var col := make_cylinder(Vector3(x + randf_range(-0.35, 0.35), broken_height * 0.5, z + randf_range(-0.35, 0.35)), 0.34, 0.38, broken_height, Color(0.14, 0.13, 0.12))
			col.rotation_degrees.x = randf_range(-3, 3)
			col.rotation_degrees.z = randf_range(-5, 5)
			add_child(col)
	add_ruined_arch(Vector3(-6.8, 0.0, -10.2), 90)
	add_ruined_arch(Vector3(6.8, 0.0, -10.2), -90)
	add_stair_run(Vector3(0.0, 0.05, -16.4), 7, Vector3(0, 0, -1), 7.4)
	add_arcane_circle(Vector3(-11.5, 0.11, -8.0), Color(0.55, 0.45, 1.0))
	add_sarcophagus(Vector3(-10.8, 0.18, -19.0), 22)
	add_crystal_cluster(Vector3(-12.8, 0.16, -17.2), Color(1.0, 0.72, 0.28))
	for i in range(24):
		add_rock(Vector3(randf_range(-12.5, 12.5), 0.12, randf_range(-17.0, -4.0)), Vector3(randf_range(0.35, 1.2), randf_range(0.22, 0.7), randf_range(0.35, 1.1)))


func build_bridge_gate_transition() -> void:
	add_box(Vector3(0, 0.2, -22.4), Vector3(7.0, 0.28, 7.8), Color(0.105, 0.095, 0.085))
	for i in range(8):
		var z := -25.4 + float(i) * 0.82
		var plank := add_box(Vector3(0, 0.42, z), Vector3(6.2, 0.16, 0.44), Color(0.20, 0.13, 0.07))
		plank.rotation_degrees.y = randf_range(-2.5, 2.5)
	for side in [-1, 1]:
		for z in [-26.0, -23.4, -20.8]:
			add_box(Vector3(side * 3.6, 0.92, z), Vector3(0.28, 1.55, 0.28), Color(0.11, 0.095, 0.085))
		add_box(Vector3(side * 4.5, 0.22, -22.8), Vector3(1.5, 0.22, 8.5), Color(0.05, 0.07, 0.095), true)
	add_landmark_obelisk(Vector3(0, 0.2, -26.5), Color(0.95, 0.32, 1.0))


func build_temple_platform() -> void:
	for step in range(8):
		add_box(Vector3(0, 0.22 + step * 0.16, -28.0 - step * 0.72), Vector3(9.8 - step * 0.44, 0.24, 0.72), Color(0.13, 0.115, 0.13))
	var dais := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 3.2
	mesh.bottom_radius = 4.2
	mesh.height = 0.82
	mesh.radial_segments = 32
	dais.mesh = mesh
	dais.material_override = make_material(Color(0.16, 0.11, 0.20), 0.72, 0.1)
	dais.position = Vector3(0, 1.18, GOAL_Z - 0.15)
	add_child(dais)
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 3.45
	ring_mesh.outer_radius = 3.56
	ring.mesh = ring_mesh
	ring.material_override = make_glow_material(Color(0.85, 0.3, 1.0), 1.1)
	ring.rotation_degrees.x = 90
	ring.position = Vector3(0, 1.64, GOAL_Z - 0.15)
	add_child(ring)
	dungeon_animatables.append(ring)
	for side in [-1, 1]:
		add_ruined_arch(Vector3(side * 5.2, 0.55, GOAL_Z + 0.4), 0)
		add_torch(Vector3(side * 4.5, 2.2, GOAL_Z + 2.2))
	var temple_light := OmniLight3D.new()
	temple_light.light_color = Color(0.78, 0.28, 1.0)
	temple_light.light_energy = 5.5
	temple_light.omni_range = 16.0
	temple_light.shadow_enabled = true
	temple_light.position = Vector3(0, 4.0, GOAL_Z + 0.2)
	add_child(temple_light)


func add_tree(pos: Vector3, tree_scale: float) -> void:
	var trunk := make_cylinder(pos + Vector3(0, 0.65 * tree_scale, 0), 0.13 * tree_scale, 0.18 * tree_scale, 1.3 * tree_scale, Color(0.18, 0.10, 0.045))
	add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := CylinderMesh.new()
	crown_mesh.bottom_radius = 0.95 * tree_scale
	crown_mesh.top_radius = 0.08 * tree_scale
	crown_mesh.height = 2.2 * tree_scale
	crown_mesh.radial_segments = 9
	crown.mesh = crown_mesh
	crown.material_override = make_material(Color(0.035 + randf() * 0.025, 0.15 + randf() * 0.055, 0.055), 0.9, 0.0)
	crown.position = pos + Vector3(0, 1.85 * tree_scale, 0)
	crown.rotation_degrees.y = randf_range(0, 45)
	add_child(crown)


func add_rock(pos: Vector3, rock_scale: Vector3) -> void:
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.7
	mesh.height = 1.2
	mesh.radial_segments = 8
	mesh.rings = 4
	rock.mesh = mesh
	rock.material_override = make_material(Color(0.105 + randf() * 0.035, 0.105 + randf() * 0.03, 0.10 + randf() * 0.025), 0.92, 0.03)
	rock.position = pos
	rock.scale = rock_scale
	rock.rotation_degrees = Vector3(randf_range(-10, 10), randf_range(0, 180), randf_range(-8, 8))
	add_child(rock)


func add_broken_wall(pos: Vector3, y_rot: float) -> void:
	for i in range(5):
		var segment := make_box(Vector3(-2.0 + i * 1.05, 0.0, 0.0), Vector3(randf_range(0.75, 1.05), randf_range(0.55, 1.45), 0.42), Color(0.12, 0.11, 0.10))
		segment.position.y = segment.scale.y * 0.5
		var holder := Node3D.new()
		holder.position = pos
		holder.rotation_degrees.y = y_rot
		holder.add_child(segment)
		add_child(holder)


func add_landmark_obelisk(pos: Vector3, glow_color: Color) -> void:
	add_box(pos + Vector3(0, 1.2, 0), Vector3(0.62, 2.4, 0.62), Color(0.11, 0.10, 0.12))
	var cap := make_sphere(pos + Vector3(0, 2.62, 0), 0.26, glow_color, true)
	add_child(cap)
	var light := OmniLight3D.new()
	light.light_color = glow_color
	light.light_energy = 2.2
	light.omni_range = 8.0
	light.position = pos + Vector3(0, 2.6, 0)
	add_child(light)


func add_ruined_arch(pos: Vector3, y_rot: float) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees.y = y_rot
	holder.add_child(make_box(Vector3(-1.25, 1.6, 0), Vector3(0.42, 3.2, 0.5), Color(0.12, 0.11, 0.105)))
	holder.add_child(make_box(Vector3(1.25, 1.35, 0), Vector3(0.42, 2.7, 0.5), Color(0.12, 0.11, 0.105)))
	holder.add_child(make_box(Vector3(0, 3.05, 0), Vector3(3.1, 0.46, 0.55), Color(0.13, 0.115, 0.105)))
	add_child(holder)


func add_stair_run(origin: Vector3, steps: int, dir: Vector3, width: float) -> void:
	var n_dir := dir.normalized()
	for i in range(steps):
		var pos := origin + n_dir * float(i) * 0.62 + Vector3.UP * (0.08 + i * 0.09)
		add_box(pos, Vector3(width - float(i) * 0.25, 0.16, 0.62), Color(0.13, 0.12, 0.11))


func add_signpost(pos: Vector3, lines: Array[String]) -> void:
	var post := make_cylinder(pos + Vector3(0, 0.72, 0), 0.08, 0.11, 1.44, Color(0.22, 0.14, 0.07))
	add_child(post)
	for i in range(lines.size()):
		var y := 1.45 + float(i) * 0.24
		var board := add_box(pos + Vector3(0, y, 0), Vector3(2.9, 0.18, 0.18), Color(0.28, 0.18, 0.08))
		board.rotation_degrees.y = -18.0 + float(i) * 18.0
		var label := Label3D.new()
		label.text = lines[i]
		label.font_size = 22
		label.modulate = Color(1.0, 0.88, 0.55)
		label.outline_size = 8
		label.outline_modulate = Color(0, 0, 0, 0.85)
		label.position = pos + Vector3(0, y + 0.18, 0.08)
		label.rotation_degrees = Vector3(0, board.rotation_degrees.y, 0)
		label.pixel_size = 0.012
		add_child(label)


func add_camp(pos: Vector3, color: Color) -> void:
	add_open_area_disc(pos + Vector3(0, 0.02, 0), Vector2(3.4, 2.6), Color(0.10, 0.085, 0.058), 16)
	for a in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
		var log := add_box(pos + Vector3(cos(a) * 0.45, 0.16, sin(a) * 0.45), Vector3(0.9, 0.16, 0.22), Color(0.25, 0.13, 0.055))
		log.rotation_degrees.y = rad_to_deg(a)
	var flame := make_sphere(pos + Vector3(0, 0.46, 0), 0.18, color, true)
	add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.0
	light.omni_range = 5.0
	light.position = pos + Vector3(0, 0.8, 0)
	add_child(light)


func add_seal_landmark(text: String, pos: Vector3, color: Color) -> void:
	add_landmark_obelisk(pos, color)
	var label := Label3D.new()
	label.text = text
	label.font_size = 26
	label.modulate = color.lightened(0.25)
	label.outline_size = 10
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.pixel_size = 0.013
	label.position = pos + Vector3(0, 3.15, 0)
	add_child(label)


func add_side_gate_marker(pos: Vector3, y_rot: float, color: Color) -> void:
	add_ruined_arch(pos, y_rot)
	var orb := make_sphere(pos + Vector3(0, 2.5, 0), 0.18, color, true)
	add_child(orb)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.8
	light.omni_range = 6.0
	light.position = pos + Vector3(0, 2.4, 0)
	add_child(light)


func add_adventure_shrine(data: Dictionary) -> void:
	var root := Node3D.new()
	root.name = String(data["id"]) + "_shrine"
	root.position = data["pos"]
	root.set_meta("shrine_id", String(data["id"]))
	root.set_meta("title", String(data["title"]))
	root.set_meta("reward", String(data["reward"]))
	root.set_meta("phase", randf() * TAU)
	var color: Color = data["color"]
	var base := make_cylinder(Vector3(0, 0.12, 0), 0.95, 1.18, 0.24, color.darkened(0.45))
	root.add_child(base)
	var ring := make_torus(0.62, 0.72, color, 1.25)
	ring.rotation_degrees.x = 90
	ring.position.y = 0.34
	ring.set_meta("spin_y_deg_s", 28.0)
	root.add_child(ring)
	dungeon_animatables.append(ring)
	var orb := make_sphere(Vector3(0, 0.82, 0), 0.24, color.lightened(0.18), true)
	root.add_child(orb)
	var beam := make_cylinder(Vector3(0, 2.2, 0), 0.025, 0.08, 3.4, color, Vector3.ZERO, true)
	root.add_child(beam)
	var label := Label3D.new()
	label.text = String(data["title"]).to_upper()
	label.font_size = 24
	label.modulate = color.lightened(0.2)
	label.outline_size = 10
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.pixel_size = 0.012
	label.position = Vector3(0, 3.95, 0)
	root.add_child(label)
	var shrine_light := OmniLight3D.new()
	shrine_light.light_color = color
	shrine_light.light_energy = 2.3
	shrine_light.omni_range = 6.5
	shrine_light.position = Vector3(0, 1.3, 0)
	root.add_child(shrine_light)
	add_child(root)
	shrine_nodes.append(root)


func build_kenzie_gate() -> void:
	# Iron portcullis at KENZIE_GATE_Z — visible until all 3 seals are collected.
	kenzie_gate_node = Node3D.new()
	kenzie_gate_node.name = "KenzieGate"
	var gz := KENZIE_GATE_Z
	# Vertical bars
	var bar_color := Color(0.14, 0.11, 0.08)
	for i in range(7):
		var bx := -3.0 + float(i) * 1.0
		var bar := make_box(Vector3(bx, 2.8, gz), Vector3(0.16, 5.6, 0.22), bar_color)
		kenzie_gate_node.add_child(bar)
	# Horizontal crossbars
	kenzie_gate_node.add_child(make_box(Vector3(0, 1.1, gz), Vector3(6.6, 0.22, 0.22), bar_color))
	kenzie_gate_node.add_child(make_box(Vector3(0, 3.2, gz), Vector3(6.6, 0.22, 0.22), bar_color))
	kenzie_gate_node.add_child(make_box(Vector3(0, 5.2, gz), Vector3(6.6, 0.22, 0.22), bar_color))
	# Gatepost pillars
	kenzie_gate_node.add_child(make_box(Vector3(-3.55, 3.2, gz), Vector3(0.5, 6.4, 0.5), Color(0.12, 0.095, 0.10)))
	kenzie_gate_node.add_child(make_box(Vector3( 3.55, 3.2, gz), Vector3(0.5, 6.4, 0.5), Color(0.12, 0.095, 0.10)))
	# Lintel
	kenzie_gate_node.add_child(make_box(Vector3(0, 6.55, gz), Vector3(7.8, 0.38, 0.45), Color(0.12, 0.095, 0.10)))
	# Glowing seal-lock orbs on top
	for side in [-1, 1]:
		var orb := make_sphere(Vector3(side * 3.5, 7.1, gz), 0.22, Color(0.85, 0.28, 1.0), true)
		kenzie_gate_node.add_child(orb)
	# Red-purple warning light
	var gate_light := OmniLight3D.new()
	gate_light.light_color = Color(0.78, 0.18, 0.55)
	gate_light.light_energy = 1.8
	gate_light.omni_range = 7.0
	gate_light.shadow_enabled = false
	gate_light.position = Vector3(0, 3.5, gz + 0.5)
	kenzie_gate_node.add_child(gate_light)
	add_child(kenzie_gate_node)


func build_great_hall() -> void:
	# ─────────────────────────────────────────────────────────────────────────
	# THE GREAT HALL — Zelda-style open chamber, z=1.5 to z=-5.5
	# Wide stone floor, massive pillars, central altar with spinning gem,
	# side crystal pools, and overhead torchlight from the pillar capitals.
	# ─────────────────────────────────────────────────────────────────────────

	# Extended floor panels — uniform 2×2 grid, Zelda stone-tile feel
	for tx_i in range(-4, 5):
		for tz_i in range(-3, 4):
			var tx := float(tx_i) * 2.2
			var tz := float(tz_i) * 2.0 - 2.0
			if absf(tx) > 8.8 or tz > 1.8 or tz < -5.8:
				continue
			var checker := (tx_i + tz_i) % 2
			var warm := 0.072 + checker * 0.016
			var tile_color := Color(warm * 1.08, warm * 0.94, warm * 0.87)
			add_box(Vector3(tx, 0.022, tz), Vector3(2.05, 0.042, 2.05), tile_color)

	# Wide side walls — deep into the hall at x=±9.5
	for side in [-1, 1]:
		for z_i in range(0, 12):
			var wz := 1.2 - float(z_i) * 0.62
			if wz < -5.8 or wz > 1.8:
				continue
			for row in range(0, 6):
				var wy := 0.42 + row * 1.0
				var depth := randf_range(0.28, 0.46)
				var tint := randf_range(0.082, 0.138)
				add_box(
					Vector3(side * 9.55, wy, wz + randf_range(-0.04, 0.04)),
					Vector3(depth, randf_range(0.8, 1.06), randf_range(1.3, 1.7)),
					Color(tint * 1.18, tint * 1.02, tint * 0.92)
				)

	# Transition pilasters — short wall caps connecting corridor walls to Great Hall walls
	for side in [-1, 1]:
		for sign_z in [1.0, -1.0]:
			var cap_z: float = GREAT_HALL_Z_MAX if sign_z > 0 else GREAT_HALL_Z_MIN
			# Angled wedge block to bridge from x=6.05 to x=9.55
			for step in range(3):
				var sx := 6.05 + float(step) * 1.15
				var tint := randf_range(0.09, 0.13)
				for row in range(0, 5):
					add_box(
						Vector3(side * sx, 0.42 + row * 1.0, cap_z),
						Vector3(0.9, randf_range(0.78, 1.05), randf_range(0.6, 0.9)),
						Color(tint * 1.1, tint, tint * 0.92)
					)

	# Header beams across the entrance and exit of the Great Hall
	add_box(Vector3(0, 7.05, GREAT_HALL_Z_MAX), Vector3(19.5, 0.42, 0.55), Color(0.095, 0.075, 0.095))
	add_box(Vector3(0, 7.05, GREAT_HALL_Z_MIN), Vector3(19.5, 0.42, 0.55), Color(0.095, 0.075, 0.095))

	# Six massive stone pillars — 3 pairs flanking the hall
	var pillar_zs := [0.5, -2.0, -4.5]
	var pillar_x := 5.85
	for pz in pillar_zs:
		for side in [-1, 1]:
			# Main shaft — chunky 8-sided cylinder
			var pillar := MeshInstance3D.new()
			var pmesh := CylinderMesh.new()
			pmesh.top_radius = 0.68
			pmesh.bottom_radius = 0.78
			pmesh.height = 7.8
			pmesh.radial_segments = 8
			pillar.mesh = pmesh
			pillar.material_override = make_material(Color(0.115, 0.095, 0.128), 0.86, 0.05)
			pillar.position = Vector3(side * pillar_x, 3.9, float(pz))
			add_child(pillar)
			# Stepped base
			add_box(Vector3(side * pillar_x, 0.22, float(pz)), Vector3(1.9, 0.44, 1.9), Color(0.10, 0.082, 0.11))
			add_box(Vector3(side * pillar_x, 0.55, float(pz)), Vector3(1.55, 0.32, 1.55), Color(0.105, 0.088, 0.115))
			# Capital
			add_box(Vector3(side * pillar_x, 7.42, float(pz)), Vector3(1.85, 0.38, 1.85), Color(0.10, 0.082, 0.11))
			add_box(Vector3(side * pillar_x, 7.72, float(pz)), Vector3(2.3, 0.22, 0.55), Color(0.092, 0.075, 0.10))
			# Torch mounted outward on pillar
			add_torch(Vector3(side * (pillar_x + 0.95), 2.55, float(pz)))

	# Central altar dais — raised octagonal platform
	var altar_dais := MeshInstance3D.new()
	var dais_mesh := CylinderMesh.new()
	dais_mesh.top_radius = 1.35
	dais_mesh.bottom_radius = 1.65
	dais_mesh.height = 0.65
	dais_mesh.radial_segments = 8
	altar_dais.mesh = dais_mesh
	altar_dais.material_override = make_material(Color(0.155, 0.105, 0.215), 0.72, 0.14)
	altar_dais.position = Vector3(0, 0.32, -2.0)
	add_child(altar_dais)
	# Altar top slab
	add_box(Vector3(0, 0.72, -2.0), Vector3(2.1, 0.18, 2.1), Color(0.17, 0.12, 0.24))

	# Spinning arcane gem on the altar
	var gem := MeshInstance3D.new()
	var gem_mesh := SphereMesh.new()
	gem_mesh.radius = 0.34
	gem_mesh.height = 0.68
	gem_mesh.radial_segments = 12
	gem_mesh.rings = 8
	gem.mesh = gem_mesh
	gem.material_override = make_glow_material(Color(0.82, 0.28, 1.0), 3.2)
	gem.position = Vector3(0, 1.52, -2.0)
	add_child(gem)
	gem.set_meta("spin_y_deg_s", 48.0)
	dungeon_animatables.append(gem)

	# Gem glow light
	var gem_light := OmniLight3D.new()
	gem_light.light_color = Color(0.78, 0.32, 1.0)
	gem_light.light_energy = 3.2
	gem_light.omni_range = 10.5
	gem_light.shadow_enabled = false
	gem_light.position = Vector3(0, 1.65, -2.0)
	add_child(gem_light)

	# Arcane circles on floor around altar
	add_arcane_circle(Vector3(0, 0.045, -2.0), Color(0.82, 0.28, 1.0))
	# Offset second circle slightly for depth
	add_arcane_circle(Vector3(0, 0.038, -2.0), Color(0.45, 0.18, 0.78))

	# Floor runes — glowing inlay lines radiating from altar
	for angle_i in range(4):
		var angle := float(angle_i) * TAU / 4.0 + TAU / 8.0
		var rx := cos(angle) * 2.8
		var rz := sin(angle) * 2.8
		var rune_box := add_box(Vector3(rx, 0.038, -2.0 + rz), Vector3(0.055, 0.02, 2.2), Color(0.72, 0.22, 0.95), true)
		rune_box.rotation_degrees.y = rad_to_deg(angle)

	# Side floor crystal pools — decorative accent points at x=±7.5
	for side in [-1, 1]:
		# Glowing floor pool
		add_puddle(Vector3(side * 7.4, 0.065, -1.2), 0.95, 1.6)
		add_puddle(Vector3(side * 7.2, 0.062, -3.4), 0.85, 1.4)
		# Crystal clusters
		add_crystal_cluster(Vector3(side * 7.6, 0.0, -0.6), Color(0.55, 0.28, 0.9))
		add_crystal_cluster(Vector3(side * 8.0, 0.0, -2.0), Color(0.35, 0.18, 0.78))
		add_crystal_cluster(Vector3(side * 7.5, 0.0, -3.8), Color(0.62, 0.22, 0.85))
		# Wall banners on Great Hall side walls
		add_banner(Vector3(side * 9.4, 3.4, -0.5), 0.0 if side < 0 else 180.0)
		add_banner(Vector3(side * 9.4, 3.4, -3.5), 0.0 if side < 0 else 180.0)

	# Overhead ambient fill lights in the hall (warm purple/gold tone)
	var fill_zs := [0.0, -2.0, -4.5]
	for fz in fill_zs:
		var fill_light := OmniLight3D.new()
		fill_light.light_color = Color(0.72, 0.58, 0.88)
		fill_light.light_energy = 1.1
		fill_light.omni_range = 8.5
		fill_light.shadow_enabled = false
		fill_light.position = Vector3(0, 5.8, float(fz))
		add_child(fill_light)


func build_ceiling() -> void:
	# Long edge beams that run the length of the corridor
	for side in [-1, 1]:
		add_box(Vector3(side * 5.55, 6.8, -4.0), Vector3(0.52, 0.38, 28.0), Color(0.08, 0.065, 0.08))

	# Side vault panels. The center lane stays open so the camera never clips through a roof.
	var z := 8.2
	while z > -17.5:
		var panel_depth := randf_range(1.55, 2.1)
		if randf() < 0.18:
			# Gap — spawn a volumetric-style light shaft through it
			add_light_beam(Vector3(randf_range(-2.0, 2.0), 6.35, z - panel_depth * 0.5), randf_range(-5, 5))
		else:
			var warm := randf_range(0.065, 0.095)
			for side in [-1, 1]:
				add_box(
					Vector3(side * 3.85, 7.05, z - panel_depth * 0.5),
					Vector3(3.2, randf_range(0.18, 0.32), panel_depth),
					Color(warm * 1.1, warm * 0.96, warm * 0.88)
				)
		z -= panel_depth + randf_range(0.0, 0.3)

	# Vault ribs sit high and thin, reading as architecture without crossing the camera.
	for col_z in range(7, -18, -5):
		add_box(Vector3(0, 7.18, col_z), Vector3(10.8, 0.18, 0.36), Color(0.1, 0.08, 0.1))
		# Central keystone drop
		add_box(Vector3(0, 6.62, col_z), Vector3(0.5, 0.46, 0.32), Color(0.14, 0.1, 0.13))

	# Stalactite-style ceiling drips stay near the edges.
	for _i in range(14):
		var sx := randf_range(3.1, 4.75) * (-1 if randf() < 0.5 else 1)
		var sz := randf_range(-14.5, 6.5)
		var drip_h := randf_range(0.18, 0.55)
		var node := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = randf_range(0.03, 0.07)
		mesh.bottom_radius = 0.0
		mesh.height = drip_h
		node.mesh = mesh
		node.position = Vector3(sx, 6.78 - drip_h * 0.5, sz)
		node.material_override = make_material(Color(0.1, 0.08, 0.09), 0.88, 0.0)
		add_child(node)


func build_riley() -> void:
	player = Node3D.new()
	player.name = "Riley"
	player.scale = Vector3.ONE * 0.96
	player.position = Vector3(0, 0, PLAYER_START_Z)
	add_child(player)

	player.add_child(make_cylinder(Vector3(0, 1.05, 0), 0.36, 0.46, 1.25, Color(0.05, 0.07, 0.13)))
	player.add_child(make_sphere(Vector3(0, 1.88, 0), 0.32, Color(0.94, 0.78, 0.65)))
	var hair := make_sphere(Vector3(0, 2.02, -0.04), 0.34, Color(0.29, 0.17, 0.09))
	hair.scale = Vector3(1, 0.55, 0.95)
	player.add_child(hair)
	player.add_child(make_box(Vector3(0, 1.78, 0.3), Vector3(0.58, 0.18, 0.05), Color(0.03, 0.04, 0.06)))
	# Glasses — boosted emission so they glow through the dark dungeon
	var glasses := make_box(Vector3(0, 1.91, 0.33), Vector3(0.45, 0.045, 0.035), Color(0.75, 0.94, 1.0))
	glasses.material_override = make_glow_material(Color(0.75, 0.94, 1.0), 1.8)
	player.add_child(glasses)
	player.add_child(make_box(Vector3(-0.22, 1.94, 0.18), Vector3(0.08, 0.06, 0.28), Color(0.02, 0.025, 0.035)))
	player.add_child(make_box(Vector3(0.22, 1.94, 0.18), Vector3(0.08, 0.06, 0.28), Color(0.02, 0.025, 0.035)))
	# Belt — bright cyan glow strip
	var belt := make_box(Vector3(0, 0.78, 0.04), Vector3(0.78, 0.1, 0.1), Color(0.15, 0.84, 1.0))
	belt.material_override = make_glow_material(Color(0.15, 0.84, 1.0), 1.6)
	player.add_child(belt)
	player.add_child(make_box(Vector3(-0.34, 1.72, -0.18), Vector3(0.12, 0.5, 0.05), Color(0.05, 0.07, 0.13)))
	player.add_child(make_box(Vector3(0.34, 1.72, -0.18), Vector3(0.12, 0.5, 0.05), Color(0.05, 0.07, 0.13)))

	player.add_child(make_cylinder(Vector3(-0.46, 1.15, 0), 0.09, 0.11, 0.8, Color(0.05, 0.07, 0.13), Vector3(0, 0, 14)))
	player_arm = Node3D.new()
	player_arm.position = Vector3(0.46, 1.35, 0.02)
	player_arm.rotation_degrees.z = -20
	player.add_child(player_arm)
	player_arm.add_child(make_cylinder(Vector3(0, -0.25, 0), 0.09, 0.11, 0.72, Color(0.05, 0.07, 0.13)))
	player_arm.add_child(make_sphere(Vector3(0, -0.68, 0), 0.105, Color(0.94, 0.78, 0.65)))

	sword = Node3D.new()
	sword.position = Vector3(0.7, 1.2, 0.18)
	sword.rotation_degrees.z = -43
	player.add_child(sword)
	var blade := make_box(Vector3(0, 0.5, 0), Vector3(0.055, 1.18, 0.035), Color(0.84, 0.96, 1.0))
	blade.material_override = make_glow_material(Color(0.84, 0.96, 1.0), 2.4)
	sword.add_child(blade)
	sword.add_child(make_box(Vector3(0, -0.1, 0), Vector3(0.34, 0.055, 0.055), Color(0.23, 0.14, 0.07)))
	# Sword point light — illuminates dungeon around Riley at all times, pulses on attack
	sword_light = OmniLight3D.new()
	sword_light.light_color = Color(0.62, 0.9, 1.0)
	sword_light.light_energy = 1.4
	sword_light.omni_range = 3.5
	sword_light.shadow_enabled = false
	sword_light.position = Vector3(0, 0.7, 0)
	sword.add_child(sword_light)
	player_damage_light = OmniLight3D.new()
	player_damage_light.name = "RileyDamageFlashLight"
	player_damage_light.light_color = Color(1.0, 0.08, 0.03)
	player_damage_light.light_energy = 0.0
	player_damage_light.omni_range = 4.0
	player_damage_light.shadow_enabled = false
	player_damage_light.position = Vector3(0, 1.2, 0)
	player.add_child(player_damage_light)

	player.add_child(make_cylinder(Vector3(-0.18, 0.32, 0), 0.11, 0.13, 0.74, Color(0.03, 0.04, 0.06)))
	player.add_child(make_cylinder(Vector3(0.18, 0.32, 0), 0.11, 0.13, 0.74, Color(0.03, 0.04, 0.06)))
	var headband_tail := make_box(Vector3(0.28, 1.92, -0.34), Vector3(0.08, 0.42, 0.04), Color(0.15, 0.84, 1.0))
	headband_tail.material_override = make_glow_material(Color(0.15, 0.84, 1.0), 1.6)
	headband_tail.rotation_degrees = Vector3(0, 18, -18)
	player.add_child(headband_tail)

	# Sprite sits slightly behind so 3D geometry renders in front of it — composite look
	player_art = make_sprite3d(ASSET_PATH + "riley_back.png", 0.0085, Vector3(0, 1.22, -0.14))
	player_art.scale = Vector3(1.0, 1.0, 1.0)
	player_art.modulate = Color(1.0, 1.0, 1.0, 0.72)  # partial transparency so 3D body reads through
	player_art.set_meta("yaw_offset", deg_to_rad(26.0))
	player.add_child(player_art)
	# Show full 3D body — geometry + sprite creates a lit-painted-art composite
	sword.position = Vector3(0.92, 1.28, 0.28)
	sword.rotation_degrees = Vector3(0, -18, -54)
	player_shadow = add_shadow_disc(Vector3(0, 0.07, PLAYER_START_Z), Vector2(1.5, 0.72), 0.38)


func build_kenzie() -> void:
	kenzie = Node3D.new()
	kenzie.name = "Kenzie"
	kenzie.scale = Vector3.ONE * 1.22
	kenzie.position = Vector3(0, 0.72, GOAL_Z - 0.15)
	add_child(kenzie)

	# Robe — strong purple emission, foundation of her visual presence
	var robe := make_cylinder(Vector3(0, 1.35, 0), 0.75, 1.05, 2.1, Color(0.49, 0.16, 0.85))
	robe.material_override = make_glow_material(Color(0.49, 0.16, 0.85), 1.2)
	kenzie.add_child(robe)
	kenzie.add_child(make_sphere(Vector3(0, 2.72, 0), 0.54, Color(0.95, 0.82, 0.76)))
	var hair := make_sphere(Vector3(0, 2.83, -0.05), 0.58, Color(0.23, 0.15, 0.11))
	hair.scale = Vector3(1, 0.75, 0.94)
	kenzie.add_child(hair)
	# Crown — bright gold
	var crown_band := make_cylinder(Vector3(0, 3.22, 0), 0.36, 0.42, 0.16, Color(1.0, 0.84, 0.38))
	crown_band.material_override = make_glow_material(Color(1.0, 0.84, 0.38), 1.4)
	kenzie.add_child(crown_band)

	for i in range(5):
		var spike := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = 0.06
		mesh.height = 0.28
		mesh.radial_segments = 8
		spike.mesh = mesh
		spike.material_override = make_glow_material(Color(1.0, 0.84, 0.38), 1.2)
		spike.position = Vector3(-0.24 + i * 0.12, 3.42 + (0.02 if i % 2 else 0.09), 0)
		kenzie.add_child(spike)

	kenzie_staff = Node3D.new()
	kenzie_staff.position = Vector3(0.9, 1.05, 0.1)
	kenzie_staff.rotation_degrees.z = -7
	kenzie.add_child(kenzie_staff)
	kenzie_staff.add_child(make_cylinder(Vector3(0, 0.7, 0), 0.035, 0.04, 2.1, Color(0.16, 0.1, 0.06)))
	# Staff orb — strong purple glow, casts light on her face
	var staff_orb := make_sphere(Vector3(0, 1.82, 0), 0.22, Color(0.85, 0.25, 1.0))
	staff_orb.material_override = make_glow_material(Color(0.85, 0.25, 1.0), 2.2)
	kenzie_staff.add_child(staff_orb)
	kenzie_aura_light = OmniLight3D.new()
	kenzie_aura_light.name = "KenzieAuraLight"
	kenzie_aura_light.light_color = Color(0.85, 0.25, 1.0)
	kenzie_aura_light.light_energy = 1.2
	kenzie_aura_light.omni_range = 4.8
	kenzie_aura_light.shadow_enabled = false
	kenzie_aura_light.position = Vector3(0, 1.82, 0)
	kenzie_staff.add_child(kenzie_aura_light)

	# Sprite behind the 3D body — same composite approach as Riley
	kenzie_art = make_sprite3d(ASSET_PATH + "kenzie_front.png", 0.013, Vector3(0, 2.05, -0.12))
	kenzie_art.scale = Vector3(1.18, 1.18, 1.18)
	kenzie_art.modulate = Color(1.0, 1.0, 1.0, 0.65)
	kenzie.add_child(kenzie_art)
	# 3D body is fully visible — no hide call

	kenzie_shield = Node3D.new()
	kenzie_shield.name = "BroccoliShield"
	kenzie_shield.position = Vector3(0, 2.26, 0.08)
	kenzie.add_child(kenzie_shield)
	var shield_ring_a := make_torus(1.25, 1.34, Color(0.85, 0.25, 1.0), 0.85)
	shield_ring_a.rotation_degrees.x = 90
	kenzie_shield.add_child(shield_ring_a)
	var shield_ring_b := make_torus(0.94, 1.0, Color(0.28, 0.95, 0.42), 0.45)
	shield_ring_b.rotation_degrees = Vector3(90, 0, 90)
	kenzie_shield.add_child(shield_ring_b)
	for i in range(6):
		var orbit := Node3D.new()
		orbit.set_meta("orbit_angle", TAU * i / 6.0)
		orbit.set_meta("orbit_radius", 1.35 + (0.16 if i % 2 else 0.0))
		var broccoli := make_broccoli_mesh()
		broccoli.scale = Vector3.ONE * 0.42
		orbit.add_child(broccoli)
		kenzie_shield.add_child(orbit)
	kenzie_shadow = add_shadow_disc(Vector3(0, 0.08, GOAL_Z - 0.15), Vector2(2.2, 1.0), 0.5)


func build_ui() -> void:
	hud = CanvasLayer.new()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)

	damage_flash = ColorRect.new()
	damage_flash.color = Color(0.9, 0.0, 0.0, 0.0)
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(damage_flash)

	start_screen = make_screen()
	hud.add_child(start_screen)
	var start_card := make_card()
	start_screen.add_child(start_card)
	start_card.add_child(make_title("Riley vs Kenzie", "Valley Temple Adventure"))
	var start_copy := make_label("Kenzie waits on a raised temple ruin beyond the forest path. Explore the valley, collect the three seals, open the gate, and break her broccoli shield.", 18, Color(0.85, 0.88, 1.0))
	start_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_copy.custom_minimum_size = Vector2(700, 70)
	start_card.add_child(start_copy)
	var start_button := make_button("Enter Valley")
	start_button.pressed.connect(start_game)
	start_card.add_child(start_button)
	start_screen.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			start_game()
	)

	over_screen = make_screen()
	over_screen.visible = false
	hud.add_child(over_screen)
	var over_card := make_card()
	over_screen.add_child(over_card)
	var over_title := make_title("Game Over", "Kenzie wins this round")
	over_title.name = "OverTitleBlock"
	over_card.add_child(over_title)
	var retry := make_button("Play Again")
	retry.pressed.connect(start_game)
	over_card.add_child(retry)
	over_screen.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			start_game()
	)

	victory_cutscene_screen = make_screen()
	victory_cutscene_screen.name = "VictoryCutscene"
	victory_cutscene_screen.visible = false
	hud.add_child(victory_cutscene_screen)
	var cutscene_outer := VBoxContainer.new()
	cutscene_outer.set_anchors_preset(Control.PRESET_CENTER)
	cutscene_outer.position = Vector2(-430, -285)
	cutscene_outer.size = Vector2(860, 570)
	cutscene_outer.alignment = BoxContainer.ALIGNMENT_CENTER
	cutscene_outer.add_theme_constant_override("separation", 12)
	victory_cutscene_screen.add_child(cutscene_outer)
	cutscene_title_label = make_label("MISSION DEBRIEF", 34, Color(0.88, 0.92, 1.0))
	cutscene_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cutscene_outer.add_child(cutscene_title_label)
	cutscene_image_panel = ColorRect.new()
	cutscene_image_panel.custom_minimum_size = Vector2(820, 350)
	cutscene_image_panel.color = Color(0.025, 0.03, 0.055, 0.96)
	cutscene_outer.add_child(cutscene_image_panel)
	var scanline_holder := Control.new()
	scanline_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	cutscene_image_panel.add_child(scanline_holder)
	for i in range(12):
		var line := ColorRect.new()
		line.color = Color(0.35, 0.58, 1.0, 0.055)
		line.position = Vector2(0, 22 + i * 27)
		line.size = Vector2(820, 2)
		scanline_holder.add_child(line)
	cutscene_riley_image = make_portrait(ASSET_PATH + "riley_portrait.png", Vector2(240, 240))
	cutscene_riley_image.position = Vector2(70, 54)
	cutscene_image_panel.add_child(cutscene_riley_image)
	cutscene_kenzie_image = make_portrait(ASSET_PATH + "kenzie_portrait.png", Vector2(240, 240))
	cutscene_kenzie_image.position = Vector2(510, 54)
	cutscene_image_panel.add_child(cutscene_kenzie_image)
	var center_gem := ColorRect.new()
	center_gem.name = "CenterGem"
	center_gem.position = Vector2(383, 128)
	center_gem.size = Vector2(54, 54)
	center_gem.color = Color(0.86, 0.24, 1.0, 0.7)
	cutscene_image_panel.add_child(center_gem)
	cutscene_caption_label = make_label("", 21, Color(0.9, 0.93, 1.0))
	cutscene_caption_label.custom_minimum_size = Vector2(820, 100)
	cutscene_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cutscene_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cutscene_outer.add_child(cutscene_caption_label)
	cutscene_continue_label = make_label("SPACE / CLICK TO ADVANCE", 14, Color(1.0, 0.82, 0.28))
	cutscene_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cutscene_outer.add_child(cutscene_continue_label)
	victory_cutscene_screen.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			advance_victory_cutscene()
	)

	controls_layer = Control.new()
	controls_layer.name = "Controls"
	controls_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	controls_layer.visible = false
	hud.add_child(controls_layer)

	score_label = make_hud_label("Score\n0")
	score_label.position = Vector2(18, 18)
	controls_layer.add_child(score_label)
	var riley_portrait := make_portrait(ASSET_PATH + "riley_portrait.png", Vector2(72, 72))
	riley_portrait.anchor_top = 1
	riley_portrait.anchor_bottom = 1
	riley_portrait.position = Vector2(24, -126)
	controls_layer.add_child(riley_portrait)
	health_hearts_label = make_label("♥ ♥ ♥", 28, Color(1.0, 0.08, 0.12))
	health_hearts_label.anchor_top = 1
	health_hearts_label.anchor_bottom = 1
	health_hearts_label.position = Vector2(108, -122)
	health_hearts_label.size = Vector2(158, 36)
	health_hearts_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	health_hearts_label.add_theme_constant_override("shadow_offset_x", 2)
	health_hearts_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(health_hearts_label)
	health_meter = ProgressBar.new()
	health_meter.anchor_top = 1
	health_meter.anchor_bottom = 1
	health_meter.position = Vector2(108, -82)
	health_meter.size = Vector2(168, 16)
	health_meter.min_value = 0
	health_meter.max_value = max_health
	health_meter.value = health
	health_meter.show_percentage = false
	health_meter.add_theme_stylebox_override("background", make_panel_style(Color(0.02, 0.0, 0.0, 0.78), 7))
	health_meter.add_theme_stylebox_override("fill", make_panel_style(Color(0.95, 0.02, 0.04, 0.95), 7))
	controls_layer.add_child(health_meter)
	boss_label = make_hud_label("Boss\n0%")
	boss_label.position = Vector2(0, 18)
	boss_label.anchor_left = 0.5
	boss_label.anchor_right = 0.5
	boss_label.offset_left = -230
	boss_label.offset_right = 230
	boss_label.position.y = 62
	boss_label.size = Vector2(460, 24)
	boss_label.add_theme_font_size_override("font_size", 15)
	controls_layer.add_child(boss_label)
	health_label = make_hud_label("Health\n3 / 3")
	health_label.anchor_left = 1
	health_label.anchor_right = 1
	health_label.position = Vector2(-160, 18)
	controls_layer.add_child(health_label)

	boss_bar = ProgressBar.new()
	boss_bar.anchor_left = 0.5
	boss_bar.anchor_right = 0.5
	boss_bar.position = Vector2(-230, 42)
	boss_bar.size = Vector2(460, 18)
	boss_bar.min_value = 0
	boss_bar.max_value = 5
	boss_bar.value = 5
	boss_bar.show_percentage = false
	boss_bar.visible = true
	boss_bar.add_theme_stylebox_override("background", make_panel_style(Color(0.02, 0.02, 0.025, 0.76), 9))
	boss_bar.add_theme_stylebox_override("fill", make_panel_style(Color(0.9, 0.08, 0.055, 0.96), 9))
	controls_layer.add_child(boss_bar)
	boss_name_label = make_label("KENZIE, DUNGEON MASTER", 16, Color.WHITE)
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.anchor_left = 0.5
	boss_name_label.anchor_right = 0.5
	boss_name_label.position = Vector2(-230, 14)
	boss_name_label.size = Vector2(460, 24)
	controls_layer.add_child(boss_name_label)
	var kenzie_portrait := make_portrait(ASSET_PATH + "kenzie_portrait.png", Vector2(54, 54))
	kenzie_portrait.anchor_left = 0.5
	kenzie_portrait.anchor_right = 0.5
	kenzie_portrait.position = Vector2(238, 29)
	controls_layer.add_child(kenzie_portrait)

	mission_label = make_label("MISSION 1: Dungeon Gate", 18, Color(0.7, 0.86, 1.0))
	mission_label.position = Vector2(18, 94)
	mission_label.size = Vector2(360, 26)
	mission_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	mission_label.add_theme_constant_override("shadow_offset_x", 2)
	mission_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(mission_label)
	mission_progress_label = make_label("", 13, Color(0.9, 0.94, 1.0))
	mission_progress_label.position = Vector2(18, 122)
	mission_progress_label.size = Vector2(430, 46)
	mission_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_progress_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	mission_progress_label.add_theme_constant_override("shadow_offset_x", 2)
	mission_progress_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(mission_progress_label)
	# Seal status row — shows which dungeon wing seals have been collected
	seal_label = make_label("Library○  Garden○  Crypt○", 13, Color(1.0, 0.82, 0.28))
	seal_label.position = Vector2(18, 170)
	seal_label.size = Vector2(420, 22)
	seal_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	seal_label.add_theme_constant_override("shadow_offset_x", 2)
	seal_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(seal_label)
	# Region indicator — top-right, tells player where they are
	region_label = make_label("", 14, Color(0.72, 0.82, 1.0))
	region_label.anchor_left = 0.5
	region_label.anchor_right = 0.5
	region_label.position = Vector2(-180, 4)
	region_label.size = Vector2(360, 22)
	region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	region_label.add_theme_constant_override("shadow_offset_x", 2)
	region_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(region_label)
	objective_hint_label = make_label("", 13, Color(0.9, 0.94, 1.0))
	objective_hint_label.anchor_left = 0.5
	objective_hint_label.anchor_right = 0.5
	objective_hint_label.position = Vector2(-240, 88)
	objective_hint_label.size = Vector2(480, 22)
	objective_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_hint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	objective_hint_label.add_theme_constant_override("shadow_offset_x", 2)
	objective_hint_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(objective_hint_label)
	star_label = make_label("Stars 12", 18, Color(0.8, 0.94, 1.0))
	star_label.anchor_left = 1
	star_label.anchor_right = 1
	star_label.position = Vector2(-174, 94)
	star_label.size = Vector2(150, 28)
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	star_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	star_label.add_theme_constant_override("shadow_offset_x", 2)
	star_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(star_label)
	level_label = make_label("Level 1", 18, Color(1.0, 0.82, 0.28))
	level_label.position = Vector2(18, 194)
	level_label.size = Vector2(140, 26)
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	level_label.add_theme_constant_override("shadow_offset_x", 2)
	level_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(level_label)
	xp_meter = ProgressBar.new()
	xp_meter.position = Vector2(100, 200)
	xp_meter.size = Vector2(190, 12)
	xp_meter.min_value = 0
	xp_meter.max_value = xp_to_next
	xp_meter.value = 0
	xp_meter.show_percentage = false
	xp_meter.add_theme_stylebox_override("background", make_panel_style(Color(0.03, 0.025, 0.02, 0.78), 6))
	xp_meter.add_theme_stylebox_override("fill", make_panel_style(Color(1.0, 0.72, 0.18, 0.95), 6))
	controls_layer.add_child(xp_meter)
	combo_label = make_label("", 20, Color(0.55, 1.0, 0.45))
	combo_label.position = Vector2(18, 218)
	combo_label.size = Vector2(260, 30)
	combo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	combo_label.add_theme_constant_override("shadow_offset_x", 2)
	combo_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(combo_label)
	ability_label = make_label("Space Slice  |  F Star  |  Shift Dash", 13, Color(0.82, 0.9, 1.0))
	ability_label.anchor_left = 1
	ability_label.anchor_right = 1
	ability_label.position = Vector2(-332, 126)
	ability_label.size = Vector2(310, 48)
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	ability_label.add_theme_constant_override("shadow_offset_x", 2)
	ability_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_layer.add_child(ability_label)

	message_label = make_label("", 54, Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.set_anchors_preset(Control.PRESET_CENTER)
	message_label.position = Vector2(-360, -80)
	message_label.size = Vector2(720, 80)
	message_label.visible = false
	controls_layer.add_child(message_label)
	sub_message_label = make_label("", 18, Color(0.88, 0.9, 1.0))
	sub_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_message_label.set_anchors_preset(Control.PRESET_CENTER)
	sub_message_label.position = Vector2(-360, 0)
	sub_message_label.size = Vector2(720, 50)
	sub_message_label.visible = false
	controls_layer.add_child(sub_message_label)

	joystick_base = Panel.new()
	joystick_base.position = Vector2(28, -156)
	joystick_base.size = Vector2(124, 124)
	joystick_base.anchor_top = 1
	joystick_base.anchor_bottom = 1
	joystick_base.add_theme_stylebox_override("panel", make_panel_style(Color(0.08, 0.12, 0.18, 0.58), 64))
	controls_layer.add_child(joystick_base)
	joystick_knob = Panel.new()
	joystick_knob.position = Vector2(36, 36)
	joystick_knob.size = Vector2(52, 52)
	joystick_knob.add_theme_stylebox_override("panel", make_panel_style(Color(0.15, 0.84, 1.0, 0.52), 32))
	joystick_base.add_child(joystick_knob)

	slice_button = make_button("Slice")
	slice_button.anchor_left = 1
	slice_button.anchor_right = 1
	slice_button.anchor_top = 1
	slice_button.anchor_bottom = 1
	slice_button.custom_minimum_size = Vector2(96, 96)
	slice_button.offset_left = -134
	slice_button.offset_top = -132
	slice_button.offset_right = -38
	slice_button.offset_bottom = -36
	style_round_button(slice_button, 50)
	slice_button.pressed.connect(attack)
	controls_layer.add_child(slice_button)
	dash_button = make_button("Dash")
	dash_button.anchor_left = 1
	dash_button.anchor_right = 1
	dash_button.anchor_top = 1
	dash_button.anchor_bottom = 1
	dash_button.custom_minimum_size = Vector2(80, 80)
	dash_button.offset_left = -236
	dash_button.offset_top = -116
	dash_button.offset_right = -156
	dash_button.offset_bottom = -36
	dash_button.add_theme_font_size_override("font_size", 14)
	style_round_button(dash_button, 42)
	dash_button.pressed.connect(dash)
	controls_layer.add_child(dash_button)
	star_button = make_button("Star")
	star_button.anchor_left = 1
	star_button.anchor_right = 1
	star_button.anchor_top = 1
	star_button.anchor_bottom = 1
	star_button.custom_minimum_size = Vector2(74, 74)
	star_button.offset_left = -318
	star_button.offset_top = -110
	star_button.offset_right = -244
	star_button.offset_bottom = -36
	star_button.add_theme_font_size_override("font_size", 13)
	style_round_button(star_button, 38)
	star_button.pressed.connect(throw_ninja_star)
	controls_layer.add_child(star_button)


func build_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "OriginalDungeonMusic"
	music_player.volume_db = -18.0
	music_player.stream = make_music_stream()
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "OriginalSFX"
	sfx_player.volume_db = -7.0
	add_child(sfx_player)


func start_game() -> void:
	reset_world()
	apply_floor_theme()
	input_locked = false
	victory_cutscene_active = false
	game_running = true
	start_screen.visible = false
	over_screen.visible = false
	controls_layer.visible = true
	show_message("ENTER", "Explore the valley. Find three seals.", Color(0.15, 0.84, 1.0))
	speak_line(kenzie_taunts.pick_random(), 1.18, 1.02, false, 4.0)
	play_music()
	play_sfx("start")


func end_game(win: bool) -> void:
	if not game_running:
		return
	game_running = false
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	won = win
	controls_layer.visible = false
	if victory_cutscene_screen:
		victory_cutscene_screen.visible = false
	over_screen.visible = true
	var title_block := over_screen.find_child("OverTitleBlock", true, false)
	if title_block:
		var labels := title_block.find_children("*", "Label", true, false)
		if labels.size() >= 2:
			labels[0].text = "You Reached Kenzie" if win else "Game Over"
			labels[1].text = "Dungeon cleared" if win else "Kenzie wins this round"
	play_sfx("win" if win else "over")


func reset_world() -> void:
	for node in projectiles:
		if is_instance_valid(node):
			node.queue_free()
	for node in particles:
		if is_instance_valid(node):
			node.queue_free()
	for node in rings:
		if is_instance_valid(node):
			node.queue_free()
	for node in monsters:
		if is_instance_valid(node):
			node.queue_free()
	for node in powerups:
		if is_instance_valid(node):
			node.queue_free()
	for node in ninja_stars:
		if is_instance_valid(node):
			node.queue_free()
	for node in event_nodes:
		if is_instance_valid(node):
			node.queue_free()
	projectiles.clear()
	particles.clear()
	rings.clear()
	monsters.clear()
	powerups.clear()
	ninja_stars.clear()
	event_nodes.clear()
	score = 0
	max_health = 5
	health = max_health
	won = false
	boss_zone = false
	boss_health = 5
	boss_max_health = 5
	run_time = 0.0
	mission_index = 0
	monster_timer = 2.2
	powerup_timer = 9.0
	star_cooldown = 0.0
	star_ammo = 18
	monsters_defeated = 0
	fruit_defeated = 0
	powerups_collected = 0
	aim_direction = Vector3(0, 0, -1)
	riley_level = 1
	riley_xp = 0
	xp_to_next = 60
	slash_damage = 2
	star_damage = 2
	star_speed = 11.5
	combo_count = 0
	combo_timer = 0.0
	powerup_boost_timer = 0.0
	shield_hits = 0
	dungeon_floor = 1
	floors_cleared = 0
	floor_transition_cooldown = 0.0
	star_regen_timer = 0.0
	director_heat = 0.0
	boss_battle_active = false
	boss_attack_timer = 0.0
	boss_minion_timer = 0.0
	boss_phase = 1
	input_locked = false
	victory_cutscene_active = false
	victory_cutscene_timer = 0.0
	victory_cutscene_stage = 0
	victory_cutscene_frame = 0
	if victory_cutscene_screen:
		victory_cutscene_screen.visible = false
	event_timer = 8.0
	event_name = ""
	event_time_left = 0.0
	event_progress = 0.0
	event_goal = 0.0
	player_z = PLAYER_START_Z
	attack_timer = 0
	attack_cooldown = 0
	invuln_timer = 0
	dash_timer = 0
	dash_cooldown = 0
	broccoli_timer = 1.75
	taunt_timer = 3.2
	joystick_vector = Vector2.ZERO
	player_velocity = Vector3.ZERO
	attack_lunge_dir = Vector3.ZERO
	dash_trail_timer = 0.0
	camera_yaw = 0.0
	target_camera_yaw = 0.0
	discovered_regions = {}
	collected_shrines = {}
	last_region_name = ""
	for shrine in shrine_nodes:
		if is_instance_valid(shrine):
			shrine.visible = true
	# Reset seal system for a fresh run
	collected_seals = {"library": false, "garden": false, "crypt": false}
	kenzie_gate_open = false
	for node in seal_nodes:
		if is_instance_valid(node):
			node.queue_free()
	seal_nodes.clear()
	spawn_seal_pickup("library", LIBRARY_SEAL_POS)
	spawn_seal_pickup("garden",  GARDEN_SEAL_POS)
	spawn_seal_pickup("crypt",   CRYPT_SEAL_POS)
	if is_instance_valid(kenzie_gate_node):
		kenzie_gate_node.visible = true
	if player:
		player.position = Vector3(0, 0, PLAYER_START_Z)
		player.rotation = Vector3.ZERO
	if kenzie:
		kenzie.position = Vector3(0, 0.72, GOAL_Z - 0.15)
	if joystick_knob:
		joystick_knob.position = Vector2(36, 36)


func update_player(delta: float) -> void:
	var input := joystick_vector
	input.x += Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.y += Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if input.length() > 1.0:
		input = input.normalized()

	var turn_input := 0.0
	if Input.is_key_pressed(KEY_Q):
		turn_input -= 1.0
	if Input.is_key_pressed(KEY_E):
		turn_input += 1.0
	target_camera_yaw += turn_input * 2.35 * delta
	camera_yaw = lerp_angle(camera_yaw, target_camera_yaw, minf(1.0, 10.0 * delta))
	var camera_forward := Vector3(sin(camera_yaw), 0, -cos(camera_yaw)).normalized()
	var camera_right := Vector3(cos(camera_yaw), 0, sin(camera_yaw)).normalized()
	var forward_amount := -input.y
	var strafe_amount := input.x * 0.92
	if forward_amount < 0.0:
		forward_amount *= 0.68
	var move_vector := camera_forward * forward_amount + camera_right * strafe_amount
	if move_vector.length() > 1.0:
		move_vector = move_vector.normalized()

	var speed := player_speed * (1.18 if powerup_boost_timer > 0.0 else 1.0) * (2.6 if dash_timer > 0 else 1.0)

	# Momentum: accelerate quickly toward target velocity, decelerate fast on release.
	# Movement is camera-relative now: W/S forward/back, A/D strafe, Q/E turns view.
	var target_vel := move_vector * speed
	var accel := 16.0 if target_vel.length() > 0.01 else 22.0   # decel slightly faster
	player_velocity = player_velocity.lerp(target_vel, minf(1.0, accel * delta))

	# Open-world movement. Try full movement first, then slide on one axis
	# if a cliff, tree line, ruin edge, or locked gate blocks the candidate.
	var cand_x := player.position.x + player_velocity.x * delta
	var cand_z := player.position.z + player_velocity.z * delta
	var full_candidate := Vector3(cand_x, player.position.y, cand_z)
	if is_position_walkable(full_candidate):
		player.position = full_candidate
	else:
		var x_candidate := Vector3(cand_x, player.position.y, player.position.z)
		var z_candidate := Vector3(player.position.x, player.position.y, cand_z)
		if is_position_walkable(x_candidate):
			player.position.x = cand_x
		if is_position_walkable(z_candidate):
			player.position.z = cand_z
	player_z = player.position.z

	aim_direction = camera_forward
	var target_yaw := atan2(aim_direction.x, aim_direction.z)
	player.rotation.y = lerp_angle(player.rotation.y, target_yaw, minf(1.0, 18.0 * delta))

	# Body lean: slight tilt into lateral movement (gives weight)
	var lateral_speed := player_velocity.dot(camera_right)
	var lateral_lean := -lateral_speed / maxf(1.0, speed) * 0.055
	player.rotation.z = lerp_angle(player.rotation.z, lateral_lean, minf(1.0, 9.0 * delta))

	# Dash afterimage trail
	if dash_timer > 0:
		dash_trail_timer -= delta
		if dash_trail_timer <= 0.0:
			dash_trail_timer = 0.045
			spawn_dash_trail()

	# Apply attack lunge forward push during the swing window
	if attack_timer > 0:
		attack_timer -= delta
		var lunge_t := attack_timer / 0.18
		if lunge_t > 0.5:  # first half of swing — push forward
			var lunge_candidate := player.position + attack_lunge_dir * speed * 0.35 * delta
			if is_position_walkable(lunge_candidate):
				player.position = lunge_candidate
		var t := attack_timer / 0.18
		player_arm.rotation_degrees.z = -92 + (1.0 - t) * 132.0
		sword.rotation_degrees.z = -103 + (1.0 - t) * 143.0
	else:
		player_arm.rotation_degrees.z = -20 + sin(Time.get_ticks_msec() * 0.006) * 4.0

	attack_cooldown = maxf(0, attack_cooldown - delta)
	invuln_timer = maxf(0, invuln_timer - delta)
	dash_timer = maxf(0, dash_timer - delta)
	dash_cooldown = maxf(0, dash_cooldown - delta)

	# Sword light pulses bright on attack, dims back to ambient glow
	if sword_light:
		var target_energy := 5.5 if attack_timer > 0 else 1.4
		sword_light.light_energy = lerpf(sword_light.light_energy, target_energy, minf(1.0, 14.0 * delta))
		sword_light.omni_range = lerpf(sword_light.omni_range, 6.0 if attack_timer > 0 else 3.5, minf(1.0, 12.0 * delta))

	# Hit flash — sprite pulses red/white when taking damage
	if player_hit_flash_timer > 0:
		player_hit_flash_timer = maxf(0.0, player_hit_flash_timer - delta)
		var f := player_hit_flash_timer / 0.55
		var strobe := 0.5 + 0.5 * sin(f * TAU * 6.0)  # fast strobe
		if player_art:
			player_art.modulate = Color(1.0, 1.0 - strobe * 0.72, 1.0 - strobe * 0.72, 0.72 + strobe * 0.28)
		if player_damage_light:
			player_damage_light.light_energy = 2.8 + strobe * 3.6
			player_damage_light.omni_range = 3.2 + strobe * 1.6
	else:
		if player_art:
			player_art.modulate = Color(1.0, 1.0, 1.0, 0.72)
		if player_damage_light:
			player_damage_light.light_energy = lerpf(player_damage_light.light_energy, 0.0, minf(1.0, 12.0 * delta))

	# Gate must be open (all 3 seals collected) before the boss fight starts
	if kenzie_gate_open and player.position.z <= GOAL_Z + 3.2 and not boss_battle_active and floor_transition_cooldown <= 0.0:
		start_boss_battle()

	if player.position.z <= GOAL_Z + 2.35 and boss_health <= 0 and campaign_ready_for_finale():
		start_victory_cutscene()


func update_camera(delta: float) -> void:
	if not player:
		return
	var viewport := get_viewport().get_visible_rect().size
	var portrait := viewport.y >= viewport.x

	var cam_forward := Vector3(sin(camera_yaw), 0, -cos(camera_yaw)).normalized()
	var cam_back := -cam_forward
	var move_lead := player_velocity.limit_length(6.0) * (0.22 if portrait else 0.18)
	var landmark_pull := Vector3.ZERO
	if player.position.z > -20.0:
		landmark_pull = (Vector3(0, 0, minf(player.position.z - 6.0, GOAL_Z + 5.0)) - player.position) * 0.18
	else:
		landmark_pull = (Vector3(0, 0, GOAL_Z + 1.0) - player.position) * 0.22

	# Adventure camera: higher/farther than combat corridors, with constant
	# forward reveal so the temple, bridge, and route landmarks stay in frame.
	camera.fov = lerpf(camera.fov, 70.0 if portrait else 61.0, minf(1.0, 4.0 * delta))
	var cam_y := 12.4 if portrait else 8.6
	var cam_back_distance := 14.8 if portrait else 11.4
	var target_pos := player.position + cam_back * cam_back_distance + Vector3.UP * cam_y + move_lead + landmark_pull * 0.4
	var look_target := player.position + cam_forward * (6.8 if portrait else 5.6) + move_lead * 0.45 + landmark_pull + Vector3.UP * (0.9 if portrait else 1.05)
	if boss_battle_active:
		camera.fov = lerpf(camera.fov, 60.0 if portrait else 54.0, minf(1.0, 5.0 * delta))
		target_pos = player.position + cam_back * (8.6 if portrait else 7.4) + Vector3.UP * (7.2 if portrait else 6.0)
		look_target = kenzie.position + Vector3(0, 1.6, 0.25)
	if victory_cutscene_active:
		var cut_t := clampf(victory_cutscene_timer / 7.2, 0.0, 1.0)
		target_pos = Vector3(0.0, lerpf(4.6, 3.2, cut_t), lerpf(GOAL_Z + 5.9, GOAL_Z + 3.2, cut_t))
		look_target = Vector3(0.0, 1.85, GOAL_Z + 0.35)

	# Smooth camera position — faster lerp keeps up with fast movement
	camera.position = camera.position.lerp(target_pos, minf(1.0, 0.16 * 60.0 * delta))

	if camera_shake_timer > 0.0:
		camera_shake_timer = maxf(0.0, camera_shake_timer - delta)
		var fade := camera_shake_timer / maxf(0.001, camera_shake_timer + delta)
		camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-0.3, 0.3)) * camera_shake_intensity * (0.3 + fade * 0.7)
		if camera_shake_timer <= 0.0:
			camera_shake_intensity = 0.0

	camera.look_at(look_target)


func update_sprite_facings() -> void:
	if not camera:
		return
	for node in get_tree().get_nodes_in_group("camera_facing_art"):
		if node is Sprite3D and is_instance_valid(node):
			node.look_at(camera.global_position, Vector3.UP)
			if node.has_meta("yaw_offset"):
				node.rotate_y(float(node.get_meta("yaw_offset")))


func update_shadows() -> void:
	if player_shadow and player:
		player_shadow.position = Vector3(player.position.x, 0.075, player.position.z + 0.12)
		player_shadow.rotation_degrees.y = rad_to_deg(player.rotation.y)
	if kenzie_shadow and kenzie:
		kenzie_shadow.position = Vector3(kenzie.position.x, 0.08, kenzie.position.z)


func hide_mesh_instances(root: Node) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			child.visible = false
		hide_mesh_instances(child)


func show_mesh_instances(root: Node) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			child.visible = true
		show_mesh_instances(child)


func update_kenzie(elapsed: float, delta: float) -> void:
	if not kenzie:
		return
	kenzie.position.y = 0.72 + sin(elapsed * 1.7) * 0.05
	kenzie.rotation.y = sin(elapsed * 0.8) * 0.12
	# Boss aura: continuous magic particle emission during the fight
	if boss_battle_active and boss_health > 0:
		kenzie_robe_timer -= delta
		if kenzie_robe_timer <= 0.0:
			kenzie_robe_timer = 0.055
			var rp := kenzie.position + Vector3(randf_range(-0.7, 0.7), randf_range(0.2, 2.0), randf_range(-0.3, 0.3))
			var rc: Color = Color(0.85, 0.25, 1.0) if randf() > 0.35 else Color(1.0, 0.82, 0.28)
			spawn_particles(rp, rc, 1)
	if kenzie_aura_light:
		var boss_pulse := 0.5 + 0.5 * sin(elapsed * (3.2 if boss_battle_active else 1.4))
		var battle_boost := 2.4 if boss_battle_active else 0.0
		kenzie_aura_light.light_color = Color(0.85 + boss_pulse * 0.12, 0.25 + boss_pulse * 0.22, 1.0)
		kenzie_aura_light.light_energy = 1.1 + boss_pulse * 0.8 + battle_boost
		kenzie_aura_light.omni_range = 4.6 + boss_pulse * 1.4 + (2.2 if boss_battle_active else 0.0)
	if kenzie_staff:
		kenzie_staff.rotation_degrees.z = -7 + sin(elapsed * 2.1) * 6
	if kenzie_shield:
		kenzie_shield.visible = boss_zone or boss_battle_active
		var shield_ratio := clampf(float(boss_health) / float(maxi(1, boss_max_health)), 0.0, 1.0)
		# Decay hit shake timer
		var shake_t := 0.0
		if kenzie_shield.has_meta("hit_shake"):
			var remaining := maxf(0.0, float(kenzie_shield.get_meta("hit_shake")) - delta)
			kenzie_shield.set_meta("hit_shake", remaining)
			shake_t = remaining / 0.45
		var base_scale := 0.74 + shield_ratio * 0.32
		kenzie_shield.scale = Vector3.ONE * (base_scale + shake_t * 0.18)
		var spin_speed := 36.0 + shake_t * 200.0
		kenzie_shield.rotation_degrees.y = elapsed * spin_speed
		kenzie_shield.rotation_degrees.z = sin(elapsed * 1.3) * 4.0 + shake_t * sin(elapsed * 28.0) * 16.0
		for orbit in kenzie_shield.get_children():
			if orbit.has_meta("orbit_angle"):
				var angle := float(orbit.get_meta("orbit_angle")) + elapsed * (1.2 + shake_t * 4.0)
				var radius := float(orbit.get_meta("orbit_radius"))
				orbit.position = Vector3(cos(angle) * radius, sin(angle * 1.7) * 0.18, sin(angle) * 0.34)
				orbit.rotation = Vector3(elapsed * 1.6, angle, elapsed * 2.1)


func update_projectiles(delta: float) -> void:
	broccoli_timer -= delta
	if broccoli_timer <= 0 and game_running:
		var progress := clampf((PLAYER_START_Z - player_z) / (PLAYER_START_Z - GOAL_Z), 0, 1)
		broccoli_timer = (0.52 if boss_zone else 0.95 - progress * 0.35) + randf() * 0.42
		spawn_broccoli()

	for i in range(projectiles.size() - 1, -1, -1):
		var projectile := projectiles[i]
		projectile.set_meta("life", float(projectile.get_meta("life")) - delta)
		projectile.set_meta("trail_timer", float(projectile.get_meta("trail_timer", 0.0)) - delta)
		if float(projectile.get_meta("trail_timer")) <= 0.0:
			projectile.set_meta("trail_timer", 0.055)
			spawn_trail_spark(projectile.position)
		projectile.position += projectile.get_meta("velocity") * delta
		projectile.rotation += Vector3(2.1, 2.8, 1.4) * delta
		if projectile.position.distance_to(player.position + Vector3(0, 0.85, 0)) < 0.68:
			spawn_particles(projectile.position, Color(0.33, 0.85, 0.36), 10)
			remove_projectile(projectile)
			damage_player()
		elif float(projectile.get_meta("life")) <= 0 or projectile.position.z > PROJECTILE_SCENE_LIMIT or absf(projectile.position.x) > 8:
			remove_projectile(projectile)


func update_missions() -> void:
	if mission_index >= MISSIONS.size():
		return
	var mission: Dictionary = MISSIONS[mission_index]
	var mission_start := mission_start_time(mission_index)
	var mission_elapsed := run_time - mission_start
	var duration_done := mission_elapsed >= float(mission["duration"])
	var kills_done := monsters_defeated >= int(mission["kills"])
	var fruit_done := fruit_defeated >= int(mission["fruit"])
	var powerups_done := powerups_collected >= int(mission["powerups"])
	if duration_done and kills_done and fruit_done and powerups_done:
		mission_index += 1
		if mission_index < MISSIONS.size():
			var next: Dictionary = MISSIONS[mission_index]
			apply_mission_reward()
			show_message("MISSION CLEAR", next["name"], Color(0.7, 0.86, 1.0))
			speak_line("New mission. " + String(next["brief"]), 1.05, 1.04, false, 4.0)
		else:
			apply_mission_reward()
			show_message("FINAL DUEL", "Kenzie is vulnerable. Break the shield.", Color(1.0, 0.82, 0.28))
			speak_line("Final duel unlocked. Break my shield if you can.", 1.18, 1.02, false, 4.0)


func update_dungeon_event(delta: float) -> void:
	if boss_battle_active or victory_cutscene_active:
		return
	if event_name == "":
		event_timer -= delta
		if event_timer <= 0.0:
			start_random_dungeon_event()
		return
	event_time_left -= delta
	match event_name:
		"RELIC HUNT":
			for i in range(event_nodes.size() - 1, -1, -1):
				var node := event_nodes[i]
				if not is_instance_valid(node):
					event_nodes.remove_at(i)
					continue
				node.rotation_degrees.y += delta * 150.0
				node.position.y = 0.62 + sin(Time.get_ticks_msec() * 0.004 + float(node.get_meta("phase", 0.0))) * 0.16
				if node.position.distance_to(player.position + Vector3(0, 0.65, 0)) < 1.05:
					event_progress += 1.0
					spawn_ring(node.position, Color(1.0, 0.82, 0.28))
					spawn_particles(node.position, Color(1.0, 0.82, 0.28), 20)
					node.queue_free()
					event_nodes.remove_at(i)
					play_sfx("powerup")
		"RUNE CHARGE":
			for node in event_nodes:
				if not is_instance_valid(node):
					continue
				node.rotation_degrees.y += delta * 65.0
				var dist := node.position.distance_to(player.position)
				if dist < 1.45:
					event_progress += delta
					node.scale = node.scale.lerp(Vector3.ONE * 1.22, minf(1.0, delta * 5.0))
					if randf() < 0.28:
						spawn_particles(node.position + Vector3(randf_range(-0.5, 0.5), 0.25, randf_range(-0.5, 0.5)), Color(0.55, 0.9, 1.0), 1)
				else:
					node.scale = node.scale.lerp(Vector3.ONE, minf(1.0, delta * 3.0))
		"ALTAR AWAKENS":
			for node in event_nodes:
				if not is_instance_valid(node):
					continue
				node.rotation_degrees.y += delta * 95.0
				var dist := node.position.distance_to(player.position)
				if dist < 1.85:
					event_progress += delta
					node.scale = node.scale.lerp(Vector3.ONE * 1.35, minf(1.0, delta * 5.0))
					if randf() < 0.35:
						spawn_particles(node.position + Vector3(randf_range(-0.8, 0.8), 0.35, randf_range(-0.8, 0.8)), Color(0.82, 0.28, 1.0), 1)
				else:
					node.scale = node.scale.lerp(Vector3.ONE, minf(1.0, delta * 3.0))
		"SURVIVE":
			if int(event_time_left * 10.0) % 17 == 0 and randf() < 0.08:
				spawn_broccoli()
		_:
			pass
	if event_progress >= event_goal:
		complete_dungeon_event(true)
	elif event_time_left <= 0.0:
		complete_dungeon_event(event_name == "SURVIVE")


func start_random_dungeon_event() -> void:
	# Event pool is shaped by which region the player is currently in
	var region := get_current_region()
	var pool: Array[String] = []
	match region:
		"Moon Library":
			pool = ["RUNE CHARGE", "AMBUSH", "RELIC HUNT"]
		"Poison Garden":
			pool = ["SURVIVE", "AMBUSH", "RELIC HUNT"]
		"Crown Crypt":
			pool = ["RELIC HUNT", "AMBUSH", "RUNE CHARGE"]
		"Training Annex":
			pool = ["SURVIVE", "AMBUSH", "RUNE CHARGE"]
		"Great Hall":
			pool = ["ALTAR AWAKENS", "RUNE CHARGE", "AMBUSH", "RELIC HUNT"]
		_:
			pool = ["RELIC HUNT", "AMBUSH", "RUNE CHARGE", "SURVIVE"]
	event_name = pool.pick_random()
	event_progress = 0.0
	event_nodes.clear()
	match event_name:
		"RELIC HUNT":
			event_goal = 3.0
			event_time_left = 32.0
			show_message("RELIC HUNT", "Grab the three gold seals.", Color(1.0, 0.82, 0.28))
			for i in range(3):
				spawn_event_relic(i)
		"AMBUSH":
			event_goal = 5.0
			event_time_left = 38.0
			show_message("AMBUSH", "Defeat the marked wave.", Color(1.0, 0.42, 0.18))
			spawn_event_ambush()
		"RUNE CHARGE":
			event_goal = 4.5
			event_time_left = 36.0
			show_message("RUNE CHARGE", "Stand inside the blue seals.", Color(0.45, 0.86, 1.0))
			if in_great_hall(player.position.z):
				spawn_event_rune(Vector3(-4.2, 0.08, -1.1))
				spawn_event_rune(Vector3(4.2, 0.08, -3.4))
			else:
				# Place runes near the player's current region
				var reg := get_current_region()
				var r_data: Dictionary = WORLD_REGIONS[0]
				for rd in WORLD_REGIONS:
					if String(rd["name"]) == reg:
						r_data = rd
						break
				var cx := float(r_data["cx"])
				var cz := float(r_data["cz"])
				spawn_event_rune(Vector3(cx + randf_range(-1.5, 1.5), 0.08, cz + randf_range(-1.2, 1.2)))
				spawn_event_rune(Vector3(cx + randf_range(-1.5, 1.5), 0.08, cz + randf_range(-1.2, 1.2)))
		"SURVIVE":
			event_goal = 1.0
			event_time_left = 24.0
			show_message("BROCCOLI STORM", "Survive the vegetable rain.", Color(0.45, 1.0, 0.35))
			for i in range(3):
				spawn_broccoli()
		"ALTAR AWAKENS":
			event_goal = 7.0
			event_time_left = 40.0
			show_message("ALTAR AWAKENS", "Hold the center and repel the guardians.", Color(0.82, 0.28, 1.0))
			spawn_event_rune(Vector3(0.0, 0.08, -2.0))
			for i in range(4):
				spawn_event_guardian(i)
	speak_line(event_name.to_lower() + ".", 1.05, 1.02, false, 4.0)


func complete_dungeon_event(success: bool) -> void:
	if success:
		show_message("EVENT CLEAR", event_name + " complete", Color(1.0, 0.82, 0.28))
		score += 60
		award_xp(35 + dungeon_floor * 4)
		star_ammo = mini(max_star_ammo, star_ammo + 5)
		if health < max_health and randf() < 0.55:
			health += 1
		spawn_powerup()
		play_sfx("level_up_fanfare")
	else:
		show_message("EVENT LOST", event_name + " fades away", Color(0.75, 0.78, 0.9))
	for node in event_nodes:
		if is_instance_valid(node):
			node.queue_free()
	event_nodes.clear()
	event_name = ""
	event_time_left = 0.0
	event_progress = 0.0
	event_goal = 0.0
	event_timer = randf_range(14.0, 24.0)


func spawn_event_relic(index: int) -> void:
	var relic := Node3D.new()
	relic.name = "event_relic"
	if in_great_hall(player.position.z):
		var hall_positions := [Vector3(-6.4, 0.64, 0.3), Vector3(6.4, 0.64, -2.0), Vector3(0.0, 0.64, -4.45)]
		relic.position = hall_positions[index % hall_positions.size()]
	else:
		var chamber: Dictionary = SIDE_CHAMBERS[index % SIDE_CHAMBERS.size()]
		var side := int(chamber["side"])
		relic.position = Vector3(side * randf_range(7.4, 10.2), 0.64, float(chamber["z"]) + randf_range(-1.25, 1.25))
	relic.set_meta("phase", randf() * TAU)
	relic.add_child(make_torus(0.28, 0.38, Color(1.0, 0.82, 0.28), 1.6))
	relic.add_child(make_sphere(Vector3.ZERO, 0.15, Color(1.0, 0.95, 0.5), true))
	add_child(relic)
	event_nodes.append(relic)


func spawn_event_rune(origin: Vector3) -> void:
	var rune := Node3D.new()
	rune.name = "event_rune"
	rune.position = origin
	var ring := make_torus(0.92, 1.05, Color(0.35, 0.85, 1.0), 1.4)
	ring.rotation_degrees.x = 90
	rune.add_child(ring)
	for i in range(4):
		var spoke := make_box(Vector3.ZERO, Vector3(1.65, 0.04, 0.06), Color(0.35, 0.85, 1.0), true)
		spoke.rotation_degrees.y = i * 45
		rune.add_child(spoke)
	add_child(rune)
	event_nodes.append(rune)


func spawn_event_ambush() -> void:
	var choices := ["runner", "runner", "soldier", "brute", "caster"]
	for i in range(5):
		var kind := "fruit" if i == 4 and mission_index >= 2 else "broccoli"
		var archetype: String = choices[i]
		if archetype == "caster" and kind != "fruit":
			archetype = "runner"
		var monster := create_monster_node(kind, archetype)
		if in_great_hall(player.position.z):
			var angle := TAU * float(i) / 5.0
			monster.position = Vector3(cos(angle) * randf_range(4.6, 7.4), 0.12, -2.0 + sin(angle) * randf_range(1.6, 3.0))
		else:
			var side := -1 if i % 2 == 0 else 1
			var spawn_z := clampf(player.position.z + randf_range(-2.8, 3.5), GOAL_Z + 1.5, PLAYER_START_Z + 1.5)
			monster.position = Vector3(side * randf_range(3.4, 5.0), 0.12, spawn_z)
		monster.set_meta("event_marked", true)
		add_child(monster)
		monsters.append(monster)


func spawn_event_guardian(index: int) -> void:
	var archetype := "brute" if index % 3 == 0 else ("runner" if index % 2 == 0 else "soldier")
	var monster := create_monster_node("broccoli", archetype)
	var angle := TAU * float(index) / 4.0 + PI * 0.25
	monster.position = Vector3(cos(angle) * 6.8, 0.12, -2.0 + sin(angle) * 2.9)
	monster.set_meta("event_marked", true)
	add_child(monster)
	monsters.append(monster)


func seal_count() -> int:
	var count := 0
	for key in collected_seals:
		if collected_seals[key]:
			count += 1
	return count


func shrine_count() -> int:
	var count := 0
	for key in collected_shrines:
		if collected_shrines[key]:
			count += 1
	return count


func get_current_region() -> String:
	if not player:
		return "Valley"
	var best := "Wild Valley"
	var best_area := INF
	for region in WORLD_REGIONS:
		if region_contains_position(region, player.position):
			var hw := float(region["hw"])
			var hz := float(region["hz"])
			var area := hw * hz
			if area < best_area:
				best_area = area
				best = String(region["name"])
	return best


func update_exploration(_delta: float) -> void:
	var region := get_current_region()
	if region == "" or region == "Wild Valley":
		return
	if region != last_region_name:
		last_region_name = region
		if not bool(discovered_regions.get(region, false)):
			discovered_regions[region] = true
			var reward_regions := ["Poison Garden", "Moon Library", "Crown Crypt", "River Ford", "North Ridge", "Ancient Crossroads", "Swift Shrine Grove", "Starfall Hollow", "Hero Shrine Ridge"]
			if region in reward_regions:
				score += 15
				star_ammo = mini(max_star_ammo, star_ammo + 2)
				award_xp(10)
				show_message("DISCOVERED", region, Color(0.72, 0.86, 1.0))
				play_sfx("powerup")


func seal_position_for(id: String) -> Vector3:
	match id:
		"library":
			return LIBRARY_SEAL_POS
		"garden":
			return GARDEN_SEAL_POS
		"crypt":
			return CRYPT_SEAL_POS
	return Vector3.ZERO


func compass_direction_to(target: Vector3) -> String:
	if not player:
		return ""
	var v := target - player.position
	var ns := ""
	var ew := ""
	if v.z < -2.0:
		ns = "N"
	elif v.z > 2.0:
		ns = "S"
	if v.x > 2.0:
		ew = "E"
	elif v.x < -2.0:
		ew = "W"
	return ns + ew if ns + ew != "" else "HERE"


func nearest_seal_hint() -> String:
	var close_shrine := nearest_shrine_hint(8.5)
	if close_shrine != "":
		return close_shrine
	if kenzie_gate_open:
		var meters := int(player.position.distance_to(Vector3(0, 0, GOAL_Z)))
		return "Temple gate open | Kenzie %s %sm" % [compass_direction_to(Vector3(0, 0, GOAL_Z)), meters]
	var best_id := ""
	var best_dist := INF
	for id in ["library", "garden", "crypt"]:
		if collected_seals.get(id, false):
			continue
		var pos := seal_position_for(id)
		var d := player.position.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best_id = id
	if best_id == "":
		return "All seals found | Go north to the temple gate"
	return "Nearest seal: %s %s  %sm" % [best_id.capitalize(), compass_direction_to(seal_position_for(best_id)), int(best_dist)]


func nearest_shrine_hint(max_distance: float) -> String:
	if not player:
		return ""
	var best_title := ""
	var best_pos := Vector3.ZERO
	var best_dist := INF
	for shrine in SHRINE_DATA:
		var id := String(shrine["id"])
		if collected_shrines.get(id, false):
			continue
		var pos: Vector3 = shrine["pos"]
		var d := player.position.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best_title = String(shrine["title"])
			best_pos = pos
	if best_title != "" and best_dist <= max_distance:
		return "Optional shrine: %s %s  %sm" % [best_title, compass_direction_to(best_pos), int(best_dist)]
	return ""


func region_contains_position(region: Dictionary, pos: Vector3) -> bool:
	var cx := float(region["cx"])
	var cz := float(region["cz"])
	var hw := float(region["hw"])
	var hz := float(region["hz"])
	var dx := absf(pos.x - cx)
	var dz := absf(pos.z - cz)
	if String(region.get("shape", "box")) == "ellipse":
		var nx := dx / maxf(0.01, hw)
		var nz := dz / maxf(0.01, hz)
		return nx * nx + nz * nz <= 1.0
	return dx <= hw and dz <= hz


func is_position_walkable(pos: Vector3) -> bool:
	if boss_battle_active:
		return pos.x >= -5.4 and pos.x <= 5.4 and pos.z >= GOAL_Z + 1.9 and pos.z <= GOAL_Z + 7.2
	for region in WORLD_REGIONS:
		if not kenzie_gate_open and String(region["name"]) == "Kenzie Temple":
			continue
		if region_contains_position(region, pos):
			return true
	return false


func spawn_seal_pickup(seal_id: String, pos: Vector3) -> void:
	var seal_node := Node3D.new()
	seal_node.name = "seal_" + seal_id
	seal_node.position = pos
	seal_node.set_meta("seal_id", seal_id)
	seal_node.set_meta("phase", randf() * TAU)
	# Glowing gold torus + orb
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.30
	ring_mesh.outer_radius = 0.42
	ring.mesh = ring_mesh
	ring.material_override = make_glow_material(Color(1.0, 0.78, 0.18), 2.4)
	ring.rotation_degrees.x = 90
	seal_node.add_child(ring)
	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.14
	orb_mesh.height = 0.28
	orb.mesh = orb_mesh
	orb.material_override = make_glow_material(Color(1.0, 0.94, 0.55), 3.0)
	seal_node.add_child(orb)
	var beacon := make_cylinder(Vector3(0, 2.25, 0), 0.035, 0.08, 4.5, Color(1.0, 0.82, 0.28), Vector3.ZERO, true)
	seal_node.add_child(beacon)
	var top_ring := make_torus(0.55, 0.62, Color(1.0, 0.82, 0.28), 1.4)
	top_ring.position = Vector3(0, 4.55, 0)
	top_ring.rotation_degrees.x = 90
	top_ring.set_meta("spin_y_deg_s", 42.0)
	seal_node.add_child(top_ring)
	dungeon_animatables.append(top_ring)
	var seal_light := OmniLight3D.new()
	seal_light.light_color = Color(1.0, 0.82, 0.28)
	seal_light.light_energy = 2.8
	seal_light.omni_range = 4.5
	seal_light.shadow_enabled = false
	seal_node.add_child(seal_light)
	add_child(seal_node)
	seal_nodes.append(seal_node)


func collect_seal(seal: Node3D) -> void:
	var sid := String(seal.get_meta("seal_id", ""))
	if sid == "" or collected_seals.get(sid, false):
		return
	collected_seals[sid] = true
	spawn_ring(seal.position, Color(1.0, 0.82, 0.28))
	spawn_particles(seal.position, Color(1.0, 0.92, 0.45), 28)
	play_sfx("powerup")
	seal.queue_free()
	var count := seal_count()
	var wing_name := sid.capitalize()
	show_message("DUNGEON SEAL", "%s seal found. %s of 3." % [wing_name, count], Color(1.0, 0.82, 0.28))
	speak_line("Seal collected. " + str(count) + " of 3.", 1.05, 1.04, false, 3.5)
	if count >= 3:
		open_kenzie_gate()


func open_kenzie_gate() -> void:
	kenzie_gate_open = true
	if is_instance_valid(kenzie_gate_node):
		kenzie_gate_node.visible = false
	# Dramatic gate-open effects
	for i in range(4):
		spawn_ring(Vector3(0, float(i) * 1.4 + 0.5, KENZIE_GATE_Z), Color(0.85, 0.28, 1.0))
	for i in range(6):
		spawn_particles(
			Vector3(randf_range(-2.4, 2.4), randf_range(0.4, 5.2), KENZIE_GATE_Z),
			Color(0.85, 0.28, 1.0) if i % 2 == 0 else Color(1.0, 0.82, 0.28), 14)
	shake_camera(0.35, 0.14)
	show_message("GATE OPEN", "All seals found. Kenzie's tower awaits.", Color(0.85, 0.28, 1.0))
	speak_line("Gate open. Kenzie is waiting in the tower.", 1.1, 1.04, false, 5.0)


func update_seals(delta: float) -> void:
	for i in range(seal_nodes.size() - 1, -1, -1):
		var seal := seal_nodes[i]
		if not is_instance_valid(seal):
			seal_nodes.remove_at(i)
			continue
		if collected_seals.get(String(seal.get_meta("seal_id", "")), false):
			seal.queue_free()
			seal_nodes.remove_at(i)
			continue
		seal.rotation_degrees.y += 88.0 * delta
		seal.position.y = 0.64 + sin(Time.get_ticks_msec() * 0.004 + float(seal.get_meta("phase", 0.0))) * 0.15
		if player and seal.position.distance_to(player.position + Vector3(0, 0.65, 0)) < 1.15:
			collect_seal(seal)
			seal_nodes.remove_at(i)


func update_shrines(delta: float) -> void:
	for shrine in shrine_nodes:
		if not is_instance_valid(shrine) or not shrine.visible:
			continue
		var phase := float(shrine.get_meta("phase", 0.0))
		shrine.rotation_degrees.y += 18.0 * delta
		shrine.position.y = 0.58 + sin(Time.get_ticks_msec() * 0.002 + phase) * 0.035
		if player and player.position.distance_to(shrine.global_position) < 1.45:
			collect_shrine(shrine)


func collect_shrine(shrine: Node3D) -> void:
	var sid := String(shrine.get_meta("shrine_id", ""))
	if sid == "" or collected_shrines.get(sid, false):
		return
	collected_shrines[sid] = true
	shrine.visible = false
	var title := String(shrine.get_meta("title", "Shrine"))
	match String(shrine.get_meta("reward", "")):
		"speed":
			powerup_boost_timer = maxf(powerup_boost_timer, 24.0)
		"stars":
			max_star_ammo += 2
			star_ammo = mini(max_star_ammo, star_ammo + 14)
		"heart":
			max_health += 1
			health = max_health
	score += 40
	award_xp(35)
	spawn_ring(shrine.global_position + Vector3(0, 0.8, 0), Color(1.0, 0.92, 0.42))
	spawn_particles(shrine.global_position + Vector3(0, 0.8, 0), Color(1.0, 0.92, 0.42), 24)
	play_sfx("level_up_fanfare")
	show_message("SHRINE FOUND", "%s awakened. %s/3 shrines." % [title, shrine_count()], Color(1.0, 0.86, 0.32))
	speak_line(title + " awakened.", 1.08, 1.04, false, 3.0)


func apply_mission_reward() -> void:
	award_xp(70 + mission_index * 25)
	star_ammo = mini(max_star_ammo, star_ammo + 8 + mission_index)
	health = mini(max_health, health + 1)
	powerup_boost_timer = 8.0


func start_boss_battle() -> void:
	boss_zone = true
	boss_battle_active = true
	if event_name != "":
		complete_dungeon_event(false)
	boss_phase = 1
	boss_max_health = 4 + mini(5, int(dungeon_floor / 3))
	boss_health = boss_max_health
	boss_attack_timer = 1.35
	boss_minion_timer = 4.0
	clear_active_hazards()
	clear_active_monsters()
	player.position.z = GOAL_Z + 3.0
	player_z = player.position.z
	aim_direction = Vector3(0, 0, -1)
	show_message("BOSS BATTLE", "Break Kenzie's broccoli shield.", Color(0.85, 0.3, 1.0))
	speak_line("Boss battle. Break my broccoli shield if you can.", 1.2, 1.02, false, 4.0)
	spawn_boss_minion("knight")


func update_boss_battle(delta: float) -> void:
	if not boss_battle_active:
		return
	player.position.z = clampf(player.position.z, GOAL_Z + 2.15, GOAL_Z + 6.6)
	player_z = player.position.z
	var prev_phase := boss_phase
	boss_phase = 3 if boss_health <= 2 else (2 if boss_health <= 4 else 1)
	if boss_phase > prev_phase:
		_announce_boss_phase(boss_phase)
	boss_attack_timer -= delta
	boss_minion_timer -= delta
	if boss_attack_timer <= 0.0:
		boss_attack_timer = maxf(1.05, 2.05 - boss_phase * 0.18 - dungeon_floor * 0.008)
		spawn_boss_attack_pattern()
	if boss_minion_timer <= 0.0:
		boss_minion_timer = maxf(5.2, 8.5 - boss_phase * 0.5)
		spawn_boss_minion("runner" if boss_phase >= 2 else "soldier")


func current_aim_direction() -> Vector3:
	# Primary: current movement direction. When standing still, use soft lock-on.
	if player_velocity.length() > 0.25:
		var v := player_velocity
		v.y = 0
		return v.normalized()
	var best_dist := 5.0
	var best_dir := Vector3.ZERO
	for m in monsters:
		var d := player.position.distance_to(m.position)
		if d < best_dist:
			best_dist = d
			var v := m.position - player.position
			v.y = 0
			best_dir = v.normalized()
	if boss_battle_active and kenzie and player.position.distance_to(kenzie.position) < best_dist:
		var v := kenzie.position - player.position
		v.y = 0
		best_dir = v.normalized()
	if best_dir.length() > 0.1:
		return best_dir
	return aim_direction.normalized() if aim_direction.length() > 0.1 else Vector3(0, 0, -1)


func playable_x_limits(z: float) -> Vector2:
	if boss_battle_active:
		return Vector2(-5.4, 5.4)
	var min_x := INF
	var max_x := -INF
	for region in WORLD_REGIONS:
		if not kenzie_gate_open and String(region["name"]) == "Kenzie Temple":
			continue
		var cz := float(region["cz"])
		var hz := float(region["hz"])
		if absf(z - cz) <= hz:
			min_x = minf(min_x, float(region["cx"]) - float(region["hw"]))
			max_x = maxf(max_x, float(region["cx"]) + float(region["hw"]))
	if min_x < max_x:
		return Vector2(min_x, max_x)
	return Vector2(-CORRIDOR_HALF_WIDTH, CORRIDOR_HALF_WIDTH)


func random_playable_x(z: float) -> float:
	var limits := playable_x_limits(z)
	return randf_range(limits.x + 0.4, limits.y - 0.4)


func _announce_boss_phase(phase: int) -> void:
	match phase:
		2:
			shake_camera(0.5, 0.22)
			show_message("SHIELD CRACKING", "Kenzie is furious. Dodge faster.", Color(1.0, 0.55, 0.1))
			speak_line("You cracked it. Do not get comfortable.", 1.22, 1.04, false, 3.0)
		3:
			shake_camera(0.6, 0.28)
			show_message("FINAL PHASE", "One more hit. Finish this.", Color(1.0, 0.82, 0.28))
			speak_line("Fine. You want a finale. Here it is.", 1.3, 1.06, true, 0.0)


func spawn_boss_attack_pattern() -> void:
	var lanes := [-2.8, -1.4, 0.0, 1.4, 2.8]
	lanes.shuffle()
	var count := mini(lanes.size(), 1 + boss_phase)
	for i in range(count):
		spawn_boss_broccoli(Vector3(lanes[i], 1.55, GOAL_Z + 0.45), 5.0 + boss_phase * 0.42)


func spawn_boss_broccoli(origin: Vector3, speed: float) -> void:
	var projectile := Node3D.new()
	projectile.add_child(make_broccoli_mesh())
	projectile.position = origin
	var target := player.position + Vector3(randf_range(-0.55, 0.55), 0.95, 0)
	projectile.set_meta("velocity", (target - projectile.position).normalized() * speed)
	projectile.set_meta("life", 4.0)
	projectile.set_meta("trail_timer", 0.0)
	add_child(projectile)
	projectiles.append(projectile)
	play_sfx("throw")


func spawn_boss_minion(archetype: String) -> void:
	if monsters.size() >= max_active_monsters():
		return
	var monster := create_monster_node("broccoli", archetype)
	monster.position = Vector3(randf_range(-3.2, 3.2), 0.12, randf_range(GOAL_Z + 1.1, GOAL_Z + 3.4))
	add_child(monster)
	monsters.append(monster)


func debug_start_boss_preview() -> void:
	if not game_running:
		start_game()
	mission_index = max(mission_index, 1)
	player.position = Vector3(0, 0, GOAL_Z + 3.4)
	player_z = player.position.z
	aim_direction = Vector3(0, 0, -1)
	start_boss_battle()


func advance_dungeon_floor(from_boss := false) -> void:
	floor_transition_cooldown = 2.0
	floors_cleared += 1
	dungeon_floor += 1
	boss_zone = false
	boss_battle_active = false
	boss_health = 5
	boss_max_health = 5
	player.position = Vector3(randf_range(-0.6, 0.6), 0, PLAYER_START_Z)
	player.rotation = Vector3.ZERO
	player_z = PLAYER_START_Z
	aim_direction = Vector3(0, 0, -1)
	clear_active_hazards()
	clear_active_monsters()
	award_xp(20 + dungeon_floor * 2)
	star_ammo = mini(max_star_ammo, star_ammo + 3)
	health = mini(max_health, health + (1 if dungeon_floor % 3 == 0 else 0))
	monster_timer = 0.35
	broccoli_timer = 0.8
	# Reset seal cycle for the new floor
	collected_seals = {"library": false, "garden": false, "crypt": false}
	kenzie_gate_open = false
	for node in seal_nodes:
		if is_instance_valid(node):
			node.queue_free()
	seal_nodes.clear()
	spawn_seal_pickup("library", LIBRARY_SEAL_POS)
	spawn_seal_pickup("garden",  GARDEN_SEAL_POS)
	spawn_seal_pickup("crypt",   CRYPT_SEAL_POS)
	if is_instance_valid(kenzie_gate_node):
		kenzie_gate_node.visible = true
	apply_floor_theme()
	if from_boss:
		show_message("FLOOR %s" % dungeon_floor, "Kenzie retreats. Seals scattered. Find them.", Color(0.7, 0.86, 1.0))
		speak_line("Fine. Floor " + str(dungeon_floor) + ". Find the seals. Try this one.", 1.18, 1.02, false, 4.0)
	else:
		show_message("FLOOR %s" % dungeon_floor, "The dungeon shifts. Seals scattered anew.", Color(0.7, 0.86, 1.0))
		speak_line("The dungeon shifts. Floor " + str(dungeon_floor) + ".", 1.08, 1.04, false, 4.0)
	spawn_floor_wave()


func apply_floor_theme() -> void:
	var theme: Dictionary = FLOOR_THEMES[(dungeon_floor - 1) % FLOOR_THEMES.size()]
	if world_environment and world_environment.environment:
		world_environment.environment.fog_light_color = theme["fog"]
		world_environment.environment.ambient_light_color = theme["ambient"]
	if key_light:
		key_light.light_color = theme["key"]
	for light in torch_lights:
		if is_instance_valid(light):
			light.light_color = theme["torch"]


func clear_active_hazards() -> void:
	for node in projectiles:
		if is_instance_valid(node):
			node.queue_free()
	for node in ninja_stars:
		if is_instance_valid(node):
			node.queue_free()
	projectiles.clear()
	ninja_stars.clear()


func clear_active_monsters() -> void:
	for node in monsters:
		if is_instance_valid(node):
			node.queue_free()
	monsters.clear()


func spawn_floor_wave() -> void:
	var room_left := maxi(0, max_active_monsters() - monsters.size())
	var count := mini(room_left, mini(8, 2 + int(dungeon_floor / 2)))
	for i in range(count):
		spawn_monster()
	if dungeon_floor % 2 == 0:
		spawn_powerup()


func mission_start_time(index: int) -> float:
	var total := 0.0
	for i in range(index):
		total += float(MISSIONS[i]["duration"])
	return total


func campaign_ready_for_finale() -> bool:
	# Kenzie is no longer a floor-loop gate. The adventure objective is:
	# explore the open valley, collect all three seals, open the temple gate.
	return kenzie_gate_open


func mission_spawn_pressure() -> float:
	return 0.62 + float(mission_index) * 0.12 + float(dungeon_floor - 1) * 0.035 + director_heat * 0.18


func max_active_monsters() -> int:
	return mini(9, 2 + mission_index + int(dungeon_floor / 4))


func update_director(delta: float) -> void:
	var target_heat := 0.55
	if health <= 1:
		target_heat = 0.18
	elif monsters.size() < 3:
		target_heat = 0.9
	elif monsters.size() > max_active_monsters() - 2:
		target_heat = 0.28
	director_heat = lerpf(director_heat, target_heat, delta * 0.35)
	star_regen_timer -= delta
	if star_regen_timer <= 0.0:
		star_regen_timer = 3.5 if star_ammo > 0 else 1.25
		if star_ammo < mini(max_star_ammo, 8 + riley_level * 2):
			star_ammo += 1


func award_xp(amount: int) -> void:
	var combo_bonus := mini(20, combo_count * 2)
	riley_xp += amount + combo_bonus
	while riley_xp >= xp_to_next:
		riley_xp -= xp_to_next
		riley_level += 1
		xp_to_next = int(float(xp_to_next) * 1.18) + 24
		if riley_level % 2 == 0:
			max_star_ammo += 2
			star_ammo = mini(max_star_ammo, star_ammo + 6)
			star_speed += 0.55
		if riley_level % 3 == 0:
			slash_damage += 1
		if riley_level % 4 == 0:
			star_damage += 1
		if riley_level % 5 == 0:
			max_health += 1
		health = max_health
		show_message("LEVEL UP", "Riley reached level %s" % riley_level, Color(1.0, 0.82, 0.28))
		play_sfx("level_up_fanfare")
		shake_camera(0.16, 0.06)


func add_combo() -> void:
	combo_count += 1
	combo_timer = 4.0
	match combo_count:
		5:
			show_message("5x COMBO!", "Riley's on fire!", Color(1.0, 0.75, 0.2))
			spawn_particles(player.position + Vector3(0, 1.2, 0), Color(1.0, 0.85, 0.1), 18)
			play_sfx("combo_milestone")
			shake_camera(0.18, 0.07)
		10:
			show_message("10x COMBO!!", "Unstoppable ninja!", Color(1.0, 0.4, 0.05))
			spawn_particles(player.position + Vector3(0, 1.2, 0), Color(1.0, 0.5, 0.1), 30)
			spawn_ring(player.position + Vector3(0, 0.5, 0), Color(1.0, 0.55, 0.05))
			play_sfx("combo_milestone")
			shake_camera(0.22, 0.09)
		20:
			show_message("20x COMBO!!!", "KENZIE IS DOOMED!", Color(0.6, 0.1, 1.0))
			spawn_particles(player.position + Vector3(0, 1.2, 0), Color(0.7, 0.2, 1.0), 48)
			spawn_ring(player.position + Vector3(0, 0.5, 0), Color(0.6, 0.1, 1.0))
			spawn_ring(player.position + Vector3(0, 1.0, 0), Color(1.0, 0.9, 0.2))
			play_sfx("combo_milestone")
			shake_camera(0.3, 0.12)


func update_monsters(delta: float) -> void:
	monster_timer -= delta
	if monster_timer <= 0 and monsters.size() < max_active_monsters() and not boss_battle_active:
		var pressure := mission_spawn_pressure()
		monster_timer = maxf(0.95, randf_range(2.8, 4.8) / pressure)
		spawn_monster()
	elif monsters.size() >= max_active_monsters():
		monster_timer = maxf(monster_timer, 0.75)

	for i in range(monsters.size() - 1, -1, -1):
		var monster := monsters[i]
		if not is_instance_valid(monster):
			monsters.remove_at(i)
			continue
		var kind := String(monster.get_meta("kind"))
		var archetype := String(monster.get_meta("archetype", "soldier"))
		var hp := int(monster.get_meta("hp"))
		var speed := float(monster.get_meta("speed"))
		# Stagger pause — monster is reeling from a hit
		var stagger := float(monster.get_meta("stagger_timer", 0.0))
		if stagger > 0.0:
			monster.set_meta("stagger_timer", maxf(0.0, stagger - delta))
		else:
			var target := player.position
			var direction := target - monster.position
			direction.y = 0
			if direction.length() > 0.01:
				direction = direction.normalized()
			if kind == "fruit":
				var wobble := sin(Time.get_ticks_msec() * 0.004 + float(monster.get_meta("wobble"))) * 0.55
				direction.x += wobble
				direction = direction.normalized()
			if archetype == "runner":
				var flank := Vector3(direction.z, 0, -direction.x) * sin(Time.get_ticks_msec() * 0.006 + float(monster.get_meta("wobble"))) * 0.9
				direction = (direction * 0.78 + flank).normalized()
			if archetype == "brute":
				var charge_timer := float(monster.get_meta("charge_timer", 1.5)) - delta
				var charge_windup := float(monster.get_meta("charge_windup", 0.0))
				var charge_velocity: Vector3 = monster.get_meta("charge_velocity", Vector3.ZERO)
				if charge_velocity.length() > 0.1:
					monster.position += charge_velocity * delta
					monster.set_meta("charge_velocity", charge_velocity.lerp(Vector3.ZERO, minf(1.0, delta * 2.8)))
					direction = charge_velocity.normalized()
				elif charge_windup > 0.0:
					monster.set_meta("charge_windup", maxf(0.0, charge_windup - delta))
					monster.scale = monster.scale.lerp(Vector3.ONE * 1.38, minf(1.0, delta * 5.0))
					if charge_windup <= delta:
						monster.set_meta("charge_velocity", direction * (speed * 4.2))
						monster.set_meta("charge_timer", randf_range(3.0, 4.4))
						spawn_ring(monster.position + Vector3(0, 0.4, 0), Color(1.0, 0.32, 0.12))
				elif charge_timer <= 0.0 and monster.position.distance_to(player.position) < 5.4:
					monster.set_meta("charge_windup", 0.55)
					monster.set_meta("charge_timer", 99.0)
					show_message("BRUTE CHARGE", "Move!", Color(1.0, 0.32, 0.12))
				else:
					monster.set_meta("charge_timer", charge_timer)
					direction *= 0.72 + absf(sin(Time.get_ticks_msec() * 0.002 + float(monster.get_meta("wobble")))) * 0.22
					monster.position += direction * speed * delta
			elif archetype == "caster":
				var dist := monster.position.distance_to(player.position)
				var side := Vector3(direction.z, 0, -direction.x) * float(monster.get_meta("strafe_dir", 1.0))
				if dist < 4.2:
					direction = (-direction * 0.85 + side * 0.75).normalized()
				else:
					direction = (direction * 0.45 + side * 0.9).normalized()
				monster.position += direction * speed * delta
			else:
				monster.position += direction * speed * delta
			monster.rotation.y = atan2(direction.x, direction.z)
		monster.set_meta("contact_cooldown", maxf(0.0, float(monster.get_meta("contact_cooldown", 0.0)) - delta))
		monster.set_meta("hit_flash", maxf(0.0, float(monster.get_meta("hit_flash", 0.0)) - delta))
		update_monster_marker(monster)
		if archetype == "caster":
			monster.set_meta("cast_timer", float(monster.get_meta("cast_timer")) - delta)
			if float(monster.get_meta("cast_timer")) <= 0.0:
				monster.set_meta("cast_timer", randf_range(3.2, 5.0))
				spawn_fruit_seed(monster.position + Vector3(0, 1.0, 0))
		if monster.position.distance_to(player.position + Vector3(0, 0.75, 0)) < 0.86 and float(monster.get_meta("contact_cooldown")) <= 0.0:
			monster.set_meta("contact_cooldown", 1.45)
			damage_player()
		if hp <= 0:
			defeat_monster(monster)
		elif monster.position.z > PLAYER_START_Z + 4.5:
			remove_monster(monster)


func update_powerups(delta: float) -> void:
	powerup_timer -= delta
	if powerup_timer <= 0:
		powerup_timer = randf_range(15.0, 24.0)
		spawn_powerup()

	for i in range(powerups.size() - 1, -1, -1):
		var powerup := powerups[i]
		if not is_instance_valid(powerup):
			powerups.remove_at(i)
			continue
		powerup.rotation_degrees.y += 120.0 * delta
		powerup.position.y = 0.55 + sin(Time.get_ticks_msec() * 0.004 + float(powerup.get_meta("bob"))) * 0.12
		if powerup.position.distance_to(player.position + Vector3(0, 0.65, 0)) < 0.95:
			collect_powerup(powerup)


func update_ninja_stars(delta: float) -> void:
	star_cooldown = maxf(0.0, star_cooldown - delta)
	for i in range(ninja_stars.size() - 1, -1, -1):
		var star := ninja_stars[i]
		if not is_instance_valid(star):
			ninja_stars.remove_at(i)
			continue
		star.set_meta("life", float(star.get_meta("life")) - delta)
		star.position += star.get_meta("velocity") * delta
		star.rotation_degrees += Vector3(0, 0, 900.0 * delta)
		var hit_something := false
		for monster in monsters:
			if is_instance_valid(monster) and star.position.distance_to(monster.position + Vector3(0, 0.75, 0)) < 0.78:
				damage_monster(monster, star_damage)
				hit_something = true
				break
		if not hit_something:
			for projectile in projectiles:
				if is_instance_valid(projectile) and star.position.distance_to(projectile.position) < 0.68:
					spawn_particles(projectile.position, Color(0.75, 0.96, 1.0), 8)
					remove_projectile(projectile)
					score += 6
					add_combo()
					award_xp(5)
					hit_something = true
					break
		if not hit_something and boss_battle_active and boss_health > 0:
			if star.position.distance_to(kenzie.position + Vector3(0, 2.1, 0.25)) < 1.75:
				hit_kenzie_shield()
				hit_something = true
		if hit_something or float(star.get_meta("life")) <= 0.0 or absf(star.position.x) > 28.0 or star.position.z < GOAL_Z - 8.0 or star.position.z > PLAYER_START_Z + 8.0:
			remove_star(star)


func spawn_broccoli() -> void:
	var projectile := Node3D.new()
	projectile.add_child(make_broccoli_mesh())
	projectile.position = Vector3(randf_range(-2.1, 2.1), 1.5, GOAL_Z + 0.8)
	projectile.rotation = Vector3(randf() * PI, randf() * PI, randf() * PI)
	var target := player.position + Vector3(randf_range(-0.8, 0.8), 0.95, 0)
	var velocity := (target - projectile.position).normalized() * (randf_range(5.1, 6.4) if not boss_zone else randf_range(6.2, 7.6))
	projectile.set_meta("velocity", velocity)
	projectile.set_meta("life", 4.2)
	projectile.set_meta("trail_timer", 0.0)
	add_child(projectile)
	projectiles.append(projectile)
	play_sfx("throw")


func spawn_fruit_seed(origin: Vector3) -> void:
	var projectile := Node3D.new()
	projectile.add_child(make_sphere(Vector3.ZERO, 0.18, Color(1.0, 0.25, 0.18), true))
	projectile.add_child(make_torus(0.18, 0.23, Color(1.0, 0.5, 0.1), 0.8))
	projectile.position = origin
	var target := player.position + Vector3(randf_range(-0.45, 0.45), 0.85, 0)
	var velocity := (target - projectile.position).normalized() * randf_range(5.8, 7.1)
	projectile.set_meta("velocity", velocity)
	projectile.set_meta("life", 3.2)
	projectile.set_meta("trail_timer", 0.0)
	add_child(projectile)
	projectiles.append(projectile)
	play_sfx("throw")


func spawn_monster() -> void:
	# Pick a region — bias toward the player's current region so fights feel spatial.
	var current_r := get_current_region()
	var region: Dictionary = WORLD_REGIONS[0]
	if randf() < 0.55:
		# Spawn in the same region as the player
		for r in WORLD_REGIONS:
			if String(r["name"]) == current_r:
				region = r
				break
	else:
		# Spawn in a random explorable region (not the locked Kenzie Tower)
		var open_regions: Array[Dictionary] = []
		for r in WORLD_REGIONS:
			if String(r["name"]) != "Kenzie Tower":
				open_regions.append(r)
		if open_regions.size() > 0:
			region = open_regions.pick_random()

	# Region-specific enemy flavour
	var rname := String(region["name"])
	var kind := "broccoli"
	var archetype := "soldier"
	match rname:
		"Poison Garden":
			kind = "fruit" if randf() < 0.78 else "broccoli"
			archetype = "caster" if kind == "fruit" and mission_index >= 2 else "runner"
		"Moon Library":
			kind = "fruit" if randf() < 0.45 else "broccoli"
			archetype = "caster" if kind == "fruit" and randf() < 0.55 else "soldier"
		"Crown Crypt":
			kind = "broccoli"
			archetype = "brute" if randf() < 0.55 else "soldier"
		"Training Annex":
			archetype = "runner" if randf() < 0.65 else "soldier"
		_:
			# Hub and corridors: general enemy mix scaled by mission progress
			if mission_index >= 2 and randf() < minf(0.62, 0.22 + mission_index * 0.08):
				kind = "fruit"
			var roll := randf()
			if mission_index >= 1 and roll < 0.24:
				archetype = "runner"
			elif mission_index >= 2 and roll < 0.46:
				archetype = "brute"
			elif mission_index >= 3 and kind == "fruit" and roll < 0.72:
				archetype = "caster"

	var monster := create_monster_node(kind, archetype)
	var cx := float(region["cx"])
	var cz := float(region["cz"])
	var hw := float(region["hw"]) - 0.5
	var hz := float(region["hz"]) - 0.5
	monster.position = Vector3(cx + randf_range(-hw, hw), 0.12, cz + randf_range(-hz, hz))
	add_child(monster)
	monsters.append(monster)


func create_monster_node(kind: String, archetype: String) -> Node3D:
	var monster := Node3D.new()
	monster.name = "%s_%s" % [kind, archetype]
	if kind == "fruit":
		monster.add_child(make_fruit_monster_mesh())
		monster.set_meta("hp", 2 + int(mission_index / 3))
		monster.set_meta("speed", randf_range(1.6, 2.35) + mission_index * 0.08)
	else:
		monster.add_child(make_broccoli_monster_mesh(archetype))
		monster.set_meta("hp", 3 + int(mission_index / 2))
		monster.set_meta("speed", randf_range(1.05, 1.75) + mission_index * 0.06)
	if archetype == "runner":
		monster.set_meta("hp", maxi(1, int(monster.get_meta("hp")) - 1))
		monster.set_meta("speed", float(monster.get_meta("speed")) + 1.05)
		monster.scale = Vector3.ONE * 0.82
	elif archetype == "brute":
		monster.set_meta("hp", int(monster.get_meta("hp")) + 3)
		monster.set_meta("speed", maxf(0.75, float(monster.get_meta("speed")) - 0.35))
		monster.scale = Vector3.ONE * 1.22
		monster.set_meta("charge_timer", randf_range(1.2, 2.4))
		monster.set_meta("charge_windup", 0.0)
		monster.set_meta("charge_velocity", Vector3.ZERO)
	elif archetype == "caster":
		monster.set_meta("hp", int(monster.get_meta("hp")) + 1)
		monster.set_meta("speed", maxf(0.9, float(monster.get_meta("speed")) - 0.15))
		monster.scale = Vector3.ONE * 1.05
		monster.set_meta("strafe_dir", -1.0 if randf() < 0.5 else 1.0)
	monster.set_meta("kind", kind)
	monster.set_meta("archetype", archetype)
	monster.set_meta("max_hp", int(monster.get_meta("hp")))
	monster.set_meta("wobble", randf() * TAU)
	monster.set_meta("contact_cooldown", 0.0)
	monster.set_meta("cast_timer", randf_range(2.2, 4.2))
	# Scale up with dungeon floor — monsters grow 4% per floor, capped at 1.45x
	var floor_scale := minf(1.45, 1.0 + (dungeon_floor - 1) * 0.04)
	monster.scale *= floor_scale
	add_monster_marker(monster, kind, archetype)
	return monster


func spawn_powerup() -> void:
	var powerup := Node3D.new()
	var kind: String = ["heart", "stars", "speed"].pick_random()
	powerup.name = "%s_powerup" % kind
	powerup.set_meta("kind", kind)
	powerup.set_meta("bob", randf() * TAU)
	match kind:
		"heart":
			powerup.add_child(make_sphere(Vector3(0, 0.28, 0), 0.28, Color(1.0, 0.08, 0.14), true))
			powerup.add_child(make_sphere(Vector3(-0.18, 0.42, 0), 0.18, Color(1.0, 0.08, 0.14), true))
			powerup.add_child(make_sphere(Vector3(0.18, 0.42, 0), 0.18, Color(1.0, 0.08, 0.14), true))
		"stars":
			powerup.add_child(make_star_mesh(Color(0.78, 0.94, 1.0), 0.45))
		_:
			powerup.add_child(make_torus(0.25, 0.34, Color(0.15, 0.84, 1.0), 1.2))
			powerup.add_child(make_sphere(Vector3.ZERO, 0.12, Color(0.7, 0.95, 1.0), true))
	var spawn_z := randf_range(GOAL_Z + 4.0, PLAYER_START_Z - 2.0)
	if boss_battle_active:
		spawn_z = randf_range(GOAL_Z + 5.6, GOAL_Z + 6.8)
	if in_great_hall(player.position.z) and not boss_battle_active:
		spawn_z = randf_range(GREAT_HALL_Z_MIN + 0.65, GREAT_HALL_Z_MAX - 0.65)
		powerup.position = Vector3(randf_range(-7.3, 7.3), 0.55, spawn_z)
	else:
		powerup.position = Vector3(random_playable_x(spawn_z), 0.55, spawn_z)
	add_child(powerup)
	powerups.append(powerup)


func attack() -> void:
	if not game_running or attack_cooldown > 0:
		return
	attack_timer = 0.18
	attack_cooldown = 0.28
	spawn_slash_fx()
	var hit := false
	var solid_hit := false  # true when an enemy or projectile (not just shield) was struck
	var attack_direction := current_aim_direction()
	attack_lunge_dir = attack_direction  # stored for update_player lunge physics
	var sword_point := player.position + Vector3(0, 0.95, 0) + attack_direction * 1.05
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile := projectiles[i]
		var rel := projectile.position - player.position
		var forward_distance := rel.dot(attack_direction)
		var in_front := forward_distance > -0.25 and forward_distance < 3.1
		if projectile.position.distance_to(sword_point) < 2.15 and in_front:
			hit = true
			solid_hit = true
			score += 10
			spawn_particles(projectile.position, Color(0.33, 0.85, 0.36), 18)
			spawn_ring(projectile.position, Color(0.33, 0.85, 0.36))
			remove_projectile(projectile)

	for i in range(monsters.size() - 1, -1, -1):
		var monster := monsters[i]
		var rel := monster.position - player.position
		var forward_distance := rel.dot(attack_direction)
		var in_front := forward_distance > -0.25 and forward_distance < 3.1
		if monster.position.distance_to(sword_point) < 2.2 and in_front:
			hit = true
			solid_hit = true
			damage_monster(monster, slash_damage + (1 if powerup_boost_timer > 0.0 else 0))

	# Shield always checked independently — minions in the arena don't block Kenzie hits
	if boss_battle_active and boss_health > 0 and player.position.distance_to(kenzie.position) < 4.4:
		hit_kenzie_shield()
		hit = true

	if solid_hit:
		trigger_hit_stop()
	if hit:
		shake_camera(0.08, 0.04)
		var line: String = riley_lines.pick_random()
		show_message("SLICE!", line, Color(0.4, 0.9, 0.44))
		speak_line(line, 1.05, 1.12, false, 2.2)
		play_sfx("slice")
	else:
		var miss_line: String = riley_lines.pick_random()
		show_message("SWING", miss_line, Color(0.15, 0.84, 1.0))
		speak_line(miss_line, 1.05, 1.12, false, 2.2)
		play_sfx("swing")


func throw_ninja_star() -> void:
	if not game_running or star_cooldown > 0.0 or star_ammo <= 0:
		return
	star_cooldown = 0.34
	star_ammo -= 1
	var star := Node3D.new()
	star.name = "NinjaStar"
	star.add_child(make_star_mesh(Color(0.78, 0.94, 1.0), 0.32))
	var forward := current_aim_direction()
	star.position = player.position + Vector3(0, 1.2, 0) + forward * 0.9
	star.set_meta("velocity", forward * (star_speed + (1.8 if powerup_boost_timer > 0.0 else 0.0)))
	star.set_meta("life", 2.8)
	add_child(star)
	ninja_stars.append(star)
	show_message("STAR", "Ninja star thrown", Color(0.78, 0.94, 1.0))
	play_sfx("star")


func hit_kenzie_shield() -> void:
	var final_ready := campaign_ready_for_finale()
	boss_health = maxi(0, boss_health - 1)
	shield_hits += 1
	score += 25
	var shield_pos := kenzie.position + Vector3(0, 2.3, 0.3)
	spawn_particles(shield_pos, Color(0.85, 0.3, 1.0), 56)
	spawn_particles(shield_pos, Color(1.0, 0.82, 0.28), 26)
	spawn_ring(shield_pos, Color(0.85, 0.3, 1.0))
	spawn_ring(shield_pos + Vector3(0, 0.3, 0), Color(1.0, 0.82, 0.28))
	shake_camera(0.35, 0.16)
	if kenzie_shield:
		kenzie_shield.set_meta("hit_shake", 0.45)
	if boss_health <= 0:
		complete_boss_battle(final_ready)
	else:
		var hits_remaining := boss_health
		var phase_label := "FINAL HIT" if hits_remaining == 1 else "SHIELD HIT %s/%s" % [boss_max_health - boss_health, boss_max_health]
		show_message(phase_label, "Kenzie shield %s left" % hits_remaining, Color(0.85, 0.3, 1.0))
		speak_line(kenzie_taunts.pick_random(), 1.2, 1.02, false, 4.0)
	play_sfx("boss")


func complete_boss_battle(final_ready: bool) -> void:
	boss_battle_active = false
	boss_zone = false
	clear_active_hazards()
	spawn_particles(kenzie.position + Vector3(0, 2.2, 0.4), Color(1.0, 0.82, 0.28), 38)
	spawn_ring(kenzie.position + Vector3(0, 2.2, 0.3), Color(1.0, 0.82, 0.28))
	award_xp(90 + dungeon_floor * 10)
	if final_ready:
		start_victory_cutscene()
	else:
		show_message("SHIELD BROKEN", "The valley stays open. Find the missing seals.", Color(1.0, 0.82, 0.28))
		speak_line("The valley is still open. Find the seals.", 1.08, 1.02, false, 4.0)
		player.position = Vector3(0.0, 0.0, -21.5)
		player_velocity = Vector3.ZERO


func start_victory_cutscene() -> void:
	if victory_cutscene_active or won:
		return
	victory_cutscene_active = true
	victory_cutscene_timer = 0.0
	victory_cutscene_stage = 0
	victory_cutscene_frame = 0
	input_locked = true
	game_running = true
	boss_battle_active = false
	boss_zone = false
	if controls_layer:
		controls_layer.visible = false
	if victory_cutscene_screen:
		victory_cutscene_screen.visible = true
	clear_active_hazards()
	clear_active_monsters()
	for projectile in projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	projectiles.clear()
	player_velocity = Vector3.ZERO
	attack_timer = 0.0
	dash_timer = 0.0
	if player:
		player.position = Vector3(-1.05, 0.0, GOAL_Z + 3.0)
		player.rotation.y = deg_to_rad(-18.0)
	if kenzie:
		kenzie.position = Vector3(0.82, 0.72, GOAL_Z + 0.55)
		kenzie.rotation.y = deg_to_rad(18.0)
	if kenzie_shield:
		kenzie_shield.visible = true
		kenzie_shield.scale = Vector3.ONE * 1.35
	show_victory_cutscene_frame(0)
	speak_line("Shield collapse. Dungeon master recovered.", 1.05, 0.95, true, 0.0)
	play_sfx("win")
	shake_camera(0.45, 0.12)


func update_victory_cutscene(delta: float) -> void:
	victory_cutscene_timer += delta
	var t := victory_cutscene_timer
	if kenzie_shield:
		kenzie_shield.rotation.y += delta * 5.5
		kenzie_shield.rotation.z += delta * 3.2
		kenzie_shield.scale = kenzie_shield.scale.lerp(Vector3.ONE * maxf(0.05, 1.35 - t * 0.26), minf(1.0, delta * 5.0))
		if t > 3.7:
			kenzie_shield.visible = false
	if player:
		player.position = player.position.lerp(Vector3(-0.58, 0.0, GOAL_Z + 1.62), minf(1.0, delta * 1.45))
		player.rotation.y = lerp_angle(player.rotation.y, deg_to_rad(-9.0), minf(1.0, delta * 2.0))
	if kenzie:
		kenzie.position = kenzie.position.lerp(Vector3(0.55, 0.72, GOAL_Z + 1.02), minf(1.0, delta * 1.35))
		kenzie.rotation.y = lerp_angle(kenzie.rotation.y, deg_to_rad(10.0), minf(1.0, delta * 2.0))
	if t > 3.8 and victory_cutscene_stage == 0:
		victory_cutscene_stage = 1
		show_victory_cutscene_frame(1)
		for i in range(3):
			spawn_ring(kenzie.position + Vector3(0, 1.65 + i * 0.25, 0.2), [Color(1.0, 0.82, 0.28), Color(0.95, 0.25, 1.0), Color(0.45, 1.0, 0.7)][i])
		spawn_particles(kenzie.position + Vector3(0, 2.2, 0.2), Color(1.0, 0.82, 0.28), 72)
	if t > 7.6 and victory_cutscene_stage == 1:
		victory_cutscene_stage = 2
		show_victory_cutscene_frame(2)
		speak_line("Bubby, you saved me! Thank you, my ninja hero!", 1.2, 1.02, true, 0.0)
		spawn_candy_burst(Vector3(0.0, 1.35, GOAL_Z + 1.35))
	if t > 11.4 and victory_cutscene_stage == 2:
		victory_cutscene_stage = 3
		show_victory_cutscene_frame(3)
		speak_line("Now let's go eat some candy!", 1.2, 1.02, true, 0.0)
		spawn_candy_burst(Vector3(-0.3, 1.1, GOAL_Z + 1.8))
	if t > 15.2:
		finish_victory_cutscene()


func advance_victory_cutscene() -> void:
	if not victory_cutscene_active:
		return
	if victory_cutscene_frame >= 3:
		finish_victory_cutscene()
		return
	victory_cutscene_frame += 1
	victory_cutscene_stage = victory_cutscene_frame
	victory_cutscene_timer = float(victory_cutscene_frame) * 3.8
	show_victory_cutscene_frame(victory_cutscene_frame)


func finish_victory_cutscene() -> void:
	if not victory_cutscene_active:
		return
	victory_cutscene_active = false
	input_locked = false
	if victory_cutscene_screen:
		victory_cutscene_screen.visible = false
	end_game(true)


func show_victory_cutscene_frame(frame: int) -> void:
	victory_cutscene_frame = clampi(frame, 0, 3)
	if not cutscene_title_label:
		return
	var titles := [
		"MISSION DEBRIEF: SHIELD COLLAPSE",
		"KENZIE SIGNAL RESTORED",
		"FIELD TRANSMISSION",
		"EPILOGUE: CANDY ROUTE"
	]
	var captions := [
		"Riley's final slash hits the broccoli shield core. The dungeon lights flicker. Kenzie's crown stops glowing red.",
		"The spell breaks. Kenzie blinks, lowers her staff, and remembers who she is. The vegetable army loses command.",
		"Kenzie says: \"Bubby, you saved me! Thank you, my ninja hero!\" Riley nods with maximum ninja seriousness.",
		"Kenzie says: \"Now let's go eat some candy!\" Mission complete. Dungeon cleared. Candy operation authorized."
	]
	var panel_colors := [
		Color(0.025, 0.03, 0.055, 0.96),
		Color(0.055, 0.026, 0.075, 0.96),
		Color(0.035, 0.055, 0.05, 0.96),
		Color(0.07, 0.045, 0.02, 0.96)
	]
	cutscene_title_label.text = titles[victory_cutscene_frame]
	cutscene_caption_label.text = captions[victory_cutscene_frame]
	cutscene_image_panel.color = panel_colors[victory_cutscene_frame]
	cutscene_riley_image.visible = victory_cutscene_frame != 1
	cutscene_kenzie_image.visible = victory_cutscene_frame != 0
	cutscene_riley_image.position = [Vector2(94, 76), Vector2(70, 70), Vector2(88, 58), Vector2(116, 68)][victory_cutscene_frame]
	cutscene_kenzie_image.position = [Vector2(520, 76), Vector2(292, 50), Vector2(490, 58), Vector2(470, 68)][victory_cutscene_frame]
	cutscene_riley_image.modulate = [Color(0.75, 0.95, 1.0, 0.9), Color(0.5, 0.6, 0.75, 0.55), Color(1.0, 1.0, 1.0, 1.0), Color(0.9, 1.0, 1.0, 0.95)][victory_cutscene_frame]
	cutscene_kenzie_image.modulate = [Color(1.0, 0.35, 0.95, 0.55), Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 0.92, 1.0, 1.0), Color(1.0, 0.9, 0.72, 0.95)][victory_cutscene_frame]
	cutscene_continue_label.text = "SPACE / CLICK TO ADVANCE" if victory_cutscene_frame < 3 else "SPACE / CLICK TO FINISH"


func dash() -> void:
	if not game_running or dash_cooldown > 0:
		return
	dash_timer = 0.22
	dash_trail_timer = 0.0  # immediately spawn first trail ghost
	invuln_timer = maxf(invuln_timer, 0.22)  # full invuln frames during dash
	dash_cooldown = 1.0
	var line: String = riley_lines.pick_random()
	show_message("DASH", line, Color(0.15, 0.84, 1.0))
	speak_line(line, 1.05, 1.14, false, 2.2)
	play_sfx("dash")


func damage_player() -> void:
	if invuln_timer > 0 or not game_running:
		return
	health -= 1
	invuln_timer = 1.0
	player_hit_flash_timer = 0.55
	shake_camera(0.22, 0.12)
	flash_damage()
	show_message("HIT!", hit_lines.pick_random(), Color(1.0, 0.38, 0.3))
	speak_line(kenzie_taunts.pick_random(), 1.18, 1.02, false, 4.0)
	play_sfx("hit")
	if health <= 0:
		health = 0
		end_game(false)


func remove_projectile(projectile: Node3D) -> void:
	projectiles.erase(projectile)
	projectile.queue_free()


func damage_monster(monster: Node3D, amount: int) -> void:
	if not is_instance_valid(monster):
		return
	var hp := int(monster.get_meta("hp")) - amount
	monster.set_meta("hp", hp)
	monster.set_meta("hit_flash", 0.35)
	var hit_color := Color(0.45, 1.0, 0.35) if String(monster.get_meta("kind")) == "broccoli" else Color(1.0, 0.4, 0.25)
	var hit_pos := monster.position + Vector3(0, 0.75, 0)
	spawn_particles(hit_pos, hit_color, 20)
	spawn_ring(hit_pos, hit_color)
	play_sfx("enemy_stagger")
	monster.set_meta("stagger_timer", 0.28)
	# Knockback away from player
	var knockback := (monster.position - player.position)
	knockback.y = 0
	if knockback.length() > 0.01:
		monster.position += knockback.normalized() * 0.55
	if hp <= 0:
		defeat_monster(monster)


func defeat_monster(monster: Node3D) -> void:
	if not is_instance_valid(monster):
		return
	var kind := String(monster.get_meta("kind"))
	score += 18 if kind == "fruit" else 14
	monsters_defeated += 1
	if kind == "fruit":
		fruit_defeated += 1
	if event_name == "AMBUSH" and bool(monster.get_meta("event_marked", false)):
		event_progress += 1.0
	add_combo()
	award_xp(15 if kind == "fruit" else 12)
	spawn_ring(monster.position + Vector3(0, 0.75, 0), Color(1.0, 0.45, 0.2) if kind == "fruit" else Color(0.33, 0.85, 0.36))
	play_sfx("enemy_death")
	# Erase from active list immediately so it's no longer targeted, then tween-out
	monsters.erase(monster)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(monster, "scale", Vector3.ZERO, 0.22)
	tw.tween_callback(monster.queue_free)
	if randf() < 0.14:
		spawn_powerup()


func remove_monster(monster: Node3D) -> void:
	monsters.erase(monster)
	monster.queue_free()


func remove_star(star: Node3D) -> void:
	ninja_stars.erase(star)
	star.queue_free()


func collect_powerup(powerup: Node3D) -> void:
	var kind := String(powerup.get_meta("kind"))
	match kind:
		"heart":
			health = mini(max_health, health + 1)
			show_message("HEART", "Health restored", Color(1.0, 0.08, 0.14))
		"stars":
			star_ammo = mini(max_star_ammo, star_ammo + 8)
			show_message("STARS", "+8 ninja stars", Color(0.78, 0.94, 1.0))
		_:
			dash_cooldown = 0.0
			dash_timer = maxf(dash_timer, 0.32)
			powerup_boost_timer = 10.0
			show_message("SPEED", "Dash charged", Color(0.15, 0.84, 1.0))
	powerups_collected += 1
	award_xp(10)
	spawn_ring(powerup.position, Color(1.0, 0.82, 0.28))
	powerups.erase(powerup)
	powerup.queue_free()
	play_sfx("powerup")


func add_monster_marker(monster: Node3D, kind: String, archetype: String) -> void:
	var marker := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.52
	mesh.bottom_radius = 0.52
	mesh.height = 0.025
	mesh.radial_segments = 32
	marker.mesh = mesh
	marker.position = Vector3(0, 0.025, 0)
	var color := Color(0.4, 1.0, 0.3)
	if kind == "fruit":
		color = Color(1.0, 0.32, 0.16)
	if archetype == "brute":
		color = Color(1.0, 0.25, 0.25)
	elif archetype == "runner":
		color = Color(0.22, 0.9, 1.0)
	elif archetype == "caster":
		color = Color(1.0, 0.5, 0.12)
	marker.material_override = make_glossy_transparent_material(color, 0.28, 0.35, 0.0)
	marker.name = "MonsterMarker"
	marker.set_meta("base_color", color)
	monster.add_child(marker)


func update_monster_marker(monster: Node3D) -> void:
	var marker := monster.find_child("MonsterMarker", false, false)
	if marker and marker is MeshInstance3D:
		var max_hp: int = maxi(1, int(monster.get_meta("max_hp", 1)))
		var hp: int = maxi(0, int(monster.get_meta("hp", max_hp)))
		var hp_scale := 0.65 + 0.55 * float(hp) / float(max_hp)
		marker.scale = Vector3(hp_scale, 1.0, hp_scale)
		marker.visible = true
		if float(monster.get_meta("hit_flash", 0.0)) > 0.0:
			marker.material_override = make_glossy_transparent_material(Color(1.0, 1.0, 1.0), 0.52, 0.2, 0.0)
		else:
			var base_color: Color = marker.get_meta("base_color", Color(0.4, 1.0, 0.3))
			marker.material_override = make_glossy_transparent_material(base_color, 0.28, 0.35, 0.0)


func update_particles(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for i in range(particles.size() - 1, -1, -1):
		var particle := particles[i]
		var life := float(particle.get_meta("life")) - delta
		particle.set_meta("life", life)
		# Ground mist wisps drift slowly — no gravity, no velocity
		if particle.has_meta("mist_phase"):
			var phase := float(particle.get_meta("mist_phase"))
			particle.position.x += sin(t * 0.28 + phase) * 0.018 * delta
			particle.position.z += cos(t * 0.18 + phase) * 0.012 * delta
			particle.position.y = 0.06 + sin(t * 0.55 + phase) * 0.06
			continue
		particle.position += particle.get_meta("velocity") * delta
		particle.set_meta("velocity", particle.get_meta("velocity") + Vector3.DOWN * 3.6 * delta)
		particle.scale *= 0.992
		if life <= 0:
			particles.remove_at(i)
			particle.queue_free()

	for i in range(rings.size() - 1, -1, -1):
		var ring := rings[i]
		ring.set_meta("life", float(ring.get_meta("life")) - delta)
		ring.scale += Vector3.ONE * delta * float(ring.get_meta("grow_rate", 5.0))
		if bool(ring.get_meta("face_camera", true)):
			ring.look_at(camera.global_position)
		if float(ring.get_meta("life")) <= 0:
			rings.remove_at(i)
			ring.queue_free()


func update_taunts(delta: float) -> void:
	taunt_timer -= delta
	if taunt_timer <= 0:
		taunt_timer = randf_range(10.0, 15.0)
		var taunt: String = kenzie_taunts.pick_random()
		show_message("KENZIE", taunt, Color(0.85, 0.3, 1.0))
		speak_line(taunt, 1.18, 1.02, false, 6.0)


func update_message(delta: float) -> void:
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message_label.visible = false
			sub_message_label.visible = false


func update_hud() -> void:
	if not score_label:
		return
	score_label.text = "Score\n%s" % score
	health_label.text = "Health\n%s / %s" % [health, max_health]
	if mission_label and mission_index < MISSIONS.size():
		var mission: Dictionary = MISSIONS[mission_index]
		mission_label.text = "BOSS: Kenzie Shield" if boss_battle_active else "MISSION %s: %s" % [mission_index + 1, mission["name"]]
	if mission_progress_label and mission_index < MISSIONS.size():
		var mission: Dictionary = MISSIONS[mission_index]
		var elapsed := run_time - mission_start_time(mission_index)
		var remaining := maxf(0.0, float(mission["duration"]) - elapsed)
		var event_text := ""
		if event_name != "":
			event_text = "\nEVENT: %s  %.0f/%.0f  %.0fs" % [event_name, event_progress, event_goal, ceil(event_time_left)]
		mission_progress_label.text = "Break the shield. Dodge broccoli waves. Phase %s.\nShield %s/%s  |  Temple fight" % [boss_phase, boss_health, boss_max_health] if boss_battle_active else ("%s\n%s left  |  Region: %s  |  Monsters %s/%s  Fruit %s/%s  Powerups %s/%s" % [
			mission["brief"],
			format_time(remaining),
			get_current_region(),
			monsters_defeated,
			int(mission["kills"]),
			fruit_defeated,
			int(mission["fruit"]),
			powerups_collected,
			int(mission["powerups"])
		] + event_text)
	elif mission_label:
		mission_label.text = "FINAL DUEL UNLOCKED"
		mission_progress_label.text = "Reach Kenzie and break the shield."
	if star_label:
		star_label.text = "Stars %s/%s" % [star_ammo, max_star_ammo]
	if level_label:
		level_label.text = "Level %s" % riley_level
	if xp_meter:
		xp_meter.max_value = xp_to_next
		xp_meter.value = riley_xp
	if combo_label:
		combo_label.text = "%sx combo" % combo_count if combo_count >= 2 else ""
	if ability_label:
		var dash_text := "Dash READY" if dash_cooldown <= 0.0 else "Dash %.1fs" % dash_cooldown
		var star_text := "Star READY" if star_cooldown <= 0.0 and star_ammo > 0 else ("Star %.1fs" % star_cooldown if star_ammo > 0 else "Star EMPTY")
		var boost_text := "  BOOST %.0fs" % ceil(powerup_boost_timer) if powerup_boost_timer > 0.0 else ""
		ability_label.text = "W/S Move  A/D Strafe  Q/E Turn\nSpace Slice %s  |  F %s  |  Shift %s%s  |  Threat %s/%s" % [slash_damage, star_text, dash_text, boost_text, monsters.size(), max_active_monsters()]
	if health_hearts_label:
		var hearts := ""
		for i in range(max_health):
			hearts += "♥ " if i < health else "♡ "
		health_hearts_label.text = hearts.strip_edges()
		health_hearts_label.modulate = Color(1.0, 0.08, 0.12) if health > 1 else Color(1.0, 0.72, 0.08)
	if health_meter:
		health_meter.max_value = max_health
		health_meter.value = health
	var is_final := campaign_ready_for_finale()
	if boss_battle_active:
		var phase_str: String = ["", " - PHASE 2", " - FINAL PHASE"][boss_phase - 1]
		boss_label.text = "BOSS%s  %s/%s shields" % [phase_str, boss_health, boss_max_health]
	elif boss_zone:
		boss_label.text = "%s/%s shield" % [boss_health, boss_max_health]
	elif kenzie_gate_open:
		boss_label.text = "★ GATE OPEN — enter the tower"
	else:
		var sc := seal_count()
		boss_label.text = "Seals %s/3 — find all seals to open the gate" % sc
	boss_bar.visible = game_running
	boss_bar.max_value = boss_max_health if boss_zone else 3
	boss_bar.value = boss_health if boss_zone else seal_count()
	boss_name_label.visible = game_running
	boss_name_label.text = "★ KENZIE — FINAL BOSS ★" if is_final else "KENZIE'S TEMPLE — visible beyond the valley"
	# Seal + region HUD
	if seal_label:
		var sc := seal_count()
		var lib_s := "✦" if collected_seals.get("library", false) else "○"
		var grd_s := "✦" if collected_seals.get("garden", false) else "○"
		var cry_s := "✦" if collected_seals.get("crypt", false) else "○"
		seal_label.text = "Library%s  Garden%s  Crypt%s  |  Shrines %s/3  Areas %s" % [lib_s, grd_s, cry_s, shrine_count(), discovered_regions.size()]
		seal_label.modulate = Color(1.0, 0.82, 0.28) if sc > 0 else Color(0.7, 0.7, 0.8)
	if region_label:
		region_label.text = get_current_region() if game_running else ""
	if objective_hint_label:
		objective_hint_label.text = nearest_seal_hint() if game_running else ""
		objective_hint_label.modulate = Color(1.0, 0.82, 0.28) if kenzie_gate_open else Color(0.9, 0.94, 1.0)


func show_message(title: String, subtitle: String, color: Color) -> void:
	message_label.text = title
	message_label.modulate = color
	sub_message_label.text = subtitle
	message_label.visible = true
	sub_message_label.visible = true
	message_timer = 0.95


func shake_camera(duration: float, intensity: float) -> void:
	camera_shake_timer = maxf(camera_shake_timer, duration)
	camera_shake_intensity = maxf(camera_shake_intensity, intensity)


func flash_damage() -> void:
	if not damage_flash:
		return
	damage_flash.color = Color(0.9, 0.0, 0.0, 0.0)
	var tween := create_tween()
	tween.tween_property(damage_flash, "color:a", 0.35, 0.06)
	tween.tween_property(damage_flash, "color:a", 0.0, 0.34)


func trigger_hit_stop() -> void:
	if hit_stop_pending:
		return
	hit_stop_pending = true
	call_deferred("_run_hit_stop")


func _run_hit_stop() -> void:
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.018, true, false, true).timeout
	Engine.time_scale = 1.0
	hit_stop_pending = false


func format_time(seconds: float) -> String:
	var total := int(ceil(seconds))
	var minutes := total / 60
	var secs := total % 60
	return "%02d:%02d" % [minutes, secs]


func handle_screen_touch(event: InputEventScreenTouch) -> void:
	var size := get_viewport().get_visible_rect().size
	if event.pressed and event.position.x < size.x * 0.52 and event.position.y > size.y * 0.42:
		var now := Time.get_ticks_msec()
		if now - last_joystick_tap_ms < 330:
			dash()
		last_joystick_tap_ms = now
		joystick_active = true
		joystick_id = event.index
		joystick_origin = joystick_base.global_position + joystick_base.size * 0.5
	elif not event.pressed and event.index == joystick_id:
		joystick_active = false
		joystick_id = -1
		joystick_vector = Vector2.ZERO
		joystick_knob.position = Vector2(36, 36)


func handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not joystick_active or event.index != joystick_id:
		return
	var offset := event.position - joystick_origin
	var max_distance := 42.0
	var clamped := offset.limit_length(max_distance)
	joystick_vector = clamped / max_distance
	joystick_knob.position = Vector2(36, 36) + clamped


func spawn_particles(origin: Vector3, color: Color, count: int) -> void:
	for i in range(count):
		var particle := make_sphere(Vector3.ZERO, randf_range(0.04, 0.085), color, true)
		particle.position = origin
		particle.set_meta("life", randf_range(0.45, 0.8))
		particle.set_meta("velocity", Vector3(randf_range(-1.8, 1.8), randf_range(0.5, 2.9), randf_range(-1.8, 1.8)))
		add_child(particle)
		particles.append(particle)


func spawn_trail_spark(origin: Vector3) -> void:
	var particle := make_sphere(Vector3.ZERO, randf_range(0.035, 0.065), Color(0.55, 1.0, 0.3), true)
	particle.position = origin + Vector3(randf_range(-0.12, 0.12), randf_range(-0.08, 0.1), randf_range(-0.12, 0.12))
	particle.set_meta("life", randf_range(0.18, 0.28))
	particle.set_meta("velocity", Vector3(randf_range(-0.25, 0.25), randf_range(0.05, 0.55), randf_range(-0.25, 0.25)))
	add_child(particle)
	particles.append(particle)


func spawn_ring(origin: Vector3, color: Color) -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.32
	mesh.outer_radius = 0.38
	ring.mesh = mesh
	ring.material_override = make_glow_material(color, 0.9)
	ring.position = origin
	ring.set_meta("life", 0.45)
	ring.set_meta("face_camera", true)
	ring.set_meta("grow_rate", 5.0)
	add_child(ring)
	rings.append(ring)


func spawn_dash_trail() -> void:
	# Ghostly afterimage at Riley's current position — fades quickly
	var ghost := Node3D.new()
	ghost.position = player.position
	ghost.rotation = player.rotation
	ghost.scale = player.scale * 0.96
	# Blue-white translucent sphere cluster to suggest body silhouette
	var alpha_color := Color(0.35, 0.72, 1.0, 0.62)
	ghost.add_child(make_sphere(Vector3(0, 1.05, 0), 0.36, alpha_color, true))
	ghost.add_child(make_sphere(Vector3(0, 1.88, 0), 0.28, alpha_color, true))
	ghost.set_meta("life", 0.18)
	ghost.set_meta("velocity", Vector3.ZERO)
	add_child(ghost)
	particles.append(ghost)


func spawn_candy_burst(origin: Vector3) -> void:
	var colors := [
		Color(1.0, 0.25, 0.45),
		Color(0.35, 0.85, 1.0),
		Color(1.0, 0.82, 0.18),
		Color(0.62, 1.0, 0.35),
		Color(0.9, 0.45, 1.0)
	]
	for i in range(22):
		var candy := MeshInstance3D.new()
		if i % 2 == 0:
			var box_mesh := BoxMesh.new()
			box_mesh.size = Vector3(randf_range(0.08, 0.18), randf_range(0.05, 0.1), randf_range(0.12, 0.26))
			candy.mesh = box_mesh
		else:
			var cylinder_mesh := CylinderMesh.new()
			cylinder_mesh.top_radius = randf_range(0.05, 0.09)
			cylinder_mesh.bottom_radius = cylinder_mesh.top_radius
			cylinder_mesh.height = randf_range(0.08, 0.18)
			cylinder_mesh.radial_segments = 12
			candy.mesh = cylinder_mesh
		candy.position = origin + Vector3(randf_range(-0.35, 0.35), randf_range(-0.1, 0.25), randf_range(-0.25, 0.35))
		candy.rotation_degrees = Vector3(randf_range(0, 180), randf_range(0, 180), randf_range(0, 180))
		candy.material_override = make_glow_material(colors[i % colors.size()], 0.65)
		candy.set_meta("life", randf_range(0.9, 1.4))
		candy.set_meta("velocity", Vector3(randf_range(-2.2, 2.2), randf_range(1.2, 3.6), randf_range(-2.2, 2.2)))
		add_child(candy)
		particles.append(candy)


func spawn_slash_fx() -> void:
	var slash_direction := current_aim_direction()
	var slash_yaw := rad_to_deg(atan2(slash_direction.x, slash_direction.z))
	var slash := make_sprite3d(ASSET_PATH + "slash_fx.png", 0.019, Vector3.ZERO, false)
	slash.position = player.position + Vector3(0.0, 1.42, 0.0) + slash_direction * 1.25
	slash.scale = Vector3(3.15, 1.08, 1.0)
	slash.rotation_degrees = Vector3(-74, slash_yaw, 0)
	slash.modulate = Color(1.0, 1.0, 1.0, 0.95)
	slash.set_meta("life", 0.52)
	slash.set_meta("face_camera", false)
	slash.set_meta("grow_rate", 1.05)
	add_child(slash)
	rings.append(slash)

	var core := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(6.2, 0.1, 0.24)
	core.mesh = mesh
	core.position = player.position + Vector3(0, 1.34, 0) + slash_direction * 1.15
	core.rotation_degrees = Vector3(0, slash_yaw, 0)
	core.material_override = make_glow_material(Color(0.68, 0.95, 1.0), 2.4)
	core.set_meta("life", 0.42)
	core.set_meta("face_camera", false)
	core.set_meta("grow_rate", 0.0)
	add_child(core)
	rings.append(core)

	for offset in [-0.18, 0.18]:
		var echo := MeshInstance3D.new()
		var echo_mesh := BoxMesh.new()
		echo_mesh.size = Vector3(4.9, 0.055, 0.12)
		echo.mesh = echo_mesh
		var side := Vector3(slash_direction.z, 0, -slash_direction.x).normalized()
		echo.position = player.position + Vector3(0, 1.48, 0) + slash_direction * 1.34 + side * offset
		echo.rotation_degrees = Vector3(0, slash_yaw, 0)
		echo.material_override = make_glow_material(Color(0.2, 0.78, 1.0), 1.4)
		echo.set_meta("life", 0.34)
		echo.set_meta("face_camera", false)
		echo.set_meta("grow_rate", 0.0)
		add_child(echo)
		rings.append(echo)


func make_broccoli_mesh() -> Node3D:
	var group := Node3D.new()
	var sprite_name: String = ["broccoli_a.png", "broccoli_b.png", "broccoli_c.png"].pick_random()
	var sprite := make_sprite3d(ASSET_PATH + sprite_name, 0.0054, Vector3(0, 0.16, 0))
	group.add_child(sprite)
	group.add_child(make_cylinder(Vector3(0, -0.2, -0.02), 0.08, 0.14, 0.54, Color(0.47, 0.55, 0.25)))
	var nodes := [
		[0.0, 0.23, 0.0, 0.28],
		[-0.23, 0.15, 0.04, 0.21],
		[0.23, 0.16, -0.04, 0.21],
		[0.0, 0.43, 0.04, 0.19],
		[-0.11, 0.35, 0.15, 0.16],
		[0.11, 0.35, 0.12, 0.16]
	]
	for node in nodes:
		var floret := make_sphere(Vector3(node[0], node[1], node[2] - 0.06), node[3] * 0.58, Color(0.19, 0.39, 0.16), true)
		group.add_child(floret)
	group.scale = Vector3.ONE * randf_range(1.0, 1.2)
	return group


func make_broccoli_monster_mesh(archetype := "soldier") -> Node3D:
	var group := Node3D.new()
	var file_name := "broccoli_knight_scary.png"
	if archetype == "brute":
		file_name = "broccoli_brute_scary.png"
	elif archetype == "runner":
		file_name = "broccoli_runner_scary.png"
	elif archetype == "caster":
		file_name = "broccoli_caster_scary.png"
	var sprite := make_sprite3d(ASSET_PATH + file_name, 0.0064, Vector3(0, 0.92, 0.04))
	sprite.scale = Vector3.ONE * (1.35 if archetype == "brute" else (0.96 if archetype == "runner" else 1.12))
	group.add_child(sprite)
	var core := make_sphere(Vector3(0, 0.72, 0), 0.34, Color(0.12, 0.32, 0.1), true)
	core.visible = false
	group.add_child(core)
	return group


func make_fruit_monster_mesh() -> Node3D:
	var group := Node3D.new()
	var body_color: Color = [Color(0.95, 0.18, 0.14), Color(1.0, 0.48, 0.1), Color(0.86, 0.1, 0.55)].pick_random()
	group.add_child(make_sphere(Vector3(0, 0.62, 0), 0.48, body_color, true))
	group.add_child(make_sphere(Vector3(-0.16, 0.74, 0.4), 0.055, Color(1.0, 1.0, 0.86), true))
	group.add_child(make_sphere(Vector3(0.16, 0.74, 0.4), 0.055, Color(1.0, 1.0, 0.86), true))
	group.add_child(make_cylinder(Vector3(0, 1.08, 0), 0.05, 0.07, 0.32, Color(0.28, 0.16, 0.07), Vector3(16, 0, 0)))
	var leaf := make_box(Vector3(0.18, 1.18, 0.02), Vector3(0.34, 0.06, 0.18), Color(0.24, 0.75, 0.22), true)
	leaf.rotation_degrees = Vector3(0, 16, -24)
	group.add_child(leaf)
	group.scale = Vector3.ONE * 0.95
	return group


func make_star_mesh(color: Color, radius: float) -> Node3D:
	var group := Node3D.new()
	for i in range(4):
		var blade := make_box(Vector3.ZERO, Vector3(radius * 1.5, 0.045, 0.13), color, true)
		blade.rotation_degrees = Vector3(0, 0, i * 45)
		group.add_child(blade)
	group.add_child(make_sphere(Vector3.ZERO, radius * 0.16, Color(0.95, 0.98, 1.0), true))
	return group


func add_torch(node_position: Vector3) -> void:
	add_box(node_position, Vector3(0.18, 0.55, 0.18), Color(0.16, 0.11, 0.08))
	var flame := make_sphere(node_position + Vector3(0, 0.38, 0), 0.18, Color(1.0, 0.6, 0.22), true)
	add_child(flame)
	var light := OmniLight3D.new()
	light.position = node_position + Vector3(0, 0.35, 0)
	light.light_color = Color(1.0, 0.55, 0.18)
	light.light_energy = 0.72
	light.omni_range = 5
	light.shadow_enabled = false
	light.set_meta("phase", randf() * TAU)
	add_child(light)
	torch_lights.append(light)


func update_dungeon_animatables(delta: float) -> void:
	for node in dungeon_animatables:
		if is_instance_valid(node) and node.has_meta("spin_y_deg_s"):
			node.rotation_degrees.y += float(node.get_meta("spin_y_deg_s")) * delta


func update_torch_flicker() -> void:
	var t := Time.get_ticks_msec() * 0.001
	for light in torch_lights:
		if is_instance_valid(light):
			var phase := float(light.get_meta("phase", 0.0))
			light.light_energy = 0.72 + sin(t * 5.1 + phase) * 0.14 + sin(t * 9.7 + phase) * 0.05
			light.omni_range = 5.0 + sin(t * 3.2 + phase) * 0.4


func add_side_chamber(z: float, side: int, tint: Color, chamber_name: String) -> void:
	var x_center := side * 8.9
	var chamber_floor := add_box(Vector3(x_center, 0.04, z), Vector3(5.4, 0.12, 4.2), tint.darkened(0.28))
	chamber_floor.rotation_degrees.y = randf_range(-1.5, 1.5)
	add_box(Vector3(side * 6.2, 0.12, z), Vector3(1.25, 0.18, 3.85), tint.lightened(0.05), true)
	add_doorway_arch(Vector3(side * 5.82, 1.65, z), side, tint.lightened(0.04))
	add_box(Vector3(side * 10.95, 1.25, z), Vector3(0.34, 2.45, 4.45), tint.darkened(0.1))
	add_box(Vector3(x_center, 1.15, z - 2.05), Vector3(5.1, 2.3, 0.28), tint.darkened(0.08))
	add_box(Vector3(x_center, 1.15, z + 2.05), Vector3(5.1, 2.3, 0.28), tint.darkened(0.08))
	add_box(Vector3(x_center, 2.62, z), Vector3(5.15, 0.24, 4.35), tint.darkened(0.18))
	var opening := MeshInstance3D.new()
	var opening_mesh := PlaneMesh.new()
	opening_mesh.size = Vector2(1.95, 2.5)
	opening.mesh = opening_mesh
	opening.position = Vector3(side * 5.68, 1.45, z)
	opening.rotation_degrees = Vector3(0, 90 if side < 0 else -90, 0)
	opening.material_override = make_transparent_material(Color(0.0, 0.0, 0.0), 0.62)
	add_child(opening)
	for dz in [-1.55, 1.55]:
		var column := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.24
		mesh.bottom_radius = 0.34
		mesh.height = 2.55
		mesh.radial_segments = 8
		column.mesh = mesh
		column.position = Vector3(side * 7.0, 1.28, z + dz)
		column.material_override = make_material(tint.lightened(0.08), 0.82, 0.04)
		add_child(column)
		add_box(Vector3(side * 8.68, 1.12, z + dz * 0.9), Vector3(0.22, 2.2, 0.22), tint.lightened(0.04), true)
	for step in range(4):
		add_box(Vector3(side * (6.65 + step * 0.55), 0.13 + step * 0.12, z - 1.5), Vector3(0.58, 0.18, 1.0), tint.lightened(0.02))
	add_torch(Vector3(side * 10.72, 1.7, z - 1.35))
	add_torch(Vector3(side * 10.72, 1.7, z + 1.35))
	add_chamber_props(Vector3(x_center, 0.18, z), side, tint, chamber_name)


func add_doorway_arch(origin: Vector3, side: int, color: Color) -> void:
	add_box(origin + Vector3(0, -0.4, -1.38), Vector3(0.42, 2.5, 0.32), color)
	add_box(origin + Vector3(0, -0.4, 1.38), Vector3(0.42, 2.5, 0.32), color)
	add_box(origin + Vector3(0, 0.9, 0), Vector3(0.48, 0.38, 3.08), color)
	for dz in [-1.2, -0.6, 0.0, 0.6, 1.2]:
		var rib := make_torus(0.42, 0.48, color.lightened(0.08), 0.08)
		rib.position = origin + Vector3(side * 0.04, 0.95, dz)
		rib.rotation_degrees = Vector3(0, 90, 0)
		rib.scale = Vector3(1.0, 1.3, 1.0)
		add_child(rib)


func add_chamber_props(origin: Vector3, side: int, tint: Color, chamber_name: String) -> void:
	match chamber_name:
		"Moon Library":
			for row in range(3):
				add_box(origin + Vector3(side * 1.35, 0.55 + row * 0.42, -1.42), Vector3(1.55, 0.13, 0.24), Color(0.19, 0.12, 0.08))
				add_box(origin + Vector3(side * 1.35, 0.55 + row * 0.42, 1.42), Vector3(1.55, 0.13, 0.24), Color(0.19, 0.12, 0.08))
			add_arcane_circle(origin + Vector3(side * 0.2, 0.06, 0.0), Color(0.42, 0.72, 1.0))
		"Poison Garden":
			for i in range(6):
				add_puddle(origin + Vector3(randf_range(-1.5, 1.5), 0.04, randf_range(-1.35, 1.35)), randf_range(0.22, 0.46), randf_range(0.7, 1.45))
				add_crystal_cluster(origin + Vector3(side * randf_range(0.6, 1.9), 0.12, randf_range(-1.45, 1.45)), Color(0.28, 1.0, 0.42))
		"Crown Crypt":
			add_sarcophagus(origin + Vector3(side * 0.8, 0.24, 0.0), tint.lightened(0.08))
			add_arcane_circle(origin + Vector3(side * 0.2, 0.065, 0.0), Color(1.0, 0.72, 0.2))
			for dz in [-1.35, 1.35]:
				add_statue(origin + Vector3(side * 1.95, 0.16, dz), side, Color(0.18, 0.16, 0.15))
		_:
			for dz in [-1.25, 0.0, 1.25]:
				add_training_dummy(origin + Vector3(side * 1.4, 0.08, dz), side)
			add_arcane_circle(origin + Vector3(0.0, 0.065, 0.0), Color(0.15, 0.84, 1.0))


func add_map_landmarks() -> void:
	add_balcony_lights(-4.8, Color(0.1, 0.085, 0.105))
	add_balcony_lights(-11.8, Color(0.12, 0.08, 0.12))
	for z in [2.25, -5.25, -10.35]:
		add_arcane_circle(Vector3(0, 0.068, z), Color(0.55, 0.32, 1.0))
		add_statue(Vector3(-4.65, 0.13, z - 0.85), -1, Color(0.16, 0.15, 0.17))
		add_statue(Vector3(4.65, 0.13, z + 0.85), 1, Color(0.16, 0.15, 0.17))
	for z in [-1.1, -8.55, -13.9]:
		add_hanging_chain(Vector3(-4.95, 4.8, z))
		add_hanging_chain(Vector3(4.95, 4.8, z + 0.6))


func add_arcane_circle(origin: Vector3, color: Color) -> void:
	var outer := make_torus(0.92, 0.98, color, 0.75)
	outer.position = origin
	outer.rotation_degrees.x = 90
	outer.set_meta("spin_y_deg_s", 22.0)   # degrees per second CW
	add_child(outer)
	dungeon_animatables.append(outer)

	var inner := make_torus(0.42, 0.46, color.lightened(0.18), 0.55)
	inner.position = origin + Vector3(0, 0.012, 0)
	inner.rotation_degrees.x = 90
	inner.set_meta("spin_y_deg_s", -35.0)  # CCW, faster
	add_child(inner)
	dungeon_animatables.append(inner)

	# Spoke group rotates as a unit
	var spoke_root := Node3D.new()
	spoke_root.position = origin + Vector3(0, 0.025, 0)
	spoke_root.rotation_degrees.x = 0
	spoke_root.set_meta("spin_y_deg_s", 14.0)
	add_child(spoke_root)
	dungeon_animatables.append(spoke_root)
	for i in range(6):
		var spoke := make_box(Vector3.ZERO, Vector3(1.75, 0.035, 0.045), color.darkened(0.08), true)
		spoke.rotation_degrees.y = i * 30.0
		spoke_root.add_child(spoke)


func add_crystal_cluster(origin: Vector3, color: Color) -> void:
	for i in range(3):
		var crystal := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = randf_range(0.08, 0.16)
		mesh.height = randf_range(0.45, 0.9)
		mesh.radial_segments = 5
		crystal.mesh = mesh
		crystal.position = origin + Vector3(randf_range(-0.18, 0.18), mesh.height * 0.5, randf_range(-0.18, 0.18))
		crystal.rotation_degrees = Vector3(randf_range(-8, 8), randf_range(0, 180), randf_range(-8, 8))
		crystal.material_override = make_glow_material(color, 0.75)
		add_child(crystal)


func add_sarcophagus(origin: Vector3, color: Color) -> void:
	add_box(origin, Vector3(1.55, 0.32, 2.1), color)
	add_box(origin + Vector3(0, 0.28, 0), Vector3(1.25, 0.18, 1.7), color.lightened(0.08))
	add_box(origin + Vector3(0, 0.42, -0.48), Vector3(0.72, 0.12, 0.42), Color(0.78, 0.58, 0.2), true)


func add_statue(origin: Vector3, side: int, color: Color) -> void:
	add_box(origin + Vector3(0, 0.06, 0), Vector3(0.62, 0.12, 0.62), color.darkened(0.15))
	var body := make_cylinder(origin + Vector3(0, 0.7, 0), 0.24, 0.34, 1.25, color)
	body.rotation_degrees.z = side * 4.0
	add_child(body)
	add_child(make_sphere(origin + Vector3(0, 1.42, 0), 0.24, color.lightened(0.05)))
	var blade := add_box(origin + Vector3(side * 0.34, 0.95, 0.12), Vector3(0.08, 1.15, 0.08), Color(0.5, 0.54, 0.58), true)
	blade.rotation_degrees.z = side * -20.0


func add_training_dummy(origin: Vector3, side: int) -> void:
	add_child(make_cylinder(origin + Vector3(0, 0.5, 0), 0.12, 0.16, 1.0, Color(0.34, 0.2, 0.1)))
	add_box(origin + Vector3(0, 0.95, 0), Vector3(0.95, 0.12, 0.12), Color(0.34, 0.2, 0.1))
	var wrap := add_box(origin + Vector3(0, 0.72, 0), Vector3(0.32, 0.16, 0.2), Color(0.12, 0.46, 0.82), true)
	wrap.rotation_degrees.y = side * 10.0


func add_balcony_lights(z: float, color: Color) -> void:
	for side in [-1, 1]:
		for dz in [-2.15, 0.0, 2.15]:
			add_box(Vector3(side * 5.72, 4.16, z + dz), Vector3(0.16, 0.95, 0.12), color.lightened(0.08), true)
		add_box(Vector3(side * 5.68, 4.82, z), Vector3(0.18, 0.16, 5.35), color.lightened(0.04))


func add_hanging_chain(origin: Vector3) -> void:
	for i in range(5):
		var link := make_torus(0.09, 0.12, Color(0.22, 0.2, 0.18), 0.02)
		link.position = origin + Vector3(0, -i * 0.18, 0)
		link.rotation_degrees = Vector3(90 if i % 2 == 0 else 0, 0, 0)
		add_child(link)
	var lamp := make_sphere(origin + Vector3(0, -1.05, 0), 0.16, Color(1.0, 0.5, 0.18), true)
	add_child(lamp)


func add_upper_gallery(z: float) -> void:
	for side in [-1, 1]:
		var x: float = side * 7.15
		add_box(Vector3(x, 3.48, z), Vector3(2.15, 0.18, 6.2), Color(0.09, 0.08, 0.1))
		add_box(Vector3(side * 5.95, 3.88, z), Vector3(0.18, 0.8, 6.0), Color(0.13, 0.1, 0.11))
		for dz in [-2.4, -1.2, 0.0, 1.2, 2.4]:
			add_box(Vector3(side * 5.72, 4.18, z + dz), Vector3(0.16, 0.9, 0.12), Color(0.18, 0.13, 0.09), true)
		add_light_beam(Vector3(side * 4.7, 4.9, z), side * 10)


func add_arch_detail(z: float) -> void:
	for side in [-1, 1]:
		add_box(Vector3(side * 5.42, 0.38, z), Vector3(0.72, 0.24, 0.74), Color(0.08, 0.07, 0.08))
		add_box(Vector3(side * 5.42, 5.78, z), Vector3(0.92, 0.2, 0.78), Color(0.16, 0.13, 0.13))
		add_box(Vector3(side * 5.8, 5.55, z - 0.78), Vector3(0.34, 0.24, 1.35), Color(0.12, 0.09, 0.1))
		add_box(Vector3(side * 5.8, 5.55, z + 0.78), Vector3(0.34, 0.24, 1.35), Color(0.12, 0.09, 0.1))
		var column := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.22
		mesh.bottom_radius = 0.28
		mesh.height = 4.55
		mesh.radial_segments = 8
		column.mesh = mesh
		column.position = Vector3(side * 5.42, 2.56, z)
		column.material_override = make_material(Color(0.11, 0.09, 0.095), 0.9, 0.02)
		add_child(column)

	for x in [-5.0, 5.0]:
		add_box(Vector3(x, 5.92, z), Vector3(0.1, 0.3, 0.42), Color(0.08, 0.065, 0.07))


func add_floor_edge_trim(z: float) -> void:
	add_box(Vector3(-4.78, 0.085, z), Vector3(0.12, 0.08, 2.1), Color(0.19, 0.14, 0.09), true)
	add_box(Vector3(4.78, 0.085, z), Vector3(0.12, 0.08, 2.1), Color(0.19, 0.14, 0.09), true)
	add_box(Vector3(0, 0.074, z + 0.98), Vector3(9.2, 0.05, 0.09), Color(0.09, 0.075, 0.08))


func add_rubble_cluster(origin: Vector3) -> void:
	for i in range(5):
		var rock := add_box(
			origin + Vector3(randf_range(-0.28, 0.28), randf_range(0.0, 0.08), randf_range(-0.28, 0.28)),
			Vector3(randf_range(0.13, 0.34), randf_range(0.08, 0.22), randf_range(0.13, 0.34)),
			Color(randf_range(0.09, 0.14), randf_range(0.08, 0.12), randf_range(0.08, 0.115))
		)
		rock.rotation_degrees = Vector3(randf_range(-8, 8), randf_range(0, 180), randf_range(-8, 8))


func add_puddle(node_position: Vector3, radius: float, width_scale: float) -> void:
	var puddle := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.012
	mesh.radial_segments = 32
	puddle.mesh = mesh
	puddle.position = node_position
	puddle.scale.x = width_scale
	puddle.rotation_degrees.y = randf_range(-18, 18)
	# Near-mirror water — roughness 0.04 / metallic 0.92 reflects torch and ambient light
	puddle.material_override = make_glossy_transparent_material(Color(0.08, 0.1, 0.15), 0.52, 0.04, 0.92)
	add_child(puddle)


func add_mote(node_position: Vector3) -> void:
	var mote := make_sphere(node_position, randf_range(0.012, 0.028), Color(1.0, 0.7, 0.38), true)
	mote.set_meta("life", 9999.0)
	add_child(mote)


func add_ground_mist_mote(node_position: Vector3) -> void:
	# Slightly larger, cool-toned translucent disc — simulates ground fog wisps
	var mote := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = randf_range(0.08, 0.22)
	mesh.bottom_radius = mesh.top_radius
	mesh.height = randf_range(0.015, 0.04)
	mesh.radial_segments = 12
	mote.mesh = mesh
	mote.position = node_position
	mote.scale.x = randf_range(0.8, 2.2)  # stretched into a wisp shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.62, 0.78, randf_range(0.04, 0.10))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mote.material_override = mat
	mote.set_meta("life", 9999.0)
	# Give each wisp a slow drift so they appear to breathe
	mote.set_meta("mist_phase", randf() * TAU)
	add_child(mote)
	particles.append(mote)


func add_shadow_disc(node_position: Vector3, size: Vector2, alpha: float) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.5
	mesh.bottom_radius = 0.5
	mesh.height = 0.01
	mesh.radial_segments = 40
	disc.mesh = mesh
	disc.position = node_position
	disc.scale = Vector3(size.x, 1.0, size.y)
	disc.material_override = make_glossy_transparent_material(Color(0, 0, 0), alpha, 0.95, 0.0)
	add_child(disc)
	return disc


func add_banner(node_position: Vector3, y_rotation: float) -> void:
	var banner := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(0.74, 1.65)
	banner.mesh = mesh
	banner.position = node_position
	banner.rotation_degrees = Vector3(0, y_rotation, 0)
	banner.material_override = make_material(Color(0.23, 0.08, 0.38))
	add_child(banner)

	var trim := add_box(node_position + Vector3(0, 0.74, 0), Vector3(0.82, 0.06, 0.035), Color(0.72, 0.54, 0.18))
	trim.rotation_degrees.y = y_rotation
	var emblem := add_box(node_position + Vector3(0, 0.1, 0), Vector3(0.34, 0.48, 0.04), Color(0.55, 0.28, 0.82), true)
	emblem.rotation_degrees.y = y_rotation


func add_light_beam(node_position: Vector3, y_rotation: float) -> void:
	var beam := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1.45, 5.2)
	beam.mesh = mesh
	beam.position = node_position
	beam.rotation_degrees = Vector3(-34, y_rotation, 0)
	beam.material_override = make_transparent_material(Color(0.65, 0.78, 1.0), 0.13)
	add_child(beam)


func add_boss_backdrop() -> void:
	var back_glow := MeshInstance3D.new()
	var glow_mesh := PlaneMesh.new()
	glow_mesh.size = Vector2(5.8, 4.2)
	back_glow.mesh = glow_mesh
	back_glow.position = Vector3(0, 2.85, GOAL_Z - 1.05)
	back_glow.rotation_degrees = Vector3(0, 0, 0)
	back_glow.material_override = make_transparent_material(Color(0.62, 0.22, 1.0), 0.18)
	add_child(back_glow)

	for side in [-1, 1]:
		add_box(Vector3(side * 2.6, 2.95, GOAL_Z - 0.82), Vector3(0.14, 3.4, 0.16), Color(0.8, 0.34, 1.0), true)
		add_box(Vector3(side * 1.62, 0.98, GOAL_Z - 0.35), Vector3(0.16, 0.18, 2.4), Color(0.28, 0.14, 0.42), true)
		add_light_beam(Vector3(side * 0.8, 4.25, GOAL_Z - 0.55), side * 13.0)

	var crown := make_torus(1.75, 1.84, Color(0.96, 0.58, 1.0), 0.75)
	crown.position = Vector3(0, 2.25, GOAL_Z - 0.3)
	crown.rotation_degrees = Vector3(90, 0, 0)
	add_child(crown)


func add_box(node_position: Vector3, size: Vector3, color: Color, glow := false) -> MeshInstance3D:
	var mesh := make_box(Vector3.ZERO, size, color, glow)
	mesh.position = node_position
	add_child(mesh)
	return mesh


func make_box(node_position: Vector3, size: Vector3, color: Color, glow := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = node_position
	node.material_override = make_glow_material(color, 0.45) if glow else make_material(color)
	return node


func make_sphere(node_position: Vector3, radius: float, color: Color, glow := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	node.mesh = mesh
	node.position = node_position
	node.material_override = make_glow_material(color, 0.45) if glow else make_material(color)
	return node


func make_cylinder(node_position: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color, rotation_degrees := Vector3.ZERO, glow := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 16
	node.mesh = mesh
	node.position = node_position
	node.rotation_degrees = rotation_degrees
	node.material_override = make_glow_material(color, 0.45) if glow else make_material(color)
	return node


func make_sprite3d(texture_path: String, pixel_size: float, node_position: Vector3, face_camera := true) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = make_image_texture(texture_path)
	sprite.pixel_size = pixel_size
	sprite.centered = true
	sprite.position = node_position
	if face_camera:
		sprite.add_to_group("camera_facing_art")
	return sprite


func add_wall_art(texture_path: String, node_position: Vector3, pixel_size: float, y_rotation: float) -> void:
	var sprite := make_sprite3d(texture_path, pixel_size, node_position, false)
	sprite.rotation_degrees = Vector3(0, y_rotation, 0)
	add_child(sprite)


func make_torus(inner_radius: float, outer_radius: float, color: Color, energy: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	node.mesh = mesh
	node.material_override = make_glow_material(color, energy)
	return node


func make_material(color: Color, roughness := 0.82, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func make_glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := make_material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func make_transparent_material(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func make_glossy_transparent_material(color: Color, alpha: float, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = roughness
	material.metallic = metallic
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func choose_voice() -> void:
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if voices.size() > 0:
		voice_id = voices[0]


func speak_line(text: String, pitch: float, rate: float, interrupt := false, min_gap := 3.0) -> void:
	if voice_id == "":
		return
	var now := Time.get_ticks_msec() / 1000.0
	if not interrupt and now < next_voice_time:
		return
	next_voice_time = now + maxf(min_gap, minf(8.0, text.length() * 0.055))
	DisplayServer.tts_speak(text, voice_id, 70, pitch, rate, 0, interrupt)


func play_music() -> void:
	if music_player and not music_player.playing:
		music_player.play()


func play_sfx(kind: String) -> void:
	if not sfx_player:
		return
	sfx_player.stream = make_sfx_stream(kind)
	sfx_player.play()


func make_music_stream() -> AudioStreamWAV:
	# A-minor dungeon chant — slow, ominous, dark fantasy feel
	# A3=220  B3=246.94  C4=261.63  D4=293.66  E4=329.63  F4=349.23  G4=392  A4=440
	var melody := [
		220.0, 0.0, 0.0, 261.63, 293.66, 0.0, 329.63, 0.0,
		329.63, 293.66, 261.63, 0.0, 246.94, 0.0, 220.0, 0.0,
		220.0, 0.0, 246.94, 261.63, 293.66, 329.63, 349.23, 0.0,
		392.0, 349.23, 329.63, 293.66, 261.63, 0.0, 220.0, 0.0,
		220.0, 0.0, 329.63, 0.0, 261.63, 293.66, 261.63, 220.0,
		246.94, 261.63, 293.66, 329.63, 261.63, 220.0, 0.0, 0.0,
		220.0, 246.94, 261.63, 293.66, 329.63, 349.23, 392.0, 349.23,
		329.63, 293.66, 261.63, 246.94, 220.0, 0.0, 0.0, 0.0
	]
	return make_wave_stream(melody, 0.24, -0.50, true)


func make_sfx_stream(kind: String) -> AudioStreamWAV:
	match kind:
		"slice":
			return make_wave_stream([1244.5, 932.33, 698.46], 0.045, -0.18, false)
		"swing":
			return make_wave_stream([520.0, 740.0], 0.045, -0.36, false)
		"dash":
			return make_wave_stream([392.0, 587.33, 783.99, 1174.66], 0.04, -0.24, false)
		"hit":
			return make_wave_stream([164.81, 123.47, 92.5], 0.08, -0.16, false)
		"throw":
			return make_wave_stream([246.94, 329.63, 392.0], 0.045, -0.34, false)
		"boss":
			return make_wave_stream([196.0, 261.63, 392.0, 523.25], 0.055, -0.2, false)
		"star":
			return make_wave_stream([880.0, 1174.66, 1567.98], 0.032, -0.28, false)
		"powerup":
			return make_wave_stream([523.25, 659.25, 783.99, 1046.5], 0.045, -0.24, false)
		"enemy_stagger":
			return make_wave_stream([320.0, 180.0], 0.03, -0.22, false)
		"enemy_death":
			return make_wave_stream([220.0, 160.0, 110.0, 80.0], 0.04, -0.18, false)
		"boss_phase":
			return make_wave_stream([196.0, 261.63, 392.0, 523.25, 659.25], 0.06, -0.14, false)
		"shield_crack":
			return make_wave_stream([880.0, 660.0, 440.0, 220.0], 0.055, -0.2, false)
		"combo_milestone":
			return make_wave_stream([523.25, 659.25, 783.99, 1046.5], 0.04, -0.2, false)
		"level_up_fanfare":
			return make_wave_stream([523.25, 659.25, 783.99, 1046.5, 1318.51, 1046.5, 783.99], 0.05, -0.16, false)
		"win":
			return make_wave_stream([523.25, 659.25, 783.99, 1046.5, 1318.51], 0.09, -0.18, false)
		"over":
			return make_wave_stream([220.0, 185.0, 146.83, 110.0], 0.12, -0.16, false)
		_:
			return make_wave_stream([440.0], 0.08, -0.3, false)


func make_wave_stream(notes: Array, note_duration: float, volume: float, loop := false) -> AudioStreamWAV:
	var sample_rate := 22050
	var data := PackedByteArray()
	var phase := 0.0
	for freq in notes:
		var frames := int(sample_rate * note_duration)
		for i in range(frames):
			var t := float(i) / float(sample_rate)
			var amp := 0.0
			if float(freq) > 0.0:
				var env := minf(1.0, float(i) / 320.0) * minf(1.0, float(frames - i) / 900.0)
				var tone := sin(phase) + 0.34 * sin(phase * 2.0) + 0.13 * sin(phase * 3.0)
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


func make_screen() -> Control:
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel := ColorRect.new()
	panel.color = Color(0.0, 0.0, 0.0, 0.68)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(panel)
	return screen


func make_card() -> VBoxContainer:
	var card := VBoxContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-420, -190)
	card.size = Vector2(840, 380)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", 16)
	return card


func make_title(title: String, subtitle: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var title_label := make_label(title, 64, Color.WHITE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub_label := make_label(subtitle, 18, Color(1.0, 0.85, 0.42))
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	box.add_child(sub_label)
	return box


func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", size)
	return label


func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 54)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", make_panel_style(Color(0.035, 0.038, 0.048, 0.78), 28))
	button.add_theme_stylebox_override("hover", make_panel_style(Color(0.08, 0.1, 0.13, 0.86), 28))
	button.add_theme_stylebox_override("pressed", make_panel_style(Color(0.14, 0.08, 0.2, 0.9), 28))
	return button


func style_round_button(button: Button, radius: int) -> void:
	button.add_theme_stylebox_override("normal", make_panel_style(Color(0.035, 0.038, 0.048, 0.78), radius))
	button.add_theme_stylebox_override("hover", make_panel_style(Color(0.08, 0.1, 0.13, 0.86), radius))
	button.add_theme_stylebox_override("pressed", make_panel_style(Color(0.14, 0.08, 0.2, 0.9), radius))


func make_portrait(texture_path: String, size: Vector2) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.texture = make_image_texture(texture_path)
	portrait.size = size
	portrait.custom_minimum_size = size
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return portrait


func make_image_texture(texture_path: String) -> Texture2D:
	var imported := load(texture_path)
	if imported is Texture2D:
		return imported
	var image := Image.load_from_file(texture_path)
	if image:
		return ImageTexture.create_from_image(image)
	return ImageTexture.new()


func make_hud_label(text: String) -> Label:
	var label := make_label(text, 22, Color.WHITE)
	label.size = Vector2(150, 68)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func make_panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(1, 1, 1, 0.16)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
