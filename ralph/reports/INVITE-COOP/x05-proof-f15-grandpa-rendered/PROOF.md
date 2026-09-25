# Two-peer proof: F15: Grandpa acknowledges each player's current team, including releases

**Verdict: PASS** (exit 0)

Scenario: `/home/user/x05-ledger/tools/net/proof_scenarios/f15_grandpa_acknowledges_each_team.json`  
Run: `net-20260925T193213Z-7100`  
Rendered: yes

ACCEPTANCE F15 clause 'receive Grandpa's acknowledgement of each current team, including releases' (T3: 'Grandpa recognizes each character's current companions, including releases'). Host and guest each walk up to Grandpa in the Meadows after the Tidewake currents are restored and press his real prompt; each hears their OWN current team named (and never the other player's), and a companion the guest let go before the visit is not named. Each player's homecoming_seen is written to their own saved character. Setup only: the host marks the world moved past the opening and the Tidewake finale's world flag through the ledger (standing in for playing the chapter), companions are granted by name, and the guest's release is the same party.remove_at the release ceremony performs.

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/28941 as peer 1 |
| 2 | 0 | story_flag — setup: world past the opening | PASS | PASS | defeated_warden: ok=true pending=false code='' reason='' |
| 3 | 1 | join | PASS | PASS | joined 127.0.0.1:28941 as peer 682226389 after 20 frames; snapshot applied; 2 peer(s) in registry |
| 4 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 4 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 0 | story_flag — setup: the Tidewake currents are restored (host-only world flag) | PASS | PASS | water_currents_restored: ok=true pending=false code='' reason='' |
| 6 | 0 | wait_flag | PASS | PASS | flag water_currents_restored (world) set after 0 frames |
| 6 | 1 | wait_flag | PASS | PASS | flag water_currents_restored (world) set after 0 frames |
| 7 | 0 | party_grant | PASS | PASS | 'terrapup' at level 3 joined the party (2 member(s)) |
| 8 | 0 | party_grant | PASS | PASS | 'mosshell' at level 3 joined the party (3 member(s)) |
| 9 | 0 | party_grant | PASS | PASS | 'sparkit' at level 3 joined the party (4 member(s)) |
| 10 | 1 | party_grant | PASS | PASS | 'bramblebun' at level 3 joined the party (2 member(s)) |
| 11 | 1 | party_grant | PASS | PASS | 'mudsnout' at level 3 joined the party (3 member(s)) |
| 12 | 1 | party_grant | PASS | PASS | 'terrapup' at level 3 joined the party (4 member(s)) |
| 13 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-e6872d7776a2aa4e88ade43e8f647064' on disk=true; copied 3 files to peer-0/before |
| 13 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-69654c7b43972e7cfb0dff0df5d8a436' on disk=true; copied 1 files to peer-1/before |
| 14 | 0 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> peer-0/00_home_before_the_visit.png |
| 14 | 1 | screenshot — first rendered frame (shader warm-up under its own allowance) | PASS | PASS | captured 960x540 -> peer-1/00_home_before_the_visit.png |
| 15 | 1 | release_member — setup: the guest lets Rill go | PASS | PASS | released 'Rill' from slot 2; party now ["Terrapup", "Bramble", "Tuff"] |
| 16 | 0 | grandpa_homecoming — host: its own team, nobody else's | PASS + {"homecoming_seen":true} | PASS | conversation 'regional_homecoming_4' (expected 'regional_homecoming_4', 8 lines) for party ["Terrapup", "Pip", "Shelby", "Volt"]; homecoming_seen=true; missing names []; wrongly named []; credits opened=true; captured 960x540 -> peer-0/01_host_grandpa.png; lines: Grandpa Elias: You're home. Word reached us that the Tidewake crossings are free again. / Grandpa Elias: The road from these fields to the outer islands belongs to its people again. / Grandpa Elias: Terrapup came home with you. / Grandpa Elias: Pip came home with you. / Grandpa Elias: Shelby came home with you. / Grandpa Elias: Volt came home with you. / Grandpa Elias: Some companions walk beside us for a season. What they gave us still matters. / Grandpa Elias: Come sit a minute. I'm glad you're here. |
| 17 | 1 | grandpa_homecoming — guest: its current team; the released Rill is not named | PASS + {"homecoming_seen":true} | PASS | conversation 'regional_homecoming_3' (expected 'regional_homecoming_3', 7 lines) for party ["Terrapup", "Bramble", "Tuff"]; homecoming_seen=true; missing names []; wrongly named []; credits opened=true; captured 960x540 -> peer-1/01_guest_grandpa.png; lines: Grandpa Elias: You're home. Word reached us that the Tidewake crossings are free again. / Grandpa Elias: The road from these fields to the outer islands belongs to its people again. / Grandpa Elias: Terrapup came home with you. / Grandpa Elias: Bramble came home with you. / Grandpa Elias: Tuff came home with you. / Grandpa Elias: Some companions walk beside us for a season. What they gave us still matters. / Grandpa Elias: Come sit a minute. I'm glad you're here. |
| 18 | 0 | screenshot | PASS | PASS | captured 960x540 -> peer-0/02_after_homecoming.png |
| 18 | 1 | screenshot | PASS | PASS | captured 960x540 -> peer-1/02_after_homecoming.png |
| 19 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-e6872d7776a2aa4e88ade43e8f647064' on disk=true; copied 3 files to peer-0/after |
| 19 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-69654c7b43972e7cfb0dff0df5d8a436' on disk=true; copied 1 files to peer-1/after |
| 20 | 0 | check_saved — host's saved character: homecoming seen, team kept | PASS | PASS | missing []; unexpectedly present []; read ["character-e6872d7776a2aa4e88ade43e8f647064/character.json"] under after/characters |
| 21 | 1 | check_saved — guest's saved character: homecoming seen, Rill gone | PASS | PASS | missing []; unexpectedly present []; read ["character-69654c7b43972e7cfb0dff0df5d8a436/character.json"] under after/characters |
| 22 | 1 | check_saved — guest's pre-visit save held Rill and no homecoming (non-vacuous baseline) | PASS | PASS | missing []; unexpectedly present []; read ["character-69654c7b43972e7cfb0dff0df5d8a436/character.json"] under before/characters |
| 23 | 0 | check_saved — the homecoming is personal: nothing written to the shared world | PASS | PASS | missing []; unexpectedly present []; read ["slot-0/world.json"] under after/worlds |

## Captured files

- `peer-0/00_home_before_the_visit.png`
- `peer-0/01_host_grandpa.png`
- `peer-0/02_after_homecoming.png`
- `peer-0/after/characters/character-e6872d7776a2aa4e88ade43e8f647064/character.json`
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/worlds/slot-0/world.json`
- `peer-0/before/characters/character-e6872d7776a2aa4e88ade43e8f647064/character.json`
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/worlds/slot-0/world.json`
- `peer-1/00_home_before_the_visit.png`
- `peer-1/01_guest_grandpa.png`
- `peer-1/02_after_homecoming.png`
- `peer-1/after/characters/character-69654c7b43972e7cfb0dff0df5d8a436/character.json`
- `peer-1/before/characters/character-69654c7b43972e7cfb0dff0df5d8a436/character.json`

---
Annotated after the run (not written by the runner): characters/ files are committed gzipped; saves/ and worlds/ copies and net/ logs are omitted for size (the worlds check above ran on the run machine).
