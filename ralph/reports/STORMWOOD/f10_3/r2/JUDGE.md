# F10#3 round 2 (73173db1): code-blind PARTIAL, up from r1

Captures: the same tool and staging as r1. seqP is hour 12 with normal motion; seqQ is hour 0 with reduced motion. They have 12 frames each at t000–t170, rendered locally at 1280×720 with fixed 60 fps on llvmpipe. The phase stills are r1's, re-shuffled as view_A–H (`phases_blind_key.json`).

| Q | r1 | r2 | Judge r2 (fresh subagent, pixels only) |
|---|---|---|---|
| Q1 danger zone from the first frame | PARTIAL | PARTIAL | Radius about 3.0–3.3 m, centred on the feet. At t000 it is still "a dashed, broken magenta outline"; the danger reads from about t040. |
| Q2 time left | FAIL | **PARTIAL** | "t000 → t080 progression is clear … the cracks grow from the rim until they reach the player's feet". There is no final-moment cue, and t100 ≈ t110. |
| Q3 impact | PARTIAL | PARTIAL | The strike location is unambiguous. A fork grounds outside the zone, there is no ground burst, and the bolt is static and drawn over the player. |
| Q4 reduced motion | PASS | PASS | No white-out; the warning matches frame for frame. |
| Q5 competition | (in Q1) | PARTIAL | The gold path streaks and zigzags just beyond the ring. |
| Q6 phases | PARTIAL | **PASS** | 8/8 grouped correctly against the key (C/H Calm, A/E Building, B/G Break, D/F Fading). Building and Fading are told apart by the cloud breaks. |

**Overall: PARTIAL.** Round 3 responds:
- a white-hot final ramp;
- a solid thin rim and a stronger fill from t000;
- road cracks fully dimmed out to 2.5 m past the ring;
- short, low side forks.
