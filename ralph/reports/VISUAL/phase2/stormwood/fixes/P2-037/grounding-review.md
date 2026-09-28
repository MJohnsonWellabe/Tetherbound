# P2-037 visual bark grounding candidate

The native phase views show a continuous gap beneath parts of Stormheart's
lower bark shell. A read-only audit at the production tree base
(-100, 112.0591, 5470) compared all 82 outer bottom vertices with the production
Stormwood heightfield: 51 vertices exceeded a 0.1 m gap, with a maximum gap
of 4.8808 m. Other portions were buried by up to 4.2752 m. The shell's bottom
was authored at one flat height despite the terrain below it varying.

The default-off `stormheart_presentation.json` candidate extends only the
height-zero visual bark vertices downward to terrain minus 0.5 m. It preserves
their X/Z coordinates, upper bands and southern split. Existing decks, ascent,
rails, collision, tree placement and departure/entry routes are unchanged.
Simulation-only builds return before loading the presentation config.

The in-memory enabled audit found the maximum bottom gap reduced to
-0.49998 m (embedded), with identical X/Z positions and identical 12 m band
vertices. This is vertex/heightfield evidence, not rendered clearance proof.
The retained `grounding-audit.json` contains all measurements. On-disk flag
remains false.

Existing `test_stormheart_presentation.gd`, `test_stormheart_wayfinding.gd`
and `test_water_return_connection.gd` passed: 9 tests, 187 assertions.
The script parses. Independent read-only reviewer `stormwood_dialogue_review`
found no actionable defects: disabled parity, production terrain coordinates,
downward-only skirt changes and unchanged physical geometry were confirmed.

P2-037 remains open. This candidate addresses grounding only. Full landmark
identity, trunk/crown forms, material quality and the broad horizontal band
still require native original-sighting, approach and 400 m / 100 m reviews.
No visual acceptance or regional Bars A/B pass is claimed.
