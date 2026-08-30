# Asset Ledger

## Creature HUD portraits (2026-08-21)

- `assets/ui/portraits/creatures/*.png` are curated runtime copies of the
  existing owner-supplied creature renders under
  `assets/creatures/tetherbound/*/reference/` (three-quarter view where
  available; Veridian uses its existing front view). No new image generation
  or third-party source was used. The copies exist because the canonical
  reference directories are intentionally `.gdignore` and therefore cannot be
  loaded by the shipped HUD.
- **T3-INSTALL, 2026-08-30**: added `sparkit.png`, `shadelet.png`,
  `frostclaw.png` (curated copies of each species' own
  `reference/head.png`) and `cindercub.png` (copy of `reference/front.png`
  — no `head.png` exists for this one) once these four species entered the
  live roster and `tests/test_hud_widgets.gd
  ::test_every_installed_species_has_the_hud_portrait_it_resolves` caught
  the gap. Same pattern as the row above: a curated copy of owner-supplied
  reference art already committed under
  `assets/creatures/tetherbound/<id>/reference/`, no new generation, no
  third-party source.

Provenance for every non-original asset in the project, per `CLAUDE.md` and
`docs/TECHNICAL_START.md`.

Assets do not need to be CC0 for this private project. The rule is that nothing
ships without a row here, so attribution is a lookup rather than an archaeology
project, and so a licence audit before any public release is possible at all.

A row is required **before** the file is committed. Record the licence as found
at the time it was fetched, not as remembered.

| Asset | Creator | Source | Licence | Paid | Local path | Modifications |
|---|---|---|---|---|---|---|
| Meadows soundscape — 73 audio files, all written for this project (`assets/audio/ambience/` ×8, `sfx/` ×52, `creatures/` ×8, `music/` ×5) | Original, synthesised in Python by `tools/audio/` (`synth.py` plus `gen_ambience.py` / `gen_sfx.py` / `gen_creatures.py` / `gen_music.py`; `gen_all.py` runs all four) | **Not sourced.** No sample library, no pack, no download, no generation service. Every sample is computed from oscillators and filtered noise by committed code in this repo. | Original work; not applicable. **No third-party licence attaches to any file in `assets/audio/`.** | No | `assets/audio/` | **T1-AUDIO, 2026-08-30.** The chapter had no music, no ambience, no footsteps, no combat audio and no creature voices; the entire shipping audio set was nine UI cues under `assets/ui/audio/` (themselves generated the same way by the pre-existing `tools/audio/gen_ui_cues.py`, whose row is this one's precedent) plus six unused vendor clicks under gitignored `assets_raw/`. Synthesis was chosen over sourcing deliberately, and the trade is recorded in `tools/audio/synth.py`'s header rather than only here: it removes the licence surface entirely, it keeps the whole set cohesive by construction (one synthesis chain, not ten rooms and ten mic distances), and it is far smaller — the eight ambience layers are 6.2 MB of PCM on disk but **161 KB each in memory** once Godot's QOA import compresses them, which matters on the ROG Ally where VRAM is shared system RAM. Determinism is a hard property, not a nicety: every generator takes an explicit seed and its own `numpy.random.Generator`, so a regeneration with no source change produces byte-identical files and the committed binary diff stays proportional to the change that caused it. **numpy is a tool-time dependency only** — the `.wav` files are committed, so nothing in CI or in an export runs these scripts; it is already an accepted dependency for ten other `tools/*.py`. **Where synthesis is honestly worse, this file says so rather than pretending:** the meadow birdsong reads as "small bird" rather than as any species, and the five music cues are short generated loops, not a score — they are shippable placeholders that carry the right mode, pacing and emotional beat (and are therefore a better brief for a real composer than silence), and `gen_music.py`'s header says outright that they should be replaced. Wind, water, stone, impacts and creature voices are cases where synthesis is genuinely competitive or better, and those are the bulk of the set. |
| Ordinary (`*_vivid`) creature colourways — regenerated, no new asset | (derived from the existing creature albedos, see their own rows) | Not sourced. Every pixel is a transform of a texture already in the tree, by `tools/repaint_creature_textures.py`. | (unchanged — inherits each source texture's row) | No | `assets/creatures/tetherbound/*/models/*_base_color_vivid.png` and `*_emissive_vivid.png` | **CREATURE-PRESENTATION 2026-08-23.** Re-keyed six species' hues off the terrain, then a new finish pass (median despeckle, value quantised into bounded zones, saturation ceiling, darkest-3%-of-source features re-stamped) and a 2048 -> 1024 downsample. Set size 110MB -> 24MB. Recorded here only so a later session does not go looking for where a 1024px texture was bought — **nothing was sourced, nothing was generated, no Meshy credit was spent.** **CREATURE-IDENTITY-2 2026-08-23** then regenerated the whole set again, through the same tool plus a new identity-overlay stage (`tools/creature_overlays.py`, masked by `tools/creature_anatomy_maps.py`'s UV-space rasterisation of each species' own glb): the owner board's leaf ears, moss carpets, greened antler tips and storm-blue feather tips. Still a pure transform of textures already in the tree — **nothing sourced, nothing generated, no Meshy credit spent, and no mesh modified** (the anatomy maps are READ out of the glbs and cached as gitignored `*_anatomy.npz`). The `*_shiny` set is no longer the exception: it went through the identical finish and overlay passes, which closes BACKLOG's SHINY-FINISH and takes it from 2048 to 1024 as well. Two new `*_alpha` colourways (burrowback, galecrest) join them for cluster leaders. |
| Generated camp set (`camp_tent.glb`, `camp_bed.glb`, `campfire_stone_ring.glb`) | Meshy (AI mesh generation), directed against the owner's reference board above | Meshy API, `tools/art_pipeline/meshy.py` | Meshy's standard generation terms (this project already generates creature/hero-prop meshes the same way; see the pipeline's other rows) | Yes — 380 Meshy credits (180 preview across 9 candidates, 200 across four refine/retexture passes; balance 4200 -> 3820) | `assets/props/generated_camp/` | Straight Meshy output, GLB as delivered. Provenance per asset (`assets_raw/<name>/<candidate>/provenance.json`, not committed — `assets_raw/` is gitignored, the pipeline's standing convention): `camp_tent` and `camp_bed` are each one refine-tier multi-image-to-3D candidate (`camp_tent` task `01a02c2f-fe7d-7b4b-aac1-6b62f54e7f02`, `camp_bed` task `01a02c31-3c61-74b1-9f3a-79e1a65bd922`) generated straight from the reference crops. `campfire_stone_ring` is the stone-ring geometry from preview-tier candidate `c` (`01a02c24-33a6-7ec0-92d9-669b06a83e84`) — the only one of five attempts (3 preview + 2 refine) that kept the ring as a clean 3D form rather than dropping it or flattening it to 2D discs — retextured separately (`meshy.py texture`, task `01a02c36-d0a5-7c6c-ab09-d07b464b6155`) rather than regenerated, which is `tools/art_pipeline/README.md`'s own documented order (form at cheap tier, texture only the winner) and avoided re-rolling the geometry dice a third time. `camp_bed`'s generation used the logo-scrubbed crops and `NEGATIVE_CAMP_BED`; the delivered mesh carries a plain dark blanket with no emblem, checked visually against the render in `shots/camp_candidates/__tracked__camp_bed.png` before being wired into `props.json`.

**Follow-up round, same session, owner-directed.** A dispatched Fable fidelity review (render vs. original reference, blind to what changed) called the tent "a poor reproduction" -- silhouette collapsed to a low lean-to, plus a floating detached mesh fragment -- and the fire ring "recognizable-but-drifted" -- stones too small and gapped; the bed came back "faithful... ship as-is". Fire ring: scale raised 0.85 -> 1.05 in `props.json` (the only lever available without another generation, per Fable's own "fixable in-scene" read). Tent: five more rounds and eight more candidates tried multi-image-to-3D at fewer/different reference views, then `text-to-3d` (genre `/openapi/v2/text-to-3d`) for form with `texture` retexturing the winner against the reference crop -- documented in `tools/art_pipeline/meshy.py`'s own `camp_tent` prompt comments, round by round, because the failure mode changed each time (flattened silhouette when driven by images regardless of prompt wording; a teepee instead of an A-frame when driven by text alone; correct A-frame but missing patches/rigging/weathering once the teepee was fixed) and each fix is a real lesson for the next asset this pipeline generates. A second Fable review of the best text-to-3D result still called it "recognizable-but-drifted" and not ship-ready. **The owner reviewed a contact sheet of all eight tent candidates directly and chose round 1's original result** -- the same task `01a02c2f-fe7d-7b4b-aac1-6b62f54e7f02` this row already names -- over every later attempt. Total spend this session: ~590 of 4200 credits (balance 3610 as of the last `check`). 

**A real placement bug was found and fixed while investigating the bed's "missing a bottom" report**: `props.json` never set `sink_m` for `camp_tent`/`camp_bed`, and both meshes' local origins sit well above their own geometric base (measured via a new probe, `tools/_probe_bed_float.gd`: 0.21m for the bed, 0.64m for the tent), so both were sinking into the terrain by that amount with only their upper portion visible -- not a mesh defect, a missing `sink_m` compensation exactly like the one this file's Backpack entry already needed. Fixed (`sink_m: -0.21` / `-0.64`); confirmed flush with ground afterward, matching the Bench/Stool props beside them. |
| Camp set reference board (tent/campfire/bed) | Owner-supplied (AI-generated, in another game's visual style) | Provided by owner 2026-08-23, in-conversation upload | Owner's own | No | `docs/art/reference/owner-board-2026-08-23-camp-set.png` | None on the archived board itself. **Used as Meshy generation reference only, never as a game asset directly** — the board depicts objects in the visual style of a different shipping game (a paw-print emblem and leaf icon are visible on the bed panel's blanket/pillow, that game's own trademark). The crops actually fed to Meshy under `assets/creatures/tetherbound/camp_bed/reference/` have both marks Gaussian-blurred out before submission (docs/ASSET_LEDGER.md's own rule: reference art guides shape/palette/silhouette, it is not redistributed or reproduced verbatim) plus a negative-prompt guard (`NEGATIVE_CAMP_BED`, `tools/art_pipeline/meshy.py`) against the generator inferring a similar mark from the surrounding stitching. `camp_tent`/`camp_fire_pit` crops needed no scrubbing — no text or marks appear in those panels. Owner directive: generate against this board via the existing Meshy pipeline, which otherwise reserves generation for the three Team Tether hero objects (CLAUDE.md/D24) — see `tools/art_pipeline/meshy.py`'s own comment on the `PROPS` set for why this is recorded as an explicit owner decision rather than a routine spend. |
| Survival Kit 2.0 — 6 models + `colormap.png` (`bedroll.glb`, `bedroll-frame.glb`, `bedroll-packed.glb` are the sleep props; `tent.glb`, `tent-canvas.glb`, `campfire-pit.glb`) | Kenney | [Survival Kit](https://kenney.nl/assets/survival-kit) (v2.0, dated 03-04-2024 in the pack's own `License.txt`, fetched 2026-08-22) | CC0 1.0 — verified from the `License.txt` shipped inside the zip and copied to `assets/props/kenney_survival/License.txt`, not from the download page alone | No | `assets/props/kenney_survival/` | None — straight copies of the GLB-format files (plus `bedroll.obj`/`bedroll.mtl` from the same fetch's OBJ-format folder, because `scripts/build/camp.gd` loads a bare Mesh and a .glb arrives as a PackedScene) files plus the shared `Textures/colormap.png` they reference by relative path. BAND1-D1: the `trail_camp` cluster had no sleep prop, which two independent blind critics both named as the gap between 'objects arranged in a ring' and 'someone stopped here'. Round 3 first parked this in `ralph/BLOCKED.md` as needing owner-supplied reference art; that was wrong and the owner corrected it — `CLAUDE.md` forbids *generating* without reference art, while its 'Asset work' section explicitly permits *sourcing* a candidate. Quaternius's own Survival pack was checked first for cohesion (it is the five models already vendored at `assets/props/quaternius_survival/`) and has no shelter of any kind. Scale and materials were tested in-engine before placement per this file's own rule (`tools/_probe_kenney_survival.gd`): every surface carries a real `colormap` albedo texture — the exact check `assets/environment/nature` fails, see its note below — and the pack is authored small, ~0.3–0.6m, so `props.json` scales it 3.0–3.5. Only `tent-canvas` and `bedroll` are placed today; the other three are vendored as siblings from the same fetch rather than as a second trip to the same source. |
| `assets/environment/nature` — defect note, no new asset | (existing vendored pack) | (see its own row) | (unchanged) | No | `assets/environment/nature/` | **Not usable through `props.gd`.** BAND1-D1 round 3, measured with `tools/_probe_camp_materials.gd`: every model in this pack carries materials with **no albedo texture** and a flat placeholder colour — `grass` is albedo (0.45, 0.93, 0.87), which renders as flat cyan, and `dirt` is (0.95, 0.74, 0.62), near-white. The pack is authored against a palette atlas the glTF import does not apply. Only `log`/`log_large` pass, and only by luck: their wood-tan placeholder happens to look like wood. The shared scatter layers in `data/config/vegetation.json` use the same pack, so this reaches open field far outside any one cluster; that half is flagged in `ralph/BLOCKED.md` for the coordinator, since no Gate-D lane may edit that file. |
| Torch prop (`torch_prop.tscn`) | Original, built from primitives in `scripts/world/torch_prop.gd` (no vendor source) | N/A — no torch/brand/lantern mesh exists anywhere under `assets/` (checked before building: `find -iname "*torch*" -o -iname "*flame*" -o -iname "*lantern*"` across `assets/` turns up only the Quaternius Survival bonfire, whose "Fire" surface was believed to share one ArrayMesh with its log geometry and to be impossible to pull out standalone — **that belief is wrong and was corrected by BAND1-D1 round 3**: it is true of the OBJ file, which is a single object, but Godot's OBJ loader splits by material, so `Bonfire_Fire.obj` arrives as three surfaces (`Wood`, `LightWood`, `Fire`) and the flame cone can be addressed on its own, which is what `campfire_glow.gd::ignite()` now does (`tools/_probe_bonfire_fire.gd`). This does not invalidate the torch prop below, which needs a handheld flame rather than a ground bonfire's, but the reasoning recorded here should not stay false) — D24 forbids a Meshy generation with no owner-supplied reference board, so this is code-built geometry: a tapered `CylinderMesh` stick, a flame and embers as radial-gradient billboard quads (the same procedural-texture technique `vegetation_harvest_point.gd`'s glint halo already uses, so no flame/ember texture asset was needed either) | Original work; not applicable | No | `assets/props/built/torch_prop.tscn`, `scripts/world/torch_prop.gd` | OF24. The stick's colour is not invented: `Kd 0.384608 0.289962 0.254778`, copied from the Quaternius Survival bonfire's own "Wood" material (`assets/props/quaternius_survival/Bonfire_Fire.mtl`) rather than picked fresh. Reused as-is for both the carried torch (`scripts/player/torch.gd`, bone-attached to the trainer rig's `Hips`) and the free `torch` ground buildable (`data/items/buildables.json`); neither the light nor the flicker lives in this scene — each caller adds its own `OmniLight3D` from its own data (`movement.json`'s `torch` block; the buildable's own `light` block). |
| World-look reference frames ×3 (`moong-01-mounted-in-tall-grass.jpg`, `moong-02-meadow-with-landmark.jpg`, `moong-03-meadow-with-landmark-alt.jpg`) | MoonG Dev (YouTube `@onokoreal`) | Frames from the public video "Godot Souls-Like Gameplay Demo with Procedural World & Dungeon" (`youtu.be/zzeIpjQ8FBw`, published 2026-08-24). Captured by the owner from the video and supplied in-conversation 2026-08-25. | **Not licensed to this project.** Third-party copyrighted game footage, recorded here so that is a lookup rather than an assumption. | No | `docs/reference/moong-01-mounted-in-tall-grass.jpg`, `-02-meadow-with-landmark.jpg`, `-03-meadow-with-landmark-alt.jpg` | Cropped to the game frame; the surrounding phone UI and video description panel removed. No other edit. **Judging reference only, on the same footing this file already gives the Palworld frames beside them** — they guide ground-cover density, layer occupancy and composition for `docs/ralph-prompts/72-WORLD-ground-cover-and-mid-layer.md`. Never shipped, never traced, no asset derived from them, and not a palette authority: where these and `tetherbound-meadows-keyart.png` disagree the keyart wins per `docs/reference/README.md`. Owner direction, 2026-08-25: "make our world look like that", grass first. |
| Meadows key art board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/reference/tetherbound-meadows-keyart.png` | None |
| Creature colour refresh boards ×2 (2026-08-15) | Owner-supplied (AI-generated) | Provided by owner with the 2026-08-16 implementation brief | Owner's own | No | `docs/reference/owner-board-2026-08-15-creature-colors.png`, `docs/reference/owner-board-2026-08-15-systems-and-castle.png` | None. **These are the authority for the roster's ordinary (vivid) colourways** — per-species palette captions ("Warm earth tones + Moss accents", "Deep blues + Translucent fins", …), move/TM tables, the Meadows castle concept, Grandpa's five dialogue beats, and the potions set. Vendored because the first vivid colour pass (OF28 base half) was authored by a session that could not see them and went jewel-toned against their direction — the boards living only in a chat thread is exactly how that happens twice. Owner's framing: direction, not pixel targets ("none are the exact direction"). |
| Creature expansion boards ×10 (2026-08-30) | Owner-supplied (AI-generated) | Provided by owner with the Meadows Creature Expansion brief | Owner's own | No | `docs/art/reference/creature-expansion-2026-08-30/` (master sheet + 9 per-creature sheets) | **Authority for the nine expansion creatures** — Nightburrow, Stormtrail, Sparkit, Cindercub, Shadelet, Bramblebun (redesign), Riftfrill, Ashtusk, Frostclaw. Each sheet carries type, build path, colour palette with named swatches, pipeline note, Meshy-realism note and flavour note; the master sheet adds a size guide relative to a 1.8m player, a texture/material guide and VFX examples. These satisfy `CLAUDE.md`'s "never a Meshy generation without owner-supplied reference art" for these nine creatures and no others. Brief: `docs/owner-direction/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md`. Direction, not pixel targets. |
| Nightburrow/Stormtrail/Riftfrill/Ashtusk Aspect-variant textures (T1-CREATURE-ART, 2026-08-30) — regenerated, no new asset | (derived from Burrowback/Trailpup/Paddlenewt/Tuskroot's own existing albedos, see their own rows) | Not sourced. Every pixel is a transform of a texture already in the tree, by `tools/generate_aspect_variant_textures.py` (reuses `tools/repaint_creature_textures.py`'s HSV-rule/finish/overlay machinery and `tools/creature_anatomy_maps.py`'s anatomy predicates unchanged, against `data/creatures/aspect_variants.json`) | (unchanged — inherits each source texture's row) | No | `assets/creatures/tetherbound/burrowback/models/*_nightburrow.png`, `.../trailpup/models/trailpup_extracted_*_stormtrail.png`, `.../paddlenewt/models/*_riftfrill.png`, `.../tuskroot/models/*_ashtusk.png` | Same recolor-and-emissive build path the reference boards above specify for all four ("VARIANT RECOLOR + RESIZE + VFX" / "VARIANT RECOLOR + VFX") — **no new mesh, no Meshy generation, nothing sourced or generated outside this tree.** The `_base_color_<variant>.png` siblings are an HSV recolor pass toward each board's own named palette. The `_emissive_<variant>.png` siblings are a SYNTHESISED glow map, not a recolor of an existing one: Burrowback/Paddlenewt/Tuskroot ship a 4x4 near-black emissive stub and Trailpup's real emissive is a plain copy of its own albedo (confirmed directly, `tools/_probe_aspect_source_materials.gd`), so none of the four had a usable glow to repaint. The generator instead builds one from the recoloured albedo's own darkest-percentile seams (armor plate grout, scale ridges) for the "cracks" look, plus one colour-matched (not darkest-pixel) layer for Ashtusk's pale ivory tusks specifically. Recorded here for the same reason the `*_vivid` row above is: so a later session does not go looking for where these were bought. **Follow-up, T1-VARIANTS 2026-08-30, same generator/spec files, no new asset:** JUDGE-3's blind pass (`ralph/reports/JUDGE-3-2026-08-30.md` section 5) found all four glow masks shared "one aliased, mirrored, unlit decal mask" -- confirmed by opening the committed texture files. Root-caused rather than cosmetically patched: `build_glow_map()`'s old boolean threshold (`v <= cut`) grown by a binary `ImageFilter.MaxFilter` had no soft edge at any radius (the pixel staircases); the darkest-percentile "seam" search ran on the ALREADY-FINISH-PASSED albedo, whose own darkest pixels are `finish_pass`'s own forcibly-re-stamped eyes/nostrils/outlines (`repaint_creature_textures.py`'s own comment), so the "armor seam" search was, by construction, frequently finding the face instead (the eye-bleed); and the bilateral symmetry read as "mirrored" because nothing broke it up in 3D space. Fixed in `tools/generate_aspect_variant_textures.py`: every glow layer's selection is now a continuous smoothstep score (not boolean) with a final Gaussian blur pass; a tight (0.15th-percentile) SOURCE-value pupil/nostril exclusion, independent of `finish_pass`'s own broader feature mask, keeps every layer off the eyes; a model-space value-noise clump (the same primitive `tools/creature_overlays.py`'s own moss/leaf overlays already use, reused rather than reinvented) breaks the selection into an organic vein network instead of a flat blob. Per-variant tuning on top: Nightburrow's glow colour moved off-board-palette magenta toward the board's actual violet; Stormtrail's markings (measured "too small to read" in the original render, ~3% of the silhouette) had their coverage/percentile raised twice, checked by rendering each time; Ashtusk's tusk `select: match` layer was narrowed by hue/saturation so it stops matching the model's own grey stone armour plates, which is what was diluting the "ember-glowing tusks" read the board calls out by name. Also fixed in the same pass: `tools/creature_overlays.py`'s and this generator's own clump-noise seed used the Python builtin `hash()` on a string tuple, which is salted per-process (`PYTHONHASHSEED`) and silently broke both files' own documented "idempotent, pure function of its inputs" claim -- confirmed by running the generator twice with no input change and getting different coverage numbers each time. Replaced with `zlib.crc32` on the same key; two consecutive runs now produce byte-identical PNGs (verified via `sha256sum`). New code-side lever, not a texture change: `scripts/creatures/creature_body.gd`'s `ASPECT_EMISSION_BOOST` gives an aspect variant's emission an additional multiplier on top of the shared `creatures_visual.json::emission_scale` — that shared tame was built for the ORDINARY colourways' full-body self-lit-copy trick, and was crushing a sparse crack map's own brightness at the exact scale that made the render-and-check pass call Stormtrail's markings "essentially invisible" at night; and `scripts/creatures/vfx/aspect_vfx.gd` gained a small `_draw_tusks()` billboard pair (Ashtusk only, mouth-anchored the same way the shared eye-glow already is) as a guaranteed-visible fallback for the tusk read, since no per-vertex tusk mask exists without new geometry. Evidence: each variant rendered beside its own base species, wide and close, day and night, `ralph/reports/T1-VARIANTS/shots/`. **Second follow-up, T1-VARIANTS-2 2026-08-30, same generator/spec files re-touched, no new asset, no Meshy spend:** JUDGE-4's blind pass (`ralph/reports/JUDGE-4-2026-08-30.md`) cleared Ashtusk and Nightburrow but found Stormtrail still reading as a base-species recolour (Q2-D2/D4: coat not darkened, marking a one-sided shoulder patch not the sheet's spine bolt) and Riftfrill marginal (Q2-D5/D6: value move not the sheet's frill hue move, filigree markings absent). Same texture files regenerated with pushed tuning in `data/creatures/aspect_variants.json`: Stormtrail's coat rule is now a real darken+desaturate toward the sheet's Storm Fur (was deepening the base tan); its lightning overlay split into a near-solid `spine_bolt` plus a wide `lightning_branches` layer so coverage no longer depends on clump noise landing on both flanks, plus a new `lightning_glow` emissive layer so the gold marking glows at night (`tools/generate_aspect_variant_textures.py` gained an optional `"sample": "albedo"` for `select: match` glow layers, needed because Stormtrail's gold paint does not exist in the pre-recolour source). Riftfrill's `lilac_frill` overlay widened to near-solid coverage over the whole frill region (round 1's `up_min` only caught the crown/tips), plus a new `filigree` emissive layer for the sheet's swirl markings. Also fixed at its root, code not texture (`scripts/creatures/vfx/aspect_vfx.gd`): JUDGE-4 Q2-D3's missing eye glow on all four variants -- the eye/tusk billboards were depth-tested against the real model and their capsule-placeholder anchor sits fractionally inside real GLB head geometry on every species, silently losing the depth test; moved to a depth-test-disabled mesh and re-anchored by rendering each species. Evidence: `ralph/reports/T1-VARIANTS-2/shots/` (16 lineup frames regenerated, plus in-world Meadows frames at encounter range on real grass). |
| Creature expansion generator-input crops ×5 (2026-08-30) | Cropped from the board above by `tools/art_pipeline/crop_views.py`, no new image generation | `tools/art_pipeline/views.json` (`sparkit`, `cindercub`, `shadelet`, `bramblebun_redesign`, `frostclaw` entries) | Same as the source board (owner's own) | No | `assets/creatures/tetherbound/{sparkit,cindercub,shadelet,bramblebun_redesign,frostclaw}/reference/{front,side,back,top}.png` | T1-CREATURE-MESH. Straight crops of the master sheet above, not a new asset — **no Meshy credit spent, nothing generated**; this row exists so the crops have a provenance entry before the coordinator spends credits against them, per this file's own "a row is required before the file is committed" rule. `bramblebun_redesign` is a NEW key, not an edit of the existing `bramblebun` entry — the shipped `assets/creatures/tetherbound/bramblebun/reference/` and its mesh are untouched and stay in place until this replacement candidate is judged better. Four views per creature (front/side/back/top), not the pipeline's usual three-plus-3/4: these boards draw no 3/4 view (their only 3/4-ish art is a crouched hero pose that fights the standing turnaround's neutral pose — evaluated and rejected, see the handover) but do draw a genuine top-down orthographic view, which `meshy.py`'s `VIEWS` list already supported and no creature sheet had carried until now. Each of the five entries needed a `mask` to paint out this sheet's own per-cell divider rules, which read past `erase_dividers()`'s faint-line threshold and would otherwise crop in as a line through the creature's own body — full detail in `ralph/reports/handover-T1-CREATURE-MESH-2026-08-30.md`. **Fidelity flag**: source figures here measure ~70–190px per view, below the 180–450px range the pipeline's own `views.json` documents as its established comfort zone — recorded as a real finding, not silently accepted; see the handover and `ralph/reports/CREATURE_MESH_PLAN_2026-08-30.md`. No mesh has been generated from these crops yet — that is the coordinator's step, tracked in the plan document above. |
| Meadows NPC design board (2026-08-30) | Owner-supplied (AI-generated) | Provided by owner 2026-08-30 | Owner's own | No | `docs/art/reference/npc-board-2026-08-30/00_MEADOWS_NPC_DESIGN_BOARD.png` | **Authority for the 25-NPC Meadows cast** — Team Tether ranks (grunt/officer/captain/Warden), village and settlement roles, trail and wilderness travellers. Carries per-NPC turnarounds, role/rank legend, an art-and-style guide, a named colour palette with hexes, a scale reference (grunt 1.7m, officer 1.8m, captain 1.9m, Warden 2.0m, player 1.75m), turnaround requirements (front/side/back/3-4, A-pose, close-up face) and accessory examples. **The board's own rig guidance matches `docs/art/HUMANOID_ASSET_INVENTORY.md`: use the existing Tetherbound human base rig and vary via head, hair, facial hair, body type, skin tone, clothing, colour and accessories** — so this board is largely a retexture/variant specification, not 25 mesh generations. The Warden panel is reference only; the Warden is already rebuilt and `CLAUDE.md` forbids reopening it. |
| Five expansion-creature meshes — Sparkit, Cindercub, Shadelet, Frostclaw, Bramblebun redesign (2026-08-30) | Meshy (AI mesh generation: multi-image-to-3D against the T1-CREATURE-MESH crops, then retexture), directed against the creature-expansion reference boards above | Meshy API, `tools/art_pipeline/meshy.py`; per-asset provenance at `assets/creatures/tetherbound/<name>/models/provenance.json` (retexture task ids: sparkit `01a04f3a-aa5d-758c-ae88-8e1c5f7caa60`, shadelet `01a04f3a-b0fd-71a6-9342-6bd6cf8c9247`, frostclaw `01a04f3a-b678-723f-9dbe-82f0771337a0`, cindercub `01a04f05-c1dc-704e-8ecf-4774e02a9df8`, bramblebun_redesign `01a04f05-b7e1-7149-9cdd-faa75191d45c`) | Meshy's standard generation terms (this project already generates creature/hero-prop meshes the same way; see the pipeline's other rows) | Yes — 90 credits for the three re-rolled textures (Sparkit/Shadelet/Frostclaw), balance 630 after | `assets/creatures/tetherbound/{sparkit,cindercub,shadelet,frostclaw,bramblebun_redesign}/models/creature_<name>_lod0.glb` + each folder's `provenance.json` and `meshy_thumbnail.png` | Coordinator commit `984572bd`, owner picks off a round-2 contact sheet: Sparkit r2a (the candidate with the lightning-bolt tail), Shadelet r2c, Frostclaw r2b (the lynx with a modelled face); Cindercub and Bramblebun redesign accepted from round 1. **Installed, not yet wired**: `sparkit`/`cindercub`/`shadelet`/`frostclaw` exist only in `data/creatures/species_pending.json`, not the live `data/creatures/species.json` roster, and `bramblebun_redesign` has not replaced the shipped `bramblebun` entry — none of the five has combat stats, moves, a type, or a band spawn placement yet, so none is reachable by a player. `ralph/OWNER_DIRECTIVES_2026-08-30.md` (D-0830-2) directs that this gets finished; recorded here as a known gap rather than actioned by this integration, since assigning stats/type/moves/spawn placement is game-design authorship outside a merge-and-land task's scope. |
| Input Prompts — 4 more files extracted (`xbox_lt.png`, `xbox_rt.png`, `xbox_button_start.png`, `keyboard_l.png`) | Kenney | [Input Prompts](https://kenney.nl/assets/input-prompts) (already staged raw, see the full-pack row below) | CC0 1.0 | No | `assets/ui/input_prompts/` | Owner playtest report fixes. `xbox_lt.png`/`xbox_rt.png`: combat's `quick`/`charged` verbs and build's `build_rotate_left`/`build_rotate_right` were showing the LB/RB SHOULDER icons as stand-ins for their real LT/RT trigger bindings — a documented "on-screen control instruction lies about its binding" defect (`scripts/ui/input_glyph.gd`) — now shown correctly; the real trigger art was already sitting in the raw vendor pack, unextracted. `xbox_button_start.png`/`keyboard_l.png`: prompts for the new starting-torch toggle (`torch_toggle`). Unmodified, straight copies from the already-logged raw pack, same as every other `assets/ui/input_prompts/*.png` file extracted before this row (none of which had their own ledger row until now — a pre-existing gap, not introduced here). |
| Input Prompts — 3 more files extracted (`xbox_stick_r_press.png`, `keyboard_b.png`, `keyboard_p.png`) | Kenney | [Input Prompts](https://kenney.nl/assets/input-prompts) (already staged raw, see the full-pack row below) | CC0 1.0 | No | `assets/ui/input_prompts/` | OF21 (same-context gamepad collision fix). `xbox_stick_r_press.png`: `torch_toggle`'s new dedicated gamepad glyph — `torch_toggle` moved OFF the Start/Menu button (where it collided with `backpack_drop`); a first pass put it on the Guide button, but Guide-class buttons are captured by the system overlay on the ROG Ally and never reach the game, so it landed on R3 (button 8), whose only other reader is menu-context. (`xbox_guide.png` was briefly extracted for that first pass and removed again — never shipped.) `keyboard_b.png`/`keyboard_p.png`: prompts for the two new world-context actions this same pass added, `build_open` (B) and `torch_place` (P). Unmodified, straight copies from the already-logged raw pack, same convention as the row above. |
| Input Prompts — 1 more file extracted (`keyboard_h.png`) | Kenney | [Input Prompts](https://kenney.nl/assets/input-prompts) (already staged raw, see the full-pack row below) | CC0 1.0 | No | `assets/ui/input_prompts/` | PT-17 (renaming a creature from the Team tab). The rename verb borrows `backpack_split` (H / gamepad R3, already vendored `xbox_stick_r_press.png`) rather than adding a new action to `project.godot`'s input map, the same borrowing `tab_creatures.gd` already does for evolve/Best Creature — only the keyboard half needed a fresh extraction. Unmodified, straight copy from the already-logged raw pack, same convention as the two rows above. |
| Input Prompts — 1 more file extracted (`keyboard_c.png`) | Kenney | [Input Prompts](https://kenney.nl/assets/input-prompts) (already staged raw, see the full-pack row below) | CC0 1.0 | No | `assets/ui/input_prompts/` | `GF-B-006` (Gate F: "one glyph language per device"). `party_cycle` had a gamepad glyph and no keyboard one, so `input_glyph.gd::icon()` fell through to its bracket fallback and the persistent exploration legend drew `M` / `I` / `R` as keycap images beside a bare `[C]` — three glyphs and one piece of text on the one HUD row that is up during ordinary exploration. The binding really is C (`project.godot`, physical_keycode 67); the keycap was simply never extracted. Unmodified, straight copy from the already-logged raw pack, same convention as the three rows above. |
| NPC bases concept board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/art/reference/12_NPC_Bases_Reusable.png` | None. Specifies three reusable base bodies; supersedes spec §22's "one or two" per D24. |
| Tether Energy Pylon board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/art/reference/13_Tether_Energy_Pylon.png` | None. Production brief, not mood art: **2K–3K triangle** target, human height +, and a five-part modular build (base + core module + supports ×4 + top frame + tether crystal). One of the three hero objects D24 reserves Meshy for. |
| Tether Energy Pylon — production hero object | Generated (Meshy multi-image-to-3D preview ×3, retexture on the winner) from crops of the owner's board `13_Tether_Energy_Pylon.png`; textures separated and graded in-pipeline | `tools/art_pipeline/`, task ids in `assets_raw/tether_pylon/manifest.json` and `c_tex/provenance.json` | Meshy ToS at generation date (paid credits of owner's account); derived from owner's own concept art. All Rights Reserved / proprietary, owner-licensed | Paid credits (~90) | `assets/environment/team_tether/tether_pylon.glb` + `tether_pylon_albedo.png` / `tether_pylon_albedo_dead.png` | SF33. One of the three hero objects D24 reserves Meshy for, and the first built. 3,041 triangles against the board's 2K–3K target. Candidate C won on the board's signature features (large faceted floating crystal, claw frame, lantern core). GLB is geometry-only (125KB); the 2K Meshy albedo was downscaled to 1024 and split into a live state (as textured) and a dead state (teal drained to cold slate via hue-masked grade) — per-material variants, one mesh. A baked emission-mask texture was built and then REMOVED: gl_compatibility (D01) ignores the mask and floods the whole mesh with the emission colour; the live read is albedo-carried, only the procedural conduit cables use uniform-colour emission. |
| Relay Apparatus board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/art/reference/14_Relay_Apparatus.png` | None. Band 3. Artist note is the build spec: *"modular construction, core and rings serviceable, conductor arms and manifolds replaceable"*. Five labelled subassemblies. Serves `SE23`. |
| Legendary Tether Machine board | Owner-supplied (AI-generated) | Provided by owner | Owner's own | No | `docs/art/reference/15_Legendary_Tether_Machine.png` | None. Warden stronghold, ~15 m against its own 0–20 m scale bar. **Depicts a bound legendary inside the containment ring — the board licenses the MACHINE, not its occupant.** D23 §20 forbids new creature meshes at any credit balance, so the bound creature is an existing roster asset or VFX. |

| Relay Apparatus — production hero object | Generated (Meshy multi-image-to-3D: preview x3 to choose, then refine x2) from FRONT/SIDE/REAR crops of the owner's board `14_Relay_Apparatus.png`, cut by `tools/art_pipeline/crop_prop_views.py` | `tools/art_pipeline/`, task ids in `assets_raw/relay_apparatus/*/provenance.json`; winner `01a00ae3-9cf0-7e34-83b2-1d3504f13236` | Meshy ToS at generation date (paid credits of owner's account); derived from owner's own concept art. All Rights Reserved / proprietary, owner-licensed | Paid credits (100: 3 preview + 2 refine) | `assets/environment/team_tether/relay_apparatus.glb` | SE23. D24's second reserved hero. The board's hero render is NOT among the inputs — its callout numbers and leader lines sit on the object. Installed at the `ApparatusSeam` in `scripts/world/tether_relay.gd` and fitted to `apparatus.height` (4.2m) by the mesh's own visual bounds; the placeholder massing stays as the fallback the code takes when `model` is unset. In-engine renders: `shots/_hero_relay_*.png`. |
| Legendary Tether Machine — production hero object | Generated (Meshy multi-image-to-3D: preview x3 rejected, preview x3 accepted, then refine x2) from four crops of the owner's board `15_Legendary_Tether_Machine.png` — **and the front and side crops had the bound legendary programmatically LIFTED OUT of them first** (`crop_prop_views.py::lift_occupant`) | `tools/art_pipeline/`, task ids in `assets_raw/tether_machine/*/provenance.json`; winner `01a00ae7-0325-7f01-b8db-07097a7929e1` | Meshy ToS at generation date (paid credits of owner's account); derived from owner's own concept art. All Rights Reserved / proprietary, owner-licensed | Paid credits (200: 6 preview + 2 refine) | `assets/environment/team_tether/tether_machine.glb` | R8.2. D24's third and last reserved hero. **THE BOARD LICENSES THE MACHINE, NOT ITS PRISONER** — D24, and D23 §20 forbids a new creature mesh at any balance. The occupant was removed from the INPUT IMAGES rather than only banned in the negative prompt, because image-to-3D follows its pictures. Every candidate was checked by eye and none contains a creature. Installed at `machine.model` in `data/config/stronghold.json`, fitted to `machine.height` (15m) — `smoke_stronghold` measures it at 16.6 x 15.0 x 12.0 m. In-engine renders: `shots/_hero_machine_*.png`. |

> **All three of D24's reserved hero objects are now generated.** The Tether
> Energy Pylon (SF33), the Relay Apparatus (SE23) and the Legendary Tether
> Machine (R8.2). No further Meshy generation is licensed for the Meadows: D23
> §20 forbids creature meshes at any balance, and CLAUDE.md forbids generating
> anything the owner has not supplied a reference board for.
> The Warden was rebuilt separately on 2026-08-16 from the owner's own
> character sheet (board 16) — see the row below. No further Meshy generation
> is licensed for the Meadows.

| Warden Aldis — rebuilt character | Body generated (Meshy multi-image-to-3D preview x3) from board 16's front/back turnaround; HEAD generated separately (preview x3, twice — the first crops included shoulders and produced whole figures) from board 16's four head views; grafted, textured, auto-rigged and animated in-pipeline | `tools/art_pipeline/`, task ids in `assets_raw/warden_body/*/`, `assets_raw/warden_head/*/`, `assets_raw/warden/tex_final/`, `assets_raw/warden/rig_final/` | Meshy ToS at generation date (paid credits of owner's account); derived from owner's own concept art. All Rights Reserved / proprietary, owner-licensed | Paid credits (~320) | `assets/characters/warden/warden_lod0.glb` | R8.3 / D49. **Board 16 supersedes board 06 for this character**: bare bearded face with a painted green eye-marking, not a visored soldier. His face is MODELLED now rather than painted, which was the point. Body candidate `b` won because the `staff` negative took on it. Recipe and the two tool flags it needed (`--skip-voxel`, `--drop 0.45`) are in D49. Renders: `shots/_warden_before_after.png`. |

**Most of the build is CC0 1.0 — but not all of it, and this ledger previously
claimed otherwise.** Corrected 2026-08-12: the Meshy-generated creatures and
characters (Ripplet, Galewisp, Grandpa Elias, and the rest of the roster
generated the same way — see their own rows above) are **not** CC0; they
carry Meshy's ToS at generation date, derived from the owner's own concept
art, and are treated as **All Rights Reserved / proprietary, owner-licensed**
for this project. The **Plumberry Plains Vol. 2** pack (also above) is not
CC0 either — its own row already states its real terms (free for personal and
commercial use, no resale/redistribution/repackaging, no AI training), also
treated as proprietary/owner-licensed rather than open. Everything else in
this table genuinely is CC0 1.0, and for that portion nothing here carries a
legal attribution obligation — though credits should still name Quaternius,
Kay Lousberg, Kenney and ambientCG; it costs a line and it is how these packs
keep existing.

The creature models remain stand-ins for bespoke art (`docs/decisions/D10`), and
the blind critic has said so in two consecutive reviews (`docs/reviews/MA-01`,
`MA-02`). They are in the build because a rigged, animated, correctly-scaled
stand-in proves the systems; they are not the answer to the owner's bar.

## Retired

Kept for audit history. These files are no longer in the repository, but they
were committed at some point and a licence audit should be able to see that.

| Asset | Creator | Source | Licence | Retired because | Was at |
|---|---|---|---|---|---|
| Trainer character (`character-a`) | Kenney | [Blocky Characters](https://kenney.nl/assets/blocky-characters) | CC0 1.0 | Minecraft-proportioned blocky figure in a different art language from the creatures beside it — the critic's lead complaint in `MA-01`. | `assets/characters/trainer.glb` |
| Trainer textures | Kenney | [Blocky Characters](https://kenney.nl/assets/blocky-characters) | CC0 1.0 | Went with the model above. | `assets/characters/Textures/` |
| Meadow Hopper (rabbit) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/dyeBDJxhDwP) | CC-BY 3.0 | Unrigged static scan; could not animate, and CC-BY added an attribution obligation the rest of the roster does not carry. | `assets/creatures/meadow_hopper.glb` |
| Thornback (boar) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/57fSWum6F1P) | CC-BY 3.0 | Unrigged static scan. | `assets/creatures/thornback.glb` |
| Bramblit (fox) | Google (Poly) | [Poly Pizza](https://poly.pizza/m/10u8FYPC5Br) | CC-BY 3.0 | Unrigged static scan. | `assets/creatures/bramblit.glb` |

## Rules

- `docs/` carries a `.gdignore`, so nothing in it is imported by Godot or
  included in an export. The reference images are documentation, not game
  content, and the Windows export preset excludes them explicitly.
- Never assume an asset is redistributable. "Free to download" is not a licence.
- Prefer assets with animations appropriate to their role over assets that look
  better in a still.
- Test scale and materials in-engine before committing to a roster. A pack that
  looks cohesive on a store page can fall apart under one directional light.
- If the game is ever distributed publicly, audit this table and purchase or
  replace anything that needs it.

## TM Orb — `assets/props/tm_orb/` (2026-08-28)

| | |
|---|---|
| Source | Meshy.ai image-to-3D, refine tier |
| Task id | `01a04868-43bf-78c4-ba6b-1cbb3dc6dce8` (refine of preview candidate `01a0483f-3343-706e-b4e3-d13fdc4ca62a`) |
| Reference | `docs/art/reference/tm_orb_board.png`, **owner-supplied 2026-08-28** |
| Licence | Meshy paid generation on the project's own account; generated from the owner's own reference board, no third-party asset ingested |
| Geometry | 30,774 tris, 37,080 verts, one mesh, one primitive, UV0 present |

Selected from three preview candidates. Chosen on the board's own lead
criterion — a clean sphere silhouette — measured rather than eyeballed:
bounding-box sphericity 0.991 against 0.976 and 0.974 for the other two. It was
also the only candidate with a well-formed spiral core AND continuous banding;
candidate A's socket was an empty dome with no spiral at all, and candidate B
drifted into the cracked-panel look the prompt explicitly ruled out.

### The generated material does NOT deliver the board, and that is expected

The board asks for a *"subtle emissive core"* with *"emissive intensity
(dynamic)"* and ten type variants as hue swaps. The generated glTF has **one
material, one base-colour texture, no emissive channel and no
metallic-roughness texture** — `metallicFactor` 0.0, `roughnessFactor` 0.8. The
glow in the render is **painted into albedo**, so out of the box it does not
emit, cannot be driven dynamically, and a naive hue rotation for a type variant
would shift the stone and brass along with the core.

So the generation supplies **form**, and the material is authored here:

- `tm_orb_0.jpg` — the generated albedo. **Not committed separately**: Godot's
  glTF import extracts the texture embedded in `tm_orb.glb` to this path, and it
  is byte-identical to what Meshy returned (sha256 verified), so a hand-copied
  second PNG was 2.9 MB of exact duplicate and was removed.
- `tm_orb_emissive_mask.png` — the core, extracted by hue. The core occupies
  **3.36% of texels** and is the only content in the 160–220° hue band above
  0.25 saturation, so it separates cleanly despite being scattered across the
  atlas. This is the channel the board's dynamic intensity drives.
- `tm_orb_shell.png` — the albedo with the core texels neutralised to greyscale,
  so tinting the core cannot drag the stone with it.

**One mesh, ten materials.** The ten type variants are hue/emissive swaps over
this single body, the same economy `character_model.gd` already uses for
villager palettes. Do not generate nine more orbs.

### Owner authorisation

CLAUDE.md reserves Meshy for Team Tether hero objects. This generation was
**directed by the owner on 2026-08-28 with a supplied reference board**, which
satisfies the actual gate — the same reasoning already recorded in
`tools/art_pipeline/meshy.py` for the BAND1-D1 camp set: the hero-objects line
exists to stop an autonomous firing spending speculatively, not to stop the
owner directing a generation themselves.

Cost: 60 credits for three previews, 40 for the refine of the winner. Preview
first, spend only on the winner, per the pipeline's own rule.

## Meadows NPC cast — 15 humanoids generated (2026-08-30)

| | |
|---|---|
| Source | Meshy.ai multi-image-to-3D, preview then refine tiers |
| Reference | `docs/art/reference/npc-board-2026-08-30/00_MEADOWS_NPC_DESIGN_BOARD.png`, owner-supplied 2026-08-30 (see that board's own ledger row above) |
| Licence | Meshy paid generation on the project's own account; derived from the owner's own reference board. All Rights Reserved / proprietary, owner-licensed, same footing as every other Meshy-generated character in this table |
| Subjects | `grunt_a`, `grunt_b`, `grunt_c`, `officer_a`, `officer_b`, `captain_a`, `captain_b` (Team Tether, board panels 1–7); `innkeeper`, `inn_helper`, `trader`, `craftsperson`, `creature_caretaker`, `farmer`, `local_historian`, `young_trainer` (Village, board panels 9–16) |
| Geometry/texture | `assets_raw/<slug>/refine_a/model.glb` — refine-tier, textured. **Not yet installed** at a production path (`assets/characters/<slug>/`) or wired into `data/config/art.json` — that install/wiring/in-engine scale check is the next step, not done by this batch. `assets_raw/` is gitignored, per this pipeline's standing convention (not committed). |

**Why this exists, and why it reverses this same document's own earlier
reasoning two rows up:** `docs/art/HUMANOID_ASSET_INVENTORY.md` and this
lane's own first-pass classification plan
(`ralph/reports/NPC_CAST_PLAN_2026-08-30.md`) both argued the existing six
rigs' palette/badge variant system was enough for this cast, at zero Meshy
cost. That was checked against a real render
(`tools/_capture_rank_variety.gd`, `shots/rank_variety/`) and found wrong
for the Team Tether rank ladder specifically — eleven named
grunts/officers/captains rendered through the game's real placement code
came back as the same body wearing the same clothes, differing only by a
colour shift and a coin-sized badge, contradicting the board's own
"Captains have distinctive silhouettes" line. The owner's direction,
in-session, was explicit: *"NPCs are going to be the same. just generate
the people on the original art."* One generation per board panel (matching
the board's own 3 grunt / 2 officer / 2 captain body variants, not one
generation per named individual — the many named grunts/officers/captains
already in `data/config/bands/*/trainers.json` are expected to keep
reusing whichever of these bodies they're assigned, the same reuse pattern
already live today for the single undifferentiated grunt body).

**Cost:** 1,440 credits for the preview round (24 subjects × 3 candidates
× 20 — all 24 board panels except the Warden, who was not touched, per
CLAUDE.md), then 450 credits refining one winning candidate for these 15
(15 × 30 — **refine measured at 30 credits here, not the 40 `meshy.py`'s
own `COSTS` table currently states**; worth re-measuring and correcting
that constant, the same kind of correction that table's own comment
records happening once before for preview pricing). Balance before this
batch: 2,880 (after the sibling T1-CREATURE-MESH lane's own spend, tracked
in that lane's own reports). Balance after: 990. **9 of the original 24
board designs remain preview-only, not yet refined** (Trail & Wilderness
group, 8 subjects, plus `traveling_merchant`, deferred separately below) —
a deliberate stop to protect the 900 credits reserved for the creature
lane, not an oversight.

**Two subjects need rework before spending anything further on them,**
found and recorded rather than hidden: `traveling_merchant`'s preview
candidates fused the reference board's cart into her body geometry despite
the prompt saying not to (the reference crop still showed cart at her hip;
image content overrode prompt text, the same lesson the sibling creature
lane already learned) — needs a genuinely person-only reference crop and a
fresh preview roll before refining. `wandering_trainer` preview candidate
A picked up a companion creature the same way; candidates B/C are clean
and don't need a re-roll.

Full account, per-subject verdict, and the exact prompt/crop provenance
for every one of the 24 (not just these 15): `ralph/reports/
NPC_CAST_PLAN_2026-08-30.md`, `ralph/reports/
NPC_CAST_PREVIEW_ROUND1_2026-08-30.md`, and `ralph/reports/
NPC_CAST_REFINE_ROUND1_2026-08-30.md`.

**Round 2, same day, owner instruction "build the rest":** refined the
remaining 8 Trail & Wilderness subjects (`rival_trainer`,
`field_researcher`, `wandering_trainer`, `lost_traveler`,
`campfire_traveler`, `alpha_tracker`, `courier`, `former_tether_member`,
one candidate each, 240 credits) and resolved `traveling_merchant`.

`traveling_merchant` needed two more attempts before it worked. A tighter,
cart-excluded reference crop (40 credits, 2 image-to-3D preview
candidates) still produced the cart fused to her body as a
wheelchair-like frame — the residual satchel corner and the single-pose
reference (the board draws her only once; there is no true second angle
to disambiguate the reconstruction) were still enough to mislead it. Root
cause was the reference IMAGE, not the crop tightness or the prompt, so
switched approach entirely: `meshy.py text` (text-to-3D, no reference
image at all, 40 credits for 2 candidates) produced a clean standing
figure with no fused geometry, then `meshy.py texture` against the
board's own three-quarter crop (10 credits — **also below the documented
30**, a single measurement, not yet re-verified across multiple runs the
way the refine correction was) delivered a textured result matching the
board's warm-earth palette. Total spend on this one subject across every
attempt: 150 credits (60 original 3-candidate preview + 40 failed re-roll
+ 40 text-to-3D + 10 retexture) — the one subject in this whole cast
where the honest cost was well above the ~90/subject baseline, recorded
here rather than smoothed into the total.

`wandering_trainer`'s companion creature was fixed the same way as
`traveling_merchant`'s cart (crop excluded it entirely) and refined
directly without a preview re-roll, since the other reference view was
already known clean.

**All 24 board designs (every NPC except the Warden) now have a refined,
textured result.** Balance after this round: 660 — below the 900
originally reserved for the sibling T1-CREATURE-MESH lane by 240 credits,
disclosed here rather than smoothed over; this happened under a direct
owner instruction to finish the remaining groups ("do team tether then
villagers... use as little budget as you can", followed by "build the
rest"), not a unilateral lane decision. Total spend across both
generation rounds: 1,440 (preview, all 24) + 450 (refine, Team Tether +
Village, 15) + 330 (refine, Trail & Wilderness, 8, plus the full
traveling_merchant rework: re-crop attempt, text-to-3D, retexture) =
**2,220 of the 2,880 balance available when this lane started
generating.**

Full account of this round: `ralph/reports/
NPC_CAST_BUILD_REST_2026-08-30.md`.

**Round 3, same day, owner instruction "put them in the game":** rigged
(Meshy auto-rigger, `meshy.py rig`, measured at **5 credits per call** —
not previously in `COSTS`) and animated (`animate_humanoid.py`, the local
Blender bake every other installed human here uses — the same recipe
`docs/decisions/D49-the-machine-is-generated-without-its-prisoner.md`
records for the Warden, not Meshy's own untested `animate` endpoint) 22
of the 24 generated subjects, installed each at
`assets/characters/<slug>/<slug>_lod0.glb`, and added a matching
`data/config/art.json` entry for each — `model`, `height` (matching the
rig call's own `--height`), `model_yaw`, the standard five-clip map,
shared `gait_reference_speeds`. Verified through the real
`CHARACTER_MODEL.config_for()` lookup path against a spread sample
(Team Tether, Village, Trail, both height extremes), idle/walk/sprint,
no tearing or split geometry despite `inspect_glb.py` flagging real
topology roughness on the raw mesh — checked by rendering one subject
end-to-end before scaling to the rest, not assumed from the geometry
report alone.

**Two subjects could not be rigged**: `campfire_traveler` (holding a
crossbow prop fused to both hands) and `traveling_merchant` (arms
crossed over her body) both failed Meshy's rigger with `422 Pose
estimation failed`, retried once each, failed identically — a
non-standard baked-in arm pose, not a transient error. Left textured but
un-rigged, un-animated, not installed; fixing it needs a fresh
generation with a resting-pose reference, not a rig retry, and wasn't
spent on further given both are lower-priority flavour NPCs.

## T3-INSTALL follow-up (2026-08-30) — wiring the meshes above into the live game

No new Meshy spend in this entry; both rows above already paid for
everything used here.

**The five expansion-creature meshes are now live.** `sparkit`, `cindercub`,
`shadelet`, `frostclaw` moved from `data/creatures/species_pending.json` into
`data/creatures/species.json` with `placeholder.model` pointing at their
committed `.glb`; `bramblebun`'s own `placeholder.model` was repointed from
the old mesh to `bramblebun_redesign`'s (same species id — the redesign
replaces the asset, per the brief, not a new species). Spawn placements moved
from `spawn_tables.json`'s `_pending` block into the live `tables`. **Real
caveat, not previously recorded**: all five `.glb`s are single-mesh, no-skin
exports (`skins: 0` in the raw glTF) with an empty `animations` array —
unlike every other production creature/humanoid rig in this project, none of
which this ledger's rows above claim otherwise, but worth stating plainly
since it changes what "installed" delivers. `creature_body.gd::_build_animator()`
warns and no-ops rather than failing, so each creature stands in the world at
its correct scale and material but does not play idle/walk/attack/hit/faint
clips. A rig pass (Meshy `rig` + `animate_humanoid.py`'s local Blender bake,
the same recipe the 22 NPC bodies above went through) is real follow-up work,
not a data problem.

**22 of the 24 NPC-cast bodies above are now used somewhere in the live
game**, still at zero further Meshy spend. `grunt_a`/`grunt_b`/`grunt_c`,
`officer_a`/`officer_b`, `captain_a`/`captain_b` are assigned via a new
per-trainer `base` override (`npc_ranks.gd::config_for()`) to the 17 named
grunt/officer/captain trainers across all five bands' `trainers.json`,
rotated so no two trainers in the same band share a body — the fix this
ledger's own "Captains have distinctive silhouettes" finding asked for,
minus the coat/cape accessory idea it also floated (superseded once full
bodies existed). The remaining 15 civilian/trail bodies
(`innkeeper`/`inn_helper`/`trader`/`craftsperson`/`creature_caretaker`/
`farmer`/`local_historian`/`young_trainer`/`rival_trainer`/
`field_researcher`/`wandering_trainer`/`lost_traveler`/`alpha_tracker`/
`courier`/`former_tether_member`) still have a valid `art.json` `config_key`
and a real rigged, animated `.glb`, but **no placement anywhere in the
world** (no `village_npcs.json`/`trainers.json`/`village.json` entry) —
see the T3-INSTALL handover for which of these got placed this pass and
which remain dark, and why. `campfire_traveler` and `traveling_merchant`
remain exactly as recorded above: textured, un-rigged, not installed —
still blocked on a fresh Meshy generation against a resting-pose reference,
which this lane has no more ability to spend than the one that found it.

Full account: `ralph/reports/NPC_CAST_INSTALL_2026-08-30.md`.

## T1-RIG-2 (2026-08-30) — the five expansion creatures are rigged and animated

> **Coordinator note, 2026-08-30.** The two entries that follow record the
> SAME five creature rigs, done twice by two lanes on the same day. That is a
> coordination failure, not a disagreement: T1-CREATURE-RIG rigged them and
> landed on `main`; the coordinator then briefed T1-RIG-2 that the creatures
> were 'unanimated statues', which was already false, and it rigged them again.
> Both used the same local Blender pipeline (`rig_quadruped.py` +
> `animate_quadruped.py`), both produced a 15-bone rig and the same six clips,
> and NEITHER spent a Meshy credit. The shipping `.glb` files are
> T1-CREATURE-RIG's, kept because they were already landed, CI-verified and
> released. T1-RIG-2's entry is kept because its in-world motion evidence
> (`ralph/reports/T1-RIG-2/shots/` and its motion.json) is stronger than a
> posed frame, and because a ledger that hides duplicated work teaches nobody.

**What changed.** `sparkit`, `cindercub`, `shadelet`, `frostclaw` and
`bramblebun_redesign` shipped as static single-mesh exports — `skins: 0`, empty
`animations` array — which the T3-INSTALL follow-up entry above records
plainly. All five now carry a 15-bone quadruped skeleton and the six clips
(`idle`, `walk`, `run`, `attack`, `hit`, `faint`) every other production
creature ships. Same files, same paths, same textures; only the rig and the
clips are new.

**How, and why it cost nothing.** `tools/art_pipeline/finish.py rig <species>
--kind quadruped`, which is a LOCAL Blender pipeline — `rig_quadruped.py`
places the skeleton from the mesh's own geometry and skins it with automatic
weights, `animate_quadruped.py` authors the clips. Meshy's auto-rigger is
documented humanoid-only (`meshy.py::cmd_rig`'s own docstring) and would not
have taken a quadruped anyway; more to the point, `CLAUDE.md` forbids a Meshy
generation for a Meadows creature outright, and this needed none. Every
production creature already in the roster went through this same path.

**A latent skinning defect closed — honestly, a latent one, not a visible one.**
Automatic weights left 35 vertices on cindercub and 20 on frostclaw with no bone
influence at all. Those do not simply stay put: Blender's glTF exporter invents
a static `neutral_bone` at the armature origin and binds them to it, so the
patch hangs in bind pose while the body moves, which is the tear
`rig_quadruped.py`'s own `weight_report` docstring says to reject before
animating. `repair_unweighted()` now gives each orphan vertex the weights of its
nearest weighted neighbour. All five report `0 unweighted` and a 15-bone skin
with no `neutral_bone`.

**What it did not do, measured rather than assumed.** Both cindercub rigs — with
and without the repair — were rendered through `pose_test.py`'s four extreme
poses and differenced pixel by pixel: seven of the eight views are identical,
the eighth differs by ten pixels. So the orphan patch was **not** producing a
visible artefact at these poses, and any claim that it was would be wrong. The
repair is worth keeping because it removes a latent failure at no cost and lets
the rigger's own zero-unweighted contract actually hold; it is not the fix for a
bug a player was seeing. Before/after frames are both kept under
`ralph/reports/T1-RIG-2/pose_test/` so the comparison is re-checkable.

The pass touches nothing that already carries weight: the three meshes that came
back clean from automatic weights export **byte-identically** with it in place,
confirmed by checksum.

**`bramblebun` now uses the redesign mesh.** `placeholder.model` points at
`bramblebun_redesign/`, which is what the creature-expansion brief asked for
and what T3-INSTALL tried and reverted on 2026-08-30 — for one reason, that the
redesign was unrigged and the game's most-seen creature would have become a
frozen mesh. That reason no longer holds. The old `bramblebun` mesh stays on
disk, untouched.

**Evidence is in the shipping world, not a preview stage.**
`ralph/reports/T1-RIG-2/shots/` — the real Meadows (`meadows_playground.tscn`,
real terrain, real grass, real light), five wild creatures spawned through
`encounter_director.spawn_wild()`, every shutter gated on
`tools/capture_check.gd` so a frame that silently lost the grass field aborts
the run instead of being filed as evidence. `motion.json` beside the frames
carries each creature's clip and a per-shot skeleton pose signature, so "it
animates" is checkable as a number and not only as two similar-looking PNGs.

**Still not done:** `campfire_traveler` and `traveling_merchant`. See the
T1-RIG-2 handover — the inherited one-line diagnosis for these two is wrong in
a way that changes what to do about them, and both now need an owner decision
before any credit is spent.
## T1-CREATURE-RIG (2026-08-30) — the five creature rigs closed locally, the 15 civilian/trail bodies placed

No new Meshy spend in this entry either.

**All 15 civilian/trail bodies above are now placed in the live game.** 12
non-battle roles (`innkeeper`, `inn_helper`, `trader`, `craftsperson`,
`creature_caretaker`, `farmer`, `local_historian`, `lost_traveler`,
`field_researcher`, `alpha_tracker`, `courier`, `former_tether_member`) are
new entries in `data/config/village_npcs.json` with their own greeting
conversations in `data/dialogue/village.json`; the 3 Battle roles
(`young_trainer`, `rival_trainer`, `wandering_trainer`) are standalone
`trainer_npc.gd` placements (the same shape as Bryn/old_champion_bram) in
`data/config/bands/band1_lower_meadows/trainers.json` with authored teams
(species already resident in Band 1, levels inside the band's own [2,7]
trainer_levels range per `chapter_curve.json`) and challenge/defeated
dialogue in `data/dialogue/bands/band1_lower_meadows.json`. Every position
was checked with a new tool, `tools/_probe_civilian_placement.gd` — the
real analytic terrain (`playground_heightfield.gd`, no bake needed) plus
real building footprints (`building_prefabs.json`'s own module-extent
formula, the same one `village.gd::_ground_clear_radius` uses at runtime)
plus distance to every already-authored person — not eyeballed, the same
standard `village_npcs.json`'s own `_comment_positions` set. Two of the
twelve (Maren the field researcher, Sorrel the alpha tracker) fill the
previously-empty `ranger_station`/mill-crossing buildings near the pond
route rather than crowding the village square further. Evidence:
`ralph/reports/T1-CREATURE-RIG/shots/` — real playground-world renders (the
actual terrain and structures, not a neutral-backdrop lineup), through
`tools/_capture_t1_creature_rig_npcs.gd`.

**The five expansion-creature meshes' no-rig defect (Sparkit, Cindercub,
Shadelet, Frostclaw, Bramblebun redesign) IS closed this pass, and by a
different recipe than the brief itself guessed at.** `MESHY_API_KEY` was
confirmed unset in this container early in this session (`python3
tools/art_pipeline/meshy.py check` reported "MESHY_API_KEY is not set"),
the same wall T3-INSTALL's own handover recorded hitting on this exact
task. But `meshy.py`'s own `cmd_rig` docstring says plainly "Meshy
documents this as HUMANOID-only" — the cloud auto-rigger was never the
right tool for five quadrupeds — and `tools/art_pipeline/finish.py` (its
own header: `finish.py rig bramblebun --kind quadruped`) already runs a
LOCAL, offline recipe for exactly this case: `rig_quadruped.py` places a
15-bone skeleton from the mesh's own geometry (leg clustering, spine along
the long axis, no hand-placed bones) and skins it with Blender's automatic
weights; `animate_quadruped.py` then authors the same six clips
(idle/walk/run/attack/hit/faint) every other production creature ships,
locally. Zero Meshy credits — this is the actual recipe every existing
creature in the roster (Bramblebun's own original mesh included) already
went through. The owner supplied a working `MESHY_API_KEY` mid-session
(515 credits, verified) after this was already found, but it was not
needed for the rig/animate steps themselves — only `finish.py texture`
(not run here; every one of these five meshes already had its texture)
touches Meshy.

Run for all five: `mkdir -p assets_raw/<species>/build && cp
assets/creatures/tetherbound/<species>/models/creature_<species>_lod0.glb
assets_raw/<species>/build/textured.glb && python3
tools/art_pipeline/finish.py rig <species> --kind quadruped && python3
tools/art_pipeline/finish.py install <species>`. Sparkit, Shadelet and
Bramblebun redesign rigged with 0 unweighted vertices; Cindercub (35/27342)
and Frostclaw (20/26840) triggered `rig_quadruped.py`'s own
"UNWEIGHTED VERTICES PRESENT — these will tear" warning, so neither was
installed on the strength of that count alone — a new tool,
`tools/art_pipeline/blender/pose_check.py`, renders a model at a named
action/frame instead of its rest pose specifically to answer that question
with a frame rather than a number, and both rendered clean at the attack
clip's most extreme pose (frame 10, full rear-up/paws-down extension) with
no visible tearing before being installed. Evidence, all five, posed:
`ralph/reports/T1-CREATURE-RIG/shots/pose_check/`.

**The Bramblebun redesign now ships.** `data/creatures/species.json`'s
`bramblebun.placeholder.model` now points at
`bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb` — the
only reason it was reverted (a static, unrigged mesh regressing the game's
most-seen creature) no longer applies, and the rendered posed frame shows
a clean rig with the redesign's own larger, antlered silhouette per the
owner's size guide.

Also fixed along the way: the newly-installed `.glb` files did not reach
Godot until `godot --headless --path . --import` was re-run — overwriting
a `.glb` on disk leaves its stale `.godot/imported/` cache alone, exactly
the trap `ralph/conventions.md`'s art-pipeline section already documents.
The first `smoke_art.gd` run after installing still reported "bramblebun
has no AnimationPlayer" against the OLD cached import; re-importing fixed
that specific defect (confirmed: the re-run's world-build log is clean
and the "no AnimationPlayer" warning is gone). `smoke_art.gd` itself could
not be run to completion in this container even after that fix — see the
handover's own Tests section for the full account and the substitute
verification (`tools/preview_creatures.gd`, real creature staging with no
full-world boot, all 25 species including the five rigged this pass).
Recorded here since the import-cache trap will bite the next person who
overwrites a creature `.glb` mid-session too.

Full account: `ralph/reports/handover-T1-CREATURE-RIG-2026-08-30.md`.

## T1-RIG-2 (2026-08-30) — the five expansion creatures are rigged and animated

**No Meshy spend. Balance 515 credits before this lane and 515 after**, checked
against the live endpoint at the start of the session (`meshy.py check`, the
only Meshy API call this lane made — one `GET` on the balance endpoint, which
costs nothing). Nothing here generated, refined, retextured or rigged anything
through Meshy.

**What changed.** `sparkit`, `cindercub`, `shadelet`, `frostclaw` and
`bramblebun_redesign` shipped as static single-mesh exports — `skins: 0`, empty
`animations` array — which the T3-INSTALL follow-up entry above records
plainly. All five now carry a 15-bone quadruped skeleton and the six clips
(`idle`, `walk`, `run`, `attack`, `hit`, `faint`) every other production
creature ships. Same files, same paths, same textures; only the rig and the
clips are new.

**How, and why it cost nothing.** `tools/art_pipeline/finish.py rig <species>
--kind quadruped`, which is a LOCAL Blender pipeline — `rig_quadruped.py`
places the skeleton from the mesh's own geometry and skins it with automatic
weights, `animate_quadruped.py` authors the clips. Meshy's auto-rigger is
documented humanoid-only (`meshy.py::cmd_rig`'s own docstring) and would not
have taken a quadruped anyway; more to the point, `CLAUDE.md` forbids a Meshy
generation for a Meadows creature outright, and this needed none. Every
production creature already in the roster went through this same path.

**A latent skinning defect closed — honestly, a latent one, not a visible one.**
Automatic weights left 35 vertices on cindercub and 20 on frostclaw with no bone
influence at all. Those do not simply stay put: Blender's glTF exporter invents
a static `neutral_bone` at the armature origin and binds them to it, so the
patch hangs in bind pose while the body moves, which is the tear
`rig_quadruped.py`'s own `weight_report` docstring says to reject before
animating. `repair_unweighted()` now gives each orphan vertex the weights of its
nearest weighted neighbour. All five report `0 unweighted` and a 15-bone skin
with no `neutral_bone`.

**What it did not do, measured rather than assumed.** Both cindercub rigs — with
and without the repair — were rendered through `pose_test.py`'s four extreme
poses and differenced pixel by pixel: seven of the eight views are identical,
the eighth differs by ten pixels. So the orphan patch was **not** producing a
visible artefact at these poses, and any claim that it was would be wrong. The
repair is worth keeping because it removes a latent failure at no cost and lets
the rigger's own zero-unweighted contract actually hold; it is not the fix for a
bug a player was seeing. Before/after frames are both kept under
`ralph/reports/T1-RIG-2/pose_test/` so the comparison is re-checkable.

The pass touches nothing that already carries weight: the three meshes that came
back clean from automatic weights export **byte-identically** with it in place,
confirmed by checksum.

**`bramblebun` now uses the redesign mesh.** `placeholder.model` points at
`bramblebun_redesign/`, which is what the creature-expansion brief asked for
and what T3-INSTALL tried and reverted on 2026-08-30 — for one reason, that the
redesign was unrigged and the game's most-seen creature would have become a
frozen mesh. That reason no longer holds. The old `bramblebun` mesh stays on
disk, untouched.

**Evidence is in the shipping world, not a preview stage.**
`ralph/reports/T1-RIG-2/shots/` — the real Meadows (`meadows_playground.tscn`,
real terrain, real grass, real light), five wild creatures spawned through
`encounter_director.spawn_wild()`, every shutter gated on
`tools/capture_check.gd` so a frame that silently lost the grass field aborts
the run instead of being filed as evidence. `motion.json` beside the frames
carries each creature's clip and a per-shot skeleton pose signature, so "it
animates" is checkable as a number and not only as two similar-looking PNGs.

**Still not done:** `campfire_traveler` and `traveling_merchant`. See the
T1-RIG-2 handover — the inherited one-line diagnosis for these two is wrong in
a way that changes what to do about them, and both now need an owner decision
before any credit is spent.

## T1-HALL-ART (2026-08-30) — the Hall's ruin layer and the five Team Tether props

Two asset groups entered the Hall in this lane. **Nothing was purchased, nothing
was downloaded, and no Meshy credit was spent.** The owner's budget for the lane
was "target $0, hard cap $10"; actual spend was **$0.00**.

| Asset | Creator | Source | Licence | Paid | Local path | Modifications |
|---|---|---|---|---|---|---|
| The five bespoke Team Tether Hall props, as nine GLBs — `team_tether_scaffold_tower`, `team_tether_boiler_chimney`, `rift_siphon_wall_machine`, `team_tether_banner_rig`, and the pipe kit `tt_pipe_straight` / `tt_pipe_elbow` / `tt_pipe_tee` / `tt_pipe_valve` / `tt_pipe_bracket` | Original, authored procedurally from primitives by `tools/art_pipeline/blender/build_hall_props.py` in this repo | **Not sourced and not generated.** No pack, no download, no generation service. Every vertex is computed by committed code in this repo, against the owner's own boards at `docs/art/reference/hall-asset-pack-2026-08-30/art_boards/`. | Original work; not applicable. **No third-party licence attaches to any file in `assets/environment/team_tether/hall/`.** | No — **$0, and no Meshy credit** | `assets/environment/team_tether/hall/` | **The owner's pack asks for these five to be generated in Meshy ("BUILD PATH = NEW MESHY PROP" on all five boards). They were not, and the reason is environmental, not a judgement call: `MESHY_API_KEY` is unset in this build container, and `tools/art_pipeline/meshy.py` reads the key "from the environment and from nowhere else". No key was hunted for and no purchase was attempted.** Authoring them instead is recorded in the script's header along with the honest list of what that trades away — surface micro-detail (rivet heads, oxidation mottling, the boards' painterly texture) is genuinely lost, and boards 02 and 04 are the two worth a Meshy budget if one is ever authorised. Every dimension is read off a board's own human-scale bar (4.5m scaffold, 3.5m boiler, 2.5m pipe envelope, 3.0m siphon, 2.8m banner), not guessed. Seven materials are shared across all nine props, and `join_by_material()` collapses each prop to one mesh per material — a budget requirement, not a cosmetic one: as separate objects the placement set cost ~1087 draw calls against 635 of headroom, and joined it costs 220. Colours are the boards' own swatch strips; the oxblood is `stronghold.gd`'s existing `BANNER_COLOUR` (#6b2a20) rather than a third red, and `palette.json`'s reserved `tether_oxblood`/`tether_teal` are not re-picked. 9,558 triangles across all nine. |
| Quaternius Medieval Village MegaKit — the four modules this lane newly ships into the Hall (`Prop_Vine1`, `Prop_Vine2`, `Prop_Brick1`, `Prop_Brick2`, plus the shared `T_VineLeaf_png.png`) | Quaternius | [quaternius.com](https://quaternius.com/) — **already vendored in this repository** before this lane; not re-fetched | CC0 — verified 2026-08-30 by fetching quaternius.com directly, whose own page metadata reads "A library of hundreds of free Low Poly 3D Models, using the CC0 License". Recorded as found today, not as remembered. The kit ships no `License.txt` of its own inside `assets/buildings/quaternius_medieval/`, so the site is the only available statement — noted here rather than glossed. | No | `assets/buildings/quaternius_medieval/` | **No modification to any file.** These are instanced through `MultiMeshInstance3D` by `stronghold.gd::_build_ruin_reclaim()` — 312 ivy and 262 rubble instances across 20 batches, which is 20 draw calls, not 574. The owner's pack names this exact kit as its first free source for "ivy, moss, vines, and overgrowth" and "broken wall tops, rubble"; it turned out the project had already shipped the kit since the village work, so the pack's whole free-asset layer was satisfied with **no download at all**. Per-band albedo tint is applied through a duplicated material so tinting the Hall's ivy cannot repaint the village's. |

**Provenance gap this lane found and did not create.** Before this row, nothing
under `assets/buildings/` had a ledger row at all — neither
`quaternius_medieval/` nor `quaternius_castle/`, the latter being the kit the
Hall's entire massing is built from. This row covers only the four modules
T1-HALL-ART newly ships. **The rest of both kits is still unrecorded**, and a
licence audit before any public release will still have to close that; it is
named here so the gap is a known item rather than an archaeology project.
