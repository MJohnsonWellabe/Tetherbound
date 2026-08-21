# Coordinated Ralph run — current operating manual

Use this when one Claude/Ralph coordinator owns the queue and launches implementation lanes.

The old flat-backlog operating model is superseded for current Meadows work. **Gameplay gates in `ralph/ACTIVE_GAME_PLAN.md` determine priority.**

## 1. Bootstrap

Read, in order:

1. `CLAUDE.md`
2. `ralph/START_HERE.md`
3. `docs/TETHERBOUND_GAME_VISION.md`
4. `ralph/ACTIVE_GAME_PLAN.md`
5. `ralph/ACTIVE_TASKS.md`
6. newest `ralph/OWNER_PLAYTEST_*.md` first, then older owner playtests only as needed
7. `ralph/PROMPT_COMPATIBILITY_MAP.md`
8. `ralph/conventions.md`
9. targeted backlog/DONE history for the current gate only
10. relevant detailed prompts/spec/code

Do not spend startup context reading the full historical backlog, DONE archive, or every prompt.

## 2. First action: reconcile the active gate

Before launching lanes, compare the current gate against actual `main`.

For every current child:

- verify whether it already landed;
- reproduce newer owner-reported failures even when old DONE history says “fixed”;
- identify overlapping prompts through the compatibility map;
- mark evidence-backed already-fixed work as verification, not a rewrite target;
- identify file ownership/conflicts before dispatch.

The first active gate is currently **Gate A — Trustworthy core verbs**. Use `ralph/ACTIVE_TASKS.md` as the compact reconciliation checklist.

## 3. Priority inside a gate

Prefer work in this order:

1. freezes, crashes, data loss, progression blockers;
2. broken core verbs/input state;
3. save/load and session lifecycle;
4. unclear or broken objective/gate;
5. core construction/gather/catch/care friction;
6. dead traversal / missing encounter purpose;
7. progression/reward/difficulty problems;
8. creature attachment and five-slot pressure;
9. regional identity/content;
10. visual/UI/performance polish that does not block judging play.

A discovered prerequisite does **not** silently inherit the owner task’s priority. Give it a parallel lane when possible. Keep the owning package moving unless it truly cannot proceed.

## 4. Lane count and conflict control

Default to **3–5 implementation lanes**, not maximum fan-out.

The limiting factor is CI and merge/rebase throughput, not agent count.

Choose lanes by file ownership:

- two tasks in different domains may still conflict if they edit the same controller/config/UI files;
- two related tasks can run safely if they have explicit file boundaries and a shared contract;
- do not let two lanes independently invent the same regional layout, reward curve, objective sequence, spawn map, or progression contract.

The coordinator owns the contract first, then gives lanes non-overlapping implementation slices.

## 5. Every lane brief must include

- repository and `main` as source revision;
- current gameplay gate/package;
- owning prompt filename;
- exact child prompt/task;
- player-visible outcome;
- complete evidence segment that will eventually judge the package;
- file exclusion list / files held by other lanes;
- newer owner decisions that supersede old wording;
- known relevant CI state;
- instruction to inspect current `main` and accept evidence-backed already-fixed outcomes;
- instruction not to edit central bookkeeping unless assigned;
- instruction to report useful findings to the shared notes channel;
- checkpoint/report expectation;
- next task(s) available inside the same gate if self-chaining is allowed.

Lanes follow `ralph/PROMPT.md`.

## 6. Notes are a coordination channel

Use `ralph/NOTES.md` on the status branch when available for findings that do not belong in a code diff:

- root causes;
- stale task assumptions;
- test blind spots;
- adjacent bugs;
- content gaps;
- file/architecture conflicts;
- evidence a task is already fixed.

The coordinator should read notes before assigning the next wave.

## 7. Leases

Under a coordinator, **do not use leases**. File exclusions and coordinator ownership prevent collisions.

Leave `ralph/STATUS.md` intact for uncoordinated firings. Do not write decorative/stale claims there during a coordinated run.

## 8. CI and landing

Implementation branches use `ralph/<task>` and normal CI/merge automation.

Rules:

- never call a branch shipped until its content is on `main`;
- read the failing **job**, not only the overall CI conclusion;
- do not weaken tests to clear unrelated failures;
- when multiple non-conflicting branches are green and the existing merge workflow would churn them one-by-one, bundling may be appropriate under the existing repo process;
- resolve bundle conflicts by understanding both changes, not choosing a side blindly;
- after integration, verify the actual tree on `main`.

The coordinator owns bookkeeping after shipment.

## 9. Child completion vs package completion

A child task may finish after its focused tests/evidence pass.

The gameplay package remains open.

When enough children land, run the **continuous evidence path** from `ralph/ACTIVE_GAME_PLAN.md`.

For the evidence run record:

### Player purpose
- what is the player trying to accomplish?
- what visible challenge are they preparing for?

### Team progression
- party/levels/condition at start and end;
- meaningful catch/switch/roster decision;
- whether progression occurred naturally or required grinding.

### World interaction
- wild encounters;
- trainers;
- resources;
- optional detours;
- rest/camp decisions;
- objective transitions.

### Empty travel
- longest interval without meaningful gameplay or visual pull;
- whether it is intentional breathing room or dead traversal.

### Reliability
- freezes/input loss;
- broken gates/collision;
- save/load failures;
- controller failures.

### Presentation
- regional identity;
- open vs lush composition;
- landmark readability;
- day/night usability;
- UI readability;
- target-hardware performance where applicable.

## 10. Evidence-gate rule

These are **autonomous evidence gates**, not owner approval stops.

If the segment fails:

1. identify the highest-impact player-facing cause;
2. open/focus the corresponding child lane;
3. land the fix;
4. replay the segment;
5. repeat until the written package criteria pass.

Then move automatically to the next gate.

Do not advance because all child prompts have commits.

### Integrated player-path evidence is mandatory

A unit test, isolated smoke test, focused harness, or green CI job is **necessary evidence, not sufficient player-facing proof** for systems whose correctness depends on real input ownership, modal focus, camera handoff, UI navigation, overlapping controls, world presentation, or target-hardware performance.

For controller, menus, camera, Build, maps, hotbar/satchel, party cycling, lighting/day-night, performance, and opening guidance, do not mark the owning gate requirement complete based only on isolated tests. Before the gate passes, exercise the feature in the representative continuous player path with the actual competing systems active. Where physical target hardware is unavailable, use the closest production/raw-controller harness that drives the real input-routing and scene stack rather than directly calling implementation methods.

Treat **input ownership collisions** as a systemic defect class. When one physical control affects two contexts at once (for example menu + hotbar, Build + party cycling, settings + world input), investigate the shared input/focus architecture and add cross-context regression coverage instead of accumulating one-off button guards.

Newest owner playtest evidence overrides older green tests or DONE records when they conflict. A fresh real-player reproduction reopens the requirement until the current production path is fixed and re-proven.

## 11. Active self-chain

The chapter order is:

**Gate A — trustworthy core verbs**
→ **Gate B — fresh start through tournament**
→ **Gate C — progression/reward/trainer/wild/rest backbone**
→ **D1 — Lower Meadows**
→ **D2 — Quarry/Warrens**
→ **D3 — River/Relay**
→ **D4 — Upper Meadows**
→ **D5 — Stronghold Approach**
→ **Gate E — Stronghold finale**
→ **Gate F — full 3–4 hour Meadows integration**.

Gate C system maps/curves can run in parallel with regional authoring after Gate B proves the first-session game, as long as contract/file ownership is clear.

## 12. Bookkeeping

`ralph/BACKLOG.md` stays the complete ledger.

- do not delete a task merely because a gameplay package groups it;
- close a child only when it is verified on `main`;
- record shipped work in `ralph/DONE.md` according to conventions;
- use targeted search rather than reading the giant DONE archive;
- preserve blocked/history records;
- update `ralph/ACTIVE_TASKS.md` when the active gate changes or when a current item’s verified state materially changes.

## 13. Stop condition

Do not stop because the queue looks empty.

The Meadows is done only when `70-MEADOWS-full-chapter-integration-playthrough.md` passes against `docs/TETHERBOUND_GAME_VISION.md`, including pacing, progression, purpose, reliability, regional quality, and target-hardware viability.

The objective of the coordinator is **not throughput of commits**. It is to keep expanding the boundary of the game that is genuinely enjoyable and production-ready until the whole Meadows chapter crosses it.
