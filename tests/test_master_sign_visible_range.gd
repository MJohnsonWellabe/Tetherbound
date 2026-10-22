extends "res://tests/test_case.gd"

## Master signpost text has a draw distance (masters.json
## sign_presentation.visible_range_m), so it never floats over a fight 30 m
## away (Stormwood GPU pass, 22 Oct 2026).
const RUNS_IN_INITIALIZED_TREE := true
const SITE := preload("res://scripts/masters/master_site.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")

class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func test_sign_words_fade_out_past_the_configured_range() -> void:
	var presentation: Dictionary = BREAKTHROUGH.masters().sign_presentation
	var reach := float(presentation.get("visible_range_m", 0.0))
	assert_true(reach > 0.0 and reach <= 40.0, "signpost text needs a finite draw distance")
	var world := FlatWorld.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(world)
	var site := SITE.new()
	site.master_id = "master_t1"
	world.add_child(site)
	site._definition = BREAKTHROUGH.master("master_t1")
	site._build_sign(world)
	var sign := world.get_node_or_null("MasterSignpost")
	assert_true(sign != null, "signpost built")
	var words: Label3D = null
	for child: Node in sign.get_children():
		if child is Label3D:
			words = child
	assert_true(words != null, "signpost words built")
	assert_almost_eq(words.visibility_range_end, reach, 0.001, "words end at visible_range_m")
	assert_almost_eq(words.visibility_range_end_margin, float(presentation.get("fade_margin_m", 0.0)), 0.001)
	assert_eq(words.visibility_range_fade_mode, GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF)
	world.free()
