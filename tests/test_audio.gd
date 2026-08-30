extends "res://tests/test_case.gd"

## The audio system's pure, headless-testable half: the config is well formed,
## every path it names exists, the mixer matches it, and the variant picker
## keeps its no-immediate-repeat promise.
##
## The wired, in-world half -- ambience actually starting, footsteps actually
## firing as the player walks, combat signals actually reaching the mixer -- is
## `tests/smoke_audio.gd`, which boots the real scene. This file is the part
## D02 scopes to pure logic with no scene tree, and it deliberately does NOT
## assert that the game makes a sound: a green run here on a build with the
## `WorldAudio` node deleted would still pass, which is exactly the trap this
## lane found the project in.

const AUDIO := preload("res://scripts/audio/audio_manager.gd")
const AMBIENCE_DIR := "res://assets/audio/ambience"
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")


# --- the config is real -------------------------------------------------------


func test_audio_config_loads() -> void:
	assert_false(AUDIO.config().is_empty(), "data/config/audio.json did not load")


func test_every_ambience_layer_has_a_file() -> void:
	var layers: Array = AUDIO.section("ambience").get("layers", [])
	assert_true(layers.size() > 0, "audio.json names no ambience layers")
	for entry in layers:
		var path := "%s/%s.wav" % [AMBIENCE_DIR, str(entry)]
		assert_true(ResourceLoader.exists(path), "no ambience file at %s" % path)


## Every ambience layer must LOOP. A bed that plays once and stops leaves the
## region silent a few seconds after the player arrives, which looks exactly
## like the feature not working while every file is present and correct.
## The loop comes from a `smpl` chunk written by tools/audio/synth.py; this is
## what catches a regeneration that dropped it.
func test_every_ambience_layer_is_a_loop() -> void:
	var layers: Array = AUDIO.section("ambience").get("layers", [])
	for entry in layers:
		var path := "%s/%s.wav" % [AMBIENCE_DIR, str(entry)]
		if not ResourceLoader.exists(path):
			continue
		var stream := load(path) as AudioStreamWAV
		assert_true(stream != null, "%s did not load as an AudioStreamWAV" % path)
		if stream == null:
			continue
		assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD,
			"%s is not set to loop; the region will fall silent" % path)


func test_every_sfx_variant_has_a_file() -> void:
	var sfx := AUDIO.section("sfx")
	var dir := str(sfx.get("dir", ""))
	var variants: Dictionary = sfx.get("variants", {}) as Dictionary
	for name: String in variants.keys():
		var count := int(variants[name])
		for i in range(1, count + 1):
			var path := "%s/%s_%d.wav" % [dir, name, i]
			assert_true(ResourceLoader.exists(path), "no sfx variant at %s" % path)


## Every sound any wired call site can ask for, by the same resolution the game
## uses. A name whose file is missing is silence at a call site nobody is
## watching, which is the failure mode this whole lane exists to remove.
func test_every_named_sound_resolves() -> void:
	var wanted: Array[String] = [
		"pickup_item", "craft_done", "build_place_thud",
		"impact_weak", "impact_normal", "impact_super", "damage_taken",
		"attack_miss", "faint", "ability_cue", "orb_throw", "orb_shake",
		"catch_fail", "combat_start", "combat_win",
		"chop_wood", "mine_stone", "gather_plant",
	]
	for name in wanted:
		var path: String = AUDIO.sfx_path(name)
		assert_true(ResourceLoader.exists(path),
			"sound '%s' resolves to %s, which does not exist" % [name, path])


func test_footstep_surfaces_all_resolve() -> void:
	var surfaces: Dictionary = AUDIO.section("footsteps").get("surfaces", {}) as Dictionary
	assert_true(surfaces.size() > 0, "no footstep surfaces configured")
	for surface: String in surfaces.keys():
		var clips: Array = surfaces[surface]
		assert_true(clips.size() > 0, "surface '%s' has no clips" % surface)
		for clip in clips:
			var path := "%s/%s.wav" % [str(AUDIO.section("sfx").get("dir", "")), str(clip)]
			assert_true(ResourceLoader.exists(path), "no footstep file at %s" % path)


func test_every_creature_archetype_has_idle_and_alert() -> void:
	var creatures := AUDIO.section("creatures")
	var dir := str(creatures.get("dir", ""))
	var archetypes: Array = creatures.get("archetypes", [])
	assert_true(archetypes.size() > 0, "no creature voice archetypes configured")
	for entry in archetypes:
		for call_name in ["idle", "alert"]:
			var path := "%s/%s_%s.wav" % [dir, str(entry), call_name]
			assert_true(ResourceLoader.exists(path), "no creature voice at %s" % path)


## A species whose archetype is not one of the generated four would fall through
## to a file that does not exist and simply never make a sound.
func test_every_species_voice_uses_a_real_archetype() -> void:
	var creatures := AUDIO.section("creatures")
	var archetypes: Array = creatures.get("archetypes", [])
	var species: Dictionary = creatures.get("species", {}) as Dictionary
	for id: String in species.keys():
		var entry: Dictionary = species[id]
		assert_true(archetypes.has(str(entry.get("archetype", ""))),
			"species '%s' names archetype '%s', which is not generated"
				% [id, entry.get("archetype", "")])


func test_every_music_track_has_a_file() -> void:
	var music := AUDIO.section("music")
	var dir := str(music.get("dir", ""))
	var tracks: Dictionary = music.get("tracks", {}) as Dictionary
	assert_true(tracks.size() > 0, "no music tracks configured")
	for name: String in tracks.keys():
		var path := "%s/%s.wav" % [dir, str((tracks[name] as Dictionary).get("file", ""))]
		assert_true(ResourceLoader.exists(path), "no music file at %s for track '%s'" % [path, name])


# --- the config agrees with the rest of the game ------------------------------


## The mixer and the config must name the same buses. A bus in audio.json that
## the layout does not have routes to Master at the wrong level and silently
## ignores the player's slider for that category.
func test_every_configured_bus_exists_in_the_layout() -> void:
	var order: Array = AUDIO.section("buses").get("order", [])
	assert_true(order.size() > 0, "audio.json names no buses")
	for entry in order:
		assert_true(AudioServer.get_bus_index(str(entry)) >= 0,
			"audio.json names bus '%s' but default_bus_layout.tres has no such bus" % str(entry))


## Every band must have an ambience entry, or that region of the Meadows plays
## nothing at all -- and would do so silently, since a missing band is an empty
## gain table, not an error.
func test_every_band_has_ambience_for_day_and_night() -> void:
	var bands: Dictionary = AUDIO.section("ambience").get("bands", {}) as Dictionary
	for band in BAND_CONTENT.BANDS:
		assert_true(bands.has(band), "no ambience configured for band '%s'" % band)
		if not bands.has(band):
			continue
		var entry: Dictionary = bands[band]
		for when in ["day", "night"]:
			var table: Variant = entry.get(when, {})
			assert_true(typeof(table) == TYPE_DICTIONARY and not (table as Dictionary).is_empty(),
				"band '%s' has no %s ambience; that region is silent then" % [band, when])


## Every gain must name a layer that exists. A typo here is a layer that never
## plays, in one band, at one time of day -- about as quiet a bug as there is.
func test_band_ambience_only_names_real_layers() -> void:
	var ambience := AUDIO.section("ambience")
	var layers: Array = ambience.get("layers", [])
	var bands: Dictionary = ambience.get("bands", {}) as Dictionary
	for band: String in bands.keys():
		var entry: Dictionary = bands[band]
		for when in ["day", "night"]:
			var table: Variant = entry.get(when, {})
			if typeof(table) != TYPE_DICTIONARY:
				continue
			for layer: String in (table as Dictionary).keys():
				if layer.begins_with("_"):
					continue
				assert_true(layers.has(layer),
					"band '%s' %s names layer '%s', which does not exist" % [band, when, layer])


## The five bands must not all sound the same. This is the check that would
## catch a copy-paste that gave every region the same bed -- the specific
## failure MEADOWS_EXIT_CRITERION A5 ("different parts felt like distinct real
## places") cares about, applied to audio.
func test_bands_have_distinct_ambience() -> void:
	var bands: Dictionary = AUDIO.section("ambience").get("bands", {}) as Dictionary
	var seen: Array[String] = []
	for band: String in bands.keys():
		var day: Variant = (bands[band] as Dictionary).get("day", {})
		if typeof(day) != TYPE_DICTIONARY:
			continue
		var keys: Array = (day as Dictionary).keys()
		keys.sort()
		var signature := ",".join(keys)
		assert_false(seen.has(signature),
			"band '%s' has the same day layer set as an earlier band (%s)" % [band, signature])
		seen.append(signature)


func test_every_effectiveness_tier_maps_to_a_sound() -> void:
	var table: Dictionary = AUDIO.section("combat").get("effectiveness_sound", {}) as Dictionary
	# type_chart.gd::classify returns -1, 0 or 1.
	for tier in ["-1", "0", "1"]:
		assert_true(table.has(tier), "no impact sound for effectiveness tier %s" % tier)
		assert_true(ResourceLoader.exists(AUDIO.sfx_path(str(table[tier]))),
			"effectiveness tier %s names a sound with no file" % tier)


# --- the variant picker -------------------------------------------------------
#
# Pure, and separated from playback in audio_manager.gd precisely so it can be
# probed here with no scene tree -- the same split audio_cues.gd::should_play
# already uses for its rate limit.


func test_one_variant_always_returns_the_only_one() -> void:
	for i in 5:
		assert_eq(AUDIO.pick_variant("__test_single", 1), 1)


func test_variant_is_always_in_range() -> void:
	for i in 50:
		var choice: int = AUDIO.pick_variant("__test_range", 4)
		assert_true(choice >= 1 and choice <= 4, "variant %d is out of 1..4" % choice)


## The whole reason the generator writes four footsteps instead of one. A
## repeated identical sound is the most fatiguing thing a game can do, and
## nothing else in the suite would notice it regressing.
func test_variant_never_repeats_immediately() -> void:
	var last := 0
	for i in 60:
		var choice: int = AUDIO.pick_variant("__test_repeat", 3)
		assert_true(choice != last, "variant %d played twice running" % choice)
		last = choice


## With two variants the no-repeat rule forces a strict alternation, which is
## the tightest case and the one most likely to break if the fallback branch is
## ever rewritten.
func test_two_variants_alternate() -> void:
	var first: int = AUDIO.pick_variant("__test_two", 2)
	var second: int = AUDIO.pick_variant("__test_two", 2)
	assert_true(first != second, "two variants did not alternate")


# --- volume -------------------------------------------------------------------


## Full volume must land exactly on the authored default, so a fresh install and
## a slider dragged to the top are the same mix rather than nearly the same one.
func test_full_volume_is_the_authored_default() -> void:
	var defaults: Dictionary = AUDIO.section("buses").get("default_db", {}) as Dictionary
	for bus: String in defaults.keys():
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		AUDIO.set_bus_percent(bus, 1.0)
		assert_true(is_equal_approx(AudioServer.get_bus_volume_db(index), float(defaults[bus])),
			"%s at 100%% is %.2f dB, not its authored %.2f dB"
				% [bus, AudioServer.get_bus_volume_db(index), float(defaults[bus])])


## Zero mutes rather than leaving the bus at the floor dB, where a quiet room
## still hears it.
func test_zero_volume_mutes() -> void:
	var index := AudioServer.get_bus_index("Music")
	if index < 0:
		return
	AUDIO.set_bus_percent("Music", 0.0)
	assert_true(AudioServer.is_bus_mute(index), "a bus at 0%% was not muted")
	AUDIO.set_bus_percent("Music", 1.0)
	assert_false(AudioServer.is_bus_mute(index), "raising a bus off 0%% did not unmute it")


func test_volume_is_clamped() -> void:
	AUDIO.set_bus_percent("SFX", 5.0)
	assert_true(is_equal_approx(AUDIO.bus_percent("SFX"), 1.0), "volume above 1.0 was not clamped")
	AUDIO.set_bus_percent("SFX", -3.0)
	assert_true(is_equal_approx(AUDIO.bus_percent("SFX"), 0.0), "volume below 0.0 was not clamped")
	AUDIO.set_bus_percent("SFX", 1.0)


## Volumes round-trip through the same object that owns user://settings.json,
## which is how they survive a restart. Uses a plain in-memory KeyBindings so
## nothing here touches the real settings file.
func test_volumes_round_trip_through_the_settings_object() -> void:
	var prefs: RefCounted = preload("res://scripts/ui/key_bindings.gd").new("user://__test_audio.json")
	AUDIO.set_bus_percent("Ambience", 0.4)
	AUDIO.store_volumes(prefs)
	assert_true(prefs.get("audio").has("Ambience"), "volumes were not written to the settings object")

	AUDIO.set_bus_percent("Ambience", 1.0)
	AUDIO.load_volumes(prefs)
	assert_true(is_equal_approx(AUDIO.bus_percent("Ambience"), 0.4),
		"volume did not come back off the settings object")
	AUDIO.set_bus_percent("Ambience", 1.0)
