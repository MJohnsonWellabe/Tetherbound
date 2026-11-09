STATUS: land (capture-stand bug fix, no score claim)
BRANCH: tb/item-f40-3-stand
HEAD: (this commit)

F40#3, Old Wind Observatory and Broken Skyroad Arch day approach: "no supported
production-camera stand among 15 candidates".

Cause: every candidate failed at travel. Cloudreach `ground_height_at` returns NaN
16-48 m back from these spots because the ground there is void. The observatory
crown is about 20 m across and the authored spot is 15.6 m from its centre. The arch
crown is about 15 m across. game_state `debug_teleport_to` refuses NaN ground, so the
player never left spawn.

Fix: tools/phase2_capture_locations.gd approach offsets are now
[32, 24, 40, 16, 48, 12, 8]. The 12 m and 8 m stands are tried only after every wider
stand fails, so frames that already found a stand keep it.

Check: one CPU capture of both frames gives 0 invalid stands, and both selected the
8 m stand. The arch frame shows the trainer between the pillars on the grass crown.
The observatory frame shows the tower and ring, but the trainer stands on the
crown's rim and reads a little high over the skirt. That is a limitation of the
authored spot on a small crown, not hidden by reframing.
Tests test_capture_jobs_args, test_meadows_cause_flags and
test_catalogue_capture_stand: 17 tests, 0 failed.

## F40#20 (same branch, also a capture-stand bug fix, no score claim)
Problem: the Sky Aviary (Summit Eyrie) close frame repeated the approach shot.
The authored spot is an overlook 120 m from the dome, and close stands are taken
5-12 m behind the spot, so "close" never got close.

Fix:
- debug_teleport_spots.json: a spot may author `close_position` [x, z]
  (optional `close_view_heading_deg`). Summit Eyrie now has close_position
  [141.7, 5366.9], on the forecourt path 45 m from the dome, same heading -112.04.
- tools/phase2_capture_locations.gd: close rows use that position (static
  `close_position_for` validates it), and the planned row records
  `close_position_authored`. Approach rows and spots without the key are unchanged.
- Tests: tests/test_catalogue_capture_stand.gd adds parsing and validation cases,
  plus a check that Summit Eyrie authors a close position.

Check: a CPU probe with an ad-hoc spot at that xz and heading (close view)
selected a stand and frames the gateway arch, towers and banners up close with the
trainer on the path. I also probed 30 m (too tight against the drum) and dropped it.
Tests: 19 tests, 0 failed. The "Parse JSON failed" line in the log comes from
test_capture_jobs_args feeding deliberately bad JSON.
