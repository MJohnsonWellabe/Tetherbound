extends RefCounted

## P2-108 (UIPOSES lane, 1 Nov 2026): flag-off presentation for mounted
## swimming. data/config/water_mount_presentation.json.
const CONFIG_PATH := "res://data/config/water_mount_presentation.json"
static var _config: Dictionary = {}


static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		_config = raw if raw is Dictionary else {"enabled": false}
	return _config


## The listed mount's row (by species id, with or without the water_ prefix),
## or {} when the flag is off or the mount is not listed.
static func row(species_id: String, cfg: Dictionary = {}) -> Dictionary:
	var source := cfg if not cfg.is_empty() else config()
	if not bool(source.get("enabled", false)):
		return {}
	var rows: Variant = source.get("mounts", {})
	if not rows is Dictionary:
		return {}
	for key: String in [species_id, "water_" + species_id.trim_prefix("water_"), species_id.trim_prefix("water_")]:
		var found: Variant = (rows as Dictionary).get(key, null)
		if found is Dictionary:
			return _with_deep_swim(found as Dictionary)
	return {}


## F39#8 `deep_swim_1113` (per mount, flag-off): the row's own deeper sink
## replaces `extra_sink_m`, so the mount's back goes under and the rider sits
## waist-deep. Presentation only; the row is copied, never edited in place.
static func _with_deep_swim(look: Dictionary) -> Dictionary:
	var deep: Variant = look.get("deep_swim_1113", {})
	if not deep is Dictionary or not bool((deep as Dictionary).get("enabled", false)):
		return look
	var out := look.duplicate()
	out["extra_sink_m"] = float((deep as Dictionary).get("extra_sink_m", look.get("extra_sink_m", 0.0)))
	return out


## Extra origin offset (metres, added to the swim follow target): a deeper sit
## plus a gentle stroke bob.
static func origin_delta(look: Dictionary, t: float) -> float:
	var period := maxf(0.2, float(look.get("bob_period_s", 1.8)))
	return -float(look.get("extra_sink_m", 0.0)) + float(look.get("bob_amplitude_m", 0.0)) * sin(TAU * t / period)


## Turn the mount's cast shadows off (or back to their own setting). The
## original setting is kept on each mesh so restoring is exact.
static func set_shadows(body: Node3D, on: bool) -> void:
	if body == null or not is_instance_valid(body):
		return
	if on and not body.has_meta("uiposes_shadows_off"):
		return
	if not on and body.has_meta("uiposes_shadows_off"):
		return
	# The blob contact shadow lies on the sea floor under a swimmer; it goes
	# with the cast shadows. Its own visibility is restored exactly.
	var blob := body.get_node_or_null("ContactShadow") as Node3D
	if blob != null:
		if on and blob.has_meta("uiposes_visible"):
			blob.visible = bool(blob.get_meta("uiposes_visible"))
			blob.remove_meta("uiposes_visible")
		elif not on:
			blob.set_meta("uiposes_visible", blob.visible)
			blob.visible = false
	for node: Node in body.find_children("*", "GeometryInstance3D", true, false):
		var geo := node as GeometryInstance3D
		if geo == blob:
			continue
		if on:
			if geo.has_meta("uiposes_cast_shadow"):
				geo.cast_shadow = int(geo.get_meta("uiposes_cast_shadow"))
				geo.remove_meta("uiposes_cast_shadow")
		else:
			geo.set_meta("uiposes_cast_shadow", int(geo.cast_shadow))
			geo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if on:
		body.remove_meta("uiposes_shadows_off")
	else:
		body.set_meta("uiposes_shadows_off", true)


## P2-108 (F39#8, flag-off with this file): a waterline ring and trailing wake
## for a listed mount whose row carries a `wake` map. Created once; the wake
## node clears itself whenever the mount is not swimming.
static func ensure_wake(actor: Node3D, look: Dictionary) -> void:
	var wake: Variant = look.get("wake", {})
	if not wake is Dictionary or (wake as Dictionary).is_empty() or actor.get_node_or_null(^"MountWake") != null:
		return
	var view: Node3D = preload("res://scripts/world/water_mount_wake.gd").new()
	view.name = "MountWake"
	var settings := (wake as Dictionary).duplicate()
	settings["enabled"] = true
	view.set("settings", settings)
	view.set("_body", actor)
	actor.add_child(view)
