# Forward+ grade breakdown (GPU pass, 22 Oct 2026, morning)

**Question (coordinator Task 2):** which Forward+ settings make Medium/High look desaturated and dark compared with Low?

**Answer:** the grey wash in Stormwood is the **depth fog**, not the Forward+-only effects. The darkness in Meadows is **ACES at exposure 0.60** as Forward+ renders it. SSAO, glow, volumetric fog and the adjustment block barely move either number. Turning off every Forward+-only effect at once recovers almost none of the gap to Low.

This was measurement only. No repo flag, config or code was changed. Each variant was forced in-process by a local wrapper on `RenderingServer.frame_pre_draw`. Copies of the wrappers are in this folder as `.gd.txt` files.

## Setup

- **Hardware and driver:** NVIDIA GeForce GTX 1060 3GB on Windows 10 (Vulkan 1.3.280). Godot 4.7-stable console.
  - Medium: Forward+ on Vulkan.
  - Low: Compatibility on OpenGL3.
- **Preset isolation:** each preset reads its own isolated `user://graphics_override.cfg` (per-preset `APPDATA`).
- **Tree rendered:** `tb/gpu-pass` at 90283da8a. Its game code is identical to main 320eb47; the only differences are `ralph/`, `tools/visual_judge/` and the visual-judge skill docs. The location tool was given `--source-commit=320eb47bf8d9306d12af154e66d5d3206d79fa4b`.
- **Stormwood scene:** F10#2 tool `capture_named_fights_f10_6.gd` with `--ids=capacitor_alpha,glass_field_alpha --camera-view=north --seconds=6 --interval=1.0`, at 1280x720.
  - Measured on frames i00–i05 of both fights (12 frames) over the arena region x 300–900, y 200–520. That region is HUD-free.
- **Meadows scene:** `phase2_capture_locations.gd` with `--biome=meadows --subset=band1 --times=day --views=approach`, at 1920x1080. That gives three frames: grandpas_village, the_south_bridge and band1_trail_camp.
  - Measured over the upper two-thirds of each frame.
- **Metrics:** mean Rec.709 luma (0–255) and mean HSV saturation (0–1). Raw values are in `grade_measure.csv`.
- **How variants were applied:** the variant is forced on every WorldEnvironment before every frame, so world-build environment swaps cannot undo it. Every non-base run logs `GRADE applied variant=<v> at frame 600`, and all 26 non-base Medium runs (13 variants x 2 scenes) logged it. Exact command lines and the logged live environment values are in `commands_and_grade_log.txt`.
- **Contact sheet:** `_sheet_forward_plus_grade.png` shows one frame per variant: capacitor_alpha i03 and grandpas_village. The fight is not frame-deterministic, so the creature pose differs between rows. Use the sheet to compare colour, not pose.

## Live environment values (logged from the running game, base variant)

| Scene / preset | tonemap | exposure | white | fog density | volfog | SSAO | glow | adjust (s/b/c) | ambient |
|---|---|---|---|---|---|---|---|---|---|
| Stormwood, Medium | ACES | 0.600 | 6.0 | 0.00135 | on (0.0005) | on | on (0.30) | on 1.0/1.0/1.0 | 1.14 |
| Stormwood, Low | ACES | 0.600 | 6.0 | 0.00135 | off | off | off | on 1.0/1.0/1.0 | 1.14 |
| Meadows, Medium | ACES | 0.600 | 6.0 | 0.00040 | on | on | on | on 1.0/1.0/1.0 | 1.90 |
| Meadows, Low | ACES | 0.600 | 6.0 | 0.00040 | off | off | off | on 1.0/1.0/1.0 | 1.90 |

SSIL and SDFGI are off at Medium, so the `no_ssil` and `no_sdfgi` variants were dropped as no-ops. The adjustment block is identity (1/1/1), and `no_adjust` confirms it changes nothing.

**Low and Medium share the same grade values.** The Low/Medium difference therefore comes from how Forward+ renders the same fog and tonemap, not from a different preset value.

## Numbers

| Variant (Medium unless noted) | Stormwood luma | Stormwood sat | Meadows luma | Meadows sat |
|---|---|---|---|---|
| **Low base (Compatibility)** | **30.0** | **0.557** | **106.8** | **0.571** |
| **Medium base** | **30.6** | **0.397** | **87.4** | **0.508** |
| no_fog (depth fog off) | 26.2 | **0.655** | 85.6 | 0.548 |
| fog_half (fog density × 0.5) | 26.4 | **0.620** | 86.8 | 0.525 |
| fog_aerial0 (aerial perspective 0) | 32.1 | 0.314 | 87.5 | 0.501 |
| no_fog_exp1 (fog off + exposure 1.0) | 40.4 | **0.570** | **114.1** | 0.489 |
| exposure_x1_5 (0.60 → 0.90) | 62.1 | 0.291 | 110.1 | 0.462 |
| no_volfog | 29.4 | 0.418 | 86.6 | 0.522 |
| no_ssao | 31.0 | 0.399 | 88.1 | 0.507 |
| no_glow | 30.4 | 0.391 | 87.6 | 0.507 |
| no_adjust | 30.1 | 0.397 | 87.2 | 0.508 |
| all_post_off (volfog, SSAO, SSIL, glow off) | 31.1 | 0.415 | 87.7 | 0.519 |
| tm_linear | 41.6 | 0.249 | 86.2 | 0.410 |
| tm_filmic | 41.8 | 0.271 | 88.5 | 0.433 |
| tm_agx | 36.3 | 0.299 | 81.5 | 0.461 |

## What causes what

1. **Stormwood desaturation is caused by depth fog (fog_density 0.00135).**
   - Fog off takes saturation from 0.397 to 0.655 (+65%), above Low's 0.557.
   - Halving the density alone gives 0.620.
   - At the same density, Compatibility fogs the scene far less than Forward+ does. The probable reason is that Forward+ applies fog in HDR before ACES, but that is not proven here.
   - Fog also slightly brightens Stormwood: fog off gives 30.6 → 26.2 luma.
2. **Aerial perspective is helping, not hurting.** Setting it to 0 makes Stormwood greyer still (0.314). The fog light colour is greyer than the sky colour it currently blends toward.
3. **Meadows darkening comes from exposure and tonemap, not fog.**
   - Meadows fog is light (0.0004): fog off only moves saturation 0.508 → 0.548.
   - Medium is 87 luma against Low's 107. Raising exposure closes that gap (0.90 → 110; fog off with 1.0 → 114), but under ACES the higher exposure lowers saturation (0.46–0.49).
   - So exposure alone cannot match Low in Meadows on both metrics. Matching Low will need exposure plus a saturation or colour lift.
4. **Swapping the tonemapper is not a fix.**
   - In Stormwood, Linear, Filmic and AgX each raise luma from 30.6 to 36–42, but saturation drops to 0.25–0.30.
   - In Meadows they all lose saturation, and AgX also darkens it (81.5).
5. **Volumetric fog, SSAO, glow and adjustment are minor.**
   - Each moves luma by 1.2 or less and saturation by 0.021 or less.
   - Turning them all off gives Stormwood 0.415 and Meadows 0.519, against Low's 0.557 / 0.571.

## For the Stormwood lane

These are the levers the numbers support, not a tested recipe:

- **Saturation:** lower the Forward+ Stormwood fog density, roughly halving it (0.00135 → about 0.0007). Keep aerial perspective as it is.
- **Brightness:** fog off plus exposure 1.0 reached 40.4 / 0.570, which is Low's saturation and brighter than Low.
- **Untested:** fog_half combined with exposure around 0.8. If the lane wants it, I can run that combination, and any candidate values they pick, as GPU confirmations.
- **Meadows:** needs a separate exposure and saturation decision, because its fog is not the cause.

## Files

- `_sheet_forward_plus_grade.png`: contact sheet, one frame per variant (1.3 MB).
- `grade_measure.csv`: per-run luma and saturation, with frame counts.
- `commands_and_grade_log.txt`: exact command line for every run, plus the logged live environment values and variant-applied markers.
- Local tools used, copied as `.txt`: `grade_override.gd`, `grade_f10.gd`, `grade_loc.gd`, `grade_queue.ps1`, `grade_queue2.ps1`, `grade_measure.ps1`, `run_tool.ps1`.
- Per-frame captures stay local and are not committed.
