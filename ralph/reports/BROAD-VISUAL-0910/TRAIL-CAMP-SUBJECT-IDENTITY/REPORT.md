# Trail Camp foreground-subject pass — 2026-09-11

## Outcome

**POLISH — improved, not PASS.** The five-body Long Field herd no longer fills
the northbound arrival, and the fire/tent/furniture are now the foreground
subject in the close day/night pair. Arrival closure remains open: `01`/`02`
show no camp at all through the terrain/trees, and `03`/`04` are still led by
the two full-scale companions rather than the rest stop.

## Authored correction

- Preserved all creature counts, species, encounter tables, radii, and wander
  behaviour.
- Moved the five-creature Long Field ring from directly on the `(332,900)`
  arrival eye to `(370,1005)`, beyond the camp. It remains ordinary road ecology
  and has 4.3m full-disc clearance from its nearest neighbouring spawn ring.
- Moved the single Bramblebun and Trailpup companions behind the tent/fire plane
  at `(338,940)` and `(350,940)`. Both remain in firelight, outside the creature
  bed, and laterally clear of the route-to-fire sightline.
- Did not move the fire, tent, seats, functional rest offer, craft point, or
  creature bed; traversal and camp gameplay remain unchanged.

## Production evidence

Dedicated script: `tools/capture_trail_camp_subject_identity.gd`. It loads the
production `meadows_playground.tscn` with ordinary Terrain3D, scatter, props,
encounters, and player; pins clear day/night looks; hides only the HUD for art
review; and uses a 70-degree, 5.2m third-person camera. No progress or encounter
state is injected. `manifest.json` records **complete: true**, six frames, and
zero failures.

- `01-northbound-arrival-day.png` / `02-northbound-arrival-night.png`: the former
  five-creature obstruction is gone, but terrain and trunks still hide the camp
  completely. The traveller is the only authored subject.
- `03-camp-standing-day.png` / `04-camp-standing-night.png`: fire, supplies, and
  tent are visible, but the companion silhouettes still carry more visual mass
  than the furniture.
- `05-fire-tent-day.png` / `06-fire-tent-night.png`: strongest proof of the
  improvement. Fire, tent, bench, crate, barrel, and bed form a readable rest
  stop with companions behind/flanking rather than blocking it.

## Validation

- `test_trail_camp_composition.gd`: **2 tests, 18 assertions, 0 failed**.
- `test_band_content.gd` and `test_spawns_data.gd`: **31 tests, 3,392
  assertions, 0 failed**.
- Combined: **33 tests, 3,410 assertions, 0 failed**.

## Ranked remaining fixes

1. Re-site or author a served clearing/threshold so the actual northbound road
   exposes the smoke/fire/tent before the player is already inside the camp.
2. Move the two companions another plane behind the camp or reduce their
   presentation scale through the shared creature-display system; their current
   world-scale silhouettes still outweigh the tent in `03`/`04`.
3. Increase the tent/camp-bed material contrast against grass and fix the bed's
   near-white placeholder-like read in `05`/`06`.
4. Apply the shared Meadows night fill/exposure correction; the local fire reads,
   but the road and most camp furniture collapse into black outside its pool.

## Incidental defects

- The creature bed at frame right reads as a bright untextured rectangular form,
  especially in `05`; it is functional content and was not removed to hide the
  defect.
- Trees form a dense wall around a landmark whose map description promises a
  waypoint found by walking to it. That obstruction is the principal remaining
  named-location gap, not a capture-only defect.
