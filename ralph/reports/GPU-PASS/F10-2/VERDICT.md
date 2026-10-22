# GPU pass: F10#2 Stormwood named-fight camera (Medium): REOPENED

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

Sheet: `_sheet_f10_2_gpu_medium_capacitor.png` (capacitor_alpha, ON top, OFF bottom, 12 matched moments). Per-frame captures stay local.
