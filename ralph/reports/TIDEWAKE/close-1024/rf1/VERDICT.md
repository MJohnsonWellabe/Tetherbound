# Tidewake close-1024 round rf1: Tidewake-only lighter rain mist, CPU pre-judge (25 Oct 2026, CT)

## What changed (OFF in play; `--tidewake-look-sections=rain_fog_candidate`)

- **The defect:** in rain, every Veilfall batch (vv1, vf4) said the fog flattens the island and sea into one grey mid-tone.
- **Why:** Tidewake sightlines run to kilometres. At that range the shared rain preset's `fog_density_add` (0.0055) washes everything out.
- **The change:** `tidewake_world_look.gd` overrides `set_weather` and scales that mist by `fog_density_add_scale` 0.35, in rain and in Tidewake only.
  - The shared `weather.json` and every other realm are untouched.
  - Rain streaks, grade and ground wetness are unchanged.

## Mapped Bar A

- **Arms:** both on top of t1e and falls f2.
- **Views:** `veilfall-vista-rain`, `shore-rain` and `lesson-rain`.
- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 10079).
- **Calibration:** `calibrate.py` slope 1.18, r 0.86, anchor RMSE 0.48.

| Set | Shared mist | Tidewake mist 0.35 | Δ | Judges |
|---|---|---|---|---|
| Rain views (3) | 5.67 | **6.18** | +0.51 | higher x3 |

**Defect changes:**
- **"Rain fog flattens the scene; landmark loses its silhouette":** PARTIAL x3 → FIXED x3.
- **"The scene does not read as rain":** PARTIAL x3 → PRESENT x2 and PARTIAL x1.
  - With less mist, the rain is carried only by faint streaks under a bright sky with dry sand.

## Next (named by all three)

1. A darker overcast sky grade for Tidewake rain.
2. Denser visible rain sheets.
3. Wet, darkened sand.
4. Keep the fog light, as here.

## GPU capture (`tb/tidewake` a3222a69a or later)

`F39-look.json --views=veilfall-vista-rain,shore-rain,lesson-rain`, with `--tidewake-look-sections=current_flow,veilfall_falls_candidate` and with `--tidewake-look-sections=current_flow,veilfall_falls_candidate,rain_fog_candidate`.
