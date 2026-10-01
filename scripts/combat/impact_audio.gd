extends RefCounted

## One contact voice retains body/type/critical/receiver layers. Input streams
## are cached by AudioManager; this bounded PCM cache performs no disk reads.
static var _cache: Dictionary = {}
static var _order: Array[String] = []

static func compose(layers: Array, cfg: Dictionary) -> AudioStreamWAV:
	var rate := clampi(int(cfg.get("mix_rate", 22050)), 8000, 48000)
	var peak_limit := clampf(float(cfg.get("peak_limit", 0.85)), 0.01, 1.0)
	var cap := maxi(1, int(float(cfg.get("max_seconds", 1.0)) * rate))
	var key := "%d:%d:%.6f" % [rate, cap, peak_limit]
	var frames := 0
	for layer: Dictionary in layers:
		var source := layer.get("stream") as AudioStreamWAV
		if source == null or source.data.is_empty() or source.get_length() <= 0.0:
			return null
		var pitch := maxf(0.01, float(layer.get("pitch", 1.0)))
		frames = maxi(frames, mini(cap, int(ceil(source.get_length() * rate / pitch))))
		key += ":%d:%.6f:%.6f" % [source.get_instance_id(), float(layer.get("gain_db", 0.0)), pitch]
	if layers.is_empty() or frames <= 0: return null
	if _cache.has(key): return _cache[key] as AudioStreamWAV
	var samples := PackedFloat32Array()
	samples.resize(frames)
	for layer: Dictionary in layers:
		var source := layer.get("stream") as AudioStreamWAV
		# Imported shipped WAVs use QOA. Decode through the engine's codec,
		# in memory, once per cached composite; exported raw files are unnecessary.
		if source.format != AudioStreamWAV.FORMAT_16_BITS:
			var playback := source.instantiate_playback()
			if playback == null: return null
			playback.start()
			var pitch := maxf(0.01, float(layer.get("pitch", 1.0)))
			var decoded := playback.mix_audio(float(AudioServer.get_mix_rate()) * pitch / rate,
				mini(cap, int(ceil(source.get_length() * rate / pitch))))
			playback.stop()
			var gain := db_to_linear(float(layer.get("gain_db", 0.0)))
			for index in mini(frames, decoded.size()): samples[index] += (decoded[index].x + decoded[index].y) * 0.5 * gain
			continue
		var bytes := source.data
		var channels := 2 if source.stereo else 1
		var width := 2
		var source_frames: int = bytes.size() / (channels * width)
		var gain := db_to_linear(float(layer.get("gain_db", 0.0)))
		var step := float(source.mix_rate) * maxf(0.01, float(layer.get("pitch", 1.0))) / rate
		for index in frames:
			var position := index * step
			var left := int(floor(position))
			if left >= source_frames: break
			var right := mini(left + 1, source_frames - 1)
			var value := lerpf(_sample(bytes, left, channels, width), _sample(bytes, right, channels, width), position - left)
			samples[index] += value * gain
	var peak := 0.0
	for sample: float in samples: peak = maxf(peak, absf(sample))
	var scale := peak_limit / peak if peak > peak_limit else 1.0
	var data := PackedByteArray()
	data.resize(frames * 2)
	for index in frames: data.encode_s16(index * 2, clampi(int(round(samples[index] * scale * 32767.0)), -32768, 32767))
	var mixed := AudioStreamWAV.new()
	mixed.format = AudioStreamWAV.FORMAT_16_BITS
	mixed.mix_rate = rate
	mixed.stereo = false
	mixed.data = data
	while _order.size() >= maxi(1, int(cfg.get("cache_entries", 64))): _cache.erase(_order.pop_front())
	_cache[key] = mixed
	_order.append(key)
	return mixed

static func _sample(bytes: PackedByteArray, frame: int, channels: int, width: int) -> float:
	var total := 0.0
	for channel in channels:
		var offset := (frame * channels + channel) * width
		total += float(bytes.decode_s16(offset)) / 32768.0
	return total / channels
