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

	# (b) runs first, on the freshly staged wild: (a)'s break makes the wild
	# reposition before it can be pinned again.
	# (b) Charge committed well before the tell: drains, never breaks.
	var blind := await _charge_case(false)
	check(bool(blind.landed), "(b) the early-committed charge landed on the host (%s)" % str(blind))
	check(not bool(blind.host_staggered),
		"(b) a charge committed %d+ frames before the tell does not force a break (%s)" % [EARLY_START_FRAMES, str(blind)])
	check(float(blind.poise_after) < float(blind.poise_before) - 0.001,
		"(b) its blow drained poise normally instead (%s)" % str(blind))
	check(int(blind.guest_staggers) == 0,
		"(b) the guest announces no break either: both peers resolve the same verdict (%s)" % str(blind))
	await step(1, "wait", {"frames": COOLDOWN_FRAMES})

	# (a) Tell first, then the committed charge: a read.
	var read := await _charge_case(true)
	check(bool(read.host_staggered),
		"(a) a charge committed after the tell breaks the wild on the host (%s)" % str(read))
	check(int(read.guest_staggers) == 1,
		"(a) the guest's manager announces the same break from the host payload (%s)" % str(read))

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
		var live: Dictionary = (await _pin(false)).get("data", {})
		var hp_was := float(live.get("hp", -1.0))
		var aim := _vec(live.get("centre", []))
		if aim != Vector3.INF: centre = aim
		_action += 1
		await step(1, "strike", {"target": [centre.x, centre.y, centre.z], "slot": "quick",
			"action": _action, "settle": 15})
		await step(1, "wait", {"frames": 30})
		if await _host_hp() < hp_was - 0.001: landed += 1
	out["energy_hits"] = landed
	var tally: Dictionary = (await _pin(true)).get("data", {})
	var breaks_before := int(tally.get("host_breaks", 0))
	var hits_before := int(tally.get("host_hits", 0))
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
		var session_view: Dictionary = await probe(1, "session")
		var guest_peer := int(session_view.get("peer_id", 0))
		var owned: Dictionary = await probe(1, "original_starter_ownership")
		if guest_peer <= 1 or str(owned.get("body_uid", "")).is_empty() \
			or str(owned.get("character_id", "")).is_empty() \
			or not (owned.get("party_uids", []) as Array).has(owned.get("body_uid")):
			check(false, "(b) the committing guest has its own deployed creature")
			return out
		_action += 1
		var action := _action
		# Keep the original command allowance across the entire split charge;
		# polling must not restart its deadline or the smoke's step-phase budget.
		var deadline := mini(int(_step_phase_deadline_ms), Time.get_ticks_msec() \
			+ int(float(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES)) \
			* NOMINAL_MS_PER_PHYSICS_FRAME + WALL_SLACK_MS))
		var begun := await _charge_step(1, "strike", {"target": [centre.x, centre.y, centre.z],
			"slot": "charged", "action": action, "start_only": true}, deadline)
		out["start"] = "%s %s" % [str(begun.get("detail", "")), str(begun.get("data", {}))]
		if begun.get("verdict") != "PASS": return out
		var observed := await _charge_commit(guest_peer, action, owned, deadline)
		out["commit"] = observed
		if observed.is_empty(): return out
		var original: Dictionary = observed.move_commit
		var early := await _charge_step(1, "wait", {"frames": EARLY_START_FRAMES}, deadline)
		if early.get("verdict") != "PASS": return out
		var pinned := await _charge_step(0, "f22_pin_tell", {"encounter_id": _encounter_id}, deadline)
		pin = pinned.get("data", {})
		if pin.is_empty(): out["pin"] = "%s: %s" % [str(pinned.get("verdict", "")), str(pinned.get("detail", ""))]
		if pinned.get("verdict") != "PASS" or pin.is_empty(): return out
		out.since_ms = int(pin.get("since_ms", -1))
		out.poise_before = float(pin.get("poise", 0.0))
		hp_before = float(pin.get("hp", -1.0))
		var ready := await _charge_commit(guest_peer, action, owned, deadline, original)
		out["ready"] = ready
		if ready.is_empty(): return out
		var struck := await _charge_step(1, "strike", {"target": [centre.x, centre.y, centre.z], "slot": "charged",
			"action": action, "move_start": false, "windup_wait": false, "settle": 15}, deadline)
		out["strike"] = "%s %s" % [str(struck.get("detail", "")), str(struck.get("data", {}))]
	var state: Dictionary = {}
	for _poll in STAGGER_POLLS:
		state = (await _pin(true)).get("data", {})
		if int(state.get("host_hits", 0)) > hits_before:
			break
		await step(0, "wait", {"frames": 4})
	# Counted from the host's own strike verdicts (`host_strike_finished`), so
	# a 0.6 s stagger that ended before this read still counts.
	out.host_staggered = int(state.get("host_breaks", 0)) > breaks_before
	out.poise_after = float(state.get("poise", 0.0))
	# Landed per the host's own strike verdict (`delta.hit`), not an HP read.
	out.landed = int(state.get("host_hits", 0)) > hits_before
	out["hp"] = [hp_before, float(state.get("hp", -1.0))]
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


## Every split-charge command consumes the same original wall-clock allowance.
func _charge_step(peer: int, command: String, args: Dictionary, deadline: int) -> Dictionary:
	var remaining := deadline - Time.get_ticks_msec() - int(WALL_SLACK_MS)
	if remaining <= 0:
		check(false, "(b) the original charge deadline expired before %s" % command)
		return {}
	var budget := mini(int(_budgets.get("step_budget_frames", DEFAULT_STEP_BUDGET_FRAMES)),
		floori(float(remaining) / NOMINAL_MS_PER_PHYSICS_FRAME))
	return await step(peer, command, args, budget)


## Read the exact retained host start, never treat the guest's pending reply as
## acceptance. On a later observation its identity and frozen timing must match.
func _charge_commit(peer: int, action: int, owned: Dictionary, deadline: int,
		original: Dictionary = {}) -> Dictionary:
	while Time.get_ticks_msec() < deadline - int(WALL_SLACK_MS):
		var response := await _charge_step(0, "f22_pin_tell", {"encounter_id": _encounter_id,
			"read_only": true, "commit_peer": peer, "commit_action": action}, deadline)
		if response.get("verdict") != "PASS": return {}
		var observed: Dictionary = response.get("data", {})
		var committed: Dictionary = observed.get("move_commit", {})
		if not committed.is_empty():
			var binding: Dictionary = committed.get("binding", {})
			var matched := int(committed.get("action", 0)) == action \
				and int(committed.get("peer", 0)) == peer and committed.get("slot") == "charged" \
				and committed.get("creature_uid") == owned.get("body_uid") \
				and binding.get("creature_uid") == owned.get("body_uid") \
				and binding.get("character_id") == owned.get("character_id") \
				and not str(committed.get("move_id", "")).is_empty() \
				and committed.get("resolved") == false \
				and int(committed.get("started_at_ms", -1)) >= 0 \
				and int(committed.get("strike_at_ms", -1)) >= int(committed.get("started_at_ms", 0)) \
				and int(observed.get("host_now_ms", -1)) >= int(committed.get("started_at_ms", 0))
			if not original.is_empty():
				for key: String in ["action", "peer", "creature_uid", "move_id", "slot", "binding", "started_at_ms", "strike_at_ms"]:
					matched = matched and committed.get(key) == original.get(key)
			if not matched:
				check(false, "(b) the original host charge commitment changed or is not current (%s)" % str(observed))
				return {}
			var remaining := int(committed.strike_at_ms) - int(observed.host_now_ms)
			if original.is_empty() or remaining <= 0: return observed
			# Frame waits merely yield; the next host tick proves readiness.
			var waited := await _charge_step(0, "wait", {"frames": mini(12,
				maxi(1, ceili(float(remaining) / NOMINAL_MS_PER_PHYSICS_FRAME)))}, deadline)
			if waited.get("verdict") != "PASS": return {}
		else:
			if not original.is_empty():
				check(false, "(b) the original host charge commitment disappeared (%s)" % str(observed))
				return {}
			var waited := await _charge_step(0, "wait", {"frames": 1}, deadline)
			if waited.get("verdict") != "PASS": return {}
	check(false, "(b) the original charge deadline expired awaiting host commitment/readiness")
	return {}


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
