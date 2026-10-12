# F33#2 Captain Veyra: skyglass vs tidesteel (routes-east)

US Central, 2026-10-11. Both runs on commit 54cb885234 (contains 3057bf24). Skyglass ran 14:46–15:33 CT, tidesteel 15:33–16:19 CT.

Command: `godot --headless --path . --fixed-fps 60 --script tests/smoke_f22_pattern_bands.gd -- --seeds=12 --band=cloudreach/summit_final_stronghold --named=captain_veyra_storm_anchor --gear-tier=<tier> --json=<out>`. The receipt says pass=false, but that only means one band was covered (ignore per the coordinator). The 30 MB JSON is not committed.

## skyglass
gear=skyglass mode=trainers runs=108 seeds=12 errors=0
| band | starter | switch_reader win | masher lead-loss | reader median cost | masher median cost | ratio | reasons |
|---|---|---:|---:|---:|---:|---:|---|
| cloudreach/summit_final_stronghold | terrapup | 1.00 | 0.00 | 0.050 | 0.056 | 0.89 | top: masher kept its lead in some run; top: reader party cost above .55x masher |
| cloudreach/summit_final_stronghold | ripplet | 1.00 | 0.92 | 0.039 | 0.225 | 0.17 | top: masher kept its lead in some run |
| cloudreach/summit_final_stronghold | galewisp | 1.00 | 0.00 | 0.030 | 0.136 | 0.22 | top: masher kept its lead in some run |

## tidesteel
gear=tidesteel mode=trainers runs=108 seeds=12 errors=0
| band | starter | switch_reader win | masher lead-loss | reader median cost | masher median cost | ratio | reasons |
|---|---|---:|---:|---:|---:|---:|---|
| cloudreach/summit_final_stronghold | terrapup | 1.00 | 0.00 | 0.052 | 0.071 | 0.74 | top: masher kept its lead in some run; top: reader party cost above .55x masher |
| cloudreach/summit_final_stronghold | ripplet | 1.00 | 1.00 | 0.038 | 0.242 | 0.16 |  |
| cloudreach/summit_final_stronghold | galewisp | 1.00 | 0.00 | 0.027 | 0.190 | 0.14 | top: masher kept its lead in some run |

"ratio" is the switch_reader's median party cost divided by the masher's. COMBAT §7's top-trainer bar asks for a reader win rate of at least 0.75, the masher losing its lead in every run, and a ratio of at most 0.55. Marrow (stormglass/skyglass) was handed to the fights lane at 16:15 CT.
