# Codex goal — Cloudreach visual and environment production, 2026-09-19

**Scope carve-out:** `docs/owner/OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md`
authorizes this lane as a bounded exception to "no Biome 2 work until Meadows clears
its exit gate." Read that directive first — it also covers the render-lock
coordination with the concurrent Meadows session on the same machine, and the
plan/results checkpoints Claude reviews.

## What Cloudreach should look like — the acceptance criteria for this lane

`docs/biomes/cloudreach/BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md` is the full
biome-build brief — most of it (Fly traversal, the Realm Heart system, NPCs,
quests, the final boss) is **not** in scope; that's full chapter implementation,
still paused behind Meadows. But its visual sections are the actual "what this
should look like" answer, and they still apply to the work this lane does:

- **Core identity (§3):** windswept, adventurous, awe-inspiring, ancient,
  high-risk/high-reward, bright but dangerous, vertical rather than flat,
  scenic without becoming empty. Explicitly **not**: another Meadows, a dense
  dark forest, a swamp, a horror biome, a corridor with cliffs painted beside
  it.
- **Visual target (§4):** towering sheer faces, suspended paths, layered
  plateaus, broad sky, warm natural stone, wind-bent vegetation, ancient stone
  structures, bridges/rope crossings, dramatic vertical sightlines, distant
  visible destinations, large readable silhouettes. The player should
  regularly see places before reaching them — Cloudreach must be navigable
  visually, not only by minimap.
- **Landmark structure (§11):** every major subregion (Gate/Lower Cliffs,
  Broken Causeways, Windscar Ravine, High Roost/Sky Shrine, Upper Cloudreach,
  Summit) needs at least one recognizable landmark, readable at a glance.
- **Validation checkpoints (§26):** first Cloudreach reveal, lower cliffs,
  broken bridge/causeway region, mid-biome ravine, upper plateau, final
  approach — each needs its own capture-and-judge pass, using real route/play
  frames, not posed beauty shots.

Use this as the standard the four mechanisms below (and any named-location
promotion) are actually judged against — "does this read as windswept,
vertical, ancient, and readable at a glance" — not just "is the grass better
than it was."

## Start here

There is no pre-existing plan or campaign checkpoint for this lane to resume from
— unlike the Meadows lane, this is a cold start. **You write the plan yourself:**

1. Re-verify the current Cloudreach named-location ledger (PASS/POLISH/FAIL) from
   real committed evidence in the repo. Do not trust the 2026-09-11 numbers below
   — they are almost certainly stale.
2. Look at which of the four systemic mechanisms below (terrain, cloud banks,
   cliff strata, grass) shows up as the recorded defect on the most FAIL/POLISH
   rows in the ledger you just rebuilt. Pick that one first.
3. Write `ralph/reports/CLOUDREACH-0919/PLAN.md`: your rebuilt ledger summary,
   which mechanism you're starting with and why, your intended fix approach, how
   you'll use the render lock, and your evidence contract (same shape as the
   Meadows lane's plan at `ralph/reports/MEADOWS-0919/PLAN.md` if you want a
   concrete reference for the format).
4. Commit and push it, then hold substantive implementation for
   `ralph/reports/CLOUDREACH-0919/PLAN-APPROVED.md` per the parallel-lanes
   directive. Low-risk investigation (reading the ledger, the shader/material
   code, prior reports) can continue while you wait.

## What is in scope

Visual and environment production on Cloudreach only:

1. **Terrain overlays.** Replace turf-painted trail/settlement overlays with true
   coverage masks so the underlying crown shows through; build continuous route
   ribbons with proper joins and endpoint fades.
2. **Cloud banks.** Replace the many independent flattened cloud spheres with
   roughly 80-120 deterministic multi-lobe cloud banks using height tiers, shaded
   bases and night-aware exposure. Preserve the safety-owned CloudSea height and
   recovery contract — do not touch its collision/safety behavior, only its look.
3. **Cliff strata.** Break the exact repeating cliff-strata cadence with
   low-frequency spatial variation; only add a few authored cliff silhouettes if
   that alone is insufficient, without changing walkable crowns or region bounds.
4. **Grass.** Rebuild into low/medium/sparse-tall roles with width proportional to
   height. Do not resume exhausted tip/arc/count tuning rounds — those are already
   spent per `docs/SECOND_PASS_BACKLOG.md`'s "Cloudreach still reads as bare turf"
   entry; a materially different approach is required, not another tuning pass on
   the same lever.
5. **Named-location visual promotion**, using the existing PASS/POLISH/FAIL ledger
   and the same evidence discipline already established for Meadows: a location
   changes grade only after a production capture (real shipping build, not a
   capture harness with missing geometry) and independent code-blind review.

**Re-verify the current ledger before trusting any older number.** As of
2026-09-11 it stood at 0 PASS / 10 POLISH / 2 FAIL (Stormward Overlook and Summit
Eyrie), but Cloudreach work continued after that date (PRs #121-125) and the
ledger has almost certainly moved. Rebuild it from committed evidence, not from
this document's memory of an old state.

## What is explicitly out of scope

- Any new Cloudreach gameplay system, mechanic, quest, or content that wasn't
  already implemented before 2026-09-11. This lane is finishing art already in
  motion, not starting the next biome. Fly, the Realm Heart, NPCs, quests, and
  the final boss (the rest of `BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md`) are
  explicitly not this lane's job.
- Stormwood and Water. Both remain fully paused.
- Anything that would read as "Cloudreach implementation" rather than "Cloudreach
  visual polish" to someone checking this against `CLAUDE.md`'s Biome-2 rule. If a
  fix seems to require new gameplay-affecting code (not just visuals/materials/
  shaders/scatter), stop and flag it in your `PLAN.md` rather than proceeding —
  that is exactly the kind of scope question Claude's plan review exists for.
- Spending a Meshy generation. `CLAUDE.md`'s Meshy rules (one nature/village/prop
  family, owner reference art required) are unchanged and unaffected by this
  directive.

## Process

Same evidence and CI discipline as the Meadows lane: exact-staged commits, no
incidental `.import`/`.uid` churn, inspect every CI job before claiming green, a
location's grade changes only with real evidence. Use the render-lock file
described in the parallel-lanes directive before any capture step, and check it
throughout a long capture session, not just once at the start.

Write your plan to `ralph/reports/CLOUDREACH-0919/PLAN.md` before starting
implementation, per the parallel-lanes directive, and your results to
`ralph/reports/CLOUDREACH-0919/RESULTS.md` when this work window ends.
