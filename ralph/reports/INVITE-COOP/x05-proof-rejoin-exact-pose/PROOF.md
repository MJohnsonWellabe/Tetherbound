# Three-process proof: a rejoin returns to the exact spot, but only in the same host world

**Verdict: PASS.** 25 checks passed and none failed (ALL CHECKS PASSED, exit 0). There were no SCRIPT ERROR lines on any of the three peers.

Owner ruling 2026-09-26, "rejoin returns to exact spot" (MULTIPLAYER Return-home placement): a rejoin to the same host world, meaning the host snapshot's instance matches the character's `last_world_instance_id`, restores the exact saved pose. Any other world keeps the authored regional spawn.

Base: `ralph/x05-rejoin-exact-pose` `325749b42`, which includes the review fix. The same run first passed on `5e130ba05`. Headless. One run on the committed code:

```
godot --headless --path . --script tests/smoke_net_rejoin_exact_pose.gd
```

## The change

- **`scripts/ui/title_screen.gd` `_begin_join`:**
  - It reads the character's saved pose and `last_world_instance_id` from its own character file (`rejoin_pose_candidate`).
  - It clears the live pose and a loaded slot's queued fly state (`pending_fly_load`) before the world builds, so no world ever places a pose saved somewhere else.
  - It mounts `RejoinPose`.
- **`scripts/mp/rejoin_pose.gd`:**
  - It waits for the host's handshake snapshot (`handshake_snapshot_applied()`), then calls `decide()`.
    - It does not use `snapshot_ready()`, which reads true again after a failed or cancelled attempt while the guest still holds its own world.
    - A join that ends without that snapshot frees the helper with no decision. A retrying join keeps it waiting.
  - `decide()` seats the saved pose only when both of these hold:
    - the snapshot's `reward_delivery_namespace` equals a non-empty saved instance;
    - the saved realm is the realm this guest is standing in, with a finite position.
  - After seating, it runs the scene's `enforce_sealed_placement` when the scene has one (Cloudreach).
  - Otherwise the world's regional spawn stays.
- **`tools/net/peer_runner.gd`:** a `rejoin_pose` probe reports the decision, where the world first placed the player, the world instance, and the character file's instance and pose.

## What the run shows

Setup: host A and host B are two worlds with two different instances. The guest (peer 2) goes through the production title every time.

1. **Setup in world A:**
   - The guest joins A as a new character.
   - It moves 53.2 m from its landing, to (-65.4, 7.6, -50.8).
   - It saves. Its character file names A's instance (`32ab4a4e…`) and that pose.
   - It leaves.
2. **Rejoin A through the title's returning route:**
   - A's world first places it at the regional spawn (0, 0.9, 0), 82.8 m away.
   - The snapshot instance matches, so the decision is `exact`.
   - **The guest stands 0.00 m from where it saved** (tolerance 1.5 m).
   - Host A sees it again.
3. **Join B as the same character:**
   - B's instance (`18b5458f…`) differs from A's, so the decision is `regional`.
   - The guest stands at B's regional spawn (0.00 m from where B's world placed it), 82.8 m from A's saved spot.

## Unit coverage

`tests/test_rejoin_pose.gd` has 6 tests and 21 assertions. Two of them fail on the pre-review helper. It covers:
- the helper waiting for the host's handshake snapshot, not deciding on a failed or retrying attempt;
- a join that ends without a snapshot seating nothing;
- the same instance;
- a different instance;
- an empty instance, a missing instance, and a snapshot without one;
- another realm;
- a non-finite or short position;
- a missing pose;
- reading the candidate from the character file.

The related title and identity suites pass: 23 tests.

## Not covered

- **A saved pose in a different realm from the one the guest builds.** On a machine that also has a slot-0 autosave, `_begin_join` builds the slot's realm. If the saved pose is in another realm, the decision is `regional` rather than a realm change. The world is built before the host is known, so switching realms after the snapshot would need a realm transfer.
- **The Cloudreach sealed-gate re-seat after an exact pose.** The code calls it, but this run is in Meadows.
- **Steam joins still apply the file's pose without checking which host's world it came from.** They go through `prepare_steam_character` and `_start_pending_steam_join`, not `_begin_join`, which is outside this grant. The fix is the same two calls: `_mount_rejoin_pose(game, rejoin_pose_candidate(game))` and clearing the pose before `_go_to_world`. The coordinator has the proposal.
- **A possible misreported outcome.** If a world placed its player after the snapshot (Stormwood builds asynchronously), the helper could report `regional` while the world's own later pose call seats the player at the exact spot.

Logs: `coordinator.log.gz`, `peer-0.log.gz` (host A), `peer-1.log.gz` (host B), `peer-2.log.gz` (the guest), `SUMMARY.md` (net run `local-3835843`).
