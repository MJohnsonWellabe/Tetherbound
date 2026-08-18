# MQ3 — Decompose and author Meadows Bands 3–5 to Band-2 quality

## Goal
Turn the relocated but comparatively empty latter half of the 8192m Meadows corridor into authored, playable progression. This umbrella item must **decompose itself into per-band implementation tasks** rather than attempting one giant undifferentiated content commit.

Bands in scope:
- Band 3 — The River Lock
- Band 4 — Upper Meadows / Ironwood
- Band 5 — Stronghold Approach

Use the current band directories under `data/config/bands/` and the approved macro/progression docs as source of truth.

## Quality bar
Copy **Band 2's completeness and density of intent**, not its literal geography. Each major region/band must have:
1. a clear entry and visual purpose;
2. authored geography/pathing that makes the area legible;
3. a meaningful critical objective/progression beat;
4. at least one optional discovery/reward/activity;
5. a memorable encounter (trainer, wild group/nest, alpha/elder, environmental gate, dungeon-like beat where already approved);
6. working road/pylon/map navigation;
7. day/night usability;
8. a reason to explore off the critical path;
9. a readable transition that points into the next band.

Do not fill distance with random props or cloned quests merely to increase object count.

## First step: inventory what already exists
Before authoring, inspect current main and produce a short gap map for each band covering:
- terrain/routes/crossings;
- landmarks and regions;
- pylons/Team Tether evidence;
- wild spawn clusters/nests;
- trainers/NPC dialogue;
- harvest/material progression;
- optional activities;
- gates/rewards;
- map markers;
- existing approved special content (river crossing/relay/stronghold approach, etc.).

Mark each as **landed / present but broken / relocated but empty / missing**. Do not rebuild shipped content because the umbrella brief sounds broad.

## Decomposition requirement
Create concrete backlog sub-items or implementation plan sections for each band, ordered by dependencies. Each sub-item must name:
- player-visible outcome;
- data/scripts it edits;
- content it reuses;
- tests/captures;
- definition of done.

Then execute in small shippable increments if this firing has sufficient context. Do not leave the umbrella as prose only if obvious independent work is ready.

## Band-specific intent
### Band 3 — River Lock
Build around the substantial river, Old Mill Crossing, Tether Relay and their established progression. The river/crossing must be a real geographical decision, the relay a clear escalation of Team Tether presence, and routes/spawns/trainers must connect those beats rather than sit as isolated islands.

### Band 4 — Upper Meadows / Ironwood
Make the material/progression tier change visible in world ecology, gathering and challenge. Ironwood/new-tier unlocks should feel earned through exploration and progression, consistent with RG13's discovery-based recipe philosophy. Avoid a simple palette swap of lower Meadows.

### Band 5 — Stronghold Approach
Build anticipation and pressure before Meadows Hall: denser Team Tether presence, meaningful approach gates/encounters, Storm Gate integration, pylons converging toward the stronghold, and strong visual landmarking. Do not turn it into a linear combat hallway; there should still be optional space and exploration.

## Content rules
- Meadows roster only; no new creature meshes/generations.
- Use existing NPC rigs/rank system.
- Wilds should follow RG20 population philosophy: prevalent/findable, singles + nests, individual variation, not Palworld flooding.
- PW2 alpha/elder variants and CONTENT-ACTIVITIES can be placed as these bands mature; coordinate rather than duplicate.
- Use existing materials/harvest/recipe tier systems.
- Preserve five-creature ownership cap.

## Navigation
The player should be able to infer progression using roads, terrain, landmarks, RG17 pylons and map/minimap. Do not rely on giant waypoint beams. Critical routes must remain traversable and collision-consistent.

## Visual bar
Use `docs/reference/tetherbound-meadows-keyart.png` as primary world direction and Palworld references only for real-time density/readability. Every visual subtask follows `ralph/conventions.md` capture + blind visual-judge convergence.

## Acceptance criteria
For each Band 3–5:
1. walking the main route never enters a long obviously empty stretch;
2. the band has a distinct readable place identity without becoming a separate biome;
3. critical progression works end-to-end;
4. at least one optional discovery/reward exists;
5. wild/trainer encounters are intentionally sited and level-appropriate;
6. material/resource progression matches current tier;
7. navigation, map, save/load and day/night work;
8. transition to the next band is visually/gameplay clear.

For MQ3 overall: all three bands meet that checklist and the full village-to-stronghold traversal feels like authored game content rather than Band 1/2 followed by relocated scaffolding.

## Testing / verification
Per-band traversal smoke, relevant trainer/spawn/harvest/gate tests, save/reload at key transitions, map-state tests, and representative day/night capture sets. Also run one end-to-end corridor traversal after all sub-items land.

## Definition of done
Bands 3–5 are decomposed into concrete shippable work and completed to the same structural quality bar as Band 2: **purposeful geography, progression, encounters, optional exploration, navigation and visual identity all working together.**