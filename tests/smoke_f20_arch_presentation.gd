extends SceneTree

## Run with a real renderer/audio driver under the shared GPU reservation.
## Captures the ordinary camera and actual mixed SFX, never a mocked effect.
const PROOF := preload("res://tests/helpers/f20_ending_probe.gd")
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const LOOK_PREFS := preload("res://scripts/ui/look_prefs.gd")
var proof := PROOF.new()
var _recording: AudioEffectRecord
var _capture_started := false
var _capture_done := false
var _image_saved := false
var _startup_began := 0
var _startup_process_frames := 0
var _startup_draw_frames := 0

func _init() -> void: _run.call_deferred()

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	if not proof.fixture(game, "Presentation"): finish(); return
	_startup_began = Time.get_ticks_msec()
	process_frame.connect(_observe_startup_process)
	RenderingServer.frame_post_draw.connect(_observe_startup_draw)
	change_scene_to_file("res://scenes/world/meadows_playground.tscn")
	# Hosted software rendering has measured 132-second gaps between physics
	# samples. Allow bounded cold startup here; solo/net retain 180 seconds.
	# Shell completion, floor contact and personal context remain mandatory.
	var ready: bool = await proof.ready(self, game, 600000)
	_stop_startup_observers()
	if not ready: finish(); return
	proof.diagnose_home_anchor(self, game)
	var bus := AudioServer.get_bus_index("SFX")
	if not proof.check(bus >= 0, "production SFX bus exists"): finish(); return
	_recording = AudioEffectRecord.new()
	var effect := AudioServer.get_bus_effect_count(bus)
	AudioServer.add_bus_effect(bus, _recording)
	var travel := TRAVEL.new(self, game)
	travel.before_interact = _prepare_camera.bind(travel)
	game.connect("portal_action_result", _capture_stir)
	var passed := await proof.fifth(self, game, travel)
	game.disconnect("portal_action_result", _capture_stir)
	while _capture_started and not _capture_done: await process_frame
	if passed:
		proof.check(_capture_started and _image_saved, "first framebuffer after actual stir result saved for visual review")
	_recording.set_recording_active(false)
	var clip := _recording.get_recording()
	if passed:
		proof.check(clip != null and not clip.data.is_empty() and clip.save_to_wav("user://f20-fifth-sfx.wav") == OK,
			"mixed SFX from actual stir result recorded for audio review")
	AudioServer.remove_bus_effect(bus, effect)
	print("F20 PRESENTATION FILES ", OS.get_user_data_dir())
	finish()

func _observe_startup_process() -> void: _startup_process_frames += 1

func _observe_startup_draw() -> void: _startup_draw_frames += 1

func _stop_startup_observers() -> void:
	if process_frame.is_connected(_observe_startup_process): process_frame.disconnect(_observe_startup_process)
	if RenderingServer.frame_post_draw.is_connected(_observe_startup_draw): RenderingServer.frame_post_draw.disconnect(_observe_startup_draw)
	print("F20 RENDER STARTUP elapsed_ms=", Time.get_ticks_msec() - _startup_began,
		" process_frames=", _startup_process_frames, " post_draw_frames=", _startup_draw_frames,
		" readiness_budget_ms=600000; software-render allowance, no device performance claim")

func _prepare_camera(travel: RefCounted) -> bool:
	# Recenter follows the player root's bearing, which need not face the arch.
	# Orbit with ordinary mouse motion; never assign a camera/player transform.
	await travel.tap("camera_recenter")
	var camera := root.get_camera_3d()
	var player := root.get_node("Game").call("find_player") as CharacterBody3D
	var rig := current_scene.get_node_or_null("CameraRig") as Node3D
	var arch: Node3D
	for candidate: Node3D in get_nodes_in_group("portal_arches"):
		if candidate.get("arch_id") == "biome5" and current_scene.is_ancestor_of(candidate): arch = candidate
	if not proof.check(camera != null and player != null and rig != null and arch != null \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and INPUT_OWNER.current(self) == null,
		"ordinary captured mouse and actual fifth arch are available for framing"): return false
	var surface := arch.get_parent().get_node_or_null("PortalSurface") as MeshInstance3D
	if not proof.check(surface != null and surface.mesh != null, "actual mounted portal surface supplies framing bounds"): return false
	var bounds := surface.get_aabb()
	var toward := surface.to_global(bounds.get_center()) - player.global_position
	toward.y = 0.0
	var sensitivity: float = LOOK_PREFS.apply(Vector2(float(rig.get("_mouse_sensitivity")), 0.0)).x
	if not proof.check(toward.is_finite() and toward.length() > 0.01 and is_finite(sensitivity) and absf(sensitivity) > 0.001,
		"ordinary look has a finite target bearing and sensitivity"): return false
	var desired_yaw := atan2(-toward.x, -toward.z)
	var deadline := Time.get_ticks_msec() + 180000
	var motions := 0
	var recoveries := int(player.get("_unstick_count"))
	while motions < 32 and Time.get_ticks_msec() < deadline:
		var error := wrapf(desired_yaw - float(rig.get("yaw")), -PI, PI)
		if absf(error) <= deg_to_rad(2.0): break
		if INPUT_OWNER.current(self) != null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: break
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(-clampf(rad_to_deg(error), -24.0, 24.0) / sensitivity, 0.0)
		Input.parse_input_event(motion)
		motions += 1
		# Both edges include an ordinary _apply_look pass after _unhandled_input.
		for frame in 2: await process_frame
	for frame in 2: await physics_frame
	for frame in 2: await process_frame
	var queued_motion: Vector2 = rig.get("_mouse_delta")
	var framed := absf(wrapf(desired_yaw - float(rig.get("yaw")), -PI, PI)) <= deg_to_rad(2.0) \
		and queued_motion.is_zero_approx() and Time.get_ticks_msec() < deadline
	var inset := root.get_visible_rect().grow(-32.0)
	for corner in 8:
		var point := surface.to_global(bounds.position + bounds.size * Vector3(float(corner & 1), float((corner >> 1) & 1), float((corner >> 2) & 1)))
		framed = framed and not camera.is_position_behind(point) and inset.has_point(camera.unproject_position(point))
	var settings: Dictionary = arch.get("_stir_settings")
	var glow_point := arch.to_global(Vector3.UP * float(settings.get("glow_height_m", 1.3)))
	framed = framed and not camera.is_position_behind(glow_point) and inset.has_point(camera.unproject_position(glow_point))
	var arbiter := current_scene.get_node_or_null("InteractionArbiter")
	print("F20 CAPTURE ordinary look motions=", motions, " camera=", camera.global_transform,
		" player=", player.global_position, " surface_bounds=", bounds,
		" glow_screen=", camera.unproject_position(glow_point), " framed=", framed)
	return proof.check(framed and player.is_on_floor() and int(player.get("_unstick_count")) == recoveries \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and INPUT_OWNER.current(self) == null and arbiter != null \
		and arbiter.call("winning_provider") == arch.get_node("Interactable") \
		and arbiter.call("winner").get("actionable") == true,
		"ordinary look frames the actual opening/glow while retaining grounded exact actionable provider")

func _capture_stir(result: Dictionary) -> void:
	var game := root.get_node("Game")
	if _capture_started or result.get("kind") != "portal_unlock" or result.get("arch_id") != "biome5" \
			or result.get("ok") != true or result.get("durable") != true \
			or result.get("character_id") != game.local.character_id \
			or result.get("world_instance_id") != game.world.reward_delivery_namespace: return
	_capture_started = true
	var began := Time.get_ticks_msec()
	_recording.set_recording_active(true)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_image_saved = image != null and not image.is_empty() and image.save_png("user://f20-fifth-stir.png") == OK
	print("F20 CAPTURE first_result_frame elapsed_ms=", Time.get_ticks_msec() - began, " request=", result.get("request_id"))
	while Time.get_ticks_msec() < began + 3000: await process_frame
	_recording.set_recording_active(false)
	_capture_done = true
	print("F20 CAPTURE mixed_audio_interval_ms=", Time.get_ticks_msec() - began)

func finish() -> void:
	for failure: String in proof.failures: print("F20 FAIL ", failure)
	print("F20 PRESENTATION: %d checks, %d failures; ordinary input/camera, real renderer and SFX bus" % [proof.checks, proof.failures.size()])
	quit(0 if proof.failures.is_empty() else 1)
