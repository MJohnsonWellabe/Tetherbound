extends "res://tests/test_case.gd"

## Owner-picked creature remakes (1 Nov 2026) ship behind named flags in
## data/config/creature_model_flags.json, OFF by default. Every flag must leave
## the installed model in place while off, swap the species' model when on, and
## point at a model that plays every gameplay clip the installed one did.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TRAINER_HEIGHT := 1.80

var installed: Dictionary


func before_each() -> void:
	installed = SPECIES.table().duplicate(true)


func after_each() -> void:
	SPECIES._table = installed


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPECIES.MODEL_FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_model_flags.json parses")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func _clip_names(model_path: String) -> PackedStringArray:
	var scene := load(model_path) as PackedScene
	assert_true(scene != null, "%s loads" % model_path)
	if scene == null:
		return PackedStringArray()
	var root := scene.instantiate()
	var names := PackedStringArray()
	for player: AnimationPlayer in root.find_children("*", "AnimationPlayer", true, false):
		for clip in player.get_animation_list():
			names.append(String(clip))
	root.free()
	return names


func test_every_model_flag_is_off_and_leaves_the_installed_model() -> void:
	var flags := _flags()
	assert_true(not flags.is_empty(), "at least one model flag")
	for flag: String in flags:
		assert_false(bool(flags[flag].get("enabled", true)), "%s ships OFF" % flag)
		for id: String in flags[flag].species:
			var live := str(SPECIES.placeholder(id).get("model", ""))
			assert_ne(live, str(flags[flag].species[id].model), "%s: %s keeps its installed model" % [flag, id])


func test_an_enabled_flag_swaps_the_model_and_keeps_every_clip() -> void:
	var flags := _flags()
	for flag: String in flags:
		var entry: Dictionary = (flags[flag] as Dictionary).duplicate(true)
		entry.enabled = true
		var rows := installed.duplicate(true)
		SPECIES.merge_model_flags(rows, {flag: entry})
		for id: String in entry.species:
			var before: Dictionary = installed[id].placeholder
			var after: Dictionary = rows[id].placeholder
			var model := str(entry.species[id].model)
			assert_eq(str(after.model), model, "%s swaps %s's model" % [flag, id])
			assert_true(float(after.height) > TRAINER_HEIGHT, "%s stands taller than the trainer" % id)
			assert_true(float(after.height) >= float(before.height), "%s is never shrunk" % id)
			var clips := _clip_names(model)
			var wanted: Dictionary = (before.get("animations", {}) as Dictionary).duplicate()
			wanted.merge(after.get("animations", {}), true)
			assert_true(not wanted.is_empty(), "%s declares its clips" % id)
			for role: String in wanted:
				# Metadata beside the clip map (Torrentoad's attack_contact_phase and
				# its _comment) names no clip; every clip role is still checked.
				if role.begins_with("_") or not wanted[role] is String:
					continue
				assert_true(clips.has(str(after.animations.get(role, wanted[role]))),
						"%s: %s plays its %s clip (has %s)" % [flag, id, role, clips])
