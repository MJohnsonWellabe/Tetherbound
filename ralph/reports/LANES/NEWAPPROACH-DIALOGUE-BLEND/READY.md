STATUS: land
BRANCH: tb/newapproach-dialogue-blend-land (cut from origin/main 3a514ef5)

# Dialogue capture waits for the conversation camera — READY (capture tooling only)

**The fault:** `tools/phase2_capture_dialogue.gd` took each `__dialogue` frame 7 drawn frames after opening the panel. The conversation camera eases in over 0.45 s, one step per physics tick. On a GPU or at `--fixed-fps` those 7 frames are under 0.45 s, so the frame was taken mid-move: the speaker small and the player in front of them. The GPU lane confirmed it from the tool's own manifests: 9 of 11 Tidewake frames in `G-rescore-tier2-dialogue` were below blend 1.0 (trainer Nerissa 0.556, Adair 0.741), and the 9 Nov captures had the same fault. CPU captures were not affected.

**Files (4):**
- `tools/phase2_capture_dialogue.gd`
- `tests/test_dialogue_capture_waits_for_blend.gd` (new)
- `docs/TECHNICAL.md` (one §8.1 runbook bullet)
- `ralph/reports/LANES/NEWAPPROACH-DIALOGUE-BLEND/READY.md`

**What changes:** `_settle_dialogue_capture()` keeps its 7 frames, then, when the rig is in a conversation, waits on physics ticks until `conversation_blend()` reaches 1.0. The wait is bounded at 180 ticks (3 s at 60 Hz); a timeout logs a warning and the frame is still taken. Two more drawn frames follow so the arrived transform is on screen. The manifest keeps `conversation_camera_blend` and gains `conversation_camera_blend_wait_ticks` and `conversation_camera_blend_timed_out`. No game code changes.

## Proof (CPU, Compatibility, this tool)
- **At `--fixed-fps 20`, the GPU lane's setting** (Tidewake: Adair, Nerissa, trainer Nerissa): waited 8, 9 and 9 ticks; blend 1.0 on all three; no timeout; arm length 2.9 m.
- **At normal CPU speed** (Cloudreach: Kelm, Veyra): waited 0 ticks; blend 1.0; no timeout.
- I did not capture a failing "before" at 20 fps on CPU; the before is the GPU lane's manifests.

## Tests run
- `test_dialogue_capture_waits_for_blend`: 3 tests, 9 assertions, 0 failed. It reads the tool's source and constants; it does not run a capture.
- Not run: any other test. The defeated-dialogue tool and `tools/_probe_dialogue_speaker.gd` extend this tool and call the same settle step; neither was run.

## What follows from it
- Dialogue frames captured before this lands may be mid-blend. Rows scored on them: F39#18, F39#26, F39#29, F38#36, F38#16, F38#37, F40#10, F40#12, F41#15 and the other dialogue items. Stormwood happened to reach 1.0.
- Re-capture those rows on this tool before any conversation-shot tuning is judged. On CPU with the blend complete, Adair is large with the player at the frame edge and Nerissa stands alone at about 70% of frame height.
