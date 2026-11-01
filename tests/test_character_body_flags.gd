extends "res://tests/test_case.gd"

## NPC body flags (data/config/character_body_flags.json, read by
## character_model.gd::with_body_flags). GPU arms flip `enabled`; a flag must
## apply only its body albedo override, only to its own character, and only
## when enabled.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const FLAGS_PATH := "res://data/config/character_body_flags.json"


func test_shipped_flags_are_off_and_resolve() -> void:
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(doc is Dictionary, "character_body_flags.json parses to an object")
	var flags: Dictionary = (doc as Dictionary).get("flags", {}) if doc is Dictionary else {}
	assert_true(not flags.is_empty(), "the file declares flags")
	for flag: String in flags:
		var entry: Dictionary = flags[flag]
		assert_false(bool(entry.get("enabled", true)), "%s ships OFF" % flag)
		var characters: Dictionary = entry.get("characters", {})
		for key: String in characters:
			var base := CHARACTER_MODEL.config_for(key)
			assert_true(not base.is_empty(), "%s names an art.json character (%s)" % [flag, key])
			for field: String in characters[key]:
				assert_true(field in CHARACTER_MODEL.BODY_FLAG_KEYS, "%s %s.%s is a body-surface key" % [flag, key, field])
			var path := str((characters[key] as Dictionary).get("body_albedo_override", ""))
			assert_true(ResourceLoader.exists(path), "%s override %s exists" % [flag, path])
			# Forced on, the override lands on that character and the rest of its entry is unchanged.
			var forced := {"flags": {flag: {"enabled": true, "characters": characters}}}
			var merged := CHARACTER_MODEL.with_body_flags(base, key, forced)
			assert_eq(str(merged.get("body_albedo_override", "")), path, "%s applies to %s when enabled" % [flag, key])
			assert_eq(str(merged.get("model", "")), str(base.get("model", "")), "%s keeps %s's rig" % [flag, key])
			# Off (as shipped), config_for is unchanged.
			assert_false(base.get("body_albedo_override", "") == path, "%s does not apply while OFF" % flag)


func test_flag_touches_only_its_character_and_body_keys() -> void:
	var base := {"model": "res://m.glb", "height": 1.7}
	var doc := {"flags": {"f": {"enabled": true, "characters": {"a": {"body_albedo_override": "res://x.png", "model": "res://other.glb"}}}}}
	var other := CHARACTER_MODEL.with_body_flags(base, "b", doc)
	assert_true(other == base, "another character is untouched")
	var merged := CHARACTER_MODEL.with_body_flags(base, "a", doc)
	assert_eq(str(merged.get("body_albedo_override")), "res://x.png")
	assert_eq(str(merged.get("model")), "res://m.glb", "a non-body key in a flag is refused")
	assert_false(base.has("body_albedo_override"), "the source entry is not mutated")
	var off := {"flags": {"f": {"enabled": false, "characters": {"a": {"body_albedo_override": "res://x.png"}}}}}
	assert_true(CHARACTER_MODEL.with_body_flags(base, "a", off) == base, "a disabled flag applies nothing")


func _idle_arm_key(model: Node3D) -> Quaternion:
	var player: AnimationPlayer = model.call("animation_player")
	var clip := StringName(str(model.call("clip_for", "idle")))
	for library_name: StringName in player.get_animation_library_list():
		var library := player.get_animation_library(library_name)
		if not library.has_animation(clip):
			continue
		var idle := library.get_animation(clip)
		for track in idle.get_track_count():
			if idle.track_get_type(track) == Animation.TYPE_ROTATION_3D \
					and str(idle.track_get_path(track)).ends_with(":LeftArm"):
				return idle.track_get_key_value(track, 0)
	return Quaternion.IDENTITY


func _build(cfg: Dictionary) -> Node3D:
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	model.call("build_from_config", cfg)
	return model


## A relaxed idle changes only this character's copy of the idle clip, and a
## daylight rim lights only the flagged body's material.
func test_idle_relax_and_day_rim_apply_per_character() -> void:
	var base_cfg := CHARACTER_MODEL.config_for("innkeeper")
	assert_true(not base_cfg.is_empty(), "innkeeper has an art.json entry")
	var plain := _build(base_cfg)
	var cfg := base_cfg.duplicate(true)
	cfg["idle_relax"] = {"arm_drop_deg": 22.0, "elbow_bend_deg": 8.0}
	cfg["day_rim"] = {"strength": 0.5, "tint": 0.3}
	var relaxed := _build(cfg)
	var before := _idle_arm_key(plain)
	var after := _idle_arm_key(relaxed)
	assert_true(before.angle_to(after) > deg_to_rad(15.0), "the relaxed idle lowers the upper arm")
	var again := _build(base_cfg)
	assert_true(_idle_arm_key(again).angle_to(before) < 0.001, "the shared idle clip is untouched for other bodies")
	var lit := relaxed.call("body_material") as BaseMaterial3D
	assert_true(lit != null and lit.rim_enabled and is_equal_approx(lit.rim, 0.5), "the daylight rim lights the flagged body")
	var unlit := plain.call("body_material") as BaseMaterial3D
	assert_false(unlit != null and unlit.rim_enabled, "an unflagged body keeps no rim")
	for model: Node3D in [plain, relaxed, again]:
		model.free()
