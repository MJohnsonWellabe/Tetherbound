STATUS: land (game bug fix: F39#21 Nerissa combat admission, coordinator-approved option 2)
BRANCH: tb/item-nerissa-seat
HEAD: (this commit)

Bug: Captain Nerissa's second creature, Mirejaw, could never be sent out. Admission
was refused with "no clear seat after 395 attempts" (CAUSE.md). In the Veilfall
Heart Chamber, the authored `arena_bounds.side_margin_m` of 5 m caps the ring at
10.2 m, but Mirejaw's rendered body reaches 11.38 m, while the chamber walls
stand about 15 m out.

Fix (room-aware growth):
- scripts/world/water_veilfall.gd: new `combat_arena_wall_bound_at(x, z)`. It
  measures the same room rect to its walls, with no authored margin, and returns
  -1 wherever `combat_arena_bounds_at` has no opinion.
- scripts/combat/combat_manager.gd `_open_arena`: after every existing path
  fails (seat search, room-centred formation, open-ground growth, capped slide),
  and only when the refusal stage is `rendered_radius`, the ring grows to half the
  fighter gap + the rendered footprint + the visible clearance. That needs a
  room provider that measures its walls and a grown ring that still stands the
  visible clearance inside them (26 m cap). The pure function is
  `room_wall_growth_radius`. The same `_staged_render_fit` /
  `_find_clear_formation` measured checks then run on the grown ring, and on
  failure the original refusal context is kept (plus `room_wall_growth_radius`).
  Nerissa's stand and the authored margin are unchanged, and admitted fights are
  unchanged because the growth only runs after a refusal.
- Ride-along: in tests/capture_tidewake_named_fights.gd, `_pose` is now untyped.
  A typed Node3D parameter rejected a freed body before the validity check ran,
  which caused the "_pose ... previously freed" script error at the win.
- New tests/test_combat_room_wall_growth.gd covers growth inside the walls,
  refusal when the walls are too close, unknown or past the cap, and the
  margin-free room measure.

Proof:
- Nerissa repro (tools/phase2_capture_tidewake_fights.gd
  --trainer=water_trainer_nerissa --verified-victory-lifecycle
  --expected-resolution=1280x720 --seed=2042 --max-frames=200, CPU): the full
  fight runs Cannonback (0 s), Mirejaw (46.7 s), Riverdrake (89.8 s) and Riptusk
  (126.6 s). terminal ok, the production win is verified, 176 frames, 0 failures,
  no admission refused. The default 40-frame cap stops at 33 s, before the old
  refusal at 34.4 s, so pass --max-frames to see the send-out.
  _sheet_mirejaw_admitted.jpg shows Mirejaw in the Heart Chamber at 47, 58, 73
  and 87 s, with the camera clear of the banner walls.
- Tests (combat formation and Veilfall): test_combat_room_wall_growth,
  test_water_veilfall_arena_bounds, test_combat_arena_boundary_candidate,
  test_combat_arena_hold_inside, test_combat_arena_bystanders,
  test_combat_send_out_hold, test_combat_aftermath_focus, test_combat_flee_buffer,
  test_combat_realm_owned_begin, test_director_join_snapshot,
  test_generated_boundary_admission, test_south_bridge_visual_scale,
  test_stronghold_arena_conduits, test_stronghold_warden_arena,
  test_tidewake_nerissa_break_tether, test_veilfall_buttress_seats,
  test_water_nerissa_channels and test_phase2_fight_capture_lifecycle give
  55 tests, 0 failed.
- Co-op smokes touching combat admission: shared_wild_fight, identity_admission,
  f27_guest_wild_win and realm_owner_disconnect_mid_fight all report ALL CHECKS
  PASSED.
- Pre-existing failures, identical on clean origin/main (re-run there):
  - smoke_water_veilfall_captain fails 3 checks. It expects the first opponent at
    level 55, but Nerissa's team is authored at level 32, and its pilot stalls on
    Cannonback, before the growth path.
  - smoke_water_veilfall_runtime fails 3 checks on the pump flag, grille
    collision and walk.
- Did not finish within 25 min on CPU, so no verdict:
  - smoke_arena_contain, a stronghold diagnostic probe.
  - smoke_tidewake_named_inworld_c2, which raised 32 helper errors:
    combat_depth_pilot.gd:199 "neutral_worst_frac" is missing from a Dictionary,
    a test-helper bug unrelated to admission.
  - smoke_named_fight_hit_avoid (captain_riverwatch).
- Risk noted in CAUSE.md (r13): a READER near the east wall could put the camera
  pivot into the banner liner. The grown ring is about 12 m against walls about
  15 m out, so about 3 m of room is kept, and the repro frames show no lens in
  the cloth.
