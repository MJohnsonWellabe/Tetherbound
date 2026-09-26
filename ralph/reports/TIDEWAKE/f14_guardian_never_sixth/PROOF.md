# Two-peer proof: F14: never an owned sixth -- at a full five the guest lets the Guardian itself go

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tetherbound/tools/net/proof_scenarios/f14_guardian_never_sixth.json`  
Run: `net-20260926T042554Z-5826`  
Rendered: yes

ACCEPTANCE F14 clause 'never an owned sixth', the let-the-newcomer-go path (the forged-accept path is f14_guardian_never_sixth_forged.json; the honest swap is f14_guardian_offer_capacity_space.json). The guest is at a full five, the host has room as the control. The guest frees the Guardian, asks at the chamber's real prompt and, on the Creatures tab the game opens, chooses the Guardian's OWN newcomer row (index 5) and 'Let them go' with controller presses only. It keeps exactly the same five (live and on disk), owns no Guardian anywhere, and its offer is resolved (receipt saved, nothing pending, the host journal holds no open claim). The host accepts into its free holder as the control. Repeat requests from both are refused already_resolved and the invite prompt is gone. Setup as in f14_guardian_offer_capacity_space.json (ledger-committed prerequisites, injected fight roster through the director's session path, companions granted by name).

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/28921 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:28921 as peer 174718992 after 7 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 4 | 0 | party_grant — setup: companions by name | PASS | PASS | 'terrapup' at level 3 joined the party (1 member(s)) |
| 5 | 0 | party_grant — setup: the host has room (two of five) | PASS | PASS | 'mosshell' at level 3 joined the party (2 member(s)) |
| 6 | 1 | party_grant — setup: companions by name | PASS | PASS | 'ripplet' at level 3 joined the party (1 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 3 joined the party (2 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 3 joined the party (3 member(s)) |
| 9 | 1 | party_grant | PASS | PASS | 'sparkit' at level 3 joined the party (4 member(s)) |
| 10 | 1 | party_grant | PASS | PASS | 'meadowhart' at level 3 joined the party (5 member(s)) |
| 11 | 1 | guardian_state — setup: the guest's belt is full (five) | PASS + {"guardians_owned":0.0,"party_size":5.0} | PASS | {"character_id":"character-ad3f2faefc3205552d9421346405b088","claim_id":"58ec1fae4a96423879ea13b46ee24271365687c1785be4e6c5028e93504e60e4","guardian_freed":false,"guardians_owned":0,"offered":false,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":0} |
| 12 | 0 | guardian_fixture — setup: both fought Nerissa (the director's own session path journals one reward row each) | PASS | PASS | prerequisites committed ["water_dock_sluice_isle_both_controls_disabled", "water_veilfall_intake_stopped", "water_veilfall_return_opened"]; Nerissa fought by peers [1, 174718992]; session path handled=true; 'water_captain_nerissa_defeated' set=true; participant characters ["character-94f4194916fa585bd090f3ecf7d3b90f", "character-ad3f2faefc3205552d9421346405b088"] |
| 13 | 0 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 13 | 1 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 14 | 1 | veilfall_press — the GUEST frees the Guardian at the chamber's real control | PASS | PASS | pressed 'Release the Abyssal Guardian' standing at (0.0, -1.2, -1.6); 'water_guardian_freed' set |
| 15 | 0 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 15 | 1 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 16 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_never_sixth/peer-0/00_guardian_freed.png |
| 16 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_never_sixth/peer-1/00_guardian_freed.png |
| 17 | 0 | guardian_state — the host journals both characters as freeing-fight participants; no claim open yet | PASS + {"guardian_freed":true,"host_open_claims":[],"participants":["character-94f4194916fa585bd090f3ecf7d3b90f","character-ad3f2faefc3205552d9421346405b088"]} | PASS | {"character_id":"character-94f4194916fa585bd090f3ecf7d3b90f","claim_id":"b6f6cb65a9b77eefb17985bb16c5ea16464c58bab0e30a2f8f28dacebd18e0f9","guardian_freed":true,"guardians_owned":0,"host_open_claims":[],"host_settled":false,"offered":false,"participants":["character-94f4194916fa585bd090f3ecf7d3b90f","character-ad3f2faefc3205552d9421346405b088"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":2} |
| 18 | 0 | guardian_state — baseline: the host (control) has room, two of five, no Guardian | PASS + {"guardians_owned":0.0,"party":["Acorn","Shelby"],"party_size":2.0} | PASS | {"character_id":"character-94f4194916fa585bd090f3ecf7d3b90f","claim_id":"b6f6cb65a9b77eefb17985bb16c5ea16464c58bab0e30a2f8f28dacebd18e0f9","guardian_freed":true,"guardians_owned":0,"host_open_claims":[],"host_settled":false,"offered":false,"participants":["character-94f4194916fa585bd090f3ecf7d3b90f","character-ad3f2faefc3205552d9421346405b088"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":2} |
| 19 | 1 | veilfall_press — the guest asks for its own offer at the chamber | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 20 | 1 | guardian_answer — baseline: AT CAPACITY the ceremony is on screen, unanswered: the guest's five plus the Guardian as the newcomer row | PASS + {"party_before":["Kestrel","Bramble","Rill","Tuff","Fern"],"pending_species":"water_abyssal_guardian","stage":"choose"} | PASS | offer on screen at stage 'choose' for party ["Kestrel", "Bramble", "Rill", "Tuff", "Fern"] (tab visible=true, focus '@HBoxContainer@2421/@VBoxContainer@2422/@MarginContainer@2508/@Button@2495') |
| 21 | 1 | guardian_state — baseline before the guest's answer: five owned, no Guardian live or saved, no receipt | PASS + {"guardians_owned":0.0,"party_size":5.0,"receipt_saved":false,"saved_guardians":0.0} | PASS | {"character_id":"character-ad3f2faefc3205552d9421346405b088","claim_id":"58ec1fae4a96423879ea13b46ee24271365687c1785be4e6c5028e93504e60e4","guardian_freed":true,"guardians_owned":0,"offered":true,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"58ec1fae4a96423879ea13b46ee24271365687c1785be4e6c5028e93504e60e4","receipt_saved":false,"saved_guardians":0,"saved_party_size":5} |
| 22 | 1 | water_guardian_let_go — LEG 1, AT CAPACITY: the guest lets the GUARDIAN itself go (newcomer row 5); the same five stay, no Guardian, offer resolved | PASS + {"guardians_owned":0.0,"party_size":5.0,"pending_catch":false,"pending_guardian_id":"","receipt_saved":true,"release_target":5.0,"same_five":true,"saved_guardians":0.0,"saved_party_size":5.0} | PASS | let the Guardian (row 5) go: party ["Kestrel", "Bramble", "Rill", "Tuff", "Fern"] -> ["Kestrel", "Bramble", "Rill", "Tuff", "Fern"]; Guardians owned 0 (saved 0, saved party 5); receipt saved=true; offer still held ''; pending_catch=false |
| 23 | 0 | guardian_state — the host settled the guest's answer: no claim left open (nothing held for the guest), control untouched before its own answer | PASS + {"guardians_owned":0.0,"host_open_claims":[],"host_settled":true,"party_size":2.0} | PASS | {"character_id":"character-94f4194916fa585bd090f3ecf7d3b90f","claim_id":"b6f6cb65a9b77eefb17985bb16c5ea16464c58bab0e30a2f8f28dacebd18e0f9","guardian_freed":true,"guardians_owned":0,"host_open_claims":[],"host_settled":true,"offered":false,"participants":["character-94f4194916fa585bd090f3ecf7d3b90f","character-ad3f2faefc3205552d9421346405b088"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":2} |
| 24 | 0 | veilfall_press — control: the host asks for its own offer | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 25 | 0 | guardian_answer — control WITH ROOM: the host's own Accept/Decline; Accept takes the free holder (3 of 5) | PASS + {"after":{"guardians_owned":1.0,"party_size":3.0},"stage":"guardian"} | PASS | answered Accept: party ["Acorn", "Shelby"] -> ["Acorn", "Shelby", "Abyssal Guardian"]; Guardians owned 1; receipt on the saved character=true |
| 26 | 1 | veilfall_press — repeat after resolution: the chamber no longer offers the guest its invite prompt | FAIL + {"enabled":false} | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 27 | 0 | veilfall_press — repeat after resolution: nor the host | FAIL + {"enabled":false} | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 28 | 1 | guardian_offer_again — repeat after resolution, judged by the host: the guest's raw offer intent is refused already_resolved; nothing new pending | PASS + {"pending_guardian_id":"","refused":true} | PASS | asked the host again: ok=false pending=true code='' message 'You have already answered the Guardian's offer in this world.'; Guardians owned 0 -> 0 |
| 29 | 0 | guardian_offer_again — repeat after resolution, judged by the host: the host's own repeat is refused already_resolved | PASS + {"code":"already_resolved","pending_guardian_id":"","refused":true} | PASS | asked the host again: ok=false pending=false code='already_resolved' message ''; Guardians owned 1 -> 1 |
| 30 | 1 | guardian_state — guest after everything: still exactly five, live and saved, exactly the expected members | PASS + {"guardians_owned":0.0,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5.0,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":0.0,"saved_party_size":5.0} | PASS | {"character_id":"character-ad3f2faefc3205552d9421346405b088","claim_id":"58ec1fae4a96423879ea13b46ee24271365687c1785be4e6c5028e93504e60e4","guardian_freed":true,"guardians_owned":0,"offered":true,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":0,"saved_party_size":5} |
| 31 | 0 | guardian_state — host (control): exactly one Guardian, receipt saved, no claim left open for anyone | PASS + {"guardians_owned":1.0,"host_open_claims":[],"host_settled":true,"party":["Acorn","Shelby","Abyssal Guardian"],"party_size":3.0,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1.0,"saved_party_size":3.0} | PASS | {"character_id":"character-94f4194916fa585bd090f3ecf7d3b90f","claim_id":"b6f6cb65a9b77eefb17985bb16c5ea16464c58bab0e30a2f8f28dacebd18e0f9","guardian_freed":true,"guardians_owned":1,"host_open_claims":[],"host_settled":true,"offered":true,"participants":["character-94f4194916fa585bd090f3ecf7d3b90f","character-ad3f2faefc3205552d9421346405b088"],"party":["Acorn","Shelby","Abyssal Guardian"],"party_size":3,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1,"saved_party_size":3} |
| 32 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_never_sixth/peer-0/04_after.png |
| 32 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_never_sixth/peer-1/04_after.png |
| 33 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-94f4194916fa585bd090f3ecf7d3b90f' on disk=true; copied 3 files to /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_never_sixth/peer-0/after |
| 33 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-ad3f2faefc3205552d9421346405b088' on disk=true; copied 1 files to /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_never_sixth/peer-1/after |
| 34 | 1 | check_saved — guest's saved character on disk: the expected five and nothing else of the Guardian's | PASS | PASS | missing []; unexpectedly present []; read ["character-ad3f2faefc3205552d9421346405b088/character.json"] under after/characters |
| 35 | 0 | check_saved — host's saved character on disk | PASS | PASS | missing []; unexpectedly present []; read ["character-94f4194916fa585bd090f3ecf7d3b90f/character.json"] under after/characters |
| 36 | 0 | check_saved — host's saved world on disk: no Guardian held anywhere in the journal (no open claim, no hidden holder) for either character | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |

## Captured files

- `peer-0/00_guardian_freed.png`
- `peer-0/03_host_offer_with_room.png`
- `peer-0/04_after.png`
- `peer-0/after/characters/character-94f4194916fa585bd090f3ecf7d3b90f/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-1/00_guardian_freed.png`
- `peer-1/01_guest_offer_at_capacity.png`
- `peer-1/02_guest_lets_guardian_go.png`
- `peer-1/02_guest_lets_guardian_go_done.png`
- `peer-1/04_after.png`
- `peer-1/after/characters/character-ad3f2faefc3205552d9421346405b088/character.json`
