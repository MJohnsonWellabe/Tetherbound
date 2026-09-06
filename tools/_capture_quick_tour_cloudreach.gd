extends SceneTree

## QUICK TOUR -- Cloudreach Cliffs pass. Sibling of
## tools/_capture_quick_tour_meadows.gd; read that file's header first, the
## same budget discipline and step order apply here. This is explicitly NOT
## the Gate F evidence pipeline (tools/owner/KICKOFF.cmd).
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_quick_tour_cloudreach.gd -- \
##     --budget-seconds=1200 --out=res://shots_quick_tour/cloudreach
##
## On current `main` there is no menu teleport into Cloudreach and playing
## through the Meadows relay/story gate to reach it is far too slow for a
## 20-minute budget, so this enters the realm directly the same way every
## existing Cloudreach capture tool does (tools/capture_cloudreach_act_one.gd,
## tools/capture_cloudreach_foundation.gd): force `Game.current_realm` and the
## realm-unlock progression flags, then instantiate the Cloudreach scene
## directly. No travel, no relay dialogue, no Meadows scene touched.
##
## The four stands below are lifted verbatim (stand/target world coordinates)
## from tools/capture_cloudreach_foundation.gd's `VIEWS` table -- already
## real, already-proven production stands on the authored route network, not
## invented for this tool. Their targets carry an authored elevation (a
## distant cliff feature, not the ground under it), so `look_y` is taken
## directly from that table instead of being read off the heightfield the
## way tools/_capture_quick_tour_meadows.gd's flat-ground stands are.
##
## Combat/creature/HUD/menu/play-functionality steps reuse the identical
## EncounterDirector/CombatManager/Game.menu()/stick_navigator idioms the
## Meadows pass uses -- `scripts/world/cloudreach_world_runtime.gd` builds a
## `CombatManager`/`EncounterDirector` pair under the world root at runtime
## the same way `playground_world.gd` does for the Meadows, so the same
## node-path lookups (`^"CombatManager"`, `^"EncounterDirector"`) apply
## unchanged. Ground height goes through `world.call("ground_height_at", x,
## z)` (`scripts/world/cloudreach_world.gd`) instead of Meadows'
## `playground_heightfield.gd`, because Cloudreach has no standalone
## heightfield helper class.

const SCENE := "res://scenes/world/cloudreach_cliffs.tscn"
const DEFAULT_OUT := "res://shots_quick_tour/cloudreach"
const DEFAULT_BUDGET_S := 1200.0

const BOOT_FRAMES := 180
const SETTLE_FRAMES := 40
const POSE_FRAMES := 6
const FOV := 70.0
const BACK_M := 3.2
const UP_M := 1.70
const LOOK_UP_M := 1.6

## `stand`/`target` copied from tools/capture_cloudreach_foundation.gd's
## `VIEWS` (id in that table -> id here): 01-arrival-first-reveal,
## 03-windscar-ravine, 05-upper-cloudreach-cliffhold, 06-summit-final-approach
## (the last is the closest authored stand to Cloudreach's endgame, so it
## stands in for "boss/hero location"). `target` keeps its authored Y.
const STANDS := [
	{"id": "arrival-hub", "stand": [0.0, -260.0], "target": [0.0, 150.0, -130.0], "night": true},
	{"id": "windscar-poi", "stand": [-520.0, 2720.0], "target": [-300.0, 460.0, 3100.0]},
	{"id": "cliffhold-waypoint", "stand": [-400.0, 3890.0], "target": [-340.0, 830.0, 3970.0]},
	{"id": "summit-approach", "stand": [100.0, 5290.0], "target": [100.0, 1215.0, 5350.0]},
]

var _out_dir := DEFAULT_OUT
var _budget_s := DEFAULT_BUDGET_S
var _start_ms := 0
var _world: Node3D = null
var _player: CharacterBody3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _director: Node = null
var _manager: Node = null
var _game: Node = null
var _companion: Node3D = null
var _last_stand := Vector2.ZERO
var _last_look := Vector2.ZERO
var _last_look_y := 0.0
var _written := 0
var _skipped: Array[String] = []
var _notes: Array[String] = []


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--budget-seconds="):
			_budget_s = maxf(60.0, float(a.substr("--budget-seconds=".length())))
		elif a.begins_with("--out="):
			_out_dir = a.substr("--out=".length())
			if not _out_dir.begins_with("res://"):
				_out_dir = "res://" + _out_dir
			_out_dir = _out_dir.trim_suffix("/")


func _elapsed_s() -> float:
	return float(Time.get_ticks_msec() - _start_ms) / 1000.0


func _budget_left() -> bool:
	return _elapsed_s() < _budget_s


func _skip(step: String) -> void:
	_skipped.append(step)
	print("[quick-tour][cloudreach] SKIP %s -- budget spent (%.0fs/%.0fs elapsed)" % [
		step, _elapsed_s(), _budget_s])


func _run() -> void:
	_parse_args()
	_start_ms = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run or a real GPU")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	_game = root.get_node_or_null(^"Game")
	if _game == null:
		push_error("Game autoload is missing")
		quit(1)
		return
	# Direct realm entry -- tools/capture_cloudreach_act_one.gd's own setup.
	_game.call("reset_for_new_game")
	_game.set("current_realm", "cloudreach")
	var progression: RefCounted = _game.get("progression")
	if progression != null:
		progression.call("set_flag", "realm_key_cloudreach")
		progression.call("set_flag", "realm_gate_cloudreach_unlocked")
	var inventory: RefCounted = _game.get("inventory")
	if inventory != null:
		for item: Dictionary in [
			{"id": "axe", "count": 1}, {"id": "pickaxe", "count": 1},
			{"id": "potion_small", "count": 3}, {"id": "revive", "count": 2}]:
			inventory.call("add", item["id"], item["count"])
	var party: RefCounted = _game.get("party")
	if party != null and (party.call("members") as Array).is_empty():
		var starter: RefCounted = _game.call("make_creature", "terrapup")
		if starter != null:
			party.call("add", starter)
	if _game.has_method("autofill_hotbar"):
		_game.call("autofill_hotbar")

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for i in BOOT_FRAMES:
		await physics_frame
	print("[quick-tour][cloudreach] world up after %.1fs boot" % _elapsed_s())

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	_manager = _world.get_node_or_null(^"CombatManager")
	if _player == null:
		push_error("no Player node; the tour has no ruler to carry")
		quit(1)
		return

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)

	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	_pin_clock("day")
	_freeze_weather()

	await _step_locations()
	if _budget_left():
		await _step_menu()
	else:
		_skip("menu")
	if _budget_left():
		await _step_combat()
	else:
		_skip("combat")
	if _budget_left():
		await _step_creature()
	else:
		_skip("creature")
	if _budget_left():
		await _step_character()
	else:
		_skip("character")
	if _budget_left():
		await _step_play_functionality()
	else:
		_skip("play-functionality")

	_finish()


## --- ground + camera ---------------------------------------------------------

func _ground(xz: Vector2) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		var h := float(_world.call("ground_height_at", xz.x, xz.y))
		if not is_nan(h):
			return h
	return 0.0


func _place_player(stand_xz: Vector2, look_xz: Vector2) -> void:
	_player.global_position = Vector3(stand_xz.x, _ground(stand_xz) + 0.2, stand_xz.y)
	_player.velocity = Vector3.ZERO
	var model: Node3D = _player.get_node_or_null(^"Model") as Node3D
	var ahead := look_xz - stand_xz
	if model != null and ahead.length() > 0.01:
		model.rotation.y = atan2(ahead.x, ahead.y)


## Unlike the Meadows stands, Cloudreach's `target` carries its own authored
## elevation (a distant landmark, not the ground under it) -- `look_y` is
## used as-is, never re-derived from `_ground()`.
func _pose_standing(stand_xz: Vector2, look_xz: Vector2, look_y: float) -> void:
	var ahead := look_xz - stand_xz
	if ahead.length() < 0.01:
		ahead = Vector2(0.0, 1.0)
	ahead = ahead.normalized()
	var eye_xz := stand_xz - ahead * BACK_M
	var eye := Vector3(eye_xz.x, _ground(eye_xz) + UP_M, eye_xz.y)
	eye.y = maxf(eye.y, _ground(stand_xz) + 0.5)
	var target := Vector3(look_xz.x, look_y, look_xz.y)
	_camera.global_position = eye
	_camera.look_at(target, Vector3.UP)
	_camera.make_current()


func _pin_clock(time: String) -> void:
	if _look == null:
		return
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	if _look.has_method("apply_time"):
		_look.call("apply_time", time)


func _freeze_weather() -> void:
	if _weather == null:
		return
	if _weather.has_method("set_weather"):
		_weather.call("set_weather", "clear")
	_weather.set_process(false)
	_weather.set_physics_process(false)


func _hide_canvas_layers() -> Dictionary:
	var saved: Dictionary = {}
	for child in _world.get_children():
		if child is CanvasLayer:
			saved[child] = (child as CanvasLayer).visible
			(child as CanvasLayer).visible = false
	return saved


func _restore_canvas_layers(saved: Dictionary) -> void:
	for child: Variant in saved.keys():
		if is_instance_valid(child):
			(child as CanvasLayer).visible = bool(saved[child])


func _shoot(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_notes.append("%s: viewport returned no image" % name)
		return false
	var path := "%s/%s.png" % [_out_dir, name]
	var err := image.save_png(path)
	if err != OK:
		_notes.append("%s: save_png failed (%d)" % [name, err])
		return false
	_written += 1
	print("  %-28s -> %s" % [name, path])
	return true


## --- steps --------------------------------------------------------------------

func _step_locations() -> void:
	var index := 0
	for entry: Dictionary in STANDS:
		index += 1
		if not _budget_left():
			_skip("locations (remaining: %s)" % str(entry["id"]))
			continue
		var stand_arr: Array = entry["stand"]
		var target_arr: Array = entry["target"]
		var stand_xz := Vector2(stand_arr[0], stand_arr[1])
		var look_xz := Vector2(target_arr[0], target_arr[2])
		var look_y: float = target_arr[1]
		_last_stand = stand_xz
		_last_look = look_xz
		_last_look_y = look_y
		_place_player(stand_xz, look_xz)
		_pose_standing(stand_xz, look_xz, look_y)
		for i in SETTLE_FRAMES:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame

		if index == 1:
			await _shoot("%02d_%s_day_hud.png" % [index, str(entry["id"])])
		var layers := _hide_canvas_layers()
		for i in 2:
			await process_frame
		await _shoot("%02d_%s_day.png" % [index, str(entry["id"])])
		_restore_canvas_layers(layers)

		if bool(entry.get("night", false)):
			_pin_clock("night")
			for i in 20:
				await physics_frame
			var night_layers := _hide_canvas_layers()
			for i in 2:
				await process_frame
			await _shoot("%02d_%s_night.png" % [index, str(entry["id"])])
			_restore_canvas_layers(night_layers)
			_pin_clock("day")
			for i in 10:
				await physics_frame


func _step_menu() -> void:
	if _game == null or not _game.has_method("menu"):
		_notes.append("menu: no Game.menu() autoload; skipped")
		return
	var menu: Node = _game.call("menu")
	if menu == null:
		_notes.append("menu: Game.menu() returned null; skipped")
		return
	menu.call("open", "backpack")
	for i in 8:
		await process_frame
	await _shoot("05_menu_backpack.png")
	menu.call("close")
	menu.call("open", "build")
	for i in 8:
		await process_frame
	await _shoot("06_menu_build.png")
	menu.call("close")


func _find_nearest_wild(from: Vector3) -> Node3D:
	if _director == null or not _director.has_method("wild_creatures"):
		return null
	var best: Node3D = null
	var best_d := INF
	for entry: Variant in _director.call("wild_creatures"):
		var body := entry as Node3D
		if body == null or not is_instance_valid(body):
			continue
		var d := body.global_position.distance_to(from)
		if d < best_d:
			best = body
			best_d = d
	return best


func _press(action: String) -> void:
	Input.action_press(action)
	for i in 2:
		await physics_frame
	Input.action_release(action)
	await physics_frame


func _engage(wild: Node3D) -> bool:
	var attempt := 0
	while attempt < 3 and not bool(_manager.call("is_fighting")):
		attempt += 1
		await _press("interact")
		var waited := 0
		while not bool(_manager.call("is_fighting")) and waited < 30:
			waited += 1
			await physics_frame
	if not bool(_manager.call("is_fighting")):
		return false
	for i in 40:
		await physics_frame
	return bool(_manager.call("is_fighting"))


func _flee_if_fighting() -> void:
	if _manager == null or not bool(_manager.call("is_fighting")):
		return
	if _manager.has_method("is_aiming") and bool(_manager.call("is_aiming")):
		await _press("menu_cancel")
	var presses := 0
	while bool(_manager.call("is_fighting")) and presses < 2:
		presses += 1
		await _press("combat_run")
		var waited := 0
		while bool(_manager.call("is_fighting")) and waited < 90:
			waited += 1
			await physics_frame
	if bool(_manager.call("is_fighting")):
		_notes.append("combat: the fight did not end after fleeing")


func _step_combat() -> void:
	if _director == null or _manager == null:
		_notes.append("combat: no EncounterDirector/CombatManager in the tree; skipped " +
			"(Cloudreach's runtime builds these dynamically -- see cloudreach_world_runtime.gd)")
		return
	var wild := _find_nearest_wild(_player.global_position)
	if wild == null:
		_notes.append("combat: no wild creature found near the last stand; skipped")
		return
	var stand := wild.global_position + Vector3(0.0, 0.0, 4.0)
	stand.y = _ground(Vector2(stand.x, stand.z)) + 1.0
	_player.global_position = stand
	_player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	if not await _engage(wild):
		_notes.append("combat: could not engage the wild within 3 attempts; skipped")
		return
	var ally: Node3D = _director.call("ally_body") as Node3D
	var focus: Vector3 = ((ally.global_position if ally != null else _player.global_position) + wild.global_position) / 2.0
	var axis := wild.global_position - focus
	axis.y = 0.0
	if axis.length() < 0.01:
		axis = Vector3(0.0, 0.0, 1.0)
	var side := axis.normalized().cross(Vector3.UP)
	_camera.global_position = focus + side * 6.0 + Vector3.UP * 2.4
	_camera.look_at(focus + Vector3.UP * 0.8, Vector3.UP)
	_camera.make_current()
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("07_combat.png")
	await _flee_if_fighting()


func _step_creature() -> void:
	if _director == null or not _director.has_method("summon_active_creature"):
		_notes.append("creature: no EncounterDirector.summon_active_creature(); skipped")
		return
	_companion = _director.call("ally_body") as Node3D
	if _companion == null:
		var summoned: bool = await _director.call("summon_active_creature")
		if not summoned:
			_notes.append("creature: summon_active_creature() returned false; skipped")
			return
		_companion = _director.call("ally_body") as Node3D
	if _companion == null:
		_notes.append("creature: ally_body() is null after summon; skipped")
		return
	var ahead := (_last_look - _last_stand).normalized() if _last_look != _last_stand else Vector2(0.0, 1.0)
	var side := Vector2(-ahead.y, ahead.x)
	var spot := _last_stand + side * 1.8
	if not bool(_companion.call("place_on_ground", Vector3(spot.x, 0.0, spot.y))):
		_companion.global_position = Vector3(spot.x, _ground(spot) + 0.1, spot.y)
	_pose_standing(_last_stand, _last_look, _last_look_y)
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("08_creature.png")


func _step_character() -> void:
	var ahead := (_last_look - _last_stand).normalized() if _last_look != _last_stand else Vector2(0.0, 1.0)
	var eye_xz := _last_stand - ahead * 1.8
	_camera.global_position = Vector3(eye_xz.x, _ground(eye_xz) + 1.5, eye_xz.y)
	_camera.look_at(Vector3(_last_stand.x, _ground(_last_stand) + 1.5, _last_stand.y), Vector3.UP)
	_camera.make_current()
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("09_character.png")


## Same reduced gather loop as tools/_capture_quick_tour_meadows.gd, itself
## tools/_play_t5_gather_craft.gd's `_gather_loop()`.
func _step_play_functionality() -> void:
	var nav_script: GDScript = load("res://tests/helpers/stick_navigator.gd")
	var rig: Node3D = _world.get_node_or_null(^"CameraRig") as Node3D
	if nav_script == null or rig == null:
		_notes.append("play-functionality: stick_navigator or CameraRig missing; skipped")
		return
	var nav = nav_script.new(self, _player, rig, Callable(self, "_drive_stick"))

	var nodes: Array[Node] = []
	for node in _world.find_children("*", "", true, false):
		if node.has_method("resource_item") and node.has_method("resource_amount"):
			nodes.append(node)
	if nodes.is_empty():
		_notes.append("play-functionality: no harvest nodes in the world; skipped")
		return
	var here := _player.global_position
	var best: Node3D = null
	var best_d := INF
	for node in nodes:
		var n3 := node as Node3D
		if n3 == null:
			continue
		var d := Vector2(n3.global_position.x, n3.global_position.z).distance_to(Vector2(here.x, here.z))
		if d < best_d:
			best_d = d
			best = n3
	if best == null:
		return
	var item := str(best.call("resource_item"))
	var inventory: RefCounted = _game.get("inventory") if _game != null else null
	if inventory == null:
		_notes.append("play-functionality: no Game.inventory; skipped")
		return
	var before := int(inventory.call("count", item))
	var target := best.global_position
	var stand := target + (here - target).normalized() * 1.6
	stand.y = _player.global_position.y
	var walked: bool = await nav.walk_to(stand, 1800, 1.2)
	if not walked:
		_notes.append("play-functionality VERDICT: FAIL -- could not walk to the nearest " +
			"harvest node (%s) in 30s of stick" % best.name)
		return
	if not InputMap.has_action("interact"):
		_notes.append("play-functionality: no 'interact' action bound; skipped")
		return
	var button_index := -1
	for event in InputMap.action_get_events("interact"):
		var joy := event as InputEventJoypadButton
		if joy != null:
			button_index = joy.button_index
			break
	for attempt in 6:
		if button_index >= 0:
			var down := InputEventJoypadButton.new()
			down.button_index = button_index
			down.pressed = true
			Input.parse_input_event(down)
			await process_frame
			await process_frame
			var up := InputEventJoypadButton.new()
			up.button_index = button_index
			up.pressed = false
			Input.parse_input_event(up)
			for i in 8:
				await process_frame
		if int(inventory.call("count", item)) > before:
			break
	var after := int(inventory.call("count", item))
	if after > before:
		_notes.append("play-functionality VERDICT: PASS -- walked %.0fm and gathered %d x %s" % [
			best_d, after - before, item])
	else:
		_notes.append("play-functionality VERDICT: FAIL -- at the node, interact gathered nothing (%s still %d)" % [
			item, after])


func _drive_stick(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))


func _finish() -> void:
	print("")
	print("[quick-tour][cloudreach] %d frames written to %s in %.0fs (budget %.0fs)" % [
		_written, _out_dir, _elapsed_s(), _budget_s])
	if not _skipped.is_empty():
		print("[quick-tour][cloudreach] skipped: %s" % ", ".join(_skipped))
	for line in _notes:
		print("[quick-tour][cloudreach] %s" % line)
	quit(0)
