# Earned start: provenance of `seed4_hall`

This is the citation that WORKFLOW §8's "Earned checkpoints are allowed starts" requires: the producing run, as a commit SHA plus its log.

- **Save:** `tests/fixtures/earned_saves/checkpoints/seed4_hall/save/`
  - Committed unchanged since **2950ac0e9c64078857b91c60f961d46c8b7ed397**, "WIP earned chain: seed-4 checkpoint after segment hall (save + all segment receipts)".
  - `slot_1.json` sha256 is `c05f81d1…e1a3`. Every F03 receipt names this hash.
  - The save was written after the chain's `hall` segment PASSED and before `warden`. It stands inside the Hall; the objective is "Defeat the Meadows Warden".
- **Producing run:** `tools/earned_saves/run_chain.sh 4 /tmp/claude-0/earned_chain/seed4`, which runs `tools/earned_saves/earned_chain_runner.gd` with `TB_WORLD_SEED=4`.
  - It started from the title screen and a new game. The `opening_team` receipt shows an empty party before and all flags gained in play.
  - Segments in order: opening_team → camp_tournament → bridge → warrens → relay → hall.
  - Code:
    - base **10b635d38** (integration-7, 2026-09-25) on the Cloudreach lane's `ralph/cloudreach-earned-c1-save` branch;
    - the `hall` segment ran on **92a977213df6d41f75f06542fe236bc4c314233f** ("earned chain hall: route pre-Sigil rest around the Relay; log B6 and apply B5 ruling step 2", 2026-09-26 12:52 UTC). Its receipt's wall-clock window is 12:52–13:28 UTC.
  - The earlier segments ran on the chain's commits between 10b635d38 and 92a97721; `git log 2950ac0e -- tools/earned_saves` lists them.
- **Log:** the per-segment receipts committed with the save at 2950ac0e, in `tests/fixtures/earned_saves/checkpoints/seed4_hall/receipts/*.json`. They record flags gained, party, items, position, wall time and disclosures. The raw `/tmp` logs are gone. The coordinator ruled on #356 that these receipts, plus `tools/earned_saves/BLOCKERS.md` and `run_chain.sh` at the recorded commits, count as the producing run's log (Rulings3, 03:17 UTC).
- **Inferred, not recorded:** the segment receipts carry no commit SHA or timestamp field. That the `hall` segment ran on 92a97721 is inferred from BLOCKERS.md's 12:52–13:28 UTC window and that commit's 12:52:15 time. A clean worktree is not recorded either.
- **Not part of this checkpoint:** `receipts/warden.json` in the same directory is a later, failed `warden` segment run made after this save was written. No F03 proof uses its output.
- **No fixtures, position writes, flag/ledger sets or granted parties:**
  - `free_build` is false in every segment.
  - Between-fight care is Satchel use through the menu (`meadows_earned_team_segment.gd::_use_remedy`).
  - The helper methods the chain used walk, tap and use beds only.
  - This was independently checked by the strict re-check on #356.
- **Disclosed limitations** (`tools/earned_saves/BLOCKERS.md`):
  - World seed 4 was chosen by `tools/earned_saves/seed_scan.gd`. It is a legitimate world but an instrumented choice.
  - Bridge: a helper's "gate owns the prompt" assertion was bypassed after the gate had already opened in play (B1).
  - Warrens: one unreachable rootstone node was skipped, and there were two walking detours (B2).
  - Hall: seven between-fight Satchel uses (B5).

## How the F03 proofs use it

Each activity is **one uninterrupted run** from this unchanged save:
- `tests/capture_activity_lures.gd --save-dir=…seed4_hall/save` copies the directory unchanged, then calls `Game.load_game(1)`, the normal load path.
- Every receipt reports `load_vs_saved_xz_m` 0.0 and `script_state_writes` none.
- The walker drives the game only through input actions. It sets the camera rig's yaw directly in place of the look stick.
- The receipts do record some route aids: stronghold-exit walk targets, the sealed Old Quarry gate excluded from route planning, and back/jump/strafe unsticking.
