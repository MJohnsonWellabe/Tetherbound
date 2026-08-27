# STALL-2 — the second New Game stall lane

Lane branch `ralph/STALL-2`, cut from `ralph/LAND-WATER` (which carries the
first lane's work and was not on `main` when this started). Target: `GF-B-001`,
the `SHIP BLOCKER` ranked #1 in Phase B's top ten — pressing **Start New Game**
freezes the screen for the better part of a minute.

llvmpipe container measurement with the renderer off, the same configuration
Phase B, the Gate F defects lane and `ralph/reports/stall-water-log.md`
measured in. **Boot time on the ROG Ally is [OWNER-ONLY] and is not claimed
here.**

## What this lane was handed

`ralph/reports/stall-water-log.md` took water from 19,230 ms to 3,899 ms and
left three things behind:

1. **The pond's height bake, 1,793 ms, 46% of what water still spent.** Its
   mesh covers 5.3% of its rect. Named as harder than the river's for two
   reasons: `_build_pond` runs *after* `_build_material`, and the stream ribbon
   shares the material.
2. **The vegetation scatter**, with a negative result attached that is worth
   more than a starting point: it **did not respond to `height_at` getting 5×
   faster**, so its cost is not terrain queries. `HIST-085` should not begin by
   profiling the placement rules.
3. **Terrain3D `data_directory`**, ~3.4 s, largely outside our code.

## Measuring honestly in this container

The box cannot time a whole boot: three runs of the same build measured the
untouched vegetation scatter at 10,120 / 14,258 / 16,834 ms and the terrain
load at 3,422 / 3,309 / 20,996 ms. So every number below comes from a probe
that runs the same work several times **in one process** and prints every
repetition, and every claim is normalised against a phase this lane did not
touch.

Two instruments were added:

- **`tools/_probe_water_phase_cost.gd`** — three complete builds of the water
  composer in one process, every phase of every repetition printed, plus
  ratios against untouched phases. The pond's step-4 height RANGE scan walks
  exactly the rect the pond's 512×512 BAKE walks with the same `height_at`, so
  `BAKE / RANGE` is a figure the box's load cannot move. The river's own
  BAKE/RANGE pair is the control for anything done to the pond.
- **`tools/_probe_scatter_load_cost.gd`** — `is_fresh` then `load_all`,
  repeated, with no scene and no Terrain3D, plus a per-layer census and an
  **order-sensitive checksum over every placement the load produces**.

Verification probes, which are separate from measurement and are the part that
matters:

- **`tools/_probe_pond_bake_mask.gd`** — the pond equivalent of the water
  lane's `_probe_river_bake_mask.gd`.
- The scatter checksum above, and a both-ways load comparison described under
  the layer skip.

## 1. The pond's bake spent 93% of itself on ground no water lies over

`_region()` unions the pond's own basin with an authored stream 465 m up the
map, so the pond's height texture covers 337 × 569 m at 0.658 × 1.111 m per
texel. The pond mesh is 2,538 quads at a 2 m grid — 10,152 m² of a 191,753 m²
rect — and the stream ribbon is a 2.4 m band along an 84 m course. A fragment
shader runs only on fragments of the mesh it is assigned to, so a texel neither
surface lies over is never read, whatever is in it.

The water lane's two stated obstacles were both real and both tractable.

**Ordering.** The wet-lattice scan and the flood fill moved out of
`_build_pond` into `_pond_cells()`, cached, ahead of the bake. `_build_pond`
reads the answer back instead of deriving it, so the scan still runs exactly
once — just earlier. The set of kept cells *is* the pond surface's footprint,
so the mask half of it is **exact**, not estimated.

**The shared material.** `build()` hands `StreamSurface` a `duplicate()` of the
pond's material, and `Resource.duplicate()` is shallow — both nodes sample the
same `ImageTexture`. The stream's footprint is a conservative superset by the
river's own convexity argument: every ribbon quad lies within `half * 1.25`
(`_width_swell`'s maximum) of an authored course segment, marked as the
axis-aligned box around each. Marked over the whole authored course rather than
the trimmed range `_build_stream` meshes, because a superset is free at this
size and the trim depends on carve depths the mask has no reason to re-derive.

Unsampled texels are filled with the **ceiling**, as the river's are, so a
wrong mask fails as *missing water* — visible instantly — rather than as water
over a phantom chasm.

### How it is verified

Not against the reasoning that produced it. `tools/_probe_pond_bake_mask.gd`
stands the real composer up, takes the two meshes **that were actually built**,
rasterises their triangles into texel space as bounding boxes (a superset of
true coverage, so the test is stricter than the meshes), dilates by one texel
for bilinear filtering, and compares the shipped texture against a full
unmasked bake over every texel in that set. It also asserts the two materials
still share one texture, so a future edit giving the stream its own bake cannot
make the probe quietly check the wrong thing.

    mesh PondSurface     15228 vertices,  5076 triangles -> 15491 texels
    mesh StreamSurface     270 vertices,    90 triangles ->   850 texels
    both, dilated by one texel, cover 16341 of 262144 texels (6.2%)
    IDENTICAL: 0 of 16341 differ from a full unmasked bake
    1390 baked anyway (mask slack)
    244413 filled with the ceiling and never sampled -- 93.2% of the bake saved

## 2. The pond's wet scan asked about 45,586 cells the fill then discarded

Third round of the same mistake in one function. The first asked `height_at`
for each cell's four corners, four questions per shared corner. The second (the
water lane's) made it one pass over the lattice. A full pass is still 48,620
calls to decide 2,538 cells, for the same reason the bake was wasteful: the
rect is 337 × 569 m and the pond is 5.3% of it.

The fill only ever keeps the seed's own connected component — every other wet
cell in the rect is computed and thrown away. So it does not need the lattice
in advance: it needs a cell's four corners at the moment it considers that
cell, and it only ever considers the component and the ring of dry cells around
it. Sampled along the fill, memoised into the same `PackedByteArray` the full
pass used to fill.

    water: pond wet-lattice scan   48,620 points -> 3,034 sampled (6.2%)

**Any cell whose wetness the fill never asks about is a cell the fill could not
have kept.** The out-of-rect seed still takes the fallback branch: that test
comes first and is not redundant, since asking `_wet_cell` directly would index
off the end of the lattice where the old `wet_cells.has()` merely returned
false.

What says so rather than the argument: every derived number is unchanged.
`_probe_pond_bake_mask.gd` reports the same 5,076 pond triangles, the same
15,491 pond texels, the same 16,341 total, the same 1,390 texels of slack, and
IDENTICAL over all of them.

### Where water finished

Medians of three complete builds in one process, back to back on this box:

| ms | phase | at lane start |
|---:|---|---:|
| 377 | water: river height BAKE (512×512) | 398 |
| 328 | water: river waterline search (520 stations) | 337 |
| 155 | water: river height RANGE scan (step 4) | 158 |
| 125 | **water: pond height BAKE (512×512)** | **1,478** |
| 69 | water: pond height RANGE scan (step 4) | 83 |
| 42 | **water: pond wet-lattice scan** | **285** |
| 82 | everything else, both masks included | 90 |
| **1,178** | **sum of every marked water phase** | **2,829** |

**The control did not move.** River BAKE / river RANGE — neither touched by
this lane — reads 2.47 before, 2.45 after the mask, 2.41 after the lazy fill.
Pond BAKE / pond RANGE went 17.81 → 1.89 → 1.75.

One honest wrinkle: the pond's RANGE scan itself got cheaper (83 → 66 ms)
without being touched, because the wet-lattice scan now runs first and pays the
heightfield's lazy-cache warm-up the RANGE scan used to pay. That makes 1.75 an
*overestimate* of what the pond's bake still costs, not an understatement.

Water is now 1,178 ms against the 19,230 ms the Gate F defects lane measured.

## 3. The vegetation scatter is a file read, and 87% of it is thrown away

The handed-over negative result did most of the work. The scatter does not
respond to `height_at`, so it is not the placement rules. `vegetation.gd`'s own
boot-phase print then says where it goes, and `scatter_bake.is_fresh()` says
what that phase is:

    [vegetation] boot phases (ms): placements=12792 mark_harvestable=526
      group_by_model=93 register_mesh_assets=35 build_batches_total=2730
      update_mmis=223

`placements=12,792 ms` of a ~16.4 s build, and it is `BAKE.load_all()` — a
**file read**, not `all_placements()` recomputing anything. `is_fresh` returns
true in 2 ms.

Split in two, because the halves behave nothing alike:

    read[256 regions, 765,391 placements]   5,763 ms cold, ~1,550 ms warm
    reorder[19 layers]                      4,961 / 5,530 / 4,907 ms

The read gets cheaper on a warm page cache across three loads in one process.
The reorder does not move at all — it is CPU, and it is the comparator.

### 3a. A comparison sort over a key that was already a dense permutation

`_reorder` called `Array.sort_custom` with a GDScript lambda, n log n
invocations, for a key that never needed comparing. `write_all` stamps each
placement with its own index within its layer's array —
`for i in kept_list.size(): _bucket(..., i)` — and writes every placement to
exactly one region file, so the orders gathered for a layer are the integers
0..n−1, each exactly once. `out[order] = placement` puts every entry where the
sort would have put it, in one pass.

    reorder[19 layers]   4,907-5,530 ms -> 442-772 ms
    load_all, warm       6,571-7,826 ms -> 2,370-2,456 ms

**The read phase is the control**: 1,525 / 1,593 ms before, 1,499 / 1,523 ms
after, same process, same three repetitions. It did not move, so the box did
not get quieter — the comparator went away.

Density is checked, not assumed, and anything that is not a dense permutation
falls back to the original sort kept verbatim. It has to be: **order is
behaviour, not presentation.** `vegetation.gd::_mark_harvestable` walks each
layer's array by index and makes a deterministic slice of it into real gather
points, so an array holding the same placements in a different order puts the
axe on different trees.

`tools/_probe_scatter_load_cost.gd` fingerprints every placement the load
produces **with its layer name and its index in that layer**, over all 765,391:

    CHECKSUM 1465375744   before (comparison sort)
    CHECKSUM 1465375744   after  (direct placement)

### 3b. 664,574 of 765,391 placements were read only to be erased

The other half, and the larger one. The grass field owns the ground plane on
this build, and `vegetation.gd` drops the four layers it replaces the moment
the load returns:

| layer | kept | drained | built? |
|---|---:|---:|---|
| grass | 373,992 | 2,161 | **no** |
| groundmat | 152,017 | 807 | **no** |
| flowers | 71,693 | 27 | **no** |
| drygrass | 63,841 | 36 | **no** |
| trees | 42,777 | 118 | yes |
| bushes | 39,582 | 158 | yes |
| path_stones | 9,243 | 21 | yes |
| rocks | 5,729 | 0 | yes |
| saplings | 2,773 | 5 | yes |
| grove | 277 | 0 | yes |
| deadfall | 134 | 0 | yes |

**86.8% of everything the read builds is constructed as two Dictionaries each
and immediately discarded.** And the caller knows which layers those are
*before* the load — `grass_field.suppressed_layers()` is a config read.

So `load_all` takes the set and walks past those layers with `_skip_placements`
— a seek plus one byte read per placement, against the two Dictionary
allocations `_read_placement` costs. Only the bake path can be told;
`all_placements` computes what it computes and `vegetation.gd`'s drop loop
still handles it, which is why the loop stays.

    read[256 regions, 100,817 placements, 661,543 skipped]  1,443-1,516 ms -> 474 ms
    reorder[11 layers]                                          448-475 ms -> 102 ms
    load_all, warm                                          2,295-2,404 ms -> 665 ms

### How the skip is verified

The seek arithmetic has to match `_write_placement`'s record layout exactly. If
it does not, the file position after a skipped layer is wrong and every layer
*after* it in that region reads garbage, or nothing, or someone else's
placements — and nothing about that failure is loud. The layers being skipped
are the ones the grass field replaces, so a desynchronised read shows up as
trees and bushes in the wrong places on a build whose scatter counts still look
plausible.

So the probe loads the bake **both ways in the same process** and requires the
surviving layers to be element-for-element identical — same count, same order,
same model, position, yaw, scale and normal — the skipped layers to be absent,
and the count reported back through `skipped_out` to equal what the unskipped
load actually held:

    load_all with 4 layers skipped: 665 ms
    IDENTICAL: 100817 placements, same order, across 7 layers

`skipped` reports 661,543, which is exactly the number `vegetation.gd`'s "left
unbuilt" line printed before this change — it counts kept only, deliberately,
so that line stays comparable instead of quietly gaining the drained ones.

### What it did to the real boot

    [vegetation] boot phases (ms)      before        after
    placements                         12,792   ->     527
    mark_harvestable                      526   ->      53
    build_batches_total                 2,730   ->   4,355   (untouched)
    update_mmis                           223   ->     634   (untouched)
    [probe] wall time to 60 settle     37,575   ->  24,087

`mark_harvestable` fell as a side effect: it no longer walks the four
suppressed layers. **The two untouched phases got worse** — which is the same
shape the water lane's headline had, and is what makes the rest credible on a
box with this much variance.

`[playground] scattered 100515 props in 29 batches (56423 harvestable, 0
already chopped, 113/51556 collision resident)` — identical before and after.

## Terrain3D `data_directory` — looked at, not touched

`_terrain.set("data_directory", DATA_DIR)` is the GDExtension reading
`data/terrain/playground`: 64 region files, 23 MB. There is no lever on our
side of that call. It is also the most volatile number on this box — 3,422 /
3,309 / 20,996 ms for the defects lane, 39,987 / 8,578 for the water lane — so
it is disk, and this container's disk is shared. Cutting it means fewer or
smaller regions, which is a world-data decision, not a stall fix.

## Tests

    tests/run_tests.gd --only=heightfield,terrain,water,pad,carve,river,scatter
    77 tests, 959,795 assertions, 0 failed

    tests/run_tests.gd --only=scatter,vegetation,bake,harvest
    89 tests, 1,898,725 assertions, 0 failed

`test_scatter_perf_budget.gd` is in that selection on purpose: its load-time
budget, placement-count bounds and batch-count bound are the assertions that
would catch this lane breaking the bake. `test_scatter_rules.gd`'s
`test_the_meadow_is_the_same_every_run` is what would catch placements moving.

`tests/smoke_pond_water.gd`: 2,538 pond quads, 46 stream points, 152 reeds, 32
marginals, 72 bank flowers, 40 rocks, 5 driftwood, 49 lilypads, 18 jetty
pieces, 390 river quads, 159 river bank reeds, 57 river bank scrub — every
count unchanged. `tools/_probe_river_bake_mask.gd` still reports IDENTICAL over
its own 36,301 texels.

## Summary of what moved

| | at lane start | now |
|---|---:|---:|
| water: pond height BAKE | 1,478 ms | **125** |
| water: pond wet-lattice scan | 285 ms | **42** |
| sum of every marked water phase | 2,829 ms | **1,178** |
| scatter bake `reorder` | 4,907–5,530 ms | **102** |
| scatter bake `read` | 1,443–1,593 ms warm | **474** |
| `BAKE.load_all`, warm | 6,571–7,826 ms | **665** |
| `vegetation` `placements` phase, real boot | 12,792 ms | **527** |
| `vegetation` `mark_harvestable`, real boot | 526 ms | **53** |

Controls that did not move, measured in the same processes: water's river
BAKE / river RANGE ratio (2.47 → 2.41), and the scatter bake's read phase
across the reorder change (1,525/1,593 → 1,499/1,523). Two phases this lane
never touched got *worse* over the same interval — `build_batches_total` 2,730
→ 4,355 and `update_mmis` 223 → 634.

Nothing here changes what the world looks like. The pond's texture is identical
over all 16,341 texels the two meshes that read it can touch, every
`smoke_pond_water` count is unchanged, and the scatter load returns the same
100,817 placements in the same order with an unchanged checksum over all
765,391.

## What is left, ranked

1. **The scatter's `build_batches_total`**, now the largest phase of the
   scatter at ~2.7–4.4 s, of which `harvest_points[56,423 nodes]` is ~2.2–3.8 s.
   56,423 `Node`s built at boot for gather points. Not looked at by this lane.
2. **Terrain3D `data_directory`** — see above; not ours.
3. **`water: river height BAKE`, 377 ms**, and `river waterline search`,
   328 ms. Both already masked or already minimal; the remaining water items are
   all under half a second and none is worth a memory-safety question.
4. **`_region()` unioning the pond with a stream 465 m away** remains a water
   QUALITY defect, recorded by the previous lane and still open. It is why the
   pond's texture is 0.658 × 1.111 m per texel instead of ~0.4 m square. Now
   that both halves of that rect are masked, it costs nothing at boot — but it
   still costs resolution. It wants the stream given its own region the way
   `SE21` gave the river one.
