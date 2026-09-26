WIP checkpoint of the earned Meadows chain (seed TB_WORLD_SEED=4), saved so a fresh
session can resume without replaying segments 1-6. NOT the C1 arrival fixture.

save/      = the game's own save directory after segment `hall` PASSED (slot 1 is the
             chain slot). Restore by copying to the runner's --save-dir, then:
             tools/earned_saves/run_chain.sh 4 <dir> warden
receipts/  = per-segment receipts (flags, party, items, position, wall time) for
             opening_team, camp_tournament, bridge, warrens, relay, hall, warden (partial).
Blockers and disclosures: tools/earned_saves/BLOCKERS.md (B1-B13). Next: B13 (reach Kell).
