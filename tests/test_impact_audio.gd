extends "res://tests/test_case.gd"

const MIX := preload("res://scripts/combat/impact_audio.gd")

func _pcm(values: Array, rate: int = 22050, stereo: bool = false) -> AudioStreamWAV:
	var source := AudioStreamWAV.new()
	source.format = AudioStreamWAV.FORMAT_16_BITS
	source.mix_rate = rate
	source.stereo = stereo
	var data := PackedByteArray()
	data.resize(values.size() * 2)
	for i in values.size(): data.encode_s16(i * 2, int(values[i]))
	source.data = data
	return source

func test_contact_retains_semantic_layers_and_reuses_bounded_mix() -> void:
	var body := _pcm([1000, 1000, 0, 0])
	var critical := _pcm([0, 0, 2000, 2000])
	var before := body.data.duplicate()
	var layers := [{"stream": body}, {"stream": critical}]
	var mixed := MIX.compose(layers, {})
	assert_true(mixed != null)
	assert_almost_eq(mixed.data.decode_s16(0), 1000, 1)
	assert_almost_eq(mixed.data.decode_s16(4), 2000, 1)
	assert_eq(body.data, before, "PCM source remains immutable")
	assert_true(MIX.compose(layers, {}) == mixed, "repeated variants reuse cached PCM")

func test_stereo_downmix_rate_pitch_and_peak_keep_all_layers() -> void:
	var stereo := _pcm([1000, 3000, 1000, 3000], 11025, true)
	var mixed := MIX.compose([{"stream": stereo}], {"mix_rate": 22050})
	assert_eq(mixed.data.size(), 8)
	assert_almost_eq(mixed.data.decode_s16(0), 2000, 1)
	var pitched := MIX.compose([{"stream": stereo, "pitch": 2.0}], {"mix_rate": 22050})
	assert_eq(pitched.data.size(), 4)
	var loud := _pcm([30000, -30000])
	var layered := MIX.compose([{"stream": loud}, {"stream": loud}], {"peak_limit": 0.5})
	assert_almost_eq(layered.data.decode_s16(0), 16384, 1)
	assert_almost_eq(layered.data.decode_s16(2), -16384, 1)
	assert_eq(loud.data.decode_s16(0), 30000)

func test_empty_layer_refuses_instead_of_dropping_required_semantics() -> void:
	var empty := AudioStreamWAV.new()
	assert_true(MIX.compose([{"stream": _pcm([1000])}, {"stream": empty}], {}) == null)

func test_shipping_semantic_layers_decode_all_imported_codecs() -> void:
	var audio := preload("res://scripts/audio/audio_manager.gd")
	var layers: Array = []
	for name: String in ["impact_normal", "impact_super", "impact_weak", "damage_taken"]:
		var source := audio.stream(audio.sfx_path(name)) as AudioStreamWAV
		assert_true(source != null, "shipping semantic layer imports as PCM WAV: " + name)
		layers.append({"stream": source, "gain_db": -8.0})
	var mixed := MIX.compose(layers, audio.section("combat").get("impact_feedback", {}).get("contact_mix", {}))
	assert_true(mixed != null, "all required semantic layers survive actual imported rates")
	assert_true(mixed != null and not mixed.data.is_empty())
	var peak := 0
	if mixed != null:
		for index in mixed.data.size() / 2: peak = maxi(peak, absi(mixed.data.decode_s16(index * 2)))
	assert_true(peak > 250, "native decoder retains audible semantic samples")
