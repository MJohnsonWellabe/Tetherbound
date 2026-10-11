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
## Hub/chapter/Dynamo are fixture adapters. Normal answers reach the original
## mounted host producer and its durable ACK. The cross-world replay cases
## drop the actual settle at transport, retain its BOOL-saved personal answer,
## and reload the original reserved world claim and character from scratch disk.
const ENDING := preload("res://scripts/world/stormwood_ending.gd")
const PANEL := preload("res://scenes/ui/dialogue_panel.tscn")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const CAPTURE_CODEC := preload("res://scripts/save/water_capture_codec.gd")
const CHARACTER := "character-choice-a"
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_IDENTITY := preload("res://scripts/save/world_identity.gd")

var failures: Array[String] = []
var assertions := 0
var _character_baseline: Dictionary = {}
var _scratch := ""
var _saver: RefCounted


class FixtureWorld extends Node3D:
	var simulation_only := false

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0

	func entry_anchor(_id: String) -> Dictionary:
		return {}


class HubStub extends Node:
	var intents: Array = []
	var sent: Array[Dictionary] = []
	var ending: Node
	var actor: Node3D
	var drop_settles := false
	var queue_offers := false
	var offers: Array[Dictionary] = []

	func send_to(_peer: int, event: Dictionary) -> void:
		sent.append(event.duplicate(true))
		if queue_offers and event.get("kind") == "ending_offer":
			offers.append(event.duplicate(true))
			return
		if ending != null: ending.receive(event)

	## Deliver one original producer packet for this reconnect/resend input.
	## Snapshot and periodic retransmissions stay queued at transport.
	func deliver_offer(claim: Dictionary) -> bool:
		for i: int in offers.size():
			if ENDING.claim_id(offers[i].get("claim", {})) == ENDING.claim_id(claim):
				var event: Dictionary = offers.pop_at(i)
				ending.receive(event)
				return true
		return false

	## The drop happens at transport, after the original personal BOOL save.
	func dispatch(peer: int, intent: Dictionary) -> void:
		intents.append(intent.duplicate(true))
		if str(intent.get("kind", "")) == "ending_settled" and drop_settles: return
		if ending != null: ending.dispatch(peer, intent)

	func claims() -> Array:
		return intents.filter(func(intent: Dictionary) -> bool:
			return str(intent.get("kind", "")) == "ending_claim")

	func actor_for(_peer: int) -> Node3D:
		return actor


class ChapterStub extends Node:
	var game: Node
	var chapter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_chapter.json"))
	func emit_event(event: String) -> Dictionary:
		return preload("res://scripts/world/realm_chapter_progression.gd").dispatch(game.progression, chapter, event)


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
	var original_scene: Node = current_scene
	var original_saver: RefCounted = game.save_system
	var original_world: RefCounted = game.world
	var original_world_data: Dictionary = game.world.save_data().duplicate(true)
	var original_character: Dictionary = game.local.save_data().duplicate(true)
	var session: Node = game.session
	var original_process_mode: int = session.process_mode
	session.process_mode = Node.PROCESS_MODE_DISABLED
	game.reset_for_new_game()
	game.current_realm = "stormwood"
	game.local.set("character_id", CHARACTER)
	_character_baseline = game.local.save_data().duplicate(true)
	_scratch = "user://stormheart-choice-%d/" % Time.get_ticks_usec()
	_saver = SAVE_GAME.new(_scratch)
	game.save_system = _saver
	session.call("_owner_passive_service")
	_check(_saver.save_character_prepared(game, CHARACTER) == true, "the fixture's initial character is BOOL-saved in scratch")
	# Seed chapter entry only; the real chapter/ledger produces the offer fact.
	game.world.flags.set_flag("stormwood:act_ii_complete")
	game.world.flags.set_flag(ENDING.FREED_FLAG)
	var conversations: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/stormwood.json")) as Dictionary).conversations
	for id: String in conversations:
		RUNNER.table()[id] = (conversations[id] as Dictionary).duplicate(true)

	var world := FixtureWorld.new()
	world.name = "StormheartChoiceFixture"
	root.add_child(world)
	current_scene = world
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
		if stub is ChapterStub:
			(stub as ChapterStub).game = game
	var hub: HubStub = world.get_node("StormwoodEncounterHub")
	var ending := ENDING.new()
	ending.name = "StormwoodEnding"
	world.add_child(ending)
	hub.ending = ending
	var actor := Node3D.new()
	world.add_child(actor)
	hub.actor = actor
	(world.get_node("StormwoodDynamo") as DynamoStub).fighter_characters = [CHARACTER]
	ending.mount(world)
	actor.global_position = ending.get("_offer_prompt").global_position
	var declines: Array[String] = []
	panel.declined.connect(func(id: String) -> void: declines.append(id))
	await process_frame

	# Yes with room on the belt: the Stormheart joins and the answer is recorded.
	_check(not game.party.is_full(), "the fixture belt has room")
	await _offer(ending, panel, game)
	await _to_question(panel)
	panel.runner().advance()
	await _frames(3)
	_check_saved_ack(ending, hub, game)
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
	_check_saved_ack(ending, hub, game)
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
	_check_saved_ack(ending, hub, game)
	_check(_receipt(game) and not _holds_stormheart(game),
		"an explicit No after an interruption records this character's refusal")
	_check(panel.drain_effects().is_empty(), "a No queues no accept effect")

	# Yes while another catch ceremony still holds the belt: the Stormheart
	# waits for it instead of stalling, then joins once it is resolved.
	_reset_character(game)
	var keepers: Array[RefCounted] = []
	for i: int in 5:
		var keeper: RefCounted = game.make_creature("terrapup", "Keeper %d" % i)
		_check(keeper != null and game.party.add(keeper), "the ordinary ceremony starts with five real keepers")
		keepers.append(keeper)
	_check(_saver.save_character_prepared(game, CHARACTER) == true,
		"the full-five original character baseline is BOOL-saved before the host reserves its claim")
	await _offer(ending, panel, game)
	var keeper_uids: Array[String] = []
	for keeper: RefCounted in keepers: keeper_uids.append(str(keeper.get("uid")))
	_check((ending.get("_local_claim") as Dictionary).get("party_uids", []) == keeper_uids,
		"the original Stormheart claim reserves these five keepers before the other catch")
	await _to_question(panel)
	# A disclosed ordinary catch fixture, with its own authored loadout and UID.
	var other_catch: RefCounted = game.make_creature("terrapup", "Other catch fixture")
	_check(other_catch != null, "the registered ordinary pending catch is created")
	if other_catch == null:
		_finish()
		return
	var other_payload := CAPTURE_CODEC.encode(other_catch)
	_check(not other_payload.is_empty(),
		"the ordinary pending catch passes the production capture/loadout codec")
	var other_uid := str(other_catch.get("uid"))
	_check(preload("res://scripts/creatures/creature_instance.gd").valid_uid(other_uid)
		and str(other_payload.get("uid", "")) == other_uid
		and other_uid != ENDING.claim_id(ending.get("_local_claim") as Dictionary),
		"the ordinary pending catch has its own stable UID distinct from the Stormheart")
	game.pending_catch = other_catch
	panel.runner().advance()
	await _frames(3)
	_check(not _holds_stormheart(game) and bool(ending.get("_ceremony_waiting")),
		"a Yes during another catch ceremony waits for that ceremony")
	var menu: Node = game.get("_menu")
	var tab: Node
	for i: int in (menu.get("_tabs") as Array).size():
		if str((menu.get("_tabs")[i] as Dictionary).get("id", "")) == "creatures":
			tab = menu.get("_bodies")[i]
			break
	_check(tab != null and tab.get("_release_stage") == "choose" and game.pending_catch == other_catch,
		"the actual ordinary release menu owns its original pending catch")
	# Decline the ordinary newcomer through the real service; all five original
	# keepers still match the Stormheart producer's reserved party_uids.
	(tab.get("_pending_button") as Button).grab_focus()
	await _press_menu("ui_accept")
	await _press_menu("ui_down")
	await _press_menu("ui_accept")
	_check(game.pending_catch == null and game.party.members() == keepers
		and tab.get("_release_stage") == "done",
		"the ordinary newcomer refusal preserves the original five keepers")
	_check(bool(ending.get("_ceremony_waiting")) and not (ending.get("_local_claim") as Dictionary).is_empty(),
		"the Stormheart's original consent survives the prior catch's goodbye screen")
	await _press_menu("ui_accept") # End the ordinary goodbye, allowing handoff.
	_check(tab.get("_release_stage") == "choose" and game.pending_catch != null
		and str(game.pending_catch.get("uid")) == ENDING.claim_id(ending.get("_local_claim") as Dictionary),
		"the original Stormheart enters its own full-five ceremony after the ordinary goodbye")
	# The player gives up an original keeper using Stormheart's typed service.
	(tab.get("_rows")[0] as Button).grab_focus()
	await _press_menu("ui_accept")
	await _press_menu("ui_down")
	await _press_menu("ui_accept")
	await _frames(3)
	_check_saved_ack(ending, hub, game)
	_check(_holds_stormheart(game) and _receipt(game),
		"the Stormheart joins as soon as the other ceremony ends")
	_check(_accepted(game), "the Stormheart kept after a waited ceremony is an acceptance")
	_check(game.party.size() == 5 and not game.party.members().has(keepers[0])
		and tab.get("_release_stage") == "done",
		"the original keeper release seats only the reserved Stormheart in the full-five roster")
	await _press_menu("ui_accept")
	await _press_menu("menu_cancel")
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
	session.call("_teardown")
	await _two_worlds(game)
	session.call("_teardown")
	game.world = original_world
	game.world.load_data(original_world_data)
	game.local.load_data(original_character)
	game.save_system = original_saver
	game.session = session
	game.call("_ensure_containers")
	session.process_mode = original_process_mode
	current_scene = original_scene
	_remove_scratch(_scratch)
	_finish()


## Two genuinely different worlds, each with its own mounted ending, panel and
## world id, and each host holding its own reserved Stormheart for this
## character. No settle reaches either host (the hub stub records it only).
func _two_worlds(game: Node) -> void:
	_reset_character(game)
	var claim_a := await _claim(game, "stormwood-world-a")
	var claim_b := await _claim(game, "stormwood-world-b")
	_check(ENDING.claim_id(claim_a) != ENDING.claim_id(claim_b) and not ENDING.claim_id(claim_a).is_empty(),
		"each world's claim carries its own Stormheart uid")
	# World B: the offer opens, and this character disconnects unanswered.
	var b := await _mount(game, "stormwood-world-b")
	_check((b.hub as HubStub).deliver_offer(claim_b), "world B receives its original producer's reserved offer")
	await _frames(2)
	_check(b.panel.is_open(), "world B's offer opens")
	await _unmount(b)
	# World A: this character refuses. Its host never hears it.
	var a := await _mount(game, "stormwood-world-a")
	_check((a.hub as HubStub).deliver_offer(claim_a), "world A receives its original producer's reserved offer")
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
	_check((b.hub as HubStub).deliver_offer(claim_b), "world B receives its original producer's reserved resend")
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
	_check((a.hub as HubStub).deliver_offer(claim_a), "world A receives its original producer's reserved resend")
	await _frames(2)
	var settled: Array = (a.hub as HubStub).intents.filter(func(intent: Dictionary) -> bool:
		return str(intent.kind) == "ending_settled")
	_check(not a.panel.is_open() and settled.size() == 1 and settled[0].kept == false,
		"world A's own unacknowledged refusal resumes as a refusal, without asking again")
	await _unmount(a)

	# Unanswered in world D, then Yes in world C, then back to world D: D's
	# resent claim must not become a second Stormheart.
	_reset_character(game)
	var claim_c := await _claim(game, "stormwood-world-c")
	var claim_d := await _claim(game, "stormwood-world-d")
	var d := await _mount(game, "stormwood-world-d")
	_check((d.hub as HubStub).deliver_offer(claim_d), "world D receives its original producer's reserved offer")
	await _frames(2)
	_check(d.panel.is_open(), "world D's offer opens")
	await _unmount(d)
	var c := await _mount(game, "stormwood-world-c")
	_check((c.hub as HubStub).deliver_offer(claim_c), "world C receives its original producer's reserved offer")
	await _frames(2)
	await _to_question(c.panel)
	c.panel.runner().advance()
	await _frames(3)
	_check(_stormheart_count(game) == 1 and _accepted(game), "world C's Yes keeps one Stormheart")
	await _unmount(c)
	d = await _mount(game, "stormwood-world-d")
	(d.hub as HubStub).intents.clear()
	_check((d.hub as HubStub).deliver_offer(claim_d), "world D receives its original producer's reserved resend")
	await _frames(3)
	settled = (d.hub as HubStub).intents.filter(func(intent: Dictionary) -> bool:
		return str(intent.kind) == "ending_settled")
	_check(not d.panel.is_open() and _stormheart_count(game) == 1,
		"back in world D after a Yes in world C: no second Stormheart is offered")
	_check(settled.size() == 1 and settled[0].kept == false,
		"world D's unanswered claim settles as not kept")
	await _unmount(d)


func _claim(game: Node, world_id: String) -> Dictionary:
	var mounted := await _mount(game, world_id)
	mounted.ending.dispatch(1, {"kind": "ending_claim"})
	var claim: Dictionary = mounted.ending.call("_saved_state").get("claims", {}).get(CHARACTER, {}).duplicate(true)
	_check(not claim.is_empty() and claim.has("party_uids"), "the original mounted producer reserves its admitted roster claim")
	await _unmount(mounted)
	return claim


func _mount(game: Node, world_id: String) -> Dictionary:
	var state := WORLD_STATE.new()
	var saved: Dictionary = _saver.worlds().state(world_id)
	if not saved.is_empty():
		state.load_data(saved)
	else:
		state.world_id = world_id
		WORLD_IDENTITY.ensure(state)
		state.flags.set_flag("stormwood:act_ii_complete")
		state.flags.set_flag(ENDING.FREED_FLAG)
	game.world = state
	game.call("_ensure_containers")
	var world := FixtureWorld.new()
	world.name = "StormheartWorld_%s" % world_id.replace("-", "_")
	root.add_child(world)
	current_scene = world
	var panel := PANEL.instantiate()
	panel.name = "DialoguePanel"
	world.add_child(panel)
	var hub := HubStub.new()
	hub.drop_settles = true
	hub.queue_offers = true
	hub.name = "StormwoodEncounterHub"
	world.add_child(hub)
	hub.add_to_group("stormwood_encounter_hub")
	for pair: Array in [["StormwoodChapter", ChapterStub], ["StormwoodDynamo", DynamoStub]]:
		var stub: Node = pair[1].new()
		stub.name = str(pair[0])
		world.add_child(stub)
		if stub is DynamoStub: (stub as DynamoStub).fighter_characters.append(CHARACTER)
		if stub is ChapterStub: (stub as ChapterStub).game = game
	var ending := ENDING.new()
	ending.name = "StormwoodEnding"
	world.add_child(ending)
	hub.ending = ending
	var actor := Node3D.new()
	world.add_child(actor)
	hub.actor = actor
	ending.mount(world)
	actor.global_position = ending.get("_offer_prompt").global_position
	await _frames(1)
	return {"world": world, "panel": panel, "hub": hub, "ending": ending}


func _unmount(mounted: Dictionary) -> void:
	(mounted.panel as Node).call("close")
	(mounted.world as Node).queue_free()
	await _frames(2)
	# A disconnect drops the service's transient freeze, never the saved answer.
	var game: Node = root.get_node("Game")
	game.session.call("_teardown")
	_check(game.session.call("_restore_character_here", CHARACTER) == true,
		"teardown reloads the original BOOL-saved portable character")
	game.call("_ensure_containers")


func _offer(ending: Node, panel: Node, _game: Node) -> void:
	ending.dispatch(1, {"kind": "ending_claim"})
	await _frames(2)
	_check(panel.is_open(), "the claim opens the Stormheart's offer")


func _check_saved_ack(ending: Node, hub: HubStub, game: Node) -> void:
	var offered: Dictionary = {}
	var ack: Dictionary = {}
	for event: Dictionary in hub.sent:
		if event.get("kind") == "ending_offer": offered = event.get("claim", {})
		if event.get("kind") == "ending_answer_saved": ack = event
	var saved: Dictionary = _saver.worlds().state(str(game.world.world_id))
	var personal: Dictionary = _saver.characters().state(CHARACTER)
	var passive: RefCounted = game.session.get("_owner_passive")
	_check(not offered.is_empty() and ack.get("claim_uid") == ENDING.claim_id(offered)
		and passive != null and passive.get("stormwood_owner").is_empty()
		and (ending.get("_local_claim") as Dictionary).is_empty()
		and saved.get("realm_environment", {}).get("stormwood", {}).get("ending", {}).get("claims", {}).get(CHARACTER, {}).get("settled") == true
		and personal.get("redesign_character", {}).get("transaction_receipts", []).has(
			"stormheart_answer:%s:%s" % [ENDING.claim_id(offered), CHARACTER]),
		"the original BOOL-saved owner/world answer and matching durable ACK clean up before assertions")


## The same real menu input path as the existing release smoke: the GUI
## Buttons receive parsed events, and the menu polls the action state.
func _press_menu(action: String) -> void:
	Input.action_press(action)
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await process_frame
	await process_frame
	Input.action_release(action)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await _frames(4)


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
	var passive: RefCounted = game.session.get("_owner_passive")
	_check(passive == null or passive.get("stormwood_owner").is_empty(),
		"an independent case begins after original durable ACK cleanup or disconnect teardown")
	game.session.call("_teardown")
	game.local.load_data(_character_baseline)
	game.world.reset()
	game.world.world_id = "stormheart-choice-fixture"
	WORLD_IDENTITY.ensure(game.world)
	game.world.flags.set_flag("stormwood:act_ii_complete")
	game.world.flags.set_flag(ENDING.FREED_FLAG)
	game.call("_ensure_containers")
	_check(_saver.save_character_prepared(game, CHARACTER) == true,
		"an independent case BOOL-saves its original character baseline")


func _remove_scratch(path: String) -> void:
	var resolved := ProjectSettings.globalize_path(path).simplify_path().trim_suffix("/")
	var base := ProjectSettings.globalize_path(_scratch).simplify_path().trim_suffix("/")
	if _scratch.is_empty() or (resolved != base and not resolved.begins_with(base + "/")): return
	var directory := DirAccess.open(path)
	if directory == null: return
	for child: String in directory.get_directories(): _remove_scratch(path.path_join(child))
	for child: String in directory.get_files(): directory.remove(child)
	DirAccess.remove_absolute(path)


func _stormheart_count(game: Node) -> int:
	var count := 0
	for creature: RefCounted in game.party.members():
		if str(creature.get("species_id")) == ENDING.LEGENDARY_SPECIES:
			count += 1
	return count


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
