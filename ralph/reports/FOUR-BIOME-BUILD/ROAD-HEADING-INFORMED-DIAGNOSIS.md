# Road heading reproduction: informed diagnosis

2026-09-09. Astra source/runtime triage; this is not a blind visual verdict.

The partial graphical run `shots/road-heading/20260909T034351Z` produced two
1280x720 frames at historical sample 37, then stopped before sample 38. It did
not reproduce the full segment. The original logs and manifest remain local.

## What changed the diagnosis

The same grounded trainer position `(15.66165,-0.02175,15.83778)` produced zero
observer-credited bodies at recorded yaw -17.1004 degrees and three at yaw
167.3549 degrees, using ordinary look input. The named Meadowhart pair remained
alive in both observations. With the second heading, the first member was
framed and centre-ray clear; the second was framed but its centre ray hit the
first member. This supports the camera-heading explanation at this one point.
It does not prove silhouette readability, every road sample, or an art pass.
The direction was the historical outgoing waypoint bearing: the attempted
walk did not complete, so it cannot certify the intended complete travel leg.

The physical render target was 1280x720 while the camera's logical viewport was
1920x1080. These are distinct coordinate spaces under the configured stretch.
The first attempt had incorrectly required the logical viewport to equal the
output size and stopped with no frames. The corrected attempt retained logical
coordinates for projection and checked the actual render output separately.

## The walk stop is a prerequisite mismatch

The second attempt walked 79.741 accumulated metres but ended 4.647 metres
from sample 38 after its unchanged 1200-frame leg budget. Final grounded XZ
was `(12.39336,21.03005)`, immediately inside the configured TrailGate at
`(13.79,22.4)`. The boundary configuration explicitly places that gate on the
same corridor spine as these samples.

The historical campaign had already earned and consumed the key:
`.artifacts/wave4-fresh-camp-lesson.log:206`. Lines 283 and 285 separately
record its TrailGate route and successful crossing. The new capture helper
resets to a fresh game and establishes sample 37 using one disclosed debug
travel; it neither earns the key nor sets `road_gate_open`.
`scripts/world/village_boundary.gd::_build_gates` binds every village gate to
that shared flag, and `scripts/world/road_gate.gd::restore_progression_from_game`
opens its leaf only when the flag is present.

The strongest supported cause is therefore the fresh fixture approaching an
intentionally locked gate that the historical campaign had opened. The run
did not record the final collider or gate-state value directly, so the exact
collision attribution remains unmeasured. It is not evidence that production
navigation or the gate geometry needs changing. No flag injection, gate
removal, extra retry, or larger walk budget is an acceptable closure.

## Separate capture metadata defect

The retained stderr reports repeated calls to a nonexistent
`day_cycle.gd::time_of_day` method from `_clock_snapshot`; resulting clock
receipts are empty. The images still exist with manifest hashes, but exact
simulation time/weather is not established by those receipts. This is a local
capture-tool API error, not evidence of a production clock failure. Any static
helper correction after this run must be identified as unexecuted in this run.

## Disposition

Stop this reproduction after the two attempts. Submit only the two retained
images to a fresh code-blind critic, with no source, history or desired answer.
Keep the full-road visibility requirement open. A later continuity proof must
arrive through ordinary earned village access; it must not treat a fresh reset
at a historical coordinate as equivalent campaign state. Continue the separate
Stormwood content lane while this partial evidence is judged.

## Independent image verdict and informed disposition

`REJUDGE-ROAD-FRAMES.md` is the fresh critic's unchanged report. Both frames
answer A yes, B no, shipping readiness no. These narrow-view answers do not
replace the 116-frame catalogue verdicts. The critic could not confidently
identify the distant pale forms as creatures, people or props, and found no
assessable foreground companion. This is an important limit on the observer's
three-body count: its credited Bramblebun, Pipwing and Meadowhart are about
52.8, 61.3 and 66.5 metres away, with projected heights of 21.3, 17.7 and
28.6 pixels at 720p. Their presence and centre-ray clearance do not prove the
owner's readable-creatures-ahead experience. Do not lower or replace the bar
with a numeric probe pass.

The full rubric also repeats ground/foliage noise, weak depth/destination,
trainer differentiation and intrusive empty HUD slots. These map to the
already-recorded G/D/K/U families in `audit-resume/VISUAL-TRIAGE-REVERIFY.md`:
shared ground/scatter, atmosphere and interface presentation with local road
composition; cast-art residual conditional on identified installed assets.
The images establish no new gross scale contradiction, terrain seam or
production traversal defect. Growing remains the only permitted scale remedy,
but no scale edit is justified by these distant silhouettes.

The next ROAD acceptance evidence must show readable living creatures during
ordinary earned road travel, including natural heading changes. This attempt
has isolated camera sensitivity and the fixture's locked-gate mismatch; it
has not justified global population inflation, a new art purchase, or another
cosmetic loop. The full ROAD requirement remains open alongside the existing
local scarcity and occlusion findings.
