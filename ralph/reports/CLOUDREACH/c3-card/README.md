# Card C3 — Cloudreach co-op and aftermath (Phase 1 integrated run)

ACCEPTANCE §6 C3: "Host and guest cross flight and realm boundaries, disconnect/rejoin and reload without
duplicating relic/key or losing rider/party identity. Veyra, Wings/shrine and restored wind roads persist.
Solmane's freeing happens once per world; each finale participant's accept/refuse persists through
disconnect/reload without duplication, and no wild or catchable Solmane exists (owner, 2026-09-27)."

Feeders (ACCEPTANCE §6.1 F08): F08#0-#2 and F08#5 met on main; F08#3 and F08#4 closed on this branch
(strict re-checks MET). This run is the card's integrated run on the head that carries them.

## The integrated run
`run-1/` — `tools/net/run_two_peer_proof.sh tools/net/proof_scenarios/c3_cloudreach_coop_aftermath.json`
(two real Godot processes, loopback ENet, headless) at `run-1/head.txt`. **Verdict: PASS, exit 0, ALL
CHECKS PASSED**; the five FAIL rows are two `any` steps and three negative controls that fail by design
(the same five as `../b/c3-coop/run-9-solmane/`). It covers:
- **Flight and realm boundaries:** both peers deploy an owned carrier from the Sky Shrine pad by production
  double-jump input; the guest's link drops mid-flight and rejoins grounded as the same character with the same
  five UIDs; both cross Cloudreach → Stormwood.
- **Reload without duplication:** the host process is killed, restarted and reloaded from the title; the guest
  rejoins; the world hash equals the pre-restart hash (negative control against the arrival hash fails as it must).
- **Persistence:** `captain_veyra_defeated`, `sky_shrine_reached`, `cloudreach_winds_restored`,
  `realm_heart_cloudreach_earned` and `realm_key_stormwood` read from the host world before and after, and in the
  saved world.
- **Solmane:** freed once as a world fact; each peer answers its own offer through the real accept/refuse
  handlers; both refuse at five, and the refusal receipts survive the drop/rejoin and the host restart with no
  second offer and no Solmane in either saved character. The accept branch (host accepts at four and keeps
  Solmane as its fifth; guest refuses; no re-offer after rejoin or host reload) is F08#5's two-peer run3
  (`../b/f08-5-solmane/`). Summit wild tables hold tempestwing, so no wild or catchable Solmane exists
  (`test_cloudreach_no_legendary_offer`).

## Disclosed shortcuts
`story_flag` world flags stand in for the completed chapter (the earned play is card C1 and card C2's run-1);
the Solmane freeing is written as a world fact (the lever press is `smoke_cloudreach_solmane_offer_choice`);
`heart_earn` through the ledger; `party_grant` gives each peer four L30 creatures and `fly_setup` an owned
galecrest; teleport to the shrine pad; the receipts' persistence after the restart is read from Stormwood (a
return crossing outran the 15 s heartbeat in run-9); loopback ENet is local evidence, not internet or Steam
acceptance. Output pruned to the proof, summary, net record and gzipped peer logs.
