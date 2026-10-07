extends SceneTree

## Disclosed Aquaryn/Swim Stone/saddle/shore fixture, not earned progression
## or Ripplet proof. Ordinary arbiter-selected Interact and directional input
## drive the production ride, HUMAN dismount and dry exit. No pose overrides.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TRAINER := preload("res://scripts/player/trainer_model.gd")
const STATE := preload("res://scripts/player/swim_state.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SAMPLE_SECONDS := 0.125
const MOTION_SECONDS := 30.0
const CIRCUIT_SECONDS := 40.0
const MAX_PNGS := 320
const TRANSITION_RESERVE := 31
const MODES := ["LAND", "HUMAN", "MOUNTED", "PAUSED"]
var output := "res://ralph/reports/VISUAL/phase2/tidewake/mounted_swim_main"
var capture_seed := 2042
var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var riding: Node
var swimming: Node
var model: Node3D
var director: Node
var arbiter: Node
var mount_body: CharacterBody3D
var _creature: RefCounted
var _identity: Dictionary = {}
var _before: Dictionary = {}
var _ground_shape: Shape3D
var _rules: Dictionary = {}
var _failure := ""
var _phase := "setup"
var _started_ms := 0
var _time_scale := 1.0
var records: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _captured: Dictionary = {}
var _activations := 0
var _mount_events := 0
var _dismount_events := 0
var _previous_position := Vector3.ZERO
var _previous_direction := Vector3.ZERO
var _previous_mode := -1
var _previous_allowed := false
var _last_step: Dictionary = {}
var _moving_seconds := 0.0
var _first_sample_seconds := -1.0
var _last_sample_seconds := -1.0
var _largest_sample_gap := 0.0
var _motion_samples := 0

func _init() -> void:
	_run.call_deferred()

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _input(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)

func _action(pressed: bool) -> void:
	_input("move_forward", pressed)

func _fail(message: String) -> void:
	if _failure.is_empty():
		_failure = message
		push_error(message)

func _sampled_seconds() -> float:
	return maxf(0.0, _last_sample_seconds - _first_sample_seconds)

func _snapshot() -> Dictionary:
	var packet: Dictionary = swimming.call("snapshot")
	var target: Node = camera.get("_target")
	var saddle := mount_body.get_node_or_null("RideSaddle") as Node3D
	var seat_error := 0.0
	if bool(player.call("is_carried")):
		seat_error = player.global_position.distance_to(mount_body.to_global(player.call("carry_offset")))
	var predicted := Vector3.INF
	if bool(riding.call("is_mounted")):
		predicted = riding.call("_dismount_spot", mount_body)
	return {"ticks_ms":Time.get_ticks_msec(), "elapsed_ms":Time.get_ticks_msec() - _started_ms,
		"physics_frame":Engine.get_physics_frames(), "process_frame":Engine.get_process_frames(), "phase":_phase,
		"mode":MODES[int(packet.mode)], "aquatic":packet, "mount_aquatic":mount_body.get_meta("water_aquatic", {}),
		"mounted":bool(riding.call("is_mounted")), "mount_uid":str(_creature.get("uid")),
		"player_position":str(player.global_position), "mount_position":str(mount_body.global_position),
		"player_depth_m":float(world.call("water_depth_at", player.global_position)),
		"mount_depth_m":float(world.call("water_depth_at", mount_body.global_position)),
		"predicted_dismount_position":str(predicted) if predicted.is_finite() else "",
		"predicted_dismount_depth_m":float(world.call("water_depth_at", predicted)) if predicted.is_finite() else null,
		"requested_input":str(Input.get_vector("move_left", "move_right", "move_forward", "move_back")),
		"paused":paused, "input_owned":INPUT_OWNER.current(self) != null,
		"moving_seconds":_moving_seconds, "observed_step":_last_step.duplicate(),
		"trainer_stamina":float(player.get("vitals").stamina), "trainer_health":float(player.get("vitals").health),
		"mount_stamina_fraction":float(_creature.get("swim_stamina_fraction")),
		"mount_fainted":bool(_creature.get("fainted")), "riding_pose":bool(model.get("_riding")),
		"rider_visible":model.is_visible_in_tree(), "seat_error_m":seat_error,
		"saddle_visible":saddle != null and saddle.is_visible_in_tree(),
		"camera_target":str(target.get_path()) if target != null else "",
		"camera_distance":float(camera.get("_distance")), "camera_height":float(camera.get("_height")),
		"on_floor":player.is_on_floor(), "collision_layer":player.collision_layer, "collision_mask":player.collision_mask}

func _save_frame(id: String) -> bool:
	if not _identity_intact():
		_fail("Actual mount identity is unavailable for this frame")
		return false
	if records.size() >= MAX_PNGS:
		_fail("Total mounted-swim PNG bound exceeded")
		return false
	var picture := root.get_texture().get_image()
	var path := "%s/mounted-swim-%04d-%s.png" % [output, records.size(), id]
	if picture == null or picture.is_empty() or picture.save_png(path) != OK:
		_fail("Cannot save native mounted-swim frame: " + path)
		return false
	var record := _snapshot()
	record.merge({"id":id, "frame_id":path.get_file().get_basename(), "file":path,
		"time_s":float(record.elapsed_ms) / 1000.0, "resolution":[picture.get_width(), picture.get_height()]})
	records.append(record)
	_captured[id] = true
	return true

func _save(id: String) -> bool:
	await RenderingServer.frame_post_draw
	return _failure.is_empty() and _save_frame(id)

func _identity_intact() -> bool:
	return is_instance_valid(mount_body) and director.call("ally_body") == mount_body \
		and director.call("ally_instance") == _creature \
		and str(mount_body.get("species_id")) == "water_aquaryn" \
		and str(_creature.get("uid")) == str(_identity.mount_uid) \
		and root.get_node("Game").get("party").call("active") == _creature

func _mounted_intact() -> bool:
	if not _identity_intact(): return false
	var saddle := mount_body.get_node_or_null("RideSaddle") as Node3D
	return _identity_intact() and bool(riding.call("is_mounted")) and riding.call("mount_body") == mount_body \
		and player.call("carrier") == mount_body and bool(player.call("is_carried")) \
		and bool(model.get("_riding")) and model.is_visible_in_tree() \
		and saddle != null and saddle.is_visible_in_tree() and camera.get("_target") == mount_body \
		and player.collision_layer == 0 and player.collision_mask == 0

func _dismount_prediction_ready() -> bool:
	if not _mounted_intact() or int(swimming.call("snapshot").mode) != STATE.Mode.MOUNTED:
		return false
	var predicted: Vector3 = riding.call("_dismount_spot", mount_body)
	if not predicted.is_finite(): return false
	var depth := float(world.call("water_depth_at", predicted))
	return depth > float(_rules.human.exit_depth_m) and depth < float(_rules.human.entry_depth_m) \
		and Vector2(mount_body.velocity.x, mount_body.velocity.z).length() <= 0.01

func _mounted(body: Node3D) -> void:
	_mount_events += 1
	if _phase != "mount_request" or body != mount_body or _mount_events != 1:
		_fail("Unexpected mounted signal or mount identity")
	_events.append({"event":"mounted", "ticks_ms":Time.get_ticks_msec(), "mount_uid":str(_creature.get("uid"))})

func _dismounted() -> void:
	_dismount_events += 1
	if _phase != "dismount_request" or _dismount_events != 1:
		_fail("Unexpected dismounted signal")
	# Base dismount emits before WaterRidingController applies its HUMAN/LAND
	# transition. The later arbiter activation receipt observes that result.
	_events.append({"event":"dismounted", "ticks_ms":Time.get_ticks_msec(),
		"mode_before_water_override":int(swimming.call("snapshot").mode)})

func _activated(provider: Object) -> void:
	if provider != riding or _phase not in ["mount_request", "dismount_request"]:
		_fail("Ordinary Interact activated an unexpected provider")
		return
	_activations += 1
	var receipt := _snapshot()
	receipt.event = "arbiter_activated_riding"
	_events.append(receipt)

func _interact(want_mount: bool) -> bool:
	_phase = "mount_request" if want_mount else "dismount_request"
	var selected := false
	for frame in 180:
		if not _failure.is_empty(): return false
		if INPUT_OWNER.current(self) == null and bool(arbiter.call("enabled")) and arbiter.call("winning_provider") == riding:
			selected = true
			break
		await physics_frame
	if not selected:
		_fail("Real RidingController offer did not win Interact: " + str(arbiter.call("prompt")))
		return false
	if not await _save("mount_prompt" if want_mount else "dismount_prompt"): return false
	if INPUT_OWNER.current(self) != null or arbiter.call("winning_provider") != riding:
		_fail("Riding offer changed before the ordinary press")
		return false
	if not want_mount and not _dismount_prediction_ready():
		_fail("Actual predicted trainer dismount left the configured band or the mount was still moving")
		return false
	var before := _activations
	_input("interact", true)
	await _frames(2)
	await process_frame
	_input("interact", false)
	await _frames(2)
	await process_frame
	if _activations != before + 1 or bool(riding.call("is_mounted")) != want_mount \
			or _mount_events != 1 or _dismount_events != (0 if want_mount else 1):
		_fail("Ordinary Interact did not produce exactly one expected riding transition")
	return _failure.is_empty()

## Completed native physics steps, independent of PNG/render cadence. Credit
## only real requested MOUNTED displacement after subtracting production flow.
func _observe_motion() -> void:
	if not _identity_intact():
		_fail("Owned mount identity changed during the capture")
		return
	var packet: Dictionary = swimming.call("snapshot")
	var mode := int(packet.mode)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var allowed := _phase in ["outbound", "circuit", "return"] and not paused \
		and INPUT_OWNER.current(self) == null and input.length() > 0.15 and _mounted_intact()
	var delta := mount_body.get_physics_process_delta_time()
	var displacement := mount_body.global_position - _previous_position
	displacement.y = 0.0
	var flow: Vector3 = world.call("current_at", _previous_position)
	var driven := displacement - Vector3(flow.x, 0.0, flow.z) * delta
	var moving := allowed and _previous_allowed and mode == STATE.Mode.MOUNTED \
		and _previous_mode == STATE.Mode.MOUNTED and delta > 0.0 \
		and displacement.length() > 0.001 and displacement.length() <= 3.0 and driven.dot(_previous_direction) > 0.001
	_last_step = {"moving":moving, "delta":delta, "displacement":str(displacement),
		"requested_direction":str(_previous_direction), "current":str(flow)}
	if moving: _moving_seconds += delta
	if not is_equal_approx(Engine.time_scale, _time_scale): _fail("Simulation time scale changed")
	if bool(packet.drowning) or bool(_creature.get("fainted")) or bool(player.get("vitals").is_dead()):
		_fail("Mounted swimming exhausted, fainted or killed a participant")
	if _phase in ["outbound", "circuit", "return"] and not _mounted_intact():
		_fail("Live mounted body/seat/camera/collision relationship was lost")
	_previous_position = mount_body.global_position
	_previous_mode = mode
	_previous_allowed = allowed
	var basis: Basis = camera.call("planar_basis")
	_previous_direction = (basis * Vector3(input.x, 0.0, input.y)).normalized()

func _capture() -> void:
	if not _failure.is_empty(): return
	if not _identity_intact():
		_fail("Owned mount identity changed before drawing")
		return
	var mode := int(swimming.call("snapshot").mode)
	if mode == STATE.Mode.MOUNTED and _mounted_intact() and not _captured.has("mounted_entry"):
		_save_frame("mounted_entry")
	if mode != STATE.Mode.MOUNTED or not _mounted_intact() or paused or INPUT_OWNER.current(self) != null \
			or not bool(_last_step.get("moving", false)) \
			or Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() <= 0.15 \
			or _sampled_seconds() >= MOTION_SECONDS or _motion_samples >= MAX_PNGS - TRANSITION_RESERVE:
		return
	if _first_sample_seconds >= 0.0 and _moving_seconds - _last_sample_seconds < SAMPLE_SECONDS: return
	if not _save_frame("motion"): return
	if _first_sample_seconds < 0.0:
		_first_sample_seconds = _moving_seconds
	else:
		_largest_sample_gap = maxf(_largest_sample_gap, _moving_seconds - _last_sample_seconds)
	_last_sample_seconds = _moving_seconds
	_motion_samples += 1

func _steer(target: Vector3, seconds: float, mounted: bool, dismount_arrival: bool = false) -> bool:
	for frame in ceili(seconds * Engine.physics_ticks_per_second):
		if not _failure.is_empty(): break
		if mounted and not _mounted_intact():
			_fail("Expected the same live mounted body throughout this leg")
			break
		var from := mount_body.global_position if mounted else player.global_position
		# The trainer lands beside the body along its CURRENT heading. Guide
		# ordinary movement/turning by that production predictor, not the mount
		# origin; no actor transform or aquatic state is written here.
		if dismount_arrival:
			from = riding.call("_dismount_spot", mount_body)
			if not from.is_finite():
				_fail("Production dismount predictor returned no finite landing")
				break
		var offset := target - from
		offset.y = 0.0
		# Release early enough for the real creature friction to stop the ride;
		# never set its velocity. Keep the original whole-leg time budget.
		var braking := 0.1 if dismount_arrival else 0.8
		if mounted:
			var speed := Vector2(mount_body.velocity.x, mount_body.velocity.z).length()
			braking = maxf(braking, speed * speed / (2.0 * maxf(0.001, float(mount_body.get("_friction"))))
				+ speed * mount_body.get_physics_process_delta_time())
		if offset.length() <= braking:
			_action(false)
		else:
			camera.set("yaw", atan2(-offset.x, -offset.z))
			_action(true)
		await physics_frame
	_action(false)
	if not _failure.is_empty(): return false
	var final_position := mount_body.global_position if mounted else player.global_position
	if dismount_arrival: final_position = riding.call("_dismount_spot", mount_body)
	var remaining := target - final_position
	remaining.y = 0.0
	if dismount_arrival:
		var receipt := _snapshot()
		receipt.event = "predicted_dismount_arrival"
		receipt.target = str(target)
		receipt.remaining_m = remaining.length()
		_events.append(receipt)
	if remaining.length() <= (0.1 if dismount_arrival else 0.8) \
			and (not dismount_arrival or _dismount_prediction_ready()): return true
	_fail("Actual mounted-swim leg did not arrive within %.1f seconds: %s" % [seconds, target])
	return false

func _surface_circuit(lesson: Dictionary) -> bool:
	_phase = "circuit"
	var west: Array = lesson.surface_polyline[0]
	var east: Array = lesson.surface_polyline[-1]
	var endpoints := [Vector3(float(west[0]), 0, float(west[2])), Vector3(float(east[0]), 0, float(east[2]))]
	var next := 1
	for frame in ceili(CIRCUIT_SECONDS * Engine.physics_ticks_per_second):
		if not _failure.is_empty(): break
		if not _mounted_intact() or int(swimming.call("snapshot").mode) != STATE.Mode.MOUNTED:
			_fail("Additional surface circuit left actual MOUNTED mode")
			break
		if _moving_seconds >= MOTION_SECONDS and _sampled_seconds() >= MOTION_SECONDS:
			_action(false)
			return true
		var offset: Vector3 = endpoints[next] - mount_body.global_position
		offset.y = 0.0
		if offset.length() <= 0.8:
			next = 1 - next
			offset = endpoints[next] - mount_body.global_position
			offset.y = 0.0
		camera.set("yaw", atan2(-offset.x, -offset.z))
		_action(true)
		await physics_frame
	_action(false)
	_fail("Bounded surface circuit lacks 30 actual moving/sample seconds: moving=%.3f sampled=%.3f" % [_moving_seconds, _sampled_seconds()])
	return false

func _spot_with_depth(target: float) -> Vector3:
	var lesson: Dictionary = world.get("config").swim_lesson
	var start: Array = lesson.surface_polyline[0]
	var from := Vector3(float(start[0]), 0.0, float(start[2]))
	var seaward := Vector3(from.x, 0.0, from.z).normalized()
	for step in 4000:
		var at := from + seaward * (float(step) * 0.05 - 40.0)
		if absf(float(world.call("water_depth_at", at)) - target) < 0.03: return at
	_fail("No actual shore point at configured depth %.3f" % target)
	return Vector3.INF

func _finish() -> void:
	_action(false)
	_input("interact", false)
	if physics_frame.is_connected(_observe_motion): physics_frame.disconnect(_observe_motion)
	if RenderingServer.frame_post_draw.is_connected(_capture): RenderingServer.frame_post_draw.disconnect(_capture)
	if riding != null:
		if riding.mounted.is_connected(_mounted): riding.mounted.disconnect(_mounted)
		if riding.dismounted.is_connected(_dismounted): riding.dismounted.disconnect(_dismounted)
	if arbiter != null and arbiter.activated.is_connected(_activated): arbiter.activated.disconnect(_activated)
	var stream := FileAccess.open(output + "/manifest.json", FileAccess.WRITE)
	if stream == null:
		_fail("Cannot write mounted-swim manifest")
	else:
		stream.store_string(JSON.stringify({"biome":"tidewake", "system":"mounted swimming", "seed":capture_seed,
			"scene":"res://scenes/world/water_archipelago.tscn", "complete":_failure.is_empty(), "failure":_failure,
			"identity":_identity, "initial_state":_before, "rules":_rules, "records":records, "events":_events,
			"elapsed_ms":Time.get_ticks_msec() - _started_ms, "moving_seconds":_moving_seconds,
			"sampled_moving_seconds":_sampled_seconds(), "sample_interval_seconds":SAMPLE_SECONDS,
			"largest_sample_gap_seconds":_largest_sample_gap, "motion_samples":_motion_samples,
			"maximum_pngs":MAX_PNGS, "reserved_transition_pngs":TRANSITION_RESERVE,
			"leg_seconds":{"outbound":12, "additional_surface_circuit":CIRCUIT_SECONDS, "return":11, "human_exit":16},
			"resolution":[root.size.x, root.size.y], "time_scale":Engine.time_scale,
			"display_server":DisplayServer.get_name(), "rendering_method":RenderingServer.get_current_rendering_method(),
			"repro_args":OS.get_cmdline_user_args(), "producer_sha256":FileAccess.get_sha256("res://tools/phase2_capture_tidewake_mounted_swim.gd"),
			"fixture_disclosure":"New-game reset; owned Aquaryn, Swim Stone/recipe and saddle seeded; initial shore placement and summon. Real arbiter-selected Interact mounts/dismounts; ordinary directional input adds a bounded surface circuit. Native viewport/HUD; no clock/resource/aquatic-state/pose overrides. Raw PNGs are artifacts. Diagnostic only, not earned progression, Ripplet proof or visual acceptance."}, "\t") + "\n")
		stream.close()
	if _failure.is_empty(): print("DISMOUNT MOTION OK frames=", records.size(), " moving=", _moving_seconds, " sampled=", _sampled_seconds())
	quit(0 if _failure.is_empty() else 1)

func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		elif argument.begins_with("--seed="): capture_seed = int(argument.trim_prefix("--seed="))
	if not output.begins_with("res://ralph/reports/VISUAL/phase2/tidewake/"):
		push_error("Mounted-swim evidence must stay in Tidewake Phase 2")
		quit(1)
		return
	_started_ms = Time.get_ticks_msec()
	_time_scale = Engine.time_scale
	seed(capture_seed)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	if DisplayServer.get_name() == "headless":
		_fail("Motion capture requires a rendering display")
		_finish()
		return
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	game.local.flags.set_flag("water_swim_stone_earned")
	game.local.flags.set_flag("water_swim_saddle_recipe_taught")
	game.local.inventory.add("swim_saddle", 1)
	_creature = SPECIES.spawn("water_aquaryn")
	if not bool(game.local.party.add(_creature)) or game.local.party.active() != _creature:
		_fail("Fixture did not select its owned Aquaryn")
		_finish()
		return
	world = WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")): break
	if not bool(world.call("shell_build_complete")):
		_fail("Production Water shell did not complete")
		_finish()
		return
	player = world.get_node("Player") as CharacterBody3D
	camera = world.get_node("CameraRig") as Node3D
	model = player.get_node("Model")
	riding = world.get_node("RidingController")
	swimming = player.get("swim_controller")
	director = world.get_node("EncounterDirector")
	arbiter = world.get_node("InteractionArbiter")
	_rules = (swimming.get("_config") as Dictionary).duplicate(true)
	var config: Dictionary = world.get("config")
	var lesson: Dictionary = config.swim_lesson
	var anchors: Array = config.anchors.filter(func(row: Dictionary) -> bool: return str(row.id) == str(lesson.start_anchor))
	if anchors.size() != 1:
		_fail("Missing unique production lesson shore anchor")
		_finish()
		return
	var start: Array = anchors[0].safe_position
	var shore := Vector3(float(start[0]), 0.0, float(start[2]))
	shore.y = float(world.call("ground_height_at", shore.x, shore.z)) + 0.2
	player.global_position = shore
	await _frames(30)
	director.call("summon_active_creature")
	await _frames(30)
	mount_body = director.call("ally_body") as CharacterBody3D
	var chosen := TRAINER.resolved_appearance_id(str(model.get("appearance_id")), game)
	if mount_body == null or not bool(mount_body.call("has_model")) or director.call("ally_instance") != _creature \
			or str(mount_body.get("species_id")) != "water_aquaryn" or not bool(model.call("has_model")) \
			or str(model.get("_config_key")) != chosen or model.call("skeleton") == null \
			or model.call("animation_player") == null or not player.is_on_floor() \
			or int(swimming.call("snapshot").mode) != STATE.Mode.LAND:
		_fail("Actual owned mount/trainer body or dry fixture failed; fallback refused")
		_finish()
		return
	var look := SPECIES.placeholder("water_aquaryn")
	var pivot: Node3D = mount_body.call("model_pivot")
	if pivot.get_child_count() == 0 or str(pivot.get_child(0).scene_file_path) != str(look.model):
		_fail("Actual Aquaryn art does not match its configured model")
		_finish()
		return
	var profile: Dictionary = model.call("config")
	_identity = {"character_id":str(game.local.character_id), "body":chosen,
		"body_model":str(profile.model), "body_model_sha256":FileAccess.get_sha256(str(profile.model)),
		"mount_uid":str(_creature.get("uid")), "mount_species":"water_aquaryn",
		"mount_model":str(look.model), "mount_model_sha256":FileAccess.get_sha256(str(look.model))}
	if str(_identity.character_id).is_empty() or str(_identity.mount_uid).is_empty() \
			or str(_identity.body_model_sha256).is_empty() or str(_identity.mount_model_sha256).is_empty():
		_fail("Actual trainer/mount identity or model source hash missing")
		_finish()
		return
	var collision := player.get_node("Collision") as CollisionShape3D
	_ground_shape = collision.shape
	var collision_position := collision.position
	_before = {"collision_layer":player.collision_layer, "collision_mask":player.collision_mask,
		"collision_position":str(collision_position), "floor_snap":player.floor_snap_length,
		"camera_distance":float(camera.get("_distance")), "camera_height":float(camera.get("_height"))}
	if not await _save("shore_before"):
		_finish()
		return
	_previous_position = mount_body.global_position
	riding.mounted.connect(_mounted)
	riding.dismounted.connect(_dismounted)
	arbiter.activated.connect(_activated)
	physics_frame.connect(_observe_motion)
	RenderingServer.frame_post_draw.connect(_capture)
	if not await _interact(true) or not _mounted_intact() \
			or int(swimming.call("snapshot").mode) != STATE.Mode.LAND or not mount_body.is_on_floor() \
			or not await _save("mounted_dry"):
		_fail("Ordinary mounted dry transition failed")
		_finish()
		return
	var deep := _spot_with_depth(4.0)
	var midpoint := (float(_rules.human.exit_depth_m) + float(_rules.human.entry_depth_m)) * 0.5
	var shallow := _spot_with_depth(midpoint)
	if not deep.is_finite() or not shallow.is_finite():
		_finish()
		return
	_phase = "outbound"
	if not await _steer(deep, 12.0, true) or int(swimming.call("snapshot").mode) != STATE.Mode.MOUNTED:
		_fail("Actual outbound arrival did not reach MOUNTED water")
		_finish()
		return
	if not await _save("mounted_deep") or not await _surface_circuit(lesson):
		_finish()
		return
	_phase = "return"
	if not await _steer(shallow, 11.0, true, true) or int(swimming.call("snapshot").mode) != STATE.Mode.MOUNTED:
		_fail("Actual return did not preserve MOUNTED hysteresis state")
		_finish()
		return
	if not await _save("before_dismount") or not await _interact(false):
		_finish()
		return
	_phase = "human_exit"
	var depth := float(world.call("water_depth_at", player.global_position))
	if depth <= float(_rules.human.exit_depth_m) or depth >= float(_rules.human.entry_depth_m) \
			or int(swimming.call("snapshot").mode) != STATE.Mode.HUMAN \
			or bool(player.call("is_carried")) or bool(model.get("_riding")):
		_fail("Actual dismount missed the configured hysteresis/HUMAN witness: depth=%.3f mode=%s" % [depth, swimming.call("snapshot").mode])
		_finish()
		return
	if not await _save("human_after_dismount") or not await _steer(shore, 16.0, false):
		_finish()
		return
	await _frames(10)
	if not _identity_intact() or bool(riding.call("is_mounted")) or bool(player.call("is_carried")) \
			or not player.is_on_floor() or int(swimming.call("snapshot").mode) != STATE.Mode.LAND \
			or bool(model.get("_riding")) or bool(model.get("_fly_hang")) or not model.is_visible_in_tree() \
			or collision.shape != _ground_shape or not collision.position.is_equal_approx(collision_position) \
			or player.collision_layer != int(_before.collision_layer) or player.collision_mask != int(_before.collision_mask) \
			or not is_equal_approx(player.floor_snap_length, float(_before.floor_snap)) or camera.get("_target") != player \
			or not is_equal_approx(float(camera.get("_distance")), float(_before.camera_distance)) \
			or not is_equal_approx(float(camera.get("_height")), float(_before.camera_height)) \
			or not bool(model.call("animation_player").active) or not bool(model.call("animation_player").is_playing()) \
			or mount_body.get_node_or_null("RideSaddle") == null \
			or not (mount_body.get_node("RideSaddle") as Node3D).is_visible_in_tree():
		_fail("Actual dry exit did not restore player floor/pose/collision/camera and preserve mount identity/saddle")
	if _failure.is_empty():
		_phase = "restored"
		await _save("dry_exit_restored")
	if _moving_seconds < MOTION_SECONDS or _sampled_seconds() < MOTION_SECONDS or _activations != 2 \
			or _mount_events != 1 or _dismount_events != 1:
		_fail("Mounted capture lacks actual movement coverage or exact ordinary transition receipts")
	for required: String in ["shore_before", "mount_prompt", "mounted_dry", "mounted_entry", "mounted_deep", "before_dismount", "dismount_prompt", "human_after_dismount", "dry_exit_restored"]:
		if not _captured.has(required): _fail("Missing actual mounted-swim transition image: " + required)
	_finish()
