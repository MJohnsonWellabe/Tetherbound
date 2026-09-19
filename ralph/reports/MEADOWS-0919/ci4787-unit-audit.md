# CI 4787 unit-shard audit

Candidate: `f1fd783372f1e4bf28477cd968d6f36c5a362858`. Run: [35454805960](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35454805960), PR 127, observed 2026-09-19. GitHub run metadata reports `run_attempt: 1` and the exact candidate SHA. Full workflow was still in progress when audited; this is **unit-shard evidence only**, not full CI or Meadows acceptance.

All four terminal job logs were fetched through the GitHub connector and inspected. Each contains one direct `tests/run_tests.gd` execution, one terminal result summary, and no actual `SCRIPT ERROR:` diagnostic. The two earlier Godot launches in each job are the cold/verification imports, not test retries.

| Unit shard | GitHub job | Tests | Assertions | Failed |
| --- | --- | ---: | ---: | ---: |
| 1 | [105928355387](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35454805960/job/105928355387) | 896 | 34,324 | 0 |
| 2 | [105928355508](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35454805960/job/105928355508) | 919 | 64,749 | 0 |
| 3 | [105928355488](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35454805960/job/105928355488) | 895 | 31,590 | 0 |
| 4 | [105928355370](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/35454805960/job/105928355370) | 1,030 | 376,729 | 0 |
| Total | All four completed successfully | 3,740 | 507,392 | 0 |

## Candidate tests actually executed

Shard 2 logs six successful `test_gate_f_village_passage.gd` tests at 16:27:27 UTC: clear same-side travel and unrelated gate rejection; closed-gate crossing refusal and outside detour; existing endpoint escape from conservative padding; native R14 geometry and reverse route; near-panel travel and square corner clearance; small moving-target route invalidation.

Shard 4 logs five successful `test_gate_f_engage_approach.gd` tests at 16:27:31 UTC: exact pinned enemy and once-only consumption of an approach-started fight; disabled/wrong-control refusal; four live-target stances; post-input enemy identity; actual winning provider identity. These eleven tests each appear once in the first workflow attempt. The logs provide per-shard assertion totals, not separate assertion totals for these two files.

## Error output and limits

Successful assertions do not mean error-free logs. Shards 1, 2, and 4 contain off-tree fixture diagnostics. Shard 2 also emits deliberate corrupt-settings JSON and unscoped-flag negative-test errors; `upper_open` is emitted from `test_realm_world_records.gd:80`. Shard 3 emits unknown-species and corrupt-settings negative-test errors and the deliberately invalid party-interface error from `test_party_seam.gd:244`. Shard 4 emits the unknown-conversation negative-test error. Shards 2 and 4 retain shutdown resource/RID leak diagnostics (15 and 17 resources respectively). No listed error was attributed to the new passage or Engage tests in the inspected logs.

This audit launches no local engine and uses no renderer. It does not replace native traversal, campaign replay, visual evidence, remaining CI jobs, or full acceptance.
