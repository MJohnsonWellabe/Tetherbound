# Creature crowding: next bounded diagnosis

Status: proposed diagnostic; no production edit authorized or made here.

The corrected Veilfall canonical frames still show neighbouring bodies crowded
together and overlapping silhouettes. The previous near-total night camera
occlusion was contaminated by a capture pitch leak; that instrument defect is
fixed and documented in `VEILFALL-VISUAL-ATTRIBUTION.md`. These are separate
findings. Do not patch the shared camera merely to repair a misleading catalogue
comparison, or treat silhouette overlap as proven physical interpenetration.

## Source facts and competing causes

- Water `site_spawn_plans` gives ground members the same authored site centre;
  inherited `cloudreach_encounter_director::_find_wild_spawn` then separates them
  by gameplay `body_radius` plus a small foot margin and verifies supported ground.
  It does not measure the rendered mesh footprint. This is a shared admission
  mechanism used beyond this local waterfall, with a Water-specific site adapter.
- `creature_body::_fit` fits art height and allows a footprint up to the collider
  diameter times species `footprint_allowance` (default 2.4). Thus visible claws,
  tails and ornament may extend beyond the gameplay capsule by design. The collider
  must not silently grow and retune combat merely to satisfy an image.
- Authored ROAD pairs are exempt only from trainer/wild physical collision to
  preserve the narrow walking corridor. They still collide with terrain, other
  bodies and attacks. Reversing that exemption can recreate a traversal blocker.
- The production camera already has a sphere sweep (0.25m) and margin (0.6m),
  excluding its current target. It responds to physics shapes, not every rendered
  appendage. Actual rendered geometry can therefore overlap the view even if the
  camera respects the capsule. No runtime proof yet isolates this as the residual
  cause at the corrected -12 degree camera.

## Proposed next instrument and ownership

Own only a new `tools/probe_creature_visual_clearance.gd` plus this report until
the cause is measured. One tiny native fixture, using installed production
creature scenes/materials and the existing render-bounds helper, measures the
visible Water Cragclaw, Mirejaw and Mangrove Monitor: declared capsule dimensions,
rendered local bounds, horizontal extent beyond capsule, and expected separation
under the existing admission rule. Use real parsed species/config; no new art,
mesh shrink, changed collider or authored actor relocation. This is synthetic
asset/geometry diagnosis, never route acceptance. AABB overlap is conservative
evidence and must not be labelled a triangle-level collision proof.

Then decide whether a bounded runtime observation is necessary to distinguish
initial admission spacing from later wandering and camera clearance. Instrument
actual nearby node identities, native camera poses, physics-collider overlap and
render-bound intersection without moving actors. Preserve the existing canonical
and ordinary views, and carry camera implications across all four biomes if a
shared camera change becomes justified. A spawn-spacing fix would require its
own supported-ground and route-visibility proof in every affected biome, keeping
the number and size of creatures and a traversable corridor.

No further waterfall material work belongs to this issue. Do not remove wildlife,
teleport actors, shrink meshes, change combat reach, or brighten the whole world
to manufacture a readable frame. Choose the implementation only after the
diagnostic distinguishes the actual mechanism.

## Approved tiny diagnostic: first-attempt result

Root approved this geometry-only probe. `tools/probe_creature_visual_clearance.gd`
parsed and ran successfully on its first native execution, 1.90 seconds, inside
the 20-second watchdog with an isolated profile. Raw log:
`.artifacts/creature-clearance-20260909/engine.log`. All three actual installed
production bodies built; no native/script error or warning occurred. No world
scene, player route, combat, spawn mutation or gameplay acceptance was exercised.

| Installed body | Rendered rest bounds W x H x D (m) | Capsule radius (m) | Same-species admission minimum (m) | Long extent / capsule diameter |
|---|---|---:|---:|---:|
| Water Cragclaw | 4.788 x 3.700 x 6.165 | 1.341 | 3.181 | 2.299 |
| Water Mirejaw | 5.916 x 3.550 x 10.983 | 1.182 | 2.865 | 4.645 |
| Water Mangrove Monitor | 3.196 x 3.850 x 9.701 | 1.282 | 3.064 | 3.783 |

The mixed Cragclaw/Mirejaw admission minimum is 3.023m. The actual collider
matches declared gameplay radius/height; there is no missing collision shape
or runtime scale-shrink finding. The render-bounds helper includes the installed
skin/rest transform correctly and measures only the Model subtree, excluding
contact-shadow helpers. Bounds are conservative at rest: they do not establish
triangle-level intersection or every animated pose.

**Selected cause to investigate next:** shared presentation clearance uses
gameplay capsule radius despite much larger visible bodies. This is a concrete
policy mismatch, not merely the observation that two boxes can overlap. Water's
ground pair members request the same site centre, and shared admission separates
them only by radius plus 0.25m margins. The measured Mirejaw may be almost 11m
long while a same-species pair can be admitted less than 3m apart. The current
ground-supported wandering predicate also has no visual-neighbour check, so
an initial spacing edit alone may not maintain the intended separation. The
camera may have an independent appendage-clearance issue, but these measurements
do not justify changing its shared behaviour first.

**Next bounded proof proposal, requiring a separate approved implementation
brief:** use the actual shared admission/wander predicates with installed bodies
on a narrow supported test ribbon to show the current rule accepting visibly
crowded placement, then test a presentation-only spacing derivation that leaves
combat capsules/reach unchanged. Require both members to remain present on
supported ground, a clear walking corridor, and sustained ordinary wandering
without visual crowding. A conservative whole-body sphere may over-reject long
animals on narrow paths, so prove shape/orientation handling rather than blindly
substituting maximum AABB radius. Preserve road count/visibility and multiplayer
host authority. Any production change would affect Cloudreach/Stormwood/Water
through the shared director and therefore needs evidence in each, with a
separate rendered independent review. No such production change is made here.

## Concrete ribbon proof proposed for root review

One 12m-wide, 60m-long supported floor with a central 2m trainer corridor,
two actual installed Water Cragclaws, and one actual trainer. Both baseline and
test-only candidate use identical species, seed, dimensions, collider, authored
site anchor (x=3.5,z=0), and ordinary wander configuration. Cragclaw's 4.788m
width fits this shoulder without crossing the central route or floor edge.
Mirejaw is deliberately not substituted onto this ribbon: its 5.916m width
requires about 13.83m total width to satisfy the same symmetrical shoulder/route
contract. Pretending it fits would make an invalid proof. No creature is shrunk.

Call the actual shared director's spawn/admission/support/path methods. The
negative control must demonstrate capsule-separated admission with overlapping
visible envelopes. The test-only subclass candidate enumerates longitudinal
positions within the existing 24m supported-path limit and checks oriented rest
rectangles with 0.5m presentation clearance, retaining the actual support checks.
It also rejects central-route occupancy; gameplay collider and reach are unchanged.

Run the actual CliffWild native wander lifecycle for 15 seconds per case.
Prospective-heading/path checks must prevent the candidate's visible bodies from
rotating or walking into each other or the reserved route. Require both bodies
present and grounded, unchanged capsules, native travel over 0.5m each, and an
actual physical-controller trainer walk along the central corridor. Initial
spacing with motion frozen is insufficient. Capture initial and final frames
from identical fixture cameras for the independent critic. Oriented rectangle
separation is conservative rest-envelope evidence, not exact skinned-triangle or
all-animation-pose collision proof.

Requested bound: 60 seconds internal, 75 seconds external, isolated profile and
the established 90% system commit / 400-process guard. The extension above the
20-second measurement fixture is explicit: two 15-second sustained native motion
cases plus actual asset loading/rendering cannot fit honestly inside 20 seconds.
Stop on first unexpected failure; no retry/tuning to manufacture motion or
readability. Ownership is only `tools/probe_creature_ribbon_clearance.gd` and
this report. Root review and the render lease precede execution. No full-world
or production-clearance edit is part of this proof.

## Rendered ribbon result — candidate rejected, 2026-09-09

One approved Compatibility fixture and one explicitly approved measurement correction were run. No production source changed. No further spacing run is warranted.

First run: `.artifacts/creature-ribbon-20260909`, 9.86s, exit 1. Retained `shots/creature-ribbon/round-20260909/A_initial.png` and `A_failure.png`. Actual baseline admission placed centres at (3.5,0,0) and (3.5,0,4.5), with overlapping conservative visible envelopes. An exact `scale != Vector3.ONE` assertion stopped the baseline before the candidate. This was an invalid floating-point invariant, not an established body-resizing defect.

Correction: `.artifacts/creature-ribbon-measurement-corrected-20260909`, 26.17s, exit 1, no external guard stop and no engine errors in stderr. The same species, global seed 740, native per-body RNG seeds 740/741, requested anchor, floor, camera and config were retained. Initial pause 1.5s is explicit fixture setup. Both initial root scales were (1,1,1). The first native rotation produced only 0.000000059605 scale deviation with zero capsule deviation; baseline maximum scale deviation was 0.000006794930. The corrected invariant compares recorded initial values with a 0.00001 tolerance, logging exact deviations rather than suppressing them. Capsules remained radius 1.340706, height 3.7. No shrinking, collision editing or actor teleporting was used by this probe.

Baseline completed 15s native behavior. Planar excursions were 2.09190m and 2.65001m; trainer physically crossed from z=-20 to z=20.44779. Candidate admission then accepted centres z=0 and z=8, with nonoverlapping initial envelopes and a clear central route. These are identical requested placements/configuration, deliberately different admission outputs; they are not identical final actor placements.

Candidate stopped at its first substantive failure after 2.406s. Trainer was (0,0.000844,-8.217495); creature 0 stayed at (3.5,-0.000202,0) but rotated from yaw 0 to -2.738942623. Trainer distance was approximately 8.93181m, inside the ordinary 9m notice range. Creature 1 remained at (3.5,0,8), yaw 0. Sustained candidate wander and completed candidate crossing were therefore NOT proved.

Source attribution: `scripts/creatures/wild_creature.gd::_tick_peaceful` calls `face_towards(player)` and returns while watching. `scripts/creatures/creature_body.gd::face_towards` directly sets root yaw. The actual shared `CliffWild` destination/path predicate checks are in the wander branch and do not intercept this notice turn. Admission-only or admission-plus-wander spacing cannot close this failure. The corrected failure is route/floor-envelope intrusion, not evidence of two creature meshes intersecting at that instant.

At the measured failure yaw, the 4.787892m × 6.164820m rest rectangle spans approximately x=0.08964..6.91036 at centre x=3.5, exceeding the permitted shoulder x=1..6 on both sides. A full yaw sweep of that conservative rectangle has radius 3.902849m. A symmetric ribbon preserving a central 2m route needs at least 17.61140m total width for such a shoulder; a pair allowing arbitrary headings needs at least 8.30570m centre separation including the proposed 0.5m visual margin. The 12m fixture cannot meet unrestricted-turn clearance through longitudinal spacing alone. These are conservative rest-box bounds, not exact triangle collision or all-animation bounds; supported capsule feet alone do not establish visible mesh clearance.

Retained corrected Compatibility frames (1280×800):
- `shots/creature-ribbon/round-measurement-corrected-20260909/A_initial.png`
- `shots/creature-ribbon/round-measurement-corrected-20260909/A_final.png`
- `shots/creature-ribbon/round-measurement-corrected-20260909/B_initial.png`
- `shots/creature-ribbon/round-measurement-corrected-20260909/B_failure.png`

The candidate is rejected and has no shipping or whole-biome acceptance. A blind aesthetic approval is not claimed. The actionable next production direction is supported habitat geometry that accommodates the actual orientation sweep while preserving road-visible creature counts and the trainer route. A narrower habitat instead requires an explicitly designed notice-turn constraint that preserves the engagement cue; silently suppressing notice behavior is not an acceptable test repair. No shared director/camera/spawn production change is authorized here, and no additional near-identical spacing diagnostic is proposed. The five held waterfall candidate files remain preserved for root disposition.
