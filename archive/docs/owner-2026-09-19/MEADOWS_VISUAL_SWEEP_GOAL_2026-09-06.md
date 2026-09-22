# Owner direction — 2026-09-06 — Meadows visual sweep goal

Reproduced verbatim from the owner-supplied task file
`MEADOWS_VISUAL_SWEEP_GOAL1.md`, supplied 2026-09-06. Under `CLAUDE.md`'s
precedence rules this is a newer owner directive; it is scoped, narrow
implementation direction for the environment/key-location visual pass that is
part of **Stage 0** in `docs/DEVELOPMENT_ROADMAP.md` ("current Claude work on
biomes 1 and 2 art, multiplayer and game fixes"). It does not redesign
gameplay, progression, creatures or Meadows geography, and it does not
supersede `CLAUDE.md`'s hard rules (no new creature meshes, Meshy reserved for
Team Tether hero objects, reuse the installed humanoid cast, etc.).

---

# /goal — MEADOWS VISUAL SWEEP: ENVIRONMENT + KEY LOCATIONS

Read `CLAUDE.md`, `docs/00_START_HERE.md`, `docs/CURRENT_STATE.md`, `docs/TETHERBOUND_VISUAL_BIBLE_V2.md`, `docs/FINISH_THE_MEADOWS.md`, and the current visual-progress/evidence docs before changing anything.

This is a **focused Meadows visual-quality sweep**. Do not redesign gameplay, progression, creatures, or Meadows geography. Preserve completed work. Checkpoint and push the current branch before beginning if meaningful work is already in progress.

## Primary target

Bring the real playable Meadows clearly above the bar of **Valheim Meadows** and toward **Palworld early-game environmental quality**:

- lush but readable;
- authored rather than procedurally empty;
- stronger vegetation;
- better key-location composition;
- improved visual hierarchy;
- more believable villages and occupied spaces;
- cohesive stylized assets;
- good target-hardware performance.

Use real in-game captures to judge the work. Do not optimize for one screenshot.

## 1. Grass — use Cloudreach as the internal benchmark

Inspect the current Cloudreach implementation and identify the **highest-quality dense grass patches**.

Compare Cloudreach and Meadows for grass mesh/design, blade/clump shape, density, height variation, color variation, wind/motion, clustering, draw distance, interaction with flowers/groundcover, and performance technique.

Determine why Cloudreach's best grass reads better.

Improve Meadows using the useful technique/art lessons without making Meadows look like Cloudreach.

Meadows should have dense grass in selected high-value areas, medium-density normal meadow coverage, intentional sparse clearings/paths, natural density transitions, flowers/weeds mixed into selected areas, and minimal large expanses of bare painted-green terrain.

Do **not** simply increase one global density number. Use ecological placement and performance-aware instancing/LOD/culling.

## 2. Trees — art quality + density

Audit every currently used Meadows tree family for silhouette, canopy quality, trunk quality, scale, repetition, material quality, distance appearance, clustering, and whether tree lines frame the world well.

Inspect the **Sakura tree asset in `github.com/MJohnsonWellabe/GolfModel`**, whose default branch is `version2`.

Locate the actual source asset and its licensing/provenance. If compatible with Tetherbound, bring the Sakura tree into the approved Tetherbound asset pipeline and record it properly in the asset ledger.

Use it as an **accent/hero tree**, not as the dominant Meadows tree. Place it only in a small number of authored locations where its color creates a memorable landmark or attractive composition.

Improve overall tree placement using groves, tree lines, hero trees, saplings, varied scale, open clearings, distant tree masses, and framing around paths, village and landmarks.

Avoid evenly spaced procedural-looking trees.

## 3. Bushes — prefer procedural if it looks better

Audit the existing bush assets.

Judge them visually against what can be produced procedurally using the current Godot pipeline.

**Preferred direction:** procedural/generated bush forms if they create better visual variety, performance and cohesion.

Keep asset-based bushes only where they are genuinely better.

Procedural bushes should vary height, width, leaf density, color/value, rotation, and shape/silhouette.

Avoid obvious green balls or repeated identical bushes.

## 4. Grandpa's Village — full composition pass

Perform a deliberate visual/layout pass on the village.

Do not merely add more props.

### Town layout

Review building spacing, path network, village center/focal area, sightlines, foreground/mid-ground/background structure, arrival experience, and the visual connection between Grandpa's area and the rest of the village.

### Signs

Inspect all signs for location, orientation, readability, hierarchy, whether the sign actually helps navigation, and whether signs feel naturally installed rather than dropped beside a road.

Use the newer Meadows sign assets if available and appropriate.

### Props

Improve authored clusters using carts, crates, barrels, benches, fences, gardens, firewood, tools, cooking/work areas, flowers, and other lived-in details.

Do not arrange props like inventory objects.

### NPC placement

Audit where each village NPC stands or moves.

Every NPC should appear to have a reason to be there.

Prefer believable placement around homes, work areas, gardens, social spaces, roads, tournament, docks/wells/shops where relevant.

Avoid obvious idle-NPC rows or people standing in empty grass.

The daylight village must immediately read as a real small settlement.

## 5. Burrow Warrens — hero location pass

Improve the Warrens exterior and interior substantially.

### Exterior priorities

- stronger entrance composition;
- better rocks/materials;
- moss/weathering;
- roots/vegetation;
- terrain integration;
- approach sightline;
- make the location visually distinct before the player reaches the entrance.

### Interior priorities

- believable den structure;
- stronger floor/wall material variation;
- nesting/bedding/use marks;
- roots, stones, damp areas where appropriate;
- readable lighting;
- better focal points;
- environmental evidence that creatures actually inhabit it.

Mystery does not mean making everything dark.

Compare the final result against the current best authored locations in Cloudreach.

## 6. Meadows stronghold / Hall — hero location pass

Re-evaluate the complete approach and exterior/interior presentation of the Meadows stronghold.

Preserve the approved identity:

> **ancient ruined stone structure reclaimed by nature, with Team Tether industrial occupation retrofitted into it**

Improve whichever elements are still visibly weak: weathered stone, material variation, moss, ivy/overgrowth, broken wall profiles, gates/arches, roofs, rubble, courtyard dressing, banners, pipes, scaffolding, machinery, occupation clutter, Team Tether personnel, lighting, and approach composition.

The stronghold should tell its story visually before dialogue explains it.

Do not turn it into a clean fantasy castle.

## 7. Other key locations

After the required locations above, walk the entire real Meadows progression route and identify the **highest-impact remaining visual weaknesses**.

Inspect at minimum the tournament, South Bridge, quarry, pond, camps/waystops, river crossing, Team Tether Relay, Upper Meadows, captain locations, and stronghold approach.

Improve locations where the visual gap is obvious.

Prioritize empty mid-ground, weak vegetation, bad NPC placement, poor landmark visibility, repetitive prop placement, bare terrain, weak route framing, and areas that look like test levels rather than authored places.

Do not spend large amounts of time micro-polishing locations that already clear the bar.

## 8. Visual density rule

Do not make all Meadows equally dense.

Use intentional contrast between open rolling meadow, medium-density travel space, lush pond/river/grove pockets, dense village/hero locations, rocky Warrens/quarry, and occupied Team Tether zones.

**Cloudreach's best dense grass is a quality reference, not an instruction to cover the entire Meadows at that density.**

## 9. Performance

Measure before and after.

Preserve the intended Windows/ROG Ally target.

Optimize with MultiMesh/instancing, LOD, visibility distances, culling, shadow-distance control, simplified distant foliage, and material consolidation.

Do not solve performance by returning the world to the sparse baseline unless profiling proves no better solution exists.

## 10. Required visual evidence

Capture matched before/after real gameplay frames for:

1. representative Meadows grass;
2. dense grass comparison against Cloudreach;
3. tree/grove composition;
4. Sakura tree usage;
5. village approach;
6. village center;
7. village NPC/prop layout;
8. Warrens approach;
9. Warrens interior;
10. Team Tether Relay;
11. stronghold approach;
12. stronghold exterior/interior;
13. at least three other improved key locations;
14. one broad Meadows hero view.

Run the existing repo blind visual-judge workflow where available.

Ask the visual judge:

- Does this look like a finished commercial stylized game or a prototype?
- Does the vegetation feel authored and natural?
- Does the village look inhabited?
- Are the Warrens and stronghold memorable hero locations?
- Does Meadows visually clear Valheim Meadows?
- Does it approach the quality/readability of Palworld's early-game environments?
- What are the three biggest remaining visible weaknesses?

Do not tell the judge what changed or what verdict is wanted.

## 11. Checkpoint / push policy

Work in coherent passes:

1. grass;
2. trees/bushes;
3. village;
4. Warrens;
5. stronghold;
6. other key locations;
7. performance/final capture.

After every coherent pass, test, capture, update the visual progress/handoff document, commit, and push.

If usage/context becomes low, stop before beginning the next pass and leave an exact resume note.

Do not merge.

## Success bar

This sweep is successful when Meadows grass is visibly improved in design and density; the best dense areas compete with Cloudreach's best vegetation; trees have stronger models, clustering and silhouettes; Sakura is used sparingly as a memorable accent; bushes look natural rather than asset-spammed; the village feels intentionally laid out and inhabited; signs help navigation and belong where they are placed; NPC placement feels purposeful; Warrens feels like a real authored den/dungeon; the stronghold is a memorable ancient-overgrown-Team-Tether location; other major route locations no longer contain obvious prototype-level visual gaps; performance remains acceptable; and representative Meadows gameplay clearly looks at least as polished as **Valheim Meadows** and meaningfully closer to **Palworld early-game**.

Final state:

> **CANDIDATE READY FOR EXTERNAL VISUAL REVIEW — DO NOT MERGE.**
