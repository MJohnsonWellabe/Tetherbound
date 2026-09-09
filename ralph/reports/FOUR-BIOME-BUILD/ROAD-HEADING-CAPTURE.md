# ROAD paired-heading capture — partial reproduction, 2026-09-09

## Result

This bounded reproduction produced the two synchronized sample-37 frames and
then stopped at the first ordinary-walk failure before sample 38. It did not
reach samples 38–43 and did not produce the sample-43 pair. This is therefore
partial static visual evidence only, not the requested full 65 m reproduction,
not a ROAD acceptance result, and not campaign or performance credit.

At sample 37 the unchanged recorded heading gave an observer proxy count of
zero. Turning the production camera through ordinary look input to the local
37→38 walking tangent gave a proxy count of three. Both order-1910 Meadowharts
were alive in both observations: under the recorded heading both failed the
camera-relative forward half-plane; under the travel heading the first was
credited and the second failed the existing centre-ray test. These are proxy
classifications. Rendered silhouette readability is reserved for a fresh blind
judge.

## Fixture and provenance

- Branch/head launched: `codex/four-biome-audit-resume-0908` at
  `4379c47bbf1a8a8aa2554f841a1a0316068b59d3`.
- Scene: unmodified `res://scenes/world/meadows_playground.tscn`, production
  trainer, `CameraRig`, FOV 70, HUD, live wild lifecycle and live spawns.
- Setup: one disclosed `Game.debug_teleport_to(x,z,"meadows")` to the exact
  sample-37 XZ. It settled grounded at
  `(15.661647, -0.021751, 15.837775)`, zero horizontal gap from the request.
- After setup, the tool used only production movement/look actions and
  `tests/helpers/stick_navigator.gd`. There was no actor/camera transform reset,
  HP, item, party, progress, save-copy, spawn, time, art, production, config or
  acceptance mutation.
- Body classification called the existing observer's read-only `_body_sample`
  and retained its forward/size/frustum/centre-ray order. All live eligible
  bodies and raw rejection fields are in the ignored manifest.
- Native executable:
  `C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe`
  with `--rendering-driver opengl3 --resolution 1280x720`; never headless for
  either graphical attempt. APPDATA was isolated per attempt.
- Corrected run output:
  `res://shots/road-heading/20260909T034351Z/`. The manifest records physical
  render target `1280×720` and logical camera viewport `1920×1080`; every saved
  PNG was checked as `1280×720`. The logical dimensions were preserved for
  `Camera3D.unproject_position()` and the observer's 720p normalization.

## Accepted frames and blind mapping

The copies below are byte-identical; no crop, resize, relabel or other image
manipulation was performed.

| Blind file | Source frame | SHA-256 | Bytes |
|---|---|---|---:|
| `blind/frame-a.png` | `sample_37__original_recorded_heading.png` | `4BBFD9A82B4ECDBF93DB72E007F7C150BC3ECB6755B72A00CD12FCCA3761C289` | 1,893,149 |
| `blind/frame-b.png` | `sample_37__travel_facing.png` | `A8E89EEE9C16C1267342431884D88855A6AA0F96206EB7F6ACEA4F1E0527A16B` | 1,786,485 |

The mapping is intentionally recorded here but is not encoded in the blind
filenames. Root owns the fresh blind judgment.

## Synchronized sample-37 metadata

### Original recorded heading (`frame-a`)

- Player grounded at
  `(15.661647, -0.021751, 15.837775)`.
- Requested yaw/pitch: `-17.237545° / -24.998412°`; observed yaw/pitch:
  `-17.100401° / -25.046832°`.
- Eligible live bodies: 969. Observer proxy credited: 0; below two.
- `Wild_meadowhart_1910_1`: alive, height 3.45 m, position
  `(2.656428, -2.403355, 80.988716)`, first rejection
  `camera_relative_forward_half_plane`.
- `Wild_meadowhart_1910_2`: alive, height 3.45 m, position
  `(2.492726, -2.845518, 83.801521)`, first rejection
  `camera_relative_forward_half_plane`.

### Travel-facing (`frame-b`)

- Same grounded player position and FOV.
- The local historical outgoing tangent, sample 37→38, was
  `(-0.221662, 0, 0.975124)`. Observed horizontal camera forward was
  `(-0.218911, 0, 0.975745)`, dot `0.999996`.
- Observed yaw/pitch: `167.354915° / -25.046832°`.
- Eligible live bodies: 969. Observer proxy credited: 3; at least two.
- `Wild_meadowhart_1910_1`: alive at the same position and height, credited by
  the existing observer.
- `Wild_meadowhart_1910_2`: alive at the same position and height, first
  rejection `centre_ray_blocked`.

## Traversal stop

The next required point was sample 38 at
`(13.452843, 25.554613)` in XZ, 9.965 m from the settled sample-37 start. The
shared navigator spent its full 1,200-physics-frame leg budget and stopped
grounded at `(12.393356, -0.460576, 21.030050)`, still 4.647 m from the point.
It reported no confined-state reset. The capture meter accumulated 79.741 m of
actual horizontal movement, showing repeated local travel rather than arrival.
The net attempted-walk direction was `(-0.532706, 0, 0.846300)`; its dot with
the sample-37 travel-facing camera was `0.942388`, above the required 0.9.

The tool then released input, wrote the terminal manifest, exited 1, and was not
run a third time. There are no accepted sample 38–42 intermediate receipts and
no sample-43 frames. The route criterion was not relaxed. The separate
[informed diagnosis](ROAD-HEADING-INFORMED-DIAGNOSIS.md) owns the source/runtime
interpretation: it identifies a fresh-fixture prerequisite mismatch at the
locked TrailGate as the strongest supported cause while keeping direct collider
attribution unproved. This stop does not establish a new production navigation
defect. No progress or gate state was injected and no rerun was made.

## Process guard and log scan

The hidden console wrapper was PID 33812 and the monitored actual non-console
Godot child was PID 32500. The guard sampled 38 times, observed maximum system
commit 75.569% and maximum process count 270, and did not fire. It would have
stopped only that owned process chain above 90% commit or 400 processes.

The corrected run's stderr scan found:

- four `SCRIPT ERROR` records from the capture tool's clock reporter calling a
  nonexistent `day_cycle.gd::time_of_day()` method;
- the terminal `ERROR` for the ordinary-walk failure before sample 38;
- existing warnings for Terrain3D textures without mipmaps and deprecated
  physics-interpolation reset usage.

Because of the reporter error, frame and walk clock dictionaries are empty and
exact world time/weather are **not verified**. The PNGs remain synchronized
with player, camera and body metadata, but support static visual judgment only.
Static inspection found the correct APIs are `preset_at(hour)` and
`interpolate_at(hour)`. The committed helper uses those guarded methods; that
small reporter correction was not executed graphically and no clean-run claim
is made.

## Preserved first setup failure

The first attempt is preserved at
`res://shots/road-heading/20260909T033505Z/`: zero frames, zero walk, exit 1.
It stopped before teleport because the tool incorrectly treated the project's
logical `1920×1080` canvas rect as the physical output size. Its actual
non-console child PID was 45656; the guard did not fire (maximum commit 69.746%,
maximum process count 268). Existing capture precedent established the corrected
hypothesis: set/verify `root.size` for physical output while retaining the
logical camera viewport for projection math. The second attempt tested only
that changed hypothesis.

Ignored receipts:

- `shots/road-heading/20260909T034351Z/manifest.json`
- `shots/road-heading/20260909T034351Z/walk-receipts.jsonl`
- `shots/road-heading/20260909T034351Z/process-monitor.json`
- `shots/road-heading/20260909T034351Z/godot.stdout.log`
- `shots/road-heading/20260909T034351Z/godot.stderr.log`
- `shots/road-heading/20260909T033505Z/` (first-failure manifest/log/monitor)
