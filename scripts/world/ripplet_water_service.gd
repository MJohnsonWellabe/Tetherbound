extends Node

## F37's transient authority seam. Requests carry an operation and creature UID,
## never authority, progression, stamina, position or velocity. No durable unlock.
const RULE := preload("res://scripts/player/ripplet_traversal.gd")
var world: Node3D
var _answered: Dictionary = {}
var _pending: Dictionary = {}
var _diving_until: Dictionary = {}
var _motion: Dictionary = {}

func _physics_process(_delta: float) -> void:
	if not get_node("/root/Game").is_host(): return
	var live: Dictionary = {}
	for proxy: Node in get_tree().get_nodes_in_group("remote_creature"):
		var peer := int(proxy.owner_peer_id)
		if peer == multiplayer.get_unique_id() or str(proxy.species_id) != "ripplet": continue
		var realm := ""
		for trainer: Node in get_tree().get_nodes_in_group("remote_trainer"):
			if trainer.get_multiplayer_authority() == peer: realm = str(trainer.net_realm)
		if realm != "water": continue
		live[peer] = true
		var now := Time.get_ticks_msec() / 1000.0
		var at: Vector3 = proxy.net_position
		var sample: Dictionary = _motion.get(peer, {"at":at,"time":now,"valid":true})
		var seconds := now - float(sample.time)
		if seconds >= float(RULE.config().validation_window_s):
			sample.valid = RULE.valid_motion(sample.at,at,seconds,world.current_at(at).length())
			sample.at = at
			sample.time = now
			if not sample.valid:
				for permit: String in _diving_until.keys():
					if permit.begins_with(str(peer) + ":"): _diving_until.erase(permit)
				_rpc_force_surface.rpc_id(peer)
		_motion[peer] = sample
	for peer: int in _motion.keys():
		if not live.has(peer): _motion.erase(peer)

@rpc("authority", "call_remote", "reliable")
func _rpc_force_surface() -> void:
	var riding := world.get_node_or_null("RidingController")
	if riding != null: riding.surface()

func _ready() -> void:
	add_to_group("ripplet_water_service")

func _process(_delta: float) -> void:
	for token: String in _pending.keys():
		if Time.get_ticks_msec() - int(_pending[token].started_ms) > 3000:
			_pending.erase(token)
			var riding := world.get_node_or_null("RidingController")
			if riding != null: riding.set("_ripplet_requesting", false)
			get_node("/root/Game").push_world_message("Ripplet traversal timed out. Try again.")

func request(action: String, uid: String) -> bool:
	var token := Crypto.new().generate_random_bytes(16).hex_encode()
	_pending[token] = {"action": action, "uid": uid, "started_ms":Time.get_ticks_msec()}
	if get_node("/root/Game").is_host():
		_handle(multiplayer.get_unique_id(), token, action, uid)
	else:
		_rpc_request.rpc_id(1, token, action, uid)
	return true

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request(token: String, action: String, uid: String) -> void:
	if not get_node("/root/Game").is_host(): return
	_handle(multiplayer.get_remote_sender_id(), token, action, uid)

func actor_context(peer: int, uid: String) -> Dictionary:
	var game := get_node("/root/Game")
	var session: Node = game.session
	var admitted: Dictionary = session.admitted_character_state(peer)
	var row := RULE.owned(admitted, uid)
	if row.is_empty(): return {}
	var actor: Node3D
	var body: Node3D
	var mounted := false
	var diving := false
	var realm := ""
	if peer == session.local_peer_id():
		actor = world.local_rig()
		realm = str(game.current_realm)
		var riding := world.get_node_or_null("RidingController")
		var director := world.get_node_or_null("EncounterDirector")
		if director != null and director.ally_instance() != null and director.ally_instance().uid == uid:
			body = director.ally_body()
		mounted = riding != null and riding.is_mounted() and riding.mount_body() == body
		diving = mounted and bool(riding.diving)
	else:
		var director := world.get_node_or_null("EncounterDirector")
		var deployed: Dictionary = director.get("_deployed_by") if director != null else {}
		if str(deployed.get(peer, {}).get("creature_uid", "")) != uid: return {}
		for proxy: Node in get_tree().get_nodes_in_group("remote_trainer"):
			if proxy.get_multiplayer_authority() == peer:
				actor = proxy as Node3D
				realm = str(proxy.net_realm)
				mounted = bool(proxy.net_riding)
				diving = bool(proxy.net_aquatic.get("ripplet_diving", false))
				break
		for proxy: Node in get_tree().get_nodes_in_group("remote_creature"):
			if int(proxy.owner_peer_id) == peer and str(proxy.species_id) == "ripplet":
				body = proxy as Node3D
				break
	if actor == null or body == null: return {}
	var at := body.global_position
	var seals := preload("res://scripts/world/water_gate_seals.gd")
	var sealed := not seals.closed_seal_at(seals.compile(world.config), seals.load_rules(), at, game.world.flags).is_empty()
	return {"peer":peer, "character_id":str(admitted.get("character_id", "")), "realm":realm,
		"position":actor.global_position, "admitted":admitted,
		"combat":peer_in_combat(peer), "mounted_uid":uid if mounted else "",
		"diving":diving and float(_diving_until.get(str(peer) + ":" + uid, 0.0)) > Time.get_ticks_msec() / 1000.0,
		"motion_valid":bool(_motion.get(peer, {}).get("valid", true)),
		"in_water":world.water_depth_at(at) >= 1.2,
		"dive_clearance":world.water_depth_at(at) >= float(RULE.config().minimum_dive_depth_m),
		"sealed":sealed, "mount_reachable":actor.global_position.distance_to(at) <= 6.0}

func _handle(peer: int, token: String, action: String, uid: String) -> void:
	if token.length() != 32: return
	if _answered.size() >= 4096: _answered.erase(_answered.keys()[0])
	var key := "%d:%s" % [peer, token]
	var verdict: Dictionary = _answered.get(key, {})
	if verdict.is_empty():
		verdict = RULE.action({"action":action, "creature_uid":uid}, actor_context(peer, uid))
		_answered[key] = verdict
		if verdict.get("ok", false):
			var permit := str(peer) + ":" + uid
			if action == "dive" and float(_diving_until.get(permit, 0.0)) <= Time.get_ticks_msec() / 1000.0:
				_diving_until[permit] = Time.get_ticks_msec() / 1000.0 + float(RULE.config().dive_seconds)
			elif action in ["mount", "surface"]: _diving_until.erase(permit)
	if peer == multiplayer.get_unique_id():
		_accept(token, verdict)
	else:
		_rpc_answer.rpc_id(peer, token, verdict)

@rpc("authority", "call_remote", "reliable")
func _rpc_answer(token: String, verdict: Dictionary) -> void:
	_accept(token, verdict)

func _accept(token: String, verdict: Dictionary) -> void:
	var expected: Dictionary = _pending.get(token, {})
	if expected.is_empty(): return
	_pending.erase(token)
	var riding := world.get_node_or_null("RidingController")
	if riding != null: riding.set("_ripplet_requesting", false)
	if not verdict.get("ok", false):
		get_node("/root/Game").push_world_message(str(verdict.get("reason", "")))
		return
	if verdict.get("uid") != expected.uid or verdict.get("action") != expected.action: return
	if riding != null: riding.apply_ripplet_action(expected.action, expected.uid)

func peer_in_combat(peer: int) -> bool:
	# Water's director is a subclass. Inspect the inherited authority service,
	# rather than the exact-script test in the general Altar placement helper.
	var director := world.get_node_or_null("EncounterDirector")
	if director == null: return true
	director._ensure_encounter_arbiters()
	var host: RefCounted = director.get("_encounter_host")
	if host == null: return true
	for id: String in host.encounters:
		var record: Dictionary = host.encounters[id]
		if record.get("phase") != "done" and host.is_participant(id, peer): return true
	if peer == get_node("/root/Game").session.local_peer_id():
		var manager := world.get_node_or_null("CombatManager")
		return manager == null or manager.is_fighting() or director.trainer_battle_active()
	return false

func is_submerged(peer: int) -> bool:
	if peer == get_node("/root/Game").session.local_peer_id():
		var riding := world.get_node_or_null("RidingController")
		return riding != null and bool(riding.diving)
	var director := world.get_node_or_null("EncounterDirector")
	if director == null or str(director.get("_deployed_by").get(peer, {}).get("species_id", "")) != "ripplet": return false
	for proxy: Node in get_tree().get_nodes_in_group("remote_trainer"):
		if proxy.get_multiplayer_authority() == peer and str(proxy.net_realm) == "water" and bool(proxy.net_riding):
			return bool(proxy.net_aquatic.get("ripplet_diving",false)) or proxy.global_position.y < world.field.water_level() - 2.0
	return false
