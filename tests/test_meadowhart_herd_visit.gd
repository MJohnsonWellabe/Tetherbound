extends "res://tests/test_case.gd"

const VISIT := preload("res://scripts/world/meadowhart_herd_visit.gd")
const GAME := preload("res://autoload/game_state.gd")

var _games: Array[Node] = []


func after_each() -> void:
	for game: Node in _games:
		game.free()
	_games.clear()


func _game_with_party(count: int = 3) -> Node:
	var game := GAME.new()
	game.reset_for_new_game()
	_games.append(game)
	for species_id: String in ["terrapup", "bramblebun", "meadowhart"].slice(0, count):
		assert_true(bool(game.party.add(game.make_creature(species_id))))
	return game


func test_visit_resolves_the_existing_herd_instead_of_copying_its_position() -> void:
	var activity: Dictionary = VISIT.definition()
	var herd: Dictionary = VISIT.herd_spawn(activity)
	assert_false(activity.is_empty(), "the herd Local Request is missing")
	assert_eq(int((activity.get("visit", {}) as Dictionary).get("spawn_order", -1)), 1005)
	assert_eq(int(herd.get("order", -1)), 1005)
	assert_eq(str(herd.get("species", "")), "meadowhart")
	assert_eq(int(herd.get("count", 0)), 2)
	assert_eq((herd.get("centre", []) as Array).size(), 3)
	assert_false((activity.get("visit", {}) as Dictionary).has("position"),
		"the objective copied a coordinate that will drift from spawn order 1005")


func test_visit_keeps_the_authored_personal_reward_and_tunable_radius() -> void:
	var activity: Dictionary = VISIT.definition()
	var visit: Dictionary = activity.get("visit", {}) as Dictionary
	assert_eq(str(activity.get("scope", "")), "player")
	assert_eq(str(activity.get("flag_id", "")), "band1_meadowhart_herd_found")
	assert_eq(float(visit.get("radius_m", 0.0)), 12.0)
	assert_eq(str(visit.get("reward_item", "")), "orb_basic")
	assert_eq(int(visit.get("reward_count", 0)), 3)
	assert_eq(str(visit.get("reward_source", "")), "meadowhart_herd_visit")
	assert_eq(str(visit.get("landmark_id", "")), "meadowhart_grazing_ground")


func test_first_personal_discovery_credits_every_owned_member_once() -> void:
	var game := _game_with_party()
	var landmark_id := str((VISIT.definition().visit as Dictionary).landmark_id)
	assert_true(VISIT.discover_for_party(game, landmark_id))
	assert_true(game.map.is_landmark_discovered(landmark_id))
	for member: RefCounted in game.party.members():
		assert_eq(int(member.landmarks_visited_together), 1)
	assert_false(VISIT.discover_for_party(game, landmark_id), "repeat visits cannot double-credit bond")
	for member: RefCounted in game.party.members():
		assert_eq(int(member.landmarks_visited_together), 1)


func test_legacy_orb_completion_keeps_prompt_open_until_actual_landmark_visit() -> void:
	var game := _game_with_party(1)
	var visit: Dictionary = VISIT.definition().visit
	game.progression.set_flag("band1_meadowhart_herd_found")
	assert_true(VISIT.visit_pending(game, visit),
		"an old completion flag must not manufacture discovery or suppress the revisit")
	assert_eq(int(game.party.members()[0].landmarks_visited_together), 0,
		"loading or setting the old completion fact cannot grant bond progress")
	assert_true(VISIT.discover_for_party(game, str(visit.landmark_id)))
	assert_false(VISIT.visit_pending(game, visit))


func test_raes_greeting_reveals_but_cannot_complete_or_pay() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/bands/band1_lower_meadows.json"))
	assert_true(parsed is Dictionary)
	var conversation: Dictionary = (parsed as Dictionary).get("conversations", {}).get(
		"meadowhart_herd_sighting", {})
	var effects: Array[String] = []
	for raw: Variant in conversation.get("lines", []):
		if not raw is Dictionary:
			continue
		var line := raw as Dictionary
		if line.has("effect"):
			effects.append(str(line.effect))
		for effect: Variant in line.get("effects", []):
			effects.append(str(effect))
	assert_true(effects.has("flag:band1_meadowhart_herd_met"))
	assert_false(effects.has("flag:band1_meadowhart_herd_found"))
	assert_false(effects.has("give:orb_basic:3"))
