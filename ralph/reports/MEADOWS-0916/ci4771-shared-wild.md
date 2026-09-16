# Original shared-wild CI failure and transaction isolation

Run [35062871038, multiplayer shard 2, job 104688805160](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35062871038/job/104688805160) tested merge `a94fdcd071a845ab6bab9c5add3473eb5b9efe95` of `c9c4610e7856eacdb5e83c08652e1bab978dc90e`. The first and only attempt of `smoke_net_shared_wild_fight.gd` failed. This verdict remains a failure; no rerun or waiver replaces it.

At 06:34:08 UTC, the correlated host receipt for action 9003 correctly reported `friendly_target`, `hit:false`, and a connected friendly creature. Opponent HP stayed 54.021. During the surrounding network-probe window, host creature HP fell 108.140 to 96.390 and the opponent's landed-hit counter advanced 2 to 3. Both strict no-damage-window assertions failed. The later peer-death failure is an intentional negative control, explicitly accepted by that smoke.

The read-only comparison `git diff --name-only 898b521a c9c4610e -- scripts autoload data tests/smoke_net_shared_wild_fight.gd tools/net/peer_runner.gd` returned no files. This supports an existing timing-dependent measurement problem rather than a newly changed friendly-fire implementation; it does not turn the failed attempt into a pass.

The repair observes HP and opponent-hit counts synchronously before and after the exact host strike handler, correlated by encounter, requesting peer, action and victim. Existing refusal, connected-candidate geometry and host receipt checks remain required. Enemy turns outside that transaction remain logged but cannot be attributed to the refused action. In-transaction HP changes still fail. No AI, balance, waits or retry policy is changed.

## Local validation

Both first local attempts passed against source `015dab0f` plus this uncommitted repair; no retry was needed:

- `--headless --path . --script tests/run_tests.gd -- --only=net_strike_transaction`: process 0, four tests, 18 assertions, zero failures. Receipt: `ci4771-transaction-unit-attempt1.log`.
- `--headless --path . --script tests/smoke_net_shared_wild_fight.gd`: process 0, `ALL CHECKS PASSED`. Coordinator receipt: `ci4771-shared-wild-local-attempt1.log`; raw two-peer evidence: `ci4771-shared-wild-local-attempt1/`, including `SUMMARY.md` and both peer logs. Clean network, no proxy. Both peers exited normally; no Godot processes remained.

The live action 9003 receipt reported `friendly_target` and a connected friendly creature. Its before/after transaction snapshots had identical host time 139251 ms, victim HP 95.8307404982181, opponent HP 53.6203633464044 and opponent-hit count 3. Neither coordinator nor peer logs contained `SCRIPT ERROR`, `ERROR:` or `FAIL:`. Surrounding-window values are also retained in the coordinator log. These local results validate the repaired measurement; they do not rewrite the original failed CI attempt or claim a new CI run passed.
