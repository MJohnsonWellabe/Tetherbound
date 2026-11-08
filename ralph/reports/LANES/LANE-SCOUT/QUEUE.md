# LANE-SCOUT queue refresh (8 Nov 2026)

Evidence, not a plan. Each entry checks whether the judges' last complaint for a row still holds in today's game, so the build lane only takes rows whose defect is real, visible and fixable.

- Source: `origin/main` c502453d43963728eb3e75028b2c4a68756805c0, imported fresh in this container.
- Captures: CPU, Mesa llvmpipe, xvfb, Compatibility, Low, 1280x720, seed 2042. Each frame uses the row's `job.json` repro through `quick_judge.py capture` with no overlay (live base only), or the tool named in the entry. No judge rounds were run. Frames stay local; only the contact sheets are committed.
- "Last score" is the coordinator board's figure. The judges' quote comes from the newest score file named in the entry (the 28 Oct GPU notes are `ralph/reports/VISUAL/item-scores/<biome>/scores-gpu.json`).
- Fix classes: config / scene placement / installed-asset swap / Blender art / code / capture-stand bug / owner decision / GPU-only.
- Gain guesses are against the row's own frames only.

## Best candidates so far

Ranked by expected visible gain per hour of build. Updated after each batch.

| # | Row | Fix idea | Fix class | Gain |
|---|---|---|---|---|
| 1 | F41#2 Surge phases | Building darker/cooler than Calm, Break darkest with the strongest bolts and a ground flash, Fading lighter than Break (today Fading has the biggest bolts) | config | medium-high |
| 2 | F41#10 Glass Sink | Replace the flat navy sink plane (half of every frame) with a dark fused-glass material; scatter installed glass spikes down the slope from the ring to the edge; seat the ring | config/material + scene | medium-high |
| 3 | F41#16 Hollows loss | GPU re-shoot on the corrected loss stand (old score judged a win frame) | GPU-only | possibly high |
| 4 | F38#35 post poses | Per-NPC role idles from installed clips (Rig_Medium_General: Idle_B, Interact, Use_Item); props already present | installed-asset swap | medium |
| 5 | F41#5 forest distance | Mid-distance tree clusters 60–150 m out at the three open stands; cut the mirror flood-plane reflection | scene + config | medium |
| 6 | F40#14 map label | Capture-stand: shoot the map with Gate/Lower Cliffs surveyed (today 0% surveyed, nothing to judge); widen the "You are here" box | capture-stand + config | medium |
| 7 | F39#9 catch camera | Capture-stand: absorbing/resting frames show the post-breakout card because the throw is at 0%; weaken first. Hide the ghost chance chip on throw | capture-stand + config | medium |
| 8 | F41#1 Stormheart | Vary the four identical royal-blue banners (size, spacing, muted storm blue); move the lattice pylon out of the approach sightline | config + scene | medium |
| 9 | F41#4 destinations | Move one Lantern Pool to the path edge facing the camera, teal water, two lit lantern posts at its rim | scene | medium |
| 10 | F41#21 Hollows reward | GPU arm `hud.json victory_focus` (OFF, never judged) | GPU-only | medium |

Watch: `lantern_hollow__night__close` (F41#12) records hour 23 but renders daylit under the canopy. Check on GPU; if it holds, Stormwood night under canopy is a bigger defect than the road line.

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

## Batch 1: below 6, non-fight rows (captured 8 Nov 13:27–14:26 UTC)

Frames: `quick_judge.py capture <rows>` on c502453d (tree dee9ffb29696), CPU Low/Compatibility 1920x1080 per each repro. Logs grep clean for `stale`.

### F39#9 P2-113 catch camera distance (Tidewake)
- Last: 5.13 GPU (28 Oct, old nearest-wild capture); CPU 6.54 on the pinned capture (VIS-TIDEWAKE qj/c9, 8 Nov 02:30).
- Judges: "strike/absorbing frames pulled so far out that trainer, creatures and orb are specks on a flat featureless sand plane" (`tidewake/scores-gpu.json`).
- Still true? **No** for the specks: today's pinned First Shore capture keeps trainer, Terrapup and the Mangrove Monitor at mid distance in 02-orb-in-flight and 03-strike (orb visible at the monitor's chest), and 03-absorbing is a closer three-quarter view with nothing cropped.
- What the frames show instead:
  - **Capture-stand bug:** 03-absorbing, 04-orb-resting, 05-orb-shakes and 06-breakout all show the same post-breakout state with the "Mangrove Monitor broke free / Weaken it more" card. The throw happens at 0% capture chance (full health), so the orb breaks out at once and no absorbing or resting moment exists to judge.
  - **HUD ghost:** in 02 and 03 a fading "0% CAPTURE CHANCE" chip plus its reticle ring hang over the sea at upper left, half transparent, with the label doubled over itself.
- Fix class: capture-stand bug (weaken before the throw so the stand reaches absorbing/resting), then config/code (hide the chance chip on throw).
- Fix idea: give the catch tool's absorbing/resting moments a weakened target (the 07-aiming-weakened state already reaches 100%), then re-judge on GPU; separately clear the chance chip the frame the orb leaves the hand.
- Expected gain: medium (the "specks" defect is gone; what judges will see next is a wrong-state frame and a ghost chip, both cheap).

### F39#23 P2-114 catch chance HUD contrast (Tidewake)
- Last: 5.62 (board); GPU 5.37 (28 Oct).
- Judges: "the capture-chance text is dark, unbacked and lost against pale sand and the creatures" (`tidewake/scores-gpu.json`).
- Still true? **No.** In catch_low, catch_high, 01-aiming and 07-aiming-weakened the chip is a dark navy plate with large orange (0%), gold (48%) or green (100%) numerals and a white label, beside the target, readable at a glance.
- Remaining: the bottom-right "Throw / Cancel / Orb x20" prompts are small, thin and low contrast on sand; in 07 the previous "broke free" card still covers the top centre while aiming.
- Fix class: config (prompt size/plate) / GPU-only re-baseline.
- Fix idea: GPU re-score first. If needed, put the throw prompts on the same navy plate.
- Expected gain: low (defect already fixed; the old score predates the plate).

### F41#5 P2-039 forest ground and distance layers (Stormwood)
- Last: 5.35 (board); GPU 5.24 (28 Oct).
- Judges: "one even dark-green leaf carpet runs to a flat horizon, with sparse isolated trunks and a pale stone tower in frame 2 against flat lilac haze, so it has no forest walls, groves or layered distance" (`stormwood/scores-gpu.json`).
- Still true? **Partly.** The Deepwood stands (Lantern Hollow, Fallen Giant) now have real forest walls: dense trunks on both sides and a canopy. The open stands (Struck Sentinel approach, Crown Overlook, Crown Heartstone) still run to a single flat distance layer: one dark-purple cut-out treeline band (Sentinel) or one pale grey strip like a painted wall (Heartstone, Overlook), under flat lilac sky, with nothing between it and the near trees.
- Also in frame: the moss ground repeats as the same dark blotch tile everywhere; at Crown Heartstone and the Glass Field a dark mirror-like flood plane covers the ground around the trainer (strong sky reflections), which reads as a black pool rather than wet ground.
- Fix class: scene placement (mid-distance tree masses) plus config (fog/haze steps, wet-ground reflection strength).
- Fix idea: one mid-distance band of installed Stormwood tree clusters 60–150 m out at the three open stands, so the eye steps near trees → grove → haze → ridge; and cut the flood-plane reflection so wet ground stays dark green.
- Expected gain: medium (two of three judged frames are open stands; the forest-wall half of the defect is already fixed).

### F41#12 P2-040 charged road surface (Stormwood)
- Last: 5.63 (board, GPU).
- Judges: "one thin wandering gold line on a flat brown path, but the 'charge' is still a gold decal rather than white-violet lightning or wet glints" (`stormwood/scores-gpu.json`).
- Still true? **Yes.** Every road frame today (Sentinel approach, Lantern Hollow, Lantern Pools, Crown Overlook, Glass Field, Dynamo Core) shows the same: a flat dark-brown road with one thin gold wandering line and scattered white pebbles.
- Fix class: config (road charge colour/emission) or code (glint pass).
- Fix idea: recolour the charge line white-violet with a brighter core and break it into short forked segments; add sparse wet glints on the road. Must stay subtle (owner: no big floating effects).
- Expected gain: low-medium (a thin line is a small share of the frame; the road's flat brown is the bigger area).

### F41#4 P2-038 named destination identities (Stormwood)
- Last: 5.92 (board); GPU 4.54.
- Judges: "the Lantern Pools frame is still a dirt path through grass with no pool or lantern" (`stormwood/scores-gpu.json`).
- Still true? **Partly.** Lantern Pools now has two small stone-rimmed grey pools with wooden posts left of the path, but they are small, flat grey and pushed to the left third; no lantern glow reads. Crown Overlook shows a white crystal spire on the horizon; the Fallen Giant root mass fills the right of its frame.
- Fix class: scene placement.
- Fix idea: move one pool to the path edge facing the camera, darken its water to the glowmoss teal, and stand two lit lantern posts at its rim (installed lantern posts).
- Expected gain: medium (the defect is about one of three frames; that frame changes from "path" to "place").

### F41#1 P2-037 Stormheart finale (Stormwood)
- Last: 5.24 CPU (`ITEM-F41-1/READY.md`, root vault ON).
- Judges' remaining asks (that READY): no glowing lightning core; lightning drawn as flat white strokes; blotchy over-saturated moss floor with a hard black pool; flat saturated-blue banners all the same size and evenly spaced.
- Still true today? **Yes**, all four, in Stormheart Tree close and Dynamo Core close: four identical royal-blue square banners with a lightning glyph hang at equal spacing along the deck rail; two white zigzag stroke pairs drop through the middle of the frame; the floor is the bright blotchy moss. On the approach stand a black-and-gold lattice pylon (Meshy) stands right in front of the trainer and blocks the view into the hollow.
- Fix class: config (banner colour, size and spacing variation) and scene placement (move the pylon off the approach sightline).
- Fix idea: vary the banners (two sizes, uneven spacing, a muted storm-blue that is not saturated royal blue) and move the lattice pylon out of the approach line.
- Expected gain: medium (the banners and strokes sit in the frame centre in two of three frames).

### F41#23 The hero landmark (the Stormheart tree) reads at distance and up close (unscored)
- No score yet.
- Today: every Stormheart stand in the catalogue (approach, close, Dynamo Core) is **inside** the hollow under the root deck, so none shows the tree from outside. The "reads at distance" half cannot be judged from these stands. The F41 matrix stormheart stand (batch 2) is the only outside view in the queue; see there.
- Fix class: capture-stand (needs an outside far stand) before any art.
- Expected gain: can't tell.

### F41#10 P2-070 Glass Sink landmark (Stormwood)
- Last: 5.36 (board); GPU 3.19 (28 Oct).
- Judges: "the trainer still stands on a bare tiled-moss ridge between pale lavender sheets that read as fog walls rather than a glass basin, with no rim marker, copper or black pool" (`stormwood/scores-gpu.json`).
- Still true? **Partly.** A rim marker and copper now exist: a pale stone ring bound with copper bands, packed with blue glass spikes and a twisted copper rod, sits on the ridge, with a second ring further along. The pale lavender fog sheets are gone. But:
  - the "sink" itself is a flat, untextured navy plane filling the right half of all three frames, ending in a straight cliff edge; it reads as a void or a flat lake, not a glass basin;
  - the ring reads as a stone well or tub (pale cartoon blocks), and in the close frame its base edge sits above the dark ground, so it looks unseated;
  - the ridge is the same blotchy moss tile.
- Fix class: config/material (give the sink plane a glass material: dark glossy with crack lines and faint teal glints) and scene placement (seat the ring; add glass shards on the slope down into the sink).
- Fix idea: replace the sink's flat navy fill with a dark fused-glass material and scatter installed glass-spike pieces down the slope from the ring to the sink edge, so the eye reads rim → slope → glass floor.
- Expected gain: medium-high (the flat navy plane is half of every frame; the earlier fixes already added the rim).

(F41#12 extra) The `lantern_hollow__night__close` frame records hour 23.01 (night requested and observed) but renders at full daylight brightness under the canopy: no darkness, no lantern pools of light. Either Stormwood's night look does not reach the Deepwood canopy, or it is a CPU-Low effect. **Check on the GPU before any road work**: if it holds there, the night frame is a bigger defect than the road line.

### F41#2 P2-042 Surge phase presentation (Stormwood)
- Last: 5.80 (board); GPU 5.69.
- Judges: "Break now has visible white-violet lightning bolts in the sky, but Calm and Building are near-identical frames (only slightly denser rain), so the storm phase does not read" (`stormwood/scores-gpu.json`).
- Still true? **Yes.** Struck Sentinel close, today: Calm and Building differ only by a little more rain; sky colour, cloud, ground light and grade are the same. Break adds two thin bolts in the sky but the ground stays as bright as Calm. Fading (not judged) shows **bigger** bolts than Break, so the peak reads in the wrong phase.
- Also in frame: the companion stands directly behind the trainer, so the two read as one stacked figure in the centre of all four frames.
- Fix class: config (per-phase sky, light energy and grade in the storm-phase presentation).
- Fix idea: make Building visibly darker and cooler than Calm (lower sun energy, darker sky top, heavier cloud), make Break the darkest with the strongest bolts and a brief ground flash, and make Fading lighter with fewer bolts than Break.
- Expected gain: medium-high (the judged defect is exactly "the phases look the same", and it is a config-scale change across three frames).

### F40#14 P2-048 Cloudreach map region label (Cloudreach)
- Last: 5.87 (board, GPU; 3/3 FIXED).
- Judges: "No truncated label is visible, but no region label appears at all: the map is an almost entirely fogged blue cloud field with one revealed square, so the subject cannot be confirmed" (`cloudreach/scores-gpu.json`).
- Still true? **Yes.** `cloudreach__menu_map` today: header "Surveyed: 0%", the map panel is all blue fog with one revealed square and the player marker; no region name sits on the map. The "You are here: Cloudreach Gate / Lower Cliffs" line now wraps instead of truncating, but it breaks between "Lower" and "Cliffs". The controls row also wraps ("View / Meadows") and uses keyboard glyphs.
- Cause: **capture-stand bug.** The capture opens the map on a fresh Cloudreach fixture with nothing surveyed, so the subject (a region label on the map) never appears.
- Fix class: capture-stand (fixture with part of Cloudreach surveyed), then config (label box width).
- Fix idea: shoot the map after the existing fixture reveals the Gate and Lower Cliffs cells, so their labels draw on the map; widen the "You are here" text box so the place name stays on one line.
- Expected gain: medium (the frame changes from an empty fog panel to a labelled map; the defect itself is already fixed).

### F38#35 P2-050 human post poses (Meadows)
- Last: 5.88 (board, GPU).
- Judges: "Oskar, Halda and Lark all stand in the same arms-down idle on bare dirt with no role prop or gesture, small in frame, so the posts read as placeholder NPC spawns" (`meadows/scores-gpu.json`).
- Still true? **Partly.** The posts now have props: Halda stands at a tournament booth with an awning and a bracket board, Lark beside a path signpost, Oskar by a bench on the village road. But all three still stand in the identical straight arms-down idle, and in the wide frames the trainer stands right beside each NPC (Oskar, Halda) so the two read as one small pair in the middle distance. The dialogue close-ups look good.
- Fix class: installed-asset swap (per-NPC idle clip) / config.
- Fix idea: give each post NPC a role idle from clips already installed in `assets/characters/Rig_Medium_General.glb` (Idle_B, Interact, Use_Item; check which NPC rigs share it): Halda Interact at the board, Lark Idle_B with a hand on the signpost, Oskar Use_Item. No new art.
- Expected gain: medium (the defect is the pose, it is in all three judged frames, and the props are already there to sell it).
