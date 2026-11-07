STATUS: parked
BRANCH: tb/item-f38-26  HEAD: 966168f8 (READY and verdict only, no game change)

Depends on tb/item-capture-fixes (4e3f0cc0): the stand now joins the grass clearing as a settled creature does.

- Row: F38#26 P2-020 creature ground contact (Meadows). Live 5.78 CPU (old stand: clearing never engaged) / GPU 5.43.
- Fixed-stand re-score: CPU mapped **6.53** (raw 6.0/5.6/5.6), round `ralph/reports/LANES/LANE-KIT/qj/F38-26-fb9fd6ec5b3f-11071828/` (r 0.80, RMSE 0.69, confirming). Sides: shipped clearing ON (base) vs `creature_grass_clear.json enabled:false` (the old stand's look). Judged identical (+0.00); crops show the clearing does uncover the hare's feet, but too small at sheet scale to move a score.
- Arm `creature_grass_clear.json p2_020_candidate` (radius x2.1) captured on the fixed stand: 0.06% of pixels differ from base, so no judge round spent. Stays OFF (flat).
- Flags turned ON: none. Tests flipped: none.
- Judges' remaining asks: (1) the fainted Mosshell (frame 3) renders translucent/ghost-like and does not read as grounded (3/3 judges); (2) creatures read about trainer height and small in frame behind the trainer; (3) value separation from the shaded tree band and a rim light; (4) near-camera grass dominates the lower half.
- Next idea: find why the fainted Mosshell is translucent on this stand (likely a faint fade/dissolve held at the 0.9 seek; creature presentation, this lane's files), then re-judge. Scale/camera asks are other lanes' files.
