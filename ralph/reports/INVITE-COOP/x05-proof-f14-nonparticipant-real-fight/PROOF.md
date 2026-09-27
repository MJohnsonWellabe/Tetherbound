# Two-peer proof: F14: only an actual freeing-fight participant receives a Guardian offer

**Verdict: PASS** (exit 0)

Scenario: `tools/net/proof_scenarios/f14_guardian_nonparticipant_real_fight.json`  
Run: `net-20260926T211820Z-2408`  
Rendered: no (headless)

ACCEPTANCE F14 clause 'Each actual freeing-fight participant's ... decision grants at most their own once-only creature' and the hard rule 'A non-participant receives nothing'. The guest alone challenges and defeats Captain Nerissa in the Veilfall through the production trainer battle; the host, in the same world, never joins the fight. The host records only the guest as a freeing-fight participant (trainer-participants-host). The guest, at a full belt, asks at the chamber and lets Rill go for the Guardian with controller presses. The host is not offered the invite prompt, and its request sent past the prompt is refused by the host (not_participant); it ends with no Guardian and no claim. Setup only: the Veilfall prerequisites before Nerissa are committed through the ledger; companions are granted by name; win_trainer_battle keeps the fighting creature topped up between swings and caps each opponent's HP at 20 (enemy_hp_ceiling, the boss smokes' own allowance: wiring, not balance), so every creature of Nerissa's team is still met and struck down in order.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/33461 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:33461 as peer 697991614 after 5 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 0 | party_grant — setup: companions by name | PASS | PASS | 'terrapup' at level 3 joined the party (1 member(s)) |
| 5 | 0 | party_grant — setup: the host has room (two of five) | PASS | PASS | 'mosshell' at level 3 joined the party (2 member(s)) |
| 6 | 1 | party_grant | PASS | PASS | 'ripplet' at level 3 joined the party (1 member(s)) |
| 7 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 3 joined the party (2 member(s)) |
| 8 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 3 joined the party (3 member(s)) |
| 9 | 1 | party_grant | PASS | PASS | 'sparkit' at level 3 joined the party (4 member(s)) |
| 10 | 1 | party_grant | PASS | PASS | 'meadowhart' at level 3 joined the party (5 member(s)) |
| 11 | 1 | guardian_state — setup: the guest's belt is full (five) | PASS + {"guardians_owned":0.0,"party_size":5.0} | PASS | {"character_id":"character-c0ef04e3ba8af15182b87d43b405d6d2","claim_id":"dff42da4e77e59c0bfa6d3b4d87dd7dd3d9e3daa760e8f5a8bef0e306f85e30f","guardian_freed":false,"guardians_owned":0,"offered":false,"party":["Kestrel","Bramble","Rill","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":0} |
| 12 | 0 | deploy_creature — each player sends a companion out | PASS | PASS | deployed AllyCreature |
| 12 | 1 | deploy_creature — each player sends a companion out | PASS | PASS | deployed AllyCreature |
| 13 | 0 | guardian_fixture — setup: the Veilfall chain up to Nerissa (her fight itself is played next) | PASS | PASS | Veilfall prerequisites committed ["water_dock_sluice_isle_both_controls_disabled", "water_veilfall_intake_stopped", "water_veilfall_return_opened"]; Nerissa left to be fought |
| 14 | 0 | wait_flag | PASS | PASS | flag water_veilfall_return_opened (world) set after 0 frames |
| 14 | 1 | wait_flag | PASS | PASS | flag water_veilfall_return_opened (world) set after 0 frames |
| 15 | 1 | nerissa_challenge — the GUEST challenges Captain Nerissa in the Veilfall (production begin_trainer_battle) | PASS | PASS | prerequisites committed []; challenged Nerissa (defeat flag 'water_captain_nerissa_defeated') with multi_peer=true; 3 creatures to come |
| 16 | 1 | win_trainer_battle — the guest fights Nerissa's team down through host-arbitrated strikes | PASS | PASS | battle won in 1513 frames / 22 swings against 4 of their creatures |
| 17 | 0 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 17 | 1 | wait_flag | PASS | PASS | flag water_captain_nerissa_defeated (world) set after 0 frames |
| 18 | 0 | guardian_state — the host journals exactly the players who FOUGHT as freeing-fight participants | PASS + {"participants":["character-c0ef04e3ba8af15182b87d43b405d6d2"]} | PASS | {"character_id":"character-5e81d7afea42cfe791d4931a0a3a7bf1","claim_id":"f011df9e0365e89f25684b513b4ecf43afc0fa16fbdaeb5110ec72e9a5b0d4d8","guardian_freed":false,"guardians_owned":0,"host_open_claims":[],"host_settled":false,"offered":false,"participants":["character-c0ef04e3ba8af15182b87d43b405d6d2"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":0} |
| 19 | 1 | veilfall_press — the guest frees the Guardian at the chamber's real control | PASS | PASS | pressed 'Release the Abyssal Guardian' standing at (0.0, -1.2, -1.6); 'water_guardian_freed' set |
| 20 | 0 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 20 | 1 | wait_flag | PASS | PASS | flag water_guardian_freed (world) set after 0 frames |
| 21 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 21 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 22 | 1 | veilfall_press — the guest, who fought, asks for its offer | PASS | PASS | pressed 'Invite the Deep Watcher' standing at (0.0, -1.2, -1.6) |
| 23 | 1 | guardian_answer — AT CAPACITY, ACCEPT: the guest lets Rill go and the Guardian takes the holder | PASS + {"stage":"choose"} | PASS | answered let Rill go: party ["Kestrel", "Bramble", "Rill", "Tuff", "Fern"] -> ["Kestrel", "Bramble", "Abyssal Guardian", "Tuff", "Fern"]; Guardians owned 1; receipt on the saved character=true |
| 24 | 0 | veilfall_press — the host, who never fought, is not offered the invite prompt | FAIL + {"enabled":false} | FAIL | the 'invite' prompt ('Invite the Deep Watcher') does not offer itself (enabled=false) |
| 25 | 0 | guardian_offer_again — a NON-PARTICIPANT's request, sent past the prompt, is refused by the host (not_participant) | PASS + {"code":"not_participant","refused":true} | PASS | asked the host again: ok=false pending=false code='not_participant' message ''; Guardians owned 0 -> 0 |
| 26 | 0 | guardian_state — the host, a non-participant with room, has no Guardian and no claim | PASS + {"guardians_owned":0.0,"host_open_claims":[],"party":["Acorn","Shelby"]} | PASS | {"character_id":"character-5e81d7afea42cfe791d4931a0a3a7bf1","claim_id":"f011df9e0365e89f25684b513b4ecf43afc0fa16fbdaeb5110ec72e9a5b0d4d8","guardian_freed":true,"guardians_owned":0,"host_open_claims":[],"host_settled":true,"offered":false,"participants":["character-c0ef04e3ba8af15182b87d43b405d6d2"],"party":["Acorn","Shelby"],"party_size":2,"pending_guardian_id":"","receipt_saved":false,"saved_guardians":0,"saved_party_size":0} |
| 27 | 1 | guardian_state — the participant has exactly one Guardian in Rill's holder, receipt saved | PASS + {"guardians_owned":1.0,"party":["Kestrel","Bramble","Abyssal Guardian","Tuff","Fern"],"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1.0} | PASS | {"character_id":"character-c0ef04e3ba8af15182b87d43b405d6d2","claim_id":"dff42da4e77e59c0bfa6d3b4d87dd7dd3d9e3daa760e8f5a8bef0e306f85e30f","guardian_freed":true,"guardians_owned":1,"offered":true,"party":["Kestrel","Bramble","Abyssal Guardian","Tuff","Fern"],"party_size":5,"pending_guardian_id":"","receipt_saved":true,"saved_guardians":1,"saved_party_size":5} |
| 28 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 28 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 29 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-5e81d7afea42cfe791d4931a0a3a7bf1' on disk=true; copied 3 files to f14np/peer-0/after |
| 29 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-c0ef04e3ba8af15182b87d43b405d6d2' on disk=true; copied 1 files to f14np/peer-1/after |
| 30 | 1 | check_saved — the participant's saved character holds the Guardian | PASS | PASS | missing []; unexpectedly present []; read ["character-c0ef04e3ba8af15182b87d43b405d6d2/character.json"] under after/characters |
| 31 | 0 | check_saved — the non-participant's saved character does not | PASS | PASS | missing []; unexpectedly present []; read ["character-5e81d7afea42cfe791d4931a0a3a7bf1/character.json"] under after/characters |

## Captured files

- `peer-0/after/characters/character-5e81d7afea42cfe791d4931a0a3a7bf1/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-1/after/characters/character-c0ef04e3ba8af15182b87d43b405d6d2/character.json`

---
X05 note: run locally in a worktree pinned to 4f5bf2cde43b33948ee6e353958715db2ae8539a (the render.yml copy was still queued behind runner starvation); loopback ENet, not internet or Steam evidence. `SCRIPT ERROR` count 0 in both peer logs. Row 24 is the scenario's own `expect: FAIL` (the non-participant host is not offered the prompt). Captured saves are gzipped here (`.json.gz`).
