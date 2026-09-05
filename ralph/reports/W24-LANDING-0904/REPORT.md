# W24-LANDING-0904 — landing report

Lane W24-LANDING: the one lane that lands other lanes' work onto `main`. Brief:
`ralph/briefs/0904/W24-LANDING.md` (on `claude/codex-merge-meadows-finish-dq12jj`).
This report is kept current per cycle; the per-lane table is the authoritative
landed / not-landed / not-yet-done ledger. Landing branches: `ralph/LAND-0904`,
`ralph/LAND-0904-2`, … Report and ledger commits live on `ralph/W24-LANDING-0904` and
ride into the next landing branch.

## Per-lane ledger (updated every cycle)

| Lane | Branch head seen | Report | Verdict | Detail |
|---|---|---|---|---|
| W00-ICONS | `38e01661` | yes (final hash still `_(filled in below)_`, round-3 verdict written, lane active) | **landing — PR #42** (`ralph/LAND-0904` @ `a20e173f`) | Diff inside ownership. Verified on the merged tree, see cycle 1. Any later W00 round lands in a batch. |
| W19-CONTRACTS | `27f3156e` | yes, complete | **done, queued for batch 1** | Docs only, 9 files, all inside the brief's list. Keeps D74 / D75 per the addendum. No tests to reproduce (none claimed, none applicable). |
| W23-DIFFICULTY | `187c2922` | draft: `SMOKE_RESULTS_PLACEHOLDER`, `FINAL_COMMIT_PLACEHOLDER` | **not landed** | Lane paused. Its own CI run 33920831882 on `187c2922`: `verify-gate-b-core` FAILED on both attempts with `village tools: natural controller travel could not activate Quarry Foreman cycle 1 (6.3m away, arbiter winner=EncounterDirector under MeadowsPlayground)` — a different failure from the one `main` showed at the lane base (`ef16544f`: tutorial catch line-of-sight), and `main` passed Gate B at `3f9e1a14`. Consistent with this lane's `aggression.chase_speed` 3.4→5.6 letting a wild take the interact line near the Foreman. `verify-combat-shard` combat / riding / boss / trainer_battle green; aggression cancelled by fail-fast; tournament_bracket and gate_e_finale never ran. Also one line outside its ownership (`scripts/combat/encounter_director.gd`, self-reported) and two ~1 k-line JSON payloads committed under its report dir. Unit claims reproduced by W24: see cycle 1. Needs its lane (or a resumed one) to make Gate B green on the branch. |
| W10-TRAINER-RULES | `505ae5e4` | skeleton only: "runs and final hash filled in below" | **not done** | Lane paused. No test claims, no hash, so nothing to reproduce; not landed by rule. Its own CI runs were all cancelled by later pushes (never completed). Touches `data/dialogue/trainers.json`, `data/config/trainers.json`, `docs/CURRENT_STATE.md`, `MEADOWS_PROGRESSION_SPEC.md` (all inside ownership) and creates a D74 (→ D79 when landed). |
| W18-DENSITY-B4-B5 | `56027a7a` | draft with `FILL` placeholders (tests, visual, final commit) | **not yet done** | Lane active (wave 2). Branch carries a merge of W17 (`434ec537`: the loader `band_pickups.gd`, `item_cache_pickup.gd`, the `playground_world.gd` hook, bands 2–3 pickups) — so W18 cannot land before W17 has a report. Creates a D74 (→ D78). |
| W01, W02, W04, W06, W08, W09, W11, W13, W14, W15, W17, W20, W21, W22 | various | none | **not yet done** | No `REPORT.md` on the branch; left alone per the brief. |
| W03, W05, W07, W12, W16 | — | — | **no branch pushed** | Nothing on `origin/ralph/<LANE>-0904` at cycle 1. |

## Decision-number renumbering (addendum 2026-09-05 01:15 UTC)

Applied at landing time, filenames and every in-diff reference:

| Lane | Created | Lands as | Status |
|---|---|---|---|
| W19 | D74 (Burrowback), D75 (level-gate rule) | D74, D75 (kept) | queued, batch 1 |
| W13 | D74 | D76 | not yet done |
| W23 | D74 | D77 | not landed (see above) |
| W18 | D74 | D78 | not yet done |
| W10 | D74 | D79 | not done |
| W09 | D74 | D80 (lane does its own) | not yet done |
| W04 | D74 | D81 | not yet done |
| W02 | D74 | D82 | not yet done |

Later decisions take D83 onward.

## Cycle 1 — 2026-09-05 01:06–… UTC

### The state of `main` at cycle start (`81dd6c40`)

Not what the brief expected. `verify-unit-tests (3)` was green; the icon test had moved
to shard 2 with the test files `main` gained since the lane base. The red on `main` was:

| Job | Failure | Cause |
|---|---|---|
| `verify-terrain-bake-freshness` | `test_terrain_bake_freshness.gd::test_playground_terrain_bake_is_committed_and_fresh` | see below |
| `verify-scatter-bake-freshness` | `test_scatter_perf_budget.gd::test_playground_bake_is_committed_and_fresh` | see below |
| `verify-unit-tests (1)` | the scatter freshness test | same |
| `verify-unit-tests (2)` | the terrain freshness test **and** the six icon tests | same + W00 |
| the smoke shards | cancelled by fail-fast | — |

**Root cause of the bake reds (verified, not assumed).** `f2dd20e4`
(`test(visual): make VP0 capture failures trustworthy`, on `codex/meadows-visual-parity`,
merged to `main` by `0f29c405`) changed exactly one line in each of
`data/terrain/playground/manifest.json` and `data/scatter/playground/manifest.json`: the
`config_fingerprint`. It changed no bake input — `data/config/terrain_playground.json` and
`data/config/vegetation.json` last changed at `3c73aab5` (#29), where both bakes were
re-run — and no region / placement bytes (`regions: 64`, `bytes: 29836475` unchanged).
Both guards compare the manifest fingerprint with a hash of the live config text, so the
committed bakes read as stale against a config that had not moved. (The W00 report
attributes this to `ef16544f`; that commit is docs-only — the manifest change is its
parent's second parent.)

**Repair (commit `2724b5af` on `ralph/LAND-0904`).** Restored the two fingerprint lines
from `90efc0d5` (`main` immediately before the Codex merge). This is what a full re-bake
against the unchanged config writes, and it was verified on the merged tree rather than
assumed: `test_terrain_bake_freshness.gd` 3 tests / 8 assertions / 0 failed;
`test_scatter_perf_budget.gd` 3 tests / 6 assertions / 0 failed (both were 1-failed on
`origin/main` in the same container first). This is a landing-lane repair to `main`, not
lane code; it rides with W00 because the brief forbids merging a red run and no run could
be green without it. Nothing else was changed.

### W00-ICONS verification on the merged tree (`a20e173f`)

| Command | Result |
|---|---|
| `godot --headless --path . --import` ×2 | 0 `SCRIPT ERROR` / `Parse Error` (one import pass leaves the six new textures un-importable — the icon test showed 2 failures after a single pass and 0 after the second, the same cold + verify sequence CI runs) |
| `run_tests.gd -- --only=test_item_icons.gd` | 7 tests, 276 assertions, 0 failed |
| `run_tests.gd -- --only=test_terrain_bake_freshness.gd` | 3 tests, 8 assertions, 0 failed |
| `run_tests.gd -- --only=test_scatter_perf_budget.gd` | 3 tests, 6 assertions, 0 failed |
| `tests/smoke_art.gd` | exit 0, `art: OK`, 0 `^ERROR:` / `SCRIPT ERROR` lines |
| `tests/smoke_playground.gd` | exit 0, `smoke: OK`; 1× `ERROR: Parameter "material" is null` (the known-benign alpha-resize line, `docs/AGENT_WORKFLOW.md` §"known-benign"; set did not grow) |

Diff vs `origin/main`: `tools/gen_item_icons.py`, six PNGs + six `.import`, the lane's
report dir (four contact sheets, one per judge round). Inside ownership.

PR: **#42 "Land W00-ICONS"** — `ralph/LAND-0904` @ `a20e173f`, opened 01:23 UTC. CI runs
33935971628 (push) and 33935993180 (pull_request) queued at open. Merge gate: every
code job executed and green.

### Gate B on `main`'s head is a flake, not a regression

`verify-gate-b-core` failed on `main` @ `81dd6c40` (run 33933772655) with the same
Quarry Foreman arbiter message W23's branch shows, on both attempts. The only code that
changed on `main` between the passing run (`3f9e1a14`) and that one is Cloudreach-only
(`scripts/world/cloudreach_world.gd`, `data/config/cloudreach_chapter.json`, one test),
which the Meadows playground never loads. Run on the landing tree (`a20e173f`) in this
container: `godot --headless --path . --script tests/smoke_gate_b_continuous.gd` →
`gate B continuous (CORE): OK — a fresh save walked opening, road gate, village tools and
tournament readiness in order` (+163 s). So the failure is a timing race in the smoke
around the Foreman (`EncounterDirector` wins the interact line when a wild is close),
seen on CI runners, not reproducible here, and not caused by W00, the manifest repair,
or W23. It is not this lane's to fix; recorded here so nobody re-diagnoses it.

### W23-DIFFICULTY checks run by W24 (worktree at `187c2922`)

| Command | Report claims | W24 result |
|---|---|---|
| `godot --headless --path . --import` ×2 | — | 0 `SCRIPT ERROR` / `Parse Error` |
| `run_tests.gd -- --only=test_combat_difficulty.gd,test_chapter_curve.gd,test_encounter_combat_override.gd` | 36 tests, 543 assertions, 0 failed | **36 tests, 543 assertions, 0 failed** |
| `tests/smoke_combat_baseline.gd` | OK, 15 rows, 24 seeds | **OK (15 rows, 24 seeds each)**, 2.1 s |
| its own CI run 33920831882 | (pending) | combat / riding / boss / trainer_battle green; aggression cancelled by fail-fast; tournament_bracket, gate_e_finale skipped; gate-b-core red with the `main` flake above |
| `smoke_aggression`, `smoke_tournament_bracket`, `smoke_gate_e_finale` in the worktree | (pending) | _(running)_ |

### Not done this cycle, deliberately

- No batch opened: batch 1 (W19 + whatever else qualifies) starts from `origin/main`
  after #42 merges, so the bake repair and the icons are its base.
- W23 not landed (Gate B red on its branch — above). W10 not landed (skeleton report).
- No lane code fixed. No history rewritten. Nothing pushed to `main`.
