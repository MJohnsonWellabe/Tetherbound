# Owner direction — 2026-09-06 — Cloudreach Cliffs visual audit + sweep goal

Reproduced verbatim from the owner-supplied task file
`CLOUDREACH_VISUAL_AUDIT_AND_SWEEP_GOAL.md`, supplied 2026-09-06. Under `CLAUDE.md`'s
precedence rules this is a newer owner directive, scoped to the Cloudreach visual
audit and improvement program that is part of **Stage 0** in
`docs/DEVELOPMENT_ROADMAP.md`. It does not supersede `CLAUDE.md`'s hard rules. The
owner's Cloudreach stronghold board now exists in the repo:
`docs/reference/boards-2026-09-06/cloudreach-sky-aviary-stronghold-board.png`.

---

# /goal — CLOUDREACH CLIFFS VISUAL AUDIT + IMPROVEMENT SWEEP

## Purpose
Perform a complete **player-facing visual audit of Cloudreach Cliffs first**, determine the specific problems from real runtime evidence, then execute a prioritized improvement program.

Unlike the Meadows sweep, do **not** assume the fixes in advance. Cloudreach already has some strong areas, especially high-density grass. First determine what works, what looks prototype-level, which locations are weakest, and which improvements have the highest player-facing return. Then implement them.

This is an **audit → prioritize → improve → validate** program.

## 0. Startup
Before changing anything:
1. Read `CLAUDE.md`, `docs/00_START_HERE.md`, `docs/CURRENT_STATE.md`.
2. Read the canonical Cloudreach build/design, progression, traversal/Fly, creature, NPC, encounter and stronghold documents.
3. Read the current gameplay/visual/environment bibles and recent Cloudreach evidence/audits.
4. Inspect current Cloudreach assets, terrain/cliff systems, materials, vegetation, lighting, weather, NPC/encounter placement and performance configuration.
5. Play/capture the real current Cloudreach route.
6. Establish baseline screenshots and performance.
7. If meaningful branch work is already in progress, checkpoint and push it first.

Do not merge.

## 1. Quality Target
Cloudreach should read as a **finished commercial stylized creature-adventure biome**, not a prototype.

Minimum comparative bar:
> **Clearly clears Valheim-level environmental presentation and meaningfully approaches Palworld early-game visual quality, while remaining achievable and performant in the current Godot pipeline.**

Cloudreach has a naturally high visual ceiling because of cliffs, elevation, huge vistas, clouds, waterfalls, bridges, vertical traversal, flying creatures and aerial routes. Do not waste that spectacle.

It must remain readable, controller-friendly, performant, cohesive with Tetherbound, distinct from Meadows, and enjoyable on foot and in the air.

# PHASE A — DISCOVER THE SPECIFICS

## 2. Capture the Whole Biome
Capture representative real gameplay frames throughout the intended journey, including:
- biome entrance/transition and first major reveal;
- early, middle and late traversal;
- best dense-grass area and ordinary/sparse areas;
- major cliffs, bridges, waterfalls and water features;
- settlements/NPC areas and camps;
- trainer locations and creature habitats;
- Team Tether locations;
- progression gates;
- Fly-related areas, aerial routes and landing areas;
- high overlooks and major landmarks;
- Alpha/mini-boss areas where applicable;
- stronghold approach, exterior and interior;
- finale/legendary area where evidence rules permit;
- day, night and meaningful weather variants.

Capture ordinary gameplay angles as well as hero views.

## 3. Identity Audit
Ask:
> **If UI and labels disappeared, would a player immediately know this is Cloudreach?**

Audit terrain silhouette, cliffs, vegetation, grass, trees, rock, architecture, props, sky/weather, palette, creature placement, verticality, waterfalls, bridges, airborne activity and landmarks.

Cloudreach must not read as **Meadows, but higher**.

Identify successful identity elements to protect and weak elements that dilute the biome.

## 4. Protect What Already Works
Identify the **best 5–10 visual examples already in Cloudreach** and make them internal references.

Pay special attention to the high-density grass areas that already outperform Meadows.

For each, determine why it works: mesh quality, density, material, lighting, terrain composition, clustering, scale, color, depth, background silhouette and motion.

Do not regress strong work while fixing weak areas.

## 5. Prototype-Level Failure Audit
Find the most visible failures, including where applicable:
- bare terrain or weak grass;
- poor cliff materials/geometry;
- repetitive rocks/vegetation/props;
- weak trees;
- empty mid-ground/horizons;
- poor NPC placement;
- weak settlement composition;
- floating/misaligned objects;
- weak bridges/waterfalls;
- generic camps or Team Tether sites;
- weak lighting/atmosphere;
- repetitive encounter spaces;
- awkward landing areas;
- weak hero locations/stronghold;
- scenes that work only from one camera.

For each significant issue record location, evidence, player-facing problem, likely owning asset/system, severity, screen-time impact, and whether it is local or systemic.

## 6. Terrain + Cliff Audit
Cloudreach lives or dies on its cliffs.

Audit cliff silhouettes, shape variation, face materials, texture scale, normals, roughness, macro variation, ledges, erosion, moss/vegetation integration, grass transitions, waterfall cuts, rock paths, distant LOD and repetition.

Find smooth/procedural walls, obvious texture repetition, unnatural edges, vegetation that ignores geology, pasted-on waterfalls and poorly integrated paths.

If cliff quality is a major weakness, rank it highly for Phase B.

## 7. Grass + Groundcover Audit
Treat Cloudreach's strongest dense grass as an internal benchmark.

Audit mesh quality, density, transitions, color variation, wind, draw distance, groundcover, flowers/weeds, exposed terrain, cliff-edge integration and performance.

Preserve intentional windswept sparse areas, rocky ledges and trails while creating lush protected pockets/plateaus where appropriate.

Do not cover everything at maximum density.

## 8. Trees, Shrubs + Highland Vegetation
Audit whether vegetation feels appropriate to Cloudreach.

Inspect silhouettes, scale, canopy/trunk quality, clustering, wind exposure, cliff placement, shrubs, flowers, alpine/highland plants and repetition.

Trees/vegetation should frame paths, overlooks, settlements, bridges, waterfalls and landmarks.

Do not automatically copy Meadows solutions.

## 9. Vistas + Mid-Ground Composition
For major routes ask:
- Is there foreground interest?
- Is there a strong mid-ground?
- Is there a meaningful distant silhouette?
- Can the player see where they are going?
- Are optional destinations visible?
- Do cliffs frame landmarks?
- Do waterfalls/bridges/settlements anchor views?
- Does atmospheric perspective create depth?
- Are there purposeless stretches of empty sky/rock/grass?

Gaining elevation should repeatedly produce a visual reward.

## 10. Verticality Audit
Audit stacked routes, switchbacks, bridges, stairs, ramps, cliff paths, ledges, lower/upper settlements, waterfalls, vertical landmarks and Fly routes.

Ask:
> **Does the player feel like they are ascending through a real place?**

If routes feel like flat paths placed at different Y coordinates, improve the composition.

## 11. Flying Integration Audit
Flying must look like a system the world was designed around.

Audit takeoff/landing spaces, aerial-route readability, vertical landmarks, airspace obstacles, creature presence, distant destinations, arches/towers/waterfalls, wind/updraft language if implemented, and places rewarding both flying and walking.

Avoid **terrestrial map + unrestricted flight cheat**.

Prefer **world deliberately composed for ground and air traversal**.

## 12. Creatures + World Life
Audit creature visibility, habitat placement, flying-creature movement, groups, perches/nests, land/flying mixture, NPC activity, trainers, camps, Team Tether patrols and ambient motion.

Important vistas should sometimes contain distant creature activity without crowd spam.

Creatures remain Tetherbound's emotional focus.

## 13. Settlements + NPC Placement
Audit every meaningful inhabited area.

Ask whether it has a purpose, architecture responds to cliffs/wind, buildings cluster logically, paths connect them, NPCs appear to work/live/socialize there, props form purposeful clusters, signs help navigation, and cliff edges have believable safety/structure.

Cloudreach settlements should feel **built for the heights**, not copied from Grandpa's Village.

## 14. Bridges, Waterfalls + Landmarks
Audit every important bridge, waterfall, arch, tower, ruin, major tree, structure and overlook.

Determine whether each is visible before arrival, orients the player, rewards reaching it, has strong materials, integrates with terrain, and has enough surrounding composition to feel important.

## 15. Team Tether Presence
Audit personnel, machinery, banners, cables, barriers, work areas, damaged environment, occupation clutter, lighting and approach composition.

Team Tether sites should feel like active hostile intervention rather than generic props dropped into cliffs.

Pressure should escalate through the chapter.

## 16. Stronghold Audit
Use the newly approved direction:

> **A giant domed aviary with a rustic stone-castle foundation and Cloudreach architectural language.**

Target old/weathered stone, towers/arches, a huge aviary dome, flying-creature scale, bridges/walkways, open air, selected overgrowth and Team Tether retrofit where story requires it.

Do not make it a pristine palace, modern glass conservatory, generic castle, or impossible ultra-detailed concept-art structure.

Audit the current stronghold against this direction. If it fundamentally misses, prefer a deliberate visual-shell/presentation rebuild over endless micro-tuning while preserving gameplay layout where practical.

## 17. Lighting, Sky + Atmosphere
Exploit altitude.

Audit sky/cloud quality, sun, shadows, fog, atmospheric perspective, distance haze, cloud layers around/below cliffs where technically appropriate, golden hour, night readability and weather.

Do not use fog to hide weak geometry.

## 18. Performance Audit
Measure dense grass, cliff vistas, settlements, waterfalls, creature-heavy areas, stronghold and flying traversal.

Separate genuine hardware constraints from unfinished art.

Use instancing/MultiMesh, LOD, visibility ranges, occlusion/culling, simplified distant foliage, shadow controls, material consolidation and sensible particles.

Protect the visible result.

# PHASE A OUTPUT

## 19. Create the Ranked Audit
Before major implementation, create/update:

`docs/CLOUDREACH_VISUAL_AUDIT_AND_SWEEP.md`

Include:
- **What already works** — top strengths to protect.
- **Top systemic weaknesses** — problems affecting many locations.
- **Weakest key locations** — ranked by player impact.
- **Strongest key locations** — internal references.
- **Recommended implementation passes** — ordered by visual return.
- **Performance risks** — measured, not guessed.
- **Asset needs** — only assets justified by evidence.
- **Do-not-touch list** — strong areas where changes risk regression.

Then begin Phase B automatically unless a genuinely unresolved creative/product decision blocks implementation.

# PHASE B — EXECUTE THE PRIORITIZED SWEEP

## 20. Let the Audit Decide the Order
Do not mechanically follow the audit-section order if evidence shows a different priority.

A likely order might be:
1. largest systemic visual weakness;
2. terrain/cliffs;
3. vegetation;
4. vistas/vertical composition;
5. settlements/NPCs;
6. Fly integration;
7. hero locations;
8. Team Tether;
9. stronghold;
10. atmosphere;
11. performance;
12. route-wide cleanup.

But Phase A evidence decides.

## 21. Improvement Loop
For each pass:
1. identify the exact failure;
2. capture baseline;
3. inspect owning implementation/assets;
4. implement the smallest coherent high-impact improvement;
5. test;
6. run the real game;
7. recapture matched views;
8. compare against baseline and Cloudreach's strongest internal references;
9. run blind visual judgement where available;
10. fix regressions;
11. update audit/progress docs;
12. commit;
13. push;
14. continue.

Do not hold all work locally until the end.

## 22. Checkpoint / Usage Policy
After every coherent pass: test, capture, document, commit and push.

If usage/context is becoming low, do not begin another pass. Finish the smallest coherent state, update the audit/progress document, commit, push, leave an exact resume note, and stop cleanly.

A future Codex session should be able to resume without repeating Phase A.

## 23. Blind Visual Judge Questions
Ask code-blind judges:
1. Finished commercial stylized game or prototype?
2. Three biggest visible weaknesses?
3. Clear identity distinct from Meadows?
4. Vegetation natural/authored?
5. Cliffs geological/authored rather than procedural?
6. Vistas rewarding?
7. World communicates vertical traversal?
8. Flying integrated into the environment?
9. Settlements inhabited and adapted to cliffs?
10. Major landmarks memorable?
11. Stronghold reads as rustic-stone domed aviary?
12. Obvious reason to explore visible destinations?
13. Creature remains visual/emotional focus?
14. Clearly exceeds Valheim-level presentation?
15. How close to Palworld early-game quality?

Do not tell the judge what changed or what verdict is desired.

## 24. Required Final Evidence
Provide matched before/after evidence for:
- biome entrance;
- dense grass;
- ordinary traversal;
- cliff material/geometry;
- vegetation composition;
- major waterfall;
- major bridge;
- settlement/NPC area;
- trainer/creature habitat;
- Team Tether site;
- ground vertical route;
- flying route;
- landing area;
- major overlook;
- stronghold distant reveal;
- stronghold approach;
- exterior;
- interior;
- day;
- night/weather;
- at least three strongest final hero views.

Also provide starting/final SHA, commit list, performance before/after, judge history, unresolved limitations, strongest internal-reference frames and exact recommended next work.

## 25. Success Bar
Cloudreach passes when:
- it unmistakably has its own cliff/air identity;
- its best existing work is preserved;
- weak areas are raised toward its strongest areas;
- grass density/design is intentional and strong;
- cliffs look authored and convincing;
- vegetation fits the highland environment;
- vistas repeatedly reward elevation;
- vertical traversal is obvious in world composition;
- flying feels intentionally integrated;
- settlements feel inhabited and built for the heights;
- creatures make the world feel alive;
- bridges, waterfalls and landmarks are memorable;
- Team Tether occupation escalates visually;
- the stronghold convincingly reads as a **rustic stone domed aviary**;
- sky/atmosphere strengthens depth;
- major route locations no longer show obvious prototype-level gaps;
- target-hardware performance remains acceptable;
- representative gameplay clearly exceeds **Valheim-level** presentation and moves meaningfully toward **Palworld early-game** polish.

Final state:

> **CANDIDATE READY FOR EXTERNAL VISUAL REVIEW — DO NOT MERGE.**
