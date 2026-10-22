# GPU pass: F04#6 Meadows trainer aftermath: Medium REOPENED (4.69), High REOPENED (4.72)

22 Oct 2026, ~00:15 CT. Remote GPU lane (owner's Windows desktop).

- **Renderer:** Forward+ on Vulkan 1.3.280, NVIDIA GeForce GTX 1060 3GB (driver 560.94), real GPU.
- **Presets:** Medium and High via the probe's own `--preset=` check. The log prints `PROBE graphics: Medium / forward_plus` (High likewise).
- **Resolution:** 1280x720.
- **Memory:** no allocation errors on the full-vegetation Meadows scene at either preset. Each run took 2–4 minutes.
- **Source:** `tb/gpu-pass` at origin/main 9db3d2146, unmodified. No flag, config or code changed.

## Commands

```
godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1280x720 \
  --script res://tools/_probe_aftermath_sites.gd -- --out=<dir> \
  --cameras=res://tools/visual_judge/camera_sets/F04-6.json --preset=<Medium|High> --candidate      # shipping (flag ON)
godot ... --script <local wrapper> -- --out=<dir> --cameras=... --preset=<Medium|High>                # control
```

- **Shipping arm:** `visual_candidate_enabled` is ON on disk. The probe needs `--candidate` to capture it and reports `PROBE visual candidate: true`.
- **Control arm:** a wrapper (`f04_6_control.gd.txt`) sets `trainer_aftermath.config().visual_candidate_enabled = false` in-process, then calls the unchanged probe's `_init` (`PROBE visual candidate: false`).
- **Wrapper fix:** the first control run hung because the subclass `_init` replaced the probe's and `_run` never started. That run was stopped and re-run with an explicit `super()`. This is a local harness fix; nothing in the repo changed.
- **Capture type:** direct-settle diagnostic, the same as the CPU rounds. This is not an earned defeat.

## Judging

Three fresh code-blind judges, one batch on one scale:

- **Anchor:** the committed CPU sheet `CAMERA/close-1020/_sheet_f04_6_r22.png`, with its arm labels masked to "A before | A after | B before | B after". A = control and B = r22 on every row; the judges weren't told.
- **GPU Medium sheet:** five rows, A/B balanced-shuffled per row.
- **GPU High sheet:** shuffled separately.

Judges saw only the sheets, the full frames, `docs/reference/` and ART_DIRECTION. The keys were withheld until all scores were in (`f04_6_gpu_key.json`, prompt `judge_prompt.md`).

| Set (same judges, same scale) | Shipping ON j1/j2/j3 | Mean | Control OFF j1/j2/j3 | Mean |
|---|---|---|---|---|
| **Anchor: CPU r22 sheet** (CPU judges: r22 6.75, control 5.83) | 4.26/4.60/4.90 | **4.59** | 2.90/2.96/3.42 | **3.09** |
| **GPU Medium** | 4.46/4.60/5.00 | **4.69** | 3.10/2.96/3.52 | **3.19** |
| **GPU High** | 4.46/4.60/5.10 | **4.72** | 3.10/2.96/3.62 | **3.23** |

Per site, ON mean for Medium / High: dell 4.00/4.03, relay_captain (Vance) 5.13/5.17, riverwatch 5.07/5.10, field 4.57/4.60, ridge 4.67/4.70.

**Bar A on GPU: Medium 4.69 and High 4.72, both below 7.5. REOPENED.** Bar B: no, from all three judges on every sheet.

Calibration, as measured: this prompt scores the CPU r22 sheet 2.16 below the CPU judges. On this scale GPU Medium/High sit +0.10/+0.13 above the CPU r22 frames. ON over OFF is +1.50 on GPU and +1.50 on the CPU anchor.

GPU Medium and High are close to identical for this scene: mean absolute pixel difference 3–6/255, and 1–6% of pixels differ by more than 24. Two judges reported the M and H sheets as "the same frames".

## Judges' asks (all three)

1. **The enemy's hold doesn't fully end (fixable in scene).**
   - The beaten grunt or officer stays standing in frame at Dell and at Riverwatch.
   - The Dell pylon stays lit.
   - "Banner down + relit waystone" repeats at Dell, Riverwatch and Ridge.
   - Only the freed captive (Vance) and the doused camp (Field) read as site-specific.
2. **Grounding artefacts (fixable in scene).**
   - A crate floats in the Dell tunnel, with purple placeholder slabs on the tunnel wall.
   - A gold disc is half-buried at Field.
   - The Field smoke column reads as a uniform billboard.
   - A grey blade intrudes at the bottom-right edge at Ridge.
   - On the control arm, the freed child sinks waist-deep at Vance.
3. **Base world.**
   - Flat, smeared terrain at Vance/Field and the box-like tunnel cliff need new art.
   - The grade is fixable in scene. The GPU frames read as "murky, desaturated, teal"; the CPU anchor reads "washed, yellow-green, soft".

Sheet: `_sheet_f04_6_gpu_medium.png` (GPU Medium, per site OFF before | OFF after | ON before | ON after). Per-frame captures stay local.

## Yardstick rejudge (22 Oct, ~11:15 CT): mapped 5.92, REOPENED

This rejudge used the standard yardstick (`tb/judge-yardstick` 45d5d7535). The overnight GPU Medium frames were reused.

**Batch.** `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`:
- 4 anchor pairs: F36 NPC C1, F36#0 gap C3, F10#2 r3 capacitor, F04#6 r22.
- Candidates: the five sites (before|after per side, shipping vs control, shuffled) plus F29#3.

Three fresh judges used `JUDGE_PROMPT.md` verbatim.

**Calibration.** Linear fit, slope 0.635, intercept 3.402, r 0.841. Anchor RMSE 0.576. Top anchor 7.53, so this is a confirming batch. No warnings.

| Arm | Mapped mean (5 sites) | Range | Aftermath defect calls (judge × site) |
|---|---|---|---|
| **Medium, shipping (flag ON)** | **5.92** | 5.27–6.37 | FIXED ×10, PARTIAL ×5 |
| Medium, control | 5.50 | 4.99–5.88 | PARTIAL ×2, PRESENT ×13 |

**F04#6: mapped 5.92, below 7.5: REOPENED.** The shipping aftermath clears the recorded defect at 10 of 15 judge-site calls; the control is PRESENT at 13. The judges named the remaining gaps:
- Generic removal-only changes at the gate site (Dell), with a red banner heap left as debris.
- The repeated lit-rune-stone payoff at Riverwatch and Ridge.
- Base-world finish: a smeared ground texture, the stretched tunnel wall and water slab, a uniform grass carpet and flat light with no aerial depth.

Evidence is in `yardstick/`. Sheet: `yardstick/_sheet_f04_6_yardstick_relay_captain.png`.
