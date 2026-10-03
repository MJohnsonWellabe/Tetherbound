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

func _init() -> void: _run.call_deferred()

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	if not proof.fixture(game, "Presentation"): finish(); return
	change_scene_to_file("res://scenes/world/meadows_playground.tscn")
	if not await proof.ready(self, game): finish(); return
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

func _prepare_camera(travel: RefCounted) -> void:
	# Use the player's normal recenter button. Never assign a camera pose or
	# move the trainer/arch to manufacture a clear capture.
	await travel.tap("camera_recenter")
	var camera := root.get_camera_3d()
	var player := root.get_node("Game").call("find_player") as CharacterBody3D
	print("F20 CAPTURE ordinary recenter camera=", camera.global_transform if camera != null else Transform3D.IDENTITY,
		" player=", player.global_position if player != null else Vector3.INF)

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
