# Cloudreach Route Ecology R1 — production verdict, 2026-09-11

Status: **ACCEPT as a bounded shared improvement**. Cloudreach's separate
biome-wide environment grade remains **FAIL**.

## Validation

The focused suite passed 3 tests with the route plan included in a wider result
of 19 tests / 283 assertions / 0 failures. It proves deterministic bounded
coverage of all ten grounded routes, exclusion of the Fly-only link, visible
path clearance, six-batch MultiMesh ownership, and absence of collision or
gameplay-state authoring.

The first production boot exposed an invalid `global_transform` query on six
unmounted imported scenes. The implementation now accumulates their local
hierarchy transforms without attaching the temporary roots. Its focused
regression passed. A clean production Cloudreach boot and capture then completed
without that engine error:

- Realm Gate day/night:
  `shots/locations/cloudreach-route-ecology-r3-gate/manifest.json` (2/2)
- Three Bells, Windscar Beacon, Cliffhold, Old Wind Observatory, and Summit
  Eyrie day/night:
  `shots/locations/cloudreach-route-ecology-r4-routes/manifest.json` (10/10)

An earlier R2 attempt terminated during pre-existing geological-face construction
with an out-of-memory crash before this presentation layer mounted. Its
incomplete zero-frame manifest is rejected evidence and is not retained.

## Independent image-only verdict

A non-author accepted the candidate as a real shared improvement. Visible cover
materially changes the route read around Three Bells, Windscar, Cliffhold,
Observatory, and Summit edges; those views no longer all present as undressed
green planes. No still-image regression was severe enough to reject it.

The owner's sparse-grass/terrain complaint is **partially and meaningfully
addressed, not closed**. Realm Gate remains a nearly bare wedge, Summit's court
is largely bare, and some areas replace sparseness with rectangular, striped, or
waist-high clumps. Smooth slabs, repeated ground texture, banded cliff walls,
white oval cloud cards, weak rock/shrub ecology, and night-value problems remain.
The evidence is not a matched A/B and does not establish collision or performance
from pixels; those limits prevent a broader grade claim.

## Grade effect

This pass changes shared production art but does not promote the Cloudreach
environment. It remains **FAIL** until natural density falloff and clustering,
route-edge transition cleanup, terrain/cliff shaping and material breakup,
cloud replacement, and night value repair are verified across the biome.
