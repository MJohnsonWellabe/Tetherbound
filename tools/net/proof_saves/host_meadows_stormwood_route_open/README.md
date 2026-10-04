# host_meadows_stormwood_route_open (declared-start proof save)

A **declared start**, not earned play (ACCEPTANCE §6.1 relaxed proof starts). Two-peer proof
scenarios load it with `load_save {"from": "tools/net/proof_saves/host_meadows_stormwood_route_open"}`.

**Provenance.** Built by `tools/net/build_proof_save_host_meadows_stormwood_route_open.gd` through
the game's own code: the title screen's fresh-identity helper, `Game.reset_for_new_game()`, a real
headless boot of the Meadows (the opening stages the trainer in Grandpa's bed and sets
`opening:beat:wake` itself), and `Game.save_game(0)`. The output is a genuine save at the current
version (slot, world and character all v28, under `redesign-v28/`), stored gzipped
(`proof_steps.gd` load_save inflates it). It replaces the hand-captured v27 save (last touched in
288abc24), which RD-35 refuses. That file was read only to describe its state; it was never
converted or migrated.

**Rebuild:**

    tools/net/build_proof_save_host_meadows_stormwood_route_open.sh

(`GODOT_BIN` overrides the default `~/godot-bin/godot`; needs an imported project.) The builder
was first run on source `5d10e6d73` (main 5d10e6d7 plus the builder). Two builds differ only in wall-clock
`created_at`/`last_played` and the day clock's elapsed seconds (frame timing).
`tests/test_proof_save_fixtures.gd` fails if this fixture stops loading at the current save version.

**State.** A day-1 trainer (`chosen_character` "trainer", display name "Trainer") in the Meadows,
in Grandpa's bed after the wake beat. Party, satchel, hotbar and equipment are empty, and the
Stormwood route is open as world flags. Portable vs world split (D100): the character holds only
`opening:beat:wake`; the world holds the two Stormwood flags.

**Disclosed state writes** (everything else is the production new game):

| Write | Value | Why |
|---|---|---|
| character id | `character-f41f4a49223483d6bfdf56715944bb7b` | scenarios assert it in `expect_data` (was the old save's id) |
| world reward namespace | `39191e30aa1d9fb699f1f8f2fde5042a` | deterministic world identity (old save's value) |
| world seed | `1423549592` | the seed the old save rolled, so wild population matches |
| world flags | `realm_key_stormwood`, `realm_gate_stormwood_unlocked` | stand in for earning the Stormwood key |
| player flag | `opening:beat:wake` only if the boot did not set it | the boot sets it, so nothing is written (receipt `wake_flag_injected: false`) |
