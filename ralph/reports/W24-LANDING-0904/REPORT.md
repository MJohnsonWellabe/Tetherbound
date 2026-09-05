# W24-LANDING-0904 — landing report

Lane W24-LANDING: the one lane that lands other lanes' work onto `main`. Brief:
`ralph/briefs/0904/W24-LANDING.md` (on `claude/codex-merge-meadows-finish-dq12jj`).
This report is kept current per cycle; the per-lane table is the authoritative
landed / not-landed / not-yet-done ledger. Landing branches: `ralph/LAND-0904`,
`ralph/LAND-0904-2`, … Report and ledger commits live on `ralph/W24-LANDING-0904` and
ride into the next landing branch.

## Per-lane ledger (updated every cycle)

| Lane | Branch head | Report | Verdict | Detail |
|---|---|---|---|---|
| W00-ICONS | `8c2e5e19` | **complete** (final code commit `ddf23399`, four judged rounds, ceiling recorded) | **landing — PR #42** (`ralph/LAND-0904` @ `3fbd67ad`) | Diff inside ownership. Verified on the merged tree (below). The lane finished mid-cycle; its last two commits are report-only, so they were folded into the PR at `3fbd67ad` — the icons and script are byte-identical to what was verified, and a report without its final hash is not a complete report. |
| W19-CONTRACTS | `27f3156e` | **complete** | **done — first in batch 1** | Docs only: four contracts, D74/D75, two plan edits, all inside the brief's list. Nothing to reproduce (no test claimed, none applicable). Keeps D74 and D75 per the addendum. |
| W17-DENSITY-B2-B3 | `a2f1d23d` | draft — `RENDER_SECTION`, `FINAL_COMMIT` unfilled | **not yet done** | Lane active. Substance looks landable (20 tests / 7,851 assertions and 148 tests / 817 k assertions claimed green, both seen red first; five smokes with the known-benign set). Flags its own ownership escape: `scripts/world/item_cache_pickup.gd` (additive fifth `flag_key` argument, default-preserving) — no other 0904 lane names that file, so the escape is safe to land, recorded here as routed. W18 merges this branch, so W17 lands first or with it. |
| W09-VFX | `e75051c0` | draft — final hash, both judge sections and perf unfilled | **not yet done** | Lane active. Already renumbered its decision D74 → **D80** itself, matching the addendum. Touches `combat_manager.gd` (`_flash_at()`, `_finish_catch()`; explicitly leaves `_flee_pressed()` alone) — the contended file, and its edits sit clear of W10's and W12's. |
| W12-COMPANION | `2c9281a7` | draft — final hash and the test/judge sections unfilled | **not yet done** | Lane active. Touches `combat_manager.gd` with one line in `_begin_resolve()` (the result-beat hook the brief predicted) and three lines in `tab_backpack.gd`. |
| W05-TREELINE | `e75b961a` | draft — perf `AFTER_*` and `JUDGE_SECTION` unfilled | **not yet done** | Lane active. Independently found the same stale-bake cause this lane repaired, and its re-bake carries the Linux fingerprint `4984520267706256` for its own modified `vegetation.json`. It is the only lane allowed to touch that file, so when it lands its manifest supersedes the repair below and the freshness tests must be re-run on the merged tree (they will be). 256 region files in the diff. |
| W18-DENSITY-B4-B5 | `56027a7a` | draft — `FILL` in the measurements, tests, visual and final-commit sections | **not yet done** | Lane active. Carries a merge of W17 `434ec537`, so it cannot land before W17. Creates a D74 (→ D78). |
| W23-DIFFICULTY | `187c2922` | draft — `SMOKE_RESULTS_PLACEHOLDER`, `FINAL_COMMIT_PLACEHOLDER` | **not landed** | Lane paused. **The blocker is the report, not the code**: its unit and harness claims reproduce exactly (below), and the `verify-gate-b-core` red on its branch is `main`'s own flake, not this lane's (below) — the earlier reading that its chase-speed change caused it is withdrawn. Not landable until the smokes it names are shown and the hash filled. Also self-reports one line outside ownership in `encounter_director.gd` (fine, it belongs with the line it sits beside) and commits two ~1 k-line JSON payloads under its report dir, against the "verdicts, not payloads" rule. |
| W10-TRAINER-RULES | `505ae5e4` | skeleton — "runs and final hash filled in below" | **not done** | Lane paused. No test claims and no hash, so nothing to reproduce. Its own CI runs were all cancelled by later pushes; none ever completed. Creates a D74 (→ D79). |
| W01, W02, W04, W06, W08, W11, W13, W14, W15, W20, W21, W22 | various, 1–5 ahead | none | **not yet done** | No report on the branch; left alone per the brief. |
| W03, W07, W16 | — | — | **no branch pushed** | Nothing at `origin/ralph/<LANE>-0904` this cycle. |

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

### The finale is broken on `main`, and it blocks every landing

PR #42's `verify-gate-evidence-shard` failed at `smoke_gate_e_finale`:
`FAIL: exploration never came back after 'warden_aldis''s fight`. Everything before it
passes — the Warden falls, the tether machine is shut down, the legendary is freed, the
roster decision resolves, the region answers, the objective chain terminates — and then
the player cannot move.

**Not this PR's, established rather than assumed.**

- The finale **passed on `main` at `90efc0d5`** (run 33916194315, `Verify gate_e_finale`
  20:41→20:45 UTC), the run whose only red job was the icon test this PR fixes.
- PR #42 adds six PNGs, six `.import` files, one Python generator and two manifest
  fingerprint lines. None is reachable from locomotion after a fight.
- Reproduced here on the PR head (`3fbd67ad`) and on a tree whose code is byte-identical
  to `origin/main` (`git diff origin/main HEAD -- ':!ralph'` is empty), same failure text.
- No CI run since `90efc0d5` had executed the step at all: fail-fast cancelled the shard
  on the bake reds first. Repairing those is what let the finale run and exposed this.

**Mechanism, to the commit.** `04d844d0` (`feat(cloudreach): establish realm reward
checkpoint`) gave the Warden `"victory_conversation": "stronghold_warden_realm_reward"` in
`data/config/bands/band5_stronghold_approach/trainers.json` and added the auto-play in
`scripts/combat/encounter_director.gd` (+19 lines), so a dialogue panel now opens by itself
the moment the Warden falls. `sequence_director.gd:747` computes
`modal := panel or is_fading() or _adopting` and line 774 holds
`set_locomotion_enabled(not modal)`, so locomotion stays off while that panel is up — which
is exactly when `smoke_gate_e_finale.gd:814` checks it.

**Not fixed here, deliberately.** The honest fix is to teach the finale smoke the new beat
(advance and close the Warden's victory conversation before asserting locomotion), and that
is the finale lane's file, not this lane's. More importantly it would mean adapting the
Meadows' own exit smoke to accommodate Biome 2 content, which is a decision above a landing
lane:

> **Hard-rule concern for the coordinator and the owner.** `CLAUDE.md` says *no Biome 2
> implementation until the Meadows passes its exit gate*, and any reconnection view is
> distant and non-enterable. Three commits on `main` since `90efc0d5` — `04d844d0`,
> `3f9e1a14`, `47ca2e12` — build Cloudreach Cliffs: a realm-heart autoload, a keyed realm
> arch and a Heart socket built into `scripts/world/playground_world.gd` (`+92` lines,
> including an arrival path that calls `_player.set_physics_process(false)`), a
> `cloudreach_cliffs.tscn`, and the Warden handoff above. That work has broken the Meadows
> finale. This lane records it; it does not touch it.

**Consequence for the push.** Every landing from now on carries this red, batch 1 included,
so under this lane's own rule ("merge only on a fully green run whose code jobs executed")
nothing can merge until the finale is green again on `main`. That is the one thing blocking
the queue, and it needs the finale owner (W06) or whoever owns the Cloudreach work.

### W13-PROGRESSION-FEED verified by this lane (worktree at `94a84c5f`)

| Command | Report claims | W24 result |
|---|---|---|
| `--only=test_progression_feed.gd,test_bond.gd,test_level_up_announcement.gd,test_candy_progression_safety.gd` | 80 tests, 249 assertions, 0 failed | **80 tests, 249 assertions, 0 failed** |
| the twelve-file set including `test_save_format.gd` | 336 tests, 1290 assertions, 0 failed | **336 tests, 1290 assertions, 0 failed** |
| `godot --headless --path . --import` ×2 | — | 0 `SCRIPT ERROR` / `Parse Error` |

One defect in its evidence: the report says the blind verdict is at
`ralph/reports/W13-PROGRESSION-FEED-0904/JUDGE.md`, and that file is not committed — only
`shots/_sheet_round1.png` is. The lane is active and may still add it; the claim cannot be
reproduced until it does.

### W17-DENSITY-B2-B3 verified by this lane (worktree at `a2f1d23d`)

| Command | Report claims | W24 result |
|---|---|---|
| `--only=test_band_pickups.gd` | 20 tests, 7851 assertions, 0 failed | **20 tests, 9599 assertions, 0 failed** (assertion count scales with the data walked; test count and result match) |
| the eight-file band set | 148 tests, 817,100 assertions, 0 failed | **148 tests, 817,100 assertions, 0 failed** |
| `tests/smoke_playground.gd` | `smoke: OK`, 46 pickups placed | **exit 0, `smoke: OK`**, `placed 46 band pickups (0 already taken, 9 nudged off scatter, 0 unclear, 0 without ground)`, known-benign `material` line ×2 |

Its substance is landable; only its report's `RENDER_SECTION` and `FINAL_COMMIT` are unfilled.

### Batch 1 assembled and waiting on the finale

`ralph/LAND-0904-2` off `origin/main`: W19-CONTRACTS and W13-PROGRESSION-FEED merged with
no conflicts, plus one landing commit renumbering W13's decision **D74 → D76** (the record
renamed and every reference rewritten: two config `_comment`s, six script and test headers,
the `CURRENT_STATE` row and the lane's own report; W19's D74/D75 untouched). Not pushed
while the finale red stands, since it would only reproduce it.

### Cycle 1 close-out

- Both finale reproductions completed after the section above was written, and both failed
  exactly as predicted: PR head `3fbd67ad` and the `main`-equivalent tree, first attempt
  each, same assertion. Base-red is proven, not inferred.
- One standing-down comment posted on PR #42
  (`#issuecomment-5548679310`): the failing check, the evidence it is not this PR's, the
  cause commit, why no fix is ported, and that no re-run was spent because a re-run cannot
  help a failure that reproduces on the base branch.
- Batch 1's merged tree (`ralph/LAND-0904-2`) passes `smoke_gate_b_continuous` —
  `gate B continuous (CORE): OK` — which is the run W13's report asked the coordinator to
  make, and `smoke_progression_feedback` passes on W13's own branch
  (`Progression feedback: OK`, known-benign `material` line ×1).
- **Nothing merged this cycle.** Under this lane's rule (merge only on a fully green run
  whose code jobs executed) PR #42 cannot merge while the finale is red, even though every
  job it exists to fix is now green and it strictly reduces `main`'s red set. That is the
  coordinator's call to make, and it is the single decision blocking the whole queue:
  either the finale is fixed on `main` (the finale lane, or whoever owns Cloudreach), or
  this lane is told that a proven pre-existing red does not block a landing that removes
  reds. This lane will not override the rule on its own.


## Cycle 3 — the owner's consolidation directive, 2026-09-05 02:24 UTC

The directive changed this lane's job: stop requiring each lane's own verification, merge
the converged lanes onto one branch, run **one** pass over the merged tree, and **do not
block on `main`'s pre-existing finale regression**. Done, in that order.

### LANDED — PR #42, merge commit `c5a16dfb`

`git merge-base --is-ancestor 3fbd67ad origin/main` confirms it. **W00-ICONS** and the
bake-manifest repair are on `main`; the six candy and mushroom PNGs are in
`assets/ui/icons/items/`. Its final CI run had every job green except
`verify-gate-evidence-shard`, and within that shard every step passed except
`gate_e_finale` — including `tournament_bracket`. Landed with that red per the directive,
which unpolls every other lane's CI: `main` was red on the icon test and on four
bake-dependent jobs until this merge.

### PR #45 — the consolidated batch, `ralph/LAND-0904-3` @ `8873f93b`

Off current `origin/main`, carrying seven lanes: W00 (via `ralph/LAND-0904`), W19 and W13
(via `ralph/LAND-0904-2`), W18, W04, W12, and W17's pickups loader through W18's merge of
its branch. PR #43 was closed as superseded, with a comment naming exactly what carries
over. 68 commits, 187 files.

**The one consolidated pass, on the merged tree:**

| Command | Result |
|---|---|
| `godot --headless --path . --import` ×2 | 0 `SCRIPT ERROR`, 0 `Parse Error` |
| the 26-file unit set across every merged lane's owned tests | **533 tests, 829,776 assertions, 0 failed** |
| `tests/smoke_playground.gd` | exit 0, `smoke: OK`, `placed 101 band pickups (0 already taken, 9 nudged off scatter, 0 unclear, 0 without ground)`, known-benign `material` line ×3 |
| `tests/smoke_gate_b_continuous.gd` (W19+W13 subset) | `gate B continuous (CORE): OK` |

Conflicts were confined to `docs/CURRENT_STATE.md`, where each lane appends its own row;
resolved as a union, with one stale combined row dropped because W13 replaced it with two
more specific ones. No bake input changed, so no re-bake was needed.

**Decision renumbering in this batch:** W19 keeps D74/D75, W13 → D76 (in `-2`), W18 → D78,
W04 → D81, and W12 → **D83**, the next free number after the addendum's reserved block
(D77 W23, D79 W10, D80 W09, D82 W02), since W12 was not in the addendum's list. Every
reference that means each record moved with it. Eight `.uid` sidecars the lanes' own
scripts needed were committed too.

### The blind-judge round, and it is not a pass

Five merged lanes already carried verdicts. W13 had frames but cited a `JUDGE.md` it never
committed, so this lane ran the round on the sheet that existed — no new render, since a
software-GL world capture costs 20–50 minutes. Verdict committed at
`ralph/reports/W13-PROGRESSION-FEED-0904/JUDGE.md`; the judge was code-blind and told
nothing about what changed.

**"Not shippable for a first playable."** Three findings are unambiguously W13's own: the
feed's tick labels at **1.34:1** ("over grass they will not exist"), the bond readout at
**1.85:1** ("the least legible text in the frame"), and the moment banner drawn over a live
world interaction prompt, ghosting both at 1.28:1 in a still with no fight running. It also
reached independently the limitation W13's report admits — the survey was shot over a flat
scaffold, so real-terrain legibility is still untested — and it notes the Team screen's
one-NEXT behaviour cannot be judged because that tab was never shot (the runtime smoke does
assert it). Where the plate is used, type measures 8.8:1 to 14.7:1, and nothing reads as
imported from another game. The rest of its list is pre-existing furniture no lane in this
batch owns: the health and food pills covering their own bars, portraits, minimap, hotbar,
safe-area margins.

Landed anyway, per the directive: the tests are green and the feature works; what the judge
found is that several readouts are **drawn too faint to read**, which no test asserts. It
wants a contrast pass and a re-shoot over real terrain, not a revert. Recorded here so the
owner decides rather than discovering it in play.

### Still open

- The finale regression stands on `main` (`04d844d0`'s Warden victory conversation).
  `tests/smoke_gate_e_finale.gd` is W06-FINALE's file. Every landing carries this red until
  that lane fixes it.
- The Biome 2 hard-rule concern stands, unchanged and untouched by this lane.
- Not yet landable: W05, W09, W17's own commits, W22, W23, W01, W10 (reports still carry
  unfilled placeholders); W02, W06, W07, W08, W11, W14, W15, W20, W21 (no report). W17 and
  W23 are pre-verified by this lane and will land fast when their reports close.
