# F19#5 Meadows pieces `hall` → `warden` → `tidewake_handoff`: PASS on 45a1dd6a (routes-west)

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

## Final chain on 45a1dd6a (merged coordinator head), Oct 12 CT, all pieces hosted (udp/27017–27018)
| Piece | Result |
|---|---|
| hall | PASS, 1699 s. Ledger `route_ledger/hall_45a1dd6a.jsonl.txt`: strict 250 m, 0 windows over, A7 clean. |
| warden | PASS, 837 s. Chapter hand-off at the win, the open ceremony and after the five are kept: portal key 1, `relics_held` [meadows], 1 boss receipt. |
| tidewake_handoff | PASS, 196 s. Home Key home, Meadows relic hung, Tidewake arch Use then Enter, Tidewake reached with the same five. No arch re-press was needed. |

## Root causes fixed on the way
- **The hand-off was never granted.** Concurrent local pieces held udp/27015, so the session ran offline-solo and skipped host-authored durable rewards.
  - Fix: `Session.host` falls back to nearby ports (`44bbda40`).
  - Joiners get the bound port (`c274ac2c`).
  - Offline-solo durable boss rewards stay out of scope: tried and reverted in `505d23f7` because the offline Warden fight fled.
- **The arch Enter press "activated nothing".** This was a helper bug.
  - At the first press, the arch prompt was up, the winner and actionable at 2.94 m.
  - The F49 stick release was lost in buffered input, so the trainer kept walking out of the 3.2 m radius.
  - Fix in `81171f73`: `_stick` flushes buffered input, and the helper steps to 1.2 m when an adjacent pedestal wins.
