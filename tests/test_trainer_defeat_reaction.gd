extends "res://tests/test_case.gd"

## F04#6 aftermath: a named trainer beaten in the world plays a one-shot
## `defeated` slump before returning to idle. Pins the data and the rigs the
## reaction needs, and the guard that stops an already-beaten trainer from
## replaying it when a world loads.

const ART := "res://data/config/art.json"
const TRAINER_NPC := "res://scripts/world/trainer_npc.gd"
## The rigs every named Meadows trainer resolves to: the three grunt-family
## captain bodies (npc_ranks.gd `captain` -> grunt, plus captain_a/b site
## bases) and the Warden's own rebuild.
const RIGS := ["grunt", "captain_a", "captain_b", "warden"]


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _glb_clip_names(path: String) -> Array:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 20:
		return []
	var json_length := bytes.decode_u32(12)
	var parsed: Variant = JSON.parse_string(bytes.slice(20, 20 + json_length).get_string_from_utf8())
	var names: Array = []
	if parsed is Dictionary:
		for animation: Variant in (parsed as Dictionary).get("animations", []):
			names.append(str((animation as Dictionary).get("name", "")))
	return names


func test_named_trainer_rigs_carry_and_map_the_defeated_clip() -> void:
	var art := _json(ART)
	for rig: String in RIGS:
		var block := art.get(rig, {}) as Dictionary
		var clips := block.get("clips", {}) as Dictionary
		assert_eq(str(clips.get("defeated", "")), "defeated", "%s maps the defeated role" % rig)
		var names := _glb_clip_names(str(block.get("model", "")))
		assert_true(names.has("defeated"), "%s's model carries a defeated animation (%s)" % [rig, names])
		for kept: String in ["idle", "walk", "sprint", "jump", "throw"]:
			assert_true(names.has(kept), "%s keeps its shipped %s clip" % [rig, kept])


func test_reaction_is_tunable_and_only_plays_on_a_witnessed_flip() -> void:
	var hold := float((_json(ART).get("cast_reactions", {}) as Dictionary) \
		.get("defeat_hold_seconds", 0.0))
	assert_true(hold > 0.0 and hold <= 20.0, "the slump holds for a bounded, tunable time (%.1fs)" % hold)
	var source := FileAccess.get_file_as_string(TRAINER_NPC)
	assert_true(source.contains("_beaten_seen.has(id) and not bool(_beaten_seen[id])"),
		"only a false -> true flip the placer witnessed plays the reaction")
	assert_true(source.contains('clip_for", "defeated", ""'),
		"a rig without the clip resolves to no reaction rather than a wrong one")
