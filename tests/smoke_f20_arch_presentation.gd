extends SceneTree

## Run with a real renderer/audio driver under the shared GPU reservation.
## Captures the ordinary camera and actual mixed SFX, never a mocked effect.
const PROOF := preload("res://tests/helpers/f20_ending_probe.gd")
var proof := PROOF.new()

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
	var recording := AudioEffectRecord.new()
	var effect := AudioServer.get_bus_effect_count(bus)
	AudioServer.add_bus_effect(bus, recording)
	recording.set_recording_active(true)
	var passed := await proof.fifth(self, game)
	if passed:
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		proof.check(image != null and not image.is_empty() and image.save_png("user://f20-fifth-stir.png") == OK,
			"actual gameplay framebuffer captured during sealed arch glow")
		var deadline := Time.get_ticks_msec() + 3000
		while Time.get_ticks_msec() < deadline: await process_frame
	recording.set_recording_active(false)
	var clip := recording.get_recording()
	if passed:
		proof.check(clip != null and not clip.data.is_empty() and clip.save_to_wav("user://f20-fifth-sfx.wav") == OK,
			"actual mixed SFX recorded for audible stir inspection")
	AudioServer.remove_bus_effect(bus, effect)
	print("F20 PRESENTATION FILES ", OS.get_user_data_dir())
	finish()

func finish() -> void:
	for failure: String in proof.failures: print("F20 FAIL ", failure)
	print("F20 PRESENTATION: %d checks, %d failures; ordinary input/camera, real renderer and SFX bus" % [proof.checks, proof.failures.size()])
	quit(0 if proof.failures.is_empty() else 1)
