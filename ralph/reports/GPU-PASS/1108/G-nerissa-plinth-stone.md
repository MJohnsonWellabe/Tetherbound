# G-nerissa-plinth-stone: F39#21 / F39#28 Heart Chamber plinths re-skinned to stone (GPU High)

Frames: `tb/gpu-frames-1108` 321bfa17c, High, `--fixed-fps 20`, seed 2042.
- base = `tb/item-nerissa-room` f81c7e994 (main batch 45, release snap ON).
- arm = base + `ITEM-NERISSA-PLINTH/overlay_plinth.json` (metal_1110: the plinths and tether box move from the S-scroll railing sheet to chamber rock-trim stone).

The full frames were judged as shipped. Batch `G-pst` used three code-blind judges with the standard prompt. Anchors were craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This is a confirming batch, so nothing is extrapolated.

## Verdict: SHIP (all three frames gain, 3/3 each). Does not close.

The arm win maps **7.06** on High. It is a near-bar item under the close-out exception, but it is below 7.5, so there is no Medium to queue yet.

| Frame | Base (mapped) | Arm (mapped) | Gain | Judges preferring arm | Source of the gain |
|---|---|---|---|---|---|
| t-000.00 (F39#28, like-for-like) | 5.49 (5.10, 5.25, 6.13) | 6.23 (5.98, 5.98, 6.72) | **+0.74** | 3/3 | **Stone only** |
| win (F39#21) | 5.25 (5.10, 5.39, 5.25) | **7.06** (6.87, 6.87, 7.45) | **+1.81** | 3/3 | Stone and framing |
| aftermath (F39#21) | 4.95 (4.81, 5.10, 4.95) | 6.42 (6.28, 6.28, 6.72) | **+1.47** | 3/3 | Mostly framing, plus stone |

**t-000.00.** Only the boxes change (0.6% of pixels).
- On base, all three judges called the S-scroll blocks a broken, corrupt or wallpaper texture that reads as a missing material. They named the block in front of Cannonback's forelegs and the one under the crystal.
- The arm's plain stone steps read clean. This is the clean measure of the stone itself.
- The recorded title-card defect was FIXED on both sides (3/3). The card sits at top right, clear of Cannonback.

**win.** 56% of pixels changed, because the end-of-fight camera picks a different orbit.
- On base, Bramblebun is cropped hard against the left edge (a flank with no face), and the patterned box fills the centre.
- The arm shows Bramblebun whole beside the trainer, taller than them and on the creature rule, with the opponent trainer in the distance. Judges called it the best staging in the batch.
- Most of the 1.8 points is framing. The box texture is part of base's loss.

**aftermath.** 60% of pixels changed.
- On base, the patterned box fills the right-centre and hides the defeated creature.
- The arm removes that, but the crystal now crowds the left third, as the GPU lane noted. Bramblebun is seen from behind.
- The gain is mostly framing; the crystal costs the arm part of it.

Raw Bar A (judges a, b, c):
- t0: base 5.0, 5.1, 5.7 → arm 5.6, 5.6, 6.1.
- win: base 5.0, 5.2, 5.1 → arm 6.2, 6.2, 6.6.
- aftermath: base 4.8, 5.0, 4.9 → arm 5.8, 5.8, 6.1.

Fit: linear, slope 1.4711, intercept −2.2554, r 0.956, anchor RMSE 0.408, 6 anchor points, top_anchor_reference 7.53, confirming_batch true, above_top_anchor false throughout. No warnings.
The slope is steep, so these judges spread scores less than the reference judges did, and mapped gains are about 1.5× the raw gains. The raw gains are +0.50 (t0), +1.23 (win) and +1.00 (aftermath).

The recorded victory-HUD defect is PARTIAL on both sides of win and aftermath (3/3). The roster and hotbar are gone; the "Put Bramblebun away" prompt and the vitals still compete with the panel.

## Framing stability
- This run's base win (5.25) and the previous G-ner arm win (6.63, same snap ON) come from different end-of-fight orbits. The F39#21 score swings by about 1.4 with the camera the solver picks.
- Before the Medium confirm, the camera should be stable across runs, or the item can close on a lucky orbit.

## Gap to 7.5 on win (judges' top changes)
- **Crystal:** it reads as a flat, facet-line placeholder (3/3), and in the aftermath it crowds the left third. Scene fix: material or keep it out of the victory cameras. New art: a proper ice-crystal hero asset.
- **Lighting:** a warm brown monotone with no rim or key light on the creature; Bramblebun's face is in shadow (3/3, scene).
- **HUD:** hide the remaining exploration prompt during the payoff (judge a).
