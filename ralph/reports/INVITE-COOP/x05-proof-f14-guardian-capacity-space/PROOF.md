# Two-peer proof: F14: each freeing-fight participant's own Guardian offer, at capacity and with room

**Verdict: PASS** (exit 0)

Scenario: `/home/user/x05-ledger/tools/net/proof_scenarios/f14_guardian_offer_capacity_space.json`  
Run: `net-20260925T201603Z-18036`  
Rendered: yes

ACCEPTANCE F14 clause 'Each actual freeing-fight participant's capacity/space accept/refuse decision grants at most their own once-only creature, never an owned sixth' (the disconnect half is f14_guardian_offer_capacity_space_drop.json). Two participants: the guest at a full belt and the host with room. The guest frees the Guardian at the chamber's real control; each asks at the chamber's real prompt and answers on the Creatures tab the game opens, with controller presses only: the guest lets Rill go for the Guardian, the host accepts into its free holder. Each ends with exactly one Guardian, never a sixth, a saved receipt, no claim left open and no second invitation. Setup only: the Veilfall prerequisites and Nerissa's defeat are committed through the ledger, the participants being recorded by the encounter director's own session path (standing in for playing the Veilfall and the fight); companions are granted by name (the water scene boots with an empty belt). Not covered here: an explicit refusal.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/34441 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:34441 as peer 1652317869 after 14 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 4 | 0 | party_grant — setup: companions by name | PASS | PASS | 'terrapup' at level 3 joined the party (1 member(s)) |
| 5 | 0 | party_grant — setup: the host has room (two of five) | PASS | PASS | 'mosshell' at level 3 joined the party (2 member(s)) |
| 6 | 1 | party_grant — setup: companions by name | PASS | PASS | 'ripplet' at level 3 joined the party (1 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 3 joined the party (2 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 3 joined the party (3 member(s)) |
| 9 | 1 | party_grant | PASS | PASS | 'sparkit' at level 3 joined the party (4 member(s)) |
| 10 | 1 | party_grant | PASS | PASS | 'meadowhart' at level 3 joined the party (5 member(s)) |
| 11 | 1 | guardian_state — setup: the guest's belt is full (five) | PASS + {"guardians_owned":0.0,"party_size":5.0} | PASS | {"character_id":"character-7fdb471da30124031b98198750b9e227","claim_id":"242f355ced020883ccd05c2dc35bd22852b05e4bd48aa0f6260be083b56e8e2a","guardian_freed":false,"guardians_owned":0,"offered":false,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":0} |
| 12 | 0 | guardian_fixture — setup: both fought Nerissa (the director's own session path journals one reward row each) | PASS | PASS | prerequisites committed ["water_dock_sluice_isle_both_controls_disabled", "water_veilfall_intake_stopped", "water_veilfall_return_opened"]; Nerissa fought by peers [1, 1652317869]; session path handled=true; 'water_captain_nerissa_defeated' set=true; participant characters ["character-8e161177d6e8e4871ca310bf93516e44", "character-7fdb471da30124031b98198750b9e227"] |
| 13 | 0 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 13 | 1 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 14 | 1 | veilfall_press — the GUEST frees the Guardian at the chamber's real control | PASS | PASS | pressed 'Release the Abyssal Guardian' standing at (0.0, -1.2, -1.6) |
| 15 | 0 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 15 | 1 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 16 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-0/00_guardian_freed.png |
| 16 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-1/00_guardian_freed.png |
| 17 | 0 | guardian_state — the host journals both characters as freeing-fight participants | PASS + {"guardian_freed":true,"participants":["character-8e161177d6e8e4871ca310bf93516e44","character-7fdb471da30124031b98198750b9e227"]} | PASS | {"character_id":"character-8e161177d6e8e4871ca310bf93516e44","claim_id":"a75c44b627f7334a98ff90bfc31652ce15f78ef0438d3aa20884ca1f291e8457","guardian_freed":true,"guardians_owned":0,"host_open_claims":[],"host_settled":false,"offered":false,"participants":["character-8e161177d6e8e4871ca310bf93516e44","character-7fdb471da30124031b98198750b9e227"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":2} |
| 18 | 1 | veilfall_press — the guest asks for its own offer at the chamber | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 19 | 1 | guardian_answer — AT CAPACITY: the ceremony opens with the Guardian as the sixth row; the guest lets Rill go and the Guardian takes the holder | PASS + {"stage":"choose"} | PASS | answered let Rill go: party ["Kestrel", "Bramble", "Rill", "Tuff", "Fern"] -> ["Kestrel", "Bramble", "Abyssal Guardian", "Tuff", "Fern"]; Guardians owned 1; receipt on the saved character=true |
| 20 | 0 | veilfall_press — the host asks for its own offer | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 21 | 0 | guardian_answer — WITH ROOM: the host's own Accept/Decline; Accept | PASS + {"stage":"guardian"} | PASS | answered Accept: party ["Acorn", "Shelby"] -> ["Acorn", "Shelby", "Abyssal Guardian"]; Guardians owned 1; receipt on the saved character=true |
| 22 | 1 | veilfall_press — once only: the chamber no longer offers the guest an invitation | FAIL | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 23 | 0 | veilfall_press — once only: nor the host | FAIL | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 24 | 1 | guardian_state — guest: exactly one Guardian, five owned, Rill gone, receipt saved | PASS + {"guardians_owned":1.0,"party_size":5.0,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1.0,"saved_party_size":5.0} | PASS | {"character_id":"character-7fdb471da30124031b98198750b9e227","claim_id":"242f355ced020883ccd05c2dc35bd22852b05e4bd48aa0f6260be083b56e8e2a","guardian_freed":true,"guardians_owned":1,"offered":true,"party":["Kestrel","Bramble","Abyssal Guardian","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1,"saved_party_size":5} |
| 25 | 0 | guardian_state — host: exactly one Guardian, receipt saved, no claim left open, settled | PASS + {"guardians_owned":1.0,"host_open_claims":[],"host_settled":true,"party_size":3.0,"receipt_saved":true,"saved_guardians":1.0} | PASS | {"character_id":"character-8e161177d6e8e4871ca310bf93516e44","claim_id":"a75c44b627f7334a98ff90bfc31652ce15f78ef0438d3aa20884ca1f291e8457","guardian_freed":true,"guardians_owned":1,"host_open_claims":[],"host_settled":true,"offered":true,"participants":["character-8e161177d6e8e4871ca310bf93516e44","character-7fdb471da30124031b98198750b9e227"],"party":["Acorn","Shelby","Abyssal Guardian"],"party_size":3,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1,"saved_party_size":3} |
| 26 | 0 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-0/03_after.png |
| 26 | 1 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-1/03_after.png |
| 27 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-8e161177d6e8e4871ca310bf93516e44' on disk=true; copied 3 files to ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-0/after |
| 27 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-7fdb471da30124031b98198750b9e227' on disk=true; copied 1 files to ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-1/after |
| 28 | 1 | check_saved — guest's saved character | PASS | PASS | missing []; unexpectedly present []; read ["character-7fdb471da30124031b98198750b9e227/character.json"] under after/characters |
| 29 | 0 | check_saved — host's saved character | PASS | PASS | missing []; unexpectedly present []; read ["character-8e161177d6e8e4871ca310bf93516e44/character.json"] under after/characters |

## Captured files

- `peer-0/00_guardian_freed.png`
- `peer-0/02_host_offer_with_room.png`
- `peer-0/03_after.png`
- `peer-0/after/characters/character-8e161177d6e8e4871ca310bf93516e44/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-1/00_guardian_freed.png`
- `peer-1/01_guest_offer_at_capacity.png`
- `peer-1/01_guest_offer_at_capacity_done.png`
- `peer-1/03_after.png`
- `peer-1/after/characters/character-7fdb471da30124031b98198750b9e227/character.json`
