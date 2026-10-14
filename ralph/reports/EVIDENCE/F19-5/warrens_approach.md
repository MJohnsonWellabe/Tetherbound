# CARD:M2 blocker: Warrens approach is reachable; the helper's staging pose was wrong (routes, Tue 13 Oct 2026, CT)
Verdict: product geometry is fine. A built ramp climbs from the ground (~4.4 m) to the entrance floor (9.19 m) along the mouth axis.
Only the earned helper's staging data was wrong. Fixed in tests/helpers/meadows_earned_warrens_segment.gd and tools/earned_saves/warrens_route.gd.

Measured (tools/earned_saves/warrens_apron_probe.gd, read-only; warrens_approach/apron_probe.txt):
- The Warrens floor is raised: floor_y 5.39 over origin y 3.80, so the entrance marker is at y 9.19.
- The product ramp therefore runs `_apron_run_m()` = max(8, 5.39*3+6) = 22.17 m from the mouth's outer face.
- The helper used the config's `site.apron_run_m` = 8. Its staging point, 8 m back from the entrance at (-349.9, 2602.9), is mid-ramp.
  There the deck is at 6.93 m over a 4.72 m heightfield, with sheer sides.
  A walker coming from the undertrail meets that side wall: the "bank" where the seed-15 runs stopped.
- (The (-355.6, 2608.6) at 9.19 m quoted in CARD-M2 is the entrance marker itself.)

Fix:
1. `staging_run()`: stage on the ground 1.5 m past the live ramp foot (the product's run, less the entrance's 3 m offset from the outer face): 20.67 m back, ground 4.37 m.
   The committed relay profile's post-Warrens pose (-339.3, 2592.3) sits on this same spot.
2. After staging (flat 5.5 m tolerance), step onto the mouth axis at the ramp foot (1.0 m) before walking up.
   Walk r1 without this: the diagonal leg crossed the ramp side and was entombed beside it at y 5.0.
3. The off-the-bank step-out uses the staging run + 6 m.

Proof (tools/earned_saves/warrens_approach_walk.gd, commit a6cf41e2c, 1x clock, no TB_WORLD_SEED):
- Input: the disclosed generated `relay` profile (L15 five, Meadows), loaded through the production title.
- DISCLOSED shortcut: teleport to the South Bridge far bank, Band2 road[0] (0, 1360). The bridge/camp pieces are proven separately. The quarry harvest is skipped.
- Then the helper's own walker by ordinary stick input: Band2 road → quarry join → station bypass → undertrail with the spike bypass → staging (-336.6, 3.68, 2597.3) → axis (-340.2, 4.28, 2594.5) → up the ramp.
- **PASS r2:** ended 1.21 m from the entrance (-354.9, 8.48, 2607.9) in 417 s wall. No recovery, no failures. No wild engaged on this walk; the helper's fight path stays live.
- Logs: warrens_approach/walk_r2.txt, walk_r1_fail.txt.

Site test: test_meadows_earned_warrens_segment (13 tests, 1307 assertions, 0 failed).
Next: Fights re-runs CARD:M2 seed 15 on this head.
