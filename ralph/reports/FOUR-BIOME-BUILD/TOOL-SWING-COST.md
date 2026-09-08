# Tool swing scan — bounded cheap win, 2026-09-08

The pre-push world smoke observed impact at 0.82 of a swing and remains failed.
This change is not claimed to resolve that failure: synchronous impact telemetry
in CI `34201147829` and a later full-world check remain required.

`tools/probe_tool_swing_cost.gd` invokes production `_resolve_swing()` against
58,001 synthetic harvest nodes, approximating the Meadows boot's group size.
It isolates selection cost, not rendering, animation or player-save performance.

- Baseline milliseconds: 66.482 cold; 32.524, 33.180, 32.087, 36.592 warm.
- Axis prefilter run: 41.961 cold; 28.461, 24.996, 29.007, 25.338 warm.
- Verification run: 59.020 cold; 27.961, 25.728, 23.013, 23.809 warm.
- Both candidate runs selected the intended target on all five calls.
- Eight differential cases match the original cone selection, including exact
  range boundary, outside range, square corners, elevation, behind, ties and overlap.
- Existing `test_swing_press_is_never_lost.gd`: five tests, ten assertions pass.
- Independent review: clean. Outside the horizontal reach square implies outside
  the reach circle; retained candidates still use the unchanged production cone
  and full 3D nearest-distance ordering. Aimed prompt swings are untouched.

No budgets, impact fractions or test tolerances changed. No spatial index or
cache was introduced. Raw logs remain in the local temporary directory as
`tool-swing-cost-baseline.log`, `tool-swing-cost-prefilter.log`, and
`tool-swing-cost-prefilter-verified.log`.
