# The Stonewater Reach — focused visual identity evidence

## Outcome

The production Meadows scene now treats **The Stonewater Reach** as the broad
opening sequence its catalogue description promises, rather than a label over
ordinary road and grass:

- the haulage wreck has a full installed wagon silhouette, snapped tongue and
  high Team Tether pennant over the existing spilled cargo;
- Lockwater Overlook has two layered, rippled water surfaces, five large dark
  stone forms across the full sequence, wet-bank reeds, a shallow walkable
  timber viewing deck, and a warm beacon;
- the Springhead has a second visible water basin, layered glint, reed brake,
  source stones and a teal night glow.

The water surfaces carry no collision. Solid collision is restricted to the
off-road wreck, five hero stones and the shallow deck. The existing authored
props, rewards and creature encounters remain in place.

## Production evidence

The seven PNGs cover the wreck, ordinary region approach, exact catalogue
centre, overlook standing view and Springhead, with night repeats at the region
centre and Springhead. `manifest.json` records all seven as complete.

All frames use `res://scenes/world/meadows_playground.tscn`, the ordinary player
and HUD, clear weather, the production-equivalent 70-degree third-person camera,
and no encounter or progress injection. Player processing is paused only to
hold each documented evidence coordinate. Ordinary streamed creatures remain
visible in several frames; inspection found no floating Stonewater geometry,
camera-inside-geometry defect, or missing day/night surface. The partial edge
rock in the Springhead frames is a real source-marker foreground occluder, not
a camera clip through its mesh.

These frames are review evidence, not a claim of independent visual-judge
acceptance.

## Verification

`tests/test_stonewater_reach.gd`: **4 tests, 22 assertions, 0 failures**.

The focused checks cover the three distinct sequence beats, more than 300 m2 of
visible water, approach/catalogue distances, broad sequence span, installed
wreck art, wet-bank density, bounded solid collision and production ordering
after the existing authored props.
