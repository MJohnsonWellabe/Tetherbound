extends RefCounted

## Disclosed initial route/position mechanics fixtures for named actual network
## journeys. No earned chapter credit, synthetic permit or saved ACK is supplied.
const DISCLOSURE := "initial_hall_position_and_open_route_no_earned_credit"
const ROUTES := {"session_host_first_realm": "cloudreach", "water_alpha": "tidewake",
	"stormwood_livewire": "stormwood", "stormwood_finalized_death": "stormwood", "stormwood_hosted_trainers": "stormwood",
	"cloudreach_riding": "cloudreach", "stormwood_realms": "stormwood", "water_return": "stormwood",
	"stormwood_glass_for_bryn": "stormwood", "veridian_same_five": "tidewake", "f15_dock": "tidewake"}
const RETURNS := ["cloudreach_riding", "stormwood_realms", "water_return"]
const HALL := preload("res://scripts/world/crossing_hall.gd")
const HOME_KEY := preload("res://scripts/world/home_key.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const TELEPORT := preload("res://scripts/creatures/remote_creature.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const META := "portal_smoke_initial_fixture"
var reply: Dictionary = {}
var request_id := ""
var _home_scope: Dictionary = {}
var _home_use_id := ""

static func selected(args: Dictionary) -> bool:
	return args.get("actual_portal_fixture") == DISCLOSURE

static func prepare(tree: SceneTree, args: Dictionary, budget: int) -> Dictionary:
	var regression: String = str(args.get("portal_regression", ""))
	var arch_id: String = str(ROUTES.get(regression, ""))
	var initial_realm: String = "water" if regression == "water_return" else "meadows"
	var game: Node = tree.root.get_node_or_null(^"Game")
	var session: Node = game.get("session") as Node if game != null else null
	if not selected(args) or arch_id.is_empty() or game == null or session == null \
		or session.call("is_active") == true or session.get("_preparing_client") == true \
		or game.get("current_realm") != initial_realm or tree.has_meta(META):
		return {"verdict": "FAIL", "detail": "Initial portal fixture requires a named isolated initial realm owner before host/join"}
	# Read an already installed service only; never create a stream or service
	# to make this fixture eligible. These are network admission/host cursors,
	# not the ordinary isolated solo care clock.
	var passive: RefCounted = session.get("_owner_passive")
	if passive != null and (not (passive.get("hosts") as Dictionary).is_empty() \
		or not (passive.get("local") as Dictionary).is_empty()):
		return {"verdict": "FAIL", "detail": "Initial portal fixture cannot replace a retained network baseline"}
	var scene: Node = tree.current_scene
	var arch: Node3D
	for node: Node in tree.get_nodes_in_group("crossing_halls"):
		if scene != null and scene.is_ancestor_of(node) and node.get_script() == HALL:
			var candidate: Node3D = node.call("arch", arch_id) as Node3D
			if candidate != null:
				if arch != null: return {"verdict": "FAIL", "detail": "Ambiguous actual Hall arch"}
				arch = candidate
	var approach: Node3D = arch.get_node_or_null(^"Approach") as Node3D if arch != null else null
	var player: CharacterBody3D = game.call("find_player") as CharacterBody3D
	if scene == null or player == null or not scene.is_ancestor_of(player) \
		or (initial_realm == "meadows" and approach == null):
		return {"verdict": "FAIL", "detail": "Actual authored Hall approach/player unavailable"}
	var started: int = Engine.get_physics_frames()
	var config: Dictionary = preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json")
	var proximity: float = float(config.arch.interaction_radius_m)
	var before: Vector3 = player.global_position
	# Only initial placement is a fixture. The ordinary controller must supply
	# real walkable contact before its sampled pose becomes the initial source.
	if initial_realm == "meadows":
		TELEPORT.teleport_body(player, approach.global_position + Vector3.UP * 2.0)
		player.velocity = Vector3.ZERO
	var grounded := false
	while Engine.get_physics_frames() - started < budget:
		await tree.physics_frame
		if not is_instance_valid(player) or tree.current_scene != scene: break
		if player.is_on_floor() and player.get_floor_normal().angle_to(Vector3.UP) <= player.floor_max_angle \
			and (initial_realm == "water" or player.global_position.distance_to(arch.global_position) <= proximity):
			grounded = true
			break
	if not grounded: return {"verdict": "FAIL", "detail": "Initial Hall fixture did not reach actual supported arch proximity"}
	var sampled: Vector3 = player.global_position
	var fly: Node = player.get("fly_controller") as Node
	if fly == null or fly.call("set_recovery_anchor", sampled, initial_realm) != true:
		return {"verdict": "FAIL", "detail": "Actual grounded initial recovery anchor refused"}
	var world: RefCounted = game.get("world")
	var route: Dictionary = (world.get("redesign_world") as Dictionary).duplicate(true)
	var opened: Array = (route.get("portal_unlocks", []) as Array).duplicate()
	if not opened.has(arch_id): opened.append(arch_id)
	route.portal_unlocks = opened
	if not STATE.validate("world", route).is_empty():
		return {"verdict": "FAIL", "detail": "Initial canonical route fixture is invalid"}
	world.set("redesign_world", route)
	if regression in RETURNS:
		var inventory: RefCounted = game.get("local").get("inventory")
		if inventory.call("count", "home_key") == 0: inventory.call("add", "home_key", 1)
		if inventory.call("count", "home_key") != 1:
			return {"verdict": "FAIL", "detail": "Disclosed initial Home Key fixture could not install exactly one key"}
	var model: Node3D = player.get_node_or_null(^"Model") as Node3D
	var rig: Node = scene.get_node_or_null(^"CameraRig")
	var facing: float = model.global_rotation.y if model != null else player.global_rotation.y
	# Explicit initial pose fixture only, before any admission/passive baseline.
	game.set("saved_player_pose", {"realm": initial_realm, "position": [sampled.x, sampled.y, sampled.z],
		"model_yaw": facing, "camera_yaw": float(rig.get("yaw")) if rig != null else facing,
		"camera_pitch": float(rig.get("pitch")) if rig != null else 0.0})
	var cost: int = Engine.get_physics_frames() - started
	tree.set_meta(META, {"regression": regression, "arch_id": arch_id, "frames": cost,
		"game": weakref(game), "owner": weakref(game.get("local"))})
	return {"verdict": "PASS", "detail": "Disclosed initial actual ground/route fixture; return cases include an initial Home Key; no earned credit",
		"data": {"fixture_disclosure": DISCLOSURE, "arch_path": str(arch.get_path()) if arch != null else "", "arch_id": arch_id,
			"initial_realm": initial_realm, "initial_home_key": regression in RETURNS,
			"before": [before.x, before.y, before.z], "sampled_ground": [sampled.x, sampled.y, sampled.z], "frames": cost}}

static func preparation_frames(tree: SceneTree, args: Dictionary) -> int:
	var initial: Dictionary = tree.get_meta(META, {})
	var game: Node = tree.root.get_node_or_null(^"Game")
	if initial.is_empty() or initial.get("regression") != args.get("portal_regression") \
		or initial.game.get_ref() != game or game == null or initial.owner.get_ref() != game.get("local"):
		return -1
	return int(initial.frames)

func travel(tree: SceneTree, args: Dictionary, started: int, budget: int) -> Dictionary:
	var initial: Dictionary = tree.get_meta(META, {})
	var game: Node = tree.root.get_node_or_null(^"Game")
	var realm: String = str(args.get("realm", ""))
	var arch_id: String = str(initial.get("arch_id", ""))
	var returning: bool = str(initial.get("regression", "")) in RETURNS
	if preparation_frames(tree, args) < 0 \
		or (realm != ("water" if arch_id == "tidewake" else arch_id) and not (returning and realm == "meadows")):
		return {"ok": false, "reason": "Exact initial named portal fixture required"}
	if Engine.get_physics_frames() - started >= budget:
		return {"ok": false, "reason": "Original portal action budget already exhausted"}
	if initial.get("regression") == "water_return":
		# Interact's retired request is asynchronous. Observe its actual router
		# owner release, without another request, fixed sleep or second budget.
		while int(game.get("_realm_crossing_owner")) != 0 and Engine.get_physics_frames() - started < budget:
			await tree.physics_frame
			if not is_instance_valid(game) or tree.root.get_node_or_null(^"Game") != game:
				return {"ok": false, "reason": "Retired gate source lifetime changed"}
		if int(game.get("_realm_crossing_owner")) != 0 or game.get("current_realm") != "water":
			return {"ok": false, "reason": "Retired gate failed to settle refused in its actual Water origin"}
		print("PORTAL_SMOKE_RETIRED_GATE_REFUSED " + JSON.stringify({"realm": game.get("current_realm"),
			"router_owner": game.get("_realm_crossing_owner"), "sampled_physics_frame": Engine.get_physics_frames()}))
	if returning and game.get("current_realm") != "meadows":
		var home: Dictionary = await _home(tree, game, started, budget)
		if home.get("ok") != true or realm == "meadows": return home
	if realm == "meadows": return {"ok": false, "reason": "Return requires an actual Home Key trip from another realm"}
	if returning:
		var approached: Dictionary = await _walk_arch(tree, game, arch_id, started, budget)
		if approached.get("ok") != true: return approached
	if Engine.get_physics_frames() - started >= budget:
		return {"ok": false, "reason": "Original portal action budget exhausted before public request"}
	# A just-admitted guest's owner record is held (Session owns input, read by
	# the host as an open dialogue) until the host answers the groom resume
	# every snapshot apply opens; a player waits for it, so does this request.
	var session: Node = game.get("session")
	while session != null and session.has_method("owns_input") and bool(session.call("owns_input")) \
			and Engine.get_physics_frames() - started < budget:
		await tree.physics_frame
		if not is_instance_valid(game) or tree.root.get_node_or_null(^"Game") != game:
			return {"ok": false, "reason": "Portal source lifetime changed"}
	# No post-admission position, pose, map or progression writes. This public
	# request owns real policy/permit, origin BOOL, arrival BOOL and host ACK.
	game.connect("portal_action_result", _completed)
	var accepted: Dictionary = game.call("request_portal_action", {"kind": "portal_enter", "arch_id": arch_id})
	request_id = str(accepted.get("request_id", ""))
	if accepted.get("ok") == true and not request_id.is_empty():
		while reply.is_empty() and Engine.get_physics_frames() - started < budget:
			await tree.physics_frame
			if not is_instance_valid(game) or tree.root.get_node_or_null(^"Game") != game: break
	if is_instance_valid(game) and game.is_connected("portal_action_result", _completed):
		game.disconnect("portal_action_result", _completed)
	if not reply.is_empty():
		print("PORTAL_SMOKE_ACTUAL_COMPLETION " + JSON.stringify(reply))
		var ok: bool = reply.get("ok") == true and reply.get("saved") == true and reply.get("durable") == true \
			and reply.get("arrived") == true and reply.get("arrival_applied") == true \
			and reply.get("permit_id") is String and not str(reply.permit_id).is_empty()
		var reason := str(reply.get("reason", ""))
		if ok and args.has("arrival_ground_tolerance_m"):
			var ground_reason: String = await _arrival_ground(tree, str(args.get("realm", "")), float(args.arrival_ground_tolerance_m))
			if not ground_reason.is_empty():
				ok = false
				reason = ground_reason
		return {"ok": ok, "reason": reason, "completion": reply.duplicate(true)}
	return {"ok": false, "reason": str(accepted.get("reason", "Actual correlated saved/arrived completion missing within original budget"))}

## Arrival must stand on the destination's own ground under its slot, not only
## near it: |player.y - ground_height_at(player.x, player.z)| <= tolerance.
func _arrival_ground(tree: SceneTree, realm: String, tolerance: float) -> String:
	for _frame in 600:
		var world := tree.current_scene
		var player := world.get_node_or_null(^"Player") as CharacterBody3D if world != null else null
		if world != null and player != null and world.has_method("ground_height_at") \
				and (not world.has_method("world_realm") or str(world.call("world_realm")) == realm) and player.is_on_floor():
			var at := player.global_position
			var ground := float(world.call("ground_height_at", at.x, at.z))
			if not is_finite(ground): return "arrival has no ground under %s" % str(at)
			if absf(at.y - ground) > tolerance: return "arrival %.2f m from the ground under its slot (at %s, ground %.2f)" % [at.y - ground, str(at), ground]
			return ""
		await tree.physics_frame
	return "arrival never stood on the destination's floor"

func _completed(value: Dictionary) -> void:
	if value.get("request_id") == request_id and not request_id.is_empty(): reply = value.duplicate(true)

func _home(tree: SceneTree, game: Node, started: int, budget: int) -> Dictionary:
	var session: Node = game.get("session")
	# Match the arch request's existing readiness wait. Public Home Key use
	# refuses an owner hold; wait for it inside the same total travel budget.
	while session != null and session.has_method("owns_input") and bool(session.call("owns_input")) \
			and Engine.get_physics_frames() - started < budget:
		await tree.physics_frame
		if not is_instance_valid(game) or tree.root.get_node_or_null(^"Game") != game:
			return {"ok": false, "reason": "Home Key source lifetime changed before use"}
	if Engine.get_physics_frames() - started >= budget:
		return {"ok": false, "reason": "Home Key owner readiness exhausted original travel budget"}
	_home_scope = {"character_id": str(game.get("local").get("character_id")),
		"world_instance_id": str(game.get("world").get("reward_delivery_namespace")),
		"session_epoch": str(session.call("_altar_current_epoch"))}
	game.connect("portal_action_result", _home_completed)
	var used: bool = game.call("use_home_key") == true
	var key: Node = game.get_node_or_null(^"HomeKey")
	if used and key != null and key.get_script() == HOME_KEY and key.get_parent() == game:
		# Public use synchronously stores this begin ID before its deferred host
		# request/reply. No cleared finish pending ID is guessed or reconstructed.
		request_id = str(key.get("_pending"))
		while reply.is_empty() and not request_id.is_empty() and Engine.get_physics_frames() - started < budget:
			await tree.physics_frame
			if not is_instance_valid(game) or tree.root.get_node_or_null(^"Game") != game: break
	if is_instance_valid(game) and game.is_connected("portal_action_result", _home_completed):
		game.disconnect("portal_action_result", _home_completed)
	var result: Dictionary = reply.duplicate(true)
	reply.clear()
	if result.is_empty():
		var reason := "Actual Home Key raise/saved arrival did not complete within original budget"
		if not used: reason = "Public Home Key use refused: " + str(game.call("home_key_refusal"))
		elif request_id.is_empty(): reason = "Public Home Key use supplied no bound begin request"
		print("PORTAL_SMOKE_ACTUAL_HOME_INCOMPLETE " + JSON.stringify({"used": used,
			"begin_id": request_id, "use_id": _home_use_id, "elapsed_frames": Engine.get_physics_frames() - started,
			"budget_frames": budget, "phase": key.get("_phase") if is_instance_valid(key) else "missing",
			"pending": key.get("_pending") if is_instance_valid(key) else "", "reason": reason}))
		return {"ok": false, "reason": reason}
	print("PORTAL_SMOKE_ACTUAL_HOME_COMPLETION " + JSON.stringify({"begin_id": request_id, "use_id": _home_use_id, "reply": result}))
	return {"ok": result.get("ok") == true and result.get("saved") == true and result.get("durable") == true \
		and result.get("arrived") == true and result.get("arrival_applied") == true \
		and not _home_use_id.is_empty() and result.get("permit_id") == _home_use_id,
		"reason": str(result.get("reason", "")), "completion": result}

func _home_completed(value: Dictionary) -> void:
	for field: String in _home_scope:
		if value.get(field) != _home_scope[field]: return
	if value.get("kind") == "home_key_begin" and value.get("request_id") == request_id and not request_id.is_empty():
		if value.get("ok") != true: reply = value.duplicate(true)
		elif value.get("use_id") is String and not str(value.use_id).is_empty(): _home_use_id = value.use_id
	elif value.get("kind") == "home_key_finish" and not _home_use_id.is_empty() and value.get("permit_id") == _home_use_id:
		# Shipping policy consumes the original raise's use_id as permit ID.
		# Session already validates the actual finish's immutable envelope before
		# emitting this signal; only this original raise can finish this observer.
		reply = value.duplicate(true)

func _walk_arch(tree: SceneTree, game: Node, arch_id: String, started: int, budget: int) -> Dictionary:
	var scene: Node = tree.current_scene
	var approach: Node3D
	for hall: Node in tree.get_nodes_in_group("crossing_halls"):
		if scene != null and scene.is_ancestor_of(hall) and hall.get_script() == HALL:
			var arch: Node3D = hall.call("arch", arch_id) as Node3D
			var candidate: Node3D = arch.get_node_or_null(^"Approach") as Node3D if arch != null else null
			if candidate != null:
				if approach != null: return {"ok": false, "reason": "Ambiguous actual return Hall approach"}
				approach = candidate
	var player: CharacterBody3D = game.call("find_player") as CharacterBody3D
	var probe: Object = tree.get("_probe")
	var rig: Node3D = probe.call("camera_rig") as Node3D if probe != null else null
	var remaining: int = budget - (Engine.get_physics_frames() - started)
	if approach == null or player == null or rig == null or remaining <= 0:
		return {"ok": false, "reason": "Actual return Hall/player/camera or remaining original budget unavailable"}
	# The host accepts the request only inside the arch's interaction radius.
	# The authored Approach stands 2.8 m out, so the walk's stop tolerance is
	# the radius slack left at that marker (capped at the navigator default);
	# a 0.8 m stop could otherwise end outside the radius the host enforces.
	var config: Dictionary = preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json")
	var radius: float = float(config.arch.interaction_radius_m)
	var arch_node: Node3D = approach.get_parent() as Node3D
	var slack: float = radius - approach.global_position.distance_to(arch_node.global_position)
	if slack <= 0.0: return {"ok": false, "reason": "Authored Hall Approach lies outside the arch interaction radius"}
	var navigator: RefCounted = NAVIGATOR.new(tree, player, rig, Callable(tree, "_drive_left"))
	var arrived: bool = await navigator.call("walk_to", approach.global_position, remaining, minf(0.8, slack * 0.75))
	tree.call("_drive_left", 0.0, 0.0)
	if not arrived: return {"ok": false, "reason": "Actual walk to authored Hall arch failed within remaining original budget"}
	# Stand still on supported ground for two host observation refresh periods
	# (portals.json arch.refresh_seconds), inside the same original budget, so
	# the host-observed trainer is the player standing at the arch -- as a
	# player who walks up and presses would be. No position is written.
	var still_frames: int = int(ceil(2.0 * float(config.arch.refresh_seconds) * Engine.physics_ticks_per_second))
	var still := 0
	while still < still_frames and Engine.get_physics_frames() - started < budget:
		await tree.physics_frame
		if not is_instance_valid(player) or tree.current_scene != scene: return {"ok": false, "reason": "Hall scene changed while settling at the arch"}
		var planar := Vector2(player.velocity.x, player.velocity.z).length()
		still = still + 1 if player.is_on_floor() and planar < 0.05 else 0
	var distance: float = player.global_position.distance_to(arch_node.global_position)
	return {"ok": still >= still_frames and distance <= radius,
		"reason": "" if still >= still_frames and distance <= radius else "Player did not settle inside the arch radius within the original budget (%.2f m)" % distance}
