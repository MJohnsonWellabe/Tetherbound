extends "res://tests/test_case.gd"

## F38#30 P2-012 (LANE-FLOOR2, 11 Nov 2026): `bank.hill_shell.meadow_match`
## puts the meadow's own grass on the mound shell's up-facing faces and stands
## grass tufts on them. Ships ON: G-floor2-warrens-meadow-match, GPU High
## 5.23 -> 6.02, 3/3.

const CONFIG := "res://data/config/burrow_warrens.json"
const NATURE := "res://assets/environment/stylized_nature/%s.gltf"


func _meadow() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_true(parsed is Dictionary, "burrow_warrens.json parses")
	return (((parsed as Dictionary).get("bank", {}) as Dictionary).get("hill_shell", {}) as Dictionary).get("meadow_match", {})


func test_meadow_match_ships_on_with_its_verdict() -> void:
	var meadow := _meadow()
	assert_true(bool(meadow.get("enabled", false)), "meadow_match ships ON (judged gain)")
	assert_true(str(meadow.get("_why_on", "")).contains("5.23 -> 6.02"), "records its judged score")
	assert_eq(str(meadow.get("scope", "")), "client_presentation", "presentation only")


func test_grass_sits_at_the_meadows_tiling_on_up_facing_faces() -> void:
	var meadow := _meadow()
	assert_almost_eq(float(meadow.get("mix", 0.0)), 1.0, 0.0001, "up-facing faces take the meadow sheet fully")
	assert_almost_eq(float(meadow.get("uv_per_m", 0.0)), 0.27, 0.0001, "the judged tiling")
	var facing: Array = meadow.get("normal_up", [])
	assert_eq(facing.size(), 2, "blend band declared")
	assert_true(float(facing[0]) > 0.0 and float(facing[0]) < float(facing[1]), "steep faces keep the shell's earth")


func test_cover_uses_installed_models_and_stays_clear_of_the_mouth() -> void:
	var cover: Dictionary = _meadow().get("cover", {})
	assert_eq(int(cover.get("count", 0)), 260, "the judged tuft count")
	assert_true(float(cover.get("mouth_pad_m", 0.0)) >= 1.0, "tufts keep clear of the mouth")
	assert_true(float(cover.get("min_up", 0.0)) >= 0.5, "tufts stand only on up-facing faces")
	var models: Array = cover.get("models", [])
	assert_false(models.is_empty(), "cover models declared")
	for model: String in models:
		assert_true(ResourceLoader.exists(NATURE % model), "%s is installed" % model)
