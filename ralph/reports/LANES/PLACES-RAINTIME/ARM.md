# ARM: rain_time_grade (P2 Cloudreach rain), LANE-PLACES, 12 Nov 2026

Branch `tb/places`. Ships OFF; `overlay.json` turns it ON. Rows: F40#0 (6.54 over 384 frames; half are rain), F40#19.

## Defect and cause
Judges: "night rain reads as day", "golden-hour rain loses the golden light", "thick white overlay streaks".
A weather preset's sky, cloud and fog colours are absolute (`world_look.gd _layer_weather`), so `rain_storm`'s day-slate sky replaces the night and golden skies outright. The streaks are one bright colour at alpha 0.7 at every hour (and the colour was applied twice, on the material and on the particle).

## Change (`cloudreach_weather.gd time_graded_preset`, flag `rain_time_grade` in `cloudreach_visual.json`)
- The rain preset's sky, cloud and fog colours are scaled by how dark the clock's own sky is against day (hue kept, floor 0.1). The storm ambient is capped at the clock's own ambient value, so a storm never lights the night.
- Where the clock's horizon is warm (golden hour, dawn), the storm horizon, lit cloud, fog and ambient take half of that warm colour, the sun cut eases from 0.45 toward 0.8 and the saturation cut is released.
- Streaks: 0.022 m wide, 1.0 m long, `#c3ced8` at alpha 0.3, dimmed to 0.4 at night.
- Re-layered every 2 s so it follows the clock. Day rain keeps the judged storm grade (only the streaks change). Cloudreach scene only; Tidewake is untouched.

## CPU proof (`_sheet_cpu_base_vs_arm.jpg`, base left, arm right; Realm Gate Crag approach, Low)
- Top, 23:00 rain: base is a bright grey day sky with thick white rods; arm is a dark night sky with fine dim streaks and the trainer still readable.
- Bottom, 18:00 rain: base is cold slate with white rods; arm keeps warm low light on the ground, rocks and haze.
- Tests: `tests/test_places_storm_phase_rain_grade.gd` (night darker than half the day storm sky; ambient never above the clock's; a golden or dawn hour keeps a warm horizon and more sun; day unchanged).

## Risks to check on GPU
- Golden rain may read too tan overall (`warm_mix` 0.5; lower it, or drop `cloud_lit` from the warm keys, to keep a slate deck over a warm horizon).
- Night rain sky may be too dark behind the gate (`night_floor` 0.1).
