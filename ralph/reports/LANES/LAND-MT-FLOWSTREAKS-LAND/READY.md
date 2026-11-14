# READY: tb/land-mt-flowstreaks-land

STATUS: land. GPU-judged ship (LANE-JUDGE G-land-mt-flowstreaks-r2, tb/judge d416990ff, 13 Nov).

**Verdict.**
- F13#5 5.70 -> 6.55 (+0.85, 3/3), clearing 6; crescents PRESENT -> PARTIAL 3/3.
- F39#16 / F39#17 current states level by construction (pixel diff 0.56-0.78).

**What.** `current_flow.lesson_cue` ON. Only the four swim-lesson current lanes (First Shore to Reedhaven and Reedhaven to Brine Steps, sheltered and direct) drop their chop-cap crescents, which the judges read as "decals or a debug overlay". The view marks those lanes with vertex alpha 0 and sets `lesson_chop_scale` 0. Every other lane keeps the shipped current look. Presentation only.

**Files.**
- `shaders/water_current_flow.gdshader`: `lesson_chop_scale`, gated by COLOR.a.
- `scripts/world/water_current_flow_view.gd`: lesson lanes get alpha 0, and the view sets the uniform.
- `data/config/water_veilfall.json`: the `current_flow.lesson_cue` block with `_why_on`.
- `tests/test_current_lesson_cue.gd`: the pin. It checks the flag ships ON, `_why_on` cites the verdict, only the lesson lanes are marked, and OFF is unchanged.

**Tests run** (headless; this branch's config and test run on the lane checkout, which has identical current code): 10 tests, 154 assertions, 0 failed.

| Test file | Tests | Assertions |
|---|---|---|
| `test_current_lesson_cue.gd` (pin) | 1 | 12 |
| `test_water_current_flow_states.gd` | 6 | 120 |
| `test_water_current_cue.gd` | 3 | 22 |

**Next asks from the verdict (lane follow-up, not in this branch):**
- stronger current-aligned streaks;
- a V-wake instead of the spoked ring;
- the shoreline seam in two views;
- the swimmer's legs, which belong to LANE-BEINGS.
