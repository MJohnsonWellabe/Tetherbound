# Runtime forward coverage observer — Wave 4

Prepared for optional instrumentation of a **future** live run. The active fresh
campaign was not changed, restarted or retroactively credited. No full world,
render, import or gameplay test was run for this helper.

## Available evidence and acceptance

Prompt 78 Phase 1 requires no road sample below two creatures in the forward
180-degree view. The playable-first content floor also retains no critical-path
dead-travel gap over 120 m and all named encounters present/fightable. These are
not replaced by the static 250 m population contract. Cosmetic blind verdicts are
recorded once per biome and deferred; functional spawn/footing gaps remain open.

The existing `tools/gate_f/probe_road_creature_visibility.gd` uses
`road_creature_visibility_model.gd`: 10 m authored route samples, minimum two,
15 projected pixels at reference 720p/70 degrees, calibrated as one metre at
40 m producing 15 px. Its last recorded 36 routes/4,253 samples pass is static
authored placement/size evidence, not live residency, occlusion or terrain footing.

`tools/gate_f/capture_four_biome_road_creatures.gd` renders actual production
scenes/camera/player/directors at twelve deterministic stands. It records live
forward/frustum counts and 1280x800 PNGs, but its 130 m body cut and centre-frustum
test do not themselves establish projected readability or ray occlusion. Its
teleported/frozen stills are diagnostic coverage, not earned gameplay. Twelve
representative frames cannot establish continuous forward coverage.

The fresh four-biome driver records stage completion, actual fights, materials,
identities and final progression/failures. It previously had no per-distance
camera/body-visibility ledger. A successful uninstrumented run proves no more
forward visibility than its recorded evidence contains.

## New helper API and behavior

`tests/helpers/four_biome_road_coverage_observer.gd` exposes:

```
var observer = OBSERVER.new()
observer.start(tree, new_jsonl_path, optional_outdoor_classifier)
# Keep the instance alive while ordinary gameplay proceeds.
var summary = observer.stop()
```

The optional classifier accepts `(actual_scene, actual_player)` and must derive
its boolean from production state. No authoritative shared runtime road or indoor
classifier was found. Without one, the observer excludes actual Veilfall interior
via `contains_interior`, and labels other free exploration as `context: unknown`.
It must not be called guaranteed outdoor coverage. It records all such travel,
including mounted travel, and excludes combat, paused/menu-owned input and missing
world/player/camera/director periods. Scene boundaries reset distance continuity.

Each sample follows at least the existing 10 m of actual horizontal travel. It
records the current frame rather than synthesizing a view at an interpolated
position. Overshoot distance and any unobserved ten-metre intervals are explicit.
Within-scene transfers/rescues are not mistaken for densely sampled travel: large
displacements expose those missing intervals. No claim of no teleports is made.

The actual viewport's active Camera3D determines forward orientation and projects
the real body's foot/head endpoints. Pixel height is normalized by viewport height
to the existing 720p reference, with the unchanged 15 px floor. The old CP-2
calibrated estimate is recorded separately, not silently substituted for actual
camera projection. Forward requires the existing horizontal 180-degree half-plane.
Frustum inclusion is recorded separately because the owner contract is a half-plane,
not only the camera's narrower visible frustum.

Only living, in-tree, visibly enabled bodies returned by the live director count.
A camera-to-body-centre ray uses the existing capture centre at 52% body height;
it excludes only the local trainer collider, ignores trigger Areas, and accepts
an empty ray or first hit on that body. Another body, wall or terrain blocks credit.
No ray is cast for bodies already failing direction or pixel size. Each record
retains body identity/path/species/position/height, projected pixels, frustum status,
LOS blocker, actual camera/viewport, scene and travel distance, and below-two status.

Required route identities/polylines come from the existing ROAD model's exact data
sources and selection rules. Nearest polyline projection supplies route ID,
along-route distance and separation, explicitly `nearest_only_not_membership`.
There is no invented road-width acceptance threshold. Off-road travel is not
silently credited to the nearest road. Every summary reports `complete_coverage:
false`, including one with no below-two samples. Unvisited roads remain unproved.

The observer changes no camera, input, pose, creature, inventory, progression,
clock, scene or save state. It writes only the caller's new JSONL evidence file,
refuses overwriting existing files, and flushes each record so a later game failure
does not erase the preceding samples. Its observation and I/O cost has not been
profiled on the Ally. `stop()` disconnects the observer and closes the file.

## Limits and next validation

Projection is geometric, not a measured rendered silhouette. Body height includes
presentation bounds that may not match every animation. Ray collision cannot see
non-colliding visual foliage, transparency, material blending or overlapping
silhouettes; a single centre ray can also conservatively reject partly visible
animals. These records do not replace rendered evidence or the recorded blind
verdict. No scene/physics ray result was exercised by the focused math tests.

After the current campaign terminal, wire this helper only into a next authorized
run and retain its JSONL with exact source SHA. Inspect unknown contexts and every
below-two/undersampled record, and reconcile observed nearest-route metadata against
the required-route ledger. A separate expanded production coverage diagnostic is
still needed for required roads not actually traversed. Do not call twelve stills,
a static pass, or a clean partial observer log full forward coverage.

Validation: `--only=four_biome_road_coverage_observer` passed **4 tests / 31
assertions / 0 failures**, with no errors/warnings. Tests cover rotated camera
half-plane math, vertical independence, 720p threshold normalization, exact nearest
polyline distance/along-distance without membership claims, and current authoritative
required-route selection. Logs are `%TEMP%/wave4-road-observer-focus-console.log`
and `%TEMP%/wave4-road-observer-focus-engine.log`.

## Native runtime validation and frustum correction — 2026-09-08

`tools/_probe_live_road_coverage_observer.gd` now exercises the actual packed wild
CreatureBody, actual packed Player, actual Camera3D, native support/blocker
colliders and the live observer APIs. The director only supplies its explicit
fixture population list. The Player crosses the 10 m sampling interval through
ordinary stick input. Initial body/player placements and dead/hidden cases are
synthetic diagnostic fixtures, not campaign progress or road-coverage proof.

The first native run passed **18 checks**, exit 0, with no engine errors or
warnings, but its additional offscreen diagnostic exposed a policy defect:
Bramblebun at `(40, 0, -12)` relative to the actual scene returned `forward=true`,
`framed=false`, a clear ray, **57.8599 reference pixels**, and `credited=true`.
The observer calculated frustum membership but omitted it from the credit gate.
This initial log is retained as `.artifacts/live-road-observer-native.log` and
`.artifacts/live-road-observer-native-engine.log`.

The authorized narrow correction requires `framed` as well as the existing
forward half-plane, projected-size and LOS gates. The distinct `forward` and
`framed` fields remain available. No distance, pixel, sample-spacing, density or
other threshold was relaxed. The contract row now names the actual camera
frustum requirement.

One changed native run passed **19 checks, 0 failures**, exit 0, with no engine
errors or warnings. The exact offscreen body now has `credited=false`; the clear
forward body still passes. Other checks cover actual blocker occlusion, behind
camera rejection, actual fainted and hidden eligibility, supported Player
movement, real physics-frame observer hookup, JSONL contract/sample/summary,
actual sampled body identity, stop/disconnect/file closure, repeated-stop
idempotence and existing-file refusal without overwriting evidence.

Changed logs: `.artifacts/live-road-observer-frustum.log` and
`.artifacts/live-road-observer-frustum-engine.log`. Its actual JSONL is
`C:/Users/mattj/AppData/Local/Temp/tetherbound-live-road-observer-frustum/Godot/app_userdata/Tetherbound/native_road_coverage_1572956.jsonl`.
Existing focused observer tests also pass **4 tests, 31 assertions, 0 failures**,
exit 0; logs `.artifacts/live-road-observer-focused.log` and `-engine.log`.
Each invocation used a separate isolated APPDATA profile and engine log.

This validates native API compatibility and instrumentation lifecycle. It does
not render silhouettes, establish authored-road membership, prove indoor
classification beyond the explicit classifier fixture, or provide complete
four-biome visibility coverage. No full-world scene, import or campaign rerun was
used for this work.

After the750.55s campaign terminal, root wired the observer into the next
fresh driver before title input and stops/flushed it on every terminal path.
The observer summary remains separate from campaign_complete and always
complete_coverage=false; write/start errors are terminal failures. Actual
native validation then found and corrected off-frustum false credit; the
corrected observer passes19nativechecks and4tests/31assertions. The complete
composition parser passed before that narrow frustum change; no later fresh
campaign has started. Late Ride/recall false returns now record exact causes.
