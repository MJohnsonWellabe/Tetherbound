# Windscar beacon grounding outcrops — 2026-09-10 continuation

## Result

Three medium, terrain-fitted stone outcrops now frame the retained Windscar
beacon. They replace an uninterrupted flat-green landmark footprint with a
readable medium-scale base composition while preserving the open arch, road,
pickups, collision, camera, and progression.

This is a bounded Cloudreach landmark improvement, not a whole-biome or
commercial-visual pass. It uses the three installed `Rock_Medium_*` assets and
the beacon foundation's existing masonry material. No art was generated or
purchased, and no grass, far-turf, terrain-material, crown-geology, or footprint
experiment was revived.

## Evidence-led disposition

The first candidate placed seven small round path stones between the canonical
stand and the arch. Its focused contract passed, but the exact production frame
showed most stones hidden beneath the grass; the visible fragments read as
incidental clutter. That candidate was fully withdrawn and left no source diff.

The materially different retained candidate uses three 3.9–5.8 m masses outside
the passage corridor. In the matched stand-05 view, the left and right outcrops
establish foreground/midground layers around the arch feet and visibly interrupt
the empty green field. They read as a deliberate ruin/rock threshold rather than
scattered pebbles. The central eight-metre opening and distant horizon remain
clear.

Matched production-camera evidence:

- baseline:
  `.artifacts/visual-audit-0910/cloudreach-windscar-clear-candidate01/cloudreach__windscar_ravine__05__windscar_beacon__day.png`
- retained:
  `.artifacts/broad-visual-0910/cloudreach-windscar-outcrops01/cloudreach__windscar_ravine__05__windscar_beacon__day.png`
- same catalogue stand, 1280x800, day preset, production CameraRig and HUD
- final catalogue run completed **2/2 frames, exit 0**; stand 06 is unchanged
  contextual coverage.

The surrounding grass remains over-chromatic and the distant plateau composition
remains sparse. This pass improves the landmark footprint but does not close those
larger Cloudreach gaps.

## Verification

`test_cloudreach_windscar_beacon_site.gd` passed **3 tests, 32 assertions, 0
failed**. It establishes:

- all three installed rock scenes resolve;
- every outcrop's visible half-width remains more than 5 m outside the route
  centreline;
- all three holders match their sampled terrain seat after the authored burial;
- no outcrop silently adds collision;
- the existing two arch frames, four independently grounded feet, ten matching
  solid colliders, 8.0 m passage width, 5.8747616 m minimum passage height, and
  6.584853 m minimum pickup-to-ground-solid clearance remain unchanged.

The production catalogue emitted only the pre-existing
`cr_candy_broken_route_good_07` no-surface warning documented by the earlier
Windscar pass.
