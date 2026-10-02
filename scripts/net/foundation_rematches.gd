extends Node

## Mounted original trainer bodies supply the authored roster and arena.
## Outcomes are retained before the director releases their stable census.
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")
var _services: Dictionary = {}
var _prompts: Dictionary = {}
var _boss_sources: Dictionary = {}
var _left := 0.0
var _sources: Dictionary = {}
var _requests: Dictionary = {}
var _pending: Dictionary = {}
var _request_epoch := ""

func _ready() -> void:
	get_parent().get_parent().connect("foundation_reply_received", _reply)

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 1.0
	var session := get_parent().get_parent()
	if RULES.config().get("runtime_enabled") != true or session.call("snapshot_ready") != true: return
	var epoch: String = session.call("_altar_current_epoch")
	if epoch != _request_epoch:
		_requests.clear()
		_pending.clear()
		_request_epoch = epoch
	var game: Node = session.call("_game")
	if game == null or game.get("local") == null: return
	var realms := {str(game.current_realm): true}
	if session.call("is_host") == true:
		for row: Dictionary in session.get("_registry").call("rows"):
			if not session.call("admitted_character_state", int(row.get("peer_id", 0))).is_empty(): realms[str(row.get("realm", ""))] = true
	for realm: String in realms: _mount_realm(realm)
	if not _pending.is_empty():
		if _pending.character_id != game.local.character_id or _pending.world.get_ref() != game.world or _pending.realm != game.current_realm:
			_pending.clear()
		else:
			var intent: Dictionary = _pending.intent
			session.call("foundation_rematch_start", intent.trainer_id, intent.tier, intent.creature_uid, intent.action_id)

func _director(realm: Node3D) -> Node:
	if realm == null: return null
	var session := get_parent().get_parent()
	for node: Node in realm.find_children("*", "Node", true, false):
		if node.get_script() != null and session.FOUNDATION_DIRECTORS.has(node.get_script().resource_path): return node
	return null

func _mount_realm(realm_id: String) -> void:
	var session := get_parent().get_parent()
	var realm: Node3D = session.call("_portal_world_node", realm_id)
	var director := _director(realm)
	if director == null: return
	var service: Node
	var reference: WeakRef = _services.get(director.get_instance_id())
	if reference != null: service = reference.get_ref() as Node
	if session.call("is_host") == true:
		if not is_instance_valid(service):
			service = preload("res://scripts/repeatables/rematch_service.gd").new()
			add_child(service)
			service.call("bind_host", director, Callable(self, "host_context").bind(director), Callable(self, "start_encounter").bind(director),
				Callable(self, "retained_outcome"), Callable(self, "submit_retained"), Callable(self, "pending_outcomes"))
			_services[director.get_instance_id()] = weakref(service)
		if not director.get("_rematch_outcome_writer").is_valid(): director.call("bind_rematch_outcome_writer", Callable(self, "retain_outcome"))
		director.call("retry_rematch_resolution")
	_sources[director.get_instance_id()] = {}
	if realm_id == "meadows": _mount_boss_requests(service, director)
	for site: Node in realm.find_children("*", "Node3D", true, false):
		if site.get_script() != preload("res://scripts/masters/master_site.gd") or site.get("_mounted") != true: continue
		var master := site.get_node_or_null(^"Master")
		if master != null: master.set_meta("foundation_trainer_spec", RULES.master_spec(str(site.get("master_id"))))
	for body: Node in realm.find_children("*", "Node3D", true, false):
		var spec: Variant = body.get_meta("foundation_trainer_spec", {})
		if not spec is Dictionary or spec.is_empty() or RULES.profile(str(spec.get("id", ""))).is_empty(): continue
		if RULES.profile(spec.id).kind == "boss": continue
		var old_prompt: Node = body.call("prompt_node") if body.has_method("prompt_node") else null
		if old_prompt == null: continue
		_register_source(director, body, spec.id)
		for tier: String in ["r1", "endgame"]:
			var key := "%d:%s" % [body.get_instance_id(), tier]
			var reference_prompt: WeakRef = _prompts.get(key)
			var prompt := reference_prompt.get_ref() as Node3D if reference_prompt != null else null
			if not is_instance_valid(prompt):
				prompt = preload("res://scripts/world/interactable.gd").new()
				body.add_child(prompt)
				prompt.position = Vector3(-1.5 if tier == "r1" else 1.5, 0, 0)
				prompt.call("configure", "R1 rematch" if tier == "r1" else "Endgame rematch", float(old_prompt.get("radius")), false)
				prompt.connect("activated", Callable(self, "challenge").bind(service, body, str(spec.id), tier))
				_prompts[key] = weakref(prompt)
			var context := _local_context(spec.id, body, director)
			prompt.call("set_enabled", not context.is_empty() and RULES.available(spec.id, tier, context.world_flags, context.personal_flags))

func _register_source(director: Node, source: Node3D, trainer: String) -> void:
	var rows: Dictionary = _sources.get(director.get_instance_id(), {})
	var found: Array = rows.get(trainer, [])
	found.append(weakref(source))
	rows[trainer] = found
	_sources[director.get_instance_id()] = rows

func _registered(director: Node, trainer: String) -> Node3D:
	var rows: Array = _sources.get(director.get_instance_id(), {}).get(trainer, [])
	if rows.size() != 1: return null
	return rows[0].get_ref() as Node3D

func _boss_board(director: Node) -> Node3D:
	for node: Node in director.get_parent().find_children("*", "Node3D", true, false):
		if node.get_script() == preload("res://scripts/world/tournament.gd") and node.call("built") == true:
			return node.get_node_or_null(^"Board") as Node3D
	return null

func _canonical_boss(trainer: String) -> Dictionary:
	var profile := RULES.profile(trainer)
	if profile.is_empty() or profile.kind != "boss": return {}
	if profile.biome == "stormwood":
		for spec: Dictionary in preload("res://scripts/combat/stormwood_encounter_catalogue.gd").trainer_specs():
			if spec.id == trainer: return spec.duplicate(true)
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(profile.source)))
	if not data is Dictionary: return {}
	if profile.biome == "cloudreach":
		# Cloudreach keeps its canonical roster in trainer_ladder and its
		# placement/patterns separately. Use the ordinary director's adapter,
		# including its authored send-out order, instead of treating that row
		# as the Meadows/Water trainers shape or inventing a second boss team.
		var encounters: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_encounters.json"))
		if not encounters is Dictionary: return {}
		var adapter: Script = load("res://scripts/combat/cloudreach_encounter_director.gd")
		for authored: Dictionary in data.get("trainer_ladder", []):
			if authored.get("id") != trainer: continue
			for placement: Dictionary in encounters.get("trainers", []):
				if placement.get("id") == trainer:
					return adapter.call("trainer_spec", authored, placement, encounters)
		return {}
	for spec: Variant in data.get("trainers", []):
		if spec is Dictionary and spec.get("id") == trainer: return spec.duplicate(true)
	return {}

func _mount_boss_requests(service: Node, director: Node) -> void:
	var board := _boss_board(director)
	if board == null or board.get_parent().get_script() != preload("res://scripts/world/tournament.gd") or board.get_parent().call("built") != true: return
	var original := board.get_node_or_null(^"Interactable")
	if original == null: return
	var index := 0
	for trainer: String in RULES.config().profiles:
		if RULES.profile(trainer).kind != "boss": continue
		var key := "%d:%s" % [board.get_instance_id(), trainer]
		var source_ref: WeakRef = _boss_sources.get(key)
		var source := source_ref.get_ref() as Node3D if source_ref != null else null
		if not is_instance_valid(source):
			var spec := _canonical_boss(trainer)
			if spec.is_empty(): continue
			source = Node3D.new()
			source.name = "Rematch_" + trainer
			board.add_child(source)
			source.position = Vector3(float(index - 2) * 2.0, 0, -1.5)
			source.set_meta("foundation_trainer_spec", spec)
			var prompt: Node3D = preload("res://scripts/world/interactable.gd").new()
			source.add_child(prompt)
			prompt.call("configure", "Endgame rematch: " + str(spec.get("name", spec.get("display_name", trainer))), float(original.get("radius")), false)
			prompt.connect("activated", Callable(self, "challenge").bind(service, source, trainer, "endgame"))
			source.set_meta("foundation_rematch_prompt", prompt)
			_boss_sources[key] = weakref(source)
		_register_source(director, source, trainer)
		var context := _local_context(trainer, source, director)
		source.get_meta("foundation_rematch_prompt").call("set_enabled", not context.is_empty() and RULES.available(trainer, "endgame", context.world_flags, context.personal_flags))
		index += 1

func _local_context(trainer: String, source: Node, director: Node) -> Dictionary:
	var session := get_parent().get_parent()
	var game: Node = session.call("_game")
	if game == null or game.local == null or not is_instance_valid(source) or not is_instance_valid(director) \
		or _registered(director, trainer) != source or not director.get_parent().is_ancestor_of(source): return {}
	var actor := game.call("find_player") as Node3D
	if actor == null or not director.get_parent().is_ancestor_of(actor): return {}
	var prompt: Node = source.call("prompt_node") if source.has_method("prompt_node") else source.get_meta("foundation_rematch_prompt", null)
	if prompt == null: return {}
	var flags: Array = session.call("_foundation_flags", session.call("local_peer_id")).keys()
	var character: String = game.local.character_id
	if game.local.redesign_character.transaction_receipts.has("craft:regional_ending_regional_credits_seen:" + character) and not flags.has("regional_credits_seen"): flags.append("regional_credits_seen")
	return {"character_id": character, "in_range": actor.global_position.distance_to(source.global_position) <= float(prompt.get("radius")),
		"world_flags": game.world.flags.call("all_set"), "personal_flags": flags,
		"canonical_spec": source.get_meta("foundation_trainer_spec", {}).duplicate(true)}

func host_context(character: String, trainer: String, source: Node, director: Node) -> Dictionary:
	var session := get_parent().get_parent()
	if session.call("is_host") != true or character != session.call("_authority_character", session.call("local_peer_id")): return {}
	return _local_context(trainer, source, director)

## Authenticated peer + host-mounted canonical source. No packet coordinate,
## roster, stat, personal flag or host-player body supplies this context.
func remote_context(peer: int, trainer: String, source: Node3D, director: Node) -> Dictionary:
	var session := get_parent().get_parent()
	if session.call("is_host") != true or director.get("_session") != session \
		or not is_instance_valid(source) or _registered(director, trainer) != source \
		or not source.is_inside_tree() or source.is_queued_for_deletion() or not director.get_parent().is_ancestor_of(source): return {}
	var lifecycle := get_parent().get_node(^"TravelLifecycle")
	var safety: Dictionary = lifecycle.call("host_context", peer)
	var actor: Node3D = lifecycle.call("remote_body", peer)
	if actor == null or safety.is_empty() or safety.get("realm") != director.call("_encounter_realm") \
		or safety.get("dialogue") != false or safety.get("cutscene") != false or safety.get("downed") != false \
		or safety.get("swimming") != false or safety.get("flying") != false or not director.get_parent().is_ancestor_of(actor): return {}
	var prompt: Node = source.call("prompt_node") if source.has_method("prompt_node") else source.get_meta("foundation_rematch_prompt", null)
	if prompt == null or actor.global_position.distance_to(source.global_position) > float(prompt.get("radius")): return {}
	var profile := RULES.profile(trainer)
	var spec: Dictionary = source.get_meta("foundation_trainer_spec", {})
	if profile.is_empty() or spec.get("id") != trainer: return {}
	var centre := actor.global_position
	var toward := actor.global_position - source.global_position
	toward.y = 0
	if toward.length() < 0.01: toward = Vector3.FORWARD
	var spot := source.global_position + toward.normalized() * float(preload("res://scripts/world/trainer_npc.gd").flow().get("deploy_offset", 3.0))
	var radius := float(preload("res://scripts/combat/combat_math.gd").config().get("arena", {}).get("radius", 11.0))
	if profile.kind == "master":
		var site := source.get_parent() as Node3D
		if site.get_script() != preload("res://scripts/masters/master_site.gd") or site.get("_mounted") != true or site.get("master_id") != trainer: return {}
		centre = site.global_position
		spot = centre
		radius = float(preload("res://scripts/creatures/breakthrough.gd").master(trainer).arena_radius_m)
	elif profile.kind == "boss":
		if source.get_parent() != _boss_board(director) or spec != _canonical_boss(trainer): return {}
	# The same body placement path as normal trainers checks actual support;
	# the centre comes from the live actor/site, never an ungrounded packet.
	return {"character_id": session.call("_authority_character", peer), "in_range": true,
		"canonical_spec": spec.duplicate(true), "arena_centre": centre, "opponent_spot": spot, "arena_radius_m": radius}

static func valid_start_intent(intent: Dictionary) -> bool:
	return intent.size() == 4 and intent.get("action_id") is String \
		and intent.action_id.length() == 32 and intent.action_id.is_valid_hex_number(false) \
		and intent.get("trainer_id") is String and not RULES.profile(intent.trainer_id).is_empty() \
		and intent.get("tier") in ["r1", "endgame"] and intent.get("creature_uid") is String \
		and preload("res://scripts/creatures/creature_instance.gd").valid_uid(intent.creature_uid)

func request_start(peer: int, intent: Dictionary) -> Dictionary:
	if not valid_start_intent(intent): return RULES.deny("invalid_rematch_request")
	var session := get_parent().get_parent()
	if session.call("is_host") != true \
		or session.call("admitted_character_state", peer).is_empty(): return RULES.deny("invalid_rematch_request")
	var game: Node = session.call("_game")
	var character: String = session.call("_authority_character", peer)
	var key := "%s:%s:%s:%s" % [game.world.reward_delivery_namespace, session.call("_altar_current_epoch"), character, intent.action_id]
	if _requests.has(key):
		var prior: Dictionary = _requests[key]
		return prior.result.duplicate(true) if prior.intent == intent else RULES.deny("rematch_action_changed")
	if _requests.size() >= 1024: return RULES.deny("rematch_request_budget")
	var safety: Dictionary = get_parent().get_node(^"TravelLifecycle").call("host_context", peer)
	var realm_id := str(safety.get("realm", ""))
	var realm: Node3D = session.call("_portal_world_node", realm_id)
	var director := _director(realm)
	if director == null: return RULES.deny("rematch_realm_unavailable")
	_mount_realm(realm_id)
	var source := _registered(director, intent.trainer_id)
	if source == null: return RULES.deny("registered_rematch_source_required")
	var result: Dictionary = director.call("start_remote_rematch", peer, source, intent.trainer_id, intent.tier,
		intent.creature_uid, Callable(self, "remote_context").bind(director))
	if result.get("ok") == true: _requests[key] = {"intent": intent.duplicate(true), "result": result.duplicate(true)}
	return result

func challenge(service: Node, source: Node, trainer: String, tier: String) -> void:
	var session := get_parent().get_parent()
	var game: Node = session.call("_game")
	var director := _director(session.call("_portal_world_node", game.current_realm))
	if director == null: return
	var ally: RefCounted = director.get("_ally")
	var uid := str(ally.get("uid")) if ally != null else ""
	if session.call("is_host") == true:
		if service == null or director.call("rematch_source_busy", source) == true: return
		var result: Dictionary = service.call("challenge", game.local.character_id, trainer, tier, source, uid)
		if result.get("ok") != true: game.call("push_world_message", str(result.get("code", "The rematch could not start.")))
		return
	if not _pending.is_empty() or uid.is_empty(): return
	var intent := {"trainer_id": trainer, "tier": tier, "creature_uid": uid, "action_id": Crypto.new().generate_random_bytes(16).hex_encode()}
	_pending = {"intent": intent, "character_id": game.local.character_id, "world": weakref(game.world), "realm": game.current_realm}
	session.call("foundation_rematch_start", trainer, tier, uid, intent.action_id)

func _reply(envelope: Dictionary, result: Dictionary) -> void:
	if envelope.get("op") != "rematch_start" or _pending.is_empty() or envelope.get("intent") != _pending.intent: return
	var intent: Dictionary = _pending.intent
	if result.get("ok") != true:
		_pending.clear()
		get_parent().get_parent().call("_game").call("push_world_message", str(result.get("reason", result.get("code", "The rematch could not start."))))
		return
	_pending.clear()
	var session := get_parent().get_parent()
	var director := _director(session.call("_portal_world_node", session.call("_game").get("current_realm")))
	if director == null: return
	if result.get("record", {}).get("encounter_id") != result.get("encounter_id") \
		or director.call("accept_remote_rematch", intent, result.get("record", {})) != true:
		director.call("submit_encounter_intent", {"kind": "disengage", "encounter_id": str(result.get("encounter_id", ""))})

func start_encounter(character: String, spec: Dictionary, source: Node, uid: String, director: Node) -> Dictionary:
	var context := host_context(character, str(spec.get("id", "")), source, director)
	if context.is_empty() or context.in_range != true: return RULES.deny("registered_rematch_source_required")
	var tier := str(spec.get("rematch", {}).get("tier", ""))
	if not RULES.available(spec.id, tier, context.world_flags, context.personal_flags) \
		or spec != RULES.encounter_spec(context.canonical_spec, tier): return RULES.deny("canonical_trainer_roster_required")
	var result: bool
	if RULES.profile(spec.id).kind == "master":
		result = director.call("start_master_rematch", source.get_parent(), character, uid, spec.duplicate(true))
	else: result = director.call("begin_trainer_battle", spec.duplicate(true), source)
	return {"ok": result, "resolved": false}

func retain_outcome(director: Node, spec: Dictionary, won: bool) -> Dictionary:
	return get_parent().get_parent().call("foundation_rematch_outcome", director, spec, won)

func retained_outcome(director: Node, _encounter: String) -> Dictionary:
	return retain_outcome(director, director.get("_trainer_spec"), director.get("_manager").call("outcome") == "won")

func pending_outcomes(encounter: String) -> Array:
	var game: Node = get_parent().get_parent().call("_game")
	var result: Array = []
	for row: Variant in game.world.reward_deliveries.values():
		if not preload("res://scripts/net/foundation_event.gd").valid(row, game.world.reward_delivery_namespace, game.world.world_id): continue
		for duty: Dictionary in row.duties:
			if duty.action == "rematch_win" and duty.intent.encounter_id == encounter:
				result.append({"character_id": duty.character_id, "trainer_id": duty.intent.trainer_id, "tier": duty.intent.tier, "encounter_id": encounter})
	return result

func submit_retained(character: String, action: String, intent: Dictionary) -> Dictionary:
	var session := get_parent().get_parent()
	session.call("_retry_foundation_events")
	var peer := int(session.get("_registry").call("peer_for_character", character))
	var game: Node = session.call("_game")
	var row: Dictionary = game.world.reward_deliveries.get(preload("res://scripts/creatures/essence.gd").training_delivery_id(game.world.reward_delivery_namespace, character), {})
	if row.get("action") != action or row.get("intent") != intent: return {"ok": false, "resolved": false}
	return session.call("_foundation_decision", peer, row)
