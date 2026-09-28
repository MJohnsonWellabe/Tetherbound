# Round 2 (commit b2ce4df6): opponent spacing and reach floored at the rendered separation

Fixed rubric: `ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md`. Judges were code-blind subagents that saw the frames only and made a single pass.

## Judge A (sonnet)

**Tess r7:** 35/38 (92.1%). `t-168.00` is excluded (Riverdrake knocked out). Tell rings 3/6.
- Failures: rule 5 on `tell-start-000.38`, `tell-start-001.80` and `tell-start-169.37` (no ring seen).
- No head occlusion. "The two creatures are consistently posed side-by-side with a clear gap."
- Contact at the hit moment: `hit-006.33`, `hit-174.68`, `t-060.02`.

**Nerissa r19:** 42/46 (91.3%). Tell rings 8/8.
- `t-288.00`, `t-304.00`: rule 3, the crate hides Riptusk's head.
- `tell-ended-269.33`: rule 1, Riptusk is mostly off-screen.
- `tell-start-268.73`: rule 1, Riptusk's reared head is cropped at the top edge.
- "Ally merely in front of the opponent's head on screen: not observed."

## Judge B (default model)

**Nerissa r19:** 40/46 (87.0%). Tell rings 8/8.
- `tell-ended-113.03`, `t-160.00`: rule 3 (borderline), the crate covers Mirejaw's head.
- `tell-ended-269.33`: rule 1, Riptusk is off-screen right.
- `hit-269.67`: rule 3 (borderline), the player's trainer covers Riptusk's forehead.
- `t-288.00`, `t-304.00`: rule 3, the crate hides Riptusk's head.
- No failure is the ally in front of the opponent's head.
- Contact at the hit moment: Ripplet's face at Mirejaw's open mouth (112.12, 112.18, 115.40, 144.00, 176.00), and Ripplet's head against Riverdrake's chin (240.00).

**Tess r7:** only 15 of 39 frames loaded on the first run (image request limit). All 15 passed (100%, 1 excluded), with tell rings 2/2. The other 24 frames were re-judged separately; the result is below.

**Tess r7, the 24 frames re-judged:** 17/24. Tell rings 4/4.
- `hit-004.45`, `t-012.00`, `t-072.02`, `t-084.02`: rule 3, Ripplet's head is in front of Mirejaw's face. The logged gaps are 8.43, 8.02, 8.24 and 8.02 m, which is the full rendered separation (8.03 m).
- `tell-ended-000.70`, `tell-ended-002.10`: rule 3, the player's trainer stands in front of Mirejaw's head.
- `t-048.02`: rule 1, Mirejaw is mostly off the right edge.
- The Riverdrake segment is 10/10.

**Judge B, Tess r7 combined: 31/38 (81.6%).**

## Reading
- **Nerissa.** No ally-over-opponent-head failure remains for either judge; judge B had 5–8 of them before.
- **Tess.**
  - Judge A finds none. Judge B still finds 4, all Mirejaw, and all at the separation the rule enforces.
  - With the bodies held at their full rendered separation, the remaining stacking comes from the fight camera sitting behind the ally and looking along a long opponent's axis. That is composition, not interpenetration.
  - This is the second attempt on this measurement, so no third spacing change was made. The residue goes to the camera and Tidewake owners, together with the trainer standing between the fighters.
