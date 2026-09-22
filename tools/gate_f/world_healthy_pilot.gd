extends RefCounted

## read_state supplies actual Game.party, world input ownership, and director
## companion readback (see snapshot). press("party_cycle") is one guarded
## physical tap: at most TWO physics + TWO process waits. next_frame waits ONE
## physics frame. No direct selection, deployment or health writes.
## Cost ceiling: budget_frames physics + 2*max(0, party_size-1) process waits;
## tap physics waits are RESERVED WITHIN the single shared physics budget.
static func snapshot(game: Node, director: Node, context: String, input_allowed: bool) -> Dictionary:
	var party: RefCounted = game.get("party") if is_instance_valid(game) else null
	var body: Node3D = director.call("ally_body") if is_instance_valid(director) else null
	return {"party": party, "context": context, "input_allowed": input_allowed,
		"active_index": int(party.call("active_index")) if party != null else -1,
		"companion": director.call("ally_instance") if is_instance_valid(director) else null,
		# _spawn_ally_body creates a hidden node BEFORE awaiting ground placement.
		"companion_ready": is_instance_valid(body) and body.is_inside_tree() \
			and body.is_visible_in_tree() and not body.is_queued_for_deletion()}


static func _eligible(creature: RefCounted) -> bool:
	return creature != null and float(creature.get("hp")) > 0.0 \
		and not bool(creature.get("fainted")) and not bool(creature.get("resting"))


static func execute(read_state: Callable, press: Callable, next_frame: Callable,
		budget_frames: int = 600, interrupted: Callable = Callable()) -> Dictionary:
	var result := {"ok": false, "why": "world pilot budget exhausted", "presses": 0,
		"physics_frames": 0, "process_frames": 0, "selected_index": -1, "no_input": true}
	var initial: Dictionary = read_state.call()
	var party: RefCounted = initial.get("party")
	if party == null:
		result.why = "no earned party"
		return result
	var baseline: Array = party.call("members")
	var active := int(initial.get("active_index", -1))
	if baseline.is_empty() or baseline.size() > 5 or active < 0 or active >= baseline.size():
		result.why = "invalid world party/index"
		return result
	# Greatest absolute live HP gives the greatest immediate damage allowance.
	# Stable ties prefer current active, then authored roster order.
	var best := active if _eligible(baseline[active]) else -1
	for index in baseline.size():
		if _eligible(baseline[index]) and (best < 0 or float(baseline[index].get("hp")) > float(baseline[best].get("hp"))):
			best = index
	if best < 0:
		result.why = "no living non-resting earned creature"
		return result
	result.selected_index = best
	var visited := [active]
	var pending := -1
	while true:
		var state: Dictionary = read_state.call()
		if str(state.get("context", "")) != "world" or not bool(state.get("input_allowed", false)):
			result.why = "world input is not exclusively available"
			return result
		if interrupted.is_valid() and bool(interrupted.call()):
			result.why = "world pilot selection interrupted by cost gate"
			return result
		if state.get("party") != party or int(party.call("size")) != baseline.size():
			result.why = "party identity or size changed"
			return result
		for index in baseline.size():
			if party.call("at", index) != baseline[index]:
				result.why = "earned roster identity/order changed"
				return result
		if not _eligible(baseline[best]):
			result.why = "selected healthy creature fainted or became unavailable"
			return result
		var now := int(state.get("active_index", -1))
		if pending >= 0:
			if now != active and now != pending:
				result.why = "physical LB selected an unexpected roster index"
				return result
			if now == pending:
				active = now
				visited.append(now)
				pending = -1
		elif now != active:
			result.why = "world active index changed without this helper's input"
			return result
		var settled: bool = bool(state.get("companion_ready", false)) and state.get("companion") == baseline[active]
		if pending < 0 and active == best and settled:
			result.ok = true
			result.why = "healthiest earned creature and actual companion verified; %d physical LB taps" % result.presses
			return result
		if pending < 0 and active != best and (settled or result.presses == 0):
			if result.presses >= baseline.size() - 1 or result.physics_frames + 2 > maxi(0, budget_frames):
				return result
			for offset in range(1, baseline.size()):
				var candidate := posmod(active + offset, baseline.size())
				if _eligible(baseline[candidate]):
					pending = candidate
					break
			if pending < 0 or visited.has(pending):
				result.why = "one roster traversal exhausted before healthiest creature"
				return result
			var sent: Dictionary = await press.call("party_cycle")
			result.presses += 1
			result.no_input = false
			result.physics_frames += 2
			result.process_frames += 2
			if not bool(sent.get("ok", false)):
				result.why = "physical party-cycle input refused"
				return result
			continue
		if result.physics_frames >= maxi(0, budget_frames):
			return result
		await next_frame.call()
		result.physics_frames += 1
	return result
