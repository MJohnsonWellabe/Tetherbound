# Practice Meadow / tournament-ground hierarchy — static pass 2026-09-11

## Baseline finding

The current production village-tournament frames (`shots/locations/01-village-
tournament-{day,night}.png`, written 2026-09-11 02:31) show the current-head
failure directly: two members of the four-shrine Meadows home circle dominate
the foreground as matching pale crescent arches. The bracket board, marshal,
benches and supply pile are present, but do not establish a stronger training-
ground hierarchy.

The duplicate silhouettes are not duplicate tournament props. They are the
owner-requested relic circle built by `playground_world.gd::_build_realm_handoff`
from one approved hero mesh. Moving, deleting or disguising those sockets would
regress the realm-heart contract and is outside this location pass.

## Authored correction

`tournament_ground_presentation.gd` adds a separate visual-only identity layer:

- a 12.5 m ochre lists ring follows the existing fight centre while leaving its
  whole surface open;
- one 4.7 m high, broad timber marshal canopy provides a singular event
  silhouette behind Halda, using a village-green pitched awning rather than
  another arch or the flags the owner previously rejected;
- one asymmetric dummy / weapon-rack / shield group sits beyond the ring and
  makes the field read as ground used for training between tournament rounds;
- one bounded warm canopy lantern carries the hierarchy after dark.

Every new node is visual-only. There is no body, collision shape, area, prompt,
state mutation or encounter hook. Tournament position, round logic, board,
marshal, trainers, paths, shrine sockets, interactions and existing collision
are unchanged.

## Evidence status

Static implementation only while another lane owns the production renderer.
Dedicated current-head day/night production capture remains queued. The honest
grade cannot advance beyond **candidate POLISH** until the complete walk-up and
fight-floor compositions are inspected at full resolution.

## Focused validation

- `tests/test_tournament_ground_presentation.gd` pins the real fight centre,
  field-scale ring, singular canopy hierarchy, installed varied equipment,
  off-floor placement, visual-only construction and production mount: **3
  tests, 27 assertions, 0 failures**.
