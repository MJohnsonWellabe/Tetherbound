# PR95 exact-head CI review

Head `2a971cb3a2a232e0bdb4e89f4613f878b58fa24b`, base
`4830bf402a94d7d945119027a454d07dfee1dccc`. Run `34344633432`, attempt1,
2026-09-09 11:15:57–11:35:38 UTC, terminal success (19m41s).

All29 jobs and all-attempt metadata inspected:26 succeeded, three intentional
skips (two known-red optional campaigns and the PR-gated export). All26 executed
raw logs reviewed,9,196,304 characters retained under
`.artifacts/pr95-ci-review-handoff/`; `final-jobs.json` and
`review-inventory.json` map identities. No failed/cancelled job, second workflow
attempt, or wrapped-smoke retry occurred. Export is not claimed from this PR run.

- Four unit shards:3,076 tests,487,614 assertions, zero failed. Corrected shard1
  restores761 tests/301,989 assertions and has no guard-field/bounds script error.
- All37 discovered network smokes ran once and passed. The peer-death negative
  control intentionally records the killed child; it matches its baseline.
- Earned aim CI explicitly reports19 windup,8 HUD,5 eight-tick/idempotence,
  and8 natural-guard checks, each with `failures=[]` and a clean complete
  error scan. No naturally invalid world commit is inferred from these fixtures.
- Solo fence held after all its required jobs. Seven release-reference helper
  tests and required gameplay, region, build and owner-regression jobs passed.

Native-error review compared every completed job against all27 executed raw logs
from main4830. No new distinct native/script error class remains attributable to
this change. Existing material-null, deliberate validation-negative, node-cache
teardown and shutdown-resource diagnostics remain recorded. PR94's distinct
unauthorized `recv_nodes` despawn condition is absent here.

Three-resource shutdown counts in the evidence shard occur after authored-camps
and post-modal assertions; this error already existed in that job on PR92
(`102333955278`), including post-modal at04:18:30.8620083Z. Gate B's eight
ObjectDB/four-resource and Water Alpha's nine/four shutdown signatures also
predate this patch in the same PR92 smokes; see
`CI-PR95-GATE-B-LEAK-COMPARISON.md`. Immediate-main counts differ, so this is
not a claim of identical output or a leak fix. All comparisons use retained
first runs; no rerun was used for clearance.

The failed/superseded first head548 run remains in `CI-PR95-548da7a3d.md`.
The changed fixture and new full CI are a source correction, not a retry pass.
Independent production/evidence review is `AIM-SHIPPING-REVIEW-0909.md`.
This clears the bounded aim branch for exact-head landing; main CI/release,
continuous campaign, visual and Beta acceptance remain separate.
