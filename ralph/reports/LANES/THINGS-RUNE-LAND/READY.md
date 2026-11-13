# THINGS-RUNE-LAND: Trainer Rune stands where the player can reach him

STATUS: land

- **Branch:** `tb/things-rune-land`, cut from `origin/main` 317b3372.
- **Kind:** correctness fix, no GPU verdict (coordinator's message, 13 Nov).
- **Fault (GPU lane, reproduced on CPU):** Rune's Tidewake conversation never engaged the conversation camera. The dialogue capture logged `refused: no stand beside the body (6.9 m)` and Rune was in no frame, at his post or in the conversation.
- **Cause (CPU terrain probe round his body):** his Gull Rest offset (6, 0, -20) put him on a steep sand face. Within 10 m the ground fell 12 m on the seaward side and rose 5 m on the other; no spot 2 to 4.4 m from him was within 2.5 m of his own height.
- **Fix:** `data/config/water_characters.json`, Rune's `island_local_offset` (6, 0, -20) to (-2, 0, -12): the flat top of the same dune, about 11 m away. Probe at the new spot: the ground within 4 m is within 1 m of his height. Config only, no code.
- **Shown:** the same capture now logs `DLG_SPEAKER ... near` and frames him (`_sheet_rune_conversation_cpu.jpg`). "near" means the catalogue post is within 4.5 m of him, so he is reachable from where the player arrives.
- **Tests:** new `tests/test_water_rune_stand.gd` (2 tests: the offset, and not back within 8 m of the old spot). Run with `test_near6_tw_judged_on.gd`: 10 tests, 0 failed.
- **Not run:** a full fight with Rune from the new spot, and the Tidewake smokes (too long for a CPU turn). The fight starts from the same body, so it moves with him.
- **Left as is:** `water_npc_posts_candidate.json offsets_unjudged.water_trainer_rune` (-3, 0, -20), an earlier lane's untried override for the same fault. It is inert and now unnecessary.
- No `.uid` files are included.
