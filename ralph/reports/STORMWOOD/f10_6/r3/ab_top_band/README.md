# Top-band lens lift A/B (F10#6 round 3)

Same command both times: `ralph/reports/STORMWOOD/b/f10_2/capture_named_fights.gd --ids=hollows_alpha`, `--fixed-fps 10`, 1920x1080, `opengl3` (llvmpipe), tb/stormwood at b0c10d8c (game code). Frame `i01`, one second into the Glowmoss Hollows alpha fight.

- `top_band_on_hollows_i01.jpg`: `data/config/stormwood_encounters.json` named encounters carry `combat_camera.framing.top_band: true`. The terrain, creatures and trainer render black; only unshaded telegraphs, rain and the arena ring show.
- `top_band_off_hollows_i01.jpg`: the same six entries set to `false` locally, nothing else changed. The fight is lit normally.

The lift is `Camera3D.v_offset` set by `combat_manager.gd::_update_combat_top_band` (F14 C3, Tidewake). Stormwood's opt-in was reverted in 28012b3a; the defect is logged in STATE for the Tidewake lane.
