extends SceneTree

## Evidence frames for F06-companion-fall: the active companion walking its
## camera-safe station off the Cloudreach arrival road, through the production
## camera rig following the real trainer.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --fixed-fps 60 \
##     --script tools/capture_cloudreach_companion_fall.gd -- --tag=after
##
## `--tag=before` on unmodified main (no companion recovery): the companion
## falls and is gone; its y is printed every frame. `--tag=after` on this
## branch: the runtime puts it back beside the trainer and the HUD shows
## "Your companion scrambled back to your side."
##
## `--fixed-fps 60` makes every frame 1/60 s of game time, so the fall, the
## HUD line's fade and the follower's gait run as in play although only the
## saved frames are drawn.
##
## Disclosed fixtures (the same stretch as leg A of
## tests/smoke_cloudreach_companion_fall.gd):
##   - the party (Meadowhart active) and the Cloudreach realm key are seeded
##     before the scene loads; the companion is called with the real recall
##     binding;
##   - the trainer is TELEPORTED once to the road centre (-3, y, -246);
##   - from there the trainer walks to the edge stretch with REAL STICK input
##     (move_* actions steered toward (5.0, y, -242.4), where leg A's
##     follower walked off) and the stick is released; the companion is never
##     positioned, only followed;
##   - the camera rig's yaw is the production default; the capture does not
##     turn it (turning it would move the follower's station).
## Printed every frame: companion y, trainer position, and the runtime's
## recovery count when `companion_fall_recoveries()` exists (-1 on main).
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT_ROOT := "res://ralph/reports/CLOUDREACH-LANE/captures/companion_fall"

const TEAM := ["meadowhart", "bramblebun", "mudsnout", "terrapup", "brooktail"]
const ROAD_CENTRE := Vector3(-3.0, 106.0, -246.0)
## Leg A's stretch: the trainer stood here and the follower walked off.
const EDGE_STAND := Vector3(5.013, 105.75, -242.44)
const FRAME_EVERY := 30
const WATCH_S := 24.0

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _director: Node
var _runtime: Node
var _frames: Array = []
var _tag := "after"
var _out := OUT_ROOT
var _shot := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	if _tag not in ["before", "after"]:
		push_error("capture: --tag must be before or after, not %s" % _tag)
		quit(2)
		return
	_out = "%s_%s" % [OUT_ROOT, _tag]
	# Only the saved frames are drawn; the software renderer is the slow part.
	RenderingServer.render_loop_enabled = false
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new("user://capture_cloudreach_companion_fall/"))
	_game.set("current_realm", "cloudreach")
	_game.set("pending_realm_entry", "")
	_game.set("saved_player_pose", {})
	(_game.get("progression") as RefCounted).call("set_flag", "realm_key_cloudreach")
	var party: RefCounted = PARTY.new()
	for species: String in TEAM:
		party.call("add", SPECIES.spawn(species))
	party.call("set_active", 0)
	_game.set("party", party)
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	if not await _call_companion():
		quit(1)
		return
	_runtime = _world.find_child("PhysicalRuntime", true, false)
	# Let the arrival toasts (team panel, bond notes) time out as they would.
	await _frames_wait(600)

	var centre := ROAD_CENTRE
	centre.y = _floor_y(centre)
	_player.global_position = centre + Vector3.UP * 0.1
	_player.velocity = Vector3.ZERO
	await _frames_wait(90)
	print("CAPTURE tag=%s rig yaw %.3f pitch %.3f" % [_tag, float(_rig.get("yaw")), float(_rig.get("pitch"))])
	await _shoot("00_road_centre_companion_following")

	# Real stick to the edge stretch; a frame every half second on the way.
	var walked := 0
	while walked < 600:
		var offset := EDGE_STAND - _player.global_position
		offset.y = 0.0
		if offset.length() < 0.4:
			break
		_steer_toward(EDGE_STAND)
		await process_frame
		walked += 1
		_log(walked)
		if walked % FRAME_EVERY == 0:
			await _shoot("walk_%03d" % walked)
	_release_move()
	var ally := _ally()
	var station: Vector3 = ally.call("formation_target") if ally != null else Vector3.INF
	print("CAPTURE at the edge: trainer %s station %s station_over_open_air=%s" % [
		_player.global_position, station, _void_below(station)])

	# Stand still and watch: the follower walks its station off the edge.
	var lowest := INF
	var fell_at := -1
	var back_at := -1
	for frame in int(WATCH_S * 60.0):
		await process_frame
		_log(frame)
		ally = _ally()
		if ally != null:
			lowest = minf(lowest, ally.global_position.y)
			if fell_at < 0 and ally.global_position.y < _player.global_position.y - 10.0:
				fell_at = frame
			if fell_at >= 0 and back_at < 0 and absf(ally.global_position.y - _player.global_position.y) < 3.0:
				back_at = frame
		if frame % FRAME_EVERY == 0:
			await _shoot("watch_t%04.1fs" % (frame / 60.0))
	await _shoot("zz_end_of_watch")
	ally = _ally()
	print("CAPTURE SUMMARY tag=%s fell_at=%s back_beside_trainer_at=%s lowest_y=%.1f final_companion_y=%s trainer=%s recoveries=%d" % [
		_tag,
		("%.1fs" % (fell_at / 60.0)) if fell_at >= 0 else "never",
		("%.1fs" % (back_at / 60.0)) if back_at >= 0 else "never",
		lowest,
		("%.1f" % ally.global_position.y) if ally != null else "none",
		_player.global_position, _recoveries()])
	LANE.contact_sheet(_frames, _out + "/_sheet_companion_fall_%s.png" % _tag, 6, 320)
	quit(0)


func _call_companion() -> bool:
	for frame in 2400:
		await process_frame
		_director = _world.get_node_or_null(^"EncounterDirector")
		if _director == null:
			continue
		if frame % 120 == 90 and _director.call("ally_body") == null:
			Input.action_press("creature_recall")
			await process_frame
			await process_frame
			Input.action_release("creature_recall")
		var body: Node3D = _director.call("ally_body")
		if body != null and is_instance_valid(body) and body.visible and frame > 60:
			return true
	push_error("capture: the active companion never appeared in Cloudreach")
	return false


func _ally() -> CharacterBody3D:
	return _director.call("ally_body") as CharacterBody3D if _director != null else null


func _log(frame: int) -> void:
	var ally := _ally()
	print("FRAME %d companion_y=%s trainer=%s recoveries=%d" % [frame,
		("%.2f" % ally.global_position.y) if ally != null else "none",
		_player.global_position, _recoveries()])


func _recoveries() -> int:
	if _runtime == null or not _runtime.has_method("companion_fall_recoveries"):
		return -1
	return int(_runtime.call("companion_fall_recoveries"))


func _steer_toward(target: Vector3) -> void:
	var offset := target - _player.global_position
	offset.y = 0.0
	if offset.length() < 0.05:
		_release_move()
		return
	var local: Vector3 = (_rig.call("planar_basis") as Basis).inverse() * offset.normalized()
	Input.action_press("move_right", maxf(local.x, 0.0))
	Input.action_press("move_left", maxf(-local.x, 0.0))
	Input.action_press("move_back", maxf(local.z, 0.0))
	Input.action_press("move_forward", maxf(-local.z, 0.0))


func _release_move() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)


func _floor_y(at: Vector3) -> float:
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 6.0, at + Vector3.DOWN * 6.0, 1, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(ray)
	return at.y if hit.is_empty() else (hit["position"] as Vector3).y


func _void_below(at: Vector3) -> bool:
	if not at.is_finite():
		return false
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0, at + Vector3.DOWN * 400.0, 1)
	return _player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func _shoot(name: String) -> void:
	_shot += 1
	RenderingServer.render_loop_enabled = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	LANE.save_frame(self, _out, "%03d_%s" % [_shot, name], _frames)
	RenderingServer.render_loop_enabled = false


func _frames_wait(count: int) -> void:
	for i in count:
		await process_frame
