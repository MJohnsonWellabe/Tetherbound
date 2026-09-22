extends RefCounted

## launch() wraps CatchLaunch.execute; connect BEFORE its physical tap/waits.
## read_party() returns the actual Game.party object, not serialized party_state.
## next_frame() waits exactly one physics frame and ticks existing telemetry.
## No input is issued here. ok means an observed outcome, not necessarily caught.
## Additional wait ceiling: flight + resolve + settle (launch priced separately).
static func execute(manager: Node, launch: Callable, read_party: Callable,
		next_frame: Callable, interrupted: Callable = Callable(), flight_budget: int = 180,
		resolve_budget: int = 360, settle_budget: int = 360) -> Dictionary:
	var result := {"ok": false, "outcome": "", "why": "", "struck": false,
		"miss": "", "verdict_seen": false, "caught": false, "shakes": -1,
		"exit": "", "refusal": "", "physics_frames": 0, "launch": {}}
	if not is_instance_valid(manager):
		result.why = "combat manager unavailable"
		return result
	var party: RefCounted = read_party.call()
	var pilot: RefCounted = manager.call("active_creature")
	var foe: RefCounted = manager.call("enemy")
	var thrower: Node = manager.call("throw_aim")
	if party == null or pilot == null or foe == null or not is_instance_valid(thrower):
		result.why = "live party/pilot/foe/thrower unavailable"
		return result
	var baseline: Array = []
	for index in int(party.call("size")):
		baseline.append(party.call("at", index))
	if baseline.has(foe):
		result.why = "target already belongs to the party"
		return result
	var bindings := [
		[manager, "catch_resolved", func(success: bool, shakes: int) -> void:
			result.verdict_seen = true
			result.caught = success
			result.shakes = shakes],
		[manager, "exited", func(outcome: String) -> void: result.exit = outcome],
		[manager, "catch_refused", func(reason: String) -> void: result.refusal = reason],
		[thrower, "orb_struck", func(_target: Node3D, _offset: float) -> void: result.struck = true],
		[thrower, "orb_missed", func(reason: String) -> void: result.miss = reason],
	]
	for binding in bindings:
		if not binding[0].has_signal(binding[1]):
			result.why = "production outcome signal unavailable: " + str(binding[1])
			return result
	for binding in bindings:
		binding[0].connect(binding[1], binding[2])
	result.launch = await launch.call()
	await _observe(manager, read_party, next_frame, interrupted, party, baseline,
		pilot, foe, result, [maxi(0, flight_budget), maxi(0, resolve_budget), maxi(0, settle_budget)])
	for binding in bindings:
		if is_instance_valid(binding[0]) and binding[0].is_connected(binding[1], binding[2]):
			binding[0].disconnect(binding[1], binding[2])
	return result


static func _observe(manager: Node, read_party: Callable, next_frame: Callable,
		interrupted: Callable, party: RefCounted, baseline: Array, pilot: RefCounted,
		foe: RefCounted, result: Dictionary, budgets: Array) -> void:
	var used := [0, 0, 0]
	var phase := 0
	while true:
		if not bool(result.launch.get("ok", false)) or int(result.launch.get("launches", 0)) != 1:
			result.why = "exactly one observed physical launch required"
			return
		if interrupted.is_valid() and bool(interrupted.call()):
			result.why = "catch observation interrupted by cost gate"
			return
		if not is_instance_valid(manager) or read_party.call() != party:
			result.why = "manager or party identity changed"
			return
		var count := int(party.call("size"))
		if count < baseline.size() or count > baseline.size() + 1:
			result.why = "party changed outside this catch"
			return
		for index in baseline.size():
			if party.call("at", index) != baseline[index]:
				result.why = "baseline party member identity/order changed"
				return
		var grew := count == baseline.size() + 1
		if grew and party.call("at", baseline.size()) != foe:
			result.why = "party grew with a different creature"
			return
		if not str(result.exit).is_empty() and str(result.exit) != "caught":
			result.why = "fight ended without catch: " + str(result.exit)
			return
		var fighting := bool(manager.call("is_fighting"))
		var resolving := bool(manager.call("is_resolving_catch"))
		if not str(result.refusal).is_empty() and (str(result.miss).is_empty() \
				or bool(result.struck) or bool(result.verdict_seen)):
			result.why = "production catch refused: " + str(result.refusal)
			return
		if bool(result.verdict_seen) and bool(result.caught):
			phase = 2
			if grew and str(result.exit) == "caught" and not fighting and not resolving:
				result.ok = true
				result.outcome = "caught"
				result.why = "caught exit and exact foe appended to unchanged party verified"
				return
		else:
			if not fighting or manager.call("enemy") != foe or manager.call("active_creature") != pilot \
					or float(pilot.get("hp")) <= 0.0 or float(foe.get("hp")) <= 0.0:
				result.why = "fight/pilot/foe lost or changed before outcome"
				return
			if grew or str(result.exit) == "caught":
				result.why = "catch completion without successful verdict"
				return
			if not str(result.miss).is_empty() and not bool(result.struck) and not bool(result.verdict_seen) and not resolving:
				result.ok = true
				result.outcome = "miss"
				result.why = "production orb_missed: " + str(result.miss)
				return
			if not str(result.refusal).is_empty():
				result.why = "production catch refused: " + str(result.refusal)
				return
			if bool(result.verdict_seen) and not bool(result.caught) and not resolving:
				result.ok = true
				result.outcome = "breakout"
				result.why = "production catch_resolved(false); live encounter ready for next decision"
				return
			if bool(result.struck) or resolving:
				phase = maxi(phase, 1)
		if used[phase] >= budgets[phase]:
			result.why = "catch %s observation budget exhausted" % ["flight", "resolve", "settle"][phase]
			return
		await next_frame.call()
		used[phase] += 1
		result.physics_frames += 1
