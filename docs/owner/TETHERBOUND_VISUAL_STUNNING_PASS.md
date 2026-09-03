# Tetherbound — Meadows Visually Stunning Pass
## Claude Code parallel visual-production prompt

**Status:** Owner-directed visual quality pass  
**Run in parallel with:** `TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md`  
**Primary objective:** Make the Meadows look like a polished, cohesive stylized survival-adventure world worthy of the gameplay — with Valheim-like world readability and atmosphere, Fortnite-like material/color polish, and Tetherbound's own identity.

---

## 0. Visual target

Do not copy another game's art.

Use these references only as quality principles:

### Valheim-like strengths
- beautiful readable terrain at large scale;
- strong atmosphere and lighting;
- simple geometry made convincing by composition;
- meaningful vegetation density;
- broad natural vistas;
- ground variation;
- readable landmarks;
- environmental mood.

### Fortnite-like strengths
- clean stylized materials;
- controlled saturation;
- strong silhouettes;
- polished props;
- confident shapes;
- attractive lighting;
- clear visual hierarchy;
- high readability.

### Tetherbound target

**Valheim world readability + Fortnite-style polish + Tetherbound's stylized creature/adventure identity.**

Avoid photorealism, dense noisy asset spam, fluorescent colors, flat green terrain, obvious procedural repetition, placeholder/simple geometry, generic asset-store diorama composition, and visual upgrades that destroy ROG Ally performance.

---

## 1. Read before editing

Start from current `main`.

Read:

1. `CLAUDE.md`
2. Tetherbound game vision
3. art/visual direction documents
4. Meadows macro layout
5. regional specs
6. current vegetation/terrain/weather configs
7. owner visual directives/playtests
8. target-hardware/performance rules
9. visual evidence / Fable critique history
10. current world scene and asset libraries

Inspect the live production world before deciding what to change.

Do not beautify obsolete geometry if another active lane is intentionally replacing it.

---

## 2. Parallel lane boundary

This is a **visual production lane**, not the gameplay redesign lane.

### Visual lane owns

- terrain appearance;
- ground materials;
- vegetation visual composition;
- decorative scatter;
- lighting;
- atmosphere;
- fog;
- water presentation;
- environmental VFX;
- landmark silhouette/presentation;
- village visual composition;
- regional identity;
- visual polish of Team Tether occupation;
- environment material quality;
- visual readability;
- visual performance optimization.

### Do not change without coordination

- objective progression;
- reward economy;
- trainer logic;
- creature progression;
- Captain gameplay;
- encounter balance;
- party/catching rules;
- save state;
- story logic.

If the gameplay lane changes a location, adapt visuals to its authoritative gameplay layout rather than restoring old geometry.

---

## 3. Ground treatment — highest priority

The Meadows ground must stop reading as a flat green surface.

Build/improve a layered terrain treatment using at least:

1. healthy meadow grass;
2. warmer/drier grass;
3. exposed dirt/earth;
4. darker/damp soil.

Use low-frequency macro variation, slope/height/water proximity, authored path masks, settlement wear, pond/river moisture transitions, and regional masks.

Avoid camouflage-like procedural noise.

From normal third-person distance, large fields should show broad natural variation over several-to-tens-of-meters scale.

---

## 4. Grass and low vegetation

Do not solve visual quality with millions of grass blades.

Use terrain material for most apparent coverage, efficient instanced grass clumps, clustered distribution, negative space, distance culling, sensible LOD, and minimal expensive shadows on tiny vegetation.

Open Meadows should remain readable.

There must not be an obvious circular grass wall following the player.

---

## 5. Paths must look authored

Paths should remain highly readable, have irregular edges, feather naturally into grass, expose worn earth, reduce grass density, include occasional edge weeds/stones, respond to settlement/travel intensity, and connect visually to bridges, doors and destinations.

A path should look traveled, not painted onto a lawn.

---

## 6. Grandpa's area and village

The opening area has disproportionate visual importance.

Make Grandpa's property and village feel lived in.

Use trampled/worn ground, believable building spacing, readable doors/entrances, fences/hedges where appropriate, small gardens/work areas, props that communicate use, signs beside roads rather than in them, coherent road hierarchy, intentional sightlines, visible route toward early adventure areas, and natural vegetation suppression around buildings.

Do not overfill with props.

Every object should look intentionally placed.

---

## 7. Creek Hollow / early adventure beauty pass

If the gameplay lane adds or repurposes Creek Hollow, prioritize it.

It should be one of the first locations that makes the player think:

> **I want to explore that.**

Desired composition:

- visible descent/basin;
- creek/water glint;
- flowers/grass clusters;
- rock shelf;
- small grove;
- cave/overhang;
- multiple sightline layers;
- strong but natural framing;
- readable habitat pockets;
- enough openness for creature visibility;
- visual pull toward optional ledges/pockets.

Do not let vegetation obscure creatures or navigation.

---

## 8. Pond and water

The pond quality should become the baseline for good water, not an isolated polished patch.

Fix trees/buildings/bushes intersecting water, terrestrial scatter in deep water, harsh shore transitions, and mismatched water-edge ecology.

Create natural gradient:

**meadow → greener/wetter vegetation → damp soil/mud → water.**

Water should reflect/light attractively, remain readable, avoid flat-blue-sheet appearance, and avoid expensive effects that harm target hardware.

---

## 9. Environmental grounding

Large objects should look embedded in the land.

Around trees: reduce immediate grass, add darker soil/leaf litter/low plants/pebbles where appropriate, and avoid identical circles.

Around buildings: expose worn earth, suppress vegetation near doors, add subtle foot traffic, and ground foundations visually.

Around boulders: sink/seat them into terrain and vary surrounding debris.

Avoid “asset placed on top of grass” appearance.

---

## 10. Regional visual identities

### Lower Meadows
- soft green;
- broad pasture;
- warm inviting light;
- farms/groves/creeks;
- open visibility.

### Stone & Root / Quarry / Warrens
- more exposed earth and stone;
- fractured rock;
- Rootstone accents;
- tighter compositions;
- cooler/darker cave transition.

### River / Relay
- wetter greens;
- riparian vegetation;
- unmistakable river landmark;
- mills/crossings;
- Team Tether industrial intrusion;
- water/metal contrast.

### Upper Meadows
- rougher/taller grass;
- elevated pasture;
- old-growth pockets;
- stronger wind/sky exposure;
- ruins;
- richer late-chapter vistas.

### Stronghold Approach
- increasingly stressed terrain;
- drained/desaturated pockets used intentionally;
- pylons/hardware;
- patrol infrastructure;
- Meadows Hall dominance;
- visual tension.

Keep all regions cohesive as one chapter.

---

## 11. Team Tether visual language

Team Tether must visually contaminate the natural Meadows.

Establish/reinforce consistent machinery, pylons, cables/conduits, barriers, camps, occupation props, drained land, unnatural lighting/energy accents, and faction materials/colors.

Do not make every area industrial.

The contrast between healthy Meadows and Team Tether occupation is the point.

---

## 12. Landmarks and sightlines

Every major route should orient the player visually.

From important traversal points, compose views toward village, Creek Hollow, South Bridge, Quarry/Warrens, river/mill, Tether Relay, Upper Meadows, and Meadows Hall.

Use terrain, tree lines, road direction, skyline silhouettes, smoke/light/machinery, ridges and architecture.

A landmark must survive normal third-person camera height.

---

## 13. Lighting and time of day

Eliminate the washed-out grey failure state.

Audit normal play across the full cycle.

Requirements:

- morning: cool/warm readable transition;
- midday: bright but not bleached;
- late afternoon: attractive warmth and depth;
- dusk: strong mood without crushing readability;
- night: dark enough to justify torch/campfire, but playable.

Avoid uniform grey haze, fluorescent grass, overexposed sky, black crushed shadows, excessive post-processing, and color grading that destroys creature readability.

---

## 14. Weather and atmosphere

Use weather to improve place and mood, not obscure gameplay.

Audit clear, cloudy, rain/storm if implemented, and fog/mist where appropriate.

Near Team Tether, environmental effects may show degradation, but navigation/combat must remain readable.

---

## 15. Creature presentation in world

The environment exists partly to show off creatures.

Ensure grass does not hide small creatures excessively, silhouettes remain visible, nests/habitats frame creatures, water creatures read near shore, larger/rare individuals catch the eye, and combat areas provide readable background contrast.

Do not beautify scenes by making the core subject harder to see.

---

## 16. Architecture polish

Audit important structures for believable scale, door size, roof proportions, foundation grounding, material consistency, window/trim detail, silhouette, and collision/presentation mismatch.

Prioritize Grandpa's house, village tournament area, mill/relay structures, and Meadows Hall.

Avoid detail that has no effect at gameplay distance.

---

## 17. Campsite assets

The new core campsite should look charming enough that players want to place it.

Prioritize:

- Tent;
- Campfire;
- Player Bed/bedroll;
- Creature Bed;
- Workbench.

They should share one material/style family, read clearly at gameplay distance, have believable scale, look useful, create an attractive camp composition, and remain low enough complexity for repeated placement.

If placeholders are visibly weak, improve/replace them using the approved asset pipeline.

---

## 18. Terrain silhouettes and macro composition

Audit rolling shapes, ridge lines, gentle elevation changes, basin shapes, river cuts, quarry form, stronghold approach, and vistas.

Avoid giant accidental cliffs around normal holes, flat empty expanses, repetitive slopes, and terrain that visually drops into nothing.

The world should feel like continuous real geography.

---

## 19. Asset repetition

Identify obvious repeated models/materials.

Fix with scale/rotation variance, alternate models in the same family, clustered composition, spacing changes, palette/material variation where safe, and intentional repetition for faction language.

Do not randomize objects into nonsense.

---

## 20. UI presentation

Do a bounded visual polish pass on HUD/menu presentation **without changing gameplay behavior**.

Focus on readable controller prompts, typography, consistent panels/margins, hotbar readability, map legibility, objective presentation, party strip, tournament/captain presentation, and level-up/catch/reward celebrations.

Do not create a major new UI architecture inside this pass.

---

## 21. Performance is part of visual quality

Target hardware includes ROG Ally.

For every major visual improvement measure before/after FPS/frame time, boot cost, vegetation-heavy areas, village, Creek Hollow/pond, combat, Upper Meadows, and Stronghold.

Prefer MultiMesh/instancing, LOD, culling, shadow discipline, simple materials, and selective effects.

A beautiful 15 FPS scene fails.

---

## 22. Visual priority order

1. Ground/terrain treatment
2. Lighting/atmosphere
3. Regional composition/landmarks
4. Vegetation density/composition
5. Water/shorelines
6. Important architecture
7. Team Tether occupation language
8. Campsite/player-facing props
9. Decorative detail
10. UI visual polish

Fix macro problems before micro-decoration.

---

## 23. Evidence plan

Capture production-world evidence from:

- Grandpa's house/yard;
- village approach and interior;
- Creek Hollow;
- open Lower Meadows field;
- South Bridge;
- pond/shore;
- Quarry/Warrens exterior/interior;
- river/mill;
- Relay;
- Upper Meadows;
- Captain location(s);
- Stronghold Approach;
- Meadows Hall.

For important locations capture normal gameplay camera, one useful elevated/macro composition view, day variant, and dusk/night where relevant.

Do not choose only flattering angles.

---

## 24. Fable independent visual review

Per owner model-routing rules:

- Sonnet/Opus/tools produce and capture the visuals.
- **Fable is blind visual reviewer only.**
- Fable must not author, stage, select, edit or fix the evidence it judges.

Give Fable the fixed evidence set, current art direction, visual acceptance criteria, and regional identity targets.

Ask it to judge terrain richness, ground variation, composition, lighting, atmosphere, landmark readability, vegetation, negative space, architecture, water, regional identity, Team Tether storytelling, visual hierarchy, and whether the game reads as polished rather than prototype.

If Fable fails an area:

1. record exact critique;
2. return implementation to Sonnet/Opus;
3. capture new evidence;
4. have Fable review new evidence independently.

---

## 25. Acceptance standard

The visual pass succeeds when:

1. The Meadows no longer reads as a flat green test environment.
2. Ground variation looks natural and authored.
3. Open fields are attractive without being cluttered.
4. Paths/settlements/water edges integrate naturally.
5. Major regions have distinct identities.
6. Major landmarks orient the player.
7. Team Tether presence visually changes the land.
8. Important structures look deliberately authored.
9. The campsite is visually appealing and coherent.
10. Day/night/weather remain attractive and readable.
11. Creatures remain visually prominent in their habitats.
12. The game looks cohesive from opening through Stronghold.
13. Fable blind review passes the agreed bar.
14. ROG Ally performance remains acceptable.

**Target question:**

> **If someone saw 30 seconds of normal Tetherbound gameplay with no explanation, would they think this is a deliberately art-directed finished stylized game rather than an AI-built prototype?**
