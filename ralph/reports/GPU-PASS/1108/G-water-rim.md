# G-water-rim: Tidewake character rim off and soft, plus the F39#21 Nerissa occlusion-fade pair

Frames: `tb/gpu-frames-1108` 0953b1ac, High.
- **Live:** main d9d79ff93.
- **rimOff:** live plus `water_character_rim_off.json` (`enabled: false`).
- **rimSoft:** live plus `water_character_rim_soft.json` (energy 0.3, power 3.5, fill_energy 0).

The two arms share one live set. Cause note: `ralph/reports/LANES/ITEM-NPC-ALBEDO/CAUSE-TIDEWAKE.md`.

Batch `G-rim`:
- One batch with three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so the top anchor is 7.35 and this is a **confirming batch**.
- Fit: linear, slope 1.5557, intercept −2.6487, r 0.868, anchor RMSE 0.573.
- Warnings: F39#26 rimSoft meets the bar only above the top anchor (this is the confirming batch). Some candidates lie more than 0.5 outside the anchors' measured range.

Ship rule: mapped gain > 0 and ≥2/3 judges prefer the arm.

## Result: both rim arms win on every row, 3/3 judges each

| Row | Item | Live | rimOff | Gain | Prefer | rimSoft | Gain | Prefer |
|---|---|---|---|---|---|---|---|---|
| F39#18 | dialogue camera framing | 5.54 | 7.20 | **+1.66** | 3/3 | **7.36** | **+1.87** | 3/3 |
| F39#26 | dialogue foreground obstruction | 5.34 / 5.39 | 7.46 | **+2.12** | 3/3 | **7.52** | **+2.13** | 3/3 |
| F39#27 | backlit named characters (the row the rim was made for) | 5.34 | 6.43 | **+1.09** | 3/3 | 6.43 | **+1.09** | 3/3 |
| F39#29 | speaker visibility | 5.08 / 5.03 | 6.53 | **+1.45** | 3/3 | 6.53 | **+1.50** | 3/3 |

Live has two values where the shuffled live side appears separately in each comparison.

Raw scores (j1, j2, j3):

| Row | Live | rimOff | rimSoft |
|---|---|---|---|
| F39#18 | 5.2, 5.6, 5.0 | 6.2, 6.4, 6.4 | 6.2, 6.5, 6.6 |
| F39#26 | 5.2, 5.2, 5.0 | 6.3, 6.6, 6.6 | 6.5, 6.6, 6.5 |
| F39#27 | 5.4, 5.0, 5.0 | 5.9, 5.7, 5.9 | 6.0, 5.7, 5.8 |
| F39#29 | 5.0, 4.9, 5.0 | 5.9, 5.6, 6.2 | 5.8, 5.6, 6.3 |

**The cause is confirmed.** All three judges independently named the live side's speakers as "washed-out, semi-transparent ghosts", and both arms render them solid. The rim off does **not** bring back F39#27's "backlit near-black" complaint: F39#27 gains +1.09 on both arms. Judges call the rim-off figures "solid but dark and small" in wide post views, which is a staging note, not a regression.

**Recommendation: ship rimSoft** (`data/config/water_character_rim.json` energy 0.8 → 0.3, power 2.2 → 3.5, fill_energy 0.14 → 0).
- It is equal to or better than rimOff on every row: +0.16 on F39#18, +0.06 on F39#26, level on #27 and #29.
- It keeps a narrow edge for the backlit dune views.

## Bar status after rimSoft (High, mapped)

- **F39#26: 7.52, which is ≥7.5** (confirming batch). Capture Medium with rimSoft to close.
- **F39#18: 7.36.** Under the close-out exception this is a near-bar item. Judges' next fix is a tighter, head-and-shoulders dialogue frame offset clear of the player.
- **F39#29: 6.53.** Nerissa is still small and behind the player's head in the dark channel chamber (3/3).
- **F39#27: 6.43.** The figures are small on barren dunes.

Live here maps lower (5.0–5.5) than the same live frames did in G-med-occl (6.5–6.85). The strong ghost-vs-solid contrast in this batch pulled the live sides down. The gains are within-batch and 3/3, so they hold either way. The absolute arm scores should be re-read in the Medium confirmation batch.

## F39#21 Nerissa win: occlusion-fade-off pair (one frame, semantic match)

| Row | Live | Arm | Gain | Prefer | Ship |
|---|---|---|---|---|---|
| F39#21 | 3.78 (raw 4.6, 4.3, 3.5) | 3.94 (raw 4.9, 4.0, 3.8) | +0.16 | 2/3 | rule met, but **not meaningful** |

The fight is not deterministic, and the two frames have different camera positions. Both frames are dominated by the victory camera sitting inside a large translucent pale-cyan crystal slab (3/3, on both sides). The 0.16 is within camera-position noise.

The real F39#21 defects, from all three judges:
- The camera clips into crystal geometry.
- The reward card text is duplicated: "Captain Nerissa's reward: Captain Nerissa's reward: 150 Coin…".
- The captain is ghosted (judge b side B), which is the same rim, since Nerissa is a Tidewake trainer.

The rimSoft change should also help the captain's look in F39#21.

## Other recurring notes (same batch, anchors excluded)
- **Red flag:** a saturated orange-red crab creature behind Iona (F39#26 frame 2) and on a dune crest in F39#27. Judges flag it as close to the reserved red, though they read it as natural crustacean colour.
