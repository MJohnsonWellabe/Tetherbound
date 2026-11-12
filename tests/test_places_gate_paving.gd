extends "res://tests/test_case.gd"

## LANE-PLACES (12 Nov 2026): `paving_scale_1112` ships ON, scoped to the
## Realm Gate road stands. GPU G-places-gatepaving: +0.93 / +0.79 on the gate
## road (3/3); on grass stands with no path the small sunk stones lost 0.61, so
## those stands keep the shipped pieces.


func _cfg() -> Dictionary:
	return (JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_f40_items.json")) as Dictionary).paving_scale_1112


func test_gate_paving_ships_on_scoped_to_the_road_stands() -> void:
	var cfg := _cfg()
	assert_true(bool(cfg.enabled), "paving_scale_1112 ships ON")
	assert_true(str(cfg.get("_why_on", "")).contains("G-places-gatepaving"), "the judged verdict is recorded")
	var stands: Array = cfg.stands
	assert_true(stands.has("gate_road_close") and stands.has("gate_road_approach"), "the gate road stands take the fix")
	for grass: String in ["gate_landmark_approach", "shrine_walk_a", "shrine_walk_b", "heartstone_approach"]:
		assert_false(stands.has(grass), "%s (no dirt path) keeps the shipped pieces" % grass)


func test_gate_paving_is_at_the_trainers_scale_and_sunk() -> void:
	var cfg := _cfg()
	assert_true(float(cfg.height_m) <= 0.15, "pieces near the model's own size (stones about a boot long)")
	var proud := float(cfg.height_m) * (1.0 - float(cfg.sink_fraction))
	assert_true(proud <= 0.08, "tops stand %.3f m proud, never shin height" % proud)
