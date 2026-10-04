# Fixture regeneration: host_meadows_stormwood_route_open at v28

Lane `tb/fixture-regen`. Local loopback runs on Linux, Godot 4.7-stable, headless. This is local evidence only, not internet or Steam acceptance.

## What changed

- `tools/net/proof_saves/host_meadows_stormwood_route_open/` was a hand-captured save: slot v27, world v2, character v6. RD-35 refuses it, so every scenario that loads it stopped at step 1 with `Game.load_game(0) refused`. It is replaced by a genuine v28 save (slot, world and character all v28, under `redesign-v28/`, gzipped) that `tools/net/build_proof_save.sh tools/net/proof_save_specs/host_meadows_stormwood_route_open.json` builds through the real new-game and save code. The v27 bytes were read only to describe their state; they were never converted.
- The old save's semantic content, which the new one reproduces:
  - a fresh day-1 trainer in the Meadows after the wake beat;
  - **no party**, an empty satchel and hotbar, and no Meadows completion flags;
  - world flags `realm_key_stormwood` and `realm_gate_stormwood_unlocked`;
  - player flag `opening:beat:wake`.

  The task brief expected five creatures and Meadows completion flags; the old save had neither.
- Disclosed writes (fixture README): the pinned character id (asserted by 17 scenario steps), the world namespace, world seed 1423549592 and the two world flags.
- `tests/test_proof_save_fixtures.gd` (2 tests, 13 assertions, PASS) fails if the fixture stops loading at the current `VERSION`.

## Two-peer proofs (`tools/net/run_two_peer_proof.sh`, run on commit 2399329b fixture content)

| Scenario | Past step 1 | Verdict |
|---|---|---|
| stormwood_host_crossing_after_guest_rejoin | yes | PASS (17/17) |
| f11_stormheart_accept_refuse | yes | PASS |
| stormwood_f11_mirror_clean_health | yes | PASS |
| f15_homecoming_credits_reload | yes (steps 1–11 PASS) | FAIL at step 12 `ending_state`: `currents_restored` false and the tracked objective is `opening_hear_grandpa`. The scenario sets the Tidewake flag `water_currents_restored`, but `scripts/story/regional_homecoming.gd` `WORLD_FLAG` is now `stormwood:stormheart_freed` (RD-22 moved the homecoming to Stormwood). The scenario has drifted; the fixture is not the cause. |

After the spec-driven rebuild (611f8d70), `f11_stormheart_accept_refuse` was re-run on the final fixture: PASS (`proofs/f11_stormheart_accept_refuse_on_611f8d70.md`). Per-run PROOF.md files are in `proofs/`.

## Other committed fixtures older than v28 (tools/, tests/fixtures/)

| Fixture | Version | Class | Action |
|---|---|---|---|
| tests/fixtures/earned_saves/c1_arrival | v27 | earned (F49) | left alone |
| tests/fixtures/earned_saves/checkpoints/c1_flight_trained | v27 | earned (F49) | left alone |
| tests/fixtures/earned_saves/checkpoints/seed4_hall | v27 | earned (F49) | left alone |
| tests/fixtures/f03_lure_saves/*.json.gz (9 files) | v15/v16 single-file | declared-start, **unused**: no proof scenario, CI job or run_tests test loads them; only the manual `tests/capture_activity_lures.gd --save=` capture tool accepts one | left alone, not deleted |
| tests/fixtures/f48-producer-seeds | v28 | current | none |
| data/schema/fixtures/v27_save.json | v27 | migration history: `test_save_redesign.gd` loads it to prove the refusal | left alone |
