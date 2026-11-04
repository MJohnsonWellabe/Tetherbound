extends "res://tests/test_case.gd"

## NEAR6-MS lane (4 Nov 2026): arms for items scored 5.4-6.0. Each arm ships
## OFF until a quick CPU judge shows a gain; a judged gain flips it ON and this
## file then asserts ON with the "CPU <base> -> <cand>" score in `_why_on`.

const POST_STANCE := preload("res://scripts/characters/post_stance.gd")


func _json(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}


## F38#29 P2-065: the immediate beaten kneel. OFF returns no rows; ON returns
## the beaten_kneel rows: both knees bent, the hips lowered (fifth value) and
## the spine, neck and head bowed.
func test_f38_29_immediate_beaten_stance() -> void:
	var cfg := _json("res://data/config/npc_post_stances.json")
	var block: Dictionary = cfg.beaten_trainer_stance.immediate_1104
	assert_true(bool(block.enabled), "F38#29 immediate kneel ships ON (judged gain)")
	assert_true(str(block._why_on).contains("CPU 5.76 -> 6.18"), "records its score")
	var off := cfg.duplicate(true)
	off.beaten_trainer_stance.immediate_1104.enabled = false
	assert_eq(POST_STANCE.beaten_stance_immediate(off), [], "OFF attaches nothing")
	var on := cfg.duplicate(true)
	var rows: Array = POST_STANCE.beaten_stance_immediate(on)
	assert_eq(rows, cfg.stances[str(block.stance)], "ON uses the configured stance rows")
	var bones := {}
	for row: Array in rows:
		bones[str(row[0])] = row
	for bone: String in ["Hips", "LeftLeg", "RightLeg", "Spine", "Head"]:
		assert_true(bones.has(bone), "the kneel sets %s" % bone)
	assert_between(float(bones.Hips[4]), 0.2, 0.6, "the hips drop a knee's height, not into the ground")
	assert_true(float(bones.LeftLeg[1]) > 45.0 and float(bones.RightLeg[1]) > 45.0, "both knees flex (+X)")


## F38#29 P2-065 round 2: a trainer beaten without victory lines gets the
## aftermath push-in for a few seconds. Ships OFF; client presentation only.
func test_f38_29_silent_victory_shot_ships_on() -> void:
	var cfg := _json("res://data/config/trainer_aftermath.json")
	var block: Dictionary = cfg.silent_victory_shot_1104
	assert_true(bool(block.enabled), "silent victory shot ships ON (judged gain)")
	assert_true(str(block._why_on).contains("CPU 5.76 -> 6.18"), "records its score")
	assert_eq(str(block.scope), "client_presentation", "declares its scope")
	assert_between(float(block.hold_s), 2.0, 8.0, "a short beat, not a held camera")
	var director := FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	assert_true(director.contains("if conversation == \"\":\n\t\t_present_silent_victory(speaker)\n\t\treturn"),
		"only trainers without victory lines take the silent shot")
	var profiles: Dictionary = _json("res://data/config/camera.json").conversation.profiles
	assert_true(profiles.has("aftermath"), "it reuses the existing aftermath profile")


## F38#32 P2-035: the trail camp keep-clear zone ships ON (judged gain); a disabled
## zone is skipped and the Practice Meadow zone (no enabled key) stays on.
func test_f38_32_trail_camp_keep_clear_ships_on() -> void:
	var zones: Array = _json("res://data/config/combat.json").arena.wild_keep_clear
	assert_eq(zones.size(), 2, "the practice zone and the trail camp zone")
	assert_false(zones[0].has("enabled"), "the Practice Meadow zone keeps its default (on)")
	var camp: Dictionary = zones[1]
	assert_eq(str(camp.id), "trail_camp_1104", "the camp zone is named")
	assert_true(bool(camp.enabled), "the trail camp zone ships ON (judged gain)")
	assert_true(str(camp._why_on).contains("CPU 5.61 -> 5.81"), "records its score")
	assert_between(float(camp.radius_m), 6.0, 20.0, "covers the 5.2 m camp floor plus wander room")
	var director := FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	assert_true(director.contains("if not bool((raw as Dictionary).get(\"enabled\", true)):\n\t\t\tcontinue"),
		"a zone with enabled false is skipped")


## F39#23 P2-114: the capture ring outline ships OFF; the reticle reads it from
## the same readout visual config as the readout outline and plate.
func test_f39_23_ring_outline_ships_off() -> void:
	var cfg := _json("res://data/config/capture_readout_visual.json")
	var ring: Dictionary = cfg.ring_outline_1104
	assert_false(bool(ring.enabled), "ring outline ships OFF until judged")
	assert_eq(str(ring.scope), "client_presentation", "declares its scope")
	assert_between(float(ring.width_scale), 1.0, 2.0, "thickens the arcs modestly")
	var reticle := FileAccess.get_file_as_string("res://scripts/ui/capture_reticle.gd")
	assert_true(reticle.contains("_readout_visual.get(\"ring_outline_1104\", {})"), "the reticle reads the flag")
