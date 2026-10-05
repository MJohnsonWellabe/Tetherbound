extends "res://tests/test_case.gd"

## F31#4 (HOMESTEAD §9, hard rule): nothing produces while the player is away
## or not interacting. Crops need a harvest tap and never stack yield; the
## Forge pays only during a present, ticking channel and never catches up; no
## homestead config carries a passive-yield/offline/automation field.
const FARM := preload("res://scripts/world/farm_logic.gd")
const FORGE := preload("res://scripts/build/station_forge.gd")

class ForgeDouble extends "res://scripts/build/station_forge.gd":
	var present := true
	var commits := 0
	func _current_plan(_actor: CharacterBody3D) -> Dictionary:
		if not present:
			return {"ok": false, "code": "out_of_radius", "reason": "away"}
		return {"ok": true, "character_id": "c", "world_id": "w", "world_namespace": "n",
			"channel": {"seconds_per_unit": 2.0}}

func _forge() -> ForgeDouble:
	var forge := ForgeDouble.new()
	forge.set("_config", {"maximum_tick_delta_seconds": 0.25})
	forge.set("_character_id", "c")
	forge.set("_world_id", "w")
	forge.set("_namespace", "n")
	forge.set("_actor", weakref(forge))
	forge.set("_commit", func(_plan: Dictionary, _ticket: String, _actor: Variant) -> Variant:
		forge.commits += 1
		return null)
	forge.set("_running", true)
	return forge


func test_a_ripe_crop_waits_for_the_harvest_tap_and_never_stacks() -> void:
	var plot: Dictionary = FARM.sown(FARM.fresh(), 3, 1)
	var after_a_day := FARM.ripened(plot, 4)
	var after_a_season := FARM.ripened(plot, 400)
	assert_eq(FARM.state_of(plot, 400), FARM.RIPE, "still waiting for the player")
	assert_eq(after_a_season, after_a_day, "leaving it longer yields nothing more")
	assert_eq(FARM.action_for(plot, 400, false, 0), FARM.ACTION_HARVEST, "only a tap takes it")


func test_the_forge_does_not_prepay_or_catch_up() -> void:
	var forge := _forge()
	for _i in 10:
		forge.call("_physics_process", 0.1) # 1 s of a 2 s unit
	assert_eq(forge.commits, 0, "no unit before its time")
	forge.call("_physics_process", 30.0) # a long gap (menu, alt-tab, away)
	assert_eq(forge.commits, 0, "a gap never pays out the missed units")
	assert_false(bool(forge.get("_running")), "the gap stops the channel instead")
	forge.free()


func test_the_forge_stops_when_the_player_leaves() -> void:
	var forge := _forge()
	forge.present = false
	for _i in 100:
		forge.call("_physics_process", 0.1)
	assert_eq(forge.commits, 0)
	assert_false(bool(forge.get("_running")), "walking away ends the channel")
	forge.free()


func test_no_homestead_config_declares_passive_production() -> void:
	# Explicit guardrails ("automatic_harvest": false) are welcome; any
	# automation-named field must be off.
	var banned := RegEx.create_from_string("(?i)(automatic|auto_harvest|auto_craft|offline|idle_yield|passive_yield|per_hour|production_rate|conveyor|hopper)")
	for path: String in ["res://data/config/stations.json", "res://data/items/buildables.json",
			"res://data/config/farm.json", "res://data/config/forward_camps.json"]:
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_true(data != null, path + " parses")
		var on: Array[String] = []
		_collect_on(data, banned, path, on)
		assert_true(on.is_empty(), "automation fields are off: %s" % str(on))


func _collect_on(value: Variant, banned: RegEx, at: String, out: Array[String]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			var child: Variant = value[key]
			if not str(key).begins_with("_") and banned.search(str(key)) != null \
					and not (child is bool and child == false) and not ((child is float or child is int) and float(child) == 0.0):
				out.append("%s.%s=%s" % [at, key, str(child)])
			_collect_on(child, banned, "%s.%s" % [at, key], out)
	elif value is Array:
		for item: Variant in value:
			_collect_on(item, banned, at + "[]", out)
