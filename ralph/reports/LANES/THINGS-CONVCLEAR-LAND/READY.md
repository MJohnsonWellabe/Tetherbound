# THINGS-CONVCLEAR-LAND: the conversation shot keeps the player and the companion out of the speaker's third; ships ON

STATUS: land

- **Branch:** `tb/things-convclear-land`, cut from `origin/main` 4e35bfbd.
- **Owner:** approved 11 Nov for conversation shots only, to ship if the GPU judges confirm it.
- **Verdict (LANE-SCOUT):** `G-things-convclear-meadows.md` (`tb/item-scout-1108` 3136cc76), GPU High.
  - Against the same-stand base the arm wins all 8 Meadows sets (+0.16 to +1.68; 3/3 on seven, 2/3 and a tie on F38#37). Nothing loses.
  - Against main, 3/3 on every row:

    | Row | Main | Arm |
    |---|---|---|
    | F38#17 | 5.75 | 6.97 |
    | F38#16 | 5.83 | 6.32 |
    | F38#36 | 7.12 | 7.39 |
    | F38#37 | 6.70 | 6.90 |

  - All Meadows dialogue: about 6.60 to 6.99. Closes none.
- **What ships (game): exactly the code and numbers that were judged** (tb/things 90763a14):
  - `scripts/player/camera_rig.gd`: `_clearance_shot` (a shot whose trainer overlaps the speaker, or sits near the frame's centre, swings then lifts to the first reachable angle that still sees and frames the speaker) and `_step_companions_clear` (this trainer's own following creature stands behind the lens while the shot is up, then follows again).
  - `data/config/camera.json conversation.twoshot_v2.clearance_1112` ON with `_why_on`. It sits inside the villager two-shot, so the aftermath, movement and fight cameras never read it.
- **What ships (capture tooling):** `tools/phase2_capture_dialogue.gd --sight-stand`, opt-in. A stand needs a clear line to the speaker by colliders and by visible meshes.
  - **Not judged:** the visible-mesh part was added after the GPU lane found `tournament_quarter_mira` shot from behind a lattice door (no collider). It is in this file but has not been re-captured.
  - **LANE-SCOUT's question, answered:** `--sight-stand` is a capture choice only. The game does not place the player; the player walks up to the speaker. The switch makes the capture stand where a player would (same room, speaker in view). I recommend making it the fixed dialogue camera set once Mira's row is re-captured clean, and re-baselining the dialogue rows on it; until then it stays opt-in.
  - `docs/TECHNICAL.md` §8.1: one bullet.
- **Test added:** `tests/test_conversation_clearance.gd` (5): the rule ships ON inside the villager shot and the aftermath profile does not inherit it; the screen-clearance score; a blocked shot swings clear and a clear shot is untouched; the follower steps behind the lens, another trainer's creature is never moved, and it follows again on exit; inert with the flag off.
- **Tests run on this branch (per-file lines checked):** `conversation_clearance` 5, `conversation_camera` 32, `dialogue_capture_waits_for_blend` 3, `camfx_candidates` 11: 51 tests, 0 failed.
- **Not included (round 2, unjudged, on `tb/things` 6d5b759d):** the companion re-checked every frame with a wider in-frame test, for the dog still at the edge on Rae and Old Perrin. It follows as its own small arm once those rows are re-captured.

## Follow-ups named by the judges
- Mira, tournament quarter (F38#16): behind the lattice on every side; the mesh check above is the fix to confirm.
- Blown key lights (Solene's face, Aldis's lamp, Mira's wall lamp) and Hald's dim green interior: NPC and interior light (T11).
- F38#36 to 7.5: the crimson banner behind Captain Halder and the over-the-shoulder framing. Halder, Hess and Verrick need a faction check before the banner is called a red leak.
- Tidewake, Cloudreach and Stormwood dialogue rows have not been captured with the rule yet; F41#15 (Nysa behind a creature) is the biggest case.
