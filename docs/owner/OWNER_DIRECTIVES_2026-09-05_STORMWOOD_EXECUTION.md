# OWNER DIRECTIVE — STORMWOOD EXECUTION BEHAVIOR

**Date:** 2026-09-05

This directive governs how Codex should execute the Stormwood build. It does not reduce the design or completion bar in `docs/biomes/stormwood/BUILD_STORMWOOD_TO_COMPLETION.md`.

## Owner observation from Cloudreach

Codex did very good work building roughly the first 80–85% of Cloudreach Cliffs. That portion of the run created substantial new playable game: the world, chapter structure, major systems and content advanced quickly.

After that point, progress flattened. A large amount of tokens/context went into repeated late-tail work without comparable material advancement.

The Stormwood run should reproduce or exceed the strong broad-build portion of Cloudreach, but **must not grind indefinitely once progress becomes marginal**.

## Required behavior

1. **Push hard while material progress is real.** Build the world, chapter path, Surge, Stormglass Arches, Hollow Crown, rod stations, content density, Dynamo, relic aftermath and persistence broadly before over-investing in narrow closure problems.
2. **Integrate continuously.** Valuable completed work belongs on verified `main`, not stranded on lanes.
3. **Use the smallest useful test while building.** Larger/full suites still run where project rules require them and at meaningful integration/closure points, but repeated expensive runs must not dominate while large independent game work remains.
4. **Two no-yield attempts is a trigger to change strategy.** If two serious attempts on the same narrow issue produce neither material player-visible improvement nor genuinely new causal evidence, do not launch a third near-identical attempt.
5. **A P0/main-path blocker still must be solved**, but after two no-yield approaches the method must change materially: reframe, inspect another layer, isolate differently, or escalate to a fresh bounded agent/session.
6. **Do not polish one slice while the rest of the biome is missing.** Broad playable completeness outranks narrow proof/polish until the chapter is substantially built.
7. **Stop the broad orchestration session when the remaining tail becomes low-yield.** Leave a precise fresh-session handoff rather than burning context to say the original goal kept running.
8. **Do not call 80–85% complete.** That number describes the minimum broad-build benchmark for the primary run, not the final definition of done. The full Stormwood exit criteria remain the ultimate completion bar.

## Canonical execution policy

Read and follow:

`docs/biomes/stormwood/EXECUTION_PROGRESS_POLICY.md`

That file defines the phase checkpoints, two-checkpoint no-progress trigger, testing/visual economy, Cloudreach benchmark, and fresh-session tail handoff.

## Bottom line

**Get Stormwood at least as materially far as Cloudreach got before the late grind. Continue beyond that while each meaningful iteration is still moving the game. Once progress flattens, stop grinding, integrate the good work, document the tail precisely, and let a fresh focused session close it.**
