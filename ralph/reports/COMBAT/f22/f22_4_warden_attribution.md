# F22#4 Warden C3 single-hit attribution

Run: `smoke_meadows_named_c2c3 --case=warden`, 12 seeds per starter and pilot.
The switching reader is used for READER rows. Each run records its worst
incoming hit (foe, move, target, type multiplier) through
`combat_depth_pilot.gd` `max_hit_by`.

| Starter | Masher max hit | Verdict |
|---|---|---|
| terrapup | 0.502 | FAIL (≥0.50) |
| ripplet | 0.510 | FAIL (≥0.50) |
| galewisp | 0.495 | PASS |

Readers win every run. Lead-faint rates for the switching reader:

| Starter | Lead-faint |
|---|---|
| terrapup | 0.08 |
| ripplet | 0.00 |

The worst hits in all three starters' masher runs are the same blow every
time: the Warden's **tuskroot `earth_fist` into the retained pipwing**, with a
type multiplier of **1.25**. Hit sizes: 0.510, 0.502, 0.500, 0.499, 0.497,
0.495, 0.492, 0.472.

This is a super-effective matchup, not a neutral one. Plan (a) trims a
member's authored power only for a neutral-matchup overshoot, so no
data change was made. The overshoot is 0.2–2% above the bar, and it comes
from the fixture leaving a weak-to-earth retained creature in the line of a
charging blow.

Owner/coordinator choice:

- Trim tuskroot anyway (a ~3% power cut clears it).
- Rule that the C3 single-hit bar applies to neutral matchups only.
