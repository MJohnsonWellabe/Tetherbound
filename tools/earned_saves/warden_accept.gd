extends "res://tests/helpers/meadows_earned_warden_segment.gd"

## The earned Warden segment with the OTHER F05 answer: the freed Veridian's
## offer is ACCEPTED. Everything else -- reveal, Warden fight, machine
## sequence, acknowledgement walk, physical Rift crossing -- is the unchanged
## read-only helper (`tests/helpers/meadows_earned_warden_segment.gd`).
##
## With a full belt the production answer to the volunteer is the five-slot
## farewell ceremony (tab_creatures.gd "choose" stage): choosing an owned row
## lets that member go and seats Veridian; choosing the newcomer refuses it.
## This variant chooses the lowest-level owned member (last on ties) through
## ordinary Down/Accept presses exactly as
## `earned_roster_replacement_segment.gd` does for a wild catch, then treats
## the resulting belt (four earned + Veridian) as the retained five for every
## later identity check. `stronghold_climax.gd` records `legendary_joined` from
## the belt itself; nothing here writes a flag or a party member.

var _accepting := false
var _outgoing_index := -1
var _accept_receipt: Dictionary = {}


static func outgoing_choice(levels: Array[int]) -> int:
	var chosen := -1
	for index in levels.size():
		if chosen < 0 or levels[index] <= levels[chosen]:
			chosen = index
	return chosen


func _keep_the_earned_five() -> bool:
	var pending: RefCounted = _game.get("pending_catch")
	var spec: Dictionary = _ending_config.get("legendary", {})
	if not opponent_matches(pending, spec) or _initial_ids.has(pending.get_instance_id()):
		return _fail("The voluntary pending creature does not match the actual authored legendary")
	var menu: Node = _game.call("menu")
	if menu == null:
		return _fail("The voluntary pending legendary has no actual game menu")
	var tab: Node = null
	for index in (menu.get("_tabs") as Array).size():
		if str(menu.get("_tabs")[index].get("id", "")) == "creatures":
			tab = menu.get("_bodies")[index]
	if tab == null:
		return _fail("The real pending legendary has no production creatures tab")
	for _frame in CEREMONY.CEREMONY_FRAMES:
		if bool(menu.call("is_open")) and str(tab.get("_release_stage")) == "choose":
			break
		await _tree.process_frame
	if not bool(menu.call("is_open")) or str(tab.get("_release_stage")) != "choose" \
			or _tree.root.gui_get_focus_owner() != tab.get("_pending_button") \
			or not retained_five(_initial_ids, _party_ids()):
		return _fail("The real ceremony did not present the pending legendary beside the unchanged earned five")
	var members: Array = (_game.get("party") as RefCounted).call("members")
	var levels: Array[int] = []
	for member: RefCounted in members:
		levels.append(int(member.get("level")))
	_outgoing_index = outgoing_choice(levels)
	var outgoing: RefCounted = members[_outgoing_index]
	var before := _party_ids()
	var rows: Array = tab.get("_rows")
	_accepting = true
	for index in _outgoing_index + 1:
		await _gui._ceremony_tap("ui_down")
		if _tree.root.gui_get_focus_owner() != rows[index]:
			return _fail("Ordinary Down did not reach the chosen outgoing belt row")
	await _gui._ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "confirm" or int(tab.get("_release_target")) != _outgoing_index \
			or _tree.root.gui_get_focus_owner() != tab.get("_farewell_keep"):
		return _fail("The farewell question did not select the chosen owned member with Keep as default")
	await _gui._ceremony_tap("ui_down")
	if _tree.root.gui_get_focus_owner() != tab.get("_farewell_release"):
		return _fail("Ordinary Down did not reach the actual release confirmation")
	await _gui._ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "done" or _game.get("pending_catch") != null \
			or not CEREMONY.replacement_receipt(before, _party_ids(), _outgoing_index, pending.get_instance_id()):
		return _fail("Accepting the Veridian did not keep the other four and seat the volunteer")
	await _gui._ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "":
		return _fail("Back to belt did not end the real farewell ceremony")
	await _gui._ceremony_tap("menu_cancel")
	if bool(menu.call("is_open")) or _tree.paused or _tree.current_scene != _world:
		return _fail("The accepted-offer ceremony did not return current-world control")
	# The new five (four earned + the volunteer) is what every later check keeps.
	_initial_ids = _party_ids()
	_accepting = false
	_accept_receipt = {"choice": "accept_veridian_release_lowest_level_member",
		"released": {"species": str(outgoing.get("species_id")), "uid": str(outgoing.get("uid")),
			"level": int(outgoing.get("level")), "index": _outgoing_index},
		"joined": {"species": str(pending.get("species_id")), "uid": str(pending.get("uid")),
			"level": int(pending.get("level"))}}
	_receipt("veridian_accepted", _accept_receipt)
	return true


func _ending_ready() -> bool:
	return _has("defeated_warden") and _has("legendary_freed") and _has("legendary_settled") \
		and _has("realm_key_cloudreach") and _has("realm_heart_meadows_earned") and _has("legendary_joined") \
		and not _has("legendary_refused") and _game.get("pending_catch") == null


func _observe_retained_party() -> void:
	if _accepting:
		return
	super._observe_retained_party()
