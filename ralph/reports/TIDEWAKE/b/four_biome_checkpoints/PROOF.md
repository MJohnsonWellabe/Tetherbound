# Four-biome continuous run: production-save checkpoint boundaries

The earned four-biome run (`tests/smoke_four_biome_continuous.gd`) takes about
2.5–4 h, and render.yml caps a script at 150 min. The run can now be split into
pieces at production-save boundaries.

## What changed

- `tests/helpers/four_biome_checkpoints.gd` (new, pure logic). It holds the
  ordered boundaries, argument parsing, receipt building, reading and
  validation, export in the earned_saves layout, and the commit SHA
  (`TB_COMMIT_SHA` env, then `git rev-parse HEAD`, then the `.git`/worktree HEAD
  file).
- `tests/smoke_four_biome_continuous.gd`: `_run` is split into five stages. The
  segment order and `--through-*` stops are unchanged. Four boundaries are
  added:

  | boundary | driver `reached` | next segment on resume |
  |---|---|---|
  | `hall` | `warden_arena_entered` | Warden (`meadows_earned_warden_segment`) |
  | `c1_arrival` | `cloudreach_arrived` | Cloudreach live segment, then the Stormward handoff |
  | `stormwood_arrived` | `stormwood_arrived` | Stormwood continuous through the Waterward handoff |
  | `water_arrived` | `water_arrived` | Water opening through the Tidewake ending |

  `hall` was added beside the three chapter handoffs so that the existing
  earned checkpoint `seed4_hall` can be resumed. At each boundary the driver
  calls `Game.save_game(1)`, the menu Save call, on the chain slot that
  `earned_chain_runner` uses. It exports the scratch save dir to
  `<checkpoint-dir>/<boundary>/` as `save/`, `receipts/<boundary>.json` plus
  the carried earlier receipts, and `README.txt`. The receipt records the
  boundary, commit, world seed (saved and env), elapsed and cumulative elapsed
  seconds, realm, player position, and party (uid/species/level/nickname). It
  also records every set flag plus `key_flags`, `resumed_from`,
  `fixtures_used_in_run_path: false`, and a no-fixture statement. When the
  piece resumed from a repo-stored earned save, the statement says so.
- `--resume-from=<dir|name>[:<boundary>]` accepts three forms: an existing
  dir, a name under `--checkpoint-dir`, or a name under
  `tests/fixtures/earned_saves/checkpoints/`. Without `:<boundary>`, the latest
  boundary that has a receipt is used. The run copies the checkpoint's `save/`
  into a fresh scratch before the save system is installed, so the checkpoint
  itself is never written. It then loads through the production title's Load
  list, the same path as `tools/earned_saves/earned_chain_runner.gd`. The
  resume is refused if the loaded party uids (as a set), the flags or the world
  seed do not match the receipt. After that the run continues with the next
  segment. `earned_chain_runner` receipts (`party_after`/`flags_gained`/
  `saved_world_seed`) are accepted.
- `--stop-at=<boundary>` ends the run with exit 0 right after that boundary's
  checkpoint is written. When it names the resumed boundary, the run
  re-exports the verified load through a fresh production save and stops.
- `--checkpoint-dir=<path>` sets where checkpoints go. The default is
  `user://four_biome_checkpoints_<pid>_<ms>/`, which is inside the user dir
  that render.yml already uploads. `--no-checkpoints` turns the writes off.
- Default behaviour, with no checkpoint args: the same segments in the same
  order, plus the checkpoint writes. A refused save or export in a default run
  is only a printed `FOUR BIOME CHECKPOINT WARNING`, so pass/fail keeps its
  meaning. With any checkpoint arg, a refused save or export fails the run.
- CI: `.github/workflows/*.yml` does not invoke
  `smoke_four_biome_continuous.gd`. No CI invocation had to be kept working.
  The only callers are render.yml dispatches.
- `tests/test_four_biome_checkpoints.gd` (new) has 10 tests and 65
  assertions. It covers parsing, bad-arg refusal, boundary order and the
  next-segment mapping, the receipt round trip, refusal of a mismatched or
  missing party member, missing flags, a wrong boundary or a failed run, the
  export layout against `seed4_hall`, resolving and picking a boundary, the
  existing `seed4_hall` checkpoint being resumable, and the commit SHA.

## Commands and results

```
XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script tests/run_tests.gd -- --only=test_four_biome_checkpoints
  -> 10 tests, 65 assertions, 0 failed            (unit_test_four_biome_checkpoints.log)
godot --headless --path . --check-only --script <each changed .gd>   -> clean  (parse_check.log)

# 1. Resume the repo's earned seed4_hall through the title Load, verify, re-export, stop (130 s)
TB_WORLD_SEED=4 godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- \
  --resume-from=seed4_hall --stop-at=hall --checkpoint-dir=<scratch>/cps/a
  -> exit 0; RESUME VERIFIED boundary=hall realm=meadows party=5 uids flags=118 seed=1393508821
     FOUR BIOME CHECKPOINT hall written            (run1_resume_seed4_hall_stop_at_hall.log)

# 2. Resume the checkpoint that run 1 exported (write/resume round trip) (112 s)
  --resume-from=<scratch>/cps/a/hall:hall --stop-at=hall --checkpoint-dir=<scratch>/cps/b
  -> exit 0; RESUME VERIFIED, same five uids and 118 flags, re-exported  (run2_resume_exported_hall.log)
     exported receipt/README/layout: exported_hall_receipt.json, exported_hall_README.txt, exported_hall_layout.txt

# 3. The next real segment from seed4_hall to c1_arrival (241 s)
  --resume-from=seed4_hall --stop-at=c1_arrival --checkpoint-dir=<scratch>/cps/c
  -> exit 1. The Warden was beaten by earned play (5 rounds, 5 wins, 96 hits,
     rewards and XP exact). The canonical helper then failed:
     "The actual trainer victory did not return ordinary world input: warden_aldis"
     (run3_resume_seed4_hall_to_c1_arrival.log)

# 4. A tampered receipt (one uid swapped, one extra flag) is refused
  --resume-from=<scratch>/cps/t:hall --stop-at=hall
  -> exit 1; RESUME REFUSED: party mismatch + missing flag  (run4_tampered_receipt_refused.log)

# 5. Default path prefix, no checkpoint args: --through-opening
  -> exit 0, reached=opening, no failures (156 s)   (run5_default_through_opening.log)
```

## Limitation (run 3)

`c1_arrival` could not be reached from `seed4_hall` in this pass. The failure is
the known BLOCKERS.md **B8**, not the checkpoint code. The canonical
`meadows_earned_warden_segment` / `meadows_earned_hall_segment::_fight_named`
waits only 120 frames for input after the Warden victory, while the production
`DialoguePanel` (`stronghold_warden_realm_reward`) owns input. B9 and B10 follow
from the same cause: the helper has no `veridian_choice` accept/refuse. The
default fresh run hits the same wall. `tools/earned_saves/warden_accept.gd`
works around it for the chain runner only. The smoke still composes the
canonical helper, and changing that helper was outside this grant. Until the
Meadows owner fixes the helper, the boundaries `c1_arrival` and later are
exercised only by unit tests. The load and verify path they share with `hall`
is proven by runs 1, 2 and 4.

## Using it from other lanes (render.yml)

Dispatch render.yml with `checkout_ref=<sha>`,
`script=tests/smoke_four_biome_continuous.gd` and `mode=headless` (or
`render`). Set `timeout_minutes` to 150 or less. For each piece:

- First piece: `args=--stop-at=c1_arrival --checkpoint-dir=user://cps`. It
  runs fresh through the Warden, and the checkpoint lands in the uploaded
  `user/` tree of the artifact.
- Later pieces: add the previous piece's exported directory to the lane's
  branch, or to any path in the checkout. One option is
  `tests/fixtures/earned_saves/checkpoints/<name>/`, which lets `--resume-from`
  take a bare name. Then run
  `args=--resume-from=<name>:c1_arrival --stop-at=stormwood_arrived --checkpoint-dir=user://cps`,
  and continue the same way with `:stormwood_arrived --stop-at=water_arrived`
  and `:water_arrived` with no stop-at for the ending.
- Set `TB_WORLD_SEED` only if the lane pins one. The loaded save carries its
  own `world_seed`, and the resume checks it against the receipt.

## Review follow-ups (independent review: APPROVE on 340b9b20)

- **Fixed: a checkpoint could overwrite itself.** An export whose target is the resume source (or contains it) is now refused, so a checkpoint this run resumed from is never rewritten. Run 6 (`run6_self_overwrite_refused.log`) used `--resume-from=/tmp/cp/hall --checkpoint-dir=/tmp/cp --stop-at=hall`. It exited 1 with `checkpoint export refused: target ... would overwrite the resume source ...`, and the md5 of every file in the source was unchanged.
- **Fixed: a dirty tree is now visible in receipts.** `commit_sha()` appends `-dirty` when `git status --porcelain --untracked-files=no` shows local changes.
- **Open, non-blocking:**
  - The cumulative elapsed time after a chain-runner resume also counts receipts after the resume boundary (8849 s here).
  - The seed check has no unit test.
  - The no-fixture statement does not point to seed4_hall's own B5 "helper Satchel care" disclosures.
  - Runs 1, 2 and 4 have no explicit `exit=` line; read their result JSON.
- **Unchanged blocker:** `c1_arrival` and later boundaries cannot be demonstrated from seed4_hall until the Meadows owner fixes B8 (the Warden helper waits 120 frames while the dialogue panel owns input).

## Merge with main's F02 resume: one `--resume-from`, two checkpoint kinds

Main (Meadows F02) added its own `--resume-from=<dir>`. It resumes a Meadows
reload-transition checkpoint that `_reload_transition` writes under
`user://four_biome_checkpoints/<label>_<pid>/` (`checkpoint.json` + `save/`).
The merge keeps one flag. `CHECKPOINTS.classify_resume` looks at the directory
to decide which kind it is:

- `checkpoint.json` without `receipts/`, and no `:<boundary>` suffix, is a
  reload-transition checkpoint. It follows main's `_resume_checkpoint` path
  unchanged: slot 0 load, then `_meadows_after_bridge`, stop after the Hall,
  `counts_as_proof: false`.
- A `:<boundary>` suffix, a bare name (resolved under `--checkpoint-dir` or
  `tests/fixtures/earned_saves/checkpoints/`), or a dir without
  `checkpoint.json` is a chapter-boundary checkpoint. It follows this lane's
  path: title Load of slot 1, receipt verification, then the next stage.
- A dir that holds both markers, with no suffix, is refused as ambiguous.

Main's Meadows restructure (`_meadows_after_bridge`, reload transitions with
their checkpoints, tournament `recover`, `--route-ledger`, `--world-seed`) now
sits inside `_stage_fresh_through_hall`. The `hall` boundary checkpoint runs
after the Hall's own reload transition and before a `--through-hall` stop.
Main's F02#4 order is unchanged: the reload comes before the `--through-*` stop.
In the result JSON, `resumed_from` is now a string: the reload label or the
chapter boundary. `counts_as_proof` is false for any resume or DRY RUN.
This lane's resume details moved to `resume`.

Verification on the merge:

- The unit tests give 11 tests, 78 assertions, 0 failed
  (`unit_test_four_biome_checkpoints_merged.log`). The new
  `test_resume_kind_is_detected_from_the_directory` covers both kinds, the
  suffix, bare names and the ambiguous dir.
- `--only=four_biome,earned,route_ledger` gives 169 tests, 4218 assertions,
  0 failed (`unit_filter_four_biome_earned_route_ledger_merged.log`).
- Run 7: a reload-transition checkpoint was built from `seed4_hall`'s save
  (slot 1 copied to slot 0, `checkpoint.json` label `warden_arena_entered`).
  The run printed `RESUMED FROM EARNED CHECKPOINT`, which is main's path. It
  exited 1 with main's own "stops after the Hall" failure, as designed, and
  `counts_as_proof: false` (`run7_unified_resume_reload_transition_kind.log`).
- Run 8: `TB_WORLD_SEED=4 --resume-from=seed4_hall --stop-at=hall` exited 0
  with `RESUME VERIFIED` and the hall checkpoint re-exported
  (`run8_unified_resume_boundary_kind_seed4_hall.log`).
- Run 9: the default `--through-opening` exited 0
  (`run9_merged_default_through_opening.log`).
- Main's closed F02 proof command, `--through-hall --reload-at-transitions
  --world-seed=15 --route-ledger` (about 77 min), was not re-run in this merge.

## Merge review follow-ups (independent review of 64c738ad)

- **Fixed:** a checkpoint's `save_game(1)` renamed the live world to `slot-1` (`save_game.gd:_world_id_for`), and nothing renamed it back. A default full run would then have carried the wrong `world_id` into satchel escrow, reward provenance and capture claims. `_checkpoint_boundary` now restores the live `world_id` after the checkpoint save. Run 10 (resume seed4_hall, stop at `hall`) exits 0; unit tests: 11 tests, 0 failed.
- **Fixed:** the run7–run10 logs are now committed. They were gitignored as `*.log`.
- **Confirmed unchanged:** main's F02 command (`--through-hall --reload-at-transitions --world-seed=15 --route-ledger`). The one difference is a non-strict `hall` export after the Hall reload, which can only warn and never changes the exit code.
