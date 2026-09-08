extends "res://tests/test_case.gd"

const RUNNER := preload("res://tests/smoke_stormwood_continuous.gd")
const SOURCE := "res://tests/smoke_stormwood_continuous.gd"

func test_route_rewards_follow_the_actual_item_and_exact_quantity() -> void:
	assert_eq(RUNNER.Segment.route_pickup_reward("stormwood_pickup_route_03"),
		{"item": "good_candy", "count": 1})
	assert_eq(RUNNER.Segment.route_pickup_reward("stormwood_pickup_route_07"),
		{"item": "good_candy", "count": 1})
	assert_eq(RUNNER.Segment.route_pickup_reward("stormwood_pickup_route_09"),
		{"item": "great_candy", "count": 1})
	assert_true(RUNNER.Segment.route_pickup_reward("missing-route-pickup").is_empty())

func test_ondra_reward_precedes_the_exact_dialogue_and_retains_receipt_and_gain_checks() -> void:
	var source := FileAccess.get_file_as_string(SOURCE)
	var collect := source.find("_collect_route_pickup(ONDRA_ROUTE_PICKUP_ID)")
	var talk := source.find("_talk_to(\"Keeper Ondra\"")
	assert_true(collect >= 0 and collect < talk)
	assert_true(source.contains("_wait_flag(flag, 300)"))
	assert_true(source.contains("gained != int(reward.count)"))

func test_crown_extension_is_opt_in_and_inherits_only_the_successful_live_prefix() -> void:
	assert_false(RUNNER.through_crown(PackedStringArray()))
	assert_true(RUNNER.through_crown(PackedStringArray(["--through-crown"])))
	assert_false(RUNNER.through_crown(PackedStringArray(["--unrelated"])))
	var source := FileAccess.get_file_as_string(SOURCE)
	assert_true(source.contains("if _prefix_complete and through_crown("))
	assert_true(source.contains("await crown.run(self, world, game)"))
