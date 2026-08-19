# WILD-ECOLOGY-JOURNEY — Make creatures the living world and team-choice engine

## Goal
Author a coherent wild-creature ecology across the full Meadows so every region feels inhabited and repeatedly presents legitimate team-building choices.

This extends RG20 from “creatures exist and are prevalent” into a chapter ecology. Reuse `encounter_director`, existing species data, band-local spawn files, current deterministic placement/variation, time/weather rules, and PW2 special variants.

No new Meadows creature meshes.

## Core rule
Every region should introduce at least one creature the player could reasonably want enough to reconsider the five.

Reasons may include:
- type coverage;
- combat role;
- moves;
- traits/appraisal;
- evolution potential;
- traversal;
- rarity;
- attachment/preference.

## Habitat plan
Use current canonical roster/spec as the starting point and verify actual current species data.

### Opening / Lower fields
Common, readable early species; singles and small groups; low-threat catches; enough population to build/train a tournament team without grinding one spot.

### Groves / pond / wooded pockets
Species whose behavior/time-of-day fits cover and water edges. Preserve lush pond composition while keeping populations readable rather than visually buried.

### Quarry / Warrens
Ground-oriented ecology, more aggression, Rootstone-associated habitats, guardian/special encounter context.

### River
Water/Air species and riverbank habitats. Current Band 3 `spawns.json` being empty is not acceptable for a finished region.

### Upper Meadows
Stronger/open-country species, Meadowhart, Galecrest/other upper roster as canon permits, special individuals, more visible herd/single silhouettes across long sightlines.

### Stronghold approach
Dangerous but still believable wild presence affected by drained/occupied land; not an empty faction-only corridor. Current Band 5 empty spawn file must be reconciled.

## Population feel
Owner direction remains:
- lower crowding than a creature-swarm game because ownership is only five;
- still prevalent enough that wanting another creature does not require a barren search;
- singles, pairs/groups and nests where appropriate;
- higher levels deeper in the chapter;
- individual level/IV/trait/size/shiny variation preserved;
- species-specific shiny rates where current owner direction requires.

## Behavior
Use peaceful/aggressive data and habitat context. Not every creature attacks on proximity. Aggressive species should create world danger before formal combat; peaceful ones should be observable/approachable.

## Special encounters
Coordinate PW2. Site roughly a handful of memorable alpha/elder/special encounters across the chapter, not one for every species. Each needs behavioral/context identity and a worthwhile reason to defeat it even if the player does not catch it.

## Day/night/weather
Nocturnal/weather-dependent creatures should add discovery, not make normal daytime traversal empty. Night should reveal different opportunities.

## Spawn siting audit
Do not judge population from total JSON count.

For each cluster record:
- region/band;
- distance from main/side routes;
- sightline/occlusion;
- habitat reason;
- expected level range;
- whether it is ordinary, nest, rare or special.

Walk the actual routes and confirm creatures are visible/findable in play.

## Performance
Population must fit ROG Ally performance. Prefer sensible streaming/siting over removing the ecology that makes the game alive.

## Verification
For each gate:
- count meaningful wild opportunities seen without deliberate search;
- record longest interval with no creature visible/available;
- note at least one tempting catch choice;
- verify expected species/habitats;
- verify no accidental mega-crowds;
- verify night/weather rules;
- verify special encounters stand out.

## Acceptance
- every regional package has real wild ecology;
- no major late band has an empty spawn population;
- creatures are findable without saturating the map;
- habitats communicate regional identity;
- the player repeatedly encounters plausible replacements/additions to the five;
- deeper regions feel stronger without player scaling;
- special wilds create memorable detours;
- performance remains acceptable.

## Definition of done
Creatures are no longer occasional content placed inside the Meadows. They are the living population of the Meadows and the main source of evolving team decisions.