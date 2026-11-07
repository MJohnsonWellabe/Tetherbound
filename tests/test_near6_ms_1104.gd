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


## F39#23 P2-114: the capture ring style ships ON (judged gain); the reticle reads it from
## the same readout visual config as the readout outline and plate.
func test_f39_23_ring_style_ships_on() -> void:
	var cfg := _json("res://data/config/capture_readout_visual.json")
	var ring: Dictionary = cfg.ring_style_1104
	assert_true(bool(ring.enabled), "ring style ships ON (judged gain)")
	assert_true(str(ring._why_on).contains("CPU 5.26 -> 5.62"), "records its score")
	assert_eq(str(ring.scope), "client_presentation", "declares its scope")
	assert_between(float(ring.alpha_scale), 0.2, 1.0, "the ring stays visible")
	assert_between(float(ring.width_scale), 0.4, 1.0, "a thinner ring, never a bolder one (round 1 lost)")
	var reticle := FileAccess.get_file_as_string("res://scripts/ui/capture_reticle.gd")
	assert_true(reticle.contains("_readout_visual.get(\"ring_style_1104\", {})"), "the reticle reads the flag")


## F38#4 P2-002: the Meadows unsurveyed map fog takes warm parchment tones
## (judged gain); other chapters keep their own tones.
func test_f38_4_meadows_parchment_fog_ships_on() -> void:
	var cloud: Dictionary = _json("res://data/config/map.json").fog_veil.cloud_fog
	assert_true(bool(cloud.enabled), "cloud fog stays on")
	assert_true(str(cloud._why_meadows_parchment_1104).contains("CPU 6.15 -> 7.18"), "records its score")
	assert_eq(cloud.tones.meadows, ["#8c8266", "#cfc3a0"], "Meadows fog is parchment, not slate")
	for tone: String in cloud.tones.meadows:
		var c := Color(tone)
		assert_true(c.r >= c.b, "a warm tone, never a cold storm grey (%s)" % tone)
		assert_false(c.r > 0.5 and c.g < 0.3 and c.b < 0.3, "no red or oxblood (%s)" % tone)


## F38#9 P2-001: the satchel focus emphasis ships ON (judged gain) and the
## Satchel tab reads it.
func test_f38_9_satchel_focus_ships_on() -> void:
	var focus: Dictionary = _json("res://data/config/menu.json").satchel_focus
	assert_true(bool(focus.enabled), "satchel focus ships ON (judged gain)")
	assert_true(str(focus._why_on).contains("CPU 7.13 -> 7.36"), "records its score")
	assert_between(float(focus.preview_icon_px), 112.0, 200.0, "the focused icon grows, within the panel")
	var backpack := preload("res://scripts/ui/tab_backpack.gd")
	assert_false(backpack.satchel_focus().is_empty(), "the Satchel tab sees the flag on")


## F38#4 P2-002 round 2: the inked chart grid and north mark ship ON (judged
## gain), on Meadows and Tidewake, and reveal no terrain (drawn as lines, never a texture).
func test_f38_4_chart_grid_ships_on() -> void:
	var grid: Dictionary = _json("res://data/config/map.json").fog_veil.chart_grid_1104
	assert_true(bool(grid.enabled), "chart grid ships ON (judged gain)")
	assert_true(str(grid._why_on).contains("CPU 6.81 -> 6.93"), "records its score")
	assert_eq(str(grid.scope), "client_presentation", "declares its scope")
	# F39#25 r25b (LANE-TW, 7 Nov): the grid also ships on Tidewake (judged gain).
	assert_eq(grid.realms, ["meadows", "water"], "Meadows and Tidewake")
	assert_between(float(grid.alpha), 0.05, 0.4, "a faint ink, not a cage over the map")
	var ink := Color(str(grid.ink))
	assert_false(ink.r > 0.5 and ink.g < 0.3 and ink.b < 0.3, "no red or oxblood ink")
	var tab := FileAccess.get_file_as_string("res://scripts/ui/tab_map.gd")
	assert_true(tab.contains("veil.get(\"chart_grid_1104\", {})"), "the map tab reads the flag")


## F38#7 P2-058: during a catch aim, an ally that hides the target is hidden
## outright instead of drawn as the occlusion dither ghost (judged gain).
func test_f38_7_aim_hide_ships_on() -> void:
	var fade: Dictionary = _json("res://data/config/combat.json").camera.occlusion_fade
	var block: Dictionary = fade.aim_hide_1104
	assert_true(bool(block.enabled), "aim hide ships ON (judged gain)")
	assert_true(str(block._why_on).contains("CPU 5.93 -> 7.00"), "records its score")
	assert_eq(str(block.scope), "client_presentation", "declares its scope")
	assert_between(float(block.hold_s), 0.0, 1.0, "a short hold, not a lingering hide")
	var manager := FileAccess.get_file_as_string("res://scripts/combat/combat_manager.gd")
	assert_true(manager.contains("cfg.get(\"aim_hide_1104\", {})"), "the fight reads the flag")
	assert_true(manager.contains("and is_aiming() and"), "only while a catch is being aimed")
	assert_true(manager.contains("func _clear_ally_fade() -> void:\n\t_set_ally_aim_hidden(null, false)"),
		"clearing the fade always restores a hidden ally")


## F38#21 P2-005: Meadows flower drifts and stone breaks (judged gain), merged
## into the ON ground candidate.
func test_f38_21_flower_drifts_ship_on() -> void:
	var cand: Dictionary = _json("res://data/config/grass_field.json").meadows_ground_candidate
	assert_true(bool(cand.enabled), "the Meadows ground candidate stays ON")
	assert_true(str(cand._why_drifts_1105).contains("CPU 6.11 -> 6.23"), "records its score")
	var lilac: Dictionary = cand.tiers.flowers
	var gold: Dictionary = cand.tiers.flowers_gold
	assert_true(float(lilac.patch_start) < float(lilac.patch_full), "lilac drifts have a soft edge")
	assert_true(float(gold.patch_start) < float(gold.patch_full), "gold drifts have a soft edge")
	assert_true(float(lilac.drift_contrast) > 1.0 and float(gold.drift_contrast) > 1.0, "flowers cluster into drifts")
	var stones: Dictionary = cand.merge.stones
	assert_true(bool(stones.enabled), "stone breaks stay on")
	assert_between(float(stones.stone_size), 0.1, 0.3, "field stones, not boulders")
	var shipped: Dictionary = _json("res://data/config/grass_field.json").stones
	for key: String in shipped:
		assert_true(stones.has(key), "the candidate stones block is complete (%s)" % key)
