STATUS: ready (land the conduit-core material fix; the post move is parked)
BRANCH: tb/item-f38-37
HEAD: see git log

# F38#37 quarry foreman (LANE-MESHY, 8 Nov)

## Land: conduit-core placeholder material (bug fix, no score claim)
- The flat unlit pale-cyan panel wrapped by two black rings at the foreman's walk-up is old_quarry.gd `_build_conduit_head_station`'s ConduitTerminationCore (a CylinderMesh) with the code-default material #62dce8 / emission #35c8df at 2.2: old_quarry.json had no `conduit_head` block, and that energy saturates to a shadeless slab. `old_quarry.json conduit_head.core` now gives it a deep Tether-teal glass albedo (#1d5a63) with emission #2aa9bd at 0.45, so it takes light and shading but still reads as live Tether energy (the hook already existed from F38#41). No code change. Tests: test_old_quarry, test_village_street_0912 23/0.

## Parked: foreman post move (two attempts, both worse)
- (389.5, 1787.5), into the shift-lantern pool at the quarry mouth: the dialogue camera puts a rock overhang and a timber post over his head (qj F38-37-post-v1, captured only).
- (388.0, 1791.0), toward the road threshold: he is pushed to the frame edge behind a rock face (qj F38-37-post-v2).
- Both worse than the current post (392, 1792) at a glance, so neither went to judges; overlays kept in this folder. Per the two-attempt rule this is parked until there is a new idea (e.g. move him with a facing change so the dialogue camera looks out of the quarry, or a dialogue camera seat).
- A move would also need tests/test_village_street_0912.gd ROUTE_ROLES updated (it pins his authored position).
