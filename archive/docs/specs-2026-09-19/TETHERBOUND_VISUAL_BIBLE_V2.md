# TETHERBOUND — VISUAL BIBLE v2

**Status:** Owner-directed visual target  
**Date:** 2026-09-01  
**Scope:** Current Meadows only. This document does not authorize Biome 2 implementation.

## 1. Target

Tetherbound's Meadows should aim for the **visual impression** of the approved website/world promotional direction while remaining a real-time playable Godot environment.

The target is not pixel-for-pixel concept-art reproduction. The target is:

> **A lush, colorful, stylized, highly readable creature-adventure world that feels close to Palworld/Fortnite in environmental finish, density, composition, and life.**

The website art establishes the desired feeling:
- lush rather than sparse
- layered rather than flat
- colorful rather than washed out
- populated rather than empty
- composed rather than procedurally scattered
- strong foreground / mid-ground / background separation
- landmarks integrated into the land
- creatures and people making the world feel alive
- clear, appealing skies and atmospheric depth

The current game's foundations are compatible with this goal. The main gap is production finish, not Godot itself.

## 2. What we are not targeting

Do not attempt to make the game:
- photorealistic
- AAA cinematic realism
- ultra-dense dark fantasy concept art
- Valheim Ashlands-level intensity in every frame
- dependent on expensive effects that damage ROG Ally performance
- a pile of unrelated marketplace assets
- a static screenshot that only looks good from one camera

Do not redesign established Meadows geography merely to imitate concept art.

## 3. Reference priority

Use visual references in this order:

1. Current owner-approved website/world boards as the emotional/compositional target.
2. `docs/reference/tetherbound-meadows-keyart.png` for Tetherbound-specific identity.
3. Palworld references already recorded in `docs/specs/ENVIRONMENT_AND_UI_BIBLE.md` for density, layering, terrain breakup, and composition.
4. Current in-game Meadows screenshots as the baseline to improve, not the target ceiling.

Never copy another game's assets or exact compositions.

## 4. Seven visual pillars

### A. Lush ground coverage

A gameplay frame should rarely expose large uniform terrain unless it is intentionally a path, rock surface, water edge, farmed ground, or authored clearing.

Visible ground should usually layer:
- terrain material
- grass
- shorter groundcover
- weeds
- flowers
- occasional pebbles
- roots
- leaf litter where appropriate
- subtle color variation

Desired read: a real meadow surface made from overlapping visual layers, not green terrain with scattered grass models.

Use LOD, MultiMesh/scatter, density bands, culling, and optimized shaders rather than brute force.

### B. Vegetation in layers and clusters

Nature must not look uniformly scattered.

Use:
1. groundcover
2. flowers/weeds
3. bushes
4. saplings
5. medium trees
6. hero trees
7. distant tree masses / haze

Use authored ecological patterns:
- groves
- stream vegetation
- forest edges
- lone hero trees
- meadow clearings
- wet-ground bands
- rocky breaks

Avoid even spacing and obvious procedural noise.

### C. Strong mid-ground composition

Important gameplay sightlines need structure between player and horizon.

Use combinations of:
- tree lines
- rock clusters
- creek bends
- fences
- small structures
- farms/gardens
- ruins
- creature groups
- NPC activity
- ridges
- bridges
- paths
- landmarks

Avoid: `player → empty grass → sky`.

Prefer: `player → ground detail → path/creatures/props → grove/river/buildings → landmark/hills → atmospheric horizon`.

### D. Places must look lived in

Buildings alone do not create a village.

Village examples:
- connecting paths
- fences
- gardens
- carts
- barrels
- crates
- tools
- stacked firewood
- laundry
- signs
- benches
- cooking
- flowers
- NPCs moving or interacting
- creatures present where appropriate

Camp examples:
- clearly readable fire focal point
- seating arranged around it
- bedroll/tent
- supplies
- irregular authored placement
- travelers/NPCs

Team Tether locations:
- patrols/grunts
- machinery
- crates/tools
- cables
- scorch/damage
- banners/faction identity
- signs of active operation

Do not line props up like inventory items. Clusters should communicate purpose.

### E. Materials must survive close and medium range

The world cannot reach target quality if rocks look uniformly painted, stone has no macro variation, vines read as flat cards, dirt is one flat texture, architecture is uniformly clean, or foliage has no depth.

Prioritize:
- readable roughness
- normal variation
- macro color variation
- sensible texture scale
- edge/weathering variation
- moss/dirt blending
- better terrain transitions

Maintain:
- one coherent nature family
- one Meadows civilian architecture family
- one normal prop family
- distinct Team Tether hero language

### F. Sky, light, and atmosphere are first-class assets

Every outdoor frame contains sky.

Target:
- crisp stylized cloud forms
- no smeared airbrush clouds
- believable sun treatment
- soft atmospheric depth
- distance haze
- directional lighting with readable form
- attractive shadows
- strong day/golden-hour presentation

Foreground should have higher contrast; distance should progressively soften.

Do not hide weak scenery in excessive fog.

### G. The world must feel alive

Important views should contain appropriate life:
- roaming creatures
- creature groups
- NPC walkers
- trainers
- villagers
- Team Tether patrols
- flying creatures where canon permits
- wind movement in grass/trees
- particles only when sourced by believable objects/events

Do not overpopulate everything. The goal is a living world, not a spawn-system demo.

## 5. Composition standard

For every major location and important corridor capture:
- approach
- player-height standing
- reverse where useful
- detail/interaction
- day
- night if relevant

Judge each frame on:
- foreground detail
- mid-ground structure
- background landmark/depth
- visible life
- material quality
- recognizable silhouette
- cohesion

## 6. Location targets

### Grandpa's Village
Target: **small but unmistakably inhabited frontier village**.

Must read as a village in daylight, not two houses in a field.

Improve:
- clustered buildings
- connecting paths
- yards
- fences/gardens
- purposeful props
- residents
- creature presence
- village-edge/tree framing

Retain/improve the already-strong night feel.

### Tournament Area
It must visually read as a tournament before text/UI explains it.

Use existing-asset dressing such as:
- ring/perimeter
- banners
- spectators
- trainer staging
- benches
- creature waiting zones
- simple event props

### Burrow Warrens
Exterior:
- better rock macro detail
- moss/weathering
- terrain integration
- coherent vegetation

Interior:
- den dressing
- nest/bedding
- stones
- scratch/use marks
- dampness/water where sensible
- local material variation
- stronger directional light
- readable focal points

Mystery should not simply mean darkness.

### Camps / Waystops
The fire is the visual anchor.

Must have:
- clearly readable flame/glow
- clustered seating/supplies
- asymmetric placement
- visual reason for the camp to exist there
- NPC/traveler presence when appropriate

### Team Tether Relay
Keep the strong pylon/apparatus language and raise the surrounding site:
- personnel
- occupation clutter
- physically mounted machinery
- clean cable endpoints
- scorch/work signs
- purposeful barriers/work areas
- faction identity

It must look operational, not abandoned.

### Meadows Hall
Target:
**ancient ruin reclaimed by nature with Team Tether industry bolted onto it**.

Not:
**clean cream castle**.

Use the established Hall direction:
- weathered stone
- per-stone variation
- moss joints
- ivy/overgrowth
- broken wall tops
- arches/gate
- roof variation
- rubble
- courtyard dressing
- Team Tether pipes/scaffolds/machinery/chimney
- convincing cloth banners

The story must be visible from the approach.

## 7. Terrain + path relationship

Paths should feel pressed into the environment, not painted on top.

Use:
- softened edges
- grass encroachment
- occasional stones
- wear
- widening at intersections
- transitions around buildings
- imperfect vegetation suppression

Streams/ponds need:
- denser edge vegetation
- mud/stone transitions
- reeds/plants where appropriate
- banks shaped by water

## 8. Color language

Meadows:
- warm yellow-green sunlit grass
- deeper cooler greens under tree cover
- warm earth paths
- neutral stone
- blue sky/water
- restrained flower accents

Team Tether:
- dark industrial values
- controlled oxblood identity
- reserved energy accent only where appropriate

Avoid:
- fluorescent lime surfaces
- uniform saturation
- making every rare element purple
- excessive teal in friendly/natural spaces

## 9. Creature + character integration

Creature and character assets are often stronger than the environment. The world must rise to meet them.

Use them compositionally:
- readable backgrounds
- appropriate habitat grouping
- scale readable against props/terrain
- avoid silhouettes disappearing into foliage
- ground characters in paths/yards/props rather than isolated grass

Do not redesign creature meshes during this world pass unless current repo rules explicitly authorize it.

## 10. Performance is part of art direction

Primary target remains Windows / ROG Ally.

Every density increase should use appropriate:
- LOD
- visibility ranges
- MultiMesh/instancing
- occlusion/culling
- distance simplification
- material consolidation
- texture atlasing where useful
- lightweight particles
- bounded shadow distances

Do not keep the world sparse merely to protect performance before measuring.

Instead:
1. build the target scene
2. measure
3. optimize invisible cost
4. preserve the visual read

## 11. The 80% rule

We do not need literal concept-art fidelity.

We need roughly **80% of the website art's visual impression**:
- lushness
- color
- depth
- composition
- life
- readable landmarks
- polished atmosphere

A representative screenshot should look like the same *kind* of polished stylized creature-adventure world that the website advertises.

## 12. Visual pass order

0. Baseline captures
1. Sky / atmosphere / lighting
2. Terrain material + ground layer
3. Vegetation structure
4. Mid-ground composition
5. Village / camps / lived-in density
6. Warrens / Relay / Hall material and dressing
7. World life
8. Performance and cleanup
9. Full recapture

## 13. Pass/fail criteria

A visual-parity candidate is ready for owner/ChatGPT review only when:

### World
- no major frame is dominated by bare uniform terrain
- vegetation reads in layers
- important horizons have mid-ground structure
- sky/cloud presentation is deliberate
- atmospheric depth is visible

### Places
- village unmistakably reads as a village in daylight
- tournament reads as an event space
- camps read around clear fire/rest focal points
- Warrens read as an authored den
- Relay reads as active hostile infrastructure
- Hall reads as ancient reclaimed ruin + Team Tether retrofit

### Life
- major locations show believable NPC/creature activity
- frames no longer feel like static test scenes

### Cohesion
- nature, village, props, creatures, humans, and Team Tether look like one game

### Performance
- changes are measured on target renderer/settings
- visual gains are not casually reverted to sparse settings

### Evidence
- matched before/after frames exist
- meaningful changes are documented
- unresolved limitations are explicit

## 14. Final authority

Codex may use internal visual comparisons and repo blind-judge tools as iteration aids.

Codex does **not** have authority to declare final visual parity.

Final acceptance belongs to the owner and external ChatGPT visual review after the branch is returned.

Correct Codex completion state:

> **CANDIDATE READY FOR EXTERNAL VISUAL JUDGEMENT, WITH EVIDENCE.**
