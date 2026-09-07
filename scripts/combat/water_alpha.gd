extends "res://scripts/combat/encounter_director.gd"

## One realm-owned Aquaryn. The ordinary director owns player deployments;
## this service owns the enemy even while the host plays on another island.
const ALPHA_STATE := preload("res://scripts/combat/water_alpha_state.gd")
const ALPHA_BODY := preload("res://scripts/creatures/water_alpha_body.gd")
const REWARDS := preload("res://scripts/world/water_alpha_rewards.gd")
var world: Node3D
var primary: Node
var rules: Dictionary
var swimming_rules: Dictionary
var authority: RefCounted
var body: Node3D
var transport: Node
var ready_for_intents := false
var _snapshot_clock := 0.0
var _pose_sequence := 0
var _received_sequence := -1
var _local_fight := false
var _engage_pending := false
var _surface_waypoint := -1
var _resolution_published := false
var _rewarded_peers: Dictionary = {}
var _presented_resolution: Dictionary = {}
var _catch_finish_pending := false
var _catch_finish_reply: Dictionary = {}
var last_verdict: Dictionary = {}

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	# Exploration streaming and follower ownership belong to the primary
	# director. Aquaryn advances only in the realm physics step below.
	pass

func build(realm: Node3D, director: Node) -> void:
	world = realm
	primary = director
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_alpha.json"))
	swimming_rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	authority = ALPHA_STATE.new(rules)
	_encounter_host = authority.host
	_ensure_encounter_arbiters()
	_player = world.local_rig()
	_camera_rig = world.local_camera_rig()
	_manager = world.get_node("CombatManager")
	var ledger := preload("res://scripts/net/ledger_rpc.gd").attach(get_node("/root/Game"))
	transport = ledger.get_node("WaterAlphaTransport")
	body = CREATURE_SCENE.instantiate()
	body.set_script(ALPHA_BODY)
	body.name = "Aquaryn"
	body.authority_node = self
	add_child(body)
	body.populate(str(rules.species_id), _player)
	_set_fixed_level(body, str(rules.species_id), int(rules.level))
	body.configure(MATH.config().get("wild", {}))
	var spawn: Array = rules.placement.spawn
	body.global_position = Vector3(float(spawn[0]), 0, float(spawn[1]))
	body.global_position.y = world.ground_height_at(body.position.x, body.position.z)
	body.home = body.global_position
	body.set_alpha(true)
	if get_node("/root/Game").world.flags.has(str(rules.completion_flag)):
		body.visible = false
		body.collision_layer = 0
		body.set_physics_process(false)
	body.register_environment_velocity_modifier(&"water_alpha", body, body.apply_surface_velocity, 0, Vector3(1, 0, 1))
	body.strike_ready.connect(_on_alpha_strike)
	_manager.exited.connect(_on_alpha_exit)
	ready_for_intents = true
	var pending: Dictionary = transport.consume_snapshot()
	if not pending.is_empty():
		receive_authority("snapshot", pending)

func is_alpha_authority() -> bool:
	return get_node("/root/Game").is_host()

func is_encounter_host() -> bool:
	return is_alpha_authority()

func phase_definition() -> Dictionary:
	return authority.phase()

func is_fight_active() -> bool:
	return str(authority.record().get("phase", "")) == "active"

func target_body() -> Node3D:
	var nearest: Node3D
	var distance := INF
	for peer: Variant in authority.record().get("participants", {}):
		var candidate := deployed_body_for(int(peer))
		if candidate != null and candidate.global_position.distance_squared_to(body.global_position) < distance:
			nearest = candidate
			distance = candidate.global_position.distance_squared_to(body.global_position)
	return nearest

func deployed_body_for(peer_id: int) -> Node3D:
	return primary.deployed_body_for(peer_id) if primary != null else null

func deployed_bodies() -> Array:
	return primary.deployed_bodies() if primary != null else []

func _creature_card_for(peer_id: int) -> Dictionary:
	if peer_id == _local_peer_id() and _local_fight:
		return _creature_card(_manager.active_creature())
	return primary._creature_card_for(peer_id)

func submit_encounter_intent(intent: Dictionary) -> Dictionary:
	if str(intent.get("kind", "")) == "catch_attempt":
		_catch_finish_reply = {}
		_catch_finish_pending = false
	return transport.submit(intent)

func host_commit(intent: Dictionary, peer: int, actor: Dictionary) -> Dictionary:
	if not is_alpha_authority():
		return _refusal(intent, "Only the realm authority can decide this fight.")
	var kind := str(intent.get("kind", ""))
	if kind == "engage":
		if get_node("/root/Game").world.flags.has(str(rules.completion_flag)):
			return _refusal(intent, "Aquaryn has already been resolved in this world.")
		var deployed := deployed_body_for(peer)
		if deployed == null or deployed.global_position.distance_to(body.global_position) > float(rules.authority.engage_radius_m):
			return _refusal(intent, "Bring your creature closer to Aquaryn.")
		var rec: Dictionary = authority.engage(peer, str(actor.get("character_id", "")), "", body.instance)
		if rec.is_empty():
			return _refusal(intent, "Aquaryn cannot be challenged right now.")
		_engaged_with = body
		_encounter = rec
		authority.host.note_opponent_position(authority.encounter_id, body.centre(), Time.get_ticks_msec())
		_publish_snapshot()
		return {"ok": true, "kind": kind, "record": rec}
	if str(intent.get("encounter_id", "")) != str(authority.encounter_id) or not authority.host.is_participant(authority.encounter_id, peer):
		return _refusal(intent, "You are not participating in this fight.")
	match kind:
		"strike_intent":
			return _alpha_strike(intent, peer)
		"catch_attempt":
			return _host_catch(intent, peer)
		"catch_finished":
			var result: Dictionary = authority.finish_catch(peer, _catch_arbiter, Time.get_ticks_msec())
			_publish_snapshot()
			return {"ok": not result.is_empty(), "kind": kind,
				"delta": {"caught": str(result.get("outcome", "")) == "caught"}}
		"disengage":
			var result: Dictionary = authority.host.leave(authority.encounter_id, peer)
			_publish_snapshot()
			return result
	return _refusal(intent, "That action is not available in this encounter.")

func _refusal(intent: Dictionary, reason: String) -> Dictionary:
	return {"ok": false, "pending": false, "kind": str(intent.get("kind", "")), "reason": reason, "delta": {}}

func _alpha_strike(intent: Dictionary, peer: int) -> Dictionary:
	var striker := deployed_body_for(peer)
	if striker == null:
		return _refusal(intent, "Your deployed creature is unavailable.")
	var card := _creature_card_for(peer)
	var slot := str(intent.get("slot", "quick"))
	var move_id := str(intent.get("move_id", ""))
	if slot not in ["quick", "charged"] or move_id != str(card.get("move_" + slot, "")):
		return _refusal(intent, "That move is not equipped.")
	var moves: RefCounted = _manager.get("_moves")
	var move := COMBAT_MANAGER.host_move_profile(moves, "player_" + slot, move_id, _body_radius(striker), _body_radius(body))
	var request := intent.duplicate(true)
	request.move = move
	var verdict: Dictionary = authority.host.validate_strike(request, peer, {
		"now_ms": Time.get_ticks_msec(), "origin": striker.centre(), "bodies": _encounter_body_rows()})
	if not verdict.get("ok", false) or not verdict.get("delta", {}).get("hit", false):
		return verdict
	var enemy: RefCounted = body.instance
	var type_mult: float = preload("res://scripts/combat/type_chart.gd").multiplier_dual(moves.type_of(move_id), enemy.creature_type, enemy.secondary_type)
	var damage: float = MATH.rolled_damage(float(move.power), maxf(1, float(card.get("attack", 1))), enemy.effective_defence(PROGRESSION.config()), _encounter_roll(), moves.power(move_id), type_mult)
	var killed: bool = enemy.take_damage(damage)
	verdict.delta.merge({"damage": damage, "killed": killed, "hp": enemy.hp, "hp_max": enemy.max_hp, "type_mult": type_mult}, true)
	authority.synchronise_damage()
	_publish_snapshot()
	return verdict

func _host_after_encounter_change(_id: String, _author: int = 0) -> void:
	_publish_snapshot()

func _publish_snapshot() -> void:
	_settle_resolution()
	_pose_sequence += 1
	var snapshot := {"sequence": _pose_sequence, "record": authority.record().duplicate(true),
		"position": body.global_position, "rotation": body.rotation, "velocity": body.velocity,
		"phase_index": authority.phase_index, "resolution": authority.resolution.duplicate(true)}
	var game := get_node("/root/Game")
	var peers: Array = game.session.peers_in_realm("water")
	if not world.simulation_only and not peers.has(_local_peer_id()):
		peers.append(_local_peer_id())
	for peer: int in peers:
		transport.deliver(peer, "snapshot", snapshot)

func _settle_resolution() -> void:
	var game := get_node("/root/Game")
	var ledger_rpc: Node = transport.get_parent()
	var ledger: RefCounted = ledger_rpc.ledger
	if not authority.resolution.is_empty() and not _resolution_published:
		var resolution: Dictionary = authority.resolution
		var verdict: Dictionary = REWARDS.resolve(game, ledger,
			"won" if str(resolution.outcome) == "defeated" else "caught", resolution.eligible_character_ids)
		if verdict.get("ok", false):
			ledger_rpc.publish_journaled_delta(verdict.delta)
			_resolution_published = true
	if not game.world.flags.has(str(rules.completion_flag)):
		return
	var peers: Array = game.session.peers_in_realm("water")
	if not world.simulation_only and not peers.has(_local_peer_id()):
		peers.append(_local_peer_id())
	for peer: int in peers:
		var actor: Dictionary = ledger_rpc._water_actor_context(peer, {})
		var character := str(actor.get("character_id", ""))
		var key := "%s:%s" % [peer, character]
		if _rewarded_peers.has(key):
			continue
		var grant: Dictionary = REWARDS.grant(game, ledger, character, peer)
		if grant.get("ok", false):
			ledger_rpc.publish_journaled_delta(grant.delta)
			_rewarded_peers[key] = true

func receive_authority(kind: String, payload: Dictionary) -> void:
	if kind == "verdict":
		last_verdict = payload.duplicate(true)
		if str(payload.get("kind", "")) == "engage":
			_engage_pending = false
			if payload.get("ok", false):
				_begin_local(payload.record)
			else:
				get_node("/root/Game").push_world_message(str(payload.get("reason", "Aquaryn is not ready for a challenge.")))
		elif str(payload.get("kind", "")) == "catch_finished":
			_catch_finish_reply = {"pending": false, "caught": bool(payload.get("ok", false)) and bool(payload.get("delta", {}).get("caught", false))}
			_catch_finish_pending = false
		else:
			if str(payload.get("kind", "")) == "catch_attempt":
				_catch_finish_reply = {}
				_catch_finish_pending = false
			_deliver_encounter_verdict(payload)
	elif kind == "enemy_hit":
		if _local_fight:
			_manager.apply_host_enemy_hit(payload)
	elif kind == "snapshot":
		if int(payload.get("sequence", -1)) <= _received_sequence:
			return
		_received_sequence = int(payload.sequence)
		_encounter = payload.record
		if not is_alpha_authority():
			body.global_position = payload.position
			body.rotation = payload.rotation
			body.velocity = payload.velocity
			authority.phase_index = int(payload.phase_index)
			var opponent: Dictionary = _encounter.get("opponent", {})
			if not opponent.is_empty():
				body.instance.hp = float(opponent.hp)
		if _local_fight:
			_manager.apply_encounter_record(_encounter)
			var result: Dictionary = payload.get("resolution", {})
			if not result.is_empty() and _presented_resolution.is_empty():
				_presented_resolution = result.duplicate(true)
				_present_resolution.call_deferred()

func _present_resolution() -> void:
	if not _local_fight or not is_instance_valid(_manager):
		return
	if str(_presented_resolution.get("outcome", "")) == "caught":
		var catcher := int(_presented_resolution.get("catcher_peer_id", 0))
		if catcher != _local_peer_id():
			_manager.note_caught_by(catcher, str(rules.species_id))
	elif _manager.state == COMBAT_MANAGER.State.ACTIVE:
		# The author already renders the killing strike synchronously. Other
		# participants reach this deferred path once and receive normal XP.
		_manager._award_victory()
		_manager._begin_resolve("won")

func request_engage() -> void:
	if _local_fight or _engage_pending or world.simulation_only:
		return
	_engage_pending = true
	var verdict: Dictionary = submit_encounter_intent({"kind": "engage"})
	if not verdict.get("pending", false):
		receive_authority("verdict", verdict)

func confirm_catch_finish(encounter_id: String) -> Dictionary:
	if not _catch_finish_reply.is_empty():
		return _catch_finish_reply
	if not _catch_finish_pending:
		_catch_finish_pending = true
		var verdict: Dictionary = submit_encounter_intent({"kind": "catch_finished", "encounter_id": encounter_id})
		if not verdict.get("pending", false):
			receive_authority("verdict", verdict)
	return _catch_finish_reply if not _catch_finish_reply.is_empty() else {"pending": true}

func _begin_local(rec: Dictionary) -> void:
	if _local_fight or world.simulation_only:
		return
	_ally_body = primary.get("_ally_body")
	_ally = primary.get("_ally")
	if _ally_body == null:
		return
	var party_obj := _party()
	if not _manager.begin(_player, body, _ally_body, _fight_party(), _camera_rig, party_obj.best(), false, true):
		return
	_local_fight = true
	_encounter = rec
	_manager.bind_encounter(self, str(rec.encounter_id), "wild")
	# The realm service owns enemy strikes, including a host without a local
	# combat camera. Remove the local-manager connection to avoid a double hit.
	var local_strike := Callable(_manager, "_on_enemy_strike")
	if body.strike_ready.is_connected(local_strike):
		body.strike_ready.disconnect(local_strike)
	primary._set_exploration_active(false)

func _on_alpha_exit(outcome: String) -> void:
	if not _local_fight:
		return
	if outcome == "caught" and int(_presented_resolution.get("catcher_peer_id", 0)) == _local_peer_id():
		primary._resolve_catch(body.instance)
	_local_fight = false

func _on_alpha_strike() -> void:
	if not is_alpha_authority() or not is_fight_active():
		return
	var cfg: Dictionary = body.combat_config()
	var origin: Vector3 = body.centre()
	var facing: Vector3 = body.facing()
	body.play_attack()
	var picked := host_pick_struck_participant(authority.encounter_id, cfg, origin, facing)
	if picked.is_empty():
		return
	var card: Dictionary = picked.card
	var enemy: RefCounted = body.instance
	var moves: RefCounted = _manager.get("_moves")
	var type_mult: float = preload("res://scripts/combat/type_chart.gd").multiplier_dual(moves.type_of(enemy.move_quick), str(card.creature_type), str(card.secondary_type))
	var damage: float = MATH.rolled_damage(float(cfg.get("power", 8)), enemy.effective_attack(PROGRESSION.config()), maxf(1, float(card.defence)), _encounter_roll(), moves.power(enemy.move_quick), type_mult)
	host_deliver_enemy_hit(authority.encounter_id, int(picked.peer_id), {"damage": damage, "type_mult": type_mult, "move_id": enemy.move_quick, "lunge": float(cfg.get("lunge", 0))})

func host_deliver_enemy_hit(_id: String, peer: int, payload: Dictionary) -> void:
	transport.deliver(peer, "enemy_hit", payload)

func surface_run_target() -> Vector3:
	if _surface_waypoint < 0:
		return Vector3(INF, INF, INF)
	var point: Array = rules.placement.surface_route[_surface_waypoint]
	return Vector3(float(point[0]), world.field.water_level(), float(point[1]))

func reach_surface_waypoint() -> void:
	_surface_waypoint += 1
	if _surface_waypoint >= rules.placement.surface_route.size():
		_surface_waypoint = -1
		authority.phase_elapsed = 0

func _physics_process(delta: float) -> void:
	if not ready_for_intents:
		return
	if is_alpha_authority():
		if str(authority.record().get("phase", "")) == "catching" and _catch_arbiter.owner_of(authority.encounter_id, Time.get_ticks_msec()) == 0:
			# A disconnected thrower or expired animation acknowledgement cannot
			# hold all other participants in a permanently paused fight.
			authority.host.set_phase(authority.encounter_id, "active")
		authority.advance(delta)
		var interval := float(authority.phase().surface_run_every_s)
		if is_fight_active() and interval > 0 and authority.phase_elapsed >= interval and _surface_waypoint < 0 and not rules.placement.surface_route.is_empty():
			_surface_waypoint = 0
		if not authority.encounter_id.is_empty():
			authority.host.note_opponent_position(authority.encounter_id, body.centre(), Time.get_ticks_msec())
		_snapshot_clock -= delta
		if _snapshot_clock <= 0:
			_snapshot_clock = float(rules.authority.snapshot_interval_s)
			_publish_snapshot()
	if not world.simulation_only and not _local_fight and Input.is_action_just_pressed("interact"):
		var deployed := deployed_body_for(_local_peer_id())
		if deployed != null and deployed.global_position.distance_to(body.global_position) <= float(rules.authority.engage_radius_m):
			request_engage()
