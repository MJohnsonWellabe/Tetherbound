F07 #1 -- two-peer (host + guest, distinct characters) witness for Cloudreach activity payoffs.
Command: GODOT_BIN=... tools/net/run_net_smoke.sh cloudreach_activity_payoffs
Files: tests/smoke_net_cloudreach_activity_payoffs.gd (coordinator; fixtures disclosed in its header)
       tests/smoke_net_cloudreach_activity_payoffs_peer.gd (peer = proof peer runner + lane steps)
run1/: 88 PASS, 1 FAIL (fixture: the Observatory "unsurveyed" control ran after the guest had
       stood on the 1020 m High Perches; Cloudreach's grounded-fall recovery carried it back there
       before the landing fired, so the landing counted at High Perches). Fixed by running the
       control first and asserting the landing position (at_marker). No product change.
run2/: 89 PASS, 0 FAIL, exit 0. SCRIPT ERROR count: 0 in both peer logs and the coordinator log.
Loopback ENet on one machine: local evidence, not internet/Steam acceptance.
