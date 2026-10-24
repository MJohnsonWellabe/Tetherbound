# r6 (24 Oct 2026, CPU): F36#1 whole-roster pose verdict, batch 6 of 7 (land head, shipping state)

Same method as r4/r5: shipping-state tiles with identical A/B sides, JUDGE_PROMPT.md verbatim, three fresh code-blind judges, and anchors Grandpa face (f36_0_npc:C1), craft and the Stormwood fight pair. This is a confirming batch. Fit: linear, slope 1.051, intercept 0.200, RMSE 0.70, no warnings.

Pass rule: no judge marks an applicable pose PRESENT, and the mapped mean is at least 6.7 (CPU-provisional). Swim applies to water_* forms. A form without a swim clip fails swim.

| Species | Mapped | Hit | Faint | Swim | Verdict |
|---|---|---|---|---|---|
| cloudfang | 7.28 | Pa x3 | F x3 | | pass (pounce-like hit) |
| skyrill | 7.14 | Pa x3 | Pa x3 | | pass (tail stays up in the faint) |
| breezetail | 7.10 | Pa/F/F | F x3 | | pass |
| aeriex | 7.07 | Pa x3 | Pa x3 | | pass (head up in the faint, wing clips the body) |
| cliffspike | 6.86 | Pa/Pa/F | F/Pa/Pa | | pass (hit reads as a hop) |
| ribbonray | 6.47 | Pa x3 | F x3 | | FAIL: score (flat magenta, weak face) |
| water_riptusk | 6.47 | Pr x3 | Pa/Pr/Pa | no clip | FAIL: hit identical to idle, no swim clip |
| tempestwing | 6.33 | Pa x3 | F/Pa/Pa | | FAIL: score (stilt leg under the standing pose) |
| water_cannonback | 6.19 | Pr x3 | Pa x3 | no clip | FAIL: hit identical to idle, no swim clip, muddy shell |
| solmane | 5.81 | Pa x3 | Pr/Pa/Pr | | FAIL: faint reads as a pounce crouch (staging: no ruler in frame) |

Raw scores: raw_scores.json. Mapping: mapped.json. Codes: key.json.
