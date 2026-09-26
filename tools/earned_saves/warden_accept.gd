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
var _ending_settled := false
var _road_care := false


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
	if beat == "meadows_ending_settled":
		_ending_settled = true
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


## B9 (attempt 5): the machine's chamber -> free -> join conversations all
## finished in order (dialogue_finished at frames 8088/8111/8127), but between
## conversations the production DialoguePanel stays open for a few frames with
## an EMPTY conversation id (8089-8096, 8128-8132). The helper's loop reads that
## hand-over frame as "an unexpected live dialogue". This copy of
## `_drive_machine_to_ceremony` waits a frame on an open panel with no
## conversation yet. B10 (attempt 6): production now follows the join with
## the F05 `veridian_choice` read-out and two spatial prompts
## (stronghold_climax.json `choice`); the helper predates it. The copy reads
## that conversation and then answers ACCEPT the way smoke_gate_e_finale.gd
## does: step to `VeridianAcceptPrompt` and press the real Interact
## (`_press_prompt`, exact-provider checked). Receipt `veridian_accept_prompt`.
func _drive_machine_to_ceremony(expected: Array[String], first: int) -> bool:
	var choice := str((_ending_config.get("choice", {}) as Dictionary).get("conversation", ""))
	var start := Engine.get_physics_frames()
	var pressed_accept := false
	while Engine.get_physics_frames() - start < SEQUENCE_FRAMES:
		var observed: Array = _finished_dialogues.slice(first)
		var story: Array = observed.slice(0, expected.size())
		var tail: Array = observed.slice(expected.size())
		if not dialogue_prefix(story, expected) or not (tail.is_empty() or tail == [choice]) or not _failures.is_empty():
			return _fail("The machine's real conversations diverged from chamber/free/join(/choice) order: " + str(observed))
		if _game.get("pending_catch") != null:
			return story == expected and pressed_accept and _has("legendary_freed") \
				and str(_climax.get("_stage")) == "ceremony" \
				or _fail("The voluntary pending creature arrived before the complete authored join sequence")
		if bool(_panel.call("is_open")) and _current_conversation().is_empty():
			await _tree.physics_frame
		elif bool(_panel.call("is_open")):
			var wanted: String = expected[observed.size()] if observed.size() < expected.size() else choice
			if (observed.size() >= expected.size() and not tail.is_empty()) or _current_conversation() != wanted:
				return _fail("An unexpected live dialogue interrupted the machine sequence: " + _current_conversation())
			await _input._tap("interact")
		elif story == expected and tail == [choice] and not pressed_accept and bool(_climax.call("choice_open")):
			# F05 accept, as a player: the read-out named both answers; step to
			# the creature's shoulder prompt and press the real Interact.
			var accept := _climax.find_child("VeridianAcceptPrompt", true, false) as Node3D
			if accept == null:
				return _fail("The Veridian choice opened without its accept prompt")
			_receipt("veridian_accept_prompt", {"prompt": str(accept.get_path()),
				"distance_m": _player.global_position.distance_to(accept.global_position)})
			if not await _press_prompt(accept):
				return false
			pressed_accept = true
		else:
			await _tree.physics_frame
	return _fail("The machine never reached its real five-slot ceremony within the existing story budget")



## B11 (attempt 7): after the ending, the acknowledgement walk is 11.4 km of
## road back to the village. The helper gives no care between road fights, and
## one ordinary wild fight ran out its budget with two members fainted
## (`Real wild combat did not win with landed strikes inside its unchanged
## physics budget`, player (164,-0.2,4565)). This is the hall_route.gd B5 remedy
## (`between_fight_care`), applied only after `meadows_ending_settled`, out of
## combat and with no modal open. Revive the fainted and give a small potion to
## anyone under ROAD_CARE_BELOW while stock lasts, each through the real
## Satchel seam, then the helper's own `_prepare()` for pilot selection.
const ROAD_CARE_BELOW := 0.4


func _walk(target: Vector3, radius: float = 1.5, budget: int = -1) -> bool:
	if _ending_settled and not _road_care and not _fighting() and INPUT_OWNER.current(_tree) == null:
		_road_care = true
		var ok := await _road_bench_care()
		_road_care = false
		if not ok:
			return false
	return await super._walk(target, radius, budget)


func _road_bench_care() -> bool:
	var party: RefCounted = _game.get("party")
	var acted := false
	for index in int(party.call("size")):
		var member: RefCounted = party.call("at", index)
		var item := ""
		if bool(member.get("fainted")) and _count("revive") > 0:
			item = "revive"
		elif not bool(member.get("fainted")) and _count("potion_small") > 0 \
				and float(member.get("hp")) < float(member.get("max_hp")) * ROAD_CARE_BELOW:
			item = "potion_small"
		if item.is_empty():
			continue
		var before := {"index": index, "species": str(member.get("species_id")), "hp": float(member.get("hp")),
			"max_hp": float(member.get("max_hp")), "fainted": bool(member.get("fainted")), "item": item}
		var observed: Dictionary = await CARE.new().care_existing(_tree, _world, _game, item, index)
		if not bool(observed.get("passed", false)):
			return _fail("Real Satchel care failed on the acknowledgement road: " + str(observed.get("failures", [])))
		before["hp_after"] = float(member.get("hp"))
		_receipt("between_fight_care", before)
		acted = true
	if acted:
		return await super._prepare()
	return true


## B12 (attempt 9): the trainer died on the acknowledgement road. The helper's
## `aftermath_road` walks band2 straight from (-330,2630) to (-420,2470),
## across the Warrens mound. The forward chain never walked that leg: warrens
## and relay took `warren_undertrail`, west of the mound (warrens_route.gd B3
## detour). Coordinator ruling: walk the return along the forward roads,
## reversed. This copy of `_acknowledge_and_cross` differs from the helper in
## three ways: (1) the band2 leg between the undertrail's two band2 joins is
## replaced by the undertrail plus the B3 west-of-mound detour, and the whole
## road is still walked in reverse; (2) whole-belt care (`_prepare()`) runs
## before the walk; (3) a death watch (below) logs every trainer health loss
## with its cause. The acknowledgement talk, gate checks, storm road and
## physical Rift crossing are unchanged.
const WARRENS_ROUTE := preload("res://tools/earned_saves/warrens_route.gd")


static func forward_return_road(road: Array[Dictionary], undertrail: Array[Vector2]) -> Array[Dictionary]:
	if undertrail.size() < 2:
		return []
	var points := road_points(road)
	var start := nearest_index(points, undertrail[0])
	var finish := nearest_index(points, undertrail[-1])
	if start < 0 or finish <= start or points[start].distance_to(undertrail[0]) > 0.5 \
			or points[finish].distance_to(undertrail[-1]) > 0.5:
		return []
	for index in range(start + 1, finish):
		if road[index].has("gate"):
			return []
	var middle: Array[Dictionary] = []
	for point: Vector2 in WARRENS_ROUTE.MOUND_WEST_DETOUR:
		middle.append({"at": point, "source": "warrens_route B3 detour"})
	for index in range(1, undertrail.size() - 1):
		middle.append({"at": undertrail[index], "source": "warren_undertrail"})
	var out: Array[Dictionary] = []
	out.append_array(road.slice(0, start + 1))
	out.append_array(middle)
	out.append_array(road.slice(finish))
	return out


func _acknowledge_and_cross() -> bool:
	_arm_death_watch()
	if not _ending_ready() or not await _exit_hall():
		return false
	if not await _prepare():
		return false
	var terrain := _read(TERRAIN)
	var gates := _open_crossings(terrain)
	var spine_road := aftermath_road(terrain, gates)
	var road := forward_return_road(spine_road, trail_points(terrain, "loops", "warren_undertrail"))
	var kell := _world.get_node_or_null("VillageNPCs/Kell") as Node3D
	var kell_spec := acknowledgement_spec(_read(NPC_CONFIG), _read(FREED_DIALOGUE))
	if gates.size() != 3 or road.is_empty() or kell == null or kell_spec.is_empty():
		return _fail("The actual acknowledgement actor or forward-road return route is unavailable")
	if NPCS.greeting_for(kell_spec, _game.get("progression")) != "spoke_traveller_storm_road":
		return _fail("The real acknowledgement actor is not offering its authored post-win branch")
	var points := road_points(road)
	var join := nearest_index(points, Vector2(_player.global_position.x, _player.global_position.z))
	_receipt("acknowledgement_backtrack_started", {"road_metres_one_way": road_length(points), "target": kell.global_position,
		"reason": "actual acknowledgement remains at the village; no earned fast travel exists",
		"route": "forward roads reversed (B12): band5/4/3 + relay loop, warren_undertrail with B3 detour, band2/band1",
		"spine_entries": spine_road.size(), "entries": road.size()})
	for index in range(join, -1, -1):
		_leg_target = points[index]
		if not await _walk_road_entry(road[index]):
			return false
	if not await _talk(kell.get_node_or_null("Interactable") as Node3D, str(kell_spec.greeting)) \
			or not _has("meadows_acknowledged") or not retained_five(_initial_ids, _party_ids()):
		return _fail("The actual return greeting did not earn Meadows acknowledgement with the retained five")
	_receipt("meadows_acknowledged", {"actor": kell.name, "conversation": _dialogue_finished, "player": _player.global_position})
	var storm := storm_road(terrain)
	if storm.is_empty():
		return _fail("The actual rebuilt storm-road approach is missing")
	var storm_join := nearest_index(points, storm[0])
	for index in range(storm_join + 1):
		_leg_target = points[index]
		if not await _walk_road_entry(road[index]):
			return false
	for point: Vector2 in storm.slice(1):
		_leg_target = point
		if not await _walk_ground(point):
			return false
	return await _cross_the_live_rift()


## Death watch (B12 root cause): every drop in the trainer's health is logged
## with position, the last floor height and the fall since, the last `landed`
## impact, whether a fight is on, and the leg being walked. On `died`, a
## summary line names the cause: "fall" when a damaging landing happened in the
## same frame, "combat" when fighting, otherwise "hazard (water/other)".
var _death_armed := false
var _leg_target := Vector2.INF
var _last_health := -1.0
var _last_floor_y := NAN
var _last_landing := {}
var _health_events := 0


func _arm_death_watch() -> void:
	if _death_armed or _player == null:
		return
	_death_armed = true
	_last_health = float((_player.get("vitals") as RefCounted).get("health"))
	_watch(_player, "landed", _on_player_landed)
	_watch(_player, "died", _on_player_died)
	_watch(_tree, "physics_frame", _death_watch_tick)


func _on_player_landed(impact_speed: float, damage: float) -> void:
	_last_landing = {"frame": Engine.get_physics_frames(), "impact_speed": impact_speed, "damage": damage,
		"fall_m": (_last_floor_y - _player.global_position.y) if not is_nan(_last_floor_y) else NAN,
		"at": _player.global_position}
	if damage > 0.0:
		print("EARNED DEATHWATCH landing ", _last_landing)


func _death_watch_tick() -> void:
	if not is_instance_valid(_player):
		return
	if _player.is_on_floor():
		_last_floor_y = _player.global_position.y
	var health := float((_player.get("vitals") as RefCounted).get("health"))
	if health < _last_health - 0.01 and _health_events < 400:
		_health_events += 1
		var landed_now: bool = not _last_landing.is_empty() and Engine.get_physics_frames() - int(_last_landing.frame) <= 1
		print("EARNED DEATHWATCH health %.1f -> %.1f at %s cause=%s fighting=%s floor=%s leg=%s" % [_last_health, health,
			_player.global_position, "fall" if landed_now else ("combat" if _fighting() else "hazard(water/other)"),
			_fighting(), _player.is_on_floor(), _leg_target])
	_last_health = health


func _on_player_died() -> void:
	var landed_now: bool = not _last_landing.is_empty() and Engine.get_physics_frames() - int(_last_landing.frame) <= 1
	var cause := "fall" if landed_now and float(_last_landing.damage) > 0.0 else ("combat" if _fighting() else "hazard(water/other)")
	print("EARNED DEATHWATCH DIED cause=%s at=%s last_floor_y=%s last_landing=%s fighting=%s leg=%s frame=%d" % [
		cause, _player.global_position, _last_floor_y, _last_landing, _fighting(), _leg_target, Engine.get_physics_frames()])
	_fail("The trainer died on the acknowledgement road (cause %s at %s); see EARNED DEATHWATCH" % [cause, _player.global_position])
