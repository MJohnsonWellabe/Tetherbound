# PR97 shutdown-corrected head — green status with retained opening failure

Head `5fae4e981ee32bafc9dd4fd657b1067d21576479`, CI34365460024 attempt1,
2026-09-09 14:43:08–15:02:22 UTC (19m14s). GitHub status is success:
26 successful jobs,3 skips. **This is not clean first-invocation acceptance:**
the opening smoke failed its first invocation and the existing wrapper retried it.

All26 complete raw logs retained at `.artifacts/pr97-5fae4e98-ci/job-<id>.log`,
9,393,857 bytes.3,118 unit tests/487,832 assertions/0 failed; all seven network
shards passed. The lifecycle step passed actual Game108 with exactly4 injected
errors and native81/77/82 with terminal synchronizer inventories checked. The
eight inactive-ENet errors from first head452a7d10 are gone. Their original failure
remains in its separate receipt.

Full raw review found `gate_a_opening_segment` failed attempt1/2 in job102513681866.
At14:49:21 it reported an actionable **Engage Mudsnout** prompt while its intended
body was the natural Bramblebun9.72m away. At14:49:24 it failed to enter combat.
Automatic attempt2/2 then completed the opening and catch. The first failure is
retained; neither GitHub's job status nor the successful retry supersedes it.

The opening driver's readiness predicate checks only the shared EncounterDirector
provider and actionable offer, not the actual body that provider would engage.
It also ignores disabled interaction. The more recent `fresh_opening_segment`
already distinguishes the exact offered body, but this older base drive did not.
Root is correcting the base drive to require enabled/actionable exact-body
readiness before and after movement settles and to verify the admitted body.
The named CI opening step will execute once, so another first failure stays red.
This identifies a concrete driver defect; the retained log alone does not prove
every reason the original Interact failed to start combat.

Other raw differences remain existing shutdown resource counts and unit-negative
controls. Aggregate unit errors217 versus218 on main1eef, with a changed19-resource
shutdown count; no new SCRIPT ERROR. Net2 retains the deliberate peer-kill cleanup
errors, and net5 is clear on this head. The additional hosted Stormwood and Water
transport/roster corrections were found during review and are **not in this head**.
Their component results and shipping manifest are separately recorded in
PR97-HOSTED-TRANSITION-SETTLEMENT.md. A new exact-head CI is required before landing.

The exact-body predicate correction passed its first focused Windows run: one
test, eight assertions, zero failures, exit 0, no engine errors or warnings.
Raw log and UTC receipt: `.artifacts/gate-a-exact-offer-0909/`. It exercises a
neighbor offered through the same provider, a changed candidate after settling,
disabled/stale offers and non-mutating observation. It is component evidence;
the next CI must prove the actual opening on its single invocation.
