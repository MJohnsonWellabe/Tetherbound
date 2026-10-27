# r35: Ashfoot firelit hut (CPU, code-blind, 26 Oct)

**Arms:** the same `ash_in` stand, all four phases.
- **OFF:** r34 `seated` ON.
- **ON:** `seated` plus `cottage_interior_finish.json storm_finish.firelit`:
  - **Hearth:** the camp flame sculpt burns in the firebox (0.35 scale), the fire light flickers, and a soft warm pool lies on the floor.
  - **Walls:** dark timber posts at stud spacing, wall plates and a tie beam frame the lining.
  - **Lantern:** the copper lantern by the window is lit.

**Result:** mapped **4.36 -> 5.12 (+0.76)**; raw means 4.53 -> 5.13. Fit: r 0.87, slope 1.26, anchor RMSE 0.49, no warnings. This batch scores the shared r34 arm lower than r34's batch did (different anchors), so read the difference, not the level.

**Defects (three judges):**

| Defect | OFF | ON |
|---|---|---|
| Hearth has no visible fire | PRESENT 2/3, PARTIAL 1/3 | PARTIAL 3/3 |
| Walls are huge flat stretched planks | PRESENT 2/3, PARTIAL 1/3 | PRESENT 2/3, PARTIAL 1/3 |
| Storm window reads as a glowing panel | PRESENT 3/3 | PRESENT 3/3 |
| No storm visible through the window | PRESENT 3/3 | PRESENT 3/3 |

**Shared asks (all three judges):**
- **Window:** a storm sky through the window (purple cloud, rain, phase-varying lightning) instead of a lit panel.
- **Hearth:** a flame that reads past the trainer.
- **Walls:** properly scaled plank texture with moss and copper touches.

Anchors: f36_0_npc C5A/C5B, f36_0_gap C6A/C6B, craft after/before. Files: `batch.json`, `key.json`, `spec.json`, `mapped.json`, `sets.md`, `_sheet_r35.jpg` (off left, on right).
