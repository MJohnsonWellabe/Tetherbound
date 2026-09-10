# First Shore welcome-beacon continuation

Date: 2026-09-10

Branch: `codex/four-biome-continuation-0910`

Parent: `f4455e324`

## Decision

Retain the authored First Shore welcome site. The production `arrival_beacon`
landmark existed only as a data/catalogue coordinate, so its named review frame
looked across an empty bank. The retained site realizes that contract as a
route-adjacent open arch with installed banners, lanterns and a crown signal.
It supplies a clear midground destination in the unchanged production camera
without removing the visible shoreline creature or changing terrain and route
composition.

The enlarged signal/light revision is withdrawn. Its matched night frame did
not show a meaningful gain over the bounded original practical, so the retained
site keeps the smaller 1.45 signal scale, 1.65 light energy and 11 m range.

## Spatial and gameplay contract

- Production viewpoint remains `[35.707, 98.104]`.
- Site centre is `[16.0, 98.0]`, 19.71 m ahead in the production composition.
- The conservative 3.2 m visible footprint retains 9.73 m beyond the nearer
  edge of the existing four-metre route.
- Only two fitted arch piers collide; their measured throat is 2.0 m.
- The landmark adds no progression, encounter, pickup, terrain, route or camera
  mutation.

## Visual evidence

- Retained baseline:
  `shots/catalogue/water/broad-clump-candidate03/water__first_shore__01__first_shore_welcome_beacon__day.png`
- Retained candidate day/night and unchanged Horizon Stones context:
  `.artifacts/visual-audit-0910/water-first-shore-welcome-candidate01/`
- Rejected stronger-light comparison:
  `.artifacts/visual-audit-0910/water-first-shore-welcome-candidate02/`
- Native catalogue run:
  `.artifacts/broad-visual-0910/runs/water-first-shore-welcome-capture01/result.json`
  (`4/4`, exit 0, no engine errors).

This closes one missing authored landmark and one sparse First Shore camera
composition. It does not claim Water-wide commercial visual acceptance: the
rigid ground-cover silhouette, bare angular banks, distant shoreline treatment
and broader inhabited-place density remain open.

## Verification

- Focused site/adjacent-Water presentation suite:
  `.artifacts/broad-visual-0910/runs/water-first-shore-welcome-unit-final/result.json`
  — 6 tests, 133 assertions, 0 failed, exit 0, no engine errors.
- Production Water opening:
  `.artifacts/broad-visual-0910/runs/water-first-shore-welcome-opening-smoke/result.json`
  — exit 0, no engine errors; real arrival, Pell dialogue and 64.487 m physical
  swimming completed with no post-arrival fixture writes.
