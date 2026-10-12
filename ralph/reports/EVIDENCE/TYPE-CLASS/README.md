# COMBAT §7 type-matchup re-evaluation of the residual C2 rows (tb/ev-systems-a)
Ruling: coordinator for the owner, 2026-10-12 (829b3c217; COMBAT.md §7 "Type matchups", ACCEPTANCE C2).
- (a) A disadvantaged lead is judged with the switching reader.
- (b) An advantaged lead is exempt from "masher loses its lead every run" only while reader party ≤ .55× masher party.
- (c) Rows still failing, or failing on timeouts, are tuned in data.

Classes come from data/config/type_chart.json and each foe roster's species types (adv = the lead hits super-effectively, or is resisted).
Runs: 1b3bacbc8 / fce6a5ca0 (adopted reader 904c3c537), 24 seeds unless noted, 12:24–12:51 CT Mon 12 Oct. Rows are in `rows.json` and `guardian_rows.txt`.

| Criterion | Row | Class | Numbers | Verdict |
|---|---|---|---|---|
| F22#1/F47#3 | Cloudreach high_roost × Ripplet (tempestwing, air) | disadv (a) | switching reader win 1.00, lead 0.000 vs masher 0.558, no timeouts | PASS |
| F22#1/F47#3 | Cloudreach summit × Ripplet | disadv (a) | switching reader win 1.00, lead 0.000 vs masher 0.548, no timeouts | PASS |
| F22#4 | Veyra × Terrapup (air team) | adv (b) | party reader 0.028 vs masher 0.132 (0.21) | PASS |
| F22#4 | Marrow × Ripplet/Galewisp (electric team) | disadv | 2/24 switching-reader timeouts each | FAIL (c): pacing probe running |
| F04#7 | Warrens guardian × Ripplet (ground) | adv (b) | party reader 0.060 vs masher 0.079 (0.77) | FAIL (c) |
| F14#0 | brine/tidecoil/songweaver × Galewisp (water) | adv (b) | party 0.092/0.090, 0.070/0.073, 0.073/0.073 (about 1.0) | FAIL (c) |
| F33#2 | Nerissa tidesteel × Galewisp (water) | adv (b) | party 0.063 vs 0.120 (0.53) | PASS |
| F33#2 | Nerissa tidesteel × Ripplet | neutral | masher lead-faint 0.75 | FAIL (c) |
| F33#2 | Veyra skyglass × Terrapup | adv (b) | party 0.009 vs 0.058 (0.16) | PASS |
| F33#2 | Veyra skyglass × Ripplet | disadv (a) | switching reader party 0.007 vs 0.225; masher lead-faint 0.92 | FAIL (c): the masher kept its lead in 1 of 12 |
| F33#2 | Veyra skyglass × Galewisp (air vs air) | neutral | masher lead-faint 0.00 | FAIL (c) |
| F33#2 | Marrow stormglass × Terrapup | adv (b) | party 0.073 vs 0.171 (0.43) | PASS |

F33#2 notes:
- The prior tier is harder for every finale. Masher party at the prior tier vs the matching tier:
  - Nerissa (rootiron vs tidesteel): 0.432 vs 0.356, 0.256 vs 0.225, 0.174 vs 0.120.
  - Veyra (tidesteel vs skyglass): 0.075 vs 0.058, 0.242 vs 0.225, 0.197 vs 0.136.
  - Marrow (skyglass vs stormglass, earlier pair): harder.
- Warden (Meadows, rootiron) passed earlier (warden_bare_bd3c20ba).

EV F22#1 PASS 1b3bacbc8 with the §7 type rule, 69/69: the two Ripplet x tempestwing rows (disadvantaged) pass with the switching reader at 24 seeds, no timeouts
EV F47#3 PASS 1b3bacbc8 same sweep as F22#1 (69/69 under the §7 type rule)
