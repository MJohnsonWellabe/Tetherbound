extends SceneTree

## Client-side Stormheart answer through the real dialogue panel. The real
## `stormwood_ending.gd` receives this character's claim, plays the offer and
## reads the panel's own signals: Yes with room on the belt, No through the
## panel's real menu_cancel input (delivered to the ending as the panel's
## `declined` signal), and conversations closed before and on the Yes/No line
## (neither is an answer). It also covers the portable acceptance (only a Yes
## that keeps the Stormheart marks it) and answers scoped to one world's
## claim, across two separately mounted worlds with different world ids and
## different reserved Stormhearts: an unanswered offer in world B survives a
## refusal in world A, and world A's own unacknowledged answer resumes there.
## Hub/chapter/Dynamo are stubs; the hub stub only records intents, so the
## host never acknowledges a settle here (the participants smoke covers the
## host side).
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
	var intents: Array = []

	func send_to(_peer: int, _event: Dictionary) -> void:
		pass

	## Reached through Session's real offline-host dispatch; recorded only.
	func dispatch(_peer: int, intent: Dictionary) -> void:
		intents.append(intent.duplicate(true))

	func claims() -> Array:
		return intents.filter(func(intent: Dictionary) -> bool:
			return str(intent.get("kind", "")) == "ending_claim")

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
		if stub is HubStub:
			stub.add_to_group("stormwood_encounter_hub")
	var hub: HubStub = world.get_node("StormwoodEncounterHub")
	var ending := ENDING.new()
	ending.name = "StormwoodEnding"
	world.add_child(ending)
	ending.mount(world)
	var declines: Array[String] = []
	panel.declined.connect(func(id: String) -> void: declines.append(id))
	await process_frame

	# Yes with room on the belt: the Stormheart joins and the answer is recorded.
	_check(not game.party.is_full(), "the fixture belt has room")
	await _offer(ending, panel, game)
	await _to_question(panel)
	panel.runner().advance()
	await _frames(3)
	_check(_holds_stormheart(game), "Yes with room: the Stormheart joins this character's belt")
	_check(_receipt(game), "Yes records this character's personal receipt")
	_check(_accepted(game), "a Yes that joins marks this character's portable acceptance")
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
	_check(declines == [ENDING.OFFER_CONVERSATION], "the real menu_cancel press reached the ending as the panel's declined signal")
	_check(not _accepted(game), "a refusal is not an acceptance")

	# A refusal sends no withholding hint when this character asks elsewhere,
	# and the ceremony receipt is never cleared.
	hub.intents.clear()
	ending.call("_on_offer")
	var asked := hub.claims()
	_check(asked.size() == 1 and asked.back().get("already_accepted") == false and not asked.back().has("already_resolved"),
		"refused: the next claim carries no withholding hint")
	_check(_receipt(game), "asking again never clears the ceremony receipt")

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

	# Yes while another catch ceremony still holds the belt: the Stormheart
	# waits for it instead of stalling, then joins once it is resolved.
	_reset_character(game)
	await _offer(ending, panel, game)
	await _to_question(panel)
	var other_catch: RefCounted = ending.call("_make_legendary")
	other_catch.set("species_id", "stand_in_wild_catch")
	game.pending_catch = other_catch
	panel.runner().advance()
	await _frames(3)
	_check(not _holds_stormheart(game) and bool(ending.get("_ceremony_waiting")),
		"a Yes during another catch ceremony waits for that ceremony")
	# The other ceremony ends (its own release/keep choice) and its menu closes.
	game.pending_catch = null
	var menu: Node = game.get("_menu")
	if menu != null and bool(menu.call("is_open")):
		menu.call("close")
	paused = false
	await _frames(3)
	_check(_holds_stormheart(game) and _receipt(game),
		"the Stormheart joins as soon as the other ceremony ends")
	_check(_accepted(game), "the Stormheart kept after a waited ceremony is an acceptance")
	# Accepted here, then this character asks in another world: the hint
	# withholds a second creature there.
	hub.intents.clear()
	ending.call("_on_offer")
	asked = hub.claims()
	_check(asked.size() == 1 and asked.back().get("already_accepted") == true,
		"accepted in world A: the claim in world B says so, and the host withholds a second creature")
	panel.close()
	world.queue_free()
	await _frames(2)
	await _two_worlds(game)
	_finish()


## Two genuinely different worlds, each with its own mounted ending, panel and
## world id, and each host holding its own reserved Stormheart for this
## character. No settle reaches either host (the hub stub records it only).
func _two_worlds(game: Node) -> void:
	_reset_character(game)
	var claim_a := _claim()
	var claim_b := _claim()
	_check(ENDING.claim_id(claim_a) != ENDING.claim_id(claim_b) and not ENDING.claim_id(claim_a).is_empty(),
		"each world's claim carries its own Stormheart uid")
	# World B: the offer opens, and this character disconnects unanswered.
	var b := await _mount(game, "stormwood-world-b")
	b.ending.receive({"kind": "ending_offer", "claim": claim_b})
	await _frames(2)
	_check(b.panel.is_open(), "world B's offer opens")
	await _unmount(b)
	# World A: this character refuses. Its host never hears it.
	var a := await _mount(game, "stormwood-world-a")
	a.ending.receive({"kind": "ending_offer", "claim": claim_a})
	await _frames(2)
	await _to_question(a.panel)
	await _press_decline()
	await _frames(3)
	_check(_receipt(game) and not _holds_stormheart(game), "world A's No is answered")
	_check((a.hub as HubStub).intents.filter(func(intent: Dictionary) -> bool:
		return str(intent.kind) == "ending_settled" and intent.kept == false).size() == 1,
		"world A's refusal is sent to its host")
	await _unmount(a)
	# Back in world B: its host resends B's unsettled claim.
	b = await _mount(game, "stormwood-world-b")
	(b.hub as HubStub).intents.clear()
	b.ending.receive({"kind": "ending_offer", "claim": claim_b})
	await _frames(2)
	_check(b.panel.is_open() and b.panel.runner().conversation_id() == ENDING.OFFER_CONVERSATION,
		"a refusal in world A does not auto-refuse world B's unanswered offer: it is asked")
	_check((b.hub as HubStub).intents.filter(func(intent: Dictionary) -> bool:
		return str(intent.kind) == "ending_settled").is_empty(), "nothing was settled in world B for it")
	await _to_question(b.panel)
	b.panel.runner().advance()
	await _frames(3)
	_check(_holds_stormheart(game) and _accepted(game), "world B's own Yes keeps world B's Stormheart")
	await _unmount(b)
	# World A again: its host still holds the claim it never heard answered.
	# This character's saved answer to THAT claim resumes it without asking.
	a = await _mount(game, "stormwood-world-a")
	(a.hub as HubStub).intents.clear()
	a.ending.receive({"kind": "ending_offer", "claim": claim_a})
	await _frames(2)
	var settled: Array = (a.hub as HubStub).intents.filter(func(intent: Dictionary) -> bool:
		return str(intent.kind) == "ending_settled")
	_check(not a.panel.is_open() and settled.size() == 1 and settled[0].kept == false,
		"world A's own unacknowledged refusal resumes as a refusal, without asking again")
	await _unmount(a)


func _claim() -> Dictionary:
	var maker := ENDING.new()
	var creature: RefCounted = maker.call("_make_legendary")
	maker.free()
	return {"recipient_character_id": CHARACTER, "creature": CAPTURE_CODEC.encode(creature),
		"settled": false, "kept": false}


func _mount(game: Node, world_id: String) -> Dictionary:
	game.world.set("world_id", world_id)
	var world := FixtureWorld.new()
	world.name = "StormheartWorld_%s" % world_id.replace("-", "_")
	root.add_child(world)
	var panel := PANEL.instantiate()
	panel.name = "DialoguePanel"
	world.add_child(panel)
	var hub := HubStub.new()
	hub.name = "StormwoodEncounterHub"
	world.add_child(hub)
	hub.add_to_group("stormwood_encounter_hub")
	for pair: Array in [["StormwoodChapter", ChapterStub], ["StormwoodDynamo", DynamoStub]]:
		var stub: Node = pair[1].new()
		stub.name = str(pair[0])
		world.add_child(stub)
	var ending := ENDING.new()
	ending.name = "StormwoodEnding"
	world.add_child(ending)
	ending.mount(world)
	await _frames(1)
	return {"world": world, "panel": panel, "hub": hub, "ending": ending}


func _unmount(mounted: Dictionary) -> void:
	(mounted.panel as Node).call("close")
	(mounted.world as Node).queue_free()
	await _frames(2)


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
	game.player_flags().set_flag(ENDING.ACCEPTED_FLAG, false)
	game.pending_catch = null


func _holds_stormheart(game: Node) -> bool:
	for creature: RefCounted in game.party.members():
		if str(creature.get("species_id")) == ENDING.LEGENDARY_SPECIES:
			return true
	return false


func _receipt(game: Node) -> bool:
	return bool(game.player_flags().has(ENDING.PERSONAL_RECEIPT_FLAG))


func _accepted(game: Node) -> bool:
	return bool(game.player_flags().has(ENDING.ACCEPTED_FLAG))


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
