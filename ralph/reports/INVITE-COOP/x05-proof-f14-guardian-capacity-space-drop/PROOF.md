# Two-peer proof: F14: each freeing-fight participant's own Guardian offer, at capacity and with room, across a drop at the claim

**Verdict: FAIL** (exit 1)

Scenario: `/home/user/x05-ledger/tools/net/proof_scenarios/f14_guardian_offer_capacity_space_drop.json`  
Run: `net-20260925T203340Z-23427`  
Rendered: yes

ACCEPTANCE F14 clause 'Each actual freeing-fight participant's capacity/space accept/refuse decision grants at most their own once-only creature, never an owned sixth; disconnect/reload cannot duplicate or erase it.' Two participants: the guest at a full belt and the host with room. The guest frees the Guardian at the chamber's real control; each asks at the chamber's real prompt and answers on the Creatures tab the game opens, with controller presses only. The guest's link dies while its at-capacity offer is on screen, unanswered; it returns as the same character by the production returning route, finds nothing granted, and then lets Rill go for the Guardian. The host accepts into its free holder. Each ends with exactly one Guardian, never a sixth, a saved receipt, the invite prompt no longer offered, and a repeat request refused by the host (already_resolved). Setup only: the Veilfall prerequisites and Nerissa's defeat are committed through the ledger, the fight's participant roster is injected into the encounter director and its payout then runs through the director's own session path (standing in for playing the Veilfall and the fight), companions are granted by name (the water scene boots with an empty belt). Not covered here: an explicit refusal (with room or at capacity), a non-participant being refused, and a drop between the saved receipt and the host's acknowledgement.

## Failures

- #29 peer 1 guardian_answer (AT CAPACITY: the guest lets Rill go and the Guardian takes the holder) -> FAIL -- could not bring focus to Rill's row (after the presses focus is on nothing, menu open=true, stage 'choose'; when presented: tab visible=true, focus '')
- #34 peer 1 guardian_offer_again (once only, judged by the host: the guest's repeat request (the intent the prompt sends) is refused already_resolved) -> FAIL; data did not match {"refused":true} -- asked the host again: ok=false pending=true code='' message ''; Guardians owned 0 -> 0
- #36 peer 1 guardian_state (guest: exactly one Guardian in Rill's holder, the other four kept, receipt saved) -> PASS; data did not match {"guardians_owned":1.0,"party":["Kestrel","Bramble","Abyssal Guardian","Tuff","Fern"],"party_size":5.0,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1.0,"saved_party_size":5.0} -- {"character_id":"character-8df730d39bd82d06d613d31317867fde","claim_id":"4741d3ac08fafe4920f25574d4bd27720475bcad1d490372d6c34838be97d0e0","guardian_freed":true,"guardians_owned":0,"offered":true,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"4741d3ac08fafe4
- #37 peer 0 guardian_state (host: exactly one Guardian, receipt saved, no claim left open, settled) -> PASS; data did not match {"guardians_owned":1.0,"host_open_claims":[],"host_settled":true,"party":["Acorn","Shelby","Abyssal Guardian"],"party_size":3.0,"receipt_saved":true,"saved_guardians":1.0} -- {"character_id":"character-d5282d9f2b7ebf43d4596caa52edfc43","claim_id":"09aa0c6b49fcdd1976ee77082fb7b7c677aa89b3e64068066b058a109adfc5d2","guardian_freed":true,"guardians_owned":1,"host_open_claims":["4741d3ac08fafe4920f25574d4bd27720475bcad1d490372d6c34838be97d0e0"],"host_settled":true,"offered":t
- #40 peer 1 check_saved (guest's saved character) -> FAIL -- missing ["water_abyssal_guardian"]; unexpectedly present ["Rill"]; read ["character-8df730d39bd82d06d613d31317867fde/character.json"] under after/characters

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/33801 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:33801 as peer 1388059693 after 16 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 4 | 0 | party_grant — setup: companions by name | PASS | PASS | 'terrapup' at level 3 joined the party (1 member(s)) |
| 5 | 0 | party_grant — setup: the host has room (two of five) | PASS | PASS | 'mosshell' at level 3 joined the party (2 member(s)) |
| 6 | 1 | party_grant — setup: companions by name | PASS | PASS | 'ripplet' at level 3 joined the party (1 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 3 joined the party (2 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 3 joined the party (3 member(s)) |
| 9 | 1 | party_grant | PASS | PASS | 'sparkit' at level 3 joined the party (4 member(s)) |
| 10 | 1 | party_grant | PASS | PASS | 'meadowhart' at level 3 joined the party (5 member(s)) |
| 11 | 1 | guardian_state — setup: the guest's belt is full (five) | PASS + {"guardians_owned":0.0,"party_size":5.0} | PASS | {"character_id":"character-8df730d39bd82d06d613d31317867fde","claim_id":"4741d3ac08fafe4920f25574d4bd27720475bcad1d490372d6c34838be97d0e0","guardian_freed":false,"guardians_owned":0,"offered":false,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":0} |
| 12 | 0 | guardian_fixture — setup: both fought Nerissa (the director's own session path journals one reward row each) | PASS | PASS | prerequisites committed ["water_dock_sluice_isle_both_controls_disabled", "water_veilfall_intake_stopped", "water_veilfall_return_opened"]; Nerissa fought by peers [1, 1388059693]; session path handled=true; 'water_captain_nerissa_defeated' set=true; participant characters ["character-d5282d9f2b7ebf43d4596caa52edfc43", "character-8df730d39bd82d06d613d31317867fde"] |
| 13 | 0 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 13 | 1 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 14 | 1 | veilfall_press — the GUEST frees the Guardian at the chamber's real control | PASS | PASS | pressed 'Release the Abyssal Guardian' standing at (0.0, -1.2, -1.6); 'water_guardian_freed' set |
| 15 | 0 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 15 | 1 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 16 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space-drop/peer-0/00_guardian_freed.png |
| 16 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space-drop/peer-1/00_guardian_freed.png |
| 17 | 0 | guardian_state — the host journals both characters as freeing-fight participants | PASS + {"guardian_freed":true,"participants":["character-d5282d9f2b7ebf43d4596caa52edfc43","character-8df730d39bd82d06d613d31317867fde"]} | PASS | {"character_id":"character-d5282d9f2b7ebf43d4596caa52edfc43","claim_id":"09aa0c6b49fcdd1976ee77082fb7b7c677aa89b3e64068066b058a109adfc5d2","guardian_freed":true,"guardians_owned":0,"host_open_claims":[],"host_settled":false,"offered":false,"participants":["character-d5282d9f2b7ebf43d4596caa52edfc43","character-8df730d39bd82d06d613d31317867fde"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":2} |
| 18 | 1 | veilfall_press — the guest asks for its own offer at the chamber | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 19 | 1 | guardian_answer — AT CAPACITY: the ceremony opens with the Guardian as the sixth row, unanswered | PASS + {"pending_species":"water_abyssal_guardian","stage":"choose"} | PASS | offer on screen at stage 'choose' for party ["Kestrel", "Bramble", "Rill", "Tuff", "Fern"] (tab visible=true, focus '@HBoxContainer@2417/@VBoxContainer@2418/@MarginContainer@2504/@Button@2491') |
| 20 | 1 | save_character_here — the guest's character is written with the offer still unanswered | PASS | PASS | character 'character-8df730d39bd82d06d613d31317867fde' is on disk (wrote_world=false) |
| 21 | 1 | drop_link — DROP at the claim: the link dies before the guest answers | PASS | PASS | transport closed without a Session.leave() |
| 22 | 0 | expect_peers | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 23 | 0 | guardian_state — the host still holds the guest's claim; nobody has a Guardian | PASS + {"guardians_owned":0.0,"host_settled":false} | PASS | {"character_id":"character-d5282d9f2b7ebf43d4596caa52edfc43","claim_id":"09aa0c6b49fcdd1976ee77082fb7b7c677aa89b3e64068066b058a109adfc5d2","guardian_freed":true,"guardians_owned":0,"host_open_claims":["4741d3ac08fafe4920f25574d4bd27720475bcad1d490372d6c34838be97d0e0"],"host_settled":false,"offered":false,"participants":["character-d5282d9f2b7ebf43d4596caa52edfc43","character-8df730d39bd82d06d613d31317867fde"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":2} |
| 24 | 1 | leave — tear down whatever is left | any | FAIL | no active session to leave |
| 25 | 1 | wipe_character — the live character is blanked: what returns comes from the save | PASS | PASS | in-memory character blanked (party 5 -> 0), id 'character-8df730d39bd82d06d613d31317867fde' kept, file untouched |
| 26 | 1 | production_join — the same character comes back | PASS | PASS | title returning entry built 'WaterArchipelago' first, then JoinDriver joined 127.0.0.1:33801 as peer 997053275 after 52 frames |
| 27 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 27 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 28 | 1 | guardian_state — after the drop: still five, no Guardian, nothing granted -- and the host has already re-sent the same claim to the same character | PASS + {"character_id":"character-8df730d39bd82d06d613d31317867fde","guardians_owned":0.0,"party_size":5.0,"saved_guardians":0.0} | PASS | {"character_id":"character-8df730d39bd82d06d613d31317867fde","claim_id":"4741d3ac08fafe4920f25574d4bd27720475bcad1d490372d6c34838be97d0e0","guardian_freed":true,"guardians_owned":0,"offered":true,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"4741d3ac08fafe4920f25574d4bd27720475bcad1d490372d6c34838be97d0e0","receipt_saved":false,"saved_guardians":0,"saved_party_size":5} |
| 29 | 1 | guardian_answer — AT CAPACITY: the guest lets Rill go and the Guardian takes the holder | PASS + {"stage":"choose"} | FAIL **(unexpected)** | could not bring focus to Rill's row (after the presses focus is on nothing, menu open=true, stage 'choose'; when presented: tab visible=true, focus '') |
| 30 | 0 | veilfall_press — the host asks for its own offer | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 31 | 0 | guardian_answer — WITH ROOM: the host's own Accept/Decline; Accept | PASS + {"stage":"guardian"} | PASS | answered Accept: party ["Acorn", "Shelby"] -> ["Acorn", "Shelby", "Abyssal Guardian"]; Guardians owned 1; receipt on the saved character=true |
| 32 | 1 | veilfall_press — once only: the chamber no longer offers the guest its invite prompt | FAIL + {"enabled":false} | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 33 | 0 | veilfall_press — once only: nor the host its invite prompt | FAIL + {"enabled":false} | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 34 | 1 | guardian_offer_again — once only, judged by the host: the guest's repeat request (the intent the prompt sends) is refused already_resolved | PASS + {"refused":true} | FAIL **(unexpected)** | asked the host again: ok=false pending=true code='' message ''; Guardians owned 0 -> 0 |
| 35 | 0 | guardian_offer_again — once only, judged by the host: the host's own repeat request is refused already_resolved | PASS + {"code":"already_resolved","refused":true} | PASS | asked the host again: ok=false pending=false code='already_resolved' message ''; Guardians owned 1 -> 1 |
| 36 | 1 | guardian_state — guest: exactly one Guardian in Rill's holder, the other four kept, receipt saved | PASS + {"guardians_owned":1.0,"party":["Kestrel","Bramble","Abyssal Guardian","Tuff","Fern"],"party_size":5.0,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1.0,"saved_party_size":5.0} | PASS **(unexpected)** | {"character_id":"character-8df730d39bd82d06d613d31317867fde","claim_id":"4741d3ac08fafe4920f25574d4bd27720475bcad1d490372d6c34838be97d0e0","guardian_freed":true,"guardians_owned":0,"offered":true,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"4741d3ac08fafe4920f25574d4bd27720475bcad1d490372d6c34838be97d0e0","receipt_saved":false,"saved_guardians":0,"saved_party_size":5} |
| 37 | 0 | guardian_state — host: exactly one Guardian, receipt saved, no claim left open, settled | PASS + {"guardians_owned":1.0,"host_open_claims":[],"host_settled":true,"party":["Acorn","Shelby","Abyssal Guardian"],"party_size":3.0,"receipt_saved":true,"saved_guardians":1.0} | PASS **(unexpected)** | {"character_id":"character-d5282d9f2b7ebf43d4596caa52edfc43","claim_id":"09aa0c6b49fcdd1976ee77082fb7b7c677aa89b3e64068066b058a109adfc5d2","guardian_freed":true,"guardians_owned":1,"host_open_claims":["4741d3ac08fafe4920f25574d4bd27720475bcad1d490372d6c34838be97d0e0"],"host_settled":true,"offered":true,"participants":["character-d5282d9f2b7ebf43d4596caa52edfc43","character-8df730d39bd82d06d613d31317867fde"],"party":["Acorn","Shelby","Abyssal Guardian"],"party_size":3,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1,"saved_party_size":3} |
| 38 | 0 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space-drop/peer-0/04_after.png |
| 38 | 1 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space-drop/peer-1/04_after.png |
| 39 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-d5282d9f2b7ebf43d4596caa52edfc43' on disk=true; copied 3 files to ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space-drop/peer-0/after |
| 39 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-8df730d39bd82d06d613d31317867fde' on disk=true; copied 1 files to ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space-drop/peer-1/after |
| 40 | 1 | check_saved — guest's saved character | PASS | FAIL **(unexpected)** | missing ["water_abyssal_guardian"]; unexpectedly present ["Rill"]; read ["character-8df730d39bd82d06d613d31317867fde/character.json"] under after/characters |
| 41 | 0 | check_saved — host's saved character | PASS | PASS | missing []; unexpectedly present []; read ["character-d5282d9f2b7ebf43d4596caa52edfc43/character.json"] under after/characters |

## Captured files

- `peer-0/00_guardian_freed.png`
- `peer-0/03_host_offer_with_room.png`
- `peer-0/04_after.png`
- `peer-0/after/characters/character-d5282d9f2b7ebf43d4596caa52edfc43/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-1/00_guardian_freed.png`
- `peer-1/01_guest_offer_at_capacity.png`
- `peer-1/02_guest_lets_rill_go.png`
- `peer-1/04_after.png`
- `peer-1/after/characters/character-8df730d39bd82d06d613d31317867fde/character.json`
