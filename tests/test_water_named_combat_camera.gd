extends "res://tests/test_case.gd"

## F14#0 C3: a Water named encounter may author a fight-camera block
## (`combat_camera`, the same shape WaterAlpha passes for Aquaryn). The
## director's named plan carries it to the body's meta, where
## CombatManager._opponent_camera reads it. Tidecoil's stand is the Deep Watch
## arrival bay, clear of the reef-edge cliff.

const DIRECTOR := preload("res://scripts/combat/water_encounter_director.gd")

var config: Dictionary


func before_each() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_encounters.json"))


func _site(id: String) -> Dictionary:
	for site: Dictionary in config.get("wild_sites", config.get("sites", [])):
		if str(site.get("id", "")) == id:
			return site
	return {}


func test_the_named_plan_carries_tidecoils_camera_block() -> void:
	var site := _site("water_deep_watch_wild_008")
	assert_false(site.is_empty(), "Tidecoil's reserved site exists")
	var plan: Dictionary = DIRECTOR.named_spawn_plan(site, config.get("named_encounters", []))
	assert_eq(str(plan.get("id", "")), "water_deep_watch_tidecoil", "the site resolves to Tidecoil")
	var camera: Dictionary = plan.get("combat_camera", {})
	assert_true(bool((camera.get("framing", {}) as Dictionary).get("top_band", false)), "the block asks for the top band")
	assert_eq(float((camera.get("framing", {}) as Dictionary).get("top_fill", 0.0)), 0.46, "Aquaryn's top fill")


func test_a_named_row_without_a_block_carries_an_empty_one() -> void:
	for site: Dictionary in config.get("wild_sites", config.get("sites", [])):
		if str(site.get("named_replacement_id", "")).is_empty() or site.id == "water_deep_watch_wild_008":
			continue
		var plan: Dictionary = DIRECTOR.named_spawn_plan(site, config.get("named_encounters", []))
		if plan.is_empty():
			continue
		assert_true((plan.get("combat_camera", {}) as Dictionary).is_empty(), "%s authors no camera block" % site.id)


func test_the_site_and_the_named_body_share_the_arrival_bay_stand() -> void:
	var site := _site("water_deep_watch_wild_008")
	var named: Dictionary = {}
	for row: Dictionary in config.get("named_encounters", []):
		if str(row.get("id", "")) == "water_deep_watch_tidecoil":
			named = row
	var landing := Vector2(1260.318, 3403.144)
	var at := Vector2(float(named.position[0]), float(named.position[2]))
	assert_eq(Vector2(float(site.position[0]), float(site.position[2])), at, "site and body agree")
	assert_true(at.distance_to(landing) < 40.0, "the stand is in the arrival bay, within reach of the landing")
	assert_true(at.distance_to(landing) > 18.0, "but off the landing itself")
