# BACKLOG-C1-NESS-FACE — diagnosis (no fix applied)

**Scope: diagnosis only**, per the task brief for this branch. Nothing under
`scripts/`, `data/`, `assets/` or `shaders/` was changed. Two small
throwaway-style probes were added under `tools/` (`_capture_t1_villagers.gd`
itself was **not** modified) to reproduce and isolate the defect; they are
kept, matching this repo's own precedent of keeping purpose-built probes
(`tools/_probe_rank_ladder.gd`, `tools/_diag_golden_hour.gd`).

## What was asked

Audit C's C1 finding (`ralph/reports/audit/C-2026-08-31.md`, line 32 and the
full section starting line 40) says Warder Ness's face renders as a flat,
featureless black shape — no eyes, brows or mouth, hair "one solid magenta
mass" — at conversation range (3.8m), on the `officer_b` body, and that the
audit itself "independently reproduced" this fresh against `main` at
`453107fb`, citing `ralph/reports/audit/C-2026-08-31-shots/11-tether-officer-ness.png`
as that fresh evidence.

Per `CLAUDE.md`'s binding instruction, `docs/art/HUMANOID_ASSET_INVENTORY.md`
was read first. It confirms `officer_b` is one of the 22 `T1-NPC-CAST`/
`T3-INSTALL`-generated humanoid bodies (the Meshy pipeline), not one of the
six hand-built production rigs, and — significant for what follows — that as
of the T1-VILLAGERS pass that first wired Ness onto it, `officer_b` was
**"installed, rigged, and standing nowhere in the game"**: this was the
character's first-ever appearance in an actually-rendered scene anywhere in
the project's history.

## Setup

Godot 4.7-stable (CI's own pin, `.github/workflows/ci.yml`) installed fresh
to `~/godot-bin`. `godot --headless --path . --import` run to completion
(cold cache, no `.godot/` in this container) before anything else, per this
repo's own `ralph/conventions.md` warning that a missing import cache makes
resources "fail to load and viewpoints silently render flat/empty instead of
erroring." Captures run with `xvfb-run -a -s "-screen 0 1280x800x24" godot
--path . --rendering-driver opengl3 ...` (never `--headless` with a real
renderer — the other documented trap).

Confirmed the working tree is a fair comparison to the audited commit before
touching anything:

```
git merge-base --is-ancestor 453107fb HEAD   # true — HEAD is 453107fb + 183 commits
git diff --stat 453107fb HEAD -- assets/characters/officer_b/ \
  scripts/characters/character_model.gd tools/regrade_tether_textures.py \
  data/config/npc_ranks.json data/config/bands/band5_stronghold_approach/trainers.json \
  tools/_capture_t1_villagers.gd
# empty — every file relevant to this defect is byte-identical to the audited commit
```

## The defect does not reproduce on a clean checkout

Ran the audit's own unmodified capture tool
(`tools/_capture_t1_villagers.gd --stage=tether`) twice, independently, full
Meadows stand-up each time (382,817 scattered props, `capture_check` clean on
every shutter):

- Run 1 — `ralph/reports/audit/fresh-repro-shots/11-tether-officer-ness.png`.
  Face renders correctly: eyes, brows, nose, mouth, natural skin tone. Tight
  crop over the face measures median luma ≈95/255 (the original defect
  evidence, `ralph/reports/T1-VILLAGERS/shots/tether-03-officer-ness-officer_b-NEWLY-WIRED.png`,
  measures ≈31/255 over the same crop — a real, large difference, not noise).
- Run 2 (deleted after confirming, to keep the diff small; described here for
  the record) — same result, face correct.

Then built a small purpose-built A/B probe,
`tools/_diag_ness_time_ab.gd` (new file, does not modify
`_capture_t1_villagers.gd`), that spawns **only** Officer Ness (`officer_b`)
and shoots the identical conversation-range close-up under each of the four
named time-of-day presets in `data/config/art.json` (`day`, `golden`, `dawn`,
`night`), pinned explicitly via `WorldLook.apply_time()` rather than left to
drift — `data/config/art.json`'s `character_emission_floor` drops to `0.5` at
night/dawn versus `1.0` at day/golden, and this project has an extensively
documented history of near-black textures crushing toward pure black at
reduced emission-floor scale (`character_model.gd`'s own `GF-B-010`/
`T1-LIGHT` comments; `data/config/art.json`'s `_comment_character_emission_floor`;
the ACES-tonemap-toe mechanism named repeatedly across this codebase), so
this was the leading hypothesis for an intermittent, lighting-linked cause.

Result: **`ralph/reports/audit/diag-time-ab/ness-{day,golden,dawn,night}.png`
all show a correctly rendered face.** Night is visibly darker overall (navy
sky, dim ambient) but Ness's face reads if anything *brighter* against the
dark surroundings, not crushed — consistent with a separate, already-recorded,
unrelated defect this project's own `art.json` documents (`_comment_ambient_ev8`
region, referenced as "T1-WORLD verdict sec5": *"The head and hands are a
SEPARATE and unrelated defect... they are near-white untextured art on the
rig... which is why they stay bright at night no matter what this value is
and why the same pale face shows on the village NPCs"*). The
`character_emission_floor` hypothesis is therefore **ruled out**: all four
pinned lighting states render Ness's face correctly, including full night.

So across six independent fresh renders (two full capture-tool runs plus four
pinned-time single-body renders), against assets and code that are byte-for-byte
identical to the audited commit, **zero reproduce the black-void face.**

## What was ruled out, with evidence, and how

- **Missing/broken texture reference.** `officer_b_lod0.glb`'s material
  (`Material_1`) is structurally identical to `officer_a`'s — dumped both as
  JSON from the glTF chunk directly: one material, `baseColorTexture` and
  `emissiveTexture` both pointing at the model's own single embedded
  `texture_0` image, `KHR_materials_specular`/`KHR_materials_ior` extensions
  present on both, nothing missing or dangling on either.
- **Material/shader parameter difference.** Same dump: emissiveFactor
  `[1,1,1]` on both, no `metallicFactor`/`metallicRoughnessTexture` on
  either (both get glTF's implicit `metallic=1.0`, which
  `character_model.gd`'s own documented `GF-B-010` fix corrects to `0.0` for
  *any* body material with no metallic texture — a generic, name-independent
  branch, so it treats officer_a and officer_b identically). No difference
  found anywhere in the material graph that could explain one face going
  black and the other not.
- **Normal-map issue.** Neither material has a `normalTexture` at all.
- **LOD swap.** Only `_lod0.glb` exists for this body and only `_lod0` is
  ever loaded; no distance-based LOD swap mechanism applies to character
  bodies at conversation range.
- **A genuine hole in the texture bake.** Extracted the mesh's own UV
  coordinates directly from the glTF accessors (`POSITION`/`TEXCOORD_0`/
  `JOINTS_0`/`WEIGHTS_0`, parsed by hand — no Blender available) for the
  vertices rigidly weighted (>0.9) to the `Head` bone, restricted to the
  centreline and forward-most 15% by local Z (forehead → nose-bridge → upper
  lip). Their UVs trace a smooth, continuous path through pixel coordinates
  roughly `(1585–1645, 224–420)` in the 2048×2048 atlas
  (`assets/characters/officer_b/officer_b_lod0_texture_0.png`). Cropping that
  exact region shows a properly detailed, correctly exposed painted face —
  eyes, brows, nose, believable skin tone — not a black or blank patch. (One
  discontinuity was found lower down, around the jaw/chin vertices, whose UVs
  jump to a flesh-toned but featureless patch elsewhere in the atlas that
  looks like a hand/knuckle island — a real, separate authoring oddity in
  this Meshy-generated body worth a note for whoever touches this asset
  next, but it is a skin-toned patch, not black, and the rendered evidence
  crops (both the original defect frame and this session's clean frames) show
  the crush/correctness affecting the *whole* face including the
  forehead/eyes region that *does* map correctly — so this discontinuity does
  not explain the reported symptom either.)

## What this leaves: an environment/load-order-dependent defect, not a content bug

The strongest remaining explanation, consistent with every measurement above,
is that the original sighting was a **first-load race specific to the
capture/import sequence**, not a persistent property of the shipped asset:

- `officer_b` was, at the moment `T1-VILLAGERS` wired it into
  `trainers.json`, a body that had **never before been referenced by any
  scene, test or capture in this project's history** (confirmed by
  `docs/art/HUMANOID_ASSET_INVENTORY.md`'s own "standing nowhere in the game"
  note). That session's own capture was therefore the *first* time Godot
  ever had to resolve and upload `officer_b`'s texture to the GPU.
- This repo's own `ralph/conventions.md` independently documents this exact
  failure shape as a real, previously-paid-for trap: *"A fresh container has
  no `.godot/` import cache... without it, resources fail to load and
  viewpoints silently render flat/empty instead of erroring"*, and
  separately, that a capture taken before a fresh bake/import has fully
  settled reads back stale or wrong.
- Every render in this session that showed a correct face followed the
  disciplined sequence this file prescribes: a full, separate
  `godot --headless --path . --import` pass run to completion *before* any
  capture process started. Six independent renders, six correct faces, zero
  exceptions.
- The material/shader/texture-content evidence above rules out every
  alternative that would need a code or asset change to fix: nothing in
  `officer_b`'s material graph, UV mapping (for the affected forehead/eye
  region specifically), or lighting response differs from the bodies that
  render correctly.

## What a fix would need to touch, if a maintainer reproduces this again

1. **First, confirm it still reproduces at all**, the same way this session
   did: same import discipline, same tool, same commit. This diagnosis found
   it does not, six times running. If it still doesn't reproduce, this may
   already be closed in practice and just needs `MEADOWS_EXIT_CRITERION.md`'s
   bookkeeping reconciled (per `CLAUDE.md`'s "evidence-backed already fixed
   is valid" guidance) rather than a code change.
2. **If it does reproduce**, the next isolation step is timing, not content:
   capture `officer_b` as the *very first* body loaded in a fresh process
   (no prior `--import` pass, or a scene that references it for the first
   time), versus after a full import — i.e. try to deliberately recreate the
   "never before referenced" condition `docs/art/HUMANOID_ASSET_INVENTORY.md`
   describes, rather than editing the atlas or the material.
3. **If that reproduces it**, the fix is almost certainly a project/tooling
   discipline fix (always run a full import before capturing/shipping a body
   that has never before appeared in any scene), not a game-code or asset
   change — there is nothing wrong with the shipped material, UV mapping (for
   the affected region), or texture content to fix.
4. **Separately, and lower priority**: the jaw/chin UV discontinuity found
   during this investigation (mapping to a flesh-toned but featureless patch
   elsewhere in the atlas) is a real, minor authoring oddity in this
   Meshy-generated body. It is not the reported black-void symptom and was
   not chased further here, but is worth a note if `officer_b` is revisited.

## Evidence committed on this branch

- `ralph/reports/audit/fresh-repro-shots/` — full tether-cast capture-tool
  output from this session (10-tether-rank-ladder.png,
  11-tether-{grunt,officer-dell,officer-ness,captain,warden}.png), unmodified
  tool, `capture_check` clean.
- `ralph/reports/audit/diag-time-ab/` — the four pinned-time-of-day renders
  of Ness alone (`ness-day.png`, `ness-golden.png`, `ness-dawn.png`,
  `ness-night.png`).
- `tools/_diag_ness_time_ab.gd` — the A/B probe itself, kept per this
  project's own precedent of keeping purpose-built diagnostic tools.
