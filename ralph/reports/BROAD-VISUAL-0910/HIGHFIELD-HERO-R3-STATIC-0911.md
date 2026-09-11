# The Highfield hero composition R3 — static clearing candidate, 2026-09-11

## Outcome

**Static candidate only; visual verdict withheld.** R2's production receipt rejected
the oversized wheat pennants and identified the new consolidated-scatter tree wall as
the real blocker. R3 removes both pennants, retains only the compact existing-asset
stock-camp grouping, and authors one bounded canopy/trunk sightline lens. No generated
scatter file was edited and no bake or capture was run while the Quarry renderer owned
the production slot.

## R2 disposition

- Removed both `HighfieldGatePennant*` props and their tests. The single visible panel
  read as a pale directional arrow; it did not strengthen the rural drove-gate identity.
- Retained the 1.12 m wagon adjustment and compact fire/feed/tent grouping. R2 frame
  `05` proves these installed props form a more legible occupied group without closing
  the gate lane or moving an encounter, pickup, gatherable, interaction, or real camp.
- Highfield remains POLISH until a fresh post-bake production set proves the full-frame
  composition.

## One canopy/trunk lens

Band 4 clearing order `4005` is one circle at `(407, 5877)`, radius `25m`. It clears
only blocking scatter layers between the two herd reads and the gate/camp:

| Relationship | Exact measure | Preservation result |
|---|---:|---|
| Existing camp clearing `4004`, `(420,5891) r12` | centre distance `19.105m`; radial overlap `17.895m` | One continuous sightline, not two disconnected holes |
| Ordinary herd centre `(377.5,5855.3)` | edge gap `11.622m` | Herd habitat is outside the lens |
| Bull centre `(425,5844)` | edge gap `12.590m` | Bull encounter is outside the lens |
| Lens world bounds | `x 382..432`, `z 5852..5902` | Surrounding pasture woodland remains beyond all four rims |
| Other Band 4 clearings | nearest is order `4001`, over `138m` edge-to-edge | No unrelated clearing merges into Highfield |

No `footprints` entry is added. `grass`, `drygrass`, `flowers`, and `path_stones` all
explicitly carry `cleared_by_clearings: false` in the production layer config, while
trees, rocks, bushes, and saplings use the default `true`. The lens therefore preserves
walkable pasture cover and dirt-road punctuation while removing the canopy/trunk wall.

## Capture receipt hardening

R2 manifest frame `01` recorded `31.76m` camera-to-player distance instead of roughly
`6m`: the player left the teleported stand while the fixed camera remained. The harness
now freezes player process/physics after loading, rejects non-finite ground samples,
and makes every frame fail if the player moves more than `0.25m` from the authored stand
or departs the expected `0.35m` ground clearance by more than `0.1m`. The manifest adds
actual player XZ, displacement, and ground clearance per frame. No silent R2 rerun was
performed.

## Validation state

- JSON parses successfully and the working diff passes `git diff --check`.
- `test_highfield_hero_composition.gd` adds a bounded-footprint, exact-overlap,
  encounter-preservation, no-local-footprint, ground-cover-preservation, and
  blocking-layer-effect contract.
- Godot tests are intentionally queued until the active Quarry production renderer
  releases; this static lane did not start a competing engine process.
- A canonical scatter bake is required before any R3 visual claim. The authoring file
  alone is not evidence that the served scatter changed.
