# Water next segment: Tovin to liberated Shellwatch

Status: production-data route and requirements identified; no runtime or
implementation claim.

The next bounded ordinary segment begins only after the Brine helper has earned
both `defeated_water_trainer_tovin` and
`water_dock_brine_steps_trial_won`. It should stop when Shellwatch's combined
world gate `water_dock_shellwatch_residents_freed_and_pump_disabled` is durable.
It needs no new equipment, material, party, HP, pose or progression fixture.

## Executable order

1. From Tovin's production body at XZ `(429,683)`, walk to Brine Steps spine
   point 4 `(488.657,758.052)`, then points 5 `(387.711,808.531)` and 6 /
   departure `(383.462,828.074)`. Those legs are approximately 95.9m, 112.8m
   and 20.0m; no direct chord back across the island is needed.
2. Swim `brine_steps_to_shellwatch_sheltered`. It is an authored
   `human_level_0` route of 93.320m, requires only the already-earned Brine
   trial flag, and lands at `brine_steps_to_shellwatch_arrival`
   `(356.538,951.926)`.
3. Walk to Shellwatch spine point 1 `(352.289,971.469)`. The production
   `water_camp_shellwatch` is seven metres beside it at XZ
   `(359.289,971.469)`. Use its real creature bed and overnight-rest controller
   flow before the two mandatory fights; do not repair HP in the harness.
4. Follow the spine to point 2 `(267.004,1006.349)`, then physically approach
   `water_trainer_solm` at XZ `(338,1090)`, 109.7m from the nearest authored
   spine point. Win both level-47 opponents, Mirejaw and Mangrove Monitor, and
   require `defeated_water_trainer_solm`.
5. Return through spine points 2 and 1. Activate the real `shellwatch_release`
   equipment near the arrival anchor (anchor offset `[-4,+10]`) and require
   `water_shellwatch_residents_freed`. Solm's flag unlocks this action but does
   not perform it. The nearby camp remains the ordinary recovery option before
   Irva.
6. Return to spine point 2 and physically approach `water_trainer_irva` at XZ
   `(302,1080)`, 81.5m from that point. Win both level-48 opponents, Riptusk and
   Cannonback, and require `defeated_water_trainer_irva`.
7. Walk from Irva to spine point 3 `(217.982,1061.1)`, then follow the authored
   point-3-to-point-4 segment. That segment is about 232m, so a harness should
   target its geometric midpoint `(303.3195,1139.576)` before point 4
   `(388.657,1218.052)`; this is movement along the authored line, not a pose
   write. Continue through points 5 and 6 / departure
   `(436.92,1246.15)`.
8. Activate the real `shellwatch_pump` equipment at the departure anchor offset
   `[-8,-4]`. Require `water_shellwatch_pump_disabled`, then the WaterDocks
   aggregation `water_dock_shellwatch_residents_freed_and_pump_disabled` and
   physical departure-barrier removal.

## Why this is the blocking order

The dock action schema deliberately separates combat from interaction. Solm's
victory only permits the resident-release prompt; Irva's victory only permits
the pump prompt. Both victories without both physical actions leave the combined
gate closed. Existing `smoke_water_dock_actions.gd` proves that rule by posed
interaction, but does not prove any crossing, approach, fight, recovery, return
walk or barrier reachability.

Both mandatory trainers use their own trainer rows rather than reused NPC
bodies, so their runtime XZ positions are Shellwatch centre `(320,1120)` plus
their offsets: Solm `[+18,-30]`, Irva `[-18,-40]`. The production terrain must
still ground those rows. The Shellwatch spine remains marked analytic
`bake_and_walk_required`; its recent composition revision and the two off-spine
trainer approaches make physical runtime the next evidence, not another static
flag audit.

The safe stop is the combined Shellwatch flag and absent departure barrier. Do
not fold the following 112.113m crossing to Tidal Cradle or the Aquaryn trial
into this first diagnostic; they are a separate balance and capture branch.
