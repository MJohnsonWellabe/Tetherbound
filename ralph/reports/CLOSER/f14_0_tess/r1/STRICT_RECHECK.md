# Strict re-check, F14#0 Tess r1 (rubric C3_RUBRIC.md, bar BAR.md)

Inputs read: BAR.md, C3_RUBRIC.md, JUDGE_A.md, JUDGE_B.md, frames.json, and all 38 .jpg frames (each viewed).

## Verdict: the round PASSES the BAR pass line

Corrected: A 34/36 = 94.4%, B 34/36 = 94.4%, all 6 tell-starts marked. Even in the strictest reading (t-168.00 also FAIL) both are 33/36 = 91.7%.

## (1) Frame coverage: PASS
frames.json has 38 entries and the folder has 38 .jpg files, with no difference between the two sets. Each verdict table has exactly 38 rows, with no duplicates, none missing and none invented (checked by script).

## (2) Arithmetic: PASS
- Judge A: 33 PASS, 3 FAIL, 2 EXCLUDED (t-156.00, t-228.00). 33/36 = 91.7%, as stated.
- Judge B: 36 PASS, 0 FAIL, 2 EXCLUDED (same two). 36/36 = 100%, as stated.
- Both exclusions are legitimate: Riverdrake lying downed at t-156.00, Sirenseal at 0 HP with the "+bond - won" text at t-228.00.

## (3) Tell-start markings: PASS
Both judges count 6/6. There are 6 tell-start-*.jpg frames, and I viewed each one. Every frame shows a magenta ground marking.
- tell-start-000.33: magenta ring under the Mirejaw's rear and tail.
- tell-start-001.78: magenta arc under the Mirejaw.
- tell-start-081.35: magenta ring under the Riverdrake.
- tell-start-082.78: magenta ring behind and under the Riverdrake.
- tell-start-156.98: magenta ring at the Sirenseal's tail.
- tell-start-158.38: magenta ring at the Sirenseal's tail.

## (4) Rubric applied as written: my own calls

| Frame | A | B | Mine | Evidence |
|---|---|---|---|---|
| tell-start-082.78 | FAIL | PASS | FAIL (rule 4) | The enemy HUD panel's lower edge covers the Riverdrake's crest and the top strip of its head, with the "incoming" line over the crest. Eye and snout read, but the camera could have avoided the overlap. Marginal, and consistent with A. |
| hit-163.00 | FAIL | PASS | FAIL (rule 3, marginal) | Ripplet's head sits against the Sirenseal's snout, and the snout tip is hidden behind Ripplet's face. Eye and silhouette read. A's "half its face" overstates it. |
| t-168.00 | FAIL | PASS | PASS (borderline) | Only the crest tip at the right edge of the seal's head sits under the HUD panel corner. Face and forehead are clear, so the overlap is smaller than at 082.78. |
| t-000.00 | PASS | PASS | PASS | The Mirejaw's rear and tail are cut at the right edge, but the head and front half are on screen, so it is not "mostly off-screen". No head is covered, and the trainer stands beside the ally's tail. |
| tell-ended-000.65 | PASS | PASS | PASS | Both heads are clear, and the ally and trainer are apart from the Mirejaw. |
| tell-ended-002.08 | PASS | PASS | PASS | Same as above. |
| hit-004.43 | PASS | PASS | PASS | Ripplet's head is beside the Mirejaw's snout with no overlap. Trainers stand aside. |
| t-012.00 | PASS | PASS | PASS | Ripplet's cheek is adjacent to the Mirejaw's jaw and touches only. The trainer is clear. |
| t-048.02 | PASS | PASS | PASS | Same as t-012.00. |
| t-072.02 | PASS | PASS | PASS | The ally's head is clear of the Mirejaw's head. |
| hit-085.27 | PASS | PASS | PASS (borderline) | Ripplet's head top meets the Riverdrake's chin. The drake's head, eye and snout are uncovered. |
| hit-087.25 | PASS | PASS | PASS (borderline) | Same as hit-085.27. |
| t-132.02 | PASS | PASS | PASS | Ripplet's cheek touches the drake's snout tip. The head reads. |
| t-144.00 | PASS | PASS | PASS | The drake's crest touches the HUD panel's lower edge without being covered. Rocks are behind the head, not in front. |

The other 24 frames are PASS or EXCLUDED, matching both judges. I viewed each of them. Other Mirejaw frames I also viewed: t-024.02, t-036.02, t-060.02, hit-006.37.

- Trainer near an opponent's head: none covers one. The nearest is the trainer between Ripplet and the Mirejaw in tell-start-000.33, about 40 px from the snout, which covers nothing. So the beside-the-ally stand puts the trainer beside the ally, not over anyone's head.
- Ally-over-head on the Mirejaw: none. In every Mirejaw frame the ally is beside the head or just short of it.
- A head covered (rule 3) or a HUD panel covering a head (rule 4) that BOTH judges passed: only the marginal ones above. Both passed hit-163.00 (Ripplet touching the snout, overlap small) and t-168.00 and 082.78 (HUD overlap). By my reading, 082.78 and hit-163.00 are FAILs that B passed. I found no frame where both judges passed a head that is clearly covered.
- Camera inside geometry: none seen. Foreground boulders (bottom-left) cover no combatant.
- The 0.25 s occlusion clause is unverified (stills).

## Differences from the judges and corrected percentages

| Frame | Judge | Their call | My call |
|---|---|---|---|
| tell-start-082.78 | B | PASS | FAIL |
| hit-163.00 | B | PASS | FAIL |
| t-168.00 | A | FAIL | PASS (borderline) |

- Judge A corrected: 34 PASS, 2 FAIL out of 36, so 34/36 = 94.4%.
- Judge B corrected: 34 PASS, 2 FAIL out of 36, so 34/36 = 94.4%.
- Sensitivity: if t-168.00 is also a FAIL, both are 33/36 = 91.7%. If all three borderline frames are FAIL, 91.7% is still the floor. Every scenario clears the 90% line.

## Pass line result

- Judge A >= 90%: yes, 94.4%.
- Judge B >= 90%: yes, 94.4%.
- Every tell-start marked: yes, 6 of 6.
- BAR fail conditions: none triggered. No Mirejaw head is covered by the ally or trainer, the Mirejaw is not mostly off-screen, and no camera is inside a boulder or wall.
- Result: the round PASSES. The margin rests on borderline HUD and ally-overlap calls.
