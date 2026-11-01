# Code-fix lane: dialogue capture fixture (GPU DLG-1, 14 rows)

Branch `tb/world-fix-dialogue-capture`, from main fc885aec. Coordinator scope: CRITERION_DELIVERY rule 3, a reproduced proof blocker.

## Change

`tools/phase2_capture_dialogue.gd` used to call `DialoguePanel.start()` at the catalogue post with no speaker. Now, before opening the panel, it does three things:

1. **Finds the row's speaker body.** It matches the row's authored id, display name and slug against every character body in the world, including the encounter directors' `trainer_nodes` and their spec names. The nearest match wins. Bodies hidden by residency culling still count.
2. **Moves the player when the speaker is elsewhere.** If the body is more than 4.5 m from the post, the player stands 2–4.4 m from the body, facing it. Each candidate stand must be on ground within 2.5 m of the body's height. This applies to the dialogue frame only; the post frame is unchanged.
3. **Hands the body to the conversation camera** with `begin(body)`, the same call the game's victory path makes. The panel's own `begin()` then sees the camera already pushed in.

The camera code, its config and the framing are untouched. Each dialogue record gains `dialogue_speaker_body`, set to `near`, `moved:<m>`, `absent` or `refused`.

The water trainer intros are a special case. No game code opens them: `spec["intro"]` is never read, and nothing plays the trainers' win/lose lines either. So no in-play conversation exists to substitute, and the capture keeps the authored intro but now frames Daro, Bex and Irva.

## CPU check

Settings: Compatibility, 1280x720, seed 2042. Shown below is `conversation_camera_active` for each dialogue frame.

| Row | Before | After | Speaker body |
|---|---|---|---|
| Tidewake Daro | false | **true** (blend 1.0) | near |
| Tidewake Bex | false | **true** | near |
| Tidewake Irva | false | **true** | near |
| Captain Nerissa (character) | false | **true** | moved: 1699 m, Veilfall interior |
| Captain Nerissa (trainer) | false | **true** | moved: 1692 m, Veilfall interior |
| Cloudreach Kelm | false | **true** | moved: 12.6 m |
| Cloudreach Veyra | false | **true** | moved: 102 m |
| Tidewake Nalia | false | false | refused: body 13.5 m away; no stand within 2.5 m of its height, tried twice |
| Captain Marrow (character + Dynamo trainer) | false | false | refused: nearest body 149 m away in the Dynamo core; no stand found |
| Meadows Kell | false | false | absent: Kell is placed only after `legendary_freed`, and the fixture does not set progression |
| Stronghold courtyard / elite | false | not reached | the CPU found no post stand (both before and after) |
| Controls Adair, Corin | Adair true, Corin false on CPU | both **true** | near |

The Veyra defeated row uses the same body, but it was not run separately.

**Result: 7 of the 14 GPU rows are verified true on CPU.** Two more are pending. The rest are blocked:
- **Pending:** the Veyra defeated row (expected true, not run) and the stronghold pair (needs the GPU, where those rows have a stand).
- **Blocked, Nalia and Marrow:** the stand search can't find floor beside these bodies. Marrow's may be an interior floor.
- **Blocked, Kell:** the fixture would have to set progression flags.
