# P2-029 parked rest/resume comparison — prepared, not captured

This scratch harness uses the existing production creature inventory fixture in the Water scene at (35, 110), seed 2042, daytime, production trainer/camera/Sun. It is a pose lifecycle diagnostic: direct play_rest and real stop_rest on a parked creature, followed by restored idle. It does not exercise bed interaction, companion AI, walking, resource restoration, combat or an earned gameplay path. No visual acceptance is claimed.

## Exact comparison

Two sequential fresh native boots, each with **14 JPGs**: Riptusk and Torrentoad × four rest targets (0.1, 0.35, 1, 3 seconds) plus three resume targets (0.1, 0.35, 0.75 seconds). Total **28**, not eight. Both installed GLBs have a faint sampler maximum of 1.5416666666666667 seconds, read directly from their JSON chunks; native imported playback speed/length and receipts remain authoritative.

The two ZIPs each contain exactly data/config/water_creature_rest_visual.json, and differ only in its Boolean enabled: before=false, after=true. No pack replaces a body, model, collider, scale, height, animation clip, material, terrain or gameplay source. Production gate remains false. Each process mounts its ZIP before explicit super initialization; the base initializer is not implicit on Godot 4.7. Separate fresh APPDATA paths and unique SaveGame directories are installed before the inherited game reset.

The inherited capture_pose continues to create, stage/seat and park the production body and invoke play_rest; it alone frees that body after our capture_transition returns. All seven samples use the same body instance. No seek, pause, manual finish callback or repeated rest call occurs. The candidate must initially be pending with its AnimationPlayer playing; before must report active generic roll. The three-second photograph must report active/nonpending rest. Stop_rest must restore the exact pre-rest model pivot, clear both flags and resume the actual installed live idle animation.

## Camera and timing validity

Before parent capture_pose/play_rest, the wrapper observes the existing live camera until five rendered frames stay within a 1e-7 origin/basis window, bounded to ten seconds. It never reassigns or freezes the camera, and never delays observation after rest starts. The tighter convergence window leaves headroom for the 1e-6 per-lifecycle camera invariant.

Targets use real monotonic deadlines beginning immediately after inherited play_rest, or immediately after stop_rest returns. Actual postdraw elapsed time, lateness, animation position and pending/active receipt accompany every frame. IO/checkpoint work is included in elapsed time. A sample may be at most **0.15 seconds late**; paired before/after elapsed times must differ by at most **0.15 seconds** and samples must be strictly monotonic within each phase. These are fixture validity bounds, not a game FPS acceptance test. In particular the first two windows [0.10, 0.25] and [0.35, 0.50] cannot collapse together. A missed window records failure and retains its diagnostic image/checkpoint, stopping further samples rather than claiming 28 complete frames.

Resume witnesses zero-speed idle on a parked body, not locomotion. Camera origin/basis must stay within 1e-6 m / 1e-6 maximum component; exact lens/projection/aspect fields and actual Sun transform/color/energy/shadow settings are checked within each lifecycle and across boots. The actual image must be 1920×1080 and the viewport's current camera must be production Camera3D. Camera convergence, performance, contact and endpoint readability still require native validation.

## Evidence and failure handling

Read-only pre-rest and every-frame snapshots cover body local/global transform, scale/height/radius and capsule transform/disabled state/dimensions. Both variants must share pre-rest model pivot, physical body, stand, camera and Sun. Rest visual pivots may intentionally differ; resume pivots must exactly restore their own pre-rest snapshot.

Parent frame IDs, records, JPEG quality 0.87, stage/cleanup and final writer are retained. There is no reusable single-frame writer in the parent; only its small readback/JPG block is repeated in the override to add resume and per-frame receipts. The richer rest-final-manifest.json supplements the unchanged parent manifest.json. Both must be complete. Numbered checkpoints retain partial evidence.

Receipts retain frame SHA256, process gate/config hash, exact source/model hashes, prepared HEAD, actual launch HEAD, ZIP hash, wrapper/launcher hash, output/save paths, actual resolution/display/adapter and monotonic timings. HEAD can advance before launch with identical pinned source bytes; both boots must share actual HEAD and pass all pinned-file hashes.

The inherited parent writer has no FileAccess-open guard. The wrapper requires its actual readable manifest after return. A runtime-aborted parent writer cannot count as success: launcher requires terminal exit zero, both manifests, latest final checkpoint, 14 files per boot and successful pair validation. Hung children meet the process deadline, then only the owned Process object is stopped. Failed/partial files are never deleted or promoted. Wrapper manifest/checkpoint open/store errors enter failures and force nonzero exit.

## Review and launch

Root should inspect the wrapper/source metadata and run an isolated engine parser check before requesting a native slot. This preparation ran no Godot, imports or GPU work.

CPU-only preflight, without touching the shared lock:

    & .artifacts/phase2/rest-native-launch.ps1 -StaticPreflight

Only after obtaining the native slot:

    & .artifacts/phase2/rest-native-launch.ps1 -Round rest-native-01 -TimeoutSeconds 1800

The launcher holds D:\tetherbound\RENDER_LOCK.json with a unique token and exclusive file handle across both boots. An empty lock is a race safeguard, not queue authorization. Only its matching token is released after verifying the last owned child terminal; an unverified child leaves the token retained. Each child has a deadline plus bounded ten-second termination cleanup. Environment restores in finally. No kill-by-name or unrelated-PID cleanup occurs.

Fresh outputs are .artifacts/phase2/p2029-rest-native-01-before/ and ...-after/; per-boot APPDATA/stdout/stderr, rest-native-01-launcher.json and rest-native-01-comparison.json are adjacent. Failed exits/partial manifests stay authoritative. Retry requires a fresh round. Launcher never rebuilds packs or updates hashes: changed source requires explicit review and CPU prepare rerun.

## Preparation result

CPU source/ZIP/gate/count checks passed. CPU boundary probes accept 2.98e-8 basis drift, reject excess origin/basis drift or lens changes, accept the 0.15-second lateness boundary, and reject missed windows, nonmonotonic samples and excessive paired elapsed differences. PowerShell AST parsing and static preflight passed. No engine parser, native capture, timing stability, contact, occlusion, restored-idle appearance or visual acceptance has been established. Live background creatures/vegetation may vary; this harness does not freeze them.

## Native01 failure and telemetry-only revision

The preceding preparation section is historical. Native01 subsequently failed its before boot, with launcher/child terminal exit 1. Its immutable before manifest contains one accepted Riptusk rest frame: target 0.1 s, actual 0.133127 s, zero recorded camera delta at that sample. The next attempted 0.35 s sample failed the camera invariant, and the previous wrapper discarded its measured camera/delta before returning. Native01 therefore cannot establish the magnitude, axis or mechanism of the change. It must not be described as numerical drift or a candidate-pose failure; the candidate boot did not run.

Current production camera_rig.gd _process calls look/tracking/follow and impact roll; _follow uses a live target, exponential position follow, vertical/shoulder sweeps and recovering/body-limited spring length. SpringArm collision can also affect the child lens position. These are plausible sources to distinguish, not diagnoses of native01. No production camera or tolerance changes are included.

The revised wrapper adds sample_observations before any sample validation return. Each attempted sample retains actual camera, camera delta, monotonic time/target/lateness, physical body and rest receipt, plus player transform/velocity/floor, rig transform/yaw/pitch/follow parameters, arm requested/hit length, target identity/transform, child-camera local transform and actual viewport-camera identity/transform. The same context is recorded at lifecycle entry. A failed observation attempts a separate rejected__<frame-id>.jpg with actual size/hash/IO status. This image is explicitly diagnostic and never enters the accepted frames array or its 14-frame completeness count. Failure still checkpoints and exits nonzero.

A bounded baseline-only diagnostic is now available; it keeps both species, all four rest and three resume targets, all original guards and the 14-frame expectation. It never launches after:

    & .artifacts/phase2/rest-native-launch.ps1 -Round rest-native-02 -BeforeOnly -StaticPreflight
    # Only after root parser/review and a newly granted native slot:
    & .artifacts/phase2/rest-native-launch.ps1 -Round rest-native-02 -BeforeOnly -TimeoutSeconds 1800

Its receipt says before_only=true; a successful validation writes rest-native-02-before-validation.json, never a paired-comparison receipt. Failed/partial output stays failed. Native01 folders/logs/receipt are not changed. Revised CPU/source checks, PowerShell AST parse and baseline-only static preflight passed, reporting exactly one before boot and 14 required frames. No revised engine/parser/GPU execution has been performed by this agent.

Native01 also exposed a separate final-manifest serialization defect. Its parent frame's physical dictionary exactly equals fresh pre-rest provenance, but the final manifest's parsed-and-reserialized frame does not: one basis component is 8.74227765734759e-8 in parent/provenance and 8.742277657e-8 in final. That approximately 3.48e-18 serialization difference would trip the offline exact checker even though the native physical check passed. The revised final writer replaces its parsed frames with the original native _records before writing alongside native provenance. Physical invariants and their exact equality checks remain unchanged; this does not explain or pardon the separate runtime camera failure.

Original native01 wrapper, launcher and checker were reconstructed by reversing only this revision's owned changes and saved under rest-native-01-source/. Their SHA256 values exactly match the original reviewed preflight: wrapper b31e2cd3b4090ea5c6cb367366c02f665793394ea6bc2a02bb6c95708170412c; launcher 5db66d403cdd31b2f8bbe5afc94839c26390660fe42bca6db2a1dcbbef8f6a6d; checker 8a76a22183b437ce9f4ccd7acda9ff608eac28217b099f074bfcb48257f8e981. The unchanged source-hashes metadata was copied byte-for-byte and its parsed contents match native01's embedded prepared_source. This preserves the failed packet's source rather than retroactively substituting the new wrapper.
