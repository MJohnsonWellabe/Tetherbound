extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F22 / COMBAT §4 forced break, guest path (owner ruling 2026-10-05).
##
##   tools/net/run_net_smoke.sh f22_forced_break
##
## A guest's charged hit into the shared wild's tell forces a break only when
## the guest's host-COMMITTED charge start came after the tell became visible
## on the host, less `forced_break_grace_s`. The host compares its own two
## ticks, so link latency and travel never widen the read window. Two real
## processes, the production move_start -> strike_intent -> host_roll_damage
## path, and one shared wild:
##
##   (a) the host pins its real wild body in a long tell, THEN the guest
##       commits a charge: the host breaks it, and the guest's own manager
##       announces the same stagger from the host's payload.
##   (b) the guest commits a charge, waits well past the grace, THEN the host
##       pins the tell and the committed charge lands: the host does not
##       break the wild (its pool drains instead) and the guest announces no
##       stagger either.
##
## The pin is a host-side fixture (`f22_pin_tell` in tools/net/peer_runner.gd):
## a tell visible from that host tick and a pool too deep to break by drain,
## so only a forced break can stagger the body.

const ANNOUNCE_POLLS := 40
const STAGGER_POLLS := 30
## Where the guest's creature stands from the wild's centre: inside a charged
## reach for the two body radii, well clear of the host's creature.
const STAND_OFF_M := 2.6
const PLACE_SETTLE := 20
## Frames between the guest's committed start and the host's pin in case (b):
## comfortably more than the 0.1 s grace even before coordinator round trips.
const EARLY_START_FRAMES := 30
const COOLDOWN_FRAMES := 150
## A charged move costs a full Energy meter, earned only by LANDED quick hits.
const ENERGY_HITS := 6
const QUICK_SWINGS := 12

## Explicit, monotonic action ids: each start and its strike share one, so the
## host matches the strike to its own committed start.
var _action := 9000
var _encounter_id := ""


func _initialize() -> void:
	_run()


func _init_budgets() -> void:
	super._init_budgets()
	# Two full world builds can exceed the ordinary startup bound on a loaded
	# machine. Gameplay bounds stay.
	_budgets["hello_budget_s"] = 600.0
	_budgets["smoke_step_budget_s_2peer"] = 1500.0


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return
	check(_peers.size() == 2, "coordinator tracked 2 peers")
	for i in 2:
		var granted: Dictionary = await step(i, "party_grant", {"species": "terrapup"})
		check(str(granted.get("verdict", "")) == "PASS",
			"peer %d owns a creature before the session (%s)" % [i, str(granted.get("detail", ""))])
	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS", "peer 0 hosted (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS", "peer 1 joined (%s)" % str(joined.get("detail", "")))
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS", "peer %d sees both players" % i)
	for i in 2:
		var deployed: Dictionary = await step(i, "deploy_creature", {})
		check(str(deployed.get("verdict", "")) == "PASS",
			"peer %d deployed its creature (%s)" % [i, str(deployed.get("detail", ""))])
	var engaged: Dictionary = await step(0, "engage_wild", {})
	check(str(engaged.get("verdict", "")) == "PASS", "peer 0 engaged a wild (%s)" % str(engaged.get("detail", "")))
	if str(engaged.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	var host_view: Dictionary = await _encounter(0)
	var encounter_id := str(host_view.get("id", ""))
	_encounter_id = encounter_id
	var guest_view: Dictionary = await _encounter(1)
	for _wait in ANNOUNCE_POLLS:
		if (guest_view.get("joinable", []) as Array).has(encounter_id):
			break
		await step(1, "wait", {"frames": 15})
		guest_view = await _encounter(1)
	var here := _vec(host_view.get("opponent_pos", []))
	if here == Vector3.INF:
		check(false, "the announcement says where the fight is")
		quit(await finish())
		return
	await step(1, "teleport", {"at": [here.x - 2.5, here.y + 1.0, here.z]})
	var joined_fight: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(str(joined_fight.get("verdict", "")) == "PASS",
		"peer 1 joined the shared wild fight (%s)" % str(joined_fight.get("detail", "")))
	await step(1, "f22_enemy_staggers", {})

	# (a) Tell first, then the committed charge: a read.
	var read := await _charge_case(true)
	check(bool(read.host_staggered),
		"(a) a charge committed after the tell breaks the wild on the host (%s)" % str(read))
	check(int(read.guest_staggers) == 1,
		"(a) the guest's manager announces the same break from the host payload (%s)" % str(read))
	await step(1, "wait", {"frames": COOLDOWN_FRAMES})

	# (b) Charge committed well before the tell: drains, never breaks.
	var blind := await _charge_case(false)
	check(bool(blind.landed), "(b) the early-committed charge landed on the host (%s)" % str(blind))
	check(not bool(blind.host_staggered),
		"(b) a charge committed %d+ frames before the tell does not force a break (%s)" % [EARLY_START_FRAMES, str(blind)])
	check(float(blind.poise_after) < float(blind.poise_before) - 0.001,
		"(b) its blow drained poise normally instead (%s)" % str(blind))
	check(int(blind.guest_staggers) == 0,
		"(b) the guest announces no break either: both peers resolve the same verdict (%s)" % str(blind))
	quit(await finish())


## One guest charge into the host's pinned tell. `tell_first` pins before the
## move_start; otherwise the start is committed, the grace allowed to pass, and
## only then is the tell pinned and the committed strike delivered.
func _charge_case(tell_first: bool) -> Dictionary:
	var pin: Dictionary = (await _pin(true)).get("data", {})
	var centre := _vec(pin.get("centre", []))
	var out := {"landed": false, "host_staggered": false, "guest_staggers": -1,
		"poise_before": 0.0, "poise_after": 0.0, "since_ms": -1}
	if centre == Vector3.INF:
		return out
	var stand := centre + Vector3(0.0, 0.0, STAND_OFF_M)
	await step(1, "place_creature", {"at": [stand.x, stand.y, stand.z],
		"face": [centre.x, centre.y, centre.z], "settle": PLACE_SETTLE})
	# Build the guest's Energy with real landed quick hits on the pinned body.
	await _pin(false)
	var landed := 0
	for _swing in QUICK_SWINGS:
		if landed >= ENERGY_HITS: break
		# Re-pin (and refill HP) before every swing: the fight must outlive them.
		var hp_was := float(((await _pin(false)).get("data", {}) as Dictionary).get("hp", -1.0))
		_action += 1
		await step(1, "strike", {"target": [centre.x, centre.y, centre.z], "slot": "quick",
			"action": _action, "settle": 15})
		await step(1, "wait", {"frames": 30})
		if await _host_hp() < hp_was - 0.001: landed += 1
	out["energy_hits"] = landed
	var breaks_before := int(((await _pin(true)).get("data", {}) as Dictionary).get("host_breaks", 0))
	var guest_before := int(((await step(1, "f22_enemy_staggers", {})).get("data", {}) as Dictionary).get("count", 0))
	var hp_before := -1.0
	if tell_first:
		pin = (await _pin(false)).get("data", {})
		out.since_ms = int(pin.get("since_ms", -1))
		out.poise_before = float(pin.get("poise", 0.0))
		hp_before = float(pin.get("hp", -1.0))
		_action += 1
		await step(1, "strike", {"target": [centre.x, centre.y, centre.z], "slot": "charged",
			"action": _action, "settle": 15})
	else:
		_action += 1
		var action := _action
		await step(1, "strike", {"target": [centre.x, centre.y, centre.z],
			"slot": "charged", "action": action, "start_only": true})
		await step(1, "wait", {"frames": EARLY_START_FRAMES})
		var pinned := await _pin(false)
		pin = pinned.get("data", {})
		if pin.is_empty(): out["pin"] = "%s: %s" % [str(pinned.get("verdict", "")), str(pinned.get("detail", ""))]
		out.since_ms = int(pin.get("since_ms", -1))
		out.poise_before = float(pin.get("poise", 0.0))
		hp_before = float(pin.get("hp", -1.0))
		await step(1, "strike", {"target": [centre.x, centre.y, centre.z], "slot": "charged",
			"action": action, "move_start": false, "windup_wait": true, "settle": 15})
	var state: Dictionary = {}
	for _poll in STAGGER_POLLS:
		state = (await _pin(true)).get("data", {})
		if int(state.get("host_breaks", 0)) > breaks_before or float(state.get("poise", 0.0)) < float(out.poise_before) - 0.001:
			break
		await step(0, "wait", {"frames": 4})
	# Counted from the host's own strike verdicts (`host_strike_finished`), so
	# a 0.6 s stagger that ended before this read still counts.
	out.host_staggered = int(state.get("host_breaks", 0)) > breaks_before
	out.poise_after = float(state.get("poise", 0.0))
	out.landed = float(state.get("hp", -1.0)) < hp_before - 0.001
	# The guest's announcement arrives with the host's strike payload.
	var guest_after := guest_before
	for _poll in STAGGER_POLLS:
		guest_after = int(((await step(1, "f22_enemy_staggers", {})).get("data", {}) as Dictionary).get("count", 0))
		if guest_after > guest_before or not out.host_staggered:
			break
		await step(1, "wait", {"frames": 4})
	if not out.host_staggered:
		await step(1, "wait", {"frames": 30})
		guest_after = int(((await step(1, "f22_enemy_staggers", {})).get("data", {}) as Dictionary).get("count", 0))
	out.guest_staggers = guest_after - guest_before
	return out


## The host's live opponent HP, read from its real shared wild body.
func _pin(read_only: bool) -> Dictionary:
	var args := {"encounter_id": _encounter_id}
	if read_only: args["read_only"] = true
	return await step(0, "f22_pin_tell", args)


func _host_hp() -> float:
	var state: Dictionary = (await _pin(true)).get("data", {})
	return float(state.get("hp", -1.0))


func _encounter(peer: int) -> Dictionary:
	var value = await probe(peer, "encounter")
	return value if value is Dictionary else {}


func _vec(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() == 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.INF
