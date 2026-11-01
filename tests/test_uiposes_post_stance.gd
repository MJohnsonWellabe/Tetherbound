extends "res://tests/test_case.gd"

## P2-050 UIPOSES candidate: npc_post_stances ships OFF; each named post has a
## distinct stance made of known rig bones.

const STANCE := preload("res://scripts/characters/post_stance.gd")
const BONES := ["Hips", "Spine", "Spine01", "Spine02", "LeftArm", "LeftForeArm", "RightArm", "RightForeArm", "Head", "neck"]


func test_ships_off() -> void:
	assert_false(bool(STANCE.config().get("enabled", true)))
	assert_true(STANCE.stance_for("Oskar").is_empty())


func test_named_posts_have_distinct_stances_on_known_bones() -> void:
	var cfg := STANCE.config().duplicate(true)
	cfg.enabled = true
	var seen := {}
	for name: String in ["Oskar", "Halda", "Lark"]:
		var rows := STANCE.stance_for(name, cfg)
		assert_false(rows.is_empty(), "%s has a stance" % name)
		for row: Array in rows:
			assert_true(str(row[0]) in BONES, "%s uses a rig bone (%s)" % [name, row[0]])
			assert_eq(row.size(), 4)
		seen[JSON.stringify(rows)] = true
	assert_eq(seen.size(), 3, "three different stances")
	assert_true(STANCE.stance_for("Mira", cfg).is_empty(), "unlisted villagers keep their idle")


func test_beaten_stance_ships_off_and_bows() -> void:
	assert_true(STANCE.beaten_stance().is_empty(), "beaten_trainer_stance defaults OFF")
	var cfg := STANCE.config().duplicate(true)
	cfg.beaten_trainer_stance.enabled = true
	var rows := STANCE.beaten_stance(cfg)
	assert_false(rows.is_empty())
	for row: Array in rows:
		assert_true(float(row[1]) > 0.0, "%s bows forward (+X on this rig)" % row[0])
