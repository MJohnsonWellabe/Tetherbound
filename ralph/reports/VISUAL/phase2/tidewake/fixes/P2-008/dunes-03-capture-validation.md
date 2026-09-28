# Dunes-03 capture validation

Source: `8f4cb049d5d7f62b0eaaedd4f8c19c950315cbca`. Native Windows,
Compatibility/OpenGL3, GTX 1060 3GB, fullscreen 1920×1080, seed 2042.
Only the two dune `enabled` flags differed from the committed source during
capture. Both were restored false and the render slot released afterward.
Reproduction commands and frame hashes are in the retained manifests.

- Locations: 4/4 captured, complete.
- Exact required routes: 3/4 captured, incomplete.
- Seven valid pairs retain the original player positions within 0.000573 m
  and camera positions within 0.000563 m. All frames are native 1920×1080.
- No shader or script errors occurred. The route tool exited 1 because the
  Brine Steps walk03 stand failed validation; that failure is not hidden.
- Native vegetation reports 73 terrain-sheltered groves across eleven islands,
  with 426 trees and 339 grove shrubs. These counts are placement evidence,
  not proof of visual quality. Veilfall retains its original vegetation path.

## Invalid original sighting

`water__brine_steps__06__brine_steps_east_beach__walk_03_day` requests stand
XZ `(365.228026, 849.813092)`. The new run observes player position
`(363.246765, -0.700217, 855.006104)`, 5.558126 m away, and saves no image.
The old before-routes run saved the exact same displaced player position.
Dunes-01 drifted 5.394340 m. This is an existing invalid fixture exposed by
stricter validation, not evidence of a dune-induced movement regression.

The resolved ground is -2.645297 m; the observed player height is the configured
human swim waterline. The manifests do not record enough swim/current state
to attribute the exact drift mechanism. The current candidate loop checks
camera distance before selecting a stand, then rejects body drift afterward.
It must validate physical support/swim state and settled displacement inside
the bounded candidate loop, retaining rejected-candidate receipts. A changed
stand requires a fresh matched before/after pair. Do not reuse the old drifting
baseline as an exact comparison, relax the threshold, or freeze production physics.

The optional Salt Crown walk02/03 views were deliberately omitted because their
older before/dunes-01 captures also slipped or respawned. Required Salt Crown
walk01 remains valid. Exact route filtering occurs after seeded generation,
so filtering does not alter the requested walk offsets.

The independent dune review is limited to seven of eight required sightings.
This round cannot close P2-008 or establish full chapter Bars A/B acceptance.
