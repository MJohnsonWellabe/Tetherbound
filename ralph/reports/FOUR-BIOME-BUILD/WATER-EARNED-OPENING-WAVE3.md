# Earned Water opening extraction — 2026-09-08

`tests/helpers/water_earned_opening_segment.gd` accepts the actual retained Water
scene after the physical Waterward gate. It requires completed scene entry,
consumed world Water key, persisted world gate/reveal receipts, the natural
grounded First Shore position and five distinct retained creature identities.
Actual negative RefCounted instance IDs are accepted. No reset, save binding,
realm assignment, scene instance, party/tool grant, hotbar assignment or pose
injection is reachable. The existing chapter-entry wrapper was not changed.

The helper extracts only the ordinary Pell/lesson sequence from
`tests/smoke_water_opening_continuous.gd`: eight grounded stance candidates and
exact arbiter activation; at most30 dialogue inputs and earned briefing; actual
lesson start, first/last surface points and dry end landing; at most2400 frames
per swim leg and at least50 metres measured only while SwimController reports
swimming. It retains the ten-minute lesson ceiling at the original1x/60Hz clock,
restores previous clocks/input and disconnects its arbiter observer on return.

Walking uses the same navigator step policy, original distance*65/min1200 frame
budget, held-frame limit, one-metre acceptance and zero-confined-reset criterion.
The loop is stepped locally to enforce the total deadline even while movement is
blocked; it fails immediately when a confined reset would become necessary.
Swimming transforms the desired direction through the current camera basis and
sends actual left-stick input instead of copying the wrapper's camera-yaw write.

The endpoint is lesson complete before Reedhaven. Public game/world/player/camera
handles and result.tree support the existing suffix API
`setup(tree, world, player, camera)` without constructing another fixture.

Validation: parser clean. Final focused5 tests/71 assertions/0 failed, no script
or engine errors: `%TEMP%/wave3-earned-water-opening-focus-r2-{console,engine}.log`.
Tests cover real CreatureInstance identities, camera-relative input direction,
entry refusal, source/evidence limits and actual world flag scope. The first test
attempt used the wrong JSON scope key and emitted one SCRIPT ERROR; it was fixed
to the production `ids` key before the final clean run.

No world run was launched. This is source/focused proof only: natural Waterward
arrival, Pell interaction and the extracted swimming sequence still require an
earned campaign run. No Reedhaven or later Water work is executed by this helper.
