extends "res://tests/test_case.gd"

## STATE owner decision #11 (settled 2026-10-05): the Crossing Hall home arch
## returns the player to the last Meadows waystone they touched, exactly as
## the live biome arches do; with no touched Meadows stone it lands at the
## Meadows entry. Uses the shipped portals.json and waystones.json.
const POLICY := preload("res://scripts/net/portal_action_policy.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")

var _config: Dictionary
var _stones: Dictionary
var _policy: RefCounted

func before_each() -> void:
	_config = DATA.json("res://data/config/portals.json")
	_stones = DATA.json("res://data/config/waystones.json")
	_policy = POLICY.new()
	_policy.bind_world("arch-world")

func _context(last: Dictionary, active: Dictionary) -> Dictionary:
	return {"world_instance_id": "arch-world", "character_id": "walker", "peer_id": 2,
		"realm": "meadows", "position": Vector3.ZERO, "damage_revision": 0, "combat": false,
		"dialogue": false, "cutscene": false, "swimming": false, "flying": false, "downed": false,
		"arch_positions": {"home": Vector3.ZERO}, "character_unlocks": [], "world_unlocks": [],
		"last_waystones": last, "waystones_activated": active}

func _enter(context: Dictionary) -> Dictionary:
	var result: Dictionary = _policy.evaluate({"kind": "portal_enter", "arch_id": "home"}, context, _config, _stones, 0)
	assert_true(result.get("ok") == true, "home arch admits: " + str(result))
	return _policy.consume_permit(str(result.get("request_id", "")), 2, "walker", "arch-world", "meadows")

func test_shipped_config_settles_decision_11() -> void:
	assert_true(POLICY.meadows_waystone_return(_config), "portals.json ships the owner's ruling")

func test_home_arch_returns_to_the_last_touched_meadows_waystone() -> void:
	var permit := _enter(_context({"meadows": "meadows_ranger_camp"},
		{"meadows": ["meadows_trail_camp", "meadows_ranger_camp"]}))
	assert_eq(permit.get("realm"), "meadows")
	assert_eq(permit.get("entry_id"), "meadows_ranger_camp", "the last touched stone, not the first")

func test_home_arch_without_a_touched_meadows_stone_lands_at_the_entry() -> void:
	var permit := _enter(_context({"tidewake": "tidewake_first_shore"}, {}))
	assert_eq(permit.get("entry_id"), "meadows_entry")

func test_a_stale_meadows_stone_lands_at_the_entry_never_strands_the_player() -> void:
	# Never activated, or not a Meadows stone: the home arch is the only way
	# home, so it lands at the entry and never takes the unactivated stone.
	for last: String in ["meadows_ranger_camp", "tidewake_first_shore", "no_such_stone"]:
		var permit := _enter(_context({"meadows": last}, {"meadows": []}))
		assert_eq(permit.get("entry_id"), "meadows_entry", last)

func test_a_live_biome_arch_still_refuses_an_unactivated_saved_stone() -> void:
	var context := _context({"tidewake": "tidewake_first_shore"}, {"tidewake": []})
	context.character_unlocks = ["tidewake"]
	context.arch_positions = {"tidewake": Vector3.ZERO}
	var result: Dictionary = _policy.evaluate({"kind": "portal_enter", "arch_id": "tidewake"}, context, _config, _stones, 0)
	assert_false(result.get("ok") == true, "a forged biome return point is still refused")
