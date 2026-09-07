# MAP-TRAILS — Preserve movement-up; make every meaningful authored trail appear

## Owner evidence — 2026-08-18 evening
Positive: the minimap now **seems to keep the player's movement pointing up**. Treat that part of RG15 as verify-only. Do not rewrite orientation if current main still satisfies the owner.

Open defect: the minimap **does not show all of the trails**.

## Goal
Make the minimap/full-map terrain/path layer represent the meaningful authored Meadows traversal network consistently, while preserving the now-working movement-up minimap behavior and north-up full map.

## Inspect first
- `scripts/ui/minimap.gd`
- `scripts/ui/tab_map.gd`
- `scripts/world/map_baker.gd`
- `autoload/map_state.gd`
- `scripts/world/world_extent.gd`
- `data/config/terrain_playground.json` trail/spine/loops/shortcuts/roads
- any band-split terrain/path config
- road/path mesh/decal rendering system
- map terrain bake cache invalidation/versioning

Identify exactly which path families are missing. The long corridor now has more than one road source: main spine bands, regional loops, shortcuts, crossings and possibly authored local roads. Do not fix by manually drawing a few missing lines on the map UI.

## Authoritative path source
The map baker should consume the same canonical path geometry/data that builds the world, or a deliberate shared derived representation.

Avoid drift such as:
- world renders `trail.loops[]` but map only reads `paths.routes`;
- shortcut exists in terrain but not map;
- band-split path data never gets merged into map source;
- old 512m-square filters silently discard later-band coordinates;
- cached map texture predates the corridor path expansion.

The test should fail if a new authored meaningful trail is added to the world but omitted from the map representation.

## Which routes should appear
Show traversable/intended navigation paths that the player can reasonably recognize on the ground:
- main Meadows spine/trail;
- authored regional loops;
- deliberate shortcuts/haul roads when they are visibly road-like;
- bridge/crossing connections necessary to understand route continuity;
- village/local paths where already part of map grammar.

Do not necessarily render every procedural animal track, tiny decorative dirt patch or secret path before discovery. Follow current fog/discovery rules and existing map design for hidden/optional routes.

## Visual hierarchy
The map should remain readable:
- primary trail slightly stronger than secondary paths if current style supports hierarchy;
- path width remains legible at minimap scale without covering landmarks/fog;
- movement-up rotation applies to the entire baked path layer with terrain/markers;
- full map remains north-up.

Do not add bright GPS lines. These are terrain/navigation marks, not objective arrows.

## Fog/discovery
Preserve current map reveal rules. A path may exist in the baked terrain source but should be masked by fog if the player has not explored the corresponding region, according to existing rules.

Do not reveal the entire corridor merely because path geometry is globally known to the baker.

## Orientation verification
Before editing orientation code, verify current behavior on live main:
- walk forward: movement reads up;
- strafe/backpedal: actual movement remains up while look triangle points independently;
- stationary camera turn: map retains stable last-movement orientation.

If these pass, leave the orientation implementation alone and record that the owner-confirmed RG15 half is now correct.

## Data completeness test
Build a test that derives the set/length/bounds of canonical authored path segments and compares it to what `map_baker` receives.

At minimum catch:
- omitted path family;
- path point outside old square silently clipped;
- empty later band;
- shortcut/loop missing from merge.

Do not use screenshot pixel matching as the only regression.

## Live verification route
Walk/teleport to representative points in:
- early village trail;
- pond band;
- quarry/warrens loop;
- river/crossing band;
- stronghold approach.

At each, the visible ground trail under/near the player should have a corresponding map line once explored.

## Acceptance criteria
1. Current movement-up orientation is verified and preserved if correct.
2. Every meaningful authored Meadows trail family reaches the map baker.
3. Later-band paths are not clipped by obsolete 512m assumptions.
4. Primary/secondary route hierarchy remains readable.
5. Fog-of-war still hides unexplored terrain/routes appropriately.
6. Full map remains north-up.
7. Automated completeness coverage fails when a world path family is omitted.
8. Owner can navigate the corridor using the map without encountering visible ground trails that simply do not exist on it.

## Definition of done
The minimap keeps the directional behavior the owner now likes, and the map itself finally tells the truth about the trail network the player is actually walking.