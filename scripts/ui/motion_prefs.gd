extends RefCounted

## UX §8's reduced-motion setting: lowers camera impulse, UI animation and
## nonessential flashes WITHOUT changing host combat timing.
##
## Static, like `audio_manager.gd`'s volumes, because the things that read it
## (a camera nudge, a telegraph flash) live all over the scene and none of them
## should need a reference to the menu to ask one yes/no question. The value is
## stored in `user://settings.json`'s `accessibility` section, which
## `key_bindings.gd` alone writes (D15): this file reads it from and hands it
## back to that object, it never opens the file itself.
##
## Presentation only. Nothing here may be read by authority code -- a peer that
## reduces motion must fight exactly the same fight as one that does not.

static var _reduced := false
## UX §8 "camera shake 0–100%, default modest". The default IS the modest
## setting: 100% plays the camera impulses exactly as combat.json tunes them
## (the charged-hit roll is 0.65°). Reduced motion overrides it to nothing.
static var _shake_percent := 100


static func reduced_motion() -> bool:
	return _reduced


static func set_reduced_motion(value: bool) -> void:
	_reduced = value


## Scale for a purely visual impulse (camera nudge, shake, flash intensity):
## 1.0 normally, 0.0 with reduced motion on. Callers multiply; they do not
## branch on timing, so the fight's clock is untouched either way.
static func impulse_scale() -> float:
	return 0.0 if _reduced else 1.0


static func camera_shake_percent() -> int:
	return _shake_percent


static func set_camera_shake_percent(value: int) -> void:
	_shake_percent = clampi(value, 0, 100)


## Scale for a camera impulse: the player's shake level, or nothing under
## reduced motion.
static func camera_shake_scale() -> float:
	return 0.0 if _reduced else float(_shake_percent) / 100.0


## Read from the settings object's `accessibility` section. A missing or
## malformed section leaves the default (off).
static func load_from(prefs: RefCounted) -> void:
	if prefs == null:
		return
	var stored: Variant = prefs.get("accessibility")
	if typeof(stored) != TYPE_DICTIONARY:
		return
	_reduced = bool((stored as Dictionary).get("reduced_motion", false))
	set_camera_shake_percent(int((stored as Dictionary).get("camera_shake_percent", 100)))


## Write back into `prefs.accessibility`. The caller saves.
static func store_to(prefs: RefCounted) -> void:
	if prefs == null:
		return
	var table: Variant = prefs.get("accessibility")
	var out: Dictionary = (table as Dictionary).duplicate() if typeof(table) == TYPE_DICTIONARY else {}
	out["reduced_motion"] = _reduced
	out["camera_shake_percent"] = _shake_percent
	prefs.set("accessibility", out)
