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


## Cycle 4 — the batch landed, 2026-09-05 06:40 UTC

### LANDED — PR #45, merge commit `fdf70ab4`

`git merge-base --is-ancestor d7d7df06 origin/main` confirms it, and each of the eight
lane branches is individually an ancestor of `main`: W00 (via #42), W19, W13, W04, W12,
W18, W17 and W09, plus W23. Nine decision records, all uniquely numbered, are on `main`.

**Merged on a fully green run — no waiver used.** Two CI runs exist for the head
`d7d7df06`. The pull-request run **33949277496 is green on every job**, including
`verify-gate-evidence-shard`; the push-event run 33949278979 failed that one shard. Same
commit, same tree, opposite results.

### Correction: the finale failure is intermittent, not deterministic

Earlier cycles of this report said `smoke_gate_e_finale` reproduces deterministically. That
was the honest reading of the evidence then — it failed on `main`'s own run twice, on this
lane's PR head, and on a locally built tree byte-identical to `origin/main`, four failures
with no counter-example. **It now has a counter-example: it passed on run 33949277496.**
So the correct statement is that the failure is a **race**, not a permanent break. The
mechanism recorded on PR #42 remains the likely cause — `04d844d0` gave the Warden an
automatic `victory_conversation`, and `sequence_director.gd` holds locomotion while that
dialogue panel is open, so whether the smoke's check lands before or after the panel closes
decides the run. That also explains why it began appearing only once the bake reds were
repaired and the shard got far enough to reach the finale step at all.

This does not change what the fix needs to be, and it does not change whose file it is
(`tests/smoke_gate_e_finale.gd`, W06-FINALE's). It does change the severity: `main` is not
permanently broken at the finale, it is flaky there, and a run can legitimately go green.

### Final verification, on the merged tree, before the push

| Command | Result |
|---|---|
| `godot --headless --path . --import` ×2 | 0 `SCRIPT ERROR`, 0 `Parse Error` |
| the 33-file unit set across all eight lanes' owned tests | **658 tests, 3,399,284 assertions, 0 failed** |
| the progression + HUD set, re-run after W13's round-2 UI fix | **158 tests, 2,521 assertions, 0 failed** |
| `tests/smoke_playground.gd` | exit 0, `smoke: OK`, 101 band pickups placed |
| `tests/smoke_gate_b_continuous.gd` | `gate B continuous (CORE): OK` |

### The blind-judge story, as it ended

Both blind rounds (W13's own and this lane's independent one) judged the **round-1** frames
and converged on the same three defects. W13 then pushed `14f4c84c`, whose round-2 judge
confirms all three fixed and which also fixes the three that round newly found. This lane's
note is committed as `JUDGE-W24-landing-round.md`, **marked superseded**, because leaving it
as written would have shipped a stale "not shippable" verdict as though it described the
landed code. What still stands: every frame in both rounds was shot over a flat scaffold, so
real-terrain legibility is unproven, and the pre-existing HUD furniture defects (health and
food chips covering their own bars, portraits, minimap, hotbar, a safe-area margin nearer
1 % than 5 %) belong to no lane in this batch.

### Still open after this landing

- **Nine lanes never produced a report**: W02, W06, W07, W08, W11, W14, W15, W20, W21.
- **Four have reports with unfilled placeholders**: W05 (`JUDGE_SECTION`), W01, W10, W22.
  W05's re-bake and its `vegetation.json` edit still want the bake-freshness re-run on
  whatever tree lands it.
- **The Biome 2 hard-rule concern** stands, untouched by this lane: `04d844d0`, `3f9e1a14`
  and `47ca2e12` build Cloudreach Cliffs on `main`, including a realm arch and Heart socket
  inside `scripts/world/playground_world.gd`, while `CLAUDE.md` bars Biome 2 implementation
  until the Meadows passes its exit gate.
- No lane closed a report between 03:10 and 06:40 UTC; the lane sessions appear to have
  stopped.

## Cycle 5 — W05-TREELINE, and a check that the benign-error set did not grow

**PR #46 landed** (`504c7b55`): `CURRENT_STATE.md` §1 now records the wave. Documents only,
so CI's own docs gate skipped the code jobs by design — verified the diff really was one
file before merging.

**PR #47 opened** for W05-TREELINE on `ralph/LAND-0904-4`. Its report's only gap was an
inline `JUDGE_SECTION` token; its code-blind verdict is committed as `JUDGE-after.md`, so
there was no unjudged visual work for this lane to run a round on. The placeholder was
replaced with a pointer to that file rather than a paraphrase, so the lane's summary is not
written in its voice.

The risk was the bake. W05 is the only lane allowed to touch `vegetation.json` and it
re-baked all 256 regions; its manifest fingerprint (`4984520267706256`) conflicted with the
repair `main` carries from #42 (`7496100143687718`). W05's is correct on the merged tree
because it changed the configs the fingerprint hashes. Checked, not assumed:

| Command | Lane's claim | Result on the merged tree |
|---|---|---|
| `--only=test_scatter_perf_budget.gd` | 3 / 6 / 0 | **3 / 6 / 0** |
| `--only=test_terrain_bake_freshness.gd` | 1 failed on its branch (pre-existing) | **3 / 8 / 0** — green here, #42's terrain repair is on `main` |
| `--only=test_scatter_rules.gd` | 38 / 1,019,854 / 0 | **38 / 1,019,854 / 0** |
| `--only=test_veg_corridor.gd` | 9 / 1,537,510 / 0 | **9 / 1,537,510 / 0** |
| `--only=test_band_vegetation.gd` | 5 / 142 / 0 | **5 / 142 / 0** |
| `godot --headless --path . --import` ×2 | — | 0 `SCRIPT ERROR`, 0 `Parse Error` |
| `tests/smoke_playground.gd` | — | exit 0, `smoke: OK` |

Cross-check on the lane's central claim that nothing moved and only sizes changed: both its
before and after bakes report **825,979 placements kept and 3,883 drained**, identical.

### The benign-error set: checked, and it did not grow

`smoke_playground` on the W05 tree logged `ERROR: 4 resources still in use at exit` beside
the usual `Parameter "material" is null` ×2. My earlier smokes on the eight-lane tree showed
only the material line, so on its face the known-benign set had grown — which
`ralph/briefs/0904/COMMON.md` says must not happen.

Ran the identical smoke on **current `main`** (`504c7b55`) as a baseline: it logs the same
two lines in the same counts, `4 resources still in use at exit` ×1 and
`Parameter "material" is null` ×2. **So W05 does not grow the set** — the line is already on
`main`. W22's own report recorded the same exit-time line on a branch cut before this wave
landed, which points at an intermittent shutdown artefact rather than anything this wave
introduced. Recorded here because "the set must not grow" is only a real check if someone
actually compares against a baseline when it appears to.

### Where the wave stands

Landed: #42 (`c5a16dfb`), #45 (`fdf70ab4`), #46 (`504c7b55`), and #47 open for W05.
Still off `main`: W01, W10, W22 (reports carry unfilled placeholders) and W02, W06, W07,
W08, W11, W14, W15, W20, W21 (no report pushed). No lane has closed a report since 03:10 UTC.

## Cycle 6 — W05 rejected on evidence; W01 + W22 up as PR #48

### W05-TREELINE: NOT LANDED. It breaks `smoke_aggression`, and it is this lane's change.

PR #47 was opened, verified on everything else, and then **closed without merging**. The
combat shard failed:

```
aggression FAIL: stood 53.7m from Galecrest for 900 frames without pressing anything and it never attacked
```

`smoke_aggression.gd:166` walks the trainer toward the aggressor until within 10 m, then
stands. The walk dies at 53.7 m.

| Tree | Result |
|---|---|
| `origin/main` @ `504c7b55` | **`aggression: OK`** |
| `main` + W05 (PR #47's head) | **FAIL at 53.7 m** |
| the same branch in CI, both runs | FAIL, `failed on attempt 2/2` each |

Both local runs were in the same container, same Godot, back to back, and the only content
difference is W05's — the branch's other commits are a decision renumber, a report pointer
and a `.uid`. The eight-lane batch without W05 passed `verify-combat-shard` on run
33949277496.

**Not the known flake, and I said the opposite earlier in this session before checking.**
`smoke_aggression.gd`'s header documents a walk-goes-dead history for this exact species,
investigated 2026-08-13, CI signature **44.1 / 38.0 / 45.1 m**, cause traced to a Terrain3D
snag rather than any tree collider. I read that and reported it as exonerating W05. It is
not: ours is **53.7 m every time, to the decimal, across two machines and three runs**. A
random snag does not stop at one distance repeatedly. The header's investigation was of a
different occurrence.

**Likely mechanism** (for the lane, not diagnosed further here): the lane raises
`trees.scale_max` 1.45 → 2.0 and `trees.heroes` to 2.2–2.7, and colliders scale with the
mesh. Placements are unchanged — both bakes report 825,979 kept / 3,883 drained, which is the
lane's own proof — so this is not a moved tree but a wider one on a line the walk used to
pass. It matters past the test: the scripted walk holds `move_forward` dead straight, but a
player walks that route too.

`data/config/vegetation.json` and the bake are W05's owned files, so this goes back as
"not landed, reason" rather than being fixed here. Everything else about the lane verified
clean (both bake guards, `test_scatter_rules` 38 / 1,019,854, `test_veg_corridor`
9 / 1,537,510, `test_band_vegetation` 5 / 142, imports, `smoke_playground`). The branch
`ralph/LAND-0904-4` is left in place so a fixed W05 re-lands from it. Evidence is on PR #47.

### PR #48 — W01-ROUTE-STRIP + W22-BRIDGE-SIGNPOST

Verified on the merged tree: `test_signpost_geometry` 6 / 101 / 0 and the four-file crossing
set 26 / 184 / 0 (both matching W22 exactly); `test_capture_check` **21 / 47 / 0** and
`test_route_strip_subject_boxes` 10 / 22 / 0; `smoke_traversal` OK with W22's own assertions
(`18 rail posts, 2 banners, sentry posted`, then `sentry stood down, barricade still
standing`); **`smoke_aggression` OK**; imports clean; benign error set unchanged
(`material` ×3).

`smoke_aggression` was run here deliberately. After W05, a lane that moves world geometry
near a route does not get the benefit of the doubt.

**W01's report undercounts itself:** it claims 18 tests / 39 assertions where the branch
carries 21 / 47 plus a second test file (10 more) it never mentions. `main` holds 3 of those
functions and the branch 21, so the lane added 18 and wrote the report after 15. More tests
than claimed, all passing.

### The judge round W22 never ran

Committed at `ralph/reports/W22-BRIDGE-SIGNPOST-0904/JUDGE.md`, on the lane's own four
questions, judge not told which column was new — **it named the after column as the finished
pass unprompted**. Call: *not shippable for a first playable, but the remaining work is scene
and material work, not new art.* Ship the bridge deck and rail after value fixes; do not ship
the signpost (glyph cap height 5–7 px at ~1.3:1 in world frames — "until a player can read a
destination from the path, this prop is decoration"); do not ship the checkpoint dressing
(untextured blockout barricades beside the road with ~4 m of clear track between them, a
guard wearing none of the faction's red, and the gate still flying its blue banners beside
the new red ones). Landed anyway per the directive: the diff improves what is there and the
gap is now in the repository rather than waiting to be found in play.

Its other two tokens were filled only where that could be done without speaking for the lane
— the leak baseline with this lane's measurement against `main`, the final hash as a fact of
the branch.

### A defect that belongs to neither lane

W22's judge and W05's judge, independently and from different frames, both flagged
`place5-bridge-approach` as shot from a camera at roughly 1.05 m rather than the game's
~2.8 m rig, with no player figure in shot and over half the frame out-of-focus ground. Two
lanes, two judges, one broken capture stand. That is a defect in the capture tooling's
viewpoint list, not in either lane's art, and it wants one fix rather than two workarounds —
`tools/_capture_band1_places.gd`'s `VIEWPOINTS`.

---

## Cycle 7 — 2026-09-05 08:25 UTC — PR #48 merged (W01-ROUTE-STRIP, W22-BRIDGE-SIGNPOST)

`main` is now `2cd711eb`. `git merge-base --is-ancestor b510043f origin/main` returns true.

### The run

CI run **33953926952** on head `b510043f`, 07:57 → 08:20 UTC, **23 minutes**, green on
every one of its eighteen non-skipped jobs. The two `*-known-red` jobs and `export` are
`skipped` by workflow condition, as on every other run this session.

| Job | Result | Finished |
|---|---|---|
| `changes` | success | 07:59:42 |
| `verify-unit-tests (1)` … `(4)` | success ×4 | 08:02–08:04 |
| `verify-terrain-bake-freshness` | success | 08:05:15 |
| `verify-scatter-bake-freshness` | success | 08:04:17 |
| `verify-gate-b-core` | success | 08:04:48 |
| `verify-harvest` | success | 08:07:31 |
| `verify-gate-a-ui-build-shard` | success | 08:09:34 |
| **`verify-combat-shard`** | **success** | 08:11:12 |
| `verify-regions-shard` | success | 08:12:14 |
| `verify-veg-corridor` | success | 08:12:47 |
| `verify-owner-regressions-shard` | success | 08:15:12 |
| `verify-scatter-rules` | success | 08:16:28 |
| `verify-core-verb-shard` | success | 08:16:57 |
| **`verify-gate-evidence-shard`** | **success** | 08:20:04 |

The pull_request run 33953949833 agrees job for job on everything it had finished, with
`verify-combat-shard` green at 08:10:02 and `verify-core-verb-shard` at 08:15:11.

**No job was waived.** The owner directive permits not blocking on
`verify-gate-evidence-shard` because `smoke_gate_e_finale` is intermittent on `main`; that
permission was available and went unused, because the shard passed. That is worth recording
precisely: this landing is green on its own merits, not green-by-exemption.

**`verify-combat-shard` was held binding and it passed.** I set that asymmetry deliberately
before the run: gate-evidence waivable, combat not, because combat is the job that caught
W05-TREELINE deterministically and W22 changes world geometry near the South Bridge. The
risk was real and it did not materialise — the bridge dressing, barricades and rail do not
disturb the combat approach walks. Had it failed I would have investigated rather than
waived, and #48 would have been split.

No re-runs. Every `started_at` sits inside the original 07:57–08:04 dispatch window, so
each result is a first attempt; nothing here is a retry that turned 0-for-1 into green.

### What W01 actually carries

The lane's report undercounts its own branch. It claims 18 tests / 39 assertions; the branch
carries **21 / 47**, plus a second test file the report never mentions. The extra coverage is
real, it is green, and it is inside the lane's ownership, so the discrepancy is a reporting
defect rather than a landing blocker — recorded here so nobody later reads the report as the
authority on what shipped. The branch is.

### What W22 carries, and the verdict against it

W22 committed both A/B contact sheets and its `JUDGE_PROMPT.md` but never ran the round,
leaving `__W22_VERDICT_BLOCK__` in its report and `__W22_VERDICT__` in its
`docs/CURRENT_STATE.md` row. Per the owner directive of 02:24 UTC — one blind round for
visual work no lane already has a verdict on — I ran it: a code-blind sub-agent given only
the visual-judge skill, `docs/reference/`, board 18 and the two sheets, told the columns are
A and B and explicitly **not** told which was the newer work, and barred from reading
anything under `ralph/`. Full round at
`ralph/reports/W22-BRIDGE-SIGNPOST-0904/JUDGE.md`.

It identified B — the lane's after column — as the finished pass **unprompted**. The
improvement is visible to someone who was not told where to look. Its call:

> Not shippable for a first playable — but the remaining work is scene and material work,
> not new art.

Split three ways: **ship** the bridge deck and rail once the value fixes land (silhouette,
plank orientation and deck colour `(127, 90, 61)` against the reference `#7f5b44` are
already right); **do not ship** the signpost, whose glyph band caps at 5–7 px with 1.3:1
text-to-board contrast at `south-bridge-trailhead`, so it fails its only job in every
gameplay frame; **do not ship** the checkpoint dressing, whose barricades are untextured and
sit beside rather than across the road and whose guard wears none of the faction's red.

I landed it anyway, and the reasoning should be legible so it can be overruled: the diff
improves what exists, nothing in it regresses a passing behaviour, every test the lane names
is green, and the outstanding work is scene and material work that a later pass can do
without new art. The alternative — holding a lane out over a verdict on two of its three
parts — would strand a real improvement. **The gap is now written into `LANES.md`, this
report and `docs/CURRENT_STATE.md` §4b rather than hidden. If the owner would rather hold W22
out until the signpost and checkpoint fixes land, say so and I will pull it back out.**

### Two documentation defects repaired on the way through

Both in `docs/CURRENT_STATE.md`, both mine to fix:

1. The D-renumbering sed I ran during the wave had rewritten W19's own row to read
   "D86/D75 W19" and "after eight lanes each opened a D86". Both should read **D74** — W19
   keeps D74/D75, and D74 is what eight lanes had each independently claimed. The artifact
   came from renumbering W22 to D86 with a docs-wide substitution. Corrected.
2. W22's §4b row shipped with an unfilled `__W22_VERDICT__` token. Filled from the judge
   round above. This is the same class of defect I have now caught in four lanes' reports;
   the difference here is that it had already reached `main`.

### Ledger

Decision numbers on `main`, all unique: D74/D75 W19, D76 W13, D77 W23, D78 W18, D80 W09,
D81 W04, D83 W12, D84 W17, **D86 W22**. D79 reserved for W10, D82 for W02. **D85 is unused**
because W05 did not land. Next free: **D87**.

Still off `main`: **W05** (rejected on evidence — `smoke_aggression` stops at 53.7 m; the
lane owns the fix, `ralph/LAND-0904-4` holds the prepared landing) and **W10** (seven-line
skeleton report, no test results). **W02, W06, W07, W08, W11, W14, W15, W20, W21** have
pushed no report of their own; W07 has judge sheets but no `REPORT.md`, which under the brief
is not done. An exact-path rescan at 08:10 confirmed this — an earlier looser grep matched
other lanes' reports that had arrived on those branches via `main` and briefly read as nine
lanes closing at once. They had not.

**No lane has pushed anything since W13 at 03:06 UTC.** Every lane that has produced a
closeable report is now on `main`.

### Process note from this cycle

`git checkout <branch>` **fails, and can be easy to miss in a compound command, when that
branch is already checked out in another worktree.** `ralph/W24-LANDING-0904` lives in
`/home/user/wt-land`, so the checkout in the main repo did nothing, and cycle 7's ledger
commit landed on `ralph/LAND-0904-5` — the already-merged landing branch — while
`git push origin ralph/W24-LANDING-0904` pushed the unchanged local ref and reported
success. PR #49 was briefly open against a branch that did not contain the work its body
described. Caught by the repository's unpushed-commits stop hook, not by anything I did.

The repair was a fast-forward of `ralph/W24-LANDING-0904` to the commit and a reset of
`ralph/LAND-0904-5` back to `origin`. Nothing incorrect reached `main`, and PR #48's merge
was never at risk. **Check `git branch -vv` or `git worktree list` before assuming a
checkout succeeded**, and read what a push actually pushed rather than trusting that a
`-u <branch>` refspec pushes the working tree.
