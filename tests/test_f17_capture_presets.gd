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
	for biome: String in ["meadows", "cloudreach", "stormwood"]:
		var spec: Dictionary = CAPTURE.relic_witness_spec(biome)
		assert_false(spec.is_empty())
		var grant: Dictionary = rewards.chapter_hand_off(str(spec.boss), biome)
		assert_eq(grant.get("relic_biome"), biome, "selected fixture identity exists in authored rewards")
		assert_ne(spec.candidate, spec.baseline)
	assert_eq(CAPTURE.relic_witness_spec("meadows").mount, "MeadowsRelicDisplay")
	assert_eq(CAPTURE.relic_witness_spec("cloudreach").mount, "CloudreachRelicDisplay")
	assert_eq(CAPTURE.relic_witness_spec("stormwood").mount, "StormwoodRelicDisplay")
	assert_true(CAPTURE.relic_witness_spec("tidewake").is_empty(), "do not invent a Tideglass mount")
	assert_true(CAPTURE.relic_witness_spec("biome5").is_empty(), "sealed biomes cannot seed a witness")
	# The outer first-column relics lie behind the partition from room centre.
	# The optional actual nave-side doorway viewpoint must clear that partition
	# for all four live mounts, without moving any pedestal or camera manually.
	var doorway := Vector3(7, 0, 0)
	var view: Vector3 = CAPTURE.relic_doorway_stand(doorway)
	assert_true(view.x < doorway.x, "viewpoint remains in the nave")
	var hall_config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/crossing_hall.json"))
	var prefabs := preload("res://scripts/world/building_prefabs.gd")
	var recipes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/building_prefabs.json"))
	var shell: Dictionary = recipes.prefabs.crossing_hall_shell
	var candidate_args := PackedStringArray(["--hall-doorway-candidate", "--hall-stills-only", "--hall-relic-hang-witness"])
	assert_false(hall_config.shrine_doorway.enabled, "unjudged physical candidate remains off")
	assert_eq(prefabs.hall_doorway_recipe(shell, hall_config.shrine_doorway, PackedStringArray(), false), shell)
	assert_eq(prefabs.hall_doorway_recipe(shell, hall_config.shrine_doorway, candidate_args, false), shell, "ordinary game/network cannot use process-only geometry")
	var baseline_args := candidate_args.duplicate()
	baseline_args.append("--hall-doorway-baseline")
	assert_eq(prefabs.hall_doorway_recipe(shell, hall_config.shrine_doorway, baseline_args, true), shell)
	var raised: Dictionary = prefabs.hall_doorway_recipe(shell, hall_config.shrine_doorway, candidate_args, true)
	assert_ne(raised, shell)
	var changed_modules := 0
	for index in shell.modules.size():
		if shell.modules[index] == raised.modules[index]:
			continue
		changed_modules += 1
		assert_eq(raised.modules[index].module, "Wall_UnevenBrick_Straight")
		assert_eq(raised.modules[index].at[1], 5.2)
		assert_almost_eq(float(raised.modules[index].scale_y) * 3.12, 1.04, 0.00001)
	assert_eq(changed_modules, 3)
	var changed_boxes := 0
	for index in shell.colliders.size():
		if shell.colliders[index] == raised.colliders[index]:
			continue
		changed_boxes += 1
		assert_almost_eq(float(raised.colliders[index].at[1]) - float(raised.colliders[index].size[1]) * 0.5, 5.2, 0.00001)
		assert_eq(raised.colliders[index].size[2], 4)
	assert_eq(changed_boxes, 1)
	assert_eq(shell, recipes.prefabs.crossing_hall_shell, "candidate does not mutate source recipe")
	for row: Dictionary in hall_config.pedestals.slice(0, 4):
		var fraction := (doorway.x - view.x) / (float(row.at[0]) - view.x)
		var crossing_z := view.z + (float(row.at[2]) - view.z) * fraction
		assert_true(absf(crossing_z) < 2.0, "actual live-pedestal sightline passes the unchanged four-metre doorway")
