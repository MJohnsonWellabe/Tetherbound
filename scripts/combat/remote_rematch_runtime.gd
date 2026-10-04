extends Node

## One guest-initiated rematch. EncounterHost remains the sole combat authority;
## SharedWildHostFight supplies its ordinary enemy simulation. This node only
## sequences the authored roster and retains the accepted final action until
## LedgerRpc saves the existing rematch_win/bounty_event obligations.
## No RPC, player manager, portable-state writer or second reward journal.
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const HIT_FEEDBACK := preload("res://scripts/combat/hit_feedback.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")

var encounter_id := ""
var _director: Node
var _session: Node
var _host: RefCounted
var _source_context := Callable()
var _source: WeakRef
var _world: WeakRef
var _epoch := ""
var _namespace := ""
var _spec: Dictionary = {}
var _cards: Array[RefCounted] = []
var _admissions: Dictionary = {}
var _master_binding: Dictionary = {}
var _master_uid := ""
var _round := 0
var _runtime: Node
var _centre := Vector3.ZERO
var _spot := Vector3.ZERO
var _radius := 0.0
var _witness: Dictionary = {}
var _frozen: Dictionary = {}
var _durable := false
var _ended := false
var _earned_final := false
var _next_round_left := -1.0
var _retry_left := 0.0
var _scaling_state: Dictionary = {}
var _dispose_requested := false

## The closure is FoundationRematches' HOST source resolver, bound to this
## director. It receives (authenticated_peer, trainer_id, actual_source).
## It must return canonical_spec, character_id, in_range and actual grounded
## arena_centre/opponent_spot/arena_radius_m. None are accepted from a packet.
func bind_director(director: Node, source_context: Callable) -> bool:
	if not encounter_id.is_empty() or not is_instance_valid(director) or not source_context.is_valid(): return false
	var session: Node = director.get("_session")
	if session == null or session.call("is_host") != true or director.get_script() == null \
		or not session.FOUNDATION_DIRECTORS.has(director.get_script().resource_path): return false
	_director = director
	_session = session
	director.call("_ensure_encounter_arbiters")
	_host = director.get("_encounter_host")
	_source_context = source_context
	return _host != null and _host.has_method("move_action_original")

func start(peer: int, source: Node3D, trainer: String, tier: String, selected_uid: String = "") -> Dictionary:
	if not encounter_id.is_empty() or not _live_host() or RULES.config().get("runtime_enabled") != true \
		or MATH.config().get("actor_vitals", {}).get("runtime_enabled") != true \
		or peer == int(_session.call("local_peer_id")) or _session.call("_altar_peer_in_combat", peer) == true or not is_instance_valid(source) \
		or not source.is_inside_tree() or not _director.get_parent().is_ancestor_of(source): return _deny("actual_remote_rematch_required")
	var raw: Variant = _source_context.call(peer, trainer, source)
	if not raw is Dictionary: return _deny("registered_rematch_source_required")
	var context: Dictionary = raw
	var character: String = str(_session.call("_authority_character", peer))
	if character.is_empty() or context.get("character_id") != character or context.get("in_range") != true \
		or context.get("canonical_spec") != source.get_meta("foundation_trainer_spec", {}) \
		or context.get("canonical_spec", {}).get("id") != trainer: return _deny("registered_rematch_source_required")
	var admission: Dictionary = _session.call("foundation_rematch_participant_context", peer)
	if admission.get("character_id") != character or not RULES.available(trainer, tier,
		admission.get("world_flags", []), admission.get("personal_flags", [])): return _deny("rematch_tier_locked")
	_spec = RULES.encounter_spec(context.canonical_spec, tier)
	if _spec.is_empty() or not arena_valid(context): return _deny("actual_rematch_arena_required")
	if RULES.profile(trainer).kind == "master" and selected_uid.is_empty(): return _deny("choose_one_conscious_owned_creature")
	var actor := _actor(peer, selected_uid)
	if actor.is_empty(): return _deny("actual_conscious_owned_actor_required")
	var trainers: Script = load("res://scripts/world/trainer_npc.gd")
	_cards.clear()
	for member: Dictionary in _spec.team:
		var card: RefCounted = trainers.call("creature_for", member)
		if card == null: return _deny("canonical_trainer_roster_required")
		_cards.append(card)
	_source = weakref(source)
	var world: RefCounted = _session.call("_game").get("world")
	_world = weakref(world)
	_epoch = str(_session.call("_altar_current_epoch"))
	_namespace = str(world.get("reward_delivery_namespace"))
	_centre = context.arena_centre
	_spot = context.opponent_spot
	_radius = float(context.arena_radius_m)
	_master_uid = ""
	if RULES.profile(trainer).kind == "master": _master_uid = str(actor.owned.uid)
	var body := _make_body(actor)
	if body == null: return _deny("supported_rematch_arena_required")
	var record: Dictionary = _host.call("open", peer, _director.call("_encounter_realm"), "trainer",
		_opponent(body), str(actor.owned.uid), character)
	encounter_id = str(record.get("encounter_id", ""))
	if encounter_id.is_empty() or not _bind_participant(peer, actor, admission):
		if not encounter_id.is_empty():
			_host.call("set_phase", encounter_id, "done")
			_host.call("forget", encounter_id)
		body.queue_free()
		return _deny("actual_rematch_actor_required")
	if not _master_uid.is_empty():
		_master_binding = _director.call("_strike_actor_binding", encounter_id, peer, actor.body)
		if _master_binding.is_empty():
			_host.call("close", encounter_id)
			body.queue_free()
			return _deny("actual_rematch_actor_required")
	_install_round(body, actor.body)
	return {"ok": true, "resolved": false, "encounter_id": encounter_id, "record": record.duplicate(true)}

static func arena_valid(context: Dictionary) -> bool:
	return context.get("arena_centre") is Vector3 and context.arena_centre.is_finite() \
		and context.get("opponent_spot") is Vector3 and context.opponent_spot.is_finite() \
		and (context.get("arena_radius_m") is float or context.get("arena_radius_m") is int) \
		and is_finite(float(context.arena_radius_m)) and float(context.arena_radius_m) > 0.0 \
		and context.arena_centre.distance_to(context.opponent_spot) < float(context.arena_radius_m)

func owns(id: String) -> bool:
	return not encounter_id.is_empty() and id == encounter_id

func spec() -> Dictionary:
	return _spec.duplicate(true)

func source() -> Node3D:
	return _source.get_ref() as Node3D if _source != null else null

## Existing engage dispatch delegates only this encounter to join(). Master
## duels stay one-on-one. Ordinary rematches admit each actual deployed owner,
## preserve the same encounter id and freeze that character's own tier flags.
func join(peer: int) -> Dictionary:
	if not _world_current() or _ended or not _master_uid.is_empty() or not _witness.is_empty(): return _deny("rematch_join_unavailable")
	var actor := _actor(peer)
	var admission: Dictionary = _session.call("foundation_rematch_participant_context", peer)
	if actor.is_empty() or actor.trainer.global_position.distance_to(_centre) > _radius \
		or admission.get("character_id") != actor.get("character_id") \
		or not RULES.available(_spec.id, _spec.rematch.tier, admission.get("world_flags", []), admission.get("personal_flags", [])):
		return _deny("actual_eligible_rematch_participant_required")
	if not _admissions.has(actor.character_id) and _admissions.size() >= 4: return _deny("rematch_party_full")
	var record: Dictionary = _host.call("record", encounter_id)
	if not record.get("participants", {}).has(peer) and record.get("participants", {}).size() >= 4: return _deny("rematch_party_full")
	var was_present: bool = record.get("participants", {}).has(peer)
	if not was_present and _session.call("_altar_peer_in_combat", peer) == true: return _deny("participant_already_fighting")
	var result: Dictionary = _host.call("join", encounter_id, peer, str(actor.owned.uid), str(actor.character_id))
	if result.get("ok") != true: return result
	if not _bind_participant(peer, actor, admission):
		if not was_present: _host.call("leave", encounter_id, peer)
		return _deny("actual_rematch_actor_required")
	_director.call("_host_after_encounter_change", encounter_id)
	return result

## Called by the director's ordinary authority checks. A normal rematch may
## switch among current admitted owned creatures; a Master pins one lifetime.
func actor_current(peer: int) -> bool:
	if not _world_current() or _ended: return false
	var record: Dictionary = _host.call("record", encounter_id)
	var participant: Dictionary = record.get("participants", {}).get(peer, {})
	var actor := _actor(peer, _master_uid)
	if actor.is_empty() or participant.get("character_id") != actor.get("character_id") \
		or not _admissions.has(actor.character_id): return false
	if not _master_uid.is_empty():
		return record.participants.size() == 1 and _director.call("_strike_actor_binding_matches", encounter_id, peer, actor.body, _master_binding) == true
	return true

## Called after the EXISTING damage writer recorded its actual accepted action,
## before publishing the terminal record. A client victory statement, stale
## projectile or HP-only reconstruction can never create this witness.
func capture_kill(peer: int, action_id: String, launch: Dictionary, verdict: Dictionary) -> bool:
	if not _witness.is_empty() or not actor_current(peer) or _runtime == null: return false
	var body: Node3D = _runtime.call("body")
	var card: RefCounted = body.get("instance") if is_instance_valid(body) else null
	var original: Dictionary = _host.call("move_action_original", encounter_id, peer, action_id)
	var record: Dictionary = _host.call("record", encounter_id)
	if card == null or float(card.get("hp")) != 0.0 \
		or not HIT_FEEDBACK.launch_matches(launch, encounter_id, str(launch.get("attacker_binding", {}).get("creature_uid", "")), str(card.get("uid")), _round + 1) \
		or not accepted_terminal_matches(original,
		encounter_id, peer, action_id, str(card.get("uid")), _round + 1, launch.get("attacker_binding", {}), verdict) \
		or record.get("opponent", {}).get("card", {}).get("uid") != card.get("uid") \
		or float(record.get("opponent", {}).get("hp", 1)) != 0.0: return false
	_witness = {"peer": peer, "action_id": action_id, "admission": original.admission.duplicate(true),
		"outcome": original.outcome.duplicate(true), "body": weakref(body), "generation": _round + 1}
	return true

static func accepted_terminal_matches(original: Dictionary, id: String, peer: int, action_id: String,
		target_uid: String, generation: int, binding: Dictionary, verdict: Dictionary) -> bool:
	var admission: Dictionary = original.get("admission", {})
	var outcome: Dictionary = original.get("outcome", {})
	return original.get("phase") in ["body_publication_pending", "published"] and not action_id.is_empty() \
		and admission.get("encounter_id") == id and admission.get("peer_id") == peer \
		and admission.get("action_id") == action_id and admission.get("target_uid") == target_uid \
		and admission.get("target_generation") == generation and generation > 0 \
		and not binding.is_empty() and admission.get("binding") == binding \
		and outcome.get("action_id") == action_id and outcome.get("verdict") == verdict \
		and verdict.get("ok") == true and verdict.get("delta", {}).get("killed") == true \
		and outcome.get("rolled", {}).get("killed") == true \
		and float(outcome.get("target_hp_before", 0)) > 0.0 \
		and float(outcome.get("target_hp_after", 1)) == 0.0 and float(verdict.get("delta", {}).get("hp", 1)) == 0.0

## Finalize hook replaces only the generic wild-ecology branch for this id.
## Publication must have completed before another round replaces its body.
func round_finished() -> bool:
	if not _world_current() or _witness.is_empty() or _runtime == null or _ended: return false
	var original: Dictionary = _host.call("move_action_original", encounter_id, int(_witness.peer), str(_witness.action_id))
	if original.get("phase") != "published" or original.get("admission") != _witness.admission \
		or original.get("outcome") != _witness.outcome or _witness.body.get_ref() != _runtime.call("body"): return false
	if _runtime.call("mark_terminal", "won") != true: return false
	_runtime.call("body").call("notify_fainted")
	if _round + 1 < _cards.size():
		var trainers: Script = load("res://scripts/world/trainer_npc.gd")
		_next_round_left = maxf(0.0, float(trainers.call("flow").get("send_out_seconds", 1.6)))
	else:
		_ended = true
		_earned_final = true
		_retry_save()
	return true

## The same typed duties as the local rematch path, consumed by Foundation's
## existing journal. The regional profile owns bounty identity even when a
## boss visits Halda's lawn; its physical combat record still says Meadows.
static func outcome_obligations(spec_row: Dictionary, id: String, namespace_id: String, epoch: String,
		seconds: int, admissions: Dictionary, master_uid: String = "") -> Dictionary:
	var profile := RULES.profile(str(spec_row.get("id", "")))
	if profile.is_empty() or id.is_empty() or namespace_id.is_empty() or epoch.is_empty() or seconds < 0 \
		or admissions.is_empty() or admissions.size() > 4 or not spec_row.get("rematch") is Dictionary \
		or spec_row.rematch.get("tier") not in ["r1", "endgame"]: return {}
	if profile.kind == "master" and (admissions.size() != 1 or master_uid.is_empty()): return {}
	var participants: Array[String] = []
	for character: String in admissions:
		var admission: Variant = admissions[character]
		if not admission is Dictionary or admission.get("character_id") != character \
			or not RULES.available(spec_row.id, spec_row.rematch.tier, admission.get("world_flags", []), admission.get("personal_flags", [])): return {}
		participants.append(character)
	participants.sort()
	var source_id := "rematch:%s:%s" % [spec_row.id, id]
	var duties: Array[Dictionary] = []
	for character: String in participants:
		var admission: Dictionary = admissions[character]
		var context := {"source_key": "rematch:" + str(spec_row.id), "validated_host_outcome": "win",
			"encounter_id": id, "trainer_id": str(spec_row.id), "tier": str(spec_row.rematch.tier), "participants": participants.duplicate(),
			"world_namespace": namespace_id, "session_id": epoch, "world_seconds": seconds,
			"world_flags": admission.world_flags.duplicate(), "personal_flags": admission.personal_flags.duplicate()}
		if profile.kind == "master":
			context.single_creature_duel = true
			context.creature_uid = master_uid
		duties.append({"character_id": character, "action": "rematch_win",
			"intent": {"trainer_id": str(spec_row.id), "tier": str(spec_row.rematch.tier), "encounter_id": id}, "context": context})
		if not admission.get("bounty_instances", []).is_empty():
			duties.append({"character_id": character, "action": "bounty_event", "intent": {}, "context": {
				"source_key": "halda_bounty_event", "event_confirmed": true, "world_namespace": namespace_id,
				"session_id": epoch, "event_id": source_id, "participants": participants.duplicate(),
				"issued_instances": admission.bounty_instances.duplicate(), "kind": "rematch", "biome": profile.biome, "traits": []}})
	return {"source_id": source_id, "duties": duties}

func retained_outcome() -> Dictionary:
	return _frozen.duplicate(true)

func settlement_complete() -> bool:
	return not _earned_final or _durable

func _process(delta: float) -> void:
	if encounter_id.is_empty() or not _world_current(): return
	if _earned_final and not _durable:
		_retry_left -= delta
		if _retry_left <= 0.0: _retry_save()
		return
	if not _ended:
		var current: Dictionary = _host.call("record", encounter_id)
		var peers: Array = current.get("participants", {}).keys()
		if peers.is_empty() or (not _master_uid.is_empty() and (peers.size() != 1 or not actor_current(int(peers[0])))):
			cancel()
			return
	if _next_round_left < 0.0 or _ended: return
	_next_round_left -= delta
	if _next_round_left > 0.0: return
	_next_round_left = -1.0
	var record: Dictionary = _host.call("record", encounter_id)
	var actor: Dictionary = {}
	for peer: int in record.get("participants", {}):
		if actor_current(peer):
			actor = _actor(peer, _master_uid)
			break
	if actor.is_empty():
		cancel()
		return
	_round += 1
	var body := _make_body(actor)
	if body == null:
		cancel()
		return
	if not advance_record(_host, encounter_id, str(_witness.admission.target_uid), int(_witness.generation), _opponent(body)):
		body.queue_free()
		cancel()
		return
	_dispose_round()
	_witness.clear()
	_install_round(body, actor.body)
	_director.call("_host_after_encounter_change", encounter_id)

## Resume the existing authority only after its killing publication settled.
## set_opponent preserves participants and their vitals while invalidating the
## previous target's action lifecycle. A replay cannot skip a roster round.
static func advance_record(host: RefCounted, id: String, prior_uid: String, prior_generation: int, opponent: Dictionary) -> bool:
	if host == null or not host.has_method("move_action_publication_pending") \
		or host.call("move_action_publication_pending", id) == true: return false
	var record: Dictionary = host.call("record", id)
	var previous: Dictionary = record.get("opponent", {})
	if record.get("phase") != "done" or record.get("participants", {}).is_empty() \
		or previous.get("card", {}).get("uid") != prior_uid or previous.get("body_generation") != prior_generation \
		or previous.get("round_continues") != true or float(previous.get("hp", 1)) != 0.0 \
		or opponent.get("body_generation") != prior_generation + 1 or opponent.get("round") != int(previous.get("round", 0)) + 1 \
		or opponent.get("owner_npc") != previous.get("owner_npc") or str(opponent.get("card", {}).get("uid", "")).is_empty() \
		or float(opponent.get("hp", 0)) <= 0.0: return false
	host.call("set_phase", id, "active")
	if host.call("set_opponent", id, opponent) == true: return true
	host.call("set_phase", id, "done")
	return false

func _retry_save() -> void:
	if not _earned_final or _durable or not _world_current(): return
	_retry_left = 1.0
	var world: RefCounted = _world.get_ref()
	if _frozen.is_empty():
		var game: Node = _session.call("_game")
		game.call("_sync_clock_state")
		var seconds := float(world.get("clock_elapsed_seconds"))
		if not is_finite(seconds) or seconds < 0.0: return
		_frozen = outcome_obligations(_spec, encounter_id, _namespace, _epoch, int(floor(seconds)), _admissions, _master_uid)
		if _frozen.is_empty(): return
	if EVENT.make(world, _epoch, _frozen.source_id, _frozen.duties).is_empty(): return
	var writer := _session.get_node_or_null(^"LedgerRpc")
	if writer == null: return
	var result: Dictionary = writer.call("journal_foundation_event", _frozen.source_id, _frozen.duties.duplicate(true))
	# The world carrier now owns subsequent owner-save/ACK retries. This does
	# not label those later receipts resolved or locally award any resources.
	_durable = result.get("ok") == true and result.get("durable") == true
	if _durable and _dispose_requested: _director.call("_dispose_shared_host_fight", encounter_id, false)

func cancel() -> bool:
	if not settlement_complete(): return false
	_ended = true
	_next_round_left = -1.0
	_witness.clear()
	if is_instance_valid(_runtime): _runtime.call("mark_terminal", "lost")
	if _host != null and not encounter_id.is_empty():
		_host.call("close", encounter_id)
		if is_instance_valid(_director): _director.call("_host_after_encounter_change", encounter_id)
	return true

## Director's ordinary disposal delegates here, before its wild ecology path.
## An earned but unsaved final terminal keeps this exact body and witness.
func dispose() -> bool:
	if not settlement_complete():
		_dispose_requested = true
		return false
	if not _ended and not cancel(): return false
	_dispose_round()
	queue_free()
	return true

func _live_host() -> bool:
	if not is_instance_valid(_director) or not is_instance_valid(_session) or _host == null \
		or _session.call("is_host") != true or _director.get("_session") != _session \
		or _director.get("_encounter_host") != _host: return false
	var game: Node = _session.call("_game")
	return game != null and game.get("session") == _session

func _world_current() -> bool:
	return _live_host() and _world != null and _world.get_ref() == _session.call("_game").get("world") \
		and _epoch == _session.call("_altar_current_epoch") \
		and _namespace == _world.get_ref().get("reward_delivery_namespace")

func _actor(peer: int, uid: String = "") -> Dictionary:
	if not _live_host(): return {}
	var character: String = str(_session.call("_authority_character", peer))
	var lifecycle := _session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
	var local_peer: bool = peer == int(_session.call("local_peer_id"))
	var safety: Dictionary = (lifecycle.call("local_sample") if local_peer else lifecycle.call("host_context", peer)) if lifecycle != null else {}
	var trainer: Node3D = _session.call("_game").call("find_player") if peer == int(_session.call("local_peer_id")) \
		else lifecycle.call("remote_body", peer) if lifecycle != null else null
	var body: Node3D = _director.call("deployed_body_for", peer)
	var deployed: Dictionary = _director.call("_creature_card_for", peer)
	var chosen: String = str(deployed.get("creature_uid", ""))
	if character.is_empty() or chosen.is_empty() or (not uid.is_empty() and uid != chosen) \
		or trainer == null or body == null or not trainer.is_inside_tree() or not body.is_inside_tree() \
		or not _director.get_parent().is_ancestor_of(trainer) or not _director.get_parent().is_ancestor_of(body) \
		or safety.is_empty() or safety.get("realm") != _director.call("_encounter_realm") \
		or safety.get("downed") == true or safety.get("swimming") == true or safety.get("flying") == true: return {}
	var admitted: Dictionary = _session.call("admitted_character_state", peer)
	var owned: Dictionary = {}
	for card: Dictionary in admitted.get("party", []):
		if card.get("uid") != chosen: continue
		if not owned.is_empty(): return {}
		owned = card
	if owned.is_empty() or owned.get("fainted") != false or float(owned.get("hp", 0)) <= 0.0: return {}
	if peer == int(_session.call("local_peer_id")):
		var ally: RefCounted = _director.get("_ally")
		if body != _director.get("_ally_body") or ally == null or ally.get("uid") != chosen: return {}
	elif _director.call("guest_master_actor_matches", body, peer, character, chosen, owned, deployed) != true: return {}
	return {"character_id": character, "trainer": trainer, "body": body, "owned": owned}

func _bind_participant(peer: int, actor: Dictionary, admission: Dictionary) -> bool:
	var result: Dictionary = _host.call("bind_actor_body", encounter_id, peer, actor.character_id, actor.owned, actor.body.get_instance_id())
	if result.get("ok") != true: return false
	if not _admissions.has(actor.character_id): _admissions[actor.character_id] = admission.duplicate(true)
	_director.call("_freeze_bounty_instances", encounter_id, peer)
	return true

func _make_body(actor: Dictionary) -> Node3D:
	var scene: PackedScene = load("res://scenes/creatures/creature.tscn")
	var body: Node3D = scene.instantiate()
	body.set_script(load("res://scripts/creatures/wild_creature.gd"))
	body.name = "RemoteRematch_%s_%d" % [str(_spec.id), _round + 1]
	_director.get_parent().add_child(body)
	var creature := _cards[_round]
	body.call("populate", str(creature.get("species_id")), actor.trainer)
	body.set("instance", creature)
	body.set("combat_override", creature.get("combat_override"))
	body.set("trainer_owned", true)
	body.set("aggressive", false)
	body.call("configure", MATH.config().get("wild", {}))
	if body.call("place_on_ground", _spot) != true or body.global_position.distance_to(_centre) >= _radius:
		body.queue_free()
		return null
	body.set("home", body.global_position)
	body.call("face_towards", actor.body.global_position)
	return body

func _opponent(body: Node3D) -> Dictionary:
	var creature: RefCounted = body.get("instance")
	var p := body.global_position
	var f: Vector3 = body.call("facing")
	return {"species_id": creature.get("species_id"), "name": str(_spec.get("name", _spec.get("display_name", _spec.id))),
		"level": creature.get("level"), "hp": creature.get("hp"), "hp_max": creature.get("max_hp"),
		"owner_npc": _spec.id, "card": CODEC.encode(creature), "position": [p.x, p.y, p.z],
		"rematch": {"trainer_id": str(_spec.id), "tier": str(_spec.rematch.tier)},
		"foot_position": [p.x, p.y, p.z], "facing": [f.x, f.y, f.z], "body_scale": body.get("body_scale"),
		"body_generation": _round + 1, "round": _round + 1, "round_continues": _round + 1 < _cards.size()}

func _install_round(body: Node3D, actor: Node3D) -> void:
	var script: Script = load("res://scripts/combat/shared_wild_host_fight.gd")
	_runtime = script.new()
	_director.add_child(_runtime)
	_director.get("_shared_host_fights")[encounter_id] = _runtime
	_runtime.connect("telegraph", Callable(_director, "_on_shared_host_telegraph").bind(encounter_id))
	_runtime.connect("swung", Callable(_director, "_on_shared_host_strike").bind(encounter_id))
	if body.has_signal("route_cue_started"):
		body.connect("route_cue_started", Callable(_director, "_on_shared_host_route").bind(encounter_id))
	_director.call("_configure_f22_patterns", body, true)
	_runtime.call("start_shared", body, actor, _centre, _radius, _director, encounter_id, _round + 1, "trainer")
	refresh_scaling()
	_director.call("_refresh_shared_record_presentation", _host.call("record", encounter_id))

func refresh_scaling() -> void:
	if not _world_current() or not is_instance_valid(_runtime): return
	var body: Node3D = _runtime.call("body")
	if is_instance_valid(body):
		_scaling_state = _director.call("scale_trainer_body_for_record", body, _host.call("record", encounter_id), _scaling_state)

func _dispose_round() -> void:
	if not is_instance_valid(_runtime): return
	var body: Node3D = _runtime.call("body")
	_runtime.call("stop_opponent")
	if is_instance_valid(body): body.queue_free()
	if is_instance_valid(_director) and _director.get("_shared_host_fights").get(encounter_id) == _runtime:
		_director.get("_shared_host_fights").erase(encounter_id)
	_runtime.queue_free()
	_runtime = null

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "resolved": false, "durable": false, "code": code}
