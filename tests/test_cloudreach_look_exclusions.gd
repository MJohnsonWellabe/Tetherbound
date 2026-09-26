extends "res://tests/test_case.gd"

## The Cloudreach look pass answers `_excluded` from an XZ grid instead of a
## linear walk (it held every Cloudreach entry frame ~130 s). The grid must
## return exactly what the linear walk returns, for every shape kind, at
## rotations, on cell boundaries, on long diagonals and for late additions.

const LOOK := preload("res://scripts/world/cloudreach_look.gd")


func _shapes(rng: RandomNumberGenerator) -> Array:
	var out: Array = [
		{"kind": "segment", "a": Vector3(-500, 400, -700), "b": Vector3(900, 460, 1300), "half_width": 6.0},
		{"kind": "segment", "a": Vector3(12, 30, 12), "b": Vector3(12, 30, 12), "half_width": 2.5},
		{"kind": "segment", "a": Vector3(64, 0, 0), "b": Vector3(64, 0, 96)},
		{"kind": "ellipse", "centre": Vector3(31.9, 10, -32.1), "half": Vector2(40, 7), "rotation": 0.7},
		{"kind": "ellipse", "centre": Vector3(0, 0, 0), "half": Vector2(170, 170), "rotation": 0.0},
		{"centre": Vector3(-64, 5, 64), "half": Vector2(5.5, 46), "rotation": 2.3},
		{"centre": Vector3(200, 5, 200), "half": Vector2.ONE * 1.4, "rotation": 0.0},
		{"kind": "ellipse", "centre": Vector3(300, 5, -300), "half": Vector2(0, 12), "rotation": 0.0},
		{"centre": Vector3(0, 0, 0), "half": Vector2(INF, 3), "rotation": 0.0},
		{"kind": "ellipse", "centre": Vector3(0, 0, 0), "half": Vector2(1.0e30, 2), "rotation": PI / 2.0},
		{"kind": "segment", "a": Vector3(-300, 0, 300), "b": Vector3(300, 0, 300), "half_width": 1.0e300},
		{"centre": Vector3(96, 0, -96), "half": Vector2(-6, 9), "rotation": -PI / 2.0},
		{"kind": "ellipse", "centre": Vector3(-160, 0, -160), "half": Vector2(-12, 20), "rotation": PI},
		"not a dictionary",
	]
	for _i in 60:
		var kind := rng.randi_range(0, 2)
		var centre := Vector3(rng.randf_range(-600, 600), rng.randf_range(-20, 20), rng.randf_range(-600, 600))
		if kind == 0:
			out.append({"kind": "segment", "a": centre,
				"b": centre + Vector3(rng.randf_range(-300, 300), rng.randf_range(-8, 8), rng.randf_range(-300, 300)),
				"half_width": rng.randf_range(0.5, 12.0)})
		else:
			out.append({"kind": "ellipse" if kind == 1 else "box", "centre": centre,
				"half": Vector2(rng.randf_range(0.5, 80), rng.randf_range(0.5, 80)),
				"rotation": rng.randf_range(-TAU, TAU)})
	return out


func test_grid_matches_linear_walk_everywhere() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260926
	var look: Node = LOOK.new()
	var shapes: Array = _shapes(rng)
	look.set("_exclusions", shapes)
	var mismatches := 0
	var hits := 0
	for i in 40000:
		var at := Vector3(rng.randf_range(-700, 700), rng.randf_range(-8, 8), rng.randf_range(-700, 700))
		if i % 4 == 0:
			# Snap onto a cell boundary; the index must not lose an edge case.
			at.x = roundf(at.x / 32.0) * 32.0
			at.z = roundf(at.z / 32.0) * 32.0
		var linear := bool(look.call("_excluded_linear", at))
		if linear:
			hits += 1
		if bool(look.call("_excluded", at)) != linear:
			mismatches += 1
	assert_eq(mismatches, 0, "grid and linear exclusion disagree")
	assert_true(hits > 1000, "sample exercised too few exclusions (%d hits)" % hits)
	look.free()


func test_late_exclusion_is_seen() -> void:
	var look: Node = LOOK.new()
	var shapes: Array = [{"centre": Vector3(0, 0, 0), "half": Vector2.ONE * 2.0, "rotation": 0.0}]
	look.set("_exclusions", shapes)
	var probe := Vector3(500, 0, 500)
	assert_false(bool(look.call("_excluded", probe)))
	shapes.append({"kind": "ellipse", "centre": probe, "half": Vector2.ONE * 3.0, "rotation": 0.0})
	assert_true(bool(look.call("_excluded", probe)), "exclusion added after first query was missed")
	look.free()
