extends "res://tests/test_case.gd"

const RELICS := preload("res://autoload/realm_heart_state.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const COMBAT := preload("res://scripts/combat/combat_manager.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")


class GameAdapter extends Node:
	var realm_hearts: RefCounted = RELICS.new()
	var progression: RefCounted = FLAGS.new()


class Manager extends "res://scripts/combat/combat_manager.gd":
	func _ready() -> void:
		set_physics_process(false)
		_moves = MOVE_DB.new()


class CardDirector extends "res://scripts/combat/encounter_director.gd":
	var announcements: Array[Dictionary] = []

	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

	func _announce_deployment(creature: RefCounted) -> void:
		announcements.append(_creature_card(creature))


func test_host_ignores_numbers_and_requires_a_placed_known_cooldown_relic() -> void:
	var hearts := RELICS.new()
	var flags := FLAGS.new()
	var claimed := {"active_relic_id": "stormwood", "cooldown_multiplier": 0.01}
	assert_almost_eq(DIRECTOR.validate_card_cooldown_multiplier(claimed, hearts, flags),
		1.0, 0.0001, "an unplaced Spark claim grants nothing")
	flags.set_flag(hearts.earned_flag("stormwood"))
	assert_true(hearts.place("stormwood", flags))
	assert_almost_eq(DIRECTOR.validate_card_cooldown_multiplier(claimed, hearts, flags),
		0.75, 0.0001, "the host reads 0.75 from its own placed Spark definition")
	assert_almost_eq(DIRECTOR.validate_card_cooldown_multiplier(
		{"cooldown_multiplier": 0.01}, hearts, flags), 1.0, 0.0001,
		"a raw multiplier without a relic identity is ignored")
	assert_almost_eq(DIRECTOR.validate_card_cooldown_multiplier(
		{"active_relic_id": "invented", "cooldown_multiplier": 0.01}, hearts, flags),
		1.0, 0.0001, "an unknown relic is ignored")
	flags.set_flag(hearts.earned_flag("cloudreach"))
	assert_true(hearts.place("cloudreach", flags))
	assert_almost_eq(DIRECTOR.validate_card_cooldown_multiplier(
		{"active_relic_id": "cloudreach"}, hearts, flags), 1.0, 0.0001,
		"Skyborne cannot manufacture a combat cooldown power")


func test_profile_multiplier_shortens_only_cooldown_and_is_clamped() -> void:
	var profile := {"cooldown": 1.2, "windup": 0.55, "recovery": 0.5, "range": 4.0}
	var livewire := COMBAT.with_cooldown_multiplier(profile, 0.75)
	assert_almost_eq(float(livewire.cooldown), 0.9, 0.0001)
	assert_almost_eq(float(livewire.windup), 0.55, 0.0001)
	assert_almost_eq(float(livewire.recovery), 0.5, 0.0001)
	assert_almost_eq(float(profile.cooldown), 1.2, 0.0001,
		"resolving a relic never mutates shared move config")
	assert_almost_eq(float(COMBAT.with_cooldown_multiplier(profile, 5.0).cooldown),
		1.2, 0.0001, "a relic cannot lengthen a move cooldown")
	assert_almost_eq(float(COMBAT.with_cooldown_multiplier(profile, 0.0).cooldown),
		0.12, 0.0001, "even host config is clamped away from a zero timer")
	var moves := MOVE_DB.new()
	var host_default := COMBAT.host_move_profile(moves, "player_charged", "arc_lash",
		0.5, 0.5)
	var host_livewire := COMBAT.host_move_profile(moves, "player_charged", "arc_lash",
		0.5, 0.5, 0.75)
	assert_almost_eq(float(host_default.cooldown), 1.2, 0.0001,
		"the host starts from its own authored charged cooldown")
	assert_almost_eq(float(host_livewire.cooldown), 0.9, 0.0001,
		"the host applies validated Livewire to its own rebuilt profile")


func _run_initialized_cases() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var old_game := tree.root.get_node_or_null("Game")
	if old_game != null:
		old_game.name = "OriginalGame"
	var game := GameAdapter.new()
	game.name = "Game"
	tree.root.add_child(game)

	for id in ["meadows", "cloudreach", "stormwood", "water"]:
		game.progression.set_flag(game.realm_hearts.earned_flag(id))
		assert_true(game.realm_hearts.place(id, game.progression))

	var manager := Manager.new()
	game.add_child(manager)
	var ordinary: Dictionary = manager.call("_move_profile", "player_charged", "stone_rush")
	assert_almost_eq(float(ordinary.cooldown), 1.2, 0.0001,
		"solo combat keeps the authored cooldown with no active relic")
	assert_true(game.realm_hearts.activate("stormwood", game.progression))
	var solo_livewire: Dictionary = manager.call("_move_profile", "player_charged", "stone_rush")
	assert_almost_eq(float(solo_livewire.cooldown), 0.9, 0.0001,
		"the real solo move profile applies Livewire")
	assert_true(game.realm_hearts.activate("meadows", game.progression))
	var meadowstride: Dictionary = manager.call("_move_profile", "player_charged", "stone_rush")
	assert_almost_eq(float(meadowstride.cooldown), 1.2, 0.0001,
		"swapping to Meadowstride removes Livewire instead of stacking")

	var director := CardDirector.new()
	game.add_child(director)
	var creature := CREATURE.from_species("terrapup", {
		"base_hp": 120.0, "base_attack": 22.0, "base_defence": 20.0,
		"type": "ground", "moves": {"quick": "pebble_toss", "charged": "stone_rush"},
	})
	var body := Node3D.new()
	game.add_child(body)
	director.set("_ally", creature)
	director.set("_ally_body", body)
	director.call("_sync_active_relic_card")
	assert_eq(str(director.announcements[-1].active_relic_id), "meadows")
	assert_false(director.announcements[-1].has("cooldown_multiplier"),
		"the deploy contract carries no client-authored multiplier")
	assert_true(game.realm_hearts.activate("stormwood", game.progression))
	director.call("_sync_active_relic_card")
	assert_eq(str(director.announcements[-1].active_relic_id), "stormwood",
		"a shrine swap refreshes the card while the same body stays deployed")
	assert_almost_eq(director.host_card_cooldown_multiplier(director.announcements[-1]),
		0.75, 0.0001, "the host resolves that refreshed identity to Livewire")
	var announced_count := director.announcements.size()
	director.call("_sync_active_relic_card")
	assert_eq(director.announcements.size(), announced_count,
		"an unchanged relic revision does not flood reliable deployment announcements")

	game.free()
	if old_game != null:
		old_game.name = "Game"


func test_solo_profile_and_deployed_card_refresh_in_initialized_tree() -> void:
	var path := "user://livewire-cooldown-child.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null)
	if file == null:
		return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_livewire_cooldowns.gd").new()\n\ttest._run_initialized_cases()\n\tprint("LIVEWIRE_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count >= 14 else 1)\n')
	file.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file",
		ProjectSettings.globalize_path("user://livewire-cooldown-child.log")], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("LIVEWIRE_RESULT="):
			result = JSON.parse_string(line.trim_prefix("LIVEWIRE_RESULT="))
	assert_true(int(result.get("assertions", 0)) >= 14, combined)
	assert_eq(result.get("failures", ["missing result"]), [])
