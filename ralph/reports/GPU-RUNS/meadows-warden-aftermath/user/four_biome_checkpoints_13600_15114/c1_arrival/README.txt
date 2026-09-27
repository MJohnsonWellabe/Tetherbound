Four-biome checkpoint 'c1_arrival' at boundary 'c1_arrival' (reached=cloudreach_arrived), written by
tests/smoke_four_biome_continuous.gd at commit 212e036edca60d03ee7febcc5471fe8e4c05d944, world seed 1393508821.

save/      = the game's own save directory after Game.save_game(1) at this
             boundary (slot 1 is the chain slot, as in seed4_hall).
receipts/  = per-boundary receipts (party, flags, seed, commit, elapsed).

Resume the earned run from here (next segment: cloudreach):
  godot --headless --path . --script tests/smoke_four_biome_continuous.gd -- \
    --resume-from=<this dir>:c1_arrival [--stop-at=<boundary>] [--checkpoint-dir=<dir>]

Produced by tests/smoke_four_biome_continuous.gd through earned play only: no fixture, seeded progress, flag/party/inventory write, teleport or HP pin in the run path. This piece resumed from checkpoint 'res://tests/fixtures/earned_saves/checkpoints/seed4_hall' at boundary 'hall' through the production title Load; its earlier pieces are described by the carried receipts. That resume source is a repo-stored earned save (tests/fixtures/earned_saves), itself produced by earned play (see its README.txt).
