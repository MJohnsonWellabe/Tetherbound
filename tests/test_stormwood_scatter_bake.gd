extends "res://tests/test_case.gd"

## Stormwood fails closed instead of computing a missing/stale bake during a
## playable load. Pin the exact production freshness decision so an edit to any
## authored scatter input cannot ship without its corresponding official bake.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")


func test_stormwood_scatter_bake_is_committed_and_fresh() -> void:
	var seed := int(SCATTER.config().get("seed", 1))
	var fingerprint := int(SCATTER.fingerprint())
	assert_true(BAKE.is_fresh("stormwood", seed, fingerprint),
		"data/scatter/stormwood is missing or stale against Stormwood's live " +
		"scatter inputs; production refuses to build vegetation. Re-run " +
		"`godot --headless --path . --script scripts/world/bake_stormwood_scatter.gd` " +
		"and commit the generated manifest and every changed region file.")
