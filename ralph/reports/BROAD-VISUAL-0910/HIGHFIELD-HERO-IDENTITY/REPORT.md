# The Highfield hero-composition pass — 2026-09-11

## Outcome

**POLISH — materially improved, not PASS.** The named pasture now has a much
clearer herd and working-stock identity, and the gate-side wagon/fire gives the
empty hill an occupied endpoint. The requested single hero read is not closed:
no frame resolves herd, gate, and the full camp strongly at once, the tent still
dissolves into the pasture, and large random trees divide the arrival view.

## Authored change

- Added `highfield_drove_camp_hero` beside the drove gate's east wing: warm
  fire, tent, bench, fodder, water, kit, and firewood. It is scenery, not a
  duplicate rest/craft trigger; the functional `highfield_stockcamp` remains at
  its measured route-side site roughly 280m away.
- Moved the existing drover wagon from the canopy-hidden north side of the
  fence into the open south-east pasture and raised it to 1.25 scale. This is
  the readable daytime bridge between the gate and camp in `05`.
- Added one 12m local canopy/boulder clearing. Shared clearing rules retain
  grass and flowers. The current scatter fingerprint does not invalidate from
  this file alone, so the pass relies on the verified open pasture rather than
  claiming an unserved rebake.
- Preserved the ordinary Meadowhart herd at `(377.5, 5855.3)`, herd bull at
  `(425, 5844)`, the gate's central opening, and the real stock-camp rest point.
- Every new camp prop is 37m+ from the Band 4 spine and 35m+ from both herd
  centres; the moved wagon also remains outside the opening and encounter rings.

## Production evidence

Dedicated script: `tools/capture_highfield_hero_identity.gd`. It loads the
production `meadows_playground.tscn` with ordinary Terrain3D, scatter, props,
encounters, and player; pins clear day/night looks; hides only the HUD for art
review; and uses a 70-degree, 5.2m third-person camera. No progress or encounter
state is injected. `manifest.json` records **complete: true**, six frames, and
zero failures.

- `01-herd-gate-camp-day.png`: strongest broad arrival; riding herd and several
  grazing animals occupy the foreground/mid-ground, while fence and wagon sit
  on the destination hill. The central tree still splits the composition and
  the camp remains too small.
- `02-herd-gate-camp-night.png`: herd silhouettes and warm fire survive, but
  terrain value separation is weak.
- `03-east-herd-gate-day.png` / `04-east-herd-gate-night.png`: close bull read
  against the drove road; gate/camp identity is secondary and partly divided by
  trees.
- `05-gate-camp-day.png`: clearest improvement receipt. The relocated wagon is
  now an obvious working-stock silhouette beside the fence, but no herd shares
  this frame and the tent is not legible.
- `06-gate-camp-night.png`: wagon/fence mass and warm occupation light read;
  the foreground remains too dark for a commercial PASS.

## Validation

- `test_highfield_hero_composition.gd`: **4 tests, 67 assertions, 0 failed**.
- Existing `test_highfield_visual_identity.gd`: **1 test, 6 assertions, 0
  failed**.
- `test_band_content.gd`: **6 tests, 1,431 assertions, 0 failed**.
- Combined: **11 tests, 1,504 assertions, 0 failed**.

## Ranked remaining fixes

1. Give the open drove gate a taller authored threshold/silhouette and compose
   the tent/wagon directly against it; the low rails cannot carry the hill at
   arrival distance.
2. Clear or deliberately reframe the two large trees splitting the herd from
   the destination. Do this through a served scatter path, not a config-only
   clearing assumption.
3. Increase tent material/value separation from green pasture; scaling alone
   will not solve the current blend.
4. Apply the shared Meadows night fill/exposure fix. The local fire is readable,
   but cannot repair black terrain and foliage across the full frame.

## Incidental defects

- `b4_candy_wind_ridge_crest` still logs that it sits inside solid scatter with
  no clear point within 8m. This is outside the Highfield composition files.
- Distant pale creatures at frame right lose surface/material definition in
  `01`/`03`; creature material work remains a separate shared lane.
