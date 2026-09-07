extends Node

## One collision owner: the trainer CharacterBody3D. This component replaces
## the ordinary locomotion tick while deployed; it never carries/hides it.
## World-authored AABBs are true 3D volumes, including progression restrictions.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const ANCHOR_ARBITER := preload("res://scripts/net/fly_anchor_arbiter.gd")
const CONFIG_PATH := "res://data/config/fly_traversal.json"
const SESSION_PATH := ^"/root/Game/Session"

signal state_changed(state: String)
signal landed(position: Vector3, species_id: String)
signal recovered(reason: String)
signal denied(reason: String)
## Stage B lane 6.C. The host answered a landing-anchor proposal. `ok` false
## carries the host's `reason`; the smoke and the HUD both read this rather
## than polling, because a refusal is a thing that HAPPENED and polling a
## boolean cannot tell one refusal from two.
signal anchor_decided(ok: bool, anchor: Vector3, code: String, reason: String)

var state := "grounded"
var last_denial := ""
var config: Dictionary = {}
var updrafts: Array[Dictionary] = []
var restrictions: Array[Dictionary] = []
var safe_anchor := Vector3.INF
var safe_realm := ""
var flight_seconds := 0.0
var _player: CharacterBody3D
var _rig: Node3D
var _model: Node3D
var _game: Node
var _creature: RefCounted
var _mentor_loaner: RefCounted
var _last_flight_used_loaner := false
var _visual: Node3D
var _trial := AABB()
var _trial_enabled := false
var _saved_camera: Dictionary = {}
var _saved_snap := 0.4
var _saved_shape: Shape3D
var _saved_shape_position := Vector3.ZERO
var _grip_bones: Array = []
var _bird_skeleton: Skeleton3D
var _presentation: Dictionary = {}
## --- Stage B lane 6.C: the anchor the host has to agree to ------------------
##
## `safe_anchor` above is the COMMITTED anchor and its meaning has not changed:
## it is the place `recover_to_anchor()` will drop this trainer, and the place
## `can_launch()` insists exists before a glide may start. What changed is who
## is allowed to write it. Solo, and on the host, nothing at all changed --
## there is no second process with an opinion, and the host's own position IS
## the host's position, so validating it against itself would only add a way to
## fail. On a CLIENT the value below is a proposal until the host answers, and
## the anchor that finally lands here is the host's own, off the host's ground.
var _anchor_pending := false
## The claim currently with the host, kept so a verdict can be matched to what
## it was about and a late answer to a superseded proposal can be ignored.
var _anchor_pending_claim := Vector3.INF
## Whether the outstanding proposal is a LANDING (a glide that just ended)
## rather than an ordinary step onto new ground while walking. Only a refused
## landing pulls the player back: a walking client whose anchor the host does
## not like keeps walking, because it never left the ground the host is
## simulating it on.
var _anchor_pending_is_landing := false
## Seconds since the outstanding proposal was sent, so a host that never
## answers (a packet lost, a host mid-scene-swap) frees the client to ask
## again rather than wedging it in "pending" for the session. `pending` is not
## a refusal and is never treated as one.
var _anchor_pending_for := 0.0
## Counters and the last text, for the net smoke and for a HUD line. Nothing
## branches on them.
var _anchor_proposals := 0
var _anchor_accepts := 0
var _anchor_refusals := 0
var _anchor_last_code := ""
## Whether the anchor currently committed was granted by the HOST, as opposed
## to written locally while this process was solo or the host itself.
##
## This exists because of a real hole the net smoke found on its first run. A
## peer boots solo, walks around, and writes itself an anchor -- correctly,
## because there is nobody else to ask. It then JOINS. The committed anchor is
## now a client-authored one, and `_propose_anchor()`'s movement rate limit
## would never re-offer it: the player is standing where they were, well inside
## `resubmit_m`, so the pre-session anchor would quietly survive the join and
## remain this client's recovery point for the whole session. Which is the
## exact authority hole §2 closes, reached by waiting rather than by lying.
var _anchor_host_granted := false
## Set for exactly one frame by the touchdown branch of `physics_step()`, and
## consumed by the next `_propose_anchor()`. It is the whole difference between
## "this client just came out of the sky here" -- which the host must agree to,
## and which is pulled back when it does not -- and "this client walked eight
## metres", which is ordinary movement the host is already simulating.
var _touched_down := false


func setup(player: CharacterBody3D, rig: Node3D, model: Node3D) -> void:
	_player = player
	_rig = rig
	_model = model
	_game = get_node_or_null(^"/root/Game")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	config = raw if raw is Dictionary else {}
	if not InputMap.has_action("fly_descend"):
		InputMap.add_action("fly_descend", 0.2)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_C
		InputMap.action_add_event("fly_descend", key)
		var trigger := InputEventJoypadMotion.new()
		trigger.axis = JOY_AXIS_TRIGGER_LEFT
		trigger.axis_value = 1.0
		InputMap.action_add_event("fly_descend", trigger)


func is_flying() -> bool:
	return state in ["glide", "climb", "descent", "exhausted"]


func register_updraft(id: String, bounds: AABB, lift_speed: float, ceiling_y: float, requires_flag: String = "") -> void:
	updrafts.append({"id": id, "bounds": bounds, "speed": lift_speed, "ceiling": ceiling_y, "requires_flag": requires_flag})


func register_restriction(id: String, bounds: AABB, requires_flag: String) -> void:
	restrictions.append({"id": id, "bounds": bounds, "requires_flag": requires_flag})


## The trial grants no global unlock. Leaving its volume before earning Fly is
## blocked by the same swept volume check as story gates. It is never saved.
func set_trial_authorization(bounds: AABB) -> void:
	_trial = bounds
	_trial_enabled = bounds.size.x > 0.0 and bounds.size.y > 0.0 and bounds.size.z > 0.0


func _has_flag(flag: String) -> bool:
	if flag.is_empty():
		return true
	var progression: Variant = _game.get("progression") if is_instance_valid(_game) else null
	return progression != null and bool(progression.call("has", flag))


func _unlocked() -> bool:
	return _has_flag(str(config.get("unlock_flag", "fly_traversal_unlocked")))


func _realm() -> String:
	return str(_game.get("current_realm")) if is_instance_valid(_game) else ""


## Realm powers are per-player state, so Fly reads them from this player's Game
## instance rather than from a global/autoload.  Phase 1 accepts the ordinary
## cost (1.0) through Skyborne's free cost (0.0); malformed relic data cannot
## make traversal restore stamina or cost more than its authored base values.
static func stamina_cost_multiplier(active_power: Dictionary) -> float:
	return clampf(float(active_power.get("fly_stamina_multiplier", 1.0)), 0.0, 1.0)


static func adjusted_stamina_cost(base_cost: float, active_power: Dictionary) -> float:
	return maxf(0.0, base_cost) * stamina_cost_multiplier(active_power)


func _active_realm_power() -> Dictionary:
	if not is_instance_valid(_game):
		return {}
	var hearts: Variant = _game.get("realm_hearts")
	if hearts == null or not hearts.has_method("active_power"):
		return {}
	var power: Variant = hearts.call("active_power")
	return power.duplicate(true) if power is Dictionary else {}


func _flight_stamina_multiplier() -> float:
	return stamina_cost_multiplier(_active_realm_power())


## Prefer the party's existing active carrier. If a valid five-member Meadows
## team has no Fly species, Maela's transient story carrier prevents a chapter
## deadlock. It is never added to Party, saved, caught, or treated as a sixth
## owned creature.
func eligible_creature() -> RefCounted:
	var party: Variant = _game.get("party") if is_instance_valid(_game) else null
	if party != null:
		var active: RefCounted = party.call("active")
		if active != null and not bool(active.get("fainted")) and not bool(active.get("resting")) \
				and (party.call("members") as Array).has(active):
			var capability := SPECIES.fly_capability(str(active.get("species_id")))
			if bool(capability.get("can_carry", false)):
				return active
	var loaner: Dictionary = config.get("mentor_loaner", {})
	var loaner_available := (_trial_enabled and bool(loaner.get("available_during_trial", false))) \
		or (_unlocked() and bool(loaner.get("available_after_unlock", false)))
	if not loaner_available or _realm() != str(loaner.get("realm_id", "cloudreach")):
		return null
	var species_id := str(loaner.get("species_id", ""))
	if species_id.is_empty() or not bool(SPECIES.fly_capability(species_id).get("can_carry", false)):
		return null
	if _mentor_loaner == null or str(_mentor_loaner.get("species_id")) != species_id:
		_mentor_loaner = SPECIES.spawn(species_id)
	return _mentor_loaner


func last_flight_used_mentor_loaner() -> bool:
	return _last_flight_used_loaner


func can_launch() -> String:
	if _player == null or _player.is_on_floor():
		return "Jump, then press Jump again to deploy Fly."
	return launch_blockers()


## Everything `can_launch()` asks EXCEPT "are you off the ground yet".
##
## Split out for Stage B lane 6.C's net smoke, which has to find somewhere a
## launch would be legal BEFORE it jumps -- a peer that boots inside Grandpa's
## farmhouse has a ceiling over it, and every launch attempt there is refused
## for "no room overhead" while `can_launch()`, asked from the ground, only
## ever says "jump first". A harness that re-implemented the overhead check to
## find a clear spot would be a second copy of it, so the harness asks THIS
## instead and the game keeps one answer.
func launch_blockers() -> String:
	if _player == null:
		return "No trainer to launch."
	if bool(_player.call("is_carried")) or not bool(_player.call("locomotion_enabled")):
		return "Fly is unavailable while riding or in combat."
	if not _unlocked() and not (_trial_enabled and _trial.has_point(_player.global_position)):
		return "Complete the Windscar flight trial to unlock Fly."
	if eligible_creature() == null:
		return "No healthy Fly carrier is available here."
	var active_power := _active_realm_power()
	var minimum_stamina := adjusted_stamina_cost(float(config.get("minimum_launch_stamina", 18.0)), active_power)
	if minimum_stamina > 0.0 and float(_player.get("vitals").get("stamina")) < minimum_stamina:
		return "Rest before launching: not enough stamina."
	if safe_anchor == Vector3.INF or safe_realm != _realm():
		return "Touch down on safe ground before launching."
	# Lane 6.C. A client whose landing the host has not answered yet still
	# holds the PREVIOUS granted anchor, so every check above passes and it
	# could launch again from ground nobody has agreed to -- and then claim
	# that ground as its recovery point for the rest of the session. Waiting is
	# not a refusal and does not read as one; it is the one frame or two the
	# round trip takes.
	if _anchor_pending:
		return "Steady -- your landing is still being confirmed."
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _flight_shape()
	query.transform = _player.global_transform.translated(Vector3.UP * float(config.get("collision_height_m", 4.5)) * 0.5)
	query.collision_mask = _player.collision_mask
	query.exclude = [_player.get_rid()]
	if not _player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		return "Find a clear launch with room for your companion overhead."
	return _restricted_reason(_player.global_position, _player.global_position)


func physics_step(delta: float, input_owned: bool) -> bool:
	if _anchor_pending:
		_anchor_pending_for += delta
	if not is_flying():
		if not input_owned and Input.is_action_just_pressed("jump") and not _player.is_on_floor():
			var reason := can_launch()
			if reason.is_empty():
				_launch()
			else:
				_deny(reason)
		if not is_flying():
			return false
	_player.call("begin_environment_velocity_step")
	flight_seconds += delta
	var vitals: RefCounted = _player.get("vitals")
	if eligible_creature() != _creature or (_flight_stamina_multiplier() > 0.0 and float(vitals.get("stamina")) <= 0.0) or flight_seconds >= float(config.get("maximum_flight_seconds", 180.0)):
		_set_state("exhausted")
	var stick := Vector2.ZERO if input_owned else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var view_basis := Basis.IDENTITY
	if _rig != null and _rig.has_method("planar_basis"):
		view_basis = _rig.call("planar_basis")
	var direction := view_basis * Vector3(stick.x, 0.0, stick.y)
	var horizontal := Vector3(_player.velocity.x, 0.0, _player.velocity.z)
	horizontal = horizontal.move_toward(direction * float(config.get("speed_mps", 16.0)), float(config.get("acceleration_mps2", 12.0)) * delta)
	var vertical := -float(config.get("sink_mps", 2.0))
	if state == "exhausted":
		vertical = -float(config.get("exhausted_sink_mps", 9.0))
	elif not input_owned and Input.is_action_pressed("fly_descend"):
		_set_state("descent")
		vertical = -float(config.get("descent_mps", 8.0))
	else:
		_set_state("glide")
		if not input_owned and Input.is_action_pressed("jump"):
			for draft: Dictionary in updrafts:
				var bounds: AABB = draft["bounds"]
				var ceiling := minf(float(draft["ceiling"]), bounds.end.y) - 2.0
				if bounds.has_point(_player.global_position) and _player.global_position.y < ceiling and _has_flag(str(draft["requires_flag"])):
					vertical = minf(float(draft["speed"]), float(config.get("maximum_updraft_mps", 18.0)))
					vertical = minf(vertical, maxf(0.0, (ceiling - _player.global_position.y) / maxf(delta, 0.001)))
					_set_state("climb")
					break
	_player.velocity = Vector3(horizontal.x, move_toward(_player.velocity.y, vertical, float(config.get("vertical_acceleration_mps2", 12.0)) * delta), horizontal.z)
	# A ceiling is enforced on actual velocity too, so inertia cannot drift over
	# the current's authored roof when the climb input remains held.
	if state == "climb":
		_player.velocity.y = minf(_player.velocity.y, vertical)
	var restriction := _restricted_reason(_player.global_position, _player.global_position + _player.velocity * delta)
	if not restriction.is_empty():
		_deny(restriction)
		_player.velocity.x = 0.0
		_player.velocity.z = 0.0
		_player.velocity.y = minf(_player.velocity.y, 0.0)
		if not _restricted_reason(_player.global_position, _player.global_position + _player.velocity * delta).is_empty():
			_player.velocity = Vector3.ZERO
			if recover_to_anchor(restriction):
				return true
	else:
		last_denial = ""
	var spend := float(config.get("climb_stamina_per_second", 1.6)) if state == "climb" else float(config.get("stamina_per_second", 1.0))
	var skills_game := get_node_or_null("/root/Game")
	if skills_game != null and skills_game.get("local") != null:
		spend *= float(skills_game.get("local").skills.efficiency("flying"))
	vitals.call("spend_traversal", adjusted_stamina_cost(spend * delta, _active_realm_power()))
	var velocity_before_environment := _player.velocity
	_player.call("apply_environment_velocity_modifiers", delta)
	# External wind cannot bypass authored swept no-fly restrictions.
	var external_restriction := "" if _player.velocity.is_equal_approx(velocity_before_environment) else _restricted_reason(_player.global_position, _player.global_position + _player.velocity * delta)
	if not external_restriction.is_empty():
		_deny(external_restriction)
		_player.velocity = Vector3.ZERO
	_player.move_and_slide()
	_player.call("finish_environment_velocity_step", not external_restriction.is_empty())
	if horizontal.length() > 0.2:
		_player.call("_face", horizontal.normalized(), delta)
	if _visual != null and _model != null:
		_visual.rotation.y = _model.rotation.y
		_pose_bird()
		_align_grip()
	if _player.is_on_floor():
		var species_id := str(_creature.get("species_id")) if _creature != null else ""
		_finish("grounded")
		# Lane 6.C: the ONE call to `observe_ground()` that is a landing rather
		# than a step. On a client the anchor it proposes is the one the host
		# can pull back from.
		_touched_down = true
		observe_ground()
		landed.emit(_player.global_position, species_id)
	# Cloudreach intentionally descends hundreds of metres between authored
	# shelves. Altitude below the previous landing is not itself a fall while
	# the carrier, stamina and flight clock still provide normal control. Keep
	# the verified-anchor fallback for exhausted/invalid flight only.
	elif state == "exhausted" and safe_anchor != Vector3.INF \
			and _player.global_position.y < safe_anchor.y - float(config.get("recovery_drop_m", 100.0)):
		recover_to_anchor("The wind carried you back to your last safe landing.")
	return true


func _restricted_reason(from: Vector3, to: Vector3) -> String:
	var margin := float(config.get("body_clearance_m", 0.5))
	var height := float(config.get("collision_height_m", 4.5))
	if not _unlocked() and _trial_enabled and (not _trial.grow(-margin).has_point(to) or not _trial.has_point(to + Vector3.UP * height) or not _trial.has_point(from)):
		return "Stay inside the marked flight trial."
	for restriction: Dictionary in restrictions:
		if _has_flag(str(restriction["requires_flag"])):
			continue
		var box: AABB = restriction["bounds"]
		# Sweep the whole hanging silhouette, not only its feet/origin.
		box.position -= Vector3(margin, height, margin)
		box.size += Vector3(2.0 * margin, height + margin, 2.0 * margin)
		if box.has_point(from) or box.has_point(to) or box.intersects_segment(from, to) != null:
			return "This wind route is still sealed: %s." % str(restriction["id"])
	return ""


## Take note of the ground under the trainer's feet. Called every physics frame
## by `player_controller.gd`, and once more the instant a glide touches down.
##
## Stage B lane 6.C split this in two without changing what it means. Solo and
## on the host it is the same unconditional line it always was. On a CLIENT the
## ground under this peer's feet is a PROPOSAL: it goes to the host, and only
## the host's answer writes `safe_anchor`. See `_anchor_is_the_hosts_to_give()`.
func observe_ground() -> void:
	if is_flying() or not _player.is_on_floor() or bool(_player.call("is_carried")):
		return
	_set_state("grounded")
	var here := _player.global_position
	if not _anchor_is_the_hosts_to_give():
		safe_anchor = here
		safe_realm = _realm()
		# Deliberately NOT `true`. Solo and on the host this flag is never read
		# (the branch above is the only one that runs), but a peer that later
		# joins somebody else's session arrives holding an anchor it wrote
		# itself, and the flag is how `_propose_anchor()` knows to offer it up
		# rather than sit on it.
		_anchor_host_granted = false
		return
	_propose_anchor(here)


# --- Stage B lane 6.C: the host decides where a client may land ---------------

## Is somebody else the authority on where this trainer is standing?
##
## Asked of the SESSION, and re-asked every time. Never `multiplayer.is_server()`:
## with no session Godot installs an `OfflineMultiplayerPeer` under which
## `is_server()` is **true** and `get_unique_id()` is **1**, so a solo player
## would answer "I am the host" and a client that cached the answer at `setup()`
## -- long before anybody joined -- would answer it forever.
func _anchor_is_the_hosts_to_give() -> bool:
	var session := _session()
	if session == null:
		return false
	return bool(session.call("is_active")) and bool(session.call("is_multi_peer")) \
		and not bool(session.call("is_host"))


## `/root/Game/Session`, resolved through the tree rather than through `_game`
## when it has to be. `_game` is captured in `setup()`, which runs while the
## player rig is being built, and a node that is not yet in the tree cannot
## resolve an absolute path -- so a null `_game` must fall through to the tree
## rather than be read as "there is no session", which would silently give a
## client back the authority this whole section takes away from it.
func _session() -> Node:
	var session: Node = null
	if _game != null and is_instance_valid(_game):
		session = _game.get_node_or_null(^"Session")
	if session == null:
		var loop := Engine.get_main_loop()
		if loop is SceneTree:
			session = (loop as SceneTree).root.get_node_or_null(SESSION_PATH)
	if session == null or not session.has_method("is_host"):
		return null
	return session


## This peer's own outbound trainer proxy -- the node the host holds a copy of,
## and therefore the only thing in this process with a line to the host's own
## opinion of where this trainer is. Resolved by AUTHORITY out of the group
## rather than by name: the node's name is `trainer_spawn.gd`'s business, and
## the local peer id is exactly what authority already encodes.
func _own_proxy() -> Node:
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return null
	for body in (loop as SceneTree).get_nodes_in_group(&"remote_trainer"):
		if is_instance_valid(body) and (body as Node).is_multiplayer_authority():
			return body
	return null


## Send one landing-anchor proposal, or decide there is nothing worth asking.
##
## Rate-limited by MOVEMENT rather than by a clock: an anchor is only worth
## re-asking about once the player has actually walked away from the one the
## host already granted. A trainer standing still asks once and then never
## again, and a trainer crossing a field asks about every `resubmit_m` of it.
func _propose_anchor(here: Vector3) -> void:
	var landing := _touched_down
	_touched_down = false
	if _anchor_pending:
		# `pending` is not a refusal. Wait for the answer, unless the host has
		# had long enough that the packet is more likely lost than late.
		if _anchor_pending_for < float(_anchor_config().get("pending_timeout_s", 5.0)):
			return
		_anchor_pending = false
	if not landing and _anchor_host_granted and safe_realm == _realm() \
			and safe_anchor != Vector3.INF \
			and here.distance_to(safe_anchor) < float(_anchor_config().get("resubmit_m", 8.0)):
		return
	var proxy := _own_proxy()
	if proxy == null or not proxy.has_method("request_landing_anchor"):
		# No session body to ask through yet (a spawn that has not landed, a
		# peer mid-join). The anchor stays whatever the host last granted;
		# `can_launch()` already refuses a launch with none, which is the
		# correct behaviour rather than a silent local grant.
		return
	_anchor_pending = true
	_anchor_pending_claim = here
	_anchor_pending_is_landing = landing
	_anchor_pending_for = 0.0
	_anchor_proposals += 1
	proxy.call("request_landing_anchor", here, _realm())


## The host answered. Called by this peer's own trainer proxy; public so a
## headless test can drive the same door without a session.
##
## A refused LANDING is the only branch that moves the player, and it moves
## them to the anchor the host has already granted -- which is by construction
## a place the host said yes to. A refused proposal made while merely walking
## changes nothing at all: the player never left ground the host is already
## simulating them on, so there is nothing to put right.
func apply_anchor_verdict(ok: bool, anchor: Vector3, code: String, reason: String) -> void:
	var was_landing := _anchor_pending_is_landing
	_anchor_pending = false
	_anchor_pending_is_landing = false
	_anchor_pending_claim = Vector3.INF
	_anchor_pending_for = 0.0
	_anchor_last_code = code
	if ok:
		_anchor_accepts += 1
		safe_anchor = anchor
		safe_realm = _realm()
		_anchor_host_granted = true
		anchor_decided.emit(true, anchor, code, reason)
		return
	_anchor_refusals += 1
	_deny(reason)
	anchor_decided.emit(false, anchor, code, reason)
	if was_landing:
		recover_to_anchor(reason)


## What the smoke and the HUD read. Deliberately a snapshot rather than the
## live fields, so a caller cannot write one of them by accident.
func anchor_report() -> Dictionary:
	return {
		"anchor": [safe_anchor.x, safe_anchor.y, safe_anchor.z] if safe_anchor != Vector3.INF else [],
		"realm": safe_realm,
		"pending": _anchor_pending,
		"host_granted": _anchor_host_granted,
		"host_validated": _anchor_is_the_hosts_to_give(),
		"proposals": _anchor_proposals,
		"accepts": _anchor_accepts,
		"refusals": _anchor_refusals,
		"last_code": _anchor_last_code,
		"last_denial": last_denial,
	}


func _anchor_config() -> Dictionary:
	var block: Variant = config.get("landing_anchor", {})
	return block if block is Dictionary else {}


func set_recovery_anchor(position: Vector3, realm: String) -> bool:
	if not _player.is_on_floor() or _player.global_position.distance_to(position) > 1.0 or realm != _realm():
		return false
	safe_anchor = position
	safe_realm = realm
	return true


func _launch() -> void:
	_creature = eligible_creature()
	_last_flight_used_loaner = _creature != null and _creature == _mentor_loaner
	last_denial = ""
	flight_seconds = 0.0
	_saved_snap = _player.floor_snap_length
	_player.floor_snap_length = 0.0
	var collider := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collider != null:
		_saved_shape = collider.shape
		_saved_shape_position = collider.position
		collider.shape = _flight_shape()
		collider.position = Vector3.UP * float(config.get("collision_height_m", 4.5)) * 0.5
	_player.get("vitals").call("spend_traversal", adjusted_stamina_cost(float(config.get("launch_stamina", 8.0)), _active_realm_power()))
	_set_state("glide")
	_build_visual(SPECIES.fly_capability(str(_creature.get("species_id"))))
	if _model != null and _model.has_method("set_fly_hang"):
		_model.call("set_fly_hang", true, config.get("hang_pose", {}))
	_pose_bird()
	_align_grip()
	if _rig != null and _rig.has_method("set_target"):
		_saved_camera = {"distance": _rig.get("_distance"), "height": _rig.get("_height")}
		_rig.call("set_target", _player, {"distance": config.get("camera_distance", 7.5), "height": config.get("camera_height", 2.0)})


func _finish(next: String) -> void:
	_player.floor_snap_length = _saved_snap
	var collider := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collider != null and _saved_shape != null:
		collider.shape = _saved_shape
		collider.position = _saved_shape_position
		_saved_shape = null
	if is_instance_valid(_visual):
		_visual.queue_free()
	_visual = null
	_bird_skeleton = null
	if _model != null and _model.has_method("set_fly_hang"):
		_model.call("set_fly_hang", false)
	if _rig != null and _rig.has_method("set_target"):
		_rig.call("set_target", _player, _saved_camera)
	_creature = null
	_set_state(next)


## Riding owns the next camera/collision transition. End Fly before the
## carrier saves the ground collision state, so dismount cannot retain it.
func end_for_carrier() -> void:
	if is_flying():
		_finish("grounded")


func _set_state(next: String) -> void:
	if state != next:
		state = next
		state_changed.emit(state)


func _deny(reason: String) -> void:
	if last_denial != reason:
		last_denial = reason
		denied.emit(reason)


func recover_to_anchor(reason: String) -> bool:
	if safe_anchor == Vector3.INF or safe_realm != _realm():
		return false
	# This ray is local to a previously stood-on anchor. Never ask a world's
	# highest-XZ height function: Cloudreach has bridges and stacked plateaus.
	var query := PhysicsRayQueryParameters3D.create(safe_anchor + Vector3.UP, safe_anchor + Vector3.DOWN * 2.0, _player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit["normal"] as Vector3).y < cos(_player.floor_max_angle):
		return false
	_finish("recovery")
	_player.global_position = (hit["position"] as Vector3) + Vector3.UP * 0.08
	_player.velocity = Vector3.ZERO
	if _rig != null:
		_rig.global_position = _player.global_position
	recovered.emit(reason)
	return true


func save_data() -> Dictionary:
	var party: Variant = _game.get("party") if _game != null else null
	var index := -1
	if party != null:
		index = (party.call("members") as Array).find(party.call("active"))
	return {"version": 1, "mode": state, "realm": _realm(), "safe_anchor": [] if safe_anchor == Vector3.INF else [safe_anchor.x, safe_anchor.y, safe_anchor.z], "velocity": [_player.velocity.x, _player.velocity.y, _player.velocity.z], "stamina_fraction": float(_player.get("vitals").call("stamina_fraction")), "active_index": index}


func apply_pending_load() -> void:
	if _game == null or not _game.has_meta("pending_fly_load"):
		return
	var payload: Dictionary = _game.get_meta("pending_fly_load")
	if str(payload.get("realm", "")) != _realm():
		return
	_game.remove_meta("pending_fly_load")
	if is_flying():
		_finish("recovery")
	var raw: Array = payload.get("safe_anchor", [])
	if raw.size() == 3:
		safe_anchor = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		safe_realm = _realm()
	var vitals: RefCounted = _player.get("vitals")
	vitals.set("stamina", float(vitals.get("max_stamina")) * float(payload.get("stamina_fraction", 1.0)))
	_player.velocity = Vector3.ZERO
	_set_state("recovery")


## `fly_traversal.json`, parsed, without an instance. Stage B lane 6.C needs
## two blocks of it on a body that has no fly controller of its own -- a remote
## trainer's carrier pose, and the host's landing tolerances -- and reading the
## file in a second place is how two readings of one file start to disagree.
static func shared_config() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return raw if raw is Dictionary else {}


## The hanging pose the trainer's arms are put in under a carrier.
static func hang_pose() -> Dictionary:
	var block: Variant = shared_config().get("hang_pose", {})
	return block if block is Dictionary else {}


## The host's landing-anchor tolerances; see `fly_anchor_arbiter.gd`.
static func landing_anchor_config() -> Dictionary:
	var block: Variant = shared_config().get("landing_anchor", {})
	return block if block is Dictionary else {}


## The species of the creature currently carrying this trainer, or "" when
## nobody is. Stage B lane 6.C reads it to tell every OTHER peer which bird to
## draw over their friend's head -- the picture on a remote body is built from
## the same `fly_capability` block this one is, so the two cannot drift.
func carrier_species_id() -> String:
	return str(_creature.get("species_id")) if _creature != null else ""


## Build the carrier's art, parented to nothing, and hand it back.
##
## Static and unparented on purpose. Stage B lane 6.C needs exactly this node
## over a REMOTE trainer's head -- `remote_trainer.gd` has no fly controller,
## no `_player` and no business growing a second copy of this code -- and the
## surest way for a friend's carrier to end up a different size, a different
## height or a different bird from the one its owner is hanging off is for two
## files to build it. So there is one builder and two callers.
##
## Returns null when the capability names no model or the model is missing,
## which is the same silence `_build_visual()` has always kept: a species with
## no art hangs the trainer from nothing rather than crashing the flight.
static func make_carrier_art(capability: Dictionary) -> Node3D:
	var path := str(capability.get("model", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		return null
	var visual := Node3D.new()
	visual.name = "FlyCompanionPresentation"
	var art := scene.instantiate() as Node3D
	visual.add_child(art)
	var bounds := AABB()
	var first := true
	for mesh: Node in art.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		var box := art.global_transform.affine_inverse() * instance.global_transform * instance.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if bounds.size.y > 0.001:
		var scale_factor := float(capability.get("height_m", 2.1)) / bounds.size.y
		art.scale *= scale_factor
		art.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
	var offset: Array = capability.get("feet_offset", [0.0, 2.45, 0.0])
	visual.position = Vector3(float(offset[0]), float(offset[1]), float(offset[2]))
	for animation: Node in art.find_children("*", "AnimationPlayer", true, false):
		var player := animation as AnimationPlayer
		if bool(capability.get("procedural_wing_pose", false)):
			player.stop()
			continue
		var clip := str(capability.get("animation", "idle"))
		if player.has_animation(clip):
			player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			player.play(clip)
	return visual


## The skeleton inside a node `make_carrier_art()` built, or null. Shared for
## the same reason the builder is: the wing pose and the grip alignment both
## need it, here and on a remote body.
static func carrier_skeleton(visual: Node3D) -> Skeleton3D:
	if visual == null or not is_instance_valid(visual):
		return null
	var skeletons := visual.find_children("*", "Skeleton3D", true, false)
	return skeletons[0] as Skeleton3D if not skeletons.is_empty() else null


func _build_visual(capability: Dictionary) -> void:
	_presentation = capability
	_visual = make_carrier_art(capability)
	if _visual == null:
		return
	_player.add_child(_visual)
	_grip_bones = capability.get("grip_bones", [])
	_bird_skeleton = carrier_skeleton(_visual)


func _flight_shape() -> CapsuleShape3D:
	var shape := CapsuleShape3D.new()
	shape.radius = float(config.get("collision_radius_m", 0.7))
	shape.height = float(config.get("collision_height_m", 4.5))
	return shape


## Align actual installed leg joints with the trainer's posed wrists. Species
## can replace their art/socket names without changing movement or ownership.
func _align_grip() -> void:
	align_carrier_grip(_visual, _bird_skeleton, _model, _grip_bones)


## Static and shared with `remote_trainer.gd`, for `make_carrier_art()`'s
## reason. A friend's carrier whose feet are not on their friend's wrists is
## the exact "two bodies drifting apart" this wave was given, one rig smaller.
static func align_carrier_grip(visual: Node3D, rig: Skeleton3D, model: Node,
		grip_bones: Array) -> void:
	if visual == null or not is_instance_valid(visual) or rig == null \
			or model == null or not model.has_method("skeleton") or grip_bones.size() != 2:
		return
	var trainer: Skeleton3D = model.call("skeleton")
	if trainer == null:
		return
	var hands := Vector3.ZERO
	var feet := Vector3.ZERO
	for i in 2:
		var hand := trainer.find_bone("LeftHand" if i == 0 else "RightHand")
		var foot := rig.find_bone(str(grip_bones[i]))
		if hand < 0 or foot < 0:
			return
		hands += trainer.to_global(trainer.get_bone_global_pose(hand).origin) * 0.5
		feet += rig.to_global(rig.get_bone_global_pose(foot).origin) * 0.5
	visual.global_position += hands - feet


func _pose_bird() -> void:
	pose_carrier_wings(_bird_skeleton, _presentation, flight_seconds)


## One wingbeat, at `seconds` into the flight. Static and shared with
## `remote_trainer.gd` for `make_carrier_art()`'s reason: a friend's carrier
## flapping to a second implementation's rhythm is a friend's carrier that
## looks wrong, and nobody would ever find out which of the two was.
static func pose_carrier_wings(rig: Skeleton3D, capability: Dictionary, seconds: float) -> void:
	if rig == null or not is_instance_valid(rig) or not bool(capability.get("procedural_wing_pose", false)):
		return
	var flap := sin(seconds * float(capability.get("wing_flap_frequency", 2.2)) * TAU) * float(capability.get("wing_flap_amplitude", 0.16))
	for side: String in ["l", "r"]:
		for section: String in ["upper", "fore"]:
			var bone := rig.find_bone("wing_%s_%s" % [section, side])
			var next := rig.find_bone("wing_%s_%s" % ["fore" if section == "upper" else "tip", side])
			if bone < 0 or next < 0:
				continue
			var side_sign := signf(rig.get_bone_global_rest(bone).origin.x)
			var parent := rig.get_bone_parent(bone)
			var parent_basis := rig.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
			var rest := rig.get_bone_rest(bone).basis
			var axis := rig.get_bone_rest(next).origin.normalized()
			var desired := (parent_basis.inverse() * Vector3(side_sign, flap, 0.0)).normalized()
			var aim := Quaternion((rest * axis).normalized(), desired)
			rig.set_bone_pose_rotation(bone, aim * rest.get_rotation_quaternion())
