extends "res://tests/test_case.gd"

const CAPTURE := preload("res://tools/capture_f17_visual.gd")

func test_native_capture_preset_branches_return_typed_strings() -> void:
	# Execute the production preset selection without constructing a SceneTree.
	var low: Array[String] = CAPTURE.capture_presets("Low", false)
	assert_eq(low.size(), 1)
	assert_eq(low[0], "Low")
	var medium: Array[String] = CAPTURE.capture_presets("Medium", false)
	assert_eq(medium.size(), 1)
	assert_eq(medium[0], "Medium")
	var paired: Array[String] = CAPTURE.capture_presets("Medium", true)
	assert_eq(paired.size(), 2)
	assert_eq(paired[0], "Medium")
	assert_eq(paired[1], "High")
	# The same witness supports only identities with existing physical mounts.
	# Verify both against the authored hand-off API without creating rewards.
	var rewards := preload("res://scripts/net/encounter_rewards.gd")
	for biome: String in ["meadows", "cloudreach"]:
		var spec: Dictionary = CAPTURE.relic_witness_spec(biome)
		assert_false(spec.is_empty())
		var grant: Dictionary = rewards.chapter_hand_off(str(spec.boss), biome)
		assert_eq(grant.get("relic_biome"), biome, "selected fixture identity exists in authored rewards")
		assert_ne(spec.candidate, spec.baseline)
	assert_eq(CAPTURE.relic_witness_spec("meadows").mount, "MeadowsRelicDisplay")
	assert_eq(CAPTURE.relic_witness_spec("cloudreach").mount, "CloudreachRelicDisplay")
	assert_true(CAPTURE.relic_witness_spec("tidewake").is_empty(), "do not invent a Tideglass mount")
	assert_true(CAPTURE.relic_witness_spec("biome5").is_empty(), "sealed biomes cannot seed a witness")
