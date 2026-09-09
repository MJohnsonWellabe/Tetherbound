# Stormwood finalized-death network regression

## Bounded execution brief — 2026-09-09

The focused Varga diagnosis found the human at the recovery camp while the
trainer roster and local combat remained active. This regression isolates the
remote finalized-death lifecycle after its production repair. It does not replay
a chapter or claim Varga/campaign acceptance.

Run `tests/smoke_net_stormwood_finalized_death.gd` once with two real Godot
processes and fresh isolated profiles. The host stays in Meadows; the client
receives only Stormwood entry flags and one level-99 Terrapup, stages beside
Tamsin, and requests the authored hosted fight. The elevated ally level isolates
the death timeout from ordinary ally knockout. The existing `go_down` command
sets human health to zero and emits the real lethal signal. No attacks, opponent
damage, time scaling, revival deadline changes, or earned-progression claims.

Required observations: the remote identity remains a fighting participant during
the normal revival window, including near expiry; normal expiry finalizes one
death; local combat ends; host authority removes that identity; later snapshots
do not restart combat; no trainer win/reward flags appear. The native synthetic
lifecycle smoke separately covers another participant continuing and death
between rounds.

Native parse passed before execution. The full-world execution has a 600-second
external bound, exclusive full-world lease, 90% system commit and 400-process
ceilings. Resource guard stops only the launched process tree. One failure is
retained and diagnosed; no automatic retry. Full exact-head CI including all
network shards remains required before landing.

## Result

First execution **passed 28 checks**, without retry. Payloads retained locally at
`.artifacts/net-finalized-death-20260909/`: `net/NET_RUN.json` has empty failures
and fatal fields, `net/SUMMARY.md` says ALL CHECKS PASSED, and the console records
all lifecycle assertions. Source was production `3384f2825` plus the new net test
and probe guard. The two subsequent review corrections are not credited to this
earlier run; final exact-head CI must exercise them.

The test observed the ordinary 45-second downed window and one expiry, retained
host membership near expiry, cleared local combat and host membership afterwards,
and remained inactive across later snapshots. Host world flags were unchanged.
The host stayed in Meadows. No earned Varga or campaign completion is claimed.

The observer now checks raw opponent validity before casting, because a finished
fight remains in the hub after its opponent is freed. It also exposes actual
roster participants separately from record participants.

Run duration was 04:53:05–04:56:25 UTC, about 200 seconds. Maximum sampled system
commit was 71.60%, process count 271, owned private bytes 4,673,265,664. No resource
stop occurred; all owned Godot processes were absent afterwards. The Windows
console launcher did not retain an exit code (`null` in wrapper JSON), so the
pass is based on the terminal harness receipt and assertions, not a claimed
process exit code.

Both complete peer logs were inspected. No SCRIPT ERROR occurred. Their four
normalized native error kinds are the already-recorded multiplayer teardown set:
missing trainer node, failed cached-node lookup, invalid packet requesting a
missing node, and invalid/non-authority synchronizer delta. Dynamic peer ID here
was 169440346. Compare `CI-MAIN-8c0bfb31a.md` and the PR92 review retained on the
release repair branch. Existing missing-mipmap and interpolation-deprecation
warnings remain. This is not a clean-engine-log claim.

Review identified two additional edges: withdrawn peers must still observe a
survivor's nonparticipant snapshots, and death during pending challenge admission
must cancel that admission. Commit `9fa41dc26` corrects both; its expanded native
lifecycle regression passed 37 checks with no engine errors or warnings.

The named `smoke_playground.gd` pre-push world boot completed with `smoke: OK`
at `.artifacts/varga-repair-worldboot-20260909/`, 04:56:53–04:58:04 UTC. Terrain,
movement, gathering, the held-tool chop impact, inventory and farming assertions
ran. Its only distinct native ERROR was the existing `Parameter "material" is
null`; no SCRIPT ERROR occurred. Known mipmap warnings remain. Peak sampled
commit was 61.85%, 264 processes, owned private bytes 2,204,409,856; no guard stop,
all Godot processes absent afterwards. The same launcher exit-code limitation
applies. Full exact-head CI, including all network shards, remains required.
