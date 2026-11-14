# LAND-MT-SHELLSHARDS arm-side crash, 13 Nov 2026 19:01 (GPU lane, GTX 1060 3GB)

Evidence for LANE-LAND-MT. The frames (6 of 10 on the arm side) are in `G-land-mt-shellshards`.

## Run

- Tree: tb/land-cs 91ac0d6a1 (imported). On top of it, 3cbb66b00's seven Meadows files were byte-copied on all three sides:
  - burrow_warrens.json and burrow_warrens.gd
  - camfx.json
  - props.gd
  - meadows_ridge_vl.json and meadows_ridge_vl.gd
  - meadows_ridge_far.gdshader
- Arm: 3cbb66b00's `LAND-MT-SHELLSHARDS/overlay.json`, which sets `burrow_warrens.json bank.hill_shell.island_strip.enabled = true`.
- Command: `_command.txt`. Renderer: Vulkan 1.3.280, Forward+, High, 1920x1080, fullscreen, seed 2042.
- The base side and the plume side ran the same two subsets on the same tree with no crash; both captured all 10 frames.

## Where it stopped

- The arm side saved 6 of 10 frames. The last save was frame index 5 (0-based), `meadows__band5_stronghold_approach__09__stronghold_approach__route_day`.
- It crashed before saving index 6, `..._stronghold_approach__walk_01_day`. Frames are captured in this order per subset: route_day, walk_01_day, walk_02_day, walk_03_day, vista_dusk.
- The last `_run.log` line is the index-5 capture. There is nothing after it: no script error, no Godot backtrace. `_run.err.log` is empty.
- Log write: 19:01:36. Windows crash event: 19:01:38.
- Godot's own `logs/godot.log` for this run has already rotated out (Godot keeps 5). `_run.log` is the same stdout.

## The crash: inside the NVIDIA driver, not in game code

From the Windows Application log (`eventlog-20261113-1901.txt`) and the WER report (`WER-Report-20261113-1901.wer`, which includes the loaded-module list):

- Faulting module: `nvoglv64.dll` 32.0.15.6094. This is NVIDIA's OpenGL and Vulkan driver DLL; the game runs on Vulkan.
- Exception: 0xC0000094 (integer divide by zero) at offset 0xe93647.
- Process: Godot_v4.7-stable_win64.exe (4.7.0.0).
- The minidump was not kept, so there is no stack beyond the module and offset.

`wer-godot-crash-history.txt` lists every archived Godot crash on this PC. The exact same signature (nvoglv64.dll, c0000094, 0xe93647) appears 10 times between 13 Oct and 9 Nov on other captures, then again here. It is an intermittent driver fault on this GPU and driver that some content hits. The 13 Nov run is the first one tied to a specific arm, because base and plume passed the same subsets in the same session.

A guess, not verified: an integer divide in the driver at draw or dispatch time usually means a zero-sized resource or count reached it. Examples are a zero-instance MultiMesh, an empty mesh surface, a zero-size texture or a zero-length buffer. `island_strip` would be the first place to look for a strip that ends up with no instances or no vertices at the stronghold walk_01 stand.

## Retry, 19:52-19:56: did not reproduce

The arm side was rerun on the same composition. It finished clean:
- exit 0, 10/10 frames ("CATALOGUE SURVEY OK"), no script errors;
- no new Application-log crash event.

The frames are in `G-land-mt-shellshards-retry`. The crash fits the known intermittent driver fault above, not a deterministic failure of `island_strip`.
