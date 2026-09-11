# Broken Skyroad Arch R6 — production disposition

## Disposition: POLISH — retain

The former pair of blockout slabs is replaced by one installed 26 x 19 m castle-kit
gateway with unequal masonry shoulders, fallen crown stones, and a non-front-on
profile. Both accepted day/night pairs now show a readable skyroad threshold at
trainer scale and preserve the open route.

This is a material structural improvement, but not a strict commercial pass. The
gateway's broad upper face remains visually plain, the small wind-fracture treatment
does not read from the accepted east shelf, and the night facade loses most surface
separation. Retain the structure and continue with bounded material/weathering work
rather than increasing its already sufficient scale.

## Production evidence

- Scene: `res://scenes/world/cloudreach_cliffs.tscn`
- Accepted output: four 1280x720 frames, two east-shelf compositions at day/night
- Manifest: complete, four of four records, zero failures
- Overlays hidden; player frozen on the production-valid shelf; fixed 62-degree
  evidence camera; no production landmark or route transforms changed for capture
- Focused/world/catalogue validation before capture: 24 tests, 1,472 assertions,
  zero failures. Catalogue recheck after correcting the arrival: 11 tests, 1,065
  assertions, zero failures.

## Rejected evidence

- R1 exposed HUD interference, player movement/death, and an invalid east frame.
- R2 rejected camera shoulders with no production ground.
- R3 exposed a stale 800px height assertion after standardizing to 720px.
- R4 and R5 proved the authored west catalogue position sits inside/under crown
  geometry. Those frames are diagnostic only and must not be used for acceptance.
- R6 moves the catalogue destination to the verified east shelf at `(365, 1925)`
  and is the only retained production set.
