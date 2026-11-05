# VIS-TIDEWAKE look round 25: storm cloud colours (CPU); no effect, stays OFF

- Candidate: `ov_r25.json` (`rain_grade_candidate.sky` cloud_lit #8d98a3, cloud_shade #3b4651, cloud_base #2b3540) vs r23b.
- The rain frames are identical to the base. Together with r24 (sky top/horizon), this shows that `rain_grade_candidate.sky` keys do not reach the rain sky in the capture; the clouds and gradient come from the weather preset or another layer. Stays OFF.
- Finding for whoever picks up the rain mood: trace where the rain sky is set (`tidewake_world_look.gd` rain path vs `world_look._layer_weather`) before tuning values. Config arms on this lane's rows are now exhausted.
