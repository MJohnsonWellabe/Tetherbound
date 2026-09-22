# Stormwood / Water survey plan — 2026-09-19

Status: **submitted for approval; survey execution held**. Wait for
`ralph/reports/STORMWOOD-WATER-SURVEY-0919/PLAN-APPROVED.md` before beginning
the evidence reconciliation, census, or capture work described below.

## Starting checkpoint and scope

- Branch: `ralph/stormwood-water-survey-0919`
- Isolated worktree: `D:\tetherbound\stormwood-water-survey-0919`
- Baseline: `origin/main` at `8990a743ce6d4126a0c826a0f66ae20ee81f953e`
- Authority: `AGENTS.md`, `CLAUDE.md`, the September 19 lane-restructure and
  parallel-lanes owner directives, and
  `docs/CODEX_GOAL_2026-09-19_STORMWOOD_WATER_SURVEY.md`

This lane is read-only survey, verification, and evidence reconciliation. It
will not change game source, scenes, data, shaders, tests, or assets; add or fix
content; promote a location without valid evidence; spend a Meshy generation;
or touch Meadows, Cloudreach, or combat work. Findings will describe gaps, not
authorize or implement repairs.

## Order of work after approval

1. **Stormwood committed-evidence reconciliation first.** Read every committed
   report under `ralph/reports/STORMWOOD-PROGRESS/`, then the later Stormwood
   entries under `ralph/reports/FOUR-BIOME-BUILD/`. For each of the 12 named
   locations, record the newest applicable PASS/POLISH/FAIL/unknown verdict,
   evidence path, evidence commit/PR when recoverable, capture/build identity,
   day/night coverage, reviewer independence, and any provenance limitation.
   Reconcile or explicitly reject the inherited `0 PASS / 5 POLISH / 6 FAIL /
   1 invalid` snapshot rather than copying it forward.
2. **Stormwood content-floor recount.** Reproduce the original census method
   from the committed census/report evidence and current shipping data. Recount
   dialogue nodes against the stated floor, recipes, and placeholder replacement
   points. Keep planned targets, implemented records, placeholders, and accepted
   player-facing content distinct.
3. **Water committed-evidence reconciliation.** Read every committed report
   under `ralph/reports/WATER-PROGRESS/`, then every later Water-related entry
   under `ralph/reports/FOUR-BIOME-BUILD/`. Build a 24-destination ledger using
   the same fields as Stormwood. Preserve the important distinction between a
   surveyed FAIL and genuinely unknown/never-surveyed; do not infer a visual
   grade from implementation or runtime-test reports.
4. **Water content-floor recount.** Reproduce the original census method and
   recount side chains, objectives, and accepted settlements from current
   shipping data. Reconcile the inherited `0/6`, `12/28–32`, and `0/3` figures,
   including why the objective target is a range if that remains unresolved.
5. **Bounded verification only where evidence cannot settle current state.**
   Prefer existing valid committed frames. If a fresh look is necessary to
   confirm an old defect or turn an unknown row into a first-look verdict,
   capture only the minimum ordinary-player day/night views of real shipping
   geometry. Record source SHA, build/export identity, renderer, camera/player
   context, time of day, output root, and a fail-closed manifest. A fresh frame
   may update a survey row but will not trigger repair work.
6. **Report without building.** Write the work-window record to
   `ralph/reports/STORMWOOD-WATER-SURVEY-0919/RESULTS.md`. Put the final
   per-biome status documents alongside the established conventions in
   `ralph/reports/STORMWOOD-PROGRESS/` and `ralph/reports/WATER-PROGRESS/`.
   Each final document will contain the named-location ledger, content-floor
   census, evidence/provenance gaps, and a concise description of what remains
   below the Meadows/Cloudreach standard. It will not scope or begin fixes.

## Evidence rules

- A report claim is not proof by itself. Trace each retained grade to its
  concrete committed receipt and, where available, its source/capture build and
  independent verdict. Mark unverifiable claims as such.
- Use only `PASS`, `POLISH`, `FAIL`, and `unknown`; explain any inherited
  `invalid` row and map it to `unknown` unless valid evidence supports another
  grade.
- Runtime tests can establish existence or behavior, not visual quality.
  Author self-ratings and missing-frame summaries cannot promote visual rows.
- Do not treat file presence, node counts, or planned prose as accepted
  player-facing content. Preserve disagreements between current data, older
  reports, and later handoffs in the final reconciliation.
- No game tests or imports are planned unless needed solely to reproduce a
  documented census. No capture is planned merely to make the ledger look
  complete; unresolved unknowns remain honest findings.

## Render-lock protocol

Before any screenshot capture, read `D:\tetherbound\RENDER_LOCK.json`. This
lane is fourth priority after Meadows, Cloudreach, and Combat and will yield to
all three. Claim the lock as `stormwood-water-survey` with an ISO-8601 UTC
timestamp only when it is absent or explicitly unheld, verify ownership before
launch, and release it immediately after success, crash, or abort. Never release
another lane's lock, terminate another lane's Godot process, or overlap a
render/import-heavy run. Reclaim a stale lock only under the directive's
greater-than-two-hour/no-corresponding-output rule and record that event. Never
combine `--headless` with a rendering driver.

## Completion bar

The lane is complete only when both biomes have an evidence-cited named-location
ledger, a reproducible current content-floor census, explicit unknown and
provenance-debt rows, and final status documents plus `RESULTS.md` committed and
pushed. Completion makes no claim that either biome is ready, accepted, or
reopened for development. The next action remains the owner's decision.

## Approval hold

After this plan is committed and pushed, stop. Do not start the reconciliation,
recount, Godot work, screenshots, or final reports until the separately committed
`PLAN-APPROVED.md` appears. Do not create that approval file locally.
