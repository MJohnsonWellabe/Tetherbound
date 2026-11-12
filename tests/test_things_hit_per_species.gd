extends "res://tests/test_case.gd"

## F36#33 Ashtusk close-out (LANE-THINGS, 12 Nov 2026): hit.per_species rows of
## creature_pose_settle.json and the `things_hit_scope` that brings Ashtusk
## into the settle for its hit only.

const SETTLE := preload("res://scripts/creatures/creature_pose_settle.gd")


func _shipped() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SETTLE.PATH))


func test_hit_row_merges_for_that_species_only() -> void:
	var cfg := _shipped()
	var ash: Dictionary = (SETTLE._hit_for_species(cfg, "ashtusk")["hit"] as Dictionary)["recoil"]
	assert_true(bool(ash.get("force", false)), "Ashtusk's recoil is forced")
	assert_almost_eq(float(ash.get("pitch_deg", 0.0)), 12.0, 0.001, "nose-up through the hit")
	var other: Dictionary = (SETTLE._hit_for_species(cfg, "mirejaw")["hit"] as Dictionary)["recoil"]
	assert_false(bool(other.get("force", false)), "other species keep the roster recoil")
	assert_almost_eq(float(other.get("pitch_deg", 0.0)), 7.0, 0.001)


func test_ashtusk_faint_stays_the_games_clip() -> void:
	var cfg := _shipped().duplicate(true)
	cfg["enabled"] = true
	var merged: Dictionary = SETTLE._for_species(cfg, "ashtusk")
	for part: String in ["grounded", "side_lie", "crumple", "head_lift"]:
		assert_true(SETTLE._section(merged, "faint", part).is_empty(), "faint.%s is off for Ashtusk" % part)


func test_scope_is_declared_for_ashtusk() -> void:
	var scope: Dictionary = _shipped().get("things_hit_scope", {})
	assert_true(bool(scope.get("enabled", false)), "ships ON (G-things-creature-closeout)")
	assert_eq(scope.get("species", []), ["ashtusk"])


func test_settle_now_reaches_ashtusk_and_no_new_species() -> void:
	var live: Dictionary = SETTLE.scoped(_shipped())
	assert_false(SETTLE.excluded(live, "ashtusk"), "Ashtusk takes the hit settle")
	for id: String in ["tuskroot", "stormtrail", "terrapup"]:
		assert_true(SETTLE.excluded(live, id), "%s is untouched" % id)
