extends RefCounted

## Pure time-of-day math for R5.1's day/night cycle.
##
## Kept apart from world_look.gd (a Node) because docs/decisions/D02 scopes
## tests/test_case.gd suites to pure logic only -- no scene tree. This is the
## part of the cycle that can be pinned by a test: the hour, which named
## data/config/art.json preset is active, and whether it counts as dark.
## world_look.gd owns turning that into an actual Sun/sky/Environment.

const CONFIG_PATH := "res://data/config/art.json"

var day_length_seconds: float = 600.0
var dark_from_hour: float = 20.0
var dark_to_hour: float = 5.0
var _keyframes: Array[Dictionary] = []


static func load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## `config` is art.json's top level: day_length_seconds/dark_from_hour/
## dark_to_hour plus a `times` dict whose entries may carry an `hour`.
## Entries with no `hour` (there were none before R5.1) are not part of the
## cycle -- they stay reachable by name only, e.g. for tools/survey.gd.
func _init(config: Dictionary) -> void:
	day_length_seconds = maxf(1.0, float(config.get("day_length_seconds", 600.0)))
	dark_from_hour = fposmod(float(config.get("dark_from_hour", 20.0)), 24.0)
	dark_to_hour = fposmod(float(config.get("dark_to_hour", 5.0)), 24.0)

	var times: Variant = config.get("times", {})
	if typeof(times) != TYPE_DICTIONARY:
		return
	for key: String in (times as Dictionary).keys():
		if key.begins_with("_"):
			continue
		var entry: Variant = (times as Dictionary)[key]
		if typeof(entry) != TYPE_DICTIONARY or not (entry as Dictionary).has("hour"):
			continue
		_keyframes.append({
			"hour": fposmod(float((entry as Dictionary)["hour"]), 24.0),
			"name": key,
		})
	_keyframes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.hour < b.hour)


func keyframe_names() -> Array:
	var found: Array = []
	for kf: Dictionary in _keyframes:
		found.append(kf.name)
	return found


## Elapsed real seconds -> hour of the in-game day (0..24), wrapping every
## day_length_seconds.
func hour_at(elapsed_seconds: float) -> float:
	return fposmod(elapsed_seconds, day_length_seconds) / day_length_seconds * 24.0


## The inverse of hour_at: how many elapsed seconds land the clock exactly on
## `hour`. Used to snap time to a named moment, e.g. camp rest -> morning.
func elapsed_for_hour(hour: float) -> float:
	return fposmod(hour, 24.0) / 24.0 * day_length_seconds


## Which named preset is active at `hour`: the latest keyframe at or before
## it, wrapping past midnight to the latest keyframe overall. "" if no
## preset in art.json's `times` carries an `hour`.
func preset_at(hour: float) -> String:
	if _keyframes.is_empty():
		return ""
	var h := fposmod(hour, 24.0)
	var active: String = _keyframes[-1].name
	for kf: Dictionary in _keyframes:
		if kf.hour <= h:
			active = kf.name
		else:
			break
	return active


## OP23-05. The neighbouring keyframes bracketing `hour` and how far between
## them play currently sits: {"from": name_before, "to": name_after,
## "t": 0..1}. world_look.gd blends sun/sky/environment continuously between
## these two rather than snapping the instant `preset_at()` crosses a
## boundary -- the owner's ROG playtest caught the snap directly ("day/night
## transition flashed straight to night instead of progressing") and it
## explains OP23-06 too: NIGHT-LIGHT's own tuning (art.json) was correct for
## a SETTLED night sky, but landing on it in one frame with no transition is
## what "worst immediately after nightfall" describes -- the same numbers,
## arrived at instantly instead of eased into.
##
## Wraps the same way `preset_at()` does. `_keyframes` is sorted by hour, so
## walking it once and checking each keyframe against its own successor
## (wrapping the last back to the first, +24h) finds exactly one bracket.
func interpolate_at(hour: float) -> Dictionary:
	if _keyframes.is_empty():
		return {"from": "", "to": "", "t": 0.0}
	if _keyframes.size() == 1:
		return {"from": _keyframes[0].name, "to": _keyframes[0].name, "t": 0.0}
	var h := fposmod(hour, 24.0)
	var n := _keyframes.size()
	for i in n:
		var cur: Dictionary = _keyframes[i]
		var nxt: Dictionary = _keyframes[(i + 1) % n]
		var cur_hour: float = cur.hour
		# The wrap case: the next keyframe's hour is not > this one's only when
		# `cur` is the LAST keyframe and `nxt` is the first, past midnight.
		var nxt_hour: float = nxt.hour if nxt.hour > cur_hour else nxt.hour + 24.0
		var h_adj: float = h if h >= cur_hour else h + 24.0
		if h_adj >= cur_hour and h_adj < nxt_hour:
			var span: float = nxt_hour - cur_hour
			var t: float = (h_adj - cur_hour) / span if span > 0.0 else 0.0
			return {"from": cur.name, "to": nxt.name, "t": clampf(t, 0.0, 1.0)}
	# Unreachable given the loop above covers every hour in [0, 24), but keeps
	# this total rather than trusting that.
	return {"from": _keyframes[-1].name, "to": _keyframes[-1].name, "t": 0.0}


func is_dark(hour: float) -> bool:
	var h := fposmod(hour, 24.0)
	if dark_from_hour <= dark_to_hour:
		return h >= dark_from_hour and h < dark_to_hour
	# The common case: the dark window wraps past midnight (e.g. 20 -> 5).
	return h >= dark_from_hour or h < dark_to_hour
