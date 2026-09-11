# Stronghold Approach vertical-standards R3 — static candidate — 2026-09-11

## Finding

The retained R2 hierarchy is a material improvement but remains `POLISH`. Its
strongest production frame is the final Hall reveal. In that frame, the two
new `hallward_overlook` standards read as bright pink-and-white directional
arrows instead of a faction threshold, competing with the Hall they are meant
to frame.

This is a source-mesh silhouette problem, not a scatter or placement problem.
`assets/buildings/quaternius_castle/Banner.obj` measures only 0.704 x 0.659 m
and is a horizontal pennant. Scaling it to 3.5 makes a larger arrow. The
installed shared prop-family `Banner_1.gltf` has a 2.39 m vertical span and a
named `MI_Banner` cloth material.

## Candidate

- Replace only `HallwardStandardWest` and `HallwardStandardEast` with
  `Banner_1`; their world positions and -14-degree road alignment do not move.
- Use scale 1.55 and lift 2.4 m, derived from the source mesh's measured
  -1.549 m below-origin bound, to seat a roughly 3.7 m vertical standard on
  each verge.
- Retint only `MI_Banner` to the reserved Team Tether oxblood `#7a2430`.
- Leave the Hall, road, terrain, vegetation aperture, wildlife, gatherables,
  torches, fences and generated scatter untouched.

The focused contract pins the installed model, material key, scale/lift range,
and the existing centreline-clearance checks. This is intentionally a static
candidate: no production renderer or scatter bake was run in this lane. The
existing `tools/capture_stronghold_approach_identity.gd` R2 harness already
contains the required paired final-reveal view and needs no change for the
next authorized render.

Static validation: both edited JSON and glTF sources parse; `git diff --check`
is clean for the candidate paths; the focused Godot run passed **5 tests / 110
assertions / 0 failed**. The first test invocation exposed and corrected one
GDScript inference error before this green run; no retry-only runtime behavior
is being counted as evidence. The band-content merge suite separately passed
**6 tests / 1,435 assertions / 0 failed**.

## File scope and overlap

- `data/config/bands/band5_stronghold_approach/props.json`
- `tests/test_stronghold_approach_visual_identity.gd`
- this report

There is no path overlap with active Trail Camp, Old Quarry, Highfield or
Ironwood work. No generated scatter file is changed.
