extends RefCounted

const CONFIG := "res://data/config/water_current_cue.json"
const PREF := "water_current_cue"


static func config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary:
		return {}
	if OS.get_cmdline_user_args().has("--tidewake-current-candidate"):
		parsed.enabled = true
	return parsed


## The arrow's default when the player has not chosen (water_current_cue.json
## `default_on`; absent = on). Owner, 10 Nov: OFF by default, kept in Accessibility.
static func default_on() -> bool:
	return bool(config().get("default_on", true))


static func preferred(prefs: RefCounted) -> bool:
	var fallback := default_on()
	if prefs == null:
		return fallback
	var table: Variant = prefs.get("accessibility")
	return bool(table.get(PREF, fallback)) if table is Dictionary else fallback


static func set_preferred(prefs: RefCounted, enabled: bool) -> bool:
	if prefs == null:
		return false
	var table: Variant = prefs.get("accessibility")
	var copy: Dictionary = table.duplicate() if table is Dictionary else {}
	copy[PREF] = enabled
	prefs.set("accessibility", copy)
	return bool(prefs.call("save"))


## A plan-view arrow relative to the viewing swimmer. Camera pitch does not
## make an away-flow disappear at a grazing water angle. Zero is calm/invalid.
static func direction(flow: Vector3, camera_basis: Basis) -> Vector2:
	if not flow.is_finite() or not camera_basis.is_finite():
		return Vector2.ZERO
	var right := Vector3(camera_basis.x.x, 0.0, camera_basis.x.z).normalized()
	var forward := Vector3(-camera_basis.z.x, 0.0, -camera_basis.z.z).normalized()
	if right.length_squared() < 0.5 or forward.length_squared() < 0.5:
		return Vector2.ZERO
	return Vector2(flow.dot(right), -flow.dot(forward)).normalized()
