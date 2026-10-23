# F08#3 Cloudreach settlements r17: weather-pinned GPU pair (22 Oct 2026, evening)

**Verdict: REOPENED.** The candidate maps to **6.57** and the control to **5.20**, the same at Medium and High. That is a **+1.37** gain, below 7.5.

The weather confound from the c14/a14 pair (`../VERDICT.md`) is gone: every frame of both arms is clear sky.

## Run

- **Source:** tb/cloudreach `ef2db84ccd4aeb6e7e0cd364405358e3919c4ed3` (r17), in a local detached worktree.
- **Arms:**
  - control: the flag off;
  - candidate: `--cloudreach-settlement-life-candidate` (157 `SETTLEMENT_LIFE placed` lines in the Medium log).
- **Capture:** `tools/capture_cloudreach_settlement_identity.gd --preset=<Medium|High> --source-commit=ef2db84c... --output=<fresh>`.
  - The same 10 views (five stands × day/night), at 1920x1080, Forward+ on a GTX 1060.
  - Exact commands and manifest headers are in `commands_and_manifests.txt`.
- **Weather:** all four manifests record `# weather pinned clear (cycle stopped)`. `_sheet_f08_3_r17_weather_clear.png` shows all 40 frames: clear sky in both arms at both presets, with no rain.

## Yardstick

- **Batch:** `anchor_tiles.py --pairs 4 --include f36_0_npc:C1`, with the candidate pairs at Medium and High.
- **Judges:** three fresh code-blind judges, each given the current `JUDGE_PROMPT.md` (tb/owner-creature-style `e188bc862`, owner direction) verbatim.
- **Calibration:** 8 points, slope 0.893, intercept 1.780, r 0.92, anchor RMSE 0.48, no warnings, confirming batch.

| Arm | Raw (j1/j2/j3) | Mapped per judge | **Mapped mean** |
|---|---|---|---|
| Medium control | 3.6 / 4.0 / 3.9 | 4.99 / 5.35 / 5.26 | **5.20** |
| **Medium candidate** | 5.4 / 5.4 / 5.3 | 6.60 / 6.60 / 6.51 | **6.57** |
| High control | 3.6 / 4.0 / 3.9 | 4.99 / 5.35 / 5.26 | **5.20** |
| **High candidate** | 5.4 / 5.4 / 5.3 | 6.60 / 6.60 / 6.51 | **6.57** |

All three judges saw the Medium and High sheets as identical, as in the c14/a14 pair.

**Recorded defects on the candidate (j1/j2/j3):**
- Flat lawn foreground: PRESENT, PRESENT, PARTIAL.
- Moon-blue nights: PARTIAL ×3.
- Rust-red road under the lamps: PARTIAL ×3.
- White window glow: PARTIAL ×3.

**On the control:**
- Foreground and moon-blue nights: PRESENT ×3.
- Rust road: PARTIAL, FIXED, PARTIAL.
- Window glow: PRESENT, PRESENT, PARTIAL.

## What the judges saw

**Candidate:**
- floating rock islets;
- cloud banks;
- stratified stone stacks;
- the upper town's stone halls with blue banners and amber arched windows (the windwatch night is "the most lived-in frame in the set").

**Control:** a near-empty lawn plateau with a few timber houses, which "does not read as a sky island".

**Remaining asks (all three judges):**
1. Dress each fixed stand's foreground (cobbles, edging, props, a visible cliff lip) and add height fog or haze.
2. Night: warm lamp pools, amber window emission with falloff instead of white, a neutral road, and value in the islets so they don't go black.
3. Placement and identity:
   - vary the islets' size and placement (they read as generated);
   - the gothic stone halls next to the timber cottages read as two architecture families.

## Files

- `_sheet_f08_3_r17_weather_clear.png`: the tool's own 10-view sheet for each arm and preset (weather check).
- `commands_and_manifests.txt`: exact commands and manifest headers.
- `yardstick/`:
  - `key.json`, `sets.md`, `recorded_defects.txt`, `judge_prompt_filled.txt`;
  - `j1.json`–`j3.json`: the judges' scores;
  - `batch.json`, `mapped.json`.
- Per-frame captures stay local.
