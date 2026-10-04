# Two-peer proof: F13#2: two characters each claim reed_root_hollow (fiber + Reed Camp Cordage) and a Skill Candy pocket, once each

**Verdict: PASS** (exit 0)

Scenario: `/home/user/Tetherbound/tools/net/proof_scenarios/f13_tidewake_b_reed_recipe_two_character_pockets.json`  
Run: `net-20261004T204957Z-6253`  
Rendered: no (headless)

ACCEPTANCE F13#2 reward pockets, co-op per-character claim. Host and guest in the Tidewake each gather the reed_root_hollow patch (water:reedhaven:harvest:012) by the production WaterPickups body, interaction arbiter and interact press; the host validates each character's claim (water_personal_pickup.gd) and each gets its own 3 Reed Fiber and learns Reed Camp Cordage (water_cordage_recipe_learned, player scope). Neither knows the recipe before its own claim; the other character's claim pays and teaches nothing. The same holds for a second pocket (lantern_hidden_cache, Skill Candy I). A repeat request from either character (hand-made, denying the personal receipt) is refused already_taken by the host's per-character world receipt. Saved characters and the host world file are checked. DISCLOSED FIXTURES: (1) a knife granted to each satchel (storage_grant) and bound to hotbar slot 5 by the step, equipped by pressing hotbar_5; (2) each trainer is teleported beside the body instead of walking (the walk is tests/smoke_water_pocket_walk_claim.gd); (3) both peers start in the Water scene (no crossing).

| # | Peer | Step | Expected | Verdict | Detail |
|---|---|---|---|---|---|
| 1 | 0 | host | PASS | PASS | hosting udp/29681 as peer 1 |
| 2 | 1 | join | PASS | PASS | joined 127.0.0.1:29681 as peer 1642864437 after 28 frames; snapshot applied; 2 peer(s) in registry |
| 3 | 0 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 3 | 1 | expect_peers | PASS | PASS | registry reports 2 peer(s) after 0 frames (0.0 s) |
| 4 | 0 | water_pocket_state — non-vacuous: neither fresh character knows Reed Camp Cordage at chapter start | PASS | PASS | { "pickup_id": "water:reedhaven:harvest:012", "character_id": "character-812e6ecf234bf7a3d5cbef50f5d448dd", "item": "reed_fiber", "count": 0, "receipt": false, "learn_flag": "water_cordage_recipe_learned", "learned": false, "recipe": "water_camp_cordage", "recipe_known": false, "resident": false } |
| 4 | 1 | water_pocket_state — non-vacuous: neither fresh character knows Reed Camp Cordage at chapter start | PASS | PASS | { "pickup_id": "water:reedhaven:harvest:012", "character_id": "character-6129a244214ed56ad17f223294e2a680", "item": "reed_fiber", "count": 0, "receipt": false, "learn_flag": "water_cordage_recipe_learned", "learned": false, "recipe": "water_camp_cordage", "recipe_known": false, "resident": false } |
| 5 | 0 | storage_grant — FIXTURE 1: a carried knife (reed fiber is gathered with a knife) | PASS | PASS | granted 1 knife (0 did not fit) |
| 6 | 1 | storage_grant — FIXTURE 1: a carried knife | PASS | PASS | granted 1 knife (0 did not fit) |
| 7 | 0 | water_pocket_claim — host gathers the reed_root_hollow patch by the real prompt: +3 fiber, learns cordage | PASS + {"gained":3.0} | PASS | water:reedhaven:harvest:012: +3 reed_fiber receipt=true recipe_known false -> true resident_after=false |
| 8 | 1 | water_pocket_state — the host's claim taught and paid the guest nothing | PASS | PASS | { "pickup_id": "water:reedhaven:harvest:012", "character_id": "character-6129a244214ed56ad17f223294e2a680", "item": "reed_fiber", "count": 0, "receipt": false, "learn_flag": "water_cordage_recipe_learned", "learned": false, "recipe": "water_camp_cordage", "recipe_known": false, "resident": true } |
| 9 | 1 | water_pocket_claim — guest walks up (teleport) to the patch the host already gathered: it still stands and is offered for the guest; gathered through host validation: +3 fiber, learns its own cordage | PASS + {"gained":3.0} | PASS | water:reedhaven:harvest:012: +3 reed_fiber receipt=true recipe_known false -> true resident_after=false |
| 10 | 0 | water_pocket_state — the guest's claim paid the host nothing more | PASS | PASS | { "pickup_id": "water:reedhaven:harvest:012", "character_id": "character-812e6ecf234bf7a3d5cbef50f5d448dd", "item": "reed_fiber", "count": 3, "receipt": true, "learn_flag": "water_cordage_recipe_learned", "learned": true, "recipe": "water_camp_cordage", "recipe_known": true, "resident": false } |
| 11 | 0 | water_pocket_resend — host repeat (hand-made request denying its receipt) refused | PASS + {"code":"already_taken","committed":false} | PASS | water:reedhaven:harvest:012 resend: code=already_taken committed=false count 3 -> 3 |
| 12 | 1 | water_pocket_resend — guest repeat refused by the host's world receipt | PASS + {"code":"already_taken","committed":false} | PASS | water:reedhaven:harvest:012 resend: code=already_taken committed=false count 3 -> 3 |
| 13 | 0 | water_pocket_claim — second pocket (lantern_hidden_cache Skill Candy I): host claims its own | PASS + {"gained":1.0} | PASS | water:lantern_cove:pickup:002: +1 skill_candy_i receipt=true recipe_known false -> false resident_after=false |
| 14 | 1 | water_pocket_state — the host's candy claim paid the guest nothing | PASS | PASS | { "pickup_id": "water:lantern_cove:pickup:002", "character_id": "character-6129a244214ed56ad17f223294e2a680", "item": "skill_candy_i", "count": 0, "receipt": false, "learn_flag": "", "learned": false, "recipe": "", "recipe_known": false, "resident": true } |
| 15 | 1 | water_pocket_claim — guest claims its own candy | PASS + {"gained":1.0} | PASS | water:lantern_cove:pickup:002: +1 skill_candy_i receipt=true recipe_known false -> false resident_after=false |
| 16 | 0 | water_pocket_resend | PASS + {"code":"already_taken","committed":false} | PASS | water:lantern_cove:pickup:002 resend: code=already_taken committed=false count 1 -> 1 |
| 17 | 1 | water_pocket_resend | PASS + {"code":"already_taken","committed":false} | PASS | water:lantern_cove:pickup:002 resend: code=already_taken committed=false count 1 -> 1 |
| 18 | 0 | capture_saves | PASS | PASS | host (world + character): autosave_here()=true, character 'character-812e6ecf234bf7a3d5cbef50f5d448dd' on disk=true; copied 3 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F13-2-reed/peer-0/after |
| 18 | 1 | capture_saves | PASS | PASS | client (character only): autosave_here()=false, character 'character-6129a244214ed56ad17f223294e2a680' on disk=true; copied 1 files to /tmp/claude-0/-home-user-Tetherbound/6050aa73-5362-5e48-a427-17c5687ec66b/scratchpad/proofs/F13-2-reed/peer-1/after |
| 19 | 0 | check_saved — host's saved character holds its own recipe and receipts | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-812e6ecf234bf7a3d5cbef50f5d448dd/character.json"] under after/characters |
| 20 | 1 | check_saved — guest's saved character holds its own recipe and receipts | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/character-6129a244214ed56ad17f223294e2a680/character.json"] under after/characters |
| 21 | 0 | check_saved — the world records one receipt per character per pocket; the recipe is not world state | PASS | PASS | missing []; unexpectedly present []; read ["redesign-v28/slot-0/world.json"] under after/worlds |

## Captured files

- `peer-0/after/characters/redesign-v28/character-812e6ecf234bf7a3d5cbef50f5d448dd/character.json`
- `peer-0/after/saves/redesign-v28/slot_0.json`
- `peer-0/after/worlds/redesign-v28/slot-0/world.json`
- `peer-1/after/characters/redesign-v28/character-6129a244214ed56ad17f223294e2a680/character.json`
