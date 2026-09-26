# Two-peer proof: F15#3 guest half: a guest's acknowledged current team, including a release, survives the guest's reconnect

**Verdict: PASS** (exit 0)

Scenario: `/home/user/x05-ledger/tools/net/proof_scenarios/f15_guest_team_survives_reconnect.json`  
Run: `net-20260926T155945Z-4442`  
Rendered: no (headless)

ACCEPTANCE F15 clause 'receive Grandpa's acknowledgement of each current team, including releases', the GUEST half. Everything in f15_grandpa_acknowledges_each_team (the same setup and first visits, unchanged), then the guest's link dies after it saved; its in-memory character is blanked so everything after comes from its own character file and the host's snapshot; it rejoins through the title's returning route. Eligibility comes from the host's world (water_currents_restored arrives in the host snapshot). On a second visit Grandpa gives the guest the REPEAT conversation (its homecoming_seen came back from its own file, so it is not acknowledged twice), and the guest's current team is still its post-release five: Rill (released) absent, Newt (the newcomer) present. The host, who never dropped, closes the regional credits its own homecoming opened and then also gets the repeat. Nothing personal reaches the shared world. Setup is disclosed as in the base scenario.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/35361 as peer 1 |
| 2 | 0 | story_flag — setup: world past the opening | PASS | PASS | defeated_warden: ok=true pending=false code='' reason='' |
| 3 | 1 | join | PASS | PASS | joined 127.0.0.1:35361 as peer 199745971 after 29 frames; snapshot applied; 2 peer(s) in registry |
| 4 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 5 | 0 | story_flag — setup: the Tidewake currents are restored (host-only world flag) | PASS | PASS | water_currents_restored: ok=true pending=false code='' reason='' |
| 6 | 0 | wait_flag | PASS | PASS | flag water_currents_restored (world) set after 0 frames |
| 6 | 1 | wait_flag | PASS | PASS | flag water_currents_restored (world) set after 0 frames |
| 7 | 0 | rename_member — setup: the host's starter gets a distinct name | PASS | PASS | party now ["Acorn"] |
| 8 | 1 | rename_member — setup: the guest's starter gets a distinct name | PASS | PASS | party now ["Kestrel"] |
| 9 | 0 | party_grant | PASS | PASS | 'terrapup' at level 3 joined the party (2 member(s)) |
| 10 | 0 | party_grant | PASS | PASS | 'mosshell' at level 3 joined the party (3 member(s)) |
| 11 | 0 | party_grant | PASS | PASS | 'sparkit' at level 3 joined the party (4 member(s)) |
| 12 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 3 joined the party (2 member(s)) |
| 13 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 3 joined the party (3 member(s)) |
| 14 | 1 | party_grant | PASS | PASS | 'terrapup' at level 3 joined the party (4 member(s)) |
| 15 | 1 | party_grant — the guest's party is now full (five) | PASS | PASS | 'meadowhart' at level 3 joined the party (5 member(s)) |
| 16 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-c24df4f6091fcd13784915248d95b52f' on disk=true; copied 3 files to /tmp/claude-0/-home-user/c9782fb5-aa60-52fe-8dc3-e14e47bf496f/scratchpad/f15g/peer-0/before |
| 16 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-2d50a6eb443d8310518c86c8867a078f' on disk=true; copied 1 files to /tmp/claude-0/-home-user/c9782fb5-aa60-52fe-8dc3-e14e47bf496f/scratchpad/f15g/peer-1/before |
| 17 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 17 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 18 | 1 | release_for_catch — setup: at a full party the guest lets Rill go for a new catch, Newt | PASS + {"party":["Kestrel","Bramble","Tuff","Fern","Newt"]} | PASS | released 'Rill' for new catch 'Newt'; party now ["Kestrel", "Bramble", "Tuff", "Fern", "Newt"] |
| 19 | 0 | grandpa_homecoming — host: its own team, nobody else's | PASS + {"homecoming_seen":true,"party":["Acorn","Pip","Shelby","Volt"]} | PASS | conversation 'regional_homecoming_4' (expected 'regional_homecoming_4', 8 lines) for party ["Acorn", "Pip", "Shelby", "Volt"]; homecoming_seen=true; missing names []; wrongly named []; credits opened=true; headless peer: no frame to capture (run with --render); lines: Grandpa Elias: You're home. Word reached us that the Tidewake crossings are free again. / Grandpa Elias: The road from these fields to the outer islands belongs to its people again. / Grandpa Elias: Acorn came home with you. / Grandpa Elias: Pip came home with you. / Grandpa Elias: Shelby came home with you. / Grandpa Elias: Volt came home with you. / Grandpa Elias: Some companions walk beside us for a season. What they gave us still matters. / Grandpa Elias: Come sit a minute. I'm glad you're here. |
| 20 | 1 | grandpa_homecoming — guest: its current five; the released Rill is not named, the newcomer Newt is | PASS + {"homecoming_seen":true,"party":["Kestrel","Bramble","Tuff","Fern","Newt"]} | PASS | conversation 'regional_homecoming_5' (expected 'regional_homecoming_5', 9 lines) for party ["Kestrel", "Bramble", "Tuff", "Fern", "Newt"]; homecoming_seen=true; missing names []; wrongly named []; credits opened=true; headless peer: no frame to capture (run with --render); lines: Grandpa Elias: You're home. Word reached us that the Tidewake crossings are free again. / Grandpa Elias: The road from these fields to the outer islands belongs to its people again. / Grandpa Elias: Kestrel came home with you. / Grandpa Elias: Bramble came home with you. / Grandpa Elias: Tuff came home with you. / Grandpa Elias: Fern came home with you. / Grandpa Elias: Newt came home with you. / Grandpa Elias: Some companions walk beside us for a season. What they gave us still matters. / Grandpa Elias: Come sit a minute. I'm glad you're here. |
| 21 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 21 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 22 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-c24df4f6091fcd13784915248d95b52f' on disk=true; copied 3 files to /tmp/claude-0/-home-user/c9782fb5-aa60-52fe-8dc3-e14e47bf496f/scratchpad/f15g/peer-0/after |
| 22 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-2d50a6eb443d8310518c86c8867a078f' on disk=true; copied 1 files to /tmp/claude-0/-home-user/c9782fb5-aa60-52fe-8dc3-e14e47bf496f/scratchpad/f15g/peer-1/after |
| 23 | 0 | check_saved — host's saved character: homecoming seen, team kept | PASS | PASS | missing []; unexpectedly present []; read ["character-c24df4f6091fcd13784915248d95b52f/character.json"] under after/characters |
| 24 | 1 | check_saved — guest's saved character: homecoming seen, Rill gone, Newt kept | PASS | PASS | missing []; unexpectedly present []; read ["character-2d50a6eb443d8310518c86c8867a078f/character.json"] under after/characters |
| 25 | 1 | check_saved — guest's pre-visit save held Rill and no homecoming (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["character-2d50a6eb443d8310518c86c8867a078f/character.json"] under before/characters |
| 26 | 0 | check_saved — host's pre-visit save held no homecoming (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["character-c24df4f6091fcd13784915248d95b52f/character.json"] under before/characters |
| 27 | 0 | check_saved — the homecoming is personal: nothing written to the shared world | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |
| 28 | 1 | save_character_here — the guest's character is on disk before its link dies | PASS | PASS | character 'character-2d50a6eb443d8310518c86c8867a078f' is on disk (wrote_world=false) |
| 29 | 1 | drop_link — the guest's link dies | PASS | PASS | transport closed without a Session.leave() |
| 30 | 0 | expect_peers — the host sees the guest gone | PASS | PASS | registry reports 1 peer(s) after 0 frames (0.0 s) |
| 31 | 1 | leave — the guest's side of the dead session is torn down | any | FAIL | no active session to leave |
| 32 | 1 | wipe_character — blank the guest's in-memory character (id kept, file untouched): what follows comes from its file and the host | PASS | PASS | in-memory character blanked (party 5 -> 0), id 'character-2d50a6eb443d8310518c86c8867a078f' kept, file untouched |
| 33 | 1 | production_join — the guest rejoins through the title's returning route | PASS | PASS | title returning entry built 'MeadowsPlayground' first, then JoinDriver joined 127.0.0.1:35361 as peer 2046152461 after 123 frames |
| 34 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 34 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 35 | 1 | wait_flag — eligibility comes from the host's world: the flag arrives in the host snapshot | PASS | PASS | flag water_currents_restored (world) set after 0 frames |
| 36 | 1 | grandpa_homecoming — guest after reconnect: the repeat conversation, and its current five (Rill released, Newt kept) | PASS + {"conversation_id":"regional_homecoming_repeat","party":["Kestrel","Bramble","Tuff","Fern","Newt"]} | PASS | conversation 'regional_homecoming_repeat' (expected 'regional_homecoming_repeat', 2 lines) for party ["Kestrel", "Bramble", "Tuff", "Fern", "Newt"]; homecoming_seen=true; missing names []; wrongly named []; credits opened=true; lines: Grandpa Elias: Good to see you home again. / Grandpa Elias: The road is open. You and your companions are welcome here. |
| 37 | 0 | credits_continue — the host closes the regional credits its first homecoming opened, as a player would, before visiting Grandpa again | PASS | PASS | credits watched 87.25s, Continue pressed; acknowledged 1 time(s) (after the first press 1), open after=false, receipt in memory=true on disk=true, pending=false; second press opened 'regional_homecoming_repeat', roll reopened=false |
| 38 | 0 | grandpa_homecoming — host: its own repeat, its own team, untouched by the guest's reconnect | PASS + {"conversation_id":"regional_homecoming_repeat","party":["Acorn","Pip","Shelby","Volt"]} | PASS | conversation 'regional_homecoming_repeat' (expected 'regional_homecoming_repeat', 4 lines) for party ["Acorn", "Pip", "Shelby", "Volt"]; homecoming_seen=true; missing names []; wrongly named []; credits opened=true; headless peer: no frame to capture (run with --render); lines: Grandpa Elias: Good to see you home again. / Grandpa Elias: The road is open. You and your companions are welcome here. / Grandpa Elias: Good to see you home again. / Grandpa Elias: The road is open. You and your companions are welcome here. |
| 39 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-c24df4f6091fcd13784915248d95b52f' on disk=true; copied 3 files to /tmp/claude-0/-home-user/c9782fb5-aa60-52fe-8dc3-e14e47bf496f/scratchpad/f15g/peer-0/after_rejoin |
| 39 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-2d50a6eb443d8310518c86c8867a078f' on disk=true; copied 1 files to /tmp/claude-0/-home-user/c9782fb5-aa60-52fe-8dc3-e14e47bf496f/scratchpad/f15g/peer-1/after_rejoin |
| 40 | 1 | check_saved — guest's saved character after the reconnect: homecoming seen, Rill gone, Newt kept | PASS | PASS | missing []; unexpectedly present []; read ["character-2d50a6eb443d8310518c86c8867a078f/character.json"] under after_rejoin/characters |
| 41 | 0 | check_saved — still nothing personal in the shared world | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after_rejoin/worlds |

## Captured files

- `peer-0/after/characters/character-c24df4f6091fcd13784915248d95b52f/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/after_rejoin/characters/character-c24df4f6091fcd13784915248d95b52f/character.json`
- `peer-0/after_rejoin/saves/slot_0.json`
- `peer-0/after_rejoin/worlds/slot-0/world.json`
- `peer-0/before/characters/character-c24df4f6091fcd13784915248d95b52f/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-1/after/characters/character-2d50a6eb443d8310518c86c8867a078f/character.json`
- `peer-1/after_rejoin/characters/character-2d50a6eb443d8310518c86c8867a078f/character.json`
- `peer-1/before/characters/character-2d50a6eb443d8310518c86c8867a078f/character.json`
