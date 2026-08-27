# STALL-WATER — cutting the New Game world stand-up

Lane branch `ralph/STALL-WATER`. Target: `GF-B-001`, the `SHIP BLOCKER` ranked
#1 in Phase B's top ten — pressing **Start New Game** freezes the screen for the
better part of a minute.

Everything below is llvmpipe container measurement with the renderer OFF, the
same configuration Phase B and the Gate F defects lane measured in. **Boot time
on the ROG Ally is [OWNER-ONLY] and is not claimed here.**

## What this lane started from

The Gate F defects lane measured and attributed the stall on current `main`
(`4f87c697`, `9efb2c25`, `ralph/reports/gate-f-defects-log.md`). Press → settled
is **40,954 ms**, of which 38,079 ms is instrumented, and **water is 19,230 ms —
half of it**:

| ms | % | phase |
|---:|---:|---|
| 10,120 | 26.6% | vegetation scatter |
| 9,384 | 24.6% | **water: river** |
| 5,763 | 15.1% | **water: shader material + height bake** |
| 3,698 | 9.7% | **water: pond** |
| 3,422 | 9.0% | terrain `data_directory` assigned |

That lane also walked one dead end so this one does not have to: threading
`_bake_height_texture` with `WorkerThreadPool` came back bit-identical and paid
~2.5% of the stall, and the reason it did not pay is a GDScript
lambda-capture/copy-on-write memory-safety question that a passing equivalence
check does not settle. It was reverted. Algorithmic wins first.

## Measuring honestly in this container

The defects lane recorded that this box cannot time the whole boot reliably:
three runs of the same build measured the untouched vegetation scatter at
10,120 / 14,258 / 16,834 ms and the terrain load at 3,422 / 3,309 / 20,996 ms.
A single before/after pair of whole-boot numbers proves nothing here.

So this lane measures with **`tools/_probe_heightfield_cost.gd`** as its primary
instrument, and treats the whole-boot probe as confirmation rather than as
evidence. The micro-probe times the same three fixed 512×512 grids three times
each in one process and prints every repetition. On the untouched build the
repetitions agree to within 3%, which is what makes it usable where the boot
probe is not:

| grid | rep 1 | rep 2 | rep 3 | µs/call |
|---|---:|---:|---:|---:|
| pond bake region | 8,760.8 ms | 8,806.6 ms | 8,802.4 ms | 33.42 |
| river bake region | 10,781.3 ms | 11,005.0 ms | 10,590.8 ms | 40.40 |
| open meadow (control) | 8,697.2 ms | 8,524.3 ms | 8,516.9 ms | 32.49 |

It also prints a **checksum of every one of the 262,144 heights it samples**.
`height_at()` is the ground itself — the scatter gates placements on thresholds
read off it, the bake paints from it, the water composer finds its waterline
with it — so any optimisation of it has to be bit-identical, and the checksum is
what proves that rather than asserting it. Baseline on untouched `main`:

    pond bake region       CHECKSUM 1894580249
    river bake region      CHECKSUM  761512845
    open meadow (control)  CHECKSUM 2171315405

## Where the cost actually is

Read before changing anything, and it moves the target list the defects lane
handed over.

**`height_at()` call volume is the stall.** The two 512×512 water bakes are
524,288 calls between them; the river's waterline search is another ~54,000; the
pond's grid build another ~37,000.

**But the river grid costs 40.40 µs/call against the open meadow's 32.49 for the
same 262,144 samples.** That 8 µs gap is not the bake — it is `_river_carve`
walking eighteen course segments and re-reading twelve `Dictionary` keys out of
each one, on every sample, because every sample of the river bake is inside the
river's own bounds and so passes the `Rect2` reject that saves the rest of the
map. That is what makes `water: river` (9,384 ms) cost 3,621 ms more than
`water: shader material + height bake` (5,763 ms) when both do exactly one
512×512 bake.

Two further findings from reading the config rather than the prose:

- **The river is 2,091 m long, not 340 m.** `_river_region`'s docstring and
  `_build_river`'s still describe a 340 m river; the authored course in
  `terrain_playground.json` spans x ∈ [−1024, 1021] over nineteen points. Its
  bake rect is 2,091 × 186.5 m, so the height texture the shader reads depth
  from is **4.08 m per texel along the course** and 0.36 m across it.
- **The pond's bake rect is 337 × 569 m, not the ~192 × 192 its comments
  assume.** `_region()` unions the pond's own below-water extent with the
  authored stream's points, and the stream sits at (−142, 80) while the pond
  centre is at (−395, 545) — 465 m apart. The single 512×512 texture is
  stretched across the gap, so the pond gets **0.658 × 1.111 m per texel** while
  most of the rect is ground neither the pond mesh nor the stream ribbon ever
  covers: the pond mesh is 2,538 quads at a 2 m grid, 10,152 m² of a 191,753 m²
  rect, or 5.3% of it.

Neither is this lane's to fix — both are water QUALITY defects, not stall
defects, and the second in particular wants the stream given its own region the
way `SE21` gave the river one. Recorded here so they are not lost.

## PERF3 — `height_at()` is 5x faster, and the ground did not move

The stall is `height_at()` call volume, so the first thing to try is not
calling it less — it is making the call cost less, which pays out across every
phase of the boot rather than only in water.

**Measured with `tools/_probe_heightfield_cost.gd`, three repetitions of each
grid in one process:**

| grid | before | after | speedup |
|---|---:|---:|---:|
| pond bake region | 33.42 µs/call | **6.60 µs/call** | **5.06×** |
| river bake region | 40.40 µs/call | **8.27 µs/call** | **4.89×** |
| open meadow (control) | 32.49 µs/call | **6.51 µs/call** | **4.99×** |

Repetition spread after the change is 4.9% on the worst grid, so the gap is
about thirty times the noise. This is not a "the box was quiet this time"
result.

**And the ground is bit-identical.** All three checksums are unchanged across
786,432 sampled heights:

    pond bake region       CHECKSUM 1894580249   (unchanged)
    river bake region      CHECKSUM  761512845   (unchanged)
    open meadow (control)  CHECKSUM 2171315405   (unchanged)

`smoke_pond_water` reports the same geometry it reported before the change,
every count: 2,538 pond quads, 46 stream points, 152 reeds, 32 marginals, 72
bank flowers, 40 rocks, 5 driftwood, 49 lilypads, 18 jetty pieces, 390 river
quads, 159 river bank reeds, 57 river bank scrub. Run against `origin/main`'s
heightfield and against this one, in this container, back to back.

### What it was spending it on

Three things, all of them the same mistake at different scales, and all of them
a continuation of what `PERF1` and `PERF2` already record in this file: those
cached the parses that BUILD something and left the scalar re-reads around them
alone.

1. **Four noise fields sampled and thrown away, on almost every call.**
   `_rise_relief` sampled the domain warp (two 2-octave FBMs), the ridged rib
   field and the crumble field (a 4-octave ridged fractal, twice) at the TOP of
   the function, above the loop that decides whether any rise is even in range.
   Twelve octave evaluations, against the seven that `height_at`'s own hills and
   detail layers cost — so the rise relief was more expensive than the terrain.
   Six rises with radii in the tens of metres sit on a 2,048 × 8,192 m corridor,
   so the overwhelming majority of queries gated out on the first
   `distance >= radius` having paid all twelve. Deferred to the first peak that
   actually passes its rim gate; all four are pure functions of x and z, so
   sampling them later is the same number, which is what the checksums say.

2. **No bounding-box reject on any authored feature except the stream.**
   Seven spoke carves, six crossing carves, the outlet's sill and eighteen river
   course segments, each read out of a `Dictionary` — seven to twelve keys — on
   every query, to establish a contribution that is exactly zero for all but one
   or two of them. `_prepared_carve_depth` returns `depth * across * along` and
   both factors saturate to zero outside the profile, so one `Rect2` test per
   feature is the same answer. `_stream_carve` has always done this on the
   stream's course; nothing else on the map did.

   The river segments are the biggest single item, and they are why the
   `water: river` phase costs 3,621 ms more than `water: shader material +
   height bake` when both do exactly one 512×512 bake: the river's existing
   whole-course `Rect2` rejects most of the map, and rejects **nothing at all**
   for the river's own bake, where every sample is inside those bounds by
   construction. That is the 8 µs gap between the river grid and the control
   grid in the table above, and it is now 1.8 µs.

3. **`_apply_flats` walked eleven building pads reading five `Dictionary` keys
   out of each**, on a hot path with no early reject, for pads that occupy a few
   hundred metres of an 8,192 m corridor. Five parallel `PackedFloat64Array`s
   instead. The centres stay as pairs of GDScript doubles rather than a
   `PackedVector2Array` — 32-bit components would round the centre before the
   subtraction instead of after it, which is the last-bits shift the loop's own
   comment has always warned about.

Also removed: `_apply_spawn_pad` re-derived `_raw_height` at the pad centre —
the whole hills/detail/valley/rise stack — on every query that landed inside the
spawn pad. It is a constant. That is precisely the defect `PERF2` found one
function further down in `_apply_flats`, still live in its neighbour.

`tests/test_heightfield_cost.gd` (PERF2's own cost-ratio guard),
`test_playground_heightfield.gd`, `test_river_crossings_stay_open.gd`,
`test_terrain_adaptation.gd`, `test_water_hazard.gd` and the rest of the
heightfield/terrain/water/river selection: 44 tests, 1,453 assertions, 0 failed.

## The pond's wet scan asked the same question four times

`_build_pond` decides which grid cells carry water by testing each cell's four
corners against the waterline. Every interior corner is shared by four cells, so
that asked `height_at` for the same point up to four times: 48,165 cells at a 2 m
grid over the 337 × 569 m region, up to 192,660 calls for 48,620 distinct
points, and the early `break` only fires on the 2,538 cells that turn out to be
wet.

Sampled once per lattice point into a `PackedByteArray` of wetness flags, which
the cell loop then reads four entries out of. Same predicate, same points; the
one place it could differ is that a cell's right corner used to be
`pos.x + col * step + step` and is now `pos.x + (col + 1) * step`, and those
agree exactly for any dyadic `step`, which the authored 2.0 is.
`smoke_pond_water` reports 2,538 quads before and after.

## Where water goes now — every phase named

`water.gd` and `_build_material` grew sub-phase marks so the remainder is
attributed rather than summarised: the 512×512 bake is separated from the step-4
height-range scan that precedes it (one is 4,096 times the samples of the other,
so a single mark over the pair says nothing), and `_build_river`'s waterline
search, bake, mesh commit and bank bands are marked individually.

| ms | phase | before |
|---:|---|---:|
| 2,174 | water: river height BAKE (512×512) | — |
| 1,777 | water: pond height BAKE (512×512) | — |
| 419 | water: river waterline search (520 stations) | — |
| 414 | water: jetty | 294 |
| 328 | water: pond wet-lattice scan (48,620 points) | — |
| 197 | water: river height RANGE scan (step 4) | — |
| 108 | water: pond height RANGE scan (step 4) | — |
| 93 | everything else in water | — |
| **5,510** | **water total** | **19,230** |

**Water is 5,510 ms against the 19,230 ms the defects lane measured — 0.29×, a
3.5× cut** — and it is no longer half the stall. It is 12% of it.

The honest caveat, and it cuts both ways. This run's untouched phases were
*worse* than the defects lane's, not better: the vegetation scatter measured
20,131 ms against 10,120 ms and the terrain load 8,578 ms against 3,422 ms, on a
box whose own variance the defects lane already recorded at 2× and 6×. So the
3.5× is a floor rather than a claim of precision — the water phases fell by that
much while everything around them was getting slower. The tight, repeated,
checksum-guarded micro-probe above is the evidence; this table is the
confirmation that it reached the real boot.

### What is left, and what it would cost

**The two 512×512 bakes are now 3,951 ms — 72% of what water still spends.**
Everything else in water is under half a second.

The bake's cost is `height_at` and nothing else: 2,174 ms over 262,144 texels is
8.29 µs a texel, against the micro-probe's 8.27 µs/call for the same region with
no image writing at all. A `PackedFloat32Array` fill handed to
`Image.create_from_data` in place of 262,144 `Image.set_pixel` calls was written
and measured against exactly that, and it is worth about 0.2 µs a texel, ~0.1 s
across both bakes. Not shipped: a change with no measurable payoff is churn.
`tools/_probe_water_bake_identity.gd` stays, because it is what a future attempt
at the bake needs to prove it did not move the water.

What WOULD pay is sampling fewer texels, and both bakes have most of theirs
going to ground the shader can never read:

- **The river.** Its rect is 2,091 × 186.5 m and its channel is at most 38 m
  wide. The surface mesh reaches the measured waterline plus half a metre, and a
  fragment shader only runs on fragments of that mesh, so texels further than
  that from the centreline are never sampled. `_build_river` already has
  `left[]`, `right[]` and `samples[]` in hand before it calls `_build_material`,
  so the band is derivable exactly. Roughly a quarter of the rect is in it —
  call it 1,600 ms.
- **The pond.** Its mesh is 2,538 quads, 10,152 m² of a 191,753 m² rect: 5.3%.
  The wet lattice that says which cells those are is now computed anyway, but
  `_build_pond` runs after `_build_material`, so using it would mean reordering
  the two. The stream ribbon shares this material and would have to be in the
  mask as well. Call it 1,600 ms.

Both are exact for every pixel the shader can sample and neither is bit-identical
as a texture, so neither can be checked the way this lane has checked everything
else so far — the check has to be "identical within the mesh's own footprint,
dilated by a texel for bilinear filtering", against the mesh that was actually
built. That is a real verification and it is not a cheap one.

### Not this lane's, but now the top of the list

With water at 12%, the New Game stall is **the vegetation scatter (20,131 ms,
44.5%) and the Terrain3D data load (8,578 ms, 19.0%)**.

The scatter is `HIST-085`'s. One thing this lane can hand it: **the scatter did
not respond to `height_at` getting 5× faster.** It measured 20,131 ms here
against 20,718 ms on the run immediately before the change and 10,120 ms on the
defects lane's box — i.e. it tracked box load and ignored the optimisation
entirely. That is consistent with `scatter_bake.gd`'s own claim that placements
are "pure of the heightfield" and served from the disk bake, and it means the
scatter's 20 s is instancing, batching or collision, NOT terrain queries.
Whoever takes `HIST-085` should not start by profiling `height_at`.

The terrain load is Terrain3D reading its region files, and it is the most
volatile number on this box: 3,422 / 3,309 / 20,996 ms for the defects lane,
39,987 / 8,578 ms here. It is disk, and this container's disk is shared.

## The river's bake spent 82% of itself on ground the shader cannot read

The river's rect is 2,091 × 186.5 m and its channel is at most 38 m across. The
surface is a ribbon reaching the measured waterline plus half a metre, and a
fragment shader runs only on fragments of the mesh it is assigned to — this
material is `material_override` on one node, `RiverSurface` — so a texel that
surface does not lie over is never read, whatever is in it.

`_build_river` already has `samples[]`, `left[]` and `right[]` in hand before it
calls `_build_material`, so the footprint is derivable exactly. The quad between
stations `i` and `i+1` lies entirely within `R` of the segment joining them,
where `R` is the largest of the four measured half-widths plus that half metre:
each of its four corners is within `R` of one endpoint, the set of points within
`R` of a segment is convex, and a quad is the convex hull of its corners. Marked
as the axis-aligned box around that segment rather than the stadium — a
conservative superset — and grown by two texels per axis for bilinear filtering.

Unsampled texels are filled with the **ceiling**, not the floor, deliberately. If
a mask were ever wrong, an unsampled texel decodes as ground a metre above the
highest ground in the rect, so the shader reads negative depth and feathers the
surface away. The failure mode is missing water, which is visible immediately,
rather than water lying over a phantom chasm — the failure `_build_material`'s
own comment records costing two blind rounds and a CPU replication of the shader
to find.

### How it is verified

Not against the reasoning that produced it. A mask a few texels too small
produces a band of wrong depth along one bank, and no headless test would see
it: the geometry counts do not change, and neither does anything else a test
currently asserts.

`tools/_probe_river_bake_mask.gd` stands the real composer up, takes the
`RiverSurface` mesh **that was actually built**, rasterises its 780 triangles
into texel space as bounding boxes (a superset of true coverage, so the test is
stricter than the mesh), dilates by one texel for bilinear filtering, and
compares the shipped texture against a full unmasked bake over every texel in
that set. The mask code has no say in which texels get checked.

    mesh: 2340 vertices, 780 triangles
    the built mesh, dilated by one texel, covers 36301 of 262144 texels (13.8%)
    IDENTICAL: 0 of 36301 differ from a full unmasked bake
    214740 filled with the ceiling and never sampled -- 81.9% of the bake saved

**`water: river height BAKE` fell from 2,174 ms to 498 ms** — 0.229×, which
tracks the 18.1% of texels still sampled. Building the mask costs 19 ms.

## Where the lane finished

| ms | phase | before |
|---:|---|---:|
| 1,793 | water: pond height BAKE (512×512) | — |
| 498 | water: river height BAKE (512×512) | — |
| 435 | water: river waterline search (520 stations) | — |
| 418 | water: jetty | 294 |
| 331 | water: pond wet-lattice scan (48,620 points) | — |
| 202 | water: river height RANGE scan (step 4) | — |
| 106 | water: pond height RANGE scan (step 4) | — |
| 116 | everything else in water, mask build included | — |
| **3,899** | **water total** | **19,230** |

**Water is 3,899 ms against 19,230 — 0.203×, a 4.9× cut**, and 9.3% of a 41,919
ms instrumented stand-up rather than half of it. Press → settled on this run was
45,347 ms; the defects lane measured 40,954 ms, on a box where the phases this
lane never touched were meanwhile measuring 19,744 ms against 10,120 (vegetation
scatter) and 7,927 against 3,422 (terrain load). The stall total is not this
lane's to claim either way — the water rows are.

### The one remaining water item worth anything

**The pond's bake, 1,793 ms — 46% of what water still spends.** Its mesh is
2,538 quads, 10,152 m² of a 191,753 m² rect: 5.3%, so it wastes even more of
itself than the river's did. Two things make it harder than the river:
`_build_pond` runs *after* `_build_material`, so the wet lattice that says which
cells carry water would have to be computed first and the two reordered; and the
stream ribbon shares this material, so its course has to be in the mask too.
Both are tractable. `_probe_river_bake_mask.gd` is the shape the verification
takes — read the built mesh, not the mask.

Everything else in water is under half a second.

### A trap this container sets, now guarded

`tools/_probe_new_game_stall.gd` leaves a `user://saves/slot_0.json` behind,
because it really does press New Game and the world really does save. **The next
run of it, and the next run of `tests/smoke_title_new_game.gd`, then fail** —
the title takes its overwrite path instead of changing scene, the world never
arrives, and the probe reports 3,000 quiet frames as though the stall had
vanished. It reads exactly like a code regression. An hour went into proving it
was not one (the same failure reproduces with `water.gd` stashed back to
`origin/main`).

The probe now refuses to run when `user://saves` is non-empty and says why. It
does not delete anything: a probe that silently removes a save is a worse
failure than one that refuses to start. Clear the directory by hand — it is
container-local state, not repository content.
