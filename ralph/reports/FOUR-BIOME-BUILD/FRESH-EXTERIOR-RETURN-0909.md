# Fresh campsite exterior return — 2026-09-09

Status: planner correction passes focused native unit tests; physical traversal
and continuous fresh rest remain unproved. No production gate or player change.

## Preserved failure

The detached `Tetherbound-opening-prefix-d3cdb57` run
`.artifacts/opening-prefix-c3e-0909/fresh-through-rest-aim-lifecycle-1200`
ended after 566.782 campaign seconds with the actual campsite catalogue funded:
wood 19/18, fiber 18/18, stone 8/8. It failed returning to the build patch,
before emitting a return `EARNED WALK START`, at frame 28872 and player
`(-33.8717, 4.537687, -51.71674)`. Five team members had been earned.
This diagnostic did not reproduce the preceding empty-preview catch failure;
that earlier failure remains unresolved, not fixed by this run.

Independent source attribution confirms the helper refused the route before
walking: all three straight exterior approaches cross the village polygon.
Even assuming all gates open, none passes the original straight-chord test.
This establishes planner incompleteness, not an obstructed production leaf.

## Correction and evidence

`meadows_earned_team_segment.gd` now finds a bounded exterior visibility path
when a mixed inside/outside route cannot directly approach or depart a gate.
Offset outline nodes are 3.2 m out; each exterior segment must clear the outline
by 3.0 m, accounting for the square 1.1 m corner guard, player radius 0.4 m,
and the caller's 1 m waypoint tolerance. The actual gate-centre crossing,
live leaf authorization, ordinary stick inputs and total movement deadline
remain intact. Same-side fence-crossing shortcuts remain refused.

The recorded-coordinate regression verifies an exterior detour, one perimeter
crossing at the gate, reverse routing, and refusal without an open gate.
Existing direct PondGate and actual leaf/collider authorization tests still run.

Root guarded native run `.artifacts/exterior-route-focused-0909`:
2026-09-09 23:03:28.651–23:03:32.412 UTC, exit 0, no guard stop,
12 tests / 98 assertions / 0 failed, empty stderr, no engine ERROR or SCRIPT
ERROR. Expected negative-control helper FAIL messages occur inside passing tests.

The saved failed-run profile exists and can support focused ordinary movement
validation without repeating training or injecting position. Save loading alone
will not count as continuous fresh-path acceptance. Source review and physical
traversal must precede shipping this correction. Independent scoped source review
found no blocker: the logged start clears the perimeter by 13.068 m; all authored
outside gate points clear the 3 m envelope. The reviewer verified reverse point
assembly and segment-distance checks. Watch runtime supply-selection latency:
the material helper can invoke this planner for many eligible harvestables.
