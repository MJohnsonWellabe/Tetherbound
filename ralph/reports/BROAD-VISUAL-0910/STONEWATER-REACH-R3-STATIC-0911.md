# The Stonewater Reach R3 — revised static candidate

## R2 rejection applied

R2 is held, not accepted. Its wet-bank meshes rendered as large flat grey polygons;
the widened water remained cyan/plastic and let grass pierce the surface; and the HUD
dominated the evidence. The entire wet-bank surface system, widened radii, and related
tests have been removed. The original retained water geometry/material values are
restored exactly.

The asymmetric relocation of the three existing overlook boulders remains. It is an
independent scene correction: the prior near-equal row directly occluded Lockwater
from the real south-west approach, while the revised west/east/crown arrangement opens
the water axis and gives the rocks a deliberate scale hierarchy. No water, terrain,
scatter, reward, encounter, or collision rule depends on their old positions.

## Production-water seam investigation

The shipped Meadows water is not a reusable colour material alone. `water.gd` builds
`shaders/water.gdshader` together with a 512 x 512 height texture over the exact carved
water region. The shader derives colour, foam and shoreline alpha from real water
depth. Stonewater's decorative meshes instead follow the terrain at a fixed 0.13 m
offset and have no matching carve or baked height region. Copying the pond/river
material would sample the wrong world rectangle; calling its private material builder
would add another full height bake and still leave grass intersecting a ground-hugging
surface. `water_surface.gd` likewise uses Water-biome baked terrain and is not valid
for Meadows coordinates.

Therefore R3 does not fake reuse by copying shader colours or introduce a second water
pipeline. A true shared-water conversion needs authored terrain/channel depth plus the
associated terrain and vegetation bake, which is outside this bounded no-bake lane.

## Evidence hardening

- Capture output moves to `STONEWATER-REACH-R3`; rejected R2 evidence is preserved.
- `PlaygroundHUD`, `CombatHUD`, `DialoguePanel`, `NamePrompt`, and `StarterPicker` are
  hidden and processing-disabled before any frame.
- The production player is process-disabled and its `CharacterBody3D.velocity` is
  zeroed before and after every teleport.
- Eight route-oriented views remain, covering wreck, south-west arrival, open
  overlook, connected run, spring arrival, and matched night views.

## Exact owned diff

- `scripts/world/stonewater_reach.gd`: asymmetric boulder relocation only relative to
  accepted HEAD.
- `tests/test_stonewater_reach.gd`: boulder hierarchy/open-axis and harness freeze/HUD
  contracts.
- `tools/capture_stonewater_reach_identity.gd`: R3 views plus evidence hardening.
- this report.

No generated scatter, vegetation/props config, production water source, or active
Band 2/4/5 path is touched. No production capture, bake, or commit was run here.

## Acceptance still required

Run focused tests and script checks, then capture R3 under the guarded Windows route.
Retain only if the open boulder composition exposes the existing water and reads more
intentional without creating isolated edge rocks or route collisions. This bounded
candidate does not claim to close Stonewater's full water-course presentation gap.

## Static validation receipt

- `test_stonewater_reach.gd`: 6 tests, 34 assertions, 0 failures.
- `--check-only`: production composer, focused test, and R3 capture harness each
  exited 0.
- `git diff --check`: clean across the exact owned paths.
