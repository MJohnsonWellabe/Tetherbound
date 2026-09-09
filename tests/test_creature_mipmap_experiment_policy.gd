extends "res://tests/test_case.gd"

## Static guard for the bounded experiment contract. It intentionally does not
## require production imports to have mipmaps before the experiment is judged.

const EXPERIMENT := preload("res://tools/probe_creature_mipmap_hierarchy.gd")
const COLOURWAYS := "res://data/creatures/four_biome_colourways.json"


func test_complete_review_cohort_is_unique_and_preregistered() -> void:
	assert_eq(EXPERIMENT.COHORT.size(), 20)
	var ids: Dictionary = {}
	for entry: Dictionary in EXPERIMENT.COHORT:
		var id := str(entry.get("id", ""))
		assert_false(id.is_empty())
		assert_false(ids.has(id), "cohort id is unique: " + id)
		ids[id] = true
		var face: Array = entry.get("face", [])
		assert_eq(face.size(), 4, id + " has a four-value face region")
		if face.size() == 4:
			assert_between(float(face[0]), 0.0, 1.0)
			assert_between(float(face[1]), 0.0, 1.0)
			assert_between(float(face[2]), 0.01, 1.0)
			assert_between(float(face[3]), 0.01, 1.0)
			assert_true(float(face[0]) + float(face[2]) <= 1.0)
			assert_true(float(face[1]) + float(face[3]) <= 1.0)
	for id: String in EXPERIMENT.FIXED_FIVE:
		var runtime_id := id
		if id == "torrentoad":
			runtime_id = "water_torrentoad"
		assert_true(ids.has(runtime_id), "fixed-five member is in full cohort: " + id)


func test_cohort_generated_species_are_covered_by_authored_colourway_policy() -> void:
	var file := FileAccess.open(COLOURWAYS, FileAccess.READ)
	assert_true(file != null)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary)
	if not parsed is Dictionary:
		return
	var species: Dictionary = (parsed as Dictionary).get("species", {})
	assert_eq(species.size(), 32, "policy remains the authored 32-species set")
	for entry: Dictionary in EXPERIMENT.COHORT:
		var runtime_id := str(entry.id)
		var source_id := runtime_id.trim_prefix("water_")
		if source_id in ["sparkit", "galecrest", "mosshell"]:
			# Explicit controls: Sparkit keeps its already-mipped source albedo;
			# Galecrest/Mosshell are older direct-vivid, full-PBR material assets.
			continue
		assert_true(species.has(source_id), runtime_id + " has an authored vivid policy")


func test_experiment_branches_preserve_capture_contract() -> void:
	assert_eq(EXPERIMENT.SIZE, Vector2i(1280, 800))
	assert_eq(EXPERIMENT.SUBPIXEL_OFFSETS, [0.0, 0.25, 0.5, 0.75])
	assert_eq(EXPERIMENT.BODY_GUARD, Rect2(0.04, 0.04, 0.92, 0.92))
