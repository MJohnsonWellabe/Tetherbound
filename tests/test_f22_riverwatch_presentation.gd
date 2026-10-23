extends "res://tests/test_case.gd"

## F22#4 Riverwatch (r13, CPU-provisional 7.03 mapped): Captain Oreth's
## signature rows draw in the water hue rather than the shared magenta, a
## completed water strike throws a droplet spray beside its splash crown, and
## the captain's Brooktail is grown (never shrunk). Presentation contract only;
## hit shapes, timings and power are pinned by the named-fight tests.

## The strike test mounts real nodes under the root.
const RUNS_IN_INITIALIZED_TREE := true
const TELEGRAPH := preload("res://scripts/combat/enemy_pattern_telegraph.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const BURST := preload("res://scripts/vfx/vfx_burst.gd")
const ORETH_ROWS := ["oreth_pressure", "oreth_overflow", "oreth_flood"]


func _attacks() -> Dictionary:
	return MATH.config().get("patterns", {}).get("attacks", {})


func test_oreth_rows_use_the_water_hue_not_the_shared_magenta() -> void:
	var shared := Color(str(MATH.config().get("telegraph", {}).get("colour", "#ff40e6")))
	for id: String in ORETH_ROWS:
		var row: Dictionary = _attacks().get(id, {})
		assert_true(row.has("telegraph_colour"), "%s names its own tell hue" % id)
		var hue := Color(str(row.get("telegraph_colour", "#ff40e6")))
		assert_true(absf(hue.h - shared.h) > 0.2, "%s hue %.2f is clear of the shared magenta %.2f" % [id, hue.h, shared.h])


func test_a_completed_water_strike_throws_droplets() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var host := Node3D.new()
	tree.root.add_child(host)
	var body := Node3D.new()
	host.add_child(body)
	var striking := 0
	for id: String in ORETH_ROWS:
		var row: Dictionary = _attacks().get(id, {})
		if row.get("cue_water_burst") != true:
			continue
		striking += 1
		assert_true(float(row.get("cue_burst_droplets", 0.0)) > 0.0, "%s carries a droplet spray" % id)
		var before := host.get_child_count()
		TELEGRAPH.strike_burst(body, row, {"origin": Vector3.ZERO, "heading": Vector3.FORWARD,
			"marker": Vector3(0.0, 0.0, -3.0)})
		assert_eq(host.get_child_count(), before + 1, "%s spawned one burst" % id)
		var burst := host.get_child(host.get_child_count() - 1)
		var sprays := 0
		for child: Node in burst.get_children():
			if child.get_script() == BURST:
				sprays += 1
		assert_true(sprays > 0, "%s burst holds a droplet spray (%d)" % [id, sprays])
	assert_true(striking > 0, "at least one Oreth row bursts on its strike")
	host.free()


func test_the_captain_brooktail_is_grown_not_shrunk() -> void:
	var path := "res://data/config/bands/band3_the_river_lock/trainers.json"
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	var found := false
	for trainer: Variant in (data as Dictionary).get("trainers", []):
		if trainer is Dictionary and str(trainer.get("id", "")) == "captain_riverwatch":
			for member: Variant in trainer.get("team", []):
				if member is Dictionary and str(member.get("species", "")) == "brooktail" \
						and member.has("body_scale"):
					found = true
					assert_true(float(member.body_scale) >= 1.0, "grow-only: body_scale %.2f" % float(member.body_scale))
					assert_true(float(member.body_scale) >= 2.0, "the captain's ace reads as a boss")
	assert_true(found, "captain_riverwatch fields a scaled Brooktail")
