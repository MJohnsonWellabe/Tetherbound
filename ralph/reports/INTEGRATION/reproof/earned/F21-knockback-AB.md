# F21 knockback hypothesis for the practice-fight losses (F02#0, #1, #6): A/B

**Result: knockback is NOT the cause.** Zeroing every F21 `knockback_m` weight did not change the outcome. In all four runs, A and B alike, the piloted creature lands 2–6 hits against 38–40 taken and loses the first practice trainer.

- **Code:** tb/reproof-earned at ea778bcf (826d273c3 plus the origin/main fe7a611ab merge; test-only net-smoke fixes).
- **Probe:** `godot --headless --path . --script tools/_probe_combat_ladder.gd -- --only=practice_trainer`. Live fights through `encounter_director.begin_trainer_battle()`, driven by `tools/combat_pilot.gd` through real input actions. Player L3 x5 against the b1 practice trainer (2 creatures, L3).
- **B condition:** `data/config/combat.json` `feedback.weights.{light,medium,heavy,ultimate}.knockback_m` = 0.0, a **local, uncommitted** edit that was restored after each B run. The working tree is clean, and no toggle was committed.
- `tests/smoke_combat_baseline.gd` was also A/B'd: its table was byte-identical. That harness does not exercise the live knockback path, so it is not evidence either way.

| run | knockback | result | hits dealt / taken | missed |
|---|---|---|---|---|
| A1 | shipped (0.3/0.6/1.2/2.0 m) | LOST | 2 / 40 | 0 |
| B1 | 0 | LOST | 3 / 39 | 0 |
| A2 | shipped | LOST | 6 / 39 | 0 |
| B2 | 0 | LOST | 2 / 38 | 0 |

Logs: `logs/knockback-ab-ladder{A1,B1,A2,B2}.log.txt`. Also, an aborted full-ladder run before the A/B showed the same rung-1 result (2 dealt / 39 taken, 109.7 s, felled 0/2).

## What the numbers point to instead
"0 missed" with only 2–6 hits means the pilot almost never *throws* an attack, not that its attacks whiff. `combat_pilot.gd::_act` swings only when `gap <= reach*0.8` and `quick_ready`/`charged_ready` is true. Next suspects, not yet tested:
1. The redesign changed the quick/charged readiness or action names (`combat_quick`/`combat_charged`), or `CombatManager.quick_ready()`, so the pilot's press is never taken.
2. `_reach()` now over-reports the reach, or the pilot's approach never closes to inside 0.8×reach (F21 hitstop/poise `pause_defence` holding the ally).

The earned-team fights in F02 did win 6–11 practice fights, so the same pilot path is not completely dead there. The ladder's isolated rung is the clearest signal and a cheap repro.
