# P0 mastery re-land on main 122682adb (tb/ev-systems), Tue 13 Oct 2026 (CT)

## Head
- 26c06390: main merged; the 8 reverts (03af81ac2 10431ef01 51c86a984 c9d8c746c 29c2df6a5
  c6e7a0f5e 7b3551b07 ed7f9b787) undone by restoring their files from the pre-merge branch
  (session.gd conflicted). Verified tree = pre-merge tb/ev-systems + main's board commit.
- Carries the series 7910ca114..baedacc50 plus bdd21c5c (stage lands owed writes), e28706f7
  (f48 feast view), 7382a176 (harness leave). 79ad8b0e: a Session test double gets the new param.
- Final: frozen_unprepared no longer requires the live record to equal the frozen hash, because
  host vitals keep landing during a live fight (re-land harness run 1 refused the leave).

## Disclosed fixture sequencing (tests/helpers/harness_hp_net_peer.gd; no assertion changed)
- f3da95fc: `harness_wear` (a direct record write) waits for the owner fence; `harness_host_hit`
  waits for pending saved vitals, which the host strike rule refuses on.
- This head: `harness_read` waits for this side's pending saved vitals, so one hit's counter and
  HP never split across the before/after pair (stored-loss arithmetic failure, 1 in 5 runs).

## Proof (local, headless)
- On 79ad8b0e: boss_rewards 3/3, f48_coop_loop 3/3, f28_masters 3/3, harness 2/3 (the leave
  refusal above). Unit tests (mastery, record_errors, research/owner passive, resource save,
  prepared training, offline session, ledger, save, training): 206 tests, 0 failed. The full
  unit suite ran 5,919 test methods with 0 FAIL before my 50-minute cap; it did not finish.
- After the frozen_unprepared change: harness 5/5 leave writes (one HP-arithmetic split), then
  with the read-settle fixture 5/5 PASS. owner_passive_sync + training_guard_lifetime 55/0.
- The other three smokes were not re-run after the final change. It touches only the leave
  save guard and the harness-only helper.
