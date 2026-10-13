# Release reliability (ACCEPTANCE §7) pieces 1–2: 10x save/load and 10x realm cycles on an exported binary

Tue 13 Oct 2026 (CT), tb/ev-systems fde71836. A real exported Linux release build
(`godot --export-release "Linux Test"`, official 4.7 templates; Windows is the release platform,
not run here), driven through the packaged-route title entry: `Tetherbound.x86_64 -- --release-cycle
--piece=save|realm --cycles=10` (tools/release_cycle_route.gd). xvfb + software GL.
Disclosed fixtures: opening beats pre-set, a host-of-one session, an isolated save dir, one unmeasured
warm-up save/load (the first load's legacy Home Key reconcile), and bypass_gate on transitions.

## Piece 1, save: PASS
10/10 cycles of save -> mutate the bag -> load, each restoring exactly the saved snapshot
(save 146–433 ms, load 225–376 ms). Refusals leave live state untouched, each with its own code:
corrupt -> unreadable_save; newer (v29) -> incompatible_future_version; archived v27 fixture ->
incompatible_old_version with the RD-35 "Start a new game. Your old save has been kept." message.

## Piece 2, realm: PASS
10/10 Meadows <-> Cloudreach transitions, each landing ready in its target scene. Total crossing
time: Cloudreach 149–177 s, Meadows 69–105 s. These are rendered software-GL runs, including the
transition autosave and the overlay; readiness stayed within the 120 s cap on every crossing.

## Not covered by these pieces
Five solo and two four-peer full clears (they depend on the earned-route chain, F49#0/Routes);
migration of saves newer than the reset format (none exists yet); the Windows binary.
