# VIS-TIDEWAKE look round 26: storm cloud colours with the cloud-key fix (CPU); flat, stays OFF

- Code (shipped, inert): `world_look._layer_weather` now passes `cloud_lit` / `cloud_shade` / `cloud_base` from a weather sky overlay (before, only top/horizon/ground horizon were copied, so r24/r25 could not move the cloud deck). No shipped weather preset sets these keys, so play is unchanged.
- Candidate: `ov_r25.json` (`rain_grade_candidate.sky` slate cloud colours) vs r23b. The rain sky becomes a dark slate storm deck; the sheet differs in 8-10% of pixels (the rain tile).
- 3 code-blind judges, `anchor_tiles.py --seed 1119`: all three score both sides of F39#30a, F39#30b and F39#31 identically (6.0/5.6/5.5, 5.9/5.4/5.6, 5.4/4.9/4.9). The rain tile is a quarter of each 2x2 sheet and does not move the score. Flat, so it stays OFF.
- The judges' asks are unchanged: a Veilfall rebuild (new art), sand stripe banding (terrain shadow, look/probes), bare dunes, and the creature and Tether face finish (other lanes).
