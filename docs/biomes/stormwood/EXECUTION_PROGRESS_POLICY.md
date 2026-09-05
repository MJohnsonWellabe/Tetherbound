# Stormwood — Material Progress Policy

**Status:** canonical execution policy for the Stormwood build. Read with `00_CODEX_START_HERE.md` before `BUILD_STORMWOOD_TO_COMPLETION.md`.

This policy records the owner's lesson from the Cloudreach Cliffs build: Codex did excellent work through roughly the first 80–85% of the biome, then consumed a disproportionate amount of context/tokens on a narrow late tail without comparable player-visible progress. Stormwood should reproduce the strong first portion, not the grind.

## 1. Objective

The primary orchestration session should maximize **material playable game delivered to verified `main` per unit of context**, not maximize runtime, token use, test count, or number of agent lanes.

The full Stormwood definition of done remains unchanged. This policy changes **how the work is attacked**, not what a finished biome ultimately requires.

## 2. Phase checkpoint rule

At the end of every major phase in `BUILD_STORMWOOD_TO_COMPLETION.md`, the orchestrator records a compact checkpoint:

- player-visible capabilities newly added;
- regions/story path newly reachable;
- systems newly working in real gameplay;
- content/density materially added;
- merged-main SHA;
- blockers discovered;
- next highest-value phase/task.

A phase may continue only when the latest work is still changing one of those materially.

Do not substitute test/report churn for a player-visible delta.

## 3. Two-checkpoint no-progress trigger

If **two consecutive orchestrator checkpoints** show no meaningful expansion of playable territory, story progression, biome-defining mechanics, content density, major visual quality, persistence, or root-cause knowledge, the orchestration strategy must change.

Allowed responses:

1. re-scope the blocker;
2. move to an independent high-value task;
3. hand the narrow issue to a fresh bounded agent;
4. preserve the issue for a fresh later orchestration session.

Not allowed:

- a third near-identical attempt;
- repeated harness runs without a changed hypothesis;
- micro-tuning the same axis after two no-yield rounds;
- spawning another agent to rediscover the same facts;
- rewriting acceptance criteria to manufacture progress.

## 4. Build breadth before closure depth

Before spending substantial time on the final 10–20%, the following should materially exist and work:

- Cloudreach → Stormwood handoff;
- all six regions;
- a traversable full-biome route;
- recognizable Stormwood visual identity using Terrain3D/scatter rather than primitive massing;
- Surge cycle;
- Stormglass Arches;
- Hollow Crown progression;
- rod stations;
- NPC/trainer/resource/pickup distribution across the chapter;
- main story path through the Dynamo;
- finale and captive-legendary sequence with placeholders where allowed;
- Spark/relic aftermath;
- Water-biome handoff;
- save/load for major chapter state.

If several of these are missing, broad implementation outranks narrow proof/polish.

## 5. Testing economy

Run the **smallest test that can answer the current question** while building.

Use targeted unit/smoke tests during implementation. Run larger integration suites at meaningful landing waves and before claiming a phase/gate is closed.

Do not repeatedly spend 30–45 minutes on full CI merely to learn the same narrow fact while large independent game work remains.

A full suite is mandatory where the canonical workflow requires it for risky shared-state/save/autoload changes and at final integration checkpoints. This policy does not weaken those safeguards.

## 6. Visual iteration economy

Visual work still requires real captures and blind judgment.

However:

- fix the largest named visual problem first;
- require each revision to move a visible/measured axis;
- after two serious rounds on the same issue with no material movement, stop tuning and either change mechanism or defer the narrow tail;
- never let one stubborn visual defect prevent building entire untouched regions/content layers.

The goal is not one perfect screenshot while five regions remain rough.

## 7. CI / branch discipline

Continuous integration remains part of material progress.

Completed valuable work should land throughout the session. A large pile of completed lane branches is not progress until reconciled and merged.

Before moving into late-tail work, ensure:

- completed PRs are reviewed and merged;
- dependent work is based on current integrated `main`;
- no high-value completed work is stranded;
- `main` is in a recoverable/playable state.

## 8. Minimum benchmark from Cloudreach

The Stormwood primary build session is expected to get **at least as materially far as Cloudreach was before its late grind**.

This is not a literal percentage score. It means the biome should broadly exist as a recognizable, playable chapter with its major regions, story spine, signature traversal/system, content layers, climax and persistence mostly built.

If material progress remains strong beyond that point, continue.

If progress has flattened and only a narrow closure tail remains, stop the broad orchestration run and create a precise handoff.

## 9. Fresh-session tail

When the broad run stops due to diminishing returns, leave a focused tail document/report with:

- current `main` SHA;
- what is proven playable;
- what is implemented but unproven;
- exact remaining blockers;
- reproduction steps;
- hypotheses already tried;
- probes/tests/logs worth preserving;
- strongest next hypothesis;
- whether each blocker is P0/main-path, quality, performance, or evidence-only;
- next 3–5 bounded tasks in priority order.

A new session should attack that list directly with fresh context. It should not reread the entire project's history or restart the biome plan.

## 10. Definition of success for the primary run

The primary Stormwood orchestration run is successful when it has:

1. made the biome materially playable end to end or very close to it;
2. reproduced Cloudreach's strong broad-build phase or exceeded it;
3. integrated its useful work to `main` continuously;
4. stopped wasting context once the remaining work became narrow and low-yield;
5. left the final tail precise enough for a fresh session to close efficiently.

The biome itself is still only **finished** when the full exit criteria in `BUILD_STORMWOOD_TO_COMPLETION.md` are met.

**Build aggressively while progress is real. Stop grinding when it is not.**
