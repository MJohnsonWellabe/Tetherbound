extends "res://tests/test_case.gd"

## P2-005 (vis-meadows, OFF until GPU-judged): grass_field.json
## `meadows_ground_candidate` layers ground zones and tighter flower drifts
## onto the Meadows field only when enabled.

const GRASS := preload("res://scripts/world/grass_field.gd")
const CONFIG := "res://data/config/grass_field.json"


func _shipping() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary


func test_candidate_ships_on_and_off_changes_nothing() -> void:
	var cfg := _shipping()
	assert_true(bool(cfg.meadows_ground_candidate.get("enabled", false)), "P2-005 candidate ships ON: cloud yardstick 1 Nov batch-1, 5.42 -> 6.09")
	var off := cfg.duplicate(true)
	off.meadows_ground_candidate.enabled = false
	var applied := off.duplicate(true)
	GRASS.apply_meadows_ground_candidate(applied)
	assert_eq(JSON.stringify(applied), JSON.stringify(off), "OFF still changes nothing")
	assert_false(off.has("zone_strength"), "OFF Meadows has no ground zones")


func test_on_sets_zones_and_merges_named_flower_tiers_only() -> void:
	var cfg := _shipping()
	cfg.meadows_ground_candidate.enabled = true
	var bushes_before := JSON.stringify((cfg.cover_tiers as Array).filter(func(r: Dictionary) -> bool: return r.name == "bushes"))
	GRASS.apply_meadows_ground_candidate(cfg)
	assert_almost_eq(float(cfg.zone_strength), 0.85)
	assert_eq((cfg.zone_bare as Array).size(), 2)
	var flowers: Dictionary = (cfg.cover_tiers as Array).filter(func(r: Dictionary) -> bool: return r.name == "flowers")[0]
	assert_almost_eq(float(flowers.patch_start), 0.6)
	assert_eq(int(flowers.count), 12000, "unmentioned tier keys stay")
	assert_eq(JSON.stringify((cfg.cover_tiers as Array).filter(func(r: Dictionary) -> bool: return r.name == "bushes")), bushes_before)
