# G-nerissa-win-release-snap: F39#21 Nerissa win, release snap (GPU High)

Frames: `tb/gpu-frames-1108` 9ecc4d914, `gpu-frames-1108/G-nerissa-win-release-snap/{live,arm}-High/nerissa/`.
Batch `G-ner`: three code-blind judges, standard prompt, anchors craft + f36_0_npc:C1 (7.47/7.53) + f10_2_r3_capacitor.
This is a confirming batch (top anchor reference 7.53), so no score here is extrapolated.

## Verdict: SHIP. Does not close (arm win maps 6.63 on High). No Medium confirm to queue.

| Frame | Live (mapped) | Arm (mapped) | Gain | Judges preferring arm |
|---|---|---|---|---|
| win | 5.32 (5.73, 5.29, 4.95) | **6.63** (6.63, 6.85, 6.40) | **+1.31** | 3/3 |
| aftermath | 5.06 (5.06, 5.40, 4.73) | **6.22** (5.96, 6.51, 6.18) | **+1.16** | 3/3 |
| midfight (t-040.02, regression check) | 6.70 (6.85, 6.85, 6.40) | 6.70 (6.51, 6.96, 6.63) | 0.00 | 2/3 (no loss) |

Raw Bar A (judges a, b, c):
- win: live 5.2, 4.8, 4.5 → arm 6.0, 6.2, 5.8.
- aftermath: live 4.6, 4.9, 4.3 → arm 5.4, 5.9, 5.6.
- midfight: live 6.2, 6.2, 5.8 → arm 5.9, 6.3, 6.0.

Fit: linear, slope 1.1162, intercept −0.0714, r 0.835, 6 anchor points, top_anchor_reference 7.53, confirming_batch true, above_top_anchor false for every candidate.
Warning (verbatim): `anchor residual RMSE 0.76 > 0.75: these judges do not rank the anchors like the reference judges; report the mapped scores with this caveat`. The C1 and craft:after anchors map within 0.1 of reference; the error comes from the low anchors (f10_2 r3 −1.43, craft:before +1.02).

Render check: win 64.7%, aftermath 45.9%, midfight 30.3% of pixels changed by more than 30.

Recorded defect (victory reward panel over full exploration HUD): PARTIAL on both sides from all three judges. The roster and hotbar are gone; the vitals and the "Put Bramblebun away" prompt still compete with the panel.

## What carried the arm
- **Win:** live has a flat pale-cyan crystal slab covering the right half of the frame, with Bramblebun cut off at the left edge. The arm stages Bramblebun whole beside the trainer, with Nerissa visible in the middle distance.
- **Aftermath:** live sits on the trainer's back with no creature in view (all three judges). The arm shows creature, trainer, banner and arches.

## Remaining defects (gap to 7.5)
- The crystal still cuts in at the top-left edge of the arm win and aftermath frames as a hard, flat-shaded shape.
- The patterned "carved" crates in the foreground (right on win, bottom-left on aftermath) read as an off-family collage texture (3/3 judges).
- The blue statue on the right reads as an unlit blob.
- Midfight, both sides: the flat white waterfall wall card. Ripplet is partly hidden behind the crystal and its plinth on the arm side.
- Fixability:
  - **Scene:** keep the crystal and the crates out of the victory cameras, or fade them.
  - **New art:** a faceted crystal with a proper material, stone-family crates and a real falls mesh. These would be Meshy candidates.
