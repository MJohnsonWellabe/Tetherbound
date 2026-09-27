# Two-peer proof: F14: each freeing-fight participant refuses their own Guardian offer, at capacity and with room

**Verdict: PASS** (exit 0)

Scenario: `tools/net/proof_scenarios/f14_guardian_refuse_real_fight.json`  
Run: `net-20260926T203043Z-2415`  
Rendered: no (headless)

ACCEPTANCE F14 clause 'Each actual freeing-fight participant's capacity/space accept/refuse decision grants at most their own once-only creature, never an owned sixth' -- the REFUSE half (the accept half is f14_guardian_offer_capacity_space.json). The host challenges Captain Nerissa in the Veilfall through the production trainer battle and the guest joins that fight in progress (a guest-run trainer fight is local to the guest and is not offered to others); the host fights her team down, recording both players as participants itself. The guest, at a full belt, refuses at the chamber's own two-press 'Decline the Deep Watcher'; the host, with room, refuses with the Creatures tab's Decline then Confirm decline, with controller presses only. Neither gains a Guardian, both keep their parties unchanged, the host settles both refusals, and each repeat request is refused by the host (already_resolved). Setup only: the Veilfall prerequisites before Nerissa (the dock controls, intake pump and return sluice) are committed through the ledger; companions are granted by name; win_trainer_battle keeps the fighting creature topped up between swings and caps each opponent's HP at 20 (enemy_hp_ceiling, the boss smokes' own allowance: wiring, not balance), so every creature of Nerissa's team is still met and struck down in order. Not covered here: a disconnect at the claim (f14_guardian_offer_capacity_space_drop.json, blocked by the lost-focus defect).

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/33061 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:33061 as peer 1013888353 after 6 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 0 | party_grant — setup: companions by name | PASS | PASS | 'terrapup' at level 3 joined the party (1 member(s)) |
| 5 | 0 | party_grant — setup: the host has room (two of five) | PASS | PASS | 'mosshell' at level 3 joined the party (2 member(s)) |
| 6 | 1 | party_grant | PASS | PASS | 'ripplet' at level 3 joined the party (1 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 3 joined the party (2 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 3 joined the party (3 member(s)) |
| 9 | 1 | party_grant | PASS | PASS | 'sparkit' at level 3 joined the party (4 member(s)) |
| 10 | 1 | party_grant | PASS | PASS | 'meadowhart' at level 3 joined the party (5 member(s)) |
| 11 | 1 | guardian_state — setup: the guest's belt is full (five) | PASS + {"guardians_owned":0.0,"party_size":5.0} | PASS | {"character_id":"character-658bd26120bb4bdfa83bf5f56bfe279c","claim_id":"9ba968c09481e73fe0a1c32d033e1d8e2ed1f163c6a9877be34f937d2dbbd4e4","guardian_freed":false,"guardians_owned":0,"offered":false,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":0} |
| 12 | 0 | deploy_creature — each player sends a companion out | PASS | PASS | deployed AllyCreature |
| 12 | 1 | deploy_creature — each player sends a companion out | PASS | PASS | deployed AllyCreature |
| 13 | 0 | guardian_fixture — setup: the Veilfall chain up to Nerissa (her fight itself is played next) | PASS | PASS | Veilfall prerequisites committed ["water_dock_sluice_isle_both_controls_disabled", "water_veilfall_intake_stopped", "water_veilfall_return_opened"]; Nerissa left to be fought |
| 14 | 0 | wait_flag | PASS | PASS | flag water_veilfall_return_opened (world) set after 0 frames |
| 14 | 1 | wait_flag | PASS | PASS | flag water_veilfall_return_opened (world) set after 0 frames |
| 15 | 0 | nerissa_challenge — the HOST challenges Captain Nerissa in the Veilfall (production begin_trainer_battle; a host-run fight is joinable) | PASS | PASS | prerequisites committed []; challenged Nerissa (defeat flag 'water_captain_nerissa_defeated') with multi_peer=true; 3 creatures to come |
| 16 | 1 | join_running_fight — the guest walks up and joins the host's fight in progress (production join_encounter) | PASS | PASS | joined 1:1 beside 'water_cannonback' at (1804.0, 4226.0) |
| 17 | 0 | win_trainer_battle — the host fights Nerissa's team down through host-arbitrated strikes | PASS | PASS | battle won in 1898 frames / 31 swings against 4 of their creatures |
| 18 | 0 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 18 | 1 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 19 | 0 | guardian_state — the host journals exactly the players who FOUGHT as freeing-fight participants | PASS + {"participants":["character-31e19e5bdf890d379ca29055e3555ed2","character-658bd26120bb4bdfa83bf5f56bfe279c"]} | PASS | {"character_id":"character-31e19e5bdf890d379ca29055e3555ed2","claim_id":"84f7b773d124c887ef94ce26b19e4ea69c83758f8e642cbe848c9d2bc225c345","guardian_freed":false,"guardians_owned":0,"host_open_claims":[],"host_settled":false,"offered":false,"participants":["character-31e19e5bdf890d379ca29055e3555ed2","character-658bd26120bb4bdfa83bf5f56bfe279c"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":2} |
| 20 | 1 | veilfall_press — the guest frees the Guardian at the chamber's real control | PASS | PASS | pressed 'Release the Abyssal Guardian' standing at (0.0, -1.2, -1.6); 'water_guardian_freed' set |
| 21 | 0 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 21 | 1 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 22 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 22 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 23 | 1 | veilfall_press — AT CAPACITY, REFUSE: the guest presses the chamber's 'Decline the Deep Watcher' (first press only arms it) | PASS | PASS | pressed 'Decline the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 24 | 1 | veilfall_press — ... and confirms inside the window | PASS | PASS | pressed 'Confirm: decline the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 25 | 1 | guardian_state — the guest's refusal: no Guardian, the same five | PASS + {"guardians_owned":0.0,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"pending_guardian_id":""} | PASS | {"character_id":"character-658bd26120bb4bdfa83bf5f56bfe279c","claim_id":"9ba968c09481e73fe0a1c32d033e1d8e2ed1f163c6a9877be34f937d2dbbd4e4","guardian_freed":true,"guardians_owned":0,"offered":true,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":5} |
| 26 | 0 | veilfall_press — the host asks for its own offer | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 27 | 0 | guardian_answer — WITH ROOM, REFUSE: the host's Decline, then Confirm decline, on the Creatures tab | PASS + {"decline_settled":true,"stage":"guardian"} | PASS | declined on the tab: host settled the refusal=true; party ["Acorn", "Shelby"] -> ["Acorn", "Shelby"]; Guardians owned 0 |
| 28 | 1 | guardian_offer_again — once only: the guest's repeat request is refused by the host | PASS + {"refused":true} | PASS | asked the host again: ok=false pending=true code='' message 'You have already answered the Guardian's offer in this world.'; Guardians owned 0 -> 0 |
| 29 | 0 | guardian_offer_again — once only: the host's repeat request is refused | PASS + {"code":"already_resolved","refused":true} | PASS | asked the host again: ok=false pending=false code='already_resolved' message ''; Guardians owned 0 -> 0 |
| 30 | 1 | guardian_state — guest: no Guardian, the same five, nothing pending | PASS + {"guardians_owned":0.0,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"pending_guardian_id":"","saved_guardians":0.0} | PASS | {"character_id":"character-658bd26120bb4bdfa83bf5f56bfe279c","claim_id":"9ba968c09481e73fe0a1c32d033e1d8e2ed1f163c6a9877be34f937d2dbbd4e4","guardian_freed":true,"guardians_owned":0,"offered":true,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":5} |
| 31 | 0 | guardian_state — host: no Guardian, no claim left open, the world settled by the first resolution | PASS + {"guardians_owned":0.0,"host_open_claims":[],"host_settled":true,"party":["Acorn","Shelby"],"saved_guardians":0.0} | PASS | {"character_id":"character-31e19e5bdf890d379ca29055e3555ed2","claim_id":"84f7b773d124c887ef94ce26b19e4ea69c83758f8e642cbe848c9d2bc225c345","guardian_freed":true,"guardians_owned":0,"host_open_claims":[],"host_settled":true,"offered":true,"participants":["character-31e19e5bdf890d379ca29055e3555ed2","character-658bd26120bb4bdfa83bf5f56bfe279c"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":2} |
| 32 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 32 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 33 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-31e19e5bdf890d379ca29055e3555ed2' on disk=true; copied 3 files to ralph/reports/INVITE-COOP/x05-proof-f14-refuse-real-fight/peer-0/after |
| 33 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-658bd26120bb4bdfa83bf5f56bfe279c' on disk=true; copied 1 files to ralph/reports/INVITE-COOP/x05-proof-f14-refuse-real-fight/peer-1/after |
| 34 | 1 | check_saved — guest's saved character: its five, no Guardian | PASS | PASS | missing []; unexpectedly present []; read ["character-658bd26120bb4bdfa83bf5f56bfe279c/character.json"] under after/characters |
| 35 | 0 | check_saved — host's saved character: its two, no Guardian | PASS | PASS | missing []; unexpectedly present []; read ["character-31e19e5bdf890d379ca29055e3555ed2/character.json"] under after/characters |

## Captured files

- `peer-0/after/characters/character-31e19e5bdf890d379ca29055e3555ed2/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-1/after/characters/character-658bd26120bb4bdfa83bf5f56bfe279c/character.json`

---
X05 note: run via render.yml run 36269215510 (headless, `tools/net/proof_via_render.gd`) at 4f5bf2cde43b33948ee6e353958715db2ae8539a; loopback ENet, not internet or Steam evidence. `SCRIPT ERROR` count 0 in both peer logs. Captured saves and character files are gzipped here to keep the evidence small (`.json.gz`); the checks in rows 34–35 read them uncompressed on the runner.
