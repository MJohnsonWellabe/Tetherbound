# Stormwood production-camera resurvey

Status: **24/24 corrected-camera frames captured and identity-validated.** This round
predates the separate Stormwood pylon-material repair and is preserved as pre-repair
evidence. It is catalogue-survey input, not a visual-quality verdict.

## Evidence identity

- Branch / capture HEAD: `codex/four-biome-audit-resume-0908` / `4e653e9b33e20f2e9e4a36bc215b1e1ce52708b5`.
- Shared production-camera repair: `fe904abf2`.
- New output: `shots/catalogue/stormwood/round-camera-20260909T013019Z/`.
- Retained baseline, untouched: `shots/catalogue/stormwood/round-20260909T004513Z/`.
- Command: `tools/catalogue_survey.ps1 -Biome stormwood -Godot C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe -Output res://shots/catalogue/stormwood/round-camera-20260909T013019Z`.
- Manifest: `complete=true`, 24 planned / 24 captured, failures `[]`; capture
  01:30:26–01:31:21 UTC.
- Logs and telemetry: `engine.log`, `launcher.stdout.log`, `launcher.stderr.log`,
  `memory-watch.csv`, and `_sheet.png` in the new round.

The Settings preflight enumerated all 12 canonical destinations and 24 day/night IDs.
Those IDs equal the manifest plan and captured rows in order. `CATALOGUE SURVEY OK:
24/24 frames` is present; no baseline frame, manifest, sheet, or report was overwritten.

## Process receipt and lease

The hidden chain was PowerShell helper PID **30412** -> console launcher PID **1388**
-> actual non-console renderer PID **29720**, verified by WMI ancestry and full command
line. Watcher PID **5528** sampled renderer PID 29720 directly. Across 18 two-second
samples, renderer private bytes peaked at **4,160,638,976**, system commit at
**16,021,618,688 / 24,344,514,560 (65.81%)**, and process count at **257**. Neither
stop guard fired. All owned processes exited naturally, no retry ran, and the exclusive
lease was released immediately when renderer exit was observed at 01:31:23 UTC.

## Mechanical validation

All 24 PNGs exist, are nonempty 1280x800 files, match their manifest byte counts, and
have 24 unique SHA-256 hashes. Requested and observed clocks match every filename: day
is about 08:00 and night about 23:00. Nearby-creature counts equal their deterministic
record-array lengths in every frame.

Nine destinations settle exactly at canonical X/Z. The retained dynamic offsets are:

| Destination | Day actual X/Z | Night actual X/Z | Largest component delta |
|---|---:|---:|---:|
| The Capacitor Grove | `-1080.103, 3020.000` | `-1078.215, 3020.000` | 1.785 m |
| The Crown Heartstone | `700.000, 2701.538` | `700.000, 2700.761` | 1.538 m |
| The Glass Field | `-309.877, 5051.814` | `-309.793, 5051.796` | 1.814 m |

All cameras remain above their resolved standing floor, with clearance from **1.793 m
to 7.379 m**. The manifest identifies production `CameraRig/Camera3D` at 70 degree FOV,
0.05 m near and 9000 m far, plus the shaped production `SpringArm3D` with 0.6 m margin.
Configured spring length is 5.2 m; several actual camera-to-player distances shorten to
about 1.79–2.34 m where obstruction handling engages.

## Pixel inspection and limitations

The ordinary HUD and labelled 08:00/23:00 clock are directly visible in all 24 frames.
The trainer is recognizable as a scale reference in **12/24** frames. Both Struck
Sentinel frames are blocked by a close tree; both Verge Rod Station frames by the white
pylon/trainer geometry; both Glass Field frames by a close creature and dark magenta
interior; both Stormheart Tree frames by the giant foreground flower/tree; and both
Crown Arch frames by the white arch/NPC. Capacitor Grove night and Crown Heartstone
night are also creature-obscured. The other twelve frames retain a recognizable trainer,
though several still have large foreground creatures.

These obstructions are disclosed for the independent judge. This lane made no retry,
composition repair, art judgment, or visual acceptance claim.

## Engine result and scope

The engine and wrapper logs contain no `ERROR:`, `SCRIPT ERROR`, crash, allocation
failure, or failed-survey marker. They retain 13 production warnings in each captured
stream: one physics-interpolation deprecation and missing-mipmap warnings for six
Stormwood terrain texture pairs.

No production, save, progress, campaign, world, camera, material, or capture-tool file
changed in this lane.
