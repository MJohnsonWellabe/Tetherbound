extends "res://tests/smoke_net_stormwood_hosted_trainers.gd"

# peers: 2

## Lifecycle regression, not campaign evidence. The remote client receives the
## Stormwood entry fixture and one level-99 Terrapup so ordinary creature defeat
## does not race the unchanged downed window. No strikes, wins or timer changes.
## `go_down` supplies the lethal event; shipping DownedState/PlayerDeath must
## preserve the encounter while revivable, then withdraw it on final expiry.

func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	if not await _require_step(0, "host"):
		quit(await finish())
		return
	var host_session := await _session(0)
	if not await _require_step(1, "join", {"host": "127.0.0.1", "port": int(host_session.get("enet_port", 0))}):
		quit(await finish())
		return
	_client_peer_id = int((await _session(1)).get("peer_id", 0))
	check(_client_peer_id > 1, "remote fighter has a real client ENet identity")
	for peer in 2:
		await _require_step(peer, "expect_peers", {"count": 2})
	for flag in [STORMWOOD_KEY, STORMWOOD_GATE]:
		await _require_step(0, "story_flag", {"flag": flag, "scope": "world"})
		for peer in 2:
			await _require_step(peer, "wait_flag", {"flag": flag})
	if not await _require_step(1, "enter_realm", {"realm": STORMWOOD}, REALM_STEP_BUDGET):
		quit(await finish())
		return
	await _await_stormwood_shell()
	var runtime := await _await_client_stormwood_runtime()
	check(bool(runtime.get("available", false)), "remote Stormwood combat runtime is ready")
	if not bool(runtime.get("available", false)):
		quit(await finish())
		return
	await _require_step(1, "party_grant", {"species": "terrapup", "level": 99})
	await _require_step(1, "deploy_creature", {"species": "terrapup"})
	var prepared := await step(1, "stormwood_hosted_start", {"trainer": TRAINER, "prepare_only": true})
	check(str(prepared.get("verdict", "")) == "PASS", "remote fighter staged beside authored trainer")
	if str(prepared.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var prepared_data: Dictionary = prepared.get("data", {}) as Dictionary
	await _await_host_actor_ready(_vec(prepared_data.get("client_actor_pos", [])))
	if not await _require_step(1, "stormwood_hosted_start", {"trainer": TRAINER, "request_only": true}):
		quit(await finish())
		return
	var host_state := await _await_hosted(0, true)
	var client_state := await _await_hosted(1, true)
	check(_is_member(host_state) and bool(client_state.get("fighting", false)), "remote participant is fighting before lethal fixture")
	var before: Variant = await probe(0, "world_snapshot")
	var flags_before: Dictionary = (before as Dictionary).get("flags", {})
	if not await _require_step(1, "go_down"):
		quit(await finish())
		return
	var down: Dictionary = await probe(1, "downed")
	check(bool(down.get("local_downed", false)), "lethal event opens normal multiplayer revival window")
	check(float(down.get("remaining_s", 0.0)) > 0.0, "revival deadline was not bypassed")
	var saw_late_membership := false
	var deadline := Time.get_ticks_msec() + 75000
	while bool(down.get("local_downed", false)) and Time.get_ticks_msec() < deadline:
		host_state = await probe(0, "stormwood_hosted_trainer", {"trainer": TRAINER, "peer": _client_peer_id})
		client_state = await probe(1, "stormwood_hosted_trainer", {"trainer": TRAINER, "peer": _client_peer_id})
		down = await probe(1, "downed")
		if not bool(down.get("local_downed", false)):
			break
		if not _is_member(host_state) or not bool(client_state.get("fighting", false)):
			check(false, "downed alone must retain host membership and local combat")
			break
		if float(down.get("remaining_s", 99.0)) < 8.0:
			saw_late_membership = true
		await step(1, "wait", {"frames": 30})
		down = await probe(1, "downed")
	check(saw_late_membership, "fight remained live near the end of the unchanged revival window")
	check(not bool(down.get("local_downed", true)) and int(down.get("expired", 0)) == 1,
		"normal downed expiry finalized exactly one death")
	client_state = await _await_hosted(1, false)
	check(str(client_state.get("local_record", "")).is_empty() and not bool(client_state.get("fighting", true)),
		"finalized death clears remote combat and its record")
	for tick in 180:
		var raw: Variant = await probe(0, "stormwood_hosted_trainer", {"trainer": TRAINER, "peer": _client_peer_id})
		host_state = raw as Dictionary
		if not _is_member(host_state):
			break
		await step(0, "wait", {"frames": 1})
	check(not _is_member(host_state), "reliable self-withdrawal removes dead client on host authority")
	await step(1, "wait", {"frames": 180})
	client_state = await _await_hosted(1, false)
	check(str(client_state.get("local_record", "")).is_empty() and not bool(client_state.get("fighting", true)),
		"later host snapshots do not restart combat at the recovery camp")
	var after: Variant = await probe(0, "world_snapshot")
	check(JSON.stringify(flags_before, "", true, true) == JSON.stringify((after as Dictionary).get("flags", {}), "", true, true),
		"death earned no trainer defeat flag or reward receipt")
	var realm: Dictionary = await probe(0, "realm")
	check(str(realm.get("current", "")) == MEADOWS, "authority stayed in Meadows throughout remote death")
	quit(await finish())


func _require_step(peer: int, action: String, args: Dictionary = {}, budget: int = DEFAULT_STEP_BUDGET_FRAMES) -> bool:
	var result := await step(peer, action, args, budget)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	return passed


func _is_member(state: Dictionary) -> bool:
	for peer: Variant in state.get("participants", []):
		if int(peer) == _client_peer_id:
			return true
	return false
