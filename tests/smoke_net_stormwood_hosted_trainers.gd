extends "res://tests/helpers/net_harness.gd"

# peers: 2

## A real two-process authority smoke for the first small authored Stormwood
## trainer. It deliberately does NOT test Captain Marrow or the Dynamo; Marrow
## remains locked behind that separate controller.
##
##   tools/net/run_net_smoke.sh stormwood_hosted_trainers
##
## Topology is the point: peer 0 hosts but stays in Meadows. Peer 1 enters
## Stormwood and starts Tamsin. The host's ready Stormwood shell owns the
## opponent/roster even though the host has no player body in that realm.
##
## This costs two Meadow boots plus the client's Stormwood scene and the host's
## Stormwood simulation shell. That is intentional: a loopback or a host-local
## Stormwood scene cannot prove the realm-owner boundary this smoke exists for.

const MEADOWS := "meadows"
const STORMWOOD := "stormwood"
const STORMWOOD_KEY := "realm_key_stormwood"
const STORMWOOD_GATE := "realm_gate_stormwood_unlocked"
const TRAINER := "tamsin_surge_lesson"
const DEFEAT_FLAG := "stormwood:trainer:tamsin_surge_lesson:defeated"
const REALM_STEP_BUDGET := 10000
const HOSTED_WAIT_FRAMES := 900
const HOST_SYNC_M := 5.0
var _client_peer_id := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	var hosted := await step(0, "host")
	check(str(hosted.get("verdict", "")) == "PASS", "peer 0 started the real listen host")
	if str(hosted.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var session: Dictionary = await _session(0)
	var joined := await step(1, "join", {"host": "127.0.0.1", "port": int(session.get("enet_port", 0))})
	check(str(joined.get("verdict", "")) == "PASS", "peer 1 joined peer 0")
	if str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var client_session := await _session(1)
	_client_peer_id = int(client_session.get("peer_id", 0))
	check(_client_peer_id > 0 and _client_peer_id != int(session.get("peer_id", 0)),
		"client has a distinct real ENet peer id (%d), not harness index 1" % _client_peer_id)
	if _client_peer_id <= 0:
		quit(await finish())
		return
	for peer in 2:
		var peers := await step(peer, "expect_peers", {"count": 2})
		check(str(peers.get("verdict", "")) == "PASS", "peer %d sees both session members" % peer)

	for flag in [STORMWOOD_KEY, STORMWOOD_GATE]:
		var granted := await step(0, "story_flag", {"flag": flag, "scope": "world"})
		check(str(granted.get("verdict", "")) == "PASS", "host committed Stormwood prerequisite '%s'" % flag)
		for peer in 2:
			var seen := await step(peer, "wait_flag", {"flag": flag})
			check(str(seen.get("verdict", "")) == "PASS", "peer %d received '%s'" % [peer, flag])

	var entered := await step(1, "enter_realm", {"realm": STORMWOOD}, REALM_STEP_BUDGET)
	check(str(entered.get("verdict", "")) == "PASS", "client entered Stormwood")
	if str(entered.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var host_realm: Variant = await probe(0, "realm")
	var client_realm: Variant = await probe(1, "realm")
	check(host_realm is Dictionary and str((host_realm as Dictionary).get("current", "")) == MEADOWS,
		"host remains physically in Meadows")
	check(client_realm is Dictionary and str((client_realm as Dictionary).get("current", "")) == STORMWOOD,
		"client is physically in Stormwood")
	var shells := await _await_stormwood_shell()
	var storm: Dictionary = ((shells.get("realms", {}) as Dictionary).get(STORMWOOD, {})) as Dictionary
	check(bool(storm.get("ready", false)), "host reports the Stormwood simulation shell ready")
	check(int(storm.get("bodies", 0)) >= 1, "host shell owns the remote client's body")
	var client_runtime := await _await_client_stormwood_runtime()
	check(bool(client_runtime.get("available", false)),
		"client finished standing up the Stormwood combat runtime")
	if not bool(client_runtime.get("available", false)):
		quit(await finish())
		return

	# A fresh net-harness process has not played the opening, so it owns no
	# party member. `deploy_creature` can build the sandbox fallback body, but
	# `begin_hosted_round` correctly requires the Game.party record that every
	# real Stormwood player acquired at the starter choice. Seed that state via
	# the opening's production PartySeam before asking the production recall
	# path to deploy it.
	var party_seeded := await step(1, "party_grant", {"species": "terrapup"})
	check(str(party_seeded.get("verdict", "")) == "PASS",
		"client owns a real party member before the hosted challenge")
	if str(party_seeded.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var deployed := await step(1, "deploy_creature", {"species": "terrapup"})
	check(str(deployed.get("verdict", "")) == "PASS", "client deployed its own creature before challenging")
	if str(deployed.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var prepared := await step(1, "stormwood_hosted_start", {"trainer": TRAINER, "prepare_only": true})
	check(str(prepared.get("verdict", "")) == "PASS", "client prepared its actor and deployed follower beside Tamsin")
	if str(prepared.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var admitted := await _await_host_actor_near_trainer()
	var actor_at := _vec(admitted.get("host_actor_pos", []))
	var trainer_at := _vec(admitted.get("trainer_pos", []))
	check(actor_at != Vector3.INF and trainer_at != Vector3.INF and actor_at.distance_to(trainer_at) <= HOST_SYNC_M,
		"host shell received the remote client's actor beside Tamsin before start")
	if actor_at == Vector3.INF or trainer_at == Vector3.INF or actor_at.distance_to(trainer_at) > HOST_SYNC_M:
		quit(await finish())
		return
	var started := await step(1, "stormwood_hosted_start", {"trainer": TRAINER, "request_only": true})
	check(str(started.get("verdict", "")) == "PASS", "REMOTE client started the authored Tamsin fight through the hub: %s" % str(started.get("detail", "")))
	if str(started.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var host_state := await _await_hosted(0, true)
	var client_state := await _await_hosted(1, true)
	check(bool(host_state.get("exists", false)), "host shell holds one live hosted trainer controller")
	check(str((host_state.get("record", {}) as Dictionary).get("realm", "")) == STORMWOOD,
		"host stamped the trainer record with Stormwood, not its own Meadows realm")
	check(str((host_state.get("record", {}) as Dictionary).get("kind", "")) == "trainer",
		"host record is a trainer encounter")
	check(int(host_state.get("round", -1)) == 0 and int(host_state.get("total", 0)) == 2,
		"host owns Tamsin's authored two-member roster at round 0")
	check(str(client_state.get("local_record", "")) == str((host_state.get("record", {}) as Dictionary).get("id", "")),
		"client renders the one record minted by the host shell")

	# A Meadows peer cannot act on the Stormwood fight even if it knows its id.
	# This is the wrong-realm attack: sender realm is derived from Session, not a
	# claim in the payload.
	var hp_before := float((host_state.get("record", {}) as Dictionary).get("hp", -1.0))
	var seq_before := int((host_state.get("record", {}) as Dictionary).get("seq", -1))
	var foreign := await step(0, "stormwood_hosted_raw_strike", {
		"trainer": TRAINER, "encounter_id": str((host_state.get("record", {}) as Dictionary).get("id", "")),
		"realm": STORMWOOD, "action": 701, "move_id": "forged_move", "damage": 999999.0,
	})
	check(str(foreign.get("verdict", "")) == "PASS", "Meadows host sent the adversarial raw Stormwood request")
	var after_foreign := await _await_hosted(0, true)
	check(_hp(after_foreign) == hp_before and _seq(after_foreign) == seq_before,
		"wrong-realm sender could not advance the remote Stormwood roster or damage its opponent")

	# A correctly located client still cannot supply its own move/damage.
	var forged := await step(1, "stormwood_hosted_raw_strike", {
		"trainer": TRAINER, "encounter_id": str((host_state.get("record", {}) as Dictionary).get("id", "")),
		"realm": STORMWOOD, "action": 702, "move_id": "forged_move", "damage": 999999.0,
	})
	check(str(forged.get("verdict", "")) == "PASS", "client submitted forged move and damage fields")
	var after_forged := await _await_hosted(0, true)
	check(_hp(after_forged) == hp_before and _seq(after_forged) == seq_before,
		"host ignored forged damage/move data without advancing the record")

	# Place only the client-side body. The next check reads the host shell's
	# remote body; no strike is submitted until that host-held transform arrives.
	var opponent_at := _vec(host_state.get("opponent_pos", []))
	check(opponent_at != Vector3.INF, "host exposes a real opponent position for synchronization")
	if opponent_at == Vector3.INF:
		quit(await finish())
		return
	var stand := opponent_at + Vector3(1.5, 0.0, 0.0)
	var placed := await step(1, "place_creature", {"at": [stand.x, stand.y, stand.z], "exact": true,
		"face": [opponent_at.x, opponent_at.y, opponent_at.z], "settle": 90})
	check(str(placed.get("verdict", "")) == "PASS", "client positioned its local creature near the hosted opponent")
	host_state = await _await_host_body_near(stand)
	check(_vec(host_state.get("host_body_pos", [])).distance_to(stand) <= HOST_SYNC_M,
		"host shell received the client's creature transform before a strike")

	# One legal raw request consumes an action. Re-sending its action id after a
	# real cooldown window must remain stale; the second request cannot change hp
	# or roster state. The raw request still traverses Session and host validation.
	var quick := str((client_state.get("local_card", {}) as Dictionary).get("quick", ""))
	check(not quick.is_empty(), "client's deployed card has an authored quick move")
	var legal := await step(1, "stormwood_hosted_raw_strike", {"trainer": TRAINER,
		"encounter_id": str((host_state.get("record", {}) as Dictionary).get("id", "")), "action": 703,
		"move_id": quick, "realm": STORMWOOD, "damage": 999999.0, "settle": 90})
	check(str(legal.get("verdict", "")) == "PASS", "client sent one host-validated action")
	await step(1, "wait", {"frames": 180}) # longer than the action cooldown; stale must stay stale.
	var before_stale := await _await_hosted(0, true)
	var stale := await step(1, "stormwood_hosted_raw_strike", {"trainer": TRAINER,
		"encounter_id": str((before_stale.get("record", {}) as Dictionary).get("id", "")), "action": 703,
		"move_id": quick, "realm": STORMWOOD, "damage": 999999.0, "settle": 90})
	check(str(stale.get("verdict", "")) == "PASS", "client resent an action id after its real cooldown elapsed")
	var after_stale := await _await_hosted(0, true)
	check(_hp(after_stale) == _hp(before_stale) and _seq(after_stale) == _seq(before_stale)
		and int(after_stale.get("round", -1)) == int(before_stale.get("round", -1)),
		"stale action could not damage, advance, or replace the host-owned round")

	# Fixture setup changes only live host HP. Each roster member still dies from
	# an injected production combat input, not direct round advancement or flags.
	for expected_round in [0, 1]:
		host_state = await _await_round(0, expected_round)
		var staged := await step(0, "stormwood_hosted_fixture_health", {"trainer": TRAINER, "hp": 1.0})
		check(str(staged.get("verdict", "")) == "PASS", "TEST FIXTURE staged host-owned round %d at 1 hp" % expected_round)
		var pressed := await step(1, "stormwood_hosted_quick", {"settle": 150, "ready_budget": 600})
		check(str(pressed.get("verdict", "")) == "PASS", "client used real combat input to finish hosted round %d" % expected_round)
		if expected_round == 0:
			var next := await _await_round(0, 1)
			check(int(next.get("round", -1)) == 1 and not bool(next.get("finished", true)),
				"host advanced from Tamsin round 0 to her authored second member once")

	var completed := await _await_finished(0)
	check(bool(completed.get("finished", false)), "host marked Tamsin's roster finished after actual strikes")
	for peer in 2:
		var flag := await step(peer, "wait_flag", {"flag": DEFEAT_FLAG, "scope": "world", "budget_frames": 900})
		check(str(flag.get("verdict", "")) == "PASS", "peer %d received the shared hosted-trainer defeat flag" % peer)
	# `world_snapshot()` synchronizes the live day clock on every read, so two
	# whole snapshots taken 180 frames apart are expected to differ even when
	# the retry changes nothing. The hosted payout's durable world facts and
	# per-participant reward receipts both live in the authoritative flag store;
	# compare that exact container around the refused retry.
	var world_before_retry: Variant = await probe(0, "world_snapshot")
	var flags_before_retry: Dictionary = (world_before_retry as Dictionary).get("flags", {}) \
		if world_before_retry is Dictionary else {}
	var retry := await step(1, "stormwood_hosted_start", {"trainer": TRAINER, "settle": 180})
	check(str(retry.get("verdict", "")) == "FAIL", "completed authored trainer cannot be reopened for a second payout")
	var world_after_retry: Variant = await probe(0, "world_snapshot")
	var flags_after_retry: Dictionary = (world_after_retry as Dictionary).get("flags", {}) \
		if world_after_retry is Dictionary else {}
	check(JSON.stringify(flags_before_retry, "", true, true) == JSON.stringify(flags_after_retry, "", true, true),
		"retrying the completed trainer made no second reward receipt or world-flag mutation")
	check(await assert_all_hashes_equal(900), "world state hash agrees after hosted trainer completion")

	quit(await finish())


func _session(peer: int) -> Dictionary:
	var raw: Variant = await probe(peer, "session")
	return raw as Dictionary if raw is Dictionary else {}


func _await_stormwood_shell() -> Dictionary:
	var last: Dictionary = {}
	for tick in 180:
		var raw: Variant = await probe(0, "realm_shells")
		last = raw as Dictionary if raw is Dictionary else {}
		var storm: Dictionary = ((last.get("realms", {}) as Dictionary).get(STORMWOOD, {})) as Dictionary
		if bool(storm.get("ready", false)) and int(storm.get("bodies", 0)) >= 1:
			return last
		await step(0, "wait", {"frames": 60})
	return last


## `Game.enter_realm()` returns after the new current scene exists, while the
## Stormwood world deliberately continues its budgeted procedural build over
## later frames.  On a cold Linux runner that build outlasts the generic realm
## settle window.  Wait for the production encounter hub (created beside the
## EncounterDirector) before asking the ordinary deploy path for that director.
func _await_client_stormwood_runtime() -> Dictionary:
	var last: Dictionary = {}
	for tick in HOSTED_WAIT_FRAMES:
		var raw: Variant = await probe(1, "stormwood_hosted_trainer", {
			"trainer": TRAINER, "peer": _client_peer_id,
		})
		last = raw as Dictionary if raw is Dictionary else {}
		if bool(last.get("available", false)) and not (last.get("trainer_pos", []) as Array).is_empty():
			return last
		await step(1, "wait", {"frames": 1})
	return last


func _await_hosted(peer: int, must_exist: bool) -> Dictionary:
	var last: Dictionary = {}
	for tick in HOSTED_WAIT_FRAMES:
		var raw: Variant = await probe(peer, "stormwood_hosted_trainer", {"trainer": TRAINER, "peer": _client_peer_id})
		last = raw as Dictionary if raw is Dictionary else {}
		var ready := bool(last.get("exists", false)) if peer == 0 else not str(last.get("local_record", "")).is_empty()
		if ready == must_exist:
			return last
		await step(peer, "wait", {"frames": 1})
	return last


func _await_host_body_near(at: Vector3) -> Dictionary:
	var last: Dictionary = {}
	for tick in HOSTED_WAIT_FRAMES:
		var raw: Variant = await probe(0, "stormwood_hosted_trainer", {"trainer": TRAINER, "peer": _client_peer_id})
		last = raw as Dictionary if raw is Dictionary else {}
		var host_at := _vec(last.get("host_body_pos", []))
		if host_at != Vector3.INF and host_at.distance_to(at) <= HOST_SYNC_M:
			return last
		await step(0, "wait", {"frames": 1})
	return last


func _await_host_actor_near_trainer() -> Dictionary:
	var last: Dictionary = {}
	for tick in HOSTED_WAIT_FRAMES:
		var raw: Variant = await probe(0, "stormwood_hosted_trainer", {"trainer": TRAINER, "peer": _client_peer_id})
		last = raw as Dictionary if raw is Dictionary else {}
		var actor_at := _vec(last.get("host_actor_pos", []))
		var trainer_at := _vec(last.get("trainer_pos", []))
		if actor_at != Vector3.INF and trainer_at != Vector3.INF and actor_at.distance_to(trainer_at) <= HOST_SYNC_M:
			return last
		await step(0, "wait", {"frames": 1})
	return last


func _await_round(peer: int, wanted: int) -> Dictionary:
	var last: Dictionary = {}
	for tick in HOSTED_WAIT_FRAMES:
		var raw: Variant = await probe(peer, "stormwood_hosted_trainer", {"trainer": TRAINER, "peer": _client_peer_id})
		last = raw as Dictionary if raw is Dictionary else {}
		if int(last.get("round", -1)) == wanted and not bool(last.get("finished", false)):
			return last
		await step(peer, "wait", {"frames": 1})
	return last


func _await_finished(peer: int) -> Dictionary:
	var last: Dictionary = {}
	for tick in HOSTED_WAIT_FRAMES:
		var raw: Variant = await probe(peer, "stormwood_hosted_trainer", {"trainer": TRAINER, "peer": _client_peer_id})
		last = raw as Dictionary if raw is Dictionary else {}
		if bool(last.get("finished", false)):
			return last
		await step(peer, "wait", {"frames": 1})
	return last


static func _vec(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() == 3:
		var a := raw as Array
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.INF


static func _hp(state: Dictionary) -> float:
	return float((state.get("record", {}) as Dictionary).get("hp", -1.0))


static func _seq(state: Dictionary) -> int:
	return int((state.get("record", {}) as Dictionary).get("seq", -1))
