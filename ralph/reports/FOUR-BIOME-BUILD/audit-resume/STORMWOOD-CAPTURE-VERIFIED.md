# Stormwood catalogue capture — verified fresh round

Capture status: **complete and accepted as catalogue-survey input**. This is visual
audit evidence only. It used Settings debug travel and an audit-only frozen clock;
it is not campaign or progression evidence. No visual quality verdict was made by
this lane.

## Evidence identity

- Branch: `codex/four-biome-audit-resume-0908`
- Capture command: `tools/catalogue_survey.ps1 -Biome stormwood -Godot C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe -Output res://shots/catalogue/stormwood/round-20260909T004513Z`
- Output: `shots/catalogue/stormwood/round-20260909T004513Z/`
- Persistent logs: `engine.log`, `wrapper.stdout.log`, `wrapper.stderr.log`
- Resource samples: `memory-samples.csv`, two-second cadence, real Godot child PID
  23288
- Process identity: capture PowerShell PID 9180, console wrapper PID 23920, real
  Godot PID 23288, watcher PID 21872
- Exit: 0; manifest `complete=true`; 24 planned / 24 captured; failures `[]`
- Engine log: zero lines matching `^ERROR:` or `SCRIPT ERROR`
- Fixture disclosure: production Stormwood scene and ordinary gameplay HUD; real
  1.80 m trainer moved with `Game.debug_teleport_to`; clear weather and day/night
  clock are audit-only controls. No progress, HP, items, save state, encounters,
  access, retries, or judgment were injected.

The preflight validator enumerated 12 canonical Stormwood destinations and 24 stable
day/night frame IDs from `data/config/debug_teleport_spots.json`. Its positions are
numeric `Array[x,z]` values, and the render manifest preserves both requested
coordinates for every frame. All 24 PNGs are 1280x800, nonempty, and have unique
SHA-256 hashes. Every day/night pair differs at the byte level. The manifest records
the requested time identity for every frame, `trainer_visible_intent=true`, the
production and capture camera identities/transforms, and nearby creature counts.

Spot inspection across the first, middle, and final regions confirms the ordinary
gameplay HUD and 08:00/23:00 clock states. The close over-shoulder framing includes
the trainer where the destination is not occluded; foreground trees and creatures
can obscure that ruler in individual frames. This is disclosed for the contact-sheet
and blind-judge lanes rather than treated as a visual verdict or repaired with a
second capture.

## Destination and coordinate verification

Requested X/Z below are the canonical catalogue values. Actual X/Z are the manifest's
post-settle player positions. Nine destinations match exactly at both times. Three
settled slightly around collision or nearby interaction geometry; their maximum
offset is 1.818 m and is retained rather than described as an exact match.

| Destination | Region | Requested X/Z | Day actual X/Z | Night actual X/Z | Max delta |
|---|---|---:|---:|---:|---:|
| The Struck Sentinel | Cinder Verge | -320.0000, 240.0000 | -320.0000, 240.0000 | -320.0000, 240.0000 | 0.000 m |
| Verge Rod Station | Cinder Verge | -650.0000, 830.0000 | -650.0000, 830.0000 | -650.0000, 830.0000 | 0.000 m |
| The Lantern Pools | Glowmoss Hollows | -380.0000, 1400.0000 | -380.0000, 1400.0000 | -380.0000, 1400.0000 | 0.000 m |
| Crown Overlook | Glowmoss Hollows | 160.0000, 1980.0000 | 160.0000, 1980.0000 | 160.0000, 1980.0000 | 0.000 m |
| Rodline Post | The Conductor Run | -700.0000, 2300.0000 | -700.0000, 2300.0000 | -700.0000, 2300.0000 | 0.000 m |
| The Capacitor Grove | The Conductor Run | -1080.0000, 3020.0000 | -1080.1033, 3020.0000 | -1078.2152, 3020.0000 | 1.785 m |
| The Crown Arch | The Hollow Crown | 485.0000, 2700.0000 | 485.0000, 2700.0000 | 485.0000, 2700.0000 | 0.000 m |
| The Crown Heartstone | The Hollow Crown | 700.0000, 2700.0000 | 700.0000, 2701.5376 | 700.0000, 2700.7607 | 1.538 m |
| Lantern Hollow | The Deepwood | -450.0000, 3960.0000 | -450.0000, 3960.0000 | -450.0000, 3960.0000 | 0.000 m |
| The Fallen Giant | The Deepwood | -150.0000, 4460.0000 | -150.0000, 4460.0000 | -150.0000, 4460.0000 | 0.000 m |
| The Glass Field | The Dynamo | -310.0000, 5050.0000 | -309.8770, 5051.8140 | -309.7928, 5051.7959 | 1.818 m |
| The Stormheart Tree | The Dynamo | -100.0000, 5470.0000 | -100.0000, 5470.0000 | -100.0000, 5470.0000 | 0.000 m |

Camera-to-player distance is 5.219-7.300 m. Nearby creature count ranges from 0 to
61 within 160 m; that telemetry describes the production scene and is not a density
acceptance claim. Full-resolution frames are retained for the separate contact-sheet
and blind-judge lanes.

## SHA-256 inventory

- `stormwood__cinder_verge__01__the_struck_sentinel__day.png` — `d349f7f1e447ba227612febc35c39ecb1467ee4c7a8572b01f8e1359f8f09abe`
- `stormwood__cinder_verge__01__the_struck_sentinel__night.png` — `49c7e233b758057845710422673a3c57f93b48a8f9d7464d0045c4f77b6f21ce`
- `stormwood__cinder_verge__02__verge_rod_station__day.png` — `ae0997e7ebaa2e349020757223afec328a3f2a7f080dbe85beee0688239cf3ed`
- `stormwood__cinder_verge__02__verge_rod_station__night.png` — `1021769758807825fe9e0a03023f5759bff7fbb7181fb18f247d901baa4b9ca6`
- `stormwood__conductor_run__05__rodline_post__day.png` — `5b590d5fdbb4f5f5abf8b10fc2cc417b99f337f662013bec47ab0a9bbe969c4a`
- `stormwood__conductor_run__05__rodline_post__night.png` — `9f61fb99177ec4f6df8ea05b6ef02c8e9f2d5bc642b926be2d422435149524d4`
- `stormwood__conductor_run__06__the_capacitor_grove__day.png` — `70f7f8f4305a52cf3d0963ee33d05a59e8c1078231d9cadf900de2dc3b1c6692`
- `stormwood__conductor_run__06__the_capacitor_grove__night.png` — `a98f58271efe1b3b9ee9d20bc9fddf80859bb80d4738a0d08e190e7c8bc9b1b2`
- `stormwood__deepwood__09__lantern_hollow__day.png` — `872b4711787e08bbdeb9f58cd245bdea7a7e7dbc033f9c5a086954b4fb8d9d2f`
- `stormwood__deepwood__09__lantern_hollow__night.png` — `f33ead41cf8739bfe6cbc035fa890da04fe4a90f5eda16c96b5ff01e0e0a8928`
- `stormwood__deepwood__10__the_fallen_giant__day.png` — `af6cf041551803a75132cd78aaa16b218a77f899817081f59ecc302d00f0ab83`
- `stormwood__deepwood__10__the_fallen_giant__night.png` — `42f4a52bfe63d4a08e2c01df5c932510cb4fd80f9092ffb1157f7ef6df2f66f0`
- `stormwood__dynamo__11__the_glass_field__day.png` — `0c81c9c5cc84ddddb00d668ca316777a9513ff9355e0fd7e5b5e744c8f24a912`
- `stormwood__dynamo__11__the_glass_field__night.png` — `7ea3866b5e96c5f72a2eef569328988000f90fb75e9568b8c30576e38b23b18f`
- `stormwood__dynamo__12__the_stormheart_tree__day.png` — `0517cf6d670029bb326909269a22c8eef10d9fec241b932d27b3f6df540cd742`
- `stormwood__dynamo__12__the_stormheart_tree__night.png` — `14552fe25492016e89f5608e1cfba63a5aa27a6e81c5e74493b1b69a669763d0`
- `stormwood__glowmoss_hollows__03__the_lantern_pools__day.png` — `05dcc70e0d06855bddf6ac44222d007804a7c41b55414c72739d2b8a06c9d275`
- `stormwood__glowmoss_hollows__03__the_lantern_pools__night.png` — `965a897cca60845896a91ffc11a6fb2b7a5f27bbe287c5e018494ee4180924a6`
- `stormwood__glowmoss_hollows__04__crown_overlook__day.png` — `270c87589ad070b8422987a750c1e94ac86603551708b5cc5a4aa20d67185dc1`
- `stormwood__glowmoss_hollows__04__crown_overlook__night.png` — `1ffa78ac12db259152ba4bd1c3dda9d71b173fdc39f09a9791451f7f0d1112bd`
- `stormwood__hollow_crown__07__the_crown_arch__day.png` — `facd4fddf31d39770cdf488d51c19b5996695d30e09afc4b919e4dde5a6d5199`
- `stormwood__hollow_crown__07__the_crown_arch__night.png` — `18bb6a3ca21b783b56b7ee87a1ddaecee3e982b1a3ab6790e5974a6c271bfa1e`
- `stormwood__hollow_crown__08__the_crown_heartstone__day.png` — `cea18bd3ba7b30a5f32984a98841c42c1e95a3c0f583f9e617387faf34b07b01`
- `stormwood__hollow_crown__08__the_crown_heartstone__night.png` — `68dc31faeb966fc10bd3038d7147bde322a8ef33fddf59ab148050d47bb179ad`

## Host resource note and lease release

The capture held the exclusive full-world RAM/render lease. The mandatory watcher
recorded 34 samples for real Godot child PID 23288. System commit ranged from 46.25%
to 64.80% of the recorded limit, and process count ranged from 253 to 259. The real
child's sampled private bytes peaked at 4,277,202,944 and working set at
1,481,199,616 bytes. Neither stop threshold (more than 90% commit or more than 400
processes) fired.

The wrapper stderr contains 13 production warnings: one deprecated physics-
interpolation call and missing-mipmap warnings for six Stormwood terrain texture
pairs. They are retained verbatim and are not engine errors or a claim that the
visual bar passes. Godot, its console wrapper, the capture shell, and the watcher all
exited after the successful manifest. The full-world lease was explicitly returned,
and this lane launched no retry or further world render.
