extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F05 / card M4, ACCEPTANCE §6.1: **MIXED TWO-PEER VERIDIAN CHOICES, WITH A
## DISCONNECT AT THE CLAIM ACKNOWLEDGEMENT.**
##
##   tools/net/run_net_smoke.sh veridian_choices
##   (or: ~/godot-bin/godot --headless --path . --script tests/smoke_net_veridian_choices.gd)
##
## IN CI. Its `# peers: 2` header puts it in `.github/workflows/ci.yml`'s
## `discover-net-smokes` list, and `verify-multiplayer-shard` runs it in
## **shard 3 of 7** (the plan on the current tree: "plan shard 3/7: ...
## tests/smoke_net_veridian_choices.gd ..."). That shard is assigned by the
## job's longest-first cost plan, not pinned, and this file has no measured
## cost there yet (it reserves the 168 s fallback), so a new net smoke can
## move it to another shard. It fights the Warden, walks the chamber and
## rebuilds the Meadows on a production rejoin, so it is one of the longer
## smokes in its shard.
##
## ## What it proves
##
## Two real peers, each playing its own SAVED character, fight the Warden
## together; the guest frees the Veridian Stag at the machine; each
## participant then gets its OWN offer, answered through the in-world prompts
## with `interact`:
##
##   * the HOST walks to `VeridianRefusePrompt` and refuses;
##   * the GUEST walks to `VeridianAcceptPrompt` and accepts, and its link is
##     cut IMMEDIATELY after that press -- the claim acknowledgement, where
##     `stronghold_climax.gd::_record_resolution()` writes the client's
##     character file. Its in-memory character is then wiped, so the file is
##     the only copy, and it rejoins by the same character id through the
##     production join.
##
## Afterwards, on each peer separately and again after a production
## save/reload on both:
##
##   * the guest holds exactly ONE Veridian (party 5), `legendary_joined`, no
##     `legendary_refused`, and is never offered again;
##   * the host holds none (party 4), `legendary_refused`, no `legendary_joined`;
##   * BOTH worlds hold exactly the receipts
##     `legendary_resolution:accepted:<guest>`, `...:refused:<host>` and
##     `legendary_resolution:live` -- no duplicate, no foreign id;
##   * the herd display is absent on both (a mixed answer is not a full refusal);
##   * `legendary_freed`, `realm_key_cloudreach` and
##     `realm_gate_cloudreach_unlocked` are world facts on both: one shared
##     healing/relic/key, not one per answer.
##
## ## DISCLOSED FIXTURES
##
##   * `party_grant`: each peer is handed four level-18 creatures
##     (`smoke_net_shared_boss.gd`'s HANDOFF_PARTY) so there is room on the belt.
##     Nothing was caught or earned on the way here.
##   * Arena seating: both peers are placed in the Warden arena with
##     `explore_at`, as `smoke_net_shared_boss.gd --handoff` does. There is NO
##     earned route to the Warden in this file; the Hall gauntlet and the
##     Meadows spine belong to other witnesses.
##   * The Warden is won with `win_trainer_battle`, the same step-driven fight
##     the handoff leg uses.
##   * Walks after the seat are teleport-free but step-driven (`move_to`, a
##     stick navigator), and every answer is a real `interact` press on the
##     live prompt. Dialogue is cleared with `dismiss_dialogue` presses.
##   * The disconnect is `drop_link` + `leave`, the pair
##     `smoke_net_reconnect_keeps_character.gd` documents as the production
##     dead-link path; `wipe_character` blanks the process between drop and
##     rejoin.

const HANDOFF_PARTY := ["terrapup", "bramblebun", "trailpup", "mudsnout"]
const WARDEN_TRAINER := "warden_aldis"
const BATTLE_FRAMES := 5400
const ENEMY_HP_CEILING := 6.0
const GUEST_NAME := "Veridian Guest"
const RECEIPT_LIVE := "legendary_resolution:live"
const WORLD_FACTS := ["legendary_freed", "realm_key_cloudreach"]
## Written only by `realm_gate.gd::try_unlock()` at the physical Cloudreach
## gate, which this witness never walks to. Reported, and required to AGREE on
## both peers (one shared world), but not required to be set here.
const GATE_FLAG := "realm_gate_cloudreach_unlocked"
## Bounded budget for reaching an open choice: probe + dismiss iterations.
const CHOICE_POLLS := 60
## Iterations of (probe, dismiss 4 presses + 30 settle) after rejoin, ~600 frames.
const NO_REOFFER_POLLS := 20

var _host_id := ""
var _guest_id := ""
var _port := 0


func _init_budgets() -> void:
	super._init_budgets()
	# A Warden fight, a chamber walk, a production rejoin (a Meadows rebuild)
	# and two reloads. Gameplay bounds (frame budgets, reach) are untouched.
	_budgets["smoke_step_budget_s_2peer"] = 2400.0
	_budgets["hello_budget_s"] = 360.0


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	_port = int(host_hello.get("enet_port", 0))
	check(_port > 0, "host reported its ENet port in hello (%d)" % _port)
	if _port <= 0:
		quit(await finish())
		return

	# 1. Two saved characters, each with four creatures (room for a fifth).
	for peer in 2:
		for species: String in HANDOFF_PARTY:
			var granted: Dictionary = await step(peer, "party_grant", {"species": species, "level": 18})
			check(str(granted.get("verdict", "")) == "PASS",
				"FIXTURE: peer %d received a level-18 %s" % [peer, species])
	var host_saved: Dictionary = await step(0, "save_character_here", {})
	var guest_saved: Dictionary = await step(1, "save_character_here", {})
	_host_id = str((host_saved.get("data", {}) as Dictionary).get("character_id", ""))
	_guest_id = str((guest_saved.get("data", {}) as Dictionary).get("character_id", ""))
	check(not _host_id.is_empty() and not _guest_id.is_empty() and _host_id != _guest_id,
		"both homes autosaved distinct stable characters (host '%s', guest '%s')" % [_host_id, _guest_id])
	if _host_id.is_empty() or _guest_id.is_empty() or _host_id == _guest_id:
		quit(await finish())
		return

	# 2. The session: production host, guest joins from its saved file.
	await _diagnose_guest_slot("after the seed saves")
	var hosted: Dictionary = await step(0, "host", {"port": _port})
	check(str(hosted.get("verdict", "")) == "PASS", "peer 0 hosted (%s)" % str(hosted.get("detail", "")))
	var joined: Dictionary = await step(1, "join",
		{"host": "127.0.0.1", "port": _port,
		 "character": {"character_id": _guest_id, "display_name": GUEST_NAME}}, 6000)
	check(str(joined.get("verdict", "")) == "PASS", "peer 1 joined as '%s' (%s)"
		% [_guest_id, str(joined.get("detail", ""))])
	if str(hosted.get("verdict", "")) != "PASS" or str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	for peer in 2:
		var start: Dictionary = await _choice(peer)
		check(int(start.get("party_size", -1)) == 4 and int(start.get("veridian_count", -1)) == 0,
			"peer %d starts with four creatures and no Veridian (%s)" % [peer, str(start)])
		await step(peer, "deploy_creature", {})

	# 3. The Warden, shared (smoke_net_shared_boss.gd::_run_chapter_handoff).
	var hold: Variant = await probe(0, "stronghold")
	var markers: Dictionary = (hold as Dictionary).get("markers", {}) as Dictionary if hold is Dictionary else {}
	var arena: Array = _marker(markers, "warden_arena")
	var control: Array = _marker(markers, "machine_foot")
	if control.size() != 3 and hold is Dictionary:
		control = ((hold as Dictionary).get("machine_at", []) as Array)
	check(arena.size() == 3 and control.size() == 3, "the Hall names its Warden arena and machine control")
	if arena.size() != 3 or control.size() != 3:
		quit(await finish())
		return
	for peer in 2:
		await step(peer, "explore_at",
			{"at": [float(arena[0]) + (2.0 if peer == 1 else -2.0), float(arena[2])], "settle": 60})
	var began: Dictionary = await step(0, "trainer_battle", {"trainer": WARDEN_TRAINER, "settle": 45})
	check(str(began.get("verdict", "")) == "PASS", "host challenged the Warden (%s)" % str(began.get("detail", "")))
	if str(began.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var record = await probe(0, "encounter")
	var encounter_id := str((record as Dictionary).get("id", "")) if record is Dictionary else ""
	var guest_in: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(str(guest_in.get("verdict", "")) == "PASS", "guest joined the Warden's own fight")
	var won: Dictionary = await step(0, "win_trainer_battle",
		{"budget_frames": BATTLE_FRAMES, "enemy_hp_ceiling": ENEMY_HP_CEILING}, BATTLE_FRAMES)
	check(str(won.get("verdict", "")) == "PASS", "both peers felled the Warden (%s)" % str(won.get("detail", "")))
	if str(won.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	for peer in 2:
		await step(peer, "wait", {"frames": 120})
		await step(peer, "dismiss_dialogue", {"presses": 40, "settle": 30})

	var control_at := Vector3(float(control[0]), float(control[1]), float(control[2]))
	# 3b. The host walks into the chamber BEFORE the lever. Walking in after
	# it is a harness trap, measured twice (runs 2 and 3: "no verdict"): the
	# host's offer opens its conversation mid-walk, locomotion is switched off,
	# and `stick_navigator.walk_to` waits without spending its frame budget, so
	# the step never answers. A player who is in the room when the tether goes
	# is the ordinary case anyway.
	var host_walk: Dictionary = await step(0, "move_to",
		{"x": control_at.x, "z": control_at.z, "close_enough": 7.0, "budget_frames": 2400})
	check(str(host_walk.get("verdict", "")) == "PASS",
		"the host walked into the chamber before the lever (%s)" % str(host_walk.get("detail", "")))

	# 4. The guest frees the legendary at the machine control.
	var reached := false
	for _attempt in 3:
		var walked: Dictionary = await step(1, "move_to",
			{"x": control_at.x, "z": control_at.z, "close_enough": 3.5, "budget_frames": 2400})
		if str(walked.get("verdict", "")) == "PASS":
			reached = true
			break
		await step(1, "move_to", {"x": float(arena[0]), "z": float(arena[2]),
			"close_enough": 6.0, "budget_frames": 1200})
	check(reached, "the guest walked to the machine control")
	if not reached:
		quit(await finish())
		return
	await step(1, "press", {"action": "interact"})
	await step(1, "dismiss_dialogue", {"presses": 16, "settle": 90})
	var freed := false
	for _poll in 60:
		if _says(await _story(1), "legendary_freed") == true:
			freed = true
			break
		await step(1, "wait", {"frames": 10})
	check(freed, "the guest's lever pull freed the legendary")
	if not freed:
		quit(await finish())
		return

	# 5. The host was already standing in the chamber when the tether went
	# (it walked in before the lever, step 3b), so its own offer opens where it
	# stands -- the way it reaches a player who watched the lever pulled.
	var host_in := false
	var host_stage := ""
	var host_view: Dictionary = {}
	for _poll in 60:
		host_view = await _choice(0)
		host_stage = str(host_view.get("stage", ""))
		if host_stage != "":
			host_in = true
			break
		await step(0, "wait", {"frames": 10})
	check(host_in, "the host, standing in the chamber, had its own offer begin (stage '%s'; %s)"
		% [host_stage, JSON.stringify({"freed": host_view.get("freed"), "near": host_view.get("near"),
			"may_receive": host_view.get("may_receive"), "panel_open": host_view.get("panel_open"),
			"participants": host_view.get("participants"), "live_id": host_view.get("live_id"),
			"receipts": host_view.get("receipts")})])
	await _diagnose_participants("after the freeing")

	# 6. Each peer's own choice opens.
	var host_choice: Dictionary = await _drive_to_choice(0)
	var guest_choice: Dictionary = await _drive_to_choice(1)
	check(bool(host_choice.get("choice_open", false)), "the host's own choice opened (%s)" % str(host_choice))
	check(bool(guest_choice.get("choice_open", false)), "the guest's own choice opened (%s)" % str(guest_choice))
	if not bool(host_choice.get("choice_open", false)) or not bool(guest_choice.get("choice_open", false)):
		quit(await finish())
		return

	# 7. HOST REFUSES at its refuse prompt.
	var refused_ok := await _answer(0, "refuse_at")
	var host_after: Dictionary = await _choice(0)
	check(refused_ok and bool(host_after.get("refused", false)) and not bool(host_after.get("joined", true)),
		"the host refused through its own prompt (%s)" % str(host_after))
	check(int(host_after.get("veridian_count", -1)) == 0 and int(host_after.get("party_size", -1)) == 4,
		"the host's belt is unchanged by refusing (%s)" % str(host_after))

	# 8. GUEST ACCEPTS, and its link dies at the claim acknowledgement.
	var accept_at: Array = guest_choice.get("accept_at", []) as Array
	var gw: Dictionary = await step(1, "move_to",
		{"x": float(accept_at[0]), "z": float(accept_at[2]), "close_enough": 0.6, "budget_frames": 900})
	check(str(gw.get("verdict", "")) == "PASS", "the guest walked to its accept prompt (%s)" % str(gw.get("detail", "")))
	var pressed: Dictionary = await step(1, "press", {"action": "interact"})
	check(str(pressed.get("verdict", "")) == "PASS", "the guest pressed interact at the accept prompt")
	await step(1, "wait", {"frames": 30})
	await _diagnose_guest_slot("after the accept press, before the drop")
	var dropped: Dictionary = await step(1, "drop_link", {"settle_frames": 60})
	check(str(dropped.get("verdict", "")) == "PASS", "the guest's link was cut right after accepting (%s)"
		% str(dropped.get("detail", "")))
	var one: Dictionary = await step(0, "expect_peers", {"count": 1}, 900)
	check(str(one.get("verdict", "")) == "PASS", "the host noticed the guest drop (%s)" % str(one.get("detail", "")))
	await step(1, "leave", {"reason": "link_died"})
	var at_ack: Dictionary = await _choice(1)
	check(bool(at_ack.get("joined", false)) and int(at_ack.get("veridian_count", -1)) == 1,
		"the press was the guest's acceptance (%s)" % str(at_ack))
	var ack_file: Dictionary = await _character(1)
	var ack_rows: Dictionary = ack_file.get("file", {}) as Dictionary
	check(bool((ack_rows.get("player_flags", {}) as Dictionary).get("legendary_joined", false))
			and _veridians((ack_rows.get("party", []) as Array)) == 1,
		"the guest's CHARACTER FILE already held the Veridian and 'legendary_joined' at the drop (%s)"
			% str(ack_rows))
	var host_during: Dictionary = await _choice(0)
	print("coordinator: host receipts while the guest is away: %s" % str(host_during.get("receipts", [])))

	await _diagnose_guest_slot("after the drop and leave")
	await _diagnose_participants("while the guest is away")
	var wiped: Dictionary = await step(1, "wipe_character", {})
	check(str(wiped.get("verdict", "")) == "PASS", "the guest's in-memory character was blanked")
	var blank: Dictionary = await _choice(1)
	check(int(blank.get("party_size", -1)) == 0 and not bool(blank.get("joined", true)),
		"the blanked guest holds no party and no answer; the file is the only copy (%s)" % str(blank))

	await _diagnose_guest_slot("after the wipe")
	# 9. Rejoin by the same character id, the production way.
	var rejoined: Dictionary = await step(1, "production_join",
		{"host": "127.0.0.1", "port": _port, "budget_frames": 6000, "returning_route": true,
		 "character": {"character_id": _guest_id, "display_name": GUEST_NAME}}, 6500)
	check(str(rejoined.get("verdict", "")) == "PASS", "the guest rejoined as '%s' (%s)"
		% [_guest_id, str(rejoined.get("detail", ""))])
	if str(rejoined.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	await _diagnose_guest_slot("after the rejoin")
	var who_back: Variant = await probe(1, "player_identity")
	print("coordinator: [%s] DIAG rejoined guest identity: %s" % [Time.get_time_string_from_system(),
		str((who_back as Dictionary).get("character_id", "")) if who_back is Dictionary else "?"])
	var two: Dictionary = await step(0, "expect_peers", {"count": 2}, 900)
	check(str(two.get("verdict", "")) == "PASS", "the host is back to two peers")

	# The guest is never offered the freeing again.
	var stages_seen: Array = []
	for _poll in NO_REOFFER_POLLS:
		var seen: Dictionary = await _choice(1)
		var stage := str(seen.get("stage", "?"))
		if not stages_seen.has(stage):
			stages_seen.append(stage)
		if bool(seen.get("pending_catch", false)) and not stages_seen.has("pending_catch"):
			stages_seen.append("pending_catch")
		await step(1, "dismiss_dialogue", {"presses": 4, "settle": 30})
	check(not stages_seen.has("join") and not stages_seen.has("choice") and not stages_seen.has("pending_catch"),
		"the rejoined guest was never offered the freeing again (stages seen: %s)" % str(stages_seen))
	for peer in 2:
		await step(peer, "dismiss_dialogue", {"presses": 16, "settle": 60})
		await step(peer, "wait", {"frames": 120})

	await _assert_outcome("after the rejoin")

	# 10. Production save/reload on both, and the same again.
	for peer in 2:
		var reloaded: Dictionary = await step(peer, "save_reload_here", {})
		check(str(reloaded.get("verdict", "")) == "PASS",
			"peer %d completed a production save/reload (%s)" % [peer, str(reloaded.get("detail", ""))])
	for peer in 2:
		await step(peer, "wait", {"frames": 120})
	await _assert_outcome("after save/reload")
	quit(await finish())


func _assert_outcome(when: String) -> void:
	var want: Array = [RECEIPT_LIVE, "legendary_resolution:accepted:%s" % _guest_id,
		"legendary_resolution:refused:%s" % _host_id]
	want.sort()
	var guest: Dictionary = await _choice(1)
	var host: Dictionary = await _choice(0)
	check(int(guest.get("veridian_count", -1)) == 1 and int(guest.get("party_size", -1)) == 5,
		"%s: the guest holds exactly one Veridian in a party of five (%s)" % [when, str(guest)])
	check(bool(guest.get("joined", false)) and not bool(guest.get("refused", true)),
		"%s: the guest's personal receipt is accepted only" % when)
	check(int(host.get("veridian_count", -1)) == 0 and int(host.get("party_size", -1)) == 4,
		"%s: the host holds no Veridian and its four (%s)" % [when, str(host)])
	check(bool(host.get("refused", false)) and not bool(host.get("joined", true)),
		"%s: the host's personal receipt is refused only" % when)
	for peer in 2:
		var view: Dictionary = host if peer == 0 else guest
		var receipts: Array = view.get("receipts", []) as Array
		check(receipts == want, "%s: peer %d's WORLD holds exactly %s (got %s)"
			% [when, peer, str(want), str(receipts)])
		check(bool(view.get("healing_found", false)) and not bool(view.get("herd_display", true)),
			"%s: peer %d has no herd display after a mixed answer (healing found %s)"
				% [when, peer, str(view.get("healing_found", false))])
		var story: Variant = await _story(peer)
		for flag: String in WORLD_FACTS:
			check(_says(story, flag) == true, "%s: peer %d's world holds '%s'" % [when, peer, flag])
	var gate_host: Variant = _says(await _story(0), GATE_FLAG)
	var gate_guest: Variant = _says(await _story(1), GATE_FLAG)
	check(gate_host != null and gate_host == gate_guest,
		"%s: both peers agree on '%s' (host %s / guest %s; set only at the physical gate, not walked here)"
			% [when, GATE_FLAG, str(gate_host), str(gate_guest)])


## Probe + dismiss until this peer's choice is open with both prompts placed.
func _drive_to_choice(peer: int) -> Dictionary:
	var last: Dictionary = {}
	for _poll in CHOICE_POLLS:
		last = await _choice(peer)
		if bool(last.get("choice_open", false)) and (last.get("accept_at", []) as Array).size() == 3 \
				and (last.get("refuse_at", []) as Array).size() == 3:
			return last
		await step(peer, "dismiss_dialogue", {"presses": 8, "settle": 20})
		await step(peer, "wait", {"frames": 20})
	print("coordinator: peer %d choice never opened; last probe %s" % [peer, str(last)])
	return last


## Walk to the named prompt anchor and press interact there; true once the
## choice has closed.
func _answer(peer: int, key: String) -> bool:
	var view: Dictionary = await _choice(peer)
	var at: Array = view.get(key, []) as Array
	if at.size() != 3:
		return false
	var walked: Dictionary = await step(peer, "move_to",
		{"x": float(at[0]), "z": float(at[2]), "close_enough": 0.6, "budget_frames": 900})
	check(str(walked.get("verdict", "")) == "PASS", "peer %d walked to its %s prompt (%s)"
		% [peer, key, str(walked.get("detail", ""))])
	await step(peer, "press", {"action": "interact"})
	for _poll in 10:
		var after: Dictionary = await _choice(peer)
		if not bool(after.get("choice_open", true)):
			return true
		await step(peer, "wait", {"frames": 10})
	return false


func _choice(peer: int) -> Dictionary:
	var raw: Variant = await probe(peer, "veridian_choice")
	return raw as Dictionary if raw is Dictionary else {}


func _character(peer: int) -> Dictionary:
	var raw: Variant = await probe(peer, "character_restore",
		{"character_id": _host_id if peer == 0 else _guest_id,
		 "flags": ["legendary_joined", "legendary_refused"]})
	return raw as Dictionary if raw is Dictionary else {}


func _veridians(rows: Array) -> int:
	var n := 0
	for raw: Variant in rows:
		if str(raw).begins_with("veridian@"):
			n += 1
	return n


func _story(peer: int) -> Variant:
	var flags: Array[String] = [GATE_FLAG]
	for flag: String in WORLD_FACTS:
		flags.append(flag)
	return await probe(peer, "story", {"world_flags": flags, "player_flags": []})


func _says(story: Variant, flag: String) -> Variant:
	if story is not Dictionary:
		return null
	var world: Variant = (story as Dictionary).get("world", {})
	if world is not Dictionary or not (world as Dictionary).has(flag):
		return null
	return bool((world as Dictionary)[flag])


func _marker(markers: Dictionary, key: String) -> Array:
	var raw: Variant = markers.get(key, [])
	return raw as Array if raw is Array else []


## DIAGNOSTIC (prints, asserts nothing): which character the guest's slot-0
## autosave points at on disk, with wall-clock time.
func _diagnose_guest_slot(when: String) -> void:
	var raw: Variant = await probe(1, "autosave_dict")
	var slot: Dictionary = raw as Dictionary if raw is Dictionary else {}
	var party: Array = slot.get("party", []) as Array
	print("coordinator: [%s] DIAG guest slot_0 %s: locator %s, party %d, live id %s" % [
		Time.get_time_string_from_system(), when, str(slot.get("split_locator", "<none>")), party.size(),
		str((await _character(1)).get("live_character_id", "?"))])


## DIAGNOSTIC (prints, asserts nothing): the Warden's recorded participants as
## each peer's world journal holds them, against both live character ids.
func _diagnose_participants(when: String) -> void:
	for peer in 2:
		var world: Variant = await probe(peer, "world_snapshot")
		var rows: Array = []
		if world is Dictionary:
			var deliveries: Variant = (world as Dictionary).get("reward_deliveries", {})
			if deliveries is Dictionary:
				for raw: Variant in (deliveries as Dictionary).values():
					if raw is Dictionary and str((raw as Dictionary).get("source", "")).begins_with("trainer:%s:" % WARDEN_TRAINER):
						rows.append("%s/%s" % [str((raw as Dictionary).get("character_id", "")),
							str((raw as Dictionary).get("status", ""))])
		var who: Variant = await probe(peer, "player_identity")
		print("coordinator: [%s] DIAG %s: peer %d live id %s; Warden journal rows %s; receipts %s" % [
			Time.get_time_string_from_system(), when, peer,
			str((who as Dictionary).get("character_id", "")) if who is Dictionary else "?",
			str(rows), str((await _choice(peer)).get("receipts", []))])
