# Forward+ grade breakdown (GPU pass, 22 Oct 2026, morning; round 2 added late morning)

**Question (coordinator Task 2):** which Forward+ settings make Medium/High look desaturated and dark compared with Low (Compatibility), and what fix restores Compatibility's look?

**Answer:**
- **Low and Medium use the same grade values.** Both run ACES at exposure 0.60 with white 6.0, the same fog density and an identity adjustment.
- **Forward+ renders those values greyer and darker:**
  - The grey wash comes from **depth fog**, which matters most in Stormwood (density 0.00135).
  - The darkness comes from **exposure 0.60 under ACES**, which matters most in Meadows and Tidewake.
- **SSAO, glow, volumetric fog and the adjustment block are minor.** Turning all of them off recovers almost none of the gap.

**Recommended Forward+ fix (Medium/High only), best tested recipe:**
- fog density ×0.5
- exposure 0.80
- adjustment saturation 1.20

It restores Low's look in Meadows and Tidewake and closes most of the gap in Stormwood. Numbers are below.

This was measurement only. No repo flag, config or code was changed. Each variant was forced in-process by a local wrapper on `RenderingServer.frame_pre_draw`. Copies of the wrappers are in this folder as `.gd.txt` files.

## Correction to round 1 (pushed at c2ae841ba)

Round 1's `fog_half` and `exposure_x1_5` rows were wrong. They are superseded by `p_fog05` and `p_exp09`.

- **What went wrong:** `world_look.gd` mutates the same Environment in place at world build. Both variants stored their base value on the first frame, before the world was built, when fog was 0.00023 and exposure 1.0. So:
  - `fog_half` ran at about 0.000115 fog, close to fog-off.
  - `exposure_x1_5` ran at exposure 1.5, not 0.90.
- **The fix:** round 2's `param` variant re-reads the game's live value whenever it differs from what the override last wrote. The log confirms it followed the live value, including Meadows' fog ramp and scene switch (`commands_and_grade_log.txt`). For example, in Stormwood, `game_fog=0.00135 applied_fog=0.00068` from frame 826.
- **Not affected:** every other round-1 variant sets absolute values (on/off, tonemapper, exposure 1.0).

## Recommended fix: before and after

Low = Compatibility, which is the target. All values are mean luma (0–255) / mean HSV saturation (0–1).

| Scene | Low (target) | Medium now | Medium + fix (fog ×0.5, exp 0.80, sat 1.20) |
|---|---|---|---|
| Stormwood (F10#2 north, 12 frames) | 30.0 / 0.557 | 30.6 / 0.397 | 38.6 / **0.520** |
| Meadows (band1 day, 3 frames) | 106.8 / 0.571 | 87.4 / 0.508 | 104.2 / **0.554** |
| Tidewake (brine steps day, 2 frames) | 164.6 / 0.273 | 142.0 / 0.269 | 162.0 / **0.281** |

- **Meadows and Tidewake:** the fix lands within about 3 luma and 0.02 saturation of Low.
- **Stormwood:** the fix reaches 93% of Low's saturation and is brighter than Low. Its heavier fog still costs some colour.
  - A Stormwood-only fog cut below ×0.5 would close the rest; fog fully off gives 0.655.
  - That deeper cut has not been tested combined with the exposure and saturation changes.
- **Where to set it:** apply the fix only to the Forward+ presets. Low already looks right with the current values.

## Setup

- **Hardware and driver:** NVIDIA GeForce GTX 1060 3GB on Windows 10 (Vulkan 1.3.280). Godot 4.7-stable console.
  - Medium: Forward+ on Vulkan.
  - Low: Compatibility on OpenGL3.
- **Preset isolation:** each preset reads its own isolated `user://graphics_override.cfg` (per-preset `APPDATA`).
- **Tree rendered:** `tb/gpu-pass` at 90283da8a. Its game code is identical to main 320eb47; the only differences are `ralph/`, `tools/visual_judge/` and the visual-judge skill docs. The location tool was given `--source-commit=320eb47bf8d9306d12af154e66d5d3206d79fa4b`.
- **Stormwood:** F10#2 tool `capture_named_fights_f10_6.gd` with `--ids=capacitor_alpha,glass_field_alpha --camera-view=north --seconds=6 --interval=1.0`, at 1280x720.
  - Measured on frames i00–i05 of both fights over the HUD-free arena region x 300–900, y 200–520.
- **Meadows:** `phase2_capture_locations.gd` with `--biome=meadows --subset=band1 --times=day --views=approach`, at 1920x1080.
  - Frames: grandpas_village, the_south_bridge and band1_trail_camp.
  - Measured over the upper two-thirds of each frame.
- **Tidewake:** the same tool with `--biome=water --subset=tidal_stairstones --subset=east_beach --times=day --views=approach`, at 1920x1080.
  - Frames: the tidal stairstones and the east beach.
  - Measured over the upper two-thirds of each frame.
- **Metrics:** mean Rec.709 luma and mean HSV saturation. Raw values are in `grade_measure.csv`.
- **How variants were applied:** forced on every WorldEnvironment before every frame. Every Stormwood and Meadows run logs `GRADE applied variant=<v> at frame 600`, and every `param` run also logs the live and applied values. The Tidewake runs finish before frame 600, so their param log lines are the evidence that the variant applied.
- **Contact sheet:** `_sheet_forward_plus_grade.png` has one row per key variant: Stormwood capacitor i03, Meadows grandpas_village and Tidewake tidal stairstones. Fight poses differ between runs, so compare colour, not pose.

## Live environment values (logged from the running game, base variant)

| Scene / preset | tonemap | exposure | white | fog density | volfog | SSAO | glow | adjust (s/b/c) | ambient |
|---|---|---|---|---|---|---|---|---|---|
| Stormwood, Medium | ACES | 0.600 | 6.0 | 0.00135 | on (0.0005) | on | on (0.30) | on 1.0/1.0/1.0 | 1.14 |
| Stormwood, Low | ACES | 0.600 | 6.0 | 0.00135 | off | off | off | on 1.0/1.0/1.0 | 1.14 |
| Meadows, Medium | ACES | 0.600 | 6.0 | 0.00040 | on | on | on | on 1.0/1.0/1.0 | 1.90 |
| Meadows, Low | ACES | 0.600 | 6.0 | 0.00040 | off | off | off | on 1.0/1.0/1.0 | 1.90 |
| Tidewake, Medium | ACES | 0.600 | 6.0 | 0.00055 | on (0.0005) | on | on | on 1.0/1.0/1.0 | 1.90 |
| Tidewake, Low | ACES | 0.600 | 6.0 | 0.00055 | off | off | off | on 1.0/1.0/1.0 | 1.90 |

SSIL and SDFGI are off at Medium, so the `no_ssil` and `no_sdfgi` variants were dropped as no-ops.

## All numbers (luma / saturation)

| Variant (Medium unless noted) | Stormwood | Meadows | Tidewake |
|---|---|---|---|
| **Low base (Compatibility)** | **30.0 / 0.557** | **106.8 / 0.571** | **164.6 / 0.273** |
| **Medium base** | **30.6 / 0.397** | **87.4 / 0.508** | **142.0 / 0.269** |
| p_fog05 (live fog ×0.5) | 30.0 / 0.489 | 86.8 / 0.525 | – |
| p_exp09 (exposure 0.90) | 42.2 / 0.341 | 110.4 / 0.460 | – |
| p_fog05_exp08 (fog ×0.5, exposure 0.80) | 35.9 / 0.477 | 102.6 / 0.494 | 161.6 / 0.239 |
| p_fog05_exp10 (fog ×0.5, exposure 1.00) | 43.9 / 0.437 | 115.2 / 0.468 | 176.2 / 0.210 |
| **p_fog05_exp08_sat12 (fog ×0.5, exposure 0.80, saturation 1.20)** | **38.6 / 0.520** | **104.2 / 0.554** | **162.0 / 0.281** |
| no_fog (depth fog off) | 26.2 / 0.655 | 85.6 / 0.548 | – |
| no_fog_exp1 (fog off, exposure 1.0) | 40.4 / 0.570 | 114.1 / 0.489 | – |
| fog_aerial0 (aerial perspective 0) | 32.1 / 0.314 | 87.5 / 0.501 | – |
| no_volfog | 29.4 / 0.418 | 86.6 / 0.522 | – |
| no_ssao | 31.0 / 0.399 | 88.1 / 0.507 | – |
| no_glow | 30.4 / 0.391 | 87.6 / 0.507 | – |
| no_adjust | 30.1 / 0.397 | 87.2 / 0.508 | – |
| all_post_off (volfog, SSAO, SSIL, glow off) | 31.1 / 0.415 | 87.7 / 0.519 | – |
| tm_linear | 41.6 / 0.249 | 86.2 / 0.410 | – |
| tm_filmic | 41.8 / 0.271 | 88.5 / 0.433 | – |
| tm_agx | 36.3 / 0.299 | 81.5 / 0.461 | – |
| ~~fog_half~~ (round 1, ran at about pre-build fog ×0.5; superseded) | 26.4 / 0.620 | 86.8 / 0.525 | – |
| ~~exposure_x1_5~~ (round 1, ran at exposure 1.5; superseded) | 62.1 / 0.291 | 110.1 / 0.462 | – |

## What causes what

1. **Stormwood's grey wash is depth fog.**
   - Live fog ×0.5 lifts saturation from 0.397 to 0.489. Fog off lifts it to 0.655.
   - At the same density, Forward+ fogs the frame far more than Compatibility does. The probable reason is that Forward+ applies fog in HDR before ACES, but that is not proven here.
2. **The darkness is exposure under ACES.**
   - Exposure 0.80 brings Meadows and Tidewake to within about 3–4 luma of Low.
   - But ACES desaturates as exposure rises: exposure 0.90 drops Meadows to 0.46 and Stormwood to 0.34.
   - So exposure needs a saturation lift alongside it. Adjustment saturation 1.20 supplies that, and no tonemapper swap does.
3. **Tonemapper swaps are not a fix.** Linear, Filmic and AgX all lose saturation (Stormwood 0.25–0.30, Meadows 0.41–0.46).
4. **Aerial perspective is helping.** Setting it to 0 makes Stormwood greyer (0.314).
5. **Volumetric fog, SSAO, glow and adjustment are minor.**
   - Each moves luma by 1.2 or less and saturation by 0.021 or less.
   - All of them off gives Stormwood 0.415 and Meadows 0.519.

## Files

- `_sheet_forward_plus_grade.png`: round 2 contact sheet, three scenes per key variant (1.46 MB).
- `grade_measure.csv`: per-run luma and saturation, with frame counts, for all rounds. The round-1 `fog_half` and `exposure_x1_5` rows are superseded, as explained above.
- `commands_and_grade_log.txt`: exact command line for every run, plus the logged live environment values and the applied values.
- Local tools used, copied as `.txt`: `grade_override.gd`, `grade_f10.gd`, `grade_loc.gd`, `grade_queue.ps1`, `grade_queue2.ps1`, `grade_queue3.ps1`, `grade_measure.ps1`, `run_tool.ps1`.
- Per-frame captures stay local and are not committed.
