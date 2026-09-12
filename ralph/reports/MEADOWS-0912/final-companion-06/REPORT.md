# Independent visual verdict — `final-companion-06`

**Overall: FAIL — formation still blocks the gameplay camera; Terrapup rest remains visually unjudgeable**

I verified `manifest.json` and inspected all eight 1280×800 PNGs at native
resolution. The package is structurally complete (8/8 planned frames, eight distinct
files, `complete: true`, and no top-level failures). Its fixture disclosure is
appropriately narrow: one production Meadows boot, production party/follower/player/
camera and Stronghold creature bed, real movement input for formation, and the shipped
bed assignment/recall/`RestingCreature`/`play_rest` path. It explicitly excludes
animation seeking, direct rest-state injection, combat, route and multiplayer claims.

That completeness is not visual acceptance. The formation frames visibly reproduce
the owner's camera-blocking complaint, while all four rest frames show only the
Stronghold stone wall and no Terrapup or bed.

## Strict 09/12 row verdicts

| Owner row | Verdict | Native-frame evidence |
|---|---|---|
| T0 #2 — companion walks beside the player rather than behind/blocking the camera | **FAIL** | The station is numerically on the player's right flank and `companion_behind_camera` is false, but the actual gameplay-camera result is still obstructive. In `01-formation-settled-day`, Terrapup's head, foreleg and shell consume roughly the right half of the view. `02-formation-settled-night` pushes the head/body across the centre and obscures the road around the player. `03-formation-left-motion-day` again devotes almost half the frame to the face and paw. `04-formation-right-motion-day` is the clearest failure: the shell/torso fills nearly the entire frame, leaving only a narrow world strip at left. The manifest itself shows why centre-only checks are insufficient: frame 04 reports the companion centre outside the frustum at `(1217, 847)`, yet its near-camera 3.85 m body still blankets the image. “Not behind camera” is not the owner's requested “beside without blocking camera.” |
| T0 #13 — Terrapup lays down correctly when resting | **HOLD** | The live transition receipt is materially stronger than prior failed runs: expected bed assignment and expected animation playback were observed, the follower was recalled, the production rest body was built at zero anchor error, the completed `faint` endpoint is recorded at 1.5417 s, and 15,616 skinned vertices were measured with no posed-surface failures. However, `05`–`08` contain no visible Terrapup, bed, or resting silhouette in either side/three-quarter or day/night view; every image is a close view of the Stronghold wall. The recorded posed height is also 3.600 m against a 3.85 m body height, which cannot by itself establish a convincing lay pose. The state transition is proven, but the owner's visible pose defect cannot be accepted or rejected from these pixels. |

## Fail-closed receipt audit

- **PASS — structural/live-state receipt:** all eight records exist at the declared
  resolution; formation uses the production camera and input; rest records repeat the
  same production assignment/playback/anchor and skinned-vertex facts. The skinned
  pose measurement no longer silently succeeds without vertex evidence.
- **FAIL — visual capture refusal:** each rest record contains a non-empty
  `capture_check` diagnostic stating that Terrain3D is streaming around the production
  `Camera3D`, not the audit camera, yet the top-level manifest still records no
  failures and declares itself complete. More importantly, the camera is visibly
  occluded by solid Stronghold geometry. A fail-closed acceptance harness must refuse
  these subjectless frames rather than count them as the four required rest views.
- **FAIL — formation acceptance metric:** centre/frustum and behind-camera booleans do
  not bound a large companion's screen footprint. Frame 04 demonstrates that a centre
  outside the image can coexist with near-total occlusion.

## Smallest required recapture

For formation, move the large-body station far enough laterally/forward of the camera
axis (or add camera-aware clearance using the live visual bounds) that settled,
left-motion and right-motion gameplay views all preserve the player and route. For
rest, seat the audit camera outside Stronghold solids, point it at the measured posed
bounds, stream Terrain3D around that active camera, and refuse the frame unless both
the bed and a useful fraction of Terrapup's posed bounds are visible. Recapture the
same 8-frame day/night matrix; the production transition path and skinned-vertex
receipt should be retained unchanged.

This report does not claim movement stability beyond the sampled inputs, recovery
effects, save/load persistence, combat behavior, route traversal, or multiplayer.
