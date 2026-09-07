# POND-WATER — Give the Meadows pond actual water

## Owner reproduction
The pond area is one of the strongest-looking vegetation pockets in the current Meadows, but **the pond itself has no actual water**.

Positive art-direction constraint: preserve the dense trees/plants around this pond. Do not thin the approved lush pocket while fixing the water.

## Goal
Make the pond read and behave as a real body of water using the project's established Meadows water/river systems and art family.

The result should have:
- visible water surface occupying the authored basin;
- correct shoreline/terrain intersection;
- water material/lighting consistent with existing river/water treatment;
- appropriate player/creature traversal semantics;
- no obvious z-fighting, floating plane edges or empty dry-bowl gaps;
- map/world presentation that still matches the pond landmark.

## Inspect first
- existing river/water scripts and materials
- `terrain_playground.json` pond/landmark/basin data
- terrain heightfield/carve used for the pond
- any `Water` scene/material currently used by the river
- map landmark data for Pond
- collision/swimming/wading code if it exists
- current pond vegetation clearings/footprints
- screenshots/capture locations around the pond

Reuse the same water family as the rest of Meadows. Do not create a visually unrelated special shader just for this pond.

## Basin and shoreline
Measure the authored pond basin and choose the water elevation from actual terrain data rather than eyeballing a plane.

Requirements:
- surface covers the intended wet basin without flooding paths/buildings;
- shoreline is irregular/natural enough to fit the authored terrain;
- no visible rectangle corners beyond the basin;
- water does not hover above shore or leave a uniform air gap below it;
- preserve the dense vegetation composition, but keep trees/large props from obviously growing out of deep water unless intentionally authored.

If the basin geometry itself is wrong, fix the smallest terrain/config issue required; do not rebuild the entire band.

## Water behavior
Use current project rules for water depth and movement. Inspect before inventing swimming.

If Meadows currently supports wading but not swimming, the pond should follow that. If deep water is intentionally hazardous/non-traversable, communicate it through depth/shore and reuse the existing recovery/volume system. Do not add a new swimming mechanic under a water-art task.

Creatures/NPCs should not spawn idle underwater unless their existing species behavior permits it.

## Visual quality
At handheld scale, the pond should clearly read as water from:
- trail approach;
- shoreline;
- nearby elevated view.

Use existing palette/art guidance: stylized realism, readable natural color, not a neon cyan sheet.

Avoid:
- opaque flat blue card;
- overly mirror-like surface;
- strong emission/glow;
- hard rectangular boundary;
- missing depth cue that makes it look painted on terrain.

## Performance
The pond should not add an expensive unique reflection/render pipeline that breaks the Ally budget. Reuse the established water material/render path and measure if changing shader features.

## Tests / verification
- world builds with pond water in correct authored location;
- player approaches shoreline without falling through terrain;
- water surface remains at stable elevation;
- map/landmark still aligns;
- no relevant trail is flooded;
- save/load has no duplicate water nodes;
- representative day, dusk and night frames show water legibly.

Because visual presentation is the core ask, capture before/after pond frames and run the normal visual review.

## Acceptance criteria
1. Pond contains a real rendered water surface.
2. Surface fits the basin and shoreline without obvious rectangular artifacts.
3. Existing Meadows water/traversal rules apply consistently.
4. Dense pond-band vegetation remains visually strong.
5. No nearby trail/building is unintentionally flooded.
6. Water reads correctly day and night on ROG-scale captures.
7. Performance remains within current world budget.

## Definition of done
The pond area keeps the lush composition the owner liked, but the landmark finally reads as an actual pond rather than a landscaped depression.