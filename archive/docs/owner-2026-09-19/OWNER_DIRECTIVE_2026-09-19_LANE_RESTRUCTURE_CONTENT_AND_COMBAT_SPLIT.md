# Owner directive — demote the Gate F chase, split combat into its own lane

**Owner call, 2026-09-19, verbatim:** "It doesn't feel like this is the right
priority. What's the purpose of the scripted playthrough. I already know I can
play the game through. It's just lacking visually and content wise especially
off the trail. The combat lane should be its own lane. Then someone needs to
check the other biomes content and visuals."

This corrects `OWNER_DIRECTIVE_2026-09-19_CONTENT_AND_VISUALS_PRIORITY.md` and
narrows how the Meadows lane spends its time. It does not reopen
`OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md`'s sequencing beyond adding
two more lanes to `OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md`'s
structure: combat, and a Stormwood/Water survey.

## Why this correction, recorded plainly

Gate F's actual purpose (`docs/acceptance/MEADOWS_EXIT_CRITERION.md` category
K2) is to produce a repeatable, no-intervention proof that a fresh save can run
start to finish — evidence a manual playtest can't give, because a manual run
is one person's one pass and doesn't repeat. That purpose is real. But the cost
so far has been disproportionate: `ralph/reports/MEADOWS-0916/CLOSEOUT.md` and
`ralph/reports/MEADOWS-0919/RESULTS.md` show roughly two weeks and 15+ numbered
campaign attempts (R1 through R15+), the large majority of which found and fixed
defects in the *scripted walker itself* (pathing, frame-budget accounting,
timestamp comparisons) rather than the game. It found two genuinely valuable
real bugs along the way (a combat-staging wall-clip, a menu button that
silently consumed a potion) — those were worth finding. But the owner has
already personally played the game through, which is the thing K2 exists to
prove for people who haven't. Continuing to chase a fully clean automated run
past that point is lower-value than the owner's actual, stated problem.

## What changes for the Meadows lane

**Gate F campaign work is demoted from primary goal to opportunistic.** Do not
treat "get one clean automated S01-to-end run" as the thing this lane is for.
If a Gate F run is already mid-flight and close to revealing whether a real
gameplay bug exists, finish that specific check — don't abandon work half-done.
But do not start a fresh full campaign attempt for its own sake, and do not
treat A0–A11 automated proof as blocking further content or visual work.

**Primary focus is content throughout the map, especially off the trail, and
visuals** — same categories named in
`OWNER_DIRECTIVE_2026-09-19_CONTENT_AND_VISUALS_PRIORITY.md`:
`docs/acceptance/MEADOWS_EXIT_CRITERION.md` category G (optional activities,
detours that pay off, roster temptation) and the Tier 3 off-path draws in
`OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md` (distant villages/glows/
creature clusters visible from the path, NPCs who tell you where things are),
plus categories B/C/D/E/J (creatures, NPCs, terrain, locations, one deliberate
game) for visual work. The Tier 1 wayfinding items (beacon, map markers) stay
in scope as the delivery mechanism for that content.

## Combat depth is now its own lane

Splitting `docs/specs/COMBAT_DEPTH_PLAN.md`'s ladder out of the Meadows lane
entirely so it stops competing with content/visual work for the same session's
attention. New goal doc: `docs/CODEX_GOAL_2026-09-19_COMBAT_DEPTH_LANE.md`, a
third worktree/branch on the same machine, coordinating through the same
render-lock file and plan/results checkpoints as the other lanes
(`OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md`).

**Verify current implementation state before assuming anything is built.**
The 2026-09-12 directive approved the dodge/step-back decision (COMBAT-3's
burst step) but nothing in the Meadows lane's actual recent work touched
combat code — it has been entirely Gate F campaign/harness work. Do not assume
COMBAT-1 or COMBAT-2 exist in the codebase; check first.

## A fourth lane: survey Stormwood and Water's content and visuals

Authorized now, per direct instruction — not a flag-and-wait. New goal doc:
`docs/CODEX_GOAL_2026-09-19_STORMWOOD_WATER_SURVEY.md`, a fourth worktree/branch
on the same machine. Scope is survey and verification, not implementation:
reconcile existing evidence, capture whatever fresh reference frames are needed
to confirm or update it, and produce a current, honest content-and-visual
status for both biomes. This does not reopen Stormwood/Water for building —
that stays paused until Meadows clears its exit gate.

Known snapshot before this lane starts, from the last evidence prior to the
pause (frozen since; nothing has touched these paths, so likely still accurate
but not freshly re-verified — confirming that is this lane's first job):

- **Stormwood** (`docs/HANDOFF_FULL_GAME_2026-09-11.md`,
  `docs/SECOND_PASS_BACKLOG.md`): named-location ledger was 0 PASS / 5 POLISH /
  6 FAIL / 1 invalid of 12. Content floor: 57 of ≥160 dialogue nodes, 8 of 12
  recipes, 461 placeholder replacement points — roughly a third of planned
  dialogue exists. Needed: irregular forest-floor material, rooted vegetation,
  less repeated creature crowding, readable electrical landmarks, authored
  route thresholds, night values that don't crush terrain/character silhouettes.
- **Water** (same sources): 24 named destinations, only 2 with POLISH evidence,
  22 unknown (never surveyed). Content floor: 0 of 6 side chains, 12 of 28-32
  objectives, 0 of 3 settlements accepted.

Both are meaningfully further from done than Meadows or Cloudreach on both
content and visuals — Water more so, since most of it has never been surveyed.

## Render-lock priority across four lanes

Meadows first, then Cloudreach, then Combat, then the Stormwood/Water survey —
survey work is verification/light-capture, not production, so it yields the
lock to all three active-build lanes. All four follow the same claim/release
protocol already specified in the parallel-lanes directive.

## What this does not change

Meadows-first sequencing, the Cloudreach visual-production scope, the
render-lock mechanism, and the plan-before-start/results-based-completion
checkpoints all stand as already directed.
