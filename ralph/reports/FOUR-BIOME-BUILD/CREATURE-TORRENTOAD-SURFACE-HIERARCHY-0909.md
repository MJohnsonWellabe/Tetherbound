# Torrentoad surface hierarchy — 2026-09-09

Status: one bounded production candidate, active-material attributed and captured
in the fixed 1280x800 five-body fixture. Independent image-only review found a
useful narrow improvement and held it pending shipping scope. No world or
whole-roster acceptance is claimed, and no second colour correction is planned.

## Finding and bounded change

The independent image-only review ranked noisy, uniformly bright creature surfaces
above the other lineup gaps and specifically found Torrentoad's face hard to parse.
The installed texture explains the avoidable part of that result. Torrentoad's
source cyan/blue region (hue 170–285, saturation at least 0.25, value at least 0.12)
covers 1,284,867 of 4,194,304 UV pixels (30.63%). The current first-match vivid rule
recoloured all chromatic pixels orange before that authored large region could be
used. Its teal came instead from 395,634 bright near-neutral UV pixels (9.43%), which
produced small wet-looking flecks over a nearly uniform orange body.

Only Torrentoad's `vivid_rules` in
`data/creatures/four_biome_colourways.json` changed:

- the source cyan/blue region is selected first and becomes muted teal (hue 190,
  saturation 0.40, source value multiplied by 1.02);
- remaining chromatic pixels keep the warm orange identity (hue 24, saturation 0.60,
  source value multiplied by 1.03);
- low-saturation source planes remain neutral instead of becoming scattered teal.

The existing deterministic pipeline regenerated only
`assets/creatures/tetherbound/torrentoad/models/torrentoad_extracted_base_color_vivid.png`.
No shader, lighting, emission, normal, mesh, scale, collider, animation, AI, combat,
or roster data changed. Voltarach's retained teal eye selector is untouched.

## Source and active texture attribution

- installed source JPEG SHA-256:
  `BE882DF283FE2C6DE3343CF21E5639E6662B453F22B5E293F2CD7BEDE13DC899`
- retained previous vivid PNG SHA-256:
  `32237F65F34A220B3218D3A60FFC9C22E0F52656922ACB7E3FDF9DD0F274BE7E`
- candidate vivid PNG SHA-256:
  `9FD5DC2D07F4A6A5F23178F0511CB42F368295D85A1D7922141F8FC5EBE06815`
- imported cache source MD5: `7b40c8bcad64c612a377de1a672e6d7e`
- imported cache destination MD5: `36cad82ca0e1e49c6e64fb2716a9807b`
- candidate S3TC cache SHA-256:
  `F80A5CE83A9D88CA65A8E544C141AFB84D5836FA648A35893C6A71FC067E48A8`

The fixed fixture instantiates the ordinary production `CreatureBody` path. Its raw
output identifies Torrentoad's active albedo as the candidate vivid PNG above. The
material remains roughness `0.800`, metallic `0.000`, with emission enabled but day
energy `0.000`. No emission behavior was changed.

The previous vivid texture had mean saturation 0.7118, with 89.12% of UV pixels over
0.70 saturation. The candidate measures 0.4887 mean saturation and 0% over 0.70.
Mean luminance moves from 0.3359 to 0.3715. Mean adjacent-pixel RGB delta moves from
0.00760 to 0.00656. These are whole-UV measurements, not estimates of screen-space
body coverage.

Separate source-map evidence is
`shots/creatures-surface-probe/torrentoad-source-map.png`, SHA-256
`8596552F4ED19D7A71345C3D2EB3AD9EE5F480F583079012A998DD5ADB0FBED7`.
It shows the installed source, retained previous vivid texture, candidate, and exact
source selector. It is attribution evidence and is not an independent-review input.

## Import and fixture receipts

The exclusive Godot 4.7 Compatibility editor import exited 0 in 17.928 seconds,
peaking at 57.281% system commit and 252 processes. The target cache source MD5
matches the candidate PNG. The editor log also contains this error verbatim:

`ERROR: Index p_idx = 9 is out of bounds (files.size() = 0).`

That error is retained. The import is therefore not described as clean. Workspace
timestamps show no other source addition during its 07:59:38–07:59:56 window;
`project.godot`, the target texture metadata, and three Bark normal-map sidecars were
written by the editor scan. This does not establish a concurrency cause, so the
filesystem error remains unexplained.

Before import, the 287 pre-existing dirty `.import` files were copied byte-for-byte
to
`C:/Users/mattj/AppData/Local/Temp/tetherbound-torrentoad-import-backup-20260909`.
All 287 post-import hashes match that backup. The editor additionally rewrote three
clean-before Bark sidecars and `project.godot`; root restored those four unrelated
files after the lease. It also created 149 untracked UID files; only those exact
untracked paths were removed after workspace boundary checks, leaving zero.

The fixed fixture then exited 0 in 6.094 seconds, peaking at 52.013% system commit and
254 processes, and left zero Godot processes. Raw receipts are under
`.artifacts/torrentoad-surface-20260909/`.

Matched neutral images:

- retained before/current-five fixture:
  `shots/creatures-surface-probe/after-five-1280x800.png`, SHA-256
  `4521D6DE772050A50EFE417A7B94A280ABBBCF689B24FF315E74BD442BE3C16C`
- candidate fixture:
  `shots/creatures-surface-probe/torrentoad-restraint-five-1280x800.png`, SHA-256
  `7A50A4C523BC730FFCBE97BDB80C8872925A356FE9C92598CF39003776F67C7B`

The images share viewport, camera, stage, actor transforms, and production material
path. They still inherit the fixture's crowded lineup and overlap, so they cannot
settle the review's staging finding. The candidate exposes a larger upper-body versus
underside colour block, but the installed squat anatomy and small facial geometry
remain unchanged; this albedo pass cannot create more expressive eyes or a new face.

## Independent image-only review

The reused image-only reviewer saw only the matched neutral pair. It judged the
candidate's broad muted crown and calmer orange-brown body as a useful local
improvement. It also found that Torrentoad's eyes and expression remain weak and
that the lineup still carries broader surface noise. Category fit remains Yes, while
visual target A remains No. This supports retaining the narrow candidate; it does
not support another colour tune or a roster-level acceptance claim.
