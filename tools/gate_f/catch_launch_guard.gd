extends RefCounted

## Observe production aim_exited AFTER _release creates/launches its new orb.
## Cancel/refusal also emit aim_exited, so that signal alone is not a launch.
## last_launch values may repeat exactly: use the actual new orb's identity.
## This helper proves a launch, never a catch; the caller retains strict party
## growth/outcome checks. Call only after arming/tracking, not to arm the aim.
static func boundary(manager: Node, context: Callable, pilot: RefCounted,
		foe: RefCounted) -> String:
	if not is_instance_valid(manager) or not bool(manager.call("is_fighting")):
		return "fight ended before physical catch release"
	if manager.call("active_creature") != pilot or manager.call("enemy") != foe:
		return "pilot or foe changed before physical catch release"
	if pilot == null or foe == null or float(pilot.get("hp")) <= 0.0 or float(foe.get("hp")) <= 0.0:
		return "pilot or foe fainted before physical catch release"
	if not bool(manager.call("is_aiming")) or str(context.call()) != "combat_aim":
		return "physical catch release requires live combat_aim ownership"
	return ""


static func execute(tree: SceneTree, manager: Node, context: Callable,
		press: Callable, pilot: RefCounted, foe: RefCounted, budget_frames: int = 60,
		interrupted: Callable = Callable(), frame_number: Callable = Callable(),
		next_frame: Callable = Callable()) -> Dictionary:
	var result := {"ok": false, "launches": 0, "why": "catch launch observation budget exhausted",
		"orb_instance_id": 0, "launch": {}, "refusal": "", "outcome": ""}
	var problem := boundary(manager, context, pilot, foe)
	if not problem.is_empty():
		result.why = problem
		return result
	if interrupted.is_valid() and bool(interrupted.call()):
		result.why = "catch launch interrupted by cost gate"
		return result
	var thrower: Node = manager.call("throw_aim")
	if not is_instance_valid(thrower) or not thrower.has_signal("aim_exited") \
			or not thrower.has_signal("throw_refused") or not thrower.has_method("last_launch") \
			or not thrower.has_method("resting_orb"):
		result.why = "production launch observation unavailable"
		return result
	var previous: Node = thrower.call("resting_orb")
	var previous_id := previous.get_instance_id() if is_instance_valid(previous) else 0
	var on_exit := func() -> void:
		var orb: Node = thrower.call("resting_orb")
		var launch: Dictionary = thrower.call("last_launch")
		if not is_instance_valid(orb) or orb.get_instance_id() == previous_id:
			return
		if not launch.has("launch_point") or not launch.has("direction") or str(launch.get("orb_id", "")).is_empty():
			return
		if int(result.orb_instance_id) == orb.get_instance_id():
			return
		result.launches += 1
		result.orb_instance_id = orb.get_instance_id()
		result.launch = launch.duplicate(true)
	var on_refused := func(reason: String) -> void: result.refusal = reason
	var on_finished := func(outcome: String) -> void: result.outcome = outcome
	thrower.connect("aim_exited", on_exit)
	thrower.connect("throw_refused", on_refused)
	manager.connect("exited", on_finished)
	var frame := frame_number if frame_number.is_valid() else func() -> int: return Engine.get_physics_frames()
	var start := int(frame.call())
	# Caller supplies the existing physical _inject("interact", tap) callback.
	# No press counter: only the observed release above increments launches.
	var sent: Dictionary = await press.call()
	while true:
		if not bool(sent.get("ok", false)):
			result.why = str(sent.get("why", "physical catch input refused"))
			break
		if not str(result.refusal).is_empty():
			result.why = "production throw refused: %s" % result.refusal
			break
		if not is_instance_valid(manager) or not bool(manager.call("is_fighting")) \
				or manager.call("active_creature") != pilot or manager.call("enemy") != foe \
				or float(pilot.get("hp")) <= 0.0 or float(foe.get("hp")) <= 0.0:
			result.why = "fight/pilot/foe ended or changed during release (%s)" % result.outcome
			break
		if int(result.launches) == 1:
			result.ok = true
			result.why = "observed one production orb launch; catch not yet proven"
			break
		if int(result.launches) > 1:
			result.why = "unexpected multiple production launches from one physical release"
			break
		if interrupted.is_valid() and bool(interrupted.call()):
			result.why = "catch launch interrupted by cost gate"
			break
		if int(frame.call()) - start >= maxi(1, budget_frames):
			break
		if next_frame.is_valid():
			await next_frame.call()
		else:
			await tree.physics_frame
	if is_instance_valid(thrower):
		thrower.disconnect("aim_exited", on_exit)
		thrower.disconnect("throw_refused", on_refused)
	if is_instance_valid(manager):
		manager.disconnect("exited", on_finished)
	return result
