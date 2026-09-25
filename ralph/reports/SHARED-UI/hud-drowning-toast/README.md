# Drowning cue (X03-WO4, F12 readability) and config-driven toast hold (X03-WO6)

`tools/capture_hud_drowning.gd` through the production Tidewake world
(`water_archipelago.tscn`), its real Player, SwimController, CameraRig and
PlaygroundHUD at the production camera; 1280x720, opengl3 under xvfb,
`--fixed-fps 30`.

- `before_drowning` / `after_drowning` (+ `before_after_drowning.png`): human
  in deep water with stamina at 0, so `swim_state.drowning` is true and health
  falls. Main shows no cue; the branch shows the amber "Drowning / Reach shore"
  plate with a caution triangle beside the health bar.
- `before_toast` / `after_toast` (+ `before_after_toast.png`): a world message
  shot 1.8 s of game time after posting. `*_log.txt` records game vs wall time.
- `sequence/frame_NN.jpg` + `sequence_sheet.jpg`: 34 s at 1 fps. Swim out with
  low stamina, run dry (t=11 s), drown with the cue up while health falls
  98.9 -> 50.7, swim back, land (t=26 s): cue cleared. Per-frame state is in the
  capture log lines `t=..s mode=.. drowning=.. cue=..`.

Staging (tool header): stamina written directly (0 for the still; cut on the
first physics step in the water for the sequence), health restored before the
sequence, time of day frozen at day, movement driven by synthetic
`move_forward` events steered by camera yaw.
