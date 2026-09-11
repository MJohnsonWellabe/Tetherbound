# The Old Quarry — post-creature-scale review

Status: **strong POLISH**. Actor obstruction fixed and accepted; ordinary-arrival
commercial hierarchy remains the blocker to strict PASS.

## Fresh evidence

Dedicated production proof loads the shipped Meadows scene with current
Terrain3D, consolidated scatter, vegetation, quarry structures, props,
gatherables, player, and live encounters. Clear day/night is explicitly applied
before the clock freezes; HUD and the independent SubmersionOverlay are hidden.
The six-frame manifest completed without failure and records matching day/night
live surfaces at every stand.

R1 and R2 evidence in this directory are rejected for closure. Arrival is
dominated by two Burrowbacks centered ahead of the road, hiding the worked site.
The floor frames prove sign, supplies, Rootstone, foundations, and lit pylon run,
but the conduit frames carry an unacceptable giant Burrowback crop at frame
left. The defect repeats day/night and survived moving order 2073, proving that
the initially suspected four-body nest was not the photographed actor.

## Corrected root cause

The actual crop is Band 2 spawn order **2912**, a roadside Burrowback pair at
`(390.007, 1808.407)`, radius 3m—only 13.1m from the quarry anchor and directly
inside all three authored arrival/floor/conduit camera corridors. The order2073
experiment was fully reverted.

The held correction moves only order2912 to the west shoulder at `(365,1792)`
and widens its disc only to 4.5m. It stays 35.9m from the quarry and remains part
of the quarry-road ecology. Its full disc plus the existing 7m default wander
and a conservative 1.6m post-scale body allowance clears all three hero
corridors by more than 13m. Order, species, count, habitat, and level-roll inputs
are unchanged.

## Validation

- Old Quarry identity/corridor test: **2 tests, 17 assertions, 0 failed**.
- Old Quarry + spawn data + spawn tables before corrected actor isolation:
  **54 tests, 11,090 assertions, 0 failed**.
- JSON parse and `git diff --check`: clean.

## Accepted R3 receipt

The single authorized R3 production run completed 6/6 frames with no manifest
failure. Day/night sampled the same live surface at every stand and all recorded
player-ground offsets were within 0.352m. Full-resolution review confirms no
Burrowback blocks arrival or floor, and the former giant left crop is absent
from both conduit frames. The road now leads visibly through worked stone,
supplies, Rootstone, and the lit pylon run.

The requested post-scale actor obstruction is PASS. Overall named-location grade
remains strong POLISH: the worked site is still small at ordinary arrival, floor
composition is rock-heavy, and dead growth overlaps part of the pylon silhouette.
The six hero frames do not independently show the resited pair, but its preserved
35.9m quarry proximity and corridor clearance are pinned in the focused test.

No production terrain, gatherable, structure, route, or actor-scale change is
included. The next strict-PASS opportunity is a bounded worked-site silhouette
and dead-growth hierarchy pass, not another creature adjustment.
