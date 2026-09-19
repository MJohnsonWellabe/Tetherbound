extends RefCounted

## Production state and signals are read only. The supplied driver must inject
## real mapped controller input; this helper never writes HP, energy or phase.
static func execute(tree: SceneTree, manager: Node, press: Callable,
		budget_frames: int = 1800, interrupted: Callable = Callable(),
		frame_number: Callable = Callable(), next_frame: Callable = Callable()) -> Dictionary:
	# Optional clock callbacks make the bounded orchestration unit-testable
	# without a running scene. Production uses the engine's real physics clock.
	var frame := frame_number if frame_number.is_valid() else func() -> int: return Engine.get_physics_frames()
	var result := {"ok": false, "why": "charged hit budget exhausted",
		"quick_presses": 0, "charged_presses": 0, "charged_damage": 0.0}
	if manager == null or not bool(manager.call("is_fighting")):
		result.why = "charged hit requires a live fight"
		return result
	var pilot: RefCounted = manager.call("active_creature")
	var foe: RefCounted = manager.call("enemy")
	if pilot == null or foe == null:
		result.why = "charged hit requires a live pilot and enemy"
		return result
	var on_hit := func(on_enemy: bool, damage: float) -> void:
		var move: Dictionary = manager.get("_pending_move")
		if on_enemy and damage > 0.0 and result.charged_presses > 0 \
				and move.has("is_quick") and not bool(move.is_quick) \
				and manager.call("active_creature") == pilot and manager.call("enemy") == foe:
			result.charged_damage += damage
	manager.connect("hit_landed", on_hit)
	var start := int(frame.call())
	var next_press := start
	while int(frame.call()) - start < maxi(1, budget_frames):
		# A killing charged hit emits before the victory transition. Accept that
		# observed hit even if the same input callback also completes the fight.
		if result.charged_damage > 0.0:
			result.ok = true
			result.why = "production charged hit landed"
			break
		if interrupted.is_valid() and bool(interrupted.call()):
			result.why = "charged hit interrupted by cost gate"
			break
		if not is_instance_valid(manager) or not bool(manager.call("is_fighting")):
			result.why = "fight ended before a charged hit landed"
			break
		if manager.call("active_creature") != pilot or manager.call("enemy") != foe \
				or float(pilot.get("hp")) <= 0.0 or float(foe.get("hp")) <= 0.0:
			result.why = "pilot/enemy changed or fainted before charged hit"
			break
		if int(frame.call()) >= next_press:
			var control := ""
			var hold := 1
			if bool(manager.call("charged_ready")):
				control = "combat_charged"
				hold = 60 # Preserve S05's physical long charged press.
				result.charged_presses += 1
			elif not bool(pilot.call("can_use_charged")) and bool(manager.call("quick_ready")):
				control = "combat_quick"
				result.quick_presses += 1
			if not control.is_empty():
				var sent: Dictionary = await press.call(control, hold)
				if not bool(sent.get("ok", false)):
					result.why = str(sent.get("why", "physical input refused"))
					break
				next_press = int(frame.call()) + 18
		if next_frame.is_valid():
			await next_frame.call()
		else:
			await tree.physics_frame
	# The last bounded injection may land while crossing the budget boundary.
	# It is still an observed hit, not a hopeful after-the-fact HP comparison.
	if result.charged_damage > 0.0:
		result.ok = true
		result.why = "production charged hit landed"
	if is_instance_valid(manager) and manager.is_connected("hit_landed", on_hit):
		manager.disconnect("hit_landed", on_hit)
	return result
