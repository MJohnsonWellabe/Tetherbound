extends Node3D

## F03, Juno's lost companion. One ordinary Meadowhart body, three places:
##
##   held      -- beside the unbeaten Tether patrol (`defeat_flag` unset)
##   waiting   -- still beside the patrol once it is beaten, offering
##                "Lead the Meadowhart home" (one tap, never a hold)
##   escorting -- kinematically following the player who tapped it
##   reunited  -- beside Juno, once the world says `return_flag`
##
## Leading her home IS the activity: she reaches Juno, the host commits the
## world flag `return_flag` once, every peer re-poses her from the world store
## and the leader hears Juno's thanks. The patrol's battle reward stays on the
## trainer (it is what `defeat_flag` pays); nothing new is paid on return.
##
## Authority. The escort is decided on the host only: who leads (one at a
## time), leash, disconnect/realm cancel and arrival. Clients mirror the leader
## id the host broadcasts and run the same follow step on their own copy for
## display. The ESCORT IS TRANSIENT: it is never saved and never sent in a
## snapshot. A save taken mid-escort reloads with her waiting by the patrol and
## the prompt back; a legacy save with the patrol beaten but no return flag
## loads the same way, so the player can still lead her home and nothing is
## completed retroactively.
##
## The body keeps collision and physics disabled (no second AI); the pure
## rules live in `lost_companion_escort_rules.gd`.

const CONFIG_PATH := "res://data/config/lost_companion_reunion.json"
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
const STORY_LEDGER := preload("res://scripts/story/story_ledger.gd")
const RULES := preload("res://scripts/world/lost_companion_escort_rules.gd")

const HOST_PEER_ID := 1
const CHANNEL_LEDGER := 1

var _world: Node3D
var _trainers: Node3D
var _body: Node3D
var _prompt: Node3D
var _config: Dictionary = {}
var _progression: RefCounted
var _revision := -1
## Transient by design (see header): the peer leading her, 0 for nobody.
var _escort_peer := 0
var _fight_hides := 0
var _return_submitted := false
var _acknowledgement_pending := false
var _speed := 0.0
## The return is announced on the transition into `reunited` while somebody
## was leading -- never on the first pose or on a load that is already home.
var _was_reunited := false
var _primed := false
## Trainer id -> spawn pose, see `_trainer_anchor`.
var _anchors := {}
var _state_requested := false


func build(world: Node3D, trainers: Node3D) -> void:
	_world = world
	_trainers = trainers
	_anchors.clear()
	add_to_group("progression_restore")
	if bool(world.get("simulation_only")):
		return
	_config = _load_config()
	if _config.is_empty():
		return
	_body = CREATURE_SCENE.instantiate() as Node3D
	_body.name = "RescuedMeadowhart"
	_body.set_script(CREATURE_BODY)
	add_child(_body)
	_body.call("setup", str(_config.get("species", "meadowhart")), false)
	# Run after creature_body's own visibility callback, which would otherwise
	# re-enable physics when the realm is shown. Leave the model's AnimationPlayer
	# processing normally while this parent supplies its locomotion role below.
	_body.visibility_changed.connect(_disable_simulation)
	_disable_simulation()

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * float(_config.get("prompt_height_m", 1.2))
	_prompt.call("configure", str(_config.get("prompt_label", "Lead the Meadowhart home")),
		float(_config.get("prompt_radius_m", 3.6)), false)
	# The beaten patrol stands a few metres away; leading her wins the press.
	_prompt.set("priority", int(_config.get("prompt_priority", 5)))
	_prompt.connect("activated", _on_prompt_activated)
	_body.add_child(_prompt)

	# Combat rings hide soft occluders inside them; she stands aside the same
	# way (see `set_fight_hidden`) and resumes following after the fight.
	add_to_group(HARVEST_NODE.FIGHT_RING_OCCLUDER_GROUP)
	_connect_session()
	# Record both spawn poses now, before either trainer walks anywhere.
	_trainer_anchor(str(_config.get("patrol_trainer_id", "")))
	_trainer_anchor(str(_config.get("owner_trainer_id", "")))
	refresh_position(true)


func _disable_simulation() -> void:
	_body.set_physics_process(false)
	_body.set("collision_layer", 0)
	_body.set("collision_mask", 0)
	var collider := _body.get_node_or_null("Collision") as CollisionShape3D
	if collider != null:
		collider.set_deferred("disabled", true)


func _process(delta: float) -> void:
	if _body == null:
		return
	var current := _progression_store()
	var revision := int(current.get("revision")) if current != null else -1
	if current != _progression or revision != _revision:
		refresh_position()
	if not _state_requested and not _is_host() and _can_rpc():
		# A joiner may arrive mid-escort. Ask the host who leads, once this
		# node exists and the session can carry the answer.
		_state_requested = true
		_send_to_host("_rpc_request_state")
	_speed = 0.0
	if phase() == RULES.PHASE_ESCORTING and _fight_hides == 0:
		_follow(delta)
	# Physics is disabled for this display; drive the existing creature
	# animator from this node's own kinematic speed (idle, walk or run).
	var animator: RefCounted = _body.get("_animator") as RefCounted
	if animator != null:
		animator.call("tick", delta, _speed, float(_config.get("max_speed_mps", 10.0)))
	_try_acknowledgement()


func restore_progression_from_game(_from_game: Node) -> void:
	refresh_position(true)


## Where she is in her story, from the two world facts and the live escort.
func phase() -> String:
	return RULES.phase(_has_flag("defeat_flag"), _has_flag("return_flag"), _escort_peer != 0)


func escort_peer() -> int:
	return _escort_peer


## Small verification seam: re-pose from the world store; returns whether the
## reunited placement is active. An escort in progress keeps her where she is.
func refresh_position(force: bool = false) -> bool:
	if _body == null or _config.is_empty():
		return false
	var current := _progression_store()
	var revision := int(current.get("revision")) if current != null else -1
	if not force and current == _progression and revision == _revision:
		return is_reunited()
	_progression = current
	_revision = revision
	var reunited := is_reunited()
	if reunited and _primed and not _was_reunited and _escort_peer != 0:
		_announce_return(_escort_peer == _local_peer_id())
	_was_reunited = reunited
	_primed = true
	if reunited:
		_escort_peer = 0
	elif not _has_flag("defeat_flag"):
		# A reload to a pre-rescue state cannot keep a leader.
		_escort_peer = 0
	_refresh_prompt()
	if phase() == RULES.PHASE_ESCORTING:
		return false
	_place(reunited)
	return reunited


func _place(reunited: bool) -> void:
	var id_key := "owner_trainer_id" if reunited else "patrol_trainer_id"
	var offset_key := "reunited_offset" if reunited else "waiting_offset"
	var yaw_key := "reunited_yaw_deg" if reunited else "waiting_yaw_deg"
	var trainer_id := str(_config.get(id_key, ""))
	var anchor := _trainer_anchor(trainer_id)
	var authored_offset := _offset(offset_key)
	var offset := Vector3(authored_offset.x, 0.0, authored_offset.y).rotated(Vector3.UP, float(anchor.yaw))
	var anchor_at: Vector2 = anchor.position
	var x := anchor_at.x + offset.x
	var z := anchor_at.y + offset.z
	var ground := float(_world.call("ground_height_at", x, z))
	if not is_finite(ground):
		push_warning("lost companion has no finite ground beside trainer '%s'" % trainer_id)
		_body.visible = false
		return
	_set_body_at(Vector3(x, ground, z))
	_body.rotation.y = anchor.yaw + deg_to_rad(float(_config.get(yaw_key, 0.0)))
	_body.visible = _fight_hides == 0


func _set_body_at(at: Vector3) -> void:
	# This node travels with her so a combat ring measures her real position.
	global_position = at
	_body.position = Vector3.ZERO


func is_reunited() -> bool:
	return _has_flag("return_flag")


func presentation_position() -> Vector3:
	return _body.global_position if _body != null else Vector3.ZERO


## `combat_arena.gd` hides every soft occluder inside a fight ring. Counted, so
## two overlapping rings do not show her while one is still open. While hidden
## she neither follows nor is leash-checked; she resumes after the fight.
func set_fight_hidden(hidden: bool) -> void:
	_fight_hides = maxi(0, _fight_hides + (1 if hidden else -1))
	if _body != null:
		_body.visible = _fight_hides == 0


# --- following -------------------------------------------------------------

func _follow(delta: float) -> void:
	var leader := _leader_body(_escort_peer)
	var from := _body.global_position
	if _is_host():
		var distance := RULES.flat_distance(from, leader.global_position) if leader != null else INF
		if RULES.should_cancel(leader != null, _peer_realm(_escort_peer), _world_realm(),
				distance, float(_config.get("leash_m", 40.0))):
			_host_end_escort("leash" if leader != null else "gone")
			return
	if leader == null:
		return
	var target := RULES.trailing_point(leader.global_position, from,
		float(_config.get("follow_distance_m", 3.0)))
	var next := RULES.follow_step(from, target, delta,
		float(_config.get("max_speed_mps", 10.0)), float(_config.get("catchup_gain", 3.0)))
	var ground := float(_world.call("ground_height_at", next.x, next.z))
	if is_finite(ground):
		next.y = ground
	var moved := Vector3(next.x - from.x, 0.0, next.z - from.z)
	if moved.length() > 0.001:
		_body.rotation.y = atan2(moved.x, moved.z)
	_speed = moved.length() / delta if delta > 0.0 else 0.0
	_set_body_at(next)
	if _is_host() and not _return_submitted and RULES.arrived(next,
			_owner_position(), float(_config.get("arrival_radius_m", 6.0))):
		_host_complete_return()


func _owner_position() -> Vector3:
	var anchor := _trainer_anchor(str(_config.get("owner_trainer_id", "")))
	var at: Vector2 = anchor.position
	return Vector3(at.x, 0.0, at.y)


func _leader_body(peer: int) -> Node3D:
	if peer == 0:
		return null
	if peer == _local_peer_id():
		var rig := _world.call("local_rig") as Node3D if _world.has_method("local_rig") else null
		return rig if rig != null and is_instance_valid(rig) and rig.is_inside_tree() else null
	for node in get_tree().get_nodes_in_group(&"remote_trainer"):
		if node is Node3D and is_instance_valid(node) and (node as Node).is_inside_tree() \
				and int(node.get("peer_id")) == peer:
			return node as Node3D
	return null


# --- the prompt and the host's decisions -----------------------------------------

func _refresh_prompt() -> void:
	if _prompt == null or not is_instance_valid(_prompt):
		return
	var current := phase()
	# The leader does not keep a prompt at their heels (it would steal every
	# interact press on the walk home); anybody else near her may still press
	# and hears who is leading.
	var offer := current == RULES.PHASE_WAITING \
		or (current == RULES.PHASE_ESCORTING and _escort_peer != _local_peer_id())
	_prompt.call("set_enabled", offer)


func _on_prompt_activated() -> void:
	if _is_host():
		_host_request_escort(_local_peer_id())
	else:
		_send_to_host("_rpc_request_escort")


func _host_request_escort(peer: int) -> void:
	var leader := _leader_body(peer)
	var distance := RULES.flat_distance(leader.global_position, _body.global_position) \
		if leader != null else INF
	var verdict := RULES.start_verdict(_has_flag("defeat_flag"), _has_flag("return_flag"),
		_escort_peer, peer, distance, float(_config.get("leash_m", 40.0)))
	if not bool(verdict.get("ok", false)):
		_tell(peer, _refusal_line(str(verdict.get("code", "")), str(verdict.get("reason", ""))))
		return
	_return_submitted = false
	_apply_escort(peer)
	_broadcast_escort()
	_tell(peer, _line("start", "The Meadowhart falls in behind you. Lead her to Juno in the high pasture."))


func _host_end_escort(why: String) -> void:
	var leader := _escort_peer
	if leader == 0:
		return
	_apply_escort(0)
	_broadcast_escort()
	if why == "leash":
		_tell(leader, _line("leash", "The Meadowhart lost sight of you and went back to wait by the patrol."))


## Host only. The world flag is the one durable fact; its arrival re-poses
## every peer and plays the acknowledgement (`refresh_position`). Idempotent:
## the ledger answers a second submission with a no-op.
func _host_complete_return() -> void:
	_return_submitted = true
	var verdict := STORY_LEDGER.set_world_flag(self, str(_config.get("return_flag", "")))
	if not bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false)):
		_return_submitted = false


func _apply_escort(peer: int) -> void:
	if peer != 0 and (is_reunited() or not _has_flag("defeat_flag")):
		peer = 0
	var was := _escort_peer
	_escort_peer = peer
	_refresh_prompt()
	if peer == 0 and was != 0 and not is_reunited():
		_place(false)


## Every peer that watched the escort sees the toast; the leader also hears
## Juno's thanks. Runs once, on the world flag's arrival (host commit or the
## client's delta), so a second arrival or a reload announces nothing.
func _announce_return(led_here: bool) -> void:
	var game := _game()
	if game != null:
		game.call("push_world_message", _line("returned", "Juno's Meadowhart is home in the high pasture."))
	if led_here:
		_acknowledgement_pending = true


func _try_acknowledgement() -> void:
	if not _acknowledgement_pending:
		return
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		_acknowledgement_pending = false
		return
	if bool(panel.call("is_open")):
		return
	if bool(panel.call("start", str(_config.get("acknowledgement", "")))):
		_acknowledgement_pending = false


# --- network -------------------------------------------------------------------

func _connect_session() -> void:
	var session := _session()
	if session == null:
		return
	if session.has_signal("peer_left") and not session.is_connected("peer_left", _on_peer_left):
		session.connect("peer_left", _on_peer_left)
	if session.has_signal("peer_realm_changed") \
			and not session.is_connected("peer_realm_changed", _on_peer_realm_changed):
		session.connect("peer_realm_changed", _on_peer_realm_changed)


func _on_peer_left(peer_id: int) -> void:
	if _is_host() and peer_id == _escort_peer:
		_host_end_escort("gone")


func _on_peer_realm_changed(peer_id: int, _from_realm: String, to_realm: String) -> void:
	if _is_host() and peer_id == _escort_peer and to_realm != _world_realm():
		_host_end_escort("gone")


func _broadcast_escort() -> void:
	if _can_rpc():
		rpc("_rpc_escort_state", _escort_peer)


func _send_to_host(method: String) -> void:
	if _can_rpc():
		rpc_id(HOST_PEER_ID, method)


## A readable line for one peer: a toast here, or addressed to that client.
func _tell(peer: int, text: String) -> void:
	if text.is_empty():
		return
	if peer == _local_peer_id():
		var game := _game()
		if game != null:
			game.call("push_world_message", text)
	elif _can_rpc():
		rpc_id(peer, "_rpc_tell", text)


## Client -> host. The leader is the transport's sender, never the payload.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_request_escort() -> void:
	if _is_host() and _body != null:
		_host_request_escort(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_request_state() -> void:
	if _is_host() and _can_rpc():
		rpc_id(multiplayer.get_remote_sender_id(), "_rpc_escort_state", _escort_peer)


## Host -> clients: who leads now (0 = nobody).
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_escort_state(peer: int) -> void:
	if _is_host() or _body == null:
		return
	_apply_escort(peer)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_tell(text: String) -> void:
	var game := _game()
	if game != null:
		game.call("push_world_message", text)


func _can_rpc() -> bool:
	if not is_inside_tree() or multiplayer == null or not multiplayer.has_multiplayer_peer():
		return false
	var game := _game()
	return game != null and bool(game.call("is_multi_peer"))


# --- reads -----------------------------------------------------------------------

func _has_flag(key: String) -> bool:
	var id := str(_config.get(key, ""))
	return not id.is_empty() and _progression != null and bool(_progression.call("has", id))


func _is_host() -> bool:
	var game := _game()
	return game == null or bool(game.call("is_host"))


func _local_peer_id() -> int:
	var session := _session()
	return int(session.call("local_peer_id")) if session != null else HOST_PEER_ID


func _peer_realm(peer: int) -> String:
	var session := _session()
	if session == null or not session.has_method("realm_of"):
		return ""
	return str(session.call("realm_of", peer))


func _world_realm() -> String:
	return str(_world.call("world_realm")) if _world != null and _world.has_method("world_realm") else ""


func _line(key: String, fallback: String) -> String:
	return str((_config.get("lines", {}) as Dictionary).get(key, fallback))


func _refusal_line(code: String, fallback: String) -> String:
	return str((_config.get("refusal_lines", {}) as Dictionary).get(code, fallback))


func _game() -> Node:
	return get_node_or_null(^"/root/Game") if is_inside_tree() else null


func _session() -> Node:
	var game := _game()
	return game.get("session") as Node if game != null else null


## The trainer's SPAWN pose, recorded once per id. Trainers step into fight
## rings and wander, so reading the live body each time moved her waiting
## spot (5.5 m after the patrol fight) and the arrival point, and could put
## them in different places on different peers. The spawn pose comes from the
## same deterministic layout on every peer and every reload.
func _trainer_anchor(id: String) -> Dictionary:
	if _anchors.has(id):
		return _anchors[id]
	var anchor := {}
	if _trainers != null and _trainers.has_method("body_for"):
		var body := _trainers.call("body_for", id) as Node3D
		if body != null and body.is_inside_tree():
			anchor = {"position": Vector2(body.global_position.x, body.global_position.z), "yaw": body.global_rotation.y}
	if anchor.is_empty():
		var spec := TRAINERS.trainer(id)
		var position: Array = spec.get("position", [])
		anchor = {
			"position": Vector2(float(position[0]), float(position[1])) if position.size() >= 2 else Vector2.ZERO,
			"yaw": deg_to_rad(float(spec.get("facing_deg", 0.0)))
		}
	else:
		# Only a real spawned body is cached; the spec fallback is retried
		# in case the trainer spawns later.
		_anchors[id] = anchor
	return anchor


func _offset(key: String) -> Vector2:
	var values: Array = _config.get(key, [])
	return Vector2(float(values[0]), float(values[1])) if values.size() >= 2 else Vector2.ZERO


func _progression_store() -> RefCounted:
	var game := get_node_or_null("/root/Game")
	return game.get("progression") if game != null else null


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("cannot open %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		push_error("%s is not a JSON object" % CONFIG_PATH)
		return {}
	return parsed as Dictionary
