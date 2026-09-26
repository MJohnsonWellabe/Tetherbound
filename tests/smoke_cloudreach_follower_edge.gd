extends SceneTree

## The following companion stays on the trainer's floor on narrow Cloudreach
## roads: after a leash snap and while it walks to its station.
##
##   godot --headless --path . --script tests/smoke_cloudreach_follower_edge.gd
##
## Reviewer findings on the shared `follower_creature.gd`:
##   1. leash snap: a trainer more than LEASH (45 m) away makes the companion
##      reappear with `place_on_ground(station)`, which seats it on the terrain
##      HEIGHT ESTIMATE; beside a narrow road that is the valley below;
##   2. road-edge walk: `_tick_follow()` walks it to a fixed flank station with
##      no floor check; on a narrow road that station is past the edge.
##
## Disclosed fixtures: the party is seeded before the scene loads; the trainer
## is teleported (the leash case IS a teleport: camp recovery, fast travel) and
## the camera rig's `yaw` is set directly to swing the camera-relative station
## round the trainer. The companion is summoned with the real `creature_recall`
## press; everything after that is the follower's own logic.
##
## Pins:
##   (a) teleported > 45 m to each narrow road spot, at each of 4 camera yaws,
##       the companion is on the trainer's floor (|dy| <= LEVEL_TOLERANCE_M) at
##       every one of SNAP_FRAMES frames after the snap;
##   (b) standing on each narrow road while the camera swings through 8 yaws
##       (~10 s of following), the companion is never more than
##       LEVEL_TOLERANCE_M below the trainer's floor (worst drop reported).

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")

const TEAM := ["meadowhart", "bramblebun"]
const LEVEL_TOLERANCE_M := 1.5
const SNAP_FRAMES := 90
const WALK_FRAMES_PER_YAW := 75
const SPOTS := {
	"arrival terrace road": Vector3(8.0, 105.4, -245.0),
	"arrival road": Vector3(0.0, 105.3, -250.0),
	"Broken Causeways ledge road": Vector3(-104.0, 401.6, 1664.0),
}
## Far from every spot above (> LEASH), on open ground, so each teleport to a
## spot is a real leash snap.
const STAGING := Vector3(8.0, 105.4, -245.0)

var _failures: Array[String] = []
var _checks := 0
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _director: Node
var _worst_snap := 0.0
var _worst_walk := 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	game.set("pending_realm_entry", "")
	game.set("saved_player_pose", {})
	(game.get("progression") as RefCounted).call("set_flag", "realm_key_cloudreach")
	var party: RefCounted = PARTY.new()
	for species: String in TEAM:
		party.call("add", SPECIES.spawn(species))
	party.call("set_active", 0)
	game.set("party", party)

	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig")
	for frame in 600:
		await physics_frame
		_director = _world.get_node_or_null(^"EncounterDirector")
		if _director != null and frame > 240:
			break
	if _director == null or _rig == null:
		_fail("Cloudreach has no EncounterDirector / CameraRig")
		_report()
		return

	await _teleport(STAGING)
	await _press("creature_recall")
	for i in 90:
		if _body() != null and _body().visible:
			break
		await physics_frame
	if _body() == null:
		_fail("the recall press brought no companion out")
		_report()
		return

	# (a) leash snaps.
	for label: String in SPOTS:
		for q in 4:
			var yaw := q * TAU / 4.0 + 0.4
			await _snap_to(label, SPOTS[label], yaw)
	# (b) following on the road for ~10 s per spot.
	for label: String in SPOTS:
		await _walk_on(label, SPOTS[label])
	print("worst snap drop below the trainer: %.2f m" % _worst_snap)
	print("worst following drop below the trainer: %.2f m" % _worst_walk)
	_report()


func _snap_to(label: String, at: Vector3, yaw: float) -> void:
	var context := "snap to %s, camera yaw %d deg" % [label, roundi(rad_to_deg(yaw))]
	# Go somewhere more than LEASH away first so the next teleport is a snap.
	var away := Vector3(-104.0, 401.6, 1664.0) if at.z < 0.0 else STAGING
	await _teleport(away)
	for i in 30:
		await physics_frame
	_rig.set("yaw", yaw)
	await _teleport(at)
	var floor_y := _floor_y(_player.global_position, _player.global_position.y)
	var worst := 0.0
	var worst_y := 0.0
	for i in SNAP_FRAMES:
		await physics_frame
		var body := _body()
		if body == null:
			continue
		var drop := floor_y - body.global_position.y
		if drop > worst:
			worst = drop
			worst_y = body.global_position.y
	_worst_snap = maxf(_worst_snap, worst)
	var body := _body()
	var flat := -1.0
	if body != null:
		flat = Vector2(body.global_position.x - _player.global_position.x,
			body.global_position.z - _player.global_position.z).length()
	_check(worst <= LEVEL_TOLERANCE_M and body != null and absf(body.global_position.y - floor_y) <= LEVEL_TOLERANCE_M,
		"%s: companion on the trainer's floor %.2f for %d frames (worst drop %.2f at y %.2f; now %.2f m away)"
			% [context, floor_y, SNAP_FRAMES, worst, worst_y, flat])


func _walk_on(label: String, at: Vector3) -> void:
	await _teleport(at)
	var floor_y := _floor_y(_player.global_position, _player.global_position.y)
	var worst := 0.0
	var worst_at := Vector3.ZERO
	var worst_yaw := 0
	for q in 8:
		var yaw := q * TAU / 8.0
		_rig.set("yaw", yaw)
		for i in WALK_FRAMES_PER_YAW:
			_player.velocity = Vector3.ZERO
			await physics_frame
			var body := _body()
			if body == null:
				continue
			var drop := floor_y - body.global_position.y
			if drop > worst:
				worst = drop
				worst_at = body.global_position
				worst_yaw = roundi(rad_to_deg(yaw))
	_worst_walk = maxf(_worst_walk, worst)
	_check(worst <= LEVEL_TOLERANCE_M,
		"follow on %s (floor %.2f), 8 camera yaws, %d frames: worst drop %.2f m (at %s, yaw %d)"
			% [label, floor_y, 8 * WALK_FRAMES_PER_YAW, worst, worst_at, worst_yaw])


func _teleport(at: Vector3) -> void:
	_player.velocity = Vector3.ZERO
	_player.global_position = Vector3(at.x, _floor_y(at, at.y) + 0.05, at.z)
	for i in 3:
		_player.velocity = Vector3.ZERO
		await physics_frame


func _body() -> Node3D:
	var body: Node3D = _director.call("ally_body")
	return body if body != null and is_instance_valid(body) else null


func _floor_y(at: Vector3, level: float) -> float:
	var ray := PhysicsRayQueryParameters3D.create(Vector3(at.x, level + 3.0, at.z), Vector3(at.x, level - 6.0, at.z), _player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(ray)
	return (hit["position"] as Vector3).y if not hit.is_empty() else level


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("PASS %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL %s" % message)


func _report() -> void:
	print("CLOUDREACH FOLLOWER EDGE %s checks=%d failures=%d" % ["OK" if _failures.is_empty() else "FAIL", _checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
