# NETFIX wedge-1024: boss_rewards_each_participant "final-round wedge"

## Finding

There is no owner-passive race. The smoke ran out of its own frame budget partway through a normal settlement.

- `tests/smoke_net_boss_rewards_each_participant.gd:194` (before the fix) called
  `step(0, "win_trainer_battle", {...}, 6000)`. The 6000 is only the coordinator's step deadline.
- `tools/net/peer_runner.gd:4395` bounds the arm by `args.budget_frames` (default 2400, minus a 240-frame margin, so 2160).
  The smoke never set it. That left 2160 frames for the fight **and** both participants' durable round settlement.
- CI run 40138183076 failed on both attempts the same way.
  - The fight took 37 swings, and the last enemy fainted at driver frame ~2040–2100 of 2160.
    Local passing runs finish the fight and settlement by frame ~1440–1550.
  - Attempt 2 (`net-smoke-runs-7`, 12578577605): the round-2 gate opens at t=89784.
    The heartbeat at t=89.95 shows driver frame 2135 with the enemy at hp 0. The failure diagnostic is written at physics frame 2964, about 0.6 s after the faint.
  - The final round's settlement needs ~3–4 s: owner-passive freeze → frozen → prepared → saved → journaled, then the ACK and rebase, for round then completion.
- The host log's "released (t=89926) / re-held 1 ms later" is a logging artifact, not a release.
  - `_note_duty_hold` keys on character+action (`scripts/net/session.gd:1623`), so round 1's still-retained duty prints "released", and round 2's in-flight checkpoint prints "held" again on the same key.
  - The same pair appears in every passing run, at the moment the host sends `prepared`.
- Reproduced on purpose: setting `budget_frames: 1650` locally gives the exact CI signature.
  "never resolved in 1410 frames … enemy=mudsnout hp=0.000/112.000", and the host's last line is
  `combat_round_reward duty … held: owner passive gate owner_passive_checkpoint_pending`.
- Temporary [DBG] tracing of the full checkpoint message flow on both peers (not committed) showed every checkpoint completing in passing runs.
  Freeze, frozen, prepared, saved, journaled, rebase and rebase_ack all arrived in order.

## Fix

`tests/smoke_net_boss_rewards_each_participant.gd`: pass `budget_frames: 6000` in the args with a 6400 step budget. This is the convention `smoke_net_f28_masters.gd` already uses. No assertion changes, nothing skipped, no production code changed.

No unit regression test was added: the fix is a timeout in a smoke's arguments, and no protocol code changed. The asked-for "re-hold re-arms the checkpoint" test would have tested behaviour that already works. The host resends `freeze` on every scan (`owner_passive_sync.gd` `_checkpoint`), and the owner answers by phase.

## Tests

- Before the fix, locally (with the [DBG] build): 5/5 pass (r1–r3 sequential, p10/p11 in parallel).
  - Two more parallel runs (p12/p13) failed only on "not every peer said hello within 180 s". They overlapped a third run of mine, so this was machine overload.
- Repro with `budget_frames: 1650`: 1/1 fails with the CI signature.
- After the fix: `smoke_net_boss_rewards_each_participant` passed **6/6**, run two at a time for load. Fight plus settlement finished at driver frames 1442–1546.
- owner_passive, ledger, session and combat-round unit suites were not run: no production code changed (RD-37).

## Follow-up: client_trainer_rewards (coordinator request)

- `tests/smoke_net_client_trainer_rewards.gd` had the same gap: a 9000-frame step budget but no `budget_frames`, so its arm also got 2160.
- Fixed in `19a1733e`: `budget_frames: 4000` with a 12600-frame step.
  - The arm gets 3760 frames, about 209 s at the 18 Hz a loaded runner was seen stepping.
  - The wall deadline is 210 s + 5 s slack, so the peer still answers first, keeping the smoke's existing rule.
- Before the change, the guest-driven fight plus saves already finished at driver frames 1726–1846 locally, close to the old 2160 cap.
- After the fix: 3/3 local passes (two run in parallel, one alone).

## Side observation (left as a finding, per the coordinator)

- `foundation_combat_round_resolution` (`scripts/net/session.gd`) re-journals its round's event on every retry call.
  - After the event retires (all duties settled), a later retry re-creates it with no settlement. Round 1's event `7e6e…` was still in the CI world save, unsettled.
  - Harmless today: its duties release by receipt. Once the trainer-round receipt window evicts that receipt, it could re-gate.

## TO COORDINATOR

READY tb/netfix-wedge @ 19a1733e742b6bf60bd58250d6ff8f87eb569cbf (fixes 294e6709 boss_rewards + 19a1733e client_trainer_rewards). Root cause: tests/smoke_net_boss_rewards_each_participant.gd:194 sent its 6000-frame budget only as the step deadline. tools/net/peer_runner.gd:4395 bounds the win arm by args.budget_frames (default 2160 effective), so a slow 37-swing CI fight timed out 0.6 s into a normal final-round settlement. There was no owner-passive race; the "released then re-held" log pair is round 1 and round 2 sharing one hold key. Fix: pass args budget_frames 6000 with step 6400. Results: the CI signature reproduced locally at budget 1650; boss_rewards 6/6 local passes after the fix, run in parallel pairs. client_trainer_rewards got the same gap fixed (budget_frames 4000 / step 12600) and passed 3/3 locally. Unit suites not run (no production change).
