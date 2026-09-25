extends "res://tests/test_case.gd"

## F09: "A closed Arch cannot be bypassed." Stormwood's two closed routes are
## the Rootgate (Conductor Run → Deepwood) and the Hollow Crown, reached only by
## its arch. These walk the production heightfield with the player's own
## 45-degree floor limit (true ground slope) rather than trusting a barrier's
## size.
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const MAX_WALK_DEG := 45.0  # scenes/player/player.tscn floor_max_angle 0.7854


## The production Rootgate: `stormwood_world.gd::_build_rootgate` centres a
## 90 x 15 m box on the pass at (-650, 3550). Pinned to the source below.
const GATE_X := -650.0
const GATE_Z := 3550.0
const GATE_WIDTH := 90.0
const GATE_DEPTH := 15.0
const CAPSULE_RADIUS := 0.4  # scenes/player/player.tscn


## True ground steepness per 1 m cell, from the heightfield's own normal: the
## quantity CharacterBody3D compares with its floor limit. (Grading a step only
## along its own axis would call a sideways walk across a 70-degree hillside
## flat.)
func _walkable(field: RefCounted, x0: int, z0: int, w: int, h: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize((w + 1) * (h + 1))
	for zi in h + 1:
		for xi in w + 1:
			out[zi * (w + 1) + xi] = 1 if field.slope_degrees_at(x0 + xi, z0 + zi) <= MAX_WALK_DEG else 0
	return out


## Breadth-first walk on a 1 m grid from the whole south edge; true when any
## walkable cell reaches the north edge without entering the gate footprint
## (grown by the player's capsule radius).
func _crosses(walkable: PackedByteArray, x0: int, z0: int, w: int, h: int, gate: bool) -> bool:
	var seen := {}
	var queue: Array[Vector2i] = []
	for xi in w + 1:
		if walkable[xi] == 1:
			queue.append(Vector2i(xi, 0))
			seen[Vector2i(xi, 0)] = true
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		if c.y == h:
			return true
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if n.x < 0 or n.x > w or n.y < 0 or n.y > h or seen.has(n):
				continue
			if walkable[n.y * (w + 1) + n.x] == 0:
				continue
			if gate and absf(float(x0 + n.x) - GATE_X) <= GATE_WIDTH * 0.5 + CAPSULE_RADIUS \
					and absf(float(z0 + n.y) - GATE_Z) <= GATE_DEPTH * 0.5 + CAPSULE_RADIUS:
				continue
			seen[n] = true
			queue.append(n)
	return false


func test_closed_rootgate_cannot_be_walked_around() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/stormwood_world.gd")
	assert_true(source.contains("shape.size = Vector3(90,40,15)")
		and source.contains("Vector3(-650,ground_height_at(-650,3550)+15,3550)"),
		"The test's gate footprint is the production Rootgate box")
	var field := FIELD.new()
	var x0 := -800
	var z0 := 3420
	var w := 300
	var h := 260
	var walkable := _walkable(field, x0, z0, w, h)
	assert_true(_crosses(walkable, x0, z0, w, h, false), "With the Rootgate open the pass is walkable")
	assert_false(_crosses(walkable, x0, z0, w, h, true),
		"The closed Rootgate seals every walkable crossing; the ridge flanks beside it are too steep to walk")


func test_ridge_outside_the_pass_is_too_steep_to_walk() -> void:
	var field := FIELD.new()
	for x in range(-2540, 2040, 4):
		if absf(float(x) - GATE_X) <= GATE_WIDTH * 0.5:
			continue
		var open := true
		for z in range(3380, 3720, 2):
			if field.slope_degrees_at(x, z) > MAX_WALK_DEG:
				open = false
				break
		if open:
			assert_true(false, "a straight walk over the ridge at x=%d stays under the floor limit" % x)
			return
	assert_true(true)


func test_crown_island_rim_is_unclimbable_all_around() -> void:
	var field := FIELD.new()
	var weakest := 90.0
	for i in 72:
		var dir := Vector2.from_angle(TAU * i / 72.0)
		var worst := 0.0
		for r in range(200, 300):
			var p := Vector2(700, 2700) + dir * r
			var q := Vector2(700, 2700) + dir * (r + 1)
			worst = maxf(worst, rad_to_deg(atan(absf(field.height_at(q.x, q.y) - field.height_at(p.x, p.y)))))
		weakest = minf(weakest, worst)
	assert_true(weakest > MAX_WALK_DEG + 15.0,
		"Every radial approach to the Crown island crosses an unclimbable rim (weakest %.1f deg)" % weakest)


func test_flight_cannot_reach_the_crown_or_cross_the_rootgate() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/stormwood_world.gd")
	assert_true(source.contains('register_restriction","stormwood_canopy",AABB(Vector3(-2560,-1000,0),Vector3(4608,3000,6144))'),
		"Fly stays restricted over the whole Stormwood realm, so neither closed route can be flown over")
