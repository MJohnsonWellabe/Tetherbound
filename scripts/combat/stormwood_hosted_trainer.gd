extends Node

## One host-owned authored trainer roster. Rendering and local party control
## live in the realm hub; neither a client's victory claim nor its damage
## number can advance this roster.
const AUTHORITY := preload("res://scripts/combat/accepted_action_host.gd")
const FIGHT := preload("res://scripts/combat/stormwood_authoritative_fight.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const BODY := preload("res://scenes/creatures/creature.tscn")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const CARD := preload("res://scripts/save/water_capture_codec.gd")
var hub: Node
var spec: Dictionary
var authority := AUTHORITY.new()
var record: Dictionary = {}
var participants: Array[int] = []
var contributors: Array[int] = []
var team: Array = []
var round_index := -1
var finished := false
var centre := Vector3.ZERO
var radius := 14.0
var opponent: Node3D
var engine: Node
var _between := 0.0
var _snap_left := 0.0
var _actions: Dictionary = {}
var _cooldowns: Dictionary = {}
var _missing_since: Dictionary = {}
var _base_attack := 1.0
var _base_defence := 1.0
var _base_combat: Dictionary = {}
## Retain the actual impact decision: a later pose or a client's retained
## refusal cannot establish why an earlier input failed to finish a round.
var last_strike: Dictionary = {}

func start(owner_hub: Node, authored: Dictionary, peer: int, at: Vector3) -> bool:
	hub = owner_hub
	authority = hub.authority
	spec = authored.duplicate(true)
	team = TRAINERS.team_of(spec)
	if team.is_empty():
		return false
	centre = at
	participants.append(peer)
	contributors.append(peer)
	engine = FIGHT.new()
	add_child(engine)
	engine.telegraph.connect(func(seconds: float) -> void:
		hub.publish(self, {"kind": "telegraph", "seconds": seconds}))
	engine.swung.connect(func() -> void: hub.publish(self, {"kind": "swing"}))
	return _next_round()

func _next_round() -> bool:
	engine.stop_opponent()
	if is_instance_valid(opponent):
		opponent.queue_free()
	opponent = null
	if participants.is_empty():
		finish(false)
		return false
	round_index += 1
	if round_index >= team.size():
		finish(true)
		return true
	var creature: RefCounted = TRAINERS.creature_for(team[round_index])
	if creature == null:
		finish(false)
		return false
	var owners: Dictionary = {}
	for peer: int in participants:
		var identity := _owned_identity(peer)
		if identity.is_empty():
			finish(false)
			return false
		owners[peer] = identity
	opponent = BODY.instantiate()
	opponent.set_script(WILD)
	opponent.name = "HostedOpponent_%s_%d" % [str(spec.id), round_index]
	hub.world.add_child(opponent)
	opponent.populate(str(creature.get("species_id")), hub.actor_for(participants[0]))
	opponent.set("instance", creature)
	opponent.set("trainer_owned", true)
	opponent.set("aggressive", false)
	opponent.set("combat_override", creature.get("combat_override"))
	opponent.configure(MATH.config().get("wild", {}))
	opponent.global_position = centre
	opponent.set("home", centre)
	# Host body is collision/AI truth. Each viewing peer draws its own replica.
	opponent.visible = false
	_base_attack = float(creature.get("attack"))
	_base_defence = float(creature.get("defence"))
	_base_combat = (creature.get("combat_override") as Dictionary).duplicate(true)
	record = authority.open(participants[0], "stormwood", "trainer", {
		"species_id": creature.get("species_id"), "level": creature.get("level"),
		"hp": creature.get("hp"), "hp_max": creature.get("max_hp"), "owner_npc": spec.id,
		"card": CARD.encode(creature), "body_generation": round_index + 1},
		owners[participants[0]].uid, owners[participants[0]].character)
	for peer: int in participants.slice(1):
		authority.join(str(record.encounter_id), peer, owners[peer].uid, owners[peer].character)
	for peer: int in participants:
		if hub.director.call("_ordinary_actor_binding", str(record.encounter_id), peer, hub.body_for(peer)).is_empty():
			finish(false)
			return false
	_actions.clear()
	_cooldowns.clear()
	_apply_scaling()
	engine.start_opponent(opponent, hub.body_for(participants[0]), centre, radius, self, str(record.encounter_id))
	_snapshot()
	return true

func join(peer: int) -> void:
	if finished or participants.has(peer):
		return
	var identity := _owned_identity(peer)
	if identity.is_empty(): return
	if _between <= 0.0:
		var joined: Dictionary = authority.join(str(record.encounter_id), peer, identity.uid, identity.character)
		if joined.get("ok") != true: return
		if hub.director.call("_ordinary_actor_binding", str(record.encounter_id), peer, hub.body_for(peer)).is_empty():
			authority.leave(str(record.encounter_id), peer)
			return
	participants.append(peer)
	if not contributors.has(peer):
		contributors.append(peer)
	if _between <= 0.0:
		_apply_scaling()
	_snapshot()

## Resolve only the authenticated owner's admitted row and live deployment.
func _owned_identity(peer: int) -> Dictionary:
	if hub.session.is_host() != true or hub.session.realm_of(peer) != "stormwood" \
		or not is_instance_valid(hub.body_for(peer)): return {}
	var character := str(hub.session.call("_authority_character", peer))
	var admitted: Dictionary = hub.session.call("admitted_character_state", peer)
	var uid := str(hub.card_for(peer).get("creature_uid", ""))
	if character.is_empty() or admitted.get("character_id") != character \
		or not admitted.get("party") is Array or admitted.party.is_empty() or admitted.party.size() > 5: return {}
	var matches := 0
	for owned: Dictionary in admitted.party:
		if owned.get("uid") == uid and owned.get("fainted") == false and float(owned.get("hp", 0.0)) > 0.0:
			matches += 1
	return {"character": character, "uid": uid} if matches == 1 else {}

func move_start(peer: int, intent: Dictionary) -> Dictionary:
	var id := str(record.get("encounter_id", ""))
	if finished or _between > 0.0 or not participants.has(peer) or intent.get("encounter_id") != id \
		or intent.get("slot") not in ["quick", "charged"] or _owned_identity(peer).is_empty() \
		or hub.director.call("_host_actor_settlement_pending", id) == true:
		return {"ok": false, "kind": "move_start", "code": "unavailable", "delta": {}}
	# Reuse the admitted loadout/mastery/gear freeze and owner-save fences.
	return hub.director.call("_host_commit_encounter", intent, peer)

func acknowledge_strike(peer: int, verdict: Dictionary) -> void:
	var action_id := str(verdict.get("publication_action_id", ""))
	if not action_id.is_empty():
		authority.acknowledge_move_action_publication(str(record.encounter_id), peer, action_id, verdict)

func leave(peer: int) -> void:
	participants.erase(peer)
	if not record.is_empty():
		authority.leave(str(record.encounter_id), peer)
	if participants.is_empty():
		finish(false)
	else:
		_apply_scaling()
		_snapshot()

func strike(peer: int, intent: Dictionary) -> Dictionary:
	last_strike = {"peer": peer, "action": int(intent.get("action", 0)),
		"encounter_id": str(intent.get("encounter_id", "")),
		"round": round_index, "host_now_ms": Time.get_ticks_msec()}
	var verdict := _strike(peer, intent)
	last_strike["verdict"] = verdict.duplicate(true)
	return verdict


func burst(peer: int, intent: Dictionary) -> Dictionary:
	var refused := {"ok": false, "kind": "burst_intent", "code": "unavailable",
		"reason": "That burst is no longer available.", "delta": {}}
	if finished or _between > 0.0 or not participants.has(peer) \
			or str(intent.get("encounter_id", "")) != str(record.get("encounter_id", "")):
		return refused
	var body: Node3D = hub.body_for(peer)
	if not is_instance_valid(body):
		return refused
	var burst_cfg: Dictionary = MATH.config().get("burst", {}) as Dictionary
	var wind_cfg: Dictionary = MATH.config().get("wind", {}) as Dictionary
	var now := Time.get_ticks_msec()
	var action := int(intent.get("action", 0))
	var verdict: Dictionary = authority.authorize_burst(str(record.encounter_id), peer,
		intent, FIGHT.host_wind_profile(hub.card_for(peer)),
		float(wind_cfg.get("burst_cost", 30.0)), now,
		float(burst_cfg.get("distance", 3.0)), float(burst_cfg.get("duration", 0.2)),
		float(wind_cfg.get("regen_delay", 0.6)))
	if not bool(verdict.get("ok", false)):
		return verdict
	var delta: Dictionary = verdict.get("delta", {}) as Dictionary
	var direction_row: Array = delta.get("direction", []) as Array
	body.call("begin_combat_burst",
		Vector3(float(direction_row[0]), 0.0, float(direction_row[2])),
		float(delta.get("distance", 3.0)), float(delta.get("duration", 0.2)), action)
	_actions[peer] = action
	_cooldowns[peer] = int(delta.get("cooldown_deadline_ms", now))
	_snapshot()
	return verdict

func _strike(peer: int, intent: Dictionary) -> Dictionary:
	var refused := {"ok": false, "kind": "strike_intent", "code": "unavailable", "reason": "That attack is no longer available.", "delta": {}}
	if finished or _between > 0.0 or not participants.has(peer) or str(intent.get("encounter_id", "")) != str(record.get("encounter_id", "")):
		return refused
	var body: Node3D = hub.body_for(peer)
	if not is_instance_valid(body):
		return refused
	var card: Dictionary = hub.card_for(peer)
	var slot := str(intent.get("slot", ""))
	if not slot in ["quick", "charged"]:
		return refused
	var move_id := str(card.get("move_" + slot, ""))
	if move_id.is_empty() or move_id != str(intent.get("move_id", "")):
		return refused
	var action := int(intent.get("action", 0))
	var now := Time.get_ticks_msec()
	if action <= int(_actions.get(peer, 0)) or now < int(_cooldowns.get(peer, 0)):
		return refused
	var id := str(record.encounter_id)
	if hub.director.call("_host_actor_settlement_pending", id) == true: return refused
	var publication_binding: Dictionary = hub.director.call("_ordinary_actor_binding", id, peer, body)
	var binding: Dictionary = hub.director.call("_strike_actor_binding", id, peer, body)
	var started: Dictionary = authority.move_commit(id, peer, action)
	if publication_binding.is_empty() or binding.is_empty() or started.is_empty() \
		or started.get("resolved") == true or started.get("cancelled") == true \
		or started.get("binding") != binding:
		return refused
	var profile: Dictionary = started.move.duplicate(true)
	var wind_cfg: Dictionary = MATH.config().get("wind", {})
	var wind_cost := float(wind_cfg.get("quick_cost" if slot == "quick" else "charged_cost", 0.0))
	var wind_profile: Dictionary = FIGHT.host_wind_profile(card)
	var wind_preview: Dictionary = authority.preview_wind(str(record.encounter_id),
		peer, wind_profile, wind_cost, now)
	var checked := intent.duplicate(true)
	checked["move"] = profile
	# The host's current facing, as well as its body position, owns the hit.
	checked["facing"] = body.call("facing")
	var origin: Vector3 = body.call("centre")
	var facing: Vector3 = checked["facing"]
	var target: Vector3 = opponent.call("centre")
	last_strike["geometry"] = {"origin": [origin.x, origin.y, origin.z],
		"facing": [facing.x, facing.y, facing.z],
		"target": [target.x, target.y, target.z],
		"range": float(profile.get("range", 0.0)),
		"cone_degrees": float(profile.get("cone_degrees", 0.0)),
		"windup": float(profile.get("windup", 0.0)),
		"connects": MATH.move_connects(profile, origin, facing, target)}
	authority.note_opponent_position(str(record.encounter_id), opponent.call("centre"), now)
	var verdict: Dictionary = authority.validate_strike(checked, peer, {
		"now_ms": now, "origin": body.call("centre"), "bodies": hub.body_rows(),
		"f22_actor_binding": publication_binding, "move_actor_binding": binding})
	if not bool(verdict.get("ok", false)):
		(verdict.get("delta", {}) as Dictionary).merge(wind_preview, true)
		return verdict
	# The accepted start already paid wind/resources. Arrival must not pay twice.
	(verdict.get("delta", {}) as Dictionary).merge(authority.move_resource_snapshot(id, peer, str(binding.creature_uid)), true)
	_actions[peer] = action
	_cooldowns[peer] = int(verdict.delta.get("cooldown_deadline_ms", now))
	if bool(verdict.delta.get("hit", false)):
		var target_instance: RefCounted = opponent.get("instance")
		var publication: Dictionary = authority.begin_move_action_resolution(id, peer, action,
			publication_binding, str(target_instance.get("uid")), round_index + 1)
		if publication.get("ok") != true: return refused
		var hp_before := float(target_instance.get("hp"))
		profile["started_at_ms"] = int(started.get("started_at_ms", -1))
		var damage: Dictionary = engine.host_roll_damage(card, move_id, float(profile.get("power", 9.0)), slot == "charged",
			{"move": profile, "action_id": str(started.action_id), "striker_body": body,
			"body_generation": round_index + 1, "direction": target - origin})
		if damage.is_empty(): return refused
		verdict.delta.merge(damage, true)
		verdict.delta.merge(authority.credit_move_hit(id, peer, action,
			maxf(0.0, hp_before - float(damage.get("hp", hp_before))), str(target_instance.get("uid")),
			hp_before, round_index + 1, float(card.get("hp", 0.0))), true)
		authority.set_opponent_hp(str(record.encounter_id), float(damage.hp), float(damage.hp_max))
		verdict["publication_action_id"] = str(publication.action_id)
		if not authority.record_move_action_outcome(id, peer, str(publication.action_id), damage, verdict): return refused
		hub.session.call("foundation_combat_mastery", hub.director, id, peer, action)
		if bool(damage.get("killed", false)):
			if not authority.publish_move_action_terminal(id, peer, str(publication.action_id), "done"): return refused
			engine.stop_opponent()
			_between = 2.4
	_snapshot()
	return verdict

func _process(delta: float) -> void:
	if finished or hub == null:
		return
	if authority.move_action_publication_pending(str(record.get("encounter_id", ""))): return
	for peer: int in participants.duplicate():
		if hub.session.realm_of(peer) != "stormwood":
			leave(peer)
		elif not is_instance_valid(hub.body_for(peer)):
			# A legitimate party switch replaces the deployment proxy. Allow its
			# reliable announcement to reconstruct the body before treating it as
			# a withdrawal; missing bodies cannot strike or receive enemy hits.
			if not _missing_since.has(peer):
				_missing_since[peer] = Time.get_ticks_msec()
			elif Time.get_ticks_msec() - int(_missing_since[peer]) > 2000:
				leave(peer)
		else:
			_missing_since.erase(peer)
	if finished:
		return
	if _between > 0.0:
		_between -= delta
		if _between <= 0.0:
			_next_round()
		return
	if is_instance_valid(opponent):
		var target: Node3D
		var distance := INF
		for peer: int in participants:
			var body: Node3D = hub.body_for(peer)
			if is_instance_valid(body) and body.global_position.distance_squared_to(opponent.global_position) < distance:
				target = body
				distance = body.global_position.distance_squared_to(opponent.global_position)
		engine.set_target_body(target)
	_snap_left -= delta
	if _snap_left <= 0.0:
		_snap_left = 0.1
		_snapshot()

func _apply_scaling() -> void:
	if not is_instance_valid(opponent):
		return
	var scaling := AUTHORITY.scaling_for(participants.size())
	var creature: RefCounted = opponent.get("instance")
	creature.set("attack", _base_attack * float(scaling.stat_multiplier))
	creature.set("defence", _base_defence * float(scaling.stat_multiplier))
	var combat := _base_combat.duplicate(true)
	if not is_equal_approx(float(scaling.attack_cooldown_multiplier), 1.0):
		combat["attack_cooldown"] = float(combat.get("attack_cooldown", MATH.config().get("enemy_trainer", {}).get("attack_cooldown", 2.0))) * float(scaling.attack_cooldown_multiplier)
	creature.set("combat_override", combat)
	opponent.set("combat_override", combat)
	opponent.call("refresh_combat_profile")

func snapshot() -> Dictionary:
	return {"kind": "state", "trainer_id": str(spec.id), "record": authority.record(str(record.get("encounter_id", ""))).duplicate(true), "round": round_index,
		"total": team.size(), "team_entry": team[round_index].duplicate(true) if round_index >= 0 and round_index < team.size() else {},
		"position": opponent.global_position if is_instance_valid(opponent) else centre,
		"yaw": opponent.rotation.y if is_instance_valid(opponent) else 0.0,
		"participants": participants.duplicate(), "finished": finished}

func _snapshot() -> void:
	if is_instance_valid(opponent) and not record.is_empty():
		authority.note_opponent_position(str(record.encounter_id), opponent.call("centre"), Time.get_ticks_msec())
	hub.publish(self, snapshot())

func finish(won: bool) -> void:
	if finished:
		return
	finished = true
	if engine != null:
		engine.stop_opponent()
	hub.publish(self, {"kind": "finished", "won": won})
	hub.trainer_finished(self, won)
	if is_instance_valid(opponent):
		opponent.queue_free()

func is_encounter_host() -> bool:
	return true

func local_encounter_peer_id() -> int:
	return 0

func host_pick_struck_participant(id: String, cfg: Dictionary, origin: Vector3, facing: Vector3) -> Dictionary:
	var candidates: Array = []
	for peer: int in participants:
		var body: Node3D = hub.body_for(peer)
		if is_instance_valid(body) and MATH.move_connects(cfg, origin, facing, body.call("centre")):
			candidates.append({"peer_id": peer, "distance": origin.distance_to(body.call("centre"))})
	var pick := authority.pick_struck(id, candidates)
	if pick.is_empty():
		return {}
	var peer := int(pick.peer_id)
	authority.note_struck(id, peer)
	return {"peer_id": peer, "card": hub.card_for(peer)}

func host_deliver_enemy_hit(_id: String, peer: int, payload: Dictionary) -> void:
	hub.send_to(peer, {"kind": "enemy_hit", "trainer_id": str(spec.id), "encounter_id": str(record.encounter_id), "payload": payload})
