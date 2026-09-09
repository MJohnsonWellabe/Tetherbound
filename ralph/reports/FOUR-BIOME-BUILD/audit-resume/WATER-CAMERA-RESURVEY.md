# Water/Tidewake production-camera resurvey

Status: **48/48 corrected-camera frames captured and identity-validated** across all 24
canonical Water/Tidewake destinations. This is mechanical catalogue evidence, not a
visual-quality verdict.

## Evidence identity

- Branch / capture HEAD: `codex/four-biome-audit-resume-0908` / `4e653e9b33e20f2e9e4a36bc215b1e1ce52708b5`.
- Shared production-camera repair: `fe904abf2`.
- New output: `shots/catalogue/water/round-camera-20260909T013251Z/`.
- Retained baseline, untouched: `shots/catalogue/water/round-20260909T004837Z/`.
- Command: `tools/catalogue_survey.ps1 -Biome water -Godot C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe -Output res://shots/catalogue/water/round-camera-20260909T013251Z`.
- Manifest: `complete=true`, 48 planned / 48 captured, failures `[]`; capture
  01:32:57–01:35:22 UTC.
- Logs and telemetry: `engine.log`, `launcher.stdout.log`, `launcher.stderr.log`,
  `memory-watch.csv`, and `_sheet.png` in the new round.

The Settings preflight enumerated all 24 destinations and 48 day/night IDs. Those IDs
equal the manifest plan and captured rows in order. `CATALOGUE SURVEY OK: 48/48 frames`
is present. No baseline evidence was overwritten.

## Process receipt and lease

The hidden chain was PowerShell helper PID **15552** -> console launcher PID **24944**
-> actual non-console renderer PID **47432**, verified by WMI ancestry and full command
line. Watcher PID **34288** sampled renderer PID 47432 directly. Across 58 two-second
samples, renderer private bytes peaked at **1,704,714,240**, system commit at
**13,561,298,944 / 24,344,514,560 (55.71%)**, and process count at **261**. Neither
guard fired. All owned processes exited naturally, no retry ran, and the exclusive lease
was released immediately when renderer exit was observed at 01:35:32 UTC.

## Mechanical validation

All 48 PNGs exist, are nonempty 1280x800 files, match their manifest byte counts, and
have 48 unique SHA-256 hashes. Requested and observed time matches every filename: day
is about 08:00 and night about 23:00. Nearby-creature counts equal their deterministic
record-array lengths in every frame.

Twenty-three destinations settle exactly at requested X/Z. Aquaryn Tidal Basin retains
the expected dynamic settle difference:

| Frame | Requested X/Z | Actual X/Z | Largest component delta |
|---|---:|---:|---:|
| Day | `601.574, 1389.434` | `602.359, 1389.015` | 0.785 m |
| Night | `601.574, 1389.434` | `600.537, 1389.987` | 1.037 m |

All cameras are above the resolved standing floor, with clearance from **2.063 m to
7.827 m**. The manifest identifies production `CameraRig/Camera3D` at 70 degree FOV,
0.05 m near and 6500 m far, plus the shaped production `SpringArm3D` with 0.6 m margin
and configured 5.2 m length.

## Pixel inspection and limitations

The ordinary HUD and labelled 08:00/23:00 clock are directly visible in all 48 frames.
The trainer is recognizable as a scale reference in **44/48**. Both Veilfall Cascade
frames are fully obscured by close pale and pink creatures. Both Veilfall Mountain Crown
frames are dominated by a giant foreground creature, leaving only a small trainer limb
fragment. Those four frames retain identity, clock, HUD, and camera-height evidence but
are weak destination/trainer evidence. Aquaryn Tidal Basin has large nearby creatures
but the trainer remains recognizable in both variants.

These obstructions are retained and disclosed for the independent judge. This lane made
no retry, composition repair, art judgment, or visual acceptance claim.

## Engine result and scope

The engine and wrapper logs contain no `ERROR:`, `SCRIPT ERROR`, crash, allocation
failure, or failed-survey marker. They retain seven production warnings in each captured
stream: one physics-interpolation deprecation and missing-mipmap warnings for three
terrain texture pairs.

No production, save, progress, campaign, world, camera, or capture-tool file changed in
this lane.
