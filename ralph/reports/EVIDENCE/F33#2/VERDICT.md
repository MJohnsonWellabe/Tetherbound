# F33#2 verdict: each finale's matching gear tier passes C2, and the prior tier is clearly harder (tb/ev-systems-a)
- Rule: HOMESTEAD.md:86. Bar: the COMBAT §7 top-trainer bar with the §7 type-matchup rule (829b3c217).
- Harness `tests/smoke_f22_pattern_bands.gd --named=<id> --gear-tier=<tier>`, adopted reader 904c3c537, 12 seeds.
- Fidelity fixes before this verdict:
  - f3a6f6fac: Nerissa now gets her foe_power_multiplier through the production team_member translator.
  - b2f0aa32c: Veyra now gets her production behaviour profiles, power 28/32/36.
  - Every earlier Nerissa and Veyra pair ran under-powered and is superseded.

| Finale (matching / prior) | Matching tier, reader/switch/masher party | Prior tier masher party | Verdict |
|---|---|---|---|
| Warden (rootiron / bare) | warden_bare_bd3c20ba + MEADOWS_ROOTIRON (systems-b), PASS | harder | PASS |
| Nerissa (tidesteel / rootiron), f3a6f6fac | terrapup 0.567/0.085/0.789; ripplet 0.502/0.194/0.748; galewisp 0.306/0.215/0.658; all PASS | 0.958 / 0.871 / 0.799 | PASS |
| Veyra (skyglass / tidesteel), b2f0aa32c | ripplet 0.057/0.034/0.361 PASS; galewisp 0.034/0.040/0.315 PASS; terrapup 0.039/0.039/0.176, Terrapup type-advantaged vs air: (b) party 0.22 ≤ 0.55, PASS | 0.232 / 0.418 / 0.367 | PASS |
| Marrow (stormglass / skyglass), 904c3c537 | ripplet 0.105/0.043/0.243 PASS; galewisp 0.104/0.034/0.247 PASS; terrapup 0.073/0.073/0.171, advantaged vs electric: (b) 0.43, PASS | 0.207 / 0.293 / 0.299 | PASS |

Rows: `nerissa_veyra_fidelity_rows.json`. Marrow's are in ../TYPE-CLASS. The matchup class is tagged per row above.

EV F33#2 PASS b2f0aa32c every finale's matching tier passes C2 (Terrapup vs Veyra/Marrow via the §7 advantaged rule) and the prior tier is harder for each; Nerissa/Veyra on production-powered fixtures
