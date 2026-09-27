# F10#3 round 5 (1ae14190): telegraph PASS on every question; phases PARTIAL

Captures are local xvfb + opengl3 at 1280×720 with `--fixed-fps 60` on llvmpipe, from `tools/vis_capture_strike_motion.gd --only=quick --vis-child`. seqG is hour 12 with normal motion; seqH is hour 0 with Reduced Motion. There are 13 frames each, t000–t170. The phase stills come from `tools/capture_stormwood_surge_phases.gd --only=quick,night` (8 stills, shuffled as pic_1–8; `phases_blind_key.json`).
- **Staging, disclosed:** one staged warning and impact through the client path, aimed at the trainer, with no damage. Random strikes are pushed out, the surge clock is pinned, the hour is frozen, the trainer is teleported to the Cinder Verge stand, and the HUD is hidden.

| Q | r1 | r2 | r3 | r4 | **r5** |
|---|---|---|---|---|---|
| Q1 danger zone, about 3 m, from frame one | PARTIAL | PARTIAL | PARTIAL | PARTIAL | **PASS**: radius about 3.2 m, "a hot-magenta ring with a darkened fill appears at once … centred on the player's feet" |
| Q2 time left / last moment | FAIL | PARTIAL | PARTIAL | PASS | **PASS**: one-way progression; "the last 0.2 s is unmistakable" |
| Q3 reads as lightning striking the zone | PARTIAL | PARTIAL | PARTIAL | PARTIAL | **PASS**, with defects: no ground burst, the bolt is static for 0.1 s, the fill darkens at impact |
| Q4 reduced motion | PASS | PASS | PASS | PASS | **PASS**: no white-out or strobe; everything stays readable |
| Q5 nothing competes / struck area = warned zone | — | PARTIAL | PARTIAL | FAIL | **PASS**: "at t150 nothing extends past the warned area" |
| Q6 phases without HUD (blind grouping) | 8/8 | 8/8 | 8/8 | 8/8 | **8/8**, PARTIAL: "four different looks", but Break has no signature cue in a still, and Calm/Fading could be swapped by name |

**Overall (judge r5): PARTIAL.** The telegraph half passes every question. The phase half grouped **40 of 40** stills correctly across five independent judges, but naming them is called unreliable without a Break-only cue in a still.
