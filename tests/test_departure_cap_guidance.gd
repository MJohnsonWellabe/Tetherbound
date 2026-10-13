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
	assert_true(BREAK.departure_guidance(personal, "cloudreach").is_empty(), "no other departure is advised")
	game.free()
