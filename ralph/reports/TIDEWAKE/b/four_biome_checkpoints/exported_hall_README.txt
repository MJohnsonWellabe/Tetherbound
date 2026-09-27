Four-biome checkpoint 'hall' at boundary 'hall' (reached=warden_arena_entered), written by
tests/smoke_four_biome_continuous.gd at commit 26e5e26f76136833171f0b12b3b2cb28c2e523ef, world seed 1393508821.

save/      = the game's own save directory after Game.save_game(1) at this
             boundary (slot 1 is the chain slot, as in seed4_hall).
receipts/  = per-boundary receipts (party, flags, seed, commit, elapsed).

Resume the earned run from here (next segment: warden):
  godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- \
    --resume-from=<this dir>:hall [--stop-at=<boundary>] [--checkpoint-dir=<dir>]

Produced by tests/smoke_four_biome_continuous.gd through earned play only: no fixture, seeded progress, flag/party/inventory write, teleport or HP pin in the run path. This piece resumed from checkpoint '/tmp/claude-0/-home-user-Tetherbound/d8bada2c-a58e-5610-90d4-afb3e7b2f9c8/scratchpad/cps/a/hall' at boundary 'hall' through the production title Load; its earlier pieces are described by the carried receipts.
