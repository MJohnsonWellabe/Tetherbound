extends SceneTree

## Evidence frames for F06: the closed upper_counterweight_gate, the sealed
## stair behind it, both flanks of the gate, an input-driven walk with the
## companion out, and a real glide refused by the gate's Fly seal, through the
## production camera rig.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --fixed-fps 60 --script tools/capture_cloudreach_counterweight_gate.gd
##
## `--fixed-fps 60` makes every frame 1/60 s of game time, so the walk, the
## glide and HUD toasts run at play speed although only saved frames are drawn.
## Never combine `--headless` with a rendering driver (WORKFLOW §7).
##
## Frames (ralph/reports/CLOUDREACH-LANE/captures/counterweight_gate/):
##   01  the closed gate (portcullis, counterweights, wing walls) from the
##       approach at player distance;
##   02  the sealed stair past the gate, seen over it;
##   03  the gate's left flank, 04 its right flank, from the approach: where
##       non-colliding rock spurs used to stand, the wing walls and the
##       ridge's own cliffs;
##   10+ a walk of well over 30 s driven by real input with the Galecrest
##       called out: up the pass from its last pad to the gate, the right and
##       then the left end of the closure, and back down to the pad. One
##       frame every 3 s;
##   then a real flight: Jump, Jump from the aerie, both currents, a glide at
##       the gate along the route, the seal's refusal (asserted from the
##       production `denied` reason before the frame is shot) and the refused
##       flyer turning back to land on the open approach.
##
## Disclosed fixture, as tests/smoke_cloudreach_closed_gate_seal.gd: the
## Galecrest-led party, `realm_key_cloudreach` and `fly_traversal_unlocked`
## are seeded (`cloudreach_upper_route_unlocked` is not); the trainer is stood
## at each still's viewpoint, at the start of the walk and on the aerie launch
## stone; during the flight stamina is refilled below half (the smoke's
## fixture 7, standing in for Skyborne's free flight). Everything else is the
## real move / jump / fly_descend / creature_recall actions through the rig's
## `planar_basis`. The tool exits 1 if the refusal it exists to show does not
## happen.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const OUT := "res://ralph/reports/CLOUDREACH-LANE/captures/counterweight_gate"
const GATE_ID := "upper_counterweight_gate"
const ROUTE_ID := "windscar_counterweight_pass"
const PHYSICAL_DATA := "res://data/config/cloudreach_physical_runtime.json"
const SEAL_PREFIX := "This wind route is still sealed: cloudreach_counterweight_"
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
var _denials: Array[String] = []


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
	_fly.connect("denied", func(reason: String) -> void: _denials.append(reason))
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

	# Stills.
	await _stand_and_look(_gate - _along * 24.0 + _right * 3.0, _gate + Vector3.UP * 4.0, 8.0)
	await _shoot("01_closed_gate_from_approach")
	await _stand_and_look(_gate - _along * 6.0 - _right * 5.0, _gate + _along * 45.0 + Vector3.UP * 10.0, 0.0)
	await _shoot("02_sealed_stair_past_the_gate")
	await _stand_and_look(_gate - _along * 16.0 - _right * 4.0, _gate - _right * 30.0 + Vector3.UP * 2.0, 0.0)
	await _shoot("03_left_flank_of_the_gate")
	await _stand_and_look(_gate - _along * 16.0 + _right * 4.0, _gate + _right * 30.0 + Vector3.UP * 2.0, 0.0)
	await _shoot("04_right_flank_of_the_gate")

	# 10+ Walk by real input with the companion out, one frame every 3 s.
	var line := _polyline()
	var pad := _last_pad_before_gate(line)
	await _stand_and_look(pad, _gate, 0.0)
	await _call_out_companion()
	_since_shot = 0.0
	var walked := 0.0
	var from := _player.global_position
	walked += await _drive(_gate - _along * 2.0, 45.0)
	walked += await _drive(_gate - _along * 1.5 + _right * 11.0, 12.0)
	walked += await _drive(_gate - _along * 1.5 - _right * 11.0, 16.0)
	walked += await _drive(pad, 45.0)
	print("CAPTURE walk: %.1f s of input-driven motion, ended %.1f m from the pad (started %s)" % [
		walked, Vector2(_player.global_position.x - pad.x, _player.global_position.z - pad.z).length(), from])
	if walked < 30.0:
		push_error("capture: the input-driven walk lasted only %.1f s" % walked)

	# A real glide at the gate, refused by its Fly seal.
	if not await _glide_refused_at_gate():
		quit(1)
		return
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


## The last authored pad of the pass before the gate (its flat landing).
func _last_pad_before_gate(line: Array[Vector3]) -> Vector3:
	var pad := _gate - _along * 80.0
	for point: Vector3 in line:
		if (point - _gate).dot(_along) < -20.0:
			pad = point
	return pad


## The ordinary recall binding brings the active Galecrest out to follow.
func _call_out_companion() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	for attempt in 4:
		if director != null and director.call("ally_body") != null:
			break
		await _tap("creature_recall")
		await _frames_wait(90)
	var body: Node = director.call("ally_body") if director != null else null
	print("CAPTURE companion out for the walk: %s" % (str(body.get("species_id")) if body != null else "none"))


## Steer by real input toward `target` until within 0.8 m or `seconds` pass,
## shooting a frame every SHOOT_EVERY_S. Returns the seconds actually moving.
func _drive(target: Vector3, seconds: float) -> float:
	var dt := 1.0 / 60.0
	var moving := 0.0
	var last := _player.global_position
	for i in int(seconds * 60.0):
		var offset := target - _player.global_position
		offset.y = 0.0
		if offset.length() <= 0.8:
			break
		_rig.set("yaw", lerp_angle(float(_rig.get("yaw")), LANE.yaw_towards(_player.global_position, target), 0.05))
		var local: Vector3 = (_rig.call("planar_basis") as Basis).inverse() * offset.normalized()
		Input.action_press("move_right", maxf(local.x, 0.0))
		Input.action_press("move_left", maxf(-local.x, 0.0))
		Input.action_press("move_back", maxf(local.z, 0.0))
		Input.action_press("move_forward", maxf(-local.z, 0.0))
		await process_frame
		if _player.global_position.distance_to(last) > 0.02:
			moving += dt
		last = _player.global_position
		_since_shot += dt
		if _since_shot >= SHOOT_EVERY_S:
			_since_shot = 0.0
			await _shoot("%02d_walk" % _shot)
			_shot += 1
	_release_move()
	return moving


## Jump, Jump from the aerie launch stone, climb the aerie current and the
## overlapping middle current, glide along the route at the gate and on for
## the stair past it; shoot the seal's refusal, then the flyer turning back to
## land on the open approach. False if no counterweight seal refused it.
func _glide_refused_at_gate() -> bool:
	var physical: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PHYSICAL_DATA))
	var aerie_lift := _box_of(_spec_in(physical.get("updrafts", []), "cloudreach_aerie_lift"))
	var middle_spec := _spec_in(physical.get("updrafts", []), "cloudreach_middle_lift")
	var middle := _box_of(middle_spec)
	var stone := _world.find_child("LaunchStone", true, false) as Node3D
	var stand := stone.global_position if stone != null else Vector3(400.0, 610.0, 3237.0)
	await _stand_and_look(stand, stand + _along * 10.0, 0.0)
	_fly.call("observe_ground")
	(_player.get("vitals") as RefCounted).call("rest")
	var blockers := str(_fly.call("launch_blockers"))
	if not blockers.is_empty():
		push_error("capture: the aerie stand %s refuses launch: %s" % [stand, blockers])
		return false
	await _tap("jump")
	await _frames_wait(6)
	await _tap("jump")
	await _frames_wait(3)
	if not bool(_fly.call("is_flying")):
		push_error("capture: Jump, Jump did not deploy Fly at the aerie")
		return false
	Input.action_press("jump")
	for i in 25 * 60:
		await process_frame
		if _player.global_position.y >= minf(776.0, aerie_lift.end.y) - 6.0:
			break
	var into_middle := middle.intersection(aerie_lift).get_center()
	var middle_ceiling := minf(float(middle_spec.get("ceiling_y", 0.0)), middle.end.y) - 8.0
	for i in 40 * 60:
		_refill()
		_steer_flat(into_middle, 6.0)
		await process_frame
		if _player.global_position.y >= middle_ceiling:
			break
	Input.action_release("jump")
	_release_move()
	var approach := _gate - _along * 40.0
	var target := _gate + _along * 25.0
	var home := _gate - _along * 18.0
	var heading := approach
	var refused_at := -1
	_denials.clear()
	for i in 200 * 60:
		if not bool(_fly.call("is_flying")):
			break
		_refill()
		var offset := heading - _player.global_position
		offset.y = 0.0
		if heading == approach and offset.length() < 15.0:
			heading = target
		var reason := _seal_reason()
		if refused_at < 0 and not reason.is_empty():
			refused_at = i
			print("CAPTURE refusal at %s: '%s'" % [_player.global_position, reason])
			_rig.set("yaw", LANE.yaw_towards(_player.global_position, _gate))
			await _shoot("50_glide_refused_by_gate_seal")
		if refused_at >= 0 and heading == target and i - refused_at > 120:
			heading = home
		_steer_flat(heading, 1.5 if heading == home else 12.0)
		var descend := heading == home and Vector2(offset.x, offset.z).length() < 40.0
		if descend:
			Input.action_press("fly_descend")
		else:
			Input.action_release("fly_descend")
		_rig.set("yaw", lerp_angle(float(_rig.get("yaw")), LANE.yaw_towards(_player.global_position, heading), 0.04))
		await process_frame
	Input.action_release("fly_descend")
	_release_move()
	await _frames_wait(30)
	if refused_at < 0:
		push_error("capture: no counterweight seal refused the glide (denials %s)" % str(_denials))
		return false
	await _shoot("51_refused_flyer_landed_on_the_approach")
	print("CAPTURE refused flyer landed at %s flying=%s" % [_player.global_position, bool(_fly.call("is_flying"))])
	return true


func _seal_reason() -> String:
	for reason: String in _denials:
		if reason.begins_with(SEAL_PREFIX):
			return reason
	return ""


func _refill() -> void:
	var vitals: RefCounted = _player.get("vitals")
	if float(vitals.get("stamina")) < float(vitals.get("max_stamina")) * 0.5:
		vitals.call("rest")


func _steer_flat(target: Vector3, stop_within: float) -> void:
	var offset := target - _player.global_position
	offset.y = 0.0
	if offset.length() <= stop_within:
		_release_move()
		return
	var local: Vector3 = (_rig.call("planar_basis") as Basis).inverse() * offset.normalized()
	Input.action_press("move_right", maxf(local.x, 0.0))
	Input.action_press("move_left", maxf(-local.x, 0.0))
	Input.action_press("move_back", maxf(local.z, 0.0))
	Input.action_press("move_forward", maxf(-local.z, 0.0))


func _spec_in(list: Variant, id: String) -> Dictionary:
	if list is Array:
		for raw: Variant in list:
			if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
				return raw
	return {}


func _box_of(spec: Dictionary) -> AABB:
	var p: Array = spec.get("position", [0, 0, 0])
	var s: Array = spec.get("size", [0, 0, 0])
	return AABB(Vector3(float(p[0]), float(p[1]), float(p[2])), Vector3(float(s[0]), float(s[1]), float(s[2])))


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
		if bool(_fly.call("is_flying")):
			_fly.call("recover_to_anchor", "capture relocation")
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
