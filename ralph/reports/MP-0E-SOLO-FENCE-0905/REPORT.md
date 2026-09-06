# MP-0E-SOLO-FENCE — report

**Lane:** 0.E Solo regression fence (Sonnet) · **Branch:** `claude/tetherbound-roadmap-next-jrcjs8`
from `main` `55c64aaa` (lane base `e3ea463e`) · **Kind:** tests + tooling + one CI job · **Brief:**
`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` Wave 0 row 0.E. The lane could not write this
file itself; Fable wrote it from the lane's completion report after reproducing the test run
(`--only=characterize` → 62 tests, 209 assertions, 0 failed) and reading the `ci.yml` diff.

## One line per item, up front

| Item | Verdict |
|---|---|
| 1 `tests/test_characterize_progression_feed.gd` | **done** — 16 tests / 57 assertions |
| 2 `tests/test_characterize_map_state.gd` | **done** — 11 / 64, including the process-global extent hazard pinned as a test whose expected value 1.B must change |
| 3 `tests/test_characterize_flag_keys.gd` | **done** — 10 / 16; `tm_pickup.gd` and the `wild_once_<order>` string have no helper, so their literals are pinned by reading source, the technique `test_pickup_glow.gd` already uses |
| 4 `tests/test_characterize_party_and_inventory.gd` | **done** — 18 / 50 |
| 5 `tests/test_characterize_game_process_ticks.gd` | **done with a proven limit** — 7 / 22; `Engine.get_main_loop()` is null for the life of `run_tests.gd` (asserted), so pause-gating of `Game._process` is smoke-only territory (`smoke_menu`, `smoke_post_modal_control`) |
| 6 Every test seen red first | **done** — five break/fail/revert triples below; `git diff` on every production file empty afterwards |
| 7 `tools/run_all_smokes.sh` | **done** — tested on the three named smokes, all exit 0 on attempt 1 |
| 8 `ci.yml` `verify-solo-regression` | **done** — needs the six shard jobs (8+10+5+6+8+9 = 46 smokes) plus `verify-gate-b-core`, conditioned on `changes`; the five new files round-robin across all four unit shards |

## Commands

```
godot --headless --path . --script tests/run_tests.gd -- --only=characterize
  → 62 tests, 209 assertions, 0 failed   (lane: three runs; Fable: one run, same numbers)
tools/run_all_smokes.sh --only=smoke_menu.gd,smoke_input.gd,smoke_save_persistence.gd --outdir=<scratch>
  → smoke_input 0 / 98 s / 0 ERROR lines; smoke_menu 0 / 130 s / 0; smoke_save_persistence 0 / 177 s / 0
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"  → ok
```

## The five red/green triples

1. `progression_feed.gd` — removed `_revision += 1` from `drain()` → `test_drain_bumps_revision_but_leaves_epoch_and_seq_untouched` red (`expected 2, got 1`) → reverted, green.
2. `map_state.gd` — `"grid_x"` → `"gridx"` in `save_data()` → `test_save_data_has_exactly_these_nine_keys` red → reverted, green.
3. `item_cache_pickup.gd` — `FLAG_PREFIX` `"cache:"` → `"loot:"` → exactly the five cache-prefix tests red, the other five green → reverted.
4. `party.gd` — `MAX_CREATURES` 5 → 6 → `test_max_creatures_is_five` and `test_add_refuses_the_sixth_creature` red → reverted.
5. `creature_instance.gd` — dropped `apply_buff()`'s garbage guard → `test_apply_buff_refuses_garbage_and_leaves_existing_buffs_untouched` red (4 assertions) → reverted.

## Findings for Wave 1 (lane 1.B)

1. **`progression_feed.gd::drain()` bumps `_revision`, not `_epoch`**; only `clear()` bumps the
   epoch. The plan's row said otherwise. A presenter gating on `epoch()` does not see a drain.
2. **`inventory.gd::drain()` returns a compacted array**, never `SLOT_COUNT`-long with `null`
   holes; index-in-array is not the slot number. Anything that wants slot-preserving drain (death
   satchel hand-off, a network transfer) must capture indices first.
3. **`map_state.gd`'s extent is one process-global static**, confirmed: two instances always
   agree. 1.B resolves it structurally (instance fields populated by `configure()`), and this
   lane's test is the one whose expected value flips.
4. **No unit test can observe `SceneTree.paused`**; D-MP8's regression coverage lives in smokes.

## Process finding, for the orchestrator

This lane held a working-tree edit to `ci.yml` uncommitted for its whole session, on a branch
two other lanes were landing to. Partway through, the edit was found reverted with no action by
this lane and had to be reapplied. A lane told not to commit is exposed to silent clobbering by
a sibling's landing. **Fable's response:** every lane from 0.F onward runs in its own git
worktree and commits there; the orchestrator merges. Recorded in the Wave 0 landing notes.
