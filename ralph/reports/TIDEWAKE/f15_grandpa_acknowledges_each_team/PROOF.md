> **Run history (Tidewake, on the consolidation base afd2421f0).**
> - A rendered attempt failed at #19 with "peer silent (peer 0, no heartbeat for >15 s)". The host stalled while building the rendered Meadows, with another two-peer proof running at the same time on this machine. No assertion failed.
> - This report is the one confirming rerun, headless: PASS.
> - X05's rendered PASS of the same scenario is `ralph/reports/INVITE-COOP/x05-proof-f15-grandpa-rendered/PROOF.md`.

# Two-peer proof: F15: Grandpa acknowledges each player's current team, including releases

**Verdict: PASS** (exit 0)

Scenario: `/home/user/tetherbound/tools/net/proof_scenarios/f15_grandpa_acknowledges_each_team.json`  
Run: `net-20260926T012831Z-8355`  
Rendered: no (headless)

ACCEPTANCE F15 clause 'receive Grandpa's acknowledgement of each current team, including releases' (T3: 'Grandpa recognizes each character's current companions, including releases'). Host and guest are each teleported beside Grandpa in the Meadows after the Tidewake currents are restored and press his real prompt through the interaction arbiter; each hears exactly their OWN current team named, in party order (and never the other player's), and a companion the guest let go for a new catch at a full party before the visit is not named while the newcomer is. Each player's homecoming_seen is written to their own saved character and not to the shared world. Setup only: the host marks the world past the opening and the Tidewake finale's world flag through the ledger (standing in for playing the chapter), companions are granted and starters renamed by the party seam so every name is distinct, and the release replays tab_creatures.gd::_do_release()'s own remove_at-then-add sequence rather than driving the release menu.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/29781 as peer 1 |
| 2 | 0 | story_flag — setup: world past the opening | PASS | PASS | defeated_warden: ok=true pending=false code='' reason='' |
| 3 | 1 | join | PASS | PASS | joined 127.0.0.1:29781 as peer 2065255250 after 24 frames; snapshot applied; 2 peer(s) in registry |
| 4 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 4 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
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
| 16 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-b63f3b19d7a2257310dd796b14f0f6c3' on disk=true; copied 3 files to /home/user/tetherbound/ralph/reports/TIDEWAKE/f15_grandpa_acknowledges_each_team/peer-0/before |
| 16 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-42be72f16aa9e63a92835e9779d20b27' on disk=true; copied 1 files to /home/user/tetherbound/ralph/reports/TIDEWAKE/f15_grandpa_acknowledges_each_team/peer-1/before |
| 17 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 17 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 18 | 1 | release_for_catch — setup: at a full party the guest lets Rill go for a new catch, Newt | PASS + {"party":["Kestrel","Bramble","Tuff","Fern","Newt"]} | PASS | released 'Rill' for new catch 'Newt'; party now ["Kestrel", "Bramble", "Tuff", "Fern", "Newt"] |
| 19 | 0 | grandpa_homecoming — host: its own team, nobody else's | PASS + {"homecoming_seen":true,"party":["Acorn","Pip","Shelby","Volt"]} | PASS | conversation 'regional_homecoming_4' (expected 'regional_homecoming_4', 8 lines) for party ["Acorn", "Pip", "Shelby", "Volt"]; homecoming_seen=true; missing names []; wrongly named []; credits opened=true; headless peer: no frame to capture (run with --render); lines: Grandpa Elias: You're home. Word reached us that the Tidewake crossings are free again. / Grandpa Elias: The road from these fields to the outer islands belongs to its people again. / Grandpa Elias: Acorn came home with you. / Grandpa Elias: Pip came home with you. / Grandpa Elias: Shelby came home with you. / Grandpa Elias: Volt came home with you. / Grandpa Elias: Some companions walk beside us for a season. What they gave us still matters. / Grandpa Elias: Come sit a minute. I'm glad you're here. |
| 20 | 1 | grandpa_homecoming — guest: its current five; the released Rill is not named, the newcomer Newt is | PASS + {"homecoming_seen":true,"party":["Kestrel","Bramble","Tuff","Fern","Newt"]} | PASS | conversation 'regional_homecoming_5' (expected 'regional_homecoming_5', 9 lines) for party ["Kestrel", "Bramble", "Tuff", "Fern", "Newt"]; homecoming_seen=true; missing names []; wrongly named []; credits opened=true; headless peer: no frame to capture (run with --render); lines: Grandpa Elias: You're home. Word reached us that the Tidewake crossings are free again. / Grandpa Elias: The road from these fields to the outer islands belongs to its people again. / Grandpa Elias: Kestrel came home with you. / Grandpa Elias: Bramble came home with you. / Grandpa Elias: Tuff came home with you. / Grandpa Elias: Fern came home with you. / Grandpa Elias: Newt came home with you. / Grandpa Elias: Some companions walk beside us for a season. What they gave us still matters. / Grandpa Elias: Come sit a minute. I'm glad you're here. |
| 21 | 0 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 21 | 1 | screenshot | PASS | PASS | headless peer: no frame to capture (run with --render) |
| 22 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-b63f3b19d7a2257310dd796b14f0f6c3' on disk=true; copied 3 files to /home/user/tetherbound/ralph/reports/TIDEWAKE/f15_grandpa_acknowledges_each_team/peer-0/after |
| 22 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-42be72f16aa9e63a92835e9779d20b27' on disk=true; copied 1 files to /home/user/tetherbound/ralph/reports/TIDEWAKE/f15_grandpa_acknowledges_each_team/peer-1/after |
| 23 | 0 | check_saved — host's saved character: homecoming seen, team kept | PASS | PASS | missing []; unexpectedly present []; read ["character-b63f3b19d7a2257310dd796b14f0f6c3/character.json"] under after/characters |
| 24 | 1 | check_saved — guest's saved character: homecoming seen, Rill gone, Newt kept | PASS | PASS | missing []; unexpectedly present []; read ["character-42be72f16aa9e63a92835e9779d20b27/character.json"] under after/characters |
| 25 | 1 | check_saved — guest's pre-visit save held Rill and no homecoming (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["character-42be72f16aa9e63a92835e9779d20b27/character.json"] under before/characters |
| 26 | 0 | check_saved — host's pre-visit save held no homecoming (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["character-b63f3b19d7a2257310dd796b14f0f6c3/character.json"] under before/characters |
| 27 | 0 | check_saved — the homecoming is personal: nothing written to the shared world | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |

## Captured files

- `peer-0/after/characters/character-b63f3b19d7a2257310dd796b14f0f6c3/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-b63f3b19d7a2257310dd796b14f0f6c3/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-1/after/characters/character-42be72f16aa9e63a92835e9779d20b27/character.json`
- `peer-1/before/characters/character-42be72f16aa9e63a92835e9779d20b27/character.json`
