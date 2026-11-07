STATUS: land
BRANCH: tb/item-f38-36  HEAD: 4015a4a5412ee57b73a4f9551a8c9b6e35ad1562 (the gain commit; this READY commit follows it)

Lane LANE-MS (Meadows). Row F38#36 (P2-078 dialogue speaker occlusion), board 5.20 GPU / 6.26 NEAR6-MS CPU.

- **Round** `ralph/reports/LANES/LANE-MS/qj/F38-36-0cc46557b370-11072314/`: **CPU mapped 6.98 -> 7.89 (+0.91)**. All three code-blind judges preferred it and moved the defect PRESENT -> PARTIAL. Calibration r 0.93, RMSE 0.41; the candidate maps above the top anchor (7.35), in a confirming batch.
- **Cause:** OWNER-0912 placed Corin (`village_npcs.json` trader) at Old Mill Crossing (-150, 4232), inside band3 wild cluster 3037's 8 m disc (four galecrest, centre (-152, 4235)). The galecrests stood 4–8 m round him, and their spread wings filled his dialogue view (probe: the capture manifest's `nearby_creature_records_160m`).
- **Change (ON):** `data/config/bands/band3_the_river_lock/spawns.json` order 3037 `centre` z 4235 -> 4258, with `_why_f38_36`.
  - The new centre is about 26 m from Corin and 55 m from the crossing deck (z 4203), further from the deck than before, so the STRANDED-P3 deck clearance still holds.
  - Same species, count, radius and role.
- **Checks:**
  - A Meadows boot shows no spawn or spacing warning.
  - Ran every `tests/test_*.gd` that reads spawns: 297 tests, 0 failed.
  - The 4235 points in tests are road waypoints, not this cluster.
- **Not judged:** the `captain_field` dialogue frame is missing on both sides ("no supported production-camera stand among 28 candidates"), a capture-stand issue; it was also absent from the base.
- **Judges' remaining asks:**
  - Corin stands in deep tree shade, with his dark robe low against the canopy.
  - A creature's leg or body is cropped at the right edge of both frames.
  - Keep creatures out of the dialogue framing volume.
- **Next idea:** a dialogue key light on the speaker, or the Captain frame's stand fix.
