extends "res://tests/test_case.gd"

## BEINGS-TERRAPUP-SPHINX (F38#1): creature_model_flags.json
## `beings_terrapup_sphinx_rest`, OFF until GPU-judged. Terrapup's remake rests
## on a copy of its faint clip (a 90-degree flank roll), so resting and fainted
## were the same side-lie. The flag swaps only Terrapup's authored rest recipe
## for a belly-down lying dog; the model, clips and faint stay as they are.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLAGS_PATH := "res://data/config/creature_model_flags.json"
const FLAG := "beings_terrapup_sphinx_rest"


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_model_flags.json parses")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func test_flag_is_off_and_declares_scope() -> void:
	var entry: Dictionary = _flags().get(FLAG, {})
	assert_false(entry.is_empty(), "%s exists" % FLAG)
	assert_false(bool(entry.get("enabled", true)), "%s is OFF until GPU-judged" % FLAG)
	assert_true(str(entry.get("scope", "")).contains("no state"), "it declares a presentation-only scope")
	var live: Dictionary = (SPECIES.table()["terrapup"]["placeholder"] as Dictionary).get("rest_pose", {})
	assert_false((live.get("bones", {}) as Dictionary).has("front_upper_l"),
		"OFF: Terrapup keeps the side-lie rest recipe")


func test_on_swaps_only_terrapups_rest_recipe() -> void:
	var entry: Dictionary = (_flags()[FLAG] as Dictionary).duplicate(true)
	entry["enabled"] = true
	var rows := {"terrapup": {"placeholder": {"model": "m", "rest_pose": {"clip_role": "rest"}}},
		"bramblebun": {"placeholder": {"model": "b"}}}
	SPECIES.merge_model_flags(rows, {FLAG: entry})
	var recipe: Dictionary = rows["terrapup"]["placeholder"]["rest_pose"]
	assert_eq(str(rows["terrapup"]["placeholder"]["model"]), "m", "the model is unchanged")
	assert_eq(str(recipe.get("clip_role", "")), "rest", "the recipe still finishes Terrapup's own rest clip")
	var bones: Dictionary = recipe.get("bones", {})
	for bone: String in ["root", "front_upper_l", "front_upper_r", "rear_upper_l", "rear_upper_r"]:
		assert_true(bones.has(bone), "the recipe poses %s" % bone)
	# The rest clip ends rolled +90 degrees about Z; the recipe undoes it.
	assert_eq(float((bones["root"]["rotation_deg"] as Array)[2]), -90.0, "the flank roll is undone")
	assert_true(float((bones["root"]["position_offset"] as Array)[1]) < 0.0, "the body is lowered onto its belly")
	assert_false((rows["bramblebun"]["placeholder"] as Dictionary).has("rest_pose"), "no other species changes")
