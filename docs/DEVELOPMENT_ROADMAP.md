# TETHERBOUND — DEVELOPMENT ROADMAP TO FOUR-BIOME BETA

**Status:** canonical living product-development roadmap.

**Purpose:** Own the execution sequence from the current two-biome build through multiplayer/art/fixes, Stormwood, Water, a single four-biome product audit and repair pass, and a four-biome beta. Update this document as each stage lands. A fresh Fable or Codex session should be able to read this file, identify the current stage, follow the linked directive, and continue without inventing a new master plan.

> **Core rule:** build → validate → repair → expand. Do not add another biome on top of unresolved systemic problems.

**Revision, 2026-09-06 (owner direction):** this roadmap is simplified from an
earlier ten-stage sequence. The previous plan gated Stormwood behind a
two-biome (Meadows + Cloudreach) audit/repair cycle, and gated Water behind a
separate three-biome (Meadows + Cloudreach + Stormwood) owner playtest/repair
cycle. Both intermediate gates are **removed**. The new sequence builds
Stormwood and Water back-to-back once current Meadows/Cloudreach work,
multiplayer and art land, then runs **one** product audit and **one** repair
pass across all four biomes before the Beta Ready gate. The audit's six
questions and the repair-pass discipline from the old two-biome gate are kept
and scaled up to four biomes rather than discarded. Stage letters below are
the current ones; do not cite the pre-2026-09-06 letters (they no longer
match this file).

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

| Stage | What it is | State |
|---|---|---|
| **0** | Current work: land Meadows + Cloudreach in flight, ship playable 1–4 player multiplayer, run the Meadows visual sweep, and land general game fixes. | In progress |
| **A** | Build Biome 3, the Stormwood. | Not started |
| **B** | Build Biome 4, the Water Archipelago. | Not started |
| **C** | Full four-biome product audit — six questions: does it work, is there enough to do, is progression satisfying, is it fun minute-to-minute, does the world feel authored, does it meet the visual bar. | Not started |
| **D** | Four-biome repair pass — fix Stage C's P0/P1 findings before any new content. | Not started |
| **E** | Four-biome Beta Ready gate. | Not started |
| **F** | Four-biome beta launch. | Not started |
| **G** | Biomes 5–8, one at a time, after beta, using the same build → audit → repair discipline. | Not started |

Do not skip a stage because later content is easier or more exciting. Do not
reintroduce an intermediate audit/playtest gate between Stormwood and Water
without a new owner directive — that is the specific thing the 2026-09-06
revision removed.

---

# STAGE 0 — LAND CURRENT WORK, SHIP MULTIPLAYER, FIX THE GAME

**Owner:** Fable orchestration / integration.

**Goal:** reach one stable, playable-multiplayer, visually improved baseline
across Meadows and Cloudreach before Stormwood begins. This stage folds
together three concurrent workstreams that were previously separate stages:
landing in-flight content, shipping multiplayer, and the Meadows visual
sweep, plus ordinary game fixes as they surface.

### Workstream 1 — land in-flight Meadows/Cloudreach work

#### Read
- `docs/FINISH_THE_MEADOWS.md`
- `docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md`
- `docs/biomes/cloudreach/BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md`
- `docs/CURRENT_STATE.md`
- recent open PRs/branches and evidence reports

#### Required work
- inspect every in-flight branch/PR;
- merge completed verified work;
- preserve incomplete but useful branches with exact handoff notes;
- resolve integration conflicts in favor of latest owner directives and player-facing behavior;
- run proportionate integrated smokes;
- update `docs/CURRENT_STATE.md` to describe what is actually on `main`;
- record severe known blockers honestly rather than carrying hidden assumptions forward.

### Workstream 2 — playable 1–4 player multiplayer

> **Naming note:** the multiplayer execution plan and `docs/CURRENT_STATE.md`
> use an older internal numbering ("Stage A" for landing in-flight work,
> "Stage B" for multiplayer, with waves under it) that predates this file's
> 2026-09-06 renumbering. That internal numbering is unrelated to this
> roadmap's stage letters; the multiplayer work it describes is entirely
> inside this roadmap's **Stage 0**. Do not confuse the execution plan's own
> "Stage B" with this roadmap's Stage B (Water).

**Detailed directive:** `docs/MULTIPLAYER_DIRECTIVE.md`

**Execution plan:** `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` —
the thirteen architecture decisions, the model-tier rule (Fable / Opus /
Sonnet / Haiku), eight waves of lanes with owned files and proving tests, and
the item-to-smoke acceptance table. `docs/CURRENT_STATE.md` carries the live
wave-by-wave status; read it for what has already landed rather than trusting
a wave number written here.

This is not an architecture-only pass. The required outcome is a real
**Valheim-style 1–4 player co-op game**.

#### Product target
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

#### Minimum implementation scope
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

#### Evidence bar
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

#### Anti-grind rule
Drive to broad playable multiplayer first. Do not spend the whole pass perfecting one edge case while basic co-op is absent elsewhere. After two serious approaches to one narrow issue produce neither material improvement nor new causal evidence, change strategy or hand it to a fresh focused lane.

### Workstream 3 — Meadows visual sweep

**Directive:** `docs/owner/MEADOWS_VISUAL_SWEEP_GOAL_2026-09-06.md` — grass,
trees (including evaluating the Sakura tree asset as a sparing hero accent),
bushes, Grandpa's Village composition, the Burrow Warrens, the Meadows
stronghold, and other key route locations, judged against Valheim Meadows and
Palworld early-game quality with the repo's blind visual-judge workflow.

This workstream ends at **CANDIDATE READY FOR EXTERNAL VISUAL REVIEW — DO NOT
MERGE**, per that directive's own success bar; it does not itself close
Stage 0, but Stage 0 should not close while it is still open.

### Workstream 4 — general game fixes

Ordinary bug fixes and small player-facing corrections surfaced by testing,
CI or owner playtests during this stage, scoped and landed the same way any
other bounded task is: branch, fix, test, evidence, PR, verify on `main`. Do
not let this workstream become a dumping ground for scope that belongs in
Stage C's audit or a later biome's directive.

### Exit criteria
- no valuable completed work is stranded;
- `main` imports and plays;
- Meadows and Cloudreach are both reachable to the extent currently implemented;
- an outside tester can launch a host world, invite three friends, move, deploy creatures, fight, gather, build, progress, save and reconnect without developer intervention;
- the Meadows visual sweep has reached its own candidate-ready state;
- known severe blockers are explicitly listed rather than carried silently forward.

Then move to Stage A.

---

# STAGE A — BUILD BIOME 3: THE STORMWOOD

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

Then move directly to Stage B. There is no intermediate three-biome
playtest/repair gate here — see the 2026-09-06 revision note above.

---

# STAGE B — BUILD BIOME 4: THE WATER ARCHIPELAGO

**Owner:** owner/creative direction first, then Codex/Fable implementation.

**Start here:** `docs/biomes/water/00_START_HERE.md`

**Design directive:** `docs/biomes/water/TETHERBOUND_BIOME4_WATER_ARCHIPELAGO_DESIGN_DIRECTIVE.md`

The design directive locks the biome fantasy: an inhabited island-chain
archipelago built around human swimming and drowning pressure, NPC-controlled
dock-gated progression, a midpoint amphibious Water Dragon Alpha that unlocks
the Swim Saddle regardless of catch outcome, expanding post-Alpha crossings
with currents and water combat, black glowing Skill Candy I/II/III, escalating
Team Tether presence, and a finale stronghold hidden inside a mountain behind
a waterfall. Read it in full before any design or implementation work; do not
simplify or replace it.

### Design gate before code
The design directive's §23 lists the later design deliverables required
before implementation, at the same depth Stormwood received in
`BUILD_STORMWOOD_TO_COMPLETION.md`:
- Water world/island map and dock progression;
- full Water creature roster;
- Water Dragon Alpha production board with full Meshy orthographic views;
- Swim Saddle production board;
- Skill Candy I/II/III board;
- Water NPC/Team Tether visual additions;
- final-island/waterfall stronghold concept board;
- Water legendary and Warden/finale design;
- numeric swimming/skills/currents tuning spec;
- multiplayer swimming authority/state spec.

Produce these — and a Stormwood-equivalent `BUILD_WATER_ARCHIPELAGO_TO_COMPLETION.md`
execution directive — before Codex begins building.

### Build requirements
- multiplayer-native from first implementation (replicated swimming, drowning
  state, mounted swimmers, rider/mount sync, water combat transitions, dock/world
  authority, Alpha state, Swim Stone unlocks, Skill Candy ownership, save/reconnect
  across islands);
- broad playable chapter before tail polish, using the same front-load
  discipline and two-no-yield-attempt rule proven on Cloudreach and Stormwood;
- density at least equal to the accepted prior-biome bars;
- preserve existing hard rules: the human never fights, creature combat is
  directly piloted, only five creatures may be owned, catching is unavailable
  on trainer-owned creatures;
- preserve shared systems rather than fork biome-specific substitutes;
- integrate continuously.

### Exit criteria
Use the design directive's §22 completion bar in full. Water is materially
complete, playable end-to-end, multiplayer-capable, visually coherent,
content-dense and stable enough to enter Stage C.

Then move to Stage C.

---

# STAGE C — FULL FOUR-BIOME PRODUCT AUDIT

**Owner:** Fable.

**Goal:** assess Meadows + Cloudreach + Stormwood + Water as a product, not as
a codebase. This is the single audit gate in this roadmap; there is no
separate two-biome or three-biome audit before it.

This is a formal quality gate. Do not begin with another architecture inventory. Inspect real runtime behavior, route density, progression, content, multiplayer behavior and representative visuals across all four biomes.

## C1 — Does it work?
Prove a new player can progress from the opening through the end of Water without:
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
- whether later biomes are thinner than earlier ones.

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
- swimming and the Swim Saddle;
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
- consistency across all four biomes;
- multiplayer scenes with multiple trainers/creatures.

Capture representative **real gameplay frames** across all four biomes and use code-blind judges. Required questions:
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
- **P2:** desirable polish that does not block beta.
- **DO NOT WORK:** low-value perfectionism, speculative refactors, tiny inconsistencies with no player impact.

Every P0/P1 must include:
- observed player-facing problem;
- exact evidence;
- likely owning system/files;
- acceptance criterion;
- whether it blocks the Beta Ready gate.

### Exit criteria
- audit evidence exists for all four biomes;
- density tables contain actuals;
- visual judge evidence exists;
- solo + multiplayer critical paths were exercised;
- P0/P1 list is short, ranked and actionable;
- Stage D can execute without guessing.

---

# STAGE D — FOUR-BIOME REPAIR PASS

**Owner:** Fable orchestrates; lower-tier agents implement bounded fixes.

**Input:** Stage C audit.

**Rule:** fix Stage C's P0/P1 findings before any new content — no Biomes 5–8
work starts, and no scope creep into new features, until this stage's exit
criteria are met.

### Priority
1. all P0s;
2. P1s affecting chapter completion or multiplayer reliability;
3. P1 density/fun problems;
4. P1 visual problems with large screen impact;
5. P1 progression/balance problems;
6. only then high-return P2 items.

### Rules
- do not begin the Beta Ready gate while unresolved P0s remain;
- do not weaken an acceptance test to hide a product problem;
- use existing systems instead of duplicates;
- broad player impact outranks internal neatness;
- integrate continuously;
- preserve before/after evidence for visual/density fixes;
- stop grinding narrow P2 closure when the P0/P1 bar is met.

### Exit criteria
- P0 = zero open;
- every Beta-blocking P1 closed;
- remaining P1s explicitly accepted as non-blocking with evidence;
- all four biomes' continuous paths still work;
- multiplayer remains playable.

Then proceed to Stage E.

---

# STAGE E — FOUR-BIOME BETA READY GATE

**Owner:** Fable senior orchestration + owner final playtest.

This is a release-readiness pass, not another content expansion.

## E1 — Continuous completion
Prove a fresh player can complete:

**opening → Meadows → Cloudreach → Stormwood → Water**

without developer intervention, both solo and on a representative multiplayer path.

## E2 — Multiplayer reliability
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

## E3 — New-player onboarding
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
- swimming/riding/Fly;
- multiplayer joining/invites.

No external instructions required.

## E4 — Performance
Validate target hardware and representative PCs in worst-case areas:
- dense Meadows;
- Cloudreach long sightlines/Fly;
- Stormwood canopy/Surge;
- Water's most expensive crossing/scene;
- four players + four deployed creatures;
- boss VFX;
- built structures.

## E5 — Visual consistency
Final blind visual audit across all four biomes.

Required bar:

> cohesive commercial stylized game; no biome or major UI surface reads like a prototype relative to the others.

Fix major visual outliers. Do not chase tiny asset imperfections that do not affect beta perception.

## E6 — Content/density consistency
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

## E7 — Progression/balance
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
- swimming/Skill Candy economy;
- multiplayer scaling.

Avoid trivialization and grind.

## E8 — Save/migration safety
- old saves migrate;
- solo saves remain valid;
- multiplayer world/player saves separate correctly;
- no destructive migration path;
- safe behavior for corrupt/incompatible saves.

## E9 — Release hygiene
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

# STAGE F — FOUR-BIOME BETA

Launch as a **four-biome beta**, not as a claim that the full eight-biome game is finished.

### Beta goals
Learn from real players:
- where they quit;
- what they misunderstand;
- which creatures they care about;
- whether the five-creature limit creates meaningful decisions;
- whether multiplayer is fun/reliable;
- whether exploration pays off;
- whether building/camping/swimming matter;
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

# STAGE G — BIOMES 5–8 AFTER BETA

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

### One audit/repair cycle across all four biomes, not one per biome
The 2026-09-06 revision deliberately removed the intermediate two-biome and
three-biome audit/playtest gates. Do not reintroduce a per-biome audit gate
between Stages A and B without a new owner directive — the point of the
simplification is to build Stormwood and Water back-to-back and audit once.

### Human playtest is a formal source of truth
The owner's observed experience may override assumptions from automated evidence. Capture it precisely and turn it into bounded acceptance criteria.

### Visual bar is commercial coherence, not impossible asset parity
Valheim and Palworld are comparison references for whether Tetherbound feels like a real cohesive game. Do not waste time chasing raw AAA asset fidelity when composition, materials, silhouettes, animation, VFX, density and UI are the actual limiting factors.

### Do not copy systemic mistakes into more biomes
Stage C/D exist precisely to catch this once, across all four biomes, before Biomes 5–8.

### Multiplayer is foundational after Stage 0
All new gameplay/world systems after Stage 0 are multiplayer-native unless an owner directive explicitly says otherwise.

---

# CURRENT NEXT ACTION

Tetherbound is in **Stage 0**: land in-flight Meadows/Cloudreach work, ship
playable 1–4 player multiplayer (`docs/MULTIPLAYER_DIRECTIVE.md`,
`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md`, live status in
`docs/CURRENT_STATE.md`), run the Meadows visual sweep
(`docs/owner/MEADOWS_VISUAL_SWEEP_GOAL_2026-09-06.md`), and land general game
fixes as they surface.

> **When Stage 0's exit criteria are met, Codex starts Stage A (Stormwood) at
> `docs/biomes/stormwood/00_CODEX_START_HERE.md`. Immediately after Stormwood
> is built, move directly to Stage B (Water) at
> `docs/biomes/water/00_START_HERE.md` — do not insert an intermediate
> playtest/audit gate. Only after Water is built does Stage C run the single
> four-biome product audit.**

Update this section whenever the current stage changes.
