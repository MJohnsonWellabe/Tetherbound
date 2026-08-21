# Weekend Meadows Sprint — 2026-08-21 through 2026-08-23

**Status: ACTIVE temporary execution overlay.**

This file changes **priority, parallelization, model routing, and checkpoint cadence only**. It does **not** delete, weaken, or supersede the acceptance criteria in `ralph/ACTIVE_GAME_PLAN.md`, `ralph/ACTIVE_TASKS.md`, the newest owner playtests, detailed prompts, or `ralph/BACKLOG.md`.

The weekend objective is to turn the current Meadows build into a **continuously playable full chapter**, not merely to accumulate green child tasks.

## 0. Weekend model-routing policy — owner directive 2026-08-21

This directive supersedes older model-floor/model-suspension wording for the active weekend sprint where it conflicts.

- **Opus is the coordinator/orchestrator.** Use Opus for prioritization, decomposition, dependency/file-ownership decisions, integration judgment, gate/evidence decisions, and deciding when a simpler implementation is appropriate. Opus may also take unusually difficult architecture/integration work when Sonnet is not sufficient, but should not become the default implementation lane and disappear into routine coding.
- **Sonnet is the default implementation worker.** Use Sonnet for bounded engineering/authoring tasks with clear acceptance criteria, normally sized for roughly 30–90 minutes.
- **Fable is reserved for independent blind visual review only.** Use Fable only for the actual visual judgment/review step when a milestone requires visual-judge evidence. Fable must not produce, stage, render, capture, select, edit, or modify the screenshots/images/evidence it is judging. Production/capture belongs to Sonnet/Opus lanes or deterministic tooling; Fable receives the resulting evidence plus the relevant art/acceptance criteria and returns an independent pass/fail/revision judgment.
- Do not use Fable for coordination, routine implementation, screenshot production, camera staging, or visual fixes during this sprint.
- Do not let the same Fable review context author the evidence and grade it. Preserve reviewer independence.

## 1. Sunday-night definition of success

A new player using a controller on the ROG Ally should be able to complete this continuous chapter path:

**Title → Grandpa → starter → naming → first wild fight/catch → village → tournament preparation → tournament win → Lower Meadows / pond route → South Bridge → quarry → Burrow Warrens → river / Tether Relay → Upper Meadows → Stronghold Approach → Meadows Hall / Warden → legendary / chapter resolution.**

The chapter is weekend-playable only if that route is:

- understandable without external instructions;
- controllable on the ROG Ally;
- performant enough to play rather than endure;
- free of freezes, dead input, impossible camera states, broken save/load, and progression blockers;
- populated with meaningful creatures, trainers, gatherables, landmarks, objectives, and reasons to stop rather than long bare walks;
- visually coherent enough that villages, roads, buildings, water, lighting, signs, and regional composition do not read as obviously broken;
- able to survive save/reload and resume normal play;
- able to complete combat without fighters phasing outside reachable arenas;
- able to complete the chapter finale.

This is the production target. The existing gates remain the evidence/checkpoint system used to prove it.

## 2. Do not lose current owner requirements

Before selecting work, read the newest `ralph/OWNER_PLAYTEST_*.md`, `ralph/ACTIVE_TASKS.md`, and current `main`.

The 2026-08-21 ROG Ally owner playtest is current evidence and **reopens older supposedly-fixed items when it conflicts with prior tests/DONE records**.

Current owner findings are not optional polish merely because this sprint is time-boxed. In particular, the current Gate A owner blockers include target-hardware lag, controller ownership/input leakage, Settings/Build/Map navigation, first-village-trainer combat camera, load-game resume, gathering/axe presentation, build rotate/scale/doors/roof correctness, party count/cycling, lighting failures, village/pond spatial errors, water hazard behavior, and related real-player path failures documented in the repo.

The owner also reported later-area combat phasing in Stronghold/Burrow Warrens and dead/bare travel between village/pond. Preserve those requirements in the appropriate gate/package; do not drop them to make the schedule look green.

## 3. Weekend priority classes

Every discovered issue must be classified before substantial work begins.

### SHIP BLOCKER
Fix immediately or dispatch immediately. Examples:

- cannot launch/start/load/resume;
- freeze/crash/dead controls;
- controller input fires in the wrong context;
- impossible or broken combat/camera;
- progression/objective cannot advance;
- save/load corrupts or strands the player;
- ROG performance is intolerable;
- chapter route is physically blocked;
- a required region/encounter/finale cannot be completed;
- long empty required travel is severe enough to make the route feel unfinished.

### QUALITY BLOCKER
Playable, but bad enough that the chapter should not be shown as a finished weekend build. Examples:

- map is technically functional but unusable;
- building works but dimensions/doors/roof make a normal house nonsensical;
- objective direction is so weak that normal players are lost;
- village/world composition reads obviously wrong;
- lighting enters a broken washed-out state;
- key HUD/controller prompts are illegible on handheld;
- gathering action has no credible hold/swing/feedback.

### POLISH
Noticeable but does not block the weekend playable chapter. Record it in the ledger/notes and move on unless all higher classes are under control.

Do not spend an hour perfecting POLISH while a SHIP BLOCKER is waiting.

## 4. Coordinator operating model

Use **one Opus coordinator plus 4–5 bounded Sonnet implementation lanes** when enough independent work exists.

The Opus coordinator should primarily:

- inspect `main`, CI, owner evidence, and active package state;
- maintain the chapter critical path;
- classify issues SHIP BLOCKER / QUALITY BLOCKER / POLISH;
- define shared contracts before parallel implementation;
- dispatch bounded Sonnet workers;
- keep file ownership non-overlapping;
- integrate frequently;
- run representative player-path evidence;
- dispatch Fable only for independent blind visual review after visual evidence has already been produced;
- refill worker capacity as soon as a lane completes;
- prevent one lane from expanding into an entire gate.

A Sonnet worker should usually own a 30–90 minute coherent task. If it exceeds ~90 minutes without a clear finish, checkpoint useful work, report the blocker, and let the Opus coordinator decompose it.

## 5. Recommended initial lanes

These are domains, not permanent agents. Refill/reshape them based on the current highest-impact blockers.

1. **ROG / input / UI / performance**
   - controller ownership and overlapping bindings;
   - Settings/teleport scrolling;
   - Build/Satchel/hotbar context suppression;
   - map controller usability;
   - ROG frame-time/performance.

2. **Core gameplay reliability**
   - title/start/load/save/resume;
   - combat camera and teardown;
   - arena containment/phasing;
   - party membership/count/cycling;
   - progression blockers.

3. **Building / gathering / care**
   - axe hold/swing/hit feedback;
   - build rotate;
   - modular floor/wall/door/roof dimensions;
   - usable doors;
   - free-build/free-crafting consistency;
   - rest/care reliability.

4. **Opening / tournament / objective flow**
   - Grandpa/start sequence;
   - explicit next-action guidance;
   - tournament objective/readiness/opponents/reward;
   - first-session pacing;
   - clear handoff toward South Bridge / Lower Meadows.

5. **World / content / regional route**
   - village spatial logic;
   - pond cleanup and water hazard;
   - village↔pond/Lower Meadows activity density;
   - creatures/trainers/resources/landmarks/sign placement;
   - region-by-region dead travel and obvious world-composition gaps.

Do not force these lane boundaries when file conflicts make a different split safer.

## 6. Gate sequencing for this sprint

The gate acceptance order remains A → B → C → D1–D5 → E → F, but **implementation does not have to be fully serial**.

### While Gate A is still open
Gate A SHIP BLOCKERS stay on the critical path and must be fixed before Gate A is declared passed.

However, independent workers may safely begin later-package work when it does not consume the same files/people/CI bandwidth needed for Gate A blockers. Examples include opening/tournament content, ecology maps, regional population, or world authoring with clean ownership.

### Gate B + foundational Gate C
Once Gate A is close enough that its remaining work is bounded, Gate B remains the blocking acceptance path while foundational Gate C work may run in parallel:

- team progression curve;
- reward/resource economy contract;
- trainer journey;
- wild ecology/habitat plan;
- expedition/rest rhythm;
- five-creature pressure/bond;
- chapter objective-chain contract.

Do not prematurely finalize tuning that Gate B's real first-session evidence is expected to inform.

### D1–D5 fan-out
Once shared Gate C contracts are stable enough, regional implementation for D1–D5 may run in parallel with explicit ownership and integration contracts.

Regional lanes must not independently invent contradictory progression, rewards, spawn rules, objective sequencing, or shared-route geometry.

The coordinator owns shared contracts first; regional lanes own bounded authoring/implementation slices.

### E and F
Gate E integrates the Stronghold chapter finale.

Gate F remains the final chapter-wide 3–4 hour integration/pacing/performance pass and cannot be replaced by green regional branches.

## 7. Simplify to ship when appropriate

This weekend, prefer the **simplest reliable implementation that produces the documented player experience** over a generalized framework that risks the deadline.

Allowed examples when architecture remains safe:

- explicit authored objective markers instead of inventing a generalized navigation system;
- straightforward combat containment boundaries instead of a complex arena abstraction;
- simplified map controls that are clear and reliable;
- reduced expensive visual settings on ROG via sensible quality/performance defaults rather than global world stripping;
- direct tournament readiness logic using the existing authoritative progression state rather than a broad new rule engine.

Do not use “simplify” as permission to remove required chapter beats or silently lower the owner-defined experience.

## 8. Integrated player-path proof is mandatory

Isolated tests are not enough for player-facing completion.

For controller, menus, camera, Build, maps, hotbar/Satchel, party cycling, lighting, performance, objective guidance, save/load, and chapter progression, validate the representative production path with competing systems active.

Fresh owner reproduction outranks old green tests.

Treat input ownership collisions as systemic architecture defects, not a collection of button-specific exceptions.

For visual milestones, Sonnet/Opus/tooling produces the capture. Only after the evidence is fixed and complete should Fable receive it for blind judgment. If Fable requests revisions, return the revision work to Sonnet/Opus; then give Fable newly produced evidence for another independent review.

## 9. Checkpoint cadence

Do not disappear for 8–10 hours before producing something worth playing.

Aim for a playable integrated checkpoint every **2–4 hours** of active coordinated work, or after a major chapter boundary becomes playable.

At each checkpoint record briefly:

- remote `main` SHA;
- required CI state;
- current highest SHIP BLOCKERS;
- what continuous player path now works;
- what chapter boundary is next;
- ROG/target-hardware evidence available;
- active lanes and their scopes.

Do not spend large amounts of time writing status prose.

## 10. Suggested weekend milestones

These are planning targets, not permission to fake a gate pass.

### Friday night
- current `main` reconciled;
- Gate A hard reliability/input/load/performance blockers substantially reduced;
- multiple later-package lanes running safely where independent;
- first fresh-save path toward tournament materially improved.

### Saturday morning
- Grandpa → tournament path genuinely playable;
- opening objectives understandable;
- tournament works as a meaningful first milestone;
- shared progression/ecology contracts stabilizing.

### Saturday afternoon/evening
- Lower Meadows / pond route populated and worth traversing;
- South Bridge → Quarry/Warrens path playable;
- dead travel materially reduced;
- regional D work fanning out where contracts allow.

### Sunday morning
- River/Relay → Upper Meadows → Stronghold Approach playable;
- later combat containment/reliability verified;
- chapter finale integrated or actively converging.

### Sunday afternoon/evening
- full fresh-save Meadows run;
- fix remaining SHIP BLOCKERS first, then QUALITY BLOCKERS;
- tune pacing, dead travel, progression, rewards, visual composition, and ROG performance;
- leave POLISH recorded rather than risking the playable chapter.

## 11. Full-chapter acceptance run

The weekend is successful when a representative ROG/controller fresh-save session can complete the Meadows chapter end to end with no external instructions and no major blockers.

Record at minimum:

- title/start/load behavior;
- objective clarity at each chapter beat;
- first catch and team growth;
- tournament entry/win;
- building/gathering/rest usefulness;
- map/navigation usability;
- save/reload continuity;
- meaningful activity cadence / longest dead-walk interval;
- regional combat containment;
- ROG performance in village, pond/vegetation, building, combat, and later regions;
- Stronghold/Warden/legendary finale completion;
- any remaining QUALITY BLOCKERS/POLISH.

## 12. Coordinator stop rule

Do not stop because individual gates have many green commits.

Do not stop because the backlog is large.

Do not stop to ask the owner routine engineering questions that can be answered from repo evidence, code, tests, or reversible implementation choices.

Keep expanding the boundary of the Meadows that is genuinely playable.

The weekend objective is **one full playable chapter by Sunday night**, while preserving all owner requirements and the canonical gate acceptance system.