# G-pilot-mark: pilot creature rim 0.9 → 1.4 (F41#3), two runs per side

Frames: `tb/gpu-frames-1108` 949ff4b9, High.
- **live and live2:** main 52a633598, two runs.
- **arm and arm2:** live plus `ITEM-PILOT-MARK/overlay_pilot_mark.json` at 80d8baf1a (`pilot_mark.rim_strength` 0.9 → 1.4), two runs.

**Pairing:** each run was judged as its own pair (r1 = live vs arm, r2 = live2 vs arm2). That separates the arm from run-to-run fight staging.

Not judged:
- **F41#6:** its frame is the same image as an F41#3 frame.
- **F41#21:** not like-for-like.

**No pixel-level render check was possible:** every fight frame differs between runs.

Batch `G-pilot`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 0.9234, intercept 1.2953, r 0.743, **anchor RMSE 0.77**.
- Calibrate warning: "anchor residual RMSE 0.77 > 0.75: these judges do not rank the anchors like the reference judges".

| Pair | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F41#3 r1 | 5.67 (raw 4.8, 4.6, 4.8) | 6.40 (raw 5.6, 5.4, 5.6) | +0.73 | 3/3 |
| F41#3 r2 | 5.57 (raw 4.9, 4.4, 4.6) | 5.57 (raw 4.9, 4.4, 4.6) | **0.00** | 0/3 (3 ties) |

**Verdict: not attributable to the rim, so this does not support shipping.** The two runs disagree.

**r2 is exactly tied.** All three judges call the two sides "almost the same" or "nearly identical". Sparkit is "a white puff wedged behind or under the spider's legs" on **both** sides, so the stronger rim does not make the ally read.

**The r1 gain comes from staging, not the rim.** In the arm run's third frame the fight happens to separate: spider left, trainer centre, Sparkit right, with a "staggered — punish now" callout. In the live run's third frame the spider stands over both. No judge mentions a brighter or more visible rim on Sparkit.

**Capture discrepancy to check (judge c):** the arm side of r1 shows **keyboard prompts** ("F Aim", "C Switch", "Esc Flee", LMB/RMB), while its live side shows controller prompts. The two runs may have been captured with different input setups. That differs from live in more than the rim. Worth checking before the next fight capture.

## What the judges ask for instead (3/3, both runs)
- **Voltarach is blown out by gold-white bloom:** its legs, plates and blue eyes are lost, so it "reads as one bright blob". Clamping its emissive to the vein lines and eyes is the top ask in all three reports. It is also why a brighter ally rim cannot separate the ally against it.
- **Enforce boss-ally spacing:** a ring that keeps Sparkit and the trainer outside the leg span in every frame.
- **The usual fight asks:** physical telegraphs instead of magenta rings, and a camera that stays out of the canopy.
