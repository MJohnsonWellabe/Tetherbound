STATUS: parked
BRANCH: tb/item-f38-38  HEAD: the commit that adds this file

- Row: F38#38 P2-096 craft action hint contrast (Meadows). Live CPU 7.33 (VIS-MEADOWS, readable_r4) / GPU 6.86.
- Round `ralph/reports/LANES/LANE-KIT/qj/F38-38-bdd0b7353419-11072141/`: base (main) **7.55** CPU mapped (raw 6.7/6.5/6.7; offset calibration, r 0.94, RMSE 0.67; above the top anchor 7.35, so extrapolated). Candidate `craft_presentation.json quiet_missing_r5` **7.35 (-0.20)**.
- Stop reason: the base reads at 7.5 or above on CPU. The row is a GPU re-judge candidate (High, then Medium); no further CPU rounds.
- Flag left OFF: `quiet_missing_r5`, which is worse. All three judges prefer the filled Missing badges because they read faster at 30%. The branch keeps the flag-off code (`craft_panel.gd` r5_missing_box / r5_selected_row_box, with the config key false). Landing it is optional and harmless OFF; dropping the branch is fine too.
- Flags turned ON: none. Tests flipped: none.
- Judges' remaining asks:
  - Make Craft the strongest element: a teal-accented footer with controller glyph plus label. Today it is weaker than the orange "Missing materials" button.
  - "Prime Orb ... 4 F..." is truncated.
  - The hint glyphs read as keyboard keys.
- Next idea, if the GPU re-judge lands under 7.5: a teal footer emphasis for the Craft hint, keeping the filled badges.
