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
