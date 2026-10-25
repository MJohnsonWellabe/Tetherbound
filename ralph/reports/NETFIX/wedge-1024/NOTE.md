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

## Follow-up 4: shared_boss staging fix (coordinator GO), 7b85a73a

- **The ring print corrected Follow-up 3's reading.** The probe's ring is (7.24, 6.17, 7655.75), r=6.45, in every run.
  - In CI failure 2 the guest's creature was 10.50 m from the centre, **4.05 m outside the ring**, and the host's creature was held exactly on the edge. It was the ring, not a +Z wall.
  - No host-only stand can come within the 4.0 m reach of that guest, so the approved re-aim alone would not have rescued that run.
- **So 7b85a73a does three things (staging and diagnostics only; the friendly_target, clean and window assertions are unchanged):**
  1. A guest's creature found outside the ring is seated 1.5 m inside its edge, through `place_creature` on the guest; its position replicates to the host.
  2. The approved re-aim: when the host's creature ends more than 1 m from its stand, the next attempt stands toward where it was actually held.
  3. The attempt print carries the ring centre and radius (plus `held_retarget` when used).
- **Validation on 590973c7 plus 7e7e2e84 and 7b85a73a, two at a time:** 8 runs, 7 passed.
  - **Forced failure-2 geometry, 2/2 passed.** A temporary copy put the guest's creature at CI's exact spot, 4.05 m outside, before the loop. Log: `guest 4.05 m outside the ring; seating it at (3.25, 6.17, 7658.69)`, then a clean attempt 1 at 1.8 m apart.
    - The host's view of the guest lags about 8 frames after the seat, so attempt 1's stand came from the old position and the re-aim also fired. It still worked: the host's creature is held at the edge beside the seated guest.
  - **Normal runs, 5/6 passed.**
    - The seat fired in n3, n4 and n5 (guests 0.0–1.0 m outside); the re-aim fired in n6.
    - An earlier batch (590973c7 plus 7e7e2e84 and the re-aim only, before the seat step) passed 8/8: 7 normal and 1 forced unheld stand. The re-aim fired in 3 of them.
- **The one failure (n5) is a separate, pre-existing failure, not this fix.**
  - "peer 0's creature is alive to be swung at (0.0 hp)": the host's creature died to the boss during the earlier boss-damage phases (self-HP top-ups are off by design), so the fight ended before the friendly half.
  - In n5 the seat and staging themselves worked: clean attempt 1, 1.81 m apart.
  - Unmodified main's smoke hit the same failure in base b1 (Follow-up 2), so it is about 2 in 18 local runs and predates #738 and these fixes.
  - Not fixed here: it needs an owner-level choice on top-ups, or a tougher fixture, for the friendly phase. Proposal: before the friendly loop, stop with a clear "teammate creature fainted before the friendly phase" detail instead of the misleading friendly_target failure, or re-deploy a live creature for peer 0.

## Follow-up 5: shared_boss "host creature fainted before the friendly phase", root cause (no change yet)

- **Measured:** 8 runs, two at a time, of a temporary copy of the branch smoke (main plus 7e7e2e84 and 7b85a73a) with HP prints at each phase boundary.
  - The host's creature has about 134 HP (the guest's reads 134.4) and each boss hit costs about 15.5.
  - "after_mover_N" below means after pilot N (0 = host, 1 = guest) has landed its blow on the boss.

| run | after first_down | after host's half (boss hits on host) | after guest's half (boss hits on host) | friendly |
|---|---|---|---|---|
| d1 | 85.0 | 37.0 (3) | **0.0** (4th hit, during the guest's half) | FAIL (fainted) |
| d2 | 84.5 | 55.4 (2) | 24.3 (4) | pass |
| d3 | 89.2 | 72.5 (1) | 42.1 (3) | pass |
| d4 | 81.7 | 49.8 (2) | 34.3 (3) | see below |
| d5 | 90.0 | 58.9 (2) | 43.7 (3) | pass |
| d6 | 84.1 | 67.9 (1) | 52.8 (2) | pass |
| d7 | 89.6 | 74.1 (1) | 58.9 (2) | pass |
| d8 | 81.9 | 49.4 (2) | 49.4 (2), 34.6 at the swing | pass |

- **Root cause:** the boss's landed hits all go to the host's creature.
  - `struck_counts` only ever names peer 1, and the guest's creature stays at 134.4 except in d1.
  - `pick_struck` spreads only among candidates its swing reaches (`encounter_host.gd:1482`), so the least-struck rule never shares the load here.
  - The host's creature is left standing beside the boss (at -NEAR_Z from its own half) through the whole guest's half and still takes 0–2 hits there (6 of 8 runs).
  - With top-ups off it reaches the friendly phase with 24–59 HP, a 1.5–3.8 hit margin. When the host's half runs long (d1: 3 hits), the guest's half finishes it.
  - Measured rate: 1/8 here, 2/18 before (b1, n5). It is the same on main; not #738.
- **A timer would not help.** Each damage half already ends on its first landed blow. Capping attempts only trades this failure for the "landed a blow" assertion failing.
- **Options (tell me which):**
  - **A (recommended):** move the host's creature out of the boss's reach before the guest's half (one `place_creature` on peer 0, at the far side of the ring), so the boss's swings during that half have no host candidate.
    - Staging only. It keeps the smoke's stated rule "the fight driver supplies no self-HP top-ups in any of this smoke's modes", and no assertion changes.
    - Risk: the boss AI may chase the host's creature. That needs a trial, with HP prints showing 0 host hits during the guest's half.
  - **B:** one bounded typed heal of the host's creature before the friendly phase, through the disclosed fixture provider `tools/net/f48_actor_topup.gd` (the durable save/ACK path win_trainer_battle already uses).
    - Most deterministic, but it reverses the smoke's explicit no-top-ups rule, so it needs your (or the owner's) call.
  - **C:** run the friendly half before the boss-damage half (the host's creature is at 82–90 HP then). This is a larger reorder of the smoke's narrative.
- **Separate new flake seen in d4:** "both peers draw the same boss health bar after it (host 214.717, guest 222.109)". The guest's boss HP was read before the second blow replicated; it is a single read with no wait. A small poll, like the refusal wait, would fix it. Say if you want that too.

## Follow-up 6: boss_rewards on PR #740 (0104628a, run 40163114819, shard 7): enemy hp 0, fainted=false

Verdict: **not #740's held wince.** It is a real wedge, pre-existing on main. The host turns a transient "guest pose not yet observed" into a terminal stream error.

- **What the CI host log shows:**
  - The guest's fly landing near Bryn was refused `no_ground` 325 times. This matches the passing runs (the earlier CI artifact showed the same refusals before `granted`).
  - It was then `granted (ok)` (peer-0.log l.443), and one millisecond later: `combat_round_reward duty for <guest> held: owner passive gate owner_passive_initial_pose_unconfirmed (t=67549ms)`.
  - That hold never changed until the end (t=148 s): round 1 never resolved. So the director kept the defeated bramblebun at hp 0 with `fighting=true`, and the arm timed out at 5760 frames. The final `pending_vitals` refusal is a consequence, not the cause.
- **Root cause:** `scripts/net/owner_passive_sync.gd:691-699` (`_inputs_host_batch`).
  - The guest's first discovery input names its new position at the landing. The host checks it with `_pose_observed_near` against its own replica of the guest's body: current position, or any sample within INITIAL_POSE_LAG_S = 2 s, within 80 m.
  - Right after the grant, the host's replica (and every sample from the last 2 s) is still at the pre-flight spot, (-1.4, 4.65, 14.3), about 87 m from (80, 0.9, 46).
  - So the check fails and the code sets `stream.error = "owner_passive_initial_pose_unconfirmed"`. That is terminal: every later `gate()` returns it, the guest's round reward can never stage, and the round never resolves.
  - The sibling case three lines up (`no host body for this owner`) returns false without an error and retries the same prefix when the owner resends.
  - This code dates from 62efa83c (22 Oct). The fly-landing timing makes it rare.
- **#740 cannot reach this path.** Its runtime changes:
  - `creature_animator.gd` `hold_wince` / `_stagger_left`;
  - `creature_body.gd` `hold_combat_wince` and the bigger flinch tween;
  - `wild_creature.gd` calling the hold on stagger;
  - `combat_manager.gd` / `remote_creature.gd` publishing `stagger_seconds` on hit presentation.
  - These are animation and presentation only: no collision, position, pose sampling, fly landing, owner-passive or round-resolution code.
  - A held wince does not defer a faint either: `play_faint` is final and `_play` clears `_stagger_left` for any non-HIT role.
- **Local, two at a time:** PR head 0104628a, 2/2 completed runs passed (pr3, pr4), the landing pattern normal, no `initial_pose_unconfirmed`. pr1 and pr2 failed only on "not every peer said hello within 180 s" (the first pair right after a re-import), so they say nothing about the battle. The race did not reproduce locally.
- **Proposed smallest fix (production net code, so not applied; needs your go):** in that branch, wait instead of failing while the refusal is young.
  - Record when the first refusal happened for that input sequence, note it with `_note_host` and return false, the same as the no-body wait.
  - Set the terminal error only if the same input is still unconfirmed after INITIAL_POSE_LAG_S (2 s).
  - This keeps "never any pose the host did not observe": the input is only ever accepted against a pose the host actually sampled.
  - `tests/test_owner_passive_sync.gd`'s four refusal tests (l.369-427) would then assert "waits, then refuses once 2 s have passed" through the existing `_record_pose` timestamps / `first_input_refusal.sampled_ms`, plus one new test: a pose the host observes during the wait is accepted.
  - Owner: whoever owns the owner-passive stream (Routes/net). It does not belong in tb/creatures-land2.

## Follow-up 7: coordinator decisions of 25 Oct 05:12

**Item 2 (PR #740 boss_rewards).** Already answered in Follow-up 6, which crossed with your message. It is not a win-arm retry problem.
- The guest's round-1 reward is held by a terminal host-side stream error (`owner_passive_initial_pose_unconfirmed`, `owner_passive_sync.gd:691-699`), set the instant the guest's fly landing was granted.
- Re-issuing a strike on `pending_vitals` or `move_start_required` in peer_runner's win arm cannot clear it: the round waits on that duty, not on a swing. The last `pending_vitals` refusal is the round being held, not the cause.
- #740's changes cannot reach that path.
- I did not run 6 vs 6. The cause is in the CI host log itself, and the race did not appear in 2 completed PR-head runs, so a few more runs per side could not separate PR from main.
- The proposed fix (wait up to 2 s on an unconfirmed first pose before the terminal error) still needs your go.

**Item 1 (Follow-up 5, option A, park the host's creature): tried; it does not work, so it was not committed.**
- The trial on the branch (main 1c64efc1 merged in) parked the host's creature at the ring's farthest point from the boss (0.5 m inside the edge, about 8.4 m from the boss) before the guest's half.
  - k1: struck 2 → 4 during the guest's half, hp 56.3 → 24.4.
  - k2: struck 1 → 2, hp 70.7 → 57.1.
- So the host's creature is still hit, from the farthest in-ring stand there is. Either the host's own combat manager walks its creature back toward the fight (the smoke's friendly staging notes that "each manager pulls its creature back"), or the boss closes the distance.
- No stand is farther inside the ring, so A cannot reach your "0 host hits" bar. I stopped after 2 runs and dropped the commit (never pushed).
- **Remaining options:**
  - **B:** one bounded typed heal through `tools/net/f48_actor_topup.gd` before the friendly phase. Deterministic, but it reverses the smoke's stated no-top-ups rule.
  - **C:** run the friendly half before the boss-damage halves, while the host's creature is at 82–90 HP.
  - Both need your call.

## Follow-up 8: the #740 boss_rewards race, fixed (07c601da)

- **The Creatures lane's "synced hp 0, nothing resolves" path is not this failure.** The CI round diagnostic (`ordinary-round-failure-2788-6580.json`) shows the host resolved the win:
  - manager outcome `won`, enemy `hp 0.0 fainted true`;
  - round 1 captured and journaled;
  - `last_resolution_result = {code: round_owner_save_pending, durable: true, resolved: false}`.
  - The round waited on the guest's owner save, which the terminal stream error blocked forever (Follow-up 6). So "resolve on synced hp" or "re-issue on pending_vitals" would not have fixed it.
- **Fix** (`scripts/net/owner_passive_sync.gd`, the first-pose branch of `_inputs_host_batch`):
  - An unconfirmed first discovery now waits, like the no-host-body wait above it.
  - The exact prefix stays unapplied and is retried on the owner's 1.5 s resend.
  - It is accepted only against a pose the host itself observed (unchanged `_pose_observed_near`).
  - Still unconfirmed INITIAL_POSE_LAG_S (2 s) after its first refusal, it is refused terminally as before.
  - A malformed position is refused at once. `first_input_refusal` still records the first refusal.
- **Tests** (`tests/test_owner_passive_sync.gd`):
  - The four refusal cases (sequence gap / far pose / sample older than 2 s / wrong realm) now assert the wait, then the same terminal refusal once the wait has expired.
  - A new case reproduces the CI order: replica 87 m back at the landing, then the replica arrives and the resent input applies.
  - The new case **fails on the unfixed code** and passes with the fix.
  - `--only=owner_passive,owner_pose_prefix`: 96 tests, 1594 assertions, 0 failed. `--only=ledger,travel_reset,fly_landing`: 89 tests, 0 failed.
- **Smoke:** `boss_rewards_each_participant` passed 4/4 locally (two at a time) on the branch (main 1c64efc1 plus the fixes). The new wait did not fire in those 4 (the race is rare locally); the unit test is the reproduction.
- **Ownership:** this is net/owner-passive code, not tb/creatures-land2, and it is on main independent of #740. Port 07c601da.

## Follow-up 9: review notes, health-bar poll, option C (25 Oct)

- **Review note 1, configurable window (33829cfe).**
  - The first-pose wait is now `multiplayer.json session.owner_passive_first_pose_wait_s`, default 4.0, with `_why` and `_scope`. When it is absent or <= 0 it falls back to INITIAL_POSE_LAG_S (2 s).
  - The terminal `owner_passive_initial_pose_unconfirmed` after the window, and the host-observed-only acceptance, are unchanged.
- **Review note 2, tests (33829cfe):**
  - A waiting first discovery is accepted through a host pose sample taken during the wait, with the current body 110 m away.
  - A far pose resent inside the window is not applied, does not restart the wait, and is refused once the window passes.
  - `--only=owner_passive,owner_pose_prefix`: 98 tests, 1615 assertions, 0 failed.
- **Health-bar poll (2f3ef1c0).**
  - The guest's boss-HP read after each damage half polls (REFUSAL_POLLS x FRIENDLY_SETTLE) while it differs from the host's.
  - A copy that never matches still fails the unchanged assertion.
- **Option C (friendly half first): not done, because it cannot fix the failure.**
  - In the failing HP-traced run (d1, Follow-up 5) the host's creature died during the damage halves. The fight then ended, and the run failed both "peer 0's creature is alive to be swung at" and "the two of them fought the Warden's whole team of 5 down (no trainer battle is running)".
  - A faint of the host's creature ends the host's trainer battle. Running the friendly half first takes no hit out of the damage halves before the final team fight, so that run would still fail, at the final battle instead of the friendly check.
  - **Why the host takes every hit:** `host_pick_struck_participant` (`encounter_director.gd:4209`) takes candidates only from bodies the boss's swing arc reaches. The damage halves stage the guest's creature on the boss's far side ("each on its own side … neither is ever in the other's arc"), and the boss faces the host's creature, so the guest is never a candidate.
  - What would actually stop the faint is B (one bounded heal, against the smoke's no-top-ups rule), or staging both creatures inside the boss's arc during the damage halves. The latter conflicts with the comment's reason for separating them (no friendly hits during that half). Both are your call. The failure did not recur in this batch's 8 runs (its rate is about 1 in 9).
- **Validation on current main (1c64efc1) plus every shared_boss fix (7e7e2e84, 7b85a73a, 2f3ef1c0) and the first-pose wait (07c601da, 33829cfe), two at a time:** shared_boss passed **8/8** (s1–s8; the last four on the 33829cfe build).

## Follow-up 10: option B (bounded heal through f48_actor_topup) as specified conflicts with the fixture's verified contract (no change)

Two constraints in the existing disclosed path make "one bounded, typed heal, back to at most the HP at the start of the damage halves" impossible without production changes:

1. **It is a full heal by contract.**
   - `request_topup` stages `max_hp - hp` (`tools/net/f48_actor_topup.gd`).
   - The host's verifier refuses any other amount: `scripts/combat/accepted_action_host.gd:570-571`, `verify_original_fixture_actor_topup`, requires `proposal.amount == before.max_hp - before.hp` (and `hp < max_hp`).
   - A capped heal would be refused by production authority code, so the cap needs a change in `accepted_action_host.gd` (verifier + `commit_original_fixture_actor_topup`) plus the provider. That is production code, beyond the smoke.
2. **It only runs inside the fight driver.**
   - `request_topup` refuses unless `_trainer_fight_progress.running`, `_trainer_fight_director` and the observed encounter id are set, i.e. inside `peer_runner._step_win_trainer_battle`.
   - There, `self_hp_topups` calls it every `stride` frames, so it is a repeated top-up during that call, not one heal. A single heal between the damage halves and the friendly phase needs either a new peer_runner step that wraps the provider once (harness code), or a `win_trainer_battle` single-shot option.

**Options:**
- **B1 (smallest that keeps production untouched):** a new peer_runner step `actor_topup_once` that installs the same provider (same DISCLOSURE) and calls `request_topup` once, waiting for its owner save/ACK. It heals to **full** (the contract), not to the start-of-damage-halves HP; the smoke header discloses it.
- **B2 (your spec exactly):** add a capped amount to the provider and to the verifier/commit in `accepted_action_host.gd`, plus its unit tests in `test_combat_progression.gd`. This is production authority code, so it needs its own independent review.
- **Arc staging (no heal):** stage the guest's creature inside the boss's swing arc during the damage halves so `pick_struck` spreads the hits. It conflicts with that phase's "neither in the other's arc" rule (friendly hits).

Waiting for your pick. Per your instruction nothing is pushed while PR #742 is in CI; this note is pushed after #742 merges.

## Follow-up 11: option B, the one disclosed aid (4d0a9a3e)

- **Built as B1:** the smallest form the disclosed provider's contract allows (Follow-up 10).
  - A new peer_runner step `actor_topup_once` installs the same `tools/net/f48_actor_topup.gd` provider with the same DISCLOSURE.
  - It sets the same fight-driver binding `win_trainer_battle` sets (director, encounter id, running progress) for one call, calls `request_topup` once, waits through its owner save/ACK, then clears the binding.
  - The heal is the provider's verified full heal (`amount == max_hp - hp`, `hp_after == max_hp`). It never revives and is never repeated.
  - It runs after the two damage halves (their checks read first) and before the friendly half.
- **Deviation from your earlier "at most its HP at the start of the damage halves":** that cap is impossible through this provider without changing the production verifier (`accepted_action_host.verify_original_fixture_actor_topup`, `session._ordinary_fixture_topup_source`). Your 07:10 restatement did not repeat the cap. If you still want it, that is B2 (production change plus review).
- **Smoke header:** "no self-HP top-ups" now names this single exception, its provider, its contract and its reason (Follow-ups 5 and 9).
- **Assertions:** none changed or removed. One added check reports whether the aid settled.
- **Validation on main eb890e6a plus 4d0a9a3e, two at a time:** shared_boss passed **8/8**.
  - The aid settled in every run (`actor_owner_saved`, same frame).
  - The host's creature had 19.7–59.9 hp before the aid (two runs at about 20 hp, one boss hit from fainting) and 134.4 after.

## TO COORDINATOR

READY tb/netfix-wedge (head = this note commit): option B in 4d0a9a3e. A new peer_runner step `actor_topup_once` gives the host's creature one disclosed full heal through f48_actor_topup.gd after the damage halves and before the friendly half; the header discloses it; no assertion changed. shared_boss 8/8 on main eb890e6a, two at a time. The full heal is the provider's verified contract; a capped heal would be B2 (production verifier change).


READY tb/netfix-wedge (head = this note commit), single batch for the 07c601da PR: 07c601da + 33829cfe (owner-passive first-pose wait, 4 s configurable window, review cases), 2f3ef1c0 (shared_boss health-bar poll). shared_boss 8/8 on main 1c64efc1, two at a time; owner_passive + pose_prefix 98 tests, 0 failed. Option C not applied: it cannot stop the host-faint failure (Follow-up 9); B or arc staging is your call. Earlier entries: port 07c601da, the owner-passive first-pose wait that fixes #740's boss_rewards wedge (a main race). STATUS (Follow-up 7): option A tried and does not work (host's creature still hit from the farthest in-ring stand); B or C needs your call. VERDICT (Follow-up 6, PR #740 boss_rewards): not the held wince; a pre-existing terminal-error race at owner_passive_sync.gd:691-699 after a fly landing. A bounded-wait fix is proposed and awaits your go. VERDICT (Follow-up 5): the 'fainted before friendly' failure is the boss concentrating every landed hit on the host's idle creature through the guest's damage half. Options A/B/C await your choice; no change made. Previously READY: shared_boss fixes 7e7e2e84 (pre-resolve refusal race) + 7b85a73a (seat an out-of-ring guest, re-aim an unheld stand, ring diagnostics). Validated on 590973c7: forced failure-2 geometry 2/2 (plus a forced unheld stand 1/1, pre-seat build); normal runs 12/13 across two batches (7/7 pre-seat build, 5/6 final); the one failure is the separate pre-existing 'host creature fainted before the friendly phase' failure, which unmodified main also hit. Fix 7e7e2e84 (shared_boss re-stages a swing the host refused before resolving, pending_vitals or move_start_required; a test race, not PR #738). Earlier fixes: 294e6709 boss_rewards, 19a1733e client_trainer_rewards. origin/main f7b9b6a1 merged in. Root cause: tests/smoke_net_boss_rewards_each_participant.gd:194 sent its 6000-frame budget only as the step deadline. tools/net/peer_runner.gd:4395 bounds the win arm by args.budget_frames (default 2160 effective), so a slow 37-swing CI fight timed out 0.6 s into a normal final-round settlement. There was no owner-passive race; the "released then re-held" log pair is round 1 and round 2 sharing one hold key. Fix: pass args budget_frames 6000 with step 6400. Results: the CI signature reproduced locally at budget 1650; boss_rewards 6/6 local passes after the fix, run in parallel pairs. client_trainer_rewards got the same gap fixed (budget_frames 4000 / step 12600) and passed 3/3 locally. Unit suites not run (no production change).
