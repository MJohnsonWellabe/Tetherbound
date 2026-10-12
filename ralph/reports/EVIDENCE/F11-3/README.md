# F11#3 Long Storm aftermath and Spark/shrine persist: PASS

Lane co-op (coop-chapters, absorbing coop-loop), branch tb/ev-coop-chapters @ c1bb62ff0. Run Sun 11 Oct 11:44 PM to Mon 12 Oct 12:09 AM CT, Godot 4.7-stable headless, two real processes.
Command: `tools/net/run_two_peer_proof.sh <scratch>/stormwood_f11_aftermath_shrine_two_peer_reload_rejoin.json`, exit 0, 99 PASS / 0 FAIL (`aftermath_shrine_two_peer_reload_rejoin/PROOF.md`).

Proven:
- The Long Storm ends through the real completion path; both peers present the aftermath (no flashes); the view is charted; one Stormheart answer per character.
- Home Key home and the Crossing Hall portal back, host first.
- The guest places the Spark and the host wears its power; SHRINE LIVE on both.
- The host's process restarts, title_load hosts again, and the guest rejoins; world-state hashes are equal before and after.
- The aftermath, Spark and answers reconstruct after the restart and after a mid-session drop and rejoin; replays offer nothing.
- The saved world and character files hold everything, against a non-vacuous baseline.

Game fixes found by this proof, each with unit tests and a clean two-peer run:
- e2fc28e6b: an owner fence that never moved the trainer keeps its travel baseline. The Stormheart answer's in-place drop had failed the guest's owner-passive stream.
- 4394e1c11: a stream re-armed during a fence forgets that baseline.
- e3ae38346 + b5433c3ed: a damage_revision rollback needs the host's own crossing record (fake-realm hardening); it allows one restart within 30 s, covering the old-vitals-first race.
- c1bb62ff0: travel permit ids carry a per-process nonce. A restarted host reissued ids, so the rejoined guest's arrival was refused as already decided.

Scenario and helper changes (pre-approved alignments, no assertion loosened):
- 761bc5c7/85b2442e (coop-loop): RD-17 crossings; the retired Waterward gate kept as a negative check; Home Key re-press on NOT_READY.
- 4f689c018: stale label "Stormwood aftermath acknowledged".
- 5e8f3ec5e: the Home Key press waits out a rejoined guest's owner hold.

Disclosed:
- Fixtures: the named host save, the initial Hall portal fixture with one Home Key, and the Dynamo fixture.
- Scratch copy, wall-clock/frame budgets only: step `budget_frames` max(4×, 12000), `build_allowance_s` 600, `budget_s` 4×, and the portal-crossing `args.budget_frames` ×3.
- This passing run carried one print-only diagnostic in `tools/net/peer_runner.gd` (per-key hash breakdown, `hash_keys_over_time.txt`); reverted.

Timing sensitivity:
- `day` and live `harvested_vegetation` are hashed and change with time.
- #54 "equals the pre-restart hash" failed once (on c1bb62ff0) when the ~10 min restart window on this host crossed such a change, and passed on rerun.
