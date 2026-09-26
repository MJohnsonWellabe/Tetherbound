# Two-peer proof: F01 road agreement and a cold guest reconnect

**Verdict: FAIL.** The failure is a product gap, reported. The road-layout agreement passes. The guest's cold reconnect cannot restore its character over a direct-address join.

Base: `ralph/x05-f01-cold` `90bc2e940`. Headless. One run:

```
godot --headless --path . --script tests/smoke_net_meadows_identity_fresh_join.gd -- \
  --opening-together --cold --host-starter=2 --guest-starter=1
```

## What passes

- Everything in `x05-proof-f01-opening-join`: the opening in a live two-peer session, the in-place reload, and the guest's drop and returning-route rejoin.
- **Road agreement.** A `road_signature` probe fingerprints each peer's road bands, built from the terrain config that peer loaded, plus its live baked ground height at every road vertex. Host and guest agree exactly: 34 bands, 248 vertices, the same sha256.
- **The host times the dead guest out.** The guest's process was killed with -9, after `save_character_here` put its character on disk. The host's registry dropped to one player after 8,925 frames, inside ENet's configured 135–180 s peer timeout.

## What fails, and why

- A fresh guest process boots the title on the same user-data home. Its live character id is newly minted, `character-f0c0…` rather than the saved `character-8172…`, because `game_state.gd` `reset_for_new_game` mints one on every boot.
- `title_screen.gd` `_join_via` / `_begin_join` treats a guest as returning only if it has a world autosave (clients never write one), or if that live id already has a portable file.
- The saved-character picker (`_show_portable_character_select`) exists only on the Steam join path.
- **So on a direct-address rejoin after a crash, the real game would send this guest to new-character creation. Its saved character, with its starter, receipt and orbs, stays unreachable on disk.**
- Every later FAIL line in the log (peers, starter, receipt, orbs, road layout after the reconnect) follows from that one failure.

## Not covered

- The same reconnect over the Steam join path. Steam can't be exercised here, and it is never faked.
- A host-side cold restart.
