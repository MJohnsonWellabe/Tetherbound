extends SceneTree

## CL-W1 live half — the acceptance criterion, driven against real nodes.
##
##   godot --headless --path . --script tests/smoke_alpha_pins.gd
##
## `tests/test_alpha_pins.gd` proves the arithmetic, the persistence and the
## clearing rule as pure logic. This file proves the thing that file explicitly
## cannot: that the real `AlphaPins` NODE, ticking on a real SceneTree clock,
## with a real body walking toward a real authored Band 2 alpha, actually pins
## it — and then unpins it when the fight's own flag fires.
##
## The brief's acceptance sentence, step by step:
##   * a probe drives a body from outside the radius to inside it  -> `_test_a_body_walking_in_pins_the_alpha`
##   * the pin appears on the minimap and the full map             -> `_test_the_pin_is_in_the_marker_list_both_screens_draw`
##   * it survives save and load                                   -> `_test_the_pin_survives_a_real_save_and_load`
##   * it clears on KO                                             -> `_test_a_knockout_clears_the_pin_within_one_tick`
##
## Named `smoke_`, not `test_`, for exactly the reason `smoke_wild_streaming.gd`
## documents at length: `AlphaPins._process()` reads `Node3D.global_position`,
## whose getter hard-requires a live tree, and `run_tests.gd`'s `test_*.gd` glob
## would crash on a SceneTree-shaped file.
##
## ## Nothing here is a double
##
## `alpha_pins.gd` reaches `/root/Game` for the map, the progression store and
## `push_world_message()` — the same three seams `encounter_director.gd` reaches
## for. A `--script` run of a `SceneTree` subclass DOES stand the `Game` autoload
## up (its `_ready` is visible in this suite's own stack traces), so this file
## drives the real one: the real `GameState`, the real `MapState` it built from
## `map_landmarks.json`, the real `ProgressionState`, and a real `SaveGame`.
##
## A first cut of this file added its own `Game`-named stand-in node under
## `root` and could not make a single pin appear. The reason is worth recording,
## because it would cost the next person the same hour: the autoload is already
## there, so the stand-in was silently renamed by the engine, and `alpha_pins.gd`
## went on reading the real `/root/Game` while every assertion inspected the
## double. Nothing errored anywhere.
##
## The one substitution: `Game.save_system` is pointed at a `SaveGame` writing
## under `user://smoke_saves_alpha_pins/` instead of `user://saves/`, so this
## file cannot overwrite a real playthrough's slot. `save_system.save()` is
## called directly rather than `Game.save_game()`, which additionally syncs
## player pose and placed buildings out of a world scene this file does not
## load.

const ALPHA_PINS := preload("res://scripts/world/alpha_pins.gd")
const MAP_STATE := preload("res://autoload/map_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

const SAVE_DIR := "user://smoke_saves_alpha_pins/"

## Band 2, order 2011, trailpup, authored centre [-180, 0, 2250] in
## `data/config/bands/band2_stone_and_root/spawns.json`. Its nearest authored
## neighbour (order 2012) is 401 m away, so this is a clean single-pin target.
const TARGET_ORDER := 2011
const TARGET_XZ := Vector2(-180.0, 2250.0)
const TARGET_LABEL := "Alpha Trailpup"
## Start well outside the 300 m radius, on the same axis, so "walking in" is a
## real crossing of the boundary rather than a teleport onto the pin.
const START_XZ := Vector2(-180.0, 1700.0)


var _failures: Array[String] = []
var _game: Node = null
var _saver: RefCounted = null
var _player: CharacterBody3D = null
var _pins: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	# See smoke_wild_streaming.gd: nothing has a live tree until after the
	# first yield, `global_position` included.
	await process_frame
	await _stand_up()
	await _test_nothing_is_pinned_from_outside_the_radius()
	await _test_a_body_walking_in_pins_the_alpha()
	_test_the_pin_is_in_the_marker_list_both_screens_draw()
	await _test_the_first_pin_announced_itself_exactly_once()
	await _test_the_pin_survives_a_real_save_and_load()
	await _test_a_knockout_clears_the_pin_within_one_tick()
	await _test_a_cleared_alpha_does_not_come_back_on_reload()
	_report()


func _stand_up() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_wipe_saves()
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("no /root/Game autoload; this smoke has nothing to drive")
		_report()
		return
	# Slots under a smoke-only directory, never the player's own.
	_saver = SAVE_GAME.new(SAVE_DIR)
	_game.set("save_system", _saver)

	_player = CharacterBody3D.new()
	_player.name = "Player"
	root.add_child(_player)
	_player.global_position = Vector3(START_XZ.x, 0.0, START_XZ.y)

	_pins = ALPHA_PINS.new()
	_pins.set("player_path", _player.get_path())
	root.add_child(_pins)
	await process_frame


## Drives the node's real `_process` clock rather than calling `tick()` by
## hand — a proximity check that only fires when something else pokes it is not
## the feature.
##
## Frame COUNT is the wrong unit here and was the second hour this file cost:
## `check_interval_s` is 0.5 s of accumulated `delta`, and the headless main
## loop runs ~150 frames a second, so 40 frames is 0.26 s and never reaches the
## first tick. Waits on the clock instead, with a generous margin.
func _let_it_tick() -> void:
	var until := Time.get_ticks_msec() + 900
	while Time.get_ticks_msec() < until:
		await process_frame


func _map() -> RefCounted:
	return _game.get("map") as RefCounted


func _progression() -> RefCounted:
	return _game.get("progression") as RefCounted


func _distance_to_target() -> float:
	return Vector2(_player.global_position.x, _player.global_position.z).distance_to(TARGET_XZ)


func _alpha_markers() -> Array:
	var out: Array = []
	for entry: Dictionary in (_map().call("landmarks") as Array):
		if not bool(entry.get("dynamic", false)):
			continue
		if str(entry.get("id", "")).begins_with(MAP_STATE.ALPHA_MARKER_PREFIX):
			out.append(entry)
	return out


func _fail(line: String) -> void:
	_failures.append(line)


# --- the acceptance sentence, in order --------------------------------------

func _test_nothing_is_pinned_from_outside_the_radius() -> void:
	await _let_it_tick()
	var distance := _distance_to_target()
	if distance <= 300.0:
		_fail("precondition broken: the probe starts %.1f m from the alpha, inside the radius" % distance)
		return
	if int(_map().call("alpha_pin_count")) != 0:
		_fail("an alpha pinned from %.1f m away, outside the authored 300 m" % distance)


func _test_a_body_walking_in_pins_the_alpha() -> void:
	# Walk the body in along the corridor in 50 m steps, ticking between them,
	# and record the distance at which the pin actually appeared. A pin that
	# only lands once the body is standing on top of the cluster would pass a
	# bare "is it pinned at the end" check and fail the owner's directive.
	var pinned_at := -1.0
	for step in 14:
		var here := START_XZ.lerp(TARGET_XZ, float(step + 1) / 14.0)
		_player.global_position = Vector3(here.x, 0.0, here.y)
		await _let_it_tick()
		if bool(_map().call("is_alpha_pinned", TARGET_ORDER)):
			pinned_at = _distance_to_target()
			break
	if pinned_at < 0.0:
		_fail("the probe walked all the way onto the alpha's authored centre and it never pinned")
		return
	if pinned_at < 250.0:
		_fail("the alpha pinned only at %.1f m; the owner's directive is 300 m" % pinned_at)
	print("alpha pins: pinned at %.1f m (radius 300 m, walked in from %.1f m)" % [
		pinned_at, START_XZ.distance_to(TARGET_XZ)])
	if int(_map().call("alpha_pin_count")) != 1:
		_fail("expected exactly one pin near this cluster, got %d" % int(_map().call("alpha_pin_count")))


func _test_the_pin_is_in_the_marker_list_both_screens_draw() -> void:
	# `minimap.gd::_draw_landmarks()` and `tab_map.gd::_draw_map()` both iterate
	# `MapState.landmarks()` and both single out an entry whose id begins with
	# `ALPHA_MARKER_PREFIX`. This asserts the entry those two filters see, which
	# is the closest a headless run can get to asserting the draw itself; the
	# drawn result is the render + blind judge in ralph/reports/.
	var markers := _alpha_markers()
	if markers.size() != 1:
		_fail("the pin exists but %d alpha markers are in the list both screens draw" % markers.size())
		return
	var marker: Dictionary = markers[0]
	if str(marker.get("display_name", "")) != TARGET_LABEL:
		_fail("the full map would label the pin '%s', not '%s'" % [
			str(marker.get("display_name", "")), TARGET_LABEL])
	if str(marker.get("icon", "")) != "alpha":
		_fail("the pin carries icon '%s'" % str(marker.get("icon", "")))
	if not ResourceLoader.exists("res://assets/ui/icons/map/alpha.png"):
		_fail("the full map would draw nothing: assets/ui/icons/map/alpha.png is missing")
	var position: Vector2 = marker.get("position", Vector2.ZERO)
	if position.distance_to(TARGET_XZ) > 0.01:
		_fail("the pin sits at %s, not the authored cluster centre %s" % [str(position), str(TARGET_XZ)])


func _test_the_first_pin_announced_itself_exactly_once() -> void:
	# `push_world_message` queues one line for the HUD to read and clear. There
	# is no HUD in this run, so the line is still sitting there — which is
	# exactly what makes it assertable.
	var queued := str(_game.call("take_pending_world_message"))
	if queued.is_empty():
		_fail("the first pin queued no world message")
	elif not queued.to_lower().contains("alpha"):
		_fail("the first-pin message does not mention an alpha: '%s'" % queued)
	if not bool(_progression().call("has", ALPHA_PINS.INTRO_FLAG)):
		_fail("the one-shot intro flag was never set, so the line would repeat")
	# The one-shot contract: another pin must not queue it again.
	_player.global_position = Vector3(-150.0, 0.0, 2650.0)  # order 2012, meadowhart
	await _let_it_tick()
	if not bool(_map().call("is_alpha_pinned", 2012)):
		_fail("precondition: the second alpha did not pin")
	if not str(_game.call("take_pending_world_message")).is_empty():
		_fail("the intro line fired a second time; it is meant to be once per save")
	# Put the probe back where the rest of this file expects it, and drop every
	# pin but the one under test. Standing at 2012's centre also brings 2100
	# inside the radius (291 m), which is the feature working, not a defect —
	# but the save/load and knockout checks below want a single, named pin so a
	# failure names the cluster that failed rather than a count.
	_player.global_position = Vector3(TARGET_XZ.x, 0.0, TARGET_XZ.y)
	for pin: Dictionary in (_map().call("alpha_pins") as Array):
		if int(pin.get("order", 0)) != TARGET_ORDER:
			_map().call("unpin_alpha", int(pin.get("order", 0)))
	if int(_map().call("alpha_pin_count")) != 1:
		_fail("could not reduce to a single pin before the save/load checks")


func _test_the_pin_survives_a_real_save_and_load() -> void:
	var saver: RefCounted = _saver
	if not bool(saver.call("save", _game, 1)):
		_fail("the save write failed")
		return
	# Throw the map away entirely and load into a fresh one — the same thing a
	# relaunch does, and the case the closure plan's fails-if is written about.
	_game.set("map", MAP_STATE.new())
	_map().call("configure", {})
	if int(_map().call("alpha_pin_count")) != 0:
		_fail("precondition: the fresh map is not empty")
		return
	if not bool(saver.call("load_slot", _game, 1)):
		_fail("the save would not load back")
		return
	if not bool(_map().call("is_alpha_pinned", TARGET_ORDER)):
		_fail("the pin did not survive a real save and load")
		return
	var markers := _alpha_markers()
	if markers.size() != 1 or str((markers[0] as Dictionary).get("display_name", "")) != TARGET_LABEL:
		_fail("the pinned set came back but the marker the map draws did not")
	await _let_it_tick()
	if not bool(_map().call("is_alpha_pinned", TARGET_ORDER)):
		_fail("the restored pin was thrown away by the first tick after loading")


func _test_a_knockout_clears_the_pin_within_one_tick() -> void:
	# Exactly what `encounter_director.gd::_on_combat_exited()` does on "won"
	# (and, per A-3, identically on CAUGHT): fire the individual's once-flag.
	_progression().call("set_flag", "wild_once_%d" % TARGET_ORDER)
	await _let_it_tick()
	if bool(_map().call("is_alpha_pinned", TARGET_ORDER)):
		_fail("the alpha was beaten and its pin is still on the map")
	if not _alpha_markers().is_empty():
		_fail("the pin cleared but its marker is still in the list the map draws")


func _test_a_cleared_alpha_does_not_come_back_on_reload() -> void:
	# The body is still standing inside the radius. A re-pin here would be the
	# feature nagging the player about a fight they have already won.
	await _let_it_tick()
	if bool(_map().call("is_alpha_pinned", TARGET_ORDER)):
		_fail("a beaten alpha re-pinned while the player stood next to it")
	var saver: RefCounted = _saver
	saver.call("save", _game, 2)
	_game.set("map", MAP_STATE.new())
	_map().call("configure", {})
	saver.call("load_slot", _game, 2)
	await _let_it_tick()
	if bool(_map().call("is_alpha_pinned", TARGET_ORDER)):
		_fail("a beaten alpha came back after a save and load")


func _wipe_saves() -> void:
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _report() -> void:
	_wipe_saves()
	print("")
	if _failures.is_empty():
		print("alpha pins: OK — a body walking in pins the Band 2 alpha inside 300 m, the pin is in the marker list both screens draw, it survives a real save/load, and beating it clears it and keeps it cleared.")
		quit(0)
		return
	for line in _failures:
		print("alpha pins FAIL: %s" % line)
	quit(1)
