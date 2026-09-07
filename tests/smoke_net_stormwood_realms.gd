extends "res://tests/helpers/net_harness.gd"

# peers: 2

## A narrow real-router smoke for Stormwood. It deliberately does not cover
## gate refusal/unlock UX or late join; those have their own lanes. This proves
## that an already-authorized client can occupy Stormwood while the host stays
## in Meadows, where the host owns the simulation shell.

const MEADOWS := "meadows"
const STORMWOOD := "stormwood"
const STORMWOOD_KEY := "realm_key_stormwood"
const SHARED_GATE_FLAG := "realm_gate_stormwood_unlocked"
const REALM_STEP_BUDGET := 10000


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var client_hello: Dictionary = (_peers[1] as Dictionary).get("hello", {}) as Dictionary
	var host_user_data_dir := str(host_hello.get("user_data_dir", ""))
	var client_user_data_dir := str(client_hello.get("user_data_dir", ""))
	check(not host_user_data_dir.is_empty() and not client_user_data_dir.is_empty()
		and host_user_data_dir != client_user_data_dir,
		"peers resolve distinct user-data directories")

	var hosted: Dictionary = await step(0, "host")
	check(str(hosted.get("verdict", "")) == "PASS", "host starts the real session")
	var session: Variant = await probe(0, "session")
	var joined: Dictionary = await step(1, "join", {
		"host": "127.0.0.1",
		"port": int((session as Dictionary).get("enet_port", 0)) if session is Dictionary else 0,
	})
	check(str(joined.get("verdict", "")) == "PASS", "client joins the host session")
	for peer in 2:
		var peers: Dictionary = await step(peer, "expect_peers", {"count": 2})
		check(str(peers.get("verdict", "")) == "PASS", "peer %d sees both session members" % peer)

	var key: Dictionary = await step(0, "story_flag", {"flag": STORMWOOD_KEY, "scope": "world"})
	check(str(key.get("verdict", "")) == "PASS", "host commits the replicated Stormwood key")
	var shared_gate: Dictionary = await step(0, "story_flag", {"flag": SHARED_GATE_FLAG, "scope": "world"})
	check(str(shared_gate.get("verdict", "")) == "PASS", "host commits the shared Stormward gate fact")
	for peer in 2:
		for flag in [STORMWOOD_KEY, SHARED_GATE_FLAG]:
			var visible: Dictionary = await step(peer, "wait_flag", {"flag": flag})
			check(str(visible.get("verdict", "")) == "PASS",
				"peer %d sees replicated world flag %s" % [peer, flag])

	var host_fog_before: Variant = await probe(0, "map_fog")
	var crossed: Dictionary = await step(1, "enter_realm", {"realm": STORMWOOD},
		REALM_STEP_BUDGET)
	check(str(crossed.get("verdict", "")) == "PASS",
		"client enters Stormwood through Game.enter_realm (%s)" % str(crossed.get("detail", "")))
	if str(crossed.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var client_realm: Variant = await probe(1, "realm")
	check(client_realm is Dictionary and str((client_realm as Dictionary).get("current", "")) == STORMWOOD,
		"client registry/current realm is Stormwood")
	check(client_realm is Dictionary and str((client_realm as Dictionary).get("scene", "")) == "Stormwood",
		"client current production root is /root/Stormwood")
	var host_realm: Variant = await probe(0, "realm")
	check(host_realm is Dictionary and str((host_realm as Dictionary).get("current", "")) == MEADOWS,
		"host remains in Meadows")

	var shells := await _await_stormwood_shell()
	var rows: Dictionary = (shells as Dictionary).get("realms", {}) if shells is Dictionary else {}
	var storm: Dictionary = rows.get(STORMWOOD, {}) as Dictionary
	check(bool(storm.get("ready", false)), "host reports the Stormwood simulation shell ready")
	check(int(storm.get("bodies", 0)) == 1, "Stormwood shell owns the departed client body")
	var host_log := FileAccess.get_file_as_string(str((_peers[0] as Dictionary).get("log_path", "")))
	check(host_log.find("STORMWOOD READY realm=stormwood shell=true terrain_regions=108") >= 0,
		"Stormwood shell built the production Terrain3D 108-region footprint")

	var client_fog_before: Variant = await probe(1, "map_fog")
	var explored: Dictionary = await step(1, "explore_at", {"at": [-350, 450], "settle": 180})
	check(str(explored.get("verdict", "")) == "PASS", "client discovers its Stormwood map locally")
	var client_fog_after: Variant = await probe(1, "map_fog")
	var host_fog_after: Variant = await probe(0, "map_fog")
	check(client_fog_before is Dictionary and client_fog_after is Dictionary
		and int((client_fog_after as Dictionary).get("cells", 0)) > int((client_fog_before as Dictionary).get("cells", 0)),
		"client discovers fresh Stormwood fog cells in its local map payload")
	check(host_fog_before == host_fog_after,
		"client Stormwood discovery does not change host Meadows fog")

	var home: Dictionary = await step(1, "enter_realm", {"realm": MEADOWS}, REALM_STEP_BUDGET)
	check(str(home.get("verdict", "")) == "PASS", "client returns to Meadows")
	var returned: Variant = await probe(1, "realm")
	check(returned is Dictionary and str((returned as Dictionary).get("current", "")) == MEADOWS,
		"client is back in Meadows after the return crossing")
	for peer in 2:
		var live: Variant = await probe(peer, "session")
		check(live is Dictionary and bool((live as Dictionary).get("active", false))
			and int((live as Dictionary).get("peer_count", 0)) == 2,
			"peer %d keeps the two-peer session through Stormwood entry and return" % peer)

	quit(await finish())


func _await_stormwood_shell() -> Dictionary:
	var last: Dictionary = {}
	for tick in 120:
		var report: Variant = await probe(0, "realm_shells")
		last = report if report is Dictionary else {}
		var rows: Dictionary = last.get("realms", {}) as Dictionary
		var storm: Dictionary = rows.get(STORMWOOD, {}) as Dictionary
		if bool(storm.get("ready", false)):
			return last
		await step(0, "wait", {"frames": 60})
	return last
