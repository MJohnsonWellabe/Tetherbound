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

## Follow-up 2: shared_boss `move_start_required` (PR #738, run 40150677244, shard 12)

Verdict: **a test race, not PR #738.**

- **Evidence:** the guest log has `move_start refused: pending_vitals (The original health change is still being saved.)`, then `strike_intent refused: move_start_required`.
  - The job log shows a single friendly-fire attempt (`attempt=1`).
  - The swing's move start reached the host while the guest's previous health change was still saving (`encounter_director.gd`'s pending_vitals gate). The strike then had no committed start (`encounter_director.gd:3438`).
  - The loop in `tests/smoke_net_shared_boss.gd` (~l.875–898) accepted any non-empty refusal as the host's answer, so it exited and the `friendly_target` assert failed.
- **Second weakness:** the striker's `last_encounter_refusal` (`combat_manager.gd:4259`) is never cleared, so a refusal from an earlier attempt could be read as this swing's answer.
- **PR #738 is not the cause.**
  - Its `_flash_host_impact` change only adds an optional `contact_burst` particle spawn after the hit is already decided.
  - The rest is camera, telegraph, arena and UI presentation.
  - None of it is on the move-start or strike-commit path.
  - The race is a pre-existing timing window that load can open on any commit.
  - I did not run 282901fd5 itself: the race never occurred in 6 local runs on main-based code, so a PR-head run would not tell the two apart.
- **Fix (7e7e2e84):** `PRE_RESOLVE_REFUSALS = ["pending_vitals", "move_start_required"]`. Such a refusal re-stages the attempt (logged).
  - A refusal only counts as the arrival if it differs from the read taken just before the swing; after all polls, whatever is there is used.
  - The `friendly_target` assertion is unchanged and still required.
  - If every attempt is refused before resolving, the assert still fails with that code.
- **Local results**, run in pairs (base = main's smoke, fixed = this branch), so each run had CI-like load:
  - **Fixed:** 3/3 pass.
  - **Base:** 2/3 pass. Its one failure was a different load failure: the host's creature died during staging and the fight ended.
  - **Race frequency:** 0 guest pending_vitals refusals in all 6 runs; it is rare locally.
  - **Forced check:** a run with a temporary copy that injected `move_start_required` on attempt 1 re-staged it, then passed on a real `friendly_target` (ALL CHECKS PASSED).

## Follow-up 3: shared_boss second failure on #738 (590973c7, run 40152511791)

Verdict: **still not PR #738.** One failure is the race fixed in 7e7e2e84; the other is a separate staging-geometry weakness in the smoke.

- **The PR head reproduces only the first failure.** 4 runs of 590973c7 locally, two at a time, unfixed smoke: 3 passed and 1 failed.
  - The failure was `the host refused it with friendly_target ... (got code 'pending_vitals')`, the same pre-resolve race as run 40150677244.
  - 7e7e2e84 re-stages on exactly this code.
- **The race exists on main too.** Pending_vitals refusals appeared in main-based runs as well (f3: one on the host).
- **The PR adds no measurable load.** Peer physics rates under paired load are the same on main and the PR: host 18.7–20.0 Hz vs 18.4–20.9 Hz, guest 24.6–26.1 Hz vs 25.3–26.2 Hz.
- **No camera or collision path is involved:**
  - `place_creature` writes `global_position` in world space.
  - `strike` aims at world targets. Neither reads the camera.
  - `combat_arena.gd`'s new `_process` (`pilot_mark.all_fights`) only moves a light and sets the rim.
  - `contact_burst` and `ground_burst` spawn visual particles after the hit is decided.
  - `hold_inside` and the contact spacing are unchanged.
  - `pitch_start`, `composition_yaw`, `fallback_max_steps` and the pilot floor only change the lens.
- **What the CI log shows (failure 2, "4.38 m of 4.00 m"):**
  - All 12 attempts have the guest's creature fixed at (-1.21, 6.17, 7661.98).
  - Attempts 1–9 used the in-ring path, with sides at 105°, 135° and 165°, multiples of FRIENDLY_RAYS' 15°. Attempts 10–12 used the away-from-boss fan. Every stand landed at Z 7662.4–7663.5, the +Z side.
  - After the 8-frame settle, the host's creature never held its stand. `place_creature` reported it back at about (2.4–3.1, 7660.0–7660.7) every time, about 4.4 m from the guest, so `apart >= SWING_REACH_M` and every attempt `continue`d (no window read, empty refusal).
  - This matches the smoke's own comment that "the Warden Arena's +Z face cuts the ring": a stand inside the ring can still be inside a wall.
  - Roomiest-first ordering keeps choosing +Z stands when the guest stands near that face.
  - Whether the guest ends near the wall depends on where its creature finished the boss-damage phase, which varies run to run.
- **Proposed smallest fix (not applied; awaiting your go):** in `tests/smoke_net_shared_boss.gd`'s staging loop, when the host's creature did not hold the previous stand (its re-read position is more than ~1 m from `stand`), stage the next attempt on the line from the guest towards where the host's creature was actually held, APART_Z from the guest.
  - For failure 2 that stand is (0.2, 7661.5): inside the room and clear of the boss (about 40° off the line, boss 7.5 m away against teammate 1.5 m).
  - Staging only; the `friendly_target`, `clean` and window assertions are unchanged.
  - An alternative that is less of a guess: first add the probe's ring centre and radius to the attempt print, to confirm the wall reading on the next failure.

## TO COORDINATOR

READY tb/netfix-wedge (head = this note commit) with fix 7e7e2e84 for the shared_boss race. VERDICT on #738's second failure (run 40152511791): not the PR; a staging-geometry weakness (host creature never holds a +Z stand near the Warden Arena wall). A fix is proposed in Follow-up 3 and awaits your go. Fix 7e7e2e84 (shared_boss re-stages a swing the host refused before resolving, pending_vitals or move_start_required; a test race, not PR #738). Earlier fixes: 294e6709 boss_rewards, 19a1733e client_trainer_rewards. origin/main f7b9b6a1 merged in. Root cause: tests/smoke_net_boss_rewards_each_participant.gd:194 sent its 6000-frame budget only as the step deadline. tools/net/peer_runner.gd:4395 bounds the win arm by args.budget_frames (default 2160 effective), so a slow 37-swing CI fight timed out 0.6 s into a normal final-round settlement. There was no owner-passive race; the "released then re-held" log pair is round 1 and round 2 sharing one hold key. Fix: pass args budget_frames 6000 with step 6400. Results: the CI signature reproduced locally at budget 1650; boss_rewards 6/6 local passes after the fix, run in parallel pairs. client_trainer_rewards got the same gap fixed (budget_frames 4000 / step 12600) and passed 3/3 locally. Unit suites not run (no production change).
