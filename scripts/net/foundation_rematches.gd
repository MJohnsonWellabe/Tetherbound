extends Node

## Mounted original trainer bodies supply the authored roster and arena.
## Outcomes are retained before the director releases their stable census.
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")
var _services: Dictionary = {}
var _prompts: Dictionary = {}
var _boss_sources: Dictionary = {}
var _left := 0.0

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 1.0
	var session := get_parent().get_parent()
	if session.call("is_host") != true or RULES.config().get("runtime_enabled") != true: return
	var game: Node = session.call("_game")
	var realm: Node3D = session.call("_portal_world_node", game.current_realm)
	if realm == null: return
	var director: Node
	for node: Node in realm.find_children("*", "Node", true, false):
		if node.get_script() != null and session.FOUNDATION_DIRECTORS.has(node.get_script().resource_path):
			director = node
			break
	if director == null: return
	var service: Node = _services.get(director.get_instance_id())
	if not is_instance_valid(service):
		service = preload("res://scripts/repeatables/rematch_service.gd").new()
		add_child(service)
		service.call("bind_host", director, Callable(self, "host_context").bind(director), Callable(self, "start_encounter").bind(director),
			Callable(self, "retained_outcome"), Callable(self, "submit_retained"), Callable(self, "pending_outcomes"))
		director.call("bind_rematch_outcome_writer", Callable(self, "retain_outcome"))
		_services[director.get_instance_id()] = service
	if not director.get("_rematch_outcome_writer").is_valid(): director.call("bind_rematch_outcome_writer", Callable(self, "retain_outcome"))
	director.call("retry_rematch_resolution")
	if game.current_realm == "meadows": _mount_boss_requests(service, director)
	for site: Node in realm.find_children("*", "Node3D", true, false):
		if site.get_script() != preload("res://scripts/masters/master_site.gd") or site.get("_mounted") != true: continue
		var master := site.get_node_or_null(^"Master")
		if master != null: master.set_meta("foundation_trainer_spec", RULES.master_spec(str(site.get("master_id"))))
	for body: Node in realm.find_children("*", "Node3D", true, false):
		var spec: Variant = body.get_meta("foundation_trainer_spec", {})
		if not spec is Dictionary or spec.is_empty() or RULES.profile(str(spec.get("id", ""))).is_empty(): continue
		# Boss rematches belong to Halda's lawn; their original stronghold
		# bodies deliberately do not acquire a rematch interaction here.
		if RULES.profile(spec.id).kind == "boss": continue
		var old_prompt: Node = body.call("prompt_node") if body.has_method("prompt_node") else null
		if old_prompt == null: continue
		for tier: String in ["r1", "endgame"]:
			var key := "%d:%s" % [body.get_instance_id(), tier]
			var prompt: Node3D = _prompts.get(key)
			if not is_instance_valid(prompt):
				prompt = preload("res://scripts/world/interactable.gd").new()
				body.add_child(prompt)
				prompt.position = Vector3(-1.5 if tier == "r1" else 1.5, 0, 0)
				prompt.call("configure", "R1 rematch" if tier == "r1" else "Endgame rematch", float(old_prompt.get("radius")), false)
				prompt.connect("activated", Callable(self, "challenge").bind(service, body, str(spec.id), tier))
				_prompts[key] = prompt
			var context := host_context(game.local.character_id, spec.id, body, director)
			prompt.call("set_enabled", not context.is_empty() and RULES.available(spec.id, tier, context.world_flags, context.personal_flags))

func _canonical_boss(trainer: String) -> Dictionary:
	var profile := RULES.profile(trainer)
	if profile.is_empty() or profile.kind != "boss": return {}
	if profile.biome == "stormwood":
		for spec: Dictionary in preload("res://scripts/combat/stormwood_encounter_catalogue.gd").trainer_specs():
			if spec.id == trainer: return spec.duplicate(true)
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(profile.source)))
	if not data is Dictionary: return {}
	for spec: Variant in data.get("trainers", []):
		if spec is Dictionary and spec.get("id") == trainer: return spec.duplicate(true)
	return {}

func _mount_boss_requests(service: Node, director: Node) -> void:
	var weak: WeakRef = get_parent().get("_board")
	var board := weak.get_ref() as Node3D if weak != null else null
	if board == null or board.get_parent().get_script() != preload("res://scripts/world/tournament.gd") or board.get_parent().call("built") != true: return
	var original := board.get_node_or_null(^"Interactable")
	if original == null: return
	var index := 0
	for trainer: String in RULES.config().profiles:
		if RULES.profile(trainer).kind != "boss": continue
		var key := "%d:%s" % [board.get_instance_id(), trainer]
		var source: Node3D = _boss_sources.get(key)
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
			_boss_sources[key] = source
		var context := host_context(get_parent().get_parent().call("_local_character_id"), trainer, source, director)
		source.get_meta("foundation_rematch_prompt").call("set_enabled", not context.is_empty() and RULES.available(trainer, "endgame", context.world_flags, context.personal_flags))
		index += 1

func host_context(character: String, trainer: String, source: Node, director: Node) -> Dictionary:
	var session := get_parent().get_parent()
	var game: Node = session.call("_game")
	if not is_instance_valid(source) or not is_instance_valid(director) or director.get("_session") != session \
		or character != session.call("_authority_character", session.call("local_peer_id")): return {}
	var spec: Dictionary = source.get_meta("foundation_trainer_spec", {})
	var profile := RULES.profile(trainer)
	if spec.get("id") != trainer or profile.is_empty() or not director.get_parent().is_ancestor_of(source): return {}
	var actor := game.call("find_player") as Node3D
	var prompt: Node = source.call("prompt_node") if source.has_method("prompt_node") else source.get_meta("foundation_rematch_prompt", null)
	if profile.kind == "boss" and (not _boss_sources.values().has(source) or source.get_parent().get_parent().get_script() != preload("res://scripts/world/tournament.gd")): return {}
	if actor == null or prompt == null: return {}
	var flags: Array = session.call("_foundation_flags", session.call("local_peer_id")).keys()
	if game.local.redesign_character.transaction_receipts.has("craft:regional_ending_regional_credits_seen:" + character) and not flags.has("regional_credits_seen"): flags.append("regional_credits_seen")
	return {"character_id": character, "in_range": actor.global_position.distance_to(source.global_position) <= float(prompt.get("radius")),
		"world_flags": game.world.flags.call("all_set"), "personal_flags": flags, "canonical_spec": spec.duplicate(true)}

func challenge(service: Node, source: Node, trainer: String, tier: String) -> void:
	var session := get_parent().get_parent()
	var game: Node = session.call("_game")
	var uid := ""
	if RULES.profile(trainer).kind == "master":
		var director: Node = service.get("_director")
		var ally: RefCounted = director.get("_ally")
		if ally != null: uid = str(ally.get("uid"))
	var result: Dictionary = service.call("challenge", game.local.character_id, trainer, tier, source, uid)
	if result.get("ok") != true: game.call("push_world_message", str(result.get("code", "The rematch could not start.")))

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
