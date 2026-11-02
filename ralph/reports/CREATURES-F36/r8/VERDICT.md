# CREATURES-F36 r8: hit react on the remakes' own clips, via a clip flag (CPU, three judges)

**Verdict:** Cindercub and Trailpup ship as arm `tb/co-f36-6-on` 66dc86a09, built on CO-F36-5 (control: main a41e1b30), under the owner's near-bar close-out exception. Their gains are under 0.5, but both are near-bar items (GPU 7.13 / 7.00) and the hit defect clears. Bramblebun and Duskhush are left out.

**Target:** GPU ROSTER-1 High (31 Oct) item 1, hit react PARTIAL 3/3. Bramblebun's hit "looks airborne, a hop"; Cindercub, Trailpup and Duskhush "barely differ from standing". These four play their own remake clips, so the recipe flinch cannot reach them.

| Species | Clip scale (rotation / position) | Mapped main | Mapped arm | Gain | Hit defect (main / arm) |
|---|---|---|---|---|---|
| **Cindercub** | 1.6 / 0.5 | 6.69 | **7.04** | +0.35 | PARTIAL x3 / FIXED x2, PARTIAL 1 |
| **Trailpup** | 1.6 / 0.5 | 6.69 | **7.00** | +0.31 | PARTIAL 2, PRESENT 1 / FIXED x2, PARTIAL 1 |
| Bramblebun | 1.0 / 0.2 | 7.04 | 7.15 | +0.11 | PRESENT 2, PARTIAL 1 / PARTIAL x3 |
| Duskhush | 1.6 / 0.5 | 6.65 | 6.69 | +0.04 | FIXED x2, PARTIAL 1 / FIXED 1, PARTIAL 2 |

**Fit:** linear, slope 1.17, intercept −0.92, r 0.79, RMSE 0.58. Confirming batch (craft, f36_0_npc:C1). The r is the weakest of this lane's batches, so read gains under 0.4 as near noise.

**Arm shape:**
- Flag-off code: `_apply_clip_flags` in `scripts/creatures/creature_body.gd`, run at animator build.
- Config: `data/config/creature_clip_flags.json`, flag `creatures_f36_grounded_hit_remakes`, `enabled` false.
- An enabled flag scales the named role's rotation and position keys relative to the clip's first key, in a per-body copy of the library. The shared import is untouched.
- No re-import is needed.

**Tests:** `test_companion_presence`, `test_creature_rest_pose` and `test_remote_stagger_wince` pass with the flag on and with it off (47 + 2 tests, 0 failed).

**Not shipped:**
- **Bramblebun:** the judges still read the planted, splayed hit as a kick or jump; the pose itself, not the root lift, is what reads as a hop.
- **Duskhush:** its main hit already rears enough for most judges, and the exaggeration twisted the wing.

Sheet `_sheet_r8.jpg`: main on the left, arm on the right; rows are Cindercub and Trailpup.
