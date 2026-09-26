# Two-peer proof: F14: a host who beat Nerissa alone answers the Guardian after inviting a guest

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tetherbound/tools/net/proof_scenarios/f14_guardian_solo_win_then_invite.json`  
Run: `net-20260926T093458Z-15858`  
Rendered: yes

ACCEPTANCE F14 clause 'every participant in the fight that freed it receives their own offer; a non-participant receives nothing'. The host hosts and fights Captain Nerissa ALONE (a one-peer session: no guest connected) through the production challenge and strikes; the solo win journals the host's own per-participant Nerissa delivery rows (encounter_director.gd `_journal_solo_trainer_win`), paid once through the ledger. A guest then joins. The host frees the Guardian at the chamber's real control and, WITH THE GUEST CONNECTED, asks at the chamber's real prompt and accepts on the Creatures tab with controller presses. The guest, who did not fight, sees no invite prompt and its offer intent (sent past the hidden prompt) is refused by the host with begin()'s not_participant reason; it receives no claim, marker or Guardian. Setup only: the Veilfall chain up to Nerissa is committed through the ledger (standing in for playing it); companions are granted by name (the water scene boots with an empty belt); the fight uses win_trainer_battle's enemy_hp_ceiling (a wiring test, not balance).

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/33701 as peer 1 |
| 2 | 0 | expect_peers — nobody else is in the session | PASS | PASS | registry reports 1 peer(s) after 0 frames |
| 3 | 0 | party_grant — setup: the host's companion by name | PASS | PASS | 'terrapup' at level 55 joined the party (1 member(s)) |
| 4 | 0 | deploy_creature — the host calls its companion out | PASS | PASS | deployed AllyCreature |
| 5 | 0 | nerissa_challenge — the host alone takes up Captain Nerissa's challenge at her Veilfall spot | PASS + {"multi_peer":false} | PASS | prerequisites committed ["water_dock_sluice_isle_both_controls_disabled", "water_veilfall_intake_stopped", "water_veilfall_return_opened"]; challenged Nerissa (defeat flag 'water_captain_nerissa_defeated') with multi_peer=false; 3 creatures to come |
| 6 | 0 | win_trainer_battle — the host wins alone (no guest connected) | PASS | PASS | battle won in 858 frames / 7 swings against 4 of their creatures |
| 7 | 0 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 8 | 0 | guardian_state — the solo win journaled the host's own Nerissa rows: the participant set names the host | PASS + {"guardian_freed":false,"participants":["character-d8ad681138a6cab5f7f736954d8cf4e3"]} | PASS | {"character_id":"character-d8ad681138a6cab5f7f736954d8cf4e3","claim_id":"34a4d43444c7ce2d16cc64d9883f3c061ca682e02a7675e83a5d0e23705629dc","guardian_freed":false,"guardians_owned":0,"host_open_claims":[],"host_settled":false,"offered":false,"participants":["character-d8ad681138a6cab5f7f736954d8cf4e3"],"party":["Acorn"],"party_size":1,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":1} |
| 9 | 1 | join | PASS | PASS | joined 127.0.0.1:33701 as peer 320979267 after 5 frames; snapshot applied; 2 peer(s) in registry |
| 10 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 10 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 11 | 1 | party_grant — setup: the guest's companion by name | PASS | PASS | 'ripplet' at level 3 joined the party (1 member(s)) |
| 12 | 1 | wait_flag — the guest's snapshot holds Nerissa's defeat | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 13 | 0 | veilfall_press — the HOST frees the Guardian at the chamber's real control, the guest connected | PASS | PASS | pressed 'Release the Abyssal Guardian' standing at (0.0, -1.2, -1.6); 'water_guardian_freed' set |
| 14 | 0 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 14 | 1 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 15 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_solo_win_then_invite/peer-0/00_guardian_freed.png |
| 15 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_solo_win_then_invite/peer-1/00_guardian_freed.png |
| 16 | 0 | guardian_state — with the guest connected the journal still names only the host | PASS + {"guardian_freed":true,"offered":false,"participants":["character-d8ad681138a6cab5f7f736954d8cf4e3"]} | PASS | {"character_id":"character-d8ad681138a6cab5f7f736954d8cf4e3","claim_id":"34a4d43444c7ce2d16cc64d9883f3c061ca682e02a7675e83a5d0e23705629dc","guardian_freed":true,"guardians_owned":0,"host_open_claims":[],"host_settled":false,"offered":false,"participants":["character-d8ad681138a6cab5f7f736954d8cf4e3"],"party":["Acorn"],"party_size":1,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":1} |
| 17 | 1 | veilfall_press — the guest, who did not fight, is not offered the invite prompt | FAIL + {"enabled":false} | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 18 | 1 | guardian_offer_refused — the guest's offer intent, sent past the hidden prompt, is refused by the host (not_participant) | PASS + {"guardians_owned":0.0,"offered":false,"pending_guardian_id":"","refused":true} | PASS | asked the host for an offer: ok=false pending=true code='' message 'Only those who fought Captain Nerissa to free the Guardian receive its offer.'; offered=false claim='' Guardians 0 |
| 19 | 0 | veilfall_press — the host asks for its own offer WITH THE GUEST CONNECTED (formerly hidden) | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 20 | 0 | guardian_answer — the host accepts its own Guardian with controller presses | PASS + {"stage":"guardian"} | PASS | answered Accept: party ["Acorn"] -> ["Acorn", "Abyssal Guardian"]; Guardians owned 1; receipt on the saved character=true |
| 21 | 0 | expect_peers — the guest was connected throughout the answer | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 21 | 1 | expect_peers — the guest was connected throughout the answer | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 22 | 0 | guardian_state — host: exactly one Guardian, receipt saved, no claim open, world settled | PASS + {"guardians_owned":1.0,"host_open_claims":[],"host_settled":true,"participants":["character-d8ad681138a6cab5f7f736954d8cf4e3"],"party":["Acorn","Abyssal Guardian"],"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1.0} | PASS | {"character_id":"character-d8ad681138a6cab5f7f736954d8cf4e3","claim_id":"34a4d43444c7ce2d16cc64d9883f3c061ca682e02a7675e83a5d0e23705629dc","guardian_freed":true,"guardians_owned":1,"host_open_claims":[],"host_settled":true,"offered":true,"participants":["character-d8ad681138a6cab5f7f736954d8cf4e3"],"party":["Acorn","Abyssal Guardian"],"party_size":2,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1,"saved_party_size":2} |
| 23 | 1 | guardian_state — guest: nothing received | PASS + {"guardians_owned":0.0,"offered":false,"party":["Kestrel"],"pending_guardian_id":""} | PASS | {"character_id":"character-f720acb4795845a1f5f3a0b7eaac6c21","claim_id":"5685b91bae2881f9e774b1e6ab9722b7928ec5312e2625a3a3c83fe86fd70f8f","guardian_freed":true,"guardians_owned":0,"offered":false,"party":["Kestrel"],"party_size":1,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":0} |
| 24 | 0 | guardian_offer_again — once only: the host's repeat request is refused already_resolved | PASS + {"code":"already_resolved","refused":true} | PASS | asked the host again: ok=false pending=false code='already_resolved' message ''; Guardians owned 1 -> 1 |
| 25 | 0 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_solo_win_then_invite/peer-0/02_after.png |
| 25 | 1 | screenshot | PASS | PASS | captured 960x540 -> /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_solo_win_then_invite/peer-1/02_after.png |
| 26 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-d8ad681138a6cab5f7f736954d8cf4e3' on disk=true; copied 3 files to /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_solo_win_then_invite/peer-0/after |
| 26 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-f720acb4795845a1f5f3a0b7eaac6c21' on disk=true; copied 1 files to /home/user/tetherbound/ralph/reports/TIDEWAKE/f14_guardian_solo_win_then_invite/peer-1/after |
| 27 | 0 | check_saved — host's saved character holds its Guardian | PASS | PASS | missing []; unexpectedly present []; read ["character-d8ad681138a6cab5f7f736954d8cf4e3/character.json"] under after/characters |
| 28 | 1 | check_saved — guest's saved character holds no Guardian | PASS | PASS | missing []; unexpectedly present []; read ["character-f720acb4795845a1f5f3a0b7eaac6c21/character.json"] under after/characters |

## Captured files

- `peer-0/00_guardian_freed.png`
- `peer-0/01_host_offer_guest_connected.png`
- `peer-0/02_after.png`
- `peer-0/after/characters/character-d8ad681138a6cab5f7f736954d8cf4e3/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-1/00_guardian_freed.png`
- `peer-1/02_after.png`
- `peer-1/after/characters/character-f720acb4795845a1f5f3a0b7eaac6c21/character.json`
