# Forward+ on CPU via Mesa lavapipe: does it work as a cloud check? (1108)

**Result: no. Godot crashes before the first frame, every time.** Lavapipe does not become the cloud check, and Forward+ verdicts stay on the GPU rig.

- **What was run:** one attempt plus one confirming rerun, as the brief allowed. No harness was built.
- **Why it matters:** the time per frame could not be measured, and there are no frames to compare with the GPU on the black slabs or the grass density.

## Setup
- **Container:** 4 cores, 15 GB RAM, Ubuntu 24.04.
  - Installed `mesa-vulkan-drivers` 25.2.8 and `vulkan-tools` with apt; the image ships no Vulkan ICD.
  - `vulkaninfo` reports `llvmpipe (LLVM 20.1.2, 256 bits)`.
- **Preset:** isolated `XDG_DATA_HOME` with `godot/app_userdata/Tetherbound/graphics_override.cfg` set as follows:
  - `preset="High"`, `base="High"`, `custom={}`, `overlay=false`;
  - `[rendering] renderer/rendering_method="forward_plus"`.
  - This is the document `scripts/ui/graphics_prefs.gd::_usable_document` accepts.
- **Subject:** the F38#24 Burrow Warrens walk frames, the same tool and subset as `manifest-A.json` on `tb/gpu-frames-1108`.
- **Command:**

  ```
  XDG_DATA_HOME=<scratch>/xdg VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json \
    xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver vulkan \
    --rendering-method forward_plus --resolution 1280x720 \
    --script res://tools/phase2_capture_routes.gd -- --biome=meadows \
    --subset=meadows__band2_stone_and_root__04__the_burrow_warrens --seed=2042 \
    --source-commit=<HEAD> --output=res://ralph/reports/VISUAL/phase2/meadows/repro/lvp_warrens
  ```

## What happened
- **Engine start works:** the engine starts on `Vulkan 1.4.318 - Forward+ - Using Device #0: llvmpipe`.
  - The production Meadows scene loads, instantiates and attaches.
  - The manifest records `rendering_method: forward_plus` at 1280x720 with 5 planned frames, including `walk_03_day`.
- **Run 1 (36 s):**
  - The terrain node builds in 154 ms.
  - The scatter bake reads 256 regions and 42,127 placements.
  - Then: `ERROR: /root: The caller thread can't call the function propagate_notification() on this node`, followed by `signal 11` in an unknown module.
  - The backtrace has only two frames (libc, then an anonymous address), consistent with JIT code from llvmpipe or a GDExtension.
  - Exit code 134; no frames written (`"frames": []`, `"complete": false`).
- **Run 2, the confirming rerun (15 s, warm import cache):**
  - It hits the same off-thread `propagate_notification` error and the same `signal 11` in an unknown module, right after the world attaches.
  - Exit code 134; no frames.
- **Conclusion:** the crash is deterministic, not a flake.
- **Likely cause (inference, not root-caused):**
  - The crash comes at the first threaded render or terrain work after the world attaches.
  - This matches the long-standing note in the visual-judge skill that Terrain3D segfaults under software Vulkan on this box.
  - That note is why cloud captures use Compatibility in the first place.
  - Finding the cause would need a debugger or a Terrain3D-free scene. That is harness work, and the brief rules it out.

## Questions from the brief
| Question | Answer |
|---|---|
| Does it run? | Forward+ starts on lavapipe, but the production world crashes (SIGSEGV) before the first frame, 2 of 2 runs. |
| Time per frame | Not measurable; no frame was produced. |
| Black slabs and dense grass match the GPU frame? | Not testable. |
| Becomes the cloud check? | No. Forward+ looks (F38#24/F38#30 black slabs, F41#15 glow blowout, grass density) stay GPU-only; cloud lanes keep iterating on Compatibility Low. |

Run by LANE-SCOUT, 9 Nov 2026 ~00:45 UTC. Logs stayed local; no capture output was kept.
