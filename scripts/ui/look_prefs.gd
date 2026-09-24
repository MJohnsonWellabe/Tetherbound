extends RefCounted

## UX §8's accessibility minimum: adjustable look sensitivity and inversion
## per axis. `camera_rig.gd` reads these every look tick, for the stick and the
## mouse alike, on top of its own tuned `gamepad_sensitivity`,
## `mouse_sensitivity` and per-profile `sensitivity_scale`, which stay the
## designer's numbers. The player's percentage multiplies them; it never
## replaces them.
##
## Static, like `motion_prefs.gd`, and stored in the same
## `user://settings.json` `accessibility` section, which `key_bindings.gd`
## alone writes (D15). Presentation-local: another peer never reads it.

const DEFAULT_PERCENT := 100
## Bounds and step are the menu's to tune (`menu.json` settings.accessibility);
## these are the fallbacks when that block is missing.
const FALLBACK_MIN_PERCENT := 25
const FALLBACK_MAX_PERCENT := 200

static var _percent := DEFAULT_PERCENT
## UX §8 "aim-assistance strength/off as an individual setting, never attack
## bending". It scales the orb throw's help only (`throw_aim.gd`): the stick
## slowdown near the target and the soft magnet; Off also withholds the launch
## lead. Attacks are never aimed for the player at any setting.
const AIM_ASSIST_STEPS: Array[int] = [100, 50, 0]
static var _aim_assist := 100
static var _invert_x := false
static var _invert_y := false


static func sensitivity_percent() -> int:
	return _percent


static func sensitivity_scale() -> float:
	return float(_percent) / 100.0


static func set_sensitivity_percent(value: int, low: int = FALLBACK_MIN_PERCENT,
		high: int = FALLBACK_MAX_PERCENT) -> void:
	_percent = clampi(value, mini(low, high), maxi(low, high))


static func invert_x() -> bool:
	return _invert_x


static func invert_y() -> bool:
	return _invert_y


static func set_invert_x(value: bool) -> void:
	_invert_x = value


static func set_invert_y(value: bool) -> void:
	_invert_y = value


## Yaw/pitch change in degrees, as the rig computed it from the stick and the
## mouse, with the player's sensitivity and inversion applied. `config_invert_y`
## is the rig's own `invert_y` default; the player's choice flips it again, so
## a config that ships inverted is still un-invertible from the menu.
static func apply(change: Vector2, config_invert_y: bool = false) -> Vector2:
	var out := change * sensitivity_scale()
	if _invert_x:
		out.x = -out.x
	if _invert_y != config_invert_y:
		out.y = -out.y
	return out


static func aim_assist_percent() -> int:
	return _aim_assist


static func aim_assist_strength() -> float:
	return float(_aim_assist) / 100.0


## Snaps to the nearest offered step.
static func set_aim_assist_percent(value: int) -> void:
	var best := AIM_ASSIST_STEPS[0]
	for step: int in AIM_ASSIST_STEPS:
		if absi(step - value) < absi(best - value):
			best = step
	_aim_assist = best


static func next_aim_assist_percent() -> int:
	var at := AIM_ASSIST_STEPS.find(_aim_assist)
	return AIM_ASSIST_STEPS[(at + 1) % AIM_ASSIST_STEPS.size()]


static func reset() -> void:
	_aim_assist = AIM_ASSIST_STEPS[0]
	_percent = DEFAULT_PERCENT
	_invert_x = false
	_invert_y = false


## Read from the settings object's `accessibility` section. Missing keys keep
## their defaults; a malformed section leaves everything as it is.
static func load_from(prefs: RefCounted) -> void:
	if prefs == null:
		return
	var stored: Variant = prefs.get("accessibility")
	if typeof(stored) != TYPE_DICTIONARY:
		return
	var table := stored as Dictionary
	set_sensitivity_percent(int(table.get("look_sensitivity_percent", DEFAULT_PERCENT)))
	_invert_x = bool(table.get("invert_look_x", false))
	_invert_y = bool(table.get("invert_look_y", false))
	set_aim_assist_percent(int(table.get("aim_assist_percent", AIM_ASSIST_STEPS[0])))


## Write back into `prefs.accessibility`, keeping what else is there (reduced
## motion lives in the same section). The caller saves.
static func store_to(prefs: RefCounted) -> void:
	if prefs == null:
		return
	var table: Variant = prefs.get("accessibility")
	var out: Dictionary = (table as Dictionary).duplicate() if typeof(table) == TYPE_DICTIONARY else {}
	out["look_sensitivity_percent"] = _percent
	out["invert_look_x"] = _invert_x
	out["invert_look_y"] = _invert_y
	out["aim_assist_percent"] = _aim_assist
	prefs.set("accessibility", out)
