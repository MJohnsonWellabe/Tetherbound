extends SceneTree

## Synthetic load probe, not gameplay acceptance or a frame-rate benchmark.
## Isolates production unaimed harvest selection from animation/poll latency.
const HOLD := preload("res://scripts/player/tool_hold.gd")
const LOGIC := preload("res://scripts/world/harvest_logic.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

class HarvestStub extends Node3D:
	var hits := 0
	func gather(_tool: String = "") -> void:
		hits += 1

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	var body := Node3D.new()
	fixture.add_child(body)
	var hold := HOLD.new()
	body.add_child(hold)
	hold.set_process(false)
	hold.set("_equipped", "axe")
	# Production smoke boot reports roughly 58,000 harvest nodes. All but one
	# are intentionally far away so this measures the global scan's floor.
	for index in 58000:
		var distant := HarvestStub.new()
		fixture.add_child(distant)
		distant.position = Vector3(100 + index % 1000, 0, 100 + index / 1000)
		distant.add_to_group(LOGIC.GROUP)
	var target := HarvestStub.new()
	fixture.add_child(target)
	target.position = Vector3(0, 0, -1.5)
	target.add_to_group(LOGIC.GROUP)
	var samples: Array[float] = []
	for attempt in 5:
		var started := Time.get_ticks_usec()
		hold.call("_resolve_swing")
		samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
	print("TOOL_SWING_COST ", JSON.stringify({"harvest_nodes": 58001,
		"resolve_ms": samples, "actual_target_hits": target.hits}))
	var correct := target.hits == 5
	target.remove_from_group(LOGIC.GROUP)
	# Compare actual production selection with the original full-cone rule,
	# including range edges, height, angle exclusions and nearest/tie ordering.
	var cases: Array = [
		[Vector3(0, 0, -3.2)],
		[Vector3(0, 0, -3.201)],
		[Vector3(3.2, 0, -3.2)],
		[Vector3(0, 100, -1), Vector3(0, 0, -2)],
		[Vector3(0, 100, -1)],
		[Vector3(0, 0, 1), Vector3(0, 0, -2)],
		[Vector3(1, 0, -2), Vector3(-1, 0, -2)],
		[Vector3.ZERO],
	]
	for positions: Array in cases:
		var candidates: Array[HarvestStub] = []
		var expected: HarvestStub = null
		var best_distance := INF
		for position: Vector3 in positions:
			var candidate := HarvestStub.new()
			fixture.add_child(candidate)
			candidate.position = position
			candidate.add_to_group(LOGIC.GROUP)
			candidates.append(candidate)
			if MATH.in_hit_cone(Vector3.ZERO, Vector3.FORWARD, position, HOLD.SWING_REACH, HOLD.SWING_ARC_DEGREES):
				if position.length() < best_distance:
					best_distance = position.length()
					expected = candidate
		hold.call("_resolve_swing")
		for candidate: HarvestStub in candidates:
			correct = correct and candidate.hits == (1 if candidate == expected else 0)
			candidate.free()
	print("TOOL_SWING_SELECTION cases=%d equivalent=%s" % [cases.size(), correct])
	fixture.free()
	quit(0 if correct else 1)
