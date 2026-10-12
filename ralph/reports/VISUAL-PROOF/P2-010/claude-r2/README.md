# P2-010 Veilfall — claude-r2 (open: code-blind WEAK)

State: source 2d7d7a98 (flag `crag_kitbash_enabled`, shipped OFF). Sheet `before-after-Low.jpg`, neutral labels only.

The r2 round answered the coordinator's WEAK on 97e430cf:
- **Waterfall seams:** removed. The translucent tube's back faces were showing at every bend; it is now a viewer-facing half-sheet on a straight inclined path. The notch follows the path.
- **Smooth cone and strip:**
  - Rock now samples raw terrain. `ground_height_at` returns Veilfall interior floors under the mountain first.
  - The skin gets a distance-scaled lift, because Terrain3D's distant LOD poked through it.
  - Steep bare slopes get a rock drape.
  - The approach corridor and the passage gorge get a skin that draws from far only.
- **Boxy pieces:** columns are now 80% free-tumbled Rock_Medium boulders, rooted to the ground with no overhang, on a denser grid.
- **Close view:** the old white falls are kept for near view only (320 m).

Code-blind rounds 3–4: WEAK. The far (~4 km) and mid views pass: no cone, one continuous fall. Open items:
1. The stock approach crops the top, so the crag reads as a straight-sided tower.
2. The fall is a constant-width strip, with no flare or plunge spray in the mid view.
3. A thin pale path line remains on the face. This is the authored approach corridor.
4. Close entrance view: a dark rock corner at top right. Its smooth terrain surfaces are unchanged from before.

Tests (flag ON): the Veilfall geometry, far-crag, fall-surface, arena-bounds and interior-props tests give 10 tests, 2421 assertions, 0 failed.
