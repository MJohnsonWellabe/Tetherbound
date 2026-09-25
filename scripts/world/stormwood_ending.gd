extends Node3D

## The Stormwood chapter's playable release and aftermath.
##
## Marrow's Dynamo remains the authority for combat. Once its fourth conduit
## commits the victory flag, this host-owned controller opens the prison and
## records which characters fought for the release. Owner rule (CLAUDE.md):
## every participant receives their own once-only offer, bound to their stable
## character, and each who accepts keeps their own; a non-participant receives
## nothing. Each claim addresses that character's existing five-slot ceremony,
## so a sixth slot never exists. The freeing, the quieted storm and the
## Waterward reveal stay single world facts committed through the chapter
## ledger; the first settled decision records the world's offer fact. The Spark
## is placed later at the Meadows shrine circle, like the other relic powers.
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const TRAINER_NPC := preload("res://scripts/world/trainer_npc.gd")
const CAPTURE_CODEC := preload("res://scripts/save/water_capture_codec.gd")
const WATER_GATE := preload("res://scripts/world/stormwood_water_gate.gd")

const MARROW_FLAG := "stormwood:marrow_defeated"
const FREED_FLAG := "stormwood:legendary_freed"
const OFFER_FLAG := "stormwood:legendary_offer_made"
const WATERWARD_FLAG := "stormwood:waterward_revealed"
const PERSONAL_RECEIPT_FLAG := "stormwood:legendary_ceremony_settled"
## Portable, player-owned: this character said Yes and a Stormheart joined them
## (with room, or kept through the release ceremony). It is the only cross-world
## hint a client sends: an acceptance anywhere withholds a second creature, a
## refusal withholds nothing. Its player scope is a line in flag_scopes.json.
const ACCEPTED_FLAG := "stormwood:legendary_offer_accepted"
## Player-owned answer to ONE world's claim: `<prefix><claim id>:accepted` or
## `:refused`, where the claim id is the uid of the Stormheart that world
## reserved. It is what resumes an answer the host has not acknowledged yet,
## and it can never be mistaken for another world's answer. Its player scope
## is a prefix line in flag_scopes.json (longer than the world `stormwood:`).
##
## The older bare ceremony receipt (`PERSONAL_RECEIPT_FLAG`) is still written
## beside it. A character holding that receipt with no scoped answer at all
## answered under an older build that did not record Yes from No, so it reads
## as an acceptance: no offer is ever granted twice.
const ANSWER_PREFIX := "stormwood:legendary_answer:"
## Published instead of an empty list when the host knows nobody who fought,
## so a client never reads it as a solo freeing that anyone may answer.
const NO_KNOWN_PARTICIPANT := "(none)"
## World receipt per character's answer, mirroring the Meadows finale's
## `legendary_resolution:<accepted|refused>:<character>`; world-scoped by the
## `stormwood:` prefix and committed once by the host.
const RESOLUTION_PREFIX := "stormwood:legendary_resolution:"
## Its last line is a Yes/No consent line carrying `confirm_effect:
## stormheart:accept`. Nothing else in Stormwood drains the panel, so this
## controller drains it when the offer completes and reads Yes from that effect.
## The panel's `declined` signal (its runner's `confirm(false)`, drawn as "No")
## is the only refusal; a close from anywhere else leaves the offer unanswered.
const OFFER_CONVERSATION := "stormwood_stormheart_offer"
const OFFER_ACCEPT_EFFECT := "stormheart:accept"
const LEDGER_CLAIM := preload("res://scripts/world/ledger_claim.gd")
const LEGENDARY_SPECIES := "fulgocobra"
const LEGENDARY_NAME := "the Stormheart"
const LEGENDARY_LEVEL := 44
const CORE_POSITION := Vector3(-100.0, 262.21, 5470.0)
const OFFER_RADIUS_M := 14.0
const VIEW_RADIUS_M := 18.0
const WATER_GATE_RADIUS_M := 6.0
const RESEND_SECONDS := 1.0

var world: Node3D
var hub: Node
var session: Node
var _chapter: Node
var _legendary: Node3D
var _cage: Node3D
var _offer_prompt: Node3D
var _view_prompt: Node3D
var _water_gate: Node3D
var _waterward_sea: MeshInstance3D
var _local_claim: Dictionary = {}
var _local_creature: RefCounted
var _waiting_for_offer_dialogue := false
## This conversation reached its Yes/No line, and whether Yes or the panel's
## explicit No was chosen. Neither set means the conversation was cut off.
var _offer_reached_choice := false
var _offer_accepted := false
var _offer_declined := false
## Yes was answered while another catch ceremony held the belt; the Stormheart's
## own ceremony starts as soon as that one ends.
var _ceremony_waiting := false
var _save_retry_left := 0.0
var _resend_left := 0.0
var _released_announced := false
var _aftermath_announced := false
var _progression_revision := -1
## Character ids the host judges claims against, as last published: the
## recorded fighters, or for a save from before the list existed the host's
## fallback (see `participants_for_claim()`).
var _participants: Array = []


func mount(owner_world: Node3D) -> void:
	world = owner_world
	hub = world.get_node("StormwoodEncounterHub")
	session = get_node("/root/Game/Session")
	_chapter = world.get_node("StormwoodChapter")
	global_position = CORE_POSITION
	_build_captive()
	_build_offer_prompt()
	_build_waterward_view()
	_build_water_gate()
	var panel := world.get_node_or_null("DialoguePanel")
	if panel != null:
		panel.finished.connect(_dialogue_finished)
		panel.completed.connect(_dialogue_completed)
		panel.line_presented.connect(_line_presented)
		panel.declined.connect(_dialogue_declined)
	add_to_group("progression_restore")
	_refresh_presentation()
	_released_announced = _has(FREED_FLAG)
	_aftermath_announced = _has(WATERWARD_FLAG)
	if not bool(world.get("simulation_only")):
		session.request_stormwood_encounter({"kind": "ending_snapshot"})


func dispatch(peer: int, intent: Dictionary) -> void:
	if not session.is_host():
		return
	match str(intent.get("kind", "")):
		"ending_claim":
			# The client's portable acceptance is only a hint: it can withhold
			# this character's own creature, never grant one (see offer_owed()).
			_claim_for(peer, bool(intent.get("already_accepted", false)))
		"ending_settled":
			_settle_for(peer, intent)
		"ending_waterward_view":
			_reveal_for(peer)
		WATER_GATE.UNLOCK_INTENT:
			_unlock_water_gate_for(peer)
		"ending_snapshot":
			send_snapshot(peer)


func receive(event: Dictionary) -> void:
	match str(event.get("kind", "")):
		"ending_state":
			_released_announced = bool(event.get("released", false))
			_aftermath_announced = bool(event.get("waterward_revealed", false))
			_participants = (event.get("participants", []) as Array).duplicate()
			_refresh_presentation()
		"ending_release":
			_released_announced = true
			_refresh_presentation()
			_animate_release()
			_start_dialogue_when_free("stormwood_stormheart_release")
		"ending_offer":
			var claim: Variant = event.get("claim", {})
			if claim is Dictionary and not (claim as Dictionary).is_empty():
				_receive_claim(claim as Dictionary)
		"ending_aftermath":
			_aftermath_announced = true
			_refresh_presentation()
			_start_dialogue_when_free("stormwood_waterward_aftermath")
		"ending_water_gate_opened":
			get_node("/root/Game").push_world_message("The Waterward gate is open.")
		"ending_refused":
			get_node("/root/Game").push_world_message(str(event.get("reason", "The Stormheart is not ready.")))


func send_snapshot(peer: int) -> void:
	if not session.is_host():
		return
	hub.call("send_to", peer, _state_event())
	var character := _character_for_peer(peer)
	var claim := claim_for_character(_saved_state(), character)
	if not claim.is_empty():
		_send_claim(peer, character, claim)


func restore_progression_from_game(_game: Node) -> void:
	_progression_revision = -1
	_refresh_presentation()


func _process(delta: float) -> void:
	var progression: RefCounted = get_node("/root/Game").get("progression")
	if progression != null and int(progression.get("revision")) != _progression_revision:
		_refresh_presentation()
	_process_local_claim(delta)
	if not session.is_host():
		return
	# realm_chapter_events admits the matching host simulation shell, so the
	# authority that completed Marrow also owns every shared ending mutation.
	if _has(MARROW_FLAG) and not _has(FREED_FLAG):
		_record_participants()
		_chapter.call("emit_event", "dynamo:release")
	if _has(FREED_FLAG) and not _released_announced:
		_released_announced = true
		_broadcast(_state_event())
		_broadcast({"kind": "ending_release"})
	if _has(WATERWARD_FLAG) and not _aftermath_announced:
		_aftermath_announced = true
		_broadcast({"kind": "ending_aftermath"})
	_resend_left -= delta
	if _resend_left <= 0.0 and _has(FREED_FLAG):
		_resend_left = RESEND_SECONDS
		var state := _saved_state()
		for peer: int in session.peers_in_realm("stormwood"):
			var character := _character_for_peer(peer)
			var claim := claim_for_character(state, character)
			if not claim.is_empty():
				_send_claim(peer, character, claim)


func _claim_for(peer: int, client_hint_accepted := false) -> void:
	if not _has(FREED_FLAG):
		_refuse(peer, "The Stormheart is still bound inside the Dynamo.")
		return
	var actor: Node3D = hub.call("actor_for", peer)
	if not is_instance_valid(actor) or actor.global_position.distance_to(_offer_prompt.global_position) > OFFER_RADIUS_M:
		_refuse(peer, "Stand beside the freed Stormheart before answering it.")
		return
	var character := _character_for_peer(peer)
	if character.is_empty():
		_refuse(peer, "Your character record is not ready for this ceremony.")
		return
	var state := _saved_state()
	var claims: Dictionary = state.get("claims", {})
	var existing: Dictionary = claims.get(character, {})
	var fallback := _fallback_participants()
	var owed := offer_owed(state, character, _world_flags_for(character), client_hint_accepted, fallback)
	if not owed:
		# No creature for this character (did not fight, already accepted a
		# Stormheart in another world, or already answered here). It can
		# still let the world move on: the freeing's single offer fact must
		# never wait on a participant who is absent or already resolved.
		if not _has(OFFER_FLAG):
			var result: Dictionary = _chapter.call("emit_event", "legendary:offer_shown")
			if bool(result.get("accepted", false)) or _has(OFFER_FLAG):
				_save_world_claim()
				_broadcast(_state_event())
				_refuse(peer, "The Stormheart has seen you. Its bond is for the trainers who fought for it, and they may still answer.")
				return
		var answered := not existing.is_empty() \
			or _has(resolution_flag(true, character)) or _has(resolution_flag(false, character))
		var reason := "The Stormheart answers the trainers who fought for its release."
		if answered:
			reason = "You have already answered the Stormheart."
		elif client_hint_accepted:
			reason = "A Stormheart already walks with you."
		_refuse(peer, reason)
		return
	if existing.is_empty():
		var creature := _make_legendary()
		var payload := CAPTURE_CODEC.encode(creature)
		if payload.is_empty():
			_refuse(peer, "The Stormheart could not begin the ceremony.")
			return
		existing = {"creature": payload, "settled": false, "kept": false}
		claims[character] = existing
		state["claims"] = claims
		# A freeing with no recorded fighters (a save from before the list
		# existed) saves the fallback it was judged against with the claim, so
		# later claims read the same list. It is never the claimant themself.
		var unrecorded := (state.get("participants", []) as Array).is_empty()
		if unrecorded:
			state["participants"] = participants_for_claim(state, fallback)
		var game := get_node("/root/Game")
		var before: Dictionary = (game.get("realm_environment") as Dictionary).duplicate(true)
		_store_state(state)
		if not _save_world_claim():
			game.set("realm_environment", before)
			_refuse(peer, "The world could not save the ceremony. Try again.")
			return
		if unrecorded:
			_broadcast(_state_event())
	_send_claim(peer, character, existing)


func _settle_for(peer: int, intent: Dictionary) -> void:
	var character := _character_for_peer(peer)
	var state := _saved_state()
	var claims: Dictionary = state.get("claims", {})
	var claim: Dictionary = claims.get(character, {})
	if claim.is_empty():
		_refuse(peer, "Only a trainer answering the Stormheart can settle its offer.")
		return
	if bool(claim.get("settled", false)):
		return
	claim["kept"] = bool(intent.get("kept", false))
	claim["settled"] = true
	claims[character] = claim
	state["claims"] = claims
	_store_state(state)
	# The first decision records the world's single offer fact; later
	# participants' decisions are personal and need no second world write.
	if not _has(OFFER_FLAG):
		var result: Dictionary = _chapter.call("emit_event", "legendary:offer_shown")
		if not bool(result.get("accepted", false)) and not _has(OFFER_FLAG):
			claim["settled"] = false
			claims[character] = claim
			state["claims"] = claims
			_store_state(state)
			_refuse(peer, "The world could not record the ceremony. Try again.")
			return
	_submit_resolution(bool(claim["kept"]), character)
	_save_world_claim()
	_broadcast(_state_event())


func _reveal_for(peer: int) -> void:
	if _has(WATERWARD_FLAG):
		hub.call("send_to", peer, {"kind": "ending_aftermath"})
		return
	if not _has(OFFER_FLAG):
		_refuse(peer, "Resolve the Stormheart's offer before reading the cleared sky.")
		return
	var actor: Node3D = hub.call("actor_for", peer)
	if not is_instance_valid(actor) or actor.global_position.distance_to(_view_prompt.global_position) > VIEW_RADIUS_M:
		_refuse(peer, "Climb onto the high platform to see beyond the broken storm.")
		return
	var result: Dictionary = _chapter.call("emit_event", "aftermath:waterward_view")
	if bool(result.get("accepted", false)) and _has(WATERWARD_FLAG):
		_broadcast({"kind": "ending_aftermath"})


func _unlock_water_gate_for(peer: int) -> void:
	if not is_instance_valid(_water_gate):
		_refuse(peer, "The Waterward gate is not ready yet.")
		return
	var actor: Node3D = hub.call("actor_for", peer)
	var game := get_node("/root/Game")
	var flags: RefCounted = game.get("progression") as RefCounted
	if not is_instance_valid(actor) or not WATER_GATE.request_allowed(flags,
			actor.global_position, _water_gate.global_position, WATER_GATE_RADIUS_M):
		_refuse(peer, "Stand at the Waterward gate after charting the cleared sky.")
		return
	var transport: Node = game.get("ledger") as Node
	var ledger: RefCounted = transport.get("ledger") as RefCounted if transport != null else null
	var result: Dictionary = WATER_GATE.host_commit(game, ledger)
	if not bool(result.get("ok", false)):
		_refuse(peer, str(result.get("reason", "The Waterward gate did not open.")))
		return
	var delta: Dictionary = result.get("delta", {}) as Dictionary
	if transport != null and not (delta.get("ops", []) as Array).is_empty():
		transport.call("publish_journaled_delta", delta)
	# The host's ordinary RealmGate interaction already reports synchronous
	# success. A remote requester needs the same feedback while its delta lands.
	if peer != int(session.call("local_peer_id")):
		hub.call("send_to", peer, {"kind": "ending_water_gate_opened"})


func _receive_claim(claim: Dictionary) -> void:
	var game := get_node("/root/Game")
	var mine := _local_character_id(game)
	if mine.is_empty() or str(claim.get("recipient_character_id", "")) != mine:
		return
	# This character's own saved answer to THIS claim resumes it; an answer to
	# another world's claim has a different id and is never read here.
	var player_flags: RefCounted = game.call("player_flags")
	var answer := recorded_answer(player_flags, claim_id(claim))
	if answer == "accepted" or _party_holds_claim(game.get("party"), claim):
		_local_claim = claim.duplicate(true)
		_save_retry_left = 0.0
		_finish_local_claim(true)
		return
	if answer == "refused":
		_local_claim = claim.duplicate(true)
		_finish_local_claim(false)
		return
	# A resend of the claim already being answered is ignored here, after the
	# answer branches above so a failed save can still retry.
	if not _local_claim.is_empty() or game.get("pending_catch") != null:
		return
	_local_claim = claim.duplicate(true)
	_waiting_for_offer_dialogue = true
	_start_dialogue_when_free("stormwood_stormheart_offer")


func _process_local_claim(delta: float) -> void:
	var game := get_node("/root/Game")
	var catch_open := game.get("pending_catch") != null
	if _waiting_for_offer_dialogue and not catch_open:
		var panel := world.get_node_or_null("DialoguePanel")
		if panel == null or not bool(panel.call("is_open")):
			_start_dialogue_when_free("stormwood_stormheart_offer")
	if _ceremony_waiting and not catch_open:
		_ceremony_waiting = false
		_begin_local_ceremony()
	if _local_claim.is_empty() or _local_creature == null:
		return
	if catch_open:
		return
	_save_retry_left -= delta
	if _save_retry_left > 0.0:
		return
	_finish_local_claim((game.get("party").call("members") as Array).has(_local_creature))


func _line_presented(id: String, is_last: bool) -> void:
	if id == OFFER_CONVERSATION and is_last:
		_offer_reached_choice = true


## Yes queues the consent line's effect; draining it here is its only consumer,
## so it is never left queued. Any other effect is a loud no-op, as the runner's
## contract asks of a caller that does not know it.
func _dialogue_completed(id: String) -> void:
	if id != OFFER_CONVERSATION:
		return
	var panel := world.get_node_or_null("DialoguePanel")
	if panel == null:
		return
	for effect: String in panel.call("drain_effects"):
		if effect == OFFER_ACCEPT_EFFECT:
			_offer_accepted = true
		else:
			push_warning("the Stormheart offer ignored dialogue effect '%s'" % effect)


## The panel's explicit No on the Yes/No line. It is emitted just before the
## same conversation's `finished`, which reads it.
func _dialogue_declined(id: String) -> void:
	if id == OFFER_CONVERSATION and _waiting_for_offer_dialogue and _offer_reached_choice:
		_offer_declined = true


## The runner closes (`finished`) before it reports `completed` for a Yes, so
## the answer is read one frame later. Only Yes or the panel's explicit No
## (`declined`) answers; any other close (before or on the Yes/No line)
## answers nothing and the offer is asked again.
func _dialogue_finished(id: String) -> void:
	if id != OFFER_CONVERSATION or not _waiting_for_offer_dialogue:
		return
	_waiting_for_offer_dialogue = false
	_offer_declined = _offer_declined and _offer_reached_choice
	_resolve_offer_choice.call_deferred()


func _resolve_offer_choice() -> void:
	var accepted := _offer_accepted
	var declined := _offer_declined
	_offer_reached_choice = false
	_offer_accepted = false
	_offer_declined = false
	if accepted:
		_begin_local_ceremony()
	elif declined:
		refuse_offer()
	else:
		_waiting_for_offer_dialogue = true


## This character's explicit refusal: no creature, a personal receipt and the
## host's world receipt, exactly as letting the newcomer go at five.
func refuse_offer() -> void:
	if _local_claim.is_empty():
		return
	get_node("/root/Game").push_world_message("The Stormheart stays free. The Spark is yours either way.")
	_finish_local_claim(false)


func _begin_local_ceremony() -> void:
	if _local_claim.is_empty():
		return
	var game := get_node("/root/Game")
	if game.get("pending_catch") != null:
		_ceremony_waiting = true
		return
	_local_creature = CAPTURE_CODEC.decode(_local_claim.get("creature", {}))
	if _local_creature == null:
		# Nothing was answered or saved: drop the unreadable copy so the host's
		# next resend of this claim offers it afresh instead of being ignored.
		game.push_world_message("The Stormheart's offer could not be restored yet.")
		_local_claim.clear()
		return
	_local_creature.set("caught_on_day", maxi(1, int(game.get("day"))))
	var party: RefCounted = game.get("party")
	if not bool(party.call("is_full")):
		if bool(party.call("add", _local_creature)):
			_finish_local_claim(true)
		return
	game.set("pending_catch", _local_creature)


func _finish_local_claim(kept: bool) -> void:
	if _local_claim.is_empty():
		return
	var game := get_node("/root/Game")
	var saver: RefCounted = game.get("save_system")
	var character := _local_character_id(game)
	# The world keeps the unresolved claim; this player-owned receipt makes a
	# reconnect resume at the acknowledgement instead of replaying a farewell.
	record_answer(game.call("player_flags"), claim_id(_local_claim), kept)
	if saver != null and not character.is_empty() and not bool(saver.call("save_character", game, character)):
		_save_retry_left = 1.0
		game.push_world_message("Could not save the roster choice. The Stormheart is still waiting.")
		return
	session.request_stormwood_encounter({"kind": "ending_settled", "kept": kept})
	_local_claim.clear()
	_local_creature = null


func _on_offer() -> void:
	var game := get_node("/root/Game")
	session.request_stormwood_encounter(claim_intent(game.call("player_flags")))


## The claim a client sends: its portable acceptance is the only cross-world
## hint. A refusal in another world withholds nothing here.
static func claim_intent(player_flags: RefCounted) -> Dictionary:
	return {"kind": "ending_claim", "already_accepted": accepted_anywhere(player_flags)}


## This character accepted a Stormheart in some world: the portable flag, or a
## bare receipt left by an older build that never recorded Yes from No.
static func accepted_anywhere(player_flags: RefCounted) -> bool:
	if player_flags == null:
		return false
	if bool(player_flags.call("has", ACCEPTED_FLAG)):
		return true
	return bool(player_flags.call("has", PERSONAL_RECEIPT_FLAG)) and not _has_scoped_answer(player_flags)


## A claim's stable identity: the uid of the Stormheart its world reserved.
static func claim_id(claim: Dictionary) -> String:
	var creature: Variant = claim.get("creature", {})
	return str((creature as Dictionary).get("uid", "")) if creature is Dictionary else ""


static func answer_flag(id: String, accepted: bool) -> String:
	return "%s%s:%s" % [ANSWER_PREFIX, id, "accepted" if accepted else "refused"]


## "accepted", "refused" or "" for this character's saved answer to claim `id`.
static func recorded_answer(player_flags: RefCounted, id: String) -> String:
	if player_flags == null or id.is_empty():
		return ""
	if bool(player_flags.call("has", answer_flag(id, true))):
		return "accepted"
	if bool(player_flags.call("has", answer_flag(id, false))):
		return "refused"
	return ""


## Record this character's answer to claim `id`. A bare legacy receipt is first
## made an explicit acceptance, so writing the first scoped answer can never
## turn an older build's Yes into a refusal. The receipt is never cleared.
static func record_answer(player_flags: RefCounted, id: String, kept: bool) -> void:
	if player_flags == null:
		return
	if accepted_anywhere(player_flags):
		player_flags.call("set_flag", ACCEPTED_FLAG)
	player_flags.call("set_flag", PERSONAL_RECEIPT_FLAG)
	if not id.is_empty():
		player_flags.call("set_flag", answer_flag(id, kept))
	# Only a Stormheart that actually joined (or was kept through the release
	# ceremony) is an acceptance another world must respect.
	if kept:
		player_flags.call("set_flag", ACCEPTED_FLAG)


static func _has_scoped_answer(player_flags: RefCounted) -> bool:
	if not player_flags.has_method("all_set"):
		return false
	for id: Variant in player_flags.call("all_set"):
		if str(id).begins_with(ANSWER_PREFIX):
			return true
	return false


func _on_waterward_view() -> void:
	session.request_stormwood_encounter({"kind": "ending_waterward_view"})


func _refresh_presentation() -> void:
	var game := get_node_or_null("/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	_progression_revision = int(progression.get("revision")) if progression != null else -1
	var freed := _has(FREED_FLAG) or _released_announced
	# Each participant sees their own Stormheart until they have answered it;
	# a non-participant sees it leave once the world's first offer is settled.
	var owed := freed and _local_offer_owed(game)
	if _legendary != null:
		_legendary.visible = owed or not _has(OFFER_FLAG)
		_legendary.position = Vector3(0.0, 0.0, 8.0) if freed else Vector3.ZERO
	if _cage != null:
		_cage.visible = not freed
	if _offer_prompt != null:
		# Anyone may answer until the world's offer fact exists; afterwards only
		# a participant still owed their own Stormheart sees the prompt.
		var answerable := freed and (owed or not _has(OFFER_FLAG))
		_offer_prompt.set("enabled", answerable and not bool(world.get("simulation_only")))
		_offer_prompt.set("label", "Accept the Stormheart's offer" if owed else "Answer the freed Stormheart")
	if _view_prompt != null:
		var revealed := _has(WATERWARD_FLAG) or _aftermath_announced
		_view_prompt.set("enabled", _has(OFFER_FLAG) and not bool(world.get("simulation_only")))
		_view_prompt.set("actionable", not revealed)
		_view_prompt.set("label", "Waterward route charted" if revealed else "Look beyond the broken storm")
	if _waterward_sea != null:
		_waterward_sea.visible = _has(OFFER_FLAG)


func _animate_release() -> void:
	if bool(world.get("simulation_only")) or _legendary == null:
		return
	_legendary.position = Vector3.ZERO
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_legendary, "position", Vector3(0.0, 0.0, 8.0), 2.4)


func _build_captive() -> void:
	if bool(world.get("simulation_only")):
		_legendary = Node3D.new()
		_legendary.name = "CaptiveStormheart"
		add_child(_legendary)
		_cage = Node3D.new()
		_cage.name = "StormheartContainment"
		add_child(_cage)
		_legendary.visible = false
		return
	_legendary = CREATURE_SCENE.instantiate() as Node3D
	_legendary.set_script(CREATURE_BODY)
	_legendary.name = "CaptiveStormheart"
	_legendary.set("body_scale", 1.8)
	_legendary.call("setup", LEGENDARY_SPECIES, false)
	add_child(_legendary)
	_legendary.call("set_alpha", true)
	_legendary.set("collision_layer", 0)
	_legendary.set("collision_mask", 0)
	_legendary.set_physics_process(false)
	_cage = Node3D.new()
	_cage.name = "StormheartContainment"
	add_child(_cage)
	var cage_material := _glow(Color("8d78e8"), 2.4, 0.62)
	for i in 8:
		var bar := MeshInstance3D.new()
		bar.name = "ContainmentArc%02d" % i
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.07
		mesh.bottom_radius = 0.07
		mesh.height = 7.0
		mesh.radial_segments = 6
		bar.mesh = mesh
		var angle := TAU * float(i) / 8.0
		bar.position = Vector3(cos(angle) * 3.6, 3.5, sin(angle) * 3.6)
		bar.material_override = cage_material
		_cage.add_child(bar)


func _build_offer_prompt() -> void:
	_offer_prompt = INTERACTABLE.new()
	_offer_prompt.name = "StormheartOffer"
	_offer_prompt.position = Vector3(0.0, 1.4, 10.5)
	_offer_prompt.call("configure", "Accept the Stormheart's offer", OFFER_RADIUS_M, false)
	_offer_prompt.connect("activated", _on_offer)
	add_child(_offer_prompt)


func _build_waterward_view() -> void:
	_view_prompt = INTERACTABLE.new()
	_view_prompt.name = "WaterwardView"
	_view_prompt.position = Vector3(0.0, 1.4, 17.0)
	_view_prompt.call("configure", "Look beyond the broken storm", VIEW_RADIUS_M, false)
	_view_prompt.connect("activated", _on_waterward_view)
	add_child(_view_prompt)
	if bool(world.get("simulation_only")):
		return
	# The view remains a horizon and has no collision. The deliberate gate on
	# this same platform is built separately and stays sealed until this view
	# grants the one-time key.
	_waterward_sea = MeshInstance3D.new()
	_waterward_sea.name = "DistantWaterwardSea"
	var plane := PlaneMesh.new()
	plane.size = Vector2(2600.0, 1700.0)
	_waterward_sea.mesh = plane
	_waterward_sea.material_override = _glow(Color("2d8fa6"), 0.35, 0.92)
	world.add_child(_waterward_sea)
	_waterward_sea.global_position = Vector3(-100.0, 35.0, 6900.0)


func _build_water_gate() -> void:
	_water_gate = WATER_GATE.new()
	_water_gate.name = "WaterwardRealmGate"
	_water_gate.origin_realm = "stormwood"
	_water_gate.call("setup", "water", "water_arrival_from_stormwood",
		"Tidewake", WATER_GATE.WATER_KEY_FLAG, WATER_GATE.WATER_GATE_FLAG)
	world.add_child(_water_gate)
	var anchor: Dictionary = world.call("entry_anchor", "stormwood_departure_to_water")
	var position: Array = anchor.get("position", []) as Array
	if position.size() >= 3:
		_water_gate.global_position = Vector3(float(position[0]), float(position[1]), float(position[2]))
	if bool(world.get("simulation_only")):
		_water_gate.visible = false


func _make_legendary() -> RefCounted:
	var creature: RefCounted = TRAINER_NPC.creature_for({
		"species": LEGENDARY_SPECIES,
		"level": LEGENDARY_LEVEL,
	})
	if creature != null:
		creature.set("nickname", LEGENDARY_NAME)
	return creature


## The party holds this claim's own Stormheart (by its uid, so levelling or
## renaming it does not matter): its Yes landed before the host heard it.
func _party_holds_claim(party: RefCounted, claim: Dictionary) -> bool:
	var id := claim_id(claim)
	if party == null or id.is_empty():
		return false
	for creature: RefCounted in party.call("members"):
		if str(creature.get("uid")) == id:
			return true
	return false


func _start_dialogue_when_free(id: String) -> bool:
	if bool(world.get("simulation_only")):
		return false
	var panel := world.get_node_or_null("DialoguePanel")
	if panel == null or bool(panel.call("is_open")):
		return false
	return bool(panel.call("start", id))


func _character_for_peer(peer: int) -> String:
	var row: Dictionary = session.registry().row(peer)
	if row.is_empty() and peer == session.local_peer_id():
		return _local_character_id(get_node("/root/Game"))
	return str(row.get("character_id", ""))


## This peer's stable character id, or "" while `Game.local` is not set yet.
static func _local_character_id(game: Node) -> String:
	var local: Variant = game.get("local") if game != null else null
	if local is Object:
		return str((local as Object).get("character_id"))
	return ""


func _saved_state() -> Dictionary:
	var environment: Dictionary = get_node("/root/Game").get("realm_environment")
	var stormwood: Variant = environment.get("stormwood", {})
	if stormwood is Dictionary:
		var ending: Variant = (stormwood as Dictionary).get("ending", {})
		if ending is Dictionary:
			return migrate_state(ending as Dictionary)
	return {}


## The earlier single-recipient shape (`recipient_character_id` + one claim)
## becomes that character's entry in `claims`. Its participant list is unknown,
## so it is seeded with that recipient only.
static func migrate_state(saved: Dictionary) -> Dictionary:
	var state := saved.duplicate(true)
	var legacy := str(state.get("recipient_character_id", ""))
	if not legacy.is_empty():
		var claims: Dictionary = state.get("claims", {})
		if not claims.has(legacy):
			claims[legacy] = {"creature": state.get("creature", {}),
				"settled": bool(state.get("settled", false)), "kept": bool(state.get("kept", false))}
		state["claims"] = claims
		# The old shape proves only that its recipient fought; seeding it keeps
		# a character who never fought from claiming a fresh Stormheart.
		if not state.has("participants"):
			state["participants"] = [legacy]
		for key: String in ["recipient_character_id", "creature", "settled", "kept"]:
			state.erase(key)
	return state


## The unsettled claim waiting for `character`, or {} when there is none.
static func claim_for_character(state: Dictionary, character: String) -> Dictionary:
	if character.is_empty():
		return {}
	var claim: Variant = (state.get("claims", {}) as Dictionary).get(character, {})
	if claim is Dictionary and not (claim as Dictionary).is_empty() \
			and not bool((claim as Dictionary).get("settled", false)):
		return (claim as Dictionary).duplicate(true)
	return {}


func _store_state(state: Dictionary) -> void:
	var game := get_node("/root/Game")
	var environment: Dictionary = game.get("realm_environment")
	var stormwood: Dictionary = (environment.get("stormwood", {}) as Dictionary).duplicate(true)
	stormwood["ending"] = state.duplicate(true)
	environment["stormwood"] = stormwood
	game.set("realm_environment", environment)


func _save_world_claim() -> bool:
	var game := get_node("/root/Game")
	var saver: RefCounted = game.get("save_system")
	var world_state: RefCounted = game.get("world")
	if saver == null or world_state == null or str(world_state.get("world_id")).is_empty():
		return true
	var saved := bool(saver.call("save_world", game, str(world_state.get("world_id"))))
	if not saved:
		push_error("Stormwood ending could not persist the reserved legendary ceremony")
	return saved


func _send_claim(peer: int, character: String, claim: Dictionary) -> void:
	if bool(claim.get("settled", false)):
		return
	var payload := claim.duplicate(true)
	payload["recipient_character_id"] = character
	hub.call("send_to", peer, {"kind": "ending_offer", "claim": payload})


func _refuse(peer: int, reason: String) -> void:
	hub.call("send_to", peer, {"kind": "ending_refused", "reason": reason})


func _broadcast(event: Dictionary) -> void:
	for peer: int in session.peers_in_realm("stormwood"):
		hub.call("send_to", peer, event)
	if not session.is_active():
		hub.call("send_to", session.local_peer_id(), event)


func _state_event() -> Dictionary:
	return {
		"kind": "ending_state",
		"released": _has(FREED_FLAG),
		"offer_made": _has(OFFER_FLAG),
		"waterward_revealed": _has(WATERWARD_FLAG),
		"participants": published_participants(participants_for_claim(_saved_state(), _fallback_participants())),
	}


## Host, at the freeing: the characters who fought Marrow and struck the
## conduits. Recorded once with the world so reload and reconnect keep the
## same eligible set; peers become stable character ids here.
func _record_participants() -> void:
	var state := _saved_state()
	if state.has("participants"):
		return
	var dynamo := world.get_node_or_null("StormwoodDynamo")
	var peers: Array = []
	var characters: Array = []
	if dynamo != null:
		# Captured when each fighter joined, so a later disconnect cannot drop
		# them; live peers below cover a fighter added before this was recorded.
		for character: Variant in dynamo.get("fighter_characters"):
			if not str(character).is_empty() and not characters.has(str(character)):
				characters.append(str(character))
		# Contributors only: a Break arrival is an observer with no send-out
		# left to admit them (BOSSES §3), so proximity alone earns no offer.
		for peer: Variant in dynamo.get("contributors"):
			if not peers.has(int(peer)):
				peers.append(int(peer))
	for peer: int in peers:
		var character := _character_for_peer(peer)
		if not character.is_empty() and not characters.has(character):
			characters.append(character)
	state["participants"] = characters
	_store_state(state)
	_save_world_claim()


## Host: the once-only world receipt of one character's answer.
func _submit_resolution(accepted: bool, character: String) -> void:
	var flag := resolution_flag(accepted, character)
	if not _has(flag):
		LEDGER_CLAIM.submit(self, {"kind": "set_world_flag", "realm": "stormwood", "id": flag, "value": true})


static func resolution_flag(accepted: bool, character: String) -> String:
	return "%s%s:%s" % [RESOLUTION_PREFIX, "accepted" if accepted else "refused", character]


## This peer's own character may still answer the Stormheart: not while this
## world holds its answer, and not once it accepted a Stormheart anywhere
## (`accepted_anywhere()`, which reads an older build's bare receipt as Yes).
func _local_offer_owed(game: Node) -> bool:
	if game == null:
		return false
	var character := _local_character_id(game)
	var player_flags: RefCounted = game.call("player_flags")
	var resolved := accepted_anywhere(player_flags) \
		or _has(resolution_flag(true, character)) or _has(resolution_flag(false, character))
	var participants := _participants
	if session != null and session.is_host():
		participants = published_participants(participants_for_claim(_saved_state(), _fallback_participants()))
	return claim_allowed([FREED_FLAG], participants, character, resolved)


## Host: who is judged to have fought when the freeing recorded nobody (a save
## from before the list existed). First the Dynamo's own `fighter_characters`,
## from its persisted payload and its live node (stable character ids). Its
## `contributors` are peer ids from the session that fought and are not mapped:
## the current registry could name someone else entirely. Failing that, the
## world owner's own character is the best available guess; a real guest who
## fought on such a save is denied rather than letting anyone claim.
func _fallback_participants() -> Array:
	var payload := {"fighter_characters": []}
	var game := get_node_or_null("/root/Game")
	var environment: Variant = game.get("realm_environment") if game != null else null
	var stormwood: Variant = (environment as Dictionary).get("stormwood", {}) if environment is Dictionary else {}
	var saved: Variant = (stormwood as Dictionary).get("dynamo", {}) if stormwood is Dictionary else {}
	var dynamo := world.get_node_or_null("StormwoodDynamo") if world != null else null
	for source: Variant in [saved, dynamo]:
		if source == null or (source is Dictionary and (source as Dictionary).is_empty()):
			continue
		var raw: Variant = (source as Dictionary).get("fighter_characters", []) if source is Dictionary \
			else (source as Object).get("fighter_characters")
		if raw is Array:
			(payload.fighter_characters as Array).append_array(raw as Array)
	var host := _local_character_id(game) if session != null and session.is_host() else ""
	return fallback_participants(payload, host)


## Host: the world facts `offer_owed()` reads for `character`.
func _world_flags_for(character: String) -> Array:
	var flags: Array = []
	for flag: String in [FREED_FLAG, resolution_flag(true, character), resolution_flag(false, character)]:
		if _has(flag):
			flags.append(flag)
	return flags


func _has(flag: String) -> bool:
	var game := get_node_or_null("/root/Game")
	return game != null and game.get("progression") != null and bool(game.get("progression").call("has", flag))


func _glow(colour: Color, energy: float, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(colour, alpha)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	material.roughness = 0.42
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


## Pure policy helpers: tests pin the per-participant and chapter-order rules
## without needing a network peer or loading the world scene.
##
## An empty participant list is a solo freeing: the only player present may
## answer, as in the Meadows ending. The host never judges a claim against an
## empty list: `offer_owed()` owes nothing when neither a recorded list nor the
## host's fallback names anyone.
static func claim_allowed(flags: Array, participants: Array, character: String,
		already_resolved: bool) -> bool:
	if not flags.has(FREED_FLAG) or character.is_empty() or already_resolved:
		return false
	return participants.is_empty() or participants.has(character)


## The list the host publishes: never empty, which a client reads as a solo
## freeing anyone may answer.
static func published_participants(participants: Array) -> Array:
	return participants.duplicate() if not participants.is_empty() else [NO_KNOWN_PARTICIPANT]


## The participant list a claim is judged against. A recorded list is used as
## is. With none recorded (a save freed before the list existed) it is the
## host's `fallback` (`fallback_participants()`), never the claimant.
static func participants_for_claim(state: Dictionary, fallback: Array) -> Array:
	var recorded: Array = state.get("participants", [])
	if not recorded.is_empty():
		return recorded.duplicate()
	return fallback.duplicate()


## The fallback for a freeing that recorded no fighters, in order: (a) the
## Dynamo's `fighter_characters`; (b) failing that, the world owner's own
## character alone, the best available guess for a save that recorded nobody
## (a real guest fighter on such a save is denied). Empty only when neither is
## known. Contributor peer ids are deliberately not read (see
## `_fallback_participants()`).
static func fallback_participants(dynamo_payload: Dictionary, host_character: String) -> Array:
	var out: Array = []
	for raw: Variant in dynamo_payload.get("fighter_characters", []):
		if not str(raw).is_empty() and not out.has(str(raw)):
			out.append(str(raw))
	if out.is_empty() and not host_character.is_empty():
		out.append(host_character)
	return out


## Host decision for one claim, from the host's own state: the world's claims,
## its recorded participants (or `fallback` when none were recorded) and its
## per-character answer receipts in `world_flags`. `client_hint_accepted` is
## the requester's portable acceptance; it can only withhold a fresh creature
## and is ignored while this world already holds that character's unsettled
## claim (a resume). A refusal elsewhere is not a hint at all.
static func offer_owed(state: Dictionary, character: String, world_flags: Array,
		client_hint_accepted := false, fallback: Array = []) -> bool:
	var participants := participants_for_claim(state, fallback)
	if participants.is_empty():
		return false
	var claim: Variant = (state.get("claims", {}) as Dictionary).get(character, {})
	var existing: Dictionary = claim if claim is Dictionary else {}
	var resolved := bool(existing.get("settled", false)) \
		or world_flags.has(resolution_flag(true, character)) \
		or world_flags.has(resolution_flag(false, character)) \
		or (client_hint_accepted and existing.is_empty())
	return claim_allowed(world_flags, participants, character, resolved)


static func waterward_allowed(flags: Array) -> bool:
	return flags.has(OFFER_FLAG) and not flags.has(WATERWARD_FLAG)
