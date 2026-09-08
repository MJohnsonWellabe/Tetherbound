extends "res://scripts/combat/encounter_director.gd"

## Reuses production deployment, host encounter authority, catches and rewards.
## Only the authored population and realm-specific admission rules differ.
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
var population_ready := false
var _hosted_body: Node3D
var _hosted_trainer := ""
var _observed_hosted: Dictionary = {}

func _init() -> void:
	default_starter = ""

func spawns_config() -> Dictionary:
	if _spawns_cfg.is_empty():
		_spawns_cfg = CATALOGUE.wild_config("calm")
	return _spawns_cfg

func _spawn_creatures() -> void:
	await super._spawn_creatures()
	population_ready = true
	print("STORMWOOD ENCOUNTERS READY wild=", _wild_creatures.size())


## The shared director derives an alpha's once id from its stable order. Named
## Stormwood residents translate that implementation id into an explicit realm
## flag, so the durable save record remains meaningful if namespaces change.
func _once_cleared(id: String) -> bool:
	return super._once_cleared(CATALOGUE.canonical_once_flag(id))


func _mark_once_cleared(id: String) -> void:
	super._mark_once_cleared(CATALOGUE.canonical_once_flag(id))


## Realm-local named options layered over the production alpha construction.
## A non-catchable authored row uses the same trainer-owned guard the catch
## pipeline already enforces; catchable rows remain ordinary wild opponents.
func _make_alpha(wild: Node3D, species: String, spawn: Dictionary, centre_z: float) -> void:
	super._make_alpha(wild, species, spawn, centre_z)
	var id := str(spawn.get("stormwood_named_id", ""))
	if id.is_empty():
		return
	wild.name = "Named_%s" % id
	wild.set_meta("stormwood_named_encounter", id)
	wild.set_meta("stormwood_behavior_profile", str(spawn.get("stormwood_behavior_profile", "")))
	wild.set("trainer_owned", not bool(spawn.get("catchable", false)))

func can_challenge(spec: Dictionary) -> bool:
	if str(spec.get("id", "")) == "captain_marrow_dynamo_core":
		var dynamo := get_parent().get_node_or_null("StormwoodDynamo")
		if dynamo == null or not dynamo.has_method("arena_ready") or not bool(dynamo.call("arena_ready")):
			return false
	for flag: String in spec.get("requires_flags", []):
		if not _progression().has(flag):
			return false
	return super.can_challenge(spec)

func _wander_target_clear_of_road(at: Vector3) -> bool:
	var world := get_parent()
	var height := float(world.call("ground_height_at", at.x, at.z))
	if not is_finite(height) or height < 0:
		return false
	# The Crown's discontinuity is a real boundary for wildlife as well as
	# trainers. A short step must not wander over the Glass Sink's rim.
	return absf(height - at.y) < 6.0


func begin_trainer_battle(spec: Dictionary, _trainer: Node3D = null) -> bool:
	if not can_challenge(spec):
		return false
	var hub := get_parent().get_node_or_null("StormwoodEncounterHub")
	if hub == null:
		return false
	hub.request_start(str(spec.get("id", "")))
	return true


func trainer_battle_active() -> bool:
	return not _hosted_trainer.is_empty() or super.trainer_battle_active()


func _process(delta: float) -> void:
	super._process(delta)
	if not _hosted_trainer.is_empty() and _manager != null and _manager.is_fighting():
		var active: RefCounted = _manager.active_creature()
		if active != null and active != _ally:
			_ally = active
			# The host must validate the newly piloted creature's moves/stats,
			# not the card announced at the start of the trainer battle.
			_announce_deployment(active)


func begin_hosted_round(link: Node, state: Dictionary) -> bool:
	if _manager.is_fighting():
		return false
	var party := _party()
	if party == null or party.call("active") == null:
		return false
	if not is_instance_valid(_ally_body):
		summon_active_creature()
	if not is_instance_valid(_ally_body):
		return false
	if is_instance_valid(_hosted_body):
		_hosted_body.queue_free()
	var creature := TRAINERS.creature_for(state.get("team_entry", {}))
	if creature == null:
		return false
	_hosted_body = CREATURE_SCENE.instantiate()
	_hosted_body.set_script(WILD_SCRIPT)
	get_parent().add_child(_hosted_body)
	_hosted_body.populate(str(creature.get("species_id")), _player)
	_hosted_body.set("instance", creature)
	_hosted_body.set("trainer_owned", true)
	_hosted_body.set("aggressive", false)
	_hosted_body.configure(MATH.config().get("wild", {}))
	_hosted_body.global_position = state.position
	_hosted_body.set_physics_process(false)
	_hosted_body.collision_layer = 0
	_hosted_body.collision_mask = 0
	_ally = party.call("active")
	_ally_body.visible = true
	_ally_body.set("instance", _ally)
	var members: Array[RefCounted] = []
	# Active first is the production manager's begin() contract.
	members.append(_ally)
	for member: RefCounted in party.call("members"):
		if member != _ally:
			members.append(member)
	_hosted_trainer = str(state.trainer_id)
	remove_hosted_observer(_hosted_trainer)
	_set_exploration_active(false)
	var started: bool = _manager.begin(_player, _hosted_body, _ally_body, members, _camera_rig, null, true)
	if not started:
		_hosted_trainer = ""
		_set_exploration_active(true)
		return false
	# The manager stages the local party; enemy location remains host truth.
	_hosted_body.global_position = state.position
	_hosted_body.set_physics_process(false)
	_manager.bind_encounter(link, str(state.record.encounter_id), "trainer")
	return true


func update_hosted_opponent(state: Dictionary) -> void:
	if is_instance_valid(_hosted_body):
		_hosted_body.global_position = state.position
		_hosted_body.rotation.y = float(state.get("yaw", 0.0))


func hosted_telegraph(seconds: float) -> void:
	if _manager.is_fighting():
		_manager.call("_on_enemy_telegraph", seconds)


func hosted_swing() -> void:
	if is_instance_valid(_hosted_body):
		_hosted_body.call("play_attack")


func observe_hosted_state(state: Dictionary) -> void:
	var id := str(state.trainer_id)
	var record: Dictionary = state.get("record", {})
	var round_id := str(record.get("encounter_id", ""))
	var row: Dictionary = _observed_hosted.get(id, {})
	if str(row.get("round", "")) != round_id:
		remove_hosted_observer(id)
		var creature := TRAINERS.creature_for(state.get("team_entry", {}))
		if creature == null:
			return
		var body: Node3D = CREATURE_SCENE.instantiate()
		body.set_script(WILD_SCRIPT)
		get_parent().add_child(body)
		body.populate(str(creature.get("species_id")), _player)
		body.set("instance", creature)
		body.set_physics_process(false)
		body.collision_layer = 0
		body.collision_mask = 0
		row = {"round": round_id, "body": body}
		_observed_hosted[id] = row
	var body: Node3D = row.body
	body.global_position = state.position
	body.rotation.y = float(state.get("yaw", 0.0))
	var creature: RefCounted = body.get("instance")
	var hp := float((record.get("opponent", {}) as Dictionary).get("hp", creature.get("hp")))
	if hp < float(creature.get("hp")):
		body.call("play_faint" if hp <= 0.0 else "play_hit")
	creature.set("hp", hp)


func observe_hosted_event(id: String, event: Dictionary) -> void:
	var row: Dictionary = _observed_hosted.get(id, {})
	var body: Node3D = row.get("body")
	if not is_instance_valid(body):
		return
	if str(event.get("kind", "")) == "swing":
		body.call("play_attack")
	elif str(event.get("kind", "")) == "telegraph":
		preload("res://scripts/combat/telegraph_glow.gd").begin(get_parent(), body.global_position, Color("ff5a3c"), 1.1, float(event.get("seconds", 0.5)))


func remove_hosted_observer(id: String) -> void:
	var row: Dictionary = _observed_hosted.get(id, {})
	var body: Node3D = row.get("body")
	if is_instance_valid(body):
		body.queue_free()
	_observed_hosted.erase(id)


func _on_combat_exited(outcome: String) -> void:
	if _hosted_trainer.is_empty():
		super._on_combat_exited(outcome)
		return
	var active: RefCounted = _manager.active_creature()
	if active != null:
		_ally = active
		var party := _party()
		var index: int = (party.call("members") as Array).find(active)
		if index >= 0 and not bool(active.get("fainted")):
			party.call("set_active", index)
	_set_exploration_active(true)
	if outcome != "won":
		_hosted_trainer = ""
	if is_instance_valid(_hosted_body):
		_hosted_body.queue_free()
	_hosted_body = null


func end_hosted_trainer(_won: bool) -> void:
	_hosted_trainer = ""
	if not _manager.is_fighting():
		_set_exploration_active(true)


func award_hosted_trainer(spec: Dictionary, peers: Array) -> void:
	# Stormwood's encounter hub owns trainer rounds even in solo play.  The
	# shared director's `_is_host()` intentionally means "an active network
	# session whose peer is host" for replicated spawn work, so it is false in
	# that ordinary offline case.  Reward authority is the broader Game/Session
	# contract: solo and the active host may commit; an active client may not.
	if _session == null or not _session.has_method("is_host") \
			or not bool(_session.call("is_host")):
		return
	for fact: Dictionary in ENCOUNTER_REWARDS.world_facts(spec, "stormwood"):
		_submit_reward_intent(fact)
	_pay_every_participant(spec, "stormwood", peers)
