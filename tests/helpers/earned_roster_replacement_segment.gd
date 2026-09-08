extends "res://tests/helpers/fresh_opening_segment.gd"

## Finish an actual Meadows wild capture with a full belt, then make the caller's
## explicit outgoing-member choice through the production farewell UI.
## This neither creates a pending catch nor releases anyone through Party APIs.
const CEREMONY_FRAMES := 60 # Same automatic-open bound as smoke_release.


func _replacement_realm() -> String:
	return "meadows"


func _fight_until_catchable() -> bool:
	# The opening driver's fixed 4 m action gate only described its tutorial
	# matchup. Ask the actual size-aware impact rule for this new wild target.
	var ally := _encounter.call("ally_body") as Node3D
	var foe: RefCounted = _combat.call("enemy")
	var own: RefCounted = _combat.call("active_creature")
	if ally == null or foe == null or own == null:
		_fail("replacement combat lacks its actual creatures and bodies")
		return false
	for frame in 1800:
		if not bool(_combat.call("is_fighting")) or bool(own.get("fainted")):
			_fail("replacement fight ended before natural weakening")
			return false
		if float(foe.get("hp")) <= float(foe.get("max_hp")) * 0.28:
			_weakened_hp = float(foe.get("hp"))
			_checkpoint("%s naturally weakened to %.0f/%.0f HP" % [
				foe.get("species_id"), foe.get("hp"), foe.get("max_hp")])
			return true
		await _drive_body_toward(ally, _wild.global_position, 1)
		var reach := float(_combat.call("combat_move_reach", "quick"))
		if reach <= 0.0:
			_fail("replacement fighter has no production quick-attack reach")
			return false
		if ally.global_position.distance_to(_wild.global_position) < reach and frame % 35 == 0:
			await _tap_action("combat_quick")
	_stop_left_stick()
	_fail("real piloted attacks did not weaken the replacement target within the existing 1800-step bound")
	return false


func replace_existing(tree: SceneTree, world: Node, game: Node,
		player: CharacterBody3D, rig: Node3D, wild: Node3D,
		outgoing_index: int) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = rig
	_started_ms = Time.get_ticks_msec()
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game) \
			or str(game.get("current_realm")) != _replacement_realm() or tree.current_scene != world:
		_fail("earned replacement requires the caller's live %s context" % _replacement_realm())
		return _result()
	if not _collect_world_nodes():
		return _result()
	_wild = wild
	var party: RefCounted = game.get("party")
	var before := roster_ids(party)
	if before.size() != 5 or outgoing_index < 0 or outgoing_index >= 5 \
			or game.get("pending_catch") != null or tree.current_scene != world:
		_fail("earned replacement requires the current five-member belt and no pending catch")
		return _result()
	if not is_instance_valid(wild) or not bool(_combat.call("is_fighting")) \
			or not _engaged_expected_body(wild):
		_fail("earned replacement needs the exact already-engaged live wild")
		return _result()
	var newcomer: RefCounted = wild.get("instance")
	if newcomer == null or before.has(newcomer.get_instance_id()):
		_fail("replacement target is not a distinct wild creature")
		return _result()
	if not await _fight_until_catchable() or not await _catch_with_real_throws():
		return _result()
	var menu: Node = game.call("menu")
	var tab: Node = null
	if menu != null:
		var tabs: Array = menu.get("_tabs")
		for index in tabs.size():
			if str(tabs[index].get("id", "")) == "creatures":
				tab = menu.get("_bodies")[index]
				break
	if tab == null:
		_fail("earned catch has no production creatures tab")
		return _result()
	for _frame in CEREMONY_FRAMES:
		if bool(menu.call("is_open")) and str(tab.get("_release_stage")) == "choose":
			break
		await tree.process_frame
	if bool(_combat.call("is_fighting")) or str(_combat.call("outcome")) != CAUGHT_OUTCOME \
			or game.get("pending_catch") != newcomer or roster_ids(party) != before \
			or not bool(menu.call("is_open")) or str(tab.get("_release_stage")) != "choose":
		_fail("physical catch did not open its actual pending-choice ceremony with the belt unchanged")
		return _result()
	if tree.root.gui_get_focus_owner() != tab.get("_pending_button"):
		_fail("automatic ceremony did not focus the newcomer first")
		return _result()
	var rows: Array = tab.get("_rows")
	if rows.size() != 5:
		_fail("ceremony must present exactly five owned belt rows")
		return _result()
	# Production fences pending -> row 0 on Down, then ordinary vertical rows.
	for index in outgoing_index + 1:
		await _ceremony_tap("ui_down")
		if tree.root.gui_get_focus_owner() != rows[index]:
			_fail("ordinary Down did not reach the expected outgoing belt row")
			return _result()
	await _ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "confirm" \
			or int(tab.get("_release_target")) != outgoing_index \
			or tree.root.gui_get_focus_owner() != tab.get("_farewell_keep") \
			or roster_ids(party) != before or game.get("pending_catch") != newcomer:
		_fail("farewell confirmation did not preserve the exact chosen member and default Keep action")
		return _result()
	await _ceremony_tap("ui_down")
	if tree.root.gui_get_focus_owner() != tab.get("_farewell_release"):
		_fail("ordinary Down did not reach Let them go")
		return _result()
	await _ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "done" or game.get("pending_catch") != null \
			or not replacement_receipt(before, roster_ids(party), outgoing_index, newcomer.get_instance_id()):
		_fail("confirmed farewell did not retain the other four and append the actual caught newcomer")
		return _result()
	if tree.root.gui_get_focus_owner() != tab.get("_farewell_done"):
		_fail("farewell goodbye did not focus Back to belt")
		return _result()
	await _ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "":
		_fail("Back to belt did not end the actual ceremony")
		return _result()
	await _ceremony_tap("menu_cancel")
	if bool(menu.call("is_open")) or tree.paused or tree.current_scene != world:
		_fail("completed earned replacement did not return current-world control")
		return _result()
	_checkpoint("earned replacement: released identity %d; caught %s identity %d appended; five retained" % [
		before[outgoing_index], newcomer.get("species_id"), newcomer.get_instance_id()])
	return _result()


static func roster_ids(party: RefCounted) -> Array[int]:
	var ids: Array[int] = []
	for member: RefCounted in party.call("members"):
		ids.append(member.get_instance_id())
	return ids


static func replacement_receipt(before: Array[int], after: Array[int],
		outgoing_index: int, newcomer_id: int) -> bool:
	if before.size() != 5 or outgoing_index < 0 or outgoing_index >= 5 \
			or before.has(newcomer_id):
		return false
	var seen: Array[int] = []
	for id in before:
		if seen.has(id):
			return false
		seen.append(id)
	var expected := before.duplicate()
	expected.remove_at(outgoing_index)
	expected.append(newcomer_id)
	return after == expected


func _ceremony_tap(action: String) -> void:
	# The ceremony pauses world processing. GUI actions use process frames,
	# without unpausing the tree or directly moving focus/advancing the menu.
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	for _frame in 3:
		await _tree.process_frame
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	for _frame in 5:
		await _tree.process_frame
