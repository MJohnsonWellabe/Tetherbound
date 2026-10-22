extends "res://tests/test_case.gd"

## WORKFLOW §8.1 rule 9 light cut: the runner's own touched-path check.
const HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")


func test_other_realm_files_cannot_block_a_meadows_piece() -> void:
	var diff := ["scripts/combat/stormwood_encounter_director.gd", "scripts/world/cloudreach_scene_encounters.gd",
		"data/config/bands/water_trainers.json", "docs/STATE.md", "tools/earned_saves/stormwood_chain_runner.gd"]
	assert_eq(HANDOFF.light_cut_touched(diff, "warrens"), {})


func test_meadows_or_shared_encounter_code_blocks_a_meadows_piece() -> void:
	var touched := HANDOFF.light_cut_touched(["scripts/combat/combat_manager.gd", "data/config/combat.json",
		"scripts/save/save_game.gd", "tests/helpers/meadows_earned_warrens_segment.gd"], "relay")
	assert_eq(touched.get("scripts/combat/combat_manager.gd"), "encounter")
	assert_eq(touched.get("data/config/combat.json"), "encounter")
	assert_eq(touched.get("scripts/save/save_game.gd"), "save_schema")
	assert_eq(touched.get("tests/helpers/meadows_earned_warrens_segment.gd"), "route")


func test_a_stormwood_piece_is_blocked_by_its_own_realm_not_by_meadows() -> void:
	assert_eq(HANDOFF.piece_realm("stormwood_crown"), "stormwood")
	assert_eq(HANDOFF.light_cut_touched(["scripts/combat/stormwood_encounter_director.gd"], "stormwood_crown").keys(),
		["scripts/combat/stormwood_encounter_director.gd"])
	assert_eq(HANDOFF.light_cut_touched(["tests/helpers/meadows_earned_relay_segment.gd"], "stormwood_crown"), {})


func test_recorded_light_transition_must_bind_its_pair_and_be_clean() -> void:
	var t := {"kind": "f49_light_cut", "producer_commit": "a", "consumer_commit": "b",
		"imported_boundary": "bridge", "touched": [], "reviewer": "routes"}
	assert_true(HANDOFF.light_transition_ok(t, "a", "b", "bridge"))
	assert_false(HANDOFF.light_transition_ok(t, "a", "c", "bridge"))
	assert_false(HANDOFF.light_transition_ok(t, "a", "b", "warrens"))
	var dirty := t.duplicate(true)
	dirty.touched = ["scripts/combat/combat_manager.gd"]
	assert_false(HANDOFF.light_transition_ok(dirty, "a", "b", "bridge"))
	var anonymous := t.duplicate(true)
	anonymous.reviewer = ""
	assert_false(HANDOFF.light_transition_ok(anonymous, "a", "b", "bridge"))

## Owner, 22 Oct 2026: a piece may start from its predecessor's accepted save
## made on an earlier commit. The recorded transition must bind exactly that
## producer, this consumer and the imported boundary.
func test_pinned_start_transition_binds_its_exact_pair() -> void:
	var a := "a".repeat(40)
	var b := "b".repeat(40)
	var ok := {"kind": "f49_pinned_start", "producer_commit": a, "consumer_commit": b, "imported_boundary": "training_t1_altar_5"}
	assert_true(HANDOFF.pinned_transition_ok(ok, a, b, "training_t1_altar_5"))
	assert_false(HANDOFF.pinned_transition_ok(ok, b, b, "training_t1_altar_5"))
	assert_false(HANDOFF.pinned_transition_ok(ok, a, a, "training_t1_altar_5"))
	assert_false(HANDOFF.pinned_transition_ok(ok, a, b, "training_t1_altar_4"))
	var light := ok.duplicate()
	light.kind = "f49_light_cut"
	assert_false(HANDOFF.pinned_transition_ok(light, a, b, "training_t1_altar_5"))
	assert_false(HANDOFF.pinned_transition_ok({}, a, b, "training_t1_altar_5"))
