# Card C3 — Cloudreach co-op and aftermath (two real peers)

Scenario: `tools/net/proof_scenarios/c3_cloudreach_coop_aftermath.json`, run with
`tools/net/run_two_peer_proof.sh` (loopback ENet, headless). `run-8/PROOF.md` is the verdict:
**PASS**, exit 0: 99 steps pass and 2 negative controls fail as designed. Large save and log files
are gzipped.

What it shows:
- **Flight.** Both peers deploy an owned galecrest carrier from the Sky Shrine pad using production double-jump input. The host holds descend and lands on the floor. The guest's link drops mid-flight. It rejoins from the title's returning route as the same character and stands grounded (not flying, not carried), with the same five owned UIDs.
- **Realm boundary.** Both cross Cloudreach → Stormwood. The host process is killed, restarted, and reloads from the title. The guest rejoins. The world hash equals the pre-restart hash. A negative control (compared against the Cloudreach arrival hash) fails, as it should.
- **Identity.** The guest's five owned UIDs match after the drop and after the restart (steps 55 and 81, exact `uids1`). The host's five before (step 34) and after its restart (step 74) are the same list, in the same order.
- **Persistence, with no duplication.** `captain_veyra_defeated`, `sky_shrine_reached`, `cloudreach_winds_restored`, `realm_heart_cloudreach_earned` and `realm_key_stormwood` are world flags (entitlements). Both peers read them from the host world before and after the reload, and they are in the saved `slot-0/world.json`. The world hash is unchanged across the restart and rejoin. A negative "lacks Veyra" check fails, as it should.
- **No legendary.** Both party sizes stay 5, and neither saved character contains `solmane`. The summit wild tables no longer list a legendary (ruling (a); strict `test_cloudreach_no_legendary_offer`).

Fixtures (disclosed):
- `story_flag` world flags stand in for the completed chapter; the earned play is card C1.
- `heart_earn` goes through the ledger.
- `party_grant` gives four L30 creatures per peer.
- `fly_setup` adds an owned galecrest (the loaner ends at chapter completion).
- Each trainer is teleported to the shrine pad before the carrier setup.

Runs 1–7 (not kept) found the harness issues fixed in the scenario: no carrier headroom at arrival, the rejoin needing the returning route, host UIDs remembered in process memory, and the launch-search anchor.
