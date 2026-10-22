# GPU pass: F10#2 Stormwood named-fight camera: Medium REOPENED (3.58; rescore 3.68), High REOPENED (3.63)

Calibration (same judges): the CPU r3 anchor scores 3.27 on this scale against 6.53 from the CPU judges, and GPU Low/Compatibility scores 4.06. See "Calibration batch and High" below.

21 Oct 2026, 20:49 CT. Remote GPU lane (owner's Windows desktop).

- **Renderer:** Forward+ on Vulkan 1.3.280, NVIDIA GeForce GTX 1060 3GB (driver 560.94), real GPU, not llvmpipe.
- **Preset:** Medium, from `user://graphics_override.cfg` (preset and base Medium, `renderer/rendering_method="forward_plus"`) in an isolated user dir. `capture_log.json` records `"graphics_preset": "Medium"`, `"renderer": "forward_plus"`.
- **Resolution:** 1280x720, `--fixed-fps 20`.
- **Memory:** no allocation errors at Medium. All runs exited 0.
- **Source:** `tb/gpu-pass` at origin/main 9db3d2146d0587d189cf172567b17345f31a0abd, unmodified. No flag, config or code changed.

## Commands

The shipping arm is the flag as committed: `line_of_sight_fade.enabled_realms = ["stormwood"]`.

```
godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1280x720 --fixed-fps 20 \
  --script res://tools/capture_named_fights_f10_6.gd -- --out=<dir> \
  --ids=hollows_alpha,capacitor_alpha,crown_guardian,old_rodfolk_hall_guardian,glass_field_alpha \
  --seconds=18 --interval=1.0 --camera-view=north
godot ... (same) -- --out=<dir> --ids=blackwater_elder --seconds=18 --interval=1.0   # default stand
```

The control arm uses the same commands with `--script <local wrapper>`. The wrapper extends the unchanged capture tool and empties `line_of_sight_fade.enabled_realms` in-process before `_initialize` (`f10_2_control.gd.txt`). Its log confirms `F10_2_CONTROL enabled=false enabled_realms=[]`.

The capture runs every frame, without `--draw-shots-only`, so Forward+ temporal effects (volumetric fog, SSAO) settle. That is the only difference from the CPU command line.

## Judging

- Three fresh code-blind judges each scored all six fights.
- Per-fight sheets came from the same frames on both sides: i00–i17 plus tell1/tell2 a–f, up to 30 a side.
- Sides were shuffled per fight, and the key was withheld until all three verdicts were in (`f10_2_gpu_medium_key.json`).
- Judges saw only the sheets, the neutral-named frames, `docs/reference/` and ART_DIRECTION.

| Fight | Shipping (ON) j1/j2/j3 | Control (OFF) j1/j2/j3 |
|---|---|---|
| hollows_alpha | 3.5/3.2/3.2 | 3.0/2.8/2.8 |
| capacitor_alpha | 4.1/4.0/3.6 | 2.7/2.5/2.0 |
| crown_guardian | 3.5/3.1/3.4 | 3.6/3.3/3.3 |
| old_rodfolk_hall_guardian | 4.0/3.8/3.6 | 2.9/2.6/2.3 |
| blackwater_elder | 3.8/3.6/3.3 | 3.5/3.2/3.2 |
| glass_field_alpha | 3.9/3.6/3.3 | 2.6/2.4/2.0 |
| **Mean** | **3.58** (3.80/3.55/3.40) | **2.82** (3.05/2.80/2.60) |
| C3 | 6/6 PASS, all three judges | 2/6, all three judges (FAIL: hollows pilot lost under the spider at impact; capacitor camera in canopy i10–i11; old_rodfolk camera in foliage i12/i17; glass_field trunk/canopy i08/i13/i17) |

**Bar A 3.58 < 7.5: REOPENED.**

The fade is still +0.77 over the matched control, and C3 holds 6/6 on the GPU. Bar B: yes (marginal) from all three judges. Bar A for the set: no from all three.

## Calibration caveat (please read before acting)

These judges' absolute scale is far below the CPU rounds' judges on the same fights. The GPU control scored 2.82; the r8 CPU control scored 5.61. The ordering and margin agree (ON over OFF, C3 6/6 versus failures in canopy and trunks).

Part of the drop is a real GPU finding: all three judges led with darkness. Forward+ Medium (volumetric fog, SSAO) renders the Stormwood floor as a crushed brown-black. Part may be judge prompt calibration. The CPU lanes' exact judge prompt isn't in the repo; this pass used the visual-judge SKILL rubric verbatim. A same-prompt anchor (GPU Low/Compatibility scored by the same prompt) would separate the two causes.

## Judges' asks (all three)

1. **Lighting and value (fixable in scene).** Frames are a dark monochrome brown with no key or rim on the fighters and weak contact shadows. There is no Stormwood moss-blue, copper or glass highlight, and no white-violet lightning. Lift exposure, add a fighter key/rim light, and give the arena ground moss/pool materials instead of bare mud (hollows and crown_guardian read as bare plains).
2. **Telegraphs and impacts (needs new art).** Flat magenta slabs and cones run under the HUD, and slabs stand vertical in some frames (old_rodfolk tell1-e, glass_field tell2-e). Most impacts show no hit effect.
3. **Camera and HUD.** The trainer and telegraphs sit under the command panel (blackwater_elder i06/i16, hollows i03). There are clone herds of the same species behind the arena (crown_guardian), and floating NPC text sits over the enemy panel (capacitor). On the shipping side the pilot ring is credited everywhere and no frame has the camera in the canopy.

## Calibration batch and High (22 Oct, ~00:30 CT): High REOPENED; scale gap measured

This batch follows the coordinator's calibration request. Three fresh code-blind judges each scored, in one batch on one consistent scale:
- the committed CPU sheet `CAMERA/close-1020/_sheet_f10_2_r3_capacitor.png` as a judge-scale anchor;
- a rescore of the GPU Medium sheets (fresh shuffle);
- the new GPU Low/Compatibility capture;
- then the GPU High capture, scored by the same three judges as a continuation.

**Prompt:** `judge_prompt_cal.md`, the same rubric and scoring as round 1. It adds a cap of at most four full frames per fight and a line asking for one scale across sets. The keys were withheld until all scores were in (`f10_2_cal_key.json`).

**Low capture:** Compatibility through opengl3 on the GTX 1060 (`OpenGL API 3.3.0 NVIDIA 560.94 - Compatibility`, not llvmpipe), with the Low preset from the override file. `capture_log.json` records `graphics_preset Low`, `renderer gl_compatibility`. The commands are the same as for Medium, with `--rendering-method gl_compatibility --rendering-driver opengl3`.

**High capture:** Forward+ High, exit 0 on all four runs, no allocation errors. `capture_log.json` records `graphics_preset High`.

| Set (same judges, same scale) | Shipping ON j1/j2/j3 | Mean | Control OFF j1/j2/j3 | Mean | C3 pass (judge × fight) ON / OFF |
|---|---|---|---|---|---|
| **Anchor: CPU r3 sheet** (CPU judges: ON 6.53, OFF 4.00) | 3.5/3.3/3.0 | **3.27** | 2.4/2.3/2.2 | **2.30** | n/a (judged from the sheet only, no full frames) |
| GPU Low / Compatibility | 4.20/4.03/3.93 | **4.06** | 3.68/3.70/3.53 | **3.64** | 16/18 / 11/18 |
| GPU Medium / Forward+ (rescore) | 3.80/3.67/3.58 | **3.68** | 3.07/2.97/2.87 | **2.97** | 18/18 / 9/18 |
| **GPU High / Forward+** | 3.77/3.62/3.52 | **3.63** | 3.17/3.05/2.95 | **3.06** | 17/18 / 10/18 |

**F10#2 High: Bar A 3.63 < 7.5, REOPENED** (the measured score, not adjusted).

What the anchor shows, as measured, with no rescaling applied to any verdict:
- **Scale:** this prompt and these judges score about 3.3 points below the CPU rounds' judges on the identical CPU sheet (6.53 → 3.27 ON, 4.00 → 2.30 OFF).
- **GPU against CPU:** on this one scale, every GPU set scores above the CPU r3 candidate that the CPU judges put at 6.53. Low is +0.79, Medium +0.41 and High +0.36.
- **Test-retest:** Medium scored 3.58 in round 1 and 3.68 here.
- The bar question (judge calibration) is the coordinator's and owner's call.

What the renderer comparison shows: on this GPU, Compatibility (Low) outscores Forward+ Medium and High by about 0.4 for the shipping arm. The judges credited set 2 (Low) with cast tree shadows, grounded and opaque creatures, and better form. They called Medium and High "dark", "desaturated" and creatures "translucent/washed-out". This matches the measured saturation drop below.

Blinding disclosure: the per-fight shuffle came out with shipping as side A on all six High fights, a 1-in-64 draw. One judge remarked that side A always carried the pilot ring. The arm was therefore inferable on High; scores are recorded as given.

Asks across the batch (all judges): the camera still enters canopy on the OFF arm. Where the fade works on the ON arm it leaves stipple on the creature. Judges asked for flat magenta slab/cone telegraphs to be replaced, the HUD bottom band covers the pilot, trainer and telegraph tails, and the arenas are bare dark clearings with cloned same-pose herds (crown_guardian). The pilot reads no taller than the 1.80 m trainer and the trainer clips into the pilot. Fixable in scene: camera/fade, grade/lighting, dressing, herd variety, HUD band, telegraph form. Needs new art: signature Stormwood trunks/glass scars and per-move effects.

## Finding: Forward+ Medium/High desaturate and haze the Stormwood fight frames

This was measured, not judged. It applies whatever the bar decision.

The measurement covers the shipping arm, all 108 interval frames (i00–i17) of the six fights per preset, on the same GPU and the same source (`luma.ps1` sample grid over the play area, HUD excluded):

| Preset (renderer) | Mean luma (0–255) | Lower-band (floor) luma | Mean saturation |
|---|---|---|---|
| Low (Compatibility, opengl3 on the GTX 1060) | 28.9 | 22.7 | 0.488 |
| Medium (Forward+) | 30.9 | 21.9 | 0.317 |
| High (Forward+) | 30.1 | 21.4 | 0.316 |

- **Every preset is very dark.** Mean luma is about 12% of full scale. The judges' "brown-black murk" holds on Compatibility too, so it isn't a Forward+-only defect.
- **Forward+ brightness:** it is not darker overall (+2 luma). The floor band is about 1 luma darker.
- **Forward+ saturation:** it drains colour by about 35% (0.49 → 0.32). The ground loses its brown and moss hue, and creature materials wash toward grey and milky (the Staticub "translucent" note).
- **Likely contributors:** this is consistent with the Medium/High volumetric fog plus SSAO and glow over a dark base exposure. The source wasn't inspected or changed in this pass.

Frame pair: `_sheet_f10_2_gpu_low_vs_medium_i13.png` (capacitor_alpha i13, shipping, GPU Low left, GPU Medium right; the cameras differ slightly because each run plays the fight a little differently).

Sheet: `_sheet_f10_2_gpu_medium_capacitor.png` (capacitor_alpha, ON top, OFF bottom, 12 matched moments). Per-frame captures stay local.

## Yardstick rejudge (22 Oct, ~11:00 CT): Medium 5.52, Low 5.39 on the reference scale, REOPENED

This rejudge used the coordinator's standard yardstick (tb/judge-yardstick 45d5d7535, merged into tb/gpu-pass at f7c149429). The overnight GPU frames were reused; nothing was re-rendered.

**Batch.** `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`:
- 4 anchor pairs (8 tiles): F04#6 r22, F36#0 gap C7, P2-094 r4, F36 NPC C1.
- 12 candidate sets: the six fights × Low and Medium. Each side is a 12-frame grid (i01–i17 odd, tell1-c-late, tell1-e-impact, tell2-e-impact), shipping vs control, with the sides shuffled.

**Judging.** Three fresh judges with `JUDGE_PROMPT.md` verbatim (`yardstick/judge_prompt_filled.txt`). The key and recorded defects were withheld until all verdicts were in.

**Calibration.** `calibrate.py`: linear fit, slope 0.866, intercept 2.052, r 0.853. Anchor RMSE 0.634. The top anchor is 7.53, so this is a confirming batch. No warnings. `yardstick/mapped.json` holds the raw `above_top_anchor` per candidate; all are false.

| Arm | Mapped mean (6 fights) | Range | Occlusion defect calls (judge × fight) |
|---|---|---|---|
| **Medium, shipping (fade ON)** | **5.52** | 5.28–5.69 | FIXED ×15, PARTIAL ×3, PRESENT ×0 |
| Medium, control | 5.29 | 4.94–5.80 | FIXED ×9, PARTIAL ×3, PRESENT ×6 |
| **Low, shipping** | **5.39** | 5.14–5.66 | FIXED ×10, PARTIAL ×8 |
| Low, control | 5.31 | 4.94–5.78 | FIXED ×9, PARTIAL ×3, PRESENT ×6 |

**F10#2: mapped 5.52 (Medium) and 5.39 (Low), below 7.5: REOPENED.** On the GPU, the sight-line fade clears the occlusion defect on every Medium fight: no PRESENT call against 6 on the control. The bar is held down by the rest of the frame, which all three judges named:
- a dark single-value grade with no purple storm sky, lightning or copper/glass;
- flat magenta slab and cone telegraphs;
- a HUD covering about 35–40% of the frame;
- a tiny, low-contrast pilot;
- Mosshock reading as a faceless shrub.

Evidence: `yardstick/` holds the key, batch, mapped scores, three judge JSONs, `sets.md`, `recorded_defects.txt` and the filled prompt. Sheet: `yardstick/_sheet_f10_2_yardstick_capacitor.png`.
