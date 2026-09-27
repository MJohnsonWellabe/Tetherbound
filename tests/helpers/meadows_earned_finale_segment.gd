extends "res://tests/helpers/meadows_earned_warden_segment.gd"

## M4 (Meadows finale and handoff) as ONE integrated headless piece, from the
## earned `seed4_hall` checkpoint (the smoke's chapter-boundary resume):
##
##   1. the reveal readout and the real Warden fight (controller input, the
##      Hall helper's `_fight_named`), rewards key/heart, shutter open;
##   2. the machine lever and its conversations up to the open Veridian choice;
##      a production save (slot 2) WITH THE CHOICE OPEN; title Load of slot 2
##      brings the same unanswered offer back;
##   3. branch R, at capacity: refuse at the refuse prompt -> legendary_refused,
##      herd display, healing, key/heart; save 3 + title Load 3: same, no
##      re-offer; title Load of the offer-open save with the answered
##      character: still no second offer;
##   4. branch C, at capacity: accept -> farewell ceremony -> let the newcomer
##      go (a refusal), the earned five unchanged;
##   5. branch A, at capacity: accept -> ceremony -> release the lowest-level
##      member for the Veridian; save 3 + title Load 3: the new five persist,
##      no re-offer, no herd display;
##   6. on branch A: walk out of the Hall, the band5 spine back to the Sigil
##      Gate's north point, the storm road north of the gorge, over the rebuilt
##      Rift span into its trigger, production Cloudreach arrival with the
##      same five.
##
## Every walk, prompt, dialogue line and ceremony choice is ordinary injected
## controller input through the inherited helpers. DISCLOSED SHORTCUTS (owner
## ruling 06:55): the run resumes from a declared start save (seed4_hall);
## title Load buttons are pressed by `pressed.emit()` exactly as the smoke's own
## resume does, after the harness changes to the title scene (no in-game quit
## to title is used); branches C and A start from a byte copy of the game's own
## offer-open save files (the portable character file already holds the
## previous branch's answer, and the game correctly refuses a second answer);
## the Kell acknowledgement is skipped (B13, tools/earned_saves/BLOCKERS.md):
## the production Rift needs only `realm_key_cloudreach`; the arrival wait lets
## readiness win on the deadline frame (B16). Nothing writes a flag, party
## member, position or inventory item.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const OFFER_SLOT := 2
const ANSWER_SLOT := 3
const LOAD_FRAMES := 3600
const LOAD_SETTLE_FRAMES := 180
const CHOICE_FRAMES := 2400
const SETTLE_FRAMES := 2400
const NO_REOFFER_FRAMES := 480
const RIFT_READY_FRAMES := 1500
const WARDEN_CARE_BELOW := 0.6
const POST_VICTORY_TAPS := 12
const PRESS_TRIES := 3
const SIGIL_NORTH := Vector2(20.0, 7480.0)
const GORGE_NORTH_Z := 7400.0
const ENDING_FLAGS := ["defeated_warden", "legendary_freed", "legendary_settled", "legendary_joined",
	"legendary_refused", "realm_key_cloudreach", "realm_heart_meadows_earned", "meadows_acknowledged"]

## The smoke's installed scratch save directory (SAVE.new(scratch)).
var save_dir := ""
var _steps: Array[Dictionary] = []
var _check_failures: Array[String] = []
var _disclosures: Array[String] = []
var _max_party := 0
var _frames_watched := 0
var _expected_uids: Array = []
var _identity_open := true
var _identity_mismatch_logged := false
var _watching := false
var _snapshot_dir := ""
var _character := ""
var _activated_path := ""
var _loads := 0
var _started_msec := 0


func run(tree: SceneTree, world: Node3D, game: Node) -> Dictionary:
	_tree = tree
	_game = game
	_started_msec = Time.get_ticks_msec()
	_start_frame_watch()
	_completed = await _run_all(world)
	_stick(0.0, 0.0)
	_disconnect_watches()
	_stop_frame_watch()
	if _max_party > 5:
		_check_failures.append("the party held %d members on some frame" % _max_party)
	_failures.append_array(_check_failures)
	_print_result()
	return result()


func _run_all(world: Node3D) -> bool:
	if save_dir.is_empty():
		return _fail("M4 finale needs the smoke's scratch save directory")
	if not _rebind(world):
		return false
	_character = str((_game.get("local") as RefCounted).get("character_id"))
	var earned := _uids()
	var present: Array = []
	for flag: String in ENDING_FLAGS:
		if _has(flag):
			present.append(flag)
	var arena: Vector3 = _hold.call("marker", "warden_arena")
	_check("0_resume_seed4_hall", "5 earned UIDs at the Warden arena; no Warden/ending flags",
		{"uids": earned, "ending_flags": present, "arena_m": _player.global_position.distance_to(arena)},
		earned.size() == 5 and present.is_empty() and _player.global_position.distance_to(arena) <= 0.6)
	_expected_uids = earned
	_identity_open = false
	if not await _warden():
		return false
	if not await _open_the_offer():
		return false
	if not await _branch_refuse_at_prompt(earned):
		return false
	if not await _branch_ceremony_let_go(earned):
		return false
	var five := await _branch_accept_release_lowest(earned)
	if five.is_empty():
		return false
	return await _walk_to_cloudreach(five)


## --- 1. Warden ------------------------------------------------------------------

func _warden() -> bool:
	var reveal: Dictionary = _ending_config.get("reveal", {})
	if not await _talk(_climax.get_node_or_null("TetherReadout/ReadoutPrompt") as Node3D, str(reveal.get("conversation", ""))) \
			or not _has(str(reveal.get("flag", ""))):
		return _fail("The environmental readout did not deliver the reveal before the Warden")
	var id := _warden_id()
	var warden := _climax.call("warden_body") as Node3D
	if not is_instance_valid(warden) or not await _fight_named(warden, id):
		return false
	var shutter := false
	for _frame in 120:
		if shutter_receipt(_hold, "defeated_warden", true):
			shutter = true
			break
		await _tree.physics_frame
	var rewards := TRAINERS.reward_flags(TRAINERS.trainer(id))
	var missing: Array = []
	for flag: String in ["defeated_warden"] + rewards:
		if not _has(flag):
			missing.append(flag)
	_check("1_warden_fight", "real Warden win: defeated_warden, realm_key_cloudreach, realm_heart_meadows_earned; shutter open; same five",
		{"reward_flags": rewards, "missing": missing, "shutter_open": shutter, "uids": _uids()},
		missing.is_empty() and rewards.has("realm_key_cloudreach") and rewards.has("realm_heart_meadows_earned")
			and shutter and _uids() == _expected_uids)
	return shutter or _fail("The Warden shutter did not open after victory")


## --- 2. Machine, the open offer, save with it open, reload -----------------------

func _open_the_offer() -> bool:
	var crossing_start := Engine.get_physics_frames()
	if not await _walk_marker("warden_arena", ROOM_FRAMES) or not await _walk_final_door(crossing_start):
		return false
	var machine := _climax.get_node_or_null("MachineControl/MachinePrompt") as Node3D
	if machine == null or _has("legendary_freed") or _game.get("pending_catch") != null:
		return _fail("The machine control or the untouched voluntary offer is unavailable")
	var config: Dictionary = _ending_config.get("machine", {})
	var expected: Array[String] = [str(config.get("chamber_conversation", "")), str(config.get("free_conversation", "")),
		str(config.get("join_conversation", "")), _choice_id()]
	if not await _press_prompt(machine) or not await _drive_to_choice("2_machine_to_choice", expected):
		return false
	_check("2_offer_open", "legendary_freed; choice open with both prompts; no answer flag; party 5 unchanged",
		_offer_state(), _offer_is_open_unanswered())
	if not _production_save(OFFER_SLOT):
		return false
	# Byte copy of the game's own offer-open save files, the declared start of
	# branches C and A (see the header).
	_snapshot_dir = save_dir.trim_suffix("/") + "_m4_offer_open"
	if not CHECKPOINTS.copy_tree(save_dir, _snapshot_dir):
		return _fail("Could not copy the offer-open production save")
	_disclose("offer-open production save (slot %d) copied byte-for-byte to %s as the declared start of branches C and A" % [
		OFFER_SLOT, ProjectSettings.globalize_path(_snapshot_dir)])
	if not await _title_load(OFFER_SLOT):
		return false
	var join := str(config.get("join_conversation", ""))
	if not await _drive_to_choice("2_reload_offer", [join, _choice_id()]):
		return false
	_check("2_offer_survives_reload", "title Load of the offer-open save re-offers the same unanswered choice",
		_offer_state(), _offer_is_open_unanswered())
	return true


func _offer_is_open_unanswered() -> bool:
	return _has("legendary_freed") and bool(_climax.call("choice_open")) and _prompt("accept") != null \
		and _prompt("refuse") != null and not _has("legendary_joined") and not _has("legendary_refused") \
		and _game.get("pending_catch") == null and _uids() == _expected_uids


func _offer_state() -> Dictionary:
	return {"legendary_freed": _has("legendary_freed"), "choice_open": bool(_climax.call("choice_open")),
		"accept_prompt": _prompt("accept") != null, "refuse_prompt": _prompt("refuse") != null,
		"joined": _has("legendary_joined"), "refused": _has("legendary_refused"),
		"pending": _game.get("pending_catch") != null, "uids": _uids()}


## --- 3. R: refuse at the prompt, at capacity -------------------------------------

func _branch_refuse_at_prompt(earned: Array) -> bool:
	if not await _answer_at_prompt("refuse") or not await _settle_after_answer("R"):
		return false
	await _verify_refusal("3R_refuse_prompt", earned)
	if not _production_save(ANSWER_SLOT) or not await _title_load(ANSWER_SLOT):
		return false
	await _verify_refusal("3R_after_reload", earned)
	await _no_reoffer("3R_reload_no_reoffer")
	# The same character loaded into the other (offer-open) save: its personal
	# receipt travels with it, so the freeing is not offered a second time.
	if not await _title_load(OFFER_SLOT):
		return false
	await _no_reoffer("3R_offer_save_no_second_grant")
	_check("3R_answer_kept_across_saves", "the offer-open save with the answered character keeps legendary_refused, same five",
		{"refused": _has("legendary_refused"), "joined": _has("legendary_joined"), "uids": _uids()},
		_has("legendary_refused") and not _has("legendary_joined") and _uids() == earned)
	return true


## --- 4. C: accept -> ceremony -> let the newcomer go -----------------------------

func _branch_ceremony_let_go(earned: Array) -> bool:
	if not await _restore_offer_open("4C"):
		return false
	if not await _answer_at_prompt("accept"):
		return false
	_identity_open = false
	if not await _keep_the_earned_five() or not await _settle_after_answer("C"):
		return false
	await _verify_refusal("4C_ceremony_let_newcomer_go", earned)
	return true


## --- 5. A: accept -> ceremony -> release the lowest-level member ----------------

func _branch_accept_release_lowest(earned: Array) -> Array:
	if not await _restore_offer_open("5A"):
		return []
	if not await _answer_at_prompt("accept"):
		return []
	var outgoing := await _release_lowest()
	if outgoing.is_empty() or not await _settle_after_answer("A"):
		return []
	var five := _uids()
	var expected := earned.duplicate()
	expected.erase(str(outgoing.released.uid))
	expected.append(str(outgoing.joined.uid))
	expected.sort()
	_check("5A_party_after_release", "the four earned members kept + the Veridian; the lowest-level member released",
		{"released": outgoing.released, "joined": outgoing.joined, "uids": five}, five == expected)
	_expected_uids = five
	await _verify_accept("5A_accept_release_lowest", five)
	if not _production_save(ANSWER_SLOT) or not await _title_load(ANSWER_SLOT):
		return []
	await _verify_accept("5A_after_reload", five)
	await _no_reoffer("5A_reload_no_reoffer")
	return five


func _release_lowest() -> Dictionary:
	var pending: RefCounted = _game.get("pending_catch")
	var spec: Dictionary = _ending_config.get("legendary", {})
	if not opponent_matches(pending, spec) or _initial_ids.has(pending.get_instance_id()):
		_fail("The pending creature does not match the authored legendary")
		return {}
	var menu: Node = _game.call("menu")
	var tab := _creatures_tab(menu)
	if tab == null:
		_fail("The pending legendary has no production creatures tab")
		return {}
	for _frame in CEREMONY.CEREMONY_FRAMES:
		if bool(menu.call("is_open")) and str(tab.get("_release_stage")) == "choose":
			break
		await _tree.process_frame
	if not bool(menu.call("is_open")) or str(tab.get("_release_stage")) != "choose" \
			or _tree.root.gui_get_focus_owner() != tab.get("_pending_button") or _uids() != _expected_uids:
		_fail("The ceremony did not present the pending legendary beside the unchanged earned five")
		return {}
	var members: Array = (_game.get("party") as RefCounted).call("members")
	var chosen := -1
	for index in members.size():
		if chosen < 0 or int(members[index].get("level")) <= int(members[chosen].get("level")):
			chosen = index
	var outgoing: RefCounted = members[chosen]
	var before := _party_ids()
	var rows: Array = tab.get("_rows")
	_identity_open = true
	for index in chosen + 1:
		await _gui._ceremony_tap("ui_down")
		if _tree.root.gui_get_focus_owner() != rows[index]:
			_fail("Ordinary Down did not reach the chosen outgoing belt row")
			return {}
	await _gui._ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "confirm" or int(tab.get("_release_target")) != chosen \
			or _tree.root.gui_get_focus_owner() != tab.get("_farewell_keep"):
		_fail("The farewell question did not select the chosen member with Keep as default")
		return {}
	await _gui._ceremony_tap("ui_down")
	if _tree.root.gui_get_focus_owner() != tab.get("_farewell_release"):
		_fail("Ordinary Down did not reach the release confirmation")
		return {}
	await _gui._ceremony_tap("ui_accept")
	if str(tab.get("_release_stage")) != "done" or _game.get("pending_catch") != null \
			or not CEREMONY.replacement_receipt(before, _party_ids(), chosen, pending.get_instance_id()):
		_fail("Accepting did not keep the other four and seat the Veridian")
		return {}
	await _gui._ceremony_tap("ui_accept")
	await _gui._ceremony_tap("menu_cancel")
	if bool(menu.call("is_open")) or _tree.paused or _tree.current_scene != _world:
		_fail("The accepted-offer ceremony did not return world control")
		return {}
	_expected_uids = _uids()
	_initial_ids = _party_ids()
	_identity_open = false
	var receipt := {"released": {"uid": str(outgoing.get("uid")), "species": str(outgoing.get("species_id")),
			"level": int(outgoing.get("level")), "index": chosen},
		"joined": {"uid": str(pending.get("uid")), "species": str(pending.get("species_id")), "level": int(pending.get("level"))}}
	_receipt("veridian_accepted_release_lowest", receipt)
	return receipt


## --- 6. Hall exit, storm road, Rift, Cloudreach ----------------------------------

func _walk_to_cloudreach(five: Array) -> bool:
	if not await _prepare():
		return false
	if not await _exit_hall():
		return false
	var road := departure_spine(_read(TERRAIN))
	var entrance: Vector3 = _hold.call("marker", "entrance")
	var from := nearest_index(road, Vector2(entrance.x, entrance.z))
	var to := nearest_index(road, SIGIL_NORTH)
	if road.is_empty() or from < 0 or to < 0 or to > from or road[to].distance_to(SIGIL_NORTH) > 2.0:
		return _fail("The band5 spine no longer runs from the Hall entrance back to the Sigil Gate north point")
	for index in range(from, to - 1, -1):
		if not await _walk_ground(road[index], 1.5 if index == to else SPINE_BEND_RADIUS):
			return false
	var north: Array[Vector2] = []
	for point: Vector2 in storm_road(_read(TERRAIN)).slice(1):
		if point.y > GORGE_NORTH_Z:
			north.append(point)
	_receipt("storm_road_north_of_gorge", {"from": _player.global_position, "points": str(north),
		"reason": "B15: the storm spoke's own road crosses the Sigil Gate gorge; walk its points north of it"})
	for point: Vector2 in north:
		if not await _walk_ground(point):
			return false
	return await _cross_the_rift(five)


## `_cross_the_live_rift` without the helper-only `meadows_acknowledged`
## precondition (B13, tools/earned_saves/BLOCKERS.md: the Kell acknowledgement
## walk is skipped here; production `rift_crossing.gd` admits on
## `Game.can_enter_realm("cloudreach")`, i.e. `realm_key_cloudreach`), and with
## the arrival wait letting readiness win on the deadline frame (B16).
func _cross_the_rift(five: Array) -> bool:
	_disclose("Kell acknowledgement skipped (B13); the Rift precondition meadows_acknowledged is not required by this helper")
	var ready := bool(_rift.call("span_ready"))
	var admitted := bool(_game.call("can_enter_realm", "cloudreach"))
	var openings_before := int(_rift.call("openings"))
	_check("6_rift_ready", "span standing once (openings 1), 0 crossings yet, Cloudreach admitted by the key",
		{"span_ready": ready, "openings": openings_before, "crossings_fired": int(_rift.call("crossings_fired")),
			"can_enter_realm": admitted, "meadows_acknowledged": _has("meadows_acknowledged")},
		ready and admitted and openings_before == 1 and int(_rift.call("crossings_fired")) == 0)
	if not ready or not admitted:
		return _fail("The Rift span or Cloudreach admission is not ready")
	var trigger := _rift.get_node_or_null("RiftCrossingTrigger") as Area3D
	var deck := _rift.get_node_or_null("DeckAnchor/CrossingDeckBody") as StaticBody3D
	if trigger == null or deck == null or not enabled_collision(deck):
		return _fail("The rebuilt Rift lacks its live deck collision or entry trigger")
	var near: Vector3 = _rift.call("near_anchor")
	var far: Vector3 = _rift.call("far_anchor")
	if not await _walk(near, 0.6) or not await _walk(far, 0.6, ROOM_FRAMES):
		return false
	_crossing_player_id = _player.get_instance_id()
	_rift_expected = true
	_watch(trigger, "body_entered", _on_rift_entered)
	var target := trigger.global_position
	target.y = float(_world.call("ground_height_at", target.x, target.z))
	_nav.reset()
	for _frame in ROOM_FRAMES:
		if _rift_crossings >= 1:
			break
		if not is_instance_valid(_player) or not _failures.is_empty() or _fighting():
			return _fail("The Rift approach was interrupted before physical admission")
		_nav.step(target)
		await _tree.physics_frame
	_stick(0.0, 0.0)
	if _rift_crossings < 1:
		return _fail("The player did not physically enter the Rift trigger")
	var start := Time.get_ticks_msec()
	while true:
		if not _failures.is_empty():
			return false
		var scene := _tree.current_scene
		if str(_game.get("current_realm")) == "cloudreach" and scene != null and scene.get_instance_id() != _source_world_id \
				and str(_game.get("pending_realm_entry")).is_empty() \
				and bool(_game.call("_realm_scene_ready", scene, "cloudreach")) and INPUT_OWNER.current(_tree) == null:
			_world = scene as Node3D
			_player = scene.get_node_or_null("Player") as CharacterBody3D
			_rig = scene.get_node_or_null("CameraRig") as Node3D
			var arrived := _uids()
			_check("6_rift_fires_once", "trigger entered once; crossings_fired 1; openings 1",
				{"trigger_entries": _rift_crossings, "crossings_fired": _rift_fired_seen, "openings": _rift_openings_seen},
				_rift_crossings == 1 and _rift_fired_seen == 1 and _rift_openings_seen == 1)
			_check("6_cloudreach_same_five", "realm cloudreach reached by the physical crossing with the recorded five",
				{"realm": str(_game.get("current_realm")), "scene": str(scene.name), "uids": arrived, "expected": five,
					"realm_gate_cloudreach_unlocked": _has("realm_gate_cloudreach_unlocked"),
					"key": _has("realm_key_cloudreach"), "heart": _has("realm_heart_meadows_earned"),
					"legendary_joined": _has("legendary_joined")},
				arrived == five and _player != null and _has("realm_gate_cloudreach_unlocked") \
					and _has("realm_key_cloudreach") and _has("realm_heart_meadows_earned") and _has("legendary_joined"))
			_receipt("cloudreach_arrived", {"uids": arrived, "player": _player.global_position if _player != null else Vector3.INF,
				"trigger_entries": _rift_crossings, "wall_seconds": (Time.get_ticks_msec() - start) / 1000.0})
			return _player != null
		if Time.get_ticks_msec() - start >= ARRIVAL_MSEC:
			break
		await _tree.process_frame
	return _fail("Cloudreach did not complete production arrival within the arrival timeout")


## --- shared driving ----------------------------------------------------------------

## Reads every chamber conversation with Interact until this character's choice
## is open and its read-out closed. `expected` is the exact conversation order.
func _drive_to_choice(label: String, expected: Array[String]) -> bool:
	var first := _finished_dialogues.size()
	for _frame in CHOICE_FRAMES:
		if not _failures.is_empty():
			return false
		var observed: Array = _finished_dialogues.slice(first)
		if not dialogue_prefix(observed, expected):
			return _fail("%s: the chamber conversations diverged: %s (expected %s)" % [label, str(observed), str(expected)])
		if _game.get("pending_catch") != null:
			return _fail("%s: a pending creature arrived before any answer" % label)
		var panel_open := bool(_panel.call("is_open"))
		if not panel_open and bool(_climax.call("choice_open")) and observed == expected:
			return true
		if panel_open and _current_conversation().is_empty():
			await _tree.physics_frame
		elif panel_open:
			if observed.size() >= expected.size() or _current_conversation() != expected[observed.size()]:
				return _fail("%s: unexpected live dialogue %s" % [label, _current_conversation()])
			await _input._tap("interact")
		else:
			await _tree.physics_frame
	return _fail("%s: the choice never opened (stage '%s', read %s)" % [label, str(_climax.get("_stage")),
		str(_finished_dialogues.slice(first))])


func _answer_at_prompt(which: String) -> bool:
	var target := _prompt(which)
	var other := _prompt("refuse" if which == "accept" else "accept")
	if target == null or other == null or not bool(_climax.call("choice_open")):
		return _fail("The open choice lacks its %s prompt" % which)
	var live_here: Array = []
	for prompt: Node3D in [target, other]:
		if not (prompt.call("interaction_offer", _player.global_position) as Dictionary).is_empty():
			live_here.append(str(prompt.name))
	if not live_here.is_empty():
		_check("answer_prompt_not_live_on_arrival", "neither answer is live where the offer landed", live_here, false)
	_receipt("veridian_%s_prompt" % which, {"prompt": str(target.get_path()),
		"distance_m": _player.global_position.distance_to(target.global_position)})
	if not await _press_prompt(target):
		return false
	for _frame in 30:
		if not bool(_climax.call("choice_open")):
			return true
		await _tree.physics_frame
	return _fail("Interact at the %s prompt did not answer the offer" % which)


## After an answer (and its ceremony, if any): read the refusal/machinery
## conversations until the climax reaches `done`.
func _settle_after_answer(label: String) -> bool:
	var failure := str((_ending_config.get("machine", {}) as Dictionary).get("failure_conversation", ""))
	var first := _finished_dialogues.size()
	for _frame in SETTLE_FRAMES:
		if not _failures.is_empty():
			return false
		if str(_climax.get("_stage")) == "done" and not bool(_panel.call("is_open")):
			var read: Array = _finished_dialogues.slice(first)
			_receipt("answer_settled", {"branch": label, "read": read})
			return read.has(failure) or _fail("%s: the machinery-failure conversation was not read" % label)
		if _game.get("pending_catch") != null:
			return _fail("%s: the offer is still parked in the ceremony seam" % label)
		if bool(_panel.call("is_open")) and not _current_conversation().is_empty():
			await _input._tap("interact")
		else:
			await _tree.physics_frame
	return _fail("%s: the answer never settled (stage '%s')" % [label, str(_climax.get("_stage"))])


func _verify_refusal(step: String, earned: Array) -> void:
	await _let_world_settle()
	var herd := await _herd_display(true)
	var receipt := _resolution(false)
	var state := _answer_state(receipt, herd)
	_check(step, "legendary_refused + refused receipt; not joined; same earned five; no Veridian; herd display stands; healing applied; key/heart; Rift open once",
		state, _has("legendary_refused") and not _has("legendary_joined") and _has(receipt) and _uids() == earned
			and _veridians() == 0 and herd and bool(state.healing_applied) and _key_and_heart() and bool(state.rift_ok)
			and _game.get("pending_catch") == null and _has("legendary_settled"))


func _verify_accept(step: String, five: Array) -> void:
	await _let_world_settle()
	var herd := await _herd_display(false)
	var receipt := _resolution(true)
	var state := _answer_state(receipt, herd)
	_check(step, "legendary_joined + accepted receipt; not refused; the new five with one Veridian; no herd display; healing applied; key/heart; Rift open once",
		state, _has("legendary_joined") and not _has("legendary_refused") and _has(receipt) and _uids() == five
			and _veridians() == 1 and not herd and bool(state.healing_applied) and _key_and_heart() and bool(state.rift_ok)
			and _game.get("pending_catch") == null and _has("legendary_settled"))


func _answer_state(receipt: String, herd: bool) -> Dictionary:
	var healing := _world.get_node_or_null("MeadowHealing")
	return {"joined": _has("legendary_joined"), "refused": _has("legendary_refused"), "receipt": receipt,
		"receipt_set": _has(receipt), "settled": _has("legendary_settled"), "uids": _uids(), "veridians": _veridians(),
		"herd_display": herd, "healing_applied": healing != null and bool(healing.call("applied")),
		"healing_report": healing.call("report") if healing != null else {},
		"key": _has("realm_key_cloudreach"), "heart": _has("realm_heart_meadows_earned"),
		"rift_ok": _rift_open_once(), "rift": {"span_ready": bool(_rift.call("span_ready")), "openings": int(_rift.call("openings")),
			"crossings_fired": int(_rift.call("crossings_fired"))},
		"pending": _game.get("pending_catch") != null}


func _rift_open_once() -> bool:
	return bool(_rift.call("span_ready")) and int(_rift.call("openings")) == 1 and int(_rift.call("crossings_fired")) == 0


## The freed-flag span waits out the sky collapse (hold + dissipate + appear)
## after the lever; wait for it (and the healing) the way a player would.
func _let_world_settle() -> void:
	var healing := _world.get_node_or_null("MeadowHealing")
	for _frame in RIFT_READY_FRAMES:
		if bool(_rift.call("span_ready")) and healing != null and bool(healing.call("applied")):
			break
		await _tree.physics_frame


func _herd_display(expected: bool) -> bool:
	var healing := _world.get_node_or_null("MeadowHealing")
	if healing == null:
		return false
	var display: Node3D = null
	for _frame in 90:
		display = healing.call("herd_display") as Node3D
		if expected and display != null:
			break
		await _tree.physics_frame
	if display != null and (display.is_physics_processing() or display.get_node_or_null("Interactable") != null):
		_check("herd_display_inert", "the herd display is not live or interactable", str(display.get_path()), false)
	return display != null


## Stands in the reloaded chamber reading whatever is said: the freeing must not
## be offered again (no join/choice stage, no parked ceremony) and nothing
## about the answer or the belt may change.
func _no_reoffer(step: String) -> void:
	var before := _uids()
	var joined := _has("legendary_joined")
	var refused := _has("legendary_refused")
	var stages: Array = []
	var reoffered := false
	for _frame in NO_REOFFER_FRAMES:
		var stage := str(_climax.get("_stage"))
		if not stages.has(stage):
			stages.append(stage)
		if stage in ["join", "choice"] or _game.get("pending_catch") != null:
			reoffered = true
		if bool(_panel.call("is_open")) and not _current_conversation().is_empty():
			await _input._tap("interact")
		else:
			await _tree.physics_frame
	var near := _player.global_position.distance_to(_climax.global_position) if _climax != null else -1.0
	_check(step, "standing in the chamber for %d frames: no join/choice/ceremony, answer and belt unchanged" % NO_REOFFER_FRAMES,
		{"stages_seen": stages, "reoffered": reoffered, "uids": _uids(), "joined": _has("legendary_joined"),
			"refused": _has("legendary_refused"), "player_to_climax_m": near},
		not reoffered and _uids() == before and _has("legendary_joined") == joined and _has("legendary_refused") == refused)


## --- saves and loads ---------------------------------------------------------------

func _production_save(slot: int) -> bool:
	var ok := bool(_game.call("save_game", slot))
	_receipt("production_save", {"slot": slot, "saved": ok, "choice_open": bool(_climax.call("choice_open")),
		"stage": str(_climax.get("_stage")), "uids": _uids()})
	return ok or _fail("Game.save_game(%d) refused" % slot)


func _restore_offer_open(label: String) -> bool:
	if not await _to_title():
		return false
	var saver: RefCounted = _game.get("save_system")
	for _frame in 600:
		if saver == null or not saver.has_method("fallback_busy") or not bool(saver.call("fallback_busy")):
			break
		await _tree.process_frame
	# Restored and loaded in the same frame: no autosave tick can land between.
	if not CHECKPOINTS.copy_tree(_snapshot_dir, save_dir):
		return _fail("%s: could not restore the offer-open production save" % label)
	_disclose("%s: started from the byte-copied offer-open production save (declared start save)" % label)
	if not await _load_from_title(OFFER_SLOT):
		return false
	var join := str((_ending_config.get("machine", {}) as Dictionary).get("join_conversation", ""))
	if not await _drive_to_choice(label + "_reoffer", [join, _choice_id()]):
		return false
	_check(label + "_offer_restored", "the declared offer-open start re-offers the unanswered choice to the same five",
		_offer_state(), _offer_is_open_unanswered())
	return true


func _title_load(slot: int) -> bool:
	return await _to_title() and await _load_from_title(slot)


func _to_title() -> bool:
	_stick(0.0, 0.0)
	_disconnect_watches()
	_identity_open = true
	if _tree.change_scene_to_file(TITLE_SCENE) != OK:
		return _fail("The harness could not change to the title scene")
	for _frame in 240:
		await _tree.process_frame
		var scene := _tree.current_scene
		if scene != null and scene.scene_file_path == TITLE_SCENE and scene.get("_load_button") != null:
			for _settle in 10:
				await _tree.process_frame
			return true
	return _fail("The title scene never became current")


func _load_from_title(slot: int) -> bool:
	var title := _tree.current_scene
	var load_button := title.get("_load_button") as Button
	if load_button == null:
		return _fail("The title has no Load button")
	load_button.pressed.emit()
	await _tree.process_frame
	var chosen: Button = null
	for node: Node in (title.get("_load_box") as Node).get_children():
		if node is Button and (node as Button).text.begins_with("Save %d" % slot) and not (node as Button).disabled:
			chosen = node
	if chosen == null:
		return _fail("The title's Load list does not offer Save %d" % slot)
	chosen.pressed.emit()
	var world: Node = null
	for _frame in LOAD_FRAMES:
		await _tree.process_frame
		var scene := _tree.current_scene
		if scene != null and scene != title and is_instance_valid(scene) and scene.get_node_or_null("Player") != null \
				and str(_game.get("pending_realm_entry")).is_empty() \
				and bool(_game.call("_realm_scene_ready", scene, str(_game.get("current_realm")))):
			world = scene
			break
	if world == null or str(_game.get("current_realm")) != "meadows":
		return _fail("Title Load of Save %d never reached a ready Meadows world" % slot)
	for _frame in LOAD_SETTLE_FRAMES:
		await _tree.physics_frame
	_loads += 1
	if not _rebind(world as Node3D):
		return false
	var loaded := _uids()
	_receipt("title_load", {"slot": slot, "uids": loaded, "player": _player.global_position,
		"stage": str(_climax.get("_stage")), "loads": _loads})
	if loaded != _expected_uids:
		_check("title_load_%d_party" % _loads, "the loaded party is the saved five", {"loaded": loaded, "saved": _expected_uids}, false)
	_identity_open = false
	return true


## Binds the live nodes of the current Meadows world (again after each load).
func _rebind(world: Node3D) -> bool:
	_disconnect_watches()
	_world = world
	_source_world_id = world.get_instance_id()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_hold = world.get_node_or_null("Stronghold") as Node3D
	_climax = world.get_node_or_null("StrongholdClimax") as Node3D
	_rift = world.get_node_or_null("RiftCrossing") as Node3D
	_panel = world.get_node_or_null("DialoguePanel")
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = _tree.get_first_node_in_group("interaction_arbiter")
	if _player == null or _rig == null or _hold == null or _climax == null or _rift == null \
			or _panel == null or _director == null or _combat == null or _arbiter == null:
		return _fail("The live Hall, climax, Rift or input dependencies are missing")
	_initial_ids = _party_ids()
	_hall_config = _read(HALL_CONFIG)
	_ending_config = _read(CLIMAX_CONFIG)
	_supported_y = (_hold.call("marker", "warden_arena") as Vector3).y
	_input = INPUTS.new()
	_input._tree = _tree
	_gui = CEREMONY.new()
	_gui._tree = _tree
	_nav = NAV.new(_tree, _player, _rig, _stick)
	_watch(_combat, "entered", _on_entered)
	_watch(_combat, "hit_landed", _on_hit)
	_watch(_combat, "exited", _on_exit)
	_watch(_panel, "finished", _on_dialogue_finished)
	_watch(_arbiter, "activated", _on_activated)
	return true


## --- every-frame party watch ---------------------------------------------------------

func _start_frame_watch() -> void:
	if _watching:
		return
	_watching = true
	_tree.process_frame.connect(_frame_watch)
	_tree.physics_frame.connect(_frame_watch)


func _stop_frame_watch() -> void:
	if not _watching:
		return
	_watching = false
	if _tree.process_frame.is_connected(_frame_watch):
		_tree.process_frame.disconnect(_frame_watch)
	if _tree.physics_frame.is_connected(_frame_watch):
		_tree.physics_frame.disconnect(_frame_watch)


func _frame_watch() -> void:
	var party: RefCounted = _game.get("party") if is_instance_valid(_game) else null
	if party == null:
		return
	_frames_watched += 1
	var size := int(party.call("size"))
	if size > _max_party:
		_max_party = size
		if size > 5:
			print("M4 FAIL — the party holds %d on frame %d" % [size, Engine.get_process_frames()])
	if not _identity_open and not _expected_uids.is_empty() and not _identity_mismatch_logged and _uids() != _expected_uids:
		_identity_mismatch_logged = true
		_check_failures.append("the party changed outside an answer/ceremony/load window: %s (expected %s)" % [str(_uids()), str(_expected_uids)])
		print("M4 FAIL — party changed outside an allowed window: ", _uids(), " expected ", _expected_uids)


## --- overrides of inherited helpers ----------------------------------------------

## Base `_keep_the_earned_five` (let the newcomer go) with its identity window.
func _keep_the_earned_five() -> bool:
	_identity_open = true
	var ok := await super._keep_the_earned_five()
	_identity_open = false
	return ok and _uids() == _expected_uids


## The same pre-Warden whole-belt Satchel care as tools/earned_saves/warden_accept.gd
## (B7): revive every fainted member, then a small potion to anyone under
## WARDEN_CARE_BELOW while stock lasts, through the real Satchel seam.
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
				return _fail("Real Satchel care failed: " + str(observed.get("failures", [])))
			before["hp_after"] = float(member.get("hp"))
			_receipt("bench_care", before)
	return await super._prepare()


## warden_accept.gd's disclosed prompt press (B4): a press whose dialogue opens
## a moment later is accepted; any other provider is a failure.
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
		if _activated_id == 0:
			for _frame in 240:
				if _activated_id == expected:
					return true
				if bool(_panel.call("is_open")) and not _fighting():
					_receipt("prompt_press_delayed_dialogue", {"target": str(prompt.get_path()), "frames_waited": _frame})
					return true
				if _fighting() or _activated_id != 0:
					break
				await _tree.physics_frame
		if _activated_id == expected:
			return true
		var side_effect := INPUT_OWNER.current(_tree) != null or _fighting() or bool(_panel.call("is_open"))
		_receipt("prompt_press_retry", {"attempt": attempt + 1, "target": str(prompt.get_path()),
			"activated": _activated_path if _activated_id != 0 else "<nothing>", "side_effect": side_effect})
		if side_effect:
			return _fail("Interact activated %s (not the offered target) and it opened a modal or fight" % _activated_path)
		for _frame in 20:
			await _tree.physics_frame
	return _fail("Interact never activated the exact offered target in %d presses" % PRESS_TRIES)


## Read the production counters inside the same `body_entered` dispatch,
## after `rift_crossing.gd`'s own handler (connected first) has fired, while
## the outgoing world still exists.
var _rift_fired_seen := -1
var _rift_openings_seen := -1


func _on_rift_entered(body: Node3D) -> void:
	super._on_rift_entered(body)
	if is_instance_valid(_rift):
		_rift_fired_seen = int(_rift.call("crossings_fired"))
		_rift_openings_seen = int(_rift.call("openings"))


func _on_activated(provider: Object) -> void:
	super._on_activated(provider)
	_activated_path = str((provider as Node).get_path()) if provider is Node and is_instance_valid(provider) else str(provider)


## B8: the Warden victory's dialogue outlasts the Hall helper's 120-frame
## input-return wait; read it with Interact as warden_accept.gd does.
func _receipt(beat: String, detail: Dictionary) -> void:
	super._receipt(beat, detail)
	if beat == "trainer_defeated" and str(detail.get("id", "")) == _warden_id():
		_read_post_victory_dialogue()


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
	print("EARNED WARDEN — ", {"beat": "post_victory_dialogue_read", "conversations": read, "taps": taps})


## Not the Warden helper's retained-five/world watch: this piece changes worlds
## by title Load on purpose; `_frame_watch` checks the party on every frame.
func _observe_retained_party() -> void:
	pass


func _ending_ready() -> bool:
	return _has("defeated_warden") and _has("legendary_freed") and _has("legendary_settled") \
		and _has("realm_key_cloudreach") and _has("realm_heart_meadows_earned") and _game.get("pending_catch") == null


## --- small readers -------------------------------------------------------------

func _uids() -> Array:
	var out: Array = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		out.append(str(member.get("uid")))
	out.sort()
	return out


func _veridians() -> int:
	var n := 0
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		if str(member.get("species_id")) == "veridian":
			n += 1
	return n


func _key_and_heart() -> bool:
	return _has("realm_key_cloudreach") and _has("realm_heart_meadows_earned") and _has("defeated_warden") \
		and _has("legendary_freed")


func _resolution(accepted: bool) -> String:
	return str(_climax.call("resolution_flag", accepted, _character if not _character.is_empty() else "solo"))


func _prompt(which: String) -> Node3D:
	var node := _climax.find_child("VeridianAcceptPrompt" if which == "accept" else "VeridianRefusePrompt", true, false) as Node3D
	return node if node != null and not node.is_queued_for_deletion() else null


func _choice_id() -> String:
	return str((_ending_config.get("choice", {}) as Dictionary).get("conversation", ""))


func _warden_id() -> String:
	return str((_ending_config.get("warden", {}) as Dictionary).get("trainer", ""))


func _creatures_tab(menu: Node) -> Node:
	if menu == null:
		return null
	for index in (menu.get("_tabs") as Array).size():
		if str(menu.get("_tabs")[index].get("id", "")) == "creatures":
			return menu.get("_bodies")[index]
	return null


func _disclose(text: String) -> void:
	if not _disclosures.has(text):
		_disclosures.append(text)
	print("M4 DISCLOSED — ", text)


func _check(step: String, expected: Variant, observed: Variant, ok: bool) -> void:
	_steps.append({"step": step, "expected": expected, "observed": observed, "pass": ok})
	print("M4 %s %s expected=%s observed=%s" % ["PASS" if ok else "FAIL", step, str(expected), JSON.stringify(observed)])
	if not ok:
		_check_failures.append("M4 step failed: " + step)


func _print_result() -> void:
	var passed := 0
	for row: Dictionary in _steps:
		if bool(row.pass):
			passed += 1
	print("M4 RESULT " + JSON.stringify({"passed": _completed and _failures.is_empty(), "completed": _completed,
		"steps_passed": passed, "steps_total": _steps.size(), "max_party_size_any_frame": _max_party,
		"frames_watched": _frames_watched, "title_loads": _loads, "wall_seconds": (Time.get_ticks_msec() - _started_msec) / 1000.0,
		"steps": _steps, "disclosures": _disclosures, "failures": _failures}))


const CHECKPOINTS := preload("res://tests/helpers/four_biome_checkpoints.gd")
