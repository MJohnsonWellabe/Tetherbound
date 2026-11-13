# THINGS-TOURNEYSTAND-LAND: tournament conversations are captured where the game stages them

STATUS: land

- **Branch:** `tb/things-tourneystand-land`, cut from `origin/main` 30d00e6b.
- **Kind:** capture-tool fix for a reproduced judging blocker; the game is unchanged. No GPU verdict needed to land, but F38#16 needs a re-capture after it.
- **Row:** F38#16 (5.57, level on CONVTIGHT). 3/3: "Mira's camera sits inside a timber-and-lattice wall, no speaker shows."
- **Cause (CPU probes):** a tournament round's lines are not spoken at the opponent's home. `tournament_dialogue_presentation.gd` hides the home body's art, stands a copy of the opponent at the round's spot and points the conversation camera at that copy. The dialogue capture walked the player into Mira's shop instead. The copy then appeared 3.5 m from the player, outside her lattice door, and the camera turned to it. Mira's own art was hidden, so the frame had no speaker. It is not her post, her stand or the camera swing.
- **Fix:** `tools/phase2_capture_dialogue.gd`: for a conversation the tournament stages, the player stays at the catalogue post (no re-seat onto the home body, no walk to it) and the game's own staging frames the speaker. Every other row is untouched.
- **Shown (CPU):** `_sheet_mira_tournament_cpu.jpg`: Mira framed on the village street with the tournament hall behind. The log reads `staged at the post by the tournament`.
- **Also affected:** the other tournament rows (`tournament_semi_tam`, `tournament_final_oskar`) now take the same path. Not captured on CPU; they were previously shot at the opponents' home bodies.
- **Tests:** new `tests/test_dialogue_capture_tournament_stage.gd` (2 tests); run with `test_dialogue_capture_waits_for_blend.gd`: 5 tests, 0 failed.
- No `.uid` files are included.

## Ask for the GPU lane after landing
Re-capture the Meadows dialogue set's three tournament rows at High for an F38#16 row score.
