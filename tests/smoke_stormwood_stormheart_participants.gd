extends SceneTree

## Host-authority fixture for the per-participant Stormheart offer. The real
## `stormwood_ending.gd` runs against the offline host Session with two extra
## registered characters; a hub stub records what each peer is sent, a chapter
## stub commits the two chapter events it would dispatch, and a Dynamo stub
## supplies the fight's participant peers. It also covers the host refusing
## from its own answer receipt against a client's flag, the portable
## acceptance hint (an acceptance elsewhere withholds, a refusal does not), and
## a legacy save freed before participants were recorded: the Dynamo's own
## record, else only the host, never whoever claims first. It does not play the
## fight, the dialogue or the five-slot ceremony UI.
const ENDING := preload("res://scripts/world/stormwood_ending.gd")

var failures: Array[String] = []
var assertions := 0


class FixtureWorld extends Node3D:
	var simulation_only := true

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0

	func entry_anchor(_id: String) -> Dictionary:
		return {}


class HubStub extends Node:
	var sent: Array = []
	var actors: Dictionary = {}

	func send_to(peer: int, event: Dictionary) -> void:
		sent.append({"peer": peer, "event": event.duplicate(true)})

	func actor_for(peer: int) -> Node3D:
		return actors.get(peer, null)

	func offers_for(peer: int) -> Array:
		return sent.filter(func(row: Dictionary) -> bool:
			return int(row.peer) == peer and str(row.event.kind) == "ending_offer")

	func refusals_for(peer: int) -> Array:
		return sent.filter(func(row: Dictionary) -> bool:
			return int(row.peer) == peer and str(row.event.kind) == "ending_refused")


class ChapterStub extends Node:
	var game: Node

	func emit_event(event: String) -> Dictionary:
		var flag: String = {"dynamo:release": "stormwood:legendary_freed",
			"legendary:offer_shown": "stormwood:legendary_offer_made"}.get(event, "")
		if flag == "" or game.progression.has(flag):
			return {"accepted": false}
		game.progression.set_flag(flag)
		return {"accepted": true}


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
	var session: Node = game.get_node("Session")
	var local_peer := int(session.local_peer_id())
	# A headless new game has no stable character id yet; give the host one.
	game.local.set("character_id", "character-host-a")
	var host_character := str(game.local.character_id)
	_check(host_character == "character-host-a", "the host character has a stable id")
	var registry: RefCounted = session.registry()
	registry.call("add", 2, "character-fought-b", "B")
	registry.call("add", 3, "character-watched-c", "C")
	for peer: int in [2, 3]:
		registry.call("set_realm", peer, "stormwood")

	var world := FixtureWorld.new()
	world.name = "StormheartFixture"
	root.add_child(world)
	var hub := HubStub.new()
	hub.name = "StormwoodEncounterHub"
	world.add_child(hub)
	var chapter := ChapterStub.new()
	chapter.name = "StormwoodChapter"
	chapter.game = game
	world.add_child(chapter)
	var dynamo := DynamoStub.new()
	dynamo.name = "StormwoodDynamo"
	dynamo.participants = [local_peer, 2]
	dynamo.contributors = [2]
	# D fought, then disconnected before the release: no registry row, but the
	# Dynamo captured D's stable character when D joined.
	dynamo.fighter_characters = ["character-host-a", "character-fought-b", "character-left-d"]
	world.add_child(dynamo)
	var ending := ENDING.new()
	ending.name = "StormwoodEnding"
	world.add_child(ending)
	ending.mount(world)
	for peer: int in [local_peer, 2, 3]:
		var actor := Node3D.new()
		world.add_child(actor)
		actor.global_position = ending.get("_offer_prompt").global_position
		hub.actors[peer] = actor

	ending.dispatch(2, {"kind": "ending_claim"})
	_check(hub.refusals_for(2).size() == 1, "nothing can be claimed before the Dynamo releases the Stormheart")
	game.progression.set_flag("stormwood:marrow_defeated")
	await process_frame
	await process_frame
	_check(game.progression.has("stormwood:legendary_freed"), "Marrow's defeat frees the Stormheart once")
	var state: Dictionary = ENDING.migrate_state(game.realm_environment.stormwood.ending)
	_check((state.participants as Array).has(host_character) and (state.participants as Array).has("character-fought-b")
		and (state.participants as Array).has("character-left-d")
		and not (state.participants as Array).has("character-watched-c"),
		"the freeing records every fighter, including one who disconnected, and not the onlooker")

	ending.dispatch(3, {"kind": "ending_claim"})
	_check(hub.offers_for(3).is_empty() and hub.refusals_for(3).size() == 1,
		"a character who did not fight receives no offer")
	_check(game.progression.has("stormwood:legendary_offer_made"),
		"an onlooker can still let the world's single offer fact land, so Waterward never waits on absent fighters")
	ending.dispatch(local_peer, {"kind": "ending_claim", "already_accepted": true})
	_check(hub.offers_for(local_peer).is_empty(),
		"a character who accepted a Stormheart in another world gets no second creature")
	# The client's hint is built from its portable acceptance only: a refusal
	# in another world (ceremony receipt, no acceptance) is no hint at all.
	var refused_elsewhere: RefCounted = preload("res://autoload/progression_state.gd").new()
	ENDING.record_answer(refused_elsewhere, "creature-from-another-world", false)
	ending.dispatch(local_peer, ENDING.claim_intent(refused_elsewhere))
	_check(hub.offers_for(local_peer).size() >= 1,
		"refused in another world, fought here: the host's participating character receives this world's offer")
	ending.dispatch(local_peer, {"kind": "ending_settled", "kept": true})
	ending.dispatch(2, {"kind": "ending_claim"})
	var b_offers := hub.offers_for(2)
	_check(b_offers.size() >= 1, "the second participant still receives their own offer after the first settles")
	if not b_offers.is_empty():
		var claim: Dictionary = b_offers.back().event.claim
		_check(str(claim.recipient_character_id) == "character-fought-b" and not (claim.creature as Dictionary).is_empty(),
			"B's offer is bound to B's stable character and carries its own creature")
	var before_refusals := hub.refusals_for(local_peer).size()
	ending.dispatch(local_peer, {"kind": "ending_claim"})
	_check(hub.refusals_for(local_peer).size() == before_refusals + 1,
		"a character who already answered cannot claim again")
	ending.dispatch(2, {"kind": "ending_settled", "kept": false})
	state = ENDING.migrate_state(game.realm_environment.stormwood.ending)
	_check((state.claims as Dictionary).has(host_character) and bool(state.claims[host_character].kept) and not bool(state.claims["character-fought-b"].kept)
		and bool(state.claims["character-fought-b"].settled),
		"each character's accept or refuse is recorded separately")
	_check((state.claims as Dictionary).size() == 2, "exactly one claim per participating character")
	_check(game.progression.has(ENDING.resolution_flag(true, host_character))
		and game.progression.has(ENDING.resolution_flag(false, "character-fought-b"))
		and not game.progression.has(ENDING.resolution_flag(true, "character-fought-b")),
		"each answer leaves its own world receipt: accepted for the host, refused for B")

	var saved: Dictionary = game.world.save_data()
	var environment: Dictionary = game.realm_environment.duplicate(true)
	game.realm_environment = {}
	game.world.load_data({})
	game.world.load_data(saved)
	game.realm_environment = environment
	var offers_before := hub.offers_for(2).size()
	ending.dispatch(2, {"kind": "ending_claim"})
	_check(hub.offers_for(2).size() == offers_before, "after reload a settled character is not offered again")

	# The host's own receipt decides, whatever the client reports: with B's
	# claim record gone but B's world answer receipt still standing, B's client
	# claiming it never answered is refused.
	state = ENDING.migrate_state(game.realm_environment.stormwood.ending)
	(state.claims as Dictionary).erase("character-fought-b")
	game.realm_environment.stormwood.ending = state
	offers_before = hub.offers_for(2).size()
	ending.dispatch(2, {"kind": "ending_claim", "already_accepted": false})
	_check(hub.offers_for(2).size() == offers_before,
		"the host refuses from its own answer receipt even when the client says it never answered")

	# A legacy save: freed before participants were recorded and never claimed,
	# and the Dynamo kept no fighter record either. A guest who never fought
	# claims first: they get nothing (but can land the world's offer fact), and
	# the host who freed it still gets its offer.
	var reset_legacy := func(dynamo_payload: Dictionary) -> void:
		game.progression.set_flag("stormwood:legendary_offer_made", false)
		for character: String in [host_character, "character-fought-b", "character-watched-c"]:
			for accepted: bool in [true, false]:
				game.progression.set_flag(ENDING.resolution_flag(accepted, character), false)
		var legacy_environment: Dictionary = game.realm_environment.duplicate(true)
		legacy_environment.stormwood.ending = {}
		legacy_environment.stormwood.dynamo = dynamo_payload.duplicate(true)
		game.realm_environment = legacy_environment
	dynamo.fighter_characters = []
	dynamo.contributors = []
	dynamo.participants = []
	reset_legacy.call({})
	var b_before := hub.offers_for(2).size()
	var c_before := hub.offers_for(3).size()
	var host_before := hub.offers_for(local_peer).size()
	ending.dispatch(3, {"kind": "ending_claim"})
	_check(hub.offers_for(3).size() == c_before,
		"a guest claiming first on a legacy save with no fighter record gets no creature")
	_check(game.progression.has("stormwood:legendary_offer_made"),
		"the refused guest still lands the world offer fact, so Waterward never softlocks")
	ending.dispatch(local_peer, {"kind": "ending_claim"})
	_check(hub.offers_for(local_peer).size() == host_before + 1,
		"the host who freed it still receives its own offer after a guest claimed first")
	ending.dispatch(2, {"kind": "ending_claim"})
	_check(hub.offers_for(2).size() == b_before,
		"with no Dynamo record only the host is a participant; another guest gets nothing")
	state = ENDING.migrate_state(game.realm_environment.stormwood.ending)
	_check(state.get("participants", []) == [host_character] and (state.claims as Dictionary).keys() == [host_character],
		"the legacy save records the host as its one participant, with one claim")
	ending.dispatch(local_peer, {"kind": "ending_claim"})
	_check(hub.offers_for(local_peer).size() == host_before + 2, "the host's own unsettled claim still resumes")

	# The same legacy save where the Dynamo's persisted payload still names its
	# fighter characters: those are owed, the guest is not, whoever arrives
	# first. Its contributor peer ids come from the session that fought, so
	# they are not mapped through today's registry (peer 1 is whoever hosts now).
	reset_legacy.call({"fighter_characters": ["character-fought-b"], "contributors": [local_peer, 77]})
	b_before = hub.offers_for(2).size()
	c_before = hub.offers_for(3).size()
	host_before = hub.offers_for(local_peer).size()
	ending.dispatch(3, {"kind": "ending_claim"})
	_check(hub.offers_for(3).size() == c_before,
		"a guest claiming first is refused against the Dynamo's persisted fighters")
	ending.dispatch(2, {"kind": "ending_claim"})
	_check(hub.offers_for(2).size() == b_before + 1, "the Dynamo's persisted fighter receives an offer")
	ending.dispatch(local_peer, {"kind": "ending_claim"})
	_check(hub.offers_for(local_peer).size() == host_before,
		"an old-session contributor peer id is not mapped to today's host character")
	state = ENDING.migrate_state(game.realm_environment.stormwood.ending)
	_check(state.get("participants", []) == ["character-fought-b"]
		and (state.claims as Dictionary).keys() == ["character-fought-b"],
		"the legacy save records only the Dynamo's fighter characters as participants")
	world.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)


func _finish() -> void:
	for failure: String in failures:
		push_error("FAIL: " + failure)
	print("STORMWOOD STORMHEART PARTICIPANTS %s: %d assertions, %d failures" % [
		"OK" if failures.is_empty() else "FAILED", assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
