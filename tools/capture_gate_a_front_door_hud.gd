extends SceneTree

## Supplemental Gate A visual-capture helper. The canonical Gate A proof is
## still the continuous representative player session in ACTIVE_GAME_PLAN.md;
## these two stills only make its front door and exploration HUD easy to judge.
##
## Default run captures both the configured project boot scene and a populated
## Meadows HUD at the production 1920x1080 canvas. `--title-only` and
## `--hud-only` support cheap targeted retakes; the latter also lets this helper
## be exercised on a branch whose main_scene has not taken the title change.
##
##   godot --path . --rendering-driver opengl3 \
##     --script tools/capture_gate_a_front_door_hud.gd

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CAPTURE_RUNTIME := preload("res://tools/capture_runtime.gd")
const OUT_DIR := "res://shots/gate_a_capture"
const WIDTH := 1920
const HEIGHT := 1080
const READY_TIMEOUT_MS := 300_000
const HUD_SETTLE_TIMEOUT_MS := 30_000

var _failures: Array[String] = []
var _written: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_position(Vector2i.ZERO)
	DisplayServer.window_set_size(Vector2i(WIDTH, HEIGHT))
	root.size = Vector2i(WIDTH, HEIGHT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var user_args := OS.get_cmdline_user_args()
	var hud_only := user_args.has("--hud-only")
	var title_only := user_args.has("--title-only")
	if hud_only and title_only:
		_failures.append("--hud-only and --title-only cannot be combined")
	var capture_targets: Array[String] = []
	if not hud_only:
		capture_targets.append("%s/title_boot.png" % OUT_DIR)
	if not title_only:
		capture_targets.append("%s/exploration_hud.png" % OUT_DIR)
	_failures.append_array(CAPTURE_RUNTIME.clear_named_pngs(capture_targets))
	if not _failures.is_empty():
		_finish()
		return
	await process_frame # autoloads finish joining /root after SceneTree._init

	if not hud_only:
		await _capture_configured_title()
	if _failures.is_empty() and not title_only:
		await _capture_exploration_hud()

	_finish()


func _finish() -> void:
	print("\n%d fresh frame(s) -> %s" % [_written.size(), OUT_DIR])
	print("Supplemental stills only; they do not replace the continuous Gate A evidence session.")
	if not _failures.is_empty():
		for failure in _failures:
			print("FAIL: %s" % failure)
		quit(1)
		return
	quit(0)


func _capture_configured_title() -> void:
	var configured := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if configured != TITLE_SCENE:
		_failures.append("configured main scene is %s, expected the Gate A title scene %s" % [configured, TITLE_SCENE])
		return
	var packed := load(configured) as PackedScene
	if packed == null:
		_failures.append("could not load configured title scene %s" % configured)
		return
	var title := packed.instantiate()
	root.add_child(title)
	current_scene = title
	if not await CAPTURE_RUNTIME.wait_until(
		self,
		func() -> bool: return _title_ready(title),
		"configured title screen",
		func() -> String: return _title_readiness_details(title),
		HUD_SETTLE_TIMEOUT_MS,
	):
		_failures.append("title state at timeout: %s" % _title_readiness_details(title))
		return
	await _shoot("title_boot")
	var title_id := title.get_instance_id()
	title.queue_free()
	current_scene = null
	if not await CAPTURE_RUNTIME.wait_until(
		self,
		func() -> bool: return instance_from_id(title_id) == null,
		"title teardown",
		Callable(),
		HUD_SETTLE_TIMEOUT_MS,
	):
		_failures.append("title teardown timed out")


func _title_ready(title: Node) -> bool:
	if not is_instance_valid(title):
		return false
	if not title.is_in_group(&"title_screen") or not title.is_node_ready():
		return false
	var focused := root.gui_get_focus_owner()
	return focused is Button and focused.is_visible_in_tree() and (focused as Button).text == "Start New Game"


func _title_readiness_details(title: Node) -> String:
	var focused := root.gui_get_focus_owner()
	return "size=%s ready=%s grouped=%s focus=%s visible=%s" % [
		root.size,
		is_instance_valid(title) and title.is_node_ready(),
		is_instance_valid(title) and title.is_in_group(&"title_screen"),
		"<none>" if focused == null else str(focused.get_path()),
		focused != null and focused.is_visible_in_tree(),
	]


func _capture_exploration_hud() -> void:
	# Seed the party before the SequenceDirector enters the tree. Its documented
	# restore seam treats an existing party as proof the starter ceremony has
	# already completed, leaving this supplemental exploration frame out of the
	# opening's real name/starter modals without reaching into either panel.
	_seed_representative_game_state()
	if not _failures.is_empty():
		return
	var packed := load(WORLD_SCENE) as PackedScene
	if packed == null:
		_failures.append("could not load %s" % WORLD_SCENE)
		return
	var world := packed.instantiate()
	root.add_child(world)
	current_scene = world
	if not await CAPTURE_RUNTIME.wait_until(
		self,
		func() -> bool: return _world_ready(world),
		"Meadows HUD and minimap",
		func() -> String: return _world_readiness_details(world),
		READY_TIMEOUT_MS,
	):
		_failures.append("Meadows startup timed out: %s" % _world_readiness_details(world))
		return

	var player := world.get_node(^"Player") as CharacterBody3D
	var hud := world.get_node(^"PlaygroundHUD") as CanvasLayer
	var rig := world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var field := HEIGHTFIELD.new()
	# The survey's spawn-outward viewpoint is already authored to clear every
	# village structure and read along the pond-valley route. Its trainer and
	# summoned active creature keep this recognisably third-person exploration,
	# not a detached landscape camera or another roof-level site shot.
	var player_xz := Vector2(-15.0, -1.0)
	player.global_position = Vector3(player_xz.x, field.height_at(player_xz.x, player_xz.y) + 0.4, player_xz.y)
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	var eye_xz := Vector2(-9.0, -7.0)
	var target_xz := Vector2(-140.0, 145.0)
	camera.global_position = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + 2.2, eye_xz.y)
	camera.look_at(Vector3(target_xz.x, field.height_at(target_xz.x, target_xz.y) + 8.0, target_xz.y), Vector3.UP)
	camera.rotation = Vector3(_pitch_for_horizon(0.28, camera.fov), camera.rotation.y, 0.0)
	var away := player.global_position - camera.global_position
	player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)
	camera.make_current()
	var terrain := world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	await _finish_representative_world_state(world)
	if not _failures.is_empty():
		return
	if not await _wait_for_representative_hud(hud, camera):
		_failures.append("HUD state at timeout: %s" % _hud_readiness_details(hud, camera))
		return
	_log_legend_rects(hud)
	await _shoot("exploration_hud")


func _world_ready(world: Node) -> bool:
	if not is_instance_valid(world) or not world.is_node_ready():
		return false
	# The HUD and minimap can finish one frame before playground_world resumes
	# its async _ready() and begins the expensive scatter. These nodes are all
	# created at the end of _build_settlement(), after vegetation and water, so
	# they distinguish a complete representative world from that premature UI-
	# only state without exposing a production-only "capture ready" flag.
	for path in [^"Village", ^"Props", ^"BuildPlacer"]:
		if world.get_node_or_null(path) == null:
			return false
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if player == null or hud == null or not hud.is_node_ready() or not hud.visible:
		return false
	var legend := hud.get_node_or_null(^"Root/ExplorationLegend") as Control
	var minimap: Variant = hud.get("_minimap")
	if legend == null or not legend.visible or minimap == null or not bool(hud.get("_minimap_baked")):
		return false
	var height: float = float(world.call("ground_height_at", -15.0, -1.0))
	return is_finite(height)


func _world_readiness_details(world: Node) -> String:
	if not is_instance_valid(world):
		return "world freed"
	var present: Array[String] = []
	for path in [^"Terrain", ^"Vegetation", ^"Water", ^"Village", ^"Props", ^"BuildPlacer", ^"PlaygroundHUD"]:
		if world.get_node_or_null(path) != null:
			present.append(str(path))
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	return "nodes=%s world_ready=%s minimap_baked=%s" % [
		str(present),
		world.is_node_ready(),
		hud != null and bool(hud.get("_minimap_baked")),
	]


func _seed_representative_game_state() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_failures.append("Game autoload missing; cannot populate representative HUD")
		return
	var inventory: RefCounted = game.get("inventory")
	for entry in [["orb_basic", 8], ["potion_small", 4], ["berries", 12], ["torch", 1]]:
		inventory.call("add", str(entry[0]), int(entry[1]))
	game.call("autofill_hotbar")
	game.call("set_objective", "Explore the Old Mill Crossing", Vector3(80.0, 0.0, -55.0))
	var map_state: RefCounted = game.get("map")
	map_state.call("mark_visited", Vector3(-15.0, 0.0, -1.0))

	var party: RefCounted = game.get("party")
	if int(party.call("size")) == 0:
		for entry in [["terrapup", "Biscuit"], ["ripplet", "Brook"], ["galewisp", "Kite"]]:
			var creature: RefCounted = game.call("make_creature", str(entry[0]), str(entry[1]))
			if creature != null:
				party.call("add", creature)


func _finish_representative_world_state(world: Node) -> void:
	var director := world.get_node_or_null(^"EncounterDirector")
	if director != null and director.call("ally_instance") == null:
		await director.call("summon_active_creature")

	var strip: Variant = (world.get_node(^"PlaygroundHUD") as CanvasLayer).get("_party_strip")
	if strip is Object and (strip as Object).has_method("set_pinned"):
		strip.call("set_pinned", true)


func _force_controller_glyphs() -> void:
	var press := InputEventJoypadButton.new()
	press.device = 0
	press.button_index = JOY_BUTTON_A
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventJoypadButton.new()
	release.device = 0
	# The same known-delivered pair used by smoke_exploration_legend.gd. The
	# readiness caller captures/settles the mouse first so a window-motion event
	# cannot immediately reclaim last-device intent.
	release.button_index = JOY_BUTTON_A
	release.pressed = false
	Input.parse_input_event(release)


func _wait_for_representative_hud(hud: CanvasLayer, camera: Camera3D) -> bool:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await process_frame
	await process_frame
	_force_controller_glyphs()
	var deadline := Time.get_ticks_msec() + HUD_SETTLE_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if _representative_hud_ready(hud, camera):
			return true
	_failures.append("timed out after %.0fs waiting for populated controller HUD" % [HUD_SETTLE_TIMEOUT_MS / 1000.0])
	return false


func _representative_hud_ready(hud: CanvasLayer, camera: Camera3D) -> bool:
	if not _failures.is_empty() or not camera.current or not hud.visible:
		return false
	var legend := hud.get_node_or_null(^"Root/ExplorationLegend") as Control
	var label := hud.get_node_or_null(^"Root/ExplorationLegend/Margin/Label") as RichTextLabel
	var objective: Variant = hud.get("_objective_text_label")
	var strip: Variant = hud.get("_party_strip")
	var minimap: Variant = hud.get("_minimap")
	if legend == null or label == null or objective == null or strip == null or minimap == null:
		return false
	if not legend.is_visible_in_tree() or not (strip as Control).is_visible_in_tree():
		return false
	if not label.text.contains("xbox_button_start.png") or str((objective as Label).text).is_empty():
		return false
	var populated_slots := 0
	for slot in 5:
		var path := NodePath("Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot%d/Label" % (slot + 1))
		var slot_label := hud.get_node_or_null(path) as RichTextLabel
		if slot_label == null:
			return false
		if not slot_label.text.is_empty():
			populated_slots += 1
	return populated_slots >= 4


func _hud_readiness_details(hud: CanvasLayer, camera: Camera3D) -> String:
	var legend := hud.get_node_or_null(^"Root/ExplorationLegend") as Control
	var label := hud.get_node_or_null(^"Root/ExplorationLegend/Margin/Label") as RichTextLabel
	var objective: Variant = hud.get("_objective_text_label")
	var strip: Variant = hud.get("_party_strip")
	var slots: Array[String] = []
	for slot in 5:
		var path := NodePath("Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot%d/Label" % (slot + 1))
		var slot_label := hud.get_node_or_null(path) as RichTextLabel
		slots.append("<missing>" if slot_label == null else slot_label.text)
	return "camera=%s legend=%s controller=%s strip=%s objective='%s' slots=%s" % [
		camera.current,
		legend != null and legend.is_visible_in_tree(),
		label != null and label.text.contains("xbox_button_start.png"),
		strip is Control and (strip as Control).is_visible_in_tree(),
		"<missing>" if objective == null else str((objective as Label).text),
		str(slots),
	]


func _log_legend_rects(hud: CanvasLayer) -> void:
	var legend := hud.get_node(^"Root/ExplorationLegend") as Control
	var margin := hud.get_node(^"Root/ExplorationLegend/Margin") as Control
	var label := hud.get_node(^"Root/ExplorationLegend/Margin/Label") as RichTextLabel
	print(
		"  legend rects: panel=%s margin=%s label=%s content_height=%.1f"
		% [legend.get_global_rect(), margin.get_global_rect(), label.get_global_rect(), label.get_content_height()]
	)


func _pitch_for_horizon(fraction: float, fov: float) -> float:
	var half := tan(deg_to_rad(fov) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_failures.append("%s: viewport returned no image" % name)
		return
	if image.get_width() != WIDTH or image.get_height() != HEIGHT:
		_failures.append("%s: expected %dx%d, got %dx%d" % [name, WIDTH, HEIGHT, image.get_width(), image.get_height()])
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		_failures.append("%s: save_png failed (%d)" % [name, error])
		return
	_written.append(path)
	print("  %-24s -> %s (%dx%d)" % [name, path, image.get_width(), image.get_height()])
