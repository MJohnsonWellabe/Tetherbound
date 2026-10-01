extends RefCounted
class_name AudioManager

## The game's one audio entry point: buses, volumes, and every one-shot sound.
##
## `RefCounted` with `static` state, NOT an autoload. D14 says the project has
## one autoload and means to keep it, and `scripts/ui/audio_cues.gd` already
## established the shape this follows: a bag of statics plus a lazily-created
## node under the tree root, reached from wherever a caller already is. The
## continuous, per-frame side of audio -- ambience beds, music, footsteps --
## needs a real Node and lives in `scripts/audio/world_audio.gd`, which sits in
## the world scene beside `WorldLook` and `WorldWeather` for the same reason
## those do.
##
## ## What this owns
##
## - The bus volume the player chose, and writing it through to `AudioServer`.
## - A pool of `AudioStreamPlayer` / `AudioStreamPlayer3D` for one-shots.
## - Variant selection, so a footstep is not the same footstep every time.
## - The stream cache, so a sound is loaded once per run.
##
## ## Headless is a real caller
##
## Every `smoke_*.gd` and `tests/run_tests.gd` boots the real world with no
## display and no audio device. `audio_cues.gd` handles this by returning early
## on `DisplayServer.get_name() == "headless"`, and callers therefore need no
## guard of their own -- but that also means NOTHING about audio is observable
## in the place this project proves things, which is exactly how a lane like
## this ships a soundscape that does not play.
##
## So this does it differently: headless still runs the whole path -- pool,
## variant pick, bus routing, `play()` on a real player node -- and only the
## final audio device is absent, which Godot's dummy driver handles silently.
## Every call is additionally recorded in `_log` when `logging_enabled` is set,
## so `tests/smoke_audio.gd` can drive the real game and assert on what actually
## reached the mixer. See `recent()`.

const CONFIG_PATH := "res://data/config/audio.json"

## Bus indices are resolved by name once and cached. A name that is not in
## `default_bus_layout.tres` returns -1 from AudioServer and would silently
## route to Master, so `_bus_index` push_error()s rather than letting a typo in
## audio.json become an inaudible mystery.
static var _bus_cache: Dictionary = {}

static var _config: Dictionary = {}
static var _config_loaded: bool = false

## name -> AudioStream. Shared with world_audio.gd through `stream()`.
static var _streams: Dictionary = {}

## Base sound name -> the variant index played last, so `pick_variant` can
## refuse to play it twice running. This is the single cheapest thing that makes
## a four-variant footstep set sound like more than four footsteps.
static var _last_variant: Dictionary = {}

static var _pool: Array[AudioStreamPlayer] = []
static var _pool_3d: Array[AudioStreamPlayer3D] = []
static var _pool_root: Node = null
static var _next_pool: int = 0
static var _next_pool_3d: int = 0

## Player volume per bus, 0.0..1.0, where 1.0 is the authored default in
## `default_bus_layout.tres`. Absent means 1.0; see `set_bus_percent`.
static var _volumes: Dictionary = {}

## Set by tests. See the class header -- this is how audio becomes observable in
## a headless smoke run without any caller knowing a test exists.
static var logging_enabled: bool = false
static var _log: Array[Dictionary] = []
static var _log_cap: int = 400


# --- config ------------------------------------------------------------------


static func config() -> Dictionary:
	if not _config_loaded:
		_config_loaded = true
		var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file == null:
			push_error("audio.json missing; the game will be silent")
			_config = {}
		else:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			_config = parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}
			if _config.is_empty():
				push_error("audio.json is not a JSON object; the game will be silent")
	return _config


static func section(name: String) -> Dictionary:
	var found: Variant = config().get(name, {})
	return found as Dictionary if typeof(found) == TYPE_DICTIONARY else {}


# --- buses and volume --------------------------------------------------------


static func bus_index(name: String) -> int:
	if _bus_cache.has(name):
		return int(_bus_cache[name])
	var index := AudioServer.get_bus_index(name)
	if index < 0:
		# Routing to Master would be inaudibly wrong rather than obviously
		# wrong: the sound plays, at the wrong level, ignoring the player's
		# slider for the category it belongs to.
		push_error("no audio bus called '%s'; check default_bus_layout.tres" % name)
	_bus_cache[name] = index
	return index


## The player's volume for a bus as a 0..1 fraction of the authored mix.
static func bus_percent(name: String) -> float:
	return float(_volumes.get(name, 1.0))


## Set a bus's player volume and write it through to the mixer immediately.
##
## The mapping is deliberately NOT linear in dB. A slider that runs -32..0 dB
## linearly spends its top half in changes the ear barely registers and its
## bottom half going silent. Fraction^2 scaled into the dB range tracks
## perceived loudness far better, and 0 mutes outright rather than leaving a bus
## at -32 dB where a quiet room still hears it.
static func set_bus_percent(name: String, fraction: float) -> void:
	var clamped := clampf(fraction, 0.0, 1.0)
	_volumes[name] = clamped
	var index := bus_index(name)
	if index < 0:
		return
	if clamped <= 0.0:
		AudioServer.set_bus_mute(index, true)
		return
	AudioServer.set_bus_mute(index, false)
	AudioServer.set_bus_volume_db(index, _db_for(name, clamped))


static func _db_for(name: String, fraction: float) -> float:
	var buses := section("buses")
	var defaults: Dictionary = buses.get("default_db", {}) as Dictionary
	var top := float(defaults.get(name, 0.0))
	var floor_db := float(buses.get("min_db", -32.0))
	# fraction == 1 lands exactly on the authored default, so a fresh install
	# and a slider dragged to full are the same mix, not nearly the same one.
	return floor_db + (top - floor_db) * (clamped_square(fraction))


static func clamped_square(fraction: float) -> float:
	var f := clampf(fraction, 0.0, 1.0)
	return f * f


## Push every stored volume into the mixer. Called once at world start, and
## after loading preferences, so the buses match the player's settings before
## the first sound plays rather than one frame after it.
static func apply_all_volumes() -> void:
	var buses := section("buses")
	var order: Variant = buses.get("order", [])
	if typeof(order) != TYPE_ARRAY:
		return
	for entry: Variant in order as Array:
		var name := str(entry)
		set_bus_percent(name, bus_percent(name))


## Read the player's volumes out of the settings file's `audio` section.
##
## `scripts/ui/key_bindings.gd` is the only writer of `user://settings.json`
## (D15), and its `save()` payload comment already anticipated this section
## existing. `prefs` is that object; passing it in rather than reaching for the
## menu keeps this testable with a plain dictionary.
static func load_volumes(prefs: RefCounted) -> void:
	if prefs == null:
		return
	var stored: Variant = prefs.get("audio")
	if typeof(stored) != TYPE_DICTIONARY:
		return
	for key: Variant in (stored as Dictionary).keys():
		_volumes[str(key)] = clampf(float((stored as Dictionary)[key]), 0.0, 1.0)
	apply_all_volumes()


## Write the player's volumes back into `prefs.audio`. The caller saves.
static func store_volumes(prefs: RefCounted) -> void:
	if prefs == null:
		return
	prefs.set("audio", _volumes.duplicate())


# --- streams -----------------------------------------------------------------


## Load and cache a stream by full res:// path. Returns null and complains once
## for a missing file rather than per call site.
static func stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	if not ResourceLoader.exists(path):
		push_error("audio: no file at %s" % path)
		_streams[path] = null
		return null
	var loaded: AudioStream = load(path)
	_streams[path] = loaded
	return loaded


## Resolve a logical sfx name to a concrete file, choosing between variants.
##
## `impact_normal` with three variants on disk becomes one of
## `impact_normal_1..3`, never the same one twice running. With one variant the
## name is used unchanged, so a caller never has to know which sounds have sets.
static func sfx_path(name: String) -> String:
	var sfx := section("sfx")
	var dir := str(sfx.get("dir", "res://assets/audio/sfx"))
	var variants: Dictionary = sfx.get("variants", {}) as Dictionary
	var count := int(variants.get(name, 1))
	if count <= 1:
		return "%s/%s.wav" % [dir, name]
	return "%s/%s_%d.wav" % [dir, name, pick_variant(name, count)]


## Which variant to play next for `name`, out of `count`.
##
## Pure and separated from playback specifically so `tests/test_audio_manager.gd`
## can prove the no-immediate-repeat property without a scene tree -- the same
## split `audio_cues.gd::should_play` uses for its rate limit.
static func pick_variant(name: String, count: int) -> int:
	if count <= 1:
		return 1
	var last := int(_last_variant.get(name, 0))
	var choice := randi_range(1, count)
	if choice == last:
		# One deterministic step rather than a resample loop: resampling can in
		# principle spin, and with count >= 2 this always lands somewhere else.
		choice = 1 + (choice % count)
	_last_variant[name] = choice
	return choice


# --- playback ----------------------------------------------------------------


## Play a one-shot on a bus, non-positionally. Used for anything the player
## should hear at a constant level wherever they are: their own footsteps, UI,
## the cue that their creature just fainted.
##
## Returns the player node used, or null if nothing could play. Callers are not
## expected to check -- every failure here is silence, never an error, the same
## contract `audio_cues.gd` set.
static func play(name: String, bus: String = "SFX", volume_db: float = 0.0,
		pitch: float = 1.0) -> AudioStreamPlayer:
	return play_file(sfx_path(name), name, bus, volume_db, pitch)


## Play a one-shot by explicit res:// path.
##
## `play()` above resolves a logical name against the sfx directory and its
## variant table; anything living elsewhere -- a creature voice under
## `assets/audio/creatures/` -- has already done its own resolution and needs to
## hand over a path rather than a name that would be looked up in the wrong
## folder. `label` is what the sound is called for logging, so a smoke test sees
## "chirp_alert" rather than a path.
static func play_file(path: String, label: String, bus: String = "SFX",
		volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	var found := stream(path)
	if found == null:
		return null
	_record(label, bus, path, pitch, volume_db, Vector3.ZERO, false)
	var player := _take_pool()
	if player == null:
		return null
	player.stream = found
	player.bus = bus
	player.volume_db = volume_db
	player.pitch_scale = maxf(0.01, pitch)
	player.play()
	return player


## Play a one-shot AT a world position, with distance falloff.
##
## Everything that happens to something other than the player goes through here:
## an impact on a creature twenty metres away must be quieter than one at the
## player's feet, and in a real-time piloted fight (D07) that difference is
## information, not polish.
static func play_at(name: String, where: Vector3, bus: String = "SFX",
		volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer3D:
	return play_file_at(sfx_path(name), name, where, bus, volume_db, pitch)


## Positional twin of `play_file`. See that function on why a path form exists.
static func play_file_at(path: String, label: String, where: Vector3,
		bus: String = "SFX", volume_db: float = 0.0,
		pitch: float = 1.0) -> AudioStreamPlayer3D:
	var found := stream(path)
	if found == null:
		return null
	_record(label, bus, path, pitch, volume_db, where, true)
	var player := _take_pool_3d()
	if player == null:
		return null
	player.stream = found
	player.bus = bus
	player.volume_db = volume_db
	player.pitch_scale = maxf(0.01, pitch)
	player.global_position = where
	player.play()
	return player


## The pool root, created lazily under the tree root.
##
## Under `root` rather than under the world scene on purpose: a sound that is
## mid-play when the world is freed (a scene change, a smoke test tearing down)
## would otherwise be freed with it, which is both a click and, historically in
## this engine, a crash risk. The pool outlives any one world.
static func _root() -> Node:
	if _pool_root != null and is_instance_valid(_pool_root):
		return _pool_root
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var holder := Node.new()
	holder.name = "AudioPool"
	tree.root.add_child(holder)
	_pool_root = holder
	return holder


static func _pool_size() -> int:
	return maxi(4, int(section("sfx").get("pool_size", 16)))


## Round-robin over a fixed pool.
##
## Round-robin, not "find a free one": a fixed pool with a moving cursor has a
## bounded worst case (the oldest sound is cut off) where searching for a free
## player has an unbounded one (a busy moment plays nothing at all, silently).
## Cutting off the oldest of sixteen overlapping sounds is inaudible; dropping
## the newest is exactly the sound the player was waiting for.
static func _take_pool() -> AudioStreamPlayer:
	var holder := _root()
	if holder == null:
		return null
	var size := _pool_size()
	while _pool.size() < size:
		var made := AudioStreamPlayer.new()
		made.name = "OneShot%d" % _pool.size()
		holder.add_child(made)
		_pool.append(made)
	var player := _pool[_next_pool % _pool.size()]
	_next_pool = (_next_pool + 1) % _pool.size()
	return player


static func _take_pool_3d() -> AudioStreamPlayer3D:
	var holder := _root()
	if holder == null:
		return null
	var size := _pool_size()
	var max_distance := float(section("sfx").get("max_distance_metres", 40.0))
	while _pool_3d.size() < size:
		var made := AudioStreamPlayer3D.new()
		made.name = "OneShot3D%d" % _pool_3d.size()
		made.max_distance = max_distance
		# Inverse falloff rather than Godot's default: the default keeps distant
		# sources audible far longer than a dense meadow full of creatures can
		# afford, and the mix turns to mud with a dozen of them.
		made.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		holder.add_child(made)
		_pool_3d.append(made)
	var player := _pool_3d[_next_pool_3d % _pool_3d.size()]
	_next_pool_3d = (_next_pool_3d + 1) % _pool_3d.size()
	return player


# --- observability -----------------------------------------------------------
#
# See the class header. This exists so a headless smoke test can assert that the
# SHIPPING GAME played a sound, rather than that a file exists on disk -- the
# repo's evidence rule, applied to a medium CI cannot listen to.


static func _record(name: String, bus: String, path: String, pitch: float,
		volume_db: float, where: Vector3, positional: bool) -> void:
	if not logging_enabled:
		return
	_log.append({
		"name": name,
		"bus": bus,
		"path": path,
		"pitch": pitch,
		"volume_db": volume_db,
		"position": where,
		"positional": positional,
		"msec": Time.get_ticks_msec(),
	})
	if _log.size() > _log_cap:
		_log = _log.slice(_log.size() - _log_cap)


## Everything played since the log was last cleared, oldest first.
static func recent() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in _log:
		out.append(entry as Dictionary)
	return out


## Distinct sound names played since the log was last cleared.
static func recent_names() -> Array[String]:
	var seen: Array[String] = []
	for entry in _log:
		var name := str((entry as Dictionary).get("name", ""))
		if not seen.has(name):
			seen.append(name)
	return seen


static func clear_log() -> void:
	_log.clear()


## Reset every piece of static state. Only tests call this; a run of the game
## has exactly one of each of these for its whole life.
static func reset_for_test() -> void:
	_bus_cache.clear()
	_streams.clear()
	_last_variant.clear()
	_volumes.clear()
	_log.clear()
	_config.clear()
	_config_loaded = false
