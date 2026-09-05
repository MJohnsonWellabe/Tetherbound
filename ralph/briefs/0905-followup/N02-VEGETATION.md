# N02-VEGETATION

**Source:** W05-TREELINE-0904, W18-DENSITY-B4-B5-0904, W20-SMALL-FIXES-0904 reports.

## Why
Three separate lanes each found a real gap in `scripts/world/vegetation.gd` and correctly left
it alone because it was outside their file ownership. All three are concrete and well-specified.

## Owns
`scripts/world/vegetation.gd` (and its own tests/bake) only. Do not touch `meadow_healing.gd`,
`band_pickups.gd`, or any `data/config/bands/*` file except where item 3 below explicitly says
to delete code from `meadow_healing.gd` after moving it.

## Do

**1. `PROP_OFFSET` is undersized (W05).** The constant is `1.3` m, sized (per its own comment)
against "the widest trunk this scatter places (CommonTree at 1.35 scale)" — but that reference
was already stale before today's tree-scale change, and today's change makes it worse: fill
now reaches scale 2.0, heroes reach 2.7, so trunk collision (`collision_radius` × scale) reaches
1.62 m at a hero's top end, and a felled-wood prop pile beside a large harvest-marked tree can
sit inside the trunk. Raise `PROP_OFFSET` to ~1.9 m, or better, derive it from the placement's
own scale rather than a constant (preferred — check whether a per-placement scale is already
available at the call site).

**2. `has_solid_scatter_near` only sees collision (W18).** The site validator used to keep
pickups clear of dense foliage checks only collision batches (trunks, boulders). Non-colliding
scatter — bushes, ferns, tall grass — passes the check and can still visually bury a pickup
(confirmed: a Rare-tier pickup at "the herd bull" site is buried by a shrub covering 86% of it
per a blind judge). Extend the query to also consider non-colliding scatter's visual footprint
(bounding radius from the scatter's own placement data), not just collision shapes. Keep the
function's existing name/signature if other callers (band density lanes) already use it —
check `git grep has_solid_scatter_near` on `origin/main` first and preserve compatibility.

**3. `restore_drained` doesn't exist yet; the healing filter logic is duplicated in the wrong
file (W20).** `meadow_healing.gd::_heal_the_scatter_within()` currently does a per-model
grouping/filtering job that belongs in `vegetation.gd`. Move it: add a new
`vegetation.gd::restore_drained(within: Array = [])` method where an **empty `within` must mean
"no filter" (heal everything), never "no discs" (heal nothing)** — this is the one arithmetic
trap in the refactor, since a chapter-wide `legendary_freed` heal calls this with no discs and
must still work. Implementation shape:
   - In the per-model grouping loop, skip placements outside every disc in `within` (when
     `within` is non-empty) into a `held` dict.
   - Return early with `_drained = held` when nothing matched (partial heal case).
   - At the end, assign `_drained = held` (not `.clear()`), so a partial heal correctly leaves
     the un-healed remainder still marked drained for a future heal.
   - Change `_regrown = _placed - before` to `_regrown += _placed - before` — the existing code
     overwrites this counter instead of accumulating it across repeated partial heals, which is
     a real bug once this is called more than once per session.
   Then delete the partition/filter block from `meadow_healing.gd::_heal_the_scatter_within()`
   and have it call `vegetation.call("restore_drained", discs)` instead (or a direct typed call
   if `meadow_healing.gd` already holds a typed reference — check before using `call()`).

## Verify
- Run the full `vegetation.gd`-adjacent test suite before and after each change (see
  `test_scatter_rules.gd`, `test_veg_corridor.gd`, `test_band_vegetation.gd`,
  `test_scatter_perf_budget.gd` — run `--only=` with all four together).
- For item 3 specifically: write or extend a test that calls `restore_drained` with an empty
  `within` and confirms it heals unconditionally (the exact trap named above), and a test that
  calls it twice with a partial disc set and confirms `_regrown` accumulates rather than resets.
- Re-run `meadow_healing.gd`'s own existing tests after the extraction to confirm the relay
  station drain/heal behaviour (CL-E12) is unchanged in observable behaviour.
- Re-bake `data/scatter/playground` only if item 2's change touches placement data (it should
  not — it's a query-time change, not a placement change; confirm with a bake-freshness test
  run before assuming a re-bake is needed).

## Acceptance
All three fixes land with real red-then-green tests. `restore_drained`'s empty-`within` case is
explicitly tested (this is the trap most likely to silently break the `legendary_freed` heal).
No other lane's owned files are touched.
