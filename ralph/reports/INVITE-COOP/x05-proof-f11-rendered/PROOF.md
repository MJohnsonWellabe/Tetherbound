# Two-peer proof: F11: eligible peers accept/refuse the Stormheart independently

Scenario: `/home/user/x05-ledger/tools/net/proof_scenarios/f11_stormheart_accept_refuse.json`  
Run: `net-20260925T145921Z-11119`  
Rendered: yes

ACCEPTANCE F11, 'eligible peers accept/refuse independently': both players fought the Dynamo; the host says Yes and keeps its own Stormheart, the guest says No and keeps nothing; each answer is its own world receipt and neither affects the other. Setup stands in for PLAYING the Dynamo fight only (contributors + Marrow's defeat flag through the ledger); the release, offers, dialogue answers, grants and saves are the game's own code.

| # | Peer | Step | Verdict | Detail |
|---|---|---|---|---|
| 1 | 0 | load_save — named save: Meadows, Stormwood route open | PASS | loaded host_meadows_stormwood_route_open.json.gz into slot 4; realm 'meadows' booted as 'world' |
| 2 | 1 | boot — guest: a fresh trainer in the Meadows | PASS | booted world (240 settle frames) |
| 3 | 0 | host | PASS | hosting udp/32621 as peer 1 |
| 4 | 1 | join | PASS | joined 127.0.0.1:32621 as peer 1401031376 after 11 frames; snapshot applied; 2 peer(s) in registry |
| 5 | 0 | expect_peers | PASS | registry reports 2 peer(s) after 0 frames |
| 5 | 1 | expect_peers | PASS | registry reports 2 peer(s) after 0 frames |
| 6 | 0 | wait_flag — the route comes from the host's save | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 6 | 1 | wait_flag — the route comes from the host's save | PASS | flag realm_gate_stormwood_unlocked (any) set after 0 frames |
| 7 | 0 | enter_realm — host first: its shell builds inside its own step | PASS | crossed 'meadows' -> 'stormwood' after 488 observed physics frames / 46059 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 8 | 1 | enter_realm | PASS | crossed 'meadows' -> 'stormwood' after 506 observed physics frames / 30455 ms (budget 6000 physics frames); current scene is /root/Stormwood |
| 9 | 0 | screenshot | PASS | captured 960x540 -> peer-0/01_both_in_stormwood.png |
| 9 | 1 | screenshot | PASS | captured 960x540 -> peer-1/01_both_in_stormwood.png |
| 10 | 0 | capture_saves | PASS | host (world + character): autosave_here()=true, character 'legacy-slot-4' on disk=true; copied 5 files to peer-0/before |
| 10 | 1 | capture_saves | PASS | client (character only): autosave_here()=false, character 'character-eb3a4081b5cca2b81a85bb8d0c71629e' on disk=true; copied 1 files to peer-1/before |
| 11 | 0 | stormheart_fixture — both fought the Dynamo (setup) | PASS | Dynamo contributors [1, 1401031376]; committed ["stormwood:act_ii_complete", "stormwood:marrow_defeated"] |
| 12 | 0 | wait_flag | PASS | flag stormwood:legendary_freed (any) set after 0 frames |
| 12 | 1 | wait_flag | PASS | flag stormwood:legendary_freed (any) set after 1284 frames |
| 13 | 0 | stormheart_answer | PASS | answered accept after reading 3 earlier line(s) and 3 offer line(s); captured 960x540 -> peer-0/02_host_offer_yes_no.png; claim settled=true; party holds the S |
| 14 | 1 | stormheart_answer | PASS | answered refuse after reading 3 earlier line(s) and 3 offer line(s); captured 960x540 -> peer-1/02_guest_offer_yes_no.png; claim settled=true; party holds the  |
| 15 | 0 | wait_flag | PASS | flag stormwood:legendary_resolution:accepted:legacy-slot-4 (any) set after 0 frames |
| 15 | 1 | wait_flag | PASS | flag stormwood:legendary_resolution:accepted:legacy-slot-4 (any) set after 0 frames |
| 16 | 0 | wait_flag | PASS | flag stormwood:legendary_resolution:refused:character-eb3a4081b5cca2b81a85bb8d0c71629e (any) set after 0 frames |
| 16 | 1 | wait_flag | PASS | flag stormwood:legendary_resolution:refused:character-eb3a4081b5cca2b81a85bb8d0c71629e (any) set after 90 frames |
| 17 | 0 | stormheart_state — host kept its own | PASS | { "character_id": "legacy-slot-4", "party": ["fulgocobra"], "has_stormheart": true, "freed": true, "world_accepted": true, "world_refused": false, "accepted_anywhere": true } |
| 18 | 1 | stormheart_state — guest refused, nothing granted | PASS | { "character_id": "character-eb3a4081b5cca2b81a85bb8d0c71629e", "party": [], "has_stormheart": false, "freed": true, "world_accepted": false, "world_refused": true, "accepted_anywhere": false } |
| 19 | 0 | screenshot | PASS | captured 960x540 -> peer-0/03_after_answers.png |
| 19 | 1 | screenshot | PASS | captured 960x540 -> peer-1/03_after_answers.png |
| 20 | 0 | capture_saves | PASS | host (world + character): autosave_here()=true, character 'legacy-slot-4' on disk=true; copied 5 files to peer-0/after |
| 20 | 1 | capture_saves | PASS | client (character only): autosave_here()=false, character 'character-eb3a4081b5cca2b81a85bb8d0c71629e' on disk=true; copied 1 files to peer-1/after |
| 21 | 0 | check_saved — host's saved world holds both answers | PASS | 2 file(s) under after/worlds; missing []; unexpectedly present [] |
| 22 | 0 | check_saved — host's saved character keeps its Stormheart | PASS | 1 file(s) under after/characters; missing []; unexpectedly present [] |
| 23 | 1 | check_saved — guest's saved character refused and holds none | PASS | 1 file(s) under after/characters; missing []; unexpectedly present [] |
| 24 | 1 | check_saved — guest's pre-offer save held no answer (non-vacuous baseline) | PASS | 1 file(s) under before/characters; missing []; unexpectedly present [] |

## Captured files

Committed subset (X05 evidence): PROOF.md, the six PNGs, every saved character file and the host's saved worlds, gzipped; the raw slot copies and net logs stayed on the run machine.

- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/boot_log.txt`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/cache/map_meadows.png`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/cache/map_meadows.png.key`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/characters/legacy-slot-4/character.json` (committed gzipped)
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/logs/godot.log`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/saves/slot_0.json`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/saves/slot_4.json`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/CanvasShaderGLES3/3cec09c32c9ddfee4bc21a437c9e4653569ca7f2a6dd7752dbd325460a8c3861/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/CopyShaderGLES3/ae131b3fcfed844d50383433810f1cf75c3686de2d84cf09e4b239151b1a6d4b/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/CubemapFilterShaderGLES3/e2d5ec8a84c2212c63e5e83d18abdd31109cd11b5ced9df2f30a25259e61866f/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/FeedShaderGLES3/344f92a73367d452cee1cac41b916e2f5a2b8853c2905454db295897ce883dda/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/ParticlesCopyShaderGLES3/480dc25af85039433727887209e11b4739e3515652aadb7960e9282942209a10/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/ParticlesShaderGLES3/9e42dbb5f431a59c14fc6084eaed987caa36555d43094b2b74352a6aa53ff6b6/55c54c113986b4fe18ab9ced2d41538fc5092ca6.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/PostShaderGLES3/271b0f9bd2f1a73711f5c60617149ce82edb8a70dec90d5a01822b0654051c0c/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/0143f5ea411f3d8a6a366c3d137112d572298aa5.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/0b52136668b1404e52bde3d36f3e5567e3a45a0b.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/0deb7674b101eae2d9d03a11aa119ebfe1a92001.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/1c391b2d44274649404846aed0752d6dc54823a3.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/1ec0123743a4d1cc73e25ebb40fa89572262e3b6.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/2538683fa8467cf2b3f51fbb18d63ff00f32f1b4.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/312ad42a7fd06585fad3eca6bb0eef83490b1da7.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/3722845ebb7d8536e1b159ed3e4643a6c4c96bae.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/4612e0cbcd25afc471b5406379b69efdd9fdc115.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/46256a5e5dd61baf8b9c471f97388e1b26f8f4d7.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/55be1b5afeb3e1187141768ab01c3b9c2b27fe95.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/5f15b88669216068b01e09ab1c9e9f1fd47781eb.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/6a0938a9a0fc1fd50d0db66009eca4d3fe324bcc.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/6c6b6820b4fba4f76c5ec92d0d37d87bf3d38765.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/75dbda390b4d6b8d1bba67e8943ace8a4f64f756.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/7610c7e24170c9ff2ef8d8f3a542d89520b2e49f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/77047cd41f429f33ceff24e890e174f5465e755e.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/79b92e0eaa374b797c1f1f9b8c3da44c004d72ba.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/7b0606ca573c4619080b2a789e9af0a5d049d9ce.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/7ef334d65fa65790fe4ba9a537dff0b6721ef8ca.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/84366ed46520476083c6b869fefb772ed1a067ee.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/8aa2ca0d142139a382e42dd317881cf2ee88335d.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/928cabbe1c59c1025608a336089807ac84403089.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/9d42c89d3306ba93ffd60acfba04b21930702e6f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/a1459696a9e31a872ec14fb0f93859e719347842.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/a337fd395264406b70bc21432ea1a85b0fce4b96.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/a8777be15f781463e27cb3b841a738f050b8c925.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/ac12777c441a90c018176d0c6c714f5788b3f460.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/b041643a643abf05307e9fac0e55811db7c17d4f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/bd3ec329b8d412569093905d27cab3f30a500a45.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/c175a238af09034d3ceac0d9fc75d1bf0cd75616.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/cff41c46c9761fadeb31bdac88c7af1296f3e20b.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/d66cd92dcecb8b97995d48d1fa89044f76b80ccf.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/de225c33839522f11071e04ddecdf3090bec4d4f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/e1afe3ef17914403530b340f9c0b60998a3f9bd4.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/f00cbd7a1b5573406fd43d486793e520640b1325.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/f2e328ac8a780a17a0c65e242b0c8bc4fc063f03.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/f3898120a1b86c86cb0b128ae6a563c539a13e3f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/fd744a1bea6f245ae70b98c015fadf5b25954c68.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SkeletonShaderGLES3/dedb1762060a36b4ce7fc096ed8a270c1ffa4dd226663bfbeaac172da0eb9b2e/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/shader_cache/SkyShaderGLES3/efe3d64b0aec36a8c302e8a977e0698caae056811fa3b8c8cd920d6da4c7b890/da1b7da2ee3464a48514015c41474f7d92626b72.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/worlds/legacy-slot-4/world.json` (committed gzipped)
- `net/net-proof_two_peer-20260925T145921Z/home-0/godot/app_userdata/Tetherbound/worlds/slot-0/world.json` (committed gzipped)
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/boot_log.txt`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/cache/map_meadows.png`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/cache/map_meadows.png.key`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/characters/character-eb3a4081b5cca2b81a85bb8d0c71629e/character.json` (committed gzipped)
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/logs/godot.log`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/CanvasShaderGLES3/3cec09c32c9ddfee4bc21a437c9e4653569ca7f2a6dd7752dbd325460a8c3861/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/CopyShaderGLES3/ae131b3fcfed844d50383433810f1cf75c3686de2d84cf09e4b239151b1a6d4b/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/CubemapFilterShaderGLES3/e2d5ec8a84c2212c63e5e83d18abdd31109cd11b5ced9df2f30a25259e61866f/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/FeedShaderGLES3/344f92a73367d452cee1cac41b916e2f5a2b8853c2905454db295897ce883dda/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/ParticlesCopyShaderGLES3/480dc25af85039433727887209e11b4739e3515652aadb7960e9282942209a10/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/ParticlesShaderGLES3/9e42dbb5f431a59c14fc6084eaed987caa36555d43094b2b74352a6aa53ff6b6/55c54c113986b4fe18ab9ced2d41538fc5092ca6.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/PostShaderGLES3/271b0f9bd2f1a73711f5c60617149ce82edb8a70dec90d5a01822b0654051c0c/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/0143f5ea411f3d8a6a366c3d137112d572298aa5.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/0b52136668b1404e52bde3d36f3e5567e3a45a0b.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/0deb7674b101eae2d9d03a11aa119ebfe1a92001.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/1c391b2d44274649404846aed0752d6dc54823a3.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/1ec0123743a4d1cc73e25ebb40fa89572262e3b6.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/2538683fa8467cf2b3f51fbb18d63ff00f32f1b4.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/312ad42a7fd06585fad3eca6bb0eef83490b1da7.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/3722845ebb7d8536e1b159ed3e4643a6c4c96bae.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/4612e0cbcd25afc471b5406379b69efdd9fdc115.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/46256a5e5dd61baf8b9c471f97388e1b26f8f4d7.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/55be1b5afeb3e1187141768ab01c3b9c2b27fe95.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/5f15b88669216068b01e09ab1c9e9f1fd47781eb.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/6a0938a9a0fc1fd50d0db66009eca4d3fe324bcc.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/6c6b6820b4fba4f76c5ec92d0d37d87bf3d38765.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/75dbda390b4d6b8d1bba67e8943ace8a4f64f756.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/7610c7e24170c9ff2ef8d8f3a542d89520b2e49f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/77047cd41f429f33ceff24e890e174f5465e755e.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/79b92e0eaa374b797c1f1f9b8c3da44c004d72ba.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/7b0606ca573c4619080b2a789e9af0a5d049d9ce.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/7ef334d65fa65790fe4ba9a537dff0b6721ef8ca.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/84366ed46520476083c6b869fefb772ed1a067ee.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/8aa2ca0d142139a382e42dd317881cf2ee88335d.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/928cabbe1c59c1025608a336089807ac84403089.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/9d42c89d3306ba93ffd60acfba04b21930702e6f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/a1459696a9e31a872ec14fb0f93859e719347842.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/a337fd395264406b70bc21432ea1a85b0fce4b96.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/a8777be15f781463e27cb3b841a738f050b8c925.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/ac12777c441a90c018176d0c6c714f5788b3f460.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/b041643a643abf05307e9fac0e55811db7c17d4f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/bd3ec329b8d412569093905d27cab3f30a500a45.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/c175a238af09034d3ceac0d9fc75d1bf0cd75616.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/cff41c46c9761fadeb31bdac88c7af1296f3e20b.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/d66cd92dcecb8b97995d48d1fa89044f76b80ccf.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/de225c33839522f11071e04ddecdf3090bec4d4f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/e1afe3ef17914403530b340f9c0b60998a3f9bd4.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/f00cbd7a1b5573406fd43d486793e520640b1325.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/f2e328ac8a780a17a0c65e242b0c8bc4fc063f03.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/f3898120a1b86c86cb0b128ae6a563c539a13e3f.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SceneShaderGLES3/86b1238e7614d02f9099271ba308261ab33a1ba40d35f130d1c79783d6a111e3/fd744a1bea6f245ae70b98c015fadf5b25954c68.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SkeletonShaderGLES3/dedb1762060a36b4ce7fc096ed8a270c1ffa4dd226663bfbeaac172da0eb9b2e/6bb7c9a2fd1c4a8fa77cb96555b9b4a720209981.cache`
- `net/net-proof_two_peer-20260925T145921Z/home-1/godot/app_userdata/Tetherbound/shader_cache/SkyShaderGLES3/efe3d64b0aec36a8c302e8a977e0698caae056811fa3b8c8cd920d6da4c7b890/da1b7da2ee3464a48514015c41474f7d92626b72.cache`
- `net/net-proof_two_peer-20260925T145921Z/peer-0.log`
- `net/net-proof_two_peer-20260925T145921Z/peer-1.log`
- `peer-0/01_both_in_stormwood.png`
- `peer-0/02_host_offer_yes_no.png`
- `peer-0/03_after_answers.png`
- `peer-0/after/characters/legacy-slot-4/character.json` (committed gzipped)
- `peer-0/after/saves/slot_0.json`
- `peer-0/after/saves/slot_4.json`
- `peer-0/after/worlds/legacy-slot-4/world.json` (committed gzipped)
- `peer-0/after/worlds/slot-0/world.json` (committed gzipped)
- `peer-0/before/characters/legacy-slot-4/character.json` (committed gzipped)
- `peer-0/before/saves/slot_0.json`
- `peer-0/before/saves/slot_4.json`
- `peer-0/before/worlds/legacy-slot-4/world.json` (committed gzipped)
- `peer-0/before/worlds/slot-0/world.json` (committed gzipped)
- `peer-1/01_both_in_stormwood.png`
- `peer-1/02_guest_offer_yes_no.png`
- `peer-1/03_after_answers.png`
- `peer-1/after/characters/character-eb3a4081b5cca2b81a85bb8d0c71629e/character.json` (committed gzipped)
- `peer-1/before/characters/character-eb3a4081b5cca2b81a85bb8d0c71629e/character.json` (committed gzipped)
