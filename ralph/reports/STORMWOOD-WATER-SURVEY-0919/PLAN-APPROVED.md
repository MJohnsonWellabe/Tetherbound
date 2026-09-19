# Stormwood/Water survey 2026-09-19 plan — approved

Reviewed against `docs/CODEX_GOAL_2026-09-19_STORMWOOD_WATER_SURVEY.md`:

- Correctly read-only: no game source, scene, data, shader, test, or asset
  changes; no content added; no location promoted without valid evidence; no
  Meshy spend; no touching Meadows, Cloudreach, or combat work.
- The evidence-reconciliation order (Stormwood ledger and content-floor
  recount, then Water's, then bounded verification only where evidence can't
  settle current state, then report) matches the goal doc and is appropriately
  rigorous — tracing every retained grade to a concrete committed receipt
  rather than copying the inherited snapshot forward unchecked.
- Correctly distinguishes a genuinely surveyed FAIL from a never-surveyed
  unknown row (Water's 22 unsurveyed destinations in particular) rather than
  blurring the two, and correctly refuses to let file presence, node counts,
  or a passing runtime test stand in for accepted player-facing content or
  visual quality.
- Render-lock handling is correct: fourth priority behind Meadows, Cloudreach,
  and Combat, yielding to all three, same claim/release/reclaim protocol as
  the other lanes.
- Completion bar is appropriately bounded: an evidence-cited ledger and census
  for both biomes, explicit unknown/provenance-debt rows, no claim that either
  biome is ready or reopened for development.

Proceed with the ordered work in `PLAN.md`, starting with Stormwood evidence
reconciliation. Update `RESULTS.md` as each stage completes. If the inherited
snapshot numbers turn out to still be accurate, say so plainly rather than
manufacturing a change; if they've drifted, show the reconciliation work that
found the difference.
