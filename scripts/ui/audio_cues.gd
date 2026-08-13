extends RefCounted
class_name AudioCues

## Spec 20's small UI audio set. One shared player, nine short cues.
##
## `RefCounted`, not an autoload -- D14 keeps input-facing singletons off the
## autoload list, and this is the same shape: a bag of `static` state plus
## `static func`s, called as `AudioCues.play(&"ui_accept")` from wherever a
## menu already reacts to that moment. No caller ever instantiates this.
##
## The player itself is lazy and shared: the first `play()` call anywhere in
## the game adds ONE `AudioStreamPlayer` under the tree root and every cue
## after that reuses it, the same "one node, not one per caller" shape
## `input_glyph.gd::using_gamepad()` uses to reach the tree.
##
## HEADLESS IS A REAL CALLER, not an edge case to shrug off: `tests/run_tests.gd`
## and every `smoke_*.gd` drive these wired call sites with no display and no
## audio device behind them. `play()` checks `DisplayServer.get_name()` first
## and no-ops before it ever touches a node, so the wiring in `game_menu.gd`/
## `build_menu.gd`/`build_placer.gd` needs no headless guard of its own.
##
## Rate limit: `should_play()` refuses to fire the same cue twice inside
## `MIN_INTERVAL_S`, so a stick nudging focus across six buttons in one frame
## of travel plays one tick, not six. Exposed as its own pure `static func`
## precisely so `tests/test_audio_cues.gd` can probe the boundary without a
## scene tree at all.

const MIN_INTERVAL_S := 0.06
const VOLUME_DB := -12.0

## Guards the `now - last < MIN_INTERVAL_S` boundary against float error: a
## caller computing `now` as `last + MIN_INTERVAL_S` (exactly the edge, in
## theory) can round to a hair under it in practice, and without this the
## edge sample refuses when it should pass.
const _EPSILON := 0.000001

## cue name -> .wav path. `tools/audio/gen_ui_cues.py` is what generated the
## files this points at; regenerate there, never hand-edit a .wav.
const CUE_PATHS := {
	"ui_focus": "res://assets/ui/audio/ui_focus.wav",
	"ui_accept": "res://assets/ui/audio/ui_accept.wav",
	"ui_cancel": "res://assets/ui/audio/ui_cancel.wav",
	"ui_tab": "res://assets/ui/audio/ui_tab.wav",
	"ui_error": "res://assets/ui/audio/ui_error.wav",
	"aim_enter": "res://assets/ui/audio/aim_enter.wav",
	"build_snap": "res://assets/ui/audio/build_snap.wav",
	"build_place": "res://assets/ui/audio/build_place.wav",
	"capture_success": "res://assets/ui/audio/capture_success.wav",
}

static var _player: AudioStreamPlayer = null
static var _stream_cache: Dictionary = {}
static var _last_played: Dictionary = {}


## Play a cue by name. Silently does nothing for an unknown cue, a headless
## run, a missing tree, or a repeat inside the rate-limit window -- every
## failure mode here is "no sound", never an error, since a menu blip is not
## worth a call site's own try/guard.
static func play(cue: StringName) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var key := String(cue)
	if not CUE_PATHS.has(key):
		return
	if not should_play(key, _now()):
		return
	var stream := _load_stream(key)
	if stream == null:
		return
	var player := _ensure_player()
	if player == null:
		return
	player.stream = stream
	player.play()


## Pure rate-limit check, deliberately separated from `play()` so it can be
## tested without a `SceneTree`. Records `now` as the cue's last-played time
## as a side effect of returning true -- the same "ask and it remembers you
## asked" shape a debounce needs, so callers never juggle their own timestamp.
static func should_play(cue: StringName, now: float) -> bool:
	var key := String(cue)
	var last: float = float(_last_played.get(key, -INF))
	if now - last < MIN_INTERVAL_S - _EPSILON:
		return false
	_last_played[key] = now
	return true


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


static func _load_stream(key: String) -> AudioStream:
	if _stream_cache.has(key):
		return _stream_cache[key]
	var path := String(CUE_PATHS.get(key, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("AudioCues: no file at %s for cue '%s'" % [path, key])
		return null
	var stream: AudioStream = load(path)
	_stream_cache[key] = stream
	return stream


static func _ensure_player() -> AudioStreamPlayer:
	if _player != null and is_instance_valid(_player):
		return _player
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var player := AudioStreamPlayer.new()
	player.name = "AudioCuesPlayer"
	player.bus = "Master"
	player.volume_db = VOLUME_DB
	tree.root.add_child(player)
	_player = player
	return player
