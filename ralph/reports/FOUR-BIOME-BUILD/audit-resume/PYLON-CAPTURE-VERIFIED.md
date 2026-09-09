# Pylon post-repair capture verification — 2026-09-08

Status: **both canonical post-repair rounds are mechanically complete; the
Stormwood Verge rod station visibly carries the installed live material. A fresh
code-blind verdict remains required.** These observations do not claim visual
acceptance or close the audit finding.

## Capture identity and lease

Both rounds launched sequentially from repair commit
`2a5f291f377c9c589bda39c57d70cfa212509ab3` with the current
`tools/catalogue_survey.ps1` and Godot
`4.7.stable.official.5b4e0cb0f`. No worlds overlapped and neither capture was
retried. The exclusive full-world lease was released as soon as each renderer
exited naturally.

| Biome | Exact round root | Launch UTC | Actual renderer PID | Result |
|---|---|---:|---:|---|
| Cloudreach | `shots/catalogue/cloudreach/round-pylon-20260909T015726Z` | `2026-09-09T01:57:26.6318012Z` | `20912` | wrapper exit `0`; renderer exited; lease released |
| Stormwood | `shots/catalogue/stormwood/round-pylon-20260909T020124Z` | `2026-09-09T02:01:24.0773510Z` | `34912` | wrapper exit `0`; renderer exited; lease released |

Cloudreach used wrapper PID `20844` and console PID `41948`; Stormwood used
wrapper PID `20140` and console PID `16864`. The command shape was:

```text
tools/catalogue_survey.ps1 -Biome <biome> \
  -Godot C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe \
  -Output res://<exact-round-root>
```

The watcher sampled the actual non-console renderer every two seconds. It would
have stopped the round above 90 percent committed memory or 400 processes.

| Biome | Samples | Peak renderer private bytes | Peak commit | Peak processes | End UTC |
|---|---:|---:|---:|---:|---:|
| Cloudreach | 66 | `5,143,027,712` | `70.1575%` | `257` | `2026-09-09T02:00:00.481Z` |
| Stormwood | 28 | `4,262,772,736` | `66.6737%` | `259` | `2026-09-09T02:02:29.711Z` |

Neither guard fired.

## Mechanical verification

Each manifest reports `complete=true`, 24 planned frames, 24 captured frames and
zero failures. The captured frame IDs match the planned IDs in exact order.
Each round contains 24 PNGs at `1280x800`, all 24 SHA-256 hashes within a round
are unique, and every manifest byte count matches its normalized `res://` file.
Cloudreach PNGs range from `646,816` to `2,056,043` bytes; Stormwood PNGs range
from `580,964` to `1,706,898` bytes.

Every frame records player position, camera position, camera transform and
camera-rig transform. The production spring length is `5.2`. Cloudreach's
camera/player distance ranges from `5.820736` to `5.821381` m. Stormwood ranges
from `1.784988` to `5.821496` m because production spring-arm collision remains
active. No transform or camera value was changed for this material repair.

Requested and observed clocks agree for all frames. Cloudreach day observations
span `08.007679`–`08.008749` and night observations span
`23.007556`–`23.008318`; Stormwood spans `08.007091`–`08.008304` and
`23.007500`–`23.008336` respectively.

Both engine logs contain `CATALOGUE SURVEY OK 24/24` and no match for `ERROR`,
`SCRIPT ERROR`, `CRASH` or `FAILED`. Standard-error output contains existing
warnings: Cloudreach reports one unresolved physical pickup surface, and
Stormwood reports the existing physics-interpolation deprecation and terrain
texture mipmap warnings. No capture failure accompanied them.

## Material visibility

The affected Stormwood Verge rod station is large and unobstructed in
`stormwood__cinder_verge__02__verge_rod_station__day.png`. Against the preserved
pre-repair frame in `round-camera-20260909T013019Z`, the identical foreground
pylon changes from the geometry-only near-white fallback to the installed live
teal, dark-metal and bronze albedo. This is direct rendered evidence that the
new binding reaches an actual production consumer. The night mate also exists
in the complete round for the blind review.

The canonical Dynamo frames are too obstructed by nearby world geometry to
judge the repaired arena pylons. The camp and other rod-station placements are
not presented closely enough in this 24-frame route for a reliable pixel claim.
The Cloudreach summit frames likewise do not place either repaired Cloudreach
consumer in a judgeable foreground view; the summit-eyrie before/after pair is
visually unchanged at catalogue scale. Native geometry tests remain the proof
of binding for those consumers, while this round proves only that the full world
captures cleanly after the repair.

The exact round roots above are ready for sheet assembly and a fresh code-blind
critic. That critic must make the visual acceptance decision for both biomes.
No additional rendering or pixel-driven code tuning was performed in this lane.

## Workspace hygiene disclosure

The required Godot import validation left 287 tracked `.import` sidecars marked
modified by line-ending/stat refresh. Both staged and unstaged semantic diffs for
all of them are empty, and sampled worktree bytes match the committed blobs.
They remain unstaged and excluded from both pylon commits; cleanup was stopped
to avoid blocking the shared checkpoint and CI index operations.
