extends "res://tests/test_case.gd"
const LINEAGE := preload("res://tools/earned_saves/checkpoint_lineage.gd")

func test_generated_input_survives_multiple_successful_descendants() -> void:
	var first := LINEAGE.derive({"passed": true, "input_mode": "generated_levels"}, {})
	for step in 3:
		first = LINEAGE.derive({"passed": true, "input_mode": "earned", "lineage": first}, {})
		assert_eq(LINEAGE.input_mode(first), "generated_ancestry")
		assert_false(first.continuous_fresh_save)
	assert_true(first.origins.has("predecessor input_mode=generated_levels"))

func test_legacy_earned_label_cannot_hide_fixture_provenance() -> void:
	for provenance: Dictionary in [{"prior_earned_play": false}, {"lineage_root": "tidewake_arrival_generated"}]:
		assert_eq(LINEAGE.derive({"passed": true, "input_mode": "earned"}, provenance).status, "generated")
	assert_eq(LINEAGE.derive({"generated_origin": {"boundary": "warrens"}}, {}).status, "generated")
	assert_eq(LINEAGE.derive({"disclosures": ["GENERATED INPUT: levels raised"]}, {}).status, "generated")

func test_unknown_legacy_input_never_becomes_verified_earned() -> void:
	assert_eq(LINEAGE.input_mode(LINEAGE.derive({"passed": true, "input_mode": "earned"}, {})), "unproven_ancestry")
	assert_false(LINEAGE.derive({}, {}).continuous_fresh_save)
	assert_eq(LINEAGE.derive({"lineage": {"status": "earned"}}, {}).status, "unproven")

func test_historical_tidewake_tidal_fixture_keeps_generated_ancestry() -> void:
	var lineage := LINEAGE.from_directory("res://tests/fixtures/earned_saves/tidewake_05_tidal")
	assert_eq(lineage.status, "generated")
	assert_false(lineage.continuous_fresh_save)

func test_current_generation_overrides_verified_prefix_and_detaches_origins() -> void:
	var earned := LINEAGE.derive({}, {}, [], true)
	assert_eq(LINEAGE.input_mode(earned), "earned")
	var generated := LINEAGE.derive({"lineage": earned}, {}, ["replaced owned members"])
	assert_eq(generated.status, "generated")
	assert_true(earned.origins.is_empty())
	assert_eq(LINEAGE.derive({"lineage": generated}, {}).origins, ["replaced owned members"])
