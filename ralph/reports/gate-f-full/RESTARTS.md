# Restarts — GATE-F-FULL

Protocol §A's blocker rule: a superseded segment is renamed, never deleted, and
the restart says which segment, which SHA, and why.

## S03, attempt 1 → `S03-superseded-1/`

| | |
|---|---|
| segment | S03, the village tutorial ladder |
| result | 385 PASS / 30 FAIL, 422 steps, complete, exit save written |
| old SHA | `4a0a9c30` (candidate `453107fb` + this lane's docs; game tree identical) |
| new SHA | this lane's HEAD at restart; **the game tree is still identical to `453107fb`** |
| what changed | `tools/gate_f/` only — `move_to_entity` gained `rank`, and S03's ten-attempt engage ladder now varies rank and tolerance across the ten (RIG-F4) |
| why | attempt 1's engage ladder resolved the same creature ten times from the same standstill and lost the interaction arbiter to the same deadwood node on all ten. The team never reached three, `tournament.json` requires three, and the exit save S04 would have inherited could not enter the tournament. Running S04–S10e on it would have repeated six runs of history: downstream evidence taken against an invalid save. |

**Attempt 1 is preserved in full and its evidence is cited in `DEFECTS.md`** —
GAME-F1, GAME-F3 and GAME-F4 are all measured from it, and GAME-F4 is measured
from nothing else.

## S05, attempt 1 → `S05-aborted-1/`

| | |
|---|---|
| segment | S05, Lower Meadows / band 1 |
| result | **STOPPED BY ME, mid-segment, at step ~30 of 80.** Not a completed attempt and not a verdict: there is no `INVENTORY.json`, no exit save, and nothing in that directory should be read as an S05 result. |
| why | Its first two walks out of the village both failed against the village fence — `did not reach (-40, 180) in 11700 walking frames; stopped 155.8 m short at (-15.0, 1.0, 26.0)`, which is the outline's own `[-15,27]` vertex — and the player was pinned there. Every remaining walk in the segment would have failed identically after burning its full budget, roughly half an hour of runtime for nothing. |
| what changed | `tools/gate_f/` only — RIG-F6: S05 and its capture twin now leave through PondGate in three legs instead of walking into a fence, and S10e comes home the same way. |

The failing walks are preserved in `S05-aborted-1/telemetry/` and are the
evidence for RIG-F6 in `DEFECTS.md`.

## S06, attempt 1 → `S06-aborted-1/`, and no attempt at S07–S10e

| | |
|---|---|
| segment | S06, Stone & Root / band 2 |
| result | **STOPPED BY ME at step ~20 of 106, on the coordinator's instruction of 23:42Z.** No `INVENTORY.json`, no exit save; nothing in that directory is an S06 result. |
| why | S06 begins on the near side of a South Bridge that never opened (TRAVERSAL-F8), against a party of two that are both fainted and cannot legally enter the tournament S04 already refused them (PROGRESSION-F7). Every walk in it would have failed against a solid bridge, and every fight would have been refused by `can_challenge()`. That is the same wall already diagnosed twice, in two places, from two directions. Running it would have produced more of the rig-health evidence RIG-F6 and TRAVERSAL-F8 already bank, and no new information about the chapter. |

**S07, S08, S09, S10a, S10b, S10c, S10d and S10e were not attempted**, for the
same reason. That is a deliberate stop with a stated cause, not a failure to
reach them.
