extends SceneTree

## Walk the production first-shore lesson with real input and capture dry,
## entry, surface crossing, and exit states. Proof-only --body selects one of
## the four installed bodies; --human-swim-candidate overrides only that live
## model's presentation dictionary. The shipped flag stays OFF. This resets
## the world and places the initial west pose; it is not an earned-route proof.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const MODEL := preload("res://scripts/player/trainer_model.gd")
const SWIM := preload("res://scripts/player/swim_state.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const MOTION_SECONDS := 30.0
const SAMPLE_SECONDS := 0.125
const MAX_CROSSINGS := 3
const DRY_RECOVERY_FRAMES := 600
const MAX_PNGS := 320
## Original stills plus the actual rendered frame before and after each
## LAND/HUMAN edge. Keep these inside the same total PNG and movement bounds.
const STILL_PNG_RESERVE := 2 + MAX_CROSSINGS * (3 * 2 + 2 + 1 + 4) + (MAX_CROSSINGS - 1)
var output := "res://ralph/reports/VISUAL/phase2/tidewake/swimming_main"
var _seed := 2042
var _body := "trainer"
var _candidate := false
var _records: Array[Dictionary] = []
var world: Node3D
var player: CharacterBody3D
var rig: Node3D
var swimming: Node
var model: Node3D
var _entry_saved := false
var _identity: Dictionary = {}
var _effective_pose: Dictionary = {}
var _failure := ""
var _started_ms := 0
var _time_scale := 1.0
var _crossing := 0
var _previous_position := Vector3.ZERO
var _previous_direction := Vector3.ZERO
var _previous_mode := -1
var _previous_allowed := false
var _last_step_moving := false
var _moving_seconds := 0.0
var _first_sample_seconds := -1.0
var _last_sample_seconds := -1.0
var _largest_sample_gap := 0.0
var _motion_samples := 0
var _last_displacement := Vector3.ZERO
var _last_direction := Vector3.ZERO
var _last_delta := 0.0
var _move_binding: InputEventJoypadMotion
var _last_draw_image: Image
var _last_draw_record: Dictionary = {}
var _entry_crossings: Array[int] = []
var _exit_crossings: Array[int] = []

func _init() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _action(pressed: bool) -> void:
	if _move_binding == null:
		return
	# Exercise the mapped physical event and the normal last-device tracker.
	# This is scripted input, not a connected-hardware or ROG Ally claim.
	var event := _move_binding.duplicate() as InputEventJoypadMotion
	event.device = 0
	event.axis_value = _move_binding.axis_value if pressed else 0.0
	Input.parse_input_event(event)

func _vector(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))

func _anchor(config: Dictionary, id: String) -> Vector3:
	for raw: Dictionary in config.anchors:
		if str(raw.id) == id:
			return _vector(raw.safe_position)
	return Vector3.INF

func _write_manifest(complete: bool) -> void:
	var file := FileAccess.open(output + "/manifest.json", FileAccess.WRITE)
	if file == null:
		_fail("Cannot write swim manifest")
		return
	file.store_string(JSON.stringify({"biome":"tidewake", "system":"swimming",
		"scene":"res://scenes/world/water_archipelago.tscn", "seed":_seed,
		"display_server":DisplayServer.get_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(),
		"resolution":[root.size.x,root.size.y], "frames":_records,
		"identity":_identity, "human_swim_candidate":_candidate,
		"entry_crossings":_entry_crossings, "exit_crossings":_exit_crossings,
		"effective_pose":_effective_pose, "shipped_pose_sha256":FileAccess.get_sha256(MODEL.HUMAN_SWIM_CONFIG),
		"time_scale":Engine.time_scale, "initial_time_scale":_time_scale,
		"elapsed_ms":Time.get_ticks_msec() - _started_ms, "moving_simulation_seconds":_moving_seconds,
		"sampled_moving_seconds":_sampled_seconds(), "motion_samples":_motion_samples,
		"maximum_pngs":MAX_PNGS, "reserved_still_pngs":STILL_PNG_RESERVE,
		"sample_target_seconds":SAMPLE_SECONDS, "largest_sample_gap_seconds":_largest_sample_gap,
		"crossings":_crossing, "maximum_crossings":MAX_CROSSINGS,
		"dry_recovery_frame_limit":DRY_RECOVERY_FRAMES,
		"disclosures":["New-game reset; selected installed appearance; initial west placement and zero velocity.",
			"Scripted camera yaw and mapped JoypadMotion move_forward input; alternating diagnostic crossings with natural dry regeneration.",
			"Transition before/after images are consecutive actual rendered observations, with their own timestamps; no extra movement or settle time.",
			"Native viewport and HUD; no clock, stamina, health or aquatic-state writes; raw PNGs are evidence artifacts.",
			"Candidate changes only the live model dictionary; not earned-route or F37 reserve evidence."],
		"complete":complete, "failure":_failure, "repro_args":OS.get_cmdline_user_args()}, "\t") + "\n")
	file.close()

func _fail(message: String) -> void:
	if _failure.is_empty():
		_failure = message
		push_error(message)

func _finish() -> void:
	_action(false)
	if physics_frame.is_connected(_observe_motion):
		physics_frame.disconnect(_observe_motion)
	if RenderingServer.frame_post_draw.is_connected(_capture_motion):
		RenderingServer.frame_post_draw.disconnect(_capture_motion)
	_write_manifest(_failure.is_empty())
	if _failure.is_empty():
		print("SWIM CAPTURE PASS body=", _body, " candidate=", _candidate,
			" frames=", _records.size(), " sampled_moving_seconds=", _sampled_seconds())
	quit(0 if _failure.is_empty() else 1)

func _save_frame(id: String, observed_image: Image = null, observed_record: Dictionary = {}) -> bool:
	if _records.size() >= MAX_PNGS:
		_fail("Total swim PNG bound exceeded: %d" % MAX_PNGS)
		return false
	if not observed_record.is_empty() and observed_image == null:
		_fail("A prior transition observation lost its actual native image")
		return false
	var picture := observed_image if observed_image != null else root.get_texture().get_image()
	var record := observed_record.duplicate(true) if not observed_record.is_empty() else _frame_record()
	if not bool(record.gamepad_prompts):
		_fail("Physical joypad movement did not reach the normal prompt device tracker")
		return false
	var path := "%s/%04d_%s.png" % [output, _records.size(), id]
	if picture == null or picture.is_empty() or picture.save_png(path) != OK:
		_fail("Cannot save native swim frame: " + path)
		return false
	record.id = id
	record.file = path
	record.resolution = [picture.get_width(), picture.get_height()]
	_records.append(record)
	return true

func _frame_record() -> Dictionary:
	var packet: Dictionary = swimming.snapshot()
	var vitals: RefCounted = player.get("vitals")
	var bones: Dictionary = {}
	var skeleton: Skeleton3D = model.skeleton()
	for bone: String in ["Spine02", "Head", "LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot"]:
		var index := skeleton.find_bone(bone)
		if index >= 0:
			var at := skeleton.global_transform * skeleton.get_bone_global_pose(index).origin
			bones[bone] = [at.x, at.y, at.z]
	var meshes: Array[Dictionary] = []
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.is_visible_in_tree() and mesh.mesh != null and mesh.skin != null:
			meshes.append({"node":str(mesh.get_path()), "mesh":mesh.mesh.resource_path,
				"skeleton":str(mesh.skeleton), "skin_binds":mesh.skin.get_bind_count(),
				"transform":str(mesh.global_transform)})
	return {"body":_body, "candidate":_candidate,
		"crossing":_crossing, "ticks_ms":Time.get_ticks_msec(), "elapsed_ms":Time.get_ticks_msec() - _started_ms,
		"physics_frame":Engine.get_physics_frames(), "process_frame":Engine.get_process_frames(),
		"mode":packet.mode,
		"resume_mode":packet.resume_mode, "surface_y":packet.surface_y, "drowning":packet.drowning,
		"player_position":[player.global_position.x,player.global_position.y,player.global_position.z],
		"requested_input":str(Input.get_vector("move_left", "move_right", "move_forward", "move_back")),
		"qualifying_movement":_last_step_moving, "moving_simulation_seconds":_moving_seconds,
		"observed_step_displacement":str(_last_displacement), "observed_step_direction":str(_last_direction),
		"observed_step_delta":_last_delta,
		"pose_active":bool(model.get("_human_swim_active")), "pose_phase":float(model.get("_human_swim_phase")),
		"art_transform":str(model.art_transform()), "bone_positions_world":bones, "visible_skinned_meshes":meshes,
		"animation_active":bool(model.animation_player().active),
		"animation":str(model.animation_player().current_animation),
		"gamepad_prompts":bool(root.get_node("Game").call("last_input_was_gamepad")),
		"stamina":float(vitals.stamina), "stamina_fraction":float(vitals.stamina) / float(vitals.max_stamina),
		"health":float(vitals.health), "on_floor":player.is_on_floor()}

func _save(id: String) -> bool:
	await RenderingServer.frame_post_draw
	var saved := _save_frame(id)
	_write_manifest(false)
	return saved and _failure.is_empty()

func _sampled_seconds() -> float:
	return maxf(0.0, _last_sample_seconds - _first_sample_seconds)

## Observe completed physics steps even while a still awaits drawing. Credit
## requires HUMAN on both ends, live requested input, and actual displacement
## along that input after subtracting production current. No idle/drift credit.
func _observe_motion() -> void:
	var packet: Dictionary = swimming.snapshot()
	var mode := int(packet.mode)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var allowed := not paused and INPUT_OWNER.current(self) == null and input.length() > 0.15
	var delta := player.get_physics_process_delta_time()
	var displacement := player.global_position - _previous_position
	displacement.y = 0.0
	var flow: Vector3 = world.call("current_at", _previous_position)
	var driven := displacement - Vector3(flow.x, 0.0, flow.z) * delta
	_last_displacement = displacement
	_last_direction = _previous_direction
	_last_delta = delta
	_last_step_moving = allowed and _previous_allowed and mode == SWIM.Mode.HUMAN \
		and _previous_mode == SWIM.Mode.HUMAN and delta > 0.0 \
		and displacement.length() > 0.001 and displacement.length() <= 3.0 \
		and driven.dot(_previous_direction) > 0.001
	if _last_step_moving:
		_moving_seconds += delta
	if not is_equal_approx(Engine.time_scale, _time_scale):
		_fail("Simulation time scale changed")
	if mode == SWIM.Mode.MOUNTED or bool(model.get("_riding")) or bool(model.get("_fly_hang")):
		_fail("Expected the selected human body, not mounted/flying mode")
	if bool(packet.drowning) or bool(player.get("vitals").is_dead()):
		_fail("Human crossing exhausted or killed the trainer")
	_previous_position = player.global_position
	_previous_mode = mode
	_previous_allowed = allowed
	var basis: Basis = rig.call("planar_basis")
	_previous_direction = (basis * Vector3(input.x, 0.0, input.y)).normalized()

func _capture_motion() -> void:
	if not _failure.is_empty() or paused:
		return
	var record := _frame_record()
	var picture := root.get_texture().get_image()
	if picture == null or picture.is_empty():
		_fail("Transition observation lacks an actual native image")
		return
	var mode := int(record.mode)
	if mode not in [SWIM.Mode.LAND, SWIM.Mode.HUMAN]:
		_fail("Unexpected aquatic mode during transition capture")
		return
	if not _last_draw_record.is_empty() and int(_last_draw_record.mode) != mode:
		var entry := mode == SWIM.Mode.HUMAN
		var crossings := _entry_crossings if entry else _exit_crossings
		if _crossing in crossings or crossings.size() >= MAX_CROSSINGS:
			_fail("Unexpected repeated LAND/HUMAN edge in one crossing")
			return
		var edge := "human_entry" if entry else "human_exit"
		if not _save_frame(edge + "_before", _last_draw_image, _last_draw_record) \
				or not _save_frame(edge + "_after", picture, record):
			return
		crossings.append(_crossing)
	_last_draw_image = picture
	_last_draw_record = record
	if mode != SWIM.Mode.HUMAN:
		return
	if bool(model.get("_human_swim_active")) != _candidate:
		_fail("Human surface did not show the requested candidate/baseline pose")
		return
	if not _entry_saved:
		_entry_saved = _save_frame("entry", picture, record)
	if not _last_step_moving or INPUT_OWNER.current(self) != null \
			or Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() <= 0.15 \
			or _sampled_seconds() >= MOTION_SECONDS:
		return
	if _first_sample_seconds >= 0.0 and _moving_seconds - _last_sample_seconds < SAMPLE_SECONDS:
		return
	# Leave capacity for every bounded route still, including the final dry
	# exit. Exhausting motion capacity never substitutes for 30-second coverage.
	if _motion_samples >= MAX_PNGS - STILL_PNG_RESERVE:
		return
	if not _save_frame("motion", picture, record):
		return
	if _first_sample_seconds < 0.0:
		_first_sample_seconds = _moving_seconds
	else:
		_largest_sample_gap = maxf(_largest_sample_gap, _moving_seconds - _last_sample_seconds)
	_last_sample_seconds = _moving_seconds
	_motion_samples += 1

func _dry_ready() -> bool:
	return int(swimming.snapshot().mode) == SWIM.Mode.LAND and player.is_on_floor() \
		and not bool(model.get("_human_swim_active")) and bool(model.animation_player().active)

func _recover_on_land() -> bool:
	_action(false)
	for frame in DRY_RECOVERY_FRAMES:
		if not _failure.is_empty() or not _dry_ready():
			_fail("Dry recovery lost the grounded, restored human pose")
			return false
		var vitals: RefCounted = player.get("vitals")
		if float(vitals.stamina) >= float(vitals.max_stamina) - 0.001:
			return await _save("dry_recovered")
		await physics_frame
	_fail("Natural dry stamina recovery timed out")
	return false

func _move_to(target: Vector3, tolerance: float, limit: int) -> bool:
	for frame in limit:
		if not _failure.is_empty():
			_action(false)
			return false
		var offset := target - player.global_position
		offset.y = 0.0
		if offset.length() <= tolerance:
			_action(false)
			await _frames(2)
			return true
		rig.set("yaw", atan2(-offset.x, -offset.z))
		_action(true)
		await physics_frame
		if frame == 180 and swimming.is_swimming():
			if not await _save("surface_mid"): return false
		if frame == 360 and swimming.is_swimming():
			if not await _save("surface_far"): return false
	_action(false)
	_fail("Swimming movement timed out toward %s at %s" % [target,player.global_position])
	return false

func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--body="):
			_body = arg.trim_prefix("--body=")
		elif arg == "--human-swim-candidate":
			_candidate = true
	if not output.begins_with("res://ralph/reports/VISUAL/phase2/tidewake/"):
		quit(1)
		return
	_started_ms = Time.get_ticks_msec()
	_time_scale = Engine.time_scale
	seed(_seed)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	if _body not in ["trainer", "lyra", "kael", "sera"]:
		_fail("Unknown installed playable body: " + _body)
		_finish()
		return
	_effective_pose = MODEL.load_human_swim_visual()
	if _effective_pose.is_empty() or bool(_effective_pose.get("pose_enabled", true)):
		_fail("Expected the shipped human swim candidate to remain flag OFF")
		_finish()
		return
	_effective_pose = _effective_pose.duplicate(true)
	_effective_pose.pose_enabled = _candidate
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	game.get("local").set("chosen_character", _body)
	game.set("current_realm","water")
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 600:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not bool(world.call("shell_build_complete")):
		_fail("Water shell did not build")
		_finish()
		return
	player = world.get_node("Player")
	rig = world.get_node("CameraRig")
	swimming = player.get("swim_controller")
	model = player.get_node("Model")
	if str(model.get("_config_key")) != _body or not model.has_model() \
			or model.skeleton() == null or model.animation_player() == null:
		_fail("Selected installed body did not build with its skeleton/animations; fallback refused")
		_finish()
		return
	var skeleton: Skeleton3D = model.skeleton()
	for bone: String in ["Spine02", "neck", "Head", "LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand", "LeftUpLeg", "LeftLeg", "RightUpLeg", "RightLeg"]:
		if skeleton.find_bone(bone) < 0:
			_fail("Selected body lacks swim pose bone: " + bone)
			_finish()
			return
	var profile: Dictionary = model.config()
	_identity = {"selected_body":_body, "built_body":str(model.get("_config_key")),
		"model":str(profile.model), "model_sha256":FileAccess.get_sha256(str(profile.model)),
		"skeleton":str(skeleton.get_path()), "bone_count":skeleton.get_bone_count()}
	model.set("_human_swim_visual", _effective_pose)
	for event: InputEvent in InputMap.action_get_events("move_forward"):
		if event is InputEventJoypadMotion:
			_move_binding = event as InputEventJoypadMotion
			break
	if _move_binding == null:
		_fail("move_forward lacks a mapped physical joypad axis")
		_finish()
		return
	_identity.move_forward_axis = _move_binding.axis
	_identity.move_forward_axis_value = _move_binding.axis_value
	var config: Dictionary = world.get("config")
	var lesson: Dictionary = config.swim_lesson
	var west := _anchor(config,str(lesson.start_anchor))
	var east := _anchor(config,str(lesson.end_anchor))
	west.y = float(world.call("ground_height_at",west.x,west.z)) + 0.15
	player.global_position = west
	player.velocity = Vector3.ZERO
	# Establish controller prompts through actual movement inside the original
	# 45-frame setup budget, then release and let the same dry floor settle.
	_action(true)
	await _frames(2)
	_action(false)
	await _frames(43)
	if not _dry_ready() or not await _save("west_dry_approach"):
		_fail("Initial west approach did not settle dry with the selected body")
		_finish()
		return
	_previous_position = player.global_position
	_last_draw_image = root.get_texture().get_image()
	_last_draw_record = _frame_record()
	physics_frame.connect(_observe_motion)
	RenderingServer.frame_post_draw.connect(_capture_motion)
	for crossing in MAX_CROSSINGS:
		_crossing = crossing + 1
		var forward := crossing % 2 == 0
		var start := _vector(lesson.surface_polyline[0 if forward else -1])
		var end := _vector(lesson.surface_polyline[-1 if forward else 0])
		if not await _move_to(start,0.4,900): break
		if int(swimming.snapshot().mode) != SWIM.Mode.HUMAN:
			_fail("Did not enter actual HUMAN swimming mode")
			break
		if not await _save("surface_west" if forward else "surface_east"): break
		if not await _move_to(end,0.4,1500): break
		if int(swimming.snapshot().mode) != SWIM.Mode.HUMAN:
			_fail("Surface crossing did not remain HUMAN swimming")
			break
		if not await _save("surface_east" if forward else "surface_west"): break
		if not await _move_to(east if forward else west,0.8,900): break
		await _frames(10)
		if not _dry_ready():
			_fail("Crossing did not exit dry with ordinary animation restored")
			break
		if not await _save("east_dry_exit" if forward else "west_dry_exit"): break
		if _moving_seconds >= MOTION_SECONDS and _sampled_seconds() >= MOTION_SECONDS: break
		if crossing + 1 < MAX_CROSSINGS and not await _recover_on_land(): break
	if _moving_seconds < MOTION_SECONDS or _sampled_seconds() < MOTION_SECONDS:
		_fail("Bounded crossings did not capture 30 actual moving HUMAN simulation seconds: moving=%.3f sampled=%.3f motion_pngs=%d total_pngs=%d/%d" \
			% [_moving_seconds, _sampled_seconds(), _motion_samples, _records.size(), MAX_PNGS])
	for crossing in range(1, _crossing + 1):
		if crossing not in _entry_crossings or crossing not in _exit_crossings:
			_fail("Missing actual rendered entry/exit edge for crossing %d" % crossing)
	for required: String in ["west_dry_approach", "entry", "surface_mid", "surface_far", "surface_west", "surface_east", "east_dry_exit"]:
		if not _records.any(func(record: Dictionary) -> bool: return str(record.id) == required):
			_fail("Missing original swim still: " + required)
	_finish()
