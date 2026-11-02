# TW-LOOK-1: Tidewake declutter with the Meshy beach focal pieces, six islands, High (31 Oct 2026)

**Verdict: land TW-LOOK-1.**
- **All six islands gain more than 0.5 at High.** The mean over both side orders goes from **5.34 to 6.19 (+0.85)**. The CPU read was 5.35 to 5.99 (+0.64), so the GPU agrees and finds a slightly larger gain.
- **The focal-building defect improves on every island.** Across six judge calls per island, control is mostly PRESENT and the candidate is **PARTIAL 6 of 6** on every island.
- **The clutter defect also improves** on every island, from mostly PRESENT to mostly PARTIAL.
- **MET: none.** The best is Drowned Garden at 6.46, so no Medium runs were queued (owner rule: High first).
- **No regressions.**

High, control → candidate. Mapped means of two batches with the sides swapped between them (see Method):

| Island (stands) | Batch 1 (cand on A) | Batch 2 (cand on B) | **Mean ctl → cand** | Focal building, ctl → cand | Clutter, ctl → cand | Gap to 7.5 |
|---|---|---|---|---|---|---|
| Gull Rest (19, 20) | 5.70 → 6.58 | 4.96 → 6.04 | **5.33 → 6.31 (+0.98)** | 6/0/0 → 0/6/0 | 6/0/0 → 1/5/0 | 1.19 |
| Tidal Cradle (09, 10) | 5.51 → 6.35 | 4.55 → 5.57 | **5.03 → 5.96 (+0.93)** | 6/0/0 → 0/6/0 | 6/0/0 → 1/5/0 | 1.54 |
| First Shore (01, 02) | 5.65 → 6.51 | 4.99 → 5.87 | **5.32 → 6.19 (+0.87)** | 6/0/0 → 0/6/0 | 5/1/0 → 3/3/0 | 1.31 |
| Salt Crown (11, 12) | 5.46 → 6.25 | 4.55 → 5.46 | **5.00 → 5.86 (+0.85)** | 6/0/0 → 0/6/0 | 6/0/0 → 2/4/0 | 1.64 |
| Drowned Garden (21, 22) | 5.95 → 6.67 | 5.40 → 6.24 | **5.68 → 6.46 (+0.78)** | 5/1/0 → 0/6/0 | 5/1/0 → 3/3/0 | 1.04 |
| Lantern Cove (17, 18) | 6.09 → 6.74 | 5.29 → 5.97 | **5.69 → 6.36 (+0.67)** | 3/3/0 → 0/6/0 | 6/0/0 → 1/5/0 | 1.14 |

Defect calls are PRESENT / PARTIAL / FIXED, summed over the six judges.
- Focal building: "Named location reads as a generic slope with no clear focal building or landmark".
- Clutter: "Cluttered scenes: scattered props, pebbles and grass tufts compete for attention".

**What changed, per the judges:**
- The candidate adds a hut, watchtower, pavilion or stall at the close view of every island:
  - the Gull Rest signal spire and huts;
  - the Tidal Cradle tower and saddle-camp hut;
  - the Salt Crown shrine hut and bell tower;
  - the First Shore gazebo and hut;
  - Lantern Cove's hut by the banner camp;
  - huts at both Drowned Garden stands.
- It clears the even grass carpet into sandy paths at Lantern Cove stand 17, Tidal Cradle stand 09, Salt Crown stand 12 and Gull Rest stand 19.
- Drowned Garden stand 22 and First Shore stand 02 keep their grass and pebble scatter, so clutter stays PRESENT for half the judges there.

**Path to 7.5 (1.04 to 1.64 short; all scene work, from the judges' notes):**
1. **Make the buildings the focus.** The new pieces are small and isolated on open sand, so they count as PARTIAL, not FIXED.
   - Scale each island's hero structure up.
   - Seat it on a levelled pad. **Salt Crown stand 11 close: the hut sits tilted on the slope.**
   - Tie it in with paths, docks, fences or banners, so a cluster dominates both views of the stand. Most approach views are still bare sand slopes.
2. **Finish the declutter.**
   - Grass in clumps along crests and edges, with the sand cleared between them.
   - Pebbles only at the tideline and on paths.
   - Drowned Garden 22 and First Shore 02 are untouched so far.
3. **Light and materials** (named in every judge's notes):
   - one flat beige sand tone, so add wet and dry sand bands;
   - hard dark-navy bands on the water, so add a shoreline gradient and foam;
   - no aerial haze and no warm day grade;
   - faceted dark-green placeholder boulders at Salt Crown.
4. **Terrain:** Tidal Cradle stand 09 close shows a smooth, near-vertical sand wall, and the blue creature there clips into it.

**Capture:**
- **Tree:** `tb/tidewake-1-on` 29ca0d23b, imported once for `assets/props/meshy-1031/tidewake/`. It has its own tree because WD2 and TW-LOOK conflict in `scripts/world/water_landmark_models.gd`.
- **Arms:**
  - The candidate is 29ca0d23b as is.
  - Control is the same tree with `data/config/tidewake_look.json` byte-copied from local commit 894bbc39b. That copy puts `beach_scene_candidate` and `beach_declutter_candidate` back in `sections_off`, so the lane's two sections render off as on main. 894bbc39b is not pushed.
  - Same import, same command; the only difference is that one file.
- **Command:** `phase2_capture_locations.gd --biome=water --preset=High --times=day --views=approach,close --seed=2042` with all 12 stands as repeated `--subset`, one boot per arm. Each arm made 24 frames on the first try.

**Method:**
- 6 two-sided sets, one 2×2 per island (two stands × approach and close), three code-blind judges per batch, high anchors.
- **Two batches, sides swapped:**
  - Batch 1 happened to put the candidate on side A in all six sets.
  - To rule out position bias I re-ran the same six sets with the candidate on side B in all six (anchor seed 31, which also redraws the anchors).
  - The gain holds in both orders: +0.65 to +0.88 in batch 1 and +0.68 to +1.08 in batch 2. The table reports the mean.
- **Fits:**
  - Batch 1: r 0.83, RMSE 0.59, slope 0.70.
  - Batch 2: r 0.92, RMSE 0.51.
  - Both confirming.
- **Absolute levels:** batch 2's levels sit about 0.7 lower than batch 1's on both arms. That comes from the different anchor draw, and the gains are unaffected.
