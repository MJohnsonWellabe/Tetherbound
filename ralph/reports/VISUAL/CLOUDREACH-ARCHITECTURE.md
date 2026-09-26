# Cloudreach aviary architecture and trail transitions

X04 / F08 / ART_DIRECTION §§3,4,7 / ACCEPTANCE §4. Isolated branch
`tb/x04-cloudreach-aviary`, PR #338, implementation `ed849997f`, based on main
`51d6dc44e`. Claude owns integration and merge. Whole chapter and whole-game
Bars A/B remain open.

## Observed defects and repair

Native production views show rectangular entrance lintels, a repetitive thin
dome lattice, lanterns placed from jamb centres, decorative trees intersecting
the inhabited footprint and entrance sightline, and near-opaque cream panels
that form a bright white shell at night. Cloudreach trail edges also reveal
square dirt fragments from the shader's fixed 5.6 cm coverage grid.

The candidate gives the four entries curved stone arch frames, articulates
the piers and crown, and separates eight main ribs from sixteen secondary
ribs. The original pier boxes remain hidden as the production footing sampler's
geometry witnesses. All twenty original colliders, route clearances, footprint,
oculus and pylon anchor remain unchanged.

Four installed Quaternius wall lanterns replace the floating post/cube fixtures.
Their metal housings stay opaque; small inset cores and non-shadowing warm
lights supply illumination. The aviary uses the existing Quaternius masonry
textures with its own weathering parameters; surrounding route wings and
Team Tether palettes retain their materials. Blue-grey translucent panes
replace the near-opaque cream treatment.

The decorative tree pass omits trees from the aviary footprint and its eastern
overlook approach corridor, after consuming the same random placement values.
Other sites retain their deterministic scatter. No colliders or gameplay trees
are changed. Path dirt now blends into the exact shared wet/dry turf sample
inside the existing coverage envelope; outside it, the crown remains visible.
Route meshes, height offsets and physics are unchanged.

No new source assets or generation: all materials/props derive from the
installed families already documented in ART_DIRECTION. Architecture is
repo-native geometry; the reference board supplies direction only.

## Verification

- Native Windows Godot 4.7 `5b4e0cb0f`, Compatibility/OpenGL 3.3, GTX 1060 3 GB,
  driver 560.94, 1920×1080. These are desktop captures, not Ally performance proof.
- Baseline: 9 frames, zero skipped, exit 0; candidate: 13 frames, zero skipped,
  exit 0. Overview day/dusk/night; entrance/interior/reverse day/night; candidate
  also includes lower gate/high shrine day/night to inspect the shared path.
  The gate/shrine comparison uses the earlier `025a09d9d` survey. Owned Cloudreach
  visual files are unchanged between that survey and this branch's base.
- Four focused suites (`cloudreach_aviary_architecture`, `cloudreach_environment`,
  `cloudreach_summit_eyrie_catalogue`, `cloudreach_summit_paving`): **11 tests,
  160 assertions, zero failures**. Tests inspect actual curved mesh winding and
  clearance, original collision/footing inputs and anchor, and lamp transforms.
  The existing environment fixture emits an off-tree global-transform diagnostic.
- `smoke_cloudreach_aviary.gd`: **PASS**, actual capsule casts through both route
  bands and open-oculus ray. 20 colliders, 24 ribs, 9 rings, 4 entries, apex 36 m.
- Independent source review `first_shore_fence`: **no blockers**. Confirmed
  footing witness order, arch winding/clearance, lamp transforms, material
  isolation, unchanged scatter RNG consumption and shared turf compatibility.
- Independent image-only `cloudreach_architecture_judge` inspected all 9 baseline
  and 13 candidate frames, matched earlier gate/shrine views, the chapter boards
  and five gameplay references. **Candidate preferred; bounded improvements
  accepted** for arches, summit visibility, transparent dome and softened trail
  fringe. **Bar A OPEN / Bar B OPEN.** This is not aviary/chapter acceptance.

The capture adapter `tools/capture_cloudreach_architecture.gd` inherits the
existing production audit boot and camera. It poses progression, clock,
companions and stands; it does not prove earned traversal. Place views park the
companion behind the camera. Baseline and candidate both emit the existing
unscoped `fly_tutorial_completed` chapter-event error and unsupported broken-route
candy placement warning. No new script/shader diagnostic was observed.

Raw captures remain local under `shots/aviary-baseline-51d6dc44e-v2/` and
`shots/cloudreach-architecture-candidate/`; the single contact sheet below is
the committed image evidence. A final fetch found main `a307e0f94`, with no
intervening changes to this PR's Cloudreach production files.

![Matched production views](_sheet_cloudreach_architecture.jpg)

## Limits

The judge specifically flags the horizontal grey hoop crossing the new arch,
large uninterrupted interior walls, differing detail scales, a faint straight
outer path boundary, the lower gate's apparent suspension and the clipped shrine
witness. Removing the old white night shell reduces its implausible brightness,
but the dark-blue dome now needs intentional architectural illumination to
replace that lost destination contrast. Small entry lamps are insufficient;
nighttime landmark contrast remains explicitly open.

The broader terrain/grass hierarchy, stacked-cliff identity, full settlement and
route matrix, night integration and creature/material quality remain open.
The added curved segments/lights have not received device performance telemetry.
No whole-region, whole-game, earned-playthrough or engine-PR-CI acceptance claim.
