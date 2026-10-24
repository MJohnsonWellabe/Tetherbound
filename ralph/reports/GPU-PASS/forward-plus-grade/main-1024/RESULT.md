# Forward+ grade on main: GPU re-measure (24 Oct 2026)

**Result: the Forward+ grade holds on main, and Meadows now sits at Low's level** with Meadows fog 0.001 (#712) and the landed grade (fog ×0.5, exposure ×1.333, saturation ×1.2).

| Scene | Low (Compatibility) luma / sat | Medium (Forward+) | High (Forward+) | Medium vs Low |
|---|---|---|---|---|
| Meadows band1 day approach | 106.8 / 0.602 | 102.6 / 0.608 | 101.0 / 0.610 | 96% luma, same saturation |
| Tidewake stairstones and east beach, day | 163.5 / 0.313 | 165.2 / 0.323 | 164.7 / 0.323 | parity |
| Stormwood F10 named fights (i00–i05, play area) | 73.1 / 0.344 | 63.2 / 0.390 | 63.0 / 0.377 | 86% luma, more saturated |

**Compared with the earlier measurements** (`../branch/`, main a4f8a6b7b before the grade):
- **Meadows Medium:** 87.6 → **102.6**. Against the tb/fplus-grade branch's 104.3, the difference is within capture noise; #712 lowered the fog.
- **Tidewake Medium:** 141.9 → **165.2**.
- **Stormwood:** its absolute values moved a long way, Low 29 → 73, because Stormwood content landed between the two runs. So only the Low/Medium ratio is comparable. The ratio is now 0.86, against 1.30 on the grade branch and 1.01 before it. Medium reads a little darker but more saturated than Low.
- **Frames:** the matched sheet shows all three scenes reading as the same look across presets (Medium and High identical). No preset is darker or greyer in a way the eye notices.

## Run

- **Source:** main 45865499d (game content; tb/gpu-pass 7b5d351da onward adds only reports).
- **Hardware:** GTX 1060, each preset with its own isolated APPDATA.
- **Scenes:** the same three as `../branch/`:
  - `grade_f10.gd`: capacitor_alpha and glass_field_alpha, north view, 6 s at 1 s;
  - `grade_loc.gd` Meadows: band1, day, approach;
  - `grade_loc.gd` Tidewake: tidal_stairstones and east_beach, day, approach.
  - All with `TB_GRADE_VARIANT=base`, which logs the live values and changes nothing.
- **Measurement:** `grade_measure.ps1`, the same grid as before:
  - F10: the play area, HUD excluded;
  - locations: the upper two-thirds.
  - Values are mean Rec.709 luma (0–255) and mean HSV saturation.

## Files

- `grade_main_measure.csv`: the table above.
- `_sheet_fplus_grade_main.png`: matched frames, with Low, Medium and High as columns and Meadows, Tidewake and Stormwood F10 as rows.
- `grade_main_queue.ps1.txt`: the local queue.
