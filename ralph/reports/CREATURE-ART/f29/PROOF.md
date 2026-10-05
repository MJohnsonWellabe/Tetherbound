# F29 Stormursa asset evidence

Lane: `tb/creature-art`. Runtime baseline:
`826d273c3dbdcb1002034812041b1dfb59d84120`. Reference/prompt checkpoint:
`9fa692e3f0ffbe15cd167c1d3cc5523b7fccc6ad`. Coordinator integrates; no lane PR.

| Criterion | Label | Evidence / remaining proof |
|---|---|---|
| F29#3 storm bear | OFF | [Reference-only independent PASS](reference-review.md). One attended Meshy task succeeded; raw candidate downloaded. Mesh inspection, measured scale, rig, poses and in-engine code-blind before/after PASS remain OPEN. `staticub_stormursa` remains `enabled:false`. |

Drafted/inspected reference:
`assets/creatures/tetherbound/stormursa/reference/stormursa-v1.png`, SHA-256
`de2ef0cbe55b546dacb950b8e1e793d60c82d35149192b0324e89b901892fc49`.
Its prompt/provenance records are beside it and in ART_DIRECTION §7.3. The
reference directory is excluded from Godot import. The raw candidate below is
also excluded; no prepared runtime model has been accepted.

## Executed CPU preflight, before the first submission

These preflight receipts are historical. The zero-task ledger and unmeasured
balance delta below describe that earlier state; the attended submission and
observed debit are recorded in the following section.

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
- Restored the exact Stormursa reference into this sparse art checkout after
  merge, and re-inspected the matching PNG. Actual guarded CLI help preflight
  exit 0: bounded subject, in-checkout reference and SHA, stored Windows user
  credential propagation and generation options are reachable. [Receipt](guard-preflight.json).
  This help-only process makes no network request; ledger bytes unchanged,
  zero tasks. A fresh shell must propagate `MESHY_API_KEY` from the Windows
  user environment before calling the existing guard; no credential is saved
  in Git or receipts. Authoritative asset provenance now records the proved
  reference-only gate; task/model/rig/animation/scale/full-bar gates stay open.
- Separate scoped provenance/preflight review `/root/stormursa_reference_review`:
  PASS. Reviewer matched reference/hash/paths/current ledger and checked the
  CLI help cannot submit a task. Credential presence is not authentication or
  billing; option availability is not a successful generation request. The
  earlier license/balance read remains separate evidence. Stale PROMPT_ONLY
  brief status was corrected to the proved reference-only disposition.

## Attended nightly submission

Use the sole `f36_meshy_guard.py` ledger with the actual Chicago night date,
subject `stormursa`, the exact inspected PNG and SHA above. Client arguments:
`generate stormursa --image assets/creatures/tetherbound/stormursa/reference/stormursa-v1.png --candidates 1 --tier refine --polycount 30000 --budget 30 --ai-model meshy-7.1 --enable-pbr --preserve-reference`.
Executed once on the Chicago night of 2026-10-04: task
`01a109db-e623-70a8-b13a-60dfc2ad2846`, reserved through the shared guard as
**1/30**. The inspected reference hash matched. Observed existing-credit balance:
13,545 before, 13,515 after, a 30-credit debit; no purchase. Task was IN_PROGRESS
45% at the first status read. Exact generated request manifest and receipt:
`source/meshy-generation-1.json`. Submission is not a mesh/rig/scale/art PASS.
Every later POST, including
refine/retexture/retry, consumes the same 30/night cap; uncertain submissions
retain their reservation. Record real task IDs and before/after balance before
further spending. Fetches/status reads do not create generation tasks.

The task subsequently SUCCEEDED. Existing `meshy.py fetch` downloaded the
GLB, FBX, OBJ, thumbnail and service provenance. Preserved primary GLB:
`source/meshy-candidate-a/model.glb`, SHA-256
`97ba748431877d9bf648f8976cd871e7ae92544eb2b2d2a855120e534f421bdc`.
The raw candidate directory has `.gdignore`; no import, rig, measured scale,
animation or full-bar PASS follows from download. Author inspected the service
thumbnail: recognizable adult bear mass, rounded ears/blue eyes/muzzle and
four visible paws; actual geometry and lightning-material fidelity need
inspection. Source terms and conditional plan attribution are recorded in
`source/meshy-candidate-a/LICENSE.md`; the credit count alone is not account-plan
proof. No extra POST, purchase or runtime flag change.

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
