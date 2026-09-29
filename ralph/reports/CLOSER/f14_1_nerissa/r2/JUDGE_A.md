# JUDGE_A - Nerissa r2 C3 framing (code-blind, C3_RUBRIC.md applied as written)

All 56 frames loaded on the first try (no retries needed).

| Frame | Verdict | Rule / note | Tell-start marking |
|---|---|---|---|
| t-000.00 | FAIL | 3: trainer stands directly in front of Cannonback's head/face | n/a |
| tell-start-000.27 | FAIL | 3: trainer covers Cannonback's head area (creature also clipped at right edge) | visible (magenta) |
| tell-ended-000.57 | PASS | shell-tucked own pose, orientation reads | n/a |
| tell-start-001.67 | PASS | | visible (magenta) |
| tell-ended-001.97 | PASS | | n/a |
| tell-start-003.03 | PASS | | visible (magenta) |
| tell-ended-003.33 | PASS | | n/a |
| hit-005.70 | PASS | | n/a |
| hit-007.55 | PASS | | n/a |
| t-016.00 | PASS | | n/a |
| t-032.02 | PASS | | n/a |
| t-048.02 | PASS | | n/a |
| t-064.02 | PASS | | n/a |
| t-080.02 | PASS | | n/a |
| t-096.02 | PASS | | n/a |
| t-112.02 | EXCLUDED | opponent at 0 HP, "+bond won" | n/a |
| tell-start-115.92 | FAIL | 1 (and 4): Mirejaw mostly off right edge, rest under boss HUD panel | visible only as a small sliver at right edge (extent not shown) |
| tell-ended-116.23 | PASS | curled own pose | n/a |
| tell-start-117.40 | PASS | | visible (magenta) |
| tell-ended-117.72 | PASS | | n/a |
| tell-start-118.88 | PASS | | visible (magenta) |
| tell-ended-119.20 | PASS | | n/a |
| hit-121.67 | PASS | | n/a |
| hit-123.55 | PASS | | n/a |
| t-128.02 | FAIL | 3: Mirejaw's head hidden behind Ripplet's head/ears | n/a |
| t-144.00 | PASS | | n/a |
| t-160.00 | PASS | | n/a |
| t-176.00 | PASS | Mirejaw clipped at right but head and body orientation read | n/a |
| t-192.00 | PASS | | n/a |
| tell-start-197.23 | FAIL | 4: Riverdrake's head/crest sits under the boss HUD panel | visible (magenta) |
| tell-ended-197.55 | PASS | | n/a |
| tell-start-198.72 | PASS | head just clear of panel edge | visible (magenta) |
| tell-ended-199.03 | PASS | | n/a |
| tell-start-200.12 | PASS | | visible (magenta) |
| tell-ended-200.43 | PASS | | n/a |
| hit-202.87 | PASS | | n/a |
| hit-204.75 | PASS | | n/a |
| t-208.00 | PASS | | n/a |
| t-224.00 | PASS | | n/a |
| t-240.00 | PASS | | n/a |
| t-256.00 | PASS | | n/a |
| t-272.00 | PASS | drake HP near zero but not 0 | n/a |
| tell-start-279.97 | PASS | | visible (large magenta) |
| tell-ended-280.07 | PASS | burst VFX overhead but head and tusks read | n/a |
| hit-280.13 | PASS | | n/a |
| tell-start-280.57 | PASS | | visible (large magenta) |
| tell-ended-281.17 | FAIL | 4: Riptusk head not readable, under top boss panel / bottom-right Orbs HUD; facing lost | n/a |
| hit-281.50 | PASS | | n/a |
| tell-start-282.47 | PASS | | visible (large magenta) |
| tell-ended-283.07 | FAIL | 4: Riptusk head not readable, under boss HUD panel / Orbs HUD (rear view) | n/a |
| t-288.00 | FAIL | 3: trainer stands in front of Riptusk's face/tusks (plus ice shard VFX) | n/a |
| t-304.00 | FAIL | 3: Riptusk overlaps Ripplet and a VFX burst hides both heads; facing unreadable | n/a |
| t-320.00 | PASS | | n/a |
| t-336.00 | PASS | | n/a |
| t-352.00 | PASS | | n/a |
| t-368.02 | PASS | camera hard against the wall and Riptusk's back under HUD, but head and tusks read | n/a |

## Result
- Excluded: 1 (t-112.02). Scored: 55. PASS 46, FAIL 9.
- **Framing = 46 / (46 + 9) = 46/55 = 83.6%** (below the 90% bar).
- Fails by rule: rule 1 x1, rule 3 x5 (t-000.00, tell-start-000.27, t-128.02, t-288.00, t-304.00), rule 4 x3 (tell-start-197.23, tell-ended-281.17, tell-ended-283.07), rule 5 x0. (tell-start-115.92 is counted once, under rule 1, with rule 4 also true.)
- **Tell-start markings: 12/12 visible** (115.92 is only a sliver at the screen edge; counted as visible, not clear).
- 0.25 s occlusion clause: unverified (stills).
