# F19#5 Meadows piece `warden`: PASS (routes-west)

- **Input:** generated `hall` lineage, run as hall → warden on one commit from a pinned clean worktree.
- **Command:** `earned_chain_runner.gd -- --segment=warden --generated-fixture --handoff-from=<hall root>/hall ...`

| Run | Source | Result |
|---|---|---|
| 1 | `088adb0f` | FAIL. Helper restored `_supported_y` but not `_in_hall`; fixed in `b52ea554`. |
| 2 | `c3c39026` | FAIL. Exact-XP: the helper modelled ordinary XP on durable rounds; aligned to the game's hybrid award (`a8cf32ae`). |
| 3 | `7f1b1b0a` | FAIL. "Unexpected live dialogue": F05 added the Veridian choice conversation and its accept/refuse prompts before the five-slot ceremony. The helper now expects the `choice.conversation` and presses the ordinary accept prompt (`d4e4ec2d`). XP receipts matched exactly. |
| 4 | `d4e4ec2d`, Oct 11 7:32–7:44 PM CT, 706 s | **PASS.** Warden 5/5. Then: chamber/free/join/choice conversations, the accept prompt, the five-slot ceremony, newcomer released, earned five kept. Flags: `defeated_warden`, `legendary_freed/refused/settled`, `realm_key_cloudreach`. |
| 5 | `516bea10`, read-only hand-off receipts added | **PASS.** |

- The `hall` piece for run 4 passed on `d4e4ec2d` (1536 s). Ledger: `route_ledger/hall_d4e4ec2d.jsonl.txt`, strict 250 m with 0 windows over, A7 clean.
- An earlier hall attempt on the same commit lost Keeper Hald's 4th round (duskhush at 92 HP). Disclosed; not counted.
- **Post-win durable hold:** no `[trainer] … win recorded` line was logged in any hall, sigils or warden run on `7f1b1b0a` or later. The hold is under one physics frame since the duty-drain fix. No "Recording the win…" message is needed; nothing was changed.

**Open: `tidewake_handoff` FAIL.** "F49 relic hanging produced no actual portable relics_hung state".
- Receipts at the win, at the open ceremony and after the five are kept: portal key 0, `relics_held` [], 0 boss receipts.
- The Warden's per-participant hand-off (`boss_relic`: portal key and Meadows relic) is never granted at all; nothing is lost later.
- Under diagnosis.
