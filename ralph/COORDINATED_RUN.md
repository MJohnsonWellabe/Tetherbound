# Coordinated Ralph run — current operating manual

Use this when one Claude/Ralph coordinator owns the queue and launches implementation lanes.

**Active temporary execution overlay:** `ralph/WEEKEND_MEADOWS_SPRINT_2026-08-21.md`.

The old flat-backlog operating model is superseded for current Meadows work. **Gameplay gates in `ralph/ACTIVE_GAME_PLAN.md` remain the canonical acceptance system; the weekend sprint overlay controls current priority, safe parallelization, and checkpoint cadence.**

## 1. Bootstrap

Read, in order:

1. `CLAUDE.md`
2. `ralph/START_HERE.md`
3. `docs/TETHERBOUND_GAME_VISION.md`
4. `ralph/WEEKEND_MEADOWS_SPRINT_2026-08-21.md`
5. `ralph/ACTIVE_GAME_PLAN.md`
6. `ralph/ACTIVE_TASKS.md`
7. newest `ralph/OWNER_PLAYTEST_*.md` first, then older owner playtests only as needed
8. `ralph/PROMPT_COMPATIBILITY_MAP.md`
9. `ralph/conventions.md`
10. targeted backlog/DONE history for the current gate/package only
11. relevant detailed prompts/spec/code

Do not spend startup context reading the full historical backlog, DONE archive, or every prompt.

## 2. First action: reconcile the active gate and chapter critical path

Before launching lanes, compare the current gate and the weekend full-chapter path against actual `main`.

For every current child:

- verify whether it already landed;
- reproduce newer owner-reported failures even when old DONE history says “fixed”;
- identify overlapping prompts through the compatibility map;
- mark evidence-backed already-fixed work as verification, not a rewrite target;
- identify file ownership/conflicts before dispatch;
- classify the issue as **SHIP BLOCKER**, **QUALITY BLOCKER**, or **POLISH** using the weekend sprint overlay.

The first active gate is currently **Gate A — Trustworthy core verbs**. Use `ralph/ACTIVE_TASKS.md` as the compact reconciliation checklist.

Gate A SHIP BLOCKERS stay on the critical path, but independent later-package implementation may run in parallel when it does not consume the same files, workers, or CI bandwidth needed to resolve the blockers.

## 3. Priority inside a gate / sprint

During the active weekend sprint, prioritize by blocker class first, then by gameplay impact.

### SHIP BLOCKER
Immediate priority. Includes launch/load/save failures, freezes/dead controls, input ownership collisions, impossible combat/camera, progression blockers, intolerable ROG performance, blocked required routes, required encounters/finale that cannot complete, and severe dead travel that makes a required route effectively unfinished.

### QUALITY BLOCKER
Next priority. Includes technically-playable but unacceptable map usability, build scale/door/roof failures, objective confusion, broken-looking village/world composition, washed-out lighting, illegible handheld HUD, or core action presentation too weak to understand.

### POLISH
Record and defer while higher classes remain.

Within a class, prefer work in this order:

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

Default to **4–5 implementation lanes** during the weekend sprint when enough independent SHIP/QUALITY work exists; fall back to 3 when integration/file overlap is the bottleneck.

The limiting factor is CI and merge/rebase throughput, not agent count.

Choose lanes by file ownership:

- two tasks in different domains may still conflict if they edit the same controller/config/UI files;
- two related tasks can run safely if they have explicit file boundaries and a shared contract;
- do not let two lanes independently invent the same regional layout, reward curve, objective sequence, spawn map, or progression contract.

The coordinator owns the contract first, then gives lanes non-overlapping implementation slices.

Recommended initial domains are defined in `ralph/WEEKEND_MEADOWS_SPRINT_2026-08-21.md`: ROG/input/UI/performance; core reliability; building/gathering/care; opening/tournament/objectives; and world/content/regional route. Reshape lanes when file ownership makes another split safer.

Refill lane capacity promptly when a worker finishes; do not leave useful parallel capacity idle while known independent blockers wait.

## 5. Every lane brief must include

- repository and `main` as source revision;
- current gameplay gate/package;
- sprint blocker class (SHIP BLOCKER / QUALITY BLOCKER / POLISH);
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
- next task(s) available inside the same package if self-chaining is allowed.

Workers should normally own 30–90 minute coherent tasks. If a worker exceeds roughly 90 minutes without a clear finish, checkpoint useful work, report the blocker/root cause, and return control to the coordinator for decomposition rather than expanding indefinitely.

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
- after integration, verify the actual tree on `main`;
- integrate successful work frequently rather than building a large pile of local/worker-only changes.

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
- controller failures;
- combat containment/arena failures.

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
2. classify it SHIP/QUALITY/POLISH;
3. open/focus the corresponding bounded lane;
4. land the fix;
5. replay the segment;
6. repeat until the written package criteria pass.

Then move automatically to the next gate.

Do not advance because all child prompts have commits.

### Integrated player-path evidence is mandatory

A unit test, isolated smoke test, focused harness, or green CI job is **necessary evidence, not sufficient player-facing proof** for systems whose correctness depends on real input ownership, modal focus, camera handoff, UI navigation, overlapping controls, world presentation, or target-hardware performance.

For controller, menus, camera, Build, maps, hotbar/satchel, party cycling, lighting/day-night, performance, opening guidance, save/load, and chapter progression, do not mark the owning gate requirement complete based only on isolated tests. Before the gate passes, exercise the feature in the representative continuous player path with the actual competing systems active. Where physical target hardware is unavailable, use the closest production/raw-controller harness that drives the real input-routing and scene stack rather than directly calling implementation methods.

Treat **input ownership collisions** as a systemic defect class. When one physical control affects two contexts at once (for example menu + hotbar, Build + party cycling, settings + world input), investigate the shared input/focus architecture and add cross-context regression coverage instead of accumulating one-off button guards.

Newest owner playtest evidence overrides older green tests or DONE records when they conflict. A fresh real-player reproduction reopens the requirement until the current production path is fixed and re-proven.

## 11. Active self-chain and safe overlap

The canonical chapter order is:

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

For the active weekend sprint, implementation may overlap safely:

- Gate A SHIP BLOCKERS remain blocking for Gate A completion.
- Gate B may begin in independent files/systems while bounded Gate A work continues.
- foundational Gate C contracts may run with Gate B where they do not prematurely lock tuning that B evidence should inform.
- once shared C contracts are stable enough, D1–D5 regional authoring may fan out in parallel with explicit shared-contract/file ownership.
- E integrates the finale; F remains the final whole-chapter proof.

Gate completion remains evidence-based even when implementation overlaps.

## 12. Playable checkpoint cadence

During the weekend sprint, do not disappear for an entire overnight block without producing an integrated build worth playing.

Aim for a playable integrated checkpoint every **2–4 hours** of active coordinated work, or whenever a major chapter boundary becomes newly playable.

At a checkpoint record briefly:

- remote `main` SHA;
- required CI state;
- highest remaining SHIP BLOCKERS;
- continuous player path that now works;
- next chapter boundary;
- ROG/target-hardware evidence available;
- active lanes/scopes.

Status prose must stay concise; engineering progress is the priority.

## 13. Simplify to ship

During this sprint, prefer the simplest reliable implementation that produces the documented experience over a generalized framework that risks the deadline.

This may include explicit objective markers, straightforward arena containment, simplified reliable map controls, sensible ROG quality/performance defaults, or direct use of existing progression state.

Do not use simplification to remove required chapter beats, hide owner blockers, or weaken canonical acceptance criteria.

## 14. Bookkeeping

`ralph/BACKLOG.md` stays the complete ledger.

- do not delete a task merely because a gameplay package groups it;
- close a child only when it is verified on `main`;
- record shipped work in `ralph/DONE.md` according to conventions;
- use targeted search rather than reading the giant DONE archive;
- preserve blocked/history records;
- update `ralph/ACTIVE_TASKS.md` when the active gate changes or when a current item’s verified state materially changes;
- never drop a current owner requirement merely because it is deferred from SHIP BLOCKER to later package ownership.

## 15. Stop condition

Do not stop because the queue looks empty.

The weekend sprint target is one full fresh-save Meadows chapter that a controller/ROG player can understand and complete through the Warden/legendary resolution without major blockers.

The Meadows is ultimately done only when `70-MEADOWS-full-chapter-integration-playthrough.md` passes against `docs/TETHERBOUND_GAME_VISION.md`, including pacing, progression, purpose, reliability, regional quality, and target-hardware viability.

The objective of the coordinator is **not throughput of commits**. It is to keep expanding the boundary of the game that is genuinely enjoyable and production-ready until the whole Meadows chapter crosses it.