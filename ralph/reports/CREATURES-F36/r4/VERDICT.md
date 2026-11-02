# CREATURES-F36 r4: Sirenseal grounded hit, Torrentoad flinch and slump vs main (CPU, three judges)

**Verdict:** Sirenseal is GPU READY as arm `tb/co-f36-2-on` 505bc2e5f (control: main a41e1b30). Torrentoad shows no gain and is dropped.

Targets come from the coordinator's GPU ROSTER-1 verdict (High, 31 Oct):
- **Sirenseal 6.81:** "hit react barely differs from standing", PARTIAL 3/3. Its whole body leaves the floor.
- **Torrentoad 6.50:** hit react PARTIAL 3/3, and the faint is "the same upright crouch as standing".

| Form | Change | Mapped main | Mapped arm | Gain | Defect (main / arm) |
|---|---|---|---|---|---|
| **Sirenseal** | hit pivot rotation at 15%, body recoil at 70% | 5.90 | **7.14** | **+1.24** | whole body off the floor PRESENT x3 / **FIXED x3** |
| Torrentoad | hit neck/head/spine x2; faint pitches over 8° with the neck dropped further | 6.95 | 6.86 | −0.09 | hit PARTIAL x3 / PARTIAL x3; upright faint PARTIAL 2, PRESENT 1 / the same |

**Fit:** linear, slope 1.43, intercept −2.46, r 0.95, RMSE 0.41. Confirming batch (craft, f36_0_npc:C1). No warnings.

**Why Sirenseal floated:** its long body pivots off the tail tip. Main's rear-up pitch (−18.8°) lifts everything else clean off the stage. Even halving it left the body in the air on CPU screening. With 15% of the pivot and 70% of the bone recoil, the chest and head rear back while the belly and tail stay down.

**Arm shape (coordinator process, 31 Oct):**
- Flag-off code: a `candidate_role_flags` hook in `creature_pose_candidates.gd`.
- One flag in `f36_pose_candidates.json`: `creatures_f36_sirenseal_grounded_hit`, with `enabled` false.
- Land Sirenseal only. water_sirenseal (GPU 7.27, hit FIXED) keeps its recipe.

**Tests:** `test_f36_pose_candidates.gd` passes with a flag on and with it off.

**Torrentoad:**
- The stronger head snap is visible, but the judges still call the hit PARTIAL.
- The +8° faint pitch drops the head and chest, but a hind leg kicks up. +15° and −15° screened worse (rump up, or rearing back).
- Stop-rule count: round 1 under 0.5. Its faint needs authored leg folds.

Sheet `_sheet_r4.jpg`: main on the left, arm on the right; rows are Sirenseal and Torrentoad. Tiles: standing, hit 050, faint 050, faint 100.
