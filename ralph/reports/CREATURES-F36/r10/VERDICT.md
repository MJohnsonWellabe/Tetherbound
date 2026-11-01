# CREATURES-F36 r10: height batch 3 via the scale flag (CPU, three judges)

**Verdict: GPU READY.** Arm `tb/co-f36-9-on` e8da58fe1, built on CO-F36-8, the all-flags tree (control: main a41e1b30). All three species gain at least 0.5.

| Species | Factor | Height | Mapped main | Mapped arm | Gain | "Barely taller than the trainer" (main / arm) |
|---|---|---|---|---|---|---|
| **Mudsnout** | x1.5 | 2.00 -> 3.00 m | 6.22 | **7.02** | **+0.80** | PRESENT x3 / FIXED x3 |
| **Paddlenewt** | x1.8 | 2.15 -> 3.87 m | 6.18 | **6.94** | **+0.76** | PRESENT x3 / FIXED x3 |
| **Riftfrill** | x1.8 | 2.15 -> 3.87 m | 6.13 | **6.90** | **+0.77** | PRESENT x3 / FIXED x3 |

**Fit:** linear, slope 1.27, intercept −1.71, r 0.92, RMSE 0.38. Confirming batch (craft, f36_0_npc:C1). No warnings.

**Notes:**
- Paddlenewt and Riftfrill were round 1 at x1.4 (r9, +0.25 / +0.14). This second try at x1.8 clears the bar, because the body line, not only the crest, now stands above the trainer.
- Mudsnout x1.5 stays under its evolution Tuskroot (3.6 m), so evolution still reads as growth. It is not rideable.
- Flag: `creatures_f36_taller_than_trainer_3` in `data/config/creature_scale_flags.json`, `enabled` false.
- Landing note: like the other scale flags, enabling it grows these colliders.

**What the judges still see:**
- Paddlenewt and Riftfrill: the trainer ruler stands inside the tail, a staging overlap made worse by the length. The faint-end tail fin pokes up as a thin blade.
- Riftfrill: its purple speckle reads procedural.
- Mudsnout: its faint-end hide clumps into a lumpy, rock-like mass.

Sheet `_sheet_r10.jpg`: main on the left, arm on the right; rows are Mudsnout, Paddlenewt, Riftfrill.
