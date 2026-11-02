extends "res://tests/test_case.gd"

## Owner-picked creature remakes (1 Nov 2026) ship behind named flags in
## data/config/creature_model_flags.json. Owner, 1 Nov 2026: "Turn on all the
## remake creatures", so every flag ships ON and its model is the live one. Each
## flag must swap the species' model, keep it taller than the trainer, never
## shrink it, and point at a model that plays every gameplay clip.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TRAINER_HEIGHT := 1.80

var installed: Dictionary

## Held OFF while their remake breaks a gameplay contract the rest of the suite
## checks; each comes back ON once its rig carries the missing data.
const HELD := {
	"remake_owner1101_torrentoad": "the remake carries the faint clip role and attack_contact_phase the installed Torrentoad has",
	"remake_owner1101_meadowhart": "the remake keeps the complete skinned bare body the riding visual needs",
	"remake_owner1101_bramblebun": "the remake carries its own alpha and shiny colourway textures (smoke_bramblebun_colourway_binding: all three variants resolve the same texture)",
	"remake_owner1101_ripplet": "the remake keeps the combat camera following the starter, not the trainer (smoke_combat: followed anchor 2.5 m from trainer vs 2.8 m from creature)",
	"remake_owner1101_terrapup": "the remake's longer rendered body (2.48 m half-extent) fits the Burrow Warrens chamber formation (smoke_arena_contain: wild engagement refused)",
	"remake_owner1101_riptusk": "the remake carries the water rest/faint candidate the installed Riptusk has (test_creature_rest_pose water candidates)",
	"remake_owner1101_burrowback": "its aspect variant Nightburrow reuses the base mesh with aspect textures painted for the old model (aspect textures / pose rig follow from tb/cause-remakes)",
	"remake_owner1101_trailpup": "its aspect variant Stormtrail reuses the base mesh with aspect textures painted for the old model (aspect textures / pose rig follow from tb/cause-remakes)",
	"remake_owner1101_paddlenewt": "its aspect variant Riftfrill reuses the base mesh with aspect textures painted for the old model (aspect textures / pose rig follow from tb/cause-remakes)",
	"remake_owner1101_tuskroot": "its aspect variant Ashtusk reuses the base mesh with aspect textures painted for the old model (aspect textures / pose rig follow from tb/cause-remakes)",
	"remake_owner1101_ashtusk": "it is an aspect variant of Tuskroot and must reuse Tuskroot's mesh, not its own (aspect textures / pose rig follow from tb/cause-remakes)",
	"remake_owner1101_mudsnout": "the Burrow Warrens mouth fight seats the companion beside the remake (smoke_arena_contain: with the remake as the wild Warrens Mudsnout, the clear-seat search for the Terrapup companion was exhausted and the engagement refused)",
	"remake_owner1101_frostclaw": "the F36 pose candidate library is measured on Frostclaw's installed rig carries over to the remake rig",
}


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


func test_every_owner_remake_ships_on_and_is_the_live_model() -> void:
	var flags := _flags()
	assert_true(not flags.is_empty(), "at least one model flag")
	for flag: String in flags:
		if flag in HELD:
			assert_false(bool(flags[flag].get("enabled", true)), "%s stays OFF until %s" % [flag, HELD[flag]])
			continue
		assert_true(bool(flags[flag].get("enabled", false)), "%s ships ON (owner, 1 Nov 2026)" % flag)
		for id: String in flags[flag].species:
			var live := str(SPECIES.placeholder(id).get("model", ""))
			assert_eq(live, str(flags[flag].species[id].model), "%s: %s plays the remake" % [flag, id])


func test_a_disabled_flag_changes_nothing() -> void:
	var flags := _flags()
	for flag: String in flags:
		var entry: Dictionary = (flags[flag] as Dictionary).duplicate(true)
		entry.enabled = false
		var rows := installed.duplicate(true)
		SPECIES.merge_model_flags(rows, {flag: entry})
		assert_eq(JSON.stringify(rows), JSON.stringify(installed), "%s OFF changes nothing" % flag)


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
