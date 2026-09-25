extends "res://tests/helpers/stormwood_earned_waterward_handoff.gd"

## Earned release -> the player's own Stormheart offer answered Yes at five ->
## the Team tab's release ceremony keeps the Stormheart and lets one named
## belt member go -> the Waterward view (Long Storm aftermath, Water key).
## Stops before the Waterward gate. Every step is ordinary input on production
## prompts, dialogue and the Team tab; nothing is granted or written here.
const RELEASED_ROW := 4
const ANSWER_PREFIX := "stormwood:legendary_answer:"
var _released_uid := 0
var _stormheart_uid := ""
var _kept_five: Array[int] = []


func _continue_waterward() -> void:
	if not await _drain_exact("stormwood_stormheart_release"):
		return
	var ending := _world.get_node_or_null("StormwoodEnding") as Node3D
	var offer := ending.get_node_or_null("StormheartOffer") as Node3D if ending != null else null
	if offer == null or not await _core_south_ring() or not await _activate_exact(ending, offer,
			Vector2(offer.global_position.x, offer.global_position.z + 2), "Stormheart offer") \
			or not await _drain_exact("stormwood_stormheart_offer") \
			or not await _accept_pending_stormheart():
		return
	if not await _receipt(OFFERED) or not bool(_game.call("player_flags").call("has", SETTLED)) \
			or not bool(_game.call("player_flags").call("has", "stormwood:legendary_offer_accepted")):
		_fail("the kept Stormheart lacks its saved personal/world settlement")
		return
	_note("ACCEPTED the Stormheart at five: kept %s, released belt row %d; world offer fact and personal receipt saved"
		% [_stormheart_uid, RELEASED_ROW])
	var view := ending.get_node_or_null("WaterwardView") as Node3D
	if view == null or not await _core_south_ring() or not await _activate_exact(ending, view,
			Vector2(view.global_position.x, view.global_position.z + 2), "Waterward view") \
			or not await _drain_exact("stormwood_waterward_aftermath"):
		return
	for flag in ["stormwood:waterward_revealed", WATER_KEY, "waterward_route_revealed", "stormwood:chapter_complete"]:
		if not await _receipt(flag):
			return
	_complete = true
	_note("REVEALED the Waterward aftermath; Water key held; STOP before the gate")


## Yes at five opens the Team tab ceremony on the pending Stormheart. Ordinary
## pad input: Up from the newcomer wraps to belt row 4, Accept opens that
## farewell with Keep focused, Down focuses "Let them go", Accept releases,
## Accept returns to the belt and Cancel closes the menu.
func _accept_pending_stormheart() -> bool:
	var menu: Node = _game.call("menu")
	var pending: RefCounted = _game.get("pending_catch")
	if pending == null or str(pending.get("species_id")) != "fulgocobra" \
			or int(pending.get("level")) != 44 or _party_before.has(pending.get_instance_id()) or menu == null:
		return _fail("Yes at five did not hold the distinct level-44 Stormheart pending")
	_stormheart_uid = str(pending.get("uid"))
	var tab: Node
	for index in (menu.get("_tabs") as Array).size():
		if str(menu.get("_tabs")[index].get("id", "")) == "creatures":
			tab = menu.get("_bodies")[index]
	if tab == null:
		return _fail("the ceremony has no creatures tab")
	for _frame in CEREMONY_FRAMES:
		if menu.is_open() and str(tab.get("_release_stage")) == "choose":
			break
		await _tree.process_frame
	if not menu.is_open() or str(tab.get("_release_stage")) != "choose" \
			or not same_five(_party_before, _roster_ids()):
		return _fail("the ceremony did not open on the pending Stormheart beside the same five")
	_released_uid = _party_before[RELEASED_ROW]
	await _gui_tap("ui_up")
	var rows: Array = tab.get("_rows")
	if rows.size() <= RELEASED_ROW or _tree.root.gui_get_focus_owner() != rows[RELEASED_ROW]:
		return _fail("Up from the newcomer did not focus belt row %d" % RELEASED_ROW)
	await _gui_tap("ui_accept")
	if str(tab.get("_release_stage")) != "confirm" or int(tab.get("_release_target")) != RELEASED_ROW \
			or _tree.root.gui_get_focus_owner() != tab.get("_farewell_keep"):
		return _fail("the farewell must target belt row %d with Keep focused" % RELEASED_ROW)
	await _gui_tap("ui_down")
	if _tree.root.gui_get_focus_owner() != tab.get("_farewell_release"):
		return _fail("Down did not focus Let them go")
	await _gui_tap("ui_accept")
	var after := _roster_ids()
	_kept_five = _party_before.duplicate()
	_kept_five.remove_at(RELEASED_ROW)
	var stormheart_ids: Array[int] = []
	for creature: RefCounted in _game.get("party").call("members"):
		if str(creature.get("uid")) == _stormheart_uid:
			stormheart_ids.append(creature.get_instance_id())
	if str(tab.get("_release_stage")) != "done" or _game.get("pending_catch") != null \
			or after.size() != 5 or after.slice(0, 4) != _kept_five or stormheart_ids.size() != 1 \
			or after[4] != stormheart_ids[0] or after.has(_released_uid):
		return _fail("keeping the Stormheart must release only belt row %d and hold exactly five (after=%s)"
			% [RELEASED_ROW, str(after)])
	await _gui_tap("ui_accept")
	if str(tab.get("_release_stage")) != "":
		return _fail("Back to belt did not close the farewell")
	await _gui_tap("menu_cancel")
	return (not menu.is_open() and not _tree.paused and _tree.current_scene == _world) \
		or _fail("the ceremony did not return world control")


func result() -> Dictionary:
	return {"passed": _complete and failures.is_empty(), "world": _world,
		"game": _game, "failures": failures.duplicate(), "transcript": transcript.duplicate(),
		"stormheart_uid": _stormheart_uid,
		"endpoint": "earned Stormheart kept at five and Waterward aftermath, before the gate"}
