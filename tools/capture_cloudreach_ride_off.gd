extends SceneTree

## Evidence frames for the F06 riding follow-ups: riding the saddled Meadowhart
## off a survivable ledge and off the arrival terrace into open air, then
## dismounting and remounting, through the production camera. Over 30 s of
## game time in motion.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --fixed-fps 60 \
##     --script tools/capture_cloudreach_ride_off.gd -- --tag=after
##
## Run it once on main (`--tag=before`) and once on the branch (`--tag=after`).
## `--fixed-fps 60` makes every frame one 1/60 s step however slowly the
## software renderer draws. Rendering is switched off between saved frames,
## and the simulation is unchanged by that.
##
## Disclosed fixture, the same as tests/smoke_cloudreach_saddle_remount.gd:
##   - The party, the saddle and the saddle flag are seeded.
##   - The trainer and mount are stood on the upper surface of each edge.
## Every mount, ride, dismount and remount is the real interact and stick
## input. Only base RidingController calls are used, so the tool runs
## unchanged on main.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT := "res://ralph/reports/CLOUDREACH-LANE/captures/ride_off"
const TEAM := ["meadowhart", "bramblebun", "mudsnout", "terrapup", "brooktail"]
const LEDGE_ROAD := Vector3(-104.0, 401.6, 1664.0)
const LEDGE_TOWARD := Vector3(-94.0, 390.0, 1647.0)
const TERRACE_ROAD := Vector3(7.6, 105.41, -245.03)
const TERRACE_TOWARD := Vector3(10.6, 83.9, -239.4)

var _tag := "after"
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _riding: Node
var _director: Node
var _arbiter: Node
var _frames: Array = []
var _shot := 0
var _motion_s := 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	RenderingServer.render_loop_enabled = false
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	game.set("pending_realm_entry", "")
	game.set("saved_player_pose", {})
	var flags: RefCounted = game.get("progression")
	flags.call("set_flag", "realm_key_cloudreach")
	flags.call("set_flag", RIDING.saddle_fitted_flag("meadowhart"))
	var party: RefCounted = PARTY.new()
	for species: String in TEAM:
		party.call("add", SPECIES.spawn(species))
	party.call("set_active", 0)
	game.set("party", party)
	(game.get("inventory") as RefCounted).call("add", "saddle", 1)
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	_arbiter = _world.get_node(^"InteractionArbiter")
	if not await _wait_for_mount():
		push_error("capture: the mount never appeared")
		quit(1)
		return
	_riding = _world.get_node(^"RidingController")

	await _edge_sequence("ledge", LEDGE_ROAD, LEDGE_TOWARD, Vector3(2.0, 0.0, 1.0), 7.0, 0.5)
	# Dismount on whatever ground the ride ended on, then remount by interact.
	await _press("interact")
	await _advance(1.0)
	await _shoot("ledge_dismounted")
	await _walk_to_mount()
	await _press("interact")
	await _advance(0.6)
	await _shoot("ledge_remounted")
	await _ride_for(3.0, 1.0, "ledge_ride_on", _heading_from_rig())

	await _edge_sequence("terrace", TERRACE_ROAD, TERRACE_TOWARD, Vector3(-1.0, 0.0, -2.5), 18.0, 1.0)
	await _advance(1.0)
	await _shoot("terrace_after")
	print("RIDE_OFF %s motion_s=%.1f frames=%d" % [_tag, _motion_s, _frames.size()])
	LANE.contact_sheet(_frames, "%s/_sheet_ride_off_%s.png" % [OUT, _tag], 4, 480)
	quit(0)


func _edge_sequence(label: String, road: Vector3, toward: Vector3, mount_offset: Vector3, ride_s: float, every_s: float) -> void:
	if bool(_riding.call("is_mounted")):
		await _press("interact")
		await _advance(1.0)
	_player.global_position = road
	_player.velocity = Vector3.ZERO
	var ally: Node3D = _director.call("ally_body")
	if ally != null:
		ally.call("place_on_ground", road + mount_offset)
	await _advance(1.0)
	await _walk_to_mount()
	await _press("interact")
	await _advance(0.6)
	var heading := toward - _player.global_position
	heading.y = 0.0
	heading = heading.normalized()
	_aim(heading)
	await _advance(0.3)
	await _shoot("%s_mounted_at_edge" % label)
	await _ride_for(ride_s, every_s, label, heading)


func _ride_for(seconds: float, every_s: float, label: String, heading: Vector3) -> void:
	var steps := int(round(seconds * 60.0))
	var every := maxi(1, int(round(every_s * 60.0)))
	var body: Node3D = _riding.call("mount_body")
	for i in steps:
		var from := body.global_position if body != null else _player.global_position
		_steer(heading)
		_aim(heading)
		await physics_frame
		_motion_s += 1.0 / 60.0
		if (i + 1) % every == 0:
			_release_move()
			await _shoot("%s_%04.1fs" % [label, float(i + 1) / 60.0])
		if not bool(_riding.call("is_mounted")):
			break
		if body != null and from.y - body.global_position.y > 0.05 and i % 30 == 0:
			print("RIDE %s %s t=%.1f y=%.2f" % [_tag, label, float(i) / 60.0, body.global_position.y])
	_release_move()


func _aim(heading: Vector3) -> void:
	_rig.set("yaw", atan2(-heading.x, -heading.z))
	_rig.set("pitch", deg_to_rad(-24.0))


func _heading_from_rig() -> Vector3:
	var basis: Basis = _rig.call("planar_basis")
	return -basis.z


func _steer(heading: Vector3) -> void:
	var local: Vector3 = (_rig.call("planar_basis") as Basis).inverse() * heading
	Input.action_press("move_right", maxf(local.x, 0.0))
	Input.action_press("move_left", maxf(-local.x, 0.0))
	Input.action_press("move_back", maxf(local.z, 0.0))
	Input.action_press("move_forward", maxf(-local.z, 0.0))


func _release_move() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)


func _press(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _walk_to_mount() -> void:
	for frame in 900:
		_arbiter.call("_recompute")
		if _arbiter.call("winning_provider") == _riding:
			break
		var body: Node3D = _director.call("ally_body")
		if body == null:
			break
		var offset := body.global_position - _player.global_position
		offset.y = 0.0
		_steer(offset.normalized())
		await physics_frame
	_release_move()
	await _advance(0.1)


func _wait_for_mount() -> bool:
	for frame in 2400:
		await physics_frame
		_director = _world.get_node_or_null(^"EncounterDirector")
		if _director == null:
			continue
		if frame % 120 == 90 and _director.call("ally_body") == null:
			await _press("creature_recall")
		var body: Node3D = _director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible and frame > 60:
			await _advance(1.0)
			return true
	return false


## Render just this frame: the loop is on for two drawn frames, then off again.
func _shoot(name: String) -> void:
	RenderingServer.render_loop_enabled = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_shot += 1
	LANE.save_frame(self, "%s/%s" % [OUT, _tag], "%s_%02d_%s" % [_tag, _shot, name], _frames)
	RenderingServer.render_loop_enabled = false
	var body: Node3D = _riding.call("mount_body") if _riding != null else null
	print("SHOT %s %s trainer=%s mount=%s mounted=%s" % [_tag, name, _player.global_position,
		body.global_position if body != null else "-", _riding.call("is_mounted") if _riding != null else "-"])


func _advance(seconds: float) -> void:
	for i in int(round(seconds * 60.0)):
		await physics_frame
