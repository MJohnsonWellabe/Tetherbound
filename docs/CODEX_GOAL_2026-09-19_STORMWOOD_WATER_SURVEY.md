# Codex goal — Stormwood and Water content-and-visual survey, 2026-09-19

**Scope authority:** `docs/owner/OWNER_DIRECTIVE_2026-09-19_LANE_RESTRUCTURE_CONTENT_AND_COMBAT_SPLIT.md`.
Also read `docs/owner/OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md`
for the render-lock file and plan/results checkpoint mechanics. This lane has
the lowest render-lock priority of the four active lanes (Meadows, Cloudreach,
Combat, then this one) — it's verification work, not production, so yield the
lock whenever another lane needs it.

## What this lane is and is not

**This is a survey and evidence-reconciliation job, not a resumption of
Stormwood or Water development.** Both biomes remain fully paused per
`OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md` and
`CLAUDE.md`'s Biome-2+ rule — nothing here authorizes building anything. The
job is to produce a current, honest, evidence-backed answer to: **where do
Stormwood and Water actually stand on content and visuals right now?**

## Known snapshot to verify or update

From the last evidence before the pause (`docs/HANDOFF_FULL_GAME_2026-09-11.md`,
`docs/SECOND_PASS_BACKLOG.md`) — frozen since nothing has touched these paths,
likely still accurate, but not freshly re-verified. Confirming or correcting
this is your first job:

- **Stormwood**: named-location ledger 0 PASS / 5 POLISH / 6 FAIL / 1 invalid
  of 12. Content floor: 57 of ≥160 dialogue nodes, 8 of 12 recipes, 461
  placeholder replacement points. Needed per the last diagnosis: irregular
  forest-floor material, rooted vegetation, less repeated creature crowding,
  readable electrical landmarks, authored route thresholds, night values that
  preserve terrain/character silhouettes.
- **Water**: 24 named destinations, only 2 with POLISH evidence, 22 unknown
  (never surveyed at all). Content floor: 0 of 6 side chains, 12 of 28-32
  objectives, 0 of 3 settlements accepted.

## What to actually do

1. **Reconcile committed evidence first**, the same way the Cloudreach lane's
   plan did for its ledger: read every Stormwood/Water report under
   `ralph/reports/STORMWOOD-PROGRESS/`, `ralph/reports/WATER-PROGRESS/`, and
   any later `ralph/reports/FOUR-BIOME-BUILD/` entries touching either biome.
   Note the actual commit/PR each claim rests on. Flag any claim (like the
   snapshot above) you can't independently verify.
2. **Survey what's never been looked at.** Water in particular has 22 of 24
   named destinations with no visual verdict at all. Where a genuine visual
   verdict is missing, that itself is a finding — "never surveyed" is a
   different, worse status than "surveyed and FAIL," and the report should say
   which is true for each location.
3. **Light verification capture only, not a production pass.** Where you need
   a fresh frame to confirm whether an old defect still exists (or to fill an
   "unknown" ledger row with an actual first look), capture it — day and night,
   ordinary player/camera, real shipping geometry, same standard the other
   lanes hold to. This is not a mandate to fix anything found; it's to know
   what's actually there.
4. **Content-floor recount.** Re-run whatever the original census method was
   for dialogue nodes, recipes, placeholder replacement points (Stormwood) and
   side chains, objectives, settlements (Water), rather than trusting the old
   counts unchecked.
5. **Produce one clear status doc** — the same PASS/POLISH/FAIL/unknown ledger
   format already used for Meadows and Cloudreach, plus the content-floor
   numbers, plus a short list of what would need to happen to bring each biome
   to the standard Meadows and Cloudreach are being held to. This is a status
   report, not a repair plan — don't scope the fix work here, just describe
   the gap accurately so a future session (or the owner) can decide sequencing.

## What is explicitly out of scope

- Any implementation, fix, or content addition in Stormwood or Water. Survey
  and report only.
- Meadows, Cloudreach, or combat work.
- Spending a Meshy generation.
- Treating this survey as authorization to keep building once it's done — it
  isn't. The next move after this lane's report is the owner's call.

## Process

Write your plan to `ralph/reports/STORMWOOD-WATER-SURVEY-0919/PLAN.md` before
starting — this one can be lighter than the other lanes' plans since the work
itself is lower-risk (read-only + verification capture), but still name which
biome/report set you're starting with. Hold for
`ralph/reports/STORMWOOD-WATER-SURVEY-0919/PLAN-APPROVED.md`. Write your
findings to `ralph/reports/STORMWOOD-WATER-SURVEY-0919/RESULTS.md`, and put the
final status doc itself wherever the existing per-biome report convention
points — check `ralph/reports/STORMWOOD-PROGRESS/` and
`ralph/reports/WATER-PROGRESS/` for the established pattern before inventing a
new location.
