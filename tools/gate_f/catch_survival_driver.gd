extends RefCounted

## Opt-in pre-aim controller policy. read_state returns production observations:
## fighting, context, aiming, catch_resolving, can_switch, pilot, foe, party,
## active_index, eligible_indices (manager.switchable_indices()). Creature values
## are actual RefCounted instances. press MUST inject mapped controller input.
## No game state setter or manager switch method is called by this helper.
static func execute(tree: SceneTree, read_state: Callable, press: Callable,
		threshold: float = 0.5, budget_frames: int = 600,
		interrupted: Callable = Callable(), frame_number: Callable = Callable(),
		next_frame: Callable = Callable()) -> Dictionary:
	var result := {"ok": false, "why": "catch survival budget exhausted", "presses": 0,
		"switches": 0, "initial_hp": 0.0, "final_hp": 0.0}
	var initial: Dictionary = read_state.call()
	var pilot: RefCounted = initial.get("pilot")
	var foe: RefCounted = initial.get("foe")
	var problem := _boundary(initial, foe)
	if not problem.is_empty():
		result.why = problem
		return result
	var initial_hp := float(pilot.get("hp"))
	var initial_fraction := initial_hp / maxf(1.0, float(pilot.get("max_hp")))
	result.initial_hp = initial_hp
	result.final_hp = initial_hp
	if initial_fraction >= clampf(threshold, 0.0, 1.0):
		result.ok = true
		result.why = "live pilot already meets catch survival threshold"
		return result
	var party: Array = initial.get("party", [])
	var eligible: Array = initial.get("eligible_indices", [])
	var healthier := false
	for index: Variant in eligible:
		if int(index) >= 0 and int(index) < party.size() and _healthier(party[int(index)], initial_hp, initial_fraction):
			healthier = true
	if not healthier:
		result.ok = true
		result.why = "no healthier eligible earned member; pilot unchanged, catch remains strict"
		return result
	var max_presses := mini(5, maxi(0, party.size() - 1))
	var frame := frame_number if frame_number.is_valid() else func() -> int: return Engine.get_physics_frames()
	var start := int(frame.call())
	var expected: RefCounted = null
	while int(frame.call()) - start < mini(600, maxi(1, budget_frames)):
		var state: Dictionary = read_state.call()
		problem = _boundary(state, foe)
		if not problem.is_empty():
			result.why = problem
			break
		if interrupted.is_valid() and bool(interrupted.call()):
			result.why = "catch survival interrupted by cost gate"
			break
		var current: RefCounted = state.get("pilot")
		result.final_hp = float(current.get("hp"))
		if float(pilot.get("hp")) <= 0.0:
			result.why = "previous pilot fainted; an automatic replacement is not a voluntary handoff"
			break
		if current != pilot:
			if expected == null or current != expected:
				result.why = "pilot changed without the expected physical forward handoff"
				break
			result.switches += 1
			pilot = current
			expected = null
			if _healthier(current, initial_hp, initial_fraction):
				result.ok = true
				result.why = "physical LB selected a healthier earned pilot in the same fight"
				break
		if expected == null and bool(state.get("can_switch", false)):
			if int(result.presses) >= max_presses:
				result.why = "one roster traversal exhausted without a healthier live pilot"
				break
			expected = _next_member(state)
			if expected == null:
				result.why = "eligible forward handoff disappeared"
				break
			result.presses += 1
			var sent: Dictionary = await press.call("party_cycle", 1)
			if not bool(sent.get("ok", false)):
				result.why = str(sent.get("why", "physical LB refused"))
				break
			# Re-read immediately: never infer a switch from an accepted press.
			continue
		if next_frame.is_valid():
			await next_frame.call()
		else:
			await tree.physics_frame
	return result


static func _healthier(member: RefCounted, hp: float, fraction: float) -> bool:
	return member != null and float(member.get("hp")) > hp \
		and float(member.get("hp")) / maxf(1.0, float(member.get("max_hp"))) > fraction


static func _boundary(state: Dictionary, foe: RefCounted) -> String:
	var pilot: RefCounted = state.get("pilot")
	if not bool(state.get("fighting", false)) or pilot == null or foe == null \
			or float(pilot.get("hp")) <= 0.0 or float(foe.get("hp")) <= 0.0:
		return "fight ended or pilot/foe fainted before catch survival handoff"
	if state.get("foe") != foe:
		return "foe identity changed during catch survival handoff"
	if str(state.get("context", "")) != "combat" or bool(state.get("aiming", false)) \
			or bool(state.get("catch_resolving", false)):
		return "catch survival requires ordinary combat ownership before aiming"
	return ""


static func _next_member(state: Dictionary) -> RefCounted:
	var party: Array = state.get("party", [])
	var active := int(state.get("active_index", -1))
	var eligible: Array = state.get("eligible_indices", [])
	if active < 0 or active >= party.size() or party[active] != state.get("pilot"):
		return null
	for offset in range(1, party.size()):
		var index := (active + offset) % party.size()
		if eligible.has(index):
			return party[index]
	return null
