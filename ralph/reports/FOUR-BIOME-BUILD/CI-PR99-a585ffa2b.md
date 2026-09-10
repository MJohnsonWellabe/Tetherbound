# Superseded PR99 CI — retained partial run

Run34373237730 on head `a585ffa2be9504eaa5e54ea40c0cab2b02a745e6`
was superseded when PR99 was stacked onto the reviewed PR94 integration head.
It is cancelled partial evidence, not a passing verification or a rescued retry.
Replacement combined head34caa2e22 has its own run34374823501.

The terminal inventory contains29 jobs: five successful,22 cancelled and two
skipped. Fourteen jobs actually started; all14 complete available raw logs are
retained in `.artifacts/pr99-a585ffa2-ci/`, totaling3,895,302 bytes, alongside
final job metadata and a diagnostic extraction. Thirteen cancelled jobs never
started and have no executed-step logs. Nine started jobs were cancelled.

Completed work comprises change detection, network discovery, both bake checks
and unit shard2. Other partial logs retain engine diagnostics including
off-tree node access, material-null and resource-shutdown messages; no zero-error
claim is made. The extraction also includes echoed workflow source, which is
not an executed failed attempt. No executed failed-attempt line or SCRIPT ERROR
was found in that scan. Unfinished unit/world/network coverage is not inferred
from cancellation or from the five successful jobs. The new exact combined run
must establish its own complete coverage and raw diagnostic comparison.
