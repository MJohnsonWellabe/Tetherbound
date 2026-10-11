extends SceneTree

## Host-authority fixture for the per-participant Stormheart offer. The real
## `stormwood_ending.gd` runs against the offline host Session with two extra
## registered characters; a hub stub records what each peer is sent, a chapter
## adapter reads the real authored table, and a Dynamo stub
## supplies the fight's participant peers. It also covers the host refusing
## from its own answer receipt against a client's flag, the portable
## acceptance hint (an acceptance elsewhere withholds, a refusal does not), and
## a legacy save freed before participants were recorded: the Dynamo's own
## record, else only the host, never whoever claims first. It does not play the
## fight, the dialogue or the five-slot ceremony UI. The final-act entry is
## seeded explicitly. The original SaveGame writes isolated scratch files;
## an in-file transport queue carries the real owner-passive messages. This
## fixture does not prove an earned chapter or a physical network connection.
const ENDING := preload("res://scripts/world/stormwood_ending.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

var failures: Array[String] = []
var assertions := 0
var _wire: Array[Dictionary] = []
var _scratch := ""


class FixtureWorld extends Node3D:
	var simulation_only := true

	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0

	func entry_anchor(_id: String) -> Dictionary:
		return {}


class HubStub extends Node:
	var sent: Array = []
	var actors: Dictionary = {}
	var ending: Node

	func send_to(peer: int, event: Dictionary) -> void:
		sent.append({"peer": peer, "event": event.duplicate(true)})
		if peer == 1 and ending != null and event.get("kind") == "ending_answer_saved":
			ending.receive(event)

	func dispatch(peer: int, intent: Dictionary) -> void:
		if ending != null: ending.dispatch(peer, intent)

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
	var chapter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_chapter.json"))

	func emit_event(event: String) -> Dictionary:
		return preload("res://scripts/world/realm_chapter_progression.gd").dispatch(game.progression, chapter, event)


class PreparedWorldWriter extends RefCounted:
	var writes: Array[Dictionary] = []
	var character_writes: Array[Dictionary] = []
	var saver: RefCounted
	func finish_fallback() -> bool: return saver.finish_fallback()
	func fallback_busy() -> bool: return saver.fallback_busy()
	func save_character_prepared(game: Object, character_id: String) -> bool:
		var saved: bool = saver.save_character_prepared(game, character_id)
		if saved: character_writes.append(game.local.save_data().duplicate(true))
		return saved
	func save_world_prepared(game: Object, world_id: String) -> bool:
		if world_id != "stormheart-participants-fixture" or game.world.world_id != world_id: return false
		var saved: bool = saver.save_world_prepared(game, world_id)
		if saved: writes.append(game.world.save_data().duplicate(true))
		return saved


## Transport only. All admission, scope, owner-save and settlement code is
## inherited from the actual Session; packets are never fabricated here.
class SessionTransport extends "res://scripts/net/session.gd":
	var wire: Array[Dictionary] = []
	func _owner_passive_send_host(packet: Dictionary) -> void:
		wire.append({"to_host": true, "peer": 2, "packet": packet.duplicate(true)})
	func _owner_passive_send_peer(peer: int, packet: Dictionary) -> void:
		wire.append({"to_host": false, "peer": peer, "packet": packet.duplicate(true)})


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
	var original_session: Node = game.session
	var original_process_mode: int = original_session.process_mode
	var original_world: Dictionary = game.world.save_data().duplicate(true)
	var original_character: Dictionary = game.local.save_data().duplicate(true)
	game.reset_for_new_game()
	game.current_realm = "stormwood"
	var original_saver: RefCounted = game.save_system
	var prepared_writer := PreparedWorldWriter.new()
	_scratch = "user://stormheart-participants-%d/" % Time.get_ticks_usec()
	prepared_writer.saver = SAVE_GAME.new(_scratch)
	game.save_system = prepared_writer
	game.world.world_id = "stormheart-participants-fixture"
	game.progression.set_flag("stormwood:act_ii_complete")
	original_session.name = "StormheartOriginalSession"
	original_session.process_mode = Node.PROCESS_MODE_DISABLED
	var session := SessionTransport.new()
	session.wire = _wire
	game.add_child(session)
	session.process_mode = Node.PROCESS_MODE_DISABLED
	game.session = session
	session.call("_owner_passive_service")
	var guest_session := SessionTransport.new()
	guest_session.wire = _wire
	game.add_child(guest_session)
	guest_session.name = "StormheartGuestSession"
	guest_session.process_mode = Node.PROCESS_MODE_DISABLED
	guest_session.set("_mode", "client")
	var local_peer := int(session.local_peer_id())
	# A headless new game has no stable character id yet; give the host one.
	game.local.set("character_id", "character-host-a")
	var host_character := str(game.local.character_id)
	var host_player: RefCounted = game.local
	_check(host_character == "character-host-a", "the host character has a stable id")
	var registry: RefCounted = session.registry()
	registry.call("add", 2, "character-fought-b", "B")
	registry.call("add", 3, "character-watched-c", "C")
	for peer: int in [2, 3]:
		registry.call("set_realm", peer, "stormwood")
	_check(session.call("_bind_character_authority") == true, "the actual Session binds this world")
	var guest := PLAYER.new()
	guest.character_id = "character-fought-b"
	guest.realm = "stormwood"
	var onlooker := PLAYER.new()
	onlooker.character_id = "character-watched-c"
	onlooker.realm = "stormwood"
	for player: RefCounted in [guest, onlooker]:
		var admitted: Dictionary = session.get("_character_authority").seed_admitted_character(
			AUTHORITY.portable_projection(player.save_data()), str(player.character_id))
		_check(admitted.get("ok") == true, "the registered character has an admitted portable record")

	var world := FixtureWorld.new()
	world.name = "StormheartFixture"
	root.add_child(world)
	current_scene = world
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
	hub.ending = ending
	hub.add_to_group("stormwood_encounter_hub")
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
	var host_offers := hub.offers_for(local_peer)
	if not host_offers.is_empty(): ending.receive(host_offers.back().event)
	ending.call("_begin_local_ceremony")
	var host_acks: Array = hub.sent.filter(func(row: Dictionary) -> bool:
		return row.peer == local_peer and row.event.get("kind") == "ending_answer_saved")
	_check(not host_offers.is_empty() and not host_acks.is_empty()
		and host_acks.back().event.get("claim_uid") == ENDING.claim_id(host_offers.back().event.claim)
		and session.get("_owner_passive").get("stormwood_owner").is_empty(),
		"the host's original BOOL-saved answer receives its durable ACK")
	ending.dispatch(2, {"kind": "ending_claim"})
	var b_offers := hub.offers_for(2)
	_check(b_offers.size() >= 1, "the second participant still receives their own offer after the first settles")
	if not b_offers.is_empty():
		var claim: Dictionary = b_offers.back().event.claim
		_check(str(claim.recipient_character_id) == "character-fought-b" and not (claim.creature as Dictionary).is_empty(),
			"B's offer is bound to B's stable character and carries its own creature")
	# Second guard: B's client now reports an acceptance from another world.
	# The host sends no fresh creature even though it holds B's unsettled claim.
	var b_offers_before := hub.offers_for(2).size()
	ending.dispatch(2, {"kind": "ending_claim", "already_accepted": true})
	var b_refusals := hub.refusals_for(2)
	_check(hub.offers_for(2).size() == b_offers_before and not b_refusals.is_empty()
		and str(b_refusals.back().event.reason) == "A Stormheart already walks with you.",
		"an acceptance hint withholds a creature even while the host holds that character's unsettled claim")
	var before_refusals := hub.refusals_for(local_peer).size()
	ending.dispatch(local_peer, {"kind": "ending_claim"})
	_check(hub.refusals_for(local_peer).size() == before_refusals + 1,
		"a character who already answered cannot claim again")
	if not b_offers.is_empty():
		_answer_guest(game, host_player, session, guest, guest_session, ending, hub,
			b_offers.back().event.claim)
	state = ENDING.migrate_state(game.realm_environment.stormwood.ending)
	_check((state.claims as Dictionary).has(host_character) and bool(state.claims[host_character].kept) and not bool(state.claims["character-fought-b"].kept)
		and bool(state.claims["character-fought-b"].settled),
		"each character's accept or refuse is recorded separately")
	_check((state.claims as Dictionary).size() == 2, "exactly one claim per participating character")
	_check(game.progression.has(ENDING.resolution_flag(true, host_character))
		and game.progression.has(ENDING.resolution_flag(false, "character-fought-b"))
		and not game.progression.has(ENDING.resolution_flag(true, "character-fought-b")),
		"each answer leaves its own world receipt: accepted for the host, refused for B")
	_check(not prepared_writer.writes.is_empty(), "the actual settlement used the prepared bool world writer")
	if not prepared_writer.writes.is_empty():
		var written := preload("res://autoload/world_state.gd").new()
		written.load_data(prepared_writer.writes.back())
		_check(written.flags.has(ENDING.resolution_flag(true, host_character))
			and written.flags.has(ENDING.resolution_flag(false, "character-fought-b"))
			and written.realm_environment.stormwood.ending.claims["character-fought-b"].settled == true,
			"the bool writer observed the original per-character receipts and settled claim together")

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
	game.save_system = original_saver
	current_scene = original_scene
	world.queue_free()
	await process_frame
	guest_session.free()
	session.free()
	original_session.name = "Session"
	original_session.process_mode = original_process_mode
	game.session = original_session
	game.local = host_player
	game.world.load_data(original_world)
	game.local.load_data(original_character)
	game.call("_ensure_containers")
	_remove_scratch(_scratch)
	_finish()


func _select_owner(game: Node, player: RefCounted, session: Node) -> void:
	game.local = player
	game.session = session
	game.call("_ensure_containers")


func _answer_guest(game: Node, host: RefCounted, host_session: Node, guest: RefCounted,
		guest_session: Node, ending: Node, hub: HubStub, claim: Dictionary) -> void:
	var before := AUTHORITY.portable_projection(guest.save_data())
	_select_owner(game, guest, guest_session)
	guest_session.call("_rpc_altar_epoch", host_session.call("_altar_current_epoch"),
		game.world.reward_delivery_namespace, guest.character_id)
	var owner: RefCounted = guest_session.call("_owner_passive_service")
	var declaration: Dictionary = owner.call("arm_owner", before, {})
	_select_owner(game, host, host_session)
	var passive: RefCounted = host_session.call("_owner_passive_service")
	passive.call("admitted", 2, {"portable_authority": before, "discovered_landmarks": {},
		"owner_passive_stream": declaration})
	_select_owner(game, guest, guest_session)
	owner.call("_flush")
	# Deliver the actual resume and actual host inputs_ack in their own scopes.
	while not _wire.is_empty():
		var message: Dictionary = _wire.pop_front()
		if message.to_host:
			_select_owner(game, host, host_session)
			passive.call("receive_host", int(message.peer), message.packet)
		else:
			_select_owner(game, guest, guest_session)
			owner.call("receive_owner", message.packet)
	_select_owner(game, guest, guest_session)
	_check(owner.call("delivery_ready") == true, "B receives the original admitted-stream ACK")
	_check(owner.call("stormwood_begin_owner", claim) == true, "B freezes its original admitted owner state")
	ENDING.record_answer(game.player_flags(), ENDING.claim_id(claim), false, game.party)
	var selected := claim.duplicate(true)
	selected.kept = false
	var cut: Dictionary = owner.call("stormwood_save_owner", selected, "")
	_check(cut.size() == 4, "B's original BOOL-saved refusal produces its stream cut")
	_select_owner(game, host, host_session)
	var sent_before := hub.sent.size()
	ending.dispatch(2, {"kind": "ending_settled", "kept": false, "released_uid": "", "stream_cut": cut})
	var ack: Dictionary = {}
	for row: Dictionary in hub.sent.slice(sent_before):
		if row.peer == 2 and row.event.get("kind") == "ending_answer_saved": ack = row.event
	_select_owner(game, guest, guest_session)
	_check(not ack.is_empty() and ack.get("claim_uid") == ENDING.claim_id(claim)
		and owner.call("stormwood_finish_owner", ack.get("stream_cut", {})) == true,
		"B cleans up only after its original mounted producer's durable ACK")
	_select_owner(game, host, host_session)


func _remove_scratch(path: String) -> void:
	var resolved := ProjectSettings.globalize_path(path).simplify_path().trim_suffix("/")
	var base := ProjectSettings.globalize_path(_scratch).simplify_path().trim_suffix("/")
	if _scratch.is_empty() or (resolved != base and not resolved.begins_with(base + "/")): return
	var directory := DirAccess.open(path)
	if directory == null: return
	for child: String in directory.get_directories(): _remove_scratch(path.path_join(child))
	for child: String in directory.get_files(): directory.remove(child)
	DirAccess.remove_absolute(path)


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
