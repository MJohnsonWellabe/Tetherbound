# The smokes were being run wrong, and that hid a real defect

**Date:** August 2026
**Trigger:** critic round 4 verification

## What happened

Four of the seven smoke tests were reported green on the strength of *"no FAIL
line in the output"*. Re-running them with the exit code captured showed all
four exiting **124 — killed by `timeout`.** They had never passed; they had
never finished.

Two separate mistakes, and each one alone was enough to produce a false green.

### 1. Absence of FAIL is not presence of pass

A test killed by `timeout` prints nothing at all, which is byte-identical to a
clean run as far as `grep FAIL` is concerned. Every smoke does print a `FAIL`
line when it fails, so the reasoning was not unsound — it was just measuring the
wrong thing, in exactly the way this project keeps rediscovering: **a check that
uses a different mechanism from the thing it checks is testing the mechanism.**

`tools/run_smokes.sh` now asserts the exit code AND each test's own success
sentence, and treats a missing success line as an error.

### 2. They were being rendered when they are meant to be headless

Every smoke's docstring says `godot --headless`. They were being run under
`xvfb-run` with `--rendering-driver opengl3`, which makes them draw all ~18,000
scattered props for every one of the **10,800 physics frames**
`smoke_traversal` simulates.

Measured:

| invocation | result |
|---|---|
| xvfb + opengl3 | **2400s, did not finish its second leg** |
| `--headless` | **191s, passes** |

All seven headless take about 200 seconds together. Nothing in these tests looks
at a pixel; the surveys do that and they are a separate tool.

## The real defect this was hiding

With the invocation fixed, `smoke_traversal` fails roughly **one run in three**:

```
traversal FAIL: airborne for 3147 consecutive frames; the ground is not continuous
  move_forward   ->     0.0,    2.2,  -140.7   grounded=true
  move_right     ->     0.0,    2.2,  -140.7   grounded=true
  move_back      ->    -6.4,    0.4,    18.1   grounded=false
  move_left      ->    -6.4,    0.4,    18.1   grounded=false
```

Three consecutive runs: fail, pass, pass. Always the same leg (`move_back`,
walking +z from about z=-140 toward the origin).

**The player is not falling.** It is stuck at **y ≈ 0.4** — roughly ground level
— for 3147 frames without ever reaching the `THROUGH_THE_FLOOR` threshold at
y=-80. So this is not the export fall-through that was fixed earlier (that one
was a `res://` path check that failed inside a `.pck`); it is the character
being held off the floor while not descending.

Candidates, none yet confirmed and listed so the next session does not start
from scratch:

- a prop collider it has climbed onto or is wedged against — trees carry
  4.0×scale cylinder colliders, and the tree skirts added this round are
  `collides: false` so they are not it;
- a terrain face steeper than the controller's 45° `floor_max_angle`, where
  `move_and_slide` slides without ever reporting `is_on_floor`;
- Terrain3D collision not yet built for a region the player has just entered —
  which is the same family as the bug `collision_mode = 3` was set to fix, and
  the reason that line is read back and asserted.

The leg distance also varies enormously between passing runs (ending at z=13.6
in one and z=48.2 in another from the same start), so the test is frame-rate
dependent and its own timing may be part of the story.

**This is a shipping blocker and it is not fixed.** It reproduces on a clean
checkout with `tools/run_smokes.sh`, so it is reproducible rather than
anecdotal, which is the one good thing about it.
