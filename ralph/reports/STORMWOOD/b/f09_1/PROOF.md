# F09#1: lawful Surge phases, grounded paths, rod safe radii

Criterion: ACCEPTANCE §6.1 F09, "lawful Surge phases, grounded paths, rod safe radii" (WORLD §5.2).

- **Witness:** `tests/smoke_stormwood_b_surge_phase_traversal.gd`.
  - It runs in the production Stormwood scene, with the production player and camera.
  - Strikes come from the host strike runtime (`stormwood_lightning.gd`).
  - The player moves by ordinary stick input through `tests/helpers/stick_navigator.gd`.
- **Command** (Linux, Godot 4.7-stable, full checkout, imported twice): `XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script tests/smoke_stormwood_b_surge_phase_traversal.gd`
- **Commit (after review fixes):** `406f6f9f72d37e019807d8c732ddda5120b2d215`
- **Result:** `STORMWOOD B SURGE PHASE TRAVERSAL OK: 64 passed, 0 failed`, 0 SCRIPT ERROR.
- **Before review:** 5c3d35d7c ran 42 passed, 0 failed.

## Observed legs (406f6f9f)
Each leg runs Still Grove (-160, 2700) → (-560, 2480) along the Conductor Run road, driven by stick input. "Attempts" counts the strike runtime re-arming its own 4–8 s interval.

| Phase | Arrived | Travelled | Phase held | Exposed samples | Attempts (with the player exposed) | Warnings | Impacts |
|---|---|---|---|---|---|---|---|
| Calm | yes | 457 m | calm only | 23 | 14 (3) | 0 | 0 |
| Building | yes | 464 m | building only | 23 | 16 (2) | 0 | 0 |
| Break | yes | 461 m | break only | 23 | 15 (4) | 4 | 4 |
| Fading | yes | 464 m | fading only | 22 | 15 (5) | 0 | 0 |

In Break, every warning:
- was on ground that was exposed when the warning was issued;
- was outside every safe zone and every rod's 12 m radius;
- carried the 1.2 s telegraph;
- was at least `interval_min` (4 s) after the previous warning;
- resolved to an impact at least 1.2 game seconds later.

## Other checks (all PASS)
- **Host storm clock:** advances with game time (4.10 s over 4.00 s).
- **Live disabled rod:** with `stormwood:rod_deepwood_disabled` set in progression, the live node gives Deepwood Calm 360 s and Break 72 s.
- **Lawful cycle.** The live surge node, at the route's region, gives:
  - Calm 240 s → Building 90 s → Break 120 s → Fading 60 s, then wraps to Calm at 510 s.
  - Gentle Cinder Verge Calm: 324 s.
  - Disabled Deepwood rod: Calm 360 s, Break 72 s.
  - Aftermath: Break 45 s after a 2400 s Calm.
- **Grounded safe ground in Break.** For each spot, the safe-zone rule alone shelters it (no canopy, no rods), and it drew no warning over at least 20 counted attempts:
  - Still Grove safe zone;
  - Rodline Post camp safe zone.
- **Not exercised here:** settlements and the Hollow Crown. Camp-rod shelter proper is proven by the open-road rod check below.
- **Rod safe radius on open road in Break.**
  - Negative control: an exposed road point with no rod draws warnings.
  - With a player-built lightning rod 6 m away, the same point draws no warning over at least 20 attempts.
  - Rule edge: 11.9 m from a rod is sheltered, 12.1 m is exposed.

## Disclosed fixtures
- **Placement:** debug placement at each leg start.
- **Storm clock:** set to the phase start and held inside the phase during that leg. It otherwise advances normally.
- **Forced attempts:** in the safe-ground and rod checks, attempts are forced by zeroing the runtime's interval timer. The eligibility path is unchanged.
- **Rod:** a `placed_buildings` record, in the shape `stormwood_lightning.gd::sheltered` reads.
- **Health:** refilled after each impact, so the standing holds never trigger the death flow.

## Runs before this one
- **First attempt:** invalid. The container checkout was sparse, so 2,129 binary assets were missing and the scene could not load. Fixed with `git sparse-checkout disable` and a re-import.
- **Run at 73e716d22:** 40 passed, 6 failed. All six failures were in the test itself, and all are fixed in 5c3d35d7c:
  - wrong disabled-rod probe time;
  - leg frame budget 5400 (raised to 9000, as in the closed-arch walker);
  - telegraph lead measured in wall-clock ms at 4× (now game seconds).
- **Safety checks in that run:** 0 warnings in Calm, Building and Fading. In Break, every warning was lawful. The safe-ground and rod checks passed.

## Independent review
- **First pass:** a read-only reviewer found the assertions sound but too weak in places, and returned CHANGES REQUIRED:
  - attempts were uncounted;
  - the impact loop could pass vacuously;
  - the Rodline spot label was wrong;
  - the multipliers were checked only in the helper;
  - there was no check that the clock advances;
  - warning cadence and exposure were not asserted;
  - there was no evidence artifact.
- **Fixes:** all of these are addressed in 406f6f9f.
- **Declined:** CI wiring. `ci.yml` is coordinator-only, so it is left to the coordinator.
