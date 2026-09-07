extends SceneTree

## Regression for OWNER_PLAYTEST_2026-09-07's process hang while placing a
## second Creature Bed. The production Meadows world and SequenceDirector are
## live; only the fixture setup (free build and the selected catalogue item) is
## staged. Both placements begin as physical joypad events through InputMap and
## settle through BuildPlacer -> ledger -> HomeProgress.
##
##   godot --headless --path . --script tests/smoke_build_two_creature_beds.gd
##   godot --headless --path . --script tests/smoke_build_two_creature_beds.gd -- --soak-seconds=180

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TEST_DIR := "user://test_saves_two_creature_beds/"
const SETTLE_FRAMES := 240
const DEFAULT_RUNS := 10
const DEFAULT_SOAK_SECONDS := 2.0
const DEFAULT_WARMUP_SECONDS := 60.0
const FRAME_GAP_LIMIT_MS := 250.0

var _failures: Array[String] = []
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _placer: Node
var _delta_count := 0
var _max_gap_ms := 0.0
var _max_gap_context := ""
var _warmup_max_gap_ms := 0.0
var _warmup_max_gap_context := ""
var _last_frame_usec := 0
var _soak_started_msec := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("Game autoload is missing")
		_report()
		return
	_game.call("reset_for_new_game")
	_wipe_test_dir()
	_game.set("save_system", SAVE_GAME.new(TEST_DIR))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	await _settle(SETTLE_FRAMES, false)
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_placer = _world.get_node_or_null(^"BuildPlacer")
	var director := _world.find_child("SequenceDirector", true, false)
	var ledger: Node = _game.get("ledger")
	if _player == null or _placer == null or director == null or ledger == null:
		_fail("Meadows did not stand up Player, BuildPlacer, SequenceDirector and ledger")
		_report()
		return
	if director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")
	ledger.connect("delta_applied", _on_delta_applied)
	for run_index in _run_count():
		# One production world boot, ten fresh gameplay states. This resets the
		# same in-place stores New Game resets, then makes BuildPlacer reconcile
		# its scene nodes from the now-empty building registry.
		if run_index > 0:
			_game.call("reset_for_new_game")
			_placer.call("restore_from_game", _game)
			await _settle(3, false)
		_game.set("free_build", true)
		_delta_count = 0
		await _settle(12, false)
		_last_frame_usec = Time.get_ticks_usec()
		await _place_bed(Vector3(70.0, 0.0, 70.0), 1)
		await _place_bed(Vector3(82.0, 0.0, 70.0), 2)

		var flags: RefCounted = _game.get("progression")
		for flag: String in ["creature_bed_built", "creature_bed_built_2"]:
			if flags == null or not bool(flags.call("has", flag)):
				_fail("run %d: second-bed path did not grant '%s'" % [run_index + 1, flag])
		if _delta_count > 4:
			_fail("run %d: two placements emitted %d ledger deltas; expected at most building+new flag per bed" % [run_index + 1, _delta_count])
		else:
			print("two-bed run %d/%d settled with %d total deltas" % [run_index + 1, _run_count(), _delta_count])

	var soak_seconds := _soak_seconds()
	if OS.get_cmdline_user_args().has("--prime-autosave"):
		_game.set("_autosave_elapsed", 179.0)
	_soak_started_msec = Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - _soak_started_msec) / 1000.0 < soak_seconds:
		await _settle(1, true)
	print("two-bed warmup watchdog: max %.1f ms during first %.1f s (%s)" % [
		_warmup_max_gap_ms, minf(soak_seconds, _warmup_seconds()), _warmup_max_gap_context])
	if soak_seconds <= _warmup_seconds():
		print("two-bed post-warmup watchdog: not requested (soak %.1f s)" % soak_seconds)
	elif _max_gap_ms > FRAME_GAP_LIMIT_MS:
		_fail("post-placement soak saw a %.1f ms frame gap (limit %.1f ms; %s)" % [_max_gap_ms, FRAME_GAP_LIMIT_MS, _max_gap_context])
	else:
		print("two-bed post-warmup watchdog: max %.1f ms from %.1f-%.1f s (%s)" % [
			_max_gap_ms, _warmup_seconds(), soak_seconds, _max_gap_context])
	_report()


func _place_bed(at: Vector3, ordinal: int) -> void:
	await _teleport_to(at)
	_game.set("pending_build", "creature_bed")
	await _settle(18, false)
	var records_before := (_game.get("placed_buildings") as Array).size()
	var deltas_before := _delta_count
	await _tap_joypad("build_place")
	await _settle(24, false)
	var records_after := (_game.get("placed_buildings") as Array).size()
	if records_after != records_before + 1:
		_fail("controller press did not place Creature Bed %d (%d -> %d records)" % [ordinal, records_before, records_after])
	var pending: Array = _placer.get("_pending_placements") as Array
	if not pending.is_empty():
		_fail("Creature Bed %d left %d pending placement ticket(s)" % [ordinal, pending.size()])
	var emitted := _delta_count - deltas_before
	if emitted > 2:
		_fail("Creature Bed %d emitted %d deltas; a settled bed may emit only its building and one new flag" % [ordinal, emitted])
	else:
		print("Creature Bed %d settled from controller input with %d ledger delta(s)" % [ordinal, emitted])


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else at.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z + 3.0)
	_player.global_rotation = Vector3.ZERO
	_player.velocity = Vector3.ZERO
	await _settle(14, false)


func _tap_joypad(action: String) -> void:
	var mapped: InputEvent = null
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			mapped = event
			break
	if mapped == null:
		_fail("InputMap action '%s' has no joypad binding" % action)
		return
	var down := mapped.duplicate()
	down.device = 0
	if down is InputEventJoypadButton:
		(down as InputEventJoypadButton).pressed = true
	else:
		(down as InputEventJoypadMotion).axis_value = (mapped as InputEventJoypadMotion).axis_value
	Input.parse_input_event(down)
	await _settle(2, false)
	var up := down.duplicate()
	if up is InputEventJoypadButton:
		(up as InputEventJoypadButton).pressed = false
	else:
		(up as InputEventJoypadMotion).axis_value = 0.0
	Input.parse_input_event(up)
	await _settle(5, false)


func _settle(frames: int, measure: bool) -> void:
	for _i in frames:
		var autosave_before := float(_game.get("_autosave_elapsed")) if _game != null else -1.0
		await process_frame
		var now := Time.get_ticks_usec()
		if measure and _last_frame_usec > 0:
			var gap_ms := float(now - _last_frame_usec) / 1000.0
			var soak_elapsed := float(Time.get_ticks_msec() - _soak_started_msec) / 1000.0
			var autosave_after := float(_game.get("_autosave_elapsed")) if _game != null else -1.0
			var context := "soak %.1fs, autosave %.1fs -> %.1fs%s" % [
				soak_elapsed, autosave_before, autosave_after,
				" (fallback fired)" if autosave_after < autosave_before else "",
			]
			if soak_elapsed < _warmup_seconds():
				if gap_ms > _warmup_max_gap_ms:
					_warmup_max_gap_ms = gap_ms
					_warmup_max_gap_context = context
			elif gap_ms > _max_gap_ms:
				_max_gap_ms = gap_ms
				_max_gap_context = context
		_last_frame_usec = now


func _on_delta_applied(_delta: Dictionary) -> void:
	_delta_count += 1


func _soak_seconds() -> float:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--soak-seconds="):
			return maxf(0.0, float(arg.trim_prefix("--soak-seconds=")))
	return DEFAULT_SOAK_SECONDS


func _run_count() -> int:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			return maxi(1, int(arg.trim_prefix("--runs=")))
	return DEFAULT_RUNS


func _warmup_seconds() -> float:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--warmup-seconds="):
			return maxf(0.0, float(arg.trim_prefix("--warmup-seconds=")))
	return DEFAULT_WARMUP_SECONDS


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report() -> void:
	if _game != null:
		_game.set("free_build", false)
		_game.set("pending_build", "")
	_wipe_test_dir()
	if _failures.is_empty():
		print("TWO CREATURE BED FREEZE SMOKE: PASS")
		quit(0)
	else:
		print("TWO CREATURE BED FREEZE SMOKE: FAIL (%d)" % _failures.size())
		for failure: String in _failures:
			print("  - %s" % failure)
		quit(1)


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir():
			_remove_test_tree(TEST_DIR.path_join(name))
			dir.remove(name)
		else:
			dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()


func _remove_test_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir():
			_remove_test_tree(path.path_join(name))
			dir.remove(name)
		else:
			dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()
