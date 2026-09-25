# Two-peer proof: F14: each freeing-fight participant's own Guardian offer, at capacity and with room

**Verdict: PASS** (exit 0)

Scenario: `/home/user/x05-ledger/tools/net/proof_scenarios/f14_guardian_offer_capacity_space.json`  
Run: `net-20260925T203140Z-23003`  
Rendered: yes

ACCEPTANCE F14 clause 'Each actual freeing-fight participant's capacity/space accept/refuse decision grants at most their own once-only creature, never an owned sixth' (the disconnect half is f14_guardian_offer_capacity_space_drop.json). Two participants: the guest at a full belt and the host with room. The guest frees the Guardian at the chamber's real control; each asks at the chamber's real prompt and answers on the Creatures tab the game opens, with controller presses only: the guest lets Rill go for the Guardian, the host accepts into its free holder. Each ends with exactly one Guardian, never a sixth, a saved receipt, no claim left open the invite prompt no longer offered, and a repeat request refused by the host (already_resolved). Setup only: the Veilfall prerequisites and Nerissa's defeat are committed through the ledger, the fight's participant roster is injected into the encounter director and its payout then runs through the director's own session path (standing in for playing the Veilfall and the fight); companions are granted by name (the water scene boots with an empty belt). Not covered here: an explicit refusal (with room or at capacity), a non-participant being refused, and the disconnect/reload half (f14_guardian_offer_capacity_space_drop.json, which currently FAILS on a lost-focus defect).

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/34201 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:34201 as peer 511596416 after 14 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 4 | 0 | party_grant — setup: companions by name | PASS | PASS | 'terrapup' at level 3 joined the party (1 member(s)) |
| 5 | 0 | party_grant — setup: the host has room (two of five) | PASS | PASS | 'mosshell' at level 3 joined the party (2 member(s)) |
| 6 | 1 | party_grant — setup: companions by name | PASS | PASS | 'ripplet' at level 3 joined the party (1 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 3 joined the party (2 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 3 joined the party (3 member(s)) |
| 9 | 1 | party_grant | PASS | PASS | 'sparkit' at level 3 joined the party (4 member(s)) |
| 10 | 1 | party_grant | PASS | PASS | 'meadowhart' at level 3 joined the party (5 member(s)) |
| 11 | 1 | guardian_state — setup: the guest's belt is full (five) | PASS + {"guardians_owned":0.0,"party_size":5.0} | PASS | {"character_id":"character-6dbe4e3e152accf63be055075077fa6f","claim_id":"2ec2cc071c6e7d9cd368e92795cd2d8d2ff66962d4ea2219f940ff7c4748de36","guardian_freed":false,"guardians_owned":0,"offered":false,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":0} |
| 12 | 0 | guardian_fixture — setup: both fought Nerissa (the director's own session path journals one reward row each) | PASS | PASS | prerequisites committed ["water_dock_sluice_isle_both_controls_disabled", "water_veilfall_intake_stopped", "water_veilfall_return_opened"]; Nerissa fought by peers [1, 511596416]; session path handled=true; 'water_captain_nerissa_defeated' set=true; participant characters ["character-32e5f87e4b21b85df290659e16a3bdd1", "character-6dbe4e3e152accf63be055075077fa6f"] |
| 13 | 0 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 13 | 1 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 14 | 1 | veilfall_press — the GUEST frees the Guardian at the chamber's real control | PASS | PASS | pressed 'Release the Abyssal Guardian' standing at (0.0, -1.2, -1.6); 'water_guardian_freed' set |
| 15 | 0 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 15 | 1 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 16 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-0/00_guardian_freed.png |
| 16 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-1/00_guardian_freed.png |
| 17 | 0 | guardian_state — the host journals both characters as freeing-fight participants | PASS + {"guardian_freed":true,"participants":["character-32e5f87e4b21b85df290659e16a3bdd1","character-6dbe4e3e152accf63be055075077fa6f"]} | PASS | {"character_id":"character-32e5f87e4b21b85df290659e16a3bdd1","claim_id":"24da5465a07c2dbf8e96098641a00a7ac13ee6a95ae055e8d1a8b7eabc045f94","guardian_freed":true,"guardians_owned":0,"host_open_claims":[],"host_settled":false,"offered":false,"participants":["character-32e5f87e4b21b85df290659e16a3bdd1","character-6dbe4e3e152accf63be055075077fa6f"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":2} |
| 18 | 1 | veilfall_press — the guest asks for its own offer at the chamber | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 19 | 1 | guardian_answer — AT CAPACITY: the ceremony opens with the Guardian as the sixth row; the guest lets Rill go and the Guardian takes the holder | PASS + {"stage":"choose"} | PASS | answered let Rill go: party ["Kestrel", "Bramble", "Rill", "Tuff", "Fern"] -> ["Kestrel", "Bramble", "Abyssal Guardian", "Tuff", "Fern"]; Guardians owned 1; receipt on the saved character=true |
| 20 | 0 | veilfall_press — the host asks for its own offer | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 21 | 0 | guardian_answer — WITH ROOM: the host's own Accept/Decline; Accept | PASS + {"stage":"guardian"} | PASS | answered Accept: party ["Acorn", "Shelby"] -> ["Acorn", "Shelby", "Abyssal Guardian"]; Guardians owned 1; receipt on the saved character=true |
| 22 | 1 | veilfall_press — once only: the chamber no longer offers the guest its invite prompt | FAIL + {"enabled":false} | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 23 | 0 | veilfall_press — once only: nor the host its invite prompt | FAIL + {"enabled":false} | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 24 | 1 | guardian_offer_again — once only, judged by the host: the guest's repeat request (the intent the prompt sends) is refused already_resolved | PASS + {"refused":true} | PASS | asked the host again: ok=false pending=true code='' message 'You have already answered the Guardian's offer in this world.'; Guardians owned 1 -> 1 |
| 25 | 0 | guardian_offer_again — once only, judged by the host: the host's own repeat request is refused already_resolved | PASS + {"code":"already_resolved","refused":true} | PASS | asked the host again: ok=false pending=false code='already_resolved' message ''; Guardians owned 1 -> 1 |
| 26 | 1 | guardian_state — guest: exactly one Guardian in Rill's holder, the other four kept, receipt saved | PASS + {"guardians_owned":1.0,"party":["Kestrel","Bramble","Abyssal Guardian","Tuff","Fern"],"party_size":5.0,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1.0,"saved_party_size":5.0} | PASS | {"character_id":"character-6dbe4e3e152accf63be055075077fa6f","claim_id":"2ec2cc071c6e7d9cd368e92795cd2d8d2ff66962d4ea2219f940ff7c4748de36","guardian_freed":true,"guardians_owned":1,"offered":true,"party":["Kestrel","Bramble","Abyssal Guardian","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1,"saved_party_size":5} |
| 27 | 0 | guardian_state — host: exactly one Guardian, receipt saved, no claim left open, settled | PASS + {"guardians_owned":1.0,"host_open_claims":[],"host_settled":true,"party":["Acorn","Shelby","Abyssal Guardian"],"party_size":3.0,"receipt_saved":true,"saved_guardians":1.0} | PASS | {"character_id":"character-32e5f87e4b21b85df290659e16a3bdd1","claim_id":"24da5465a07c2dbf8e96098641a00a7ac13ee6a95ae055e8d1a8b7eabc045f94","guardian_freed":true,"guardians_owned":1,"host_open_claims":[],"host_settled":true,"offered":true,"participants":["character-32e5f87e4b21b85df290659e16a3bdd1","character-6dbe4e3e152accf63be055075077fa6f"],"party":["Acorn","Shelby","Abyssal Guardian"],"party_size":3,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1,"saved_party_size":3} |
| 28 | 0 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-0/03_after.png |
| 28 | 1 | screenshot | PASS | PASS | captured 960x540 -> ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-1/03_after.png |
| 29 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-32e5f87e4b21b85df290659e16a3bdd1' on disk=true; copied 3 files to ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-0/after |
| 29 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-6dbe4e3e152accf63be055075077fa6f' on disk=true; copied 1 files to ralph/reports/INVITE-COOP/x05-proof-f14-guardian-capacity-space/peer-1/after |
| 30 | 1 | check_saved — guest's saved character | PASS | PASS | missing []; unexpectedly present []; read ["character-6dbe4e3e152accf63be055075077fa6f/character.json"] under after/characters |
| 31 | 0 | check_saved — host's saved character | PASS | PASS | missing []; unexpectedly present []; read ["character-32e5f87e4b21b85df290659e16a3bdd1/character.json"] under after/characters |

## Captured files

- `peer-0/00_guardian_freed.png`
- `peer-0/02_host_offer_with_room.png`
- `peer-0/03_after.png`
- `peer-0/after/characters/character-32e5f87e4b21b85df290659e16a3bdd1/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-1/00_guardian_freed.png`
- `peer-1/01_guest_offer_at_capacity.png`
- `peer-1/01_guest_offer_at_capacity_done.png`
- `peer-1/03_after.png`
- `peer-1/after/characters/character-6dbe4e3e152accf63be055075077fa6f/character.json`
