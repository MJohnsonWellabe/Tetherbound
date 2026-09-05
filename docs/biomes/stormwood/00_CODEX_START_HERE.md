# Stormwood — Codex Start Here

**Status:** execution entrypoint for Biome 3. Read this first, then execute `BUILD_STORMWOOD_TO_COMPLETION.md`.

The detailed biome contract is:

- `docs/biomes/stormwood/BUILD_STORMWOOD_TO_COMPLETION.md`

That file owns the creative direction, story, systems, counts, regional structure, Surge cycle, Stormglass Arches, Hollow Crown, rod stations, Dynamo finale, captive legendary, realm relic, level range, content targets and acceptance criteria. **Do not replace or simplify that specification.**

This file adds the execution lesson from the Cloudreach Cliffs build: front-load material game progress, integrate continuously, and do not spend the end of a long session grinding the same low-yield closure problem after the biome is already broadly built.

---

# 1. THE CLOUDREACH BENCHMARK

Cloudreach proved that Codex can build a very large amount of a biome in one sustained orchestration run. The useful benchmark is the state Cloudreach reached **before the late-session diminishing-return grind**: approximately the first **80–85% of the biome was materially built**, the world and chapter had taken recognizable form, most major systems/content existed, and the project had advanced dramatically.

That is the minimum execution standard for the Stormwood run.

This is **not** a request to stop at an arbitrary numerical 80–85% checklist score. It means:

> Reach at least the same kind of broad, materially playable state Cloudreach reached before repeated late attempts began consuming large amounts of context/tokens for very little additional player-visible progress.

If the run is still making strong material progress after that point, continue.

If the remaining work has become dominated by repeated low-yield debugging, harness instability, micro-tuning, or evidence closure that is not materially improving the game, **do not grind simply because tokens remain**. Preserve the blocker and hand the narrow tail to a fresh session.

The goal is maximum useful game built per orchestration run, not maximum token consumption.

---

# 2. WHAT COUNTS AS MATERIAL PROGRESS

A lane/run is making material progress when it does one or more of the following:

- adds a new playable Stormwood region or materially advances one;
- extends the continuous main story/player path;
- makes the Surge cycle work in real gameplay;
- makes Stormglass Arches function and integrates them into progression;
- creates/lands meaningful NPC, trainer, objective, resource, pickup or encounter content;
- materially increases world density or exploration value;
- implements a major chapter system, boss, rod station, Hollow Crown beat, Dynamo beat, relic reward or Cloudreach→Stormwood handoff;
- resolves a player-facing blocker with evidence;
- identifies a new root cause that materially changes the next implementation step;
- produces a measurable visual/gameplay improvement that survives blind/runtime validation;
- makes save/load, progression or integration actually work for more of the chapter;
- moves completed work from a branch into verified `main`.

A commit existing is not, by itself, material progress.

A test going green through a workaround that does not improve the actual player path is not material progress.

A new report describing the same known failure more verbosely is not material progress.

---

# 3. FRONT-LOAD THE BIOME, NOT THE LAST 10%

The orchestration order should maximize broad chapter completion before deep closure work.

Prioritize roughly in this order, respecting dependencies in the detailed directive:

1. **Cloudreach handoff and realm seam** — Stormwood key/relic routing, entry, persistence.
2. **World foundation** — six regions, authored terrain, macro routes, landmarks, scatter/forest presentation.
3. **Main chapter path** — arrival through Dynamo finale in playable form.
4. **Biome-defining mechanics** — Surge and Stormglass Arches, including Hollow Crown access.
5. **Regional content density** — NPCs, trainers, rod stations, encounters, resources, pickups, side content, camps.
6. **Progression and climax** — levels, mini-bosses/captains, Dynamo, captive legendary, Spark/relic aftermath, Water handoff.
7. **Persistence and regression coverage** for the above.
8. **Visual quality pass** across the actual route, correcting the largest visible misses.
9. **Continuous-play evidence and polish**.
10. **Narrow late-tail closure** only while it is still yielding meaningful progress.

Do not spend half the run proving one narrow subsystem while entire regions, story beats or content layers remain unbuilt.

A broad playable chapter with several named rough edges is more valuable at this stage than one exquisitely proven early slice followed by an empty second half.

---

# 4. THE TWO-ATTEMPT DIMINISHING-RETURN RULE

A bounded agent may investigate/fix a problem normally.

If **two consecutive serious attempts on the same narrow issue** produce neither:

- player-visible/material improvement, **nor**
- genuinely new causal evidence that changes the next hypothesis,

then stop that lane.

Do not launch attempt three merely by varying constants, rerunning the same harness, rewriting the same workaround, or asking another agent to rediscover the same facts.

Instead:

1. record the exact observed failure;
2. record what was tried;
3. record what was ruled out;
4. preserve logs/probes/tests that are genuinely useful;
5. state the strongest remaining hypothesis;
6. classify whether it blocks the main path or only final proof/polish;
7. move the orchestrator to the next independent high-value task.

A fresh later session can attack the narrow problem with fresh context.

### Exception

A true P0/main-path blocker cannot simply be abandoned if it prevents the biome from becoming playable. But even then, after two no-yield approaches the orchestrator must **change strategy**: escalate/reframe/root-cause from a different layer, rather than repeating the same class of attempt indefinitely.

---

# 5. DO NOT CONFUSE EVIDENCE GRIND WITH GAME BUILDING

Stormwood still needs real evidence. The detailed directive's acceptance criteria remain valid.

But use evidence to answer questions, not to manufacture activity.

Stop and rethink when any of these patterns appear:

- the same smoke/harness run is repeated without a new hypothesis;
- a nondeterministic harness is consuming the session instead of being isolated;
- a visual tuning loop has stopped moving a measured or perceptual axis;
- a test is being rewritten around the implementation instead of exercising player behavior;
- an agent is producing reports/ledger updates faster than gameplay changes;
- a minor final acceptance clause is monopolizing time while major independent content remains;
- architecture is being generalized beyond what the Stormwood actually requires;
- a clean working system is being refactored simply because the orchestrator has remaining context.

Follow the existing project rule: a green check is useful only when it proves the relevant behavior. Likewise, a red check is worth chasing only when fixing it materially advances the game or the proof needed to trust the game.

---

# 6. KEEP SHIPPING WHILE YOU BUILD

Do not recreate the late-session problem by accumulating a giant private working tree.

For every meaningful bounded lane:

- branch from the correct integrated base;
- implement the scoped player-facing outcome;
- run proportionate tests/runtime validation;
- capture/blind-judge visual changes where required;
- commit and push;
- integrate verified work through the normal PR/landing path;
- verify the merged state at meaningful waves;
- branch dependent work from the newer integrated state.

Prefer ten meaningful integrated advances over thirty speculative concurrent lanes.

Use cheaper/lower-tier agents for bounded implementation, content authoring, tests, capture, inventories and mechanical work. Keep the senior orchestrator focused on dependency choice, world/story coherence, architecture, blocker escalation, integration and acceptance.

---

# 7. TARGET STATE BEFORE ANY LATE-TAIL GRIND

Before allowing the run to spend substantial time on final closure/polish, the orchestrator should be able to answer **yes** to most of the following from actual repo/runtime evidence:

- Can the player transition from Cloudreach into Stormwood?
- Do all six Stormwood regions materially exist?
- Is there a coherent traversable route through the whole biome?
- Is the forest visually recognizably Stormwood rather than placeholder geometry?
- Does the Surge materially affect gameplay?
- Do Stormglass Arches work as a real traversal/progression system?
- Is the Hollow Crown reachable through the intended arch mechanic?
- Are the four rod stations materially implemented?
- Are NPCs, trainers, encounters, resources and pickups distributed across the chapter?
- Is off-route exploration meaningfully rewarded at approximately the density specified in the main directive?
- Does the main task/story chain reach the Dynamo?
- Does the Dynamo finale materially work?
- Can the captive legendary/freeing/release-choice sequence occur with a placeholder creature if necessary?
- Does the Spark/relic reward and post-biome state materially work?
- Does the game point toward Water as Biome 4?
- Does save/load preserve the important chapter state?
- Are the major player-facing visuals recognizably at the project's target direction, even if final art/polish remains?

If major answers are still **no**, keep building broad missing game content before entering low-yield evidence/polish loops.

---

# 8. WHEN TO STOP THE ORCHESTRATION RUN

Stopping is correct when all three are true:

1. the Stormwood has reached or exceeded the broad material state Cloudreach reached before its late grind;
2. remaining independent high-value tasks have either landed or are clearly blocked by narrow issues/art dependencies;
3. recent attempts are consuming substantial context/tokens without meaningful player-visible progress or new causal evidence.

At that point, **do not grind for the sake of saying the one goal ran longer**.

Leave a precise handoff containing:

- current `main` SHA;
- what is truly playable;
- what is implemented but not proven;
- what remains visibly missing;
- every narrow blocker with reproduction/evidence;
- the next best hypothesis for each blocker;
- incomplete branches/PRs and whether they should land;
- the highest-value next task for a fresh session.

This is a successful orchestration outcome, not an admission of failure.

The next fresh session can finish the narrow tail with a much better context-to-progress ratio.

---

# 9. WHAT NOT TO SACRIFICE

The anti-grind rule does **not** lower the Stormwood design bar.

Do not use it to justify:

- leaving half the biome as empty terrain;
- skipping the Surge;
- skipping the arches/Hollow Crown;
- omitting the rod-station progression;
- stopping before a material Dynamo/finale exists;
- deleting content targets from the detailed directive;
- ignoring broken save/load on the core chapter path;
- calling placeholder massing a finished visual pass;
- declaring the chapter complete at 80–85%.

The 80–85% Cloudreach comparison is a **minimum material-build benchmark for the main orchestration run**, not Stormwood's final definition of done.

The full definition of done remains in `BUILD_STORMWOOD_TO_COMPLETION.md` and can be completed across subsequent focused passes where necessary.

---

# 10. CODEX EXECUTION COMMAND

After reading this file, read the entire:

`docs/biomes/stormwood/BUILD_STORMWOOD_TO_COMPLETION.md`

Then execute it aggressively in dependency order.

Build broad player-facing game first. Integrate continuously. Use subagents where economical. Validate proportionately. Escalate rather than repeat. Continue while material progress remains strong.

**Do not spend a long tail of the session grinding a narrow problem after progress has flattened. Get the Stormwood at least as materially far as Cloudreach got before its late-session grind, then use judgment.**
