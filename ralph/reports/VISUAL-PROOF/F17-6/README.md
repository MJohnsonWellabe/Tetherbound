# F17#6 Meadows village and Hall matrix at Low, for the code-blind judge

Captures lane, Low/Compatibility (llvmpipe). This lane captures; it does not judge.

- **Exterior, 14 frames:** `tests/capture_f17_visual_matrix.gd` walks the real farmhouse door → Main Street → Hall route. Movement uses parsed joypad input, real collision and one inherited starting fixture; camera turns use the look stick only.
  - Source: `tb/ev-captures` at `d4e4ec2d`, 1920x1080, finished about 6:51 PM CT Sun 11 Oct.
  - That run was then OOM-killed (exit 137) before its Hall interior stations. These 14 frames were complete before the kill.
- **Interior, 4 frames:** `tests/capture_f17_hall_interior.gd` stands the player in the nave once (disclosed placement) and aims the ordinary rig down the nave and at the Shrine Room, by day and by night.
  - Source: `tb/ev-captures` at `1aa63f73`, 1280x720, finished about 1:12 AM CT Mon 12 Oct.
- **`sheet.jpg`:** 18 frames, all scaled to 1280x720 in `frames/`.
  - **Farm door:** day, golden hour, night, day with the rain setting.
  - **Main Street left frontage:** day, golden hour, night.
  - **Main Street right frontage:** day, night.
  - **Hall approach:** day, golden hour, night, day with rain; plus the reverse view by day.
  - **Hall nave** and **Shrine Room:** day and night.
- **Observed, not judged:** in both rain-setting frames no rain is visible at Low; they read the same as the clear frames.
