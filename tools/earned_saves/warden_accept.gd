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
var _last_owner_label := "<none>"


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
	# Diagnostic for B8: name every change of the live input owner.
	var owner := INPUT_OWNER.current(_tree)
	var label := "<none>" if owner == null else "%s (%s)" % [owner.get_path(), owner.get_script().resource_path.get_file() if owner.get_script() else owner.get_class()]
	if owner != null and owner == _panel:
		label += " conversation=" + _current_conversation()
	if label != _last_owner_label:
		print("EARNED WARDEN input_owner %s -> %s frame=%d" % [_last_owner_label, label, Engine.get_physics_frames()])
		_last_owner_label = label
	if _accepting:
		return
	super._observe_retained_party()


## Same disclosed prompt-press handling as `relay_route.gd` (BLOCKERS.md B4).
const PRESS_TRIES := 3

var _activated_path := ""


func _on_activated(provider: Object) -> void:
	super._on_activated(provider)
	_activated_path = str((provider as Node).get_path()) if provider is Node and is_instance_valid(provider) else str(provider)


func _press_prompt(prompt: Node3D) -> bool:
	for attempt in PRESS_TRIES:
		if not await _approach_prompt(prompt):
			return false
		var expected := prompt.get_instance_id()
		_activated_id = 0
		_activated_path = ""
		await _input._tap("interact")
		if _activated_id == expected:
			return true
		# Attempt 2 showed the press does reach the trainer: with nothing
		# reported through the arbiter's `activated` signal, a modal opened a
		# moment later during the re-approach. Give the real press time to
		# open its dialogue; `_talk()` still requires the exact expected
		# conversation to finish, so a wrong provider cannot pass.
		if _activated_id == 0:
			for _frame in 240:
				if _activated_id == expected:
					return true
				if bool(_panel.call("is_open")) and not _fighting():
					_receipt("prompt_press_delayed_dialogue", {"target": str(prompt.get_path()),
						"frames_waited": _frame, "activated_signal": "<none>", "player": _player.global_position})
					return true
				if _fighting() or _activated_id != 0:
					break
				await _tree.physics_frame
		if _activated_id == expected:
			return true
		var side_effect := INPUT_OWNER.current(_tree) != null or _fighting() or bool(_panel.call("is_open"))
		_receipt("prompt_press_retry", {"attempt": attempt + 1, "target": str(prompt.get_path()),
			"activated": _activated_path if _activated_id != 0 else "<nothing>", "side_effect": side_effect,
			"player": _player.global_position})
		if side_effect:
			return _fail("Physical Interact activated %s (not the offered target) and it opened a modal or fight" % _activated_path)
		for _frame in 20:
			await _tree.physics_frame
	return _fail("Physical Interact never activated the exact offered target in %d ordinary presses" % PRESS_TRIES)


## Warden attempt 1 (BLOCKERS.md B7) lost the Warden with the whole belt at 0 HP.
## The helper's own `_prepare()` revived only the pilot it chose, and left
## 7 small potions and 8 revives unused. Before each preparation, give the
## whole belt the same Satchel care `hall_route.gd` uses between fights
## (`care_existing`, the team helper's real Satchel seam): revive every
## fainted member, then a small potion to anyone under WARDEN_CARE_BELOW
## while stock lasts. Disclosed per dose as `pre_warden_bench_care`.
const WARDEN_CARE_BELOW := 0.6


func _prepare() -> bool:
	var party: RefCounted = _game.get("party")
	for pass_item: String in ["revive", "potion_small", "potion_small"]:
		for index in int(party.call("size")):
			var member: RefCounted = party.call("at", index)
			var fainted := bool(member.get("fainted"))
			if _count(pass_item) <= 0:
				break
			if pass_item == "revive" and not fainted:
				continue
			if pass_item == "potion_small" and (fainted \
					or float(member.get("hp")) >= float(member.get("max_hp")) * WARDEN_CARE_BELOW):
				continue
			var before := {"index": index, "species": str(member.get("species_id")), "hp": float(member.get("hp")),
				"max_hp": float(member.get("max_hp")), "fainted": fainted, "item": pass_item}
			var observed: Dictionary = await CARE.new().care_existing(_tree, _world, _game, pass_item, index)
			if not bool(observed.get("passed", false)):
				return _fail("Real Satchel care failed before the Warden: " + str(observed.get("failures", [])))
			before["hp_after"] = float(member.get("hp"))
			_receipt("pre_warden_bench_care", before)
	return await super._prepare()


## B8 (attempts 2-3): after the Warden victory, the production DialoguePanel
## opens and the helper's 120-frame "ordinary world input returned" wait
## expires while it is still open. A player reads it: on the helper's own
## `trainer_defeated` receipt for the Warden, press the real Interact action
## while that panel stays open (as `_drive_machine_to_ceremony` does), and
## record each conversation read as `post_victory_dialogue_read`.
const POST_VICTORY_TAPS := 12


func _receipt(beat: String, detail: Dictionary) -> void:
	super._receipt(beat, detail)
	if beat == "trainer_defeated" and str(detail.get("id", "")) == _warden_id():
		_read_post_victory_dialogue()


func _warden_id() -> String:
	return str((_ending_config.get("warden", {}) as Dictionary).get("trainer", ""))


func _read_post_victory_dialogue() -> void:
	var read: Array[String] = []
	for _frame in 30:
		if bool(_panel.call("is_open")):
			break
		await _tree.physics_frame
	var taps := 0
	while bool(_panel.call("is_open")) and taps < POST_VICTORY_TAPS and not _fighting():
		var conversation := _current_conversation()
		if read.is_empty() or read[-1] != conversation:
			read.append(conversation)
		await _input._tap("interact")
		taps += 1
	print("EARNED WARDEN — ", {"beat": "post_victory_dialogue_read", "conversations": read, "taps": taps,
		"panel_open_after": bool(_panel.call("is_open"))})


func _on_dialogue_finished(id: String) -> void:
	super._on_dialogue_finished(id)
	print("EARNED WARDEN dialogue_finished %s frame=%d" % [id, Engine.get_physics_frames()])
