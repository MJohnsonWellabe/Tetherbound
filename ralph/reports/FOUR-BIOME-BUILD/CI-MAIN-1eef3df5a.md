# PR96 main CI — all executed jobs reviewed

Main `1eef3df5a774e4fe4a2ba27751df24def522e2b7`, CI run `34358304662`,
attempt1: success, 13:37:53–14:05:34 UTC (27m41s). Of29 jobs,27 succeeded and
the two configured optional known-red jobs skipped. No rerun was requested.
All27 executed raw logs were retrieved and reviewed, retained as10,426,962 bytes
under `.artifacts/main-1eef3df5-ci/`, alongside final job metadata and comparison.

- Four unit shards:3,076 tests,487,614 assertions,0 failed.
- Seven multiplayer shards:37 distinct named smokes, each first invocation.
- Character runtime binding/cache proof:7 checks, no failures.
- Native aim/entry fixtures:19/8/5/8 checks, no failures.
- Required gameplay, region, UI, owner, scatter/terrain and solo aggregate jobs passed.
- Main export passed: terrain=yes, ground_at_spawn=0.90, player_y=2.90,
  props=383004; packaged-ground predicate reports `export: OK`.

This is not a raw-error-free run. Full comparison against reviewed PR head81504019d
retains the same unit negative-test errors, material-null errors and shutdown
resource/RID leak classes. Unit error counts and signatures match that head.
Gate-A/owner/regions shutdown resource counts vary; all are the same existing
shutdown class, with3/4-resource observations also present elsewhere in baseline.
Combat raw error count fell10→4, owner5→4, regions5→4, gate evidence17→16.
Network shard5 retains the same disappearing trainer/cache/invalid-delta sequence
with new dynamic peer id50824216. Shard2 retains two process-cleanup errors for
dynamic pid2819. No new SCRIPT ERROR or unauthorized-despawn recv_nodes condition
was found. Export has no engine ERROR or SCRIPT ERROR, only installed import
warnings. Existing defects remain separate work; job success does not erase them.

The reviewed PR head is an ancestor of this merge and the trees match. Release
publication is independently verified in `RELEASE-MAIN-1eef3df5a.md`. This closes
the narrow Arlo landing verification, not biome visual or Beta acceptance.
