extends SceneTree

## Run with a real renderer/audio driver under the shared GPU reservation.
## Captures the ordinary camera and actual mixed SFX, never a mocked effect.
const PROOF := preload("res://tests/helpers/f20_ending_probe.gd")
const TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
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

func _prepare_camera(travel: RefCounted) -> void:
	# Use the player's normal recenter button. Never assign a camera pose or
	# move the trainer/arch to manufacture a clear capture.
	await travel.tap("camera_recenter")
	var camera := root.get_camera_3d()
	var player := root.get_node("Game").call("find_player") as CharacterBody3D
	print("F20 CAPTURE ordinary recenter camera=", camera.global_transform if camera != null else Transform3D.IDENTITY,
		" player=", player.global_position if player != null else Vector3.INF)
	for arch: Node3D in get_nodes_in_group("portal_arches"):
		if arch.get("arch_id") == "biome5" and current_scene.is_ancestor_of(arch) and camera != null:
			print("F20 CAPTURE target_arch=", arch.global_transform,
				" behind_camera=", camera.is_position_behind(arch.global_position + Vector3.UP),
				" screen_point=", camera.unproject_position(arch.global_position + Vector3.UP))

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
