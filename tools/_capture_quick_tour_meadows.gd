extends SceneTree

## QUICK TOUR -- Meadows pass. A fast, breadth-first spot-check for the owner's
## ROG Ally, hard-capped at --budget-seconds (default 1200 = 20 minutes) of
## wall-clock time INSIDE this process. This is explicitly NOT the Gate F
## evidence pipeline (tools/owner/KICKOFF.cmd) -- it exists to answer "does the
## chapter still look and play right", not to ship chapter-acceptance evidence.
## Launched by tools/owner/quick_tour.ps1; never run with --headless (a real
## rendering driver is required for every screenshot here).
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_quick_tour_meadows.gd -- \
##     --budget-seconds=1200 --out=res://shots_quick_tour/meadows
##
## Every step below is a THIN adaptation of an existing, already-proven
## capture tool rather than a new mechanism -- cited at each step:
##
##   locations  -- tools/_capture_locations.gd (SITES data, RIG "standing"
##                 defaults, marker() resolution for the Stronghold). Reduced
##                 to ONE eye per site (no approach/detail) and four sites
##                 instead of eleven, because breadth across the whole tour
##                 matters more here than any one site's full coverage.
##   day/night  -- tools/_capture_route_strip.gd's WorldLook pin
##                 (set_clock_frozen + apply_time).
##   menu       -- tools/capture_menu_panels.gd (game.menu()/open()/close()).
##   combat     -- tools/_capture_combat_moments.gd (_find_nearest_wild,
##                 _teleport_player_near, _engage, _flee_if_fighting, _press).
##   creature   -- tools/_capture_route_strip.gd's companion summon
##                 (EncounterDirector.summon_active_creature()).
##   play test  -- tools/_play_t5_gather_craft.gd's gather loop
##                 (tests/helpers/stick_navigator.gd's walk_to(), the pad
##                 interact press).
##
## Camera framing here is deliberately simpler than _capture_locations.gd's:
## no `_clear_of_bodies` depenetration pass, no collider-hit `look_up`
## corrections. The four stands below are the "standing" eyes that file
## already ships with the DEFAULT rig (no per-shot override), chosen
## specifically because they needed no such correction there -- reusing an
## already-corrected number rather than re-deriving one.
##
## Budget discipline: every step below checks `_budget_left()` before it
## starts and is skipped (not attempted, not truncated mid-shot) once the
## budget is spent. Steps are ordered breadth-first: all four locations come
## before HUD/menu/combat/creature/character, so a slow box still gets the
## whole location set before losing anything.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const DEFAULT_OUT := "res://shots_quick_tour/meadows"
const DEFAULT_BUDGET_S := 1200.0

const BOOT_FRAMES := 240
const SETTLE_FRAMES := 40
const POSE_FRAMES := 6
const FOV := 70.0
## RIG "standing" defaults from tools/_capture_locations.gd, unmodified.
const BACK_M := 3.2
const UP_M := 1.70
const LOOK_UP_M := 1.6

## Four curated stands. `at`/`look` are world XZ metres, taken verbatim from
## the "standing" eye of the same-named site in tools/_capture_locations.gd's
## SITES table (default rig, no override -- see header). `marker`/`look_marker`
## resolve through the site node's own marker() the same way that file does,
## because stronghold.json's site yaw (90) makes a hand-picked coordinate a
## coin flip to photograph the right wall.
const STANDS := [
	{"id": "village-hub", "at": [10.0, -15.5], "look": [3.0, 1.0], "night": true,
	 "_why": "tools/_capture_locations.gd SITES '01-village' shot 'standing'."},
	{"id": "quarry-poi", "at": [400.0, 1803.0], "look": [418.0, 1764.0],
	 "_why": "tools/_capture_locations.gd SITES '03-quarry' shot 'standing'."},
	{"id": "relay-checkpoint", "at": [238.0, 3670.0], "look": [252.0, 3686.0],
	 "_why": "tools/_capture_locations.gd SITES '05-relay-camp' shot 'standing'."},
	{"id": "stronghold-gate", "marker": ["Stronghold", "entrance"],
	 "look_marker": ["Stronghold", "outer_works"],
	 "_why": "tools/_capture_locations.gd SITES '10-stronghold' shot 'gate' -- the boss/hero site."},
]

var _out_dir := DEFAULT_OUT
var _budget_s := DEFAULT_BUDGET_S
var _start_ms := 0
var _field: RefCounted = null
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
	print("[quick-tour][meadows] SKIP %s -- budget spent (%.0fs/%0.fs elapsed)" % [
		step, _elapsed_s(), _budget_s])


func _run() -> void:
	_parse_args()
	_start_ms = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run or a real GPU")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

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
	print("[quick-tour][meadows] world up after %.1fs boot" % _elapsed_s())

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	_manager = _world.get_node_or_null(^"CombatManager")
	_game = root.get_node_or_null(^"Game")
	_field = HEIGHTFIELD.new()
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

	# A populated hotbar/party so the HUD and menu steps show real content
	# rather than five empty cards -- tools/capture_cloudreach_act_one.gd's
	# own reasoning for doing the same thing on arrival.
	if _game != null:
		var party: RefCounted = _game.get("party")
		if party != null and (party.call("members") as Array).is_empty():
			var starter: RefCounted = _game.call("make_creature", "terrapup")
			if starter != null:
				party.call("add", starter)
		var inventory: RefCounted = _game.get("inventory")
		if inventory != null:
			for item: Dictionary in [
				{"id": "orb_basic", "count": 3}, {"id": "potion_small", "count": 2},
				{"id": "wood", "count": 12}, {"id": "stone", "count": 5}]:
				inventory.call("add", item["id"], item["count"])
		if _game.has_method("autofill_hotbar"):
			_game.call("autofill_hotbar")

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
	return float(_field.height_at(xz.x, xz.y))


func _marker(node_name: String, key: String) -> Vector3:
	var node: Node = _world.get_node_or_null(NodePath(node_name))
	if node == null or not node.has_method("marker"):
		print("[quick-tour][meadows] WARN %s has no marker() for '%s'" % [node_name, key])
		return Vector3.ZERO
	return node.call("marker", key) as Vector3


## Resolves a STANDS entry to a player stand and a look-at point, both world
## XZ. Marker-based entries carry their own Y; plain at/look entries get
## theirs from the heightfield, same as tools/_capture_locations.gd.
func _resolve_stand(entry: Dictionary) -> Dictionary:
	if entry.has("marker"):
		var spec: Array = entry["marker"]
		var stand3 := _marker(str(spec[0]), str(spec[1]))
		var lspec: Array = entry["look_marker"]
		var look3 := _marker(str(lspec[0]), str(lspec[1]))
		return {"stand": Vector2(stand3.x, stand3.z), "stand_y": stand3.y,
			"look": Vector2(look3.x, look3.z), "look_y": look3.y}
	var at: Array = entry["at"]
	var look: Array = entry["look"]
	return {"stand": Vector2(at[0], at[1]), "stand_y": NAN,
		"look": Vector2(look[0], look[1]), "look_y": NAN}


func _place_player(stand_xz: Vector2, stand_y: float, look_xz: Vector2) -> void:
	var y: float = stand_y if not is_nan(stand_y) else (_ground(stand_xz) + 0.2)
	_player.global_position = Vector3(stand_xz.x, y, stand_xz.y)
	_player.velocity = Vector3.ZERO
	var model: Node3D = _player.get_node_or_null(^"Model") as Node3D
	var ahead := look_xz - stand_xz
	if model != null and ahead.length() > 0.01:
		model.rotation.y = atan2(ahead.x, ahead.y)


func _pose_standing(stand_xz: Vector2, stand_y: float, look_xz: Vector2, look_y: float) -> void:
	var ground_stand: float = stand_y if not is_nan(stand_y) else _ground(stand_xz)
	var ground_look: float = look_y if not is_nan(look_y) else _ground(look_xz)
	var ahead := look_xz - stand_xz
	if ahead.length() < 0.01:
		ahead = Vector2(0.0, 1.0)
	ahead = ahead.normalized()
	var eye_xz := stand_xz - ahead * BACK_M
	var eye := Vector3(eye_xz.x, _ground(eye_xz) + UP_M, eye_xz.y)
	# Never let the eye sink under the stand it is looking from (a crest can
	# read lower a few metres back than the stand itself).
	eye.y = maxf(eye.y, ground_stand + 0.5)
	var target := Vector3(look_xz.x, ground_look + LOOK_UP_M, look_xz.y)
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
		var resolved := _resolve_stand(entry)
		var stand_xz: Vector2 = resolved["stand"]
		var look_xz: Vector2 = resolved["look"]
		_last_stand = stand_xz
		_last_look = look_xz
		_place_player(stand_xz, float(resolved["stand_y"]), look_xz)
		_pose_standing(stand_xz, float(resolved["stand_y"]), look_xz, float(resolved["look_y"]))
		for i in SETTLE_FRAMES:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame

		# The HUD requirement is folded into the FIRST stand's shot rather than
		# a separate world boot (tools/_capture_buff_hud.gd's "just a HUD
		# screenshot" reduced to "one frame that keeps the HUD on" -- this tour
		# already has a populated hotbar/party from _run(), which is the same
		# thing that tool exists to show).
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
		_notes.append("combat: no EncounterDirector/CombatManager in the tree; skipped")
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
	_pose_standing(_last_stand, NAN, _last_look, NAN)
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("08_creature.png")


func _step_character() -> void:
	var eye_xz := _last_stand - (_last_look - _last_stand).normalized() * 1.8 if _last_look != _last_stand else _last_stand - Vector2(0.0, 1.8)
	_camera.global_position = Vector3(eye_xz.x, _ground(eye_xz) + 1.5, eye_xz.y)
	_camera.look_at(Vector3(_last_stand.x, _ground(_last_stand) + 1.5, _last_stand.y), Vector3.UP)
	_camera.make_current()
	for i in POSE_FRAMES:
		await process_frame
	await _shoot("09_character.png")


## A little real functionality, not a full playthrough: walk to the nearest
## harvest node and gather once, exactly tools/_play_t5_gather_craft.gd's
## `_gather_loop()`, reduced to the walk + one gather and a printed verdict
## (no screenshot -- this step is about proving the loop still works).
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
	print("[quick-tour][meadows] %d frames written to %s in %.0fs (budget %.0fs)" % [
		_written, _out_dir, _elapsed_s(), _budget_s])
	if not _skipped.is_empty():
		print("[quick-tour][meadows] skipped: %s" % ", ".join(_skipped))
	for line in _notes:
		print("[quick-tour][meadows] %s" % line)
	quit(0)
