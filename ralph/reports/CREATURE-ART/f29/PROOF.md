# F29 Stormursa asset evidence

Lane: `tb/creature-art`. Runtime baseline:
`826d273c3dbdcb1002034812041b1dfb59d84120`. Reference/prompt checkpoint:
`9fa692e3f0ffbe15cd167c1d3cc5523b7fccc6ad`. Coordinator integrates; no lane PR.

| Criterion | Label | Evidence / remaining proof |
|---|---|---|
| F29#3 storm bear | OFF | [Reference-only independent PASS](reference-review.md). Meshy task, actual mesh, measured scale, rig, poses and in-engine code-blind before/after PASS are MISSING. `staticub_stormursa` remains `enabled:false`. |

Drafted/inspected reference:
`assets/creatures/tetherbound/stormursa/reference/stormursa-v1.png`, SHA-256
`de2ef0cbe55b546dacb950b8e1e793d60c82d35149192b0324e89b901892fc49`.
Its prompt/provenance records are beside it and in ART_DIRECTION §7.3. The
reference directory is excluded from Godot import; the model remains uncreated.

## Executed CPU preflight

- Owner-supplied credential stored outside Git in the Windows user environment.
  License/balance check succeeded with 13,545 existing credits. No purchase and
  no generation, refine, retexture or retry submitted. The shared ledger at
  `ralph/reports/R2-F36/meshy-night-ledger.json` has zero actual tasks.
- Installed Blender `4.2.9 LTS` confirmed by its executable. Local quadruped rig
  and animation pipeline is available; it still requires measured four-leg
  geometry, inspected weights and bent-pose renders on the actual candidate.
- Current authored Staticub ladder height is 3.25 m, trainer 1.80 m. The existing
  F29 `stormursa/source/reference_brief.json` and species candidate set the adult
  target to 4.10 m; use that target, superseding this receipt's earlier 3.90 m
  minimum. Final mesh bounds and visible differentiation still require proof.
  Grow the smaller side; never shrink Staticub or the adult. Reference pixels
  contain no measured scale ruler and do not establish a final model height.
- Read-only single-thread Blender CPU inspection of installed Staticub completed
  in 6.48 s; [baseline receipt](staticub-cpu-inspection.json). Exact model SHA-256
  `c2e42a53ebeb922b06564bd4ce210cb02b5d438bf0d816516cc327719d758c1a`.
  Raw pre-fit mesh: 1.1079 m high, 52,886 triangles, one material, 15 bones and
  six clips. This raw size is not the runtime 3.25 m fitted scale. The inspector
  flags topology/duplicate/component issues; these are inspection heuristics,
  not a visual rejection or permission to alter the accepted base. Preserve
  this exact baseline for comparison; candidate joint/pose checks remain open.
- Optional Meshy model pin, PBR maps and reference-preservation controls added
  without changing existing CLI request defaults. Five focused offline tests
  PASS, including one mocked Stormursa submission with the exact PNG data URI,
  one candidate and manifest provenance. Mock task IDs are temporary fixtures.
- Independent implementation review `/root/stormursa_reference_review`: PASS,
  no scoped blocker. The guard was unchanged and outside this review. Actual
  balance delta, generated model quality and all model gates remain open.

## Attended nightly submission

Use the sole `f36_meshy_guard.py` ledger with the actual Chicago night date,
subject `stormursa`, the exact inspected PNG and SHA above. Client arguments:
`generate stormursa --image assets/creatures/tetherbound/stormursa/reference/stormursa-v1.png --candidates 1 --tier refine --polycount 30000 --budget 30 --ai-model meshy-7.1 --enable-pbr --preserve-reference`.
This is a prepared command, **not an executed task**. Every later POST, including
refine/retexture/retry, consumes the same 30/night cap; uncertain submissions
retain their reservation. Record real task IDs and before/after balance before
further spending. Fetches/status reads do not create generation tasks.

Checked primary [Multi-Image API](https://docs.meshy.ai/en/api/multi-image-to-3d)
and [pricing](https://docs.meshy.ai/en/api/pricing) on 2026-10-04: one inspected
PNG is supported; Meshy 7.1 with standard geometry and default 2K textures is
listed at 30 credits. The estimate is not a substitute for observed billing.
Legacy `mode`, `prompt` and `negative_prompt` fields are not documented as
geometry controls; do not infer that they enforce shape. The image remains the
geometry authority. No humanoid auto-rig is planned for this quadruped.

Before any candidate integration: preserve raw model/provenance; inspect mesh,
scale, joints, weights and full poses; judge matched ordinary-distance images
code-blind against Staticub and the creature bar. Failures remain flag-off. The
training lane alone enables the evolution after the asset passes. The F36 batch
waits for the settled F26 look bar. No current full-feature acceptance claim.

Shared file touched in prior checkpoint: ART_DIRECTION provenance row only.
This checkpoint adds client options/tests, reference `.gdignore`, this evidence
and the existing zero-task ledger note; no runtime species or flag changes.
