# F17#6 Crossing Hall r9: GPU pass (24 Oct 2026)

**Verdict: REOPENED.** Main r9 maps to **5.83** and the pre-r9 control to **4.98**, identical at Medium and High. That is +0.85, but well below 7.5, and below the CPU-provisional 6.84.

**Why GPU scores below CPU:** r9's four `hall_great_hall.shafts` (DaylightShaft, two crossed additive quads each) render on Forward+ as **hard, blown-out white bead-streak bars**. They appear in 6 of the 10 day views and cross the trainer in three. All three judges name this as the worst artefact in the batch. The CPU r9 sheet (Compatibility, llvmpipe) shows no visible shafts at all, so the CPU judges never saw it.

This is the same renderer split as the F22#4 boss aura: additive effects that are faint on Compatibility draw at full weight on Forward+.

## Run

- **Arms:**
  - candidate: main 7b5d351da (r9 816dfa60f; `crossing_hall.json` is unchanged since then);
  - control: the same tree with `data/config/crossing_hall.json` from **5f1f388cc**, the only game-content difference between 5f1f388cc and r9.
  - The control file was restored after the run.
- **Capture:** `tools/visual_judge/capture_camera_set.gd --set=res://tools/visual_judge/camera_sets/F17-6.json --preset=<Medium|High>`, all 15 views at 1920x1080. Forward+ on a GTX 1060, with an isolated APPDATA per preset.
- **Capture-tool fix, local:** on a GPU the tool's fixed 300 physics frames end before the Meadows shell reaches its settlement step (about 150–160 s on this machine). The first capture was 15 frames of empty meadow and was discarded.
  - The local copy (`capture_camera_set_ready.gd.txt`) waits for the world's `_shell_ready` flag first. Each log records `shell_ready=true after 148–161 s`.
  - The coordinator has the same fix in aaaa585a1 (#725).
- **Check:** every frame was eyeballed before judging; the Hall is present in all 60.

## Yardstick

- **Batch:** `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`: 4 anchor pairs plus 6 candidate sets.
  - The sets are the CPU r9 groupings: approach-nave, nave-sides and shrine, five views each, at Medium and High.
- **Judges:** three fresh code-blind judges, each given `JUDGE_PROMPT.md` (main) verbatim.
- **Recorded defects:** the three CPU r9 defects (bare courtyard and cold grade; near-field posts; no shrine focal).
- **Calibration:** 8 points, slope 0.896, intercept 1.723, r 0.90, anchor RMSE 0.54. Confirming batch (top anchor 7.53), no warnings.

| Set | Control raw (j1/j2/j3) | Control mapped | Main r9 raw | **Main r9 mapped** |
|---|---|---|---|---|
| approach-nave | 4.2/3.8/3.8 | 5.25 | 5.0/4.6/4.6 | **5.96** |
| nave-sides | 3.6/3.0/3.0 | 4.59 | 4.5/4.5/4.0 | **5.61** |
| shrine | 4.0/3.5/3.8 | 5.10 | 5.0/4.6/4.5 | **5.93** |
| **mean** | | **4.98** | | **5.83** |

The Medium and High sheets got the same scores from every judge; two judges said outright that the paired sets were the same images. Bar B: no for every Hall set, from all three judges.

## Recorded defects on main r9 (j1/j2/j3)

| Set | Bare courtyard / cold grade | Near-field posts | No shrine focal |
|---|---|---|---|
| approach-nave | PARTIAL / FIXED / PARTIAL | PARTIAL / PRESENT / PARTIAL | PARTIAL ×3 |
| nave-sides | PARTIAL / FIXED / PARTIAL | PARTIAL ×3 | PARTIAL / PARTIAL / PRESENT |
| shrine | PARTIAL ×3 | PARTIAL ×3 | PARTIAL ×3 |

## What the judges saw

**New on r9 (GPU):**
1. White bead-streak shafts: nave-forward day; nave-arches-left/right day; nave-reverse day; shrine-pedestals day and reverse day. They blow out a third of nave-arches-right day and pass over the trainer.
2. Neon blue/violet rim strips on the sealed arches (night and rain), which read as UI glow or portals, not architecture.

**Carried by r9:**
- warm plank floor;
- blue runner;
- chandeliers;
- teal banners;
- the shrine fountain as a focal point. It is lit cool white-blue, not warm.

**Still open:**
- The nave reads as an empty corridor: no tables, hearth or clutter.
- Posts still bracket nave-forward night and rain.
- The shrine pedestals are an even, generator-like ring.
- The grey stone gate-tower exterior reads off-family against the half-timbered cottages. Two judges preferred the control's half-timbered hall facade.

**Top changes (all three judges, all "scene"):**
1. Remove or repair the shafts and the neon arch rims, keeping the warm furnishing.
2. Add a warm fire-lit shrine focal point and furnish the nave.
3. Move the cameras or posts out of the near field.

## Suggested fix (Meadows lane)

Make the shafts renderer-aware, as `enemy_pattern_telegraph.aura_renderer_scale()` does for the boss aura:
- on Forward+, scale `hall_great_hall.shaft.strength` down hard, or drop the quads;
- or replace the quads with a soft volumetric or fog-light approach.

The arch rim strips probably need the same treatment.

A shafts-off Medium diagnostic (`hall_great_hall.shafts = []`) is queued on this lane, to show what the rest of r9 scores on GPU. It will be added here as `noshafts/`.

## Files

- `_sheet_f17_6_r9_gpu.png`: Medium, control (top) vs main r9 (bottom); nave-forward day, arches-right day, nave-forward night, shrine day.
- `yardstick/`:
  - `key.json`, `sets.md`, `candidates.json`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1.json`–`j3.json`: per-set scores. j2 is the judge's own block; j1 and j3 hold the same scores and defect calls, with the notes trimmed;
  - `batch.json`, `mapped.json`.
- `capture_camera_set_ready.gd.txt`, `f17b_queue.ps1.txt`: the local tools used.
- Per-frame captures stay local.
