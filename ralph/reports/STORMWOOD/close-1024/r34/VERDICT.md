# r34: Ashfoot seated window (CPU, code-blind, 26 Oct)

Arms (the same `ash_in` stand, all four phases: top row calm and building, bottom row break and fading):
- **OFF:** the lane, with the land8 storm finish ON.
- **ON:** `cottage_interior_finish.json storm_finish.seated`.

What `seated` changes:
- **Pane:** it sits behind the lining plane, inside the kit window's own frame, with a 3 cm margin and a 2.5 cm flush trim.
- **Window light:** its colour and energy change by phase, and the pane tint changes with it.
- **Chimney breast:** a stone breast rises from the hearth stack to the ceiling pitch. It hides the exterior chimney base, which made the pale apex shard.
- **Hearth fire:** stronger and wider (2.6 / 6.5 m).

**Result:** mapped **4.77 -> 5.81 (+1.04)**; raw means 5.23 -> 5.83. The fit is r 0.96, slope 1.74, anchor RMSE 0.31, with no warnings.

Defects (three judges):

| Defect | OFF | ON |
|---|---|---|
| Pale shard at the roof apex | PRESENT 3/3 | **FIXED 3/3** |
| Window reads as a glowing slab off the wall | PRESENT 3/3 | PRESENT 2/3, PARTIAL 1/3 |
| Phases barely differ through the window | PRESENT 3/3 | PARTIAL 3/3 |
| The hearth does not read | PRESENT 3/3 | PRESENT 2/3, PARTIAL 1/3 |

Shared asks from all three judges:
- A real storm sky, rain and lightning visible through the glass.
- A visibly lit fire with a warm glow on the floor and walls, for a warm-inside / storm-outside contrast.
- Break up the large stretched plank walls with Stormwood moss, copper and glass.

Anchors:
- craft after/before;
- f36_0_npc C1A/C1B;
- f36_0_gap C1A/C1B.

Files: `batch.json`, `key.json`, `spec.json`, `mapped.json`, `sets.md`, `_sheet_r34.jpg` (off left, on right).
