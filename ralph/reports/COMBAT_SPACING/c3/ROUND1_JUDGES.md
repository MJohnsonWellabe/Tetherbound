# Round 1 (commit 9b3d0cca, separation capped at the 2.75x collider floor)

Fixed rubric: `ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md`. Judges were code-blind subagents that saw the frames only.

| Round | Judge A (sonnet) | Judge B (default model) |
|---|---|---|
| Tess ordinary route (`tess_route_r6`, 38 frames) | 38/38 (100%), tells 6/6 | 28/38 (73.7%), tells 6/6 |
| Nerissa (`nerissa_r18`, 47 frames) | 41/47 (87.2%), tells 8/8 | 31/46 (67.4%), tells 8/8 |

**Judge B's failures.**
- Tess: 8 rule-3 failures, all Ripplet's head in front of the opponent's face at contact (t-000, hit-004/006, t-012, t-072, hit-089, t-144, hit-165), plus 2 HUD-edge failures (t-156, hit-164).
- Nerissa: 8 contact-range rule-3 failures (Mirejaw at 111-176 s, Riverdrake t-224, Riptusk t-320); 4 stone-block occlusions (t-032, t-048, t-064, t-352); 3 camera-in-ally failures (tell-ended-261, hit-261, t-304).

**Diagnosis.** The logged centre gaps on the contact failures were 6.99-7.5 m, which is exactly the cap. Water Mirejaw's rendered half-length is 5.49 m and Ripplet's is 1.94 m, so clearing them head-on needs 8.03 m. The cap, (1.18 + 1.37) × 2.75 = 7.01 m, held them about 1 m into each other.

**Fix (round 2).** The cap is removed. Instead:
- the opponent's `preferred_range` floors at the rendered separation;
- every reach floors at the pair's longest separation plus 0.5 m.
