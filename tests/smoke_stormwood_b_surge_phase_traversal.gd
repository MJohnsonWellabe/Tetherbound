extends SceneTree

## F09#1: "lawful Surge phases, grounded paths, rod safe radii" as a traversal
## witness in the live production Stormwood, with the production player,
## camera, host strike runtime (stormwood_lightning.gd) and ordinary stick input.
##
## WORLD §5.2: Calm 240 s -> Building 90 s -> Break 120 s -> Fading 60 s; strikes
## land only in Break (outside the glass sink), on exposed ground, never in a
## camp/settlement safe zone or inside a rod's 12 m radius; 1.2 s telegraph.
##
## 1. Lawful cycle: the surge node's own phase_info_at() walks Calm, Building,
##    Break, Fading in order with the authored durations at the route's region,
##    and the Break/Calm lengths follow the gentle and disabled-rod multipliers.
## 2. Under each phase the player walks the Conductor Run road out of the Still
##    Grove safe zone by stick input while the host strike runtime runs at its
##    own cadence. Calm, Building and Fading issue no warning; Break issues
##    warnings, every one at least a telegraph ahead of its impact, on exposed
##    ground, never inside a safe zone or rod radius.
## 3. Grounded safe ground in Break: standing in the Still Grove safe zone and
##    beside the Rodline Refuge rod draws no warning over forced strike attempts.
## 4. Rod safe radius in Break on open road: a player-built lightning rod
##    record beside an exposed road point shelters it (0 warnings); the same
##    point without the rod draws warnings (negative control). The rule edge is
##    checked at 11.9 m (sheltered) and 12.1 m (exposed).
##
## Disclosed fixtures: debug placement at each leg start; the storm clock is set
## to each phase's start and held inside that phase while its leg runs (the
## clock otherwise advances normally); strike attempts in 3 and 4 are forced by
## zeroing the runtime's interval timer (the eligibility path is unchanged); the
## rod is a `placed_buildings` record, as the build ledger would write it;
## trainer health is refilled after each impact so the holds never die.

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const STORMWOOD_SCENE := preload("res://scenes/world/stormwood.tscn")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")

const TEST_SAVE_DIR := "user://stormwood_b_surge_phase_traversal"
const EVIDENCE := "user://stormwood_b_surge_phase_traversal.txt"
const ROUTE_START := Vector2(-160.0, 2700.0)
const ROUTE_END := Vector2(-560.0, 2480.0)
const LEG_FRAMES := 5400
const HOLD_FRAMES := 1200

var _failures: Array[String] = []
var _passes := 0
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _camera: Node3D
var _surge: Node
var _lightning: Node
var _navigator: RefCounted
var _field: RefCounted
var _warnings: Array[Dictionary] = []
var _impacts: Array[Dictionary] = []
var _hits := 0
var _log: PackedStringArray = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(1500.0).timeout.connect(func() -> void:
		_expect(false, "1500 second watchdog expired")
		_finish())
	_remove_tree(TEST_SAVE_DIR)
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_game = GAME.new()
		_game.name = "Game"
		root.add_child(_game)
	await process_frame
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	_game.get("local").set("character_id", "stormwood-b-surge-phase")
	_game.get("world").set("world_id", "stormwood-b-surge-phase-world")
	_game.set("current_realm", "stormwood")
	_game.call("bind_realm_map")
	_game.call("announce_realm", "meadows", "stormwood")
	_world = STORMWOOD_SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + 240000
	while not bool(_world.call("shell_build_complete")) and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(bool(_world.call("shell_build_complete")), "production Stormwood built")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_camera = _world.get_node_or_null(^"CameraRig") as Node3D
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_lightning = _find_lightning()
	_expect(_player != null and _camera != null and _surge != null and _lightning != null,
		"production player, camera, surge and strike runtime mounted")
	if not _failures.is_empty():
		_finish()
		return
	_game.get_node("Session").stormwood_strike_received.connect(_on_strike)
	_navigator = NAVIGATOR.new(self, _player, _camera, _drive)
	_field = FIELD.new()
	Engine.time_scale = 4.0
	Engine.physics_ticks_per_second = 240
	Engine.max_physics_steps_per_frame = 16

	_check_lawful_cycle()
	for phase: String in ["calm", "building", "break", "fading"]:
		await _phase_leg(phase)
	await _grounded_safe_ground()
	await _rod_safe_radius()
	_finish()


## 1. Order and authored lengths come from the live surge node, not the rules
## helper alone: it reads the route region, rod flags and aftermath from Game.
func _check_lawful_cycle() -> void:
	var at := _ground(ROUTE_END)
	var region := str(_surge.call("region_at", at))
	_expect(region == "conductor_run", "route end lies in the Conductor Run (got %s)" % region)
	var expected := [["calm", 240.0], ["building", 90.0], ["break", 120.0], ["fading", 60.0]]
	var t := 0.0
	for row: Array in expected:
		_set_elapsed(t + 0.5)
		var info: Dictionary = _surge.call("phase_info_at", at)
		_expect(str(info.get("phase")) == row[0] and is_equal_approx(float(info.get("duration")), row[1]),
			"cycle at %.1f s is %s for %.0f s (got %s %.1f)" % [t + 0.5, row[0], row[1], info.get("phase"), float(info.get("duration", 0))])
		t += float(row[1])
	_set_elapsed(t + 0.5)
	_expect(str(_surge.call("phase_at_position", at)) == "calm", "cycle wraps to Calm after 510 s")
	var rules: RefCounted = _lightning.get("rules")
	_expect(is_equal_approx(float(rules.call("phase_at", 1.0, "cinder_verge").duration), 324.0),
		"gentle Cinder Verge Calm is 240 x 1.35 = 324 s")
	# Deepwood is not gentle: Calm 240 x 1.5 = 360 s, Building 90 s, then Break.
	var rod_off: Dictionary = rules.call("phase_at", 240.0 * 1.5 + 90.0 + 1.0, "deepwood", true)
	_expect(is_equal_approx(float(rules.call("phase_at", 1.0, "deepwood", true).duration), 360.0)
		and str(rod_off.phase) == "break" and is_equal_approx(float(rod_off.duration), 72.0),
		"disabled Deepwood rod: Calm 360 s, Break 72 s")
	var after: Dictionary = rules.call("phase_at", 2400.0 + 45.0 + 1.0, "deepwood", false, true)
	_expect(str(after.phase) == "break" and is_equal_approx(float(after.duration), 45.0),
		"aftermath Break is 45 s after a 2400 s Calm")


## 2. One stick-driven leg along the Conductor Run road per phase.
func _phase_leg(phase: String) -> void:
	var start_t := _phase_start(phase)
	await _place(ROUTE_START)
	_set_elapsed(start_t + 0.5)
	_lightning.set("_next", 1.0)
	_warnings.clear()
	_impacts.clear()
	var goal := Vector3(ROUTE_END.x, _field.height_at(ROUTE_END.x, ROUTE_END.y), ROUTE_END.y)
	var arrived := false
	var phases_seen := {}
	var travelled := 0.0
	var last := _player.global_position
	var exposed_samples := 0
	for frame in LEG_FRAMES:
		var info: Dictionary = _surge.call("phase_info_at", _player.global_position)
		if float(info.get("remaining", 99.0)) < 4.0:
			_set_elapsed(start_t + 0.5)
		phases_seen[str(_surge.call("phase_at_position", _player.global_position))] = true
		if frame % 60 == 0 and bool(_lightning.call("exposed", _player.global_position, _player)):
			exposed_samples += 1
		travelled += _player.global_position.distance_to(last)
		last = _player.global_position
		if Vector2(_player.global_position.x, _player.global_position.z).distance_to(ROUTE_END) < 3.0:
			arrived = true
			break
		if bool(_navigator.call("can_walk")):
			await _navigator.call("step", goal)
		else:
			_drive(0, 0)
			await physics_frame
	_drive(0, 0)
	for _i in 120:
		await physics_frame
	var line := "%s leg: arrived=%s travelled=%.0f m, phases=%s, exposed samples=%d, warnings=%d, impacts=%d" % [
		phase, arrived, travelled, phases_seen.keys(), exposed_samples, _warnings.size(), _impacts.size()]
	_log.append(line)
	print("  ", line)
	_expect(arrived and travelled > 300.0, "%s: the player walks the Conductor Run road by stick (%.0f m)" % [phase, travelled])
	_expect(phases_seen.keys() == [phase], "%s: the live phase stayed %s for the whole leg (saw %s)" % [phase, phase, phases_seen.keys()])
	if phase == "break":
		_expect(exposed_samples > 0, "break: the road has exposed ground (non-vacuous)")
		_expect(_warnings.size() >= 2, "break: the host issued strike warnings on the road (%d)" % _warnings.size())
		for warning: Dictionary in _warnings:
			var at: Vector3 = warning.at
			_expect(not _in_safe_zone(at) and _nearest_rod(at) > 12.0,
				"break: warning at (%.0f, %.0f) is outside every safe zone and rod radius" % [at.x, at.z])
			_expect(is_equal_approx(float(warning.remaining), 1.2), "break: warning carries the 1.2 s telegraph")
		for impact: Dictionary in _impacts:
			var lead := float(impact.msec) - _warning_msec(int(impact.id))
			_expect(lead >= 1150.0 / 4.0, "break: impact %d landed %.0f ms (real, x4) after its warning" % [int(impact.id), lead])
	else:
		_expect(_warnings.is_empty(), "%s: no strike warning anywhere on the road (%d)" % [phase, _warnings.size()])


## 3. Break, standing still in grounded safe ground, strike attempts forced.
func _grounded_safe_ground() -> void:
	for spot: Array in [["Still Grove safe zone", Vector2(-160.0, 2700.0)], ["Rodline Refuge rod", Vector2(-664.0, 2314.0)]]:
		await _place(spot[1])
		var attempts := await _hold_in_break(spot[1])
		_log.append("%s in Break: %d forced attempts, %d warnings" % [spot[0], attempts, _warnings.size()])
		_expect(attempts >= 20 and _warnings.is_empty(),
			"break: %s draws no warning over %d strike attempts (%d)" % [spot[0], attempts, _warnings.size()])


## 4. Rod safe radius on open road, with its negative control.
func _rod_safe_radius() -> void:
	var spot := _exposed_road_point()
	_expect(spot != Vector2.INF, "an exposed Conductor Run road point exists for the rod check")
	if spot == Vector2.INF:
		return
	var rod_at := Vector2(spot.x + 6.0, spot.y)
	await _place(spot)
	var control := await _hold_in_break(spot)
	_log.append("control hits on the standing player: %d" % _hits)
	_expect(_warnings.size() >= 3, "control: the exposed point (%.0f, %.0f) draws warnings without a rod (%d of %d)" % [spot.x, spot.y, _warnings.size(), control])
	var buildings: Array = _game.get("placed_buildings")
	var record := {"id": "lightning_rod", "realm": "stormwood", "uid": "stormwood-b-rod",
		"position": [rod_at.x, _field.height_at(rod_at.x, rod_at.y), rod_at.y]}
	buildings.append(record)
	_game.set("placed_buildings", buildings)
	await _place(spot)
	var sheltered := await _hold_in_break(spot)
	_log.append("rod check at (%.0f, %.0f): %d warnings without rod, %d with a rod 6 m away over %d attempts" % [spot.x, spot.y, control, _warnings.size(), sheltered])
	_expect(sheltered >= 20 and _warnings.is_empty(), "rod 6 m away: no warning over %d attempts (%d)" % [sheltered, _warnings.size()])
	var rules: RefCounted = _lightning.get("rules")
	var at := _ground(spot)
	var rod := Vector3(spot.x, at.y, spot.y)
	_expect(bool(rules.call("sheltered", at, "conductor_run", false, [rod + Vector3(11.9, 0, 0)])), "rule edge: 11.9 m from a rod is sheltered")
	_expect(not bool(rules.call("sheltered", at, "conductor_run", false, [rod + Vector3(12.1, 0, 0)])), "rule edge: 12.1 m from a rod is exposed")
	buildings.erase(record)
	_game.set("placed_buildings", buildings)


func _hold_in_break(at: Vector2) -> int:
	_warnings.clear()
	var attempts := 0
	for frame in HOLD_FRAMES:
		_set_elapsed(_phase_start("break") + 10.0)
		if frame % 40 == 0:
			_lightning.set("_next", 0.0)
			attempts += 1
		await physics_frame
	_drive(0, 0)
	return attempts


func _exposed_road_point() -> Vector2:
	_set_elapsed(_phase_start("break") + 10.0)
	for i in range(8, 40):
		var p := ROUTE_START.lerp(ROUTE_END, float(i) / 48.0)
		var at := _ground(p)
		if not _in_safe_zone(at) and _nearest_rod(at) > 30.0 and bool(_lightning.call("exposed", at, null)):
			return p
	return Vector2.INF


func _on_strike(event: Dictionary) -> void:
	var row := event.duplicate(true)
	row["msec"] = Time.get_ticks_msec()
	if str(event.get("kind")) == "warning":
		_warnings.append(row)
	elif str(event.get("kind")) == "impact":
		_impacts.append(row)
		if not (event.get("hits", {}) as Dictionary).is_empty():
			_hits += 1
		_refill.call_deferred()


## A standing player takes real hits during the Break holds; health is topped
## up after each impact so no death flow moves the player (disclosed).
func _refill() -> void:
	var vitals: RefCounted = _player.get("vitals")
	if vitals != null and not vitals.is_dead():
		vitals.health = float(vitals.max_health)


func _warning_msec(id: int) -> float:
	for warning: Dictionary in _warnings:
		if int(warning.id) == id:
			return float(warning.msec)
	return INF


func _phase_start(phase: String) -> float:
	return {"calm": 0.0, "building": 240.0, "break": 330.0, "fading": 450.0}[phase]


func _set_elapsed(value: float) -> void:
	var environment: Dictionary = _game.get("realm_environment")
	var storm: Dictionary = environment.get("stormwood", {}).duplicate(true)
	storm["elapsed"] = value
	environment["stormwood"] = storm
	_game.set("realm_environment", environment)


func _in_safe_zone(at: Vector3) -> bool:
	for zone: Dictionary in _lightning.get("rules").config.safe_zones:
		if Vector2(at.x, at.z).distance_to(Vector2(float(zone.at[0]), float(zone.at[1]))) <= float(zone.radius):
			return true
	return false


func _nearest_rod(at: Vector3) -> float:
	var best := INF
	var camps := _world.get_node_or_null(^"StormwoodCampsRuntime")
	var rods: Array = camps.call("rod_positions", _world) if camps != null else []
	for record: Variant in _game.get("placed_buildings"):
		if record is Dictionary and str(record.get("id", "")) == "lightning_rod":
			rods.append(Vector3(float(record.position[0]), float(record.position[1]), float(record.position[2])))
	for rod: Vector3 in rods:
		best = minf(best, Vector2(at.x, at.z).distance_to(Vector2(rod.x, rod.z)))
	return best


func _find_lightning() -> Node:
	for node: Node in _world.find_children("*", "Node3D", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("stormwood_lightning.gd"):
			return node
	return null


func _ground(p: Vector2) -> Vector3:
	return Vector3(p.x, _field.height_at(p.x, p.y), p.y)


func _place(at: Vector2) -> void:
	_player.global_position = Vector3(at.x, _field.height_at(at.x, at.y) + 1.0, at.y)
	_player.velocity = Vector3.ZERO
	_navigator.call("reset")
	for _i in 30:
		await physics_frame


func _drive(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))
	if is_zero_approx(x):
		Input.action_release(&"move_right")
		Input.action_release(&"move_left")
	if is_zero_approx(y):
		Input.action_release(&"move_back")
		Input.action_release(&"move_forward")


func _expect(condition: bool, message: String) -> void:
	if condition:
		_passes += 1
		print("  PASS: ", message)
	else:
		_failures.append(message)
		print("  FAIL: ", message)


var _done := false


func _finish() -> void:
	if _done:
		return
	_done = true
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	_log.append("RESULT %d passed, %d failed" % [_passes, _failures.size()])
	var file := FileAccess.open(EVIDENCE, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_log) + "\n")
	_remove_tree(TEST_SAVE_DIR)
	print("STORMWOOD B SURGE PHASE TRAVERSAL %s: %d passed, %d failed" % [
		"OK" if _failures.is_empty() else "FAILED", _passes, _failures.size()])
	quit(0 if _failures.is_empty() else 1)


func _remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	for file: String in DirAccess.get_files_at(absolute):
		DirAccess.remove_absolute(absolute.path_join(file))
	for dir: String in DirAccess.get_directories_at(absolute):
		_remove_tree(path.path_join(dir))
	DirAccess.remove_absolute(absolute)
