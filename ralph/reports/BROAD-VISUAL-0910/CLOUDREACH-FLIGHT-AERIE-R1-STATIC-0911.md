# Windscar Flight Aerie R1 static integration — 2026-09-11

Disposition: **expected POLISH; production visual judgment pending.**

## Baseline failure

The current-head catalogue classifies Flight Aerie as RESTAGE/FAIL: an oversized
bird and HUD own most of the frame while the aerie has no readable local silhouette
or activity. The catalogue destination is also the exact flight-lesson centre, and
the nearby two-creature roadside site is only metres from that centre.

## Integrated candidate

- Mount the isolated collision-free presentation under the existing production
  `WindscarFlightAerie` landmark. Two flat blue/gold compass rings and eight rays
  organize the existing five perches as one launch dais.
- Three installed cloth banners add altitude/route colour. Three installed standing
  torches provide visible, grounded landing signals and bounded warm night sources.
- Move only roadside wild site 15 back along the same incoming ravine road, retaining
  its table, count, radius and cadence while clearing the lesson dais.
- Move only the Flight Aerie catalogue row to the final authored ground-route point,
  29.8 m from the centre, with a heading toward the complete composition.

The existing dais, five perches, LaunchStone, lesson mentor, Fly unlock, camp/service
positions, flight path, collision and route geometry are unchanged.

## Production gate

The dedicated R1 harness requires the mounted presentation, valid production ground,
zero wildlife inside the 20 m lesson composition, hidden overlays, frozen player,
verified day/night clocks, four fresh 1280x720 frames, and a fresh output directory.

Promote FAIL to POLISH only if the production frames show a coherent launch compass,
five readable perches, grounded signals and banner rhythm at trainer scale without
turning the floor into a busy target graphic. Reject if rings stand upright, torches
float, props block the flight lesson, or the ordinary route arrival loses the aerie.
No renderer or bake was run for this static integration.

## Static and gameplay validation receipts

- Flight Aerie presentation/integration contract: **4 tests, 37 assertions,
  0 failed**.
- Cloudreach encounters, world data and four-biome catalogue: **24 tests,
  4,613 assertions, 0 failed**.
- Existing production-world Aerie services smoke: **PASS**. It verified the
  camp and flight-trial floor, exercised the real rest interaction, started the
  trial through real input, and confirmed that starting alone does not grant Fly.
- Godot 4.7 `--check-only`: passed for the presentation, focused test, production
  world builder and dedicated capture harness.
- Focused `git diff --check`: passed.

The smoke emitted only the already documented unrelated
`cr_candy_broken_route_good_07` missing-surface warning.
