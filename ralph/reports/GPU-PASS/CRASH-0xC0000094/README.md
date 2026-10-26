# CRASH 0xC0000094: intermittent integer divide-by-zero in the NVIDIA Vulkan driver during F38 captures (26 Oct 2026)

**What happened.** In the K5 / MH3 / MH4 Meadows block (tb/meadows d35483f3c, `capture_f38_matrix.gd`), two of the eight runs crashed. The same commit completed in the other six runs: k5 and mh4 at Medium, and off, k5, mh3 and mh4 at High, all with 49 files.

| Run | Arm / flags | Preset | Time | Exit code | Got as far as |
|---|---|---|---|---|---|
| `K5-off-Medium` | off (`--f38-baseline`; every flag off, so effectively the shipping game) | Medium | 10:00:54 | -1073741676 = **0xC0000094** | world loaded and **frame 1 saved** (`band3_the_river_lock_0__day__clear__approach`); crashed moving to the next view |
| `K5-mh3-Medium` | mh3 (`--f38-candidate`; courtyard daylight + banner) | Medium | 10:19:36 | 0xC0000094 | same: frame 1 saved, then the crash |

**Windows Application log** (both events, identical apart from the process id; full text in `windows_application_events.txt`):
- Faulting application: `Godot_v4.7-stable_win64.exe` 4.7.0.0 (time stamp 0x6a32f90f).
- **Faulting module: `nvoglv64.dll` 32.0.15.6094** (NVIDIA driver 560.94, time stamp 0x66bc35f7), path `C:\WINDOWS\System32\DriverStore\FileRepository\nvmd.inf_amd64_aa54f7a758543a0a\nvoglv64.dll`.
- **Exception 0xc0000094, fault offset 0x0000000000e93647**, the same offset both times.
- Report Ids: a5d0db2c-45f2-4a1b-b1f2-d824204aaf6a (10:00) and d878f2e9-e34c-4b86-8154-b779d154ce05 (10:19).
- No crash dump was written (`%LOCALAPPDATA%\CrashDumps` is empty).

**What it is.** The renderer was Vulkan 1.3.280, Forward+, GTX 1060 3GB, at 1920x1080 (see `_run.log` and `_command.txt`). On Windows, NVIDIA's Vulkan ICD is `nvoglv64.dll`, so this is an **integer divide-by-zero inside NVIDIA's user-mode Vulkan driver**, not in Godot or game code.
- Godot's own crash handler did not fire. `_run.err.log` has no backtrace; the process was killed by the exception.
- The crash comes **after** the scene load and the first draw and capture, on the first camera move to a new view in the same session.
- No display-driver reset (TDR) was logged at those times.

**Related but different.** At 08:22 the SW16 candidate run (Stormwood, storm_view) hit a real **TDR**: System log nvlddmkm event 153, then Display 4101 "nvlddmkm stopped responding and has successfully recovered". Godot then crashed with 0xc000001d at Godot+0x136e6a1 after Vulkan reported device lost (VkResult -4, last breadcrumb SKY_PASS). That one is tracked under SW16.

**Next.**
- Both runs are queued to re-run (queue 46).
- If 0xC0000094 reproduces, a lane should look at the Vulkan work on the first view change after the river_lock_0 approach frame at Medium: which pass or draw divides by zero in the driver, for example a zero-sized dispatch or image, or a zero-count indirect draw.
- Updating the GTX 1060's NVIDIA driver (560.94 is from August 2024) is a host change. It needs the owner's say-so, and it would also change the GPU-pass baseline.

## Files

- `K5-off-Medium/` and `K5-mh3-Medium/`: `_run.log` (full Godot stdout), `_run.err.log` (stderr), `_command.txt`, `manifest.json` (the capture's own manifest, written before the crash).
- `windows_application_events.txt`: the Application-log events 1000/1001 for the Godot crashes from 08:00 to 10:20.
