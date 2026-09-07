extends Node3D

## Host-owned authored climax layered over the shared hosted trainer fight.
## Captain Marrow's roster is the first two phases; defeating it opens the
## directly-piloted four-conduit run.  Peers submit named move intents, while
## the host alone evaluates body positions, bank hazards and completion.
const RULES := preload("res://scripts/world/stormwood_dynamo_rules.gd")
const ARENA := preload("res://scripts/world/stormwood_dynamo_arena.gd")
const FIELD_CONTROL := preload("res://scripts/world/stormwood_dynamo_field_control.gd")
const HOSTED := preload("res://scripts/combat/stormwood_hosted_trainer.gd")
const COMBAT_MANAGER := preload("res://scripts/combat/combat_manager.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")

const TRAINER_ID := "captain_marrow_dynamo_core"
const MARROW_FLAG := "stormwood:marrow_defeated"
const KESTREL_FLAG := "stormwood:kestrel_defeated"
const CORE_FLAG := "stormwood:core_reached"
const CORE_POSITION := Vector3(-100.0, 262.21, 5470.0)
const SNAPSHOT_INTERVAL_S := 0.1

var world: Node3D
var hub: Node
var session: Node
var rules: RefCounted
var arena: Node3D
var fight: Node
var phase := "bank_cycle"
var participants: Array[int] = []
var contributors: Array[int] = []
var _moves := MOVE_DB.new()
var _actions: Dictionary = {}
var _cooldowns: Dictionary = {}
var _snapshot_left := 0.0
var _last_fired_serial := -1
var _local_action := 0
var _completion_committed := false


func mount(owner_world: Node3D) -> void:
	world = owner_world
	hub = world.get_node("StormwoodEncounterHub")
	session = get_node("/root/Game/Session")
	global_position = CORE_POSITION
	rules = RULES.new()
	_restore_saved_state()
	phase = str(rules.phase)
	arena = ARENA.new()
	arena.name = "DynamoArena"
	add_child(arena)
	arena.build(rules, bool(world.get("simulation_only")))
	if not bool(world.get("simulation_only")):
		var control := FIELD_CONTROL.new()
		control.name = "FieldControl"
		add_child(control)
		control.mount(world, self)
	add_to_group("progression_restore")
	if phase == "released" and not _progression().has(MARROW_FLAG):
		# A crash after the fourth conduit was persisted but before the chapter
		# event committed must finish the idempotent reward transaction on load.
		call_deferred("_complete_marrow")


func arena_ready() -> bool:
	if rules == null or phase == "released":
		return false
	var flags: RefCounted = get_node("/root/Game").get("progression")
	# The same prompt admits a second peer to the live captain fight and lets a
	# reconnecting peer rejoin a persisted conduit phase. Neither is a new win.
	return flags.has(CORE_FLAG) and flags.has(KESTREL_FLAG) and not flags.has(MARROW_FLAG)


func begin_for_peer(peer: int) -> void:
	if not session.is_host():
		return
	if phase == "break_core":
		_add_participant(peer)
		_publish_state()
		return
	if not arena_ready():
		hub.call("_refuse_start", peer, TRAINER_ID, "dynamo_not_ready")
		return
	if is_instance_valid(fight) and not bool(fight.get("finished")):
		fight.call("join", peer)
		_add_participant(peer)
		return
	var cast := world.get_node("StormwoodTrainers")
	var authored: Dictionary = cast.get("authored_specs")
	var spec: Dictionary = authored.get(TRAINER_ID, {})
	var trainer: Node3D = cast.call("body_for", TRAINER_ID)
	var actor: Node3D = hub.call("actor_for", peer)
	if spec.is_empty() or not is_instance_valid(trainer) or not is_instance_valid(actor):
		hub.call("_refuse_start", peer, TRAINER_ID, "dynamo_not_ready")
		return
	var toward := actor.global_position - trainer.global_position
	toward.y = 0.0
	var at := trainer.global_position + (toward.normalized() if toward.length_squared() > 0.001 else Vector3.BACK) * 4.0
	fight = HOSTED.new()
	fight.name = "DynamoCaptainFight"
	hub.add_child(fight)
	hub.call("register_fight", TRAINER_ID, fight)
	if not bool(fight.call("start", hub, spec, peer, at)):
		hub.call("forget_fight", TRAINER_ID, fight)
		fight.queue_free()
		fight = null
		hub.call("_refuse_start", peer, TRAINER_ID, "opponent_unavailable")
		return
	_add_participant(peer)
	rules.reset()
	phase = str(rules.phase)
	_persist_state()
	_publish_state()


func captain_team_finished(completed_fight: Node, won: bool) -> void:
	if completed_fight != fight:
		return
	contributors = _unique_peers(completed_fight.get("contributors"))
	participants = _unique_peers(completed_fight.get("participants"))
	if participants.is_empty():
		participants = contributors.duplicate()
	hub.call("forget_fight", TRAINER_ID, completed_fight)
	fight = null
	if not won:
		_reset_after_loss()
		return
	var total := (completed_fight.get("team") as Array).size()
	rules.update_team(0, maxi(1, total))
	phase = str(rules.phase)
	_last_fired_serial = -1
	_persist_state()
	_publish_state()


func request_conduit_strike(index: int, slot: String, move_id: String) -> void:
	_local_action += 1
	session.request_stormwood_encounter({
		"kind": "dynamo_conduit_strike", "index": index, "slot": slot,
		"move_id": move_id, "action": _local_action,
	})


func dispatch(peer: int, intent: Dictionary) -> void:
	if not session.is_host():
		return
	var kind := str(intent.get("kind", ""))
	if kind == "dynamo_join":
		if phase == "break_core":
			_add_participant(peer)
			_publish_state()
		return
	if kind != "dynamo_conduit_strike":
		return
	var verdict := _validate_conduit_strike(peer, intent)
	hub.call("send_to", peer, {"kind": "dynamo_verdict", "verdict": verdict})
	if not bool(verdict.get("ok", false)):
		return
	if phase == "released":
		_complete_marrow()
	else:
		_persist_state()
		_publish_state()


func receive(event: Dictionary) -> void:
	match str(event.get("kind", "")):
		"dynamo_state":
			var state: Variant = event.get("state", {})
			if state is Dictionary:
				rules.load_data(state as Dictionary)
				phase = str(rules.phase)
			participants = _unique_peers(event.get("participants", []))
			if arena != null:
				arena.show_state(rules.bank_state())
		"dynamo_hazard_hit":
			_apply_local_hazard(event)
		"dynamo_recovery":
			_apply_local_recovery()
		"dynamo_verdict":
			var verdict: Dictionary = event.get("verdict", {})
			if not bool(verdict.get("ok", false)):
				get_node("/root/Game").push_world_message(str(verdict.get("reason", "That conduit strike was refused.")))


func send_snapshot(peer: int) -> void:
	if session.is_host():
		hub.call("send_to", peer, _state_event())


func restore_progression_from_game(_game: Node) -> void:
	if not is_instance_valid(fight):
		_restore_saved_state()
		phase = str(rules.phase)
		if arena != null:
			arena.show_state(rules.bank_state())


func _process(delta: float) -> void:
	if rules == null or not session.is_host():
		return
	if is_instance_valid(fight) and not bool(fight.get("finished")):
		participants = _unique_peers(fight.get("participants"))
		contributors = _unique_peers(fight.get("contributors"))
		var team: Array = fight.get("team")
		var remaining := maxi(0, team.size() - int(fight.get("round_index")))
		rules.update_team(remaining, team.size())
		phase = str(rules.phase)
	elif phase == "break_core":
		for peer: int in participants.duplicate():
			if session.realm_of(peer) != "stormwood" or not is_instance_valid(hub.call("body_for", peer)):
				participants.erase(peer)
		if participants.is_empty():
			_reset_after_loss()
			return
	var before: Dictionary = rules.bank_state()
	rules.advance(delta)
	phase = str(rules.phase)
	var state: Dictionary = rules.bank_state()
	if str(state.get("state", "")) == "fire" and int(state.get("serial", -1)) != _last_fired_serial:
		_last_fired_serial = int(state.get("serial", -1))
		_fire_bank(int(state.get("bank", -1)))
	arena.show_state(state)
	_snapshot_left -= delta
	if _snapshot_left <= 0.0 or before.get("state") != state.get("state") or before.get("bank") != state.get("bank"):
		_snapshot_left = SNAPSHOT_INTERVAL_S
		_persist_state()
		_publish_state()


func _validate_conduit_strike(peer: int, intent: Dictionary) -> Dictionary:
	var refused := {"ok": false, "reason": "That conduit strike is no longer available."}
	if phase != "break_core" or not participants.has(peer) or session.realm_of(peer) != "stormwood":
		return refused
	var body: Node3D = hub.call("body_for", peer)
	if not is_instance_valid(body):
		return refused
	var card: Dictionary = hub.call("card_for", peer)
	var slot := str(intent.get("slot", ""))
	if not slot in ["quick", "charged"]:
		return refused
	var move_id := str(intent.get("move_id", ""))
	if move_id.is_empty() or move_id != str(card.get("move_" + slot, "")):
		return refused
	var action := int(intent.get("action", 0))
	var now := Time.get_ticks_msec()
	if action <= int(_actions.get(peer, 0)) or now < int(_cooldowns.get(peer, 0)):
		return refused
	var local: Vector3 = to_local(body.global_position)
	var index := int(intent.get("index", -1))
	if index < 0 or index >= int(rules.config.bank_count):
		return refused
	var conduit: Vector2 = rules.bank_position(index)
	var facing: Vector3 = body.call("facing")
	var toward: Vector3 = Vector3(conduit.x - local.x, 0.0, conduit.y - local.z)
	if not facing_conduit(facing, toward):
		return {"ok": false, "reason": "Face the live conduit before striking."}
	if not rules.strike_conduit(index, Vector2(local.x, local.z), true):
		return {"ok": false, "reason": "Move your companion beside a live conduit before striking."}
	var profile: Dictionary = COMBAT_MANAGER.host_move_profile(
		_moves, "player_" + slot, move_id, float(hub.call("body_radius", body)), 1.25)
	_actions[peer] = action
	_cooldowns[peer] = now + ceili(1000.0 * maxf(float(profile.get("cooldown", 0.0)),
		float(profile.get("windup", 0.1)) + float(profile.get("recovery", 0.1))))
	phase = str(rules.phase)
	return {"ok": true, "reason": "", "index": index, "phase": phase}


func _fire_bank(bank: int) -> void:
	if bank < 0:
		return
	for peer: int in participants:
		var body: Node3D = hub.call("body_for", peer)
		if not is_instance_valid(body):
			continue
		var local := to_local(body.global_position)
		if not rules.in_discharge_lane(Vector2(local.x, local.z), bank):
			continue
		var card: Dictionary = hub.call("card_for", peer)
		var maximum := maxf(1.0, float(card.get("hp_max", card.get("max_hp", 1.0))))
		var damage := maximum * clampf(float(rules.config.get("strike_max_health_fraction", 0.25)), 0.0, 0.25)
		hub.call("send_to", peer, {"kind": "dynamo_hazard_hit", "bank": bank,
			"damage": damage, "static_seconds": float(rules.config.get("static_seconds", 8.0))})


func _apply_local_hazard(event: Dictionary) -> void:
	var manager := world.get_node("CombatManager")
	if manager.call("is_fighting"):
		manager.call("apply_host_enemy_hit", {"damage": float(event.get("damage", 0.0)),
			"move_id": "dynamo_discharge", "lunge": 0.0})
	else:
		var body: Node3D = hub.call("body_for", session.local_peer_id())
		if is_instance_valid(body):
			var creature: RefCounted = body.get("instance")
			if creature != null:
				var killed := bool(creature.call("take_damage", float(event.get("damage", 0.0))))
				body.call("play_faint" if killed else "play_hit")
	# Static is a locomotion penalty, shared with ordinary Stormwood lightning.
	# The piloted companion takes the core damage; its trainer's stamina regen
	# is what the named status affects.
	var player := world.get_node("Player") as CharacterBody3D
	var vitals: RefCounted = player.get("vitals") if is_instance_valid(player) else null
	if vitals != null:
		vitals.call("_apply_buff", {"id": "stormwood_static",
			"stat": "stamina_regen_scale", "amount": 0.5,
			"duration_s": float(event.get("static_seconds", 8.0))})


func _complete_marrow() -> void:
	if _completion_committed or not session.is_host():
		return
	var cast := world.get_node("StormwoodTrainers")
	var authored: Dictionary = cast.get("authored_specs")
	var spec: Dictionary = authored.get(TRAINER_ID, {})
	if not _progression().has(MARROW_FLAG):
		world.get_node("EncounterDirector").call("award_hosted_trainer", spec, contributors)
		world.get_node("StormwoodChapter").call("emit_event", "trainer:marrow_defeated")
	_completion_committed = _progression().has(MARROW_FLAG)
	if not _completion_committed:
		push_error("Dynamo release did not commit Captain Marrow's chapter flag")
		return
	_persist_state()
	_publish_state()


func _reset_after_loss() -> void:
	var peers := contributors.duplicate()
	rules.reset()
	phase = str(rules.phase)
	participants.clear()
	contributors.clear()
	_actions.clear()
	_cooldowns.clear()
	_last_fired_serial = -1
	_completion_committed = false
	_persist_state()
	_publish_state()
	for peer: int in peers:
		hub.call("send_to", peer, {"kind": "dynamo_recovery"})


func _apply_local_recovery() -> void:
	var player := world.get_node("Player") as Node3D
	var x := -120.0
	var z := 5270.0
	player.global_position = Vector3(x, world.call("ground_height_at", x, z) + 0.3, z)
	get_node("/root/Game").push_world_message("The Dynamo throws you back to Ember Bivouac. Recover, then climb again.")


func _add_participant(peer: int) -> void:
	if not participants.has(peer):
		participants.append(peer)
	if not contributors.has(peer):
		contributors.append(peer)


func _publish_state() -> void:
	if not session.is_host():
		return
	var event := _state_event()
	for peer: int in session.peers_in_realm("stormwood"):
		hub.call("send_to", peer, event)
	if not session.is_active():
		hub.call("send_to", session.local_peer_id(), event)


func _state_event() -> Dictionary:
	return {"kind": "dynamo_state", "state": rules.save_data(),
		"participants": participants.duplicate(), "trainer_id": TRAINER_ID}


func _persist_state() -> void:
	if session != null and not session.is_host():
		return
	var game := get_node("/root/Game")
	var environment: Dictionary = game.get("realm_environment")
	var stormwood: Dictionary = (environment.get("stormwood", {}) as Dictionary).duplicate(true)
	stormwood["dynamo"] = save_payload()
	environment["stormwood"] = stormwood
	game.set("realm_environment", environment)


func _restore_saved_state() -> void:
	var game := get_node_or_null("/root/Game")
	if game == null or rules == null:
		return
	var environment: Dictionary = game.get("realm_environment")
	var stormwood: Variant = environment.get("stormwood", {})
	if stormwood is Dictionary:
		var saved: Variant = (stormwood as Dictionary).get("dynamo", {})
		if saved is Dictionary and not (saved as Dictionary).is_empty():
			load_payload(saved as Dictionary)
	if _progression().has(MARROW_FLAG):
		rules.phase = "released"
		_completion_committed = true


func save_payload() -> Dictionary:
	return {"rules": rules.save_data(), "participants": participants.duplicate(),
		"contributors": contributors.duplicate()}


func load_payload(saved: Dictionary) -> void:
	# The first implementation persisted the rules dictionary directly. Keep
	# accepting it so saves made during that development window remain usable.
	var rule_data: Variant = saved.get("rules", saved)
	if rule_data is Dictionary:
		rules.load_data(rule_data as Dictionary)
	participants = _unique_peers(saved.get("participants", []))
	contributors = _unique_peers(saved.get("contributors", []))


func _progression() -> RefCounted:
	return get_node("/root/Game").get("progression")


static func facing_conduit(facing: Vector3, toward: Vector3) -> bool:
	facing.y = 0.0
	toward.y = 0.0
	if not facing.is_finite() or not toward.is_finite() or facing.length_squared() <= 0.0001 \
			or toward.length_squared() <= 0.0001:
		return false
	return facing.normalized().dot(toward.normalized()) >= 0.2


static func _unique_peers(raw: Variant) -> Array[int]:
	var out: Array[int] = []
	if raw is Array:
		for value: Variant in raw:
			var peer := int(value)
			if peer > 0 and not out.has(peer):
				out.append(peer)
	return out
