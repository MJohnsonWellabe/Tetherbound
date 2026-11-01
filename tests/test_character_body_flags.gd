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
