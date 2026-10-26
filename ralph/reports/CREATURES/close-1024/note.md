# Creatures close-1024 (lane tb/creatures)

## TO COORDINATOR (26 Oct, Ripplet)

- **Tail spacing was the stage, not the creature. Fixed in the harness:** f68cc2a6 on tb/creatures-land.
  - The ruler was placed 1.4 m from the bind-pose box. Ripplet's idle, hit and faint clips swing the tail curl past that box, onto the ruler.
  - `capture_f36_poses.gd` now keeps the ruler 1.4 m clear of each frame's posed body. The CPU re-capture shows clear space in all four tiles. Added to TECHNICAL §8.1.
  - Any GPU stage run from this commit gets it; earlier scores for long-tailed species carry the artefact.
- **Fur detail: no candidate built.** The nat1024b albedo already has painted strand fur, plus a normal map. I see no single texture change expected to gain more than 0.5, so per the 25 Oct rule I'm not making one.
  - Please re-judge Ripplet on GPU at f68cc2a6's stage (no asset change). If it is still under 7.5 and judges name fur, send me the exact read.
- **Next:** riders (water forms, Sirenseal, water_cannonback's perch).

## TO COORDINATOR (26 Oct, Stormtrail b45)

- **Stormtrail value separation: tie, reverted.** CPU b45 (confirming, r 0.90, RMSE 0.43): main 6.32 vs candidate 6.22 mapped. Body-merges-with-stage PARTIAL on both sides. Candidate fac6e385, reverted e5495230; verdict at `ralph/reports/CREATURES/close-1024/b45/VERDICT.md` (tb/creatures-land d5b4fcef).
- **QUESTION: Stormtrail's blue vein glow.** All three judges, on both sides, read it as stamped "glowing seams on fur". The owner ruled that out on 25 Oct. Options: (a) remove the vein glow from the coat; (b) replace it with arcs off the body, as Tanglevolt's. I'd do (b) through `arc_emission.py` unless you say (a). No Stormtrail push until you answer.
- **Bug on main, not chased:** the `storm_line_glow` layer in `aspect_variants.json` selects no texels for Stormtrail (no-op). Changing colour and clump coverage did not make it select anything.
- **Next:** Ripplet (fur detail; tail spacing on the stage), CPU-checked.

## TO COORDINATOR (26 Oct, after CO34)

- **GPU READY (CLOSE-OUT, on main): CO5-ON e78759f17bbc8e0d7959b5ecbbcfbcae2b5d8ada** (tb/co5-on = origin/main ac5e1426 + only the Tanglevolt arcs; no rim/settle, no other lane work).
  - Arcs v2: crisp edge (soften 0.4), **dilated 1 px** (coverage 0.68% -> 2.08%), core halfway to #EEE4FF, **emission 5.0** (was 3.0).
  - The GLB reproduces byte-for-byte from main's GLB with the tool; f36 pin updated. Import + texture policy PASS (981); f36_pose, texture_import, colourways, creature_body: 5 tests, 0 failed.
  - The arcs now show even on the CPU stage at the roster crop.
  - Judge main vs co5-on at the standard roster crop.
- **Tanglevolt faint-mid float: not a pose gap.** A probe measured the lowest skinned vertex through the faint at every 1/16 phase: never more than 1 cm off the floor.
  - A crouch-topple candidate (+90 roll, crouch 30, fold 25) kept the body standing with the head up at faint mid on CPU, where the current faint is already a low slink. Dropped, not shipped.
  - The GPU "hangs above its shadow" is likely the directional shadow falling away from a rolled body, or the contact-shadow blob staying under the origin. If you want it chased, it is a shadow or presentation item, not a recipe one.
- **Galecrest fly_grip:** fixed in the harness (e9a6681f, see above). Plain captures no longer exit 1. Galecrest flies on its procedural wingbeat by design.
- **Shared rim parked** per your call; tb/co3-on stays unlanded.
- **Next:** Stormtrail (value separation, brighter streaks), then Ripplet (fur detail; tail spacing on the stage), as per-species texture work, CPU-checked, then bundled on main.
- tb/creatures-land head 1812f5d7eb19554465326df87ba3800b8a0db3b2.

## TO COORDINATOR (26 Oct, missing-clip check)

- **Galecrest fly_grip: not a game bug.** Galecrest is a Fly carrier (fly_traversal.json `can_carry`) but is not an f36 recipe species, so it has no fly_grip clip by design.
  - In play, `fly_controller.gd` installs a grip clip only when a recipe provides one. Otherwise, for a `procedural_wing_pose` carrier (Galecrest, Galewisp) it stops the player and flaps the wings procedurally on the flight clock. So flight shows the authored-style wingbeat, not a static pose.
- **water_cannonback swim/ride: the game falls back, also not a crash.** Its water form has no swim or ride clip; the f36 water recipe lost in b13 (5.51 vs 6.03), so it is OFF. In play, `creature_animator.gd` plays locomotion while the traversal role is set: walk while swimming, idle under a rider.
  - On the stage the walk under the water line reads as paddling, which is acceptable.
  - Under a rider, the rider perches on top of the shell's cannons. That is one of your "riders that don't read" items and is next.
- **Fix (harness, e9a6681f on tb/creatures-land):** `capture_f36_poses.gd` now shows what the game plays for a traversal row with no clip and records it in the receipt (`runtime_fallback` with the clip, or `runtime_procedural_wingbeat`) instead of failing. Re-run water_cannonback,galecrest: no errors. Added to TECHNICAL §8.1.
- **Next:** riders (water forms, Sirenseal, water_cannonback's perch), then trainer-height scale (Thundertunnel, Brooktail).

## TO COORDINATOR (26 Oct, isolated arms on main)

- **CO3-ON 33ba3f2a2bc8a22bd625cd8b4f4839796a4c0c27** (tb/co3-on = origin/main ac5e1426 + only da816e00's change: shared rim + faint settle).
  - The creature_body.gd conflicts were the lane-only `_clear_hit_flash()` calls next to `clear_faint_settle()`. Resolved without any hit-flash or wince code.
  - Checks (after `--import`): creature_body, companion_presence, f36_pose, faint, rest_pose, flinch, field/rim/alpha/tier, remote/wild creature: 224 tests, 0 failed.
  - **smoke_art:** fails the same four checks as plain main ac5e1426 (run on both). None is new:
    - shiny (Terrapup);
    - shiny repaint (Paddlenewt nat1024);
    - alpha swap (Burrowback nat1024);
    - rarity tier. The tier check fails differently: on main it trips on Terrapup's own 0.25 rim; on co3-on the tier rims never reach the nat1022 remake's material (all three tiers read 0.25).
  - The tier ladder order holds in code (common 0.15 < uncommon 0.29 < rare 0.41 < alpha 0.65 for a species without its own rim). Reaching the remakes is a pre-existing colourway-path gap, not part of this change. For the PR body: smoke_art's tier and alpha checks now take the rim an untiered body already wears as the baseline instead of zero; the invariant is the same.
- **CO4-ON 4c35d5d7eba4d9e4e32913a877f8eb53c6362297** (tb/co4-on = co3-on + only c6941e68's change: Tanglevolt arcs).
  - Only Tanglevolt's arc_emission.json entry is on main, so the conflict kept that entry alone.
  - The GLB reproduces byte-for-byte from main's GLB with the tool. Texture policy PASS (981); f36_pose and texture tests pass.
- tb/creatures-land is unchanged (cc8d7599).

## TO COORDINATOR (26 Oct, per-species faints judged)

- **No faint candidate gains; nothing to bundle; reverted (cc8d7599).** CPU b44 (`close-1024/b44/VERDICT.md`; not confirming, r 0.79):

  | species | base | candidate | change | judges |
  |---|---|---|---|---|
  | Torrentoad | 6.20 | 6.28 | +0.08 | the side topple's wide splayed body ends limbs-up, read as a belly-up flip; the prone base reads as a crouch |
  | Tanglevolt | 7.84 | 7.58 | -0.26 | its faint already reads as down on CPU; the GPU "pale slab" is a lighting read |
  | Brooktail | 6.89 | 6.97 | +0.08 | tie |

  - Riverdrake's prone was dropped before judging: head up, a low crouch.
  - Burrowback and Mosshell faints are authored clips in their remakes, each already redesigned after a GPU round. Re-authoring needs a Blender re-export of the shipped GLB with no clear better pose, so I did not attempt them.
- What is left for faints is hand-shaping, not a style switch. For Torrentoad: chest down, legs splayed flat, chin on the ground. Expected gain is uncertain, so I'm moving to your next items unless you want that one.
- The CLOSE-OUT rim (da816e00) and arcs (c6941e68) are unchanged and still queued on GPU.
- **Next, per your list:** trainer-height scale (Thundertunnel, then Brooktail if it measures at or under the trainer; grow only), then water-form and Sirenseal riders.
- tb/creatures-land head cc8d75990f0d02a6dca5e65f229cff3f47aecb68 (data = fa5addda; adds `capture_f36_poses.gd --roles=`).

## TO COORDINATOR (26 Oct, CLOSE-OUT)

- **GPU READY (CLOSE-OUT) tb/creatures-land da816e0004132a75ca874f92a293e6b617f1ffaf: one shared rim + one faint settle rule.**
  - **Rim:** `creatures_visual.json` field_rim_default 0.15. Every species without its own `placeholder.field_rim` now wears it: Ripplet, Stormtrail, Paddlenewt, Cindercub, Mudsnout, Trailpup and Duskhush; Tanglevolt drops its explicit 0.
    - Rarity tiers add on top (cap 0.45), so common < uncommon < rare < alpha 0.65 still holds.
    - `smoke_art`'s alpha and tier checks now take the shared rim as the baseline instead of zero. Same invariant, new baseline per your direction; the test is not weakened.
  - **Faint settle:** after a combat faint clip ends, a posed whole body floating above the floor is lowered onto it. It moves the visual node only and is undone on revive, the next faint or a model swap. Bed rest is untouched.
  - **Judge on GPU against main.** Species: Ripplet, Stormtrail, Paddlenewt, Cindercub, Mudsnout, Trailpup, Duskhush, Tanglevolt, plus a few already-passing controls (Galecrest, Stormursa) to catch over-rim.
  - **No CPU batch:** llvmpipe draws no rim and the settle fires on none of the captured species; pixel diffs ≤ 0.30 everywhere (`close-1024/co1/VERDICT.md`).
- **Your item 2 (faint collapse) is NOT solved by a shared rule.** I tried two and rejected both on CPU (sheet in co1):
  - A roll-onto-side for faints taller than 0.6 of standing height rolled correct sideways faints belly-up: Riverdrake, Burrowback, Torrentoad, Brooktail, Stormursa. A box-height test cannot tell an upright faint from a sideways one with raised legs or a wide splayed body.
  - Two-way grounding lifted sunk collapses (Mosshell, Burrowback, Mirejaw, Galecrest) into standing reads, so the settle is lower-only and is a guard against floating faints only.
  - The listed faints stay per-species recipe work. QUESTION: may I take them as per-species f36 faint recipes next, in your list order (Torrentoad, Burrowback, Mosshell, Mirejaw, Brooktail, Riverdrake, Tanglevolt), each judged on CPU since poses do show there?
- **GPU READY tb/creatures-land c6941e683023e9344709dfe1ef587c69fdc9a813 (= da816e00 + one commit): Tanglevolt arcs.**
  - The painted arcs are already 1-2 px wide; a 1 px erosion would delete 83% of them. So instead: crisper mask edge (soften 1.0 -> 0.4), core mixed halfway to white-violet #EEE4FF, emission strength 3.0 (KHR_materials_emissive_strength; imports as emission_energy_multiplier 3.0) for a tight bloom on the lines only.
  - Judge on GPU High, day and night, against da816e00 so the arcs are isolated from the rim.
- **Staticub regression check:** nothing on main touched Staticub's model, texture or species entry after the 21 Oct regrade (a4ea89a7); later commits only slimmed unrelated files and restored references. I can't see the 8.10 batch from here. If it predates a4ea89a7 or the current stage/camera, the drop is a judging-setup difference, not a dimmed asset. Its arc emission (cecef9776) is only on tb/creatures-land, not main. Suggest the GPU puts the 8.10 frames and today's main frames side by side in one batch.
- tb/creatures-land head 5db2963fe434b094a27fd7a6dc4950b84d574447 (co1 evidence on top of c6941e68).

## TO COORDINATOR (26 Oct, dog3 spine ridge judged)

- **dog3 spine ridge (your yes): ties r1, reverted. No new READY.**
  - CPU b43 (confirming, RMSE 0.44; `close-1024/b43/VERDICT.md` on tb/creatures-land): ridge 6.72 vs r1 6.82, and vs main's badger 6.31.
  - Plates strapped on: PRESENT x3 for the ridge, against PRESENT/PARTIAL/PARTIAL for r1. The coat-filled shoulders, still shaded by the mesh's shoulder lumps, read as "dark muddy patches, a smeared saddle-pack".
- **r1 at ebec8e36 stays the dog3 GPU candidate,** queued as before; the GPU queue entry is unchanged.
- That is three dog3 rounds under 0.5 (r3, flatten, ridge), so I am parking dog3 plate work until the GPU verdict on r1. The CPU stage cannot tell these apart, and its self-lit albedo also exaggerates the orange.
- A real fix probably needs both together: the flatten plus the coat fill, which cuts the lump shading, or a Meshy re-generation of the shoulders. Your call once the GPU reads r1.
- Next: the Tanglevolt arcs + faint + Thundertunnel scale bundle, plus the Voltarach map check.
  - Voltarach's GLB does carry its arc map, and the imported material has emission_texture = `creature_voltarach_native_arc_emission.png`.
  - So the identical arms are not a load failure. Most likely the gold-vein mask (6.9% coverage) coincides with the gold blotches, so emission adds no visible change. I'll look at it inside the bundle.
- tb/creatures-land head d109b2f6bf848aca2c9e2092355624001dc12aae (dog3 assets = ebec8e36).

## TO COORDINATOR (26 Oct, dog3 mesh fix judged)

- **dog3 plate flatten (your go-ahead): no gain, reverted.** CPU b42 (`close-1024/b42/VERDICT.md` on tb/creatures-land): every judge scored the flattened mesh exactly as r1 (6.40 = 6.40 mapped; "almost identical"). Plates strapped on: PRESENT x3 on both.
  - Method, for the record: `flatten_plates.py` in 4df82f73. Back and shoulder vertices under the r1 plate mask moved 70% toward a Laplacian-smoothed body; 5810 of 19936 vertices, max 0.105 m. Height, length, rig, weights, clips and UVs unchanged. GLB sha256 b55d6805… -> 3cf5181b…. Reverted in the next commit, so the assets equal ebec8e36 again.
  - The batch is not confirming (r 0.69), so the dog-vs-badger number (6.40 vs 6.54) is noise-level; b40/b41 had dog3 +0.45/+0.57.
- **Diagnosis after r1, r3 and the flatten:** the "pack" read is the big dark plate mass painted over both shoulder blades, outlined hard against the orange coat. It is not the lumps (flattening changed nothing) and not stone separation (r3 changed nothing). Two rounds under 0.5, so I am switching approach.
- **QUESTION (design, yours or the owner's):** let the shoulders go back to coat and keep only a short, low stone ridge along the spine (the owner's "one or two light touches" read)? It is one texture change on r1's grade (paint coat over the shoulder-blade plates and keep the spine row), so no new Meshy run is needed. It changes the creature's look, so I won't do it without your yes. Otherwise dog3 r1 at ebec8e36 stays as queued, and the GPU decides the coat.
- **Next (your ST verdict): Tanglevolt arcs + faint + Thundertunnel scale, bundled as one candidate,** starting now. Small ride-along: check Voltarach's emission map loads (GPU arms identical).
- tb/creatures-land head 80f73b7a3e44854e55fa6f25fa2136a4e5bddbed (docs/evidence on top of ab2ea606; dog3 assets = ebec8e36).

## TO COORDINATOR (25 Oct, later)

- **dog3 r3 (6c63dfa6d) graded and judged: CPU b41 ties r1** (6.89 vs 6.95 mapped; RMSE 0.35, confirming; `close-1024/b41/VERDICT.md` on tb/creatures-land). Plates strapped on: PRESENT x3 for r1, PRESENT x2 and PARTIAL for r3. r1 stays the candidate; the r3 grade commit b6129230 is reverted in a9e286d3, and the assets are byte-identical to the READY head ebec8e36. Both beat main's badger by about +0.5 (b41 +0.57); judges again read the badger as off-identity.
- **PROPOSAL (mesh, as you asked; no more retextures):** the "strapped on" read comes from the dog3 mesh's raised shoulder lumps. Every texture so far, including separate stones, sits on a hard-edged mound that stops at the shoulders and haunches.
  - Fix in Blender on `candidate_dog3/models/creature_terrapup_dog3.glb`. Select the lump vertices by the plate mask in UV space (`grade_retex.py`'s plate mask, dilated by about 6 px), then shrink them along their normals toward a smoothed copy of the body surface (about 70% of the lump height), feathering 4-6 cm into the coat.
  - Keep two or three low stones along the spine and over each shoulder blade as small relief. Weights, rig and clips are unchanged (vertex positions only; skin weights carried).
  - The texture then follows the smoothed form, with fur reaching the stone edges.
  - Expected: removes the "pack" read, the remaining dog3 defect. b40/b41 put dog3 at about 6.6-6.95 CPU, so the gain is likely above 0.5.
  - This is a mesh edit, so it is yours or Codex's call. I can do it if you say the Creatures lane may edit this vertex data.
- **FIXED the companion-presence regression** (you were right: not pre-existing). Root cause: the P2-016 0.55 s hit-wince hold lives in `creature_animator.play_once("hit")` and also caught Companion Presence's out-of-combat hurt flinch (via `play_if_exists`). It froze the clip at speed_scale 0, so Presence read 0 after healing.
  - The fix is in code (ab2ea606): `play_if_exists`, used only by Presence, plays the clip straight through; combat hits (`play_hit`, `play_combat_flinch`, remote stagger) keep the hold. The test is unchanged.
  - Focused tests: companion_presence, creature_flinch, hit_flash, hit_impact, remote_stagger, combat_feedback, impact, creature_animator, f36_pose, hurt: 55 tests, 0 failed.
  - Any land carrying the wince code should include ab2ea606. Texture-only lands (Mirejaw, dog3 at ebec8e36) don't need it.
- tb/creatures-land head: ab2ea606433868b4b33ce8645bb8bac8fd6272b8.

## TO COORDINATOR (25 Oct, resumed session; orders 1-2 done)

- **GPU READY tb/creatures-land ebec8e36 (Mirejaw retexture, one candidate).** Full SHA ebec8e36732c9b4d8f573956f7953ba32e9cd8ea (= 4f7c8d31c + one commit).
  - r2 (b959ba072) graded by `mirejaw/candidate/retex/grade_retex.py`: back lifted off black to olive-umber (value floor 0.18, darks +0.18 fading out by 0.7), frills/crest amber-gold (regions from main's albedo, same UVs), red mouth interior to muted flesh-tan. Reserved red band 0.000%. Written into the native GLB's Image_0 + extracted jpg; f36 `source_sha256` re-pinned. Vivid not rebuilt: the native candidate's colourway id is `mirejaw_native_review`, so `--only vivid mirejaw` only rewrites the old lod0 extraction (reverted).
  - CPU b40 (3 judges, RMSE 0.67, confirming; `close-1024/b40/VERDICT.md` on the land branch): **6.35 vs main 5.69 (+0.66)**. Near-black back PARTIAL x3 (base PARTIAL/PARTIAL/PRESENT); judges call main's black-and-gold net "busy, generated-looking".
  - GPU form: `godot --path . --rendering-method forward_plus --resolution 1920x1080 --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=mirejaw --whole-body --context --candidate --source-commit=ebec8e36732c9b4d8f573956f7953ba32e9cd8ea --out=<fresh dir>` at Medium and High (the tool has no preset flag; set it the way your GPU session does) (and `water_mirejaw`, which shares the mesh). Control: main.
- **GPU READY tb/creatures-land ebec8e36 (dog3 Terrapup, one candidate; owner: "Terrapup should be a dog").**
  - r1 (b959ba072) graded by `terrapup/candidate_dog3/retex/grade_retex.py`: coat to chestnut (#7A5A3A-ish measured; hue 27-31, saturation capped 0.54 so nothing sits in the reserved band; 0.13% band texels left at jpeg edges), plates to matte earth-grey stone with lichen flecks, fur over each plate rim, contact shadow under the plates, moss clumps creeping into the coat. The Meshy normal and roughness maps are unchanged.
  - Folded in: `species.json` Terrapup -> `candidate_dog3` mesh, seat [0, 2.36, 0] (f0ada94b5's pad dip), field_rim 0.3, the cower and side-lying faint clips already in dog3. The lane's `creature_touches` terrapup overlays were never on the land branch, so nothing to drop.
  - CPU b40: **6.63 vs main's badger 6.18 (+0.45)**. Under 0.5 on CPU, queued for the owner's identity order: all three judges read it as an appealing, on-style big dog with the best poses in the batch; one calls the badger "off-board identity". Coat orange-red PARTIAL/PRESENT/PARTIAL on the self-lit CPU stage (GPU decides the coat). One judge saw a thin white streak off the tail in the hit frame (a dog3 clip artefact, not the texture).
  - GPU form: same as above with `--species=terrapup` (no `--candidate`: Terrapup is not in enabled_species). Control: main.
- **MESHY: stronger dog3 plate retexture.** After grading, all three judges still read the plates as "a rock saddle/pack strapped on", hard-edged at shoulders and haunches (PRESENT x3). Texture grading cannot break the outline the Meshy r1 painted as one blanket. Ask: a /retexture of dog3 (same mesh, original UVs) where the plates are **smaller separate stones following the spine and shoulder blades, each surrounded by coat, not one connected mat**; fur tufts between and over every plate edge; coat a deeper chestnut-brown #6E4628 (never orange); plates #6E6A5E with moss in the gaps. Deliver to `tb/meshy-1024` `assets_raw/naturalistic-1024/terrapup_dog3_retex/r3/`; I grade it with the same script (it reads one source path).
- Pre-existing failure, not mine: `test_companion_presence :: test_low_hp_slows_the_gait_lowers_the_head_and_flinches` (gait_scale 0 on a healthy creature) fails identically on the land head 4f7c8d31c. Focused batch otherwise 694 tests, 693 pass.
- Harness note (also for §8.1): a `--depth=50` fetch of tb/creatures + tb/meshy-1024 pulled 14 GB. Use `git archive <ref> <paths> | tar -x` into scratch, then drop the refs and that pack (`.git/shallow` back to HEAD) to recover the disk; a land checkout needs only the paths.

## HANDOFF (25 Oct, PAUSED for a fresh session)

**PAUSED 42fc1dcb2** (send_message was refused: untrusted device). tb/creatures-land 4f7c8d31c. Both branches are clean and pushed. No half-done grading exists: the b959ba072 fetch failed on disk before any change.

### Branch heads
- `tb/creatures` 6ce1a74cb (+ this handoff): the lane. It holds dog3 Terrapup (candidate_dog3, f0ada94b5), the Grandpa hair candidate (41b3b19c0), all specs and this note. It is not landed.
- `tb/creatures-land` 4f7c8d31c: the landing candidate. It merged main 400f3661f (#746/#747) at 9ad1c9e85. Not landed as a whole; the coordinator lands pieces from it.
- `tb/creatures-land2` 6749404d4: landed (#740 merged).
- `main` 400f3661f.

### Landed
- #740: Mosshock height 3.6 m with its collider grown (radius 1.8), and the Grandpa eyes.
- Earlier batches, per the coordinator.

### Open candidates on `tb/creatures-land`

| item | commit | status | next step |
|---|---|---|---|
| P2-016 body hit-flash | 29f4de904 | GPU queued (coordinator). CPU inconclusive: the disk filled and only 4 of 12 frames survived; the boar looked lighter on contact. | GPU verdict. If PRESENT, raise `impact.hit_flash.strength` (0.55) or `seconds` (0.12) as one change. |
| Big wince (head drop, squash, shove) | f2afad52d, gated by `impact.hurt_wince`, OFF | b37 +0.31, b38 +0.00. Parked by rule 1. | None. The 0.55 s wince-hold timing (4403807c8/288784257) is still in the animator; ask whether to gate it too. |
| Fight-effect ride-alongs: dust clear 2x radius, ground burst 5 @ 0.3, flash radius 0.3/0.38 | 5d1e10c71, f19176296 | Ride along with the hit-flash; not judged alone. | Judged with the hit-flash on GPU. |
| Mosshock regrade (#745 CI fix) | 01b054770 (8c27cb42e) | GPU queued. CPU b36 4.90 -> 6.01. colourway test moss share about 0.48. | Coordinator: once GPU holds it at 6 or above, move #745 to main + 01b054770's texture. Its GPU path to 7.5: more coat value range, rim, higher head carriage, a faint that keeps the head up. |
| Storm arc emission (Tanglevolt, Staticub, Thundertunnel, Voltarach) | e4b6a4018, cecef9776 | GPU queued (one stage check against the 22 Oct board). | GPU only; the CPU stage cannot show emission. |
| Tanglevolt board look: field_emission and field_rim to 0 | 1b9c6616b | GPU queued with the above. | If the GPU wants a rim, it is one number in species.json. |
| Nightburrow plate fill + rim, Riftfrill rim | tb/creatures 4e5dc1d35 | CPU b35 +0.23 / +0.00. Not queued (under 0.5). | Drop, or fold into a bigger change. |
| Mirejaw `lift_dark_back` touch | tb/creatures 4e5dc1d35 | Superseded by the Mirejaw retexture. | Drop it. |

### Orders not started (blocked on disk)
Source: the Meshy retextures on `tb/meshy-1024` b959ba072, `assets_raw/naturalistic-1024/{terrapup_dog3_retex,mirejaw_retex}/{r1,r2}/` (GLB, base_color PNG, thumbnail, provenance, prompt; original UVs).

**2. dog3 Terrapup** (owner: "Terrapup should be a dog"; land target: dog3 replaces the badger). Work on `tb/creatures`; the dog3 mesh is `assets/creatures/tetherbound/terrapup/candidate_dog3/models/creature_terrapup_dog3.glb`.
- Start from r1 (it shows the plates best).
- Write a grade script modelled on `assets/creatures/tetherbound/mosshock/retex/grade_retex.py`: the coat goes from orange to chestnut #7A4E2E, keeping hue out of the red band (check with the `shift_reserved_red.py` bands), and the plates go to weathered earth-grey.
- Write it into the dog3 GLB's Image_0 and the extracted jpg. Drop the `terrapup` overlays in `creature_touches.json`; the retexture replaces them.
- Fold into the same candidate:
  - lower `mount_offset` into the pad dip (now [0, 2.36, 0]; measure the pad height on the ride clip);
  - the cower (already in dog3 clips, 17ce37f88/f0ada94b5);
  - `field_rim` 0.3.
- Re-pin f36 if dog3 is in the recipes, run the import policy, import again, then CPU-judge against shipped main (the badger). Use `mkb15.py` with `BASE_FROM`, or the runbook flow.
- If the plates still read as a backpack after grading, ask the coordinator for a re-run with a stronger plate prompt.
- Specs: `close-1024/dog3-retex-spec/spec.md`. GPU path-to-7.5 verdicts: `tb/gpu-pass` `F36-1/M-terrapup-dog3-17ce37f88/VERDICT.md`.

**3. Mirejaw**
- Start from r2. r1 went blue-grey, which is off-spec.
- Grade the back to about value 0.28 olive-umber (#4A4636, seams #8A7A4E) and lift the frills to amber #D69A3A-#E7B85A. No red: re-run the `shift_reserved_red.py` check.
- Mesh: main's `assets/creatures/tetherbound/mirejaw/candidate/models/creature_mirejaw_native.glb`.
- Then rebuild vivid with `--only vivid mirejaw`, re-pin f36, run the import policy, import again.
- CPU-judge against main and post READY.
- Spec: `close-1024/mirejaw-retex-spec/spec.md`.

### Parked by the coordinator
- Land Riverdrake faint "seated coil" (GPU 7.13).
- water_riverdrake rider framing (no tool change).

### Open questions sent
- Whether to gate the 0.55 s wince hold off as well.

### What worked
- Asset-level changes:
  - the Mosshock Meshy retexture: GPU +1.76, CPU +1.11 after the regrade;
  - the red-band hue shifts (GPU red check FIXED 12/12);
  - the dog3 rig;
  - the Grandpa eyes (GPU 7.20 vs 7.09).
- Rule 1 (two rounds under 0.5 means switch approach) saved time once it was followed.

### What did not work
- Pose and timing tweaks for P2-016: five GPU rounds with no gain, and two CPU rounds under 0.5 for the big wince.
- Belly-to-camera faint rolls (b34: read as belly-up, −1.1).
- Albedo value nudges (b35 Mirejaw −0.05).
- Rims under llvmpipe: they don't render, so the CPU can't judge them.

### Harness runbook
TECHNICAL §8.1 "Creature stage and asset lessons" was added on `tb/creatures-land` 4f7c8d31c. Scratch scripts used (re-create from these descriptions if needed):
- `cap_live.sh <out> <species...>`: wraps `capture_f36_poses.gd` and adds `--candidate` for enabled species.
- `mkb15.py <batch> <cand_root> <sp>:<base_root>`: tiles hit-000/hit-050/faint-100 (plus ride/swim/fly) per side, writes spec.json, calls `anchor_tiles.py --pairs 3 --include f36_0_npc:C1`, hard-links `docs/reference` (`cp -rl`, to save disk) and fills the prompt. The prompt's judge-folder path must be absolute.
- `mapb.py <batch>`: raw_scores.json + key.json -> batch.json -> `calibrate.py`.
- Fight A/B: run `capture_named_fight.gd --trainer=south_bridge_grunt --frames=18 --interval=0.15 --attack` twice, the main arm with main's versions of the changed files checked out. Crop each frame to (0, 0.2h, 0.6w, 0.8h), tile 6 wide at 384x240, and build the spec by hand.
- Disk is the binding constraint: each 1280x720 fight frame is about 4 MB, and a full disk silently truncates PNGs. Check `Image.load()` before tiling.

Rows: F36#0, F36#1, F29#3. Renderer for every capture: Godot 4.7 Compatibility (Low), Mesa llvmpipe under xvfb (CPU-provisional bar 6.7 mapped).

## TO COORDINATOR
- 25 Oct **BLOCKED (disk), orders 2-3 not started.** Even a depth-1 fetch of tb/meshy-1024 b959ba072 needs more than the 189 MB free here and failed with no space left on device; the temp pack was removed and the checkout is clean.
  - The dog3 and Mirejaw retexture grading needs a session with disk headroom. Plan, from your read:
    - **dog3:** r1; coat graded to chestnut #7A4E2E (no red); seat pad, cower, rim 0.3 and f0ada94b5 folded into one candidate on tb/creatures.
    - **Mirejaw:** r2; back graded to about value 0.28 olive-umber, frills lifted to amber.
    - Both: CPU-check against main, then READY.
  - Specs: `close-1024/dog3-retex-spec/`, `close-1024/mirejaw-retex-spec/`.
  - Grading template: `assets/creatures/tetherbound/mosshock/retex/grade_retex.py`.

- 25 Oct GPU READY tb/creatures-land 29f4de904 (order 1): **P2-016 body hit-flash, one candidate.**
  - A struck creature's own surface pulses warm-white: #fff0d2 at 0.55, fading to 0 over 0.12 s, as an additive overlay on every mesh of its art, removed after the pulse. Art node only; body, collider and materials untouched. Config: combat.json `impact.hit_flash`.
  - The big wince is kept but OFF (`impact.hurt_wince`), and the recoil is back to main's tween. The 0.55 s wince-hold timing is still in the animator; say if you want that gated off as well.
  - Tests: new `test_creature_hit_flash`, plus flinch (wince forced on), hit window, remote stagger, combat feedback and impact: 20 tests, 0 failed.
  - CPU capture is inconclusive. The disk filled twice mid-capture, and only 4 of 12 frames survived. In frames 2-3 the struck boar reads lighter on contact, but dust overlaps it. **Please judge on GPU.**
  - GPU command (the same G3/G5 shape):
    `godot --path . --script res://tools/capture_f38_fight.gd -- --trainer=south_bridge_grunt --frames=32 --interval=0.15 --attack --dodge --tell-frames --source-commit=29f4de904d9f5eca286413256ed70aef20602a64 --out=<fresh dir>`
    Control: main.
- 25 Oct **lane blocker: disk.** This container has about 150 MB free; git packs are 18 GB plus 1 GB loose objects. Captures and imports keep failing. The dog3 and Mirejaw retexture grading (orders 2-3, tb/meshy-1024 b959ba072) needs room for an import and two captures each. A fresh session or a sparse/shallow checkout would unblock it. I'll try in place, small steps first.

- 25 Oct GPU READY tb/creatures-land 1b9c6616b: **Tanglevolt restored to its 22 Oct board look, one small candidate.**
  - field_emission 1.45 -> 0.0. I also took field_rim 0.25 -> 0.0: both came in ce892f75a after the board was made, and the rim brightens the fur at the silhouette, so I left it out rather than guess. If the GPU stage check wants the rim back, it is one number.
  - The vein emissive mask (e4b6a4018) carries the arcs against the dark coat.
  - Focused tests: 96 tests, 0 failed.
  - Proof is your GPU stage check against the board, as you asked. The CPU stage cannot show it.

- 25 Oct: **tb/creatures-land merged main 400f3661f (#746, #747)** as 9ad1c9e85.
  - One conflict, in combat.json soft_style: I kept main's `dust_lane_alpha_max` and the lane's `dust_body_clear`; tell_style.gd auto-merged both.
  - Focused tests (tell_dust_body_clear, enemy_pattern_telegraph, creature_flinch_head_drop, f36_pose_candidates, texture_import_policy, stormwood_source_colourways): 14 tests, 0 failed.
  - **The GPU READY head for the storm arc emission is now 9ad1c9e85.**

- 25 Oct GPU READY tb/creatures-land cecef9776 (order 4): **storm arc emission.** Tanglevolt (e4b6a4018), plus Staticub, Thundertunnel and Voltarach.
  - Each gets an emissiveTexture built only from its painted lightning: arc-hue pixels that are saturated and lifted 0.12-0.15 above the surrounding fur. The coverage is Tanglevolt 0.68%, Staticub 0.21%, Thundertunnel 0.70% and Voltarach 6.90% (its gold vein network). The texture is embedded in the shipped GLB the way Stormursa's map is. Base colour, mesh, rig and clips are unchanged.
  - Tool: `tools/art_pipeline/arc_emission.py`; spec: `data/creatures/arc_emission.json`. f36 pins and import policy updated; f36_pose_candidates + texture_import_policy pass.
  - **The check is GPU only:** Low/Compatibility already self-lights the whole albedo (field_emission), so the CPU stage shows no difference (Tanglevolt before/after identical on CPU). Please judge Medium/High night and day.
  - Scan of the other electric species:
    - Stormursa already ships emission.
    - Stormbrush's blue is the fur itself, not arcs.
    - Fulgocobra and Voltwig have faint veining only.
    - Glimmermoth, Sparkit, Stormraven and Mosshock have no painted arcs.
- 25 Oct status: order 3 (big wince) is not ready (b38 = main) and the body hit-flash is proposed above. Order 2 (dog3) is waiting on the Meshy retexture.

- 25 Oct (order 3) **Big wince: NOT READY; switching approach under rule 1.**
  - Bundle on tb/creatures-land f19176296:
    - b37's wince (head drop of a third of height, squash, 0.2 m/m shove);
    - telegraph dust clear of the attacker (2x body radius);
    - thinner contact dust (5 puffs at 0.3);
    - smaller impact flash (0.3 / 0.38).
  - CPU b38: 5.92 = main 5.92. With b37 at +0.31, that is two rounds under 0.5.
  - Judges: the head drop does not read from the grunt camera at strip size. The dust is lighter and the disc smaller, but both still sit over the body (PARTIAL).
  - Evidence: `close-1024/b38/judges.md`. The code stays on tb/creatures-land and is not landed.
  - **Proposed switch:** a body hit-flash, a 0.1-0.15 s white-warm tint pulse on the struck creature's own material (Palworld's and most action games' hit read). It shows at any camera distance, independent of pose and of the effects over the body. Visual only, on the art node's material; no body or collider change.
  - Say go and I'll build it as the next single candidate. Meanwhile I'm on order 4 (Tanglevolt arc emission).

- 25 Oct MESHY (order 2): **Terrapup dog3 retexture of the existing rigged mesh.** Spec, palette and the seat pad: `close-1024/dog3-retex-spec/spec.md`. The GPU M path-to-7.5 item 1 is stone plates grown into the coat: fur over the plate rims, contact shadow, moss creeping into the fur, weathered earth-grey plates, plus a worn leather pad in a dip between the shoulder plates. Mesh: `tb/creatures` `terrapup/candidate_dog3/models/creature_terrapup_dog3.glb`, Image_0, original UVs.
  - Once it lands, it becomes one bundled candidate with the lowered seat, the cower, rim 0.3 and f0ada94b5.
  - Meanwhile I'm finishing the big wince CPU check (order 3, captured), then Tanglevolt's vein emission (order 4).

- 25 Oct ~~Terrapup: shipped model passes; dog3 retired~~ **superseded by the owner's correction: "Terrapup should be a dog"; dog3 is the Terrapup.**

- 25 Oct MESHY (rule 2): **Mirejaw retexture of the existing mesh.** GPU 6.92, one dominant defect (the near-black back, a 'dark smear' at faint end). Two albedo nudges gained under 0.5 (b34 -1.17, b35 -0.05), so per rule 1 I'm switching to the Mosshock route. Spec, palette and refs: `close-1024/mirejaw-retex-spec/` (back about value 0.28, olive-umber with thinner ochre seams; cream belly and amber frills kept; no red; texture only, same mesh, rig and recipe). I'll grade, wire, re-pin and CPU-judge it when the task lands.
  - The lane's `lift_dark_back` touch (4e5dc1d35) is superseded by this; drop it from GPU READY.
  - Status of my order: the Mosshock regrade (01b054770) and the bigger wince (2a1eb2d98) are both posted GPU READY.

- 25 Oct GPU READY tb/creatures-land 2a1eb2d98 (= 01b054770 + G5): **P2-016 bigger wince.** On top of the third-of-height head drop (04ee56bcd): a 0.08 s squash on contact (0.86 high, 1.08 wide) and a shove away from the attacker of 0.2 m per metre of body (was 0.11). Hold timing unchanged; art node only, body and collider untouched (`test_creature_flinch_head_drop` + hit-window + remote-stagger: 9 tests, 0 failed).
  - CPU b37 grunt fight vs main: 5.81 -> 6.12 (+0.31); the defect moves PRESENT 2 / PARTIAL 1 -> PARTIAL 3/3 ('lowered or pulled back after an impact' in a few frames). Evidence: `close-1024/b37/judges.md`.
  - What still hides it on CPU, per all three judges: the dust puffs and the contact disc over the body at impact (fights lane), and the boar's facing turns reading as repositioning. If the GPU still calls it PRESENT, the next lever is a larger dip cap (25 deg now) or a stagger step back of about half a body length.

- 25 Oct GPU READY tb/creatures-land 01b054770 (= 463c2149b + 3 commits): **Mosshock CI fix for #745 (urgent).**
  - Regraded from r1 (`retex/grade_retex.py`, never compounding): coat moss at hue 100 with lighter values and a saturation floor, darker folds (below the coat's median value) olive-brown, belly and throat pale cream, olive-brown rims, amber iris, no red. Written to the embedded albedo, the extracted jpg and the vivid PNG; f36 pin updated.
  - `test_stormwood_source_colourways`: moss share ~0.48, inside the unchanged 0.34-0.78 band. The only test edit: the Mosshock case gets the one-rule, match {}, sat_scale 1.0 check every other species gets (commit 8c27cb42e records that the retexture replaces the anatomical repaint).
  - Named run on this branch: stormwood_source_colourways, director_join_snapshot, f36_pose_candidates, texture_import_policy, colourway, creature_flinch_head_drop: 23 tests, 0 failed. **test_director_join_snapshot passes here** and printed no "resources still in use" line.
  - CPU pre-judge b36 against main: 4.90 -> 6.01 (+1.11). Judges: face and eye now read, but the coat is 'clay-like' with a narrow value range; the hit and the faint (a belly-up roll) are unchanged from main. Evidence: `close-1024/b36/judges.md`.
- 25 Oct READY (fallback, same head) **P2-016 G4:** 04ee56bcd. The hit recoil drops the head about a third of the body's height (pitched nose-down about the hindquarters, capped at 25 deg), plus the shove away from the attacker; art node only, body and collider unchanged (`test_creature_flinch_head_drop`). CPU grunt fight capture: Mudsnout visibly dips nose-down at the impact frames. Use it if the 463c2149b re-test still fails.

- 25 Oct GPU READY tb/creatures (head after this note): batch-2 follow-ups. Base for every pair is main.
  - **Nightburrow** (aspect_variants rule + field_rim 0.3): the mustard fill between the black back plates goes violet charcoal, so the plates read as one armoured mass; brown coat kept. CPU b35 6.76 -> 6.99 (+0.23).
  - **Riftfrill** (field_rim 0.3): CPU b35 7.37 = 7.37; the rim does not render under llvmpipe, so only the GPU can judge it.
  - **Mirejaw** (creature_touches `lift_dark_back`, GLB albedo; f36 pin updated): the faint end keeps its pose and the near-black scale fill lifts to slate under the gold net. CPU b35 6.95 -> 6.90 (neutral; the 'dark smear' was a GPU read). Judge it on GPU or drop it.
  - **Tried and reverted:** belly-to-camera faint rolls for Mirejaw and land Riverdrake lost on CPU b34 (Mirejaw 6.77 -> 5.60, Riverdrake 6.77 -> 5.69; 3/3 judges read belly-up). Evidence: `close-1024/b34`, `b35`.
- 25 Oct QUESTION (batch 2): **land Riverdrake faint.** On the CPU stage main's faint end reads prone and down (b34: FIXED 3/3), not a seated coil. Which GPU frame shows the coil (camera or phase)? I'll fix against that frame.
- 25 Oct QUESTION (batch 2): **water_riverdrake rider.** The rider sits correctly at the neck base of a ~5 m drake; only the whole-body strip makes the 1.80 m trainer tiny. Options: (a) the capture tool frames the ride pose on the rider (tool change, every mount); (b) seat the rider higher or further forward (game change on this mount only). Which one?

- 2026-10-25 00:45 CT READY tb/creatures-land2 6749404d4 (PR #740 verify-suite (4) fix): `test_mosshock_collider_covers_its_art_width` now pins the 3.6 m body. The invariant held only by growing the collider too: the art grew 3.6/2.95 = 1.22x, so radius 1.475 -> 1.8 (scale ladder ceiling 0.5 x 3.6; spacing reach scales with the art as F10#2 requires) and footprint_allowance 2.73 -> 2.237 (radius x allowance 4.027 = 3.304 x 1.22, art fit only scaled). Test asserts radius >= 1.45 x 1.22, fit 1.0325 x 3.2 x 1.22 +/- 0.01, height 3.6. Local: stormwood_b_combat_camera_fit, creature_scale_ladder, scale_sensitive_gameplay, four_biome_roster_population, south_bridge_visual_scale all pass (25 tests). `test_stormwood_source_colourways` fails locally both with and without this commit, from a stale local import of the Mosshock vivid png (the file is byte-identical to main); CI imports fresh. Net smoke left to netfix as asked.

- 2026-10-25 00:25 CT QUESTION (PR #740 net smoke): `smoke_net_boss_rewards_each_participant` does NOT reproduce on tb/creatures-land2 c28bb6cc9: two local runs (`tools/net/run_net_smoke.sh boss_rewards_each_participant`, CPU, clean net) both ALL CHECKS PASSED. Reading: land2's only combat-path change is a presentation call (`_take_player_poise_damage` -> `hold_combat_wince`); hp/kill/resolve logic is untouched (the rest is animator hold + a 0.4 s recoil tween). The CI detail's `fainted=false` is OUR active creature's flag, not the enemy's; the shape is enemy hp 0 with the battle unresolved. A pre-existing path fits that: guest/host sync writes `_enemy.hp` directly (apply_host_strike_verdict, apply_encounter_record) and `_award_victory`/`_begin_resolve("won")` run only at the end of `_perform_player_strike`, after early returns (state != ACTIVE, null body, `_admit_host_feedback` refusing a duplicate impact). No fix pushed. Ask: has netfix reproduced it (and on main too)? If you still want the defensive change (no held wince on a fainted/0-hp body; faint always clears it) I'll put it on land2 with a focused test.

- 25 Oct GPU READY tb/creatures f0ada94b5 (dog3 Terrapup, your 0aad259db path to 7.5, all four levers):
  1. **Plates:** darker and weathered (val 0.62, sat 0.38), with moss clumps creeping from them onto the upper-back coat (`moss_at_plate_edges`, grow mode, 18.5% of the surface), so plate and fur share an edge.
  2. **Seat:** lowered 2.58 to 2.36 m. The rider sits into the back in CPU frames, with no clipping visible at stage distance.
  3. **Cower:** much bigger. The neck pitch goes 30 to 48 deg and the head 14 to 24 deg, with a harder roll; the head now drops near the ground.
  4. **Rim:** the coat's `field_rim` goes 0.25 to 0.30, the ceiling (an ordinary creature stays under the alpha rim).
  - **Check:** CPU stage frames only, not CPU-judged.
- 25 Oct batch-2 pose notes: tried, nothing committed.
  - **Faint rolls (Mosshock, Mirejaw):** rolling the other way (-90) shows the pale belly and splayed legs, a clear belly-up flip, worse. A partial 65 deg roll reads as propped or mid-tip, not down. So the shipped +90 roll (back to camera) stays as the least-bad option.
    - Mosshock's "feet up" read is its dorsal spikes.
    - Mirejaw's "dark smear" is its dark back.
    - A real fix is a new side-lying faint authored per rig with the head toward camera. Tell me if you want that queued.
  - **Land Riverdrake's faint coil:** the top hind leg sticks up after the roll. Folding the legs in the recipe did not move it (likely a sign or axis mismatch on this rig). Parked after two attempts.
  - **water_riverdrake rider size:** this is the 1.80 m trainer on a large drake. It is a strip-framing matter, not a creature change.
- 25 Oct GPU READY tb/creatures-land a888fb436: Mosshock's graded Meshy retexture, separate from land2 as you asked.
  - **Source:** your r1 retexture of the existing mesh, graded by `mosshock/retex/grade_retex.py`, with provenance and task ids beside it.
  - **Grade:**
    - the olive-yellow coat moves to a deeper moss at 72 deg (0% of texels in the grass band);
    - the orange mouth line and eye rims become olive-brown;
    - the irises are pushed to amber;
    - the pale belly is kept.
  - **Unchanged:** the mesh, rig, UVs, clips and 3.6 m. The ordinary colourway passes the embedded albedo through.
  - **CPU b33 against the batch-2 look:** mapped 6.31 to **6.94** (+0.63). Fit slope 1.11, anchor RMSE 0.59, confirming batch. Evidence: `b33/judges.md`.
  - **Still flagged:** the faint reads as a belly-up flip (PRESENT 2 of 3), and the hit as more crouch than flinch. I'm taking the faint next, with the batch-2 notes (Mirejaw's faint back, land Riverdrake's faint coil, water_riverdrake's rider size).
- 25 Oct READY tb/creatures-land2 c28bb6cc9, from main e60204db8. It replaces tb/creatures-land-grandpa.
  - **Contents:** all of 4e5217f1b, merged cleanly (86611cffd), except Mosshock's colour. Mosshock's vivid texture and its colourway rules are main's again; it keeps the 3.6 m height and scaled footprint (e4de7124e). Plus the Grandpa eyes (cf5bbf99d) and the `art.json` `_why` citing tb/gpu-pass 9099a88322 (c28bb6cc9); no other switch is needed, because main already ships the candidate head.
  - **Not in it:** the later G3 hit-react hold (4403807c8, 288784257 on tb/creatures-land, posted separately for GPU) is not in land2, as you scoped it to 4e5217f1b.
  - **Tests:** f36_pose_candidates, rest_pose, water_species_catalog, texture_import_policy, four_biome_roster_population, creature_scale_ladder, hit_impact_window, remote_stagger_wince, combat_feel, combat_stagger, hit_feedback, remote_creature, character_hair_split, character_appearance_variants, character_metallic: 96 tests, 0 failed.
  - **Next:** grading the Meshy Mosshock r1 retexture (separate), then the batch-2 notes (Mirejaw faint back, land Riverdrake faint coil, water_riverdrake rider size).
- 25 Oct READY tb/creatures-land-grandpa f1209f09c (Grandpa eyes only, from main e60204db8, separate from batch 2):
  - **Contents:** 30a52c7de (cherry-picked as d52929bc5) plus an `art.json` `_why_eyes_close1024` citing tb/gpu-pass 9099a88322.
  - **No switch needed:** main's `art.json` already ships `grandpa/candidate/models/grandpa_native_face.glb`, so the eyes commit alone turns the eyes on.
  - **Tests:** texture_import_policy, character_hair_split, character_appearance_variants, character_metallic, captured_character_receipt: 23 tests, 0 failed.
  - **smoke_art:** reports four failures (creature shiny, alpha and rarity-tier checks: terrapup, paddlenewt, burrowback), identical on plain main e60204db8. Nothing Grandpa-related.
- 25 Oct GPU READY tb/creatures-land 288784257 (your G3 verdict): every landed hit now holds its wince 0.55 s.
  - **Diagnosis:** a CPU fight log showed every hit already triggers the wince and nothing clears it early. The wince simply ended long before the damage number did: 0.19 s, then 0.3 s, against the number's 0.8 s (combat.json `duration_seconds`).
  - **Change:** 0.55 s held plus the clip's release now spans the number. 4403807c8 (0.3 s) and 288784257 (0.55 s). Two existing tests updated to the new intended timing; 47 tests, 0 failed.
  - **CPU proof, your exact capture_f38_fight grunt command:** damage-number frames 15, 16, 18-21, 23, 24 and 26 show Mudsnout's head ducked in the wince; G3 had 1 in 32.
  - **Exceptions:** frames 2, 12 and 13, where the hit lands during Mudsnout's protected heavy wind-up (the purple cone). The body stays committed to the attack there, which reads like the heavy-armour design. Tell me if it should flinch through it instead.
- 25 Oct GPU READY tb/creatures 41b3b19c0 (Grandpa hair and beard, on top of the 30a52c7de eyes you have queued for the next PR):
  - **Change:** same head, mesh and atlas. Only the white-grey hair and beard texels (7.6%) change: a 3 px median removes the felt speckle, and an unsharp pass at strand scale (4 px) makes the strands crisper. Colours and identity unchanged.
  - **Method:** a wide smoothing was tried first and rejected; it blurred the strands into more felt.
  - **Script:** `assets/characters/grandpa/candidate/source/smooth_hair.py`, which repaints from a kept base.
  - **Check:** at the cast distance the change is invisible (mean difference 0.05/255). At atlas scale the strands read clearly crisper. Please judge it on your face close-ups (the f36_0_npc layout).
- 25 Oct GPU READY tb/creatures 17ce37f88 (tier 3, dog3 Terrapup; lane-only like the earlier dog3 posts):
  - **Hit:** now the cower. The head-up recoil read as rearing.
  - **Plates:** the green stone plates are desaturated and darkened toward a weathered earth-grey, so they read as grown into the coat (`creature_touches.json` terrapup `plates_into_fur`).
  - **Seat:** stays at the lane's 2.58 m offset; the rider sits on the back in CPU frames.
  - **Faint:** already side-lying, unchanged.
  - **Capture:** the lane species state (dog3 model plus its own `rideable.mount_offset`). Not CPU-judged yet.
  - **Mosshock retexture spec:** staged as you asked, at `close-1024/mosshock-retex-spec/` (palette hex, what stays, style-bar crops). Use it only if batch 2 leaves Mosshock below 6.
- 25 Oct GPU READY tb/creatures-land 4e5217f1b. It replaces the 9463a4326 head; please queue this one. CPU b32 is in `b32/judges.md`.
  - **Your Mosshock correction:** agreed, not stale. The blotch shapes are baked into the source atlas, so recolouring keeps the pattern. b32 (its compressed values plus 3.6 m, against the GPU-judged look) mapped 6.25 to 6.32.
  - **Mosshock in 4e5217f1b:** one hue and close values (about 0.3-0.4) across the growth, lichen and dark patches, for a mostly even moss coat. A wide despeckle did not merge the shapes.
    - Still left: a few amber flecks (the rule that keeps the eyes) and near-black dots.
    - A clean coat needs new art (a retexture), which the owner's no-remake direction rules out. Tell me if you want a Meshy retexture of the existing mesh instead.
  - **Riftfrill:** the roughness fix is kept (6.90 to 6.97).
  - **Stormtrail:** the rim is reverted (7.49 to 7.39).
  - **The red check and Mirejaw's tail curl (48c7c2c0a)** ride this head unchanged.
- 25 Oct GPU READY tb/creatures-land 9463a4326: one head for your batch 1 verdict, in your priority order. CPU sanity frames only; not CPU-judged.
  - **Red check (48c7c2c0a), both repainted from the pre-shift originals in git:**
    - Riverdrake: the crest and frill edges move to gold (hue 42; the band now reaches 32 deg, 10.8% of texels).
    - Mirejaw: the rust frill roots move to tan (hue 40; saturated rust only, 6%; its taupe body under sat 0.55 untouched).
    - Mirejaw's faint now curls the tail toward the camera. The tail was the same length as standing, not stretched, but rolled on its side it read as a straight rod.
    - **Water forms:** they share the land mesh and albedo by design. The roster's water Mirejaw uses the same `creature_mirejaw_native.glb`, and since f3d6d65f0 it no longer pulls the old lod0 repaint. So they look identical to land on purpose, and a fresh import loads the committed GLB.
  - **Mosshock (a3aab1cf5):**
    - The repaint did land. `mosshock/models/mosshock_extracted_base_color_vivid.png` is committed and is the path `_texture_for` resolves. "Yellow-black blotches" is that olive-and-lichen texture: the blotch pattern itself read as camo.
    - Fix: the value range compresses into one mossy hide. Black patches go to a deep olive at 0.3, the growth and lichen darken toward them, and the eyes and near-black features are kept.
    - Grown 2.95 to 3.6 m, clearly over the trainer. The footprint allowance scaled with it; collider unchanged. creature_scale_ladder passes.
  - **Riftfrill (9463a4326):**
    - Gloss: its plastic sheen is Paddlenewt's shared roughness map (mean 0.32, against about 0.9 on the other remakes). Raised to about 0.63, so Paddlenewt changes too.
    - Height: not grown. Riftfrill is in the owner's small class with Paddlenewt and Mudsnout (owner direction, standing).
  - **Stormtrail (9463a4326):** the 0.25 silhouette rim for its near-black coat.
  - **Tests:** f36_pose_candidates, water_species_catalog, texture_import_policy, rest_pose, four_biome_roster_population, creature_scale_ladder: all 0 failed.
- 25 Oct GPU READY tb/creatures-land 78361d936 (tier 3 and the owner notes). CPU b31 is in `b31/judges.md`.
  - **Mudsnout (66612a79b):** its small tusks (the lane's candidate_nat1024t, CPU b27 7.51 vs 7.04), the hardened shoulder hide and the snout scar. Height stays 2.0 m, in its small class. Its hit is the cower.
  - **Trailpup (14639c373, then 78361d936):** one subtle touch, light trail dust in the paws and lower legs. I dropped the rim: b31 judges read it as bleached legs, and b20 had found no rim gain. Its hit is now the cower too, which Stormtrail shares.
  - **Cindercub (a20d65623, then 78361d936):** definition via a soft ash-grey mask on the muzzle, cheeks and brow, ember cracks unchanged. Its hit is the cower.
  - **Nightburrow (41c771e24):** small pale chips worn into the edges of its stone back plates, under the glow. Burrowback is unchanged.
  - **b31 mapped:** Cindercub 7.44 to 7.52, Mudsnout 7.12 to 7.09, Nightburrow 6.63 to 6.66, Trailpup 7.18 to 7.09. All within noise; these are the owner-directed touches, so the GPU decides.
  - **Grandpa:** noted the GPU pass on the eyes; the hair and beard pass is queued after dog3.
- 25 Oct GPU READY tb/creatures-land 4fb473e7a (tier 1, on top of the a986d3142 repaint): Mosshock's hit is now a cower, because all three b30 judges read the rear-up as a lunge.
  - **New pose:** the head ducks low and aside, the body dips 8 deg and rolls 16 deg away, the tail tucks and all four feet stay planted. Only its recipe hit line changes, in `f36_pose_candidates.json`.
  - **Checks:** CPU stage frames read as a flinch; test_f36_pose_candidates and the hit-window test, 7 tests, 0 failed. Not yet judged; it rides the next CPU batch.
  - **State:** pushed and clean, so nothing was lost to the disconnect.
- 25 Oct GPU READY tb/creatures-land a986d3142 (tier 1, the sub-6 row): Mosshock's ordinary repaint.
  - **Change:** the neon-green camo is gone. Its red growth becomes a darker, muted olive moss outside the grass hue band (0% of chromatic texels in the band, was 57%); the gold current becomes pale lichen; the amber eyes are kept, so the face reads. Rule change only: `four_biome_colourways.json` mosshock `vivid_rules`, regenerated with `tools/repaint_creature_textures.py --only vivid mosshock`.
  - **CPU b30:** mapped 5.55 to 6.43 (+0.88). Fit slope 1.26, anchor RMSE 0.55, confirming batch. Evidence: `b30/judges.md`.
  - **Still flagged by all three judges:** the hit (a rear-up that reads as a lunge) and the faint (hard to parse). I'm doing a cower hit next.
- 25 Oct GPU READY tb/creatures-land 471d7ff3e (your G2 verdict on cf2d4258a): the struck enemy now flinches in named-trainer fights.
  - **Path:** the enemy in a named-trainer fight is the same wild_creature body; its hit clip fires with its impact window. The hit pose itself was the problem: a rear-back that read as attacking, and Mudsnout's had never been strengthened.
  - **21714fd2f:** Mudsnout, Burrowback and the Terrapup badger now cower when hit (head ducks low and aside, body rolls away, tail tucks; feet planted). Only the hit clip changes.
  - **471d7ff3e:** every creature's hit shove now scales with its size (0.11 m per metre of height, about 0.27 m on a 2.4 m body), adds an 8 deg lean away and holds about 0.4 s, so it spans two or three 0.15 s frames. Before, it was a fixed 0.14 m over 0.16 s.
  - **CPU proof:** your exact `capture_f38_fight` command (grunt and Warden, 32 frames at 0.15 s, --attack --dodge --tell-frames, Low). In frames with a damage number, Mudsnout's head drops low and Burrowback ducks and turns away. Sheet: `p2016-g3/_sheet_fight.png` (left: grunt f17-32, Mudsnout; right: Warden f15-30).
  - **The STAGGER label in these fights is the player's:** it reads "Terrapup STAGGERED — recovering". A temporary log showed the ally's stagger hold fires (0.6 s) and nothing clears it. But during those frames Terrapup is usually between the camera and its target, so the camera draws it see-through (dithered), or it is out of shot. That is camera framing (F38 L1), not the pose. Worth telling the judges, or fixing in the camera lane.
  - **Tests:** combat_feel, combat_stagger, hit_impact_window, hit_feedback, remote_stagger_wince: 41 tests, 0 failed.
  - **Owner glow rule (25 Oct):** none of my pending touch candidates has glowing seams (Mudsnout's hardened shoulder hide and snout scar, Terrapup's chestnut-to-brown coat), so nothing needs reworking.
- 25 Oct GPU READY tb/creatures-land f3d6d65f0 (hard rule, from your GPU roster baseline): the crimson frills on Riverdrake and Mirejaw (land and water) are amber now. Please GPU-judge mirejaw, water_mirejaw, riverdrake and water_riverdrake.
  - Albedo texels in the saturated red band were shifted to amber, keeping each texel's value: Riverdrake 8.5%, Mirejaw 1.6%. Tool: `tools/art_pipeline/shift_reserved_red.py`. GLB-embedded and extracted images are both rewritten, and the f36 recipe hashes re-pinned.
  - Found while checking: water Mirejaw had been loading the previous lod0 mesh's vivid repaint onto the native UVs, which gave the garbled camo and most of its red. Its water roster entry now has the land form's `colourway_source_species`, so it wears its own texture. Abyssal Guardian's water form had the same gap and got the same fix; CPU frames show the water and land Guardians now match.
  - Tests: water_species_catalog, f36_pose_candidates, rest_pose, texture_import_policy, four_biome_roster_population, 0 failed.
- 25 Oct GPU READY tb/creatures-land a22e582cd (tier 1): the Stormtrail and Riftfrill repaint (lane aca00a732) is promoted to land. CPU b22 mapped: Stormtrail 7.21 vs 5.58, Riftfrill 6.63 vs 5.93. Stormtrail is one of the two GPU sub-6 rows.
- 24 Oct READY tb/creatures-land b36911df9 (your non-blocking ask on cf2d4258a): other peers' copies of a player's creature now hold the stagger wince too.
  - The owner's proxy attaches `stagger_seconds` (combat `player_stagger_seconds_left()`) to the hit it publishes, and the viewer's copy calls `hold_combat_wince`, clamped to 2 s.
  - Tests: new test_remote_stagger_wince plus the test_remote, remote_creature, hit-window and presentation suites, 149 tests, 0 failed.
- 24 Oct GPU READY tb/creatures-land b8fd842b8 (tier 2, Mosshell): the withdraw faint (`close-1024/b29/judges.md`).
  - CPU (confirming batch): 7.38 against shipping 6.70. The faint end now reads as down; the old -60 roll read as standing or a wheel-like flip.
  - The water form shares the mesh, so it shows the same faint.
  - Capture: `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=mosshell,water_mosshell --whole-body --context --out=res://.artifacts/gpu-mosshell-withdraw/<preset>`
  - Note on cf2d4258a (your review): the three re-exported GLBs differ from the old ones by float noise only (up to 0.6 mm), not byte-identical. Thanks for the correction.
  - Next on my lane, per your order: tier 3 (Trailpup rim and accent, then dog3: plates, faint and seat). Also the co-op held-wince follow-up for remote copies.
- 24 Oct READY tb/creatures-land cf2d4258a (P2-016 after the GPU PARTIAL on #733). The commit is main 124a7393c plus the stage commits, 4b2a5fa63 and cf2d4258a.
  - **Who was idle:** in the grunt fight the large armoured badger is the PLAYER's fixture Terrapup (HUD: "Terrapup Lv3"), not the enemy. The small creature that now rears is the enemy Mudsnout.
    - An in-engine probe of an engaged wild Mudsnout shows the hit clip held about 0.28 s through hitstop and movement, then gait.
  - **Cause 1 (4b2a5fa63):** a stagger showed its STAGGER label over an idle body once the 0.25 s wince ran out.
    - Fix: a stagger now holds the creature's wince, the middle of its named hit window, for the whole stagger, then lets the clip play out.
    - Applies to the enemy (local and synced) and to the player's creature. Rigs with no named window are unchanged.
  - **Cause 2 (cf2d4258a):** Terrapup's badger, Burrowback and Bramblebun use the small "recoil" hit (root 4 deg, lean 9 deg). At fight distance it reads as idle.
    - Fix: the recoil roughly doubles (pitch 9, lean 16, spine 11, neck 26, head snap 30 deg), feet planted. Only the hit clip changes; idle, faint and rest keyframes are identical.
    - The CPU stage before/after shows a clear chest-back recoil on all three.
  - **Tests:** hit window plus stagger (3 new), telegraph, companion, combat_feedback, hitstop, flinch, poise and stagger: 66, 0 failed. test_combat, wild_creature, encounter, test_poise and remote_creature: 357, 0 failed. rest_pose, f36_pose, texture_for, rideable, riding and four_biome: 88, 0 failed.
  - **GPU check (same command):** `godot --path . --script res://tools/capture_f38_fight.gd -- --trainer=south_bridge_grunt,warden_aldis --frames=32 --interval=0.15 --attack --dodge --tell-frames --preset=<Medium|High> --source-commit=<sha>`
  - **Not mine:** the lavender telegraph domes over the reacting creature are Fights'.
  - **Lane note:** dog3 on tb/creatures uses the same small recoil; it gets the same accent if dog3 goes forward.
- 24 Oct QUESTION/ASK (reply to your --all baseline at main; please swap it before it starts): `capture_f36_poses.gd --all --whole-body --context` at main gives a wrong shipping baseline for two reasons.
  1. **Without `--candidate`, every species plays its installed clips** (capture_f36_poses.gd line ~168: `map.get(role)`). The 36 F36 (1) subjects whose f36 recipe ships (enabled_species) would be scored on poses players never see.
  2. **Main lacks the two stage commits.** Land species get a floating carried frame or a swim slab with a white edge; that alone docked Mosshell, Bramblebun, Trailpup and Mudsnout in GPU A+C.
  - **Use instead:** the two commands in my previous line, at tb/creatures-land 1e83cafa0 (= main 124a7393c plus only the stage commits). They are batched: 36 with `--candidate`, 19 without. That covers every F36 (0) and F36 (1) subject without a GPU score.
  - **If you want the whole roster,** run `--all` twice at 1e83cafa0, once with `--candidate` and once without, and take each species from the arm that matches whether it is in enabled_species.
- 24 Oct GPU READY (owner tiers, "lowest up to 6 first"): one batched GPU baseline for every F36 subject without an F36 (1) GPU score, on tb/creatures-land 1e83cafa0.
  - That commit is main 124a7393c plus the two F36 stage commits (no swim row for non-swimmers; carried row only for fly carriers; rough water with the ruler on the waterline). On plain main, land species get a floating carried frame or a swim slab, which docked every judged set.
  - It is 55 subjects. Recipe species ship their f36 recipe, so they need `--candidate` to capture the shipping state:
    - Recipe ON (36): `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=abyssal_guardian,aeriex,ashtusk,brooktail,cannonback,cragclaw,fulgocobra,galewisp,glimmermoth,mangrove_monitor,mirejaw,mosshock,ribbonray,riptusk,riverdrake,shadelet,sirenseal,skyrill,sparkit,staticub,stormbrush,stormursa,tempestwing,torrentoad,tuskroot,voltarach,water_abyssal_guardian,water_aquaryn,water_cragclaw,water_mangrove_monitor,water_mirejaw,water_riptusk,water_riverdrake,water_sirenseal,water_tidecoil,water_torrentoad --whole-body --context --candidate --out=res://.artifacts/gpu-baseline-1024/cand/<preset>`
    - Own or installed clips (19): `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=bramblebun,burrowback,cindercub,duskhush,meadowhart,mosshell,mudsnout,nightburrow,paddlenewt,pipwing,reedwing,riftfrill,ripplet,stormtrail,terrapup,trailpup,veridian,water_cannonback,water_mosshell --whole-body --context --out=res://.artifacts/gpu-baseline-1024/plain/<preset>`
  - Excluded, because they already have an F36 (1) GPU score (tb/gpu-pass F36-1/main-1024): aquaryn, breezetail, cliffspike, cloudfang, craghorn, frostclaw, galecrest, pebbik, solmane, stormcapra, stormraven, tanglevolt, thundertunnel, tidecoil, voltwig.
    - Lowest there: stormraven's recipe 5.81, but it is OFF and shipping is 6.09. Galecrest's recipe 6.62 is also OFF.
  - F36 (0) model rows with no GPU score are inside these lists: Galewisp, Cannonback, Ashtusk. Cloudfang already has its F36 (1) score.
  - Known sub-6 on GPU: Mudsnout 5.88 and Trailpup 5.73, both on the old stage. The fixed stage alone maps them 7.73 on CPU (b26), and their H candidates are queued (47d097879).
  - Parked per the tier rule: Mosshell and Aquaryn near-bar polish.
- 24 Oct GPU READY on tb/creatures 30a52c7de: Grandpa eyes (F36#0 Grandpa sub-row; `close-1024/b28/judges.md`).
  - Change: the same installed head, mesh, rig and UVs; only the bead eyes in the face albedo are repainted, with a pupil, hazel iris, limbal ring and catch-light. No new face generation.
  - CPU (confirming batch, C1 excluded): eyes 6.87 against installed lod0 6.27.
  - The eyes-vs-ship set was excluded: the judges copied scores across two different tiles.
  - Arms, as in your re-confirm: art.json `grandpa.model` = `candidate/models/grandpa_native_face.glb` (now carrying the eyes) against `grandpa_lod0.glb`, using `tools/_capture_character_cast.gd`.
  - Still open from the judges: noisy hair and beard texture, and the blotchy scarf.
- 24 Oct GPU READY on tb/creatures 05671f929: Mosshell, Bramblebun, Trailpup and Mudsnout on the fixed stage, plus the Terrapup dog3 redraft. See `close-1024/b26` and `b27/judges.md`.
  - **Stage fix (67882b304):**
    - fly_grip is shot only for fly carriers (Galecrest, Galewisp), so land species no longer hang in mid-air.
    - The swim water is rough with no white specular edge, and the ruler stands on the waterline.
    - Mosshell and Bramblebun have no travel frame now; neither is rideable or a swimmer.
  - **Trailpup:** shipping albedo, with the touch reverted.
    - On the fixed stage it maps 7.88 CPU (b27) and 7.73 (b26), both confirming batches.
    - It is 3.1 m to the ear tips in every build, with the back at about 2 m. That is why it reads close to the ruler at thumbnail size.
  - **Mudsnout:** the tusk build with bolder hardened hide and snout scar maps 7.51 against shipping 7.04 (b27). Small class kept at 2.0 m.
  - **Energy seams:** an unshaded shell hook (species `touch_glow`) exists, but b26's three judges read amber seams on fur as gold glitter or an artefact (-0.6). No species uses it now.
  - **Terrapup dog3:**
    - The raw redraft measures 1.53 L/H, not 1.3-1.4; dog2 was 1.66. The legs are only slightly longer (belly about 0.35 of height), and the tail still streams back about 20%.
    - Rigged at 3.20 m (4.90 m long). Faint is the -90 prone (b26: the +90 belly-to-camera faint read as the listed belly-up flip x3). Coat pulled from orange-red to chestnut. Seat 2.58 m at z 0.0, lower and forward.
    - CPU 7.41 against dog2 7.55: within noise. It reads as a St Bernard; two judges preferred dog2's darker coat.
  - **Capture:** `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=mosshell,bramblebun,trailpup,mudsnout,terrapup --whole-body --context --out=res://.artifacts/gpu-1024-stage/<preset>`
  - **Tests (lane state in a full tree):** touch_vfx, hit window, texture_for, rest_pose, rideable, riding, four_biome, scale_ladder, species, water_species, f36_pose, aspect, colourway and night_floor: 111 tests, 0 failed. texture_import_policy passes.
- 24 Oct READY tb/creatures-land 34a27dd59 (P2-016 hurt poses in real fights; `close-1024/p2016/verdict.md`).
  - Remakes' own held hit clips now start at the wince and hold it through hitstop and movement, like recipes.
  - Tests: 62, 0 failed. On a CPU real-fight capture the wince shows after the fix and not before.
  - GPU check: `godot --path . --script res://tools/capture_f38_fight.gd -- --trainer=south_bridge_grunt,warden_aldis --frames=32 --interval=0.15 --attack --dodge --tell-frames --out=res://.artifacts/gpu-p2016/<preset>`. Use 0.15 rather than 0.5: at 0.5 s the 0.25 s wince falls between frames.
  - Also seen: the tan hit-spark disc covers the struck creature on the impact frame. That is effects work for whoever owns P2-062/063.
- 24 Oct MESHY (answer on the Terrapup dog's proportions): the mesh itself is elongated. Our fit, rig and stance do not stretch it, so please regenerate from the side-view concept with explicit proportions.
  - Raw Meshy GLB `assets_raw/naturalistic-1024/terrapup_dog2/terrapup_dog2.glb`: 1.14 tall by 1.89 long (1.66:1).
  - In game (`candidate_dog2`): 3.20 by 5.31 (1.66:1). The scale is uniform, there is no footprint shrink, and the idle stance does not lower it.
  - Profile along its length:
    - Body (rump to chest) is about 1.25 times withers height, which is close to normal.
    - The tail streams straight back and adds about 20% of the length; the concept's tail hangs down.
    - The legs are short: the belly line sits at about 35% of withers height, against roughly 45-50% for a mountain dog.
  - Suggested prompt terms: legs about half the withers height, a deep chest with a tucked waist, the tail hanging down to the hocks, and the ear and muzzle stop visible in profile.
  - Meanwhile I am doing the coat lift, the side-lying faint and the lower, forward seat on this mesh. The coat spec carries over to a regenerated mesh as albedo direction.
- 24 Oct GPU READY on tb/creatures 7a44a9367: Cindercub ember motes (owner touch pass; `touch_vfx`, not a variant; `close-1024/b25/judges.md`).
  - CPU: parity, 7.19 vs 7.26.
  - Capture vs main: `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=cindercub,nightburrow,stormtrail,riftfrill,ashtusk --whole-body --context --out=res://.artifacts/gpu-touch-vfx/<preset>`
  - Same commit fixes Aspect VFX billboards drawn edge-on on side-on creatures, so Nightburrow, Stormtrail, Riftfrill and Ashtusk VFX change too. That is why they are in the capture.
  - Tests: the new touch_vfx test plus 138 aspect/variant/shiny/colourway tests, 0 failed.
- 24 Oct GPU READY on tb/creatures 1225d1a86: owner touch pass on Trailpup and Mudsnout (weathered shoulders and faint scars, baked into the albedo; the mesh is unchanged; `close-1024/b24/judges.md`).
  - CPU: score-neutral and light (Trailpup 7.58 vs 7.58, Mudsnout 6.86 vs 6.82). It is the owner-directed look, so the GPU pass decides.
  - Capture vs main: `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=trailpup,mudsnout --whole-body --context --out=res://.artifacts/gpu-touch/<preset>`
  - Mudsnout on the lane is the tusk build (0d0d73cf6), which carries the same touched albedo.
  - Next: energy seams and elemental VFX (Cindercub embers, Bramblebun ground-amber seams), with Nightburrow and Bramblebun touches after.
- 24 Oct GPU READY on tb/creatures 96c68213c: Aquaryn and Tidecoil b5 remakes, land and water forms on the same mesh (`close-1024/b23/judges.md`).
  - CPU: Tidecoil 7.26 vs 6.39. Aquaryn ties at 7.30 (judges split navy vs cyan).
  - Capture vs main: `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=aquaryn,tidecoil,water_aquaryn,water_tidecoil --whole-body --context --out=res://.artifacts/gpu_b23/<preset>`.
  - Tidecoil's blue lines read as water sheen, so they are left as they are.
  - Next for Tidecoil: a serpent hit (the quadruped recoil barely moves the coil).
- 24 Oct GPU re-run request at tb/creatures ef8c20d7e. Trailpup, Bramblebun, Nightburrow and Mosshell were judged on GPU with a swim row (land species walking on the water slab) and, for Trailpup, below the ruler. Both are fixed: the stage drops the swim row for non-swimmers (06beef397), and Trailpup is now 3.1 m.
  - On CPU they map 7.80, 7.93, 6.69 and 7.31 (b20, b18).
  - Command: `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=trailpup,bramblebun,nightburrow,mosshell --whole-body --context --out=res://.artifacts/gpu_rerun/<preset>`.
  - The owner's "one touch" accent for them stays my next item: the rim lever was invisible, so it will be texture-level.
- 24 Oct GPU READY on tb/creatures aca00a732: Stormtrail and Riftfrill texture-level fixes (`close-1024/b22/judges.md`).
  - CPU b22: Stormtrail 7.21 vs 5.58 (storm-grey coat, soft blue spine line, gold leg bands gone). Riftfrill 6.63 vs 5.93 (lighter teal, pale belly, accent-only glow).
  - Their b19 value lift is dropped (the repaint replaces it). Cindercub keeps its lift.
  - Capture at aca00a732 vs main: `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=stormtrail,riftfrill,cindercub --whole-body --context --out=res://.artifacts/gpu_b22/<preset>`. This supersedes the b19 queue for Stormtrail and Riftfrill.
  - Terrapup dog lead admission: smoke_arena_contain headless with the dog bound (seat 2.66 m) gives arena containment OK, Warrens 6.0 m and Hall 7.0 m held, a full 7.60 m formation. It can land once GPU passes.
- 24 Oct GPU READY on tb/creatures 0d0d73cf6 (corrected: b705fe176 bound the models before they were committed). Both candidates are bound on the lane; ride seat 2.66 m on Terrapup's plated back.
  - Terrapup large dog (`candidate_dog2`, 3.20 m, 5.31 m long, no footprint shrink). CPU sanity b21: 7.46 vs the badger's 7.65; no pose PRESENT, ride fixed x3. It is the owner's species, so it goes to GPU.
  - Mudsnout tusks (`candidate_nat1024t`): b20 CPU 7.46 vs 7.33.
  - Capture, Medium and High, at 0d0d73cf6 against main: `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=terrapup,mudsnout --whole-body --context --out=res://.artifacts/gpu_b2021/<preset>`.
  - Grow/lead admission for the dog is the same 3.20 m footprint class as the cleared badger; I'll run the lead probe before it lands.
  - b20 rim on Trailpup, Nightburrow and Bramblebun: no visible gain, dropped. A texture-level accent comes next.
- 24 Oct GPU READY (candidate pick on CPU, b19; `close-1024/b19/judges.md`): value lift on tb/creatures 5d9b70894. Cindercub field_emission 0.8 (CPU 7.15 vs 6.88), Stormtrail 1.0 (6.77 vs 6.59), Riftfrill 1.0 (6.21 vs 6.03).
  - Capture, both arms at Medium and High:
    - candidate: `godot --path . --script res://tools/art_pipeline/capture_f36_poses.gd -- --species=cindercub,stormtrail,riftfrill --whole-body --context --out=res://.artifacts/gpu_b19/<preset>` at 5d9b70894;
    - shipping: the same command at main.
  - Cindercub is the one likely to close.
  - MESHY requests (owner said "tell me if it needs Meshy"):
    - Riftfrill: yes. The galaxy/starfield skin on the Paddlenewt mesh reads synthetic and illegible even lifted. Redraft as a naturalistic newt in Riftfrill's own palette, with a readable face and eyes and a lighter belly/value break.
    - Stormtrail: the recolour on Trailpup's mesh has hard yellow emissive leg bands that read as UV artefacts. Two options: (a) I drop the yellow emissive bands for a soft blue storm line along the spine, done as a data and texture edit here; (b) a Meshy storm-coyote with its own silhouette. I'll try (a) next unless you say (b).
- 24 Oct b18 (`close-1024/b18/judges.md`): no candidate beats shipping. Aquaryn's gentle shove 6.94 vs 7.08, Tidecoil's 7.03 vs 7.27, Mosshell's -90 faint 7.17 vs 7.31. All OFF; nothing to queue on GPU from b18.
  - Aquaryn and Tidecoil are parked on poses after two flat rounds (b17, b18).
  - MESHY request: naturalistic remakes of Aquaryn and Tidecoil that keep identity (fin crest, orange fin tips; serpent coil, pink fins) and restore the board's white belly and navy value break in place of the glossy single-value cyan. That is the judges' common ask, and it is new art.
  - Mosshell's model is rated at the bar. Two faint variants have lost (sprawl b16, -90 b18), so its faint is parked as well.
- 24 Oct owner direction received ("switch to GPU judging and split the rows"). From now on:
  - CPU batches only pick candidates.
  - Every candidate READY carries its exact GPU capture command, so you can queue it.
  - Rows count per unit: F36#0 per ledger asset, F36#1 per roster subject.
  - Working order: Aquaryn (7.49), water Mosshell (7.41), Mosshell (7.36), Tidecoil (7.45), Ripplet (7.26).
  - The CPU-provisional labels in close-1024 verdicts are now history, not closures.
- 24 Oct READY tb/creatures-land 5cecc01bd (= b67ec65dc + the admission probe you asked for).
  - `close-1024/admission/lead_probe_grown.txt`: smoke_arena_contain with the party lead swapped (headless). Cindercub at 3.25 m, Trailpup at 3.1 m and Stormtrail at 3.45 m each seat in the Warrens mouth (6.0 m ring; held to 3.2 m, 6.0 m and 6.0 m inside it) and the Hall elite room (7.0 m). Arena containment is OK on all three. No cap needed.
  - Scale answer (a) noted: Mudsnout, Paddlenewt and Riftfrill stay in the small class. Any further fix there is presentation (head line), not height.
  - b17 (`close-1024/b17/judges.md`): the recoil hit loses on Aquaryn and Tidecoil (6.95 vs 7.29 and 6.67 vs 7.04; it reads as idle), so the held shove stays. Next for them: swim stroke, curled Tidecoil faint, value break (art).
- 24 Oct Frostclaw "dark sphere at the trainer's feet" (GPU F36#1), investigated, no change shipped:
  - It is the tail tip itself: the installed mesh ends in a dark rounded lump of geometry and texture.
  - Separately, the installed skin weights every tail vertex to rear_upper_l and rear_lower_l; none go to tail_1 or tail_2.
  - I tried a byte-level weight-only rewrite (rig, clips and textures untouched; recipe sha updated). The lump stays, and in the hit the tail swings somewhere worse, so it was reverted.
  - The fix needs art. MESHY candidate: a Frostclaw tail-tip edit or remake (snow-leopard identity; long tapering tail, no terminal ball; tail skinned to the tail bones). Frostclaw's recipe is GPU-confirmed at 7.88 despite this.
- 24 Oct READY tb/creatures-land b67ec65dc (= c6985d7a9 + two commits).
  - F36#0 scale (GPU item 2): Trailpup 2.3 -> 3.1 m, Stormtrail 2.55 -> 3.45 m and Cindercub 2.5 -> 3.25 m, radius with height. No footprint warning; Warrens and Hall admission hold.
  - F36#1: Riverdrake's land form plays its recipe (b15: 6.80 vs 6.20; land only, since the lane keeps its pilot).
  - Galecrest and Stormraven recipes OFF (GPU judged worse), with `_why_gpu_1024_f36_1` recording the six GPU-confirmed species.
  - Checks:
    - Full suite on 15d18563a: 6964 tests, 2 failed. One was a local untracked candidate's texture import; the other is the scale ladder below.
    - After the fix: scale_ladder, texture_import_policy, species, rideable, dual_type, variant, evolution and companion pass (162 tests, 0 failed). Post-pass `--check` current.
    - Smokes, headless, with the larger growth applied (a superset of this one): arena OK, gate E passed, catching OK.
  - QUESTION, scale rule against the owner's 7 Sep 2026 ladder. The GPU judges read Mudsnout, Paddlenewt and Riftfrill at or below the ruler. They sit in the owner's "small class: just over the trainer" band (1.90-2.15 m, at least five species; `test_creature_scale_ladder`). Growing them empties the class to three, so they stay at 2.0, 2.15 and 2.15 m. Mudsnout would also be capped at 2.45 m by Warrens admission (2.6 m fails). Options:
    - (a) keep them, with the declared height still just over the trainer;
    - (b) owner revises the small class;
    - (c) grow other small species into the band.
    Your call or the owner's; I've not changed the test.
  - b16 (`close-1024/b16/judges.md`): the growth is neutral on CPU tiles, because each tile crops to creature plus trainer. The Mosshell sprawl faint lost (6.62 vs 6.74) and is OFF; the lane keeps only its scripts.
  - b15: the Tuskroot fresh re-check is 6.59, so its F36#1 pass is withdrawn (it stays ON). The water-Riptusk swim got one PRESENT. Riverdrake gains a pass. The roster now stands at 37 of 70.
  - Next: Aquaryn and Tidecoil (GPU 7.49 and 7.45; the notes only describe shipping, so I'll try hit variants). Then dark values (Stormtrail, Cindercub) and the Frostclaw dark sphere at the trainer's feet.
- 24 Oct READY tb/creatures-land c6985d7a9 (= 078a5f6c4 + Mirejaw fit + Pebbik remake ON + rig sources and raw files + Riptusk held OFF).
  - Checks:
    - Full `run_tests`: 6964 tests. 4 failed on cb8b86ca7, all Riptusk; after the hold the affected files (creature_rest_pose, four_biome_roster_population, species, f36_pose, water) pass, 540 tests, 0 failed.
    - Smokes: catching OK, gate E passed and arena containment OK (all headless: 369 s, 186 s, 106 s). Field brightness PASS, F37 Ripplet PASS and Bramblebun colourway 12/12 (xvfb).
    - Post-pass `--check` current. Footprint audit: zero shrink warnings.
    - Note: xvfb smokes now crawl here, because the Terrain3D height map loads after a re-import; headless runs avoid that.
  - Also on the lane, for the next land: 06beef397, `capture_f36_poses.gd --context` no longer stages a swim row for species that never swim (only water_* and swim mounts). That is your GPU item 1.
  - GPU F36#0 noted: Terrapup 7.64 and Burrowback 7.61 are GPU-confirmed. Next:
    - grow the five under-ruler species (Trailpup with Stormtrail, Mudsnout, Cindercub, Paddlenewt with Riftfrill), with footprint and admission checked;
    - lift values on the dark remakes;
    - work Mosshell, water Mosshell and Ripplet first.
- 24 Oct land update, now c6985d7a9 (not ready yet; this replaces the cb8b86ca7 entry below).
  - The full suite on cb8b86ca7 had 4 failures out of 6964, all about Riptusk:
    - test_four_biome_roster_population: water presentations must use the land species mesh.
    - test_creature_rest_pose x3: these sample Riptusk's recipe, and the remake stopped playing it.
  - So the Riptusk remake is held OFF on land and lane. It comes back once:
    - its water form moves to the same mesh and is judged;
    - the rest-pose tests sample a species that still plays its recipe.
  - Pebbik stays ON (b14, 7.16 vs 5.69). The rerun of the failing files gives 540 tests, 0 failed. smoke_arena_contain is OK.
  - Smokes on this box went about 10x slower after my b14 `--import`: the grass stone tier now gets a real Terrain3D height map; it was null before. It is no code regression: gate E is equally slow with the remakes unbound. catching and gate E are rerunning with the longest timeouts, and READY follows if both pass.
- 24 Oct reply to the b13 judge flag. The three b13 judges were independent. Each was a separate fresh general-purpose subagent, spawned by its own Agent call, and given one instruction: read `prompts/b13.txt` (the standard prompt naming only the blind judge folder) and open nothing else. None saw another's output or my context. Their raw scores differ elsewhere in the same batch: Zn A 6.2/6.5/6.5, Xc B 6.6/7.0/6.6, Rd A 6.2/5.6/5.9, Ml B 6.2/6.7/6.4. On the two tiles you flagged, all three gave Kp 5.6/6.8 and Rd B 6.8, so Tuskroot maps to 7.46 on every judge. That is a coincidence on common values, not shared context. I'll still put both tiles back in the next batch with fresh judges as an extra check.
  - Dates in close-1024 corrected from 25 to 24 Oct. The stale `--candidate-r13` line in roster/verdict.md is updated.
- 24 Oct land tb/creatures-land cb8b86ca7 = 078a5f6c4 + three changes:
  - water_mirejaw fit_candidate on. It renders at its declared 3.55 m; the all-species audit logs zero footprint-shrink warnings (`admission/footprint_audit.txt`).
  - Pebbik and Riptusk batch-4 remakes ON (b14: 7.16 vs 5.69, 7.81 vs 6.88 mapped; confirming batch; `b14/judges.md`).
  - Their rig sources and raw files.
  NOT READY YET. smoke_arena_contain passes (OK) but takes about 30 min on this box. The cause is not the b13 water ids: without them it is 1640 s, against 1802 s with them. My first 15-min timeout plus a full disk (now cleaned) cut the full suite and three smokes short. A rerun with long timeouts is in progress, and READY follows when it is clean.
- 24 Oct READY tb/creatures-land 078a5f6c4 (= 2a5300916 + three cherry-picks from the lane: roster r6-r7 and the whole-roster verdict, b13 ON flips with the verdict folder, the count fix). The b13 flips are data and post-pass only (enabled_species gains seven water_* ids; Tuskroot topples), so no mesh changed and there is no footprint risk. The land keeps water_riverdrake enabled. Checks: post-pass `--check` current; `run_tests --only=f36_pose,creature_pose,water,swim,species,dual_type,aspect,rideable,riding` 583 tests, 0 failed. Roster: 38 of 70 pass, so F36#1 is still open.
- 24 Oct F36#1 b13 (`close-1024/b13/judges.md`, CPU, confirming). Water forms now play their base recipe, which gives them a swim pose instead of the base-rig fallback.
  - ON: water Riptusk 7.46 vs 5.74, Abyssal Guardian 7.36 vs 5.36, Aquaryn 7.13 vs 5.46, Mangrove Monitor 6.94, Sirenseal 6.94, Tidecoil 6.89 (Tidecoil swim still marked PRESENT once).
  - ON below the bar: Mirejaw 5.89 vs 4.31.
  - ON: Tuskroot topple 7.46 vs 6.17.
  - OFF: water Cannonback 5.51 vs 6.03, and Mangrove Monitor -90 (5.84 vs 7.03). Its shipping faint reads as down here, so it now passes.
  - Roster after b13: 38 of 70 pass.
- 24 Oct ADMISSION: shipping water_mirejaw is silently scaled down 8% (3.28 m instead of its 3.55 m), same on the land head roster capture. `water_roster.json` already carries a disabled `fit_candidate` (footprint_allowance 5.21) "pending neutral visual review". I'm leaving it for your call.
- 24 Oct MESHY batch 4 measured. Mosshock c3 is 4.62x longer than tall (0.80 x 1.90 x 0.41 raw). At its 2.95 m installed height that is about 13.6 m nose to tail against the 5.3 m cap; fitting 5.3 m would mean 1.15 m tall, under the 1.80 m trainer. STOPPED as you asked; it is your call with the owner. Pebbik (1.64, about 5.3 m at 3.25 m) and Riptusk (1.68, about 7.1 m at 4.25 m) fit; rigging them now.
- 24 Oct MESHY batch 4 request: `close-1024/meshy-batch4/REQUEST.md` (Mosshock salamander redraft per your identity call, plus Pebbik and Riptusk, which fail F36#1 on material, not pose). Each has a drafted prompt, identity references, target height and max length inside its footprint allowance and the rings, no red or oxblood, and stays flag-off until judged. Deliver to `tb/meshy-1024` `assets_raw/naturalistic-1024/<species>_b4/`.
- 24 Oct F36#1 WHOLE-ROSTER VERDICT (`close-1024/roster/verdict.md`; r1-r7, 70 subjects, CPU, three judges, every batch confirming): **not met, 31 of 70 pass**. 24 fail on a pose (clip work here: b13 Mangrove Monitor/Tuskroot topples via `--candidate-r13`, now on the lane OFF; b14 enables the water_* recipes, of which 5 have no swim clip and play the base-rig fallback). 15 fail on score only (materials, F36#0 remakes; Meshy batch 4 covers three). r6: Cloudfang 7.28, Skyrill 7.14, Breezetail 7.10, Aeriex 7.07 and Cliffspike 6.86 pass. r7: only water_mosshell passes (7.32).
- 24 Oct 09:30 CT READY tb/creatures-land 2a5300916 (= c74eb3908 + your two tb/ev-coordinator merges + one commit).
  - **F36#1 fixes ON** (b12, CPU, 3 judges, confirming; `close-1024/b12/judges.md`). Base = the roster shipping tiles:
    - Bramblebun recoil hit: 8.02 vs 7.71.
    - Terrapup recoil hit + back-to-camera faint: 7.28 vs 7.02.
    - Ripplet sunk level swim: 7.49 vs 7.36.
    - Burrowback recoil + roll: 7.23 vs 6.93.
    - Bramblebun, Terrapup and Ripplet now pass F36#1 (no pose PRESENT). Burrowback keeps one "hit reads as a lunge".
    - Reverted (no gain): Paddlenewt flat faint, Torrentoad/Cannonback sprawl.
    - QUESTION: the Mosshock remake with the sprawl faint maps 7.15 vs 4.45 (faint FIXED x3), but judges read it as a toad while shipping Mosshock is a lizard. That's an identity change, so it is OFF until you say.
  - **Your nits:**
    - b11 verdict folder now on the land branch.
    - Admission probe at `close-1024/admission/lead_probe.txt`.
    - Cindercub out of LANDED_1024_BELOW_BAR and Ripplet out of LANDED_1024B_SHOVE (only those two profiles regenerate).
    - Ripplet's stale comments fixed.
    - `_field_bright_root` pruned together with the weak references.
    - Cindercub's 0.62 m footprint headroom noted for redrafts.
  - **Checks on 2a5300916** (local, CPU, after `--import`):
    - `run_tests --only=dual_type,aspect,variant,creature_body,texture_for,colourway,shiny,surface_finish,night,field,rideable,riding,swim,water,f36_pose,creature_pose,species,scale_ladder,companion,evolution,spawns,rest_pose,starter`: 879 tests, 0 failed.
    - Smokes: `smoke_arena_contain` OK; `smoke_gate_e_finale` passed; `smoke_catching` OK; `smoke_f37_ripplet` PASS; `smoke_creature_field_brightness` PASS; `smoke_bramblebun_colourway_binding` 12/12.
    - Postpass `--check` current; texture policy PASS (870).
- 24 Oct F36#1 whole-roster verdict, in progress: 50 of 70 subjects judged at the land head (`close-1024/roster/r1`-`r5/verdict.md`; rule: no pose PRESENT and mapped >= 6.7, CPU-provisional). r6-r7 (Voltwig onward and the water_* forms) are next.
  - Passing so far: Stormursa, Trailpup, Mudsnout, Meadowhart, Mosshell, Galecrest, Nightburrow, Veridian, Brooktail, Pipwing, Cindercub, Frostclaw, Shadelet, Staticub, Tidecoil, Sirenseal, Tanglevolt, Stormcapra, Craghorn, Thundertunnel, Stormraven, Glimmermoth. Bramblebun, Terrapup and Ripplet also pass with the b12 fixes in this READY.
  - Failing on poses (clip work next): Tuskroot (belly-up faint), Paddlenewt, Riftfrill, Mangrove Monitor (flips), Torrentoad, Cragclaw, Fulgocobra (upright faints), Pebbik (airborne hit), Cannonback (shell roll), and the installed land Riverdrake (hit equals standing; the held pilot fixes this).
  - Failing on score only (materials/style, F36#0 territory): Galewisp, Stormtrail, Duskhush, Reedwing, Ashtusk (6.68), Riptusk, Sparkit, Mirejaw, Voltwig, Abyssal Guardian, Mosshock, Stormbrush, Voltarach.
  - Judges' recurring asks: a recoil instead of rear-ups (most installed recipes), and stage staging (long tails pass through the ruler; capture-stage only).
  - Swim applicability: only the water_* forms and swim mounts. Base species of the water roster swim through their water form, so base-species swim rows in r2-r3 are informational.
- 24 Oct 01:40 CT READY tb/creatures-land c74eb3908 (= dbd0a12c6 + your tb/ev-coordinator merge + one commit). Your `_texture_for` .jpg fallback and its test are merged in, so the regression is not reintroduced (thanks for catching it).
  - **F36#0 b11** (CPU, three judges, confirming; `close-1024/b11/judges.md`):
    - New ON: Ripplet (starter, four-legged otter) 7.40 vs 5.51; Cindercub 7.63 vs 5.59.
    - Terrapup at 3.20 m re-judged 7.47 vs installed 5.59, which confirms the shrink.
    - OFF:
      - Staticub b2: 7.28, below the shipping 7.98 (the red-brown grade edges toward oxblood). The shipping cub stays for F29#3.
      - Sparkit b2: 5.20 vs 6.57. Judges also flag both versions as no taller than the trainer (1.95 m declared).
      - Mosshock: 6.73 vs 6.18, but its faint stays upright, and judges read the remake as a different creature (a warty toad vs the shipped lava salamander).
      - Stormbrush: 6.81 vs 6.73 (noise).
      - Torrentoad: 6.69, faint squats upright.
      - Cannonback: 6.49, shell flips onto its side.
      - Skyrill: 5.94.
  - **Integration:**
    - Ripplet's seat moves 1.45 -> 2.58 m on the measured 2.45 m back; on the pose stage the rider sits on the back.
    - Both remakes leave `enabled_species` (own clips).
    - Lead admission probe: both seat in the Warrens mouth, tether approach and Hall elite room (Ripplet 0.36 m spare in the elite room).
  - **Your nits:**
    - Terrapup seat comment updated.
    - Variants removed from LANDED_1024_BELOW_BAR (only their three profiles regenerate).
    - `_field_bright_derived` dedupes and prunes freed copies.
    - The F36 wiring sample moves to Frostclaw (Cindercub is a remake now).
  - **Checks on c74eb3908** (local, CPU): `run_tests --only=dual_type,aspect,variant,creature_body,texture_for,colourway,shiny,surface_finish,night,field,rideable,riding,swim,water,f36_pose,creature_pose,species,scale_ladder,companion,evolution,spawns,rest_pose,starter` gave 879 tests, 0 failed. `smoke_f37_ripplet` PASS; `smoke_arena_contain` OK; `smoke_creature_field_brightness` PASS; postpass `--check` current; texture policy PASS (870).
  - **Next:** the F36#1 whole-roster verdict (70 subjects at the land head, judged in batches with each applicable pose as a recorded defect); identity follow-ups (Trailpup mantle, Mudsnout moss); Bramblebun rim round; birds (Pipwing, Galewisp) need a weighted rig with all 11 roles.
- 24 Oct 23:55 CT READY tb/creatures-land dbd0a12c6 (= 928f6abfb + ead45a117 + dbd0a12c6). Carries the #717 variant fix and the Terrapup shrink.
  - **#717 suite 4 (test_dual_type):** Nightburrow, Stormtrail and Riftfrill now bind their bases' remake meshes (Burrowback, Trailpup, Paddlenewt) and 11-role clips, keeping their own height, colour and aspect VFX.
    - Their look is a repaint of the remake's own albedo plus a synthesised glow map on the new UVs. `generate_aspect_variant_textures.py` gains an optional `source_model`; `creature_body._texture_for()` reads `<albedo>_<variant>.png` and `<albedo>_emissive_<variant>.png` beside an import-extracted .jpg albedo; a remake material takes the glow the way native Ashtusk does.
    - On the pose stage they read as the variants: Stormtrail black with yellow lightning, Riftfrill violet, Nightburrow dark plates. Unjudged on the new meshes.
    - All three left `enabled_species` (they play the remake clips).
    - Flag: Riftfrill and Paddlenewt stand only about at the trainer's head (a low newt at 2.15 m declared). That scale question is for the judges; I have not grown them.
  - **Terrapup (owner 24 Oct: "Just shrink it"):** naturalistic pilot ON at 3.20 m (x0.831 from 3.85). Radius, seat (3.16 m, 0.08 m over the measured back) and dismount scaled by the same ratio. Recorded in `_comment_shrink_owner_1024`. Terrapup has no evolution line, so no ladder order changes. b1 judged it 7.62 at 3.85 m; it gets re-judged at 3.20 m in the next batch.
  - **Functional fix (pre-existing on main):** the night field-brightness scale never reached rimmed creatures (Galecrest, Tanglevolt, Voltarach stayed at daytime brightness all night). The rim and night-floor copies are now registered under the brightened material and rescaled with it. `smoke_creature_field_brightness` spawns Galecrest, so it covers that chain: it failed before the fix and passes after.
  - **Checks, local CPU after `--import`:** on ead45a117, `smoke_arena_contain` OK, `smoke_gate_e_finale` passed, `smoke_catching` OK, `smoke_creature_field_brightness` PASS. On dbd0a12c6, `run_tests --only=dual_type,aspect,variant,creature_body,colourway,shiny,surface_finish,night,field,species,spawns,f36_pose,creature_pose,rideable,riding,scale_ladder,water,roster` gave 710 tests, 0 failed. On ead45a117, a wider creature set gave 807, 0 failed. Postpass `--check` current; texture policy PASS (858 sidecars).
  - **Paddlenewt/Burrowback as party lead** (a copy of `smoke_arena_contain` with the lead swapped; uncommitted). Both pass all three cases. In the Hall elite room (ring 7.0 m, `stronghold_elite`) the reach after the fight opened is Paddlenewt 5.90 m (0.50 m spare with the 0.6 m clearance) and Burrowback 5.73 m (0.67 m spare). The Warrens mouth (6.0 m) admits both. After opening, their reach measures 5.99 m and 5.54 m: the bodies settle toward the ring after seating, but `hold_inside` keeps them in. Nothing changed for either.
  - **Follow-ups from your review:** Veridian's r6 comment is marked superseded. The F36 test header is accurate again (Terrapup ships its remake). Trailpup and Burrowback play their remake clips: their b2-b4 shove scores describe the old meshes and no longer what ships. The tall-grass capture for Bramblebun (done, b10: 7.20 vs 6.01), Mudsnout and Burrowback joins the next judged batch. Trailpup's green mantle and Mudsnout's moss are queued as identity follow-ups.
  - **Admission watch for pending remakes** (nose-to-tail at installed height): Skyrill 6.77 m, Stormbrush 5.88 m, Ripplet b3 5.73 m (starter; the cap came out wider than asked), Cannonback 5.40 m, Staticub b2 5.07 m. Before any lands I'll run the lead probe; the shrink OK covers only Terrapup, so I'll report any failure to you.
- 24 Oct 14:40 CT READY tb/creatures-land 928f6abfb (= 688c0dcc6 + one commit). Your sub-6.7 call is applied. The candidate had to beat shipping by at least 0.1 in a confirming batch, and no judge could mark its faint end PRESENT (per-judge verdicts re-read).
  - ON: Cindercub, Ashtusk (with its side topple), Nightburrow, Shadelet, Mosshock, Stormtrail, Riftfrill (b2-b4); Abyssal Guardian, Brooktail, Glimmermoth, Tempestwing, Ribbonray (b8-b9). Nightburrow, Riftfrill, Glimmermoth, Tempestwing and Ribbonray join `enabled_species`. Scores are in `_why_close1024_below_bar`.
  - Left OFF: a judge marked the faint PRESENT on Cragclaw, Skyrill, Mangrove Monitor, Cannonback, Torrentoad and Tuskroot. Duskhush gained only +0.05 (noise). Reedwing and Pipwing gained nothing.
  - The 12 changed profiles are byte-equal to their judged candidates. Postpass `--check` current. `run_tests --only=f36_pose,creature_pose,fly,riding,rideable,water,roster,species,creature_body`: 588 tests, 0 failed. The three #716 smokes are unaffected (pose data only).
- 24 Oct b10 (your note 2, Bramblebun in grass): pilot 7.20 vs the shipped redesign 6.01 mapped, from the grass-separation probe at throwing range (CPU, three judges, confirming; `close-1024/b10/judges.md`). Blend defect PARTIAL x3 on the pilot. A rim/value-lift round is next on tb/creatures, OFF until judged.
- 24 Oct 11:30 CT READY tb/creatures-land 688c0dcc6 (= 02e0d2476 + two commits). Replaces 250d4b42b/02e0d2476 for #716.
  - **The three #716 smokes, root cause:** the Terrapup pilot (starter in all three). Combat admission seats both fighters' bind-pose render boxes inside the room ring with 0.6 m clearance. At its fixed 3.85 m height the naturalistic Terrapup is 6.84 m nose to tail (installed mesh 3.07 m). Reproduced locally: the Warrens mouth (capacity 6.0 m) needs about 6.2 m for Terrapup vs remade Mudsnout ("could not engage the warrens wild creature"); the Hall elite room (7.0 m) refuses the seat (corner reach 7.17 m), so `defeated_stronghold_elite` never sets.
  - **Fix:** Terrapup pilot OFF on the land (installed model, rest offset and test pin back). Shrinking is forbidden, so the pilot waits for a compact redraft (MESHY batch 3 below). Riverdrake held OFF on the land as you asked. Both candidates stay on tb/creatures.
  - `smoke_creature_field_brightness`: Bramblebun and Mudsnout are both remakes with no field emission now. It spawns Terrapup (installed, emission 0.6, no degreen) for the live night rescale and neutral-hue checks. The ceiling guarantee stays as a check on the real `_apply_field_bright_values` at Bramblebun's shipped 2.5/0.75, 2.5/0 and a 12.0 push. Pass conditions unchanged.
  - **Results on 688c0dcc6** (local, CPU, after `--import`): `smoke_catching` OK, `smoke_arena_contain` OK, `smoke_gate_e_finale` passed, `smoke_creature_field_brightness` PASS, `smoke_bramblebun_colourway_binding` 12/12. `run_tests --only=f36_pose,creature_rest_pose,water_species_catalog,rideable_roster,species`: 32 tests, 984 assertions, 0 failed. Postpass `--check` current; `test_f36_pose_postpass.py` 8/8 OK.
  - **New in it:** F36#1 b8-b9 (CPU, 3 judges each, both confirming; `close-1024/b8`, `b9/judges.md`). Held shove live on Tanglevolt 7.99 vs 7.45, Stormcapra 7.63 vs 7.04, Solmane 7.31 vs 6.37, Ripplet 7.04 vs 6.73, Galecrest 7.01 vs 6.87, Aeriex 6.82 vs 6.21 and Galewisp 6.73 vs 6.16. Aeriex, Galecrest and Solmane join `enabled_species`. The 7 changed profiles are byte-equal to the judged candidates.
  - **Land content now:** Bramblebun, Mudsnout, Trailpup, Paddlenewt, Burrowback, Veridian, Mosshell (+water) remakes; 23 shove-hit recipes + 8 newly enabled; water catalog colourway-source fix.
- 24 Oct FINDING (pre-existing on main, not fixed here): the field-brightness night scale never reaches Galecrest or Tanglevolt. Their dressed surface is a field-bright material the registry does not hold: day = night = 1.626 / 1.6415 albedo, while Terrapup goes 1.413 -> 1.16. Owner of `creature_body.gd` field-bright registry, please route.
- 24 Oct MESHY: batch 3, two compact starters: `ralph/reports/CREATURES/close-1024/meshy-batch3/REQUEST.md`. Terrapup keeps the judged concept but nose-to-tail is capped at 1.2x height (4.6 m), which fits the Warrens pair with about 0.6 m spare. Ripplet gets a four-legged otter with the same cap.
- 24 Oct ack: your notes. Bramblebun tall-grass legibility capture goes in my next judged batch. Shiny/vivid colourways for the remakes, the unreferenced normal maps and the `tools/diag_*` paths are queued. Sub-6.7 improvements: per your answer I'll turn ON those that beat shipping in a confirming batch and pass faint/mount checks, scores in `_why`, in the next READY.
- 24 Oct 06:30 CT READY tb/creatures-land 02e0d2476 (= 250d4b42b + two commits): adds F36#0 Burrowback 7.23 vs 6.97 and Veridian 6.82 vs 6.56 (b6; seats re-fitted to the measured backs: Burrowback 2.603 -> 2.93 m inside its 2.95 m height, Veridian 2.771 -> 3.13 m; pose-stage ride row seats the rider on the back) and Mosshell land 7.31 vs 5.65 + water form 7.19 vs 5.86 (b7; level swim, shell 2.50 m at the unchanged 2.49 m water seat; mounted-swimming smoke on water_mosshell 19/19).
  - Checks on 02e0d2476: Godot `--only=mosshell,cannonback,water,roster,f36_pose,creature_pose,species,creature_body,scale_ladder,colourway,shiny,surface_finish,variant,texture_import_policy,companion,spawns,rest_pose,evolution,rideable,riding` 749 tests, 0 failed; the 73fb0ddbf step ran `--only=burrowback,veridian,nightburrow,retex,...` 729, 0 failed.
  - Whole land branch so far: Terrapup, Bramblebun, Mudsnout, Trailpup, Paddlenewt, Burrowback, Veridian, Mosshell (+water) remakes; Riverdrake pilot (+water); 16 shove-hit recipes + 5 newly enabled recipes; water catalog colourway-source fix.
- 24 Oct 04:10 CT READY tb/creatures-land 250d4b42b (= 337f81506 + one commit): F36#0 Mudsnout, Trailpup, Paddlenewt naturalistic remakes (your Meshy batch 1, thanks) and the Riverdrake pilot, land and water forms, ON.
  - b6 (CPU, 3 judges, confirming; `close-1024/b6/judges.md`): Trailpup 7.49 vs 6.50, Mudsnout 7.40 vs 5.61, Paddlenewt 6.88 vs 5.29, water Riverdrake 7.00 vs 6.36; land Riverdrake 7.29 vs 4.78 (b1).
  - Functional fix with test: `water_species_catalog.gd` forced every water presentation's colourway source to the board id, so a replacement water mesh wore the installed atlas on its own UVs. A presentation may now name its own source; `test_water_species_catalog.gd` checks only replacement meshes may.
  - Riverdrake water mount/saddle unchanged (pilot back about 2.49 m under the 2.739 m seat). `smoke_water_mounted_swimming.gd` restricted to water_riverdrake: 19/19 checks. NOTE: the unrestricted smoke fails at water_sirenseal ("rider art origin remains above sea") on origin/main data too, before it reaches Riverdrake; pre-existing, not touched here.
  - Checks on 250d4b42b: Godot `--only=mudsnout,trailpup,paddlenewt,riverdrake,terrapup,bramblebun,rest_pose,rideable,riding,f36_pose,creature_pose,species,creature_body,scale_ladder,colourway,shiny,surface_finish,variant,texture_import_policy,companion,water,roster,fly,meadowhart,spawns,saddle,bed,camp,evolution` 848 tests, 0 failed; postpass `--check` current; texture policy PASS.
  - Also passing in b6 but held for mount/faint work: Burrowback 7.23 (rideable seat), Mosshell 7.08 (faint stands; water swim mount), Veridian 6.82 (rideable seat). Losing, OFF: Sparkit 5.84, Staticub 7.11 (lost its storm veins, maroon drift), Mirejaw 6.42.
- 24 Oct MESHY: batch 2, ten more: `ralph/reports/CREATURES/close-1024/meshy-batch2/REQUEST.md` (Staticub juvenile WITH violet veins for F29#3, Sparkit, Pipwing single shell, Galewisp spread-wing starter, Mosshock, Skyrill, Stormbrush, Cindercub, Torrentoad, Cannonback). Same route as batch 1; branch `tb/meshy-1024` worked well, same again please.
- 24 Oct 01:40 CT READY tb/creatures-land 337f81506 (= 7773d93c5 Terrapup/Bramblebun pilots + one commit): F36#1 held shove hit live for 16 species and five more species on their recipe.
  - b2-b4 (CPU, 3 judges x 3 batches, standard prompt, confirming batches; `close-1024/b2/judges.md`): Craghorn 7.89, Cloudfang 7.82, Breezetail 7.73, Stormraven 7.47, Tidecoil 7.43, Burrowback 7.34, Frostclaw 7.34, Aquaryn 7.29, Thundertunnel 7.22, Cliffspike 7.16, Pebbik 7.09, Trailpup 7.08, Voltwig 7.04, Stormbrush 6.97, Sirenseal 6.97, Riptusk 6.79 mapped, each above shipping. b3 (Aquaryn, Tidecoil, Voltwig, Sirenseal, Riptusk) carries an anchor-RMSE 0.83 caveat.
  - The regenerated `f36_pose_candidates.json` changes exactly those 16 profiles, each byte-equal to its judged candidate; Aquaryn/Tidecoil/Breezetail/Craghorn/Stormraven join `enabled_species`.
  - Checks on 337f81506: Godot `--only=f36_pose,creature_pose,creature_body,species,scale_ladder,water,roster,fly,riding,rideable,terrapup,bramblebun,rest_pose,texture_import_policy` 617 tests, 0 failed; `test_f36_pose_postpass.py` 8/8 OK (tear guard); postpass `--check` current.
  - GPU confirm: `capture_f36_poses.gd --candidate --whole-body --context --species=<the 16>`.
- 24 Oct QUESTION (your call, as on 22 Oct): these beat shipping but sit under 6.7 mapped, all OFF: Cindercub 6.67, Cragclaw 6.65, Skyrill 6.62, Ashtusk 6.57, Nightburrow 6.52 (+1.03), Shadelet 6.52, Mangrove Monitor 6.51, Cannonback 6.44, Mosshock 6.13, Mudsnout 6.00, Tuskroot 5.95, Stormtrail 5.75, Riftfrill 5.18. ON for the wind-down, or keep OFF? I'll keep iterating their faints meanwhile.
- 23 Oct 23:59 CT READY tb/creatures-land 7773d93c5 (origin/main 5f1f388cc + one commit): F36#0 Terrapup (starter) and Bramblebun naturalistic pilots ON.
  - b1 (CPU, three judges, standard prompt, confirming batch; `close-1024/b1/`): Terrapup 7.62 vs live 5.30, Bramblebun 7.57 vs live 4.59 mapped. Both clear 7.5 even on CPU; recorded as CPU-provisional until a GPU pass.
  - Integration: Terrapup seat 3.264 -> 3.80 m on the measured plated back, rest offset 1.0302 -> 0 (pilot rest clip grounded, 0.79 height ratio), out of `enabled_species`; Bramblebun lift/degreen off. Provenance jsonl + drafted concept beside each rig. Textures mode 2.
  - Checks on 7773d93c5: Godot `--only=terrapup,bramblebun,rest_pose,rideable,riding,f36_pose,creature_pose,species,creature_body,scale_ladder,colourway,shiny,surface_finish,variant,texture_import_policy,companion,water,roster,fly,meadowhart,spawns,saddle,bed,camp` 806 tests, 0 failed; `smoke_bramblebun_colourway_binding.gd` 12/12; postpass `--check` current; texture policy PASS.
  - Test changes follow the shipped model: F36 wiring sample Terrapup -> Trailpup; rest offset pin 1.0302 -> 0; Bramblebun UV smoke reads the shipped GLB.
  - Known: `tools/_capture_riding.gd --species=terrapup` fails identically on main (Meadowhart-only leg/boot fit; mount fades from its camera), so the seat was checked on the pose stage's ride row. No authored shiny/alpha for the pilot UVs (fallback path, as Meadowhart).
  - GPU confirm: `capture_f36_poses.gd --whole-body --context --species=terrapup,bramblebun` (no `--candidate`).
- 23 Oct (b1) Riverdrake pilot 7.29 vs live 4.78 (>= 6.7 CPU). Held on tb/creatures: `water_riverdrake` binds its own model (water_roster/water_mounts), so land and water forms move together after a water-mount re-measure.
- 23 Oct MESHY: batch 1, ten naturalistic remakes (starters/main path first): `ralph/reports/CREATURES/close-1024/meshy-batch1/REQUEST.md` (identity refs, target heights, prompts; same route as the Meadowhart nat-v1 pilot).

## Status by row (24 Oct)
- F36#0 (30-row ledger + owner style direction): ON this lane on CPU-provisional judged rounds: Terrapup 7.62, Bramblebun 7.57, Trailpup 7.49, Mudsnout 7.40, Mosshell 7.31 (+water 7.19), Riverdrake 7.29 (+water 7.00), Burrowback 7.23, Paddlenewt 6.88, Veridian 6.82. Open: starters Ripplet (nat-v1 GLB; sitter rig weights lopsided) and Galewisp (batch 2 spread-wing redraft); Sparkit, Staticub, Mirejaw, Pipwing remakes lost (batch 2 redrafts); the six NPC faces (coordinator-owned identity-preserving face regeneration, ledger rows 26-30, unchanged here).
- F36#1: b2-b4 judged 31 species on hit/faint; 16 held-shove recipes and 5 newly enabled species ON (all >= 6.7, above shipping). 13 below-bar improvements listed for your call. The second half (15 species incl. birds) is being captured now (`--candidate-1024b`).
- F29#3: Stormursa ships its b13 state (held shove hit, 5.00 m): CPU-provisional 7.54 mapped (close-1022 b13, confirming batch), so >= 6.7 on CPU; the GPU 7.00 was the older 4.10 m / no-shove state. A GPU pass on the current head is needed to confirm 7.5. Cub/adult read improves with the batch-2 Staticub juvenile (veins kept).

## Worklist
1. F36#0: judge the archived Terrapup, Bramblebun and Riverdrake naturalistic pilots against live (restored from `tb/archive-2026-10-23^4`, OFF); rig Ripplet and Galewisp nat-v1 GLBs.
2. F36#1: full shipping pose matrix (58 species) captured, ranked, worst faints fixed (Fulgocobra faint end rears up).
3. F29#3: Staticub juvenile remake (batch 1) for the cub/adult read; Stormursa eyes, veins, rim.
