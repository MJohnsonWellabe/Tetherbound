# r31 (26 Oct): SW8 follow-up atmosphere + ground pass 2, code-blind CPU

Arms: lane `tb/stormwood` (all OFF) against three switches ON:
- `stormwood_surge.json presentation.height_fog`;
- `stormwood_look.json storm_light`, the cool rim light plus grade;
- `stormwood_ground_finish.json ground_zones` pass 2: moss and black pools only, bare loam off (`bare` [-1, -0.9]), and grass tufts thinned only in the pools (`grass_bare` [0.27, 0.335]).

Stands, one view each: Rodline Post, Lantern Hollow, Fallen Giant road, Glass Field approach, Crown heartstone. Phases: calm and fading.

Yardstick: JUDGE_PROMPT v1, 3 fresh judges, 3 anchor pairs (craft, f04_6_r22, f36_0_npc C7), seed 3131. calibrate.py linear fit: slope 1.78, intercept -3.42, r 0.92, anchor RMSE 0.30. Warning: candidates are extrapolated below the anchors.

| Set | off (mapped) | on (mapped) | gain | judges (raw) |
|---|---|---|---|---|
| calm | 3.82 | 4.36 | +0.54 | 3.9->4.3, 4.4->4.5, 3.9->4.3 |
| fading | 4.12 | 4.65 | +0.53 | 4.1->4.5, 4.5->4.6, 4.1->4.5 |

- **What the judges credited:** only the black reflective pools ("the one on-brief Stormwood element").
- **Rim light:** not seen on CPU (the no-rim defect stays PRESENT).
- **Height fog:** no visible effect. Godot's height fog is uniform near-ground haze, not distance layering, so it is dropped from the GPU arm.
- **All three judges' top ask on every stand:** real forest (groves, edges and clearings round each stand); the stands read as open plains. The Lantern Pools grove (r30) is the model for that.
