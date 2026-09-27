# Handover to TIDEWAKE FIGHTS + VISUALS: F14#0, F14#1, F13#5 work from tb/tidewake-full

These rows moved to the fights lane on 2026-09-27 at 18:04 (#356). Everything here is
evidence and notes only. Nothing in this folder closes a criterion.

## Frames (JPG, 1280x720, production fight camera, xvfb + opengl3)
- `calder_b86ef8e6/`, `nerissa_b86ef8e6/`: curated sets (tell frames plus every Nth periodic
  frame) that were judged below. `frames.json` holds the kind, fight time, opponent,
  tell_s and gap.
- `nerissa_dbe43195/`: the full 60-frame capture after the Riptusk CHARGER lane
  (dbe43195). Late frames there are tagged `tell-late` only while the opponent is still
  winding up; otherwise they are tagged `tell-ended`. **Not judged yet.**
- `tess_dbe43195/`: a 32-frame capture at Tess's crown stand. It **fails**: the fight still
  slides off the crown's west edge into the cut, and the camera then faces the rock.
- `venn_beach_local_65cf8db2/`: a 4-frame local check of Venn's new beach stand.
  Framing is clean.
- Capture command: `tests/capture_tidewake_named_fights.gd -- --trainer=<id>
  --pilot=READER --level=43 --interval=4 --max-frames=60
  [--flags=water_dock_salt_crown_landing_charted for Calder]`.

## Code-blind C3 judges (fresh subagent, frames + frames.json + the C3/COMBAT §5 bar only)
- **Calder @b86ef8e6: FAIL.**
  - Framing 34/35 (97%).
  - Tells readable on 9/12 frames. The 3 failures were late frames after a READER
    interrupt or a resolved blow; the capture now tags these `tell-ended`.
  - Engage-tick (t=0) close-up.
  - Team list covers the ally's face on about 1/3 of frames.
  - Stacked floating sand-island artefact in the sky (frames 22–24, 32–34).
  - Wild creatures behind the fight add clutter.
- **Nerissa @b86ef8e6: FAIL.**
  - Framing 34/37 (92%).
  - Tells readable on 12/16 frames (same late-frame cause as Calder).
  - Blocking: Riptusk's heavy tell looked identical to ordinary tells. dbe43195 adds the
    F04 travelling CHARGER lane (lunge 7, `lunge_travels`) to Nerissa's and Venn's Riptusk
    in `water_characters.json`.
  - Camera collapses into close-ups (frames 9, 10); hit VFX washes out the target.

## Placement defects found and changed on tb/tidewake-full (game data; please re-verify)
- **Venn** (65cf8db2): the B4 graded pad beside the gate put the 26 m x 82 m waterfall
  curtain inside his arena, and frames were whited out.
  - No stand within 60 m of the gate needs less than 18 m of cut or fill.
  - He now stands on the open landing shelf 21 m from `sluice_isle_to_veilfall_arrival`.
    WORLD: "Officer Venn guards the climb".
  - The pad and the heightfield pad code are removed; region 00_07 is main's bake again.
- **Tess** (dbe43195): moved 13 m east onto Deep Watch's crown (offset 16,0,-12). Still
  failing, as above.
  - A 16 m fill pad at her old stand cut the Tidecoil walk route.
  - The only open 16 m disc on Deep Watch is the swim rest shoal
    `sluice_isle_to_deep_watch_rest_03`.
  - Suggestion: a graded pad centred on the new stand with a feather of about 8 m. Its
    influence stops about 17 m short of the Tidecoil route near x=1327.
  - Before, at b86ef8e6, the READER pilot wiped in 82 s.
- **C2 in-world:** `../f14_1_nerissa_inworld_c2/` passes for Nerissa at 4398c59e (144
  fights). It predates the Riptusk lane change and needs a rerun. Driver:
  `tests/batch_tidewake_named_inworld_c2.gd`.
  - Completed dbe43195 artifacts, if useful: render runs 36339189870, 36339187258,
    36339184600, 36339176365, 36339174004 (Nerissa C2 cells).
  - The rest were cancelled at 19:05.

## F13#5
- There is no fresh judge.
- Local matrix capture (`tools/art_pipeline/capture_tidewake_matrix.gd`, 1920x1080) is
  unchanged from earlier rounds.
- A first local pass showed white untextured props. The cause was stale model imports
  after restoring skip-worktree textures, not a game defect. Delete
  `.godot/imported/*.gltf-*` and re-import.
- Against `water-veilfall-stronghold-board.png` the gap is asset-level: the grey cone
  mountain, the plank docks.
