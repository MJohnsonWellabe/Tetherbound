# P2-010 Veilfall — claude-r3 (net-improvement round; own code-blind judge WEAK)

Flag `crag_kitbash_enabled` (`data/config/water_veilfall_crag_kitbash.json`), **OFF** as committed.
Sheet `before-after-Low.jpg`: coordinator's rows 1 (sluice bridge route day) and 4 (cascade close),
Low/Compatibility 1280x720, ordinary camera + HUD, neutral labels.

Changes since r2 (2d7d7a98):
- **Near-entrance restore.** Within `near_restore_m` (60 m, 8 m hysteresis) of the waterfall
  passage, the kitbash hides itself. Every node it hid comes back, and every draw range it changed
  is restored, so the close cascade view renders as with the flag off. Row 4 matches the before:
  the passage is open, the object is visible and there is no dark slab.
  The row-4 frame was captured at c9feddf4; later changes do not render inside the restore radius.
- **Base shards.** Spires within `spire_min_above_ground_m` (40 m) of the ground become
  boulders. The drape's foot now dips into open low ground, and fringe vertices skip the distance
  lift via a vertex-colour weight. The pale striated teeth are gone. A row of small dark teeth
  still shows along the left base at the far camera (judge: condition 2 FAIL).

Own code-blind judge: close view PASS (matches before); far base saw-tooth FAIL; net improvement
yes; overall WEAK. Not posted as CAPTURE-DONE.
