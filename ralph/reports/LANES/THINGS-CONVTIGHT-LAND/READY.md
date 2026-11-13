# THINGS-CONVTIGHT-LAND: tighter conversation shot

STATUS: land

- **Branch:** `tb/things-convtight-land`, cut from `origin/main` 317b3372.
- **Verdict (LANE-SCOUT):** `G-things-convtight.md` (`tb/item-scout-1108` b4ff847a), GPU High. Wins 10 of 11 judged sets, loses none (3/3 on 9).

  | Row | Base | Arm | Judges |
  |---|---|---|---|
  | F38#17 | 6.46 | 6.85 | 3/3 |
  | F38#37 | 6.50 | 6.69 | 2/3, one tie |
  | F39#26 | 6.73 | **7.04** | 3/3 |
  | F40#10 | 6.61 | 6.92 | 3/3 |
  | F40#12 | 6.85 | **7.12** | 3/3 |
  | F38#16 | 5.57 | level | identical (Mira's stand) |

- **What ships:** `data/config/camera.json conversation.fov` 40 to 36, with `_why_tight_1113`. Config only.
- **DIFFERENT FROM THE REQUEST: the plain `distance` stays 3.5.** The judged overlay set it to 2.9, but that was a no-op in play: `twoshot_v2` (ON) already sets the conversation arm to 2.9. So the judged change was the field of view alone. Writing 2.9 into the plain block changes nothing in the game and fails an older test, `test_twoshot_v2_frames_the_speaker_closer_with_the_trainer_behind_the_lens`, which compares the candidate against that plain value. The frames the judges saw and what this branch renders are the same: arm 2.9 m, field of view 36.
- **Tests:** new `tests/test_conv_tight_landed.gd` (fov 36 in the file; live config distance 2.9 and fov 36; aftermath unchanged at 5.2 / 52).
- **Tests run on this branch:** `conv_tight_landed`, `conversation_camera` (including the 3.0 to 5.2 m stand assertion), `conversation_camera_aftermath_profile`, `conversation_clearance`, `camfx_candidates`, `dialogue_capture_waits_for_blend`: 57 tests, 259 assertions, 0 failed.
- No `.uid` files are included.

## Still holding these rows (both sides, 3/3)
- Solene's blown-out face (F38#17); the chain prop across Vance; a trunk over Gil; a floating teal disc above Senn; Tovin, Nel and Orsen share one mesh.
- F38#16: Mira's tournament stand puts the camera inside a lattice wall.
