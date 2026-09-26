# F09#1: lawful Surge phases, grounded paths, rod safe radii

Criterion: ACCEPTANCE §6.1 F09, "lawful Surge phases, grounded paths, rod safe radii" (WORLD §5.2).

- **Witness:** `tests/smoke_stormwood_b_surge_phase_traversal.gd`.
  - It runs in the production Stormwood scene, with the production player and camera.
  - Strikes come from the host strike runtime (`stormwood_lightning.gd`).
  - The player moves by ordinary stick input through `tests/helpers/stick_navigator.gd`.
- **Command** (Linux, Godot 4.7-stable, full checkout, imported twice): `XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script tests/smoke_stormwood_b_surge_phase_traversal.gd`
- **Commit:** `5c3d35d7c1473855a09cb816db0861a82dc0c507`
- **Result:** `STORMWOOD B SURGE PHASE TRAVERSAL OK: 42 passed, 0 failed`. Exit 0, 0 SCRIPT ERROR.

## Observed legs
Each leg runs Still Grove (-160, 2700) → (-560, 2480) along the Conductor Run road, driven by stick input.

| Phase | Arrived | Travelled | Phase held | Exposed samples | Warnings | Impacts |
|---|---|---|---|---|---|---|
| Calm | yes | 457 m | calm only | 23 | 0 | 0 |
| Building | yes | 464 m | building only | 26 | 0 | 0 |
| Break | yes | 469 m | break only | 28 | 4 | 3 |
| Fading | yes | 465 m | fading only | 27 | 0 | 0 |

Break:
- Every warning was outside every safe zone and every rod's 12 m radius, and carried the 1.2 s telegraph.
- Every impact landed at least 1.2 game seconds after its warning, allowing one physics tick of slack.
- The fourth impact was still pending when the leg ended.

## Other checks (all PASS)
- **Lawful cycle.** The live surge node, at the route's region, gives:
  - Calm 240 s → Building 90 s → Break 120 s → Fading 60 s, then wraps to Calm at 510 s.
  - Gentle Cinder Verge Calm: 324 s.
  - Disabled Deepwood rod: Calm 360 s, Break 72 s.
  - Aftermath: Break 45 s after a 2400 s Calm.
- **Grounded safe ground in Break.** Over at least 20 forced strike attempts, neither spot drew a warning:
  - Still Grove safe zone;
  - beside the Rodline Refuge rod.
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
