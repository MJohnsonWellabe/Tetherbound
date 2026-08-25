# Gate F — Authoritative Human-Equivalent Full-Game Playtest and Backlog Regeneration

**Owner-supplied, 2026-08-25.** This is the authoritative Gate F process for the
next coordinator to run. It **supersedes** `ralph/GATE_F_EVIDENCE_2026-08-23.md`
as the process to follow — that earlier pass (chaining harness, three-segment
smoke) was a real evidence gathering exercise and its measurements remain valid
historical input under §16 below, but it did not follow this protocol and its
verdict is not the Gate F exit criterion. Do not treat 2026-08-23's pass as
having already closed Gate F.

See `ralph/HANDOVER_2026-08-25_CI_GREEN_AND_TWO_LANES.md` for how this lane
relates to the concurrent WORLD-GRASS visual lane and for current `main` state
at hand-off.

---

## Mission

Gate F replaces the inherited active backlog with evidence from a
systematic end-to-end playtest of the game as it actually exists.

Gate F is not a cleanup checklist. It is the product-quality audit.
Historical backlog, DONE records, prior gates, and owner playtests
remain preserved as history and risk inputs, but the **post-Gate-F
backlog becomes authoritative**.

The bar is `docs/TETHERBOUND_GAME_VISION.md` plus current owner
decisions — not "better than the last build."

## Model roles

-   **Fable — Playtest Director and Product Reviewer.** Fable designs
    the complete protocol before execution, then analyzes the evidence
    afterward. It does not execute the game, create or select
    screenshots, modify the build, or fix defects during the
    authoritative run.
-   **Sonnet — Neutral Playtest Operator and Recorder.** Sonnet
    executes Fable's protocol against the production build, records
    telemetry/notes, captures prescribed images/video, and does not
    redesign or repair the game during the run.
-   **Developer agents — remediation only after analysis.** They
    receive the new authoritative backlog after Fable's post-analysis.

Reviewer and operator separation is mandatory.

---

## 1. Preconditions and candidate freeze

Before Gate F:

1.  Freeze a specific `main` SHA as the candidate build.
2.  Record Godot version, export identity, target hardware, resolution,
    graphics settings, controller, input mode, save state, and date.
3.  Preserve historical backlog/DONE/playtest documents. Remove
    unresolved historical items from the authoritative active queue
    without deleting history.
4.  Fable reads the complete game vision, owner directives, controls,
    Meadows progression/regional specs, systems specs, art direction,
    performance requirements, and relevant historical risk areas.
5.  Add any required non-invasive instrumentation **before** freezing
    the candidate.
6.  Do not patch the frozen build during an authoritative run.

If a blocker prevents continuation, preserve the failed evidence, fix it
outside the run, freeze a new SHA, and restart the affected
authoritative segment. Never combine pre-fix and post-fix evidence as
one continuous run.

---

## 2. Fable Phase A — Master Playtest Protocol

Fable creates an executable **Master Playtest Protocol** for Sonnet.
Required coverage must be explicit enough that Sonnet does not need to
improvise what to test.

### Coverage matrix

Map every meaningful player-facing requirement to at least one test
action and evidence artifact. Cover:

-   every controller button and meaningful combination;
-   tap/press/release distinctions;
-   every exploration action and hotbar action;
-   every menu/submenu/tab;
-   every menu open/close path;
-   scrolling, focus, confirm, cancel and settings adjustment;
-   map/minimap zoom, pan, centering and navigation;
-   Satchel/inventory;
-   party/creature UI and cycling;
-   Build: open, navigate, repeat-place, rotate, snap, cancel,
    dismantle;
-   crafting and gathering;
-   creature care/rest and player rest;
-   torch/day/night/weather;
-   catch success, miss, cancel and failure states;
-   party-full behavior;
-   required trainer fights and representative optional fights;
-   intentional combat loss and creature faint;
-   combat switching, camera and arena boundaries;
-   tournament qualification, bracket, win and representative failure;
-   every required story conversation/objective transition;
-   every gate/crossing;
-   every meaningful named location and Meadows region;
-   Stronghold/Warden/legendary/chapter resolution;
-   save, quit, load and resume at multiple progression states;
-   shipped website/front door where applicable.

### State-transition coverage

Test interactions between systems, not just isolated features. Include:

-   exploration → Satchel → exploration;
-   exploration → Build → exploration;
-   Build + party-cycle/hotbar inputs;
-   Satchel + hotbar inputs;
-   dialogue → combat → exploration;
-   combat → switch → combat;
-   map/settings/menu → exploration;
-   rest → next day;
-   save → title → load → world;
-   tournament dialogue → fight → bracket update;
-   catch → party count/full state → cycling;
-   tool equip → gather → hotbar switch;
-   torch equip → holster → redraw;
-   region transition → encounter;
-   objective completion → next guidance.

For every transition define expected input owner, focus, camera state
and outcome.

### Abuse/failure cases

Deliberately:

-   mash controls during transitions;
-   press world controls while modal UI owns input;
-   repeatedly open/close menus;
-   rapidly rotate/place/cancel Build;
-   attempt invalid placements;
-   stress collision edges;
-   push fights toward arena boundaries;
-   throw capture orbs badly;
-   attempt invalid catches;
-   fully submerge in water;
-   approach locked routes early;
-   attempt tournament before ready;
-   save in awkward but legal states;
-   load those saves;
-   revisit completed areas;
-   backtrack after story transitions;
-   play naturally through day/night changes.

---

## 3. Instrumentation schema

Fable specifies the schema before execution. Prefer JSONL/CSV structured
telemetry plus Markdown operator notes.

For meaningful events record where available:

-   run ID, candidate SHA, segment ID;
-   timestamp from run start and wall-clock time;
-   objective ID/text;
-   region/location;
-   player `(x,y,z)`, heading;
-   camera yaw/pitch/distance/FOV;
-   party, active creature, levels/XP/condition/health;
-   player health/stamina/condition;
-   inventory/resources;
-   equipped item/tool/hotbar slot;
-   current input context/modal owner;
-   physical controller input and resolved game action;
-   combat/opponent state;
-   progression/story flags;
-   game clock/time of day;
-   sun/environment/light variables;
-   weather;
-   FPS and frame-time average/spikes;
-   draw calls/primitives and memory/VRAM where available;
-   graphics preset/render scale;
-   distance traveled;
-   time since last meaningful interaction;
-   encounter-free travel duration;
-   save/load and transition durations;
-   screenshot/video artifact IDs;
-   expected vs actual result;
-   operator observation;
-   severity candidate;
-   reproducibility.

Instrumentation must not materially alter performance without recording
that limitation.

---

## 4. Pacing, timing and distance study

Measure actual travel rather than saying "this feels long."

Required route measurements include:

Grandpa → village; village traversal; village → pond; tournament → next
objective; pond → South Bridge; bridge → Quarry/Warrens; Warrens;
river/relay; Upper Meadows; Stronghold approach; Stronghold/finale;
expected backtracking routes.

Record actual distance, elapsed time, meaningful interactions,
wild/trainer encounters, resource stops, landmarks/visual pulls,
objective updates, wrong turns, longest uninterrupted walk, longest
dead-travel interval, and moments of uncertainty.

Fable must classify travel as intentional breathing room, exploration
opportunity, or dead time.

---

## 5. Combat study

Include early wild combat, early trainer, tournament, representative
combat in every band, Warrens, Stronghold, Warden/finale, intentional
loss, creature faint, switching under pressure, camera stress near
geometry, arena-edge stress, different creature sizes/ranges, and
different lighting where practical.

Record duration, attacks/damage exchanges, switches, camera corrections,
target-out-of-view events, pathing stalls, boundary violations,
difficulty, recovery consequences, XP/reward, and whether combat felt
fair, readable and purposeful.

---

## 6. Catching study

Exercise tutorial/required catch, close/long throws, deliberate miss,
cancel, moving/weakened targets, invalid/fainted state, different body
sizes, party-not-full/full behavior, catch→party UI/cycling, and
save/load after catch.

Record aim time, throw count, distance, target size where available,
hit/miss reason, result, party count, feedback and camera behavior.

---

## 7. Building, crafting and gathering study

Require a real construction task, not "Build opens."

Sonnet must gather/craft under the current economy, visibly use tools,
then construct at least a simple 2×2 enclosed structure with repeated
floors, rotation, snapping, walls, doorway, usable door and roof;
enter/exit it; place required camp/care objects where applicable;
dismantle; verify refunds/resources; exit Build and immediately resume
normal play.

Record construction time, failed placements, correction attempts, snap
failures, collision, dimensions, camera obstruction, input leakage and
resource costs.

Verify the authoritative free-vs-resource-bound crafting/building rule
from current decisions; do not infer it.

---

## 8. Controller/menu exhaustion matrix

For every physical control, exercise it in exploration, combat,
dialogue, Satchel, creature/party UI, Build, map, settings, pause/main
menu and tournament UI where applicable.

For every menu: open through production path, visit every reachable tab,
reach first/last elements, scroll long lists, change representative
settings, confirm/cancel/back, reopen, close, and immediately resume
world control.

Record focus, physical input, resolved action, simultaneous unintended
action and recoverability.

The goal is to discover **input ownership collisions**.

---

## 9. Navigation, map and objective clarity

At each major objective Sonnet first navigates using only information
available to a normal player. No teleport, hidden coordinates or
developer knowledge until failure is recorded.

Record objective wording, whether it explains what/where, visible
landmarks, minimap usefulness, full-map usefulness, centering/zoom
behavior, time to choose route, wrong turns, time lost, signage
usefulness and destination readability.

Fable distinguishes exploration from confusion.

---

## 10. World and regional audit

Visit every meaningful location on foot through intended routes.

At each region capture arrival, normal gameplay, landmark,
terrain/ground, ecology/activity and any obvious defect. Add
day/night/weather variants when materially relevant.

Record vegetation, creature/trainer/resource cadence, empty areas,
invalid prop placement, water intrusion, collision, repetition,
sightlines, paths, landmarks, environmental storytelling, regional
identity and vision fit.

Do not take only flattering screenshots.

---

## 11. Prescribed screenshot plan

Fable defines screenshots **before** Sonnet plays so evidence cannot be
cherry-picked.

Every capture has an ID, trigger, location, camera type, time/weather
requirement if any, intended proof, HUD rule and telemetry timestamp.

Required classes:

1.  title/opening;
2.  Grandpa/start;
3.  village wide/street;
4.  tournament;
5.  open meadow;
6.  pond approach/shore;
7.  South Bridge;
8.  Quarry;
9.  Warrens;
10. river/relay;
11. Upper Meadows;
12. Stronghold approach;
13. Stronghold/finale;
14. combat;
15. catching;
16. gathering;
17. Build exterior/interior;
18. map;
19. menus/UI;
20. night/torch;
21. weather/lighting;
22. every defect at first occurrence.

For defects capture context first, then a diagnostic close view if
useful.

Fable does not produce, stage, select or edit these images.

---

## 12. Continuous evidence

Record continuous video or equivalent evidence where practical,
segmented by chapter/region. Structured logs should correlate:

`timestamp → player state → input → event → screenshot/video`.

If full-run video is impractical, continuous evidence is mandatory for
the highest-risk segments: opening, tournament, Build, controller/menu
stress, representative combat, region transitions, save/load and
Stronghold finale.

---

## 13. Sonnet operator rules

During the authoritative run Sonnet is a tester, not a developer.

Sonnet must follow the protocol; use production paths; avoid debug
shortcuts except explicit diagnostic reruns; record defects before
attempting fixes; change no code/data/config during the run; never skip
a failed step silently; never substitute a unit-test result for failed
player-path evidence; capture first occurrence; perform bounded
reproduction when directed; preserve saves/logs/images associated with
failures; and report inability to continue as a blocker rather than
improvising around it.

---

## 14. Fable Phase B — Blind post-playtest analysis

After execution Fable receives the frozen vision/acceptance docs,
protocol, telemetry, notes, screenshots, continuous evidence, saves/logs
and candidate metadata.

Do **not** give Fable developer excuses or proposed fixes before its
first judgment.

Fable judges:

-   Can a new player understand the game?
-   Is the opening compelling?
-   Is there always meaningful near-term purpose?
-   Does exploration reward attention?
-   Are routes empty, overloaded or well paced?
-   Does the world feel authored?
-   Are creatures worth finding/catching/caring about?
-   Is combat fair, readable and satisfying?
-   Is progression earned without grind?
-   Does building matter and feel good?
-   Are rest/care useful?
-   Are controls predictable?
-   Are menus polished game UI rather than debug tooling?
-   Is the map genuinely useful?
-   Does every region have identity?
-   Is Team Tether/story pressure legible?
-   Does the chapter escalate?
-   Does the finale pay off the journey?
-   Is ROG Ally performance acceptable?
-   Would a player voluntarily keep playing?

### Root-cause clustering

Do not turn 40 symptoms into 40 unrelated tasks if a few causes explain
them. Cluster findings around input ownership, navigation/objectives,
world density, progression/economy, combat/camera, terrain/composition,
performance, save/session lifecycle, creature attachment, UI
architecture, etc.

For each cluster identify evidence, affected experience, likely cause
and remediation strategy.

---

## 15. Regenerate the authoritative backlog

Fable's post-plan becomes the new authoritative active backlog.
Historical backlog remains archived/searchable.

Every new item includes:

-   stable ID/title;
-   `SHIP BLOCKER`, `QUALITY BLOCKER`, or `POLISH`;
-   player-visible problem;
-   violated vision requirement;
-   exact evidence references: run/segment/timestamp/screenshots;
-   reproduction;
-   measured timing/distance/performance data where relevant;
-   root-cause cluster;
-   desired outcome without unnecessarily prescribing code;
-   acceptance criteria;
-   regression coverage;
-   required player-path retest;
-   visual-review requirement;
-   dependencies/file ownership;
-   parallel-safety;
-   estimated task size;
-   suggested agent/model role.

Prioritize by **player impact × frequency × chapter criticality ×
confidence**, not ease of implementation.

Also produce:

1.  **Top 10 experience failures** — highest player impact.
2.  **Systemic root causes** — fixes that eliminate multiple symptoms.
3.  **Regional/world plan** — content/composition/pacing work by
    region.
4.  **Performance plan** — measured target-hardware problems.
5.  **Regression plan** — automation needed to prevent recurrence.
6.  **Retest plan** — exact Gate F segments to replay after each
    cluster lands.

---

## 16. Blind-first historical backlog reconciliation and completeness audit

The historical backlog is valuable, but it must not bias Fable into
rediscovering only known problems.

### 16.1 Preserve it, but quarantine it from initial diagnosis

At Gate F start:

-   preserve the complete historical backlog, DONE history, owner
    playtests and prior defect records in Git;
-   freeze a snapshot/reference of every unresolved historical item for
    later reconciliation;
-   remove historical unresolved items from the authoritative active
    execution queue without deleting them;
-   Fable may use high-level historical risk knowledge to ensure
    dangerous system classes are exercised, but should **not** use the
    old task list as a checklist for its first post-playtest diagnosis;
-   Sonnet should not be told "look for backlog item X" during normal
    play unless a specifically planned diagnostic segment requires it.

Required order:

**game vision → comprehensive protocol → blind execution → Fable
evidence analysis → provisional new backlog → historical reconciliation
→ final authoritative backlog.**

### 16.2 Freeze a provisional backlog before comparison

Before reconciling individual historical tasks, Fable must produce a
**provisional Gate F backlog** using only the game vision/current owner
decisions, predeclared protocol, telemetry, operator notes,
screenshots/video, saves/logs and observed player experience.

Version/hash this provisional result before historical reconciliation.
It is the record of what Gate F independently discovered.

### 16.3 Reconcile every unresolved historical item

After the provisional backlog exists, compare **every unresolved
historical backlog item** against Gate F evidence and classify it into
exactly one primary category:

1.  **REDISCOVERED** — Gate F independently found the same problem.
    Merge useful historical context into the evidence-backed new item;
    do not duplicate it.
2.  **STILL VALID — NOT NATURALLY ENCOUNTERED** — important current
    requirement that the run did not naturally expose. Carry it forward
    with a current reason/evidence basis.
3.  **COVERED BY BROADER ROOT CAUSE** — the old symptom is better
    represented by a new systemic item. Link and retire the duplicate.
4.  **SUPERSEDED** — a later owner decision, architecture or product
    direction intentionally replaced it. Archive it with the superseding
    decision.
5.  **NOT REPRODUCED** — the relevant path was explicitly exercised
    and the old defect was not observed. Do not automatically carry it
    forward; preserve the tested evidence.
6.  **OBSOLETE / NO LONGER WORTH DOING** — explicitly retire work that
    no longer improves the current product enough to justify
    implementation.
7.  **MISSED BY GATE F / COVERAGE DEFECT** — the old item remains
    valid and a comprehensive Gate F should have detected it, but the
    protocol/evidence failed to exercise or identify it.

Category 7 means **Gate F itself failed coverage**.

### 16.4 Coverage-defect feedback loop

For every `MISSED BY GATE F / COVERAGE DEFECT`:

1.  identify why the protocol missed it;
2.  add/strengthen the required action, state transition, location or
    failure case;
3.  add telemetry/screenshot/video evidence needed to expose it;
4.  add automated regression where appropriate;
5.  update the permanent Gate F protocol template;
6.  re-run the new segment against the candidate;
7.  incorporate the evidence into the final backlog.

Gate F must therefore become progressively better at replacing manually
accumulated backlog.

### 16.5 Historical backlog capture-rate metric

Calculate a **historical backlog capture rate** after reconciliation.

Use genuinely valid/current historical player-facing issues as the
denominator. Exclude clearly superseded and obsolete items.

Report:

-   valid historical issue count;
-   `REDISCOVERED` count;
-   `STILL VALID — NOT NATURALLY ENCOUNTERED` count;
-   `COVERED BY BROADER ROOT CAUSE` count;
-   `NOT REPRODUCED` count;
-   `MISSED BY GATE F / COVERAGE DEFECT` count;
-   independent rediscovery percentage;
-   broader capture percentage including systemic/root-cause coverage.

Do not game the metric by calling difficult misses obsolete.

The metric answers:

**"If we had thrown away the old active backlog before this run, how
much genuinely important work would Gate F have independently
recovered?"**

A weak capture rate means Gate F is not yet authoritative enough.
Improve the protocol before allowing the old backlog to lose operational
importance.

### 16.6 Publish the final authoritative backlog

Only after blind-first analysis and historical reconciliation does Fable
publish the **final authoritative backlog**.

Anything carried forward from history must be converted into the same
evidence-oriented format as new findings: current player-visible
problem, current vision requirement, current evidence/reason, acceptance
criteria, regression requirement, player-path retest and
root-cause/dependency relationship.

No task is grandfathered in merely because it existed before Gate F.

The historical backlog remains searchable forever, but after successful
reconciliation it is no longer the active source of truth. The
evidence-backed Gate F backlog is.

## 17. Remediation loop after the new backlog

After Fable publishes the authoritative backlog:

1.  Opus/coordinator groups work by root cause and dependency.
2.  Sonnet/default developers implement bounded tasks.
3.  Run targeted regressions.
4.  Re-run the exact failed Gate F segment.
5.  Re-run broader affected transitions.
6.  For visual issues, production agents create new evidence and Fable
    performs independent blind review.
7.  Periodically re-run the full authoritative protocol.

Do not let Fable become the implementation agent. Preserve its role as
independent product reviewer.

---

## 18. Exit criterion

Gate F is not complete because every generated ticket has a commit.

Gate F completes only when a new frozen candidate build survives the
full authoritative protocol and Fable judges the Meadows chapter against
the complete game vision as ready at the agreed quality bar.

The final report must state:

-   candidate SHA/build;
-   target hardware/settings;
-   total playtime;
-   route completion;
-   objective clarity;
-   longest dead-travel intervals;
-   combat/catch/build/rest results;
-   menu/controller coverage;
-   save/load results;
-   regional findings;
-   performance distributions and worst spikes;
-   visual-review result;
-   remaining known POLISH;
-   explicit Fable ship/readiness judgment.

**The authoritative question is not "Did the tests pass?" It is: "If
this were handed to a real player as a finished Meadows chapter, what
would make them confused, bored, frustrated, distrust the game, or stop
playing — and what evidence proves that assessment?"**
