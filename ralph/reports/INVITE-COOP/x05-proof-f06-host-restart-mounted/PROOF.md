# Two-peer proof: F06#5 host restart while the guest is mounted (BLOCKED)

**Verdict: NOT RUN. The proof is blocked in setup, before any F06#5 row.** Runs `net-20260926T170929Z-3599` and `net-20260926T171645Z-6747` both stop at step 9 with an ERROR. Step 9 is the host (peer 0, solo, before `host`) running `enter_realm {realm: cloudreach}`. The coordinator reports "peer silent (peer 0, no heartbeat for >15 s)" when the step's 150 s world-build allowance (`tests/helpers/net_harness.gd` `WORLD_BUILD_ALLOWANCE_S`) runs out.

## It is not this scenario

Cloudreach's unchanged `tools/net/proof_scenarios/f06_cloudreach_mounted_rejoin.json` fails at the identical step 9:
- **on origin/main 79fe89048:** 150 s after the step starts. See `main-mounted_rejoin-timing.txt` (timestamps are UTC, from the coordinator's output) and `main-mounted_rejoin-peer-0.log.gz`.
- **on `ralph/stormwood-shared-net-fixes` d69b46bf5,** which this branch is based on: again 150 s after the step starts. See `stormwood-base-mounted_rejoin-timing.txt`.

In every run, the host's log ends at `[village_npcs] placed 11 of 11`, right after the `cloudreach_physical_runtime.gd:848` placement warning from `cloudreach_world.gd:398` `_ready`. Nothing more is printed. The step only awaits `Game.enter_realm` (`tools/net/peer_runner.gd` `_step_enter_realm`), and the harness teleport isn't involved. The machine is a 4-vCPU container. The first run overlapped local unit tests; the rerun and the mounted_rejoin control runs had no other Godot work.

Whether the host is hung or only slow, and which commit introduced it, is still open. It is reported to Cloudreach on #253.

## What the scenario asserts once Cloudreach entry works

`f06_cloudreach_host_restart_mounted_save.json`, 68 steps:
1. **Setup.** The guest's own world has the upper counterweight route open; the host's world has it closed.
2. **Save while mounted.** The guest joins and launches on its galecrest at the gate's legal side. While it is in the air, the guest writes its character and the host saves its world.
3. **Restart and reload.** The host's process restarts (`restart_peer`) and loads that save through the title's own Load (`title_load`). The guest rejoins through the returning route.
4. **Asserts:**
   - `party_uids equals` the same five UIDs, in the same order, kept in the guest's process;
   - on solid ground;
   - not inside sealed Upper Cloudreach;
   - back at its own spot;
   - the gate closed for host and guest and in the saved world;
   - the galecrest flies again.
5. **Control.** With the gate open, the guest comes back past it, which shows the negative check can fail.

Logs: `coordinator.log.gz` and `peer-0.log.gz` are from the rerun.
