extends SceneTree

## Evidence frames for F06: the moved upper_counterweight_gate, the sealed
## stair behind it, the no-fly margin over its approach, and a traversal
## driven by real input, through the production camera rig.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --fixed-fps 60 --script tools/capture_cloudreach_counterweight_gate.gd
##
## `--fixed-fps 60` makes every frame 1/60 s of game time, so the walk, the
## glide and HUD toasts run at play speed although only saved frames are drawn.
## Never combine `--headless` with a rendering driver (WORKFLOW §7).
##
## Frames (ralph/reports/CLOUDREACH-LANE/captures/counterweight_gate/):
##   01-03  stills: the closed gate from the approach side, the sealed stair
##          past it, and the trainer in the ~4-5 m no-fly margin after a
##          refused Jump, Jump (the seal's denial on the HUD).
##   10-..  a traversal of well over 30 s of input-driven motion, one frame
##          every 3 s: walk up the pass from its last pad to the gate, try the
##          right then the left end of the barrier, walk back out of the
##          margin, then Jump, Jump and glide at the gate.
##
## Disclosed fixture, as tests/smoke_cloudreach_closed_gate_seal.gd: the
## Galecrest-led party, `realm_key_cloudreach` and `fly_traversal_unlocked`
## are seeded (`cloudreach_upper_route_unlocked` is not); the trainer is stood
## at each still's viewpoint and at the start of the traversal. Everything in
## the traversal is the real move / jump actions through the rig's
## `planar_basis`.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT := "res://ralph/reports/CLOUDREACH-LANE/captures/counterweight_gate"
const GATE_ID := "upper_counterweight_gate"
const ROUTE_ID := "windscar_counterweight_pass"
const SHOOT_EVERY_S := 3.0

var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: Node
var _fly: Node
var _frames: Array = []
var _gate := Vector3.ZERO
var _along := Vector3.FORWARD
var _right := Vector3.RIGHT
var _shot := 10
var _since_shot := 0.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	# Only the saved frames are drawn; the software renderer is the slow part.
	RenderingServer.render_loop_enabled = false
	_game = root.get_node(^"Game")
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new("user://capture_cloudreach_counterweight_gate/"))
	_game.set("current_realm", "cloudreach")
	_game.set("pending_realm_entry", "")
	_game.set("saved_player_pose", {})
	for species: String in ["galecrest", "bramblebun", "mudsnout", "terrapup", "brooktail"]:
		(_game.get("party") as RefCounted).call("add", SPECIES.spawn(species))
	var flags: RefCounted = _game.get("progression")
	for flag: String in ["realm_key_cloudreach", "fly_traversal_unlocked"]:
		flags.call("set_flag", flag)
	_world = SCENE.instantiate()
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = _world.get_node(^"CameraRig")
	_fly = _player.get("fly_controller")
	for i in 3600:
		await process_frame
		if bool(_world.call("shell_build_complete")) and i > 20:
			break
	if not bool(_world.call("shell_build_complete")) or not _read_gate():
		push_error("capture: Cloudreach did not build or the gate is not authored")
		quit(1)
		return
	# Let the arrival toasts time out as they would.
	await _frames_wait(600)
	print("CAPTURE gate %s along %s" % [_gate, _along])

	# 01 The closed gate from the approach side.
	await _stand_and_look(_gate - _along * 22.0 + _right * 4.0, _gate + Vector3.UP * 4.0)
	await _shoot("01_gate_from_approach")
	# 02 The sealed stair past the gate, seen over the barrier.
	await _stand_and_look(_gate - _along * 7.0 - _right * 6.0, _gate + _along * 45.0 + Vector3.UP * 8.0, 0.0)
	await _shoot("02_sealed_stair_past_the_gate")
	# 03 The no-fly margin: a real Jump, Jump inside it is refused.
	await _stand_and_look(_gate - _along * 3.0 + _right * 3.0, _gate + Vector3.UP * 3.0, 20.0)
	await _tap("jump")
	await _frames_wait(8)
	await _tap("jump")
	await _frames_wait(20)
	print("CAPTURE margin refusal '%s'" % str(_fly.get("last_denial")))
	await _shoot("03_no_fly_margin_refusal")

	# 10+ Traversal by real input, one frame every SHOOT_EVERY_S.
	var line := _polyline()
	var start := line[3] if line.size() > 3 else _gate - _along * 80.0
	await _stand_and_look(start, _gate)
	_since_shot = 0.0
	await _drive(_gate - _along * 2.0, 40.0)
	await _drive(_gate - _along * 1.5 + _right * 11.0, 12.0)
	await _drive(_gate - _along * 1.5 - _right * 11.0, 16.0)
	await _drive(_gate - _along * 16.0, 12.0)
	# Glide at the gate: Jump, Jump, then hold the stick at the stair past it.
	await _tap("jump")
	await _frames_wait(8)
	await _tap("jump")
	await _drive(_gate + _along * 25.0, 10.0)
	await _drive(_gate + _along * 25.0, 4.0, false)
	print("CAPTURE traversal end %s flying=%s last_denial '%s'" % [
		_player.global_position, bool(_fly.call("is_flying")), str(_fly.get("last_denial"))])
	LANE.contact_sheet(_frames, OUT + "/_sheet_counterweight_gate.png", 4)
	quit(0)


func _read_gate() -> bool:
	var config: Dictionary = _world.call("config_data")
	for raw: Variant in config.get("gates", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == GATE_ID:
			var p: Array = (raw as Dictionary).get("position", [])
			_gate = Vector3(float(p[0]), float(p[1]), float(p[2]))
	var line := _polyline()
	for i in line.size() - 1:
		if Geometry3D.get_closest_point_to_segment(_gate, line[i], line[i + 1]).distance_to(_gate) < 2.0:
			var d := line[i + 1] - line[i]
			d.y = 0.0
			_along = d.normalized()
			_right = Vector3.UP.cross(_along).normalized()
			return true
	return false


func _polyline() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for raw: Variant in (_world.call("config_data") as Dictionary).get("routes", []):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == ROUTE_ID:
			for p: Variant in (raw as Dictionary).get("polyline", []):
				var a: Array = p
				out.append(Vector3(float(a[0]), float(a[1]), float(a[2])))
	return out


## Steer by real input toward `target` until within 0.8 m or `seconds` pass
## (with `steer` false, just let `seconds` of play pass), shooting a frame
## every SHOOT_EVERY_S. The rig yaw trails the travel direction like a player's.
func _drive(target: Vector3, seconds: float, steer: bool = true) -> void:
	var dt := 1.0 / 60.0
	for i in int(seconds * 60.0):
		var offset := target - _player.global_position
		offset.y = 0.0
		if steer and offset.length() <= 0.8:
			break
		if steer:
			_rig.set("yaw", lerp_angle(float(_rig.get("yaw")), LANE.yaw_towards(_player.global_position, target), 0.05))
			var local: Vector3 = (_rig.call("planar_basis") as Basis).inverse() * offset.normalized()
			Input.action_press("move_right", maxf(local.x, 0.0))
			Input.action_press("move_left", maxf(-local.x, 0.0))
			Input.action_press("move_back", maxf(local.z, 0.0))
			Input.action_press("move_forward", maxf(-local.z, 0.0))
		else:
			_release_move()
		await process_frame
		_since_shot += dt
		if _since_shot >= SHOOT_EVERY_S:
			_since_shot = 0.0
			await _shoot("%02d_traversal" % _shot)
			_shot += 1
	_release_move()


func _release_move() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)


func _tap(action: String) -> void:
	Input.action_press(action)
	await process_frame
	await process_frame
	Input.action_release(action)
	await process_frame


## Stand the trainer at `at` on authored ground (a deliberate relocation, not a
## fall) and aim the rig at `target`, `off_axis_deg` aside so the subject sits
## beside the trainer rather than behind them.
func _stand_and_look(at: Vector3, target: Vector3, off_axis_deg: float = 14.0) -> void:
	var y := float(_world.call("ground_height_near", at + Vector3.UP * 3.0))
	if _fly != null:
		_fly.call("clear_recovery_anchor")
	_player.global_position = Vector3(at.x, (y if not is_nan(y) else at.y) + 0.3, at.z)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", LANE.yaw_towards(_player.global_position, target) + deg_to_rad(off_axis_deg))
	_rig.set("pitch", deg_to_rad(-10.0))
	await _frames_wait(30)


func _shoot(name: String) -> void:
	RenderingServer.render_loop_enabled = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	LANE.save_frame(self, OUT, name, _frames)
	RenderingServer.render_loop_enabled = false


func _frames_wait(count: int) -> void:
	for i in count:
		await process_frame
