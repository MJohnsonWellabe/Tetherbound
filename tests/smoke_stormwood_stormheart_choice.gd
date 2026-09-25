extends SceneTree

## Client-side Stormheart answer through the real dialogue panel. The real
## `stormwood_ending.gd` receives this character's claim, plays the offer and
## reads the panel's own signals: Yes with room on the belt, No through the
## panel's real menu_cancel input, and conversations closed before and on the
## Yes/No line (neither is an answer). Hub/chapter/Dynamo are stubs;
## the host settle intent is not observed here (the participants smoke covers
## the host side).
const ENDING := preload("res://scripts/world/stormwood_ending.gd")
const PANEL := preload("res://scenes/ui/dialogue_panel.tscn")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const CAPTURE_CODEC := preload("res://scripts/save/water_capture_codec.gd")
const CHARACTER := "character-choice-a"

var failures: Array[String] = []
var assertions := 0


class FixtureWorld extends Node3D:
	var simulation_only := false

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0

	func entry_anchor(_id: String) -> Dictionary:
		return {}


class HubStub extends Node:
	func send_to(_peer: int, _event: Dictionary) -> void:
		pass

	func actor_for(_peer: int) -> Node3D:
		return null


class ChapterStub extends Node:
	func emit_event(_event: String) -> Dictionary:
		return {"accepted": false}


class DynamoStub extends Node:
	var participants: Array[int] = []
	var contributors: Array[int] = []
	var fighter_characters: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	_check(game != null, "Game autoload is available")
	if game == null:
		_finish()
		return
	game.reset_for_new_game()
	game.current_realm = "stormwood"
	game.local.set("character_id", CHARACTER)
	var conversations: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/stormwood.json")) as Dictionary).conversations
	for id: String in conversations:
		RUNNER.table()[id] = (conversations[id] as Dictionary).duplicate(true)

	var world := FixtureWorld.new()
	world.name = "StormheartChoiceFixture"
	root.add_child(world)
	var panel := PANEL.instantiate()
	panel.name = "DialoguePanel"
	world.add_child(panel)
	for node_name: String in ["StormwoodEncounterHub", "StormwoodChapter", "StormwoodDynamo"]:
		var stub: Node = {"StormwoodEncounterHub": HubStub, "StormwoodChapter": ChapterStub,
			"StormwoodDynamo": DynamoStub}[node_name].new()
		stub.name = node_name
		world.add_child(stub)
	var ending := ENDING.new()
	ending.name = "StormwoodEnding"
	world.add_child(ending)
	ending.mount(world)
	await process_frame

	# Yes with room on the belt: the Stormheart joins and the answer is recorded.
	_check(not game.party.is_full(), "the fixture belt has room")
	await _offer(ending, panel, game)
	await _to_question(panel)
	panel.runner().advance()
	await _frames(3)
	_check(_holds_stormheart(game), "Yes with room: the Stormheart joins this character's belt")
	_check(_receipt(game), "Yes records this character's personal receipt")
	_check(panel.drain_effects().is_empty(),
		"the Yes effect was consumed by the ending, not left queued on the panel")

	# No: nothing joins, and the refusal is still this character's answer.
	_reset_character(game)
	await _offer(ending, panel, game)
	await _to_question(panel)
	await _press_decline()
	await _frames(3)
	_check(not _holds_stormheart(game), "No: the Stormheart stays free")
	_check(_receipt(game), "No records this character's personal receipt as an answer")
	_check(game.pending_catch == null, "No opens no release ceremony")

	# Closed before the question: nothing is answered and the offer returns.
	_reset_character(game)
	await _offer(ending, panel, game)
	_check(panel.is_open(), "the offer conversation opens")
	panel.close()
	await _frames(3)
	_check(not _receipt(game) and not _holds_stormheart(game),
		"a conversation closed before its Yes/No line answers nothing")
	_check(panel.is_open() and panel.runner().conversation_id() == ENDING.OFFER_CONVERSATION,
		"the unanswered offer is asked again")

	# Closed ON the Yes/No line without an answer (a cutscene, a teardown):
	# still no refusal, and the offer returns.
	await _to_question(panel)
	_check(bool(panel.runner().line().get("confirmation", false)), "the re-asked offer reaches its Yes/No line")
	panel.close()
	await _frames(3)
	_check(not _receipt(game) and not _holds_stormheart(game),
		"a close on the Yes/No line without an explicit No is not a refusal")
	_check(panel.is_open() and panel.runner().conversation_id() == ENDING.OFFER_CONVERSATION,
		"the offer interrupted on its Yes/No line is asked again")

	# And the decline is still available after that interruption.
	await _to_question(panel)
	await _press_decline()
	await _frames(3)
	_check(_receipt(game) and not _holds_stormheart(game),
		"an explicit No after an interruption records this character's refusal")
	_check(panel.drain_effects().is_empty(), "a No queues no accept effect")
	panel.close()
	world.queue_free()
	await _frames(2)
	_finish()


func _offer(ending: Node, panel: Node, game: Node) -> void:
	var creature: RefCounted = ending.call("_make_legendary")
	ending.receive({"kind": "ending_offer", "claim": {
		"recipient_character_id": CHARACTER, "creature": CAPTURE_CODEC.encode(creature),
		"settled": false, "kept": false}})
	await _frames(2)
	_check(panel.is_open(), "the claim opens the Stormheart's offer")


## The panel's real decline: a menu_cancel press through Input, read by the
## panel's own `_physics_process` on the next physics tick.
func _press_decline() -> void:
	var press := InputEventAction.new()
	press.action = "menu_cancel"
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await physics_frame
	await physics_frame
	var release := InputEventAction.new()
	release.action = "menu_cancel"
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await physics_frame


func _to_question(panel: Node) -> void:
	var runner: RefCounted = panel.runner()
	for _i in 8:
		if bool(runner.line().get("confirmation", false)):
			return
		runner.advance()
		await process_frame
	_check(false, "the offer reaches its Yes/No line")


func _reset_character(game: Node) -> void:
	var party: RefCounted = game.party
	for i in range(party.size() - 1, -1, -1):
		if str(party.at(i).get("species_id")) == ENDING.LEGENDARY_SPECIES:
			party.remove_at(i)
	game.player_flags().set_flag(ENDING.PERSONAL_RECEIPT_FLAG, false)
	game.pending_catch = null


func _holds_stormheart(game: Node) -> bool:
	for creature: RefCounted in game.party.members():
		if str(creature.get("species_id")) == ENDING.LEGENDARY_SPECIES:
			return true
	return false


func _receipt(game: Node) -> bool:
	return bool(game.player_flags().has(ENDING.PERSONAL_RECEIPT_FLAG))


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _finish() -> void:
	for failure: String in failures:
		push_error("FAIL: " + failure)
	print("STORMWOOD STORMHEART CHOICE %s: %d assertions, %d failures" % [
		"OK" if failures.is_empty() else "FAILED", assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
