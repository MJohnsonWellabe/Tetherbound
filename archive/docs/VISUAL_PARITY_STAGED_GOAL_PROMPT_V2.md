# /goal — TETHERBOUND MEADOWS VISUAL PARITY (VP PROGRAM), STAGED + RESUMABLE

## 0. Authority and precedence

This is an **owner directive**. Under the canon precedence list in `CLAUDE.md`, it sits at
item 1 (explicit newer owner directive) and **supersedes the normal
`ralph/ACTIVE_GAME_PLAN.md` gameplay-gate routing for this branch only**.

Do not start from Gate A of the gameplay plan for this session. Do not merge this branch
into `main` without owner review.

All other `CLAUDE.md` hard rules remain binding and win over anything in this document —
especially the asset rules, the five-creature rule, and the no-Biome-2 rule.

### Terminology

The repo already uses "Gate A / Gate B / …" for **gameplay** gates. This program uses
**VP0 … VP11** for visual passes. These are different axes. Never conflate them, and never
write "Gate 3" in a commit message, progress file, or doc when you mean **VP3**.

---

## 1. Purpose

Run the Meadows visual-parity program defined by:

- `docs/TETHERBOUND_VISUAL_BIBLE_V2.md` (authoritative art target)
- `CLAUDE.md` (hard rules and agent contract)
- `ralph/START_HERE.md` (repo routing)
- `ralph/conventions.md` (branch, CI, testing, visual-judge conventions)
- `docs/ENVIRONMENT_AND_UI_BIBLE.md` (Palworld-quality density/composition principles)
- `docs/reference/tetherbound-meadows-keyart.png`
- current owner-approved website/world art references

The work must be **staged, resumable, and usage-safe**. Do not hold work locally until the
end. After every VP pass: finish it coherently, test, capture evidence, judge, measure,
commit, **push**, update the progress file, then continue.

If the session dies, the latest completed pass must already be pushed and documented so a
fresh session can resume from GitHub without repeating work.

---

## 2. PRIMARY VISUAL GOAL

Make the real playable Godot Meadows deliver approximately **80% of the visual impression
of the approved website art** while remaining achievable and performant: lush, colorful,
layered, alive, well-composed, readable, polished, recognizably the same Tetherbound world.

Target reaction to a representative gameplay screenshot:

> **"This looks like the same game the website is advertising."**

Do not fake screenshots. Do not substitute concept art for real in-game evidence. Do not
redesign Meadows canon. Do not implement Biome 2.

---

## 3. VP-PRE — ENVIRONMENT CAPABILITY CHECK (BLOCKING)

**Do this before anything else. Everything downstream depends on it.**

1. Confirm the Godot binary is available and the project imports.
2. Confirm you can launch the real game and **produce an actual screenshot file on disk**
   from the repo's capture path (see `ralph/conventions.md` / `tools/` / `shots/`).
3. Open the produced image and confirm it is a real rendered frame, not a black frame,
   an editor frame, or a stub.
4. Confirm the repo test command runs: `<OWNER: fill in exact test command>`.
5. Confirm the blind visual-judge workflow is invocable **from this environment**.
   Note: the judge currently lives at `.claude/skills/visual-judge`, which is a Claude Code
   skill and may not be runnable by Codex.

Record the result of each check in the progress file.

**Halt conditions.** If (1)–(3) fail, **stop and report**. Do not proceed with visual work
you cannot see. Reasoning about what a change probably looks like is not evidence, and a
pass built on unverified rendering is worse than no pass.

If only (5) fails, continue, but see the judge fallback in §10.

---

## 4. BRANCH + RESUME RULES

Start from current `main`. Use a dedicated branch: `codex/meadows-visual-parity`.

- Do not work directly on `main`.
- Do not force-push, rewrite history, or touch other branches.
- Do not merge.

If the branch already exists: fetch latest remote state, read
`docs/VISUAL_PARITY_PROGRESS.md`, verify the last completed pass is actually present on the
branch, then resume at the first incomplete pass. Do not restart completed passes unless new
evidence shows a regression.

---

## 5. PERSISTENT PROGRESS FILE

Create and maintain `docs/VISUAL_PARITY_PROGRESS.md`. It is the single resume checkpoint.

Always contains:

- branch name, starting `main` SHA, current branch SHA
- current VP pass; passes completed; passes remaining
- **per-pass commit SHA** and last successful push SHA
- VP-PRE capability-check results
- test state (command run, pass/fail)
- current performance measurements against the budget in §6
- latest blind-judge verdict **or** `DEFERRED — judge not runnable in this environment`
- evidence paths
- important implementation decisions
- regressions / unresolved problems
- exact recommended next action

Update and commit at the end of **every pass**. If a future agent has only this file plus
the repo, it should know exactly where to continue.

---

## 6. HARD ACCEPTANCE NUMBERS

Qualitative targets alone cannot be passed or failed. These are the measurable bars.

| Item | Value |
|---|---|
| Target platform | Windows / ROG Ally |
| Renderer | Compatibility |
| Capture + measurement resolution | `<OWNER: e.g. 1920x1080>` |
| Graphics preset used for all measurements | `<OWNER: named preset>` |
| **Minimum sustained FPS** | `<OWNER: e.g. 45>` |
| Minimum 1% low FPS | `<OWNER: e.g. 30>` |
| Test command | `<OWNER: exact command>` |

Rules:

- Measure on the **same** resolution, renderer, and preset every time. A number taken under
  different settings is not comparable and must not be recorded as progress.
- **If a pass drops sustained FPS below the floor, fix it inside that pass.** Do not defer
  cost to VP10. VP10 is for final retention, not for paying off nine passes of debt.
- If a visual feature is genuinely expensive: prove the cost, find the specific bottleneck,
  optimize it, and preserve as much of the visible result as possible. Do not "optimize" by
  returning Meadows to its sparse baseline.

---

## 7. PER-PASS PLAYABILITY REGRESSION GUARD

Density, scatter, and collision changes routinely break things that screenshots do not show.
Before any pass is marked complete, verify:

- the player can still traverse the major Meadows route end to end;
- no new collision blockers, stuck spots, or unintended walls;
- NPCs and creatures still pathfind (navmesh rebuilt where required);
- spawn points, encounter triggers, and interactables still function;
- save / load works;
- the repo test suite passes.

A pass that improves a frame but breaks traversal is a failed pass. Record any regression in
the progress file rather than shipping it silently.

---

## 8. STARTUP (after VP-PRE passes)

1. Read `CLAUDE.md`.
2. Read `ralph/START_HERE.md`.
3. Read `ralph/conventions.md` for branch/CI/testing/visual-judge conventions.
4. Read `docs/TETHERBOUND_VISUAL_BIBLE_V2.md`.
5. Read `docs/ENVIRONMENT_AND_UI_BIBLE.md`.
6. Read the latest relevant visual audits / reports.
7. Inspect the latest actual Meadows screenshots in the repo.
8. Inspect current: world/lighting, sky/weather, Terrain3D configuration, terrain materials,
   vegetation/scatter, paths, village, tournament, camps, Warrens, Team Tether Relay,
   Meadows Hall, NPC/creature population, performance configuration.
9. Establish a clean baseline capture set.
10. Create `docs/VISUAL_PARITY_PROGRESS.md`.
11. Commit and push the program baseline.

Do not rely on stale screenshots or historical reports when current `main` can be measured
directly.

---

## 9. OPERATING LOOP

For each VP pass:

1. Re-read that pass's success criteria.
2. Reproduce the current player-facing state in the real game.
3. Identify the highest-impact visible problems inside that pass.
4. Implement the smallest coherent set of fixes that materially improves the real game.
5. Run the test command.
6. Run the real game and the capture pipeline.
7. Generate matched before/after evidence.
8. Compare against: the Visual Bible, the key art, owner-approved website direction, and the
   recorded Palworld-quality principles.
9. Run the blind visual judge (see §10).
10. Run the §7 playability guard and the §6 performance measurement.
11. Fix significant failures inside the current pass and repeat.
12. When coherent and improved: update progress file, commit, push, record remote SHA,
    continue.

Do not wait for owner approval between normal passes. Do not merge. Do not stop merely
because one screenshot looks better.

---

## 10. BLIND VISUAL JUDGE

Use the repo's visual-judge process as an iteration tool. The judge must not be told what
changed, what verdict is desired, or what previous judges said unless repo convention
explicitly requires it. A failed verdict is not a reason to stop — it becomes the next
problem list inside the current pass. Do not overfit to fixed screenshot coordinates;
inspect the real game route.

**Fallback.** If the judge harness is not invocable from this environment (likely, since it
is packaged as a Claude Code skill at `.claude/skills/visual-judge`):

1. Do **not** substitute your own opinion and call it a judge verdict.
2. Capture the full evidence set the judge would have consumed, at the paths it expects.
3. Record in the progress file: `JUDGE: DEFERRED — harness not runnable in this
   environment`, plus the evidence paths and the exact command that failed.
4. Continue to the next pass. The deferred judgement becomes an owner-side review item, not
   a silent pass.

---

## 11. NO SELF-CERTIFICATION

Codex is the builder, not the final visual authority. Do not stop because tests pass, code
is clean, a pass has a commit, one screenshot looks excellent, an internal judge says yes, or
the implementation is "technically complete."

The final branch state is only:

> **CANDIDATE READY FOR EXTERNAL VISUAL JUDGEMENT**

---

## 12. SESSION SCOPE FOR THIS RUN

**This run targets VP0 through VP3, then stops cleanly.**

Do not sprint through later passes to reach a finish line. Depth on the early passes —
lighting, terrain, vegetation — carries most of the visual gain and every later pass inherits
it. When VP3 is complete, pushed, and documented, write the resume note and stop.

If usage clearly remains after VP3, continue to VP4 and beyond under the same rules, one
pass at a time.

### Usage / exhaustion rule

If you believe the session may run out of usage, context, or execution time:

1. do **not** begin a new pass;
2. finish the smallest coherent state possible in the current pass;
3. run whatever validation is realistically available;
4. update `docs/VISUAL_PARITY_PROGRESS.md`;
5. commit;
6. **push the branch**;
7. write an exact resume note;
8. stop cleanly.

Never leave the only copy of meaningful visual work unpushed. A clean checkpoint is worth
more than half of the next pass.

---

# THE PASSES

## VP0 — BASELINE + PROGRAM CHECKPOINT

Establish trustworthy current-state evidence before any visual work.

Capture at minimum: representative wide Meadows traversal; village day; village night;
Grandpa yard; tournament; pond/stream; Warrens approach; Warrens interior/den; relay camp;
ridge camp; waystop; Team Tether Relay; Meadows Hall approach/exterior/courtyard where
available; a creature-in-world frame; a combat frame; a building/home frame.

Record: starting SHA, branch, renderer, graphics settings, baseline performance under §6,
capture locations, and current visible defects.

**Complete when:** baseline evidence exists, VP-PRE results are recorded,
`docs/VISUAL_PARITY_PROGRESS.md` exists, state is committed and pushed.

---

## VP1 — SKY, SUN, GLOBAL LIGHTING, ATMOSPHERE

Highest-leverage global presentation. Targets: crisp stylized cloud forms; no smeared or
airbrushed clouds; believable sun treatment; attractive directional light; readable form on
terrain, creatures, and buildings; strong but not crushed shadows; atmospheric depth;
distance haze; clear foreground / mid-ground / background separation; attractive day and
golden-hour presentation; night readable and appealing.

Avoid effects inappropriate for the Compatibility renderer and the ROG Ally target.

**Evidence:** broad outdoor comparisons at several locations, not one hero angle. Measure.
Judge. Record remaining global-light limitations.

---

## VP2 — TERRAIN MATERIALS + GROUND-COVER DENSITY

Fixes the largest percentage of every gameplay frame. Targets: major reduction in exposed
uniform terrain; layered meadow grass; short groundcover; natural weeds and flowers;
improved terrain macro variation; better texture scale; better dirt/grass/rock transitions;
better water-edge transitions; paths visually embedded rather than painted on; no giant
fluorescent-lime terrain surfaces.

Do not simply multiply density until performance collapses. Inspect the current
implementation and improve efficiency with MultiMesh, Terrain3D capabilities, distance
bands, LOD, culling, shader technique, and optimized scatter. If a dense implementation is
expensive, optimize invisible cost before abandoning the target.

**Evidence:** matched player-height ground views across open meadow, path, village edge,
water edge, forest edge. Measure. Judge.

---

## VP3 — VEGETATION LAYERING + NATURAL CLUSTERING

Move from "grass with scattered trees" to a layered living environment: groves; forest-edge
density; bushes beneath trees; saplings; varied tree scales; hero trees; distant tree masses;
stream vegetation; foreground framing; readable clearings; ecological clustering instead of
uniform noise.

Fix mismatched assets: flat vertical vine cards, neon spherical bushes, badly scaled
vegetation, repetitive evenly spaced trees, foliage clashing with the selected nature family.
Preserve one coherent nature family.

**Evidence:** open meadow to forest edge; inside grove; stream edge; village backdrop;
important travel corridor; long-distance horizon. Measure. Judge.

**This is the planned stopping point for this run (see §12).**

---

## VP4 — MID-GROUND COMPOSITION + TRAVEL CORRIDOR QUALITY

Eliminate `player → empty grass → sky`. Walk the actual routes and improve weak sightlines
using existing canonical content: groves, rock clusters, fences, stream bends, ridges,
structures, ruins, paths, creature groups, landmark framing, tree lines.

Build rhythm: compression → reveal → landmark → detail/rest → next reveal. Do not spam
decorative clutter.

**Evidence:** the major continuous player journey at representative intervals. Judge.

---

## VP5 — VILLAGE + TOURNAMENT + CAMPS

**Grandpa's Village** must unmistakably read as inhabited in daylight: building clustering
and depth, connecting paths, yards, fences, gardens, carts, barrels, crates, tools, firewood,
benches, flowers, residents, creature presence, believable activity, village-edge framing.
Preserve the strong night feel.

**Tournament** must read as an event space before UI text explains it: ring/perimeter,
banners, spectator areas, trainer staging, benches, creature staging, event dressing.

**Camps / waystops** each need a legible fire focal point, seating, supplies, authored
irregular clustering, traveler presence where appropriate, and a visible reason the camp
exists there. Do not arrange props like items on a shelf.

**Evidence:** matched village / tournament / camp frames. Judge.

---

## VP6 — BURROW WARRENS

**Exterior:** rock macro variation, texture scale, moss/weathering, ground integration,
coherent surrounding vegetation.

**Interior:** read as a real creature den — nest/bedding, stones, scratch and use marks,
dampness/water, localized ground variation, debris, stronger directional light, a light shaft
or warm source where appropriate, focal composition. Do not create mystery solely by making
the cave dark. Verify creature staging at gameplay camera height and in motion.

**Evidence:** approach, entrance, interior, den, creature encounter. Judge.

---

## VP7 — TEAM TETHER RELAY

Keep the strong pylon/apparatus identity; make the full location feel like an active hostile
operation: visible grunt/patrol presence, occupation clutter, tools, crates, work areas,
machinery with physical mounts, clean cable endpoints, scorch/damage/work marks, faction
identity, purposeful barriers, strong approach composition.

It must look operational, not abandoned. Do not weaken the distinctive hero props.

**Evidence:** approach, standing view, apparatus, populated operational view, night if
useful. Judge.

---

## VP8 — MEADOWS HALL

Deliver **ancient ruin reclaimed by nature + Team Tether industry bolted onto it**. Never a
clean cream castle.

Use owner-approved Hall references and approved asset direction. Highest-value items:
weathered stone, per-stone and macro variation, moss in joints, ivy/overgrowth, broken wall
tops, arched gate/keystone/portcullis treatment, roofs, rubble, courtyard dressing,
cloth-read banners, Team Tether scaffolds, pipes, machinery, boiler/chimney, signs of
occupation.

Do not rebuild gameplay layout to make screenshots prettier. The approach itself must
communicate the building's history.

**Evidence:** distant reveal, approach, gate, exterior, courtyard, retrofit detail,
climax-space view where spoiler conventions permit. Judge.

---

## VP9 — WORLD LIFE + POPULATION + AMBIENT DENSITY

Raise Meadows from a polished environment into a living creature-adventure world: roaming
creatures, creature groupings, NPC walkers, trainers, villagers, Team Tether personnel,
ambient interactions, wind movement, small environmental motion.

Do not create crowd spam, break encounter balance, fake life only for screenshots, or
introduce non-canonical creature assets. **The visible population and the real gameplay
population must agree.** Re-run the §7 guard with particular attention to pathfinding and
encounter triggers.

**Evidence:** representative travel and major locations with active life. Judge.

---

## VP10 — PERFORMANCE RETENTION + VISUAL CLEANUP

Profile the actual game. Optimize LOD, visibility ranges, scatter distance, shadow ranges,
MultiMesh usage, material count, overdraw, particle bounds, texture memory, unnecessary
always-active nodes, distant object complexity.

Do not "optimize" by returning Meadows to its sparse baseline. When a feature is expensive:
prove the cost, find the bottleneck, optimize it, preserve the visible result.

**Evidence:** baseline-vs-final performance and settings under §6. Visual regression check
after optimization.

---

## VP11 — FINAL RECAPTURE + HANDOFF

Produce the strongest candidate for external visual review.

- **Branch info:** branch, starting SHA, final SHA, per-pass commit SHAs, latest pushed SHA.
- **Matched before/after gallery** for all major locations.
- **Hero gallery:** 3 strongest wide Meadows views, village day, village night,
  creature/world frame, combat/world frame, building/home frame, tournament, Warrens,
  Team Tether Relay, Hall approach.
- **Performance report:** baseline, final, renderer/settings, optimization decisions,
  measured against the §6 budget.
- **Judge history** per pass: verdict (or deferral), main failures, response, final state.
- **Known limitations:** explicit. Do not hide unresolved defects.
- **Final progress file** showing all passes complete or any intentionally unresolved pass.

Commit and push the full handoff. Do not merge.

Final status:

> **CANDIDATE READY FOR EXTERNAL VISUAL JUDGEMENT**

---

# COMMIT / PUSH STANDARD

Milestone commits, prefixed with the pass ID:

- `visual(VP0): establish parity baseline`
- `visual(VP1): improve Meadows sky and atmospheric depth`
- `visual(VP2): densify terrain ground layer`
- `visual(VP3): layer and cluster Meadows vegetation`
- `visual(VP4): strengthen Meadows travel composition`
- `visual(VP5): densify village, tournament, and camps`
- `visual(VP6): finish Warrens presentation pass`
- `visual(VP7): make Relay read as active Team Tether site`
- `visual(VP8): rebuild Hall toward ancient retrofit target`
- `visual(VP9): increase world life and ambient population`
- `perf(VP10): retain visual parity on target renderer`
- `visual(VP11): package final parity evidence`

Push after each completed pass.

---

# ASSET RULES

Follow `CLAUDE.md` exactly; it wins on any conflict with this document. In particular:

- no new creature meshes or Meshy generations for Meadows;
- never spend a Meshy generation without owner-supplied reference art;
- reuse the installed humanoid cast; check `docs/art/HUMANOID_ASSET_INVENTORY.md` first;
- one nature family, one village family, one prop family;
- Meshy reserved for permitted Team Tether hero objects;
- maintain `docs/ASSET_LEDGER.md` with provenance and license;
- inspect currently installed assets before sourcing anything new.

Do not turn the visual pass into an uncontrolled asset-shopping exercise.

---

# SUCCESS BAR

The completed program should broadly deliver: lush ground rather than painted empty terrain;
layered vegetation; strong mid-ground composition; polished sky, sun, and atmosphere; an
inhabited village; a legible tournament; camps that feel lived in; an authored Warrens den;
an active Team Tether Relay; an ancient-overgrown-industrial Meadows Hall; visible creature
and NPC life; coherent materials; website-art-like color, depth, and composition; and
performance at or above the §6 floor.

**Stop safely, commit, and push at every completed pass so the entire program can resume
from GitHub at any time.**
