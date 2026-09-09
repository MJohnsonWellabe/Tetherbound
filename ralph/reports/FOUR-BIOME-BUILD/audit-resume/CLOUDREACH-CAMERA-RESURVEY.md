# Cloudreach production-camera resurvey

Status: **24/24 corrected-camera frames captured and identity-validated.** This is a
mechanical catalogue-survey result, not a visual-quality verdict. Direct inspection
found six weak frames at three destinations where the trainer is obscured; they are
retained for the independent judge and were not recaptured.

## Evidence identity

- Branch / capture HEAD: `codex/four-biome-audit-resume-0908` / `f93ee9729e0118e08fec545f35f49bff3613c3a4`.
- Shared production-camera repair: `fe904abf2`.
- New output: `shots/catalogue/cloudreach/round-camera-20260909T012134Z/`.
- Retained baseline, untouched: `shots/catalogue/cloudreach/round-20260909T004031Z/`.
- Command: `tools/catalogue_survey.ps1 -Biome cloudreach -Godot C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe -Output res://shots/catalogue/cloudreach/round-camera-20260909T012134Z`.
- Manifest: `complete=true`, 24 planned / 24 captured, failures `[]`.
- Logs and telemetry: `engine.log`, `launcher.stdout.log`, `launcher.stderr.log`,
  `memory-watch.csv`, and `_sheet.png` in the new round.
- Completion evidence: `CATALOGUE SURVEY OK: 24/24 frames`. The detached helper's
  numeric exit code was not recoverable after its process object exited, so the complete
  manifest and terminal success line are retained instead of inventing an exit value.

The Settings-source preflight enumerated all 12 canonical Cloudreach destinations and
their 24 day/night frame IDs before launch. No baseline frame, manifest, contact sheet,
or report was overwritten.

## Process identity, resource guard, and lease

The hidden process chain was PowerShell helper PID **32324** -> 1 MB console launcher
PID **15668** -> actual non-console renderer PID **45496**. WMI ancestry and the full
command line tied that chain to this round before monitoring began. The resource watcher
targeted renderer PID 45496, not the console launcher, for 46 two-second samples.

Peak sampled renderer private bytes were **5,136,154,624**. Peak sampled system commit
was **18,341,330,944 / 24,344,514,560 bytes (75.34%)**, and peak process count was
**259**. Neither the greater-than-90% commit threshold nor the greater-than-400-process
threshold fired. The renderer, console launcher, and helper exited naturally; no process
was killed and no retry was launched. The exclusive full-world lease was released
immediately when renderer exit was observed at **2026-09-09 01:24:14 UTC**, before
offline validation. An unrelated headless AIM probe was identified and left untouched.

## Catalogue, clock, file, and camera validation

The validator's 24 expected frame identities equal both the manifest plan and captured
frames, in order. Every file exists, is nonempty and 1280x800, matches its manifest byte
count, and has a unique SHA-256 hash; all 24 day/night images therefore contain distinct
pixels. Every actual settled player X/Z equals the canonical requested X/Z exactly
(maximum absolute delta **0.0 m**).

Every frame records `observed_clock.requested` and `observed_clock.time_of_day` equal to
its filename label. Day frames report about **08:00** and night frames about **23:00**.
The manifest identifies the production `CameraRig/Camera3D` at 70 degree FOV, 0.05 m
near and 3500 m far, and the shaped production `SpringArm3D` with 0.6 m margin. Its
actual spring length is 5.2 m in all 24 frames.

All recorded cameras are above the resolved standing floor: the minimum clearance is
**2.832 m** and the maximum is **4.130 m**. Nearby-creature counts equal the length of
the deterministic evidence array in every frame. Those arrays are proximity metadata,
not a claim that each creature is visible in pixels.

| # | Destination | Requested X/Z | Settled player X/Y/Z | Floor Y | Camera above floor | Nearby creatures |
|---:|---|---:|---:|---:|---:|---:|
| 1 | Realm Gate Crag | `0, -130` | `0, 150.131, -130` | 150.000 | 2.962 m | 4 |
| 2 | Galefoot Waycamp | `-280, 520` | `-280, 180.031, 520` | 180.030 | 2.832 m | 6 |
| 3 | Three Bells Bridge | `-485, 1320` | `-485, 338.131, 1320` | 338.000 | 2.962 m | 6 |
| 4 | Broken Skyroad Arch | `350, 1940` | `350, 480.131, 1940` | 480.000 | 2.962 m | 0 |
| 5 | Windscar Beacon | `-260, 2680` | `-260, 500.131, 2680` | 500.000 | 2.962 m | 2 |
| 6 | Windscar Flight Aerie | `400, 3250` | `400, 610.131, 3250` | 610.030 | 2.932 m | 4 |
| 7 | Sky Shrine | `1110, 2940` | `1110, 1051.299, 2940` | 1050.000 | 4.130 m | 0 |
| 8 | The High Perches | `900, 2700` | `900, 1020.131, 2700` | 1020.000 | 2.962 m | 0 |
| 9 | Cliffhold | `-340, 3970` | `-340, 830.031, 3970` | 830.030 | 2.832 m | 0 |
| 10 | Old Wind Observatory | `430, 4500` | `430, 920.031, 4500` | 920.030 | 2.832 m | 0 |
| 11 | Summit Eyrie | `100, 5350` | `100, 1160.131, 5350` | 1160.030 | 2.932 m | 0 |
| 12 | Waterward Overlook | `-420, 5650` | `-420, 1110.131, 5650` | 1110.030 | 2.932 m | 0 |

## Pixel inspection and limitations

The ordinary HUD is present in all 24 frames: health and food, clock, minimap, main
story objective, creature slots, and the action strip are directly visible. Day/night
lighting differs as labelled. The trainer is directly recognizable as a scale reference
in **18/24** frames.

Both Windscar Beacon frames are almost completely blocked by a close rock face. Both Sky
Shrine frames are dominated by the foreground stone well/platform, which hides the
trainer. Both Waterward Overlook frames show open ground and a large pillar but no
recognizable trainer. These six frames retain canonical identity, clock, HUD, and camera
height evidence, but they are weak destination/trainer evidence and must be disclosed to
the independent judge. This lane made no visual acceptance claim and did not alter the
camera tool or production world to improve them.

## Engine result and scope

`engine.log`, stdout, and stderr contain no `ERROR:`, `SCRIPT ERROR`, crash,
allocation failure, or failed-survey marker. The only runtime warning is the retained
Cloudreach physical-surface warning for `cr_candy_broken_route_good_07` at
`(-88.9, 465.4, 2335.0)`.

No production, save, progress, campaign, world, camera, or capture-tool file changed in
this lane. This report validates the new survey evidence only; independent visual
judgment remains separate.
