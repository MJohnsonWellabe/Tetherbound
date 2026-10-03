extends RefCounted

## Disclosed initial route/position mechanics fixtures for two actual network
## journeys. No earned chapter credit, synthetic permit or saved ACK is supplied.
const DISCLOSURE := "initial_hall_position_and_open_route_no_earned_credit"
const ROUTES := {"session_host_first_realm": "cloudreach", "water_alpha": "tidewake",
	"stormwood_livewire": "stormwood", "stormwood_finalized_death": "stormwood", "stormwood_hosted_trainers": "stormwood"}
const HALL := preload("res://scripts/world/crossing_hall.gd")
const TELEPORT := preload("res://scripts/creatures/remote_creature.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const META := "portal_smoke_initial_fixture"
var reply: Dictionary = {}
var request_id := ""

static func selected(args: Dictionary) -> bool:
	return args.get("actual_portal_fixture") == DISCLOSURE

static func prepare(tree: SceneTree, args: Dictionary, budget: int) -> Dictionary:
	var regression: String = str(args.get("portal_regression", ""))
	var arch_id: String = str(ROUTES.get(regression, ""))
	var game: Node = tree.root.get_node_or_null(^"Game")
	var session: Node = game.get("session") as Node if game != null else null
	if not selected(args) or arch_id.is_empty() or game == null or session == null \
		or session.call("is_active") == true or session.get("_preparing_client") == true \
		or game.get("current_realm") != "meadows" or tree.has_meta(META):
		return {"verdict": "FAIL", "detail": "Initial portal fixture requires a named isolated Meadows owner before host/join"}
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
	if approach == null or player == null or not scene.is_ancestor_of(player):
		return {"verdict": "FAIL", "detail": "Actual authored Hall approach/player unavailable"}
	var started: int = Engine.get_physics_frames()
	var config: Dictionary = preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json")
	var proximity: float = float(config.arch.interaction_radius_m)
	var before: Vector3 = player.global_position
	# Only initial placement is a fixture. The ordinary controller must supply
	# real walkable contact before its sampled pose becomes the initial source.
	TELEPORT.teleport_body(player, approach.global_position + Vector3.UP * 2.0)
	player.velocity = Vector3.ZERO
	var grounded := false
	while Engine.get_physics_frames() - started < budget:
		await tree.physics_frame
		if not is_instance_valid(player) or tree.current_scene != scene: break
		if player.is_on_floor() and player.get_floor_normal().angle_to(Vector3.UP) <= player.floor_max_angle \
			and player.global_position.distance_to(arch.global_position) <= proximity:
			grounded = true
			break
	if not grounded: return {"verdict": "FAIL", "detail": "Initial Hall fixture did not reach actual supported arch proximity"}
	var sampled: Vector3 = player.global_position
	var fly: Node = player.get("fly_controller") as Node
	if fly == null or fly.call("set_recovery_anchor", sampled, "meadows") != true:
		return {"verdict": "FAIL", "detail": "Actual grounded initial recovery anchor refused"}
	var world: RefCounted = game.get("world")
	var route: Dictionary = (world.get("redesign_world") as Dictionary).duplicate(true)
	var opened: Array = (route.get("portal_unlocks", []) as Array).duplicate()
	if not opened.has(arch_id): opened.append(arch_id)
	route.portal_unlocks = opened
	if not STATE.validate("world", route).is_empty():
		return {"verdict": "FAIL", "detail": "Initial canonical route fixture is invalid"}
	world.set("redesign_world", route)
	var model: Node3D = player.get_node_or_null(^"Model") as Node3D
	var rig: Node = scene.get_node_or_null(^"CameraRig")
	var facing: float = model.global_rotation.y if model != null else player.global_rotation.y
	# Explicit initial pose fixture only, before any admission/passive baseline.
	game.set("saved_player_pose", {"realm": "meadows", "position": [sampled.x, sampled.y, sampled.z],
		"model_yaw": facing, "camera_yaw": float(rig.get("yaw")) if rig != null else facing,
		"camera_pitch": float(rig.get("pitch")) if rig != null else 0.0})
	var cost: int = Engine.get_physics_frames() - started
	tree.set_meta(META, {"regression": regression, "arch_id": arch_id, "frames": cost,
		"game": weakref(game), "owner": weakref(game.get("local"))})
	return {"verdict": "PASS", "detail": "Disclosed initial actual Hall placement and canonical route; no earned credit",
		"data": {"fixture_disclosure": DISCLOSURE, "arch_path": str(arch.get_path()), "arch_id": arch_id,
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
	if preparation_frames(tree, args) < 0 or realm != ("water" if arch_id == "tidewake" else arch_id):
		return {"ok": false, "reason": "Exact initial named portal fixture required"}
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
		return {"ok": reply.get("ok") == true and reply.get("saved") == true and reply.get("durable") == true \
			and reply.get("arrived") == true and reply.get("arrival_applied") == true \
			and reply.get("permit_id") is String and not str(reply.permit_id).is_empty(),
			"reason": str(reply.get("reason", "")), "completion": reply.duplicate(true)}
	return {"ok": false, "reason": str(accepted.get("reason", "Actual correlated saved/arrived completion missing within original budget"))}

func _completed(value: Dictionary) -> void:
	if value.get("request_id") == request_id and not request_id.is_empty(): reply = value.duplicate(true)
