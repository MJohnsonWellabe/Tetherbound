# F08#3 land branch: settlement life ON (tb/cloudreach-land)

Rebuilt 22 Oct ~20:10 CT as one commit on origin/main a4f8a6b7: the diff of tb/cloudreach ef2db84c (judged r17 source) without the unreferenced Meshy folders (aviary hero shell, arch bridge, curtain arcade, cliff shelf edge, hanging lantern post, stilt house) and without the F40 items candidate (its config change, aerie perch, aviary drum ring v2 and belvedere tower, reference drafts and floor-strip tool). Those come with their own land. Changes on top: `data/config/cloudreach_settlement_life.json` `enabled: true`; new focused test `tests/test_cloudreach_settlement_life.gd`; `tests/test_cloudreach_galefoot_waycamp.gd` now asserts the lantern line against the effective setting (7/6/1 when on, none when settlement life removes it, because its pole split the hearth camera; the judges flagged it).

Judged: r17 mapped 7.13 vs control 6.15 (CPU Low/Compatibility, weather pinned; evidence on branch tb/cloudreach: `ralph/reports/CLOUDREACH/close-1022/f08-3/r17/`). CPU-provisional (≥ 6.7). GPU confirmation pending (the coordinator queues it).

Proofs, 22 Oct 2026 ~16:00–17:10 CT, headless CPU, this branch, flag ON by config:
- Unit (`tests/run_tests.gd --only=cloudreach_settlement_life,cloudreach_cliffhold_detail,cloudreach_production_integration,galefoot_waycamp,cloudreach_cast_dialogue,resource_node_reach,waycamp_shelter,cloudreach_camp_recovery`): 39 tests, 1880 assertions, 0 failed. Before the waycamp test update: 1 failure (lantern counts expected 7/6/1, got 0, from the intended removal).
- `smoke_cloudreach_production_integration`: PASS, failures=0.
- `smoke_cloudreach_route_blockers`: PASS (B1–B6 reached, 0 detours).
- `smoke_cloudreach_arrival_walk`: OK, player (-275.1, 180.0, 517.5).
- `smoke_cloudreach_camp_recovery`: PASS.
- `smoke_cloudreach_ground_truth`: PASS, 42250 samples, 0 holes, 38 mismatches (main without the flag: 37).
- `smoke_cloudreach_persistence_tail`: PASS, 5 members, 0 differences.

Rebuild check (same proofs re-run on the rebuilt tree): see below.

Note: on the coordinator's review run, `smoke_cloudreach_route_blockers` leg B2 stalled once (the encounter director held movement near the ravine_wind wilds at (-738.9, 686.6, 3642.0)) and passed on rerun. The stall is intermittent and not tied to this flag; it is recorded here, not fixed in this land.
