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
