# Aggression CI 34208280455 follow-up

## Scope and verdict

The combat shard in CI run `34208280455`, job `102003435270`, failed
`tests/smoke_aggression.gd` on attempt 1/2 and passed on attempt 2/2. The failed
attempt waited for Galecrest while the player was 116.1 m away, so it did not
prove an aggression defect: the scripted approach had failed before the
aggression observation began. The retry is still a finding, not first-attempt
green evidence.

Commit `1765092fc` made that prerequisite explicit. Both the peaceful and
aggressive halves now require actual 3D proximity, a spontaneous fight during
the approach remains observable by the existing exact-species checks, and an
inconclusive peaceful approach stops the smoke before it can contaminate the
aggressive half. It does not increase either frame budget or relax an
aggression assertion.

## First local diagnostic

The first strengthened local run used the unique log
`%TEMP%\aggression-ci-34208280455-first-20260908.log`. It stopped in the
peaceful Bramblebun prefix, as intended, rather than running the Galecrest half
from an invalid position.

- Player start: approximately `(40, 1.29, -62)`.
- Across frames 400 through 3,600 the player remained around
  `x=39.7..42.0`, `z=-62.4..-62.87` while Bramblebun wandered around
  `z=-46.6..-50.4`.
- `locomotion_enabled` remained true, `is_on_wall()` remained true, and
  horizontal velocity was usually zero despite held movement input.
- The old alternating lateral escape did not clear the obstruction.
- At the 4,000-frame boundary the player remained 15.27 m from Bramblebun.

This run proves a physical approach failure before the behavior assertion. It
does **not** yet identify the collider and makes no verdict about Galecrest's
aggression.

## Exact approach mechanism

The one collider-instrumented reproduction used
`%TEMP%\aggression-ci-34208280455-collider-20260908.log` and named the current
contact on every stalled sample from frame 400 through the terminal failure:

```text
/root/MeadowsPlayground/VillageBoundary/FencePanelCollision_39
normal=(-0.196116, 0.0, -0.980581)
```

The final player position was approximately `(41.57, 0.27, -62.78)`, 8.92 m
from the wandering Bramblebun. This is not the historical Terrain3D or tree
hypothesis. The smoke's own `_leave_the_farmhouse()` fixture hard-codes
`(40,-62)`. The current village outline segment from `[36,-61]` to `[46,-63]`
passes through `z=-61.8` at `x=40`, putting that fixture only 0.20 m outside
the line and overlapping the sealed fence with the player's capsule. The
fixture comment that calls this point "open meadow" became stale when the
authored village boundary moved.

Moving the start inside is not by itself a complete repair. The practice
Bramblebun is inside the sealed village perimeter while the authored Galecrest
at approximately `(35,-115)` is outside it. With no gate-key/opening state in
this deliberately opening-bypassing fixture, a single initial stand cannot
reach both subjects by ordinary input. The smoke must not silently unlock a
progression gate to hide that fact.

## Repair and first complete verdict

The legacy approach rotates its desired heading by alternating `+/-1.3`
radians after twenty stationary frames. It has no collision-volume probes,
ground/cliff rejection, persistent selected side, or progress-based confined
recovery. `tests/helpers/stick_navigator.gd` has those facilities.

The shared navigator cannot legitimately solve a fixture spawned overlapping
and outside a locked, intentionally sealed perimeter. The smoke now runs the
two behavior halves as isolated scene fixtures: `(40,-57)`, inside and 4.71 m
from the current fence line, for the practice Bramblebun; `(40,-72)`, outside
and 10.00 m from it, for Galecrest. There is no teleport during either
approach, no progression flag or gate unlock, no larger budget and no weaker
behavior assertion. The smoke also redirects Game to a unique process/run
test-save directory before resetting gameplay state.

An initial launch of this change exited before loading the world because the
new save-isolation setup tried to find the Game autoload directly from
`SceneTree._init()`. It reported only `Game autoload is missing`; this was a
harness-lifecycle failure, not a behavior attempt. Deferring `_run()`, the
standard sibling-smoke pattern, makes the autoload available before the saver
is replaced.

The first complete behavior run then passed with exit 0. Its unique log is
`%TEMP%\aggression-ci-34208280455-separated-fixtures-behavior-20260908.log`.

- Peaceful fixture: ordinary input reached the authored Bramblebun; the player
  stood 2.2 m away for all 900 frames without a fight, and the voluntary
  engage prompt remained available.
- Aggressive fixture: ordinary input closed from 47.5 m to the authored
  Galecrest; Galecrest initiated from 8.8 m. The exact opponent, suspended
  player locomotion, arena, deployed ally and Run escape assertions all
  passed.

The log contains one native warning during second-scene staging, before the
aggressive fixture position was printed: player velocity `854729 m/s` at world
origin was clamped to the production 120 m/s ceiling. It did not occur during
either measured approach and caused no assertion or script error, but this is
not a blanket clean-native-log claim. The fix's behavioral verdict is the two
separately reported checks above.

Static validation also passes:

```text
godot --headless --path . --check-only --script tests/smoke_aggression.gd
git diff --check -- tests/smoke_aggression.gd \
  ralph/reports/FOUR-BIOME-BUILD/AGGRESSION-CI-34208280455.md
```
