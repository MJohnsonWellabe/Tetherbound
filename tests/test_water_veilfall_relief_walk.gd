extends "res://tests/test_case.gd"

## F39#4 (close-1024): the Veilfall crag relief must never touch a walked
## surface. Every authored trail's walk band, every anchor's safe/shore spot and
## the gate entrance keep exactly the height they have with the relief off, so
## the hike's graded slope (and its slope limit) is unchanged; the relief only
## reshapes the flanks and cut walls around them.
const FIELD := preload("res://scripts/world/water_heightfield.gd")


func _fields() -> Array:
	var on: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	on.terrain.veilfall_relief.enabled = true
	var off: Dictionary = on.duplicate(true)
	off.terrain.veilfall_relief.enabled = false
	return [FIELD.new(on), FIELD.new(off), on]


func test_veilfall_hike_walk_band_keeps_its_graded_height() -> void:
	var fields := _fields()
	var on = fields[0]
	var off = fields[1]
	var cfg: Dictionary = fields[2]
	var spine: Array = []
	for route: Dictionary in cfg.land_routes:
		if str(route.id) == "veilfall_exploration_spine":
			spine = route.polyline
	assert_true(spine.size() >= 2, "precondition: the Veilfall hike exists")
	var half := float(cfg.terrain.trail_grading.flat_half_width_m)
	var worst := 0.0
	var samples := 0
	for k in spine.size() - 1:
		var a := Vector2(float(spine[k][0]), float(spine[k][2]))
		var b := Vector2(float(spine[k + 1][0]), float(spine[k + 1][2]))
		var along := (b - a).normalized()
		var across := Vector2(-along.y, along.x)
		var steps := int(a.distance_to(b))
		for i in steps + 1:
			var centre := a.lerp(b, float(i) / maxf(1.0, float(steps)))
			for offset: float in [-half, 0.0, half]:
				var p := centre + across * offset
				worst = maxf(worst, absf(float(on.height_at(p.x, p.y)) - float(off.height_at(p.x, p.y))))
				samples += 1
	assert_true(samples > 1000, "the whole hike is sampled")
	assert_almost_eq(worst, 0.0, 0.0001, "the hike's walk band keeps its exact graded height")


func test_veilfall_anchors_and_gate_keep_their_height_and_the_flanks_change() -> void:
	var fields := _fields()
	var on = fields[0]
	var off = fields[1]
	var cfg: Dictionary = fields[2]
	var checked := 0
	for anchor: Dictionary in cfg.get("anchors", []):
		for key: String in ["safe_position", "shore_position"]:
			var at: Array = anchor.get(key, [])
			if at.size() == 3 and Vector2(float(at[0]) - 200.0, float(at[2]) - 4140.0).length() < 400.0:
				assert_almost_eq(float(on.height_at(float(at[0]), float(at[2]))),
					float(off.height_at(float(at[0]), float(at[2]))), 0.0001, "%s %s keeps its height" % [anchor.get("id", "?"), key])
				checked += 1
	assert_true(checked > 0, "Veilfall anchors are checked")
	assert_almost_eq(float(on.height_at(335.208, 3885.711)), float(off.height_at(335.208, 3885.711)), 0.0001,
		"the gate entrance keeps its height")
	var changed := 0
	for x in range(300, 420, 6):
		for z in range(3800, 3900, 6):
			if absf(float(on.height_at(x, z)) - float(off.height_at(x, z))) > 0.5:
				changed += 1
	assert_true(changed > 20, "the relief reshapes the gully flanks")
