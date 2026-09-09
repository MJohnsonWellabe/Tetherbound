# PR97 final hosted-settlement shipping candidate

Head `3104aa9cee10e2e5baab15023874dcfd72d889db`, tree
`098a16f9528ee83390df667ab23df7a6eed9e30e`, parents corrected prior head
`5fae4e981ee32bafc9dd4fd657b1067d21576479` and actual main
`77745ef03421a3adceb6282d3e5abb71350e1197`.

The temporary-index construction retains the prior protocol tree and overlays
twelve reviewed paths. Seven hosted files equal frozen shared commit `ea109ee3c`;
the Stormwood hub starts from actual main and adds only the eight-line withdrawal
method. The driver, predicate unit and first-invocation failure receipt equal
`13d6b6977`. CI starts from prior PR97 and changes only the opening retry count
to one and its explanatory comment. No held PR94 implementation, telemetry steps
or held visual candidates are included.

Independent review verified every path, tree and parent identity, exact hub and
CI differences, and clean diff formatting. It found no integration blocker and
approved running CI; it did not approve landing without that evidence.

The branch was fast-forward pushed at approximately15:23 UTC. Exact-head CI
`34369962476` started15:23:48 UTC and is pending. First-head failure452a7d10
and the auto-retried opening failure at5fae4e981 remain recorded separately.

The original287 protected import files were rehashed after these captures and
the push:287 checked, zero mismatches. Candidate construction and its complete
diff/manifest are retained under `.artifacts/realm-hosted-shipping-0909/`.
