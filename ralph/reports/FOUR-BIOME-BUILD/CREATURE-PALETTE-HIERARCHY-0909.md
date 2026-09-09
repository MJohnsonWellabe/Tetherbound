# Creature palette hierarchy — 2026-09-09

Status: production candidate generated and runtime-attributed; fixture-visible only,
not world-accepted. Fixed 1280x800 production context was recaptured in Cloudreach
and Stormwood, with the roster and native-facing limitations below. Independent
visual acceptance remains pending.

## Bounded change

The deterministic repaint pipeline is first-match-wins. Pebblik's broad saturated
body rule therefore consumed its source cobalt mineral panels before the intended
violet secondary rule could see them. Voltarach had the same ordering defect on a
much smaller but visually important source-blue facial/node region. The change adds
one source-blue selector before each broad body rule:

- Pebblik: source hue 205–285, saturation >= 0.25 and value >= 0.12 becomes violet
  (hue 278), while the remaining saturated body stays sun-gold.
- Voltarach: the same source selector becomes teal (hue 178), while the shell stays
  magenta.

No mesh, scale, collider, animation, AI, encounter, shiny/alpha, or emission behavior
changed. `scripts/creatures/creature_body.gd` did not need a change.

Owned production files:

- `data/creatures/four_biome_colourways.json`
- `assets/creatures/tetherbound/pebbik/models/pebbik_extracted_base_color_vivid.png`
- `assets/creatures/tetherbound/voltarach/models/voltarach_extracted_base_color_vivid.png`

Diagnostic fixture:

- `tools/probe_creature_surface_hierarchy.gd`

## Source and active-material attribution

Against each installed source JPG, the selector covers 355,073 of 910,515
chromatic Pebblik pixels (39.0%) and 5,925 of 791,809 chromatic Voltarach pixels
(0.7%). The latter small region is the three front-facing nodes that carry the
alpha's face read.

The production-body fixture instantiates the ordinary `CreatureBody` setup for
Pebblik, Skyrill, Voltarach, Torrentoad, and Water Cragclaw. All five resolve to the
authored `*_extracted_base_color_vivid.png` albedo through the production material
wrapper. At day the wrapper reports emission energy `0.000`, roughness `0.800`, and
metallic `0.000`. Source mesh materials are ordinary lit PBR without source
emission, so emission removal was not justified.

The editor import completed with exit 0. Active cache source MD5 values equal the
current generated PNG bytes:

- Pebblik source/cache MD5: `39f0f0981bb594583c357ab3d01a8cd6`
- Voltarach source/cache MD5: `2db982c76843b5911a4cbe147110b2d4`
- Pebblik S3TC SHA-256: `532B7B0443F6E905B5D8F38BA6A2CF0FE983CB4E94A2839BFDDE7ADC69427F01`
- Voltarach S3TC SHA-256: `60FFAC07CA731584296FEF4FD821855261242556E95D6D69EEB1F69B09B3865E`

Generated source hashes:

- Pebblik vivid PNG SHA-256: `4935559AB859D5236345A305EE7B74237193A7BD8E860DE3D21D98BF037313B6`
- Voltarach vivid PNG SHA-256: `D00D1ACE21C8F10E27405962245A26974327AB83BA8C6FACD7A798728DB42262`

The two lineup images are attribution diagnostics, not a matched comparison: the
stale-cache image is 1280x800 and the rebuilt-cache image is 1600x900. The rebuilt
image visibly shows Pebblik's violet mineral planes and Voltarach's teal face nodes.

- `shots/creatures-surface-probe/before-five.png`
- `shots/creatures-surface-probe/after-five.png`

## Validation and capture state

- JSON parse: pass.
- Deterministic repaint command completed for `pebbik voltarach --only vivid`.
- Godot 4.7 Compatibility editor import: exit 0, no timeout or memory guard.
- The original 287 dirty `.import` files were byte-backed before import and verified
  at zero changed hashes after it. Six editor-touched files were restored from the
  byte backup. Three clean-before Bark normal-map sidecars were restored to their
  exact index blobs. The final status returned to exactly 287 modified `.import`
  files, with no extra tracked sidecars and no untracked `.uid` files.
- First rebuilt-cache Cloudreach world attempt:
  `shots/catalogue/cloudreach/round-creature-palette-reimported-20260909/`.
  It started at 2026-09-09 07:02:29-05:00 and the guard stopped it about 37.4 seconds
  later at 379 MB free memory. Its manifest is `complete=false` and contains no
  frame. This is retained failure evidence and is not palette validation. The stop
  came from a mistaken reading of the approved `90%/400` guard: retained resource
  monitors establish that the second limit is 400 processes, not a 400 MB
  free-physical-memory floor. Subsequent runs used 90% system commit, 400 processes,
  a 240-second timeout, persisted samples, and owned-PID termination.
- The earlier `round-creature-palette-20260909` Cloudreach and Stormwood frames were
  captured before the rebuilt texture cache. They are stale-context evidence only.
- Corrected Stormwood context:
  `shots/catalogue/stormwood/round-creature-palette-reimported-20260909/`.
  It completed 1/1 in 23.2 seconds at 1280x800, peaking at 68.5% system commit and
  249 processes. The manifest identifies the foreground body as Voltarach. Native
  facing leaves its back toward the production camera in both the stale-cache and
  rebuilt-cache frames, so this pair does not expose the corrected teal face nodes.
- Corrected Cloudreach context:
  `shots/catalogue/cloudreach/round-creature-palette-reimported2-20260909/`.
  It completed 1/1 in 112.9 seconds at 1280x800, peaking at 71.89% system commit and
  251 processes. The rebuilt-cache manifest contains six Skyrill and no Pebblik,
  while the stale-cache comparator showed Pebblik. This is valid ordinary production
  context and confirms the unchanged Skyrill route, but it is not a matched Pebblik
  before/after pair.

The neutral production-body fixture is the direct visual evidence for Pebblik's
violet planes and Voltarach's teal facial nodes. The canonical world frames establish
that the ordinary production scenes still load and place the identified bodies, but
their stochastic roster/facing prevents a matched species comparison. An ordinary
player-camera orbit/walk supplement would be appropriate if independent review needs
world-space face proof; actor rotation or spacing changes are unnecessary. No broad
cast or whole-biome acceptance is claimed here.

## Root fixed-resolution fixture correction

Root repeated only the existing static production-body fixture with an explicit
1280x800 viewport and a distinct output path after the world attempts. The source
change adds output-path and image-size reporting only. It completed in 5.6 seconds,
exit 0 with no native/script errors, on Compatibility/OpenGL3, and reports an actual
`(1280, 800)` image. Evidence:
`shots/creatures-surface-probe/after-five-1280x800.png`, compared with retained
`before-five.png` at the same resolution and static camera/stage. This removes
the earlier resolution confound; the original 1600x900 after-image stays retained.
Violet Pebblik panels and teal Voltarach facial nodes are visible in the corrected
fixture. It remains a staged production-body comparison, not an ordinary-world
cast acceptance. Full logs/engine-child guard receipts are in
`.artifacts/water-gate-finish-lineup-20260909/` (root's shared visual-check wrapper).

Independent disposition: the reused image-only reviewer returned A No/B Yes
(category only) for the matched lineup. Voltarach's teal facial nodes have
substantially clearer contrast; Pebblik's violet panels introduce another
competing hue. Wider surface noise and facial hierarchy remain unresolved.
See `VISUAL-WAVE-IMAGE-REVIEW-0909.md`. These candidates are retained but held;
no roster acceptance or main landing is claimed. The later single-Torrentoad
candidate and its separate verdict are recorded in
`CREATURE-TORRENTOAD-SURFACE-HIERARCHY-0909.md`.
