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
- **The pond's bake rect is 361 × 609 m, not the ~192 × 192 its comments
  assume.** `_region()` unions the pond's own below-water extent with the
  authored stream's points, and the stream sits at (−142, 80) while the pond
  centre is at (−395, 545) — 465 m apart. The single 512×512 texture is
  stretched across the gap, so the pond gets ~0.71 × 1.19 m per texel while most
  of the rect is ground neither the pond mesh nor the stream ribbon ever covers.

Neither is this lane's to fix — both are water QUALITY defects, not stall
defects, and the second in particular wants the stream given its own region the
way `SE21` gave the river one. Recorded here so they are not lost.
