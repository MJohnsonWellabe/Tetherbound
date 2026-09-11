# The Stonewater Reach R4 static candidate — 2026-09-11

Disposition: **STATIC CANDIDATE; production visual judgment pending.**

## Highest-leverage remaining gap

The committed R3 evidence establishes the overlook and broad wreck-to-spring route,
but the continuous run still reads as a flat cyan ribbon. Grass crossing its exposed
edges makes the water look placed on top of the meadow rather than belonging to it.
The rejected R2 wet-bank polygons demonstrated that another broad procedural surface
is not a safe local answer.

## Bounded correction

- Removed metallic and emissive response from the Stonewater-local shallow-water
  material, raised its roughness, and reduced normal strength. This targets the
  plastic/self-lit cyan value without changing shared Meadows water.
- Added four sparse, irregular stone-riffle clusters at existing bends in the run.
  They reuse installed stylized-nature rocks, remain non-colliding, and interrupt
  the longest exposed water/ground-cover contact lines without creating another
  bank mesh or changing the route.
- Advanced the focused production capture output to `STONEWATER-REACH-R4`; the
  harness continues to freeze the player and hide HUD/modal overlays.

## Binding production review

R4 must remain POLISH or be rejected until fresh production frames prove all of the
following:

1. The run reads as shallow water moving through stone, not a cyan road.
2. Riffles read as irregular natural interruptions, not a repeated stepping-stone
   fence or floating asset row.
3. Grass/water intersections are materially less dominant in the overview, eastern
   run, spring arrival, and springhead frames.
4. The overlook, route clearance, and wreck-to-spring sequence remain intact.

Reject the candidate if any riffle visibly floats, forms a traversal-looking barrier,
or makes the already rock-heavy frames more cluttered. No production renderer or
bake was run for this static lane.

## Static validation receipts

- `tests/run_tests.gd -- --only=test_stonewater_reach.gd`: **8 tests, 56
  assertions, 0 failed**.
- Godot 4.7 `--check-only`: passed independently for the production source,
  focused test, and capture harness.
- `git diff --check` on the three tracked lane files: passed.
