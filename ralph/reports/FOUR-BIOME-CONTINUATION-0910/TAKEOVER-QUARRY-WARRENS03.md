# Takeover checkpoint 03 — quarry route and earned Warrens clear

Date: 2026-09-10
Base source: `a45e28801` plus the bounded changes described here
Branch: `codex/four-biome-continuation-0910`
Status: **retained post-bridge quarry/Warrens segment green; fresh whole-campaign proof remains open**

## Reproduction and cause

The retained earned checkpoint reproduced the quarry stop after four legitimate
rootstone harvests. The fifth authored node at `(393, 1802)` is outside
`OldQuarry/Foundation_0`; it is not embedded and its terrain footing is valid.
The direct line from the preceding node crosses the rotated foundation's low wall.
The ordinary stick navigator alternated detours around the compact ruin for 24.8
seconds / 80.28 metres and returned to approximately `(395, 1804.5)`.

Contact telemetry identified the actual foundation collision and distinguished it
from nearby station crates, rocks and tools. A collision-normal wall-following
candidate was tested and withdrawn: it could inherit the wrong prop normal or
continue around a second foundation corner. No shared navigator change from that
candidate was retained.

## Bounded correction

The earned Warrens helper now uses two ordinary-controller clearance points around
Foundation_0's west return before approaching the unchanged fifth harvest node:
`(394.1, 1809.0)` and `(392.85, 1806.82)`. No authored node, collider, world mesh,
resource amount, party rule or gameplay movement code changed.

The helper's preliminary centre-distance check was also corrected from 1.5 m to
2.2 m. Production `HarvestNode` configures its real prompt at 2.4 m; the old helper
threshold could pin against station dressing at 2.12 m and refuse to let the real
prompt/arbiter verification run. The harvest still must win that live prompt and
produce the exact configured inventory delta.

## Runtime evidence

The exact failing fifth leg first passed in isolation through real CharacterBody
collision and controller input:

`.artifacts/four-biome-continuation-0910/runs/quarry-foundation-west-waypoints/`

The full retained post-bridge replay then passed from the original read-only save:

`.artifacts/four-biome-continuation-0910/runs/quarry-warrens-full-west-waypoints-r2/`

It recorded:

- seven unique authored quarry nodes, each yielding exactly 2 rootstone, carrying
  the inventory from 0 to 14;
- two organic wild victories on the onward route;
- the real Warrens guardian admission and a 17-hit victory;
- the same five party instance IDs before and after the fight, with all five
  surviving and receiving observed XP;
- exact rewards from 140 to 230 coin, 14 to 19 rootstone, 0 to 2 greater orbs,
  7 to 8 revives and 0 to 1 hide vest;
- `warrens_cleared`, a physical exit to `(-350.9432, 4.611609, 2603.94)`, and
  terminal `passed=true` / exit 0.

This is a copied retained-checkpoint continuation and is labelled as such. It closes
the diagnosed quarry/Warrens segment blocker; it is not represented as a fresh
opening-to-Warrens or complete-campaign pass.

## Focused validation

- `test_meadows_earned_warrens_segment.gd`: 8 tests / 85 assertions, green after
  the final source assertion;
- exact-leg native replay: exit 0;
- retained post-bridge through-Warrens native replay: exit 0;
- no shared stick-navigator candidate code retained.

## Next gate

Proceed to multiplayer departure synchronization with protocol-order evidence and
a clean two-process smoke, while the larger fresh earned campaign and visual tails
remain open.
