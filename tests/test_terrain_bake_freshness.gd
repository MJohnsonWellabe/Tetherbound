extends "res://tests/test_case.gd"

## HARNESS-HYGIENE-0903, task 1.5's terrain half. `data/scatter/playground`
## has had a fingerprint freshness guard since GATE-D
## (`scripts/world/scatter_bake.gd`, `test_scatter_perf_budget.gd::
## test_playground_bake_is_committed_and_fresh`); `data/terrain/playground`
## had none. `data/config/terrain_playground.json` was edited during the
## 2026-09-02 repository reset (doc-path text in several `_comment`/`_why`
## strings) with no re-bake, and nothing on disk or in CI could have caught
## that the committed `.res` files might no longer match the config that is
## supposed to describe them.
##
## `scripts/world/terrain_bake.gd` is the guard this file exercises: a
## fingerprint of `terrain_playground.json` stamped into `data/terrain/
## playground/manifest.json` at bake time, and `is_terrain_bake_fresh()`
## compares the two. Per docs/AGENT_WORKFLOW.md: "an assertion that cannot
## fail is not a test" -- the second test below proves the fingerprint
## actually moves when the config's bytes change, the same way
## `test_scatter_fingerprint_covers_bands.gd` proves it for the scatter bake.

const TERRAIN_BAKE := preload("res://scripts/world/terrain_bake.gd")
const CONFIG_PATH := "res://data/config/terrain_playground.json"


## The regression this file exists to guard: a config edit with no re-bake
## must be loud, not silent. See this task's own completion report for
## whether `data/terrain/playground` currently passes this -- it may not,
## and re-baking to force a pass is a separate, deliberate decision, not a
## side effect of adding the check.
func test_playground_terrain_bake_is_committed_and_fresh() -> void:
	assert_true(TERRAIN_BAKE.is_terrain_bake_fresh(),
		"data/terrain/playground has no manifest, or is stale against the live " +
		"data/config/terrain_playground.json -- the committed Terrain3D region " +
		"data may not match the config that is supposed to describe it. Re-run " +
		"`godot --headless --path . --script scripts/world/build_playground_terrain.gd` " +
		"and commit the result (including the region files AND manifest.json).")


## The load-bearing property: perturb the real config on disk, take the
## fingerprint again, restore the file, and assert the number moved. Writes
## to the real file rather than a fixture for the same reason
## `test_scatter_fingerprint_covers_bands.gd` does -- the fingerprint hashes
## the real path the game reads, and a fixture copy would prove nothing about
## it. Original bytes are captured first and written back in the same call,
## and the test asserts the restore succeeded so a failure here cannot leave
## the repo dirty without saying so.
func test_fingerprint_moves_when_the_config_changes() -> void:
	var original := FileAccess.get_file_as_string(CONFIG_PATH)
	assert_ne(original, "", "%s is empty or unreadable; this test needs the real config" % CONFIG_PATH)

	var before := TERRAIN_BAKE.config_fingerprint()

	var perturbed := original + "\n"
	assert_ne(perturbed, original, "could not perturb %s" % CONFIG_PATH)

	var writer := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	assert_true(writer != null, "cannot open %s for writing" % CONFIG_PATH)
	writer.store_string(perturbed)
	writer.close()

	var after := TERRAIN_BAKE.config_fingerprint()

	var restore := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	assert_true(restore != null, "cannot reopen %s to restore it" % CONFIG_PATH)
	restore.store_string(original)
	restore.close()
	assert_eq(FileAccess.get_file_as_string(CONFIG_PATH), original,
		"failed to restore %s; the working tree is now dirty" % CONFIG_PATH)

	assert_ne(after, before,
		"editing terrain_playground.json did not move the terrain bake fingerprint, " +
		"so a stale bake against a changed config would be served as fresh")


## A world with no manifest at all (never baked with this guard) must read as
## NOT fresh, never as vacuously fresh -- the same "absent means untrusted"
## contract `scatter_bake.gd::is_fresh()` documents on itself.
func test_missing_manifest_is_not_fresh() -> void:
	assert_false(TERRAIN_BAKE.is_terrain_bake_fresh("res://data/terrain/__no_such_world__"),
		"a data directory with no manifest.json must not read as fresh")
