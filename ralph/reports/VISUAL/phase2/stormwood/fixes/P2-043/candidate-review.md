# P2-043 existing scorched-scar candidate review

The existing `scorched_scars` presentation remains disabled. Independent
read-only reviewer `stormwood_dialogue_review` found no actionable correctness
issues in the enabled branch of `stormwood_glass_field.gd`, its config,
identity tests and runtime grass-clear integration.

Ground sampling agrees with the field's translated and rotated coordinates.
Grass-clear markers register before world construction next yields, and the
existing footprint refresh uses their world positions. The branch changes
visual meshes/materials and ground-cover suppression without adding collision,
interaction, progression or encounter changes. Its authored scar extents stay
outside the 14 m road corridor. Geometry uses local seeded randomness; the
disabled path retains the legacy clusters.

The focused identity suite passed 3 tests and 45 assertions with no failures
in `.tmp/stormwood-phase2/glass-field-tests.log`. Its third test explicitly
builds the enabled candidate through `force_scorched_scars`; the first two
check construction and route/encounter invariants. No test was rerun for this
read-only review.

The flat test terrain cannot establish slope conformity, shader clearance or
visual readability. Native before/after review must establish those. The
current original-sighting baseline exposes a slab edge, grass penetration and
a white crossing element; the candidate has no Phase 2 visual acceptance.
P2-043 remains open.
