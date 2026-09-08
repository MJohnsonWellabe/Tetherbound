# Keeper Tovin graded approach repair

Date: 2026-09-08
Scope: the bounded Brine Steps exploration-spine approach to Keeper Tovin and
his live production challenge offer. This is not fresh-save chapter-continuity
or battle-victory evidence.

## Fixture boundary

`tools/probe_water_tovin_approach.gd` boots the production Water world with the
already-earned Reedhaven repair and one healthy level-44 Sparkit. It places the
player at authored Brine Steps spine point p3. That initial pose is diagnostic
setup. Every metre from p3 through p4, p5 and the candidate interaction area is
then ordinary stick-controlled walking; neither trainer nor prompt is moved by
the probe.

Command:

`Godot_v4.7-stable_win64_console.exe --headless --path . --log-file
%TEMP%\water-tovin-approach-baseline.log --script
tools/probe_water_tovin_approach.gd`

## Baseline

The opening-through-Brine production run first exposed the blocker. It walked
the authored landing and spine to p3, then stopped at
`(408.952,43.667,733.921)` while seeking Tovin at
`(429,76.091,683)`, with zero navigator confinement resets. No challenge could
be offered.

The bounded baseline reproduced the terrain mechanism:

- Tovin's reused `water_tovin` NPC row put the dock-test trainer on the island
  summit, 60.535 m from the nearest graded spine segment.
- The direct p3-to-Tovin chord contained 21 of 108 approximately one-metre
  samples over the 24-degree route contract and a 0.955 m maximum adjacent
  height step.
- Ordinary walking instead followed graded p3-to-p4-to-p5 and reached the
  candidate neighborhood with zero resets. The first measured candidate at
  `(393,809)` had all nine real Terrain ray contacts, minimum normal Y 0.9286,
  and zero of six approach samples over 24 degrees.
- That first candidate was rejected for production placement because an exact
  nearest-polyline calculation put it only 2.785 m from the p4-to-p5 centerline.
  It was evidence for the terrain neighborhood, not the final coordinate.

Log: `%TEMP%\water-tovin-approach-baseline.log`; expected exit 1 because the
production body still stood on the summit. Native `ERROR` / `SCRIPT ERROR`
scan was clean; the only runtime warnings were the separately owned rejected
ordinary ecology sites `water_brine_steps_wild_010/_011`.

## Repair

Only the reused `water_tovin` NPC placement changes, from island-local
`(9,0,23)` to `(-25,0,149)`, world XZ `(395,809)`. The latter is 3.68 m from
the p4-to-p5 centerline, outside the 3 m flat trail core, and 22.29 m before the
Shellwatch departure. Tovin's identity, role, dialogue, team, levels, flags and
all other characters remain unchanged.

The Brine segment now walks the complete graded p1-through-p5 approach before
seeking the live prompt.

## Validation

Log: `%TEMP%\water-tovin-approach-final-deployed.log`

- Exit 0 in approximately 66 seconds; clean native `ERROR` / `SCRIPT ERROR`
  scan. The only runtime warnings were the separately owned Brine ordinary
  ecology sites `_010/_011`.
- The final `(395,809)` center was 3.6799 m from the graded centerline and
  22.2922 m before departure. All nine 1.2 m footprint rays hit production
  Terrain; minimum normal Y was 0.9143.
- The approximately one-metre p5-to-candidate profile had zero of eight samples
  over 24 degrees and a 0.3458 m maximum adjacent height step.
- Ordinary stick-controlled p3-to-p4-to-p5-to-candidate walking passed with
  zero navigator confinement resets.
- Controller recall deployed the healthy fixture. The first grounded stance
  reached the live prompt, which was enabled, won the actual
  `InteractionArbiter`, and offered actionable `Challenge Keeper Tovin` at
  2.733 m. Neither trainer nor prompt was moved by the probe.
- Focused config/segment checks: 2 tests, 9 assertions, 0 failures. Parser,
  JSON parse and `git diff --check`: passed.

This closes the placement and challenge-offer blocker. The opening-through-
Brine composition must still replay the production Tovin battle and durable
trial outcome; that broader run is separate evidence.
