extends "res://tests/test_case.gd"

## F09: "A closed Arch cannot be bypassed." Stormwood's two closed routes are
## the Rootgate (Conductor Run → Deepwood) and the Hollow Crown, reached only by
## its arch. These walk the production heightfield with the player's own
## 45-degree floor limit rather than trusting a barrier's size.
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const WORLD := preload("res://scripts/world/stormwood_world.gd")
const MAX_WALK_DEG := 45.0  # scenes/player/player.tscn floor_max_angle 0.7854


func _heights(field: RefCounted, x0: int, z0: int, w: int, h: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize((w + 1) * (h + 1))
	for zi in h + 1:
		for xi in w + 1:
			out[zi * (w + 1) + xi] = field.height_at(x0 + xi, z0 + zi)
	return out


## Breadth-first walk on a 1 m grid from the whole south edge; true when any
## walkable cell reaches the north edge without entering a blocker footprint.
func _crosses(heights: PackedFloat32Array, x0: int, z0: int, w: int, h: int, blockers: Array) -> bool:
	var seen := {}
	var queue: Array[Vector2i] = []
	for xi in w + 1:
		queue.append(Vector2i(xi, 0))
		seen[Vector2i(xi, 0)] = true
	var half_depth := WORLD.ROOTGATE_DEPTH_M * 0.5
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		if c.y == h:
			return true
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if n.x < 0 or n.x > w or n.y < 0 or n.y > h or seen.has(n):
				continue
			var x := float(x0 + n.x)
			var z := float(z0 + n.y)
			var blocked := false
			for blocker: Array in blockers:
				if absf(x - float(blocker[0])) <= float(blocker[1]) * 0.5 \
						and absf(z - WORLD.ROOTGATE_Z) <= half_depth:
					blocked = true
					break
			if blocked:
				continue
			var rise := absf(heights[n.y * (w + 1) + n.x] - heights[c.y * (w + 1) + c.x])
			if rad_to_deg(atan(rise)) > MAX_WALK_DEG:
				continue
			seen[n] = true
			queue.append(n)
	return false


func test_closed_rootgate_cannot_be_walked_around() -> void:
	var field := FIELD.new()
	var x0 := -800
	var z0 := 3420
	var w := 300
	var h := 260
	var heights := _heights(field, x0, z0, w, h)
	assert_true(_crosses(heights, x0, z0, w, h, []), "The open pass is walkable ground")
	var central: Array = [WORLD.rootgate_blockers()[0]]
	assert_true(_crosses(heights, x0, z0, w, h, central),
		"Regression witness: the old central box alone left the ridge flanks walkable")
	assert_false(_crosses(heights, x0, z0, w, h, WORLD.rootgate_blockers()),
		"The closed Rootgate and its flank columns seal every walkable crossing")


func test_ridge_outside_the_gate_is_not_walkable_anywhere() -> void:
	var field := FIELD.new()
	var widest: Array = WORLD.rootgate_blockers()
	var left := INF
	var right := -INF
	for blocker: Array in widest:
		left = minf(left, float(blocker[0]) - float(blocker[1]) * 0.5)
		right = maxf(right, float(blocker[0]) + float(blocker[1]) * 0.5)
	for x in range(-2540, 2040, 4):
		if float(x) >= left and float(x) <= right:
			continue
		var worst := 0.0
		for z in range(3380, 3720):
			worst = maxf(worst, rad_to_deg(atan(absf(field.height_at(x, z + 1) - field.height_at(x, z)))))
		if worst <= MAX_WALK_DEG:
			assert_true(false, "the ridge is straight-walkable at x=%d outside the gate" % x)
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
