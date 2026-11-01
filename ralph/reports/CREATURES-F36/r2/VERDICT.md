# CREATURES-F36 r2: Cragclaw and Skyrill side-lie faints vs main (CPU, three judges)

**Verdict: GPU READY.** Arm `tb/co-f36-1-on` e5667aecd vs main 3a0e1fa0d. The only change is the two faint recipes in `data/creatures/f36_pose_candidates.json`.

| Form | Mapped main | Mapped arm | Gain | Defect (main / arm) |
|---|---|---|---|---|
| Cragclaw | 5.71 | **6.24** | **+0.53** | faint same as standing PRESENT x3 / PARTIAL x3 |
| water_cragclaw (plays Cragclaw's recipe) | 5.71 | **6.24** | **+0.53** | PRESENT x3 / PARTIAL x3 |
| Skyrill | 6.00 | **6.53** | **+0.53** | head and sail up PRESENT x3 / **FIXED x3** |

**The change:** the faint pivot rolls 70° (smoothstep to phase 0.75) on top of each recipe's existing fold. The back faces the stage camera; −80° showed the pale belly, which read as belly-up in an earlier round. The grounded-role contact solve keeps the posed body on the floor.

**Fit:** linear, slope 1.23, intercept −1.03, r 0.90, RMSE 0.41. Confirming batch: craft and f36_0_npc:C1 are included, top anchor 7.53. No warnings.

**Capture:**
- `capture_f36_poses.gd --candidate --whole-body --context`, CPU, Compatibility, 1280x720.
- Main: `--source-commit` 3a0e1fa0d.
- Candidate frames come from the lane tree with only these two recipe edits differing from main for these species. The pushed arm holds exactly those edits.

**Tests:** `run_tests --only=test_f36_pose_candidates.gd,test_skyrill_replacement.gd` on the arm's recipe file: 2 tests, 19 assertions, 0 failed.

**What the judges still see (path to 7.5):**
- **Crab:** it tips back onto its shell edge with its legs in the air. The faint reads now, but it "rears" and the shell rides high rather than settling. A smaller roll with the legs folded, or a forward slump, is the next swing.
- **Crab model:** a noisy barnacle shell, no readable face and rubbery limbs. This is a model and material issue, not a pose one.
- **Skyrill:** faint mid hangs above its shadow, the belly-up flip reads a little cartoonish, and the skin reads chrome and plastic (the GPU roster's R4).

**Screened and rejected (never judged; the rolls made each worse on sight):**
- Fulgocobra: the coil stands on edge, and lowering the hood through the neck bone barely moves it.
- Glimmermoth and Tempestwing: their wings stand vertical.
- Torrentoad, Ashtusk, Abyssal Guardian and its water form, Sparkit, Shadelet: limbs or tail flip into the air.

Sheet `_sheet_r2.jpg`: main on the left, arm on the right; rows are Cragclaw and Skyrill. Tiles: standing, hit 050, faint 050, faint 100.
