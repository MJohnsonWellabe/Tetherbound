# F10#3 round 4 (3bcea2c6): code-blind PARTIAL, **countdown PASS**

Same tool and staging. seqK is normal motion and seqL is reduced motion, 13 frames each including t090. The phase stills are shuffled as shot_1–8 (`phases_blind_key.json`).

| Q | r1 | r2 | r3 | **r4** | Judge r4 (fresh subagent, pixels only) |
|---|---|---|---|---|---|
| Q1 zone | PARTIAL | PARTIAL | PARTIAL | PARTIAL | Radius about 2.8–3.2 m. t000 still reads as "a thin target reticle"; danger reads from t020. It calls the ring off-centre, but the ring is placed at the trainer's position: the close camera compresses its far half. |
| Q2 time left | FAIL | PARTIAL | PARTIAL | **PASS** | "The last ~0.2 s is unmistakable", stepping t090 → t100 → t110. |
| Q3 impact | PARTIAL | PARTIAL | PARTIAL | PARTIAL | It reads clearly as a bolt from the sky hitting the player. There is no ground flash, and one branch ends in open sky. |
| Q4 reduced motion | PASS | PASS | PASS | **PASS** | Gentle and readable. |
| Q5 competition | — | PARTIAL | PARTIAL | FAIL | After impact the road's gold cracks light the whole path. **Cause found:** r4's post-impact road dim was timed in wall-clock ms, which a slow fixed-fps capture outruns. It is fixed to a game-time clock in the next commit. |
| Q6 phases | PARTIAL | PASS | PARTIAL | PARTIAL | **8/8 grouped correctly** against the key (1/6 Calm, 3/5 Building, 4/7 Break, 2/8 Fading) in every round. Building and Break differ by rain density and darkness. |
