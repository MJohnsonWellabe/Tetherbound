# G-f36-72-stormbrush-medium: F36#72 Stormbrush poses at Medium (GPU)

## Inputs
- **Frames:** `tb/gpu-frames-1108` f835c10d5, Medium, one-sided, on main 3a514ef5c as it is.
  - The High set (7.68, `G-rescore-tier2-batch-2.md`) was on main 0058b0d6c.
- **Capture:** `capture_f36_poses.gd --whole-body --context`, hit and faint 000–100.
- **Set:** the same crop as High (560,200 1000×640 at 1080p).
  - Tiles: standing (hit 000), hit 050, faint 050 and faint 100.
  - Brief and recorded defects: the same F36 (1) brief and defects as the High set.
- **Render check:** blank frames 0 of 10.

## Batch `G-sbm`
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.4557, intercept −2.3905, r 0.982, anchor RMSE 0.189.
- **Warning:** stormbrush meets the bar only above the top anchor (7.53). This batch's anchors reach 7.35 or more, so it is the confirming batch.

## Verdict: Medium maps to 7.75, so F36#72 CLOSES (High 7.68 + Medium 7.75, both at 7.5 or above)

| Preset | Raw a, b, c | Mapped per judge | Mapped mean |
|---|---|---|---|
| High (G-r3a) | 6.5, 7.2, 7.0 | n/a | 7.68 ↑top |
| **Medium (G-sbm)** | 7.1, 7.0, 6.8 | 7.94, 7.80, 7.51 | **7.75** ↑top |

- **Every judge is at or above 7.5:** the lowest mapped judge is 7.51.
- **Recorded defects:**
  - "oversaturated plastic-blue fur": FIXED for judges a and c, PARTIAL for judge b.
  - "bulk hides the trainer ruler": PARTIAL 3/3. The tail sweeps across the trainer's hand and hip in the standing and faint-mid frames, but the trainer stays readable.
- **Bar B:** yes from judge a; no from judges b and c, who cite the bare stage atmosphere and the faint-end lump.

## Remaining notes (do not block the close)
- **Faint end (3/3):** a flat dark fur mound with the face hidden, so it loses identity at 30% size.
- **Species read (2/3, new_art):** the build is a long-legged badger-wolf with a long brush tail, against the board's stocky badger. The white face stripe carries the identity.
- **Owner rules:** no red flag; the creature is taller than the trainer (3/3).
