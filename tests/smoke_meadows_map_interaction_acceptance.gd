extends SceneTree

## Meadows OWNER-0912 Tier 1 #2/#5 production interaction smoke.
##
## Scope is deliberately narrow:
##   * establish Dara's already-defeated prerequisite as fixture state;
##   * use Dara's real world body, Interactable, physical controller binding,
##     shared DialoguePanel and SequenceDirector effect drain;
##   * open the production full-map shell with its physical controller binding;
##   * place/remove a personal marker through the focused map canvas;
##   * round-trip the reveal and marker through Game.save_game/load_game.
##
## Proximity discovery and alpha auto-pinning are paused after world boot so
## the smoke can prove the knowledge came from Dara's spoken effect rather than
## merely from teleporting its focused probe close to the Pond. This does not
## claim ordinary road traversal, dialogue visuals, map raster quality, or the
## title-screen Continue flow; those remain separate acceptance surfaces.
##
## Run from the repository root:
##   godot --headless --path . --script tests/smoke_meadows_map_interaction_acceptance.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const MAP_STATE := preload("res://autoload/map_state.gd")

const TEST_DIR := "user://test_saves_meadows_map_interaction_0912/"
const TEST_SLOT := 1
const SETTLE_FRAMES := 300
const DARA_ID := "shepherd_the_rise"
const DARA_DEFEATED_FLAG := "defeated_shepherd_the_rise"
const DARA_CONVERSATION := "shepherd_the_rise_defeated"
const POND_REGION := "the_pond"
const POND_ALPHA_ORDER := 1900

var _failures: Array[String] = []
var _world: Node3D = null
var _game: Node = null
var _player: CharacterBody3D = null
var _trainers: Node = null
var _arbiter: Node = null
var _dialogue: CanvasLayer = null
var _menu: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	_wipe_test_dir()
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_fail("could not load the production Meadows scene")
		_report()
		return
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for _frame in SETTLE_FRAMES:
		await physics_frame
	if not _collect_production_nodes():
		_report()
		return

	# Never touch the owner's saves. The production Game seam still performs
	# both writes and loads; only its root directory is replaced.
	_game.set("save_system", SAVE_GAME.new(TEST_DIR))
	_prepare_exact_dialogue_causality()
	await _reveal_pond_through_daras_real_interaction()
	if not _failures.is_empty():
		_report()
		return
	await _open_map_and_place_marker()
	if not _failures.is_empty():
		_report()
		return
	await _save_reload_remove_and_repeat()
	_report()


func _collect_production_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_trainers = _world.get_node_or_null(^"Trainers")
	_arbiter = get_first_node_in_group("interaction_arbiter")
	_dialogue = get_first_node_in_group("dialogue_panel") as CanvasLayer
	_menu = _game.call("menu") as CanvasLayer if _game != null else null
	if _game == null or _player == null or _trainers == null or _arbiter == null \
			or _dialogue == null or _menu == null:
		_fail("real Meadows boot is missing Game/player/trainers/arbiter/dialogue/menu")
		return false
	if not _trainers.has_method("body_for"):
		_fail("production trainer placer no longer exposes its authored bodies")
		return false
	return true


func _prepare_exact_dialogue_causality() -> void:
	# This smoke begins immediately after Dara's battle. The combat win itself
	# is covered elsewhere; its durable flag is the prerequisite that makes her
	# real prompt select the direction-giving defeated conversation.
	var progression: RefCounted = _game.get("progression")
	progression.call("set_flag", DARA_DEFEATED_FLAG)

	# Stop both ordinary discovery sources before moving the focused probe.
	# Game's child menu retains its own processing; only Game's discovery tick
	# is disabled. The AlphaPins node is likewise paused locally.
	_game.set_process(false)
	var alpha_pins := _find_by_script(_world, "res://scripts/world/alpha_pins.gd")
	if alpha_pins != null:
		alpha_pins.set_process(false)
	var encounters := _world.get_node_or_null(^"EncounterDirector")
	if encounters != null:
		encounters.set_process(false)
		encounters.set_physics_process(false)

	# Reset only the personal map after the boot/setup movement. With both
	# proximity producers paused, any following reveal has one possible source:
	# DialoguePanel -> SequenceDirector -> dialogue_map_reveal.gd.
	var config := JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/map_landmarks.json")) as Dictionary
	var map: RefCounted = _game.get("map")
	map.call("configure", config)
	if bool(map.call("is_region_discovered", POND_REGION)) \
			or bool(map.call("is_alpha_pinned", POND_ALPHA_ORDER)):
		_fail("Pond knowledge was not hidden before Dara spoke")


func _reveal_pond_through_daras_real_interaction() -> void:
	var dara := _trainers.call("body_for", DARA_ID) as Node3D
	if dara == null:
		_fail("Dara's authored road body was not built")
		return
	var prompt := dara.call("prompt_node") as Node3D if dara.has_method("prompt_node") else null
	if prompt == null or str(prompt.get("label")).findn("Dara") < 0:
		_fail("Dara has no real defeated-state interaction prompt")
		return
	if not await _stand_where_prompt_wins(dara, prompt):
		_fail("Dara's real prompt never won the production interaction arbiter")
		return

	await _press_action("interact")
	if not await _wait_dialogue(true, 40):
		_fail("physical controller interaction did not open Dara's dialogue")
		return
	var runner := _dialogue.call("runner") as RefCounted
	if runner == null or str(runner.call("conversation_id")) != DARA_CONVERSATION:
		_fail("Dara's real interaction opened the wrong conversation")
		return

	var presses := 0
	while bool(_dialogue.call("is_open")) and presses < 12:
		await _press_action("interact")
		presses += 1
	if bool(_dialogue.call("is_open")):
		_fail("Dara's production dialogue did not close through controller input")
		return
	for _frame in 4:
		await process_frame

	var map: RefCounted = _game.get("map")
	if not bool(map.call("is_region_discovered", POND_REGION)):
		_fail("Dara's spoken map_reveal effect did not discover The Pond")
	if not bool(map.call("is_alpha_pinned", POND_ALPHA_ORDER)):
		_fail("Dara's spoken map_reveal effect did not pin Alpha Mosshell")
	if _alpha_marker(map).is_empty():
		_fail("Dara's reveal produced no full-map dynamic alpha marker")
	if _failures.is_empty():
		print("  ok    physical road-NPC dialogue revealed The Pond and Alpha Mosshell")


func _open_map_and_place_marker() -> void:
	await _press_action("map")
	if not await _wait_menu(true, 40):
		_fail("physical Map binding did not open the full map")
		return
	var map_tab := _current_map_tab()
	if not _map_open_state_is_valid(map_tab):
		return

	var map: RefCounted = _game.get("map")
	var alpha := _alpha_marker(map)
	var canvas := map_tab.get("_canvas") as Control
	var map_rect: Rect2 = map_tab.call("_map_rect_for_canvas", canvas.size)
	var alpha_point: Vector2 = map_tab.call("_world_to_canvas",
		alpha.get("position", Vector2.ZERO), map_rect)
	if not map_rect.has_point(alpha_point):
		_fail("the revealed Alpha Mosshell marker is outside the opened full map")
		return

	# Let the map's open-edge guard expire, then press the controller's real A
	# binding. The focused canvas, not a direct MapState call, owns placement.
	for _frame in 6:
		await process_frame
	var cursor: Vector2 = map_tab.call("_player_pin_cursor_point")
	var expected_world: Vector2 = map_tab.call("_canvas_to_world", cursor, map_rect)
	await _press_action("ui_accept")
	var markers: Array = map.call("player_markers")
	if markers.size() != 1:
		_fail("physical A on the focused full map did not place exactly one marker")
		return
	var placed := markers[0] as Dictionary
	if (placed.get("position", Vector2.ZERO) as Vector2).distance_to(expected_world) > 0.1:
		_fail("the placed marker did not use the full map's visible controller cursor")
		return
	print("  ok    opened full map mounted the reveal and physical A placed a personal marker")
	await _press_action("menu_cancel")
	if not await _wait_menu(false, 40):
		_fail("physical Back did not close the map before saving")


func _save_reload_remove_and_repeat() -> void:
	var map: RefCounted = _game.get("map")
	var before: Array = map.call("player_markers")
	if before.size() != 1:
		_fail("personal marker was absent before save")
		return
	var saved_marker := (before[0] as Dictionary).duplicate(true)
	if not bool(_game.call("save_game", TEST_SLOT)):
		_fail("Game.save_game could not write the isolated map-acceptance slot")
		return

	# Make restoration capable of failing: remove the live copy before loading.
	if not bool(map.call("remove_player_marker", str(saved_marker.get("id", "")))):
		_fail("could not invalidate the live marker before reload")
		return
	if not bool(_game.call("load_game", TEST_SLOT)):
		_fail("Game.load_game could not reopen the isolated map-acceptance slot")
		return
	for _frame in 8:
		await physics_frame
	map = _game.get("map")
	var restored: Array = map.call("player_markers")
	if restored.size() != 1 or str((restored[0] as Dictionary).get("id", "")) \
			!= str(saved_marker.get("id", "")):
		_fail("the personal marker did not persist through Game save/reopen")
		return
	if (restored[0] as Dictionary).get("position", Vector2.ZERO) != saved_marker.get("position"):
		_fail("the personal marker moved across Game save/reopen")
		return
	if not bool(map.call("is_region_discovered", POND_REGION)) \
			or not bool(map.call("is_alpha_pinned", POND_ALPHA_ORDER)):
		_fail("Dara's revealed map knowledge did not persist through save/reopen")
		return

	await _press_action("map")
	if not await _wait_menu(true, 40):
		_fail("full map would not reopen after loading its saved marker")
		return
	var map_tab := _current_map_tab()
	if not _map_open_state_is_valid(map_tab):
		return
	for _frame in 6:
		await process_frame
	await _press_action("interact")
	if not (map.call("player_markers") as Array).is_empty():
		_fail("physical X did not remove the personal marker under the map cursor")
		return
	await _press_action("menu_cancel")
	if not await _wait_menu(false, 40):
		_fail("map did not close after marker removal")
		return

	# Three fresh canvas builds catch lost focus, stale canvas pointers and the
	# shared shortcut edge. Each open must land controller focus on that build's
	# canvas and each Back must release the pause shell.
	for cycle in 3:
		await _press_action("map")
		if not await _wait_menu(true, 40):
			_fail("repeated full-map open %d failed" % (cycle + 1))
			return
		if not _map_open_state_is_valid(_current_map_tab()):
			return
		await _press_action("menu_cancel")
		if not await _wait_menu(false, 40):
			_fail("repeated full-map close %d failed" % (cycle + 1))
			return
	print("  ok    save/reopen persisted the pin; X removed it; repeated map focus stayed stable")


func _map_open_state_is_valid(map_tab: Control) -> bool:
	if not bool(_menu.call("is_open")) or str(_menu.call("current_tab_id")) != "map":
		_fail("menu opened without selecting the full map tab")
		return false
	if not paused:
		_fail("solo full map did not own pause while open")
		return false
	if map_tab == null or map_tab.call("_map_state") != _game.get("map"):
		_fail("opened map tab is not mounted to the active Meadows MapState")
		return false
	var canvas := map_tab.get("_canvas") as Control
	var focus := _menu.get_viewport().gui_get_focus_owner()
	if canvas == null or focus != canvas:
		_fail("controller focus did not land on the current full-map canvas")
		return false
	if _alpha_marker(_game.get("map") as RefCounted).is_empty():
		_fail("opened full map cannot see Dara's persisted alpha marker")
		return false
	return true


func _current_map_tab() -> Control:
	if _menu == null or not bool(_menu.call("is_open")):
		return null
	var bodies: Array = _menu.get("_bodies")
	var index := int(_menu.get("_index"))
	return bodies[index] as Control if index >= 0 and index < bodies.size() else null


func _alpha_marker(map: RefCounted) -> Dictionary:
	if map == null:
		return {}
	var wanted := MAP_STATE.alpha_marker_id(POND_ALPHA_ORDER)
	for entry: Dictionary in (map.call("landmarks") as Array):
		if str(entry.get("id", "")) == wanted:
			return entry
	return {}


func _stand_where_prompt_wins(body: Node3D, prompt: Node3D) -> bool:
	for offset: Vector3 in [
		Vector3(0.0, 0.08, 1.45), Vector3(1.45, 0.08, 0.0),
		Vector3(0.0, 0.08, -1.45), Vector3(-1.45, 0.08, 0.0),
	]:
		_player.global_position = body.global_position + offset
		_player.velocity = Vector3.ZERO
		for _frame in 10:
			await physics_frame
		if _arbiter.call("winning_provider") == prompt:
			return true
	return false


func _wait_dialogue(open: bool, budget: int) -> bool:
	for _frame in budget:
		if bool(_dialogue.call("is_open")) == open:
			return true
		await physics_frame
	return bool(_dialogue.call("is_open")) == open


func _wait_menu(open: bool, budget: int) -> bool:
	for _frame in budget:
		if bool(_menu.call("is_open")) == open:
			return true
		await process_frame
	return bool(_menu.call("is_open")) == open


func _press_action(action: String) -> void:
	var button_index := _button_for(action)
	if button_index < 0:
		_fail("'%s' has no physical joypad-button binding" % action)
		return
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for _frame in 5:
		await process_frame


func _button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for raw: Variant in InputMap.action_get_events(action):
		var button := raw as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


func _find_by_script(from: Node, path: String) -> Node:
	if from.get_script() != null and str(from.get_script().resource_path) == path:
		return from
	for child: Node in from.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir():
			dir.remove(entry)
		entry = dir.get_next()
	dir.list_dir_end()


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	_wipe_test_dir()
	print("")
	if _failures.is_empty():
		print("Meadows map interaction acceptance: OK -- dialogue reveal, full-map pin persistence/removal, and repeated controller focus.")
		quit(0)
		return
	for message: String in _failures:
		print("Meadows map interaction acceptance FAIL: %s" % message)
	quit(1)
