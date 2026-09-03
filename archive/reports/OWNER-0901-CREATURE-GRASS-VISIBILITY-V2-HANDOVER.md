# Handover — OWNER-0901-CREATURE-GRASS-VISIBILITY-V2

Written by the coordinator, not the lane. The lane session archived before it
wrote its own, so this is assembled from its branch, its commit message, its
`ralph/reports/OWNER-0901-CREATURE-GRASS-VISIBILITY-V2/REPORT.md` (16KB, the
detailed record — read it for the pixel-level evidence), and the
coordinator's own review of the diff. Where this file states something the
lane did not demonstrate, it says so.

Owner's words, twice: *"small creatures in grass still want fixed. they're
not super visible."*

## 1. Read this first: two different things are called "bushes"

This cost the lane hours and will cost the next person the same.

- **`vegetation.json`'s `bushes` layer** — statically **baked** scatter, in
  `data/scatter/playground/**`. Carries `collides: false`: ferns and shrubs
  the player walks straight through. It is the **densest visual occluder in
  the whole layer set**, and it is what the owner's creature was standing
  inside.
- **`grass_field.json`'s `cover_tiers` `bushes`** — **procedural**, built at
  runtime by `grass_field.gd`.

Same name, unrelated systems. Any lever that reaches one does not reach the
other. Check which one you are looking at before forming a theory.

## 2. What was actually fixed, and why this shape

Root cause: a wild creature could spawn **directly inside** a baked bush, its
whole silhouette broken by real leaf geometry. No creature-material tint can
fix total geometric occlusion.

The fix is **spawn siting**, not clearing:

- `vegetation.gd::has_solid_scatter_near(centre, extra)` — read-only query.
  Two sources, because the data has two shapes. Trees/rocks/saplings/grove
  **collide**, so `_collision_batches` already holds their positions and each
  layer's authored `radius` — the same number a footstep bounces off, reused
  rather than guessed. `bushes` carries `collides: false` and holds **no**
  collision entry at all, so a new narrow `_bush_positions` list plus
  `BUSH_VISUAL_RADIUS = 1.2` covers it.
- `encounter_director.gd::_pick_clear_spot()` — redraws the candidate up to
  `CLEAR_ATTEMPTS = 6` times **from the same per-cluster seeded rng** (so the
  meadow stays deterministic), then spawns anyway rather than never spawning.
  A creature that fails to appear is a worse defect than one partly occluded.

**Why siting rather than clearing:** `grass_field.gd`'s `grass_clear`
group/meta mechanism was tried, rendered, proven not to reach a
statically-baked placement, and **fully reverted**. It cannot work here —
the bushes in question are baked, and re-baking or live-culling them was out
of this lane's brief. Not spawning a creature on top of authored world
dressing is also simply more correct than deleting the dressing.

Verified against the exact reproduced worst case: before, 0% visible, fully
inside opaque canopy; after, silhouette (ears, body outline) intact, 5.3m
from the original point.

## 3. What is still NOT fixed

At a 30% thumbnail — the honest readability test — the creature reads as a
**dark smudge**, not a crisp shape. The picked spot landed in partial shade.

That remaining gap is **creature-vs-ground contrast, not occlusion**. It is a
different problem from the one this lane closed and needs a different lever:
a ground-contact shadow to seat the creature, a rim or fill so the silhouette
survives shade, or a value separation between creature and ground. The lane
filed it rather than chasing it. **It is open.**

## 4. `field_degreen`

A per-creature colour lever in `creature_body.gd`, shipped alongside, for
bramblebun's own painted hue matching the grass. Real and measured. An
independent **blind** visual-judge pass called it a modest improvement on its
own — **not** a fix for the occlusion this lane actually closed. Treat it as
a supporting tweak, not the answer.

## 5. Performance warning — read before calling this from anywhere else

`has_solid_scatter_near()` is a **linear scan of every collision placement**
(~52,000 in the shipped playground) **plus** the bush list, with a Dictionary
lookup per placement. `_pick_clear_spot()` can call it up to 6 times per
creature, and `spawns.json` authors **933 creatures across 283 clusters**
(band1 219, band2 196, band3 160, band4 280, band5 78).

Worst case is ~293 million inner iterations at boot.

**What is actually observed:** CI step durations on the branch are
indistinguishable from main's (playground 67s vs 67s, catching 2m02s vs
2m02s), so the realised cost was not visible at CI granularity. The likely
reason is that `encounter_director._ready()` awaits only one process frame
before spawning, so `_collision_batches` may still be largely unpopulated
when the query runs — which would also mean **the check is doing less work
than intended**. Nobody has instrumented this. Treat both the cost and the
effectiveness as **unmeasured**.

**Recommendation: put a spatial index (grid or quadtree) behind this before
any other caller uses it**, and instrument how many candidates actually get
rejected — if the answer is near zero, the fix is not doing what it claims.

## 6. Grass density — decided, and a separate open question

The owner asked why grass had become far less dense. Shipped values in
`data/config/grass_field.json`: `tuft_count: 75000`, `blades_per_tuft: 4`,
`blade_segments: 3` (cut from 300000/6/4; stones 90000→25000, litter
49000→15000).

**Decision: keep 75k.** Two judges, one blind to which frame was which,
agreed. (The coordinator initially read the frames backwards and said 75k
looked denser than 150k; the blind judge measured the opposite and a pixel
diff confirmed it. Density is not the defect.)

**The real gap is blade SHAPE, and it is unresolved.** Thin isolated spikes
on a blurry ground read as "hair on a lawn";
`docs/reference/moong-01-mounted-in-tall-grass.jpg` shows overlapping blades
with mass. Proposed: a **clump card** (3–5 blades per instance, wider base,
root-to-tip gradient, ±30% height variation) at the current instance count.

**NOT owner-approved — do not ship unilaterally.** `grass_field.gd` has been
VP-owned since PR #20; route it through the visual coordinator.

## 7. CI note

This branch's only real CI failure was `Verify traversal`, and it was **not
this lane's fault** — a pre-existing harness defect that reproduces
byte-identical on unmodified trees. Fixed separately on main (`c4172bcd`).
Two of the branch's three "green" runs were the sub-200-second all-skipped
trap and verified nothing; see §0 of
`ralph/COORDINATOR_HANDOVER_2026-09-02_EVENING.md`.
