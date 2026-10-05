extends "res://tests/test_case.gd"

## Every asset path in data/config/stormwood_audio.json exists and loads as the
## kind of stream its cue needs (owner, 2026-10-05: the nine Stormwood WAVs are
## authored from installed sources by tools/audio/gen_stormwood.py). A loop cue
## must import as a forward loop: the observer starts each bed with a single
## play_file call, so a bed that does not loop goes silent mid-phase. A strike
## layer must not loop, or one lightning strike would sound forever.
##
## Spectral, loudness and seam checks are offline: tools/audio/check_stormwood.py.

const OBSERVER := preload("res://scripts/world/stormwood_surge_audio.gd")


func test_every_stormwood_cue_asset_loads() -> void:
	var cues: Array[Dictionary] = OBSERVER.all_cues(OBSERVER.load_config())
	assert_eq(cues.size(), 9, "the Stormwood audio contract names nine cues")
	for cue: Dictionary in cues:
		var path := str(cue.asset_path)
		assert_true(ResourceLoader.exists(path), "no Stormwood asset at %s" % path)
		var stream := load(path) as AudioStreamWAV
		assert_true(stream != null, "%s did not load as an AudioStreamWAV" % path)
		if stream == null:
			continue
		assert_true(stream.get_length() > 0.1, "%s is empty" % path)
		assert_false(stream.stereo, "%s must be mono" % path)
		if bool(cue.loop):
			assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s must loop" % path)
		else:
			assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_DISABLED, "%s must not loop" % path)


func test_strike_warning_matches_the_telegraph() -> void:
	var surge: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_surge.json"))
	var telegraph := float((surge as Dictionary).get("strike", {}).get("telegraph_seconds", 1.2))
	var warning := load("res://assets/audio/stormwood/strike_warning.wav") as AudioStreamWAV
	assert_true(warning != null, "strike_warning.wav did not load")
	if warning != null:
		assert_true(absf(warning.get_length() - telegraph) <= 0.02,
			"strike_warning lasts %.3f s; the telegraph is %.3f s" % [warning.get_length(), telegraph])
