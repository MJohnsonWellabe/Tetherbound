# G-occlusion-fade-off-wide, plus the F39#18/#26 rimSoft confirm (High and Medium)

Frames: `tb/gpu-frames-1108`.
- **Wide pairs:** 02536cf15. Live is main d9d79ff93; the arm is live plus `COORDINATOR/overlays/occlusion_fade_off.json` (`camera.json` `occlusion_fade.enabled false`), High. camfx `fight_fade` stays ON in the arm.
- **Confirm sets:** `G-confirm-f39-26-high` (6426126b) and `G-confirm-f39-26-medium` (f7e53f00), main plus `water_character_rim_soft.json`, judged one-sided.

Batch `G-wide`:
- One batch with three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so the top anchor is 7.35 and this is a **confirming batch**.
- Fit: linear, slope 1.1273, intercept 0.0824, r 0.823, anchor RMSE 0.656. No warnings.

## Occlusion fade off, outside Tidewake: no gain anywhere, one loss

| Row | Item | Live | Arm | Gain | Judges preferring arm | Ship |
|---|---|---|---|---|---|---|
| F38#35 | Meadows human post poses | 6.24 | 6.24 | 0.00 | 0/3 (3 ties) | no |
| F39#4 | Tidewake shiny finish (no-change control) | 7.33 | 7.37 | +0.04 | 1/3 (2 ties) | no |
| F40#12 | Cloudreach speaker visibility | 7.41 | 7.45 | +0.04 | 1/3 (2 ties) | no |
| F41#7 | Stormwood trainer identity | 6.58 | 6.58 | 0.00 | 0/3 (3 ties) | no |
| F41#11 | Stormwood portrait identity | 7.11 | 7.11 | 0.00 | 0/3 (3 ties) | no |
| F41#15 | Stormwood foreground obstruction (Marrow) | 5.46 | 5.27 | **−0.19** | **0/3: all three prefer live** | no |
| F41#20 | Stormwood dialogue reuse | 7.15 | 7.15 | 0.00 | 0/3 (3 ties) | no |

Raw scores (j1, j2, j3), live → arm, for the only row that moved:
- F41#15: 4.8, 4.6, 4.9 → 4.6, 4.4, 4.8.

Every other row has identical or ±0.1 raw scores.

**Answer to the coordinator's question:** yes, turning `occlusion_fade` off loses a dialogue gain outside Tidewake.
- **F41#15** drops 0.19, and all three judges prefer live. On the arm's side, judges a and c name a creature head intruding at the lower left of the Marrow frame and a pale pole at the left edge; judge c marks the obstruction defect PARTIAL on that side.
- Nothing else moves; F39#4, the control, holds level.

With the earlier Tidewake result (F39#26 +0.34, F39#29 +0.39, F39#18 −0.10), the net case for switching it off is weak. Those Tidewake gains were measured while the ghosting rim was live; the rim is now explained and fixed by rimSoft.

**Recommendation: keep `camera.json` `occlusion_fade` ON.** If the Tidewake framing gains matter, re-test occlusion fade off on Tidewake only, on top of rimSoft.

## F39#18 and F39#26 with rimSoft: one-sided, High and Medium

| Row | Preset | Raw (j1, j2, j3) | Mapped judges | **Mapped** | above_top_anchor | Earlier High (G-c26) | ≥7.5 |
|---|---|---|---|---|---|---|---|
| F39#18 | High | 6.4, 6.4, 6.4 | 7.30, 7.30, 7.30 | **7.30** | no | 7.07 | no |
| F39#18 | Medium | 6.5, 6.4, 6.5 | 7.41, 7.30, 7.41 | **7.37** | yes | — | no |
| F39#26 | High | 6.6, 6.5, 6.3 | 7.52, 7.41, 7.18 | **7.37** | yes | 6.88 | no |
| F39#26 | Medium | 6.6, 6.5, 6.3 | 7.52, 7.41, 7.18 | **7.37** | yes | — | no |

Neither row closes. Both sit at about 7.3–7.4 on both presets, which makes them near-bar items under the close-out exception. The two High passes (G-c26 and this batch) average 7.19 for F39#18 and 7.13 for F39#26.

Remaining defects named by the judges:

**F39#18:**
- Irva in frame 3 is still small and distant.
- The player's shoulder and backpack take a large share of the frame.
- Bex and Irva share one model and one portrait (3/3).

**F39#26:**
- The Adair portrait shows Iona's glasses-wearing face (judge c; judges a and b in G-c26).
- A large untextured grey-green curved slab sits behind Iona, with the creature pasted against it (2/3).

**Next changes, in order:**
1. A tighter dialogue shot, the same ask as in G-c26.
2. The Adair portrait mapping.
3. Texturing or removing the Iona-frame slab.

## Other notes from the same batch
- **Captain Marrow's head blows out to glowing white in Stormwood (3/3: F41#15 and the F41#7 frame 3).** The cause trail is in ITEM-NPC-ALBEDO/CAUSE.md. The remaining suspect is the metallic-0 fix on the captain bodies.
- **Stormwood rain renders as thick, opaque white bars (3/3).**
- **The body text repeats the speaker name** ("Elder Maud: Elder Maud: …", and in Nerissa's reward card) (2/3).
