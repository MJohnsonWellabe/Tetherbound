extends "res://tests/smoke_net_stormwood_hosted_trainers.gd"

# peers: 2

## Two-process authority proof for `stormwood_glass_for_bryn`'s delivery.
##
##   tools/net/run_net_smoke.sh stormwood_glass_for_bryn
##
## Peer 0 hosts and stays in Meadows; peer 1 enters Stormwood. The client
## finishes Bryn's request through real interact presses; the host's Stormwood
## simulation shell validates the client's trainer proxy beside Bryn, commits
## the step and the client's takes as one delta, and both processes see the
## repair. A repeat conversation takes nothing, and the client's live inspect
## prompt completes the chain for both.
##
## STAGED on the host through the ordinary world-flag path, and disclosed:
## Bryn's Act-I facts and step 1 (the earned route is the continuous smoke's
## `--through-bryn` witness), the route-07 reward at Bryn's feet already taken,
## and satchel contents granted with `storage_grant`.

const GLASS := preload("res://scripts/world/stormwood_glass_for_bryn.gd")
const ROUTE_07_TAKEN := "cache:stormwood:stormwood_pickup_route_07"
const BRYN_STANCE := [-700.0, 46.0, 2297.4]


func _initialize() -> void:
	_run_bryn()


func _run_bryn() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	var hosted := await step(0, "host")
	check(str(hosted.get("verdict", "")) == "PASS", "peer 0 started the real listen host")
	var session: Dictionary = await _session(0)
	var joined := await step(1, "join", {"host": "127.0.0.1", "port": int(session.get("enet_port", 0))})
	check(str(joined.get("verdict", "")) == "PASS", "peer 1 joined peer 0")
	if str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	_client_peer_id = int((await _session(1)).get("peer_id", 0))
	check(_client_peer_id > 1, "client has a distinct real ENet peer id")
	for flag in [STORMWOOD_KEY, STORMWOOD_GATE]:
		await _world_flag(flag)
	var entered := await step(1, "enter_realm", {"realm": STORMWOOD}, REALM_STEP_BUDGET)
	check(str(entered.get("verdict", "")) == "PASS", "client entered Stormwood")
	if str(entered.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var shells := await _await_stormwood_shell()
	check(bool((((shells.get("realms", {}) as Dictionary).get(STORMWOOD, {})) as Dictionary).get("ready", false)),
		"host stays in Meadows while its Stormwood shell owns the client's realm")
	var runtime := await _await_client_stormwood_runtime()
	check(bool(runtime.get("available", false)), "client stood up the Stormwood runtime")
	for flag in ["stormwood:chapter_started", "stormwood:rodline_linked", GLASS.REVEALED,
			GLASS.STEP_1, ROUTE_07_TAKEN]:
		await _world_flag(flag)

	await step(0, "storage_grant", {"item": "stormglass", "n": 5})
	await step(0, "storage_grant", {"item": "conductor_vine", "n": 5})
	await step(1, "storage_grant", {"item": "stormglass", "n": 4})
	await step(1, "storage_grant", {"item": "conductor_vine", "n": 2})
	var moved := await step(1, "teleport", {"at": BRYN_STANCE, "settle": 90})
	check(str(moved.get("verdict", "")) == "PASS", "client stands with Bryn: %s" % str(moved.get("detail", "")))
	await step(1, "wait", {"frames": 60})

	# Bryn's request: open with interact, then read both lines to the end.
	await step(1, "press", {"action": "interact"})
	await step(1, "wait", {"frames": 20})
	await step(1, "press", {"action": "interact", "times": 2, "gap_frames": 20})
	for peer in 2:
		var seen := await step(peer, "wait_flag", {"flag": GLASS.STEP_2, "scope": "world", "budget_frames": 900})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d sees Bryn's delivery committed: %s" % [peer, str(seen.get("detail", ""))])
	await step(1, "wait", {"frames": 60})
	var client_bag := await _satchel(1)
	var host_bag := await _satchel(0)
	check(client_bag == {"stormglass": 1, "conductor_vine": 0},
		"the host took exactly 3 Stormglass and 2 Conductor Vine from the requester: %s" % str(client_bag))
	check(host_bag == {"stormglass": 5, "conductor_vine": 5},
		"the host's own satchel was not charged for a remote delivery: %s" % str(host_bag))

	# Asking again takes nothing: Bryn has moved on, and the host refuses.
	await step(1, "storage_grant", {"item": "stormglass", "n": 3})
	await step(1, "storage_grant", {"item": "conductor_vine", "n": 2})
	await step(1, "press", {"action": "interact"})
	await step(1, "wait", {"frames": 20})
	await step(1, "press", {"action": "interact", "times": 2, "gap_frames": 20})
	await step(1, "wait", {"frames": 90})
	client_bag = await _satchel(1)
	check(client_bag == {"stormglass": 4, "conductor_vine": 2},
		"a second conversation after delivery takes nothing: %s" % str(client_bag))

	# The client inspects the repaired supplies; both processes see completion.
	var shelter := GLASS.shelter_at()
	var inspect := shelter + GLASS._offset(GLASS.config().shelter.inspect.offset)
	var inspect_stand := inspect + (inspect - shelter).normalized() * 1.4
	moved = await step(1, "teleport", {"at": [inspect_stand.x, 60.0, inspect_stand.y], "settle": 120})
	check(str(moved.get("verdict", "")) == "PASS", "client stands at the shelter supplies: %s" % str(moved.get("detail", "")))
	await step(1, "press", {"action": "interact"})
	for peer in 2:
		var done := await step(peer, "wait_flag", {"flag": GLASS.COMPLETE, "scope": "world", "budget_frames": 900})
		check(str(done.get("verdict", "")) == "PASS",
			"peer %d sees the chain complete: %s" % [peer, str(done.get("detail", ""))])
	quit(await finish())


func _world_flag(flag: String) -> void:
	var granted := await step(0, "story_flag", {"flag": flag, "scope": "world"})
	check(str(granted.get("verdict", "")) == "PASS", "host committed staged world fact '%s'" % flag)
	for peer in 2:
		var seen := await step(peer, "wait_flag", {"flag": flag})
		check(str(seen.get("verdict", "")) == "PASS", "peer %d received '%s'" % [peer, flag])


func _satchel(peer: int) -> Dictionary:
	var raw: Variant = await probe(peer, "trainer_reward", {"items": ["stormglass", "conductor_vine"]})
	return ((raw as Dictionary).get("satchel", {}) as Dictionary) if raw is Dictionary else {}
