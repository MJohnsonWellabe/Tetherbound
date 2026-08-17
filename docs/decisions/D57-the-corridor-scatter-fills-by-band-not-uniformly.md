# D57 — the corridor scatter fills by band, not at one uniform density

## Context

`VEG-CORRIDOR`. The vegetation scatter (`scripts/world/scatter_rules.gd`)
only ever sampled clumps and strays inside the old +-256m test-playground
square. The Meadows became an 8192x2048m corridor (`D50`) with `OW5B`, and
nothing widened the scatter to match — everything past the first ~512m of
the corridor's ~8072m length was correctly-shaped, correctly-baked bare
ground with a handful of authored anchors on it. Content authors working the
first bands in parallel cannot dress anything the terrain has not been given
vegetation to place.

The obvious fix — sample clumps/strays across the corridor's real bounds
instead of the old square — was measured before being shipped, not assumed:
naively widening the sampling rectangle to the full corridor while keeping
every layer's already-tuned density produces roughly 64x the area and,
because this scatter draws a fixed number of clumps per layer rather than a
density, would have to draw roughly 64x the clumps to avoid the corridor
reading as nearly empty. Measured on this container:
`scatter_rules.all_placements()` (the exact call `vegetation.gd::build()`
makes at boot) goes from **26,985 instances / ~17.3s** to **102,192
instances / ~60.9s** at the density this decision actually ships — a ~3.8x
instance count and ~3.5x compute increase, not 64x, because most of the
corridor is deliberately filled far more sparsely than the square. A full,
uniform-density fill was not built at all: extrapolating the same
compute-per-instance cost, 64x the instances would cost on the order of
64/3.8 ≈ 17x this shipped increase in scatter compute alone — on this
container, minutes rather than tens of seconds, and disproportionately worse
on the CI/export environment where a full boot's vegetation phase was
already independently measured at ~45s of a ~188s boot (`PERF2`) before the
corridor existed at all.

## Decision

The corridor fill is **per layer, per band, and additive**:

- Every layer opts in individually via a `corridor_fill` key in
  `data/config/vegetation.json` (absent/empty is a no-op — the same contract
  `verge`, `anchors` and `path_standoff` already use). `path_stones` does not
  opt in: it needs path-following placement (`path_bias`) to read as road
  gravel rather than random stones in a field, which this mechanism does not
  attempt, so it stays square-only until a path-aware version exists.
- A new top-level `corridor_bands` table (five entries, z-ranged, mirroring
  `terrain_playground.json`'s `trail.bands` without importing them — this
  file owns scatter rules, not the spine) each carry a `density_scale`
  (0..1, TUNABLE) that a content lane can raise or lower per band as it
  authors that reach, without touching `scatter_rules.gd` at all.
- Candidates are drawn proportional to the CORRIDOR's area at each layer's
  own origin-square density (clumps/strays per m²), then kept or dropped by
  the band's `density_scale` before any per-instance placement work runs —
  so a rejected candidate costs one RNG draw, not a wasted heightfield/slope
  sample.
- The fill runs **last**, after clumps, strays, verge and anchors, on the
  same per-layer `RandomNumberGenerator` stream, and a candidate whose centre
  falls inside the old square is dropped outright. Both are load-bearing:
  every draw made before this point stays bit-identical to the shipped
  meadow inside the square (verified directly —
  `tools/_probe_veg_corridor_perf.gd` diffs every existing placement's
  position before/after and prints a mismatch if the append-only property
  ever breaks), and the square's own already-tuned density is never diluted
  by the corridor's own fill.

Shipped default `corridor_bands`: Band 1 (Lower Meadows) and Band 2 (Stone
& Root) — the two bands the owner wants finished first — at `density_scale`
0.07 and 0.05; Bands 3-5 at 0.03, since they are not yet under active
authorship. These are starting points, not a final density: the mechanism
exists so a content lane can raise its own band's number in
`vegetation.json` directly once it has a reason to (a landmark that wants
denser cover, a stretch that reads too bare in a survey frame) without
touching scatter code. Real boot-time headroom exists to raise these: a full
in-engine boot (`tests/smoke_playground.gd`, this container) went from
**56s to 103s** ready-phase (**68.4s to 117.4s** wall including engine
startup and the smoke test's own driven checks) end to end, well under the
`EXP1` 420s export boot allowance.

## What this does not do

- It does not attempt full, square-matching density across the whole
  corridor. That was measured unaffordable (see Context) and is explicitly
  not attempted here — raising it further is each band's own call as it is
  authored, via `corridor_bands`, not a global rewrite.
- It does not touch `playground_world.gd` or `vegetation.gd::build()`'s
  signature. `field.world_bounds()` (`world_extent.gd`'s existing corridor
  bounds, already used by `map_baker.gd`/`minimap.gd`) is read directly
  inside `scatter_rules.gd`, so the `world_size` parameter both files
  already pass keeps meaning exactly what it always has — the old square,
  now understood as "the origin band's own tuned density," not the whole
  world.
- It does not give `path_stones` corridor coverage. A path-following fill is
  future work if the road itself needs a stone accent past the square.

## Verification

`tests/test_veg_corridor.gd`: a real-config placement-extent test that fails
if the fill is disabled (demonstrated failing by stripping `corridor_fill`
from the live config and re-running — see the test's own header for the
exact counts, since a bare "anything outside the square" check does not
discriminate a real regression from the corridor-wide `verge` fringe already
placing outside the square on `main` independently of this feature), plus
the append-only/no-op contract tests matching `verge`/`anchors`' own
pattern. `tests/test_scatter_rules.gd`'s existing 27 tests pass unchanged.
`tests/smoke_playground.gd` passes with the real scene boot end to end.
