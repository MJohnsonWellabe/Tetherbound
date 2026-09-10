extends SceneTree

## Isolated production-wiring smoke. Trainer outcomes are scripted at the
## encounter hub's post-battle callback; no combat result is fabricated inside
## chapter logic, and every fact still travels through Game.ledger.

const GAME := preload("res://autoload/game_state.gd")
const EVENTS := preload("res://scripts/world/realm_chapter_events.gd")
const CHAPTER := preload("res://scripts/world/stormwood_chapter.gd")
const HUB := preload("res://scripts/world/stormwood_encounter_hub.gd")
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
var failures: Array[String] = []
var fixture_world: Node3D
var fixture_hub: Node


class FixtureWorld extends Node3D:
	func world_realm() -> String:
		return "stormwood"


class DirectorStub extends Node:
	var authored_specs := {}

	func award_hosted_trainer(spec: Dictionary, _contributors: Array) -> void:
		get_node("/root/Game").ledger.submit({"kind": "set_world_flag", "realm": "stormwood",
			"id": str(spec.defeat_flag), "value": true})


class FightStub extends Node:
	var spec: Dictionary
	var contributors: Array = [1]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.reset_for_new_game()
	game.current_realm = "stormwood"
	_commit(game, "stormwood:lantern_hollow_reached")
	var world := FixtureWorld.new()
	fixture_world = world
	world.name = "CircuitFixture"
	root.add_child(world)
	var director := DirectorStub.new()
	director.name = "EncounterDirector"
	world.add_child(director)
	for spec: Dictionary in CATALOGUE.trainer_specs():
		director.authored_specs[str(spec.id)] = spec
	var chapter := CHAPTER.new()
	chapter.name = "StormwoodChapter"
	world.add_child(chapter)
	chapter.world = world
	chapter.chapter = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_chapter.json")) as Dictionary
	var events := EVENTS.new()
	events.realm_id = "stormwood"
	events.chapter = chapter.chapter
	chapter.add_child(events)
	chapter.events = events
	await process_frame
	var specs: Array[Dictionary] = []
	for spec: Dictionary in director.authored_specs.values():
		if str(spec.group) == "deepwood_circuit":
			specs.append(spec)
	_expect(specs.size() == 5, "production catalogue exposes all five circuit members")
	if specs.size() != 5:
		_finish()
		return
	# Two victories happened before Rook's offer. They are real trainer defeat
	# facts, but cannot advance the unrevealed middle step on their own.
	_commit(game, str(specs[0].defeat_flag))
	_commit(game, str(specs[1].defeat_flag))
	_expect(not game.progression.has("stormwood:side_deepwood_circuit_1"),
		"opening or leaving Rook's offer unfinished grants no acceptance")
	chapter.call("_dialogue_finished", "stormwood_rook_circuit_offer")
	_expect(game.progression.has("stormwood:side_deepwood_circuit_1"), "Rook offer completion accepts the circuit")
	_expect(game.progression.has("stormwood:side_deepwood_circuit_win:%s" % specs[0].id)
		and game.progression.has("stormwood:side_deepwood_circuit_win:%s" % specs[1].id),
		"acceptance credits earlier authoritative trainer wins")
	var hub := HUB.new()
	fixture_hub = hub
	hub.world = world
	hub.director = director
	var unrelated := {"id": "not_a_circuit_trainer", "group": "picket_leader",
		"defeat_flag": "stormwood:trainer:not_a_circuit_trainer:defeated"}
	_script_win(hub, unrelated)
	_expect(not game.progression.has("stormwood:side_deepwood_circuit_2"), "unrelated trainer is ignored")
	_script_win(hub, specs[0])
	_expect(not game.progression.has("stormwood:side_deepwood_circuit_2"), "repeat circuit win cannot supply the third credit")
	_script_win(hub, specs[2])
	_expect(game.progression.has("stormwood:side_deepwood_circuit_2"), "actual trainer_finished callback supplies the distinct third credit")
	_expect(not game.progression.has("stormwood:side_deepwood_circuit_complete"), "three wins still require returning to Rook")
	chapter.call("_dialogue_finished", "stormwood_rook_circuit_return")
	_expect(game.progression.has("stormwood:side_deepwood_circuit_complete"), "Rook return completion acknowledges the circuit")
	_finish()


func _script_win(hub: Node, spec: Dictionary) -> void:
	var fight := FightStub.new()
	fight.spec = spec
	hub.call("trainer_finished", fight, true)
	fight.free()


func _commit(game: Node, id: String) -> void:
	game.ledger.submit({"kind": "set_world_flag", "realm": "stormwood", "id": id, "value": true})


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)


func _finish() -> void:
	if fixture_hub != null and is_instance_valid(fixture_hub):
		fixture_hub.free()
		fixture_hub = null
	if fixture_world != null and is_instance_valid(fixture_world):
		fixture_world.queue_free()
		fixture_world = null
	await process_frame
	await process_frame
	if failures.is_empty():
		print("STORMWOOD DEEPWOOD CIRCUIT WIRING OK: Rook -> any three distinct real trainer facts -> Rook")
		quit(0)
		return
	for failure: String in failures:
		push_error("STORMWOOD DEEPWOOD CIRCUIT WIRING: " + failure)
	quit(1)
