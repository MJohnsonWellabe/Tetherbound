# N11-TERRAIN-BAKE

**Source:** W03, W00, W04, W05, W11, W18, W20, W21's reports — all independently confirmed
this same red on `main`.

## Why
`data/terrain/playground/manifest.json` is stale against `data/config/terrain_playground.json`
— `test_terrain_bake_freshness.gd::test_playground_terrain_bake_is_committed_and_fresh` fails
identically on `origin/main` and on every lane branched from it today, confirmed independently
by at least seven lanes via `git diff` showing none of them touched the relevant config. (The
*scatter*-bake half of this same class of defect was already fixed on `main` earlier today by
commit `2724b5af`.) This is the one remaining actually-broken CI job blocking a fully green
`main`, and nobody owns it — it needs one coordinator-style bake-and-commit.

## Owns
`data/terrain/playground/**` (the baked output only — never hand-edit terrain data,
regenerate it) and `data/terrain/playground/manifest.json`.

## Do
1. Fetch `origin/main` fresh. Confirm the failure first:
   `godot --headless --path . --script tests/run_tests.gd -- --only=test_terrain_bake_freshness.gd`
   should show 1 failure on `test_playground_terrain_bake_is_committed_and_fresh`.
2. Run the terrain bake tool (`scripts/world/build_playground_terrain.gd` — check its exact
   invocation in `docs/AGENT_WORKFLOW.md` or a recent lane's report for the precise command;
   W05's report describes running the equivalent scatter bake and is a good model for the
   command shape).
3. Confirm the bake did not silently change any placement/region data it shouldn't have —
   diff the regenerated files against the committed ones and confirm the only change is the
   fingerprint/manifest plus whatever the config actually requires regenerating. If region
   bytes change unexpectedly, stop and investigate before committing (that would mean the
   config changed more than expected, or the bake tool has drifted).
4. Commit the regenerated `data/terrain/playground/**` and `manifest.json` together in one
   commit.

## Verify
- `test_terrain_bake_freshness.gd` passes clean (0 failures) after the re-bake.
- Confirm `test_scatter_perf_budget.gd` and other bake-adjacent tests still pass (the scatter
  bake was already fresh — make sure this change doesn't disturb it).
- Full `godot --headless --path . --import` + `smoke_playground.gd` pass on the result.

## Acceptance
`main`'s one remaining self-inflicted CI red (the terrain-bake freshness check) is closed with
a verified, minimal re-bake — no region or placement data changes beyond what regenerating
against the current config actually produces.
