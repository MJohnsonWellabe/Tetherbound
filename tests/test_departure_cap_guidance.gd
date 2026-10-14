extends "res://tests/test_case.gd"

## Coordinator ruling 2026-10-11: after the Warden, a team still under cap 30
## is guided to the second Meadows Master before Tidewake. Advice only: the
## quest-log row and arch notice derive from state and never gate travel.
const QUEST := preload("res://scripts/world/quest_log.gd")
const ARCH := preload("res://scripts/world/portal_arch.gd")
const VIEW := preload("res://scripts/net/portal_view.gd")
const BREAK := preload("res://scripts/creatures/breakthrough.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const GAME := preload("res://autoload/game_state.gd")


func _tidewake_arch() -> Dictionary:
	for row: Dictionary in DATA.json("res://data/config/portals.json").arches:
		if row.biome == "tidewake": return row
	return {}


func test_a_finished_meadows_with_a_cap_20_team_tracks_the_master_before_the_departure() -> void:
	var game := GAME.new()
	game.reset_for_new_game()
	var personal: Dictionary = game.local.redesign_character
	personal.portal_unlocks = ["tidewake"]
	personal.creatures = {"a": {"cap_level": 20}, "b": {"cap_level": 20}}
	var progression: RefCounted = game.local.flags
	var log := QUEST.new(game)
	log.set_realm("meadows")
	for entry: Dictionary in log._main: progression.set_flag(str(entry.flag_id))
	assert_eq(log.tracked_id(progression), "departure_guidance:master_t2", "the Master step is tracked first")
	assert_true(log.tracked_text(progression).contains("cap to 30"))
	var beacon: Dictionary = log.tracked_beacon(progression)
	assert_eq(beacon.get("position"), Vector2(-405, 5050), "the beacon points at the Meadows Master")
	var arch := _tidewake_arch()
	var view := VIEW.build(game.local, game.world, arch)
	assert_eq(view.cap_advice, "Recommended: Master training, cap 30")
	view.ready = true
	view.open = true
	view.character_open = true
	assert_true(ARCH.prompt_text(arch, view).contains("Recommended: Master training, cap 30"))
	# One creature reaching cap 30 retires both; no flag is invented or needed.
	personal.creatures.b.cap_level = 30
	assert_eq(log.tracked_id(progression), "chapter_departure:" + str(arch.id), "departure follows once trained")
	assert_eq(VIEW.build(game.local, game.world, arch).cap_advice, "")
	# A cap-30 team is still below the next chapter's advice (13 Oct ruling).
	assert_eq(BREAK.departure_guidance(personal, "cloudreach").get("master_id"), "master_t3")
	game.free()


func test_each_later_departure_names_the_master_that_raises_its_cap() -> void:
	var personal := {"creatures": {"a": {"cap_level": 30}}}
	assert_eq(BREAK.departure_guidance(personal, "cloudreach").get("min_cap"), 40)
	assert_eq(BREAK.departure_guidance(personal, "cloudreach").get("master_id"), "master_t3")
	personal.creatures.a.cap_level = 40
	assert_true(BREAK.departure_guidance(personal, "cloudreach").is_empty())
	assert_eq(BREAK.departure_guidance(personal, "stormwood").get("master_id"), "master_t4")
	assert_eq(BREAK.departure_guidance(personal, "stormwood").get("arch_notice"), "Recommended: Master training, cap 50")
	personal.creatures.a.cap_level = 50
	assert_true(BREAK.departure_guidance(personal, "stormwood").is_empty())
	for row: Dictionary in BREAK.masters().departure_guidance:
		var master := BREAK.master(str(row.master_id))
		assert_eq(int(master.next_cap), int(row.min_cap), "%s raises the cap the %s row asks for" % [row.master_id, row.biome])


func test_rowan_is_signposted_in_stormwood_after_the_rootgate_until_deepwood() -> void:
	var game := GAME.new()
	game.reset_for_new_game()
	var personal: Dictionary = game.local.redesign_character
	personal.creatures = {"a": {"cap_level": 40}}
	var progression: RefCounted = game.local.flags
	var log := QUEST.new(game)
	log.set_realm("stormwood")
	assert_true(BREAK.chapter_guidance(personal, "stormwood", progression).is_empty(), "not before the Rootgate")
	progression.set_flag("stormwood:rootgate_released")
	assert_eq(log.tracked_id(progression), "chapter_guidance:master_t5", "the Master step is tracked first")
	assert_true(log.tracked_text(progression).contains("cap to 60"))
	assert_eq(log.tracked_beacon(progression).get("position"), Vector2(-1110, 3000), "the beacon points at Rowan")
	personal.creatures.a.cap_level = 60
	assert_ne(log.tracked_id(progression), "chapter_guidance:master_t5", "a trained team drops the advice")
	personal.creatures.a.cap_level = 40
	progression.set_flag("stormwood:deepwood_station_disabled")
	assert_true(BREAK.chapter_guidance(personal, "stormwood", progression).is_empty(), "not after Deepwood")
	game.free()
