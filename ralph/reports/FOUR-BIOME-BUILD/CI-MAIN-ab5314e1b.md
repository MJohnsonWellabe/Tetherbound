# Main ab5314 exact-head CI review

Head `ab5314e1b081b018decc17d070fba85ee3afd210`, the PR95 merge of reviewed
`2a971cb3a2a232e0bdb4e89f4613f878b58fa24b`. Reviewed-head ancestry and identical
tree were verified before this run was credited.

Run `34346697696`, attempt 1, completed successfully on 2026-09-09:
11:39:11–12:08:07 UTC. All-attempt API metadata lists 29 jobs: 27 successful
and two configured optional known-red campaign skips. All 27 executed job logs
were read in full and retained under `.artifacts/main-ab5314-ci/job-*.log`
(10,395,168 bytes on disk). `final-all-jobs.json` retains the job/step inventory.
No workflow rerun or smoke retry was used.

The four unit shards total 3,076 tests and 487,614 assertions, zero failures.
All 37 discovered network smokes passed on their first invocation. The four
native earned-aim cases passed 19/8/5/8 checks with empty failure arrays and
clean native-error scans. Seven release-reference helper tests passed and the
solo regression fence held.

The main export job `102456094406` also passed. Its complete raw log contains
1,224,528 characters, with no native or script errors. The packaged runtime
reported `EXPORT-CHECK terrain=yes ground_at_spawn=0.90 player_y=2.90
props=383004` at 12:07:22.5250942 UTC.

Native-error review compared the complete executed logs against retained main
4830 and PR92 signatures. Known ObjectDB/resource shutdown diagnostics remain;
this is not a claim of error-free output. The regions shard reported four
resources after `smoke_art.gd` at 11:59:44.691, versus two/three in the immediate
baseline; evidence also repeats the three-resource shutdown signature already
retained from PR92. Counts vary within the known shutdown class, with no new
distinct native/script condition identified. Gate B and Water Alpha shutdown
comparisons are retained in `CI-PR95-GATE-B-LEAK-COMPARISON.md`. The distinct
PR94 `recv_nodes` unauthorized-despawn condition is absent here; PR94 remains
held on its separate branch.

Release verification is separate: `RELEASE-MAIN-ab5314e1b.md`. Neither this
CI pass nor publication establishes a new visual verdict, hardware playtest,
earned campaign completion or Beta Ready acceptance.
