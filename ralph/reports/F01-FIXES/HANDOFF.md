# F01 fixes: handoff

- **Branch:** `tb/f01-fixes`. The head is the commit that adds this file. Its parent is 41d455b7.
- **main merged:** e2fa5e4e. F18 had not landed when the lane stopped.
- **F01#4:** landing in PR #543, not covered here.

## Done and reviewed

### F01#6a part 1: host-first original starter for a co-op guest
- **Commits:**
  - d7950e5c: host-first install;
  - 2d69daf5: review fixes;
  - 557553cb: nickname cap;
  - 4699b311, 81869ae3, e6378ee3: bounded retry, below.
- **Review rounds:**
  1. CHANGES REQUESTED, then fixed in 2d69daf5.
  2. APPROVE (2d69daf5).
  3. The bounded-retry change went CHANGES REQUESTED → fixed (81869ae3) → APPROVE. e6378ee3 hardens one non-blocking point from that review.
- **Proof:** `smoke_net_meadows_identity_fresh_join --opening-together`, run alone on 2d69daf5: 156/156. Unit suites green; the last full run was 88 tests, 0 failed.
- **Evidence:** `f01_6a/README.md`, `f01_6a/opening-together-hostfirst-run.txt`, `f01_6a/opening-together-hostfirst-SUMMARY.md`.

### F01#6a part 2: a guest's dialogue gifts are host-delivered reward_grants
- **Commits:** 6c2ce186, plus the recursive scan and Nessa's gift in 2d69daf5.
- **Classification:** the table is in `f01_6a/README.md`.
- **Residual risk, accepted by the coordinator:**
  - Mira's and Tam's progression gifts are gated only by the once-per-character receipt.
  - Lane A (tb/f17) advises a host-world `requires_any` flag per give. Its notes: rows never compact, one item per entry, build rows inside `client_grant_sources()`.

### F01#6a stuck-pending (coordinator condition 3): DONE, still needs the live rerun
- **Behaviour:**
  - after `starters.admission_retry_after_seconds` (45 s, `data/config/opening.json`), the guest's automatic re-sends stop and the guest is told that Interact asks again;
  - the retry re-sends the request, re-runs the owner install, or re-adopts the host's staged card;
  - a stalled wait still finishes on the host's accept;
  - a terminal host refusal resets to the picker;
  - the host never stalls.
- **Code and tests:**
  - `game_state.gd`: `retry_original_starter`, `adopt_original_starter_instance`, `original_starter_admitted_now`;
  - `sequence_director.gd`: `_retry_original_starter_save`, `retry_starter_adoption`;
  - `tests/test_starter_install.gd`, `tests/test_original_starter_guest_commit.gd`.

## Not done: single tasks

1. **6a portals-on rerun.** After F18 lands: merge `origin/main` into `tb/f01-fixes` and resolve. The F18-owned files the lane touched are `scripts/net/session.gd` (the `_capture_roster_allowed` / starter hunks) and `autoload/party.gd`. Run:

   ```
   TB_NET_RUN_ID=<id> TB_NET_OUT_DIR=<dir> TB_NET_PEERS=2 godot --headless --path . --script tests/smoke_net_meadows_identity_fresh_join.gd -- --opening-together
   ```

   Run it alone, never beside another smoke. Proof: ALL CHECKS PASSED, plus the 6a unit suites (`--only=test_starter_install,test_original_starter_guest_commit,test_starter_choice_action,test_dialogue_give_delivery,test_merge_owner_passive_exact,test_den_groom_saved_transaction`). Then 6a can land.

2. **6b re-measure.** Wait for #543's perf fixes (97bea36d memo) and Lane A's owner_passive_sync work (send only inputs since the last ACK, cheaper apply and fewer save rounds). Then run `smoke_net_shared_boss.gd -- --tournament` three times, alone, with the TB_NET_* vars.
   - **Proof:** the quarter-final and semi-final guest joins bind; the semi-final reaches a verdict and the host leaves RESOLVING.
   - **If it still fails:** re-apply the local diagnostics (below) and compare with `f01_6b/README.md`.
   - **Last step, once green:** the `combat_round_reward` owner action, which the coordinator deferred until 6b is understood.
   - **Don't:** take the other lanes' fixes or raise timeouts.

3. **F01#3 night walk: done; the judge passed it, but barely.**
   - **Approved files, all four done:**
     - `data/config/village_npcs.json`: night light on Tam and Maren; Nessa moved to (60,10.6) facing 125;
     - `data/config/terrain_playground.json`: a "Practice Meadow Camp" trailhead, last in `paths.trailheads`;
     - band1 `harvest.json`: grass node 1023 moved to (16.5,-20.5);
     - `data/config/essence_nodes.json`: rock moved to (24,-33), offset (8,-5), route distance 5.139.

     There is also the `scripts/world/village_npcs.gd` hook and the new `scripts/world/villager_night_light.gd`. Commits: d2362512, 7bbc7653, 9ad7461a.
   - **Conditions, all met:**
     - the fill is soft, night-only and unshadowed, with no source and no red;
     - the rock moved only after the night3 frames confirmed it;
     - the F32 censuses pass, with the moved node's recorded distance updated;
     - `smoke_f32_material_sites --realm=meadows --essence --site=essence_meadows_ground_01` PASS.
   - **Final capture (9ad7461a):** PASS, 105 captures, visited=12.
   - **Fresh code-blind judge: PASS, but barely.**
     - Nessa and Maren are now GOOD.
     - The camp is reached YES, but its arrival frame is MARGINAL.
     - Tam is still MARGINAL.
     - Bram is MARGINAL because the camera clips into the ceiling.
     - Details are in `f01_3/README.md`.
   - **Optional next step if a stronger pass is wanted:** add a config-only `night_light` override on Tam (more energy, offset toward the camera). Move the camp sign into the arrival view; it is at (22.5,-22.4) with its arm on the fire at (26.8,-26.6). Then re-capture alone (about 80 minutes) and re-judge. The camera and indoor issues belong to F21/F38.

## Must NOT land on its own
- **11880d39** ("a guest commits its own original starter"). It is the replaced local-first design. d7950e5c reverts its semantics inside this branch, so landing the branch as a whole is fine, but never cherry-pick 11880d39.
- **WIP commits:** d2362512, b166edcd, c93aecd9, ca91de91 and 81e27a57 are superseded or completed by later commits on the branch. Don't cherry-pick them alone.

## Known traps
- **Net smokes:**
  - `run_net_smoke.sh` doesn't forward flags; use the TB_NET_* env vars directly.
  - Two smokes on this 4-vCPU box starve each other: hello timeouts, late joins, and dialogue presses landing late.
- **Diagnostics:**
  - Local diagnostic patches were never committed: dialogue/arbiter, passive, engage timing, per-callback profiler, pending_vitals.
  - Re-create them from the descriptions in `f01_6b/README.md`; don't commit them.
  - Never kill by a `pkill -f` pattern that matches your own shell.
- **The `--from-title` capture:**
  - It is required. Without it the walk sticks at Grandpa's wall.
  - It takes about 80 minutes, and a capture beside other Godot processes gets OOM-killed (exit 137).
  - Disk is tight (about 3 GB free); use `--depth` fetches.
- **Owned files:** session.gd and portal code belong to F18, shared_boss staging to F22, owner_passive_sync to Lane A, actor_vitals to F27, and F32 resources to the perf lane and F32. Ask the coordinator before editing any of them.
