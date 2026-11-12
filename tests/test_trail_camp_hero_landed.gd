extends "res://tests/test_case.gd"

## F38#32 P2-035 (LANE-FLOOR2, 12 Nov 2026): the Trail Camp candidate ships ON
## (G-floor2-camp-r2, GPU High 6.26 -> 6.91, no frame loses): small loose
## props are left out, the TRAIL CAMP board's labels show one face each, and
## the gate timber is a plain weathered brown. Nothing is scaled. The bonfire
## frame's capture stand looks from the east.

const PROPS := "res://data/config/props.json"
const STANDS := "res://data/config/capture_stands.json"
const THRESHOLD := preload("res://scripts/world/trail_camp_roadside_threshold.gd")
const INVENTORY := preload("res://tools/phase2_capture_world_inventory.gd")


func _hero() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROPS))
	assert_true(parsed is Dictionary, "props.json parses")
	return ((parsed as Dictionary).get("hero_candidates", {}) as Dictionary).get("trail_camp", {})


func test_candidate_ships_on_with_its_verdict() -> void:
	var hero := _hero()
	assert_true(bool(hero.get("enabled", false)), "hero_candidates.trail_camp ships ON")
	assert_true(str(hero.get("_why_on", "")).contains("6.26 -> 6.91"), "records its judged score")
	assert_eq(str(hero.get("scope", "")), "client_presentation")


func test_it_declutters_and_scales_nothing() -> void:
	var hero := _hero()
	# Attempt 1 scaled the tent, fire and ring and lost on GPU (-0.44, 0/3).
	assert_false(hero.has("prop_scale"), "no prop is scaled")
	assert_eq(hero.get("drop_models", []), ["Rope_1", "Bag", "Fern_1", "Clover_1"])
	for kept: String in ["camp_tent", "camp_bed", "Bonfire_Fire", "campfire_stone_ring"]:
		assert_false((hero.get("drop_models", []) as Array).has(kept), "%s stays" % kept)


func test_sign_reads_from_both_sides_in_plain_wood() -> void:
	var hero := _hero()
	assert_true(bool(hero.get("single_sided_sign", false)), "labels draw one face each")
	var tint := Color(str(hero.get("sign_wood_tint", "")))
	# Red and oxblood are Team Tether's: the timber is a brown with no red cast.
	assert_true(tint.r - tint.g < 0.08 and tint.r - tint.b < 0.14, "gate timber carries no red cast (%s)" % str(hero.get("sign_wood_tint", "")))
	var gate := THRESHOLD.new()
	gate.single_sided_labels = true
	gate.wood_tint = str(hero.get("sign_wood_tint", ""))
	gate.build(Vector3.ZERO, 0.0)
	for name: String in ["TrailCampLabelFront", "TrailCampLabelBack"]:
		var label := gate.get_node(name) as Label3D
		assert_false(label.double_sided, "%s shows one face" % name)
	var board := gate.get_node("TrailCampBoard") as MeshInstance3D
	var wood := board.material_override as StandardMaterial3D
	assert_eq(wood.albedo_texture, null, "the banded trim albedo is not used")
	gate.free()
	var shipped := THRESHOLD.new()
	shipped.build(Vector3.ZERO, 0.0)
	assert_true((shipped.get_node("TrailCampLabelFront") as Label3D).double_sided, "off keeps the old labels")
	shipped.free()


func test_bonfire_frame_looks_from_the_east() -> void:
	var heading: Variant = INVENTORY.stand_heading_override(STANDS, "meadows__inventory__prop__bonfire_fire")
	assert_true(heading != null, "the bonfire frame has a reviewed stand")
	assert_almost_eq(float(heading), 90.0, 0.0001, "heading 90")
