# Torrentoad face/contact attribution — 2026-09-09

Status: bounded source attribution and one completed initialized probe. No production,
source image, import, material, animation or model file changed.

## Iteration accounting

The required third remediation round has not been consumed. The retained surface
round changed one Torrentoad repaint rule and one generated vivid texture. The attack
round changed anticipation timing and captured the installed low pose. Its metadata
correction and second capture completed that same timing round. The shared mipmap
fixture tested roster-wide filtering and is not a new Torrentoad mesh, pose or facial
art round. The next round must address the still-visible face/eye hierarchy and
low-pose toe contact rather than repeat hue or timing work.

## Current contact mechanism

The unprefixed `torrentoad` entry declares a 3.25m gameplay height, but the tested body
is the distinct namespaced `water_torrentoad`. The Water adapter inherits Ripplet's
presentation dimensions, then scales height to the roster's 3.7m target and radius by
the same source-height ratio; model scale remains 1.0 and yaw 0. `CreatureBody._fit()`
measures the imported bind-pose model, scales it to the tighter gameplay-height or
footprint fit, horizontally centers it, and places the bind-pose AABB minimum at
model-local y=0. The body root then sits on the world ground. The shared contact-shadow
quad is separately placed at root y=0.02.

The installed attack animation deforms the skinned mesh after that one-time fit. There
is no per-frame deformed-foot or deformed-mesh grounding step, and the attack timing
path does not translate the body root to compensate. This is a source-supported
hypothesis for how the same installed low pose can hide the spread front digits at the
plane while other frames show them intact. Existing stills establish the visible
disappearance, but do not distinguish occlusion from penetration or establish that
this mechanism caused penetration.

The attack round is otherwise complete: its final initialized tests passed 5 tests and
28 assertions, and the corrected eight-frame fixture records the low pose at attack
position 0.31250003. Wave 10 and fresh Wave 11 both report the shared low-pose lost
digits and weak face; neither treats the raised contact pose as a newly introduced
timing regression.

## Atlas attribution

The installed 2048x2048 source atlas visibly contains authored dark oval pairs and
surrounding brow/muzzle detail on several packed head islands. Those regions are usable
source detail in principle; a new eye mesh or global synthetic face mask is not yet
justified. The same teal, dark and pale values recur across torso, limbs and toes,
however, so color thresholds alone cannot identify eyes. The completed broad cyan/blue
selector already demonstrated that limitation: it improved a large body block while
independent review still could not locate the eyes reliably. Another hue pass would
repeat exhausted work.

Static packed-atlas inspection cannot prove which repeated island lands on the visible
face. `tools/probe_torrentoad_face_contact.gd` therefore freezes the installed attack
clip at 0.3125 seconds and captures matched rest and low-pose appearance in an isolated
1280x800 `SubViewport`. Godot 4.7's documented
`MeshInstance3D.bake_mesh_from_current_skeleton_pose()` snapshots the active skinned
pose. The probe first screens each model mesh for a surface with an active albedo, so
the GPU bake is never called for the contact shadow or another nontextured mesh. It
records matched rest and low-pose exact minimum world y, below-ground vertex count, the
64 lowest position/UV pairs, and occupied 64x64 UV cells for vertices projected inside
the fixed face region. Surface facts include source blendshape count, skin availability
and resolved skeleton state so the documented bake limits remain visible. This avoids
treating ACES/display-transformed image bytes as direct UV coordinates. Face-cell
membership narrows atlas attribution but does not prove visibility or semantic eye
identity.

The fixture uses the production resolver's namespaced `water_torrentoad` id. Before
either shutter it requires the body `Model` subtree to expose an active material whose
albedo path is exactly the installed Torrentoad vivid PNG, and separately requires the
installed `attack` animation. A fallback capsule or wrong species therefore fails
before producing attribution images.

The exact proposed check is: parse the script, run it once under the guarded
Compatibility renderer, require two 1280x800 images and a complete manifest, confirm
the baked surfaces name only Torrentoad's textured model and active vivid albedo, and
compare rest versus low `minimum_world_y` and `below_ground_vertex_count`. Negative y
below the frozen 1mm epsilon establishes deformed geometry below the floor; a
nonnegative minimum keeps occlusion as the live explanation. Use the projected-face UV
cells only to inspect authored atlas islands; do not derive a new selector until a
compact eye region is visually attributable. The viewport is freed and one process
frame is awaited before the probe quits.

If a guarded run confirms a compact authored eye island, the bounded production plan
is an island-specific repaint selector derived from that UV attribution, paired with a
clip-local low-pose root/bone correction in the animation source. Both require matched
rest/low/contact captures before any production edit. If quantitative UV attribution
shows no distinct authored eye pixels or the contact is only camera occlusion, stop
rather than invent a global mask, another palette pass or a new asset purchase.

## Probe result

The script passed `--check-only` and its one guarded Godot 4.7 Compatibility run
completed with two records and no failure or engine-error line. Both appearance PNGs
are physically 1280x800. The pre-shutter identity gate resolved
`water_torrentoad`, the installed `attack` animation, and exactly one qualifying
surface:
`creature_torrentoad_lod0/Armature/Skeleton3D/Mesh_0`, surface 0, using the active
Torrentoad vivid PNG with texture filter 3. It has 34,216 vertices, a registered skin,
a resolved `..` Skeleton3D and zero blendshapes.

The matched idle pose at animation position 0.0 has minimum world y
`0.000000428364245408375` and zero vertices below the fixed -0.001m threshold. The
low attack pose at position 0.3125 has minimum world y `-0.888469696044922` and 4,965
vertices below that threshold. This establishes that the installed animation deforms
substantial model geometry below the unchanged floor while the body/model roots remain
seated. Together with the matched low image's visibly truncated forelimbs, penetration
is the supported contact cause; the bake does not semantically label every below-floor
vertex as a toe.

The rest frame also confirms the installed atlas supplies discrete pale/dark facial
forms around the brow, but their expression remains weak in ordinary shading and they
are largely hidden by the low pose's head angle. The manifest retains projected-face
UV occupancy and the lowest 64 position/UV pairs for an island-specific follow-up; no
selector is proposed from color alone.

Evidence paths:

- `.artifacts/torrentoad-face-contact-0909/captures/rest-appearance.png`;
- `.artifacts/torrentoad-face-contact-0909/captures/low-appearance.png`;
- `.artifacts/torrentoad-face-contact-0909/captures/manifest.json`;
- `.artifacts/torrentoad-face-contact-0909/probe.stdout.log` and
  `probe.stderr.log`.

The terminal census found zero Godot processes.

## CPU proposal disposition, 2026-09-09

The original CPU scale mismatch was corrected to the tested namespaced height3.7.
The calibrated no-override pose gives minimum -0.888485m and4965 below-floor
vertices, matching the native receipt within0.016mm. Earlier sixteen scalar cases
are inconclusive: immutable penetrating endpoints, ineffective lower-leg parameters,
and a synthesized baseline invalidated a rig-ceiling inference.

One changed-strategy sparse-key proposal added grounded initial rotations and solved
foreleg centroid targets with local-X joint corrections. It still penetrates by
0.48270m overall and0.37821m across the selected toe proxy. Independent review found
nonconverged bound-limited joint solves, unconstrained toe minima, unverified anatomical
hinge axes, and unchanged rear-contact penetration of0.03671m. Mathematical quaternion
interpolation was evaluated; exported/native parity was not established.

Hold production round3 and stop tuning this proposal. This is a failed bounded CPU
proposal, not an installed-rig ceiling or a consumed production art round. Five face
ray samples map to distinct atlas regions but do not establish semantic eye islands.
Both required corrections remain unresolved. Retain `sweep-disposition.json`,
`skin-parity-diagnosis.json`, `sparse-ik-candidate.json`, and `face-ray-map.json` under
`.artifacts/torrentoad-face-contact-0909/`. A future brief must establish anatomical
paw/hinge regions, clearance across the trajectory including rear contact, and face
island attribution before production work.
