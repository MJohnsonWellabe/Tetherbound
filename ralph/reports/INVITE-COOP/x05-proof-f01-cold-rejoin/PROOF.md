# Two-peer proof: F01 road agreement and a cold guest reconnect

**Verdict: PASS.** 156 assertions, 0 failures, exit 0. There were no SCRIPT ERROR lines in any of the three process logs: the host, the killed guest, and the relaunched guest.

Base: `ralph/x05-f01-cold` `90188bc7a`, which includes the review follow-ups. Headless. One run on the committed code:

```
godot --headless --path . --script tests/smoke_net_meadows_identity_fresh_join.gd -- \
  --opening-together --cold --host-starter=2 --guest-starter=1
```

The earlier FAIL on `90bc2e940` found a product gap. A guest process that restarts mints a new live character id at boot. On a direct-address join, `title_screen.gd` `_join_via` then treated it as a brand-new player, so its saved character stayed on disk and couldn't be reached.

## The fix

- **`scripts/ui/title_screen.gd` `_join_via`:** when the live id has no portable file but this machine holds saved portable characters, a direct join now shows the same saved-character picker the Steam join uses, plus "Create a New Character".
  - Picking a saved character points the live id at its file.
  - `_begin_join`'s returning-guest branch then restores it.
  - A machine with no saved characters keeps the existing new-character flow.
- **`tools/net/peer_runner.gd` `production_join` `pick_saved`:** the harness presses the real picker button for the saved character id, because it can't click. A missing picker, or a picker that doesn't offer that id, is a FAIL.
- **`expect_peers` `budget_s`:** the step can now wait on wall time instead of frames.
  - The "host drops the dead guest" wait uses 240 s.
  - ENet's peer timeout maximum is 180 s, but ENet tests it only when it next retransmits, on a backed-off interval.
  - Measured drops: 148.9 s (this run and the one before), 183.4 s, and one run past 190 s. The minimum is 135 s once the retry limit is hit.

## What passes

All the checks from `x05-proof-f01-opening-join`: the opening in a live two-peer session, the in-place reload, and the guest's drop and returning-route rejoin.

**Road agreement.** Host and guest hold identical road layouts: 34 bands, 248 vertices, the same fingerprint (`b7c6b5ed2fea`). This holds after the rejoin and after the cold reconnect.

**Cold reconnect:**
- The guest's character is on disk before its process is killed with -9.
- The host's registry drops to one player after 148.9 s.
- A fresh guest process on the same user-data home starts at the title. It joins by address, picks its saved character from the picker, and joins under a new peer id.
- Both peers see two players again.
- It holds the same character and the **same** starter UID. Its starter is the ripplet named "A".
- Its starter receipt came back from disk.
- It has exactly the 50 orbs it had before its process died.
- The host's starter is unchanged: the galewisp named "A".

## Unit coverage

- `tests/test_steam_invite_ui.gd` `test_a_restarted_guest_still_sees_its_saved_portable_characters`. The title, Steam-invite and identity tests pass: 20 tests, 0 failed.
- No unit test builds the title scene. Only the picker's Pick is exercised, end to end, by this proof pressing the real button. Its Create and Back actions are not tested.

## Not covered

- A restarted guest whose machine also has a local slot-0 autosave, for example one that also plays solo or hosts. `_join_via` loads that slot and never shows the picker. This behaviour predates this change.
- The same reconnect over the Steam join path. Steam can't be exercised here, and it is never faked.
- A host-side cold restart.

Logs: `coordinator.log.gz`, `peer-0.log.gz` (host), `peer-1.log.gz` (the guest before the kill), `peer-1-cold.log.gz` (the relaunched guest), `SUMMARY.md` (net run `local-3761654`).
