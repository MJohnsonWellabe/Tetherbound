# LANE-SCOUT queue refresh (8 Nov 2026)

Evidence, not a plan. Each entry checks whether the judges' last complaint for a row still holds in today's game, so the build lane only takes rows whose defect is real, visible and fixable.

- Source: `origin/main` c502453d43963728eb3e75028b2c4a68756805c0, imported fresh in this container.
- Captures: CPU, Mesa llvmpipe, xvfb, Compatibility, Low, 1280x720, seed 2042. Each frame uses the row's `job.json` repro through `quick_judge.py capture` with no overlay (live base only), or the tool named in the entry. No judge rounds were run. Frames stay local; only the contact sheets are committed.
- "Last score" is the coordinator board's figure. The judges' quote comes from the newest score file named in the entry (the 28 Oct GPU notes are `ralph/reports/VISUAL/item-scores/<biome>/scores-gpu.json`).
- Fix classes: config / scene placement / installed-asset swap / Blender art / code / capture-stand bug / owner decision / GPU-only.
- Gain guesses are against the row's own frames only.

## Best candidates so far

Ranked by expected visible gain per hour of build. Updated after each batch.

(filled after batch 1)

## Batch 0: rows already diagnosed today (cited, not re-captured)

These rows have a 7–8 Nov ITEM READY with a current-frame diagnosis. Re-capturing would repeat it.

| Row | Last | Today's diagnosis | Still true? | Fix class | Next idea from the READY | Gain |
|---|---|---|---|---|---|---|
| F38#24 P2-014 distant mountains / F38#30 P2-012 Warrens hillside | 3.51 CPU | `ITEM-F38-30/READY.md`, `ITEM-F38-30B/READY.md`, `ITEM-P2-014/READY.md`, `ITEM-F38-30-STANDS/READY.md` | Partly. walk_03 was a stand inside the solid Bank (capture-stand bug, fixed by `inside_collision_reseat`, ON); the remaining look is the 247 m Meshy shell overhanging meadow with the Bank's steep faces hidden. | owner decision, then Blender art | Owner picks either moving five front/east ring items 10–20 m out (then a smoothed mound with rebuilt collision fits) or keeping steep walls with a hand-modelled dug face. A GPU re-score of the re-seated stands comes first: the 3.51 was measured on the buried stand. | medium (after the re-seat; unknown until re-scored) |
| F39#15 P2-026 Veilfall approach shallows | 4.85 | STATE §0 "Blocked" | can't tell (blocked) | owner decision | Terrain re-bake plus route re-proof. Skip. | – |
| F41#21 P2-111 Hollows victory reward tiles | 4.92 | `ITEM-F41-16/READY.md` (GPU list) | can't tell on CPU (41 min wall for 45 s of fight) | GPU-only | Judge `hud.json victory_focus` (OFF, never judged) as a GPU arm on the hollows_win 99-after and hollows_aftermath stands. | medium |
| F41#16 P2-110 Hollows loss result clarity | 5.05 | `ITEM-F41-16/READY.md` | no: the "loss" frames were a capture-stand bug (they shot a win). Fixed in job.json. | capture-stand bug (fixed) / GPU-only | GPU re-shoot on the corrected loss stand; `loss_card` is ON. | unknown, possibly high (old score judged the wrong state) |
| F41#19 P2-043 Glass Field spike bases | 5.22 | `ITEM-F41-19/READY.md` | partly: the flat dark base is gone (rock collars, Meshy spikes); the frame's defect is now the trainer standing inside a non-colliding cluster at walk_03 | owner decision (glass field is non-colliding by test contract) | Art or placement that keeps spikes and collar stones off walkable stand areas; colliders rejected by test contract. | low |
| F41#1 P2-037 Stormheart finale | 5.24 CPU | `ITEM-F41-1/READY.md` | yes (root vault ON, 4.75 -> 5.24) | Blender art / scene | Floor material (largest area in all three frames: blotchy over-saturated moss, hard black pool), then a deep-blue, mostly unlit crystal core inside the 18–27 m band. | medium |
| F39#31 Veilfall at distance and up close / F39#2 P2-010 Veilfall silhouette | 5.32 / 5.78 | `ITEM-F39-31/READY.md` | yes (two Blender far-hero rounds lost) | scene placement on the existing kitbash | Keep the shipping crag; add green ledges or tree clusters on its upper shelves, two more broad continuous veils beside the main fall, and base spray/mist. Reaches F39#31's near stands too. | medium |
| F38#19 P2-004 exploration HUD | 5.69 | `ITEM-F38-19/READY.md` (settled stand 6.58 CPU) | partly: the old score was a stand under the opening fade (capture-stand bug, fixed) | capture-stand / config | Put the stand on the gamepad glyph path so prompts read controller-first; quest-box border into the panel family. | low-medium |
| F39#19 P2-088 fight roster contrast | 5.78 | `ITEM-F39-19-ROSTER/READY.md` | no: the roster no longer fades (opaque rows, TEAM 5/5) | GPU-only re-baseline | If "rows are tiny" holds on GPU: tunable row height plus names. | low |
| F36#29 Innkeeper body model | 5.83 | `ITEM-F36-29/READY.md` | yes | Blender art | Texture pass on the innkeeper atlas, face and eyes only, keeping the warmer value range. Grade approach failed twice. | low-medium |
| F41#8 P2-055 named character silhouettes | 5.83 CPU | `ITEM-F41-8/READY.md` | yes (one body for three roles) | Blender art | Distinct bodies, headwear and held props per role from installed parts. | medium |
| F40#1 P2-021 open terrain | 5.86 | `ITEM-F40-1/READY.md` | yes | parked (strata family failed twice) | Needs a new idea; strata terraces read as "slabs pasted on grass". | low |
| F36#70 Sparkit poses | 6.03 | `ITEM-F36-70/READY.md` (land, legs thickened) | partly | Blender art | Thicken upper legs (HIP ~0.62); eye and arc emission coat flag. | low-medium |
| F41#14 P2-045 candy pickup tiers | 6.04 CPU | `ITEM-F41-14/READY.md` (land) | partly | config | Tint or hide the shared crest/wing parts for Good and Great; height_mult 1.0 / 1.35 / 1.7. | low |
| F38#28 P2-064 Warden arena boundary | 6.09 | `ITEM-F38-28/READY.md` (parked, two flat rounds) | partly (thick rails gone) | Blender/scene | Grounded stone-curb ring from the installed Hall stone kit. | low |
| F39#17 P2-067 current restoration environment | 6.09 | `ITEM-F39-17/READY.md` (parked) | yes | scene placement | Restored-state pass tied to `water_currents_restored`: water colour, foam lines, sandbars and props. | medium |
| F40#2 P2-022 summit aviary | 6.16 | `ITEM-F40-2/READY.md` (parked) | yes | – | See READY. | low |
| F40#4 P2-023 exposed landform edges | 6.27 | `ITEM-F40-4/READY.md` (parked) | partly | – | Break the remaining straight shelf lips. | low |
| F39#8 P2-108 Aquaryn mounted-water pose | 6.38 | `ITEM-F39-8/READY.md` (land) | partly | – | See READY. | low |
| F41#9 P2-046 harvest resource identity | 5.65 | `ITEM-F41-9/READY.md` (land, three rounds ON) | partly | – | GPU re-score first. | low |
