# SPINE-LAYOUT — Default route goes around the Warrens; dungeon is a shortcut

## Goal
Repair the Meadows main-spine routing near the Burrow Warrens so the ordinary route **goes around the dungeon**, while traversing through the Warrens provides a separate, noticeably faster optional shortcut.

The current route must never guide a player directly into a dungeon wall just because two authored spine points happen to connect across its footprint.

## Backlog intent — locked
- The current spine's largest reported gap (~173m) runs into/through the Burrow Warrens geometry.
- **Default progression route:** walk around the Warrens without entering it.
- **Optional reward:** going through the Warrens can reconnect to the spine farther ahead and be faster.
- Routing the safe/default path is independently shippable; the shortcut is additive.

## Existing geography to reuse
- Meadows is authored corridor geography in `data/config/terrain_playground.json`, not procedural runtime path generation.
- Warrens sit at the current `burrow_warrens.json` site and are a compact five-chamber dungeon with real walls/passages/collision.
- Preserve the dungeon's current purpose and local-frame geometry. Do not move or redesign it merely to make a straight trail line easier.

## Required implementation
### 1. Diagnose current route
Inspect the authoritative route/spine/trail data on current `main`. Plot or capture the segment approaching, crossing and leaving the Warrens footprint. Identify exactly which points/segments make the road run into geometry.

### 2. Author the default bypass
Adjust/add route control points so the main trail:
- approaches the Warrens clearly enough that the player can notice/find the dungeon;
- bends around its exterior on walkable, sensible terrain;
- never intersects chamber walls, hidden underground collision, entrance dressing, or impassable slope;
- reconnects cleanly to the downstream spine;
- reads as an intentionally authored road/trail, not a mathematically bent avoidance arc.

The bypass should not be absurdly long. The dungeon shortcut needs room to be meaningfully faster without making players who skip it feel punished.

### 3. Add/verify the optional shortcut
Create a distinct route through the actual dungeon entrance and exit/reconnection path only if the current Warrens architecture supports it honestly. The shortcut must require entering/traversing the Warrens, not simply clipping across its roof or walking through a wall.

If the existing dungeon has only one exterior mouth, implement the smallest coherent additional exterior connection needed by the approved shortcut concept, using existing cave geometry language. Do not turn the Warrens into a maze.

The shortcut may be dangerous because the dungeon already contains encounters; do not add an arbitrary key/teleport simply to make the route shorter.

## Navigation integration
- main road/spine visual language must make the safe bypass understandable;
- optional entrance should remain discoverable;
- minimap/full-map baking should represent actual traversable paths if path rendering exists;
- RG17's pylon navigation spine must not contradict the road by visually pointing through a solid wall. Bend/sight pylons consistently where this region overlaps.

## Preserve
- Warrens content, guardian, reward and dungeon progression;
- authored corridor world bounds;
- route progression before/after this region;
- no procedural runtime terrain generation;
- no invisible blockers.

## Acceptance criteria
1. Following the default main spine from either side never collides with or dead-ends at the Warrens building.
2. The default route goes around the Warrens on normal walkable terrain.
3. The Warrens remain visible/discoverable from the route.
4. A separate route through the Warrens exists and reconnects farther ahead.
5. The through-Warrens path is measurably faster than the outside bypass under comparable movement.
6. Neither path uses clipping, roof-walking, teleporting, or invisible walls.
7. Road/map/pylon guidance does not contradict the actual paths.

## Testing / verification
Add a traversal smoke that walks the default route through this region without entering dungeon collision, plus a traversal for the shortcut from entrance to downstream reconnection. Measure path lengths/travel times in a deterministic harness and assert the shortcut is shorter using a tunable generous threshold rather than frame-perfect timing. Capture overhead/approach views and run visual review because path siting is visual-affecting.

## Definition of done
A first-time player can simply follow the road **around** the Burrow Warrens, while an exploring player who chooses to go **through** the dungeon earns a real shortcut and rejoins the same progression spine ahead.