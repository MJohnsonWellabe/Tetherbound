# Handover — CI consolidation landed on `main`, two lanes open next (2026-08-25)

**Read this before `ralph/ASSESSMENT_2026-08-23.md` / `ralph/ACTIVE_TASKS.md`.**
Those still describe true current gate state for implementation work, but this
file is what changed today and what the *next* coordinator session should
start: two concurrent lanes, Gate F and WORLD-GRASS. `ralph/START_HERE.md`
points here.

## 1. What this session did

Two days of red/cancelling CI on the consolidation branch
(`claude/ci-consolidation-main-sync-lmztz6`, see
`ralph/HANDOVER_CONSOLIDATION_2026-08-25.md` for the original diagnosis) are
resolved:

- Fixed the SIGIL-SEAL gate/key placement blocker
  (`scripts/world/playground_world.gd`'s `GATE_KEY_AT`, computed via
  `tools/_probe_key_site.gd`, not eyeballed).
- Root-caused `verify-unit-tests` shard timeouts to individual test methods
  paying for a full `RULES.all_placements()` (~200s, all ten vegetation
  layers against the real corridor) when they only ever read one or two
  layers back out. Fixed at the test level in `tests/test_harvest.gd`,
  `tests/test_harvest_permanence.gd`, `tests/test_scatter_rules.gd` (each
  verified locally, 0 failures, before pushing). Went to six unit-test shards
  for margin.
- Added a third flake-retry attempt to `smoke_traversal.gd` in
  `verify-core-verb-shard` after diagnosing (via new
  `tools/_probe_wedge_53_neg65.gd`) a **real, pre-existing, still-unfixed**
  player-slide wedge on a ~10-15° slope near a rock at world (53,-65) —
  matching a previously-documented OF15 defect. This is mitigated (3
  attempts, matching its observed ~2-in-a-row flake rate), not fixed. The
  underlying physics fix was deliberately not attempted: it's a traversal-
  philosophy change, which `CLAUDE.md` requires flagging rather than
  inventing. **Whoever next touches player slope/slide physics should look at
  this before assuming it's new.**
- Fast-forward merged the consolidation branch into `main`
  (`571d9e86` → `e56da1d7`, 220 commits, verified with
  `git merge-base --is-ancestor` first).
- Cherry-picked `ralph/WORLD-GRASS`'s docs-only diagnosis commit (`12027a31`)
  onto `main` — see §3.
- `main`'s CI run after the merge (`#2422`) came back green on every gating
  job. `verify-continuous-core-known-red` is expected-red
  (`continue-on-error: true`, tracking a real unfixed CONTINUOUS-CORE defect
  on purpose — see its own header comment in `ci.yml`, do not remove the
  flag without fixing the underlying thing). The separate `Release` workflow
  (export build) also ran green (`#629`).

**Confirm before trusting this document's "green" claim has not gone stale:**
check the latest `CI` run on `main` in GitHub Actions before starting either
lane below. This session's own last observed state: run `#2422`
(`32858474097`) on `e56da1d73b5a2d8c2c9ca7e6258d9a10ce5ed3c2`.

## 2. Branch state

`origin/main` is at `4958a745` (`e56da1d7` plus the WORLD-GRASS docs
cherry-pick and this handover). Remote branches as of this session's end:
`main`, `claude/ci-consolidation-main-sync-lmztz6` (now redundant — its
content is `main`'s history, safe to delete once nothing else needs it),
`ralph/WORLD-GRASS`, and `ralph-status` (permanent bookkeeping — never
delete this one).

`ralph/VIS-MAKE`, `ralph/VIS-UI`, `ralph/VISUAL-CORRIDOR`,
`ralph/integration-W2`, `ralph/integration-W3`, `ralph/CONSOLIDATION` were
**already deleted from the remote before this session touched them** — this
session's local git cache still had stale refs for them, which briefly made
it look like `ralph/integration-W2`/`W3` carried real unlanded work
(creature-presentation art, `SITE-DRESSING`, `BAND2-FLOOR` vegetation,
`OP23-FIXPACK`'s stronghold camera/map/auto-run/bond-curve/trait work).
**Verified none of that is lost**: a prior `SUPERSESSION`/
`INTEGRATION-BOOKKEEPING` pass (`ralph/DONE.md`, commits around `7d452a97`)
already reconciled and landed the equivalent content on `main` through a
different merge path before those branches were retired — spot-checked
several files each integration branch uniquely carried
(`tools/capture_creature_presentation.gd`, `tests/test_trait_ui.gd`,
`tests/test_map_zoom_persistence.gd`, and OP23-FIXPACK's own commit hash)
and all are present on `main`. Nothing further to do here.

`ralph/WORLD-GRASS` is now fully redundant too, by the same check — every
file it uniquely carried (a large amount of probe/capture tooling from an
older divergent ancestor, plus the diagnosis doc this session cherry-picked)
is already on `main`, byte-identical, either via that same supersession pass
or via the cherry-pick above. It's safe to delete but this session's
permission scope didn't allow deleting it — the next session or the owner
should remove it.

## 3. Lane 1 — Gate F (`ralph/GATE_F_PROTOCOL.md`)

The owner supplied a materially more rigorous Gate F protocol than the
informal chaining-harness pass this repo already ran on 2026-08-23
(`ralph/GATE_F_EVIDENCE_2026-08-23.md`). It is now vendored at
**`ralph/GATE_F_PROTOCOL.md`** verbatim. Read that file in full before
starting this lane — it is long and self-contained (Fable as playtest
director/reviewer, Sonnet as neutral operator, full telemetry/screenshot
schema, blind-first analysis, historical-backlog reconciliation with a
measured capture-rate metric). Its own §18 exit criterion is the bar, not
"every generated ticket has a commit."

Two things worth knowing before assigning this lane:

- **The file the earlier session's task description referenced
  (`GATE_F_AUTHORITATIVE_PLAYTEST_AND_BACKLOG_REGENERATION.md`, said to have
  been owner-uploaded 2026-08-24) never existed anywhere in this repo's
  git history.** It could not be reconstructed or invented. This concern is
  now moot — the owner re-supplied the actual content on 2026-08-25 and it's
  vendored as `ralph/GATE_F_PROTOCOL.md`. Nothing further to chase here.
- 2026-08-23's evidence pass remains valid historical input under
  `ralph/GATE_F_PROTOCOL.md` §16 (the reconciliation step), not a substitute
  for running the new protocol.

## 4. Lane 2 — WORLD-GRASS (ground-plane / grass visual work)

Owner reference: a Godot soulslike "PCG Forge" tall-grass/procedural-world
demo, already vendored with provenance in `docs/ASSET_LEDGER.md` as
`docs/reference/moong-01/02/03-*.jpg` (video frames, not the mobile
screenshots re-shared alongside this handover — those are the same source
video, lower quality, not separately vendored). Judge reference only, same
footing as the existing Palworld frames beside them; not a palette
authority (keyart still wins).

Full contract: `docs/ralph-prompts/72-WORLD-ground-cover-and-mid-layer.md`.
Diagnosis, measured on `main` (originally at `ded2e697`, now re-verify
against current `main`): `vegetation.json`'s `grass` layer is placed in
quantity (110 clumps × 130, 900 strays, a 2400 verge) but scaled to
0.14–0.42 — a few centimetres tall — while `bushes`/`trees` scale
0.6–1.5/0.55–1.35. `corridor_fill.density_scale` for grass sits at 1.0
where bushes/trees sit at 6.0, so the fill covering the 7.5km outside
authored clumps barely places any, and `lod_range` 55m leaves a bald ring
around the player. Net: the player sees the terrain splat texture, not
grass.

**No new assets — none may be added.** `Grass_Common_Tall` and
`Grass_Wide_Tall` are already in the layer's `models` and already vendored,
with `Fern_1`/`Clover_1`/`Clover_2` available for a mid-layer.

**The sequencing prerequisite the diagnosis doc names is already satisfied.**
It says merge `ralph/VISUAL-GROUNDCOVER` (`ea589dd9`) first — that commit's
flower/bush rescale must land before the grass work so the ground doesn't
end up sparser. **`ea589dd9` is already an ancestor of `main`** (it rode in
with the consolidation fast-forward — confirmed via
`git merge-base --is-ancestor ea589dd9 origin/main`). This lane can start
directly on the grass numbers; no separate merge step is needed first.

**Binding constraint: GPU, unmeasured in any headless container**
(`PERF-ROG-GPU`). `test_scatter_perf_budget.gd` caps total placements at
260,000 against a current bake of ~144,456 — that's the headroom, and the
cap is not to be raised to fit a chosen number. `OP23-01` took per-frame CPU
from 33-40ms to 3.8-4.7ms; this lane does not get to spend that win. State
GPU risk as risk in any findings; do not claim a frame rate without ROG
Ally evidence.

Relevant tests to run before/after: `test_veg_corridor`, `test_scatter_rules`,
`test_scatter_perf_budget`, `test_band_vegetation`,
`test_scatter_fingerprint_covers_bands`. This is visual-affecting work —
`ralph/conventions.md`'s visual-judge requirement applies; render the actual
change and get a blind critic look at it against `docs/reference/moong-*.jpg`
before calling it done.

## 5. Parallel-safety between the two lanes

No file collision: Gate F is read-only against the shipped build until its
remediation loop starts (§17 of its own protocol), and even then remediation
work is scoped per-finding by the coordinator, not blanket-owned by the Gate
F lane. WORLD-GRASS's exclusive surface is `data/config/*/vegetation.json`,
`scripts/world/scatter_rules.gd`, and the vegetation test files listed above.
These two lanes can run concurrently from the start.

If Gate F's playtest surfaces its own grass/ground-cover findings, route them
to the WORLD-GRASS lane through the coordinator rather than letting Gate F
remediation duplicate that work.
