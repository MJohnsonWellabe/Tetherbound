# Owner directive — four lanes, each anchored to written acceptance criteria

**Owner call, 2026-09-19, verbatim:** "I'd rather we do something like laying
out all the acceptance criteria for what combat should be, then what meadows
should look like, what cloudreach should look like, and the density of
content and other things. Those could be our four lanes."

This restructures the four concurrent lanes from
`OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md` and
`OWNER_DIRECTIVE_2026-09-19_LANE_RESTRUCTURE_CONTENT_AND_COMBAT_SPLIT.md`. The
render-lock mechanism and plan/results checkpoint process from those
directives are unchanged — only what each lane is pointed at changes.

## The four lanes

1. **Combat** — `docs/CODEX_GOAL_2026-09-19_COMBAT_DEPTH_LANE.md`, criteria in
   `docs/specs/COMBAT_DEPTH_PLAN.md`. Unchanged from before this directive —
   it was already anchored to a written acceptance-criteria document.
2. **Meadows visual** — `docs/CODEX_GOAL_2026-09-19_MEADOWS_VISUAL_ACCEPTANCE.md`,
   criteria in `docs/owner/OWNER_DIRECTIVE_2026-09-10_VISUAL_ACCEPTANCE_CRITERIA_BY_DOMAIN.md`,
   `docs/VISUAL_BIBLE.md`, and `docs/acceptance/MEADOWS_EXIT_CRITERION.md`
   categories B/C/D/E/J. Replaces the previous Meadows lane, which had drifted
   toward chasing the Gate F automated campaign-proof as its actual work.
   Content density is split out of this lane into its own.
3. **Cloudreach visual** — `docs/CODEX_GOAL_2026-09-19_CLOUDREACH_VISUAL_PRODUCTION.md`,
   now with an explicit acceptance-criteria section extracted from
   `docs/biomes/cloudreach/BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md`'s visual
   sections (§3, §4, §11, §26) — not the full biome-build brief, which is
   still paused. The in-flight approved grass-role work continues unchanged.
4. **Content density** — `docs/CODEX_GOAL_2026-09-19_CONTENT_DENSITY_ACCEPTANCE.md`,
   criteria in `docs/acceptance/MEADOWS_EXIT_CRITERION.md` category G,
   `docs/GAME_VISION.md` §2/§7, and the off-trail mechanisms named in
   `OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md` Tier 1/3. **Replaces
   the Stormwood/Water survey lane** — the owner is stopping that session
   directly. The survey itself is deferred, not cancelled forever: Stormwood
   and Water are already known to be well behind Meadows and Cloudreach on
   both content and visuals (see the snapshot in
   `OWNER_DIRECTIVE_2026-09-19_LANE_RESTRUCTURE_CONTENT_AND_COMBAT_SPLIT.md`),
   and a full audit right now doesn't unlock any work sooner, since neither
   biome can be touched until Meadows clears its exit gate regardless.

## Why acceptance-criteria-first, not task-lists

A lane pointed at "do these tasks" drifts once the obvious tasks are done or a
distraction appears (this is exactly what happened to the old Meadows lane —
its task list was superseded by the Gate F chase without anyone deciding that
on purpose). A lane pointed at "here is what done looks like, written down"
has a standard to keep checking itself against regardless of which specific
task it's on at any moment. Where a lane's criteria document already existed
(Combat had `COMBAT_DEPTH_PLAN.md`, Meadows already had the 09-10 domain doc),
this directive just makes the pointer explicit. Where one didn't fully exist
in the right shape (content density, Cloudreach's visual-only slice), this
directive adds it.

## What this does not change

The render-lock file and priority ordering, the plan-before-start/results-
based-completion checkpoints, Meadows-first sequencing, and every hard rule in
`CLAUDE.md` remain exactly as already directed. Stormwood and Water remain
fully paused for any implementation work.
