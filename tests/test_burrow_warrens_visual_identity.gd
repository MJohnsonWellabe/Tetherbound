extends "res://tests/test_case.gd"

const WARRENS_PATH := "res://data/config/burrow_warrens.json"
const SPECIES_PATH := "res://data/creatures/species.json"
const TRAINER_HEIGHT_M := 1.80


func test_guardian_scale_fits_the_approved_den_after_the_global_creature_pass() -> void:
	var warrens_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(WARRENS_PATH))
	var species_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPECIES_PATH))
	assert_true(warrens_raw is Dictionary, "Burrow Warrens config did not parse")
	assert_true(species_raw is Dictionary, "Creature species config did not parse")
	if not warrens_raw is Dictionary or not species_raw is Dictionary:
		return
	var warrens := warrens_raw as Dictionary
	var guardian: Dictionary = warrens.get("guardian", {})
	var species_id := str(guardian.get("species", ""))
	var species_table: Dictionary = (species_raw as Dictionary).get("species", {})
	var species: Dictionary = species_table.get(species_id, {})
	var placeholder: Dictionary = species.get("placeholder", {})
	var source_height := float(placeholder.get("height", 0.0))
	var source_radius := float(placeholder.get("radius", 0.0))
	var scale_value := float(guardian.get("scale", 1.0))
	var guardian_height := source_height * scale_value
	var guardian_diameter := source_radius * scale_value * 2.0

	assert_true(source_height > TRAINER_HEIGHT_M,
		"Ordinary Burrowback regressed below the fixed trainer")
	assert_true(scale_value >= 1.25,
		"Warren Guardian no longer reads larger than an ordinary Burrowback")
	assert_true(guardian_height >= TRAINER_HEIGHT_M * 2.0,
		"Warren Guardian no longer has a boss-scale silhouette")

	var den_height := 0.0
	for raw: Variant in warrens.get("chambers", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == "den":
			den_height = float((raw as Dictionary).get("height", 0.0))
	var passage_height := 0.0
	var passage_width := 0.0
	for raw: Variant in warrens.get("passages", []):
		if not raw is Dictionary:
			continue
		var passage := raw as Dictionary
		if str(passage.get("from", "")) == "hall" and str(passage.get("to", "")) == "den":
			passage_height = float(passage.get("height", 0.0))
			passage_width = float(passage.get("width", 0.0))
	assert_true(den_height - guardian_height >= 2.5,
		"Post-scale guardian crowds the approved den ceiling")
	assert_true(passage_height - guardian_height >= 0.35,
		"Post-scale guardian no longer clears its authored den threshold")
	assert_true(passage_width - guardian_diameter >= 0.25,
		"Post-scale guardian no longer fits the authored den threshold width")
