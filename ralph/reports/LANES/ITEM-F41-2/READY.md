STATUS: parked
BRANCH: tb/item-f41-2  HEAD: see the commit that adds this READY (pushed head)

Lane LANE-MESHY, F41#2 P2-042 Surge phase presentation (coordinator queue 8 Nov, item 1). **No change; nothing ships.**

## Diagnosis (main 972670fa, Struck Sentinel close, CPU, `qj/F41-2-base`)
Mean luma, sky (top third) / ground (bottom third):

| Phase | Sky | Ground |
|---|---|---|
| Calm | 108.5 | 79.3 |
| Building | 105.3 | 75.4 |
| Break | 90.8 | 56.5 |

- Break is already the darkest phase, with visible white-violet bolts. The scout's "Break ground as bright as Calm" does not hold in today's frame. Fading is not in the judged set.
- The defect is **Calm and Building look alike** (Building has only a little more rain).

## What was tried / ruled out
- Darker and cooler Building with a brighter Calm grade is `presentation.phase_grade_1104`, already judged twice and parked by VIS-STORMWOOD (5.46 -> 5.46, then 4.40 -> 4.23). Its r2 also carried the per-phase rain split (Calm 0.18, Building 0.9). Not repeated.
- `presentation.building_glow_1104` r2 (Building in-cloud sheet lightning reaching the horizon band, glow_low 0) was built 4 Nov and never judged. Visibility check `qj/F41-2-bglow`: Building changes **0.30% of pixels (>12 luma)**, the same as the Calm run-to-run noise (0.29%). It is invisible at these stands, like r1. Not judged.

## Why parked
Both config levers (grade, in-cloud glow) are spent on this stand. Under the stop rule F41#2 waits for a new idea.

**New-idea candidates (untested):**
- A distant rain curtain or cloud wall on the horizon that exists only in Building. It is a world object, not a grade, and the close stand shows a wide horizon band.
- Building-only wind cues readable in a still: bent grass cards or flying leaves.

Both need code, so they are not config-scale.

## Files
`ralph/reports/LANES/ITEM-F41-2/READY.md` only.
