extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F44#2: an alpha respawns after the configured in-game days with freshly
## rolled traits, across two real ENet peers.
##
##   tools/net/run_net_smoke.sh f44_alpha_respawn
##
## The host engages the Pond's Alpha Mosshell (wild_once_1900); the guest
## joins and defeats it with real host-accepted strikes. Its retained cycle then waits: neither the configured
## days alone nor a departure alone respawns it; once the days have passed and
## every trainer who was in the region has left it, generation 2 spawns with a
## new roll, and both peers see that one body when they return.
## Disclosed fixtures: party_grant seeds a strong guest creature before
## networking; f44_stand places trainers on the ground at fixed points; the
## guest walks to the fight by move_to; place_creature stands the guest
## creature beside the opponent before each
## strike (as smoke_net_f27_guest_wild_win does); mornings are the host's own
## Game.advance_day.
const SITE := "wild_once_1900"
const SITE_XZ := [-318.0, 505.0]
const BESIDE_XZ := [-310.0, 498.0]
const AWAY_XZ := [-318.0, 1500.0] # band2_stone_and_root
const SWINGS := 60

var _port := 0
var _encounter_id := ""


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 2400.0 * 1000.0
	if await _start():
		await _proof()
	quit(await finish())


func _start() -> bool:
	for peer in 2:
		if not await _pass(peer, "boot", {"scene": "world"}, 30000): return false
	if not await _pass(0, "party_grant", {"species": "bramblebun", "level": 5}): return false
	if not await _pass(1, "party_grant", {"species": "terrapup", "level": 40}): return false
	var saved: Dictionary = await step(1, "save_character_here", {})
	var guest_id := str((saved.get("data", {}) as Dictionary).get("character_id", ""))
	if not await _pass(0, "host", {}): return false
	_port = int(((await probe(0, "session")) as Dictionary).get("enet_port", 0))
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": _port,
			"character": {"character_id": guest_id, "display_name": "Alpha Guest"}}, 6000): return false
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return false
	for peer in 2:
		if not await _pass(peer, "f27_dismiss_modals", {}): return false
	return true


func _proof() -> void:
	# Generation 1 becomes resident beside both trainers.
	for peer in 2:
		if not await _pass(peer, "f44_stand", {"at": BESIDE_XZ}): return
	var first := await _wait_live(0, 1)
	check(first.get("cycle", {}).get("status") == "active" and int(first.get("cycle", {}).get("generation", 0)) == 1,
		"host retains an active generation-1 cycle (%s)" % str(first.get("cycle")))
	if not _one_live(first, 1, "host generation 1"): return
	var first_traits: Array = first.cycle.get("spawn_traits", {}).get("rolled_traits", [])
	check(not first_traits.is_empty() and first.live[0].traits == first_traits,
		"the live alpha carries the retained roll (%s)" % str(first_traits))
	var guest_first := await _wait_live(1, 1)
	if not _one_live(guest_first, 1, "guest generation 1"): print("F44 guest near site: %s" % str(guest_first.get("diagnostics", {}).get("near_site")))
	# Defeat it: the host engages; the guest joins and lands real
	# host-accepted strikes, as smoke_net_f27_guest_wild_win does.
	for peer in 2:
		if not await _pass(peer, "deploy_creature", {}): return
	if not await _pass(0, "engage_wild", {"foundation_alpha_site": SITE}): return
	var host_view: Dictionary = await _encounter(0)
	_encounter_id = str(host_view.get("id", ""))
	var here := _vec(host_view.get("opponent_pos", []))
	if here == Vector3.INF: return
	var announced := false
	for _poll in 16:
		announced = ((await _encounter(1)).get("joinable", []) as Array).has(_encounter_id)
		if announced: break
		await step(1, "wait", {"frames": 15})
	check(announced, "the guest was told the alpha fight exists")
	await step(1, "move_to", {"x": here.x - 2.5, "z": here.z, "close_enough": 4.0, "budget_frames": 2400})
	if not await _pass(1, "join_encounter", {"encounter_id": _encounter_id}): return
	var done := false
	for swing in SWINGS:
		var view: Dictionary = await _encounter(0)
		if str(view.get("phase", "")) == "done" or float(view.get("opponent_hp", 1.0)) <= 0.0:
			done = true
			break
		var opponent := _vec(view.get("opponent_pos", []))
		if opponent == Vector3.INF: break
		var stand := opponent + Vector3(0.0, 0.0, 3.5)
		await step(1, "place_creature", {"at": [stand.x, stand.y, stand.z], "face": [opponent.x, opponent.y, opponent.z], "settle": 15})
		var toward := opponent - stand
		await step(1, "strike", {"facing": [toward.x, toward.y, toward.z], "slot": "quick", "settle": 20})
	check(done, "real host-accepted strikes brought the alpha down")
	if not done: return
	var waiting := await _wait_status("waiting", 1)
	var cycle: Dictionary = waiting.get("cycle", {})
	if cycle.get("status") != "waiting": print("F44 diagnostics after defeat: %s" % str(waiting.get("diagnostics")))
	check(cycle.get("status") == "waiting" and (cycle.get("required_departures", []) as Array).size() == 2,
		"the defeat leaves a waiting cycle that needs both trainers to leave the region (%s)" % str(cycle))
	# Days alone do not respawn it while the trainers are still here.
	var days := int(_respawn_days())
	if not await _pass(0, "f44_advance_days", {"days": days}): return
	await step(0, "wait", {"frames": 180})
	var still := await _view(0)
	check(still.cycle.get("status") == "waiting" and still.live.is_empty(),
		"after %d days with both trainers present nothing respawns (%s)" % [days, str(still.cycle.get("status"))])
	# Both leave the region; the days have passed, so generation 2 spawns.
	for peer in 2:
		if not await _pass(peer, "f44_stand", {"at": AWAY_XZ}): return
	var respawned := await _wait_status("active", 2)
	var next: Dictionary = respawned.get("cycle", {})
	var next_traits: Array = next.get("spawn_traits", {}).get("rolled_traits", [])
	check(next.get("status") == "active" and int(next.get("generation", 0)) == 2,
		"once every trainer left, generation 2 spawned (%s)" % str(next.get("status")))
	check((next.get("departed", []) as Array).size() == 2, "both departures were recorded (%s)" % str(next.get("departed")))
	check(not next_traits.is_empty() and next.get("spawn_traits", {}).get("captured_from", {}).get("spawn_generation") == 2,
		"generation 2 carries its own fresh alpha roll (%s, was %s)" % [str(next_traits), str(first_traits)])
	# Both peers see the one new body when they return.
	for peer in 2:
		if not await _pass(peer, "f44_stand", {"at": BESIDE_XZ}): return
	var host_back := await _wait_live(0, 2)
	if _one_live(host_back, 2, "host generation 2"):
		check(host_back.live[0].traits == next_traits, "the host's live generation-2 body carries the new roll")
	var guest_back := await _wait_live(1, 2)
	if not _one_live(guest_back, 2, "guest generation 2"): print("F44 guest gen2 diagnostics: cycle %s %s" % [str(guest_back.get("cycle")), str(guest_back.get("diagnostics"))])
	print("F44_NET_ALPHA_RESPAWN: defeat, %d-day wait, departures, fresh generation 2 on both peers" % days)


func _respawn_days() -> int:
	return int(preload("res://scripts/repeatables/alpha_respawns.gd").config().get("respawn_days", 0))


func _one_live(view: Dictionary, generation: int, label: String) -> bool:
	var live: Array = view.get("live", [])
	var ok := live.size() == 1 and int(live[0].generation) == generation
	check(ok, "%s: exactly one live alpha body of generation %d (%s)" % [label, generation, str(view.get("bodies"))])
	return ok


func _wait_live(peer: int, generation: int) -> Dictionary:
	var view: Dictionary = {}
	for attempt in 40:
		view = await _view(peer)
		for body: Dictionary in view.get("live", []):
			if int(body.generation) == generation: return view
		await step(peer, "wait", {"frames": 30})
	return view


func _wait_status(status: String, generation: int) -> Dictionary:
	var view: Dictionary = {}
	for attempt in 60:
		view = await _view(0)
		if view.get("cycle", {}).get("status") == status and int(view.get("cycle", {}).get("generation", 0)) == generation: return view
		await step(0, "wait", {"frames": 30})
	return view


func _view(peer: int) -> Dictionary:
	var data: Dictionary = (await step(peer, "f44_alpha_view", {"site_id": SITE, "encounter_id": _encounter_id})).get("data", {})
	return data


func _encounter(peer: int) -> Dictionary:
	var value = await probe(peer, "encounter")
	return value if value is Dictionary else {}


func _vec(raw: Variant) -> Vector3:
	if not raw is Array or (raw as Array).size() != 3: return Vector3.INF
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _ok(result: Dictionary, label: String) -> bool:
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "%s: %s" % [label, str(result.get("detail", ""))])
	return passed


func _pass(peer: int, action: String, args: Dictionary, budget: int = -1) -> bool:
	return _ok(await step(peer, action, args, budget), "peer %d %s" % [peer, action])
