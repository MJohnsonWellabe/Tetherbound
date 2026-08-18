# RG20 — Meadows wild creature population: prevalent, varied, findable

## Goal
Fix the owner-reported blocker that normal Meadows traversal can contain no visible wild creatures for long stretches. Tetherbound is a creature-focused game: wild creatures must be a prevalent part of the landscape and a player who decides "I want to catch another creature" must be able to find one without an extended search.

Do not solve this by blindly multiplying every spawn count. First reproduce and trace the current population path on current `main`, identify why authored creatures are not visible during ordinary play, then tune/build the population system to satisfy the player-facing contract below.

## Owner decisions — authoritative
- Creature density should be **lower than Palworld** because Tetherbound's keep-five rule means the world should not feel flooded with disposable captures.
- Even so, creatures should be **prevalent**. Long ordinary stretches with no visible creatures should be unusual.
- If the player wants to catch another creature, they should be able to deliberately go find one.
- Encounters should not all have the same shape:
  - sometimes a single creature;
  - sometimes a nest / small local concentration.
- Wild individuals should vary:
  - some are higher level than others;
  - some are visually larger than others;
  - some have different traits / individuality;
  - some are shiny.
- Shiny rarity is **species-specific**, roughly **1 in 20 to 1 in 100 depending on the creature**. Do not use one global shiny probability for every species.

Treat visual size variance as presentation/individuality only unless an existing design document explicitly gives size mechanical meaning. Do not silently make a larger body stronger, change hitboxes, attack range, capture odds, stats, or combat balance as part of RG20.

## Current code / facts to inspect before changing anything
Read at minimum:
- `scripts/combat/encounter_director.gd`
- `scripts/creatures/creature_instance.gd`
- `scripts/creatures/creature_visual.gd`
- `scripts/creatures/creature_species.gd`
- `scripts/creatures/wild_creature.gd`
- `data/config/spawns.json`
- every band spawn file loaded through `scripts/data/band_content.gd`
- `data/config/progression.json`
- `data/config/creatures_visual.json`
- `data/creatures/species.json`
- current Meadows/world scene and whichever node owns `EncounterDirector`
- `tests/test_spawns_data.gd` and relevant smoke tests
- any `VEG-SITING` / population investigation notes that exist on current main or in Ralph notes; the backlog says that work was asked to diagnose RG20 before this task.

Important existing behavior:
- `EncounterDirector` says the Meadows wild population is data-driven and merged from per-band spawn files.
- It already rolls wild level, three IV/stat-quality values, two trait rolls, and shiny state for each wild individual.
- Shiny is currently a cosmetic boolean on `CreatureInstance`.
- Current shiny odds are read from `creature_visual.gd` / `data/config/creatures_visual.json` as one global tunable. RG20 changes that contract to species-specific odds.
- `data/spawns/` itself being nearly empty is not proof that no population data exists; the live code points at `data/config/spawns.json` and band content. Trace the actual path rather than assuming the directory name is authoritative.

## Reproduction / diagnosis first
Before editing population numbers, create a repeatable measurement of the current build.

From normal owner-like traversal on current `main`:
1. Start from the real opening/world route, not a combat sandbox.
2. Traverse representative portions of every currently playable Meadows band, including the main route and reasonable off-trail space.
3. Record for each segment:
   - how many wild nodes actually exist in the scene tree;
   - how many are active/visible rather than gated off;
   - their authored spawn centres and radii;
   - distance from the normal player route;
   - whether terrain/ground placement succeeded;
   - whether visibility, LOD, culling, time/weather gating, band loading, or activation removes them;
   - how many are actually visible to a player from plausible traversal positions.
4. Separate these failure families rather than guessing:
   - spawn data missing or not merged;
   - population count too low;
   - spawn centres left behind after the world/corridor was resized or moved;
   - clusters too far off the traversable route;
   - ground-placement failure putting creatures under terrain / at unreachable locations;
   - time/weather gates hiding too much of the population;
   - band-content loading/activation issue;
   - rendering/culling/visibility issue;
   - creature nodes exist but normal camera/path never exposes them.

A headless test proving dictionaries contain spawn entries is not proof that the player sees creatures.

## Desired population grammar
Build/tune the Meadows so wild life feels intentionally distributed rather than uniformly sprinkled.

### Singles
- Common enough that a player traveling normally regularly sees an individual creature living in the world.
- Singles may be near the route or in nearby readable habitat, not systematically hidden hundreds of metres away.
- Do not place every single directly on top of the path. They should read as wildlife, not traffic cones.

### Nests / clusters
- Some locations should be recognizable small creature concentrations: a nest, den, feeding patch, pond edge, grove, rock pocket, etc., using habitat that already exists rather than inventing large new landmarks unless required.
- Nests provide the answer to "I want another one of this kind" without requiring the entire biome to be densely populated.
- A nest is not necessarily a literal nest prop; it is a population pattern / local concentration unless existing content already defines a physical nest.
- Avoid giant swarms. The keep-five rule is part of why density should stay below Palworld.

### Findability
- Ordinary traversal should encounter creatures regularly enough that the biome visibly supports its core fantasy.
- A player deliberately looking for a catch should be able to find a viable wild encounter in a short, reasonable search rather than wandering through an apparently empty game world.
- Do not hard-code a permanent seconds-to-encounter number in code. Measure and tune in spawn data, and document the observed traversal result.

## Individual variation
Reuse the existing instance systems instead of creating parallel ones.

### Level
- Preserve/use the existing wild-level roll and progression config.
- Ensure the authored/rolled range actually produces noticeable occasional higher-level individuals.
- Do not make every nest member identical merely because they share a cluster.
- Any changes to level bands remain data-driven/tunable.

### Traits and stat individuality
- Preserve the existing IV/stat-quality and trait roll systems.
- Confirm field-spawned individuals actually receive them through the real population path.
- Different members of the same species/cluster should be capable of rolling different individuality.
- Do not introduce a new trait system.

### Visual size
Add a per-individual visual size roll if no equivalent currently exists.
- Keep it modest enough that all individuals remain clearly the same species.
- It must survive capture/save/load if the captured creature is expected to remain the same individual. Do not let a large wild creature become default-sized after capture or reload.
- Store the rolled value as instance state if persistence requires it; add save migration safely if the field becomes persistent.
- Scaling must not change gameplay collision, attack reach, combat maths, navigation constraints, or camera logic as part of this task. If the current scene architecture couples visual scale to collision, split visual/model scale from gameplay body scale rather than accepting accidental mechanical variance.
- Make the range data-driven/tunable, preferably species-capable if species proportions require different ranges.

### Shiny
The owner supersedes the current one-global-rate design.
- Shiny remains cosmetic only.
- Replace/extend the global `shiny_chance()` contract so odds can be set per species.
- Each Meadows species must have an explicit tunable probability in the approximate owner-approved range of **1/20 through 1/100**, chosen deliberately rather than randomly at runtime.
- Do not invent lore or mechanical bonuses for rarer shinies.
- Keep a safe fallback for malformed/missing species data, but shipped Meadows species should not silently rely on one fallback rate.
- Preserve deterministic seeded-spawn behavior unless there is a strong reason not to; if draw order changes, update tests intentionally and document why. Existing comments make deterministic per-spawn RNG an explicit contract.

## Population persistence / respawn
- Preserve the existing faint/catch/respawn model unless diagnosis proves it is part of the emptiness bug.
- A caught/fainted population should not instantly refill around the player in an obviously gamey way merely to hit a density target.
- Conversely, normal play should not permanently empty huge stretches with no recovery if the current design expects wild respawns.
- Keep respawn timing data-driven.

## Performance constraint
The Meadows is very large and the ROG Ally is target hardware. Do not solve visibility by instancing an unbounded number of fully simulated creatures across the entire world.
- Measure node count / active population and boot/runtime impact before and after.
- Reuse existing band activation/streaming where appropriate.
- Prefer correctly sited, readable population over brute-force density.
- If distant population needs lightweight activation/culling, use the project's existing patterns rather than creating a second world-streaming system.

## Preserve
- Keep-five party/capture rule.
- Existing combat/catching flow.
- Existing species roster and authored creature identity.
- Existing deterministic spawn philosophy unless explicitly justified.
- Existing wild level, IV/stat-quality, trait, and cosmetic-shiny systems where they already work.
- Time/weather-specific species rules that are intentional, but do not allow them to make the baseline world empty.
- No new storage system, breeding system, procedural biome generator, or quest system.

## Testing / verification
### Data / unit coverage
Expand or add tests that prove:
- every Meadows band intended to contain wild life has valid spawn entries;
- species ids resolve;
- centres/radii/counts are sane for current world extents;
- species-specific shiny odds load and remain within valid 0..1 bounds;
- shipped Meadows species have explicit shiny rates in the owner-approved approximate 1/20–1/100 band;
- wild instances still roll levels, IVs, and traits;
- visual size rolls stay inside configured bounds;
- if size is persisted, save/load round-trips it and old saves migrate safely.

### Real-world smoke / survey
Add a regression/survey that boots the actual Meadows world and proves population presence along representative player traversal, not only config validity.
- Assert wild creatures are instantiated and grounded.
- Sample representative route points/bands and confirm nearby active wild population is nonzero at enough locations to prevent a visually empty biome.
- Include at least one single-style spawn and one cluster/nest-style spawn in coverage.
- Ensure the smoke does not direct-inject creature instances and then claim population works.

### Visual / owner-like verification
Capture representative traversal frames showing:
- a normal single;
- a small nest/cluster;
- same-species individuals with visible size variance where feasible;
- a shiny variant if a deterministic test seed can produce one without changing production odds.

Do NOT increase production shiny odds just to make a screenshot easy. A test fixture/seed may force a visual example; live odds stay the configured species odds.

Run at minimum the backlog-required:
- `test_spawns_data`
- `smoke_playground`
plus any new population/individuality/save tests this work introduces and the current relevant project suite.

## Acceptance criteria
RG20 is complete only when all of these are true on current `main`:
1. A normal Meadows session visibly contains wild creatures; the owner no longer experiences the biome as creatureless.
2. Population is deliberately below Palworld-like saturation but clearly prevalent.
3. A player who decides to catch another creature can reasonably locate wild life rather than search through an empty landscape.
4. The world contains both singles and nest/cluster patterns.
5. Wild individuals use the existing level/stat-quality/trait variation systems and can differ within the same species.
6. Some individuals have modest persistent visual size variation without accidental mechanical/stat/collision changes.
7. Shiny odds are data-driven per species, approximately 1/20–1/100 according to species, and shiny remains cosmetic only.
8. Population is correctly sited on the current long Meadows corridor/bands and grounded/reachable.
9. The solution does not brute-force so many active creatures that ROG boot/runtime performance materially regresses.
10. Tests exercise the real population path and representative world placement, not only synthetic instance creation.

## Definition of done
- Root cause of the currently empty-feeling Meadows is written down in the implementation notes/commit.
- Appropriate existing systems are repaired/reused rather than replaced.
- Spawn/population data is tuned for the current world geometry.
- Species-specific shiny tunables exist.
- Individual visual size variance exists and persists where needed.
- Regression coverage proves population, grounding, variation, and data validity.
- Relevant tests pass.
- Representative in-engine captures demonstrate that creatures are genuinely present in normal play.