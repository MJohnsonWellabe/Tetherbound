extends Node

## Realm-local adapters, global Session transport. The host owns all trainer
## opponents even when its own player remains in another realm.
const HOSTED := preload("res://scripts/combat/stormwood_hosted_trainer.gd")
const AUTHORITY := preload("res://scripts/net/encounter_host.gd")
var world: Node3D
var session: Node
var director: Node
var authority := AUTHORITY.new()
var fights: Dictionary = {}
var _local_trainer := ""
var _local_record := ""
var _action := 0
var _pending_state: Dictionary = {}
var last_start_refusal: Dictionary = {}
## A reliable state already in flight may still include a departed participant.
## Keep that trainer retired locally until the player explicitly challenges anew.
var _withdrawn_trainers: Dictionary = {}

func mount(owner_world: Node3D) -> void:
	world = owner_world
	director = world.get_node("EncounterDirector")
	# Existing realm safety checks (including arch travel) see these fights too.
	director.set("_encounter_host", authority)
	session = get_node("/root/Game/Session")
	add_to_group("stormwood_encounter_hub")
	session.stormwood_encounter_message.connect(_receive)
	if not bool(world.get("simulation_only")):
		session.request_stormwood_encounter({"kind": "snapshot"})

func request_start(id: String) -> void:
	last_start_refusal.clear()
	_withdrawn_trainers.erase(id)
	session.request_stormwood_encounter({"kind": "start", "trainer_id": id})


func on_finalized_death() -> void:
	var id := _local_trainer
	if id.is_empty():
		id = str(_pending_state.get("trainer_id", ""))
	if id.is_empty() or _withdrawn_trainers.has(id):
		return
	var record_id := _local_record
	_withdrawn_trainers[id] = true
	_retire_local_trainer(id)
	# Self-only withdrawal is routed through the same authority even for solo.
	# Do not use ordinary disengage: a done round is not roster withdrawal.
	session.request_stormwood_encounter({"kind": "finalized_death_withdrawal",
		"trainer_id": id, "encounter_id": record_id})


func _retire_local_trainer(id: String) -> void:
	if _local_trainer != id and str(_pending_state.get("trainer_id", "")) != id:
		return
	_pending_state.clear()
	if _local_trainer == id:
		world.get_node("CombatManager").call("abort_for_finalized_death")
	director.end_hosted_trainer(false)
	director.remove_hosted_observer(id)
	_local_trainer = ""
	_local_record = ""

func _refuse_start(peer: int, id: String, reason: String) -> void:
	send_to(peer, {"kind": "start_refused", "trainer_id": id, "reason": reason})

func dispatch(peer: int, intent: Dictionary) -> void:
	if not session.is_host() or session.realm_of(peer) != "stormwood":
		return
	var kind := str(intent.get("kind", ""))
	if kind == "snapshot":
		for fight: Node in fights.values():
			if not fight.finished:
				send_to(peer, fight.snapshot())
		var dynamo := world.get_node_or_null("StormwoodDynamo")
		if dynamo != null:
			dynamo.call("send_snapshot", peer)
		var ending := world.get_node_or_null("StormwoodEnding")
		if ending != null:
			ending.call("send_snapshot", peer)
		return
	var id := str(intent.get("trainer_id", ""))
	if kind == "start":
		_start_for(peer, id)
		return
	if kind.begins_with("dynamo_"):
		var dynamo := world.get_node_or_null("StormwoodDynamo")
		if dynamo != null:
			dynamo.call("dispatch", peer, intent)
		return
	if kind.begins_with("ending_"):
		var ending := world.get_node_or_null("StormwoodEnding")
		if ending != null:
			ending.call("dispatch", peer, intent)
		return
	var fight: Node = fights.get(id)
	if not is_instance_valid(fight):
		return
	match kind:
		"finalized_death_withdrawal":
			# The authenticated sender is the only removable participant. The
			# current roster membership, not an old round id/phase, owns this
			# decision so final death also works during the between-round gap.
			if fight.participants.has(peer):
				fight.leave(peer)
			send_to(peer, {"kind": "withdrawn", "trainer_id": id,
				"encounter_id": str(intent.get("encounter_id", ""))})
		"strike_intent":
			var verdict: Dictionary = fight.strike(peer, intent)
			send_to(peer, {"kind": "verdict", "trainer_id": id, "encounter_id": intent.get("encounter_id", ""), "verdict": verdict})
		"disengage":
			# A completed round is not withdrawal from the trainer's roster.
			if str(intent.get("encounter_id", "")) == str(fight.record.get("encounter_id", "")) and str(authority.record(str(intent.encounter_id)).get("phase", "")) != "done":
				fight.leave(peer)

func _start_for(peer: int, id: String) -> void:
	var cast := world.get_node("StormwoodTrainers")
	var spec: Dictionary = cast.authored_specs.get(id, {})
	var trainer: Node3D = cast.body_for(id)
	var actor := actor_for(peer)
	if spec.is_empty() or not is_instance_valid(trainer) or not is_instance_valid(actor) or not is_instance_valid(body_for(peer)):
		_refuse_start(peer, id, "missing_trainer_or_deployment")
		return
	if actor.global_position.distance_to(trainer.global_position) > 12.0:
		_refuse_start(peer, id, "too_far")
		return
	if float(card_for(peer).get("hp", 0.0)) <= 0.0:
		_refuse_start(peer, id, "no_healthy_deployment")
		return
	var flags: RefCounted = get_node("/root/Game").get("progression")
	if flags.has(str(spec.get("defeat_flag", ""))):
		_refuse_start(peer, id, "already_defeated")
		return
	for flag: String in spec.get("requires_flags", []):
		if not flags.has(flag):
			_refuse_start(peer, id, "missing_prerequisite")
			return
	# The climax must explicitly register its controller before admitting Marrow.
	if id == "captain_marrow_dynamo_core":
		var dynamo := world.get_node_or_null("StormwoodDynamo")
		if dynamo == null or not dynamo.has_method("begin_for_peer"):
			_refuse_start(peer, id, "dynamo_unavailable")
			return
		dynamo.begin_for_peer(peer)
		return
	for active: Node in fights.values():
		if not active.finished and active.participants.has(peer) and str(active.spec.id) != id:
			_refuse_start(peer, id, "already_fighting")
			return
	var fight: Node = fights.get(id)
	if is_instance_valid(fight) and not fight.finished:
		fight.join(peer)
		return
	if is_instance_valid(fight):
		fight.queue_free()
	fight = HOSTED.new()
	fight.name = "Trainer_%s" % id
	add_child(fight)
	fights[id] = fight
	var toward := actor.global_position - trainer.global_position
	toward.y = 0.0
	var at := trainer.global_position + toward.normalized() * 4.0
	if not fight.start(self, spec, peer, at):
		_refuse_start(peer, id, "opponent_unavailable")
		fights.erase(id)
		fight.queue_free()

func publish(fight: Node, event: Dictionary) -> void:
	var message := event.duplicate(true)
	message["trainer_id"] = str(fight.spec.id)
	message["encounter_id"] = str(fight.record.get("encounter_id", ""))
	for peer: int in session.peers_in_realm("stormwood"):
		send_to(peer, message)
	if not session.is_active():
		send_to(session.local_peer_id(), message)

func send_to(peer: int, event: Dictionary) -> void:
	session.send_stormwood_encounter(peer, event)


func register_fight(id: String, hosted_fight: Node) -> void:
	fights[id] = hosted_fight


func forget_fight(id: String, hosted_fight: Node) -> void:
	if fights.get(id) == hosted_fight:
		fights.erase(id)

func trainer_finished(fight: Node, won: bool) -> void:
	if str(fight.spec.get("id", "")) == "captain_marrow_dynamo_core":
		var dynamo := world.get_node_or_null("StormwoodDynamo")
		if dynamo != null:
			dynamo.call("captain_team_finished", fight, won)
		return
	if won:
		director.award_hosted_trainer(fight.spec, fight.contributors)
		var event := chapter_event_for_trainer(str(fight.spec.get("id", "")))
		if not event.is_empty():
			world.get_node("StormwoodChapter").call("emit_event", event)


static func chapter_event_for_trainer(id: String) -> String:
	return str({
		"lieutenant_varga_rodline_bridge": "trainer:varga_defeated",
		"officer_kestrel_outer_works": "trainer:kestrel_defeated",
	}.get(id, ""))

func actor_for(peer: int) -> Node3D:
	return (world.get_node("StormwoodLightning").call("_actors") as Dictionary).get(peer)

func body_for(peer: int) -> Node3D:
	return director.deployed_body_for(peer)

func card_for(peer: int) -> Dictionary:
	return director.call("_creature_card_for", peer)

func body_rows() -> Array:
	return director.call("_encounter_body_rows")

func body_radius(body: Node3D) -> float:
	return float(body.call("body_radius")) if body.has_method("body_radius") else 0.5

func _receive(event: Dictionary) -> void:
	if bool(world.get("simulation_only")):
		return
	var kind := str(event.get("kind", ""))
	var id := str(event.get("trainer_id", ""))
	if kind == "withdrawn":
		# Local final-death handling already releases control before the RPC.
		# Never let an old acknowledgement abort a later explicit challenge.
		if _withdrawn_trainers.has(id):
			_retire_local_trainer(id)
		return
	if kind.begins_with("dynamo_"):
		var dynamo := world.get_node_or_null("StormwoodDynamo")
		if dynamo != null:
			dynamo.call("receive", event)
		return
	if kind.begins_with("ending_"):
		var ending := world.get_node_or_null("StormwoodEnding")
		if ending != null:
			ending.call("receive", event)
		return
	if kind == "start_refused":
		last_start_refusal = event.duplicate(true)
		var messages := {
			"missing_trainer_or_deployment": "Bring your companion close before challenging.",
			"too_far": "Move closer to the trainer to challenge.",
			"no_healthy_deployment": "Your companion needs to recover before this battle.",
			"already_defeated": "You have already won this battle.",
			"missing_prerequisite": "There is more to do before this challenge.",
			"dynamo_unavailable": "The Dynamo Core is not ready for your challenge.",
			"dynamo_not_ready": "Disable the rods, defeat Kestrel and reach the Dynamo Core first.",
			"already_fighting": "Finish your current battle first.",
			"opponent_unavailable": "This opponent is not available right now.",
		}
		get_node("/root/Game").push_world_message(str(messages.get(str(event.get("reason", "")), "This challenge is not available right now.")))
		return
	var manager := world.get_node("CombatManager")
	if kind == "state":
		if _withdrawn_trainers.has(id):
			return
		if not (event.get("participants", []) as Array).has(session.local_peer_id()):
			director.observe_hosted_state(event)
			return
		_pending_state = event.duplicate(true)
		_apply_state()
		return
	if kind == "finished":
		director.remove_hosted_observer(id)
	if id != _local_trainer or str(event.get("encounter_id", "")) != _local_record:
		director.observe_hosted_event(id, event)
		return
	match kind:
		"verdict":
			var verdict: Dictionary = event.verdict
			if bool(verdict.get("ok", false)):
				manager.apply_host_strike_verdict(verdict.get("delta", {}))
			else:
				manager.note_encounter_refusal(verdict)
		"enemy_hit":
			manager.apply_host_enemy_hit(event.payload)
		"telegraph":
			director.hosted_telegraph(float(event.seconds))
		"swing":
			director.hosted_swing()
		"finished":
			_pending_state.clear()
			director.end_hosted_trainer(bool(event.get("won", false)))
			_local_trainer = ""
			_local_record = ""

func _process(_delta: float) -> void:
	if not _pending_state.is_empty():
		_apply_state()

func _apply_state() -> void:
	if _withdrawn_trainers.has(str(_pending_state.get("trainer_id", ""))):
		_pending_state.clear()
		return
	var manager := world.get_node("CombatManager")
	var incoming: Dictionary = _pending_state.get("record", {})
	var incoming_id := str(incoming.get("encounter_id", ""))
	if incoming_id.is_empty():
		return
	if incoming_id != _local_record:
		if manager.is_fighting():
			# The request was issued while idle, but a local aggressive wild can
			# begin combat before the host-owned trainer state makes the round
			# trip.  Host admission wins that race.  Only a fleeable wild may be
			# yielded; a trainer fight remains protected by CombatManager.
			if not manager.yield_wild_fight_for_hosted_trainer():
				return
		if str(incoming.get("phase", "")) == "done":
			_pending_state.clear()
			return
		if not director.begin_hosted_round(self, _pending_state):
			return
		_local_trainer = str(_pending_state.trainer_id)
		_local_record = incoming_id
		_action = 0
	director.update_hosted_opponent(_pending_state)
	manager.apply_encounter_record(incoming)
	_pending_state.clear()

func submit_encounter_intent(intent: Dictionary) -> Dictionary:
	var request := intent.duplicate(true)
	request["trainer_id"] = _local_trainer
	_action += 1
	request["action"] = _action
	session.request_stormwood_encounter(request)
	return {"ok": false, "pending": true, "kind": str(intent.get("kind", "")), "delta": {}}

func is_encounter_host() -> bool:
	return false

func hosted_transport() -> bool:
	return true

func local_encounter_peer_id() -> int:
	return session.local_peer_id()
