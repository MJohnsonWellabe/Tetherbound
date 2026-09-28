# P2-022 crown arcade candidate

The inspected Sky Aviary board supplies composition and identity direction:
`docs/reference/boards-2026-09-06/cloudreach-sky-aviary-stronghold-board.png`.
Its open stone arches below the dome and warm architectural lanterns informed
four broad bays over the existing drum piers. No reference pixels were copied.
The mesh is original procedural geometry reusing the already reviewed aviary
arch-stone helper. Materials reuse the existing aviary masonry; the wall lantern
is the installed Quaternius Fantasy Props asset already used by the aviary.
No new acquired asset, generated texture, purchase, or external service is used.

`crown_arcade.enabled` defaults to false. The previously rejected tower candidate
also remains false. The added bays start above the original drum and introduce
no floor or collision. The four local lantern lights are shadowless. Existing
routes, gameplay state, camera, encounters, and dome dimensions are unchanged.

The focused architecture suite passes 4 tests / 129 assertions, including a
candidate-enabled check for no collision objects/shapes and geometry above the
existing required route headroom, plus disabled-scene equivalence. The new
script passes GDScript check-only. These checks do not establish visual quality,
performance, complete traversal, or regional acceptance. Native paired day/night
capture and independent visual judgement remain required.
