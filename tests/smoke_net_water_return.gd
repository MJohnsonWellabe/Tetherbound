extends "res://tests/helpers/net_harness.gd"

# peers: 2

## REDESIGN (RD-10/RD-17/RD-22): a Tidewake (Water) player reaches Stormwood
## only through the Crossing Hall. The old physical Water -> Stormwood return
## gate is retired under the shipped config (portal runtime on): the connected
## client walks to it and presses Interact, and it must refuse and move nobody;
## the client then raises the Home Key to the Hall and takes the Stormwood
## arch (tools/net/portal_smoke_travel.gd, regression "water_return"), while
## the host stays in Water. The registry/session/shell assertions about one
## member in each realm are unchanged; the arrival is the Stormwood portal
## entry (portals.json arch entry_id stormwood_arrival_from_cloudreach), not
## the retired Stormheart return anchor.
##
## Fixture-only network proof, not earned campaign evidence. Both peers boot
## the production Water scene. DISCLOSED FIXTURE, before host/join on each
## peer: portal_smoke_travel.prepare (initial grounded Water pose, the
## Stormwood arch open for the world, one initial Home Key; no earned credit).

const WATER := "water"
const STORMWOOD := "stormwood"
const ARCH := "stormwood"
const FIXTURE := "initial_hall_position_and_open_route_no_earned_credit"
const REGRESSION := "water_return"
## Retired legacy route facts: the shipped portal path neither reads nor
## writes them, so they must stay absent everywhere.
const RETIRED_FLAGS: Array[String] = ["realm_key_stormwood", "realm_gate_water_unlocked", "realm_key_water"]
## Same production transition budget the focused Stormwood realm smoke uses
## for one crossing; the whole portal action (retired-gate settle, Home Key
## trip, Hall walk and Stormwood arch) must fit inside it.
const REALM_STEP_BUDGET := 10000
## water_world.json places the gate at (12, 162) and RealmGate places its
## Interactable 0.72 m forward. This is the same 2.2 m physical stance derived
## by the single-process proof, on the First Shore side of the threshold.
const GATE_STANCE := Vector2(9.8, 162.72)
const ARRIVAL_TOLERANCE_M := 0.75


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

	# DISCLOSED FIXTURE, before admission (portal_smoke_travel.prepare): the
	# grounded initial Water pose, the Stormwood arch open for this world and
	# one initial Home Key. No earned chapter credit, permit or ACK.
	for peer in 2:
		var prepared: Dictionary = await step(peer, "enter_realm", {"realm": WATER,
			"actual_portal_fixture": FIXTURE, "portal_regression": REGRESSION,
			"portal_prepare_only": true}, 3000)
		if not _require(_passed(prepared),
				"peer %d: disclosed initial Hall route fixture (%s)" % [peer, _detail(prepared)]):
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

	var before: Array[Dictionary] = []
	for peer in 2:
		var story := await _route_story(peer)
		if not _require(_retired_absent(story),
				"peer %d holds none of the retired physical-route keys/unlocks" % peer):
			quit(await finish())
			return
		before.append(story)

	# The retired physical gate: ordinary movement and Interact, which the
	# shipped config must refuse (portal_smoke_travel observes the refusal
	# settle in Water before it raises the Home Key).
	var moved: Dictionary = await step(1, "move_to", {
		"x": GATE_STANCE.x, "z": GATE_STANCE.y, "close_enough": 0.9,
	})
	if not _require(_passed(moved),
			"connected client reaches the retired Water return gate through ordinary movement (%s)"
				% _detail(moved)):
		quit(await finish())
		return
	var pressed: Dictionary = await step(1, "press", {"action": "interact"})
	if not _require(_passed(pressed),
			"connected client sends ordinary Interact at the retired physical gate (%s)" % _detail(pressed)):
		quit(await finish())
		return

	# Home Key to the Hall, walk to the Stormwood arch, public portal request.
	var travelled: Dictionary = await step(1, "enter_realm", {"realm": STORMWOOD,
		"actual_portal_fixture": FIXTURE, "portal_regression": REGRESSION,
		"budget_frames": REALM_STEP_BUDGET}, REALM_STEP_BUDGET)
	if not _require(_passed(travelled),
			"retired gate refused; the client reached Stormwood by Home Key and the Hall's Stormwood arch (%s)"
				% _detail(travelled)):
		quit(await finish())
		return
	var client_realm := await _await_client_completion()
	if not _require(str(client_realm.get("current", "")) == STORMWOOD
			and str(client_realm.get("scene", "")) == "Stormwood"
			and bool(client_realm.get("world_ready", false))
			and str(client_realm.get("pending_entry", "<missing>")).is_empty(),
			"the portal trip completes in the production Stormwood scene"):
		quit(await finish())
		return
	var arrival_raw: Variant = await probe(1, "position")
	var on_floor: Variant = await probe(1, "on_floor")
	var arrival := Vector3.INF
	if arrival_raw is Array and (arrival_raw as Array).size() == 3:
		var values := arrival_raw as Array
		arrival = Vector3(float(values[0]), float(values[1]), float(values[2]))
	var slot_distance := _nearest_portal_slot_m(arrival)
	if not _require(slot_distance <= ARRIVAL_TOLERANCE_M
			and on_floor is bool and bool(on_floor),
			"client arrival is grounded at the authored Stormwood portal entry or one of its co-op slots (%.2f m, at %s)"
				% [slot_distance, str(arrival)]):
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
				"peer %d keeps the two-peer session active through the trip" % peer):
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
		if not _require(_retired_absent(after)
				and JSON.stringify(after.get("world", {})) == JSON.stringify(before[peer].get("world", {}))
				and JSON.stringify(after.get("player", {})) == JSON.stringify(before[peer].get("player", {})),
				"peer %d: the portal trip wrote none of the retired route facts" % peer):
			quit(await finish())
			return

	quit(await finish())


func _route_story(peer: int) -> Dictionary:
	var result: Variant = await probe(peer, "story", {
		"world_flags": RETIRED_FLAGS,
		"player_flags": RETIRED_FLAGS,
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


## Distance from `at` (XZ) to the nearest production arrival slot of the
## Stormwood arch's authored entry: the anchor first, then portals.json's
## co-op ring (foundation_portal_arrival.gd::arrival_slots).
func _nearest_portal_slot_m(at: Vector3) -> float:
	if not at.is_finite():
		return INF
	var portals: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/portals.json"))
	var entry_id := ""
	if portals is Dictionary:
		for arch: Variant in (portals as Dictionary).get("arches", []):
			if arch is Dictionary and str((arch as Dictionary).get("id", "")) == ARCH:
				entry_id = str((arch as Dictionary).get("entry_id", ""))
	var world: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_world.json"))
	var anchor := Vector3.INF
	if world is Dictionary and not entry_id.is_empty():
		var points: Dictionary = (world as Dictionary).get("transition_points", {}) as Dictionary
		for key: Variant in points:
			var spec: Variant = points[key]
			if spec is Dictionary and str((spec as Dictionary).get("id", "")) == entry_id:
				var raw: Array = (spec as Dictionary).get("position", []) as Array
				if raw.size() >= 3:
					anchor = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	if not anchor.is_finite():
		return INF
	var best := INF
	for slot: Vector3 in preload("res://scripts/net/foundation_portal_arrival.gd").arrival_slots(anchor):
		best = minf(best, Vector2(at.x, at.z).distance_to(Vector2(slot.x, slot.z)))
	return best


func _retired_absent(story: Dictionary) -> bool:
	var world: Dictionary = story.get("world", {}) as Dictionary
	var player: Dictionary = story.get("player", {}) as Dictionary
	if story.is_empty():
		return false
	for flag: String in RETIRED_FLAGS:
		if bool(world.get(flag, false)) or bool(player.get(flag, false)):
			return false
	return true


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
