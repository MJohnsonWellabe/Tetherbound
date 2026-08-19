# OP-WORLD — Pond water, usable doors, complete trails, and regional density contrast

## Goal
Fix several world-completeness issues while preserving a newly approved Meadows composition target.

## Positive art-direction lock
The densely populated band around the pond is owner-approved. Preserve its lush trees/plants and use it as a reference for dense regional pockets.

Do **not** make the whole Meadows equally dense. The biome must intentionally alternate:
- lush, enclosed pockets;
- broad open meadow/field spaces with long sightlines;
- readable paths, creatures, resources and landmarks across open ground.

Think Valheim Meadows / Palworld open-field readability for the open regions, while retaining Tetherbound's own assets/palette. Regional composition is the goal, not one global vegetation density.

## Pond water
The pond currently lacks convincing actual water.

Implement using the project's existing water/terrain conventions if available:
- visible water surface at correct authored elevation/extent;
- shoreline intersection that does not look like a floating plane or empty crater;
- appropriate material/reflection/transparency within Ally performance budget;
- collision/wading/swimming behavior consistent with existing game rules rather than inventing a new traversal mechanic;
- map/world presentation remains coherent.

Preserve the approved dense pond vegetation while adding water.

## Building doors around pond
Fresh report: visually ordinary doors on pond-area buildings are not openable.

General rule:
- accessible Meadows building doors that visually read as usable should respond to interaction and open/close;
- if a door is deliberately locked, communicate that physically/UI-wise and tie it to an actual reason/state;
- decorative fake doors should not masquerade as interactive entrances on otherwise accessible buildings.

Reuse one door interaction/state system; do not script each pond building separately.

## Map/minimap trails
Owner reports movement-up minimap behavior now appears to work. Verify it before touching orientation math.

Remaining defect: not all meaningful visible trails appear on the minimap/full map.

Audit authored route/trail sources and map-bake inputs so a player following a clear world trail can see that route represented consistently. Preserve fog-of-war and discovery; this is about missing terrain/path information, not revealing undiscovered landmarks.

## Density audit
Walk the current Meadows by band and classify regions intentionally as dense pocket / transition / open field. Fix accidental monotony only where needed.

Acceptance examples:
- pond region remains lush and enclosed;
- at least several major stretches open into broad fields with long sightlines;
- open fields are not empty: sparse tree groups, creatures, rocks/resource clusters, trails and distant landmarks still create purpose/readability;
- dense vegetation does not hide every path/encounter;
- performance optimization does not globally thin the approved pond composition.

## Testing / verification
Capture representative pond dense view and at least two open-field views. Verify pond water from multiple camera angles, every ordinary pond-building door, trail representation on minimap/full map, and Ally performance through both dense and open regions.

## Definition of done
The Meadows has deliberate visual rhythm—lush pockets and open fields—while the pond reads as a real place with water, readable buildings behave as expected, and the map represents the trails the player actually follows.