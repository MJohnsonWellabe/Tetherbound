extends "res://tests/test_case.gd"

## X05 co-op parity: the host rolls a guest's incoming hits against the
## `defence` on that guest's deploy-time creature card. Solo applies the
## party's Best Creature survivability per hit (`combat_manager` passes
## `is_best` and the species ability to `effective_defence`), so the card has
## to carry the same number, and has to be re-announced when the title moves
## while the creature stays deployed.

const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


class GameAdapter extends Node:
	var party: RefCounted = PARTY.new()


class CardDirector extends "res://scripts/combat/encounter_director.gd":
	var announcements: Array[Dictionary] = []

	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

	func _announce_deployment(creature: RefCounted) -> void:
		super(creature)
		announcements.append(_creature_card(creature))


func _run_initialized_cases() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var old_game := tree.root.get_node_or_null("Game")
	if old_game != null:
		old_game.name = "OriginalGame"
	var game := GameAdapter.new()
	game.name = "Game"
	tree.root.add_child(game)

	var ability: Dictionary = SPECIES.best_creature_ability("terrapup")
	assert_eq(str(ability.kind), "survivability", "terrapup's authored Best Creature kind")
	var guard := CREATURE.from_species("terrapup", {
		"base_hp": 120.0, "base_attack": 22.0, "base_defence": 20.0,
		"type": "ground", "moves": {"quick": "pebble_toss", "charged": "stone_rush"},
	})
	var other := CREATURE.from_species("galewisp", {
		"base_hp": 100.0, "base_attack": 24.0, "base_defence": 16.0,
		"type": "air", "moves": {"quick": "pebble_toss", "charged": "stone_rush"},
	})
	assert_true(game.party.add(guard))
	assert_true(game.party.add(other))
	var cfg: Dictionary = PROGRESSION.config()
	var plain := float(guard.effective_defence(cfg))
	var solo_best := float(guard.effective_defence(cfg, true, ability))
	assert_true(solo_best > plain + 0.001, "the fixture's survivability is a real bonus")

	var director := CardDirector.new()
	game.add_child(director)
	var body := Node3D.new()
	game.add_child(body)
	director.set("_ally", guard)
	director.set("_ally_body", body)

	var card: Dictionary = director.call("_creature_card", guard)
	assert_almost_eq(float(card.defence), plain, 0.0001,
		"an undesignated creature's card carries plain effective defence")

	assert_true(game.party.set_best(0))
	card = director.call("_creature_card", guard)
	assert_almost_eq(float(card.defence), solo_best, 0.0001,
		"the Best Creature's card carries the same survivability solo applies per hit")
	var other_card: Dictionary = director.call("_creature_card", other)
	assert_almost_eq(float(other_card.defence), float(other.effective_defence(cfg)), 0.0001,
		"only the flagged creature gets the bonus")

	# Deployed while not best, then the title moves onto it: exactly one refresh.
	game.party.set_best(0)
	director.call("_announce_deployment", guard)
	var count := director.announcements.size()
	director.call("_sync_active_relic_card")
	assert_eq(director.announcements.size(), count, "no change, no re-announcement")
	assert_true(game.party.set_best(0))
	director.call("_sync_active_relic_card")
	assert_eq(director.announcements.size(), count + 1,
		"designating the deployed creature re-announces its card once")
	assert_almost_eq(float(director.announcements[-1].defence), solo_best, 0.0001,
		"and the refreshed card carries the survivability")
	director.call("_sync_active_relic_card")
	assert_eq(director.announcements.size(), count + 1, "the refresh does not repeat")
	game.party.set_best(0)
	director.call("_sync_active_relic_card")
	assert_eq(director.announcements.size(), count + 2, "clearing the title refreshes once more")
	assert_almost_eq(float(director.announcements[-1].defence), plain, 0.0001,
		"and drops the bonus")

	game.free()
	if old_game != null:
		old_game.name = "Game"


func test_card_defence_matches_solo_best_creature_survivability() -> void:
	var path := "user://card-best-survivability-child.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null)
	if file == null:
		return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_director_card_best_survivability.gd").new()\n\ttest._run_initialized_cases()\n\tprint("CARD_BEST_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count >= 15 else 1)\n')
	file.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file",
		ProjectSettings.globalize_path("user://card-best-survivability-child.log")], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("CARD_BEST_RESULT="):
			result = JSON.parse_string(line.trim_prefix("CARD_BEST_RESULT="))
	assert_true(int(result.get("assertions", 0)) >= 15, combined)
	assert_eq(result.get("failures", ["missing result"]), [])
