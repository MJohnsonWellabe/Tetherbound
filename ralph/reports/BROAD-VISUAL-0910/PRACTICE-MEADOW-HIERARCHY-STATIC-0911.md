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

- one 13.3 x 11.5 m continuous ochre packed-earth ribbon follows authored
  terrain around the existing fight centre while leaving its whole surface
  open; the 72-segment ArrayMesh replaces the rejected repeated pale slabs;
- one 4.65 m high, approximately 5.1 m wide installed market stall provides a singular authored timber/
  cloth event silhouette directly behind the board; two installed cloth-only
  pieces hang beneath its outer eaves as board framing rather than returning
  the freestanding ring flags the owner previously rejected;
- one enlarged asymmetric dummy / weapon-rack / shield group sits together on
  the open southeast verge beyond the ring, with measured clearance from the
  berry, named cast, road, boundary, authored furniture and all four shrines;
- one bounded warm canopy lantern carries the hierarchy after dark.

Every new node is visual-only. There is no body, collision shape, area, prompt,
state mutation or encounter hook. Tournament position, round logic, board,
marshal, trainers, paths, shrine sockets, interactions and existing collision
are unchanged.

## Evidence status

R1 was rejected for cottage/tree occlusion. R2 was rejected because the stock
stall stayed subordinate, the ring read as tiny ticks and the equipment was
occluded. R3 proved the widened installed stall and warm night light, but was
rejected because its repeated cream box segments read as slabs and the
equipment was still hidden. R4 replaces those boxes with one low terrain-
conforming packed-earth ribbon and moves the enlarged equipment group to an
open verge. Its four-frame production receipt completed 4/4 at 1280x720 with
no failures on 2026-09-11 04:58:24–04:58:30. Full-resolution inspection accepts
the widened stall, readable warm lamp and continuous packed-earth ribbon as
shippable improvements. The honest R4 grade is **POLISH, not commercial PASS**:
the distant equipment view leaves the dummy small, the rack dark/low and the
shield indistinguishable. That bounded equipment legibility gap continues in
R5; generated R1–R4 capture directories remain local review receipts and are
excluded from the implementation commit.

## Focused validation

- `tests/test_tournament_ground_presentation.gd` pins the real fight centre,
  field-scale ring, installed singular stall hierarchy, varied equipment,
  measured clearance from the berry, Bryn, Halda, the real route, village
  boundary, existing tournament props and all four shrine bodies; it also pins
  the single 72-segment SurfaceTool ribbon, both sampled terrain edges, packed-
  earth texture, low lift, visual-only construction and production mount.
- R4 focused validation: `3 tests, 95 assertions, 0 failed` (exit 0).
- R4 production capture: `manifest.complete=true`, `failures=[]`, 4/4 frames,
  process exit 0.
