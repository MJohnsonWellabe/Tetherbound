extends "res://tests/test_case.gd"

## BEINGS-THUNDERTUNNEL-FAINT (F36#80): creature_pose_settle.json
## `beings_thundertunnel_scope`, OFF until GPU-judged. When on, the settle runs
## for Thundertunnel with a forced belly-down crumple so the faint does not end
## as a faceless rolled ball.

const SETTLE := preload("res://scripts/creatures/creature_pose_settle.gd")
const CONFIG := "res://data/config/creature_pose_settle.json"


func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG))


func test_scope_is_off_and_thundertunnel_only() -> void:
	var scope: Dictionary = _cfg().get("beings_thundertunnel_scope", {})
	assert_false(scope.is_empty(), "the scope exists")
	assert_false(bool(scope.get("enabled", true)), "it is OFF until GPU-judged")
	assert_eq(scope.get("species", []), ["thundertunnel"])
	assert_true(str(scope.get("scope", "")).contains("no state"), "presentation-only scope")


func test_off_the_settle_does_not_reach_thundertunnel() -> void:
	var cfg := _cfg()
	var scoped := SETTLE.scoped(cfg)
	var reached: Array = []
	for key: Variant in cfg:
		var block: Variant = cfg[key]
		if str(key).ends_with("_scope") and block is Dictionary and bool((block as Dictionary).get("enabled", false)):
			reached.append_array((block as Dictionary).get("species", []))
	assert_false("thundertunnel" in reached, "no enabled scope lists Thundertunnel")
	assert_false(bool(cfg.get("enabled", false)), "the roster-wide master stays OFF")
	assert_true(scoped is Dictionary)


func test_its_row_forces_the_crumple() -> void:
	var row: Dictionary = SETTLE._for_species(_cfg(), "thundertunnel")
	var crumple: Dictionary = (row.get("faint", {}) as Dictionary).get("crumple", {})
	assert_true(bool(crumple.get("force", false)), "the crumple is forced for Thundertunnel")
	assert_eq(float(crumple.get("tail_relax", 0.0)), 1.0, "the tail eases to rest")
