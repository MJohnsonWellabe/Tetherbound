extends "res://tests/test_case.gd"

## Flag-off candidates from the STORMCAMS lane (1 Nov): each is inert while its
## `enabled` is false and replaces only its own keys when on.

const GLASS_SINK := preload("res://scripts/world/stormwood_glass_sink.gd")
const GROUNDING := preload("res://scripts/world/pickup_grounding.gd")


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func test_glass_sink_dark_pool_is_off_and_inert_by_default() -> void:
	var config := _json("res://data/config/stormwood_glass_sink.json")
	assert_true(config.has("dark_pool_candidate"), "the P2-070 candidate must be declared")
	assert_false(bool((config["dark_pool_candidate"] as Dictionary).get("enabled", true)),
		"the candidate ships OFF")
	var same := GLASS_SINK.with_dark_pool(config)
	assert_eq(same["glass_colour"], config["glass_colour"], "OFF must not change the glass")


func test_glass_sink_dark_pool_on_darkens_the_glass_and_fades_far_specular() -> void:
	var config := _json("res://data/config/stormwood_glass_sink.json")
	var cand: Dictionary = (config["dark_pool_candidate"] as Dictionary).duplicate(true)
	cand["enabled"] = true
	config["dark_pool_candidate"] = cand
	var on := GLASS_SINK.with_dark_pool(config)
	assert_true(Color(str(on["glass_colour"])).get_luminance()
			< Color(str(config["glass_colour"])).get_luminance(), "the pool must read darker")
	var far: Array = on["far_fade_m"]
	assert_true(float(far[1]) > float(far[0]), "the far fade must be switched on")
	assert_false(on.has("enabled"), "the switch must not leak into the material keys")


func test_candy_tiers_are_off_by_default() -> void:
	var config := _json("res://data/config/pickup_grounding.json")
	assert_false(bool((config.get("tier_candidate", {}) as Dictionary).get("enabled", true)),
		"the P2-045 candidate ships OFF")
	if not bool((GROUNDING.config().get("tier_candidate", {}) as Dictionary).get("enabled", false)):
		assert_true(GROUNDING.tier_spec("rare_candy").is_empty(), "OFF must give no tier change")


func test_candy_tiers_differ_in_count_and_size_when_declared() -> void:
	var items: Dictionary = (_json("res://data/config/pickup_grounding.json")["tier_candidate"] as Dictionary)["items"]
	var good: Dictionary = items["good_candy"]
	var great: Dictionary = items["great_candy"]
	var rare: Dictionary = items["rare_candy"]
	assert_true(int(good.get("count", 1)) < int(great.get("count", 1))
		and int(great.get("count", 1)) < int(rare.get("count", 1)), "each tier needs its own count")
	assert_true(float(good["scale_mult"]) < float(great["scale_mult"])
		and float(great["scale_mult"]) < float(rare["scale_mult"]), "each tier needs its own size step")


func test_harvest_hero2_is_off_and_gives_crown_its_own_silhouette() -> void:
	var cfg := _json("res://data/config/stormwood_harvest_hero2.json")
	assert_false(bool(cfg.get("enabled", true)), "the P2-046 round-2 candidate ships OFF")
	assert_true(preload("res://scripts/world/stormwood_harvest_runtime.gd").hero2_for("stormglass").is_empty(),
		"OFF must leave the landed hero in charge")
	var items: Dictionary = cfg["items"]
	var plain: Dictionary = (items["stormglass"]["models"] as Array)[0]
	var crown: Dictionary = (items["stormglass_crown"]["models"] as Array)[0]
	assert_ne(str(plain["model"]), str(crown["model"]), "stormglass and its crown need different silhouettes")
	assert_true(float((crown["height_m"] as Array)[0]) > float((plain["height_m"] as Array)[0]),
		"the crown grade must stand taller")


func test_glass_field_rock_collar_ships_off() -> void:
	var cfg := _json("res://data/config/stormwood_glass_field.json")
	var collar: Dictionary = cfg.get("rock_collar_candidate", {})
	assert_true(collar.has("stones"), "the P2-043 candidate must be declared")
	assert_false(bool(collar.get("enabled", true)), "the candidate ships OFF")
