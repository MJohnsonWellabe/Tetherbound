extends "res://tests/helpers/net_harness.gd"

# peers: 2

## The host walks into a realm FIRST, and the guest follows it there.
##
##   tools/net/run_net_smoke.sh net_session_host_first_realm
##
## `smoke_net_split_realms.gd` only ever sends the client over first; its
## late host crossing goes to a realm the client has already left. The
## Cloudreach lane found the opposite order broken: with the host already
## in Cloudreach and the guest still in the Meadows, the guest logged
## `Node not found: "CloudreachCliffs/Spawned/TrainerSpawner"`, then, after it
## arrived, `ID ... not found in cache of peer 1` and `Parameter "spawner" is
## null`, and the two players could not see each other.
##
## The run: handshake in the Meadows, open the Cloudreach route, the HOST
## crosses, the guest (still in the Meadows) must receive nothing addressed to
## a Cloudreach spawner, then the guest crosses and each peer must draw the
## other in the Cloudreach scene on its own screen.

const REALM_STEP_BUDGET_S := 1200.0
const MEADOWS := "meadows"
const CLOUDREACH := "cloudreach"
const CLOUDREACH_KEY_FLAG := "realm_key_cloudreach"


func _initialize() -> void:
	_run()


func _run() -> void:
	require_peer_logs_without([
		'Node not found: "CloudreachCliffs/Spawned/',
		"not found in cache of peer",
		'Parameter "spawner" is null',
		"Failed to get cached node from peer",
	], "host-first crossing leaves no misaddressed spawn or cache errors")
	if not await launch(2, "world"):
		quit(await finish())
		return
	check(_peers.size() == 2, "coordinator tracked 2 peers")
	_step_phase_deadline_ms = Time.get_ticks_msec() + REALM_STEP_BUDGET_S * 1000.0

	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session, "a Session exists to host/join")
	if not have_session:
		quit(await finish())
		return
	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])

	var keyed: Dictionary = await step(0, "story_flag",
		{"flag": CLOUDREACH_KEY_FLAG, "scope": "world"})
	check(str(keyed.get("verdict", "")) == "PASS",
		"the Cloudreach route is open (%s)" % str(keyed.get("detail", "")))
	for i in 2:
		var flag: Dictionary = await step(i, "wait_flag", {"flag": CLOUDREACH_KEY_FLAG})
		check(str(flag.get("verdict", "")) == "PASS",
			"peer %d sees the Cloudreach route open (%s)" % [i, str(flag.get("detail", ""))])

	var budget_frames := int(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES)) * 4

	# 1. The HOST crosses first. The guest stays in the Meadows.
	var host_crossed: Dictionary = await step(0, "enter_realm", {"realm": CLOUDREACH}, budget_frames)
	check(str(host_crossed.get("verdict", "")) == "PASS",
		"the host crossed into Cloudreach first (%s)" % str(host_crossed.get("detail", "")))
	if str(host_crossed.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var host_realm = await probe(0, "realm")
	check(host_realm is Dictionary and str((host_realm as Dictionary).get("current", "")) == CLOUDREACH,
		"the host is standing in Cloudreach")
	var guest_realm = await probe(1, "realm")
	check(guest_realm is Dictionary and str((guest_realm as Dictionary).get("current", "")) == MEADOWS,
		"the guest is still standing in the Meadows")
	# Give any misaddressed spawn/delta time to reach the guest before it
	# builds a Cloudreach of its own, so the log check above can see it.
	await step(1, "wait", {"frames": 120})
	# Anywhere in the guest's tree, not just its current scene: the guest runs
	# no shells, so any body it holds for somebody else is in the Meadows.
	var guest_meadows_bodies = await probe(1, "remote_trainers")
	check(_others(guest_meadows_bodies, false).is_empty(),
		"the guest in the Meadows holds no body for the host in Cloudreach (holds %d)"
			% _others(guest_meadows_bodies, false).size())

	# 2. The guest follows.
	var guest_crossed: Dictionary = await step(1, "enter_realm", {"realm": CLOUDREACH}, budget_frames)
	check(str(guest_crossed.get("verdict", "")) == "PASS",
		"the guest followed the host into Cloudreach (%s)" % str(guest_crossed.get("detail", "")))
	if str(guest_crossed.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	for i in 2:
		var still = await probe(i, "session")
		var d: Dictionary = still if still is Dictionary else {}
		check(bool(d.get("active", false)) and int(d.get("peer_count", 0)) == 2,
			"peer %d is still in a 2-peer session after both crossings (%s)" % [i, str(d.get("peer_count", 0))])
		var realm = await probe(i, "realm")
		check(realm is Dictionary and str((realm as Dictionary).get("scene", "")) == "CloudreachCliffs",
			"peer %d's current scene is Cloudreach" % i)

	# 3. Each sees the other, in Cloudreach, on its own screen. Replication
	#    can take a few frames after the guest's world finishes building.
	for i in 2:
		var others := await _await_others_drawn(i, 1, 30)
		check(others.size() == 1,
			"peer %d draws exactly one other trainer in Cloudreach (drew %d)" % [i, others.size()])
		if others.size() == 1:
			check(bool((others[0] as Dictionary).get("visible", false)),
				"peer %d's view of the other trainer is visible" % i)

	quit(await finish())


func _await_others_drawn(peer: int, want: int, seconds: int) -> Array:
	var deadline := Time.get_ticks_msec() + seconds * 1000
	var last: Array = []
	while Time.get_ticks_msec() < deadline:
		last = _others(await probe(peer, "remote_trainers"), true)
		if last.size() == want:
			return last
		await step(peer, "wait", {"frames": 30})
	return last


## Bodies this process holds for other players; `on_screen` keeps only those
## under its current scene (the host also holds bodies in headless shells).
static func _others(bodies: Variant, on_screen: bool) -> Array:
	var out: Array = []
	if not (bodies is Dictionary):
		return out
	for key in (bodies as Dictionary).keys():
		var row: Variant = (bodies as Dictionary)[key]
		if row is Dictionary and not bool((row as Dictionary).get("mine", false)) \
				and (not on_screen or bool((row as Dictionary).get("in_current_scene", false))):
			out.append(row)
	return out
