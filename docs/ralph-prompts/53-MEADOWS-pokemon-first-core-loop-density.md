# MEADOWS-CORE-LOOP — Make the long journey about building a stronger five-pal team

## Owner diagnosis — 2026-08-18 evening
The owner played the current long Meadows and found the central problem: **there is not enough purpose while moving through it.** Some of this is because core systems are broken/incomplete (wild pals, building, gathering), but even after those work the corridor needs a stronger repeated gameplay cadence.

Owner observations:
- more pals are needed to fight so the team can level;
- more NPC trainers should be encountered on/near the path for XP and team testing;
- more useful things should be mineable/harvestable along the route;
- there should be reasons to stop, build a camp and rest pals;
- special stronger/boss-like wild pals should create reasons to explore/detour;
- right now too much of the experience is simply running around;
- Palworld provides special boss-pals and visible encounters; Valheim provides resource progression and a reason to return/rest; Pokémon provides the strongest motivational model: catch/train a better team to beat increasingly important trainers/gym-like goals.

## Locked high-level design
**Tetherbound's primary Meadows motivation is Pokémon-like team progression.**

The core question pushing the player forward should be:

> `Can I build and train a strong enough five-creature team for the next meaningful challenge?`

Valheim/Palworld-inspired survival systems support that question:
- gathering provides the materials for preparation;
- building lets the player establish camps/home infrastructure;
- creature beds/rest make attrition and recovery matter;
- food/condition supports tournament/readiness;
- exploration finds better/rarer/different creatures and resources;
- special wilds and trainers provide tests and XP;
- Team Tether and the stronghold provide the chapter's escalating opposition.

Do **not** turn the game into a survival resource grind where creatures are secondary. Do **not** turn it into a linear trainer gauntlet where gathering/building are decorative.

## Goal
Author the Meadows corridor so every meaningful travel segment contains a recurring mix of:
- creatures worth fighting/catching;
- trainers worth challenging;
- resources worth harvesting/mining;
- occasional special/rare encounters worth detouring for;
- environmental discoveries/side activities;
- natural places where the player considers stopping to camp/rest before pushing farther.

There should still be scenic breathing room. The goal is **purposeful cadence**, not constant combat density.

## Coordinate existing work instead of duplicating it
This item is an integration/design-density pass across existing systems/prompts:
- `06-RG20-meadows-wild-creature-population.md` — ordinary wild prevalence, nests, levels/traits/shinies;
- `28-MQ3-decompose-and-author-bands-3-to-5.md` — band content construction;
- `29-PW2-alpha-elder-wild-variants.md` — special wild encounters;
- `30-CONTENT-ACTIVITIES-meadows-optional-activities.md` — memorable optional beats;
- `25/26-RG19` — tournament and creature condition;
- `43-CREATURE-BED-gradual-overnight-rest.md` — real recovery/camp pressure;
- `44-GATHER...` — working resource loop;
- trainer NPC/data systems;
- progression/objective chain RG16/RG17/RG18/STORM-GATE.

Do not build second versions of those systems. This prompt decides **how densely and intentionally they are distributed as one gameplay loop**.

## Chapter motivational spine
The route should escalate roughly like this, using existing canon/bands rather than inventing a new story:

1. **Grandpa / starter / first catches** — learn team-building basics.
2. **Prepare for village tournament** — catch a full team, train, gather, build, rest/feed/happy.
3. **Win the tournament** — first clear proof that team preparation matters.
4. **Leave village toward Team Tether** — route now repeatedly tests and improves the team.
5. **Wild encounters + local trainers + resources + optional special creatures** grow stronger/deeper by band.
6. **Team Tether patrols/grunts/captains/gates** become increasingly meaningful trainer tests.
7. **Stronghold/Warden/chapter climax** pays off the team the player built.

Each band should answer both:
- `Why am I moving forward?`
- `What can I do here that makes my team better/prepares me for what is ahead?`

## Encounter cadence — measure instead of guessing
Walk the real main spine at normal speed and map the actual time/distance between meaningful choices.

For each band record:
- minutes of uninterrupted travel with no interactable gameplay opportunity;
- ordinary wild encounter opportunities;
- trainers;
- resource clusters;
- special/alpha/elder/rare encounters;
- side-activity hooks;
- safe/camp-worthy spaces;
- mandatory story/gate encounters.

Use this as a density heatmap. Do not merely count total creatures in JSON; a dozen spawns 400 m off-route do not solve an empty 8-minute walk.

### Target feel, not hard permanent numbers
The player should generally encounter or visibly notice another meaningful opportunity before travel begins to feel like empty holding-forward. But scenic open fields can intentionally breathe, especially if there is a distant landmark, visible herd, trainer silhouette, resource formation or special encounter pulling the player onward.

Keep exact spacing/data tunable after playtest. Do not hardcode one encounter every N metres globally.

## Wild creatures
RG20's owner direction remains:
- less world saturation than Palworld because Tetherbound has a strict five-creature ownership rule;
- nevertheless, if the player decides they want another creature, they should be able to find one without an extended barren search;
- singles and nests/groups;
- varied level/stat/trait/size/shiny individuality;
- higher-level/special individuals deeper into the route.

Use habitat to create identity:
- open-field creatures visible at distance;
- tree-line/pond/warren/river species in appropriate pockets;
- night/weather species where already designed, without emptying the daytime route.

## Trainers
Add enough NPC trainers that team battles are a regular source of progression, not a rarity.

Trainer roles should include:
- ordinary local trainers/villagers/travelers early;
- stronger route trainers deeper in Meadows;
- Team Tether grunts/patrols where faction occupation becomes relevant;
- captains/special trainers at meaningful landmarks/gates;
- tournament opponents in the village.

Do not place them as evenly spaced combat vending machines. Give them readable world context: camp, path intersection, bridge, farm, quarry, patrol, overlook, etc.

Reuse current NPC rigs/rank palette and trainer battle system; no new human mesh requirement.

## Resources and harvesting
The journey needs useful gathering/mining opportunities that reinforce the current material progression:
- early wood/stone/berries;
- material clusters appropriate to later recipe/build unlocks;
- visible resource formations that justify leaving the main trail;
- enough resources near plausible camp sites to make setting up camp possible without backtracking across the biome.

Do not make every field a dense resource carpet. Resource siting should create small decisions: `Do I detour for that stone/wood/rootstone because the next camp or upgrade will need it?`

Coordinate with progressive recipe/build unlocks so resources have a purpose when introduced.

## Camp/rest pressure
The long world is supposed to take multiple in-game days. Use that.

With the new bed contract:
- injured pals recover only while actually resting;
- resting pals are unavailable;
- overnight completion matters.

Therefore band pacing should naturally create moments where pushing onward with an injured team is a meaningful choice and making camp is useful.

Do not force a camp every exact X minutes with invisible gates. The pressure should emerge from distance, night, attrition, team condition and upcoming fights.

Place/design camp-worthy clearings where needed:
- enough relatively flat buildable space;
- nearby basic resources;
- not directly inside constant hostile aggro;
- visually distinct enough that a player can remember the stop.

## Special wilds / boss-pals
PW2 should provide the Palworld-like `I see something special over there` motivation without just scaling a normal creature up.

Across Meadows, site memorable alpha/elder/special encounters that:
- are optional or semi-optional detours;
- visibly stand out through size/behavior/context already allowed by PW2;
- test the player's team;
- reward XP/catch opportunity/resource/item/achievement as existing systems permit;
- create local goals between major Team Tether beats.

Do not make every species have an alpha in every band.

## Visual composition — lush pockets AND open meadows
The owner specifically approved the **dense tree/plant band around the pond**: `looks great`.

Preserve it as a lush-area reference.

But the Meadows must also contain **wide open areas** with long sightlines and lower clutter, in the spirit of Valheim meadows or Palworld open fields.

Required regional composition:
- lush pockets: pond, certain groves/river/warren edges where appropriate;
- open grassland: broad fields, rolling meadow, visible distant landmarks/creatures/trainers;
- transition zones: tree lines, sparse copses, rock/resource formations, roads.

Do not solve vegetation with one global density multiplier.

Open does **not** mean empty. In open areas, gameplay/readability can come from:
- visible herd/single creature at distance;
- trainer/camp silhouette;
- resource outcrop;
- landmark/pylon line;
- side trail;
- stronghold/bridge/terrain vista.

This variation should make each stretch breathe and also protect Ally performance.

## Band-by-band deliverable
For each Meadows band, write/adjust a compact content-density plan before placing more objects:
- core purpose/challenge;
- ordinary wild habitats;
- trainers;
- resources;
- special encounter(s);
- optional activity/discovery;
- camp/rest opportunity;
- visual density mode: open / mixed / lush;
- transition/payoff to next band.

Then implement through the existing band-split data files.

## Anti-patterns
Do not:
- fill empty travel with dozens of quest markers;
- place wild creatures uniformly every N metres;
- turn every NPC into a trainer;
- create huge Palworld-like creature crowds that conflict with five-pal ownership tone/performance;
- make resource nodes glow/gold again;
- make every region as dense as the pond;
- make open meadow into bare procedural nothing;
- invent a second XP/progression system;
- add new creature meshes for Meadows;
- hide main objective under side content.

## Verification
### Traversal playtest
Walk the entire critical path in the exported/representative build and record:
- encounter/opportunity timeline;
- longest empty interval per band;
- team levels at major beats from a fresh realistic run;
- when/why player chooses to camp/rest;
- whether material availability supports the intended unlocks;
- whether tournament -> route -> Team Tether escalation feels coherent.

### Visual survey
Capture both open and lush representative areas. The critic should be able to distinguish them as intentionally different compositions while both read as the same Meadows biome.

### Gameplay question
A fresh player should be able to answer after each band:
- what they were trying to get stronger for;
- how their team improved;
- what optional thing tempted them off-path;
- whether/why they stopped to recover or build.

## Acceptance criteria
1. Ordinary wild creatures are prevalent/findable across the journey.
2. Trainers provide regular team battles/XP between major bosses.
3. Useful harvesting/mining opportunities recur by material tier.
4. Special wild encounters provide memorable optional tests/detours.
5. Camp/rest has real utility because of distance/condition/attrition.
6. No long corridor segment feels like purposeless running without visual/gameplay pull.
7. Main motivation clearly remains building a stronger five-pal team for the next challenge.
8. Pond lush composition is preserved.
9. Wide open Meadows areas also exist and look intentionally good, not under-populated.
10. Density is authored per region and measured on target hardware.
11. Tournament, Team Tether and stronghold form a coherent escalation spine.

## Definition of done
The Meadows is no longer a long map containing systems. It becomes a journey where the player repeatedly sees something worth fighting, catching, gathering, exploring or preparing for—and each choice feeds the central goal of building the five-creature team that can beat what is farther down the road.