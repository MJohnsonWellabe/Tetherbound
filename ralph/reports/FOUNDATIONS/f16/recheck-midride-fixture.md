# Independent bounded CI repair review

Reviewer: combat, read-only source/parsed-fixture inspection, 2026-09-30.
Result: PASS for the adaptation; runtime CI remains required on the same PR.

Exact diff only adds the named `cloudreach_midride_rejoin` allowlist member and prepends the all-peer existing debug-only `legacy_physical_crossings` hook. Every original parsed JSON step remains identical after removing the new first step; the old claim is retained verbatim followed by explicit RD-35 fixture disclosure. No gameplay/default/schema changes, earned-proof restamp or assertion removal. This restores the retired crossing fixture scope only; no new F19/F49 acceptance.

The retained actual failure is `ci-cloudreach-midride-initial.txt`. CI run 36663610989 reached authored setup and refused the old realm-key entry, as the new shipping default requires. No duplicate local two-peer replay is selected under RD-37; the already selected full-CI job must validate its unchanged complete riding/rejoin assertions.
