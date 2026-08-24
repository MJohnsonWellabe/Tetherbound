extends "res://tests/test_case.gd"

## PERF/OP21-01. The single largest measured boot-time cost this task found:
## `vegetation.gd::build()` falls back to computing the corridor's full
## scatter from scratch in pure GDScript (`scatter_rules.all_placements()`)
## whenever `data/scatter/<world>/` is missing or stale, and on the meadows
## corridor that computation is NOT cheap -- measured directly, twice, on
## this box: 58330ms and 59201ms wall time for 129,723 placements (see
## `tools/_probe_veg_corridor_perf.gd`'s own "after" column and the
## `bake_playground_scatter.gd` run this task added, "60389 ms"). That
## number is inflated by this box's own contention (three other Ralph lanes'
## Godot processes were running concurrently both times it was measured --
## see this task's report for the `ps aux` evidence), so treat the absolute
## figure as INFERRED-to-be-large-on-real-hardware, not measured-on-Ally. What
## IS measured cleanly is the *shape*: this whole cost collapses to a 1327ms
## file read (`BAKE.load_all`, same call, same box, same run) once a fresh
## bake exists on disk, a 44x reduction, because the bake was landed at
## SCAT1 but its actual output was never generated and committed --
## `data/scatter/` did not exist anywhere in this tree before this task,
## verified by `git log -- data/scatter` and `git ls-tree -r origin/main`
## both returning nothing.
##
## A single 40-60+ second unyielded main-thread stall during scene `_ready()`
## is a textbook explanation for a scene transition that "never completes"
## (OP21-23) or an input/camera handoff that misses its window (OP21-05) --
## this file's job is to make sure that stall can never silently come back.
## It asserts the CHEAP, MEASURABLE things a missing/stale bake changes
## (freshness, load wall time, placement/model-batch counts from the loaded
## data) rather than re-running the 60-second compute path itself, which
## would make this test the exact cost it exists to prevent.
##
## Per ralph/conventions.md: "an assertion that cannot fail is not a test."
## Every assertion below fails today if the bake this task committed is ever
## deleted, goes stale (a vegetation.json/terrain_playground.json edit with
## no re-bake -- `BAKE.is_fresh()`'s own fingerprint check), or the corridor's
## density silently balloons past a sane multiple of what shipped.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")

const WORLD_NAME := "playground"

## Shipped total the day this test was written: 129,723 (10 layers, 256
## regions -- see `data/scatter/playground/manifest.json`). 2x headroom
## catches an accidental density explosion (e.g. a `corridor_fill.density_scale`
## typo) without failing on ordinary content growth.
##
## RAISED 260,000 -> 900,000 on owner directive (2026-08-24, "land it all"),
## against a measured 789,511 on the consolidated visual sweep. The ceiling was
## doing its job: it caught the jump and refused, and its own message says a
## re-bake is not the fix because "the density change needs a deliberate look
## first". That look happened before this edit rather than after it, and the
## growth is authored, not accidental -- `corridor_fill.density_scale` went
## 1.0 -> 1.6 -> 2.8 across VIS-WORLD and B11, each step with a measured
## rationale and a stated acceptance test (8-12 countable ground-cover clumps
## in the lower half of a player-height frame, against the blind critic's
## measured 0-2), answering the #1 finding of every round of visual critique:
## the near field reads empty. The confusing part is real and worth naming for
## whoever reads this next: vegetation.json carries a
## `_comment_density_scale_ground_layers` saying density is going
## "deliberately DOWN" sitting directly above a value of 2.8. That comment
## belongs to an EARLIER lane that cut 532,886 back down; a later lane raised
## it again and appended its own note beneath. Stacked history, not a typo --
## checked before this ceiling moved, because shipping a density typo to a
## handheld that already freezes is exactly what this guardrail exists to stop.
##
## A ceiling still exists on purpose. 900,000 keeps ~14% headroom over today's
## real number, the same shape of margin the original 260,000 had, so the next
## accidental explosion still fails here rather than on the owner's device.
##
## NOT YET VERIFIED ON DEVICE. 789,511 instances is a MultiMesh batching
## question, not a per-instance one, and this project has now shipped four
## performance fixes measured only in a container (see OP23-01: the one that
## actually mattered was a 837ms map-fog repaint nothing here would have
## caught). `vegetation.json`'s own ground-layer note names this density as
## "the honest first thing to give back if the ROG Ally needs headroom" --
## that is the lever to pull first if the next owner playtest still hitches,
## and BACKLOG.md's SCATTER-BUDGET-REVIEW carries it.
const MAX_SANE_PLACEMENT_COUNT := 900000
## Below this, something is almost certainly missing rather than merely
## sparse -- the base square alone was ~28,186 before corridor_fill.
const MIN_SANE_PLACEMENT_COUNT := 25000

## `BAKE.load_all()` measured at 1327ms on a 4-CPU box with three concurrent
## Godot processes fighting it for CPU (see this test's header). A generous
## multiple of that, not a tight one -- this budget exists to catch "the bake
## silently stopped being used and we're back to computing," which is a
## 40-60x jump, not to police single-digit-millisecond drift on shared CI
## runners.
##
## RAISED 15,000 -> 45,000 alongside the placement ceiling above, same owner
## ruling, and this is the number that actually costs something. Measured
## 15,769ms on this box for the consolidated sweep's bake against the 1,327ms
## the comment above records for the pre-rebuild one -- roughly 12x, of which
## ~5.5x is simply reading 789,511 placements instead of 143,630 and the rest
## is CPU contention. It is a BOOT cost, not a per-frame one: it lands once on
## load, not every few feet, so it is a different and lesser evil than OP23-01's
## map-fog stall. It is still a real 15+ second wait on a dev box, and the Ally
## is slower.
##
## 45,000 is deliberately generous rather than snug to today's number, because
## a tight budget here would fail on CI contention alone and teach the next
## reader to raise it again reflexively. What this assertion is FOR is
## unchanged and still works at 45,000: catching the bake silently falling back
## to `vegetation.gd`'s ~60s compute path, which is the 40-60x jump the header
## describes, not this 12x one.
const MAX_BAKE_LOAD_MS := 45000


func _base_seed() -> int:
	return int(RULES.config().get("seed", 1))


## The regression this whole file exists to guard: a missing or stale bake
## silently falls back to `vegetation.gd`'s ~60s-on-this-box compute path on
## every single load. `BAKE.is_fresh()` is the exact check `vegetation.gd`
## itself gates on, so this asserts the real production condition, not a
## proxy for it.
func test_playground_bake_is_committed_and_fresh() -> void:
	assert_true(BAKE.is_fresh(WORLD_NAME, _base_seed()),
		"data/scatter/playground is missing or stale against the live config " +
		"(vegetation.json / terrain_playground.json) -- every boot will fall " +
		"back to computing the full corridor scatter from scratch, a ~60s " +
		"stall measured on this box. Re-run " +
		"`godot --headless --path . --script scripts/world/bake_playground_scatter.gd` " +
		"and commit the result.")


## Loading the bake is the whole point: it must actually be fast, not merely
## present. A corrupted or absurdly bloated bake file would pass "is_fresh"
## (which only checks the fingerprint) but still stall the boot.
func test_playground_bake_loads_within_budget() -> void:
	var t0 := Time.get_ticks_msec()
	var drained: Dictionary = {}
	var by_layer: Dictionary = BAKE.load_all(WORLD_NAME, drained)
	var elapsed := Time.get_ticks_msec() - t0

	assert_true(elapsed <= MAX_BAKE_LOAD_MS,
		"BAKE.load_all() took %dms, over the %dms budget -- the bake exists " % [elapsed, MAX_BAKE_LOAD_MS] +
		"but reading it is no longer cheap, which defeats the point of baking it")

	var total := 0
	for layer_name: String in by_layer.keys():
		total += (by_layer[layer_name] as Array).size()

	assert_true(total >= MIN_SANE_PLACEMENT_COUNT,
		"bake loaded only %d placements, below the %d floor -- looks like a partial or truncated bake" % [
			total, MIN_SANE_PLACEMENT_COUNT])
	assert_true(total <= MAX_SANE_PLACEMENT_COUNT,
		"bake loaded %d placements, over the %d ceiling -- a config edit made the corridor's scatter density explode; " % [
			total, MAX_SANE_PLACEMENT_COUNT] +
		"re-bake is not the fix here, the density change needs a deliberate look first")


## `vegetation.gd::build()` groups placements by MODEL (not by layer) before
## registering Terrain3DMeshAsset ids and calling `add_transforms` -- one
## call per unique model is the whole draw-call-count win the file's own
## header describes. This counts unique models directly from the loaded
## bake, which is what `by_model.keys().size()` would be in `build()`
## without needing a live Terrain3D node (this suite runs under `--headless`,
## the Dummy rendering driver -- see `tools/diag_scene_perf.gd`'s header for
## why nothing here can go through a real Terrain3DInstancer).
func test_scatter_batch_count_stays_bounded() -> void:
	var drained: Dictionary = {}
	var by_layer: Dictionary = BAKE.load_all(WORLD_NAME, drained)
	var models: Dictionary = {}
	for layer_name: String in by_layer.keys():
		for entry: Variant in (by_layer[layer_name] as Array):
			models[str((entry as Dictionary)["model"])] = true

	# 42 unique models shipped at the time this test was written
	# (`vegetation.gd`'s own header: "42 today"). One `add_transforms` call
	# per model at boot, plus one `set_mesh_list` registration -- headroom to
	# 80 catches a regression back toward "a mesh id per layer instead of per
	# shared model" without blocking ordinary new-species content work.
	assert_true(models.size() > 0, "no models found in the baked scatter at all")
	assert_true(models.size() <= 80,
		"baked scatter now spans %d unique models (was ~42) -- each is a separate " % models.size() +
		"Terrain3DMeshAsset registration and add_transforms() call at boot; if this grew " +
		"legitimately, raise the budget deliberately rather than let it drift")
