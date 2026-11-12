# Medium close-outs (F36#69 Solmane, F36#42 Cragclaw faint arm) and the F36#92 all-roles re-score

**Frames:** `tb/gpu-frames-1108`.
- `G-solmane-medium` (347eec615): main, Medium.
- `G-cragclaw-faint-medium` (2ec3fc87c): THINGS-FAINT overlay on, `--game-clips --clear-ruler --roles=hit,faint`, Medium.
- `G-water-mangrove-monitor-gameclips-rescore` (b7a256c4c): `tb/things` flags off, `--game-clips --clear-ruler`, all roles (hit, faint, swim), High.
- Blank frames: 0 of 10, 0 of 10 and 0 of 15.

**Sets:** one-sided, crop 560,200 1000×640, F36 (1) brief, recorded defects as in the High sets.
- Solmane and cragclaw: standing, hit 050, faint 050, faint 100.
- Water mangrove monitor: standing, hit 050, swim 050, faint 050, faint 075, faint 100.

**Batch `G-mx`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- **Fit:** slope 1.4922, intercept −2.8486, r 0.967, RMSE 0.253.
- **Warning:** solmane meets the bar only above the top anchor. This is the confirming batch.

## Results

| Row | High (earlier) | Medium / this batch | Raw a, b, c | Mapped per judge | Verdict |
|---|---|---|---|---|---|
| **F36#69 Solmane** | 7.63 (G-t4b) | **8.04** ↑top | 7.3, 7.1, 7.5 | 8.04, 7.75, 8.34 | **CLOSES** (High and Medium both at 7.5 or above; every judge at or above 7.75) |
| **F36#42 Cragclaw, faint arm** | 7.51 (G-fb) | **7.30** | 6.9, 6.6, 6.9 | 7.45, 7.00, 7.45 | **Does not close.** Medium is 0.20 short; a close-out candidate |
| F36#92 Water Mangrove Monitor, all roles | n/a | **6.60** (High) | 6.3, 6.2, 6.5 | 6.55, 6.40, 6.85 | in line with the 6.72 from the hit/faint-only capture |

**Solmane notes:**
- In both faint frames the wings stay fanned and bury the body and head, so the faint reads as "a pile of feathers" (3/3).
- No elemental trait is visible (judge b).
- Neither blocks the close.

**Cragclaw notes:**
- Both faint defects are FIXED 3/3: the shell rests on the ground and differs from standing.
- **What keeps Medium under 7.5:** the face is hidden under the shell in every frame (3/3). At 30% size it reads as "a boulder with legs", and the faint end as "an upturned bowl" or "withdrawn into the shell".
- **Next swing:** a faint end with the head out and visible on the ground.

## Water mangrove monitor: which faint does the game show? Belly-up, legs in the air, in both captures
- **Judges, all-roles capture:** in faint 075 and faint 100 the monitor "has flipped onto its back with the legs stiffly up and splayed" (3/3). They call it "roadkill", "comical" or "a rigid rotated mesh". It is grounded: the "does not reach the ground" defect is FIXED 3/3.
- **My eye check of the frames agrees:** the body lies flat with the feet pointing up above it and the crest underneath. That is belly-up, not belly-down.
- **Earlier capture:** the hit/faint-only capture (`G-water-gameclip-rescores.md`, 6.72) showed the same belly-up pose.
- **Conclusion:** the role order does not change this faint. **#92 does need a faint fix:** a side or belly-down slump with the limbs folded (3/3 top change). Faint mid is also still barely different from standing (2/3).

**Other notes on #92:**
- "Dark olive on grey" is PARTIAL 3/3.
- The face against the spines is FIXED on 1/3, PARTIAL on 2/3.
- Swim reads (2/3); judge c calls it semi-transparent and weak.
- Height against the trainer is borderline, about level (judge b).

**Owner rules:** no red on any of the three creatures.
