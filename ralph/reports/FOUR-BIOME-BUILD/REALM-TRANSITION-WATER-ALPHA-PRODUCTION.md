# Default Water Alpha production smoke — first-attempt pass

2026-09-09. Root granted one exclusive production-world run after the 81-check native component and 73-check tiny Game orchestration proofs. The unchanged `tests/smoke_net_water_alpha.gd` ran through its default Meadows-to-Water router path, **without `--water-only`**. Run ID `phase1-game73-water-0909-v1`; artifacts `.artifacts/phase1-game73-water-0909-v1/`.

Result: **28 checks passed**, `ALL CHECKS PASSED`, coordinator exit 0, elapsed **129.629713 seconds**. No retry. The 15 recorded Game/network/smoke/harness source hashes are identical before and after execution. All exact raw logs, isolated peer homes, source hashes and process/resource receipt are retained. All run-owned processes exited; subsequent CIM inspection found zero Godot processes.

## What the actual production run established

- Host and client built Meadows and joined through actual Session registration/snapshot application.
- The existing smoke's explicit Water key/gate flags replicated, and the client crossed via actual `Game.enter_realm`.
- Host remained in Meadows and built Water Alpha authority at the production `/root/WaterArchipelago/WaterAlpha` path.
- Client summoned the smoke's owned level-49 Mosshell fixture beside Alpha, then joined the real host encounter. No damage/result/Stone/completion fixture was supplied.
- Both peers referenced one encounter; host held authority while the client's local manager presented combat. HP and Alpha pose replicas agreed.
- The existing negative outcome message did not resolve Alpha or grant a Stone. A real host Alpha strike damaged the client's creature; an unfinished fight granted no Stone.
- Client left during combat through the production Session path. Host removed the participant, cleared the target/capture owner, and folded the now-empty Water shell into saved world state. The client wrote its character without a world file, as recorded by the peer log.

## Raw errors and warnings

Complete coordinator stdout/stderr, coordinator engine log and both peer logs were inspected. **Zero ERROR, SCRIPT ERROR or FAIL entries.** The unauthorized-despawn class that motivated this repair, and missing cached-node/synchronizer errors, are absent in this run. This is one clean production route, not proof that every multiplayer path is clean.

There are **32 known warnings**: two `instance_reset_physics_interpolation() is deprecated` warnings and 30 missing-terrain-mipmap warnings (13 total warnings on host, 19 on client). No novel warning class was observed. These warnings were retained and disclosed, not relabeled as errors or hidden by a rerun.

## Guard and process evidence

External world ceiling was **600 seconds**; the harness's tighter hello, heartbeat and step deadlines remained unchanged. The resource guard used **system commit percentage**, not physical-memory usage, and **total process count**, not a 400 MB free-memory floor. Maximum observed commit was **75%**, maximum process count **260**, below the 90%/400 stop thresholds throughout 182 samples. First unexpected raw error or failed assertion would have stopped the owned process trees.

| Process | PID | Parent | Peak working set |
|---|---:|---:|---:|
| Console launcher | 21008 | 19072 | 7.26 MB |
| Coordinator engine | 12136 | 21008 | 188.00 MB |
| Host engine | 4548 | 12136 | 1219.63 MB |
| Client engine | 3612 | 12136 | 1455.67 MB |

Ownership used the exact run marker and recorded actual descendants. All process handles report terminal; per-child exit codes are unavailable after exit, so only the confirmed coordinator exit 0 is claimed. No unrelated process was terminated.

## Remaining limits

This is production integration evidence for ordinary initial join, controlled client departure/admission, actual remote combat and disconnect cleanup. The flags, level-49 owned creature and encounter positioning are explicit test fixtures, not earned campaign progress. It does not establish a retained third player's real fight during crossing, rollback over actual transport, scoped late join after departure, client return travel, old host scene-rebuild compatibility, full exact-head CI, visual acceptance, complete multiplayer or Beta readiness. The shared draft remains uncommitted/unshipped; root owns isolation, review and the remaining validation gates.
