# Main d67976bba — completed CI audit

[Run34404989612](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34404989612), head `d67976bba0705276def96642b7c5a784c626e215`, completed successfully on attempt1, 2026-09-09 21:06:11–21:37:45 UTC. Independent source/log audit read `run.json`, every job/step conclusion and all27 raw job logs: **10,318,318 bytes** under `.artifacts/main-d67976bba-ci/`. Full extracted receipts and exact error-class comparison are in `source-audit.json`; reproducible scanner is `audit_source.py`.

There are27 successful executed jobs,296 successful steps, five skipped cached-Godot installation steps, and two skipped known-red continuous/full-chain jobs. No failed/cancelled job or step. Export ran on main, unlike PR109; its release/publication semantics are a separate audit. The solo-regression job is a dependency fence, not another independently executed gameplay suite. This is not full continuous-campaign acceptance.

| Unit shard | Tests | Assertions | Failed |
|---|---:|---:|---:|
| 1 | 810 | 15,854 | 0 |
| 2 | 766 | 322,353 | 0 |
| 3 | 854 | 116,090 | 0 |
| 4 | 718 | 33,779 | 0 |
| Total | 3,148 | 488,076 | 0 |

Unit totals exactly match PR109. Other explicit suite summaries also match: harvest30/799078, scatter38/1019854, vegetation9/1537510, and terrain/scatter freshness each1/1, all zero failed.

All38 distinct network smokes match PR109's name set and ran invocation1/1. All88 logged smoke invocation groups across CI are first invocations; no emitted failed-attempt receipt or retry group was found. Reconnect completed with `ALL CHECKS PASSED` at21:27:06 in job102649152943. The emitted `FAIL: ERROR: peer exited` in job102649152969 is the deliberate peer-death negative control: immediately followed by its required coordinator-exit2 receipt and `PASS: negative control` at lines3781–3783. Echoed shell text containing `failed on attempt ${n}/${RETRIES}` is not execution failure.

Raw logs contain **319 native `ERROR:` lines and zero `SCRIPT ERROR:` lines**, versus313/0 in PR109. The exact-message delta is entirely retained-resource shutdown counts:

| Diagnostic | PR109 | Main |
|---|---:|---:|
| 3 resources still in use at exit | 7 | 8 |
| 4 resources still in use at exit | 13 | 17 |
| 5 resources still in use at exit | 0 | 1 |

The new five-resource spelling occurs after `night ecology smoke test passed` at job102648581244 lines4122–4126. Every other normalized native diagnostic message/count matches PR109, including139 outside-tree get_node lines,92 null-data.tree lines,29 null-material lines, expected malformed-input/realm rollback diagnostics and peer-death process checks. These remain real diagnostic debt; this is **not a clean-log pass**. No new functional error class was identified from the comparison.

The preceding c3e main run34401138071 remains separately **failed** at reconnect's heartbeat watchdog. This later d679 pass does not repair, invalidate or rewrite that failure and does not validate the pending watchdog fix. It establishes this run's observed first-invocation result only. No Godot execution or production edit was performed during this audit.
