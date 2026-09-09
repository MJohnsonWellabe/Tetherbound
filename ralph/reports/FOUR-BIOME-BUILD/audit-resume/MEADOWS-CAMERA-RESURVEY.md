# Meadows production-camera resurvey

Status: **20/20 corrected-camera frames captured and identity-validated.** The set is
usable for the Meadows catalogue except that both Burrow Warrens frames remain weak
audit evidence due to visible scene obstruction. This capture lane made no blind
visual-quality verdict and does not treat metadata alone as proof of a repaired view.

## Evidence identity

- Branch: `codex/four-biome-audit-resume-0908`
- Shared camera-tool repair: `fe904abf2`
- New output: `shots/catalogue/meadows/round-camera-20260909T011407Z/`
- Retained baseline, untouched: `shots/catalogue/meadows/round-20260909T002752Z/`
- Command: `tools/catalogue_survey.ps1 -Biome meadows -Godot C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe -Output res://shots/catalogue/meadows/round-camera-20260909T011407Z`
- Manifest: `complete=true`, 20 planned / 20 captured, failures `[]`
- Logs: `engine.log`, `wrapper.stdout.log`, `wrapper.stderr.log`
- Resource telemetry: `resource-monitor.csv`
- Engine/log result: `CATALOGUE SURVEY OK`; zero lines matching `^ERROR:` or
  `SCRIPT ERROR`. The detached wrapper's numeric exit code was not recoverable after
  its process object exited, so the manifest and terminal success line are the retained
  completion evidence rather than an invented exit value.

The Settings-source preflight enumerated all 10 canonical Meadows destinations and
their 20 day/night frame IDs before launch. No prior round, manifest, frame, contact
sheet, or verdict was overwritten.

## Catalogue, clock, and file validation

All 20 manifest frame IDs match the validator output. Eighteen frames settled exactly
at canonical X/Z. The Stronghold Approach pair again settled at
`(-40.0808, 7008.7515)` against requested `(-40, 7010)`, a 1.251 m post-pose delta
within the named destination; both time variants agree. No frame exceeded the 1.5 m
validation bound.

Every frame records `observed_clock.requested` and `observed_clock.time_of_day` equal
to its day/night label. Day frames report approximately 08:00 and night frames
approximately 23:00. All 20 PNGs exist, are nonempty 1280×800 files, and have unique
SHA-256 hashes. Every day/night pair therefore contains different pixels.

The manifest identifies the production `CameraRig/Camera3D` at 65° FOV with 0.05 m
near and 2000 m far planes. It identifies `CameraRig` as a shaped `SpringArm3D` with
0.6 m margin, and records settled player, rig, camera, and actual spring-length data
for every frame.

Nearby-creature counts range from 11 to 35 and equal the length of each frame's
`nearby_creature_records_160m` array. Every record has a deterministic node path,
species ID, position, scale, gameplay body height, and gameplay body radius. Recorded
species across the round are Bramblebun, Brooktail, Burrowback, Duskhush, Galecrest,
Meadowhart, Mosshell, Mudsnout, Paddlenewt, Pipwing, Reedwing, Sparkit, Stormtrail,
and Trailpup. This is identity/proximity evidence, not a claim that each creature is
visible in pixels.

## Hall floor and corrected view

Both Meadows Hall frames record:

- resolved authored floor Y `6.1720` versus Terrain3D Y `3.9231`;
- settled trainer Y `6.1720`;
- rig pivot Y `7.9220`;
- camera Y `9.0046`, **2.8326 m above the authored floor**;
- actual spring length `5.2 m`;
- matching 08:00 day and 23:00 night clock states.

Direct pixel inspection confirms the new camera is above the floor and shows the
Hall courtyard, supported trainer/NPC, supplies, banners, walls, and doorway from an
ordinary third-person view. The retained baseline's below-floor capture artefact is
absent. This verifies the capture defect is repaired for these Hall frames. It does
not claim every Hall prop placement or visual-quality criterion passes.

## Warrens usability result

Both Burrow Warrens frames record resolved floor Y `4.15`, trainer Y `4.22`, rig Y
`5.97`, and camera Y `6.16`, placing the camera about 2.01 m above the resolved floor.
The production spring arm shortened to about `3.15 m`, evidence that its obstruction
handling engaged.

Direct pixel inspection does **not** establish a clean, broadly usable Warrens scene:
the trainer is framed and the ordinary HUD, 08:00/23:00 clock, location title, cave
surfaces, and waterfall/opening are identifiable, but a nearby Burrowback fills much
of the right side while close dark geometry covers much of the remaining frame. The
night view is especially occluded. These two frames should be retained and shown to
the independent judge, but they should not be treated as complete Warrens coverage
without a reviewed supplemental-view decision. Per instruction, this lane made no
unreviewed retry and changed no production or capture code.

## Resource thresholds and lease

The exclusive full-world lease was held for the render and released immediately when
the wrapper exited. System committed memory sampled from 66.32% to 74.89%; process
count sampled from 247 to 249. Neither the greater-than-90% commit threshold nor the
greater-than-400-process threshold fired.

The monitor followed the wrapper's direct Godot console child, PID 30032, but its
reported 6.2 MB working set / 1.1 MB private bytes identify it as a small launcher,
not reliable renderer-allocation evidence. The actual renderer was likely a deeper
descendant that the direct-parent query did not identify. The system commit and total
process measurements are valid and retained; per-process renderer memory is explicitly
unproven. No process was killed and no second render was launched.
