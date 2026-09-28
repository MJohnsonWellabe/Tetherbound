# Cloudreach current matrix and exposed banks

F08#4 / M3 / ART_DIRECTION §§3–4,9 / ACCEPTANCE §4. Owned branch
`tb/x04-cross-game-visual-sweep`, draft PR365; Claude owns merging.

The current 36-frame matrix still fails both visual bars. It independently
confirms turf-covered vertical walls (13, 21, 28, 32), repeated cliff forms,
weak settlement/finale approaches and indistinct aftermaths. Houses exist at
Cliffhold: the approach survey's tower-dominated silhouette was not evidence
that its buildings were absent.

## Bounded repair

Ground crowns and route shoulders previously projected turf through X/Z on
every face, including steep cuts. Vertical faces stretched that texture into
grass stripes. The ground material now exposes the existing triplanar cliff
material as the triangle slope rises from 34 to 56 degrees, with a small
irregular transition. Its textures, colours, strata and normal detail come
from the same configured geology material used by the adjoining walls.

The cliff calculations are extracted unchanged into one shader include.
Ground material coverage uses the geometric triangle normal, separately from
its interpolated lighting normal. The first experiment used the latter and
left long grass smears near steep upper edges; the final uses the actual slope.
Gentle turf skips the six unnecessary rock texture samples. No mesh, route,
collision, creature placement or gameplay state is changed by this repair.

**Retain this bounded material repair.** The fresh anonymous comparison
inspected 32 native images (16 pairs) and ten full-matrix sheets. Set A is the
final candidate; B is baseline. **Ten pairs prefer A, six tie; no clear
environmental regression.** The strongest gains are 13 and 21, where exposed
stone replaces stretched grassy banks. Both sets still fail Bar A and Bar B.
[Paired judgment](cloudreach-banks/cloudreach-bank-paired-judge.md).

## Current matrix: what remains

The [independent current-matrix review](cloudreach-banks/cloudreach-current-matrix-judge.md)
inspected all 36 native images and all five sheets. **Bar A NO / Bar B NO.**
The original M1–M12 orders are in `CLOUDREACH-LANE/REPORT.md`; this run does not
claim to close them.

| Work orders | Current evidence and remaining requirement |
|---|---|
| M1/M2 placements and palette | Neon blade plants remain in 12/13. This matrix does not establish every old floating-prop or oxblood finding repaired. |
| M3 rock family | The bank change addresses stretched turf only. Giant smooth planes, disconnected near/far forms and pale cliff curtains still fail. |
| M4/M5 night/cloud sea | Night route visibility survives, but terrain form and motivated settlement light remain weak. Flat/detached cloud forms remain visible. |
| M6 scatter | Coarse grass strips, hard patch transitions and smooth empty ground remain across the route. |
| M7 finale landmark | 33/34 do not establish a strong readable 400/100 m arrival; the close dome in 29 is recognizable but isolated. |
| M8 homecoming | Judge cannot identify a meaningful environmental difference in 34/35 or 05/36. |
| M9 settlements | Galefoot has coherent cottages. Cliffhold needs inhabited activity, stronger terrace integration and an approach with more than its tower silhouette. |
| M10–M12 capture, follower, camera | 16/18 are architecture-obstructed and 19/20 do not prove a useful perch vista. These require valid current stands and the owning camera lane's results, not a parallel camera edit. |

The full matrix is an inherited **fixture**, not an ordinary follower-motion
witness. It forcibly places the companion roughly 1.8 m sideways and 1.6 m
forward, which contributes to the repeated trainer overlap. The shrine detail
18 also seats at y=1020 despite its requested y=1050. Failed images remain
useful failure evidence but do not by themselves diagnose live follower or
camera behavior. Zero capture skips is not a visual pass.

## Verification and provenance

- Baseline: `1c7b50f18`, with main `4ee9f4157` integrated. Final material patch
  captured on that same baseline. Both complete 36-frame runs exited 0 and
  every native PNG is exactly 1920×1080. The initial experiment also produced
  36 frames; its visuals are superseded by the final packet.
- Windows Godot 4.7 stable, Compatibility/OpenGL 3.3, GTX 1060 3 GB, borderless
  1080p, fixed 60 simulation steps. These are desktop art captures, not Ally
  performance measurements.
- Nine focused tests /149 assertions pass, covering the existing environment,
  cliff-strata and aviary architecture suites. The existing off-tree transform
  diagnostic in the environment test remains disclosed in its stderr.
- Independent source review finds no final blockers. It verifies all 16 cliff
  uniforms and the extracted calculation are preserved, parameter copying and
  normal transforms are sound, and the flat-turf fast path is valid.
- Main advanced to `4d55fddfd` during capture and is integrated in `f8df14db3`.
  That update changes no Cloudreach world/config/shader or shared camera files;
  the packet retains its actual pre-merge capture identity.
- Both runs emit the inherited unscoped `fly_tutorial_completed` fixture error,
  the unsupported candy placement warning, and two fail-closed wild-site
  warnings. Logs are preserved; no clean-execution or progression claim.
- [Manifest](cloudreach-banks/manifest.json) includes all 72 original native
  PNGs plus navigation sheets, image hashes, normalized source hashes and
  fixture/camera manifests. Capture adapters and launch scripts are archived
  as text. They only change output location and request 1080p from the original
  `tools/capture_cloudreach_frame_matrix.gd`.

No full F08#4, regional Bars A/B, motion, HUD, co-op or device-cost pass follows.
Rock sampling remains extra work on steep ground; derivative/branch cost and
triangle-boundary appearance still require motion/device validation.
