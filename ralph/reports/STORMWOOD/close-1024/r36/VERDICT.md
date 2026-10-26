# r36: Ashfoot storm view (CPU, code-blind, 26 Oct)

Arms: the same `ash_in` stand, all four phases.
- **OFF:** r35, with `seated` and `firelit` ON.
- **ON:** adds `cottage_interior_finish.json storm_finish.storm_view`:
  - A storm card 3 m outside the east window faces the room, with back faces culled so it never draws from outside.
  - It shows a storm sky over a dark treeline, with cloud, sky and rain set per phase and the surge flash lighting the cloud.
  - The pane is lighter.
  - That one window's kit glass (`MI_WindowGlass`) is made clear. It draws as an opaque pale sheet, and that sheet was the "glowing panel" in r34/r35; the first r36 capture, made without this fix, showed no change.

Result: mapped **5.50 -> 6.21 (+0.71)**; raw means 5.27 -> 5.80. Fit r 0.86, slope 1.33, anchor RMSE 0.70 (under the 0.75 flag), no warnings.

Defects (three judges):

| Defect | OFF | ON |
|---|---|---|
| Hearth has no visible fire | PARTIAL 3/3 | PARTIAL 3/3 |
| Walls are huge flat stretched planks | PRESENT 3/3 | PRESENT 3/3 |
| Storm window reads as a glowing panel | PRESENT 3/3 | **PARTIAL 3/3** |
| No storm visible through the window | PRESENT 3/3 | **PARTIAL 3/3** |

Shared asks:
- Lightning and rain that read through the window, with the room lighting up at the break.
- Cut the bright frame bloom at the window.
- Wall and ceiling planks at real scale (narrow boards), with moss and copper.
- A flame that reads past the trainer.

Anchors: craft after/before, f36_0_gap C6A/C6B, p2_094_r4 X_before/Y_after. Files: `batch.json`, `key.json`, `spec.json`, `mapped.json`, `sets.md`, `_sheet_r36.jpg` (off left, on right).
