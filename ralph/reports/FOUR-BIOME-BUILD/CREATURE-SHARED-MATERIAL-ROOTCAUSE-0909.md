# Creature shared material root-cause proposal — 2026-09-09

Status: causal attribution, clean initialized runtime preflight and frozen A/B
experiment contract. No production material, texture, import, runtime or scene file
has changed. The A/B renderer has not been launched.

## What the retained reviews establish

The complete code-blind catalogue review (`audit-resume/REJUDGE-COMBINED.md`) finds
inconsistent creature surface treatment, busy internal detail and weak face/body
hierarchy across Cloudreach, Stormwood and Water. The biome reports identify the same
problem in ordinary production frames, while the fixed five-body review isolates
Pebblik, Skyrill, Voltarach, Torrentoad and Cragclaw on one camera and stage. The later
Torrentoad pass reduces saturation and adjacent-texel RGB delta but still does not make
its eyes or expression read clearly.

The canonical manifests associate the named affected frames with these candidate
species; proximity does not prove every listed body is visible:

- Cloudreach: Skyrill, Pebblik, Galecrest, Aeriex and Cloudfang;
- Stormwood: Sparkit, Tanglevolt, Voltwig, Voltarach, Mosshock, Staticub and
  Stormraven;
- Water: Mangrove Monitor, Torrentoad, Mirejaw, Mosshell, Riverdrake, Cragclaw,
  Sirenseal and Riptusk.

Those 20 species are the experiment coverage set. The fixed five-body fixture is the
strongest exact identity evidence and remains the primary matched comparison.

## The owner hypothesis is only partly supported

There is no one shader or one active material behavior across the reviewed set.
Offline GLB inspection and the retained active-material probe show three paths:

1. Pebblik, Skyrill, Voltarach, Torrentoad, Cragclaw and most later-biome Meshy
   creatures have one material and one albedo, metallic 0, roughness 0.8, no normal
   map and no source emission. Their production vivid wrapper also reports daylight
   emission energy 0. `creatures_visual.json::emission_scale` therefore cannot cause
   their current daylight noise or weak faces.
2. Galecrest and Mosshell carry normal, metallic/roughness and emissive inputs. The
   shared colourway wrapper preserves those channels while swapping their albedo.
3. Sparkit retains its source JPG and normal/metallic maps and does not use a generated
   ordinary vivid repaint. Its base-colour and normal imports generate mipmaps.

`creature_body.gd::_swapped_material()` is shared plumbing, but it deliberately
preserves these different source material families. Normalizing roughness, deleting
normal maps or changing emission globally would alter different inputs for different
reasons and is not supported by the evidence.

Weak facial hierarchy is also not one demonstrated material fault. Voltarach's face
improved when its actual source-blue facial nodes received a specific selector.
Torrentoad remained hard to parse after a broad colour-block correction, and its
squat head/anatomy is unchanged. A global face contrast slider has no anatomical mask
to identify an eye or muzzle on these single-atlas, single-surface meshes. This
proposal therefore treats face contrast as a regression guard, not as a promised
shared improvement.

## Measured shared cause worth testing

All 32 species in `data/creatures/four_biome_colourways.json` have a generated ordinary
`*_base_color_vivid.png`. All 32 tracked texture imports say
`mipmaps/generate=false`; none says true. Their current sidecar bytes are identical to
live `origin/main` `a46fc868d6d93d491a8a17c8931576148ed0dfb7`, so this policy is not an
unshipped worktree-only difference. The controlled lineup displays 1024x1024
albedos on bodies roughly 140–220 screen pixels high, so the renderer minifies each
map by several source texels per output pixel without a mip chain.

The fixed cohort's current texture-space adjacent-luma deltas are:

| Species | Mean adjacent luma delta | Adjacent pairs over 0.08 |
| --- | ---: | ---: |
| Pebblik | 0.01631 | 5.705% |
| Skyrill | 0.01179 | 4.120% |
| Voltarach | 0.00785 | 0.919% |
| Torrentoad | 0.00480 | 0.646% |
| Cragclaw | 0.00715 | 0.591% |

This repeats the prior Pebblik measurement and shows that source frequency varies
substantially even after the common repaint finish. It does not prove that mipmaps will
repair a face. It does establish a shared minification-policy mismatch that can cause
screen-space shimmer/speckle and can be isolated without another hue pass.

## Initialized production preflight

`tools/probe_creature_mipmap_preflight.gd` instantiated the real production
`CreatureBody` scene for Pebblik, Skyrill, Voltarach, Torrentoad, namespaced Water
Cragclaw, Sparkit, Galecrest and namespaced Water Mosshell. All eight active albedo
textures returned nonempty decoded images; this is runtime evidence rather than an
inference from `.import` text or a dummy-renderer placeholder.

- The five generated-vivid bodies plus Galecrest and Mosshell reported mip count 0.
- Sparkit's active 2048 source JPG reported 11 mip levels and remains the negative
  control.
- Every active material reported `texture_filter=3`. Godot 4.7 defines numeric 3 as
  `BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`: the material requests mipmapped
  linear sampling, but the seven active vivid textures supply no mip chain.
- Active paths and the three material families match the earlier source attribution.
  The probe reports null/empty decoded images as unavailable rather than zero.

The corrected cleanup run exited 0 with zero `ERROR`/`SCRIPT ERROR` lines and zero
remaining Godot processes. Raw evidence is under
`.artifacts/creature-mipmap-preflight-0909/`: `console-cleanup.log`,
`receipt-cleanup.json`, `origin-main-provenance.json`, and
`all-colourway-origin-main-provenance.json`. A hash manifest freezes all 287 protected
modified `.import` worktree files; this lane changed none of them.

Pixel provenance is narrower than policy provenance. Against live `origin/main`,
Skyrill, Cragclaw, Sparkit, Galecrest and Mosshell active albedo bytes are identical.
Pebblik, Voltarach and Torrentoad vivid PNG bytes differ because the shared branch
contains later held paint candidates, although their no-mip sidecars are still exactly
the shipped bytes. A positive A/B result on those three current pixels alone therefore
cannot establish the appearance delta for their exact `origin/main` paintings.

## One causal experiment

The scoped probe `tools/probe_creature_mipmap_hierarchy.gd` derives from the known
five-body stage. For each active source image it creates two runtime `ImageTexture`s
from the same decoded pixels: A preserves the production image's current mip chain;
B calls `Image.generate_mipmaps()` only when that chain is absent. Both use the same
duplicated production material, texture filter, camera, light, transform, frozen
animation frame and 1280x800 viewport. Sparkit therefore remains mipped in both A and
B instead of being degraded to manufacture a control difference. This avoids
an editor import and avoids changing any of the protected existing `.import` bytes.

The probe renders:

- the exact fixed five-body cohort as one matched A/B pair;
- one same-height isolated card for every one of the 20 species associated with the
  complete-review frames, using namespaced Water ids through the production
  `CreatureBody` resolver;
- Sparkit as the already-mipped, non-vivid control;
- Galecrest and Mosshell as the normal/emissive material-family controls.

It records source paths, source/branch mip counts, filter, normals, emission,
roughness, metallic and projected body bounds, and verifies that each replacement is
the effective active material even when a mesh uses `material_override`. The exact
old fixed-five camera/placements produce a matched A/B pair at the original
minification scale. Each isolated card targets 180 projected body pixels (allowed
140–220), with normalized viewport bounds guard `[0.04, 0.04, 0.92, 0.92]`.

Each of the 20 species has an explicit four-value face rectangle in the helper,
expressed as a fraction of its measured projected body rectangle. These broad regions
are preregistered upper-body anatomy guards, not validated eye/muzzle masks; the
experiment may reject lost local contrast there but may not claim improved expression.
Four camera offsets are fixed at `[0.00, 0.25, 0.50, 0.75]` output pixels. Image
analysis uses the fixed background to derive each silhouette mask and records three
axes at full resolution and at a 30% reduction:

1. high-frequency luminance energy and adjacent-pixel deltas inside the body;
2. silhouette-edge stability under four subpixel camera offsets;
3. 5th–95th percentile body-value range plus fixed, disclosed face-region contrast.

The candidate is supported only if the mip branch lowers high-frequency energy and
subpixel variance across the generated-vivid cohort, matches Sparkit's current
already-mipped production sample within the measurement tolerance, and does not reduce
any face-region contrast or body value range by more than 5%. A fresh code-blind judge
then receives neutral A/B pairs
for every previously reviewed affected location/species, with no implementation
description. A result that helps only Pebblik or only the five-body card is local and
does not pass this shared-cause experiment.

## Exact file boundary

Experiment only:

- new `tools/probe_creature_mipmap_hierarchy.gd`;
- new `tools/probe_creature_mipmap_preflight.gd`;
- new `tests/test_creature_mipmap_experiment_policy.gd` for the unique 20-species
  cohort, 32-species policy coverage, capture constants and valid preregistered
  anatomy rectangles;
- this report and retained artifact output.

No production runtime/config/image/import file changes for the experiment. Existing
`tools/probe_creature_surface_hierarchy.gd` stays unchanged so its current fixed stage
remains a baseline.

If and only if the experiment passes, the smallest production correction is import
policy, not a shader change: switch `mipmaps/generate` to true on the 32 existing
ordinary vivid albedo `.import` sidecars and keep the PNG bytes, repaint rules,
roughness, normals, emission, meshes and runtime code unchanged. The new policy test
would enumerate the exact 32 outputs from `four_biome_colourways.json` and prevent a
new vivid output from silently returning to no-mip import. Because those sidecars are
inside the pre-existing protected dirty-import set, that candidate requires a root
coordinated byte backup and explicit import lease; this proposal does not alter them.

If mipmaps fail the cohort or face guards, stop this shared material experiment. The
remaining face issues should be recorded as per-asset anatomy/paint/staging work rather
than forcing a global material value onto unrelated rigs.

The policy test's first run correctly exposed that Galecrest and Mosshell are direct
vivid full-PBR controls outside the 32-species generated policy. After retaining that
failure, the corrected test treats only Sparkit, Galecrest and Mosshell as explicit
controls and passes 3 tests / 209 assertions / 0 failures with a clean raw log. This
prevents the experiment from falsely attributing those two older assets to
`four_biome_colourways.json`.

## Source hashes at attribution

- `scripts/creatures/creature_body.gd`:
  `9CA97AE7E5EF99A1769813CE7E5A0C427DDF0D1E369BD2A52FAC28DF229543F4`
- `scripts/creatures/creature_visual.gd`:
  `7095A7F84220E26BD9E91C76E2EC6998D6C6497A5FB806C65AB67AE6DD9DE6E7`
- `data/config/creatures_visual.json`:
  `B64D4801148266B214CF1883AAF10D54B5CAE24F899F9B033A3DB495B547DC90`
- `data/creatures/four_biome_colourways.json`:
  `F6EF6A394CB0DBC5C8DD39A8152A473F77B3B108E5C5FA86D12017439D5DCE45`
- `tools/repaint_creature_textures.py`:
  `161C76C694F9EC503F72F14A034B69A3CCA2356855AA8D8B943F70FFDF73101D`
- `tools/probe_creature_surface_hierarchy.gd`:
  `46873C23DAF87CA3A66174E93E97D1D09F669A62A6EC70D8DC000BCBF67B963D`
