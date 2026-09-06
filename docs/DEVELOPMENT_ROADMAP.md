# TETHERBOUND — DEVELOPMENT ROADMAP TO FOUR-BIOME BETA

**Status:** canonical living product-development roadmap.

**Purpose:** Own the execution sequence from the current two-biome build through multiplayer, integrated game audit, Stormwood, the owner playtest/repair cycle, Biome 4, and a four-biome beta. Update this document as each stage lands. A fresh Fable or Codex session should be able to read this file, identify the current stage, follow the linked directive, and continue without inventing a new master plan.

> **Core rule:** build → validate → repair → expand. Do not add another biome on top of unresolved systemic problems.

---

## 0. How to use this roadmap

At the start of any major orchestration session:

1. Read `CLAUDE.md`.
2. Read `docs/00_START_HERE.md`.
3. Read this file in full.
4. Read `docs/CURRENT_STATE.md`.
5. Identify the first stage below whose exit criteria are not satisfied.
6. Read that stage's linked directive(s).
7. Execute that stage instead of creating a parallel roadmap.
8. Update this file and `docs/CURRENT_STATE.md` when stage state materially changes.

Use these status labels consistently: **not started / in progress / implemented but unproven / proven / blocked / intentionally deferred**.

A stage is not complete because files, tests or branches exist. Completion is player-facing and evidence-backed.

---

## 1. Master sequence

1. **Land all current Meadows + Cloudreach work and stabilize `main`.**
2. **Make Tetherbound fully playable 1–4 player multiplayer.**
3. **Run a full Fable product audit across Meadows + Cloudreach on multiplayer-capable `main`.**
4. **Repair the audit's P0/P1 findings before adding another biome.**
5. **Build Biome 3: The Stormwood.**
6. **Owner performs a real continuous three-biome playtest.**
7. **Repair all broken/high-impact findings from that playtest.**
8. **Design and build Biome 4 using the lessons from the three-biome game.**
9. **Run a dedicated four-biome Beta Ready gate.**
10. **Launch four-biome beta.**
11. **Add Biomes 5–8 over time using the same build → audit → repair discipline.**

Do not skip a gate because later content is easier or more exciting.

---

# STAGE A — LAND CURRENT WORK AND STABILIZE MAIN

**Owner:** Fable orchestration / integration.

**Goal:** reach one known-good integrated baseline containing the best completed Meadows and Cloudreach work before multiplayer begins.

### Read
- `docs/FINISH_THE_MEADOWS.md`
- `docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md`
- `docs/biomes/cloudreach/BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md`
- `docs/CURRENT_STATE.md`
- recent open PRs/branches and evidence reports

### Required work
- inspect every in-flight branch/PR;
- merge completed verified work;
- preserve incomplete but useful branches with exact handoff notes;
- resolve integration conflicts in favor of latest owner directives and player-facing behavior;
- run proportionate integrated smokes;
- update `docs/CURRENT_STATE.md` to describe what is actually on `main`;
- record severe known blockers honestly rather than carrying hidden assumptions into multiplayer.

### Exit criteria
- no valuable completed work is stranded;
- `main` imports and plays;
- Meadows and Cloudreach are both reachable to the extent currently implemented;
- known severe blockers are explicitly listed;
- multiplayer can branch from one stable SHA.

Then move immediately to Stage B.

---

# STAGE B — MAKE THE GAME PLAYABLE MULTIPLAYER

**Owner:** Fable senior orchestrator.

**Detailed directive:** `docs/MULTIPLAYER_DIRECTIVE.md`

**Execution plan (approved 2026-09-05):** `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` —
the thirteen architecture decisions, the model-tier rule (Fable / Opus / Sonnet / Haiku), eight
waves of lanes with owned files and proving tests, and the §17-item-to-smoke acceptance table.
Start at its Wave 0.

This is not an architecture-only pass. The required outcome is a real **Valheim-style 1–4 player co-op game**.

### Product target
- one player hosts a world;
- up to three friends join;
- host/server authoritative shared world;
- portable player trainer/team/inventory saves;
- shared world progression;
- each player owns a five-creature team;
- each player directly controls their active creature in combat;
- solo remains first-class;
- no friendly fire initially;
- friends may occupy different biomes;
- host quit safely ends/saves the session;
- dedicated servers and host migration are not required initially.

### Minimum implementation scope
- WorldState vs PlayerState ownership split;
- migrated world/player save format;
- host/join UI and session lifecycle;
- player spawn/despawn/reconnect;
- replicated trainer movement;
- replicated creature deployment/control;
- shared wild encounters;
- catch ownership: first successful catch wins;
- server-authoritative damage, loot and resource state;
- shared buildings/storage/crafting stations;
- gathering without duplication;
- shared main story/world flags;
- personal creature progression, inventory, bond and active relic power;
- co-op revive;
- multiplayer-compatible menus that do not pause the shared world;
- riding replication;
- Fly replication;
- realm transitions;
- boss multiplayer behavior;
- shared relic placement/unlocks with personal active power choice;
- personal fog-of-war;
- all-player sleep requirement;
- safe save/reload/reconnect.

### Evidence bar
Prove:
- 1-player hosted run;
- 2-player join/play/leave/rejoin;
- 3-player session;
- 4-player session;
- shared Meadows encounter;
- shared Cloudreach encounter;
- simultaneous creature deployment;
- shared building placement visible to all;
- shared resource gathering without duplication;
- shared boss/major encounter;
- realm transition;
- save/reload/reconnect;
- geographically separated players without state collapse;
- different-biome occupancy if realm architecture supports it.

### Anti-grind rule
Drive to broad playable multiplayer first. Do not spend the whole pass perfecting one edge case while basic co-op is absent elsewhere. After two serious approaches to one narrow issue produce neither material improvement nor new causal evidence, change strategy or hand it to a fresh focused lane.

### Exit criteria
An outside tester can launch a host world, invite three friends, move, deploy creatures, fight, gather, build, progress, save and reconnect without developer intervention.

After this stage, **do not start Stormwood yet**. Move directly to Stage C.

---

# STAGE C — FULL TWO-BIOME PRODUCT AUDIT

**Owner:** Fable.

**Goal:** assess Meadows + Cloudreach as a product, not as a codebase.

This is a formal quality gate. Do not begin with another architecture inventory. Inspect real runtime behavior, route density, progression, content, multiplayer behavior and representative visuals.

## C1 — Does it work?
Prove a new player can progress from the opening through the end of Cloudreach without:
- console commands;
- debug teleports;
- dead objectives;
- menu softlocks;
- irreversible progression errors;
- save/load corruption;
- broken realm transitions;
- multiplayer desync that prevents progress.

Audit both solo and multiplayer-critical paths.

## C2 — Is there enough to do?
Measure actual per-region/per-route density of:
- wild creature encounters;
- trainers;
- named encounters;
- pickups;
- candy;
- potions/revives;
- harvest nodes/resources;
- NPCs;
- camps;
- side objectives;
- secrets;
- landmarks;
- crafting/building reasons;
- meaningful rewards.

Do not rely only on totals. Measure:
- average time/distance between meaningful interactions;
- worst dead-travel gap;
- on-route vs off-route reward balance;
- whether visible detours pay off;
- whether late regions are thinner than early ones.

## C3 — Is progression satisfying?
Audit:
- XP/level visibility;
- bond visibility/milestones;
- five-creature roster decisions;
- catch/release pressure;
- candy economy;
- difficulty curve;
- trainer ladder;
- boss preparation;
- gathering → crafting usefulness;
- camping/recovery;
- riding;
- Fly;
- realm relic powers;
- whether stronger creatures/gear materially change play.

A player should regularly understand why they are stronger now than an hour ago.

## C4 — Is it fun minute-to-minute?
Use real route/play evidence for:
- combat frequency;
- exploration payoff;
- traversal enjoyment;
- downtime;
- preparation pressure;
- discovery cadence;
- curiosity;
- creature attachment;
- encounter variety;
- boss payoff;
- multiplayer cooperation.

Distinguish **works** from **fun**. A technically correct 90-second empty walk is still a product failure.

## C5 — Does the world feel authored?
Look for:
- repeated procedural-looking tree/prop patterns;
- purposeless acreage;
- obvious region bands;
- dead routes;
- copy-pasted NPC clusters;
- repetitive trainer composition;
- landmarks that do not orient the player;
- settlements without believable purpose;
- content placed only to hit counts;
- environments that do not tell a story.

## C6 — Does it meet the visual bar?
Target statement:

> Tetherbound does not need Palworld's raw asset budget, but it must read as a cohesive commercial stylized game that can sit beside Valheim/Palworld without looking like a prototype.

Judge:
- composition;
- terrain/material quality;
- lighting;
- props;
- foliage layering;
- silhouettes;
- creature prominence;
- NPC differentiation;
- animation;
- VFX;
- UI legibility;
- world density;
- consistency across Meadows and Cloudreach;
- multiplayer scenes with multiple trainers/creatures.

Capture representative **real gameplay frames** across both biomes and use code-blind judges. Required questions:
1. Does this look like a finished commercial game or a prototype?
2. What are the three most visible things holding it back?
3. Is there an obvious reason to explore what is visible?
4. Does this region have a distinct identity?
5. Does the creature feel like the visual/emotional focus?
6. What comparable quality tier does this resemble?

Do not reduce this audit to a numeric score.

### Required output
Produce a concise prioritized repair plan, not a 300-item backlog:

- **P0:** game-breaking, progression-breaking, data-loss, severe multiplayer failure.
- **P1:** materially hurts fun, density, progression, visuals, performance or usability.
- **P2:** desirable polish that does not block the next biome.
- **DO NOT WORK:** low-value perfectionism, speculative refactors, tiny inconsistencies with no player impact.

Every P0/P1 must include:
- observed player-facing problem;
- exact evidence;
- likely owning system/files;
- acceptance criterion;
- whether it blocks Stormwood.

### Exit criteria
- audit evidence exists for both biomes;
- density tables contain actuals;
- visual judge evidence exists;
- solo + multiplayer critical paths were exercised;
- P0/P1 list is short, ranked and actionable;
- Stage D can execute without guessing.

---

# STAGE D — TWO-BIOME REPAIR PASS

**Owner:** Fable orchestrates; lower-tier agents implement bounded fixes.

**Input:** Stage C audit.

### Priority
1. all P0s;
2. P1s affecting chapter completion or multiplayer reliability;
3. P1 density/fun problems;
4. P1 visual problems with large screen impact;
5. P1 progression/balance problems;
6. only then high-return P2 items.

### Rules
- do not begin Stormwood while unresolved P0s remain;
- do not weaken an acceptance test to hide a product problem;
- use existing systems instead of duplicates;
- broad player impact outranks internal neatness;
- integrate continuously;
- preserve before/after evidence for visual/density fixes;
- stop grinding narrow P2 closure when the P0/P1 bar is met.

### Exit criteria
- P0 = zero open;
- every Stormwood-blocking P1 closed;
- remaining P1s explicitly accepted as non-blocking with evidence;
- Meadows + Cloudreach continuous paths still work;
- multiplayer remains playable.

Then proceed to Stage E.

---

# STAGE E — BUILD BIOME 3: THE STORMWOOD

**Owner:** Codex orchestration.

**Start here:** `docs/biomes/stormwood/00_CODEX_START_HERE.md`

**Detailed directive:** `docs/biomes/stormwood/BUILD_STORMWOOD_TO_COMPLETION.md`

**Execution policy:** `docs/biomes/stormwood/EXECUTION_PROGRESS_POLICY.md`

### Required behavior
Stormwood must be built against the multiplayer-capable architecture. Do not create single-player-only Surge, arch, pickup, encounter, boss, progression, camp or save systems that need a second retrofit.

Reproduce or exceed the useful broad-build performance Codex achieved on Cloudreach: get the world, chapter, systems and content materially built before allowing the session to be consumed by narrow tail work.

The primary orchestration run should reach at least the same broad **80–85%-style material state** Cloudreach reached before its diminishing-return grind. This is a progress benchmark, not a completion declaration.

Use the two-no-yield-attempt rule from the Stormwood execution policy. Continue while meaningful player-facing progress remains strong; hand narrow late-tail work to a fresh session when progress flattens.

### Exit criteria
Use the full Stormwood directive. Product-level requirements include:
- natural Cloudreach → Stormwood transition;
- six regions materially exist;
- Surge changes play;
- Stormglass Arches work;
- Hollow Crown works;
- rod-station progression works;
- content density is real;
- story reaches Dynamo;
- finale and captive legendary sequence work with placeholders if necessary;
- Spark/relic aftermath works;
- Water is clearly next;
- save/load works;
- multiplayer works throughout;
- major visuals read as intentional/commercial;
- no critical path requires debug intervention.

Close the remaining high-value tail in focused passes rather than forcing one giant session to consume itself.

---

# STAGE F — OWNER THREE-BIOME PLAYTEST

**Owner:** human owner.

**Goal:** play the integrated game from the beginning through the end of Stormwood and record what actually feels broken, boring, confusing or weak.

This occurs before designing Biome 4 so three chapters of repetition can expose systemic problems.

### Playtest mode
Do at least:
- one primarily solo run;
- one meaningful multiplayer run with at least one friend if available;
- controller-first on target hardware where practical.

### Capture findings by category
- progression blocker;
- bug/softlock;
- multiplayer issue;
- combat/balance;
- creature/catching;
- bond/leveling;
- exploration/density;
- crafting/building;
- camping/recovery;
- traversal/riding/Fly/arches;
- story/dialogue;
- UI/controller;
- visuals;
- performance;
- boring/nothing-to-do moments;
- great moments worth protecting.

Do not turn the playtest into a developer checklist while playing. Record actual player experience first.

### Required output
An owner playtest report with:
- chronological notes;
- P0/P1/P2 classification afterward;
- screenshots/clips where useful;
- reproduction steps when known;
- strongest positive moments later work must preserve.

### Exit criteria
The playtest report is complete enough for Stage G to execute without guessing.

---

# STAGE G — THREE-BIOME REPAIR AND SYSTEM HARDENING

**Owner:** Fable orchestrates.

**Input:** owner Stage F report + automated regressions.

### Goal
Repair the game the owner actually played before designing Biome 4. Prefer systemic fixes once rather than biome-by-biome patches.

Examples:
- if all three biomes feel empty late, fix density methodology;
- if progression becomes invisible after level 30, fix progression UX globally;
- if multiplayer catch ownership is confusing, fix the shared system;
- if final regions perform badly, fix visibility/streaming strategy;
- if traversal bypasses gates, fix authority/gating globally.

### Exit criteria
- all owner-playtest P0s closed;
- high-impact P1s closed or explicitly accepted;
- continuous three-biome run works;
- multiplayer remains functional across all three;
- no known systemic flaw should obviously be copied into Biome 4.

Only then begin Stage H.

---

# STAGE H — DESIGN AND BUILD BIOME 4

**Owner:** owner/creative direction first, then Codex/Fable implementation.

Current direction is the **Water biome**, but final traversal mechanic, story, roster, reward and world structure should be designed after the three-biome playtest so the design incorporates what the game actually taught us.

### Design gate before code
Create a Biome 4 directive at least as complete as Stormwood, including:
- concept/visual board;
- biome fantasy/tone;
- chapter story;
- entry from Stormwood;
- coherent regional layout;
- signature traversal/gameplay mechanic;
- required gate/destination proving the mechanic matters;
- NPC cast;
- trainer ladder;
- encounter structure;
- resource/crafting tier;
- item density minimums;
- camps;
- side chains;
- boss/finale;
- captive legendary if canon still requires it;
- unique realm relic/power;
- Biome 4 → Biome 5 handoff;
- multiplayer behavior;
- save/state requirements;
- visual/performance bar;
- tests/evidence;
- anti-grind execution policy learned from Cloudreach/Stormwood.

### Build requirements
- multiplayer-native from first implementation;
- broad playable chapter before tail polish;
- density at least equal to accepted prior-biome bars;
- new mechanic must change player decisions, not decorate traversal;
- preserve shared systems rather than fork biome-specific substitutes;
- integrate continuously.

### Exit criteria
Biome 4 is materially complete, playable end-to-end, multiplayer-capable, visually coherent, content-dense and stable enough to enter Beta Ready.

---

# STAGE I — FOUR-BIOME BETA READY GATE

**Owner:** Fable senior orchestration + owner final playtest.

This is a release-readiness pass, not another content expansion.

## I1 — Continuous completion
Prove a fresh player can complete:

**opening → Meadows → Cloudreach → Stormwood → Biome 4**

without developer intervention, both solo and on a representative multiplayer path.

## I2 — Multiplayer reliability
Stress:
- 1/2/3/4 players;
- join/leave/reconnect;
- long sessions;
- realm transitions;
- players in different biomes;
- boss fights;
- simultaneous building/gathering;
- catches;
- death/revive;
- sleeping;
- storage transactions;
- save/reload;
- host quit/restart.

Item duplication, save corruption, progression rollback and unrecoverable desync are beta blockers.

## I3 — New-player onboarding
A player unfamiliar with the project must understand:
- movement;
- creature control;
- catching;
- five-creature limit;
- bond/leveling;
- gathering;
- crafting;
- building;
- recovery/camping;
- trainer progression;
- maps/tasks;
- realm relics;
- multiplayer joining/invites.

No external instructions required.

## I4 — Performance
Validate target hardware and representative PCs in worst-case areas:
- dense Meadows;
- Cloudreach long sightlines/Fly;
- Stormwood canopy/Surge;
- Biome 4's most expensive scene;
- four players + four deployed creatures;
- boss VFX;
- built structures.

## I5 — Visual consistency
Final blind visual audit across all four biomes.

Required bar:

> cohesive commercial stylized game; no biome or major UI surface reads like a prototype relative to the others.

Fix major visual outliers. Do not chase tiny asset imperfections that do not affect beta perception.

## I6 — Content/density consistency
Run one density census across all four biomes comparing:
- encounters/km;
- trainers/km;
- pickups/km;
- harvest/resources/km;
- meaningful detours;
- landmarks;
- side content;
- worst dead-travel interval.

Later biomes must not become thinner.

## I7 — Progression/balance
Check end-to-end:
- levels;
- candy;
- bond;
- resources;
- crafting;
- potions/revives;
- catch rates;
- trainer difficulty;
- bosses;
- relic powers;
- multiplayer scaling.

Avoid trivialization and grind.

## I8 — Save/migration safety
- old saves migrate;
- solo saves remain valid;
- multiplayer world/player saves separate correctly;
- no destructive migration path;
- safe behavior for corrupt/incompatible saves.

## I9 — Release hygiene
- no debug-only progression dependency;
- no credentials/secrets;
- no unnecessary reference assets in export;
- correct version/build metadata;
- crash/error logging path;
- beta feedback instructions;
- known-issues list;
- release build tested, not editor-only.

### Beta Ready exit criteria
- no open P0s;
- multiplayer genuinely usable by four friends;
- complete four-biome path works;
- saves trustworthy;
- performance acceptable;
- content density consistent;
- progression understandable;
- representative visuals meet the commercial stylized bar;
- remaining P1/P2 issues documented and acceptable for beta.

---

# STAGE J — FOUR-BIOME BETA

Launch as a **four-biome beta**, not as a claim that the full eight-biome game is finished.

### Beta goals
Learn from real players:
- where they quit;
- what they misunderstand;
- which creatures they care about;
- whether the five-creature limit creates meaningful decisions;
- whether multiplayer is fun/reliable;
- whether exploration pays off;
- whether building/camping matter;
- which bosses are memorable;
- where pacing drags;
- what breaks across different hardware/networks.

### Feedback categories
- reliability;
- progression;
- fun/pacing;
- multiplayer;
- balance;
- visuals;
- usability;
- requested features.

Do not implement every feature request immediately. Fix reliability and repeated high-impact friction first.

---

# STAGES K–N — BIOMES 5–8 AFTER BETA

For each remaining biome:

1. review beta/player evidence;
2. decide what system/theme the biome should add;
3. create a full build directive before code;
4. create concept/reference art;
5. build multiplayer-native;
6. enforce accepted density/progression bars;
7. use the anti-grind execution policy;
8. run focused internal playtest;
9. repair high-impact findings;
10. release the biome to beta;
11. observe player behavior before designing too far ahead.

Do not lock all remaining biomes so rigidly that beta evidence cannot change them.

---

# ROADMAP QUALITY RULES

### Player-facing truth outranks code existence
A system is not done because a class, JSON file or test exists.

### Broad useful progress before late-tail grind
The Cloudreach lesson applies to every major orchestration pass. Push hard while the game is materially advancing. When a narrow tail stops yielding progress, preserve evidence and move it to a fresh focused pass rather than consuming the entire session.

### Human playtest is a formal source of truth
The owner's observed experience may override assumptions from automated evidence. Capture it precisely and turn it into bounded acceptance criteria.

### Visual bar is commercial coherence, not impossible asset parity
Valheim and Palworld are comparison references for whether Tetherbound feels like a real cohesive game. Do not waste time chasing raw AAA asset fidelity when composition, materials, silhouettes, animation, VFX, density and UI are the actual limiting factors.

### Do not copy systemic mistakes into more biomes
Audit and repair between expansion waves.

### Multiplayer is foundational after Stage B
All new gameplay/world systems after Stage B are multiplayer-native unless an owner directive explicitly says otherwise.

---

# CURRENT NEXT ACTION

When all currently in-flight Meadows/Cloudreach work has landed and `main` is stabilized:

> **Fable starts Stage B by reading `docs/MULTIPLAYER_DIRECTIVE.md` and executes it until Tetherbound is a playable Valheim-style 1–4 player co-op game.**

After multiplayer is proven, Fable does **not** start another biome. It moves directly to Stage C, the full two-biome product audit.

Update this section whenever the current stage changes.
