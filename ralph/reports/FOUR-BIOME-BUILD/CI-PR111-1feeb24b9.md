# PR111 reconnect watchdog — completed CI audit

Landing verified at 2026-09-09 21:47 UTC: PR111 merged as
`dc83a41936b676b04859ee6483183fc9e3cfd90a`. A fresh fetch confirmed main,
source-head ancestry and exact source/CI/landing tree
`9a994fa389d7a327fe35a87227a75f119e8376e0`. Main CI34408839617 and
Release34408839678 were queued/running when checked; neither has acceptance
credit yet.

[Run34406047749](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34406047749) passed attempt1 on frozen head `1feeb24b9f60c00efaafa6b30ed34825befb47e9`, 2026-09-09 21:17:02–21:43:28 UTC. Independent audit read run metadata, all29 job records and every step, plus all26 raw logs: **9,110,766 bytes**, retained under `.artifacts/pr111-1feeb24b9-ci/`. Exact extracted diagnostics, invocation groups and PR109 comparison are in `source-audit.json`.

All26 executed jobs and281 executed steps succeeded. Four cached-Godot installation steps were skipped. The three skipped jobs are the two known-red continuous/full-chain jobs and PR export. No failed/cancelled job or step. Solo-regression is the dependency fence, not another independent gameplay suite. This does not establish continuous-campaign acceptance or publication.

| Unit shard | Tests | Assertions | Failed |
|---|---:|---:|---:|
| 1 | 683 | 32,938 | 0 |
| 2 | 851 | 318,369 | 0 |
| 3 | 836 | 112,763 | 0 |
| 4 | 780 | 24,017 | 0 |
| Total | 3,150 | 488,087 | 0 |

Totals increase by exactly2 tests/11 assertions over PR109 and main d679. Both new watchdog tests have actual `ok` receipts in job102649687329 lines4053–4054. The other explicit suite summaries retain their previous counts: harvest30/799078, scatter38/1019854, vegetation9/1537510, terrain/scatter freshness each1/1, all zero failed.

All38 distinct network smokes match PR109's set and ran invocation1/1, including reconnect. All88 logged smoke groups across CI are first invocations; no emitted failed-attempt receipt or retry group occurred. The sole emitted `FAIL: ERROR: peer exited` is the deliberate peer-death negative control: job102650545331 lines3782–3784 records coordinator exit2 followed by `PASS: negative control`. Shell-source echoes containing failure/error search strings are not execution failures.

Logs contain **313 native `ERROR:` lines and zero `SCRIPT ERROR:` lines**: equal to PR109's313/0, versus main d679's319/0. All non-shutdown normalized diagnostic messages and counts match PR109, including139 outside-tree get_node,92 null-data.tree and29 null-material lines, plus established malformed-input/realm rollback and process-check diagnostics. Differences are only shutdown-resource/RID cardinalities: PR111 has3-resource exit lines9 times (PR1097; main8),4-resource lines17 (PR10913; main17), and5-resource lines1 (PR1090; main1). Its unit-shard shutdown reports28 resources and combined dummy-renderer RID counts where PR109 reported13/19 resources and split RID counts; one PagedAllocator line replaces two. Exact additions and removals are preserved in the audit JSON. The28-resource report follows the successful unit summary in job102649687321; it is retained diagnostic debt, not a clean-log claim. No new functional error class was identified.

Disposition: **no actionable CI blocker found for this frozen PR head**. Source review and the new regression address the completion-to-watchdog transition; this run supplies first-invocation CI evidence. The preceding c3e main run34401138071 remains a separately failed reconnect result. Neither PR109 nor main d679's later green run rewrites that failure; this PR's result is not a retry of it. Landing/main CI and publication remain separate obligations. No Godot execution or production edit was performed during this audit.
