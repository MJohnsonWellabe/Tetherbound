# GPU arm round 1108, G-npc-floor: rank emission floor off (captain only, and all ranks), plus the F38#1 ghost-glow recheck (GPU High plus ghost-glow, mapped)

**Verdict:**
- **The rank-floor arms do not fix Marrow.** On the Marrow rows both arms lose slightly:
  - F41#15: −0.14 for both arms.
  - F41#7: 0.00 (captain) and −0.09 (ranks).
  - All three judges still describe Marrow's head as "blown out to a glowing white ball" on both sides.
- **Turning off every rank's floor does help the Tidewake grunts.**
  - F39#18 (Bex, Irva): +0.28, 3/3 prefer.
  - F39#29: +0.14, 2/3 prefer.
  - That passes the ship rule on those two rows, but it costs the Marrow rows a little.
- **The F38#1 recheck on the ghost-glow state gains +0.47 (3/3) over the F-meadows frames.**
  - The see-through faint is **gone for the Terrapup frames** (1–2). All three judges say the old side's body is a pale silver-blue smear, while the new side's darker body separates from the grass with a readable head.
  - It is **not gone in frame 3** (Veridian fainted). All three still see a white, spiky, wispy shape sitting above the grass on both sides. The defect stays PARTIAL 3/3.

| Pair | Row | Live | Arm | Gain | Prefer arm | Ship rule |
|---|---|---|---|---|---|---|
| npc-floor-captain (captain floor 0, captain_a/b emission off) | F41#7 Marrow | 6.76 | 6.76 | 0.00 | 1/3 (1 level) | No |
| npc-floor-captain | F41#15 Marrow and Nysa | 6.67 | 6.53 | −0.14 | 0/3 | No |
| npc-floor-captain | F39#29 Nalia and Nerissa | 5.74 | 5.65 | −0.09 | 1/3 | No |
| npc-floor-ranks (captain, grunt, officer floors 0, captain_a/b emission off) | F41#7 | 6.76 | 6.67 | −0.09 | 1/3 | No |
| npc-floor-ranks | F41#15 | 6.62 | 6.48 | −0.14 | 0/3 (1 level) | No |
| npc-floor-ranks | F39#29 | 5.70 | 5.84 | +0.14 | 2/3 (1 level) | Passes (small) |
| npc-floor-ranks | **F39#18 Daro, Bex, Irva** | 6.76 | **7.04** | **+0.28** | **3/3** | **Passes** |
| F38#1 recheck (ghost-glow state vs F-meadows frames) | **F38#1 faint and rest** | 6.11 | **6.58** | **+0.47** | **3/3** | Improved (see note) |

**Per judge, mapped (live → arm):**

| Pair | Live | Arm |
|---|---|---|
| armCap F41#7 | 7.36 / 6.11 / 6.81 | 7.08 / 6.11 / 7.08 |
| armCap F41#15 | 6.94 / 5.97 / 7.08 | 6.81 / 5.84 / 6.94 |
| armCap F39#29 | 5.84 / 5.56 / 5.84 | 5.56 / 5.84 / 5.56 |
| armRanks F41#7 | 7.36 / 6.11 / 6.81 | 6.94 / 5.97 / 7.08 |
| armRanks F41#15 | 6.94 / 5.97 / 6.94 | 6.67 / 5.84 / 6.94 |
| armRanks F39#29 | 5.84 / 5.56 / 5.70 | 5.84 / 5.84 / 5.84 |
| armRanks F39#18 | 6.53 / 6.81 / 6.94 | 6.94 / 6.94 / 7.22 |
| F38#1 recheck | 6.25 / 6.25 / 5.84 | 6.81 / 6.67 / 6.25 |

**Notes:**
- **F38#1 control:** the "live" side for F38#1 is the F-meadows F38#1 frames (tree be95950b, before ghost-glow), at the paths the GPU lane restored in d1b60a49. This batch scores that side at 6.11. In F-meadows it scored 5.76, on another batch's scale.
- **What is left on Marrow's head.**
  - The cause analysis listed the steps the b5a5aabb crash skipped: the albedo grade, emission opt-out, rank emission floor, day rim and metallic fix.
  - Every arm so far has addressed one of the first four: the albedo grade (npc-albedo), emission opt-out (npc-emission-off), the floor (this round) and the day rim (stripped in npc-albedo). None of them darkened the head.
  - **The one step left is the GF-B-010 metallic fix (step 6).** The imported glb has no `metallicFactor`, so glTF's default 1.0 applies, and the fix forces it to 0. A fully diffuse pale head under the Forward+ key light and glow reads white. The crashed frames kept metallic 1.0, which is why they looked dark.
  - **Suggested next arm:** keep the fix but give captain_a and captain_b's body a `finish` with `metallic` around 0.3–0.5 and roughness about 0.7. That needs a body-finish config key, if one exists, or a two-line code path. Alternatively, test a darker head and hair region in the albedo.
  - Restoring metallic 1.0 everywhere would bring back the black-silhouette bug, so don't.
- **Also seen by all three judges:**
  - Nerissa's pale in-world model does not match her dark-bearded portrait. This is identity, not light.
  - Nysa's model reads as a re-tint of Marrow's armour.
  - A flat purple light slab lies on the Marrow deck (two judges).

## Method
- **Frames:** `tb/gpu-frames-1108`, GTX 1060, Forward+ High.
  - `G-npc-floor-captain` (e2594e9d) and `G-npc-floor-ranks` (f45c4d2f): main ba6778f45 plus ghost-glow plus the coordinator overlays `npc_floor_captain.json` / `npc_floor_ranks.json`. The live set is G-npc-albedo's.
  - `G-recheck-f38-1` (71d0c237): main ba6778f45 plus ghost-glow.
- **Judging:** one batch, `G-floor`, of 8 pairs. Three fresh code-blind judges, standard JUDGE_PROMPT and 3 pinned anchor pairs. Sides were shuffled with the key kept outside.
- **Fit:** `calibrate.py` linear, slope 1.387, intercept −1.931, r 0.902, anchor RMSE 0.499. Confirming batch; no warnings. Read gains within the batch.
- **Defect key:** one judge abbreviated the recorded defect keys. Its scores are unaffected, and its defect calls match the other two.
- **Judged by:** LANE-SCOUT, 9 Nov 2026 ~07:30 UTC.
