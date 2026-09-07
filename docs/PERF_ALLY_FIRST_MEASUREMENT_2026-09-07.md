# The first real ROG Ally frame times, and what they say

**Source:** owner kickoff run `20260907T023802Z`, branch `owner-run/20260907T023802Z`,
machine MATTSALLY, repo sha `75bb1dc7`. Files: `ralph/reports/OWNER-KICKOFF-20260907T023802Z/`
(`fps.json`, `perf_render_stats.txt`).
**Status:** measurement and analysis. No tuning done. Nothing here is a decision.

---

## 1. Why this run matters

`docs/specs/PERFORMANCE_BUDGET.md` says outright, twice, that it is **not** a
frame-rate guarantee and that "no container in this project has ROG Ally
hardware; nothing above is a frame-rate claim." Every number the project has
budgeted against until now — draw calls, primitives, objects — is a *structural
proxy*, chosen because it was the only thing measurable in a container.

This run is the first time the game has been profiled on the target device.
The proxy can now be checked against the thing it was standing in for.

## 2. The frame times

`tools/_owner_fps_probe.gd`, 20 s per site, AMD Radeon iGPU, grass field **on**,
2053x1080.

| site | fps avg | 1% low | frame ms avg | draw calls | primitives |
|---|---|---|---|---|---|
| band2_quarry_eye | 6.4 | 5.3 | 155.9 | 2,439 | 7.67 M |
| band1_open | 6.6 | 6.3 | 152.0 | 7,328 | 11.67 M |
| village_high | 6.8 | 5.9 | — | 3,424 | 8.14 M |
| village_square_eye | 7.3 | 6.6 | — | 4,557 | 9.59 M |
| pond_pocket_eye | 7.4 | 6.2 | — | 2,453 | 5.74 M |
| band1_open_eye | 7.6 | 6.8 | 132.1 | 2,247 | 7.75 M |
| hall_approach | 10.3 | 9.1 | — | 3,786 | 2.78 M |
| band4_ironwood_eye | 10.5 | 9.0 | — | 2,688 | 7.41 M |
| hall_approach_eye | 11.3 | 10.6 | — | 4,207 | 3.79 M |

Six of nine sites are **under 8 fps**. The best is 11.3.

## 3. Draw calls do not predict the frame rate here

This is the finding, and it is the opposite of what the project has been
optimising against.

- The **fastest** site, `hall_approach_eye` at 11.3 fps, has the **second-most
  draw calls** (4,207).
- The **slowest** site, `band2_quarry_eye` at 6.4 fps, has nearly the **fewest**
  (2,439).
- `band1_open_eye` (2,247 draws) and `band1_open` (7,328 draws) are the same
  place from two heights and differ by 1.0 fps — a 3.3x difference in draw
  calls buying a 15 % difference in frame time.

Across these nine points the relationship between draw calls and fps is flat to
slightly inverted. **Whatever is costing 150 ms a frame, it is not the number
of draw calls.**

Primitives correlate better — the two `hall_approach` sites carry the lowest
primitive counts (2.78 M, 3.79 M) and are the two fastest — but the fit breaks
on `band4_ironwood_eye`, which runs 10.5 fps at 7.41 M primitives, as fast as
the hall sites at twice their geometry.

## 4. What the fast sites have in common

The three fastest sites are the two Hall approaches and Ironwood. The six
slowest are open meadow, village and quarry. The clean split is not geometry
count and not draw calls: it is **how much of the frame is open ground carrying
the grass field**.

From the same run's boot log at `band1_open`:

```
grass ring:  62,140 instances over 13 lattice layers, 24m cull tiles
stone ring:   6,084 instances over  8 lattice layers
cover tiers:  4,876 + 4,876 + 6,008 instances over 4 + 4 + 3 layers
far cover:    1 sheet, 71,200 tris, 6m cell, 40-640m reach
```

That is a large amount of alpha-tested foliage covering most of the screen, at
2053x1080, on an integrated GPU. Fill rate and overdraw are the textbook cost
of exactly that, they are invisible to every counter in the budget document,
and they would explain why an enclosed fortress approach runs twice as fast as
an open field with a third of the draw calls.

**This is a hypothesis, not a result.** Nine data points, no per-pass timing, no
GPU capture. It is the most probable explanation of the split, and it is cheap
to test.

## 5. The one measurement that would settle it

Re-run `tools/_owner_fps_probe.gd` on the Ally with `grass_field.enabled` false,
then true, at the same nine sites, changing nothing else. One config flag, one
kickoff `-Only perf`, roughly twenty minutes.

- If the six slow sites jump and the three fast ones barely move, it is the
  grass, and the work is grass LOD, density falloff, and reducing overdraw.
- If they barely move, the grass is exonerated, the cost is elsewhere, and the
  next step is a real GPU capture rather than more counter-reading.

Do this before funding any optimisation work. Every lever below is guesswork
until it runs.

## 6. Correcting the record on the budget

Two things in the tree are not what a reader would assume.

**`4000 draw calls` is not a global budget, and `band1_open` is not over it.**
That number is `PERFORMANCE_BUDGET.md` §0.5's build target for the *Hall*, set
for the `T1-HALL-3` lane at the `hall_approach` stand. It was derived by taking
`band1_open` as the corridor's demonstrated worst case (measured then at
5,712–5,929 draws) and giving the finale ~68 % of it. So `band1_open` is the
yardstick, not an offender. Measured this run:

- `hall_approach`: **4,115** against its 4,000 target — 2.9 % over.
- `band1_open`: **6,956** (render-stats probe) / 7,328 (fps probe). A
  `performance.json` comment from the 2026-09-02 WORLD lane records a 7,500
  ceiling for this stand, so it is under that.

What *is* true is drift: the stand the whole budget was calibrated against has
risen from 5,712–5,929 to 6,956 since the document was written, about 20 %. The
budget's own §0.5 flags that its band1 number was taken pre-rebake and never
re-confirmed. It has now been re-confirmed, and it moved.

**Two config flags contradict each other about a third.** `performance.json`
sets `scatter_lod_ranges: false`. But `vegetation.json` carries two comments
(lines 527, 739) asserting "VP3: `scatter_lod_ranges` is now TRUE in
performance.json ... so these ranges are LIVE", and sizes its canopy and
ground-layer ranges on that basis. They are not live. Under the shipped config
every `lod_*` key in `vegetation.json` is inert — which `vegetation.json`'s own
`_comment_lod_range_t1_hall_4` states correctly elsewhere in the same file,
after a lane spent a re-bake and a render round discovering it. Whatever VP3
believed it landed, it did not ship. Someone should reconcile these three
comments; they currently cost every lane that reaches for this lever the same
afternoon.

## 7. Levers that exist and are switched off

Both are written, reasoned and gated to a no-op. Neither should be turned on
before §5 runs, because both target draw calls, and §3 says draw calls are not
what is costing the frame.

- **`structure_visibility_ranges`** (`performance.json`, false).
  `scripts/world/structure_visibility_range.gd` sets real
  `visibility_range_end` on built structures. Its own comment records that at
  `band1_open`, 4,058 of the draws are discrete built structures and props, not
  the grass carpet (133 MultiMesh draws total, already ruled out). Distances are
  derived from a 3 px cull threshold rather than fitted. It deliberately never
  touches the Stronghold, per the landmark-silhouette rule.
- **`scatter_lod_ranges`** (`performance.json`, false). PERF-ROG measured the
  authored ranges as changing draw calls by less than noise, and forcing every
  range to 20 m as removing only 5–16 %: "the lever works; it is just not where
  the frames are." That verdict was reached against draw calls, and §3 now says
  draw calls were the wrong scoreboard — so the flag may deserve a re-test
  against *frame time*, which nobody has ever been able to measure until now.

## 8. What this does not say

- It does not say the game is unplayable. It says nine authored camera stands
  render at 6–11 fps under the probe's conditions, with grass on, at
  2053x1080. A player's real session may differ; nobody has measured one.
- It does not identify a cause. §4 is a hypothesis with a named test.
- It does not blame the grass. It observes that the fast/slow split follows open
  ground, and proposes the experiment that would confirm or kill that.
