extends SceneTree

## Disclosed unlocked aerie fixture, not earned Cloudreach progression. Real
## double-Jump, directional input and descent drive the existing controller.
## Native viewport/HUD and production clocks, resources and poses stay intact.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLY := preload("res://scripts/player/fly_controller.gd")
const TRAINER := preload("res://scripts/player/trainer_model.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const MOTION_SECONDS := 30.0
const SAMPLE_SECONDS := 0.125
const MAX_PNGS := 320
const TRANSITION_RESERVE := 31
const FLIGHT_FRAMES := 2400
const LANDING_FRAMES := 1800
const AIR_TARGET := Vector3(535,760,3170)
var output := "res://ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/round3"
var _seed := 2042
var world: Node3D
var player: CharacterBody3D
var rig: Node3D
var model: Node3D
var fly: Node
var _creature: RefCounted
var _identity: Dictionary = {}
var _before: Dictionary = {}
var _ground_shape: Shape3D
var _ground_position := Vector3.ZERO
var _landing_rules: Dictionary = {}
var _failure := ""
var _phase := "setup"
var _started_ms := 0
var _time_scale := 1.0
var _records: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _history: Array[Dictionary] = []
var _captured: Dictionary = {}
var _landing: Dictionary = {}
var _reached_target := false
var _previous_position := Vector3.ZERO
var _previous_direction := Vector3.ZERO
var _previous_flying := false
var _previous_allowed := false
var _last_step: Dictionary = {}
var _moving_seconds := 0.0
var _first_sample_seconds := -1.0
var _last_sample_seconds := -1.0
var _largest_sample_gap := 0.0
var _motion_samples := 0
var _draws := 0.0
var _primitives := 0.0
var _performance_frames := 0
var _performance_started_us := 0
var _performance_ended_us := 0

func _init() -> void:
	_run.call_deferred()

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _action(name: String, pressed: bool, strength: float = 1.0) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = pressed
	event.strength = strength if pressed else 0.0
	Input.parse_input_event(event)

func _release() -> void:
	for action: String in ["move_right", "move_left", "move_back", "move_forward", "jump", "fly_descend"]:
		_action(action, false)

func _fail(message: String) -> void:
	if _failure.is_empty():
		_failure = message
		push_error(message)

func _sampled_seconds() -> float:
	return maxf(0.0, _last_sample_seconds - _first_sample_seconds)

func _snapshot() -> Dictionary:
	var camera_target: Node = rig.get("_target")
	return {"ticks_ms":Time.get_ticks_msec(), "elapsed_ms":Time.get_ticks_msec() - _started_ms,
		"physics_frame":Engine.get_physics_frames(), "process_frame":Engine.get_process_frames(),
		"phase":_phase, "position":str(player.global_position), "velocity":str(player.velocity),
		"state":str(fly.get("state")), "denial":str(fly.get("last_denial")),
		"flight_seconds":float(fly.get("flight_seconds")), "moving_seconds":_moving_seconds,
		"requested_input":str(Input.get_vector("move_left", "move_right", "move_forward", "move_back")),
		"jump":Input.is_action_pressed("jump"), "descend":Input.is_action_pressed("fly_descend"),
		"input_owned":INPUT_OWNER.current(self) != null, "paused":paused, "observed_step":_last_step.duplicate(),
		"stamina":float(player.get("vitals").stamina), "health":float(player.get("vitals").health),
		"carrier_uid":str(_creature.get("uid")), "carrier_species":fly.call("carrier_species_id"),
		"fly_hang":bool(model.get("_fly_hang")), "on_floor":player.is_on_floor(),
		"collision_layer":player.collision_layer, "collision_mask":player.collision_mask,
		"camera_target":str(camera_target.get_path()) if camera_target != null else "",
		"camera_distance":float(rig.get("_distance")), "camera_height":float(rig.get("_height"))}

## Read both actual pairs: the production aligner matches their midpoint,
## which alone is not proof that each wrist meets its corresponding grip.
func _grips() -> Dictionary:
	var visual: Node3D = fly.get("_visual")
	var bird: Skeleton3D = fly.get("_bird_skeleton")
	var human: Skeleton3D = model.call("skeleton")
	var capability := SPECIES.fly_capability(str(_creature.get("species_id")))
	var bones: Array = capability.get("grip_bones", [])
	if fly.get("_creature") != _creature or bool(fly.call("last_flight_used_mentor_loaner")) \
			or str(fly.call("carrier_species_id")) != str(_creature.get("species_id")) \
			or not is_instance_valid(visual) or not visual.is_visible_in_tree() \
			or bird == null or human == null or bones.size() != 2 \
			or FLY.carrier_skeleton(visual) != bird or fly.get("_grip_bones") != bones \
			or not bool(model.get("_fly_hang")) or not model.is_visible_in_tree() \
			or bool(player.call("is_carried")) or bool(model.get("_riding")) \
			or player.collision_layer == 0 or player.collision_mask == 0:
		_fail("Actual carrier/body/grip identity or live flight presentation is missing; fallback refused")
		return {}
	if visual.get_child_count() == 0 or str(visual.get_child(0).scene_file_path) != str(capability.model):
		_fail("Live carrier art does not match the configured model")
		return {}
	_identity.human_skeleton = str(human.get_path())
	_identity.carrier_skeleton = str(bird.get_path())
	var hands: Array[Vector3] = []
	var feet: Array[Vector3] = []
	for index in 2:
		var hand := human.find_bone("LeftHand" if index == 0 else "RightHand")
		var foot := bird.find_bone(str(bones[index]))
		if hand < 0 or foot < 0:
			_fail("Missing actual hand or configured carrier grip bone")
			return {}
		hands.append(human.to_global(human.get_bone_global_pose(hand).origin))
		feet.append(bird.to_global(bird.get_bone_global_pose(foot).origin))
		if not hands[index].is_finite() or not feet[index].is_finite():
			_fail("Non-finite actual grip pose")
			return {}
	return {"bones":bones, "left_hand":str(hands[0]), "right_hand":str(hands[1]),
		"left_grip":str(feet[0]), "right_grip":str(feet[1]),
		"left_error_m":hands[0].distance_to(feet[0]), "right_error_m":hands[1].distance_to(feet[1]),
		"midpoint_error_m":((hands[0] + hands[1]) * 0.5).distance_to((feet[0] + feet[1]) * 0.5)}

func _save_frame(id: String, grips: Dictionary = {}) -> bool:
	if _records.size() >= MAX_PNGS:
		_fail("Total Fly PNG bound exceeded")
		return false
	var picture := root.get_texture().get_image()
	var name := "10-real-fly-silhouette" if id == "airborne_target" else "%04d-%s" % [_records.size(), id]
	var path := output + "/shots/" + name + ".png"
	if picture == null or picture.is_empty() or picture.save_png(path) != OK:
		_fail("Cannot save native Fly frame: " + path)
		return false
	var record := _snapshot()
	record.merge({"id":id, "file":path, "resolution":[picture.get_width(), picture.get_height()], "grips":grips})
	_records.append(record)
	_captured[id] = true
	return true

func _save_once(id: String, grips: Dictionary = {}) -> void:
	if not _captured.has(id):
		_save_frame(id, grips)

func _state_changed(state: String) -> void:
	_events.append({"event":"state", "state":state, "ticks_ms":Time.get_ticks_msec(),
		"physics_frame":Engine.get_physics_frames(), "position":str(player.global_position)})

func _landed(position: Vector3, species_id: String) -> void:
	if _phase != "landing" or not _landing.is_empty() or species_id != str(_creature.get("species_id")):
		_fail("Unexpected or duplicate actual Fly landing")
	_landing = {"event":"landed", "ticks_ms":Time.get_ticks_msec(), "position":str(position), "species_id":species_id}
	_events.append(_landing.duplicate())

func _recovered(reason: String) -> void:
	_fail("Recovery cannot stand in for the actual aerie landing: " + reason)

## Observe completed physics steps independently of render cadence. Require
## requested horizontal movement and actual aligned displacement, excluding
## setup, paused/input-owned frames, landing, drift and stationary lift.
func _observe_motion() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var flying := bool(fly.call("is_flying"))
	var allowed := _phase == "flight" and not paused and INPUT_OWNER.current(self) == null and input.length() > 0.15
	var delta := player.get_physics_process_delta_time()
	var displacement := player.global_position - _previous_position
	displacement.y = 0.0
	var environment: RefCounted = player.get("_environment_velocity")
	var wind: Vector3 = environment.get("_surviving")
	var driven := displacement - Vector3(wind.x, 0.0, wind.z) * delta
	var moving := allowed and _previous_allowed and flying and _previous_flying and delta > 0.0 \
		and displacement.length() > 0.001 and displacement.length() <= 3.0 and driven.dot(_previous_direction) > 0.001
	_last_step = {"moving":moving, "delta":delta, "displacement":str(displacement),
		"direction":str(_previous_direction), "environment_velocity":str(wind)}
	if moving:
		_moving_seconds += delta
	if not is_equal_approx(Engine.time_scale, _time_scale):
		_fail("Simulation time scale changed")
	if str(fly.get("state")) in ["exhausted", "recovery"] or bool(player.get("vitals").is_dead()):
		_fail("Flight exhausted, recovered or killed the trainer")
	_previous_position = player.global_position
	_previous_flying = flying
	_previous_allowed = allowed
	var basis: Basis = rig.call("planar_basis")
	_previous_direction = (basis * Vector3(input.x, 0.0, input.y)).normalized()

func _capture() -> void:
	if not _failure.is_empty(): return
	var flying := bool(fly.call("is_flying"))
	var grips := _grips() if flying else {}
	if not _failure.is_empty(): return
	if _phase == "first_jump" and not player.is_on_floor() and not flying:
		_save_once("first_jump")
	if flying:
		_save_once("deployed", grips)
		var state := str(fly.get("state"))
		if state in ["climb", "glide", "descent"]: _save_once(state, grips)
		if _phase == "flight" and player.global_position.distance_to(AIR_TARGET) < 6.0:
			_reached_target = true
			_save_once("airborne_target", grips)
		if _performance_frames < 24:
			if _performance_frames == 0: _performance_started_us = Time.get_ticks_usec()
			_draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			_primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			_performance_frames += 1
			_performance_ended_us = Time.get_ticks_usec()
	elif _phase == "landing" and not _landing.is_empty() and player.is_on_floor():
		_save_once("landed")
	if not flying or paused or INPUT_OWNER.current(self) != null or _phase != "flight" \
			or not bool(_last_step.get("moving", false)) \
			or Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() <= 0.15 \
			or _sampled_seconds() >= MOTION_SECONDS or _motion_samples >= MAX_PNGS - TRANSITION_RESERVE:
		return
	if _first_sample_seconds >= 0.0 and _moving_seconds - _last_sample_seconds < SAMPLE_SECONDS: return
	if not _save_frame("motion", grips): return
	if _first_sample_seconds < 0.0:
		_first_sample_seconds = _moving_seconds
	else:
		_largest_sample_gap = maxf(_largest_sample_gap, _moving_seconds - _last_sample_seconds)
	_last_sample_seconds = _moving_seconds
	_motion_samples += 1

func _steer(target: Vector3, descend: bool = false) -> void:
	var offset := target - player.global_position
	var flat := Vector3(offset.x, 0, offset.z)
	var local: Vector3 = (rig.call("planar_basis") as Basis).inverse() * flat.normalized() * clampf(flat.length() / 12.0, 0, 1)
	for entry: Array in [["move_right", maxf(local.x, 0)], ["move_left", maxf(-local.x, 0)],
			["move_back", maxf(local.z, 0)], ["move_forward", maxf(-local.z, 0)]]:
		_action(str(entry[0]), float(entry[1]) > 0.0, float(entry[1]))
	_action("jump", not descend and offset.y > 2.0)
	_action("fly_descend", descend)

func _trace(frame: int) -> void:
	var sample := _snapshot()
	sample.frame = frame
	var contacts: Array[String] = []
	for index in player.get_slide_collision_count():
		var collision := player.get_slide_collision(index)
		contacts.append(str(collision.get_collider().get_path()) + " normal=" + str(collision.get_normal()))
	sample.contacts = contacts
	_history.append(sample)
	print("FLY TRACE ", JSON.stringify(sample))

func _write_json(name: String, value: Dictionary) -> void:
	var file := FileAccess.open(output + "/" + name, FileAccess.WRITE)
	if file == null:
		_fail("Cannot write Fly report: " + name)
		return
	file.store_string(JSON.stringify(value, "\t") + "\n")
	file.close()

func _finish() -> void:
	_release()
	if physics_frame.is_connected(_observe_motion): physics_frame.disconnect(_observe_motion)
	if RenderingServer.frame_post_draw.is_connected(_capture): RenderingServer.frame_post_draw.disconnect(_capture)
	if fly != null:
		if fly.state_changed.is_connected(_state_changed): fly.state_changed.disconnect(_state_changed)
		if fly.landed.is_connected(_landed): fly.landed.disconnect(_landed)
		if fly.recovered.is_connected(_recovered): fly.recovered.disconnect(_recovered)
	_write_json("fly-diagnostic.json", {"history":_history, "events":_events, "failure":_failure})
	_write_json("fly-performance.json", {"draw_calls":_draws / maxf(1, _performance_frames),
		"primitives":_primitives / maxf(1, _performance_frames), "sample_frames":_performance_frames,
		"measured_frame_ms":float(_performance_ended_us - _performance_started_us) / (1000.0 * maxf(1, _performance_frames - 1)),
		"capture_phase":"first 24 rendered flight frames including PNG capture overhead",
		"adapter":RenderingServer.get_video_adapter_name()})
	_write_json("manifest.json", {"complete":_failure.is_empty(), "failure":_failure,
		"scene":"res://scenes/world/cloudreach_cliffs.tscn", "seed":_seed, "identity":_identity,
		"resolution":[root.size.x, root.size.y], "display_server":DisplayServer.get_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(), "time_scale":Engine.time_scale,
		"elapsed_ms":Time.get_ticks_msec() - _started_ms, "moving_seconds":_moving_seconds,
		"sampled_moving_seconds":_sampled_seconds(), "sample_interval_seconds":SAMPLE_SECONDS,
		"largest_sample_gap_seconds":_largest_sample_gap, "maximum_pngs":MAX_PNGS,
		"reserved_transition_pngs":TRANSITION_RESERVE, "motion_samples":_motion_samples,
		"flight_frame_limit":FLIGHT_FRAMES, "landing_frame_limit":LANDING_FRAMES,
		"initial_state":_before, "landing":_landing, "frames":_records, "repro_args":OS.get_cmdline_user_args(),
		"producer_sha256":FileAccess.get_sha256("res://tools/capture_cloudreach_fly_visual.gd"),
		"disclosures":["New-game reset, Cloudreach/Fly unlock flags and owned Galecrest seeded; initial aerie/player/camera placement.",
			"Actual double-Jump; ordinary flight input shuttles inside the authored aerie updraft, then descends to the aerie.",
			"Native viewport and HUD. No clock, resource, collider, pose or airborne placement writes. Raw PNGs are artifacts.",
			"Diagnostic integration fixture, not earned progression or a visual acceptance verdict; each hand-grip error is reported."]})
	if _failure.is_empty(): print("CLOUDREACH REAL FLY VISUAL PASS moving=", _moving_seconds, " sampled=", _sampled_seconds())
	quit(0 if _failure.is_empty() else 1)

func _run() -> void:
	if "--round4" in OS.get_cmdline_user_args(): output = "res://ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/round4"
	if "--round5" in OS.get_cmdline_user_args(): output = "res://ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/round5"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="): _seed = int(arg.trim_prefix("--seed="))
	if not (output.begins_with("res://ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/") \
			or output.begins_with("res://ralph/reports/VISUAL/phase2/cloudreach/")):
		push_error("Fly evidence must stay in the existing Cloudreach report roots")
		quit(1)
		return
	_started_ms = Time.get_ticks_msec()
	_time_scale = Engine.time_scale
	seed(_seed)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output + "/shots"))
	if DisplayServer.get_name() == "headless":
		_fail("Fly capture requires a rendering display")
		_finish()
		return
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "cloudreach")
	game.get("progression").call("set_flag", "realm_key_cloudreach")
	game.get("progression").call("set_flag", "fly_traversal_unlocked")
	_creature = SPECIES.spawn("galecrest")
	if not bool(game.get("party").call("add", _creature)) or game.get("party").call("active") != _creature:
		_fail("Fixture did not select its actual owned Galecrest")
		_finish()
		return
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")): break
	if not bool(world.call("shell_build_complete")):
		_fail("Production Cloudreach shell did not complete")
		_finish()
		return
	player = world.get_node("Player") as CharacterBody3D
	rig = world.get_node("CameraRig")
	model = player.get_node("Model")
	fly = player.get("fly_controller")
	var body := TRAINER.resolved_appearance_id(str(model.get("appearance_id")), game)
	if fly == null or str(model.get("_config_key")) != body or not bool(model.call("has_model")) \
			or model.call("skeleton") == null or model.call("animation_player") == null:
		_fail("Selected trainer body/skeleton or production Fly controller missing; fallback refused")
		_finish()
		return
	var human: Skeleton3D = model.call("skeleton")
	for bone: String in ["LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand"]:
		if human.find_bone(bone) < 0:
			_fail("Selected trainer lacks the actual Fly pose bone: " + bone)
			_finish()
			return
	var profile: Dictionary = model.call("config")
	var capability := SPECIES.fly_capability(str(_creature.get("species_id")))
	_identity = {"character_id":str(game.get("local").get("character_id")), "body":body,
		"body_model":str(profile.model), "body_model_sha256":FileAccess.get_sha256(str(profile.model)),
		"carrier_uid":str(_creature.get("uid")), "carrier_species":str(_creature.get("species_id")),
		"carrier_model":str(capability.model), "carrier_model_sha256":FileAccess.get_sha256(str(capability.model)),
		"grip_bones":capability.get("grip_bones", []), "fly_config_sha256":FileAccess.get_sha256(FLY.CONFIG_PATH)}
	if str(_identity.character_id).is_empty() or str(_identity.carrier_uid).is_empty() \
			or str(_identity.body_model_sha256).is_empty() or str(_identity.carrier_model_sha256).is_empty():
		_fail("Actual trainer/carrier identity or model source hash missing")
		_finish()
		return
	_landing_rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_physical_runtime.json")).trial
	player.global_position = Vector3(400,610.25,3250)
	player.velocity = Vector3.ZERO
	rig.global_position = player.global_position + Vector3.UP * 1.55
	rig.set("yaw", atan2(-710.0,310.0))
	await _frames(12)
	if not player.is_on_floor() or bool(fly.call("is_flying")) or INPUT_OWNER.current(self) != null:
		_fail("Aerie fixture did not settle on actual free-input ground")
		_finish()
		return
	_ground_position = player.global_position
	var collision := player.get_node("Collision") as CollisionShape3D
	_ground_shape = collision.shape
	_before = {"collision_position":str(collision.position), "floor_snap":player.floor_snap_length,
		"collision_layer":player.collision_layer, "collision_mask":player.collision_mask,
		"camera_distance":float(rig.get("_distance")), "camera_height":float(rig.get("_height"))}
	var collision_position := collision.position
	await RenderingServer.frame_post_draw
	_save_once("grounded")
	_previous_position = player.global_position
	fly.state_changed.connect(_state_changed)
	fly.landed.connect(_landed)
	fly.recovered.connect(_recovered)
	physics_frame.connect(_observe_motion)
	RenderingServer.frame_post_draw.connect(_capture)
	_phase = "first_jump"
	_action("jump", true)
	await _frames(3)
	_action("jump", false)
	await _frames(6)
	_phase = "deploy"
	_action("jump", true)
	await _frames(3)
	_action("jump", false)
	if not bool(fly.call("is_flying")):
		_fail("Actual double Jump did not launch production Fly")
		_finish()
		return
	_phase = "flight"
	var target := AIR_TARGET
	for frame in FLIGHT_FRAMES:
		if not _failure.is_empty() or not bool(fly.call("is_flying")): break
		if _reached_target and _moving_seconds >= MOTION_SECONDS and _sampled_seconds() >= MOTION_SECONDS: break
		if player.global_position.distance_to(target) < 6.0:
			target = Vector3(_ground_position.x, AIR_TARGET.y, _ground_position.z) if target == AIR_TARGET else AIR_TARGET
		_steer(target)
		await physics_frame
		if frame % 60 == 0: _trace(frame)
	_release()
	if not _reached_target or _moving_seconds < MOTION_SECONDS or _sampled_seconds() < MOTION_SECONDS or not bool(fly.call("is_flying")):
		_fail("Bounded flight lacks actual target/30 moving seconds: moving=%.3f sampled=%.3f" % [_moving_seconds, _sampled_seconds()])
	if not _failure.is_empty():
		_finish()
		return
	_phase = "landing"
	for frame in LANDING_FRAMES:
		if not _failure.is_empty() or not _landing.is_empty(): break
		if not bool(fly.call("is_flying")):
			_fail("Flight ended without its actual landed event")
			break
		_steer(_ground_position, true)
		await physics_frame
		if frame % 60 == 0: _trace(frame)
	_release()
	await _frames(12)
	var offset := player.global_position - _ground_position
	if _landing.is_empty() or not player.is_on_floor() or str(fly.get("state")) != "grounded" \
			or Vector2(offset.x, offset.z).length() > float(_landing_rules.landing_radius_m) \
			or absf(offset.y) > float(_landing_rules.landing_height_tolerance_m) \
			or bool(model.get("_fly_hang")) or bool(player.call("is_carried")) \
			or fly.get("_visual") != null or collision.shape != _ground_shape \
			or not collision.position.is_equal_approx(collision_position) \
			or not is_equal_approx(player.floor_snap_length, float(_before.floor_snap)) \
			or player.collision_layer != int(_before.collision_layer) or player.collision_mask != int(_before.collision_mask) \
			or rig.get("_target") != player or not is_equal_approx(float(rig.get("_distance")), float(_before.camera_distance)) \
			or not is_equal_approx(float(rig.get("_height")), float(_before.camera_height)) \
			or not bool(model.call("animation_player").is_playing()):
		_fail("Actual aerie landing did not restore floor, body, camera, collision and ordinary animation")
	if _failure.is_empty():
		_phase = "restored"
		await RenderingServer.frame_post_draw
		_save_once("restored")
	for required: String in ["grounded", "first_jump", "deployed", "climb", "glide", "airborne_target", "descent", "landed", "restored"]:
		if not _captured.has(required): _fail("Missing actual Fly transition image: " + required)
	_finish()
