# Meadows 2026-09-19 plan — approved

Reviewed against `docs/owner/OWNER_DIRECTIVE_2026-09-19_PARALLEL_MEADOWS_CLOUDREACH_LANES.md`:

- Scope is the village-passage harness repair (`tools/gate_f/village_passage_route.gd`,
  its `operator_harness.gd::_walk_loop` adapter, `tests/test_gate_f_village_passage.gd`)
  and continuing the Meadows campaign in order from there. No Cloudreach, Stormwood,
  or Water work. No change to production fence geometry, progression, combat balance,
  creature stats, or target selection to force the evidence harness to pass — the plan
  is explicit that this is a harness-navigation defect, not a game defect, and treats
  it accordingly.
- Render-lock handling (`D:\tetherbound\RENDER_LOCK.json`, claim/release, 2-hour
  staleness reclaim, Meadows priority) matches the directive exactly.
- Evidence contract (report first-attempt results, don't silently overwrite a retry,
  no ledger promotion from a self-report) matches existing project standards.

Proceed with the intended sequence in `PLAN.md`. Continue reporting to
`ralph/reports/MEADOWS-0919/RESULTS.md` as work progresses — a mid-window update is
fine, doesn't need to wait for full completion. Flag back (in `RESULTS.md` or a new
plan note) if the passage repair investigation turns up something that looks like it
needs a fence-geometry or progression change after all; that would be outside this
approval and needs another look before proceeding.
