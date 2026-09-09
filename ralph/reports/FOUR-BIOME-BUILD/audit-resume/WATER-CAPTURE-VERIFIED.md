# Water/Tidewake catalogue capture — verified fresh round

Capture status: **complete and accepted as catalogue-survey input**. This is visual
audit evidence only. It used Settings debug travel and an audit-only frozen clock;
it is not campaign or progression evidence. This lane made no visual-quality verdict.

## Evidence identity

- Branch: `codex/four-biome-audit-resume-0908`; capture HEAD `4a3965a2f`.
- Capture command: `tools/catalogue_survey.ps1 -Biome water -Godot
  C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe
  -Output res://shots/catalogue/water/round-20260909T004837Z`.
- Output: `shots/catalogue/water/round-20260909T004837Z/`.
- Persistent logs: `engine.log`, `wrapper.stdout.log`, `wrapper.stderr.log`.
- Resource samples: `memory-watch.csv`, two-second cadence, explicitly attached to
  real Godot child PID 12552 rather than console wrapper PID 14680.
- Runtime: Windows display, Compatibility renderer, NVIDIA GeForce RTX 3050 6GB
  Laptop GPU, 1280x800; capture 00:48:42–00:51:14 UTC.
- Exit: 0; manifest `complete=true`; 48 planned / 48 captured; failures `[]`.
- Engine and wrapper logs: zero matches for `^ERROR:`, `SCRIPT ERROR`, crash,
  out-of-memory, or allocation-failure patterns.
- Fixture disclosure: production Water Archipelago scene and ordinary gameplay HUD;
  real 1.80 m trainer moved through `Game.debug_teleport_to`; clear weather and the
  day/night clock were audit-only controls. No progress, health, items, save state,
  encounters, or campaign completion were injected.

The preflight validator enumerated all 24 canonical Water/Tidewake Settings
destinations and 48 stable day/night frame IDs from
`data/config/debug_teleport_spots.json`. The render used the corrected typed-array
coordinate parser already present in `tools/catalogue_survey.gd`. Offline comparison
found exactly the same 48 IDs in the manifest: no missing, extra, or duplicate
identity. All 48 PNGs exist, are nonempty 1280x800 images, and have unique SHA-256
hashes. Every destination's day and night hashes differ.

## Destination and coordinate verification

The manifest's requested X/Z values agree with the canonical catalogue for every
frame. At 23 of 24 destinations, day and night settled on the same X/Z and matched
the requested coordinate exactly. Aquaryn Tidal Basin retained a small dynamic
settle offset:

| Frame | Requested X/Z | Actual X/Z | Delta |
|---|---:|---:|---:|
| Aquaryn Tidal Basin — day | 601.57, 1389.43 | 602.36, 1389.01 | 0.89 m |
| Aquaryn Tidal Basin — night | 601.57, 1389.43 | 600.54, 1389.99 | 1.18 m |

The day/night actual positions at that destination differ by about 2.07 m. Both
remain at the authored basin and preserve their canonical frame identity; the
difference is disclosed rather than represented as an exact same-position pair. No
rerun was made because the full round completed cleanly and a blind rerun without a
changed hypothesis is prohibited.

Every manifest row records `trainer_visible_intent=true`, production and capture
camera identities and transforms, and an ordinary-HUD production fixture. Camera to
trainer distance ranges from 5.382 m to 7.262 m. Nearby creature counts range from 1
to 10 within 160 m. Representative full-resolution inspection across First Shore,
Tidal Cradle, Veilfall, and Deep Watch confirms the trainer and ordinary gameplay HUD
are visible; the Tidal Cradle frame also provides direct creature/trainer scale
context. Whether individual compositions or visibility meet the full visual rubric
belongs to the separate code-blind judge.

## Preserved warnings

The run produced seven distinct warning texts, each appearing in both captured log
streams (14 matches total): the existing
`instance_reset_physics_interpolation()` deprecation and missing-mipmap warnings for
the albedo and normal textures of `meadow_grass`, `dirt_path`, and `rock_scree`.
These warnings are preserved in the logs. They did not prevent any frame and were not
altered or retried by this evidence-only lane.

## Host resource receipt and lease release

The capture held the exclusive full-world lease. The watcher recorded 56 samples.
Maximum system commit was 54.58%, maximum process count was 261, and maximum sampled
real-Godot private memory was 1712.5 MiB. Neither abort threshold (greater than 90%
system commit or greater than 400 processes) was approached.

Wrapper PID 47420, console PID 14680, real Godot PID 12552, and watcher PID 9944 all
exited after the successful manifest. The full-world lease was explicitly released
to root before this report was written, and this lane launched no further Godot
process.

