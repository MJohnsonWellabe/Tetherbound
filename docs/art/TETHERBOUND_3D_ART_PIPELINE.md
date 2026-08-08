# TETHERBOUND — 3D CHARACTER / PAL ART PRODUCTION PIPELINE

**Purpose:** Give Claude Code / Codex an executable workflow for turning Tetherbound concept/reference art into game-ready 3D characters and Pals that actually resemble the supplied art.

**Primary project:** Tetherbound  
**Engine:** Godot — locked  
**Primary platform:** Windows desktop + Windows handheld PCs / ROG Ally  
**Art target:** Stylized PBR, cohesive, readable at third-person gameplay distance  
**First proof asset:** **Terrapup, the Ground starter**

---

# 0. DIRECTIVE TO THE CODING / ART AGENT

Do not read this document as a list of suggestions.

Treat it as an implementation plan.

Your job is to:

1. Inspect the local development environment.
2. Inspect the Tetherbound repo and reference-art folders.
3. Install or configure the approved tools below when possible.
4. Never commit API keys, secrets, downloaded installers, caches, generated temporary files, or third-party packages that should remain external.
5. Ask the owner only when a genuinely user-controlled dependency is required, such as:
   - an API key,
   - a paid account,
   - an interactive login,
   - OS administrator approval,
   - a license decision,
   - or a major visual/design choice.
6. Prove the entire pipeline on **Terrapup** before producing the rest of the roster.
7. Do not mass-generate the full roster until Terrapup passes the quality gate.
8. Prefer visual iteration and comparison over accepting the first generated mesh.
9. Record all important technical/art decisions in the repo.
10. Record provenance and license information for every third-party or AI-generated asset in `docs/ASSET_LEDGER.md`.

The goal is not merely to produce a `.glb`.

The goal is to produce a `.glb` that:

- clearly resembles the reference art,
- moves correctly,
- reads well in gameplay,
- fits the Tetherbound visual language,
- performs adequately in Godot,
- and is maintainable.

---

# 1. WHY THIS PIPELINE EXISTS

Claude is capable of:

- operating Blender through MCP or scripts,
- modifying geometry,
- creating materials,
- rendering previews,
- exporting GLB,
- importing assets into Godot,
- writing rigging/export/validation scripts,
- comparing screenshots,
- and iterating.

Claude is **not** expected to reliably hand-sculpt polished organic characters entirely from mathematical primitives or raw `bpy` vertex generation.

For organic characters and Pals, the preferred approach is:

**Reference art  
→ AI image/multi-view-to-3D generation  
→ Blender inspection and cleanup  
→ remesh / retopology where necessary  
→ rigging  
→ animation  
→ GLB export  
→ Godot validation  
→ rendered visual comparison  
→ iteration**

Claude should act primarily as:

- art-production orchestrator,
- technical artist,
- Blender operator,
- asset pipeline engineer,
- QA reviewer,
- and Godot integrator.

Do not force Claude to behave as a traditional sculptor when a better starting mesh can be generated.

---

# 2. REFERENCE ART IS AUTHORITATIVE

Locate the supplied Tetherbound art pack.

Expected content includes reference images for:

- Main player character
- Terrapup — Ground starter
- Ripplet — Water starter
- Galewisp — Air starter
- Meadows roster
- Grandpa
- Meadows Warden
- Ground legendary
- supporting Markdown prompts / roster manifest

Use the PNGs for:

- silhouette,
- proportions,
- major forms,
- facial appeal,
- material breakup,
- color relationships,
- equipment placement,
- scale relationships,
- and overall style.

Use the Markdown specs for:

- canonical names,
- canonical types,
- gameplay roles,
- lore,
- animation requirements,
- and any detail that conflicts with text accidentally rendered inside AI concept art.

**Markdown wins over image-generated labels.**

Never infer a new gameplay mechanic from concept art.

For the **wild** roster specifically — the twelve wild species and Tuskroot —
the authoritative package is `docs/art/wild/`, with its five sheets in
`docs/art/reference/wild/`. It is the owner's, it is later than everything else
here, and it is explicit that it wins over any earlier board or note. See
`docs/decisions/D13`.

---

# 3. APPROVED TOOL STACK

## Tier A — Required Core

### 3.1 Blender

Blender is the authoritative DCC tool for:

- inspecting generated geometry,
- checking topology,
- checking normals,
- checking UVs,
- material cleanup,
- scale correction,
- pivot / origin correction,
- armature inspection,
- skin-weight inspection,
- animation inspection,
- rendering comparison shots,
- LOD preparation,
- and GLB export.

Use a stable Blender 4.x version supported by the selected MCP bridge.

If Blender is not installed:

- install it using an appropriate official or package-manager route when permissions allow,
- otherwise tell the owner exactly what interactive/admin step is required.

Do not download Blender from random mirrors.

---

### 3.2 Meshy MCP — Preferred 3D Generation Service

Preferred repository:

`https://github.com/meshy-dev/meshy-mcp-server`

This is the current official Meshy MCP server.

Use it as the preferred agent-facing generator because it exposes tools for:

- text-to-3D,
- image-to-3D,
- multi-image-to-3D,
- remesh,
- retexture,
- rig,
- animate,
- resize,
- conversion,
- and UV operations.

For Tetherbound creatures, prefer:

**multi-image-to-3D > image-to-3D > text-to-3D**

when suitable front / side / back / 3/4 references exist.

Do not commit the Meshy API key.

Store it only in:

- environment variables,
- user-level secret storage,
- or local MCP configuration excluded from Git.

At time of writing, the official Meshy MCP documentation states the API key requires a qualifying Meshy plan. If the account/API key is unavailable, do not fake one and do not commit placeholders that look like real credentials.

Instead proceed to the fallback generator section or ask the owner for the minimum required credential.

Before installing, inspect the repository README and current install instructions because MCP installation commands can change.

The current documented Claude Code pattern is based on adding the Meshy MCP server and passing `MESHY_API_KEY` through environment configuration.

After installation verify that:

- the MCP server loads,
- the expected Meshy tools are listed,
- a test operation works,
- and output can be downloaded to a controlled local asset-staging directory.

---

## Tier B — Blender Agent Bridge

Install **one** Blender MCP bridge.

Do not install several simultaneously unless performing a deliberate comparison in an isolated environment.

The bridge must support at minimum:

- scene inspection,
- arbitrary or sufficiently powerful `bpy` execution,
- object transforms,
- material inspection/editing,
- rendering / viewport screenshots,
- file import/export,
- and preferably animation/armature inspection.

Current candidate repositories worth evaluating include:

### Candidate A
`https://github.com/glonorce/Blender_mcp`

This project currently advertises broad Blender control, many structured tools, screenshot feedback, animation support, and direct `bpy` execution.

### Candidate B
`https://github.com/mackson/blender-mcp`

This project currently advertises standard MCP control, material/texture work, sculpting/model operations, rendering previews, export, custom `bpy`, and vision feedback.

### Candidate C — Godot-focused experiment
`https://github.com/ricky-yosh/blender-mcp`

This is specifically described as Blender → Godot oriented, but it is much newer/smaller. Treat it as experimental unless inspection shows it has matured enough for production use.

### Selection rule

Before installing a Blender MCP:

1. Inspect README.
2. Inspect recent commit activity.
3. Inspect license.
4. Inspect open issues relevant to Windows / Claude Code / Blender version.
5. Inspect whether it executes arbitrary local code.
6. Understand security implications.
7. Prefer the smallest reliable tool that supports the complete workflow.
8. Document which bridge was selected and why.

Do not expose a Blender MCP server to the public internet.

Prefer localhost / local-only operation.

Do not disable security controls merely for convenience.

---

## Tier C — Tripo Fallback / Comparison Generator

Official repository:

`https://github.com/VAST-AI-Research/tripo-mcp`

The current project describes itself as the official Tripo MCP and currently labels itself **alpha**.

Use Tripo when:

- Meshy is unavailable,
- Meshy produces a poor result for a particular creature,
- or we deliberately want a second candidate mesh for comparison.

Do not automatically adopt Tripo as primary just because it produces a mesh.

Judge the output against the Tetherbound quality gate.

If Tripo requires:

- API credentials,
- Blender addon installation,
- or interactive login,

configure those without committing secrets.

---

# 4. OPTIONAL SUPPORTING TOOLS

Claude may obtain additional tools where they clearly improve the pipeline.

Examples:

- Godot command-line export / import validation
- Blender Python scripts
- image comparison scripts
- topology statistics scripts
- GLTF / GLB validation tools
- texture inspection utilities
- local image processing using Python / Pillow / OpenCV
- Git LFS if repository asset size warrants it

Do not introduce large infrastructure stacks for marginal value.

Every new dependency should answer:

> What concrete production failure does this solve?

---

# 5. REPOSITORY ORGANIZATION

Create a clear structure if one does not already exist.

Recommended structure:

```text
assets/
  characters/
    player/
      source/
      textures/
      models/
      animations/
      reference/
    npcs/
      grandpa/
      warden_meadows/
    pals/
      starters/
        terrapup/
          source/
          textures/
          models/
          animations/
          reference/
        ripplet/
        galewisp/
      meadows/
        bramblebun/
        mudsnout/
        trailpup/
        meadowhart/
        burrowback/
        paddlenewt/
        mosshell/
        brooktail/
        reedwing/
        pipwing/
        duskhush/
        galecrest/
        tuskroot/
      legendary/
        veridian/

tools/
  art_pipeline/
    blender/
    validation/
    image_compare/

docs/
  art/
    3D_PIPELINE_DECISIONS.md
    TERRAPUP_PRODUCTION_REPORT.md
```

Adapt this to the existing repo organization rather than creating duplicate hierarchies.

Keep:

- generated intermediates,
- Blender source,
- production GLBs,
- textures,
- references,
- and animations

clearly separated.

---

# 6. ASSET NAMING

Use stable machine-readable names.

Example:

```text
pal_terrapup_lod0.glb
pal_terrapup_lod1.glb
pal_terrapup_lod2.glb
pal_terrapup_basecolor.png
pal_terrapup_normal.png
pal_terrapup_orm.png
pal_terrapup.blend
```

Armature / animation names should be predictable.

Example:

```text
Idle
Walk
Run
TurnLeft
TurnRight
Sleep
Happy
Hurt
Faint
QuickAttack
ChargedAttack
Dig
```

Do not accept generator filenames such as:

`model_final_new2_good.glb`

---

# 7. TERRAPUP IS THE PIPELINE PROOF

Do not begin batch roster production until Terrapup passes.

Terrapup was chosen because:

- its silhouette is strong,
- its anatomy is relatively simple,
- it is a quadruped,
- it has clear material breakup,
- its stone mantle gives an obvious similarity test,
- and it is important enough that poor quality cannot be hidden.

Expected reference:

`01_Ground_Starter_Terrapup.png`

or the corresponding Terrapup reference file in the repo.

---

# 8. TERRAPUP GENERATION PROCEDURE

## Step 1 — Prepare reference views

Extract or crop clean views from the concept sheet:

- front,
- left/right side,
- back,
- 3/4.

Do not include:

- text,
- design notes,
- other poses,
- other characters,
- scale charts,
- borders,
- or unrelated details

inside the generator input if that confuses the multi-view process.

Preserve:

- identical apparent scale,
- centered creature,
- neutral pose,
- consistent background,
- consistent cropping.

Create temporary cleaned reference inputs if necessary.

Keep original reference art unchanged.

---

## Step 2 — Generate multiple candidates

Generate at least **three** candidates when budget/credits allow.

Do not accept candidate #1 automatically.

Preferred order:

1. Meshy multi-image-to-3D
2. Meshy image-to-3D with best 3/4 reference if multi-view fails
3. Tripo comparison candidate if Meshy results are inadequate

Use prompts that preserve:

- stylized PBR,
- exact species proportions,
- stone mantle geometry,
- brown/cream fur layout,
- large paws,
- expressive face,
- compact sturdy silhouette.

Explicitly reject:

- photoreal fur,
- humanoid anatomy,
- clothing,
- armor,
- generic dog appearance,
- overly realistic claws,
- random accessories,
- excessive moss,
- excessive surface noise.

---

# 9. AUTOMATIC CANDIDATE REVIEW

For every candidate:

1. Import into Blender.
2. Normalize scale.
3. Place on ground plane.
4. Use the same orthographic camera setup.
5. Render:
   - front,
   - side,
   - back,
   - 3/4.
6. Save renders to a comparison folder.
7. Compare them to the equivalent concept-art crops.

Evaluate:

- silhouette,
- head/body ratio,
- ear placement,
- eye placement,
- muzzle length,
- shoulder height,
- leg thickness,
- paw size,
- tail shape,
- stone mantle layout,
- color blocking.

Create a simple scorecard.

Example:

```text
Silhouette similarity          / 10
Face appeal                    / 10
Body proportion similarity     / 10
Stone mantle similarity        / 10
Material/color similarity      / 10
Topology usability             / 10
Rigging suitability            / 10
Gameplay readability           / 10
TOTAL                          / 80
```

Do not hide failures behind a total score.

Any catastrophic failure is a rejection even if the aggregate score is high.

---

# 10. VISUAL QUALITY GATE

Terrapup does not pass merely because a generated mesh looks "cool."

It must look like **our Terrapup**.

Reject or revise if:

- silhouette is substantially different,
- face loses the friendly starter personality,
- creature looks like a normal badger/dog,
- stone mantle looks like artificial armor,
- proportions become photoreal,
- paws are too small to communicate digging,
- materials look plastic,
- fur treatment conflicts with the rest of Tetherbound,
- eyes are uncanny,
- anatomy deforms badly,
- or the creature stops matching the reference at gameplay distance.

Target:

**A player seeing the GLB and concept sheet side by side should immediately identify them as the same designed character.**

For hero assets, aim for roughly **80–90% visual intent preservation**, recognizing that exact pixel-level 3D reproduction is not expected from AI-generated geometry.

---

# 11. BLENDER CLEANUP PASS

After selecting the best candidate:

Inspect:

- non-manifold geometry,
- duplicate geometry,
- internal geometry,
- flipped normals,
- stretched UVs,
- excessive material slots,
- extreme polygon density,
- microscopic disconnected components,
- topology around shoulders/hips/jaw,
- topology around deformation zones,
- symmetry issues,
- eye construction,
- mouth construction,
- feet contacting ground,
- tail origin,
- and stone-plate attachment.

Use remesh / retopology where appropriate.

Do not assume an automatic remesh is sufficient for animation.

For hero assets:

- prioritize deformation quality over preserving generator topology,
- use cleaner edge flow around major joints,
- and perform manual/scripted corrections when necessary.

Avoid destructive optimization before visual form is locked.

---

# 12. MATERIAL PASS

Tetherbound uses stylized PBR.

Target:

- large clean color regions,
- restrained normal detail,
- moderate roughness,
- minimal metallic use on creatures,
- no wet plastic fur,
- no noisy photogrammetry-style albedo,
- no hyperreal pore/fur detail.

Terrapup:

- warm brown primary fur,
- cream face/chest,
- stone gray mantle,
- restrained moss accents,
- dark paw pads,
- expressive teal/blue eye treatment consistent with reference.

Prefer a small material count.

Bake complexity into textures when sensible.

---

# 13. RIGGING

Use generator auto-rigging only as a starting point.

Inspect the armature.

For quadrupeds verify:

- pelvis,
- spine,
- neck,
- head,
- jaw if used,
- front-leg chains,
- rear-leg chains,
- paws,
- tail chain,
- ear bones if needed,
- optional stone mantle secondary bones only if useful.

Test extreme but plausible poses.

Inspect skin weights at:

- shoulders,
- elbows,
- wrists/paws,
- hips,
- knees/hocks,
- neck,
- tail root,
- mouth/jaw.

Reject obviously collapsing deformation.

---

# 14. TERRAPUP REQUIRED ANIMATION SET

Minimum:

- Idle
- Walk
- Run
- Turn
- Hop
- Sleep
- Happy interaction
- Hurt
- Faint
- Directional Quick Attack
- Charged Attack
- Dig / scratch action

Animations may come from:

- Meshy animation tools,
- a compatible animation library,
- retargeting,
- procedural Blender work,
- or custom animation.

Do not use an animation merely because it exists.

It must fit Terrapup's anatomy and personality.

---

# 15. GODOT IMPORT VALIDATION

Export GLB with:

- normalized transforms,
- correct meter scale,
- correct forward direction,
- clean origin/root,
- armature included,
- animations named,
- materials linked predictably.

Create or use a dedicated asset-validation scene in Godot.

Validation scene should allow:

- neutral lighting,
- gameplay lighting,
- orbit camera,
- gameplay-distance camera,
- animation selection,
- skeleton debug if useful,
- scale comparison beside player,
- floor contact,
- shadow inspection.

Do not judge the asset only inside Blender.

The game is Godot.

---

# 16. GAMEPLAY-DISTANCE REVIEW

A character can look good in a Blender close-up and fail in the actual game.

Capture screenshots at:

- normal exploration distance,
- combat camera distance,
- capture/aim distance,
- interaction close-up distance.

Check:

- eye readability,
- limb readability,
- attack anticipation,
- stone mantle visibility,
- silhouette during movement,
- foot sliding,
- clipping,
- material response,
- and whether visual effects obscure attacks.

ROG Ally readability matters.

---

# 17. REFERENCE COMPARISON LOOP

After Godot integration:

1. Capture front / side / back / 3/4 Godot renders if practical.
2. Compare to reference.
3. Identify the **three largest visual mismatches**.
4. Fix those first.
5. Re-render.
6. Repeat.

Do not waste cycles polishing microscopic texture details while the head shape is wrong.

Priority order:

1. silhouette
2. proportion
3. face
4. major color/material breakup
5. distinctive species features
6. animation/deformation
7. secondary detail

---

# 18. TERRAPUP EXIT GATE

Do not proceed to roster-scale production until all are true:

- [ ] Mesh visually matches Terrapup reference
- [ ] Model reads correctly from gameplay camera
- [ ] Materials fit Tetherbound
- [ ] Model is correctly scaled
- [ ] Rig deforms acceptably
- [ ] Required core animations work
- [ ] Quick and charged attacks read clearly
- [ ] GLB imports without material/skeleton failure
- [ ] Performance is acceptable
- [ ] Source + exported asset organization is clean
- [ ] Provenance is documented
- [ ] Owner would willingly use the asset in the actual game

The final checkbox matters.

A technically successful ugly asset is a failure.

---

# 19. AFTER TERRAPUP PASSES

Proceed in this order:

1. Ripplet
2. Galewisp
3. one representative wild Ground Pal
4. one representative Water/Air Pal
5. test style cohesion together in Godot
6. remaining Meadows wild roster
7. Meadowhart / rideable Pal
8. Tuskroot, the one evolution, after Mudsnout
9. Grandpa
10. Warden
11. Veridian Stag legendary

Do not produce the Veridian Stag cheaply just to complete a checklist.

The legendary and starters deserve hero-asset treatment.

---

# 20. HUMANOID CHARACTER RULE

For:

- player,
- Grandpa,
- Warden,

do not assume AI-generated topology and rigging are automatically production quality.

Humans expose errors immediately in:

- face,
- hands,
- shoulders,
- elbows,
- hips,
- knees,
- clothing deformation,
- eye movement,
- and facial expression.

Use AI generation as a base if helpful, then expect a stronger Blender cleanup pass.

Prefer a shared/compatible humanoid skeleton where practical to reduce animation duplication.

Do not force exact skeleton sharing if it materially damages character proportions.

---

# 21. LEGENDARY PAL RULE

The Veridian Stag must not look like:

- a normal deer with accessories,
- a Grass-type cliché,
- a generic fantasy elk,
- or a generator's random "epic creature."

It must preserve:

- ancient Ground guardian identity,
- root/stone antler language,
- large readable silhouette,
- superior ride capability,
- restrained moss,
- restrained Tetherbound energy,
- majestic personality.

Treat it as a hero asset.

---

# 22. LICENSE / PROVENANCE RULES

For every downloaded, generated, remeshed, rigged, or animated asset record:

- source,
- date,
- tool/service,
- account/license tier when relevant,
- original license,
- whether commercial use is allowed,
- attribution requirement,
- modifications performed,
- final repository path.

Update:

`docs/ASSET_LEDGER.md`

Never assume an asset is redistributable.

Never copy random Sketchfab / marketplace / GitHub art into the project without checking license.

---

# 23. SECRET MANAGEMENT

Never commit:

- Meshy keys,
- Tripo keys,
- MCP auth tokens,
- account cookies,
- passwords,
- private URLs containing secrets.

Before modifying configuration, inspect `.gitignore`.

Add local secret/config files to `.gitignore` when appropriate.

Prefer environment variables.

If a required key is missing, tell the owner:

1. exactly which service,
2. why it is needed,
3. where to obtain the key,
4. the environment-variable name,
5. and how to verify connectivity.

Do not ask the owner to paste a secret into a tracked Markdown file.

---

# 24. SECURITY RULES FOR MCP

A Blender MCP can execute powerful local commands.

Therefore:

- use trusted/open-source repos after inspection,
- prefer localhost,
- do not expose MCP endpoints externally,
- do not disable authentication casually,
- do not install unexplained binaries,
- do not run arbitrary remote shell scripts without reading them first,
- pin versions/commits when stability becomes important,
- document the chosen setup.

Before executing a one-line remote installer, inspect its contents or install through a conventional package manager/manual process when practical.

---

# 25. COST CONTROL

AI 3D services can consume credits quickly.

Use this strategy:

### Cheap stage
- crop references
- test prompt
- low-cost preview
- validate gross silhouette

### Candidate stage
- generate 2–3 serious candidates

### Refinement stage
- spend credits only on the best candidate

### Hero stage
- remesh/rig/animate only after visual selection

Do not rig and animate three bad candidates.

Do not batch-generate 15 Pals before the style pipeline is proven.

---

# 26. WHEN TO REGENERATE VS FIX

Regenerate when:

- overall anatomy is wrong,
- silhouette is fundamentally wrong,
- face is wrong,
- major appendages are missing,
- topology is catastrophically unusable,
- concept identity is lost.

Fix in Blender when:

- paw size is somewhat off,
- ears need reshaping,
- tail needs adjustment,
- stone plates need repositioning,
- material colors are off,
- small symmetry issues exist,
- topology needs cleanup,
- rig weights need repair.

Do not spend hours repairing the wrong base mesh.

---

# 27. DO NOT TRUST A SINGLE GENERATOR

Different models may be better at different species.

The approved philosophy is:

**Generate candidates → compare → choose best → clean → validate.**

Not:

**Pick one provider forever.**

However, avoid unnecessary tool proliferation.

Meshy is the preferred starting point because its current official MCP exposes the broadest relevant pipeline in one service.

Tripo is a useful fallback/comparison path.

Blender remains the authoritative cleanup/inspection environment.

---

# 28. EXPECTED PROBABILITY / QUALITY REALITY

Without AI image-to-3D assistance, Claude scripting an organic hero creature from scratch has a meaningful risk of creating something recognizable but visibly inferior to the concept art.

With:

- multi-view reference art,
- multiple candidate generations,
- Blender visual feedback,
- remesh/topology cleanup,
- rig inspection,
- Godot screenshots,
- and iterative comparison,

the odds of preserving the intended visual design improve substantially.

For simple stylized creatures such as Terrapup, the pipeline should target a result that preserves most of the concept's visual identity.

Feathered creatures and humanoids are harder.

Do not lower the bar merely because they are harder.

---

# 29. ART-PRODUCTION REPORT

For Terrapup create:

`docs/art/TERRAPUP_PRODUCTION_REPORT.md`

Record:

- generator used
- prompt
- reference inputs
- number of candidates
- screenshots of candidates if repository policy allows
- chosen candidate and why
- topology stats before/after
- texture resolution/material count
- rig method
- animations
- GLB size
- Godot test result
- performance notes
- known imperfections
- owner review result

This becomes the template for later hero assets.

---

# 30. CREATE A REUSABLE CLAUDE SKILL AFTER THE PROOF

Once Terrapup succeeds, convert the successful process into a reusable local Claude skill or equivalent agent instruction.

Suggested path:

`.claude/skills/tetherbound-character-production/SKILL.md`

The skill should encode the workflow that **actually worked**, not this document's speculative branches.

It should include:

1. find canonical reference
2. prepare clean multiview inputs
3. generate N candidates
4. import to Blender
5. render standard comparison views
6. score candidates
7. select
8. cleanup/remesh
9. materials
10. rig
11. animations
12. export GLB
13. Godot validation
14. gameplay screenshots
15. reference comparison
16. final quality gate
17. asset-ledger update
18. production report

---

# 31. FIRST EXECUTION TASK

Claude:

Begin by doing the following now.

1. Inspect whether Blender is installed.
2. Inspect whether Node.js / npm / npx and Python are available.
3. Inspect existing MCP configuration.
4. Inspect the Tetherbound art/reference files.
5. Inspect the official Meshy MCP repository and current README.
6. Inspect the candidate Blender MCP repositories listed above.
7. Select one Blender MCP based on current compatibility, maintenance, license, and capabilities.
8. Install/configure it if permissions allow.
9. Install/configure Meshy MCP if permissions and credentials allow.
10. If a Meshy key is missing, stop only at the credential boundary and give the owner the exact one-step requirement; continue all setup work that does not require the secret.
11. Prepare the Terrapup reference crops.
12. Create the standard Blender comparison scene and Godot asset-validation scene.
13. Do **not** generate the entire roster.
14. Generate/produce Terrapup first.
15. Iterate until the Terrapup exit gate passes or you can clearly explain the remaining blocker.

Do not merely reply with a plan if you have permission and tooling to execute the plan.

Make the pipeline real.

---

# 32. CURRENT TOOL REFERENCES TO RE-CHECK BEFORE INSTALLATION

These were good candidates when this file was created, but Claude must verify current status before installing:

- Official Meshy MCP:  
  `https://github.com/meshy-dev/meshy-mcp-server`

- Meshy guides / game-asset guidance:  
  `https://github.com/meshy-dev/Meshy-guide`

- Official Tripo MCP:  
  `https://github.com/VAST-AI-Research/tripo-mcp`

- Blender MCP candidate:  
  `https://github.com/glonorce/Blender_mcp`

- Blender MCP candidate:  
  `https://github.com/mackson/blender-mcp`

- Experimental Godot-oriented Blender MCP:  
  `https://github.com/ricky-yosh/blender-mcp`

Repositories, installation commands, API requirements, and feature support change.

**Always inspect the current README before installation.**

---

# FINAL PRINCIPLE

Tetherbound's art pipeline is successful only when it produces characters the player emotionally accepts as the characters in the reference art.

Automation is a means to get there.

It is not the quality standard.

**Reference fidelity + gameplay readability + clean technical integration are the standard.**
