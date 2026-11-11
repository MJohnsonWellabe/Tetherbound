STATUS: land
BRANCH: tb/below6-remakes-land (cut from origin/main; READY is in the same commit)

# F36#86 Voltarach and F36#61 Ribbonray: floor coats and grounded hit, ON (LANE-BELOW6, 11 Nov 2026)

The grades and the clip flag are LANE-REMAKES' work (`tb/remakes` ac738b144), judged on the GPU and landed by LANE-BELOW6.

## Verdict
`ralph/reports/GPU-PASS/1108/G-remakes-floor1-ribbonray-voltarach.md` on `tb/item-scout-1108` e9012a32d (GPU High, three code-blind judges, standard prompt, confirming batch):

| Row | Base (main) | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| F36#61 Ribbonray | 5.02 | 6.90 | +1.88 | 3/3 |
| F36#86 Voltarach | 5.15 | 6.50 | +1.35 | 3/3 |

- Ribbonray: magenta effect PRESENT -> FIXED 3/3; airborne hit PARTIAL -> FIXED 3/3; the detached tail tip is gone.
- Voltarach: chrome-gold statue PRESENT -> PARTIAL 3/3; face lost PRESENT -> PRESENT / PARTIAL / PARTIAL.
- No loss, no red. High only: Medium has not been judged, so neither row closes here (both are under 7.5).

## Flags
- ON: `creature_coat_flags.json` `remakes_floor_voltarach`, `remakes_floor_ribbonray`; `creature_clip_flags.json` `remakes_floor_ribbonray_hit`. Each carries `_why_on` with the score and the verdict file.
- OFF: `remakes_floor_abyssal_guardian` (its arm `BELOW6-ABYSSAL` is on the GPU now). Its texture ships here so the arm needs no further import.

## Files
- `data/config/creature_coat_flags.json`, `data/config/creature_clip_flags.json`
- Four graded textures with VRAM-compressed import sidecars: Voltarach `_floor1.png` and `_floor1_glow.png`, Ribbonray `_floor1.png`, Abyssal Guardian `_floor1.png`
- `tools/art_pipeline/grade_remakes_floor.py` (the script that makes them)
- `tests/test_remakes_floor_landed.gd` (pins the three ON flags, their verdict citation, the live coat table, and Abyssal OFF)

## Tests
Run in the lane checkout with these files copied over: `--only=remakes_floor_landed,creature_coat_flags,texture_import_policy,remake_owner1101_finish,creature_clip,creature_model_flags,stormheart`: 56 tests, 8987 assertions, 0 failed. The per-file lines show `test_remakes_floor_landed.gd` ran (4 tests ok). No full suite (config flags and textures only).

## Not fixed (judges, arm side)
- Voltarach: the face is one blue eye spot with no head mass; the hit barely differs from standing; some gold sheen on leg tips and front plates.
- Ribbonray: upright two-legged anatomy (mesh; parked without new art), a tiny eye, the fin juts up at the end of the faint.
