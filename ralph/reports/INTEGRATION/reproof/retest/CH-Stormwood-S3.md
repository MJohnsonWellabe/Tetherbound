# CH-Stormwood-S3 — Two peers: Arches, Dynamo, Stormheart offers through disconnect

**Verdict: ERROR (blocked: v27 start save; v28 re-run interrupted)**

Shares its runs with F11#2 (see F11-2.md). Both x05 Stormheart drop-at-ack proofs stopped at step 1 on the v27 proof save (RD-35 refusal). Of the v28 re-runs, drop_at_ack was interrupted by a container restart, and refuse_drop_at_ack was not re-run. The Arch half has a v28 PASS in F09-4.md (52/0). Stormheart at capacity has a real v28 FAIL in F11-1.md: the guest who releases a belt member never gets their accepted receipt. The S3-specific scenarios (`x05_s3_stormwood_shared_state`, `stormwood_s3_integrated_two_peer`) were queued but not run before the lane was retired.

Note, as the action asked: `tests/smoke_net_stormwood_stormheart_offers.gd` exists but is unfinished. It is not a two-peer witness for this card yet, and it was not run.
