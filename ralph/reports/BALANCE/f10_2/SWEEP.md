# Capacitor Alpha starter sweep (tests/_diag_starter.gd equivalent: same pilot, same seed hashes as the harness; 24 seeds)

| ripple_jab w/r | gale_peck w/r | ripplet stats | galewisp stats | ripplet ratio | galewisp ratio |
|---|---|---|---|---|---|
| 0.14/0.18 | 0.12/0.15 | 105/24/17 | 92/27/14 | 0.98 | 0.71 |
| 0.22/0.24 | 0.20/0.22 | 105/24/17 | 92/27/14 | 0.43 | 0.59 |
| 0.22/0.24 | 0.22/0.24 | 110/23/18 | 92/27/14, 100/25/16, 105/24/17 | 0.50 | 0.64 / 0.64 / 0.64 |
| — | 0.26/0.26 | — | 92/27/14, 105/24/17 | — | 0.41 / 0.41 (rejected: Galewisp reader stalls against CURRENT recovery windows, e.g. Oreth Brooktail 113-241 s) |
| — | 0.30/0.26 | — | 92/27/14, 105/24/17 | — | 0.64 / 0.69 |
| — | 0.22/0.30 | — | 92/27/14 | — | 0.56 (wind regen 24->18 changed nothing: 0.56) |
| — | 0.24/0.28 | — | 92/27/14 | — | 0.50 (rejected: CURRENT stall, 113-196 s) |
| **0.22/0.24** | **0.22/0.34** | **110/23/18** | **105/24/17** | **0.50** | **0.41** (kept; CURRENT fights 21-43 s) |

Species stats alone (moves unchanged) did not move the ratio: ripplet 1.49-2.27 and galewisp 0.76-2.23 at 8 seeds, noise-dominated. The masher's hit count comes from its quick windup being caught during the dive; Terrapup's exhausted windup is 0.44 s, the old Ripplet/Galewisp ones 0.28/0.24 s.
