# Hall I — isolated interior blind comparison

Recorded 2026-10-13 18:37 CT. Branch `tb/ev-visual`; runnable source `0ed5f35e92112fbff9b399d1c6f56f5eabde96db`. Godot 4.7, Forward+, Medium and High, 1280×720. Three fresh independent code-blind judges reviewed the contact sheet, all 52 full-size frames, keyart, Palworld references and ART_DIRECTION. They received neutral A/B labels, no source, mapping, earlier scores or performance budget.

Scope: 13 committed interior cameras × two presets = 26 matched pairs. Fixed idle trainer, isolated Hall at assumed ground Y=0; exterior approaches, terrain integration, traversal, follower/collision behavior and full-world acceptance are unverified. F17#6 remains open. Both production candidate flags remain OFF.

## Evidence and verification

- Neutral sheet: `D:/tetherbound/.artifacts/visual-takeover/hall-review-0ed5f35e92/phase1-verified/public/_sheet.png`.
- Sheet SHA256: `99d1e20269ecf96aa188ccdda081dadcfc9a20e28531d7510d6e01be93213e35`.
- Original first-run receipt remains FAILED due to wrapper postprocessing; the explicit predecessor record independently validates its engine exit 0, logs and three PNGs. Continuation receipt is EXITED_ZERO_AWAITING_REVIEW, all 15 steps PASSED and 49 PNGs.
- Original run: `D:/tetherbound/.artifacts/visual-takeover/hall-arms-0ed5f35e92/capture-runs/run-hall-arms-phase1-0ed5f35e92`.
- Continuation: `D:/tetherbound/.artifacts/visual-takeover/hall-arms-0ed5f35e92/capture-runs/run-hall-arms-phase1-cont-0ed5f35e92`.
- Validated exact source pin, all raw image hashes against receipt/recovery, graphics-profile hashes, log hashes, empty stderr, natural engine exits, preset/Forward+/idle/arm/OFF/isolated markers, dimensions/format, freshness and complete unique camera coverage. Preserved originals. Private receipt chain and mapping remain outside judge input in `phase1-verified/PRIVATE-provenance.json`.
- Verdict JSONs in this directory retain every judge score, per-view defects, reference rationales and ranked scene-versus-art fixes; `Hall-I-aggregate.json` retains per-view three-score arrays, means and spreads. Aggregator requires distinct judge IDs, exact 26-pair coverage and actual sheet hash.

## Round scores

Mapping disclosed after independent verdicts: A = furnishing; B = baseline. Round mean is the mean of each judge’s equally weighted 26-view average. Spread is maximum minus minimum judge average, not a confidence interval.

| Arm | Bar | Judge 1 | Judge 2 | Judge 3 | Mean | Spread |
|---|---|---:|---:|---:|---:|---:|
| Baseline | A | 3.000 | 3.231 | 2.915 | 3.049 | 0.315 |
| Baseline | B | 2.462 | 2.588 | 2.323 | 2.458 | 0.265 |
| Furnishing | A | 3.554 | 4.054 | 3.577 | 3.728 | 0.500 |
| Furnishing | B | 2.800 | 3.192 | 2.723 | 2.905 | 0.469 |

Furnishing gain: Bar A **+0.679**, Bar B **+0.447**. Bar A remains far below 8.5; all three judges answered no for both arms on both reference-fit questions. This matched GPU comparison is not two consecutive flat rounds: its Bar A gain exceeds 0.5, and historic Low results are not substituted into the revised stop rule. No candidate activation or acceptance follows.

## Highest-impact defects and next work

1. **Night light and trainer integration — scene work.** All night nave/shrine views bleach stone, plaster and timber into beige haze, lose depth, and show disconnected bright floor pools. The trainer stays disproportionately crisp/dark and weakly grounded. Reduce uniform fill/haze, preserve material values, motivate local warm sources and cooler openings, then recapture. Still images indicate weak contact, not proof of physical floating.
2. **Architecture and human-scale use — scene work first.** Day nave forward/reverse and arch views read as a large repetitive shell with exterior-like upper facades, questionable eaves/junctions and little structural hierarchy. Furnishing improves occupation, but small benches/supplies cannot resolve the empty spans. Judge 2 specifically flags fragmented/occluded baseline night windows; diagnose against native frames rather than assuming a cause. The already-prepared structural-frame arm is a bounded next comparison, not a demonstrated fix.
3. **Shrine/portal identity — new authored art may be needed.** Shrine forward/reverse views read as generic sloped lecterns; arch destinations read as thin labeled doors/dark wall sections. Strong portal surrounds, symbols and distinctive pedestal silhouettes would add identity at small size. No purchase is authorized or required by this finding; installed-kit composition may be tested before commissioning geometry.

Trainer silhouette is readable, but its lighting/contact does not match the room; rear fixed-idle images cannot establish face quality or animation. These are independent critics’ visible findings, not source-level diagnoses.

Root owns the next native slot. Phase 2 may compare the existing OFF frame candidate against the same-pin furnishing images; use a fresh neutral sheet and three fresh judges. Do not stack further unjudged art changes. F04 remains separately queued behind faithful terrain/context and memory admission.

## Per-view means and spreads

Each cell is mean / spread across the three judges. Exact individual scores and frame-specific defects are in the adjacent JSON verdicts.

| Preset / camera | Baseline A | Furnishing A | Baseline B | Furnishing B |
|---|---:|---:|---:|---:|
| Medium / nave-forward_day_clear | 3.47 / 0.50 | 4.67 / 0.50 | 2.97 / 0.30 | 3.67 / 0.50 |
| Medium / nave-forward_night_clear | 2.47 / 0.40 | 3.03 / 0.50 | 1.87 / 0.20 | 2.13 / 0.40 |
| Medium / nave-forward_day_rain | 3.23 / 0.50 | 4.30 / 0.70 | 2.80 / 0.40 | 3.40 / 0.60 |
| Medium / nave-arches-left_day_clear | 3.63 / 0.40 | 4.27 / 0.60 | 3.10 / 0.30 | 3.53 / 0.50 |
| Medium / nave-arches-left_night_clear | 2.50 / 0.20 | 2.90 / 0.50 | 1.80 / 0.20 | 2.10 / 0.50 |
| Medium / nave-arches-right_day_clear | 3.47 / 0.50 | 4.07 / 0.60 | 2.97 / 0.30 | 3.37 / 0.40 |
| Medium / nave-arches-right_night_clear | 2.40 / 0.20 | 2.80 / 0.50 | 1.80 / 0.20 | 2.07 / 0.40 |
| Medium / nave-reverse_day_clear | 3.60 / 0.40 | 4.30 / 0.50 | 3.03 / 0.30 | 3.53 / 0.40 |
| Medium / nave-reverse_night_clear | 2.50 / 0.20 | 2.90 / 0.50 | 1.83 / 0.10 | 2.13 / 0.40 |
| Medium / shrine-pedestals_day_clear | 3.67 / 0.30 | 4.57 / 0.60 | 3.07 / 0.30 | 3.73 / 0.50 |
| Medium / shrine-pedestals_night_clear | 2.53 / 0.50 | 3.07 / 0.60 | 1.83 / 0.30 | 2.20 / 0.50 |
| Medium / shrine-pedestals-reverse_day_clear | 3.67 / 0.30 | 4.53 / 0.60 | 3.07 / 0.30 | 3.70 / 0.50 |
| Medium / shrine-pedestals-reverse_night_clear | 2.53 / 0.50 | 3.07 / 0.60 | 1.83 / 0.30 | 2.20 / 0.50 |
| High / nave-forward_day_clear | 3.47 / 0.50 | 4.67 / 0.50 | 2.97 / 0.30 | 3.67 / 0.50 |
| High / nave-forward_night_clear | 2.47 / 0.40 | 3.03 / 0.50 | 1.87 / 0.20 | 2.13 / 0.40 |
| High / nave-forward_day_rain | 3.23 / 0.50 | 4.30 / 0.70 | 2.80 / 0.40 | 3.40 / 0.60 |
| High / nave-arches-left_day_clear | 3.63 / 0.40 | 4.27 / 0.60 | 3.10 / 0.30 | 3.53 / 0.50 |
| High / nave-arches-left_night_clear | 2.50 / 0.20 | 2.90 / 0.50 | 1.80 / 0.20 | 2.10 / 0.50 |
| High / nave-arches-right_day_clear | 3.47 / 0.50 | 4.07 / 0.60 | 2.97 / 0.30 | 3.37 / 0.40 |
| High / nave-arches-right_night_clear | 2.40 / 0.20 | 2.80 / 0.50 | 1.80 / 0.20 | 2.07 / 0.40 |
| High / nave-reverse_day_clear | 3.60 / 0.40 | 4.30 / 0.50 | 3.03 / 0.30 | 3.53 / 0.40 |
| High / nave-reverse_night_clear | 2.43 / 0.10 | 2.90 / 0.50 | 1.80 / 0.00 | 2.13 / 0.40 |
| High / shrine-pedestals_day_clear | 3.67 / 0.30 | 4.57 / 0.60 | 3.07 / 0.30 | 3.73 / 0.50 |
| High / shrine-pedestals_night_clear | 2.53 / 0.50 | 3.07 / 0.60 | 1.83 / 0.30 | 2.20 / 0.50 |
| High / shrine-pedestals-reverse_day_clear | 3.67 / 0.30 | 4.53 / 0.60 | 3.07 / 0.30 | 3.70 / 0.50 |
| High / shrine-pedestals-reverse_night_clear | 2.53 / 0.50 | 3.07 / 0.60 | 1.83 / 0.30 | 2.20 / 0.50 |
