# Meshy batch 3 (Creatures lane, 24 Oct 2026): compact starter remakes for F36#0

Same route as batches 1-2: image-to-image concept with the identity reference + `style_wolf.png` + `style_bear.png`, then multi-image-to-3D textured. Deliver to `tb/meshy-1024` under `assets_raw/naturalistic-1024/<species>/` as before.

Why: the Terrapup pilot judged 7.62 (b1) but is 6.84 m nose to tail at its fixed 3.85 m height (installed mesh 3.07 m). Combat admission seats both fighters' bind-pose render boxes inside the room ring with 0.6 m clearance; the Warrens mouth (6.0 m capacity) and the Hall elite room (7.0 m) cannot hold it, so #716's catching, arena-contain and gate-E smokes failed. The hard rule forbids shrinking it, so the body must be compact: **nose-to-tail length no more than 1.2x standing height** (Terrapup at most 4.6 m; the Warrens pair then fits with about 0.6 m to spare). Ripplet is the other starter and gets the same cap with its four-legged otter redraft (its nat-v1 GLB sits, and the sitter rig weights are lopsided).

Scale: target heights are the installed heights, above the 1.80 m trainer. Both are rideable: a broad, level back. No red or oxblood. Each stays flag-off until a judged round and the three smokes pass.

| Species | Target height | Max length | Identity reference | Prompt |
|---|---|---|---|---|
| terrapup | 3.85 m (trainer 1.80, ratio 2.14) | 4.6 m | `assets/creatures/tetherbound/terrapup/reference/nat1022-concept.png` (judged 7.62) + `three_quarter.png` | `terrapup.prompt.txt` |
| ripplet | 3.60 m (trainer 1.80, ratio 2.00) | 4.3 m | `assets/creatures/tetherbound/ripplet/reference/three_quarter.png` | `ripplet.prompt.txt` |
