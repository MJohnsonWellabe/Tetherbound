extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Fixture-only network proof for the ordinary Water return connection. Both
## peers boot the production Water scene and form a real Session. The host
## ledger supplies only the two route prerequisites an earned save would have;
## the connected client then walks to the physical gate and presses Interact.
## This is not earned campaign evidence.

const WATER := "water"
const STORMWOOD := "stormwood"
const STORMWOOD_KEY := "realm_key_stormwood"
const WATER_UNLOCK := "realm_gate_water_unlocked"
const WATER_KEY := "realm_key_water"
const ROUTE_FLAGS: Array[String] = [STORMWOOD_KEY, WATER_UNLOCK, WATER_KEY]
## Same production Stormwood transition budget used by the existing focused
## two-peer Stormwood realm smoke; this test does not extend a global budget.
const REALM_STEP_BUDGET := 10000
## water_world.json places the gate at (12, 162) and RealmGate places its
## Interactable 0.72 m forward. This is the same 2.2 m physical stance derived
## by the single-process proof, on the First Shore side of the threshold.
const GATE_STANCE := Vector2(9.8, 162.72)


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, WATER):
		quit(await finish())
		return
	if not _require(_peers.size() == 2, "coordinator tracks exactly two Water peers"):
		quit(await finish())
		return

	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var client_hello: Dictionary = (_peers[1] as Dictionary).get("hello", {}) as Dictionary
	var host_home := str(host_hello.get("user_data_dir", ""))
	var client_home := str(client_hello.get("user_data_dir", ""))
	if not _require(not host_home.is_empty() and not client_home.is_empty()
			and host_home != client_home,
			"peers use distinct isolated user-data directories"):
		quit(await finish())
		return

	for peer in 2:
		var boot: Variant = await probe(peer, "realm")
		if not _require(boot is Dictionary
				and str((boot as Dictionary).get("current", "")) == WATER
				and str((boot as Dictionary).get("scene", "")) == "WaterArchipelago",
				"peer %d boots the production Water scene" % peer):
			quit(await finish())
			return

	var hosted: Dictionary = await step(0, "host")
	if not _require(_passed(hosted), "host starts the real session (%s)" % _detail(hosted)):
		quit(await finish())
		return
	var host_session: Variant = await probe(0, "session")
	if not _require(host_session is Dictionary,
			"host exposes a live Session after hosting"):
		quit(await finish())
		return
	var joined: Dictionary = await step(1, "join", {
		"host": "127.0.0.1",
		"port": int((host_session as Dictionary).get("enet_port", 0)),
	})
	if not _require(_passed(joined), "client joins the host session (%s)" % _detail(joined)):
		quit(await finish())
		return
	for peer in 2:
		var peers_seen: Dictionary = await step(peer, "expect_peers", {"count": 2})
		if not _require(_passed(peers_seen),
				"peer %d sees both connected session members (%s)" % [peer, _detail(peers_seen)]):
			quit(await finish())
			return

	var shells_before: Variant = await probe(0, "realm_shells")
	if not _require(shells_before is Dictionary and _shell_realms(shells_before).is_empty(),
			"host has no realm shell while both peers occupy Water"):
		quit(await finish())
		return

	# Prove these are the only fixture progression writes: all three route facts
	# are initially absent in both scopes before the two named WORLD submissions.
	for peer in 2:
		var empty_story := await _route_story(peer)
		if not _require(_route_state(empty_story, false, false, false, false),
				"peer %d starts without route keys/unlock or personal copies" % peer):
			quit(await finish())
			return

	for flag: String in [STORMWOOD_KEY, WATER_UNLOCK]:
		var seeded: Dictionary = await step(0, "story_flag", {"flag": flag, "scope": "world"})
		if not _require(_passed(seeded),
				"host ledger seeds fixture prerequisite %s (%s)" % [flag, _detail(seeded)]):
			quit(await finish())
			return
	for peer in 2:
		for flag: String in [STORMWOOD_KEY, WATER_UNLOCK]:
			var visible: Dictionary = await step(peer, "wait_flag", {
				"flag": flag, "scope": "world",
			})
			if not _require(_passed(visible),
					"peer %d sees replicated WORLD prerequisite %s" % [peer, flag]):
				quit(await finish())
				return

	var before: Array[Dictionary] = []
	for peer in 2:
		var story := await _route_story(peer)
		if not _require(_route_state(story, true, true, false, false),
				"peer %d sees both WORLD prerequisites, no Water key, and no personal copy" % peer):
			quit(await finish())
			return
		before.append(story)

	var moved: Dictionary = await step(1, "move_to", {
		"x": GATE_STANCE.x, "z": GATE_STANCE.y, "close_enough": 0.9,
	})
	if not _require(_passed(moved),
			"connected client reaches the real Water return gate through ordinary movement (%s)"
				% _detail(moved)):
		quit(await finish())
		return

	var pressed: Dictionary = await step(1, "press", {"action": "interact"})
	if not _require(_passed(pressed),
			"connected client sends ordinary Interact at the physical gate (%s)" % _detail(pressed)):
		quit(await finish())
		return
	# The gate issues its router request asynchronously. Poll the read-only
	# destination state inside the same frame budget used by the existing
	# focused Stormwood transition smoke; this never calls the router directly.
	var client_realm := await _await_client_completion()
	if not _require(str(client_realm.get("current", "")) == STORMWOOD
			and str(client_realm.get("scene", "")) == "Stormwood"
			and bool(client_realm.get("world_ready", false))
			and str(client_realm.get("pending_entry", "<missing>")).is_empty(),
			"ordinary gate interaction completes in the production Stormwood scene"):
		quit(await finish())
		return
	var arrival_raw: Variant = await probe(1, "position")
	var on_floor: Variant = await probe(1, "on_floor")
	var authored_arrival := _authored_stormheart_arrival()
	var arrival := Vector3.ZERO
	var has_arrival := arrival_raw is Array and (arrival_raw as Array).size() == 3
	if has_arrival:
		var values := arrival_raw as Array
		arrival = Vector3(float(values[0]), float(values[1]), float(values[2]))
	if not _require(has_arrival
			and Vector2(arrival.x, arrival.z).distance_to(
				Vector2(authored_arrival.x, authored_arrival.z)) <= 0.75
			and absf(arrival.y - authored_arrival.y) <= 0.5
			and on_floor is bool and bool(on_floor),
			"completed client arrival is grounded at the authored Stormheart return anchor"):
		quit(await finish())
		return
	var host_realm: Variant = await probe(0, "realm")
	if not _require(host_realm is Dictionary
			and str((host_realm as Dictionary).get("current", "")) == WATER
			and str((host_realm as Dictionary).get("scene", "")) == "WaterArchipelago",
			"host and other player remain in the production Water scene"):
		quit(await finish())
		return

	for peer in 2:
		var realm_view: Variant = host_realm if peer == 0 else client_realm
		var registry: Dictionary = (realm_view as Dictionary).get("peers", {}) as Dictionary
		var occupied: Array = (realm_view as Dictionary).get("occupied", []) as Array
		var realms: Array = registry.values()
		realms.sort()
		occupied.sort()
		if not _require(registry.size() == 2 and realms == [STORMWOOD, WATER]
				and occupied == [STORMWOOD, WATER],
				"peer %d registry records one member in Water and one in Stormwood" % peer):
			quit(await finish())
			return

	for peer in 2:
		var live: Variant = await probe(peer, "session")
		if not _require(live is Dictionary
				and bool((live as Dictionary).get("active", false))
				and int((live as Dictionary).get("peer_count", 0)) == 2,
				"peer %d keeps the two-peer session active through the return" % peer):
			quit(await finish())
			return

	var shells := await _await_stormwood_shell()
	var rows: Dictionary = shells.get("realms", {}) as Dictionary
	var storm_shell: Dictionary = rows.get(STORMWOOD, {}) as Dictionary
	if not _require(_shell_realms(shells) == [STORMWOOD]
			and bool(storm_shell.get("ready", false))
			and int(storm_shell.get("bodies", 0)) == 1,
			"host owns one ready Stormwood shell containing the departed client"):
		quit(await finish())
		return
	var client_shells: Variant = await probe(1, "realm_shells")
	if not _require(client_shells is Dictionary and _shell_realms(client_shells).is_empty(),
			"client owns no simulation shells; shell authority remains on the host"):
		quit(await finish())
		return

	for peer in 2:
		var after := await _route_story(peer)
		if not _require(_route_state(after, true, true, false, false)
				and JSON.stringify(after.get("world", {})) == JSON.stringify(before[peer].get("world", {}))
				and JSON.stringify(after.get("player", {})) == JSON.stringify(before[peer].get("player", {})),
				"peer %d retains unchanged WORLD route facts with no personal copy" % peer):
			quit(await finish())
			return

	quit(await finish())


func _route_story(peer: int) -> Dictionary:
	var result: Variant = await probe(peer, "story", {
		"world_flags": ROUTE_FLAGS,
		"player_flags": ROUTE_FLAGS,
	})
	return result if result is Dictionary else {}


func _await_client_completion() -> Dictionary:
	var last: Dictionary = {}
	var waited_frames := 0
	while waited_frames < REALM_STEP_BUDGET:
		var result: Variant = await probe(1, "realm")
		last = result if result is Dictionary else {}
		if str(last.get("current", "")) == STORMWOOD \
				and str(last.get("scene", "")) == "Stormwood" \
				and bool(last.get("world_ready", false)) \
				and str(last.get("pending_entry", "<missing>")).is_empty():
			print("WATER RETURN NET COMPLETION: explicit_wait_frames=%d budget_frames=%d"
				% [waited_frames, REALM_STEP_BUDGET])
			return last
		var batch := mini(60, REALM_STEP_BUDGET - waited_frames)
		var waited: Dictionary = await step(1, "wait", {"frames": batch})
		if not _passed(waited):
			return last
		waited_frames += batch
	return last


func _authored_stormheart_arrival() -> Vector3:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_world.json"))
	if not (parsed is Dictionary):
		return Vector3.INF
	var transitions: Dictionary = (parsed as Dictionary).get("transition_points", {}) as Dictionary
	var spec: Dictionary = transitions.get("water_departure", {}) as Dictionary
	var raw: Array = spec.get("position", []) as Array
	if str(spec.get("id", "")) != "stormwood_departure_to_water" or raw.size() < 3:
		return Vector3.INF
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _route_state(story: Dictionary, stormwood_key: bool, water_unlock: bool,
		water_key: bool, any_personal: bool) -> bool:
	var world: Dictionary = story.get("world", {}) as Dictionary
	var player: Dictionary = story.get("player", {}) as Dictionary
	return bool(world.get(STORMWOOD_KEY, false)) == stormwood_key \
		and bool(world.get(WATER_UNLOCK, false)) == water_unlock \
		and bool(world.get(WATER_KEY, false)) == water_key \
		and bool(player.get(STORMWOOD_KEY, false)) == any_personal \
		and bool(player.get(WATER_UNLOCK, false)) == any_personal \
		and bool(player.get(WATER_KEY, false)) == any_personal


func _await_stormwood_shell() -> Dictionary:
	var last: Dictionary = {}
	# Identical polling allowance to smoke_net_stormwood_realms.gd.
	for _tick in 120:
		var report: Variant = await probe(0, "realm_shells")
		last = report if report is Dictionary else {}
		var rows: Dictionary = last.get("realms", {}) as Dictionary
		var storm: Dictionary = rows.get(STORMWOOD, {}) as Dictionary
		if bool(storm.get("ready", false)):
			return last
		var waited: Dictionary = await step(0, "wait", {"frames": 60})
		if not _passed(waited):
			return last
	return last


static func _shell_realms(report: Variant) -> Array:
	if not (report is Dictionary):
		return []
	var realms: Variant = (report as Dictionary).get("realms", {})
	if not (realms is Dictionary):
		return []
	var out: Array = (realms as Dictionary).keys()
	out.sort()
	return out


func _require(condition: bool, message: String) -> bool:
	check(condition, message)
	return condition


static func _passed(verdict: Dictionary) -> bool:
	return str(verdict.get("verdict", "")) == "PASS"


static func _detail(verdict: Dictionary) -> String:
	return str(verdict.get("detail", ""))
