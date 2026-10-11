# F37#4 — riding and diving survive save/reload and a two-peer rejoin

Lane: systems-a (`tb/ev-systems-a`). Sun 11 Oct 2026, Godot 4.7-stable headless, Linux, two real ENet peers over loopback.

## Proof (first-ever run of the prepared scenario)
`GODOT_BIN=godot tools/net/run_two_peer_proof.sh tools/net/proof_scenarios/f37_ripplet_rejoin.json` on `a5c1b7e2` (11:41–11:45 AM CT) → **Verdict: PASS**, exit 0 (`PROOF-f37_ripplet_rejoin.md`):
- the guest mounts its owned Ripplet (no saddle) by the ordinary prompt and dives with a Jump tap in deep water near Lantern Cove (steps 6–11); the host's picture of the rider agrees (14);
- the guest's character is written to disk while mounted mid-dive, and the saved file carries the Ripplet, `aquatic`, `creature_uid` and the remaining dive budget (15–17);
- the link is dropped, the live character is blanked (so everything must come back from the DISK save), and the guest makes a returning production join (18–22);
- the ride is restored, the same character and Ripplet, swim mode 2 (24–25); the host sees the new peer id riding, its mount, swim mode and identity agree, nothing stale (26–29);
- reconnect seats at the surface with the saved dive debt, and a fresh Jump tap resumes the bounded dive (30–32).
Step 20 `leave` is an `any` step (no session after a dropped link), as the scenario expects.

## Failures found and fixed (smallest local changes)
1. Test helper (coordinator-approved 11:15 AM CT): `tools/net/proof_steps.gd::_rider_identity` required `mount_saddle_worn`. The Ripplet surface ride is saddle-less (SYSTEMS §171, WORLD §459), and this scenario asserts `saddle_count 0`. The check is now `(saddle worn or mount_species == "ripplet")`; every other agreement condition is unchanged. Before: `PROOF-f37-first-run-before-fixes.md` (FAIL at step 14 only on the saddle).
2. Game, `scripts/combat/water_encounter_director.gd::restore_swim_mount` (`dddfdce3`): it called `party.set_active(index)` on the already-active saved mount. During rejoin admission the owner fence refuses party writes (`Party._owner_mutation_blocked`), so the ride was never restored. Now `set_active` is called only if `active_index() != index`. Before: `PROOF-f37-after-saddle-fix.md` (FAIL step 24, ride not restored). The same regression hit the saddled Aquaryn control: `PROOF-f12-before-fix.md` (FAIL step 21).
3. Game, `scripts/world/ripplet_water_service.gd` (`da61ab6d` → `a5c1b7e2`): the host's Ripplet motion validator first sampled the rejoined peer's proxy at the default spawn (0, 1.9, 162). The restored seat is 216 m away, so the next dive was force-surfaced (`_rpc_force_surface`) as a "teleport". Now only a connection's FIRST approved mount restarts that peer's motion sample and leaves one 1 s window unjudged, so the rejoin seat becomes the anchor.
   **Anti-cheat scope (coordinator question 11:38 AM CT):**
   - The reset sits inside `if verdict.get("ok", false)`, so it happens only after `ripplet_traversal.gd::action` (lines 55–68) approves the mount. Approval needs the actor's own admitted Ripplet, the water realm, no combat, `motion_valid` (line 61: a sample already judged invalid refuses the mount), and `mount_reachable` (line 67: the host measures the actor within 6 m of the body).
   - `_mount_anchored[peer]` limits it to once per connection. A guest re-sending "mount" on the same connection never resets the sample again; a rejoin is a new peer id.
   - Residual: one unjudged 1 s window per connection, starting at its first approved mount.
   - No unit test covers this validator; the lines above are the citation.

## Saddle check still bites elsewhere (coordinator request)
The only other scenario using `rider_identity`, `f12_remote_rider_identity_reconnect.json` (Aquaryn, saddled), on `da61ab6d`: **Verdict: PASS** (`PROOF-f12_control.md`). Step 10 agrees with `mount_saddle_worn` true under the unchanged saddle requirement, and its rejoin restore (step 21) now passes too.
Its validator commit differs from the final one only in `ripplet_water_service`, which judges Ripplet proxies only, not Aquaryn.

## Checks
Affected units: `test_f37_ripplet_traversal`, `test_combat_aftermath_focus`, `test_f28_training_boundaries`, `test_stormwood_earned_waterward_handoff`, `test_water_encounter_residency`, `test_water_encounter_runtime_data`, `test_water_named_combat_camera`, `test_water_trainer_greet_mute`: 53 tests, 3049 assertions, 0 failed (`units.txt`).

## Disclosed fixtures
The scenario's own: an owned Ripplet and an L30 breakthrough record set before admission (`f37_fixture`); the host is placed on the first shore (`water_fixture`); the deep-water spot near Lantern Cove (`f37_deep_fixture`); a forced link drop and an in-memory character wipe. No generated save. Not claimed: earned campaign, device or visual acceptance.

Verdict: PASS
