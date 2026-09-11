# The Ridgeline Watch R2 — static candidate

## Evidence finding

The latest three production frames establish a clear scaffold and signal mast, but the
strict `POLISH` verdict is supported. At the ordinary approach the tower is a repeated
two-bay brace cage with no secondary mass. At the close stand there is no access/service
story, usable deck dressing, weathered shelter, or visible lamp; the only night cue is
an unexplained pool from an invisible OmniLight. The full frame otherwise has healthy
grass, mixed low plants, trees, rocks, trainer activity and campfire, so this lane does
not alter vegetation or terrain.

## Bounded correction

- Add a southwest service lean-to tied into the existing scaffold: three unequal,
  subtly varied canvas strips, timber edge beams and two outer posts create one low
  asymmetric silhouette against the repeated vertical tower.
- Ground an installed wooden supply crate and barrel beneath it. These reuse the one
  established prop family and make the posting read occupied without adding rewards,
  interactions, collision, or invented story.
- Replace the invisible deck light with the installed `Lantern_Wall` cage, a visible
  emissive source and a bounded 8 m warm pool. The prior 18 m light washed much of the
  hill without explaining its source.
- Preserve the signal mast, oxblood reservation, installed scaffold, camp/rest cluster,
  patrol trainer, route and four-support collision.

## Evidence hardening

The six-view R2 harness pairs day/night southwest arrivals, canonical watch views and
service-shelter views. It hides all exploration/combat/modal overlays, disables their
processing, disables the production player, and zeros locomotion velocity at every
stand. Rendered acceptance remains pending and must be judged independently.

## Exact owned paths

- `scripts/world/ridgeline_watch.gd`
- `tests/test_ridgeline_watch.gd`
- `tools/capture_ridgeline_watch_identity.gd`
- this report

No shared configuration, generated scatter, vegetation, terrain, imports, existing
dirty evidence, renderer, bake, or commit is touched.

## Acceptance still required

Focused tests and script parsing must pass. Then guarded Windows production evidence
must show the low shelter as a coherent attached service wing, not a floating flat
awning; installed supplies must remain grounded; the tower must retain its skyline;
the lantern must visibly account for the night pool; and no camp/trainer/route
clearance may regress. Reject if any of those fail.

## Static validation receipt

- `test_ridgeline_watch.gd`: 7 tests, 42 assertions, 0 failures.
- `--check-only`: composer, focused tests and R2 capture harness each exit 0.
- `git diff --check`: clean across the four owned paths.
