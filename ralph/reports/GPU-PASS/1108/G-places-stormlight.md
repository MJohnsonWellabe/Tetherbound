# G-places-stormlight: Stormwood storm-light arm (LANE-PLACES; GPU High)

**Frames:** `tb/gpu-frames-1108`, six sections `G-places-stormlight-{storm,locations,routes,dialogue,fight,creatures}`, High, seed 2042. Both sides were captured from `tb/places` 038f0fdeb.
- **base:** overlay off.
- **arm:** `PLACES-STORMLIGHT/overlay.json`, which turns on `storm_phase_1111` and `distinct_bodies_1111`.

**Render check:** every arm frame differs from its base frame and none is blank.

| Section | Pixels changed (>12 levels) | Mean brightness, base → arm |
|---|---|---|
| storm phases | 18–73% | Calm 81→83, Building 72→71, Break 72→78, Fading 83→74 |
| locations | 6–20% | lifted by +1.4 to +4.4 |
| dialogue | Maud 3%, Hesk 21%, Bryn 17% | — |
| fight | 7% | — |
| routes | 3% | — |
| creatures | 52–53% | — |

As the GPU lane noted, the brightness change across phases does not go darker step by step: Break is brighter than Building, and Fading is the darkest. The night frame at the lantern_hollow landmark renders as day on both sides. It was judged as captured.

**Batch `G-ps1`:**
- Three code-blind judges with the standard prompt and 8 candidate sets, one per row. Each set's brief and recorded defect come from `job.json`.
- F41#2 shows its four phases as a 2×2 grid, and the brief names their order.
- F41#8 and F41#13 frames are stacked at full size.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This counts as a confirming batch.

**Fit:** linear, slope 1.3333, intercept −1.6702, r 0.928, anchor RMSE 0.516, no warnings. The capacitor anchor pair fits worst (residuals −0.69 and +1.05): these judges scored its r3 side well below its reference.

## Verdict: SHIP. F41#2 gains +0.80 and F41#8 +0.58 (3/3 each), F41#13 rides along at +0.23 (3/3), and the other rows are level

| Row | Subject | Base raw (a,b,c) → mapped | Arm raw (a,b,c) → mapped | Gain | Prefer arm |
|---|---|---|---|---|---|
| F41#2 | Surge phase presentation | 5.3, 5.1, 5.0 → **5.17** | 6.0, 5.6, 5.6 → **5.97** | **+0.80** | 3/3 |
| F41#8 | named character silhouettes | 5.3, 5.2, 5.0 → **5.22** | 5.6, 5.6, 5.6 → **5.80** | **+0.58** | 3/3 |
| F41#13 | electric creature finish | 5.5, 5.2, 5.6 → **5.57** | 5.7, 5.4, 5.7 → **5.80** | +0.23 | 3/3 |
| F41#6 | danger and opening cues | 6.3, 6.0, 6.0 → 6.46 | identical → 6.46 | 0 | tie |
| F41#12 | charged road surface | 5.5, 5.6, 5.3 → 5.62 | identical → 5.62 | 0 | tie |
| F41#19 | Glass Field spike bases | 5.6, 5.3, 5.3 → 5.53 | identical → 5.53 | 0 | tie |
| F41#4 | named destination identities | 5.5, 5.6, 5.5 → 5.71 | 5.5, 5.5, 5.5 → 5.66 | −0.05 | 0/3 (b +0.1 for base, a and c tie) |
| F41#5 | forest ground and distance layers | 5.3, 5.3, 5.3 → 5.40 | 5.4, 5.2, 5.2 → 5.35 | −0.05 | 1/3 (a); b and c +0.1 for base |

- **Ship rule:** two rows clear 0.5 with all three judges preferring the arm, and F41#13 gains under 0.5 inside the same change.
- **F41#4 and F41#5:** all three judges call the two sides "near-identical". The differences are single 0.1 steps, which I read as level, not as a loss. The arm keeps F41#5's stronger storm sky (judges a and c), while base keeps a slightly clearer distance band.
- **Recorded defects:**
  - F41#2: PRESENT 3/3 on base → PARTIAL 3/3 on the arm.
  - F41#8: base PRESENT 2/3 / PARTIAL 1/3 → arm PARTIAL 3/3.
  - F41#6: FIXED on both sides. No magenta slab appears in this single impact frame.
- **No row closes.** Every row is still below 6.5 on this batch.
- **Absolute level:** unchanged sides score about 0.8–1.0 below their board values (for example, F41#19 5.53 here against 6.56 on the board). This batch's judges read the whole Stormwood frame low. The gains are within-batch comparisons and stand. Treat these absolute values as a low reading, not as a re-score that replaces the board.

## What the judges say
- **F41#2, arm (3/3):** "Break shows visible lightning forks"; the "swirling violet sky" changes between phases. Fading is still close to Building (3/3).
- **F41#2, base (3/3):** "pale washed lilac", with phases "nearly indistinguishable". Base Fading has "flat opaque white-lilac blobs sitting on the ground around the trainer", which reads as a particle artefact. That artefact is on the overlay-off side, so the arm removes it.
- **F41#8, arm:** three distinct people: an elder, "a bearded armoured engineer" and "a young woman in a scarf". On base the elder silhouette appears twice (3/3). Judge c's earlier dissent from `G-meshy-f41-8-distinct-bodies.md` (shared tan-brown palette) did not come back.
- **F41#13:** the arm adds "fog and light shafts" (3/3). Stormraven is "flat saturated royal/cobalt blue with white flecks, not believable as a raven" on both sides (3/3). That is the ceiling, and it needs new art.

## What still holds the Stormwood rows down (top changes, all three judges)
1. **Ground (scene, 3/3):**
   - near-black mud and road surfaces with hard cut-out edges;
   - a flat green carpet with black blotch decals;
   - evenly spaced trees with a single flat purple treeline band.

   Judges ask for wet dark-umber road with puddle highlights, blended edges, terrain relief, and dense grouped groves. This affects F41#2, #4, #5, #8 and #12.
2. **Fights (scene, 3/3):** flat magenta telegraph rings and wedges, and canopy blocking the fight camera. These come from the capacitor anchor frames but describe live Stormwood fights. Judges also flag a beige or grey mat-like patch under Voltarach in F41#6 (3/3).
3. **Stormraven remake (new art, 3/3):** black feathers with blue arcs. Judge b would also remove the "bolt-on copper plates" from Fulgocobra.

Row-specific:
- **F41#19:** a tree trunk fills the right half of the frame and the trainer clips into the crystal cluster (3/3). The base defect is now PARTIAL, since rocks have replaced the flat disc. This is a capture-stand problem, not an art problem.
- **F41#12:** the gold line is thinner. Judges a and b mark it PARTIAL; judge c still sees "a thick saturated gold zig-zag" (PRESENT).
- **Other notes:**
  - Fading is still too close to Building (3/3), so the next phase step should brighten and clear Fading.
  - the salmon-pink bears in the F41#8 background (3/3);
  - judge c called the house door in the F41#13 frame "borderline" red-orange; it reads as wood.

## Recommendation
1. **Land the overlay.** F41#2 gains +0.80 and F41#8 +0.58 (3/3 each), F41#13 rides along, and nothing loses beyond 0.05.
2. **Next PLACES swing:** Stormwood ground and road value (change 1). It is the shared ceiling for every row here, and none of them can reach 6.5 without it.
