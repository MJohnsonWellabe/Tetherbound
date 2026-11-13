# G-things-telldust: soft tell dust band (F38#3, F38#28, F38#11; GPU High and Medium)

## Verdict: SHIP. Every set gains, 3/3 prefer the arm on all five candidate sets, and none loses. Nothing closes: F38#3 Medium and F38#28 High each land 0.03 under the bar.

| Row | Preset | Base | Arm | Gain | Prefer arm | Arm per judge (mapped) |
|---|---|---|---|---|---|---|
| **F38#3** | High | 7.08 | **7.51** | +0.43 | 3/3 | 7.12, 7.90, 7.51 |
| **F38#3** | Medium | 7.08 | **7.47** | +0.39 | 3/3 | 7.12, 7.90, 7.38 |
| **F38#28** | High (warden 03, 05) | 7.16 | **7.47** | +0.31 | 3/3 | 7.25, 7.38, 7.77 |
| **F38#28** | Medium (warden 03, 05) | 7.29 | **7.55** | +0.26 | 3/3 | 7.25, 7.64, 7.77 |
| **F38#11** (no-loss) | High (the three "! incoming" frames) | 6.56 | **6.95** | +0.39 | 3/3 | 6.73, 7.12, 6.99 |
| control F38#38 | High / Medium | 8.28 | 8.28 | | identical | |

- **Control.** F38#38 read 8.28 against its closing 8.16/8.30, so this panel is neutral.
- **Close calls (not closed):**
  - **F38#3:** High 7.51, Medium 7.47. It misses on Medium by 0.03; the lowest judge is 7.12 on both presets.
  - **F38#28:** Medium 7.55 (above the top anchor; this batch is confirming), High 7.47. It misses on High by 0.03, and is scored on frames 03 and 05 only.
  - Both rows are near-bar. Under the close-out exception they go first in the GPU queue for a small change taking them over 7.5.

## Does the tell still read as danger? (the coordinator's check)
- **The arm does not lose the danger read.** F38#11's recorded defect is PARTIAL on both sides for all three judges, and the tell set gains +0.39 (3/3). No judge says the arm's tell is weaker or harder to see.
- **But neither side's dust reads as a danger cue on its own.** All three judges read the danger from the text ("! incoming — move") and see the dust as the hit or impact trail, not a ground telegraph: "tells are still text only ... there is no ground telegraph or wind-up pose that I can see" (judge c).
- **Why the arm wins (3/3 on every set).** The base's bead strings read as "a chain of evenly spaced round puffs ... a debug particle path" and "a dotted chain of identical round blobs". The arm's soft band reads as "soft smoky dust ... at least reads as kicked-up earth".
- **What still costs (3/3, both sides):**
  - The looping dust covers both creatures' legs, and on grunt-03 and warden-03 the boar's or Burrowback's head too.
  - The judges' next ask is "short, grounded impact puffs and debris at the point of contact", plus a ground telegraph or wind-up pose, so the tell is not text only.

## Other defects, both sides
- **F38#3:**
  - The enemy grunt is mostly hidden behind the boar in every frame (2/3).
  - In frame 3 the trainer merges with Terrapup's muzzle (1/3).
  - The grade is a murky olive with a flat grey sky (3/3).
  - The recorded defect is PARTIAL for 2/3 and FIXED for 1/3: the ally no longer fills half the view.
- **F38#28:**
  - The boundary is a thin curved teal edge line, still PARTIAL (3/3).
  - A translucent green vertical plane stands behind the dog in both frames, read as exposed geometry (2/3).
  - Faint ghost damage numerals sit against the back wall in frame 2 (1/3).
  - The red Warden-hall banner is flagged as close to oxblood (2/3).
- **Confound:** pair_frames.py matched base and arm cameras at 0.00 m, but the pairs can come from different runs. The fight moment and damage numbers can differ, and render differences on the grunt frames are 1–4. Every judge names the dust style as the difference, so the confound does not decide the verdict.

## Frames
- **Source:** `tb/gpu-frames-1108` sections `G-things-telldust-high` (c3be86595) and `G-things-telldust-medium` (3a06c5fc7), `tb/things` f87e2d1b6 (contains main 0a57e6d75).
  - **base:** branch as is.
  - **arm:** `overlay_tell_dust.json`: telegraph.soft_style dust size 0.42 → 0.8 m, spacing 0.34 → 0.3, alpha 0.6 → 0.32, rise 0.16 → 0.06, colour #9c8763 → #8a7654. Painted outlines stay off.
- **Capture:** Meadows fight, `phase2_capture_fights.gd` grunt and Warden, `--attack --tell-frames --fixed-fps 20`. 0 script errors, 0 blank frames.
- **Sets:** all stacked, with recorded defects from job.json.
  - F38#3: south_bridge_grunt-01/02/03.
  - F38#28: warden_aldis-03 and 05. Frames 08 and r04 were excluded because their cameras are unmatched (2.70 m and 2.52 m).
  - F38#11: warden_aldis-03 and south_bridge_grunt-02/03, the "! incoming" frames.
  - F38#38: the closing crafting frames.

## Batch `G-td`
- Three code-blind judges, standard prompt, six candidate sets.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.292, intercept −1.016, r 0.980, anchor RMSE 0.20.
- **Warning:** "meets the bar only above the top anchor (7.53)" for F38#28 Medium arm and the F38#38 control. The anchors reach 7.35 or more, so this is the confirming batch.
- Yardstick: `yardstick_g_things_telldust/`.

**Raw Bar A (judges a, b, c):**

| Set | Base | Arm |
|---|---|---|
| F38#3 High | 6.0, 6.5, 6.3 | 6.3, 6.9, 6.6 |
| F38#3 Medium | 6.0, 6.5, 6.3 | 6.3, 6.9, 6.5 |
| F38#28 High | 6.1, 6.4, 6.5 | 6.4, 6.5, 6.8 |
| F38#28 Medium | 6.1, 6.6, 6.6 | 6.4, 6.7, 6.8 |
| F38#11 High | 5.7, 6.0, 5.9 | 6.0, 6.3, 6.2 |
| F38#38 (High / Medium) | 7.2, 7.2, 7.2 | 7.2, 7.2, 7.2 |

Bar B: no on every fight set (3/3), except one yes on F38#28 Medium (1/3).
