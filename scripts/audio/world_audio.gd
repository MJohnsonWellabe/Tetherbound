extends Node

## The continuous half of the game's audio: ambience beds, footsteps, music, and
## everything that answers a combat signal.
##
## Sits in `meadows_playground.tscn` beside `WorldLook` and `WorldWeather`, and
## is the same kind of thing they are: a node that reads a config file and
## applies it to a world it does not own. `scripts/audio/audio_manager.gd` holds
## the static side (buses, pools, volumes); this holds everything that needs a
## frame.
##
## ## It subscribes; it does not intrude
##
## Not one line of `combat_manager.gd`, `player_controller.gd` or the harvest
## code was changed to make this work. Combat already emitted `hit_landed`,
## `attack_missed`, `catch_resolved`, `orb_shook`, `entered` and `exited`; the
## player already emitted `landed`; footsteps are derived from distance
## travelled. Audio is a LISTENER on the game, which is what keeps a silent
## build and a loud one the same game -- and means deleting this node degrades
## the project to exactly where it was before this lane, with nothing else
## broken.
##
## ## Ambience is layers, not beds
##
## Eight looping layers play continuously; what changes per region and per time
## of day is their GAIN. See `tools/audio/gen_ambience.py` for why, and
## `data/config/audio.json`'s `ambience.bands` for the table. A layer whose
## target gain is zero is stopped outright, so a band pays no CPU for the
## layers it does not use.

const CONFIG := preload("res://scripts/audio/audio_manager.gd")
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"

## Node names this looks for in the world. Resolved once in `_ready`; a missing
## one disables only the feature that needs it, never the whole node -- a smoke
## test that boots a partial world should lose footsteps, not ambience.
const PLAYER_NAME := ^"Player"
const WORLD_LOOK_NAME := ^"WorldLook"
const COMBAT_NAME := ^"CombatManager"
const WATER_NAME := ^"Water"

var _player: CharacterBody3D = null
var _look: Node = null
var _combat: Node = null
var _water: Node = null

## layer name -> AudioStreamPlayer. Created once, in `_ready`.
var _layers: Dictionary = {}
## layer name -> the gain it is moving toward, 0..1.
var _layer_target: Dictionary = {}
## layer name -> the gain it is at now. Separate from the target so a band
## change mid-fade continues from where the fade had reached rather than
## snapping and starting again.
var _layer_gain: Dictionary = {}

var _band: String = ""
var _dark: bool = false
## Whether the player was indoors as of the last mix update. Tracked as state
## like `_band`/`_dark` so a door counts as a transition and fades, rather than
## being re-read only when something else happens to change.
var _indoors_now: bool = false
## How long the transition currently in flight should take. Held rather than
## recomputed per frame so a day/night fade that is interrupted by a band change
## keeps the slower rate it started with instead of speeding up mid-fade.
var _fade_seconds: float = 6.0

## Metres travelled since the last footstep. See `_tick_footsteps`.
var _stride: float = 0.0
var _last_step_msec: int = 0
var _last_position: Vector3 = Vector3.ZERO
var _have_last_position: bool = false

## Band z-boundaries, ascending, read from terrain_playground.json's trail.
## See `_load_band_bounds` for why they are derived rather than restated.
var _band_bounds: Array[float] = []
var _band_ids: Array[String] = []

var _music: AudioStreamPlayer = null
var _music_track: String = ""
var _music_wanted: String = ""
var _music_fade: float = 0.0
## Seconds until the exploration bed next turns on or off. See the config's
## `_comment_silence`: exploration music is deliberately intermittent.
var _music_gap_left: float = 0.0
var _music_playing_stretch: bool = false
## Village centre, resolved once in `_ready`. NaN when it could not be found.
var _village_at: Vector2 = Vector2(NAN, NAN)

var _in_combat: bool = false


func _ready() -> void:
	var world := get_parent()
	if world != null:
		_player = world.get_node_or_null(PLAYER_NAME) as CharacterBody3D
		_look = world.get_node_or_null(WORLD_LOOK_NAME)
		_combat = world.get_node_or_null(COMBAT_NAME)
		_water = world.get_node_or_null(WATER_NAME)

	CONFIG.apply_all_volumes()
	# `landed` is a signal player_controller.gd already emitted; a landing is a
	# footstep with more weight behind it, so it reuses the surface sets rather
	# than needing a sound of its own.
	if _player != null and _player.has_signal("landed"):
		_player.connect("landed", _on_player_landed)
	_village_at = _find_village()
	_load_band_bounds()
	_build_ambience()
	_build_music()
	_connect_combat()

	# Seed the mix from wherever the player actually starts, so the opening does
	# not fade up from silence over six seconds while the player is already
	# standing in a meadow.
	_dark = _is_dark()
	_indoors_now = _indoors()
	_band = _band_for(_player_z())
	_retarget_ambience()
	for name: String in _layer_target.keys():
		_layer_gain[name] = float(_layer_target[name])
	_apply_layer_gains()


func _process(delta: float) -> void:
	_tick_ambience(delta)
	_tick_footsteps(delta)
	_tick_music(delta)
	_tick_creature_voices(delta)


# --- creature voices ---------------------------------------------------------
#
# Four archetypes cover the whole roster; a species picks one and a pitch. See
# tools/audio/gen_creatures.py's header for why that is enough to tell twenty
# creatures apart, and audio.json's `creatures.species` for the table.


## Seconds until the next idle call from anything. One timer for the WHOLE
## world, not one per creature: creatures near the player are picked at random
## when it fires, so a herd of six does not vocalise six times as often as a
## lone one. That is the difference between a living meadow and a farmyard.
var _idle_left: float = 0.0
## Creature node -> the tick it last made an alert sound, so a creature that
## re-notices the player every frame does not machine-gun.
var _alert_msec: Dictionary = {}
## Bodies whose `wants_to_engage` this has already connected to.
var _voiced: Array = []


func _tick_creature_voices(delta: float) -> void:
	var config := CONFIG.section("creatures")
	_connect_new_creatures(config)

	_idle_left -= delta
	if _idle_left > 0.0:
		return
	_idle_left = _roll(config.get("idle_interval_seconds", [9.0, 22.0]))

	var candidates := _creatures_near(float(config.get("idle_max_distance_metres", 30.0)))
	if candidates.is_empty():
		return
	_say(candidates[randi() % candidates.size()], "idle", config)


## Subscribe to `wants_to_engage` on any wild creature not already hooked up.
##
## Polled rather than done once at `_ready`, because creatures spawn and despawn
## continuously as the player moves through the corridor -- there is no single
## moment when "every creature" exists to connect to.
func _connect_new_creatures(config: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group(&"creature_voice"):
		if _voiced.has(node):
			continue
		_voiced.append(node)
		if node.has_signal("wants_to_engage"):
			node.connect("wants_to_engage", _on_creature_alert.bind(node))
	# Freed creatures would otherwise accumulate here for the whole run.
	_voiced = _voiced.filter(func(n: Variant) -> bool: return is_instance_valid(n))


func _on_creature_alert(who: Node) -> void:
	var config := CONFIG.section("creatures")
	var now := Time.get_ticks_msec()
	var gap := int(float(config.get("alert_cooldown_seconds", 2.5)) * 1000.0)
	if now - int(_alert_msec.get(who.get_instance_id(), -gap)) < gap:
		return
	_alert_msec[who.get_instance_id()] = now
	_say(who, "alert", config)


## Play one call from one creature, at its position and in its own voice.
func _say(who: Node, call_name: String, config: Dictionary) -> void:
	if not is_instance_valid(who) or not (who is Node3D):
		return
	var species := str(who.get("species_id"))
	var table: Dictionary = config.get("species", {}) as Dictionary
	var entry: Dictionary = table.get(species, config.get("default", {})) as Dictionary
	var archetype := str(entry.get("archetype", "chirp"))
	var pitch := float(entry.get("pitch", 1.0))
	var jitter := float(config.get("pitch_jitter", 0.05))

	# By PATH, not by name: creature voices live in their own directory, and the
	# name form would resolve them against the sfx folder's variant table.
	var path := "%s/%s_%s.wav" % [str(config.get("dir", "")), archetype, call_name]
	# Positional: a creature calling from the tree line must sound like it is at
	# the tree line, which is most of what makes the meadow feel occupied.
	CONFIG.play_file_at(
		path,
		"%s_%s" % [archetype, call_name],
		(who as Node3D).global_position,
		"Creatures",
		0.0,
		pitch * randf_range(1.0 - jitter, 1.0 + jitter)
	)


func _creatures_near(radius: float) -> Array:
	if _player == null:
		return []
	var here := _player.global_position
	var out: Array = []
	for node in get_tree().get_nodes_in_group(&"creature_voice"):
		if not (node is Node3D) or not (node as Node3D).visible:
			continue
		if (node as Node3D).global_position.distance_to(here) <= radius:
			out.append(node)
	return out


# --- ambience ----------------------------------------------------------------


func _build_ambience() -> void:
	var ambience := CONFIG.section("ambience")
	var dir := str(ambience.get("dir", "res://assets/audio/ambience"))
	var names: Variant = ambience.get("layers", [])
	if typeof(names) != TYPE_ARRAY:
		return
	for entry: Variant in names as Array:
		var name := str(entry)
		var stream := CONFIG.stream("%s/%s.wav" % [dir, name])
		if stream == null:
			continue
		var player := AudioStreamPlayer.new()
		player.name = "Ambience_%s" % name
		player.stream = stream
		player.bus = "Ambience"
		# Starts silent and stopped; `_apply_layer_gains` decides what plays.
		player.volume_db = -80.0
		add_child(player)
		_layers[name] = player
		_layer_gain[name] = 0.0
		_layer_target[name] = 0.0


## Recompute every layer's target gain from the current band and time of day.
func _retarget_ambience() -> void:
	var ambience := CONFIG.section("ambience")
	var bands: Dictionary = ambience.get("bands", {}) as Dictionary
	var band: Dictionary = bands.get(_band, {}) as Dictionary
	var table: Dictionary = band.get("night" if _dark else "day", {}) as Dictionary

	var interior := float(ambience.get("interior_gain", 0.25)) if _indoors_now else 1.0
	for name: String in _layers.keys():
		_layer_target[name] = float(table.get(name, 0.0)) * interior


func _tick_ambience(delta: float) -> void:
	var band := _band_for(_player_z())
	var dark := _is_dark()
	# Indoors is a third input to the mix, and it changes far more often than
	# the other two -- a player walks in and out of the farmhouse repeatedly in
	# the opening alone. Folding it in here rather than reading it only inside
	# `_retarget_ambience` is what makes stepping through a door actually duck
	# the outside world; without it the duck would not apply until the next band
	# or day/night change, which could be an hour away.
	var indoors := _indoors()
	# Captured BEFORE `_dark` is updated: the fade rate depends on which kind of
	# transition started, and reading it back after the assignment would always
	# say "no day/night change" and use the fast rate for both.
	var daynight_changed := dark != _dark
	if band != _band or daynight_changed or indoors != _indoors_now:
		_band = band
		_dark = dark
		_indoors_now = indoors
		_retarget_ambience()
		_fade_seconds = _rate_for(daynight_changed)

	var step := delta / maxf(_fade_seconds, 0.01)

	var moved := false
	for name: String in _layers.keys():
		var current := float(_layer_gain.get(name, 0.0))
		var target := float(_layer_target.get(name, 0.0))
		if is_equal_approx(current, target):
			continue
		_layer_gain[name] = move_toward(current, target, step)
		moved = true
	if moved:
		_apply_layer_gains()


## Seconds for the transition now starting. A day/night change is slower than a
## band change; when both happen at once (walking into Band 3 at dusk) the
## slower of the two wins, so the mix never lurches because one of two
## simultaneous reasons for it happened to be quick.
func _rate_for(daynight_changed: bool) -> float:
	var ambience := CONFIG.section("ambience")
	var band_rate := float(ambience.get("band_fade_seconds", 6.0))
	if not daynight_changed:
		return band_rate
	return maxf(band_rate, float(ambience.get("daynight_fade_seconds", 12.0)))


## Write the current gains to the players, starting and stopping as needed.
##
## The gain is applied as a dB offset on a player whose bus already carries the
## authored level: `linear_to_db` of the 0..1 gain. A gain of 0 stops the player
## rather than leaving it running at -80 dB, because eight looping streams
## decoding continuously for a band that uses three of them is a real cost on a
## handheld and buys nothing.
func _apply_layer_gains() -> void:
	for name: String in _layers.keys():
		var player: AudioStreamPlayer = _layers[name]
		var gain := float(_layer_gain.get(name, 0.0))
		if gain <= 0.001:
			if player.playing:
				player.stop()
			continue
		player.volume_db = linear_to_db(gain)
		if not player.playing:
			player.play()


# --- footsteps ---------------------------------------------------------------


## A step every `stride_metres` of ground travelled.
##
## Distance-based rather than animation-driven: the trainer rig's walk cycle is
## not frame-tagged, and deriving the step from distance keeps it in time with
## sprinting, slopes and any future change to `movement.json`'s speeds without a
## second source of truth to drift. The cost is that a step lands on distance
## rather than exactly on a foot plant, which at these speeds is within a frame
## or two and inaudible.
func _tick_footsteps(_delta: float) -> void:
	if _player == null:
		return
	var here := _player.global_position
	if not _have_last_position:
		_last_position = here
		_have_last_position = true
		return

	var moved := Vector2(here.x - _last_position.x, here.z - _last_position.z).length()
	_last_position = here

	if not _player.is_on_floor():
		# Airborne travel does not accumulate stride, and the stride resets, so
		# landing after a jump does not immediately fire a step on top of the
		# landing sound.
		_stride = 0.0
		return

	var config := CONFIG.section("footsteps")
	var sprinting := bool(_player.get("_sprinting"))
	var stride := float(config.get("stride_metres", 1.85))
	if sprinting:
		stride *= float(config.get("sprint_stride_scale", 0.78))

	_stride += moved
	if _stride < stride:
		return
	_stride = 0.0

	# A hard floor on the interval as well as on distance. Anything that
	# teleports or is shoved (debug teleport, an unstick, a knockback) covers
	# metres in one frame, and without this that arrives as a machine-gun burst.
	var now := Time.get_ticks_msec()
	var min_gap := int(float(config.get("min_interval_seconds", 0.18)) * 1000.0)
	if now - _last_step_msec < min_gap:
		return
	_last_step_msec = now

	_play_step(config, sprinting, 0.0)


## Touching down after a fall. Louder than a step, on the same surface set, and
## it resets the stride so the next ordinary step is a full stride away rather
## than landing on top of this one.
func _on_player_landed(_impact_speed: float, _damage: float) -> void:
	var config := CONFIG.section("footsteps")
	_stride = 0.0
	_last_step_msec = Time.get_ticks_msec()
	_play_step(config, false, float(config.get("land_gain_db", 4.0)))


func _play_step(config: Dictionary, sprinting: bool, extra_db: float) -> void:
	var surfaces: Dictionary = config.get("surfaces", {}) as Dictionary
	var set_name := _surface_for(config)
	var clips: Variant = surfaces.get(set_name, [])
	if typeof(clips) != TYPE_ARRAY or (clips as Array).is_empty():
		return
	# The variant sets are named `step_grass_1..4` on disk; AudioManager resolves
	# a base name to one of them, so the base is what this passes.
	var base := str((clips as Array)[0]).rsplit("_", true, 1)[0]

	var jitter := float(config.get("pitch_jitter", 0.07))
	var db := extra_db
	if sprinting:
		db += float(config.get("sprint_gain_db", 2.0))
	CONFIG.play(base, "SFX", db, randf_range(1.0 - jitter, 1.0 + jitter))


## Which surface set the player is standing on.
##
## Resolution order is water, then the structure under them, then the band's
## default. This is COARSE and the config says so: Terrain3D carries no
## per-texture material id here, so "band 2 is stone" is the honest resolution
## available without a terrain change this lane has no business making.
func _surface_for(config: Dictionary) -> String:
	if _in_water(config):
		return "water"
	var structure := _structure_surface(config)
	if not structure.is_empty():
		return structure
	var by_band: Dictionary = config.get("band_surface", {}) as Dictionary
	return str(by_band.get(_band, config.get("default_surface", "grass")))


func _in_water(config: Dictionary) -> bool:
	if _player == null or _water == null:
		return false
	if not _water.has_method("water_level"):
		return false
	var level := float(_water.call("water_level"))
	if is_nan(level):
		return false
	var feet := _player.global_position.y
	var depth := level - feet
	# Below the surface but not deep: standing IN water. Deeper than this and
	# water.gd's own submersion hazard has taken over and footsteps are not the
	# sound that matters.
	return depth > 0.0 and depth < float(config.get("water_depth_metres", 1.2))


## Match the name of the body the player is standing on against the configured
## substrings. `get_last_slide_collision` is what `move_and_slide` already
## recorded this frame -- no raycast, per D09, and no extra physics query.
func _structure_surface(config: Dictionary) -> String:
	if _player == null:
		return ""
	var slide := _player.get_last_slide_collision()
	if slide == null:
		return ""
	var collider := slide.get_collider()
	if collider == null or not (collider is Node):
		return ""
	# The collider is usually a StaticBody3D whose PARENT carries the meaningful
	# name (a built floor's body is called "StaticBody3D"), so both are checked.
	var names := [(collider as Node).name]
	var parent := (collider as Node).get_parent()
	if parent != null:
		names.append(parent.name)

	var table: Dictionary = config.get("structure_surface", {}) as Dictionary
	for surface: String in table.keys():
		var needles: Variant = table[surface]
		if typeof(needles) != TYPE_ARRAY:
			continue
		for needle: Variant in needles as Array:
			for name: Variant in names:
				if str(name).findn(str(needle)) >= 0:
					return surface
	return ""


func _indoors() -> bool:
	# The same structure test the footsteps use: if the player is standing on a
	# built or interior floor, the outside world is muffled. Cheap and wrong at
	# the edges (a wooden bridge is not indoors), which is why `interior_gain`
	# is a duck rather than a cut -- being wrong costs a little colour, not the
	# whole soundscape.
	return _structure_surface(CONFIG.section("footsteps")) == "wood"


# --- combat ------------------------------------------------------------------
#
# Every one of these is a signal `combat_manager.gd` ALREADY emitted. Nothing in
# combat was changed; see this class's header.


func _connect_combat() -> void:
	if _combat == null:
		return
	_combat.connect("entered", _on_combat_entered)
	_combat.connect("exited", _on_combat_exited)
	_combat.connect("hit_effectiveness", _on_hit_effectiveness)
	_combat.connect("hit_landed", _on_hit_landed)
	_combat.connect("attack_missed", _on_attack_missed)
	_combat.connect("orb_shook", _on_orb_shook)
	_combat.connect("catch_resolved", _on_catch_resolved)


func _on_combat_entered() -> void:
	_in_combat = true
	CONFIG.play("combat_start", "SFX")


func _on_combat_exited(outcome: String) -> void:
	_in_combat = false
	# "fled" and "lost" are not victories and must not sound like one. Anything
	# that is not a win simply gets no cue; the music change is the feedback.
	if outcome == "won" or outcome == "caught":
		CONFIG.play("combat_win", "SFX")


## The effectiveness tier decides WHICH impact plays; `hit_landed` right after
## it decides where. Both signals fire for the same hit, in this order, so this
## records the tier and lets the position-carrying one actually play it.
var _pending_effectiveness: int = 0
var _pending_on_enemy: bool = true


func _on_hit_effectiveness(on_enemy: bool, effectiveness: int) -> void:
	_pending_effectiveness = effectiveness
	_pending_on_enemy = on_enemy


func _on_hit_landed(on_enemy: bool, _amount: float) -> void:
	if not on_enemy:
		# The player's own creature took it. A different sound entirely -- in a
		# real-time piloted fight the mix's first job is to say who was hit.
		CONFIG.play("damage_taken", "SFX")
		return
	var table: Dictionary = CONFIG.section("combat").get("effectiveness_sound", {}) as Dictionary
	var key := str(_pending_effectiveness) if _pending_on_enemy == on_enemy else "0"
	CONFIG.play(str(table.get(key, "impact_normal")), "SFX")


func _on_attack_missed(_by_player: bool) -> void:
	CONFIG.play("attack_miss", "SFX")


func _on_orb_shook(index: int) -> void:
	var step := float(CONFIG.section("combat").get("orb_shake_pitch_step", 1.06))
	# Each shake a semitone up. Three rising clicks is a question the player is
	# waiting on the answer to; three identical ones is a stutter.
	CONFIG.play("orb_shake", "SFX", 0.0, pow(step, float(maxi(index, 0))))


func _on_catch_resolved(success: bool, _shakes: int) -> void:
	if success:
		# The existing UI cue already covers the success moment on the UI bus
		# (`audio_cues.gd`'s `capture_success`); this lane does not double it.
		return
	CONFIG.play("catch_fail", "SFX")


# --- music -------------------------------------------------------------------


func _build_music() -> void:
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.bus = "Music"
	_music.volume_db = -80.0
	add_child(_music)
	_music_gap_left = _roll(CONFIG.section("music").get("exploration_off_seconds", [70.0, 130.0]))


func _tick_music(delta: float) -> void:
	var music := CONFIG.section("music")
	var wanted := _wanted_track(music, delta)

	if wanted != _music_wanted:
		_music_wanted = wanted
		_music_fade = 0.0

	var fade_seconds := maxf(float(music.get("fade_seconds", 3.0)), 0.01)

	if _music_track != _music_wanted:
		# Fade the outgoing track out before the incoming one starts. One player,
		# two phases -- a second player and a true crossfade is the obvious
		# upgrade and is deliberately not here: two music streams decoding at
		# once on a handheld, for a transition the player hears a few dozen
		# times a run, is not a trade worth making yet.
		if _music.playing:
			_music_fade = minf(_music_fade + delta / fade_seconds, 1.0)
			_music.volume_db = linear_to_db(maxf(1.0 - _music_fade, 0.0001))
			if _music_fade >= 1.0:
				_music.stop()
			return
		_music_track = _music_wanted
		_music_fade = 0.0
		if _music_track.is_empty():
			return
		var tracks: Dictionary = music.get("tracks", {}) as Dictionary
		var entry: Dictionary = tracks.get(_music_track, {}) as Dictionary
		var file := str(entry.get("file", ""))
		if file.is_empty():
			_music_track = ""
			return
		var stream := CONFIG.stream("%s/%s.wav" % [str(music.get("dir", "")), file])
		if stream == null:
			_music_track = ""
			return
		_music.stream = stream
		_music.volume_db = -80.0
		_music.play()
		return

	if _music_track.is_empty() or not _music.playing:
		return
	# Fade in.
	_music_fade = minf(_music_fade + delta / fade_seconds, 1.0)
	_music.volume_db = linear_to_db(maxf(_music_fade, 0.0001))


## Which track the current game state calls for, or "" for silence.
##
## Combat outranks place; the exploration bed is intermittent by design (see the
## config's `_comment_silence`) and returns "" during its off stretches, which is
## what the gap timer below is counting.
func _wanted_track(music: Dictionary, delta: float) -> String:
	if _in_combat:
		return "combat"
	if _near_village(music):
		return "village"

	_music_gap_left -= delta
	if _music_gap_left <= 0.0:
		_music_playing_stretch = not _music_playing_stretch
		var key := "exploration_on_seconds" if _music_playing_stretch else "exploration_off_seconds"
		_music_gap_left = _roll(music.get(key, [90.0, 140.0]))
	return "exploration" if _music_playing_stretch else ""


func _near_village(music: Dictionary) -> bool:
	if _player == null or is_nan(_village_at.x):
		return false
	var here := _player.global_position
	return Vector2(here.x, here.z).distance_to(_village_at) \
		< float(music.get("village_radius_metres", 55.0))


## Where the village is, taken from `playground_world.gd`'s own `HOUSE_AT`.
##
## Read out of the script's CONSTANT MAP rather than copied into audio.json:
## the house position is not an audio tunable, it is a fact about the world, and
## a second copy of it here is a copy that goes stale the day the village moves.
## `Object.get()` does not see constants, hence the script detour.
##
## NaN means "not found", which disables only the village music cue.
func _find_village() -> Vector2:
	var world := get_parent()
	if world == null:
		return Vector2(NAN, NAN)
	var script := world.get_script() as Script
	if script == null:
		return Vector2(NAN, NAN)
	var constants := script.get_script_constant_map()
	var at: Variant = constants.get("HOUSE_AT")
	if typeof(at) != TYPE_VECTOR2:
		return Vector2(NAN, NAN)
	return at as Vector2


func _roll(range_value: Variant) -> float:
	if typeof(range_value) != TYPE_ARRAY or (range_value as Array).size() < 2:
		return 90.0
	return randf_range(float((range_value as Array)[0]), float((range_value as Array)[1]))


# --- world queries -----------------------------------------------------------


func _player_z() -> float:
	return _player.global_position.z if _player != null else 0.0


func _is_dark() -> bool:
	return _look != null and _look.has_method("is_dark") and bool(_look.call("is_dark"))


## Which band a world z falls in.
##
## The boundaries are DERIVED from `terrain_playground.json`'s trail: each
## band's polyline ends where the next begins, so the last point's z is the
## boundary. `world_perimeter.gd` restates the same four numbers as constants;
## adding a third copy here is how they drift, and the config is the source both
## of them ultimately came from.
func _load_band_bounds() -> void:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		push_warning("audio: no terrain config; ambience will stay in one band")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var trail: Dictionary = (parsed as Dictionary).get("trail", {}) as Dictionary
	var bands: Variant = trail.get("bands", [])
	if typeof(bands) != TYPE_ARRAY:
		return
	for entry: Variant in bands as Array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var band := entry as Dictionary
		var points: Variant = band.get("points", [])
		if typeof(points) != TYPE_ARRAY or (points as Array).is_empty():
			continue
		var last: Variant = (points as Array)[(points as Array).size() - 1]
		if typeof(last) != TYPE_ARRAY or (last as Array).size() < 2:
			continue
		_band_ids.append(str(band.get("id", "")))
		_band_bounds.append(float((last as Array)[1]))


func _band_for(z: float) -> String:
	if _band_ids.is_empty():
		return "band1_lower_meadows"
	for i in _band_ids.size():
		if z < _band_bounds[i]:
			return _band_ids[i]
	# Past the last boundary is the final band -- the approach continues beyond
	# the point its own polyline stops being drawn.
	return _band_ids[_band_ids.size() - 1]
