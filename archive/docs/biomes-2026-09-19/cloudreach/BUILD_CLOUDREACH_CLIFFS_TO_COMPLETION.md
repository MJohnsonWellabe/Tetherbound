# TETHERBOUND — BUILD BIOME 2: CLOUDREACH CLIFFS TO COMPLETION

## `/goal`

Build **Biome 2: Cloudreach Cliffs** all the way through to a complete, integrated, playable chapter after the Meadows.

This is **not** a design-only task.

The goal is to take the existing Tetherbound game from the end of the Meadows into a fully playable second biome, with working progression, world, story, traversal, NPCs, encounters, resources, objectives, bosses, rewards, shrine-power progression, Fly traversal, content density, save-state integration, UI hooks, tests, evidence, and integration to `main`.

You are responsible for orchestration and completion.

Use lower-tier agents aggressively for bounded implementation, investigation, testing, capture, content authoring, and repetitive work. Retain senior responsibility for architecture, canon, sequencing, integration, quality judgment, world composition, progression coherence, and final acceptance.

---

# 1. READ FIRST

Before changing anything, read and obey:

1. `CLAUDE.md`
2. `docs/00_START_HERE.md`
3. newest `docs/owner/` directives
4. current Meadows canonical docs
5. current gameplay/world/architecture docs
6. this document
7. the supplied Cloudreach Cliffs concept board

Do not reopen archived backlogs as active truth.

Do not create a competing master plan unless current canonical documentation is provably wrong.

If existing docs define Biome 2 differently, update them so Cloudreach Cliffs becomes the authoritative second biome.

The later **Water biome comes after Cloudreach Cliffs**. Reorder any future-biome roadmap references accordingly.

---

# 2. FINAL OUTCOME

At the end of this goal, a player should be able to:

1. finish the Meadows;
2. defeat the Warden;
3. receive:
   - the **Key to the Next Realm**;
   - the **Heart of the Meadows**;
4. return to the Meadows shrine;
5. hang/place the Heart of the Meadows there;
6. unlock the Meadows Heart power:
   - **double stamina**;
7. equip that Heart power;
8. understand that only **one realm-heart power may be active at a time**;
9. open and enter the next realm;
10. enter **Cloudreach Cliffs**;
11. play through the entire Cloudreach Cliffs chapter;
12. unlock and use Fly traversal;
13. access the required mid-chapter Fly-only sheer cliff destination;
14. complete the biome's main story;
15. defeat its final major confrontation;
16. earn its end-of-biome progression reward;
17. leave the game clearly pointing toward the future Water biome.

The Cloudreach Cliffs chapter must be a real playable game chapter, not scaffolding.

---

# 3. CLOUDREACH CLIFFS — CORE IDENTITY

## Name

**Biome 2: Cloudreach Cliffs**

## Core fantasy

A dramatic vertical highland realm built around:

- sheer cliffs;
- massive elevation changes;
- broken sky roads;
- rope bridges;
- stone bridges;
- cliff paths;
- lookout towers;
- ruined waystations;
- ancient shrines;
- exposed ridgelines;
- bird perches;
- wind-carved plateaus;
- dangerous drops;
- high-altitude settlements;
- big horizon views;
- vertical shortcuts;
- hidden ledges;
- inaccessible-looking spaces that later become reachable through Fly.

It should feel like the Meadows has given way to a more dangerous, daring, adventurous place.

## Tone

Cloudreach should feel:

- windswept;
- adventurous;
- awe-inspiring;
- ancient;
- high-risk/high-reward;
- bright but dangerous;
- open to the sky;
- vertical rather than flat;
- scenic without becoming empty.

It should NOT feel like:

- another Meadows;
- a dense dark forest;
- a swamp;
- a horror biome;
- a water biome;
- a corridor with cliffs painted beside it.

---

# 4. VISUAL TARGET

Use the supplied Cloudreach Cliffs art board as the primary visual direction.

Preserve its core ideas:

- towering sheer faces;
- suspended paths;
- layered plateaus;
- broad sky;
- warm natural stone;
- wind-bent vegetation;
- ancient stone structures;
- bridges and rope crossings;
- bird-related architecture/perches;
- dramatic vertical sightlines;
- distant visible destinations;
- settlements and landmarks clinging to terrain;
- large readable silhouettes.

The player should regularly see places before reaching them.

Cloudreach must be navigable visually, not only by minimap.

Every major subregion needs at least one recognizable landmark.

---

# 5. MEADOWS ENDING REWORK

The current Meadows ending must flow cleanly into Cloudreach.

## After defeating the Warden

The Warden gives the player two major items:

### A. Key to the Next Realm

This is the progression key that allows entry into Cloudreach Cliffs.

It must be:

- represented in story;
- persisted in save data;
- recognized by the realm-entry gate;
- impossible to bypass through ordinary play;
- granted exactly once;
- retained after save/load.

### B. Heart of the Meadows

The Warden also gives the player the **Heart of the Meadows**.

This is not a normal consumable.

It is a realm trophy / power source.

The player must return to the Meadows shrine and place the Heart there.

---

# 6. REALM HEART SYSTEM

Implement a reusable **Realm Heart** system modeled conceptually after Valheim's boss-power structure.

## Required behavior

Each completed biome can eventually grant:

- one Realm Heart;
- one shrine placement;
- one biome-specific passive/active power;
- only one equipped Heart power at a time.

For now, fully implement only the Meadows Heart power.

## Heart of the Meadows

Power:

**Double maximum stamina.**

The exact implementation should feel meaningful but must not break core traversal balance.

Implement it in a clean reusable way so later biomes can define different Heart powers.

## Shrine interaction

The Meadows shrine must:

- recognize whether the Heart has been earned;
- allow the Heart to be placed;
- visually/statefully record that it has been placed;
- unlock the Meadows Heart power;
- allow the player to select/equip the power;
- clearly communicate that only one Heart power can be active at once;
- persist state across save/load.

If future Heart slots are visible, they may remain inactive placeholders, but do not invent future biome powers yet.

## Acceptance

A player must be able to:

- defeat the Warden;
- receive the Heart;
- save;
- load;
- return to shrine;
- place it;
- equip Meadows power;
- verify stamina doubles;
- unequip/swap cleanly through the shared system;
- save/load with the chosen Heart power preserved.

---

# 7. ENTRY TO CLOUDREACH CLIFFS

Create a real realm transition.

The player should not simply teleport from a debug menu.

The progression should feel ceremonial and meaningful.

Requirements:

- entrance exists physically in the Meadows;
- entrance is visibly locked before the Warden reward;
- the Key to the Next Realm unlocks it;
- transition is clear and intentional;
- loading/streaming works reliably;
- save position works correctly;
- returning to Meadows remains possible unless canon explicitly requires otherwise;
- no accidental gate skip;
- no sequence break through Fly or geometry.

The first view of Cloudreach should immediately establish height and scale.

---

# 8. CLOUDREACH STORY

Write and implement a full chapter story.

Do not leave this as disconnected objectives.

## Story objective

Cloudreach must have a central regional problem that:

- matters to local people;
- connects to the larger Tetherbound world;
- explains why traversal routes are broken/controlled;
- creates a reason to explore deeper;
- escalates through the chapter;
- culminates in a major final confrontation;
- sets up the Water biome afterward.

The story should feel like the second chapter of the same game, not a side expansion.

## Structure

Use a clear three-act progression:

### Act I — Arrival / orientation

The player:

- enters Cloudreach;
- meets the first local NPCs;
- learns the immediate regional problem;
- discovers that ordinary paths only reach part of the biome;
- begins encountering stronger trainers and wild creatures;
- learns that flight routes used to connect the upper plateaus;
- begins working toward Fly access.

### Act II — Vertical unlock / Fly

The player:

- earns or unlocks Fly capability;
- gains access to previously unreachable cliff routes;
- reaches the required Fly-only sheer cliff destination;
- discovers a major story truth, important landmark, key NPC, relic, shrine, or progression object there;
- sees the biome open up vertically;
- begins accessing higher-altitude content and stronger challenges.

### Act III — High Cloudreach / climax

The player:

- reaches the upper reaches;
- confronts the biome's primary antagonist or controlling force;
- completes the final progression chain;
- defeats the biome's major boss/final challenge;
- resolves the region's central conflict;
- receives the biome completion reward;
- sees the route toward the Water biome revealed.

Do not stop at "boss defeated." Include aftermath and region-state change.

---

# 9. FLY TRAVERSAL

Fly is a major biome feature and must be fully implemented enough for Biome 2 to rely on it.

## Visual concept

Fly should look like a creature-powered paraglider.

The player does NOT sit on a flying creature.

Instead:

- the bird creature flies overhead;
- the player hangs beneath it;
- both player arms reach above the head;
- the player holds the creature's legs;
- the bird carries the player;
- the overall silhouette should resemble a Fortnite-style parachute/glider descent;
- the creature is effectively the glider.

The final flying-creature roster/art may come later.

Therefore:

- implement the traversal system now;
- use a placeholder fly-capable creature if needed;
- separate traversal mechanics from species-specific final art;
- document the final creature-art dependency.

## Flight model

Fly should feel like controlled gliding/travel, not unrestricted noclip.

Design for:

- takeoff eligibility;
- launch from suitable locations;
- forward glide;
- descending movement;
- limited climb behavior if appropriate;
- stamina interaction if appropriate;
- landing;
- collision safety;
- no flying through terrain;
- no flying through locked realm progression;
- no bypassing story gates before Fly is unlocked;
- controller-first usability.

Do not make the player capable of infinitely ascending from flat ground unless explicitly justified.

Cloudreach should still have meaningful terrain and route structure after Fly unlocks.

---

# 10. REQUIRED FLY-ONLY SHEER CLIFF

Somewhere around the middle of Cloudreach, create a major sheer cliff destination that cannot be accessed by walking, jumping, climbing, or ordinary riding.

It must require Fly.

This is not a tiny collectible ledge.

It must be meaningful enough that the player remembers it.

Recommended role:

**The Sky Shrine / High Roost / Wind Sanctuary** — choose the final name based on the story.

This location should contain at least one major chapter component such as:

- key story revelation;
- important NPC;
- regional relic;
- flight mastery trial;
- major objective unlock;
- rare crafting resource;
- powerful reward;
- major side objective;
- access to a new plateau network.

The location should be visible earlier from below to build anticipation.

Before Fly:

> "I can see that place, but I cannot get there."

After Fly:

> "Now the world has changed."

---

# 11. WORLD STRUCTURE

Build Cloudreach as a full authored world with several distinct subregions.

Exact names can evolve, but the biome should include approximately:

## Region 1 — Cloudreach Gate / Lower Cliffs

Purpose:

- arrival;
- tutorialization of vertical terrain;
- first settlement/camp;
- first trainers;
- basic cliff ecology;
- introduce the region's problem.

## Region 2 — Broken Causeways

Purpose:

- rope bridges;
- shattered stone roads;
- side paths;
- first major route choices;
- stronger encounters;
- resource pockets;
- visible inaccessible upper terrain.

## Region 3 — Windscar Ravine

Purpose:

- narrow traversal;
- dramatic drop;
- wind hazards/visual language;
- important mid-biome conflict;
- preparation for Fly.

## Region 4 — High Roost / Sky Shrine

Fly-only major destination.

Purpose:

- story pivot;
- meaningful reward;
- chapter unlock.

## Region 5 — Upper Cloudreach

Purpose:

- large elevated plateau system;
- stronger trainers;
- higher-tier resources;
- dangerous wild ecology;
- optional content;
- flight shortcuts;
- late-game preparation.

## Region 6 — Summit / Final Stronghold

Purpose:

- biome climax;
- elite encounters;
- final major boss;
- conclusion;
- Water-biome setup.

Do not build these as six straight checkpoints.

Use loops, alternate paths, overlooks, shortcuts, optional pockets, and reconnecting routes.

---

# 12. CONTENT DENSITY

Cloudreach must learn from the Meadows.

Do not create beautiful empty acreage.

Every meaningful traversal segment should regularly present reasons to:

- fight;
- catch;
- explore;
- gather;
- climb;
- glide;
- detour;
- talk;
- discover;
- prepare;
- heal;
- camp;
- investigate.

Use authored density, not object spam.

Cloudreach should include:

- wild encounters;
- trainers;
- NPCs;
- resource nodes;
- camps;
- landmarks;
- pickups;
- hidden rewards;
- side objectives;
- shrines;
- ruins;
- alternate paths;
- shortcuts;
- high-value cliff ledges;
- flight-accessible secrets.

No long stretches of only holding forward.

---

# 13. NPCS

Create and implement a full biome NPC cast.

Target a manageable but meaningful roster.

Include:

- arrival/guide NPC;
- local residents;
- cliff travelers;
- trainers;
- bridge/watch personnel;
- people affected by the biome conflict;
- one or more memorable side characters;
- antagonist faction representatives;
- late-game story NPCs.

Every NPC should have:

- purpose;
- location;
- dialogue;
- progression relevance or world-building role;
- correct portrait/body where applicable;
- no player-face placeholder problem.

NPCs should be distributed across the biome, not stacked in one town.

---

# 14. QUESTS / TASK FEED

Use the task-feed system established in the Meadows.

Cloudreach should have:

- one clear main chapter chain;
- several optional regional tasks;
- at least one trainer completion objective;
- exploration-driven tasks;
- Fly-related objectives;
- at least one objective that visibly changes after Fly unlock;
- at least one multi-step side chain;
- clear completion feedback.

Avoid GPS spam.

The task feed should tell the player what matters without replacing exploration.

---

# 15. ENCOUNTERS AND TRAINERS

Creatures will be finalized later, but the chapter structure cannot wait.

Implement encounter structure now using placeholders/data hooks if needed.

Define:

- level ranges by region;
- trainer progression;
- encounter difficulty curve;
- captain/elite encounters;
- boss/final challenge;
- reward tiers.

Do not hard-wire final species assumptions into architecture.

Use replaceable encounter tables.

Cloudreach combat should be noticeably harder than Meadows.

"Stronger" should come from:

- better moves;
- better encounter composition;
- smarter behavior;
- terrain use;
- pressure;
- switching;
- positional threats;

not merely huge HP inflation.

---

# 16. FINAL BOSS / BIOME CLIMAX

Cloudreach requires a real biome-ending confrontation.

Design and implement:

- pre-boss approach;
- visual buildup;
- encounter identity;
- unique arena;
- meaningful mechanics;
- clear story stakes;
- difficulty appropriate after an entire second biome;
- reward;
- post-boss state change.

The boss should test:

- team strength;
- creature switching;
- bond/level investment;
- preparation;
- recovery planning;
- movement/combat skill.

Do not make it a generic enlarged trainer.

If the final creature/boss art is not ready, use a replaceable placeholder and leave the system fully functional.

---

# 17. PROGRESSION / LEVELING / BONDING

Cloudreach must continue the improved progression feedback now being added to Meadows.

Requirements:

- XP visible;
- level progress visible;
- level-up celebration;
- bond progress visible during ordinary play;
- bond milestone celebration;
- bond UI understandable;
- shared actions reinforce creature relationship;
- Fly itself may become a bonding opportunity with the active fly-capable creature.

The player should feel their team becoming stronger over the entire chapter.

---

# 18. EXPLORATION REWARDS

Continue the Meadows philosophy of worthwhile findables.

Cloudreach should contain:

- Good Candy;
- Great Candy;
- Rare Candy;
- potions;
- revives;
- useful consumables;
- crafting materials;
- rare resources;
- TMs;
- meaningful optional rewards.

Use Cloudreach-specific placement logic.

Examples:

- cliff-edge caches;
- ruined watchposts;
- abandoned packs;
- shrine offerings;
- dangerous upper ledges;
- Fly-only pockets;
- broken bridge ends;
- caves/overhangs;
- summit rewards.

Pickups must be persistent and one-time where appropriate.

Do not uniformly scatter them.

---

# 19. RESOURCES / CRAFTING

Define and implement Cloudreach's resource tier.

It should include new materials appropriate to the biome.

Examples may include:

- wind-worn hardwood;
- cliffstone;
- sky ore;
- rope fiber;
- feather-like crafting drops;
- alpine herbs;
- high-altitude berries.

Use names that fit Tetherbound canon and existing naming conventions.

Resources should unlock useful preparation for Cloudreach and later progression.

Do not turn crafting into a separate factory game.

---

# 20. BUILDING / CAMPING

Cloudreach should make camping matter more than Meadows without making hunger punitive.

Use:

- long distances;
- vertical routes;
- recovery pressure;
- scarce safe rest locations;
- environmental exposure;
- stronger encounters.

Create suitable campable spaces.

Do not solve necessity through extreme hunger drain.

Camp and building systems should remain supportive of exploration.

---

# 21. MAP / NAVIGATION

Cloudreach requires strong world readability.

The player should recognize:

- lower cliffs;
- broken causeways;
- ravine;
- Fly-only cliff destination;
- upper plateaus;
- summit/final zone.

Use:

- towers;
- giant rock formations;
- bridges;
- shrines;
- ruins;
- banners;
- settlement silhouettes;
- huge vertical landmarks.

The minimap supports this but does not replace it.

Fly routes should be readable.

---

# 22. AUDIO / ATMOSPHERE

Where the current game supports it, add Cloudreach atmosphere:

- wind;
- exposed-cliff ambience;
- bridge creaks;
- distant bird calls;
- high-altitude silence;
- settlement ambience;
- boss-zone escalation.

Do not block completion if bespoke audio assets are unavailable, but wire the system and use existing appropriate assets where possible.

---

# 23. ART / ASSET RULES

Use the supplied concept board as visual reference.

Follow existing project asset rules.

Priority:

1. installed assets;
2. suitable free-pack assets;
3. owner-approved generated assets where required.

Do not invent expensive asset pipelines unnecessarily.

If a required final creature does not exist yet:

- use a placeholder;
- document the exact replacement point;
- do not block the chapter.

For structural art gaps, create explicit art briefs rather than leaving vague TODOs.

---

# 24. SAVE / STATE REQUIREMENTS

Everything important must survive save/load:

- Meadows Heart earned;
- Meadows Heart placed;
- active Heart power;
- realm key earned;
- Cloudreach unlocked;
- Cloudreach entrance discovered;
- Fly unlocked;
- Fly tutorial completed;
- chapter objectives;
- defeated trainers;
- boss state;
- pickups collected;
- shrine interactions;
- side quest progress;
- shortcuts opened;
- post-boss world state.

Add migration/default handling so old saves do not crash.

---

# 25. TESTING REQUIREMENTS

Do not treat code existence as completion.

Create tests for:

- Warden reward grant;
- Heart persistence;
- shrine placement;
- only one active Heart power;
- double-stamina effect;
- realm-key gating;
- Cloudreach transition;
- Fly unlock;
- Fly state;
- Fly landing;
- Fly gate restrictions;
- Fly-only destination access;
- objective progression;
- pickups persistence;
- trainer defeat persistence;
- final boss state;
- post-boss state;
- save/load.

Create a continuous Cloudreach smoke/play path.

The chapter needs an end-to-end evidence chain comparable to the Meadows Gate F philosophy.

---

# 26. VISUAL VALIDATION

Every major visual batch must be:

1. implemented;
2. captured;
3. judged code-blind;
4. revised if needed.

Required visual review points:

- first Cloudreach reveal;
- lower cliffs;
- broken bridge/causeway region;
- mid-biome ravine;
- Fly silhouette;
- Fly-only cliff destination;
- upper plateau;
- final approach;
- final arena.

Do not judge only posed beauty shots.

Use real route/play frames.

---

# 27. PERFORMANCE

Cloudreach's verticality and sightlines can be expensive.

Profile and manage:

- terrain draw distance;
- vegetation;
- distant structures;
- cliff geometry;
- shadows;
- particle effects;
- Fly view distance.

Do not repeat the Meadows mistake of beautiful editor scenes that fail on the target machine.

Preserve target-hardware performance discipline.

---

# 28. BRANCH / PR / INTEGRATION MODEL

Never push implementation directly to `main`.

For each bounded task:

1. branch from current `main`;
2. use a shipping branch;
3. own explicit files;
4. implement;
5. test;
6. validate;
7. commit;
8. push;
9. open PR;
10. review actual diff;
11. merge verified work;
12. verify integrated `main`.

Do not leave dozens of finished branches unmerged.

Land continuously.

Dependent work should branch from the latest integrated `main`.

---

# 29. AGENT DELEGATION

Use lower-tier agents aggressively.

Good delegation targets:

- resource tables;
- NPC dialogue drafts;
- pickup placement;
- trainer data;
- objective data;
- tests;
- capture runs;
- bug investigations;
- file moves;
- placeholder art integration;
- regional dressing;
- map pins;
- save migration tests;
- combat tuning slices.

Senior/orchestrator retains:

- chapter story;
- world structure;
- Fly architecture;
- Heart architecture;
- progression;
- biome gating;
- major encounter design;
- integration;
- visual acceptance;
- final chapter acceptance.

---

# 30. EXECUTION ORDER

Recommended high-level order:

## Phase 0 — Reconcile / prepare

- verify clean current main;
- inspect open PRs/branches;
- update Biome 2 docs;
- establish Cloudreach canonical path;
- identify existing reusable systems.

## Phase 1 — Meadows handoff

- Warden rewards;
- Key to Next Realm;
- Heart of Meadows;
- shrine placement;
- Heart power framework;
- double stamina;
- save/load;
- realm gate.

## Phase 2 — Cloudreach world foundation

- terrain;
- major region layout;
- paths;
- bridges;
- landmarks;
- settlement;
- transition;
- streaming;
- navigation;
- initial visual pass.

## Phase 3 — Core chapter content

- NPCs;
- dialogue;
- task chain;
- trainers;
- pickups;
- resources;
- camps;
- side objectives;
- world density.

## Phase 4 — Fly

- mechanics;
- animation pose/hooks;
- controls;
- unlock;
- tutorial;
- landing;
- collision;
- stamina;
- Fly-only destination.

## Phase 5 — Mid/late progression

- high-altitude regions;
- stronger trainer ladder;
- story pivot;
- upper routes;
- late resources;
- optional content.

## Phase 6 — Final confrontation

- approach;
- final zone;
- boss;
- reward;
- aftermath;
- Water-biome handoff.

## Phase 7 — Evidence / polish

- end-to-end Cloudreach run;
- visual route review;
- balance;
- persistence;
- performance;
- bug fixing;
- docs;
- final main verification.

Do not wait until the end to integrate.

---

# 31. DEFINITION OF DONE — CLOUDREACH

Cloudreach is not done because its folders exist.

It is done when:

- the player can enter it naturally from a completed Meadows save;
- the Meadows Heart loop works;
- the realm gate works;
- the full world exists;
- the full main story exists;
- objectives guide the chapter;
- content density is intentional;
- Fly works;
- Fly is actually required;
- the sheer cliff destination works;
- NPCs function;
- trainers function;
- encounters function;
- pickups function;
- resources function;
- camping/recovery remains meaningful;
- the final major confrontation works;
- the post-boss state works;
- save/load works throughout;
- chapter visuals pass review;
- performance is acceptable;
- continuous-play evidence exists;
- completed work is merged to main;
- canonical docs describe reality.

---

# 32. INTENTIONALLY DEFERRED

The following may remain intentionally unfinished if final art/design does not yet exist:

- final Cloudreach creature roster;
- final bird-creature models;
- final unique creature animations;
- final biome legendary creature art, if not yet supplied;
- Water-biome implementation.

But placeholders must allow the entire chapter to function.

The missing creature roster is not permission to leave world progression incomplete.

---

# 33. REQUIRED FINAL REPORT

Before ending the goal, provide:

## Main state

- current `main` SHA;
- confirmation all completed work is merged;
- remaining open PRs/branches and why.

## Meadows transition

- Warden key status;
- Heart of Meadows status;
- shrine status;
- double-stamina power status;
- persistence evidence.

## Cloudreach completion

For each:

- world;
- story;
- NPCs;
- trainers;
- objectives;
- resources;
- pickups;
- Fly;
- Fly-only cliff;
- boss;
- aftermath;
- Water-biome setup;

classify as:

- proven;
- implemented but unproven;
- blocked;
- intentionally deferred.

## Evidence

- tests;
- smoke runs;
- continuous chapter run;
- visual judgments;
- performance evidence.

## Deferred art

List every placeholder and exact replacement point.

## Next step

If Cloudreach is truly complete except creature art, say so clearly.

If not, state the highest-value remaining work and continue if the session still has capacity.

---

# 34. CORE PRINCIPLES

Build the chapter, do not merely describe it.

Integrate continuously.

Evidence over assumptions.

Playable progression over isolated systems.

Designed density over empty acreage.

Vertical exploration over decorative cliffs.

Fly must change the player's understanding of the map.

The Heart system must feel like a major realm reward.

Cloudreach must feel like a full second chapter, not a tech demo.

Do not stop at architecture.

Do not stop at scaffolding.

Do not stop at "ready for implementation."

**Finish the biome.**
