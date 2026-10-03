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
const PORTAL_FIXTURE := "initial_hall_position_and_open_route_no_earned_credit"


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	# RD-35/F16: explicit retired-crossing fixture in isolated debug peers.
	# All original authority, encounter and persistence assertions remain.
	for fixture_peer in 2:
		var legacy: Dictionary = await step(fixture_peer, "legacy_physical_crossings_fixture", {"regression": "stormwood_realms"})
		check(legacy.get("verdict") == "PASS", "disclosed retired crossing fixture enabled")
		if legacy.get("verdict") != "PASS":
			quit(await finish())
			return
	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var client_hello: Dictionary = (_peers[1] as Dictionary).get("hello", {}) as Dictionary
	var host_user_data_dir := str(host_hello.get("user_data_dir", ""))
	var client_user_data_dir := str(client_hello.get("user_data_dir", ""))
	check(not host_user_data_dir.is_empty() and not client_user_data_dir.is_empty()
		and host_user_data_dir != client_user_data_dir,
		"peers resolve distinct user-data directories")
	for fixture_peer in 2:
		var prepared: Dictionary = await step(fixture_peer, "enter_realm", {"realm": STORMWOOD,
			"actual_portal_fixture": PORTAL_FIXTURE, "portal_regression": "stormwood_realms", "portal_prepare_only": true})
		check(prepared.get("verdict") == "PASS", "Disclosed initial Hall/route/Home Key fixture before admission; no earned credit")
		if prepared.get("verdict") != "PASS":
			quit(await finish())
			return

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

	var crossed: Dictionary = await step(1, "enter_realm", {"realm": STORMWOOD,
		"actual_portal_fixture": PORTAL_FIXTURE, "portal_regression": "stormwood_realms"},
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

	# Ask both personal maps about the exact remote point. Comparing whole-map
	# counts was not an isolation test: the host legitimately keeps revealing
	# cells under its own settling body while the client action spans 180 frames.
	# If the client's Stormwood reveal leaks, this point appears in the host's
	# Meadows map; unrelated host exploration cannot create that false result.
	var reveal_at := [-350, 450]
	var client_fog_before: Variant = await probe(1, "map_fog")
	# Preserve the same point and actual discovery tick, using real movement.
	# A post-admission teleport cannot supply the next exact passive checkpoint.
	var explored: Dictionary = await step(1, "move_to", {"x": reveal_at[0], "z": reveal_at[1],
		"budget_frames": 6000 - 180})
	check(str(explored.get("verdict", "")) == "PASS", "client discovers its Stormwood map locally")
	var discovery_frames: int = int(explored.get("frames_used", 0))
	check(discovery_frames + 180 < 6000, "Actual movement plus original settle leaves room in the original return action budget")
	if explored.get("verdict") != "PASS" or discovery_frames + 180 >= 6000:
		quit(await finish())
		return
	var discovery_settled: Dictionary = await step(1, "wait", {"frames": 180})
	check(discovery_settled.get("verdict") == "PASS", "Original discovery settle remains within return action budget")
	if discovery_settled.get("verdict") != "PASS":
		quit(await finish())
		return
	discovery_frames += int(discovery_settled.get("frames_used", 0))
	# Terrain collision may settle the body away from the requested fixture
	# coordinate. Ask both maps about where the shipping discovery tick actually
	# sampled the player, not where the harness originally tried to place them.
	var discovered_position: Variant = await probe(1, "position")
	check(discovered_position is Array and discovered_position.size() == 3, "Actual walked discovery position is available")
	if not discovered_position is Array or discovered_position.size() != 3:
		quit(await finish())
		return
	var settled_at: Array = [discovered_position[0], discovered_position[2]]
	var client_fog_after: Variant = await probe(1, "map_fog", {"at": settled_at})
	var host_fog_after: Variant = await probe(0, "map_fog", {"at": settled_at})
	check(client_fog_before is Dictionary and client_fog_after is Dictionary
		and int((client_fog_after as Dictionary).get("cells", 0)) > int((client_fog_before as Dictionary).get("cells", 0)),
		"client discovers fresh Stormwood fog cells in its local map payload")
	check(client_fog_after is Dictionary and bool((client_fog_after as Dictionary).get("at_discovered", false)),
		"client discovers the requested Stormwood position")
	check(host_fog_after is Dictionary
		and not bool((host_fog_after as Dictionary).get("at_discovered", true)),
		"client Stormwood discovery does not change host Meadows fog")

	var home: Dictionary = await step(1, "enter_realm", {"realm": MEADOWS,
		"actual_portal_fixture": PORTAL_FIXTURE, "portal_regression": "stormwood_realms",
		"portal_prior_frames": discovery_frames}, REALM_STEP_BUDGET)
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
