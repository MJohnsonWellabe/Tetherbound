extends SceneTree

## Isolated production chime + passive export regression, not a Home Key use.
## No player/input/travel/earned/audio-device acceptance is claimed.
const HOME := preload("res://scripts/world/home_key.gd")
const CAPTURE := preload("res://tests/helpers/f18_presentation_capture.gd")
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason)

func _pcm_from_wav(path: String) -> PackedByteArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return PackedByteArray()
	if file.get_buffer(4).get_string_from_ascii() != "RIFF": return PackedByteArray()
	file.get_32()
	if file.get_buffer(4).get_string_from_ascii() != "WAVE": return PackedByteArray()
	while file.get_position() + 8 <= file.get_length():
		var chunk := file.get_buffer(4).get_string_from_ascii()
		var size := file.get_32()
		if file.get_position() + size > file.get_length(): return PackedByteArray()
		if chunk == "data": return file.get_buffer(size)
		file.seek(file.get_position() + size + (size % 2))
	return PackedByteArray()

func _run() -> void:
	await process_frame
	var output := "res://ralph/reports/HUB/f18/native/waveform_component_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var observer: Node = CAPTURE.attach(self, root.get_node(^"Game"), output)
	if observer == null:
		push_error("F18 waveform component could not attach its fresh observer")
		quit(1)
		return
	# Remote-only presentation avoids joining input ownership/authority. Its
	# ordinary _ready still loads the shipped settings; only the actual chime
	# generator is invoked here, explicitly as a component fixture.
	var presenter := HOME.new()
	presenter.set("_remote_only", true)
	root.add_child(presenter)
	presenter.call("_play_chime")
	var audio: Variant = presenter.get("_audio")
	if not is_instance_valid(audio) or not audio is AudioStreamPlayer or not audio.stream is AudioStreamWAV:
		failures.append("production component did not create its actual WAV audio player")
		presenter.free()
		observer.call("finish", "component setup failed")
		observer.free()
		quit(1)
		return
	var stream: AudioStreamWAV = audio.stream
	var pcm_before: PackedByteArray = stream.data
	var bus_before: String = str(audio.bus)
	var volume_before: float = audio.volume_db
	var first: Dictionary = observer.call("_audio_info", audio)
	var exported: Dictionary = first.get("waveform", {})
	_check(exported.get("status") == "exported_runtime_waveform", "exact playing runtime stream was not exported")
	var path: String = output.path_join(str(exported.get("wav", "")))
	_check(not pcm_before.is_empty() and _pcm_from_wav(path) == pcm_before, "saved WAV PCM differs from the actual production stream")
	_check(audio.stream == stream and stream.data == pcm_before and str(audio.bus) == bus_before
		and audio.volume_db == volume_before and audio.playing, "observer changed actual stream/playback/bus/player gain")
	var again: Dictionary = observer.call("_audio_info", audio)
	_check(again.get("waveform", {}) == exported, "same runtime stream lost its original cached observation")
	_check((observer.get("_manifest").get("waveforms", []) as Array).size() == 1,
		"same runtime stream produced multiple export records")
	_check(exported.get("stream_instance") == stream.get_instance_id()
		and exported.get("source_path") == stream.resource_path
		and exported.has("observed_monotonic_msec") and exported.has("observed_process_frame")
		and exported.has("observed_physics_frame"), "standalone export lacks actual source/time provenance")
	_check(exported.get("device_playback_proven") == false and exported.get("listened") == false,
		"source export improperly claimed device or listening acceptance")
	var settings: Dictionary = presenter.get("_settings")
	_check(absf(stream.get_length() - float(settings.get("raise_seconds", 0.0))) < 0.001,
		"production chime stream duration differs from shipped raise settings")
	observer.call("finish", "isolated production chime/export component finished")
	var manifest := JSON.parse_string(FileAccess.get_file_as_string(output.path_join("presentation.json"))) as Dictionary
	_check(manifest.get("waveforms", []).size() == 1 and manifest.get("errors", []).is_empty(),
		"durable observer manifest lost export or retained a write error")
	print("F18_WAVEFORM_EXPORT ", JSON.stringify({"failures": failures,
		"fixture": "isolated remote-only actual HomeKey presenter; private production chime invoked directly; no actual key use/input/raise/travel/earned/device/listening acceptance",
		"waveform": exported, "pcm_bytes": pcm_before.size(), "output": output,
		"audio_driver": AudioServer.get_driver_name(), "waveform_file_sha256": FileAccess.get_sha256(path)}))
	presenter.free()
	observer.free()
	quit(0 if failures.is_empty() else 1)
