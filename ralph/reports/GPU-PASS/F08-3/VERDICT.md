# F08#3 Cloudreach settlements and cliff identity: GPU pair c14 / a14 (22 Oct 2026, late morning)

**Verdict: REOPENED.** On the yardstick the candidate maps to **5.75** and the control to **5.72**, at both Medium and High. The gain is +0.03 against the 7.5 bar.

The lane's CPU gain (5.91 vs 5.04) does not show on GPU.

**One confound to read alongside the score:** every candidate frame renders in **grey overcast with rain**, and every control frame under **clear sky**. Details are under "Weather confound" below.

## What was run

- **Source:** `ff3cc7cfa427d6ebaec276ca3187d1890a1d33c7` (tb/cloudreach), checked out as a local detached worktree. Nothing was committed from it.
- **Arms:**
  - Control **c14**: the flag off.
  - Candidate **a14**: `--cloudreach-settlement-life-candidate`. The log shows the flag active: `SETTLEMENT_LIFE placed ...` lines.
- **Capture:** `res://tools/capture_cloudreach_settlement_identity.gd -- --preset=<Medium|High> --source-commit=ff3cc7cf... --output=<fresh>`.
  - Five stands × day/night = the same 10 views in every run, at 1920x1080.
  - Forward+ on Vulkan, on an NVIDIA GTX 1060 3GB.
  - Each preset reads its own isolated `user://graphics_override.cfg` (`preset="Medium"` / `"High"`).
  - The manifests confirm preset, renderer, adapter and source commit.
  - Exact commands and manifest headers are in `commands_and_manifests.txt`.
- **All four runs:** exit 0, 10/10 views. The manifest stand, trainer and camera positions are identical across arms.

## Yardstick result

**Batch:**
- Built with `tools/visual_judge/anchor_tiles.py --pairs 4 --include f36_0_npc:C1`.
- 4 anchor pairs: f10_2_r3_capacitor, p2_094_r4, f36_0_npc C1 and f36_0_gap C5.
- 2 candidate pairs: Medium a14|c14 and High a14|c14.
- Sides shuffled.

**Judges:**
- Three fresh, code-blind judges, each given `JUDGE_PROMPT.md` verbatim (filled copy in `yardstick/judge_prompt_filled.txt`).
- The key was withheld until all three verdicts were in.

**Calibration (`calibrate.py`):**
- 8 anchor points, linear fit, slope 0.736, intercept 2.635, r 0.81.
- Confirming batch: the top anchor reference is 7.53.
- **Warning:** anchor RMSE 0.85 is above 0.75. These judges rank the anchors somewhat differently from the reference judges, so the mapped scores carry that caveat.

| Pair | Judges (raw Bar A) | Mapped per judge | **Mapped mean** | Meets 7.5 |
|---|---|---|---|---|
| Medium a14 (candidate) | 4.5 / 4.3 / 3.9 | 5.94 / 5.80 / 5.50 | **5.75** | no |
| Medium c14 (control) | 4.3 / 4.0 / 4.3 | 5.80 / 5.58 / 5.80 | **5.72** | no |
| High a14 (candidate) | 4.5 / 4.3 / 3.9 | 5.94 / 5.80 / 5.50 | **5.75** | no |
| High c14 (control) | 4.3 / 4.0 / 4.3 | 5.80 / 5.58 / 5.80 | **5.72** | no |

All three judges independently said the Medium and High sheets look the same at judging resolution. The source frames are not byte-identical, so High adds no visible difference at these stands.

## Recorded defects (per judge: candidate a14 | control c14)

| Defect | a14 candidate | c14 control |
|---|---|---|
| Flat lawn or dirt foreground | PRESENT ×3 | PRESENT ×3 |
| Night stays flat moon-blue | PARTIAL, PARTIAL, PRESENT | PRESENT ×3 |
| Night road rust-red under warm lamps (near oxblood) | **PRESENT ×3** | FIXED, PARTIAL, FIXED |
| Window glow blows to white | PRESENT, PARTIAL, PARTIAL | PARTIAL ×3 |

## What the judges saw

**Candidate:**
- The judges credited it with the batch's strongest settlement identity:
  - floating rock islands;
  - the upper-town stone hall with blue banners and arched windows;
  - the stair building.
- Against that, the grey rain flattens day and night alike, the fog eats the distant cliffs, and the warm lamps make the night road rust-red.
- Window glow clips to near-white at windwatch night.

**Control:**
- Its bright sky and pale stratified spires match the Cloudreach board.
- But the stands read sparse: a few timber houses on an empty lawn, with almost no props or people, and the upper and lower settlements blur together.
- Nights are flat moon-blue with pinprick lamps.

**Both arms:**
- No stand shows a cliff edge or drop-off.
- Four of five foregrounds are bare road on lawn.
- The trainer always stands at frame centre.

**Top changes the judges named:**
1. Dress each stand's foreground with props, people and fences, and show a cliff edge.
2. At night, use warm lamp pools and unblown windows over a darker base, with a road colour that stays out of oxblood.
3. Keep the upper town's stone-and-banner identity distinct from the timber lower village.
4. Combine the candidate's architecture with the control's clear sky.

## Weather confound

- **What differs:** the c14 frames are clear sky in both presets, and the a14 frames are overcast with rain in both presets. Since it repeats the same way at both presets, the difference comes with the candidate run rather than with chance. See `_sheet_f08_3_medium.png`.
- **Why it matters:** the judges penalised the candidate's grey rain while crediting its architecture. So this pair does not isolate the settlement dressing from the weather.
- **What I checked:** the settlement-life code and config at ff3cc7cfa contain no weather setting. A likely cause is that the candidate's extra build work shifts the game's weather roll, but this was not proven.
- **Proposed follow-up:** a weather-pinned re-run, both arms under the same clear sky. This capture tool has no weather argument, so it needs a small process-local wrapper. The lane could also pin it in the tool. The coordinator decides.

## Files

- `_sheet_f08_3_medium.png`: Medium, five stands × day/night. Control pair on the left, candidate pair on the right.
- `commands_and_manifests.txt`: exact command lines and manifest headers for all four runs.
- `yardstick/`:
  - `key.json`, `candidates.json`, `sets.md`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1.json`–`j3.json`: the judges' final JSON blocks;
  - `batch.json`, `mapped.json`: calibrate output.
- Per-frame captures and judge tiles stay local and are not committed.
