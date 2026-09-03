# OWNER-0902-LOAD-TIME — "the game took forever to load," root-caused

`branch: ralph/OWNER-0902-LOAD-TIME` · `owner report: ralph/OWNER_PLAYTEST_2026-09-02.md`
finding #2, "The game took forever to load." · `harness: tools/_probe_scatter_load_cost.gd`,
`tools/_probe_veg_boot_phases.gd` (both pre-existing, from the `GF-B-001`/`STALL-2`
investigation lineage)

## Which "load" this is

Three candidate meanings were named in the dispatch: boot-to-menu, menu-to-world,
and save-load. Only one measures large in this codebase and matches "forever":
**menu-to-world — pressing New Game (or loading a save) stands up
`meadows_playground.tscn`, and that world's own vegetation scatter build is the
cost.** Boot-to-menu is cheap and already covered (`smoke_title_load_game`,
`HIST-085`'s title-screen half, closed). Save-load reaches the same
`vegetation.gd::build()` path as New Game, so it is not a separate cost — same
finding, same fix.

## What's actually slow, measured

`vegetation.gd::build()` has two paths for computing the scatter's placements:
read a pre-baked file off disk (`scatter_bake.gd`, fast), or recompute them live
from `scatter_rules.all_placements()` (slow — this is the exact cost `GF-B-001`
named as CPU, GPU-independent, "the missing scatter bake"). Which path runs is
decided by `scatter_bake.is_fresh()`, which hashes `vegetation.json`,
`terrain_playground.json` and the per-band vegetation configs and compares
against the fingerprint stamped into `data/scatter/playground/manifest.json` at
bake time. `data/config/vegetation.json` was last edited **2026-09-01 22:37:05**
(`0c297552`, `VISUAL-FLOWER-SCALE` — a four-line per-model scale override, unrelated
to performance) but the committed bake on `main` predates it, last written
**2026-08-31 23:33:59** (`9f06bc4d`). Nothing in `ci.yml` or the Ralph landing
process re-runs the offline bake automatically when a config file it covers
changes — `bake_playground_scatter.gd`'s own header says as much ("re-run
after editing..."), and this lane is the first time nobody did.

Confirmed directly: `tools/_probe_scatter_load_cost.gd` calls
`scatter_bake.is_fresh("playground", 20260803)` before doing anything else and
refuses to proceed if it's false, specifically so a run against a stale bake
can't be mistaken for a real measurement.

```
is_fresh(playground, seed 20260803) = false   [2 ms]
the bake is STALE -- `vegetation.gd` would recompute...
```

So on `main` right now, every New Game / load pays the full live-compute cost,
not the disk-read cost — and the world has grown a great deal since the last
time anyone measured that live path in this codebase's own comments (23,707
placements in `vegetation.gd`'s header prose; **812,433** placements today,
a ~34x growth the header text was never updated to reflect).

### Before/after, this container (`tools/_probe_veg_boot_phases.gd`, headless,
loads `meadows_playground.tscn` and settles 60 physics frames — no GPU
involved, matching `GF-B-001`'s finding that this cost is CPU-only)

| | placements phase | total wall time to first settled frame |
|---|---|---|
| **before** (stale bake, live recompute) | **256,643 ms** (256.6 s) | **302,453 ms** (~5.0 min) |
| **after** (bake re-run, fresh) | **6,915 ms** (6.9 s) | **47,251 ms** (47.3 s) |

**37x** on the placements phase alone, **6.4x** end to end. The remaining ~47s
matches the previously-recorded `GF-B-001` baseline (one ~49–51s blocking frame,
also headless/CPU, also this same world-stand-up path) — this fix restores the
already-known, already-accepted boot cost rather than introducing anything new.
That remaining cost is real and un-fixed (a genuine architectural item —
`docs/PERFORMANCE_BUDGET.md`/`GF-B-001` already scoped it and it is out of this
lane's size), but it is a different, much smaller problem than the one the
owner hit.

This container has no GPU (`ralph/conventions.md`); nothing here is a ROG Ally
frame time. But the cost measured is explicitly the CPU placement-compute path
GPU hardware cannot help with, so the structural fix (serve the bake instead of
recomputing) is real regardless of what device runs it.

## The fix

Re-ran the offline bake (`godot --headless --path . --script
scripts/world/bake_playground_scatter.gd`) against the current, current-on-`main`
config. This is exactly the documented, existing, zero-risk recovery path
(`scatter_bake.gd`'s own header: "a bake against an older config is a staleness
class... it must be loud rather than silently served" — it was loud, here, and
this is the loud path's answer). Output:

```
computed 812433 placements (2933 drained) across 11 layers in 258351 ms
baked -> data/scatter/playground (256 regions, 29327205 bytes, 36.0 bytes/placement)
```

`data/scatter/playground/manifest.json` and all 256 `region_*.bin` files are
regenerated data, committed as-is — no code changed. `tools/_probe_scatter_load_cost.gd`
now reports `is_fresh(...) = true` and a **2.4–6.5s** load (its own self-check,
`_skipping_reads_the_same_layers`, also passed: the skip-path and full-read path
agree element-for-element).

## What this does NOT fix, on purpose

**The process gap that let this happen again.** Nothing currently re-bakes
scatter automatically when `vegetation.json`/`terrain_playground.json`/band
vegetation configs change, so any future landing that edits those files
(exactly what `VISUAL-FLOWER-SCALE` did) reintroduces this same multi-minute
regression silently — `is_fresh()` fails loud in a probe built to check for
it, but nothing in the ordinary Ralph landing path runs that probe or the
bake. That is a process/CI fix (e.g. a `changes` filter step that re-bakes and
commits when those paths move, or a CI check that fails a PR when the bake is
stale), not a data regeneration, and is out of this lane's scope — recommend
whoever owns the Ralph landing pipeline pick it up as its own task so this
doesn't recur on the next config-touching visual lane.

## Verification

- `tools/_probe_scatter_load_cost.gd`: fresh, 2.4–6.5s load, self-check passed
  (skip-path == full-read path, element-for-element).
- `tools/_probe_veg_boot_phases.gd`: 47,251 ms to first settled frame (was
  302,453 ms).
- `godot --headless --path . --script tests/run_tests.gd -- --only=scatter,vegetation,scatter_bake,scatter_perf_budget`
  — 38 tests, 968,797 assertions, 0 failed.

## Reproducing

```
GODOT=/root/.cache/tetherbound-art/godot   # tools/art_pipeline/setup.sh godot fetches this fresh in a new container
$GODOT --headless --path . --import       # required once; this container has no .godot/ cache

# confirm staleness / freshness
$GODOT --headless --path . --script tools/_probe_scatter_load_cost.gd

# re-bake (this is the fix; costs ~258s once, offline, same box)
$GODOT --headless --path . --script scripts/world/bake_playground_scatter.gd

# before/after world-stand-up timing
$GODOT --headless --path . --script tools/_probe_veg_boot_phases.gd
```
