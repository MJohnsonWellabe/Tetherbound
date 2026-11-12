extends "res://tests/test_case.gd"

## T1 faint grounding (LANE-THINGS, 12 Nov 2026; G-things-faint.md): pins the
## shipped `things_faint_scope`, its exclusions and the per-species overrides
## of creature_pose_settle.json, and the per-species merge itself.

const SETTLE := preload("res://scripts/creatures/creature_pose_settle.gd")


func _shipped() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SETTLE.PATH))


func test_scope_ships_on_for_the_judged_species_without_fulgocobra() -> void:
	var cfg := _shipped()
	var scope: Dictionary = cfg.get("things_faint_scope", {})
	assert_true(bool(scope.get("enabled", false)), "the judged faint scope ships ON")
	assert_eq(scope.get("species", []), ["mirejaw", "abyssal_guardian", "mangrove_monitor", "cragclaw", "cannonback"])
	assert_false(bool(cfg.get("enabled", true)), "the roster-wide master stays OFF")
	var live: Dictionary = SETTLE.scoped(cfg)
	for id: String in ["mirejaw", "water_mirejaw", "abyssal_guardian", "cragclaw", "water_cragclaw", "cannonback", "mangrove_monitor"]:
		assert_false(SETTLE.excluded(live, id), "%s takes the settle" % id)
	for id: String in ["fulgocobra", "water_abyssal_guardian", "glimmermoth", "terrapup"]:
		assert_true(SETTLE.excluded(live, id), "%s keeps its own faint" % id)


func test_per_species_row_changes_only_that_species() -> void:
	var cfg := _shipped()
	var rows: Dictionary = (cfg.get("faint", {}) as Dictionary).get("per_species", {})
	assert_eq(float(((rows.get("water_mirejaw", {}) as Dictionary).get("crumple", {}) as Dictionary).get("tail_relax", 0.0)), 1.0)
	var water: Dictionary = SETTLE._for_species(cfg, "water_mirejaw")
	assert_eq(float(water.faint.crumple.tail_relax), 1.0, "water mirejaw's tail eases to rest")
	assert_eq(float(water.faint.crumple.splay_deg), float(cfg.faint.crumple.splay_deg), "other crumple keys are kept")
	var land: Dictionary = SETTLE._for_species(cfg, "mirejaw")
	assert_false((land.faint.crumple as Dictionary).has("tail_relax"), "an exact water id does not reach the land form")
	assert_false((cfg.faint.crumple as Dictionary).has("tail_relax"), "the shared block is not edited")


func test_base_id_row_reaches_the_water_form_and_exact_id_wins() -> void:
	var cfg := {"faint": {"crumple": {"splay_deg": 55.0}, "per_species": {
		"cragclaw": {"crumple": {"splay_deg": 10.0}},
		"water_cragclaw": {"crumple": {"splay_deg": 20.0}}}}}
	assert_eq(float(SETTLE._for_species(cfg, "cragclaw").faint.crumple.splay_deg), 10.0)
	assert_eq(float(SETTLE._for_species(cfg, "water_cragclaw").faint.crumple.splay_deg), 20.0)
	(cfg.faint.per_species as Dictionary).erase("water_cragclaw")
	assert_eq(float(SETTLE._for_species(cfg, "water_cragclaw").faint.crumple.splay_deg), 10.0)
	assert_eq(float(SETTLE._for_species(cfg, "terrapup").faint.crumple.splay_deg), 55.0)


## Round 2 (G-things-faint2.md): the species the judges preferred take the
## forced belly-down crumple; the four that lost keep their own faint.
func test_round_two_scope_ships_the_winners_and_not_the_losers() -> void:
	var cfg := _shipped()
	var scope: Dictionary = cfg.get("things_faint2_scope", {})
	assert_true(bool(scope.get("enabled", false)))
	assert_eq(scope.get("species", []), ["pebbik", "breezetail", "shadelet", "paddlenewt", "riftfrill", "mosshock", "stormraven"])
	var live: Dictionary = SETTLE.scoped(cfg)
	for id: String in (scope.get("species", []) as Array) + ["water_mangrove_monitor"]:
		assert_false(SETTLE.excluded(live, id), "%s takes the settle" % id)
		var crumple: Dictionary = SETTLE._for_species(cfg, id).faint.crumple
		assert_true(bool(crumple.get("force", false)), "%s crumples belly-down" % id)
		assert_eq(float(crumple.get("tail_relax", 0.0)), 1.0)
	for id: String in ["stormtrail", "trailpup", "voltwig", "sparkit"]:
		assert_true(SETTLE.excluded(live, id), "%s lost on the GPU and keeps its side-lying faint" % id)
	assert_false(bool(SETTLE._for_species(cfg, "cragclaw").faint.crumple.get("keep_head_up", false)), "cragclaw's head change was level and is not shipped")
	assert_false(bool(SETTLE._for_species(cfg, "mangrove_monitor").faint.crumple.get("force", false)), "the land monitor keeps round 1's settle")
