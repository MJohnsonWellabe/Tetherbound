# F43 regression after the bounty_rotate grace (b28d1c0a0) — PASS

systems-b, Sun 11 Oct 2026, 4:32–4:47 PM CT, at 60f745a18 (bounty code identical to b28d1c0a0).
`tools/net/run_net_smoke.sh f43_bounties` (2 peers, real ENet): 97 PASS, 0 FAIL, ALL CHECKS PASSED (`net_f43_bounties.txt`).
Disclosed: LOCAL scaled slow-host budgets (pre-approved, not committed): hello_budget_s 900, smoke_step_budget_s_2peer 3600, smoke_step_budget_s_wide 7200.
A first attempt inside an `unshare -rn` namespace never reached its steps (no `ip` tool, so loopback stayed down; the client could not reach the run coordinator). That was infrastructure, not a game failure.
Covers: morning rotation for host and guest, personal boards, claim paid once, reconnect/reload replay, and the next morning's rotation after a claim.
