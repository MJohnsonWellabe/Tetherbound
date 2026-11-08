# LANE-SCOUT queue refresh (8 Nov 2026)

Evidence, not a plan. Each entry checks whether the judges' last complaint for a row still holds in today's game, so the build lane only takes rows whose defect is real, visible and fixable.

- Source: `origin/main` c502453d43963728eb3e75028b2c4a68756805c0, imported fresh in this container.
- Captures: CPU, Mesa llvmpipe, xvfb, Compatibility, Low, 1280x720, seed 2042. Each frame uses the row's `job.json` repro through `quick_judge.py capture` with no overlay (live base only), or the tool named in the entry. No judge rounds were run. Frames stay local; only the contact sheets are committed.
- "Last score" is the coordinator board's figure. The judges' quote comes from the newest score file named in the entry (the 28 Oct GPU notes are `ralph/reports/VISUAL/item-scores/<biome>/scores-gpu.json`).
- Fix classes: config / scene placement / installed-asset swap / Blender art / code / capture-stand bug / owner decision / GPU-only.
- Gain guesses are against the row's own frames only.

## Best candidates so far

Ranked by expected visible gain per hour of build. Updated after batch 6 (8 Nov 21:10 UTC). From batch 6 on, messages to the coordinator were refused (untrusted device), so this table is the channel.

**Build rows (defect real, visible and fixable today):**

| # | Row | Fix idea | Fix class | Gain |
|---|---|---|---|---|
| 1 | F41#2 + F41#22 Surge phases | Calm, Building and Surge are the same frame at every stand. Building darker/cooler than Calm, Break darkest with a ground flash, Fading lighter than Break (today Fading has the biggest bolts). One fix serves both rows | config | medium-high |
| 2 | F41#18 Tether uniforms | Officers are no longer dark but carry no faction mark: a Team Tether oxblood sash/collar accent (appearance variant, same mesh; red is Tether-reserved) | config + recolour | medium-high |
| 3 | F41#10 Glass Sink | Half of every frame is a flat untextured navy plane: dark fused-glass material, glass spikes down the slope, seat the ring | config/material + scene | medium-high |
| 4 | F41#20 dialogue reuse | Fenn and Oswin share model and portrait image: recolour Oswin plus portrait (the F41#8 recipe) | config + recolour | medium |
| 5 | F41#24 cleanliness | A flat pinkish-mauve square quad on the ground at the matrix giant stand: find and remove; mushroom caps render as flat cream discs | scene | medium |
| 6 | F39#6 faint state | Aquaryn's fainted body floats half a body-height above the sand, shadow detached: ground its faint end pose | animation/config | medium |
| 7 | F38#27 settings | Bindings list shows 3–5 rows above a tall empty band: let it fill the panel; glyphs for the footer tab prompts | UI layout | medium |
| 8 | F38#37 dialogue rock | Move the foreman's post to the lit quarry mouth; find the flat unlit cyan ringed panel at his post | scene | medium |
| 9 | F40#19 rain | Rain frames are as dry as clear: wetness term (darker, glossier path/stone/grass) plus low gate mist | config/code | medium |
| 10 | F41#5 forest distance | Mid-distance groves 60–150 m out at the open stands; cut the mirror flood plane | scene + config | medium |
| 11 | F41#3 spacing | Dither-fade Voltarach over the ally in the opening exchange (owner-allowed fix) | code/config | medium |
| 12 | F38#3 fight scale | Trainer standoff so the humans stop overlapping Terrapup's legs | config | medium |
| 13 | F38#8 fly grip | Bend elbows, trail legs; glide frame at cruise height | config/animation | medium |
| 14 | F41#1 Stormheart | Vary the four identical banners; move the lattice pylon out of the approach | config + scene | medium |
| 15 | F41#4 destinations | Bring a Lantern Pool to the path edge with lit lantern posts | scene | medium |
| 16 | F39#30 / F13#5 night water | Darken the shallows at night (time-of-day input to `water.gdshader`) | code | medium |

**Capture-stand bugs (fix before any judging of these rows):**
- F39#21: job.json repros lack `--verified-victory-lifecycle`, so no win/aftermath frame is ever written. The row can never be scored as it stands.
- F38#14 / F39#9: the catch tool shows the "broke free" card over frames 02–05 (suspect: the verdict-card hold from ITEM-CAPTURE-FIXES).
- F40#14: map shot at Surveyed 0%, so no label exists to judge.
- F40#3: observatory and skyroad-arch stands fail ("no supported production-camera stand").
- F40#20 / F40#2: the eyrie "close" stand is the same shot as "approach".
- F13#5: T2-current `swim-brine-day` misses its authored current.
- F39#11: today's fight ends before the job's t-208/216 frames.
- F41#23: every catalogue Stormheart stand is inside the hollow (only the F41 matrix stand sees it from outside).

**GPU re-score only (defect gone on today's frames, old score is stale):** F39#29 (3.54, speaker now visible), F41#15 (3.19, banner gone), F41#16 (loss stand fixed), F39#7, F39#20, F39#5, F39#8, F39#22, F39#23, F39#19.

**Watch:** F41#12's night frame (hour 23) renders fully daylit under the Deepwood canopy; check on GPU.

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
- Still true? **Partly.** The posts now have props: Halda stands at a tournament booth with an awning and a bracket board, Lark beside a path signpost, Oskar by a bench on the village road. All three still stand in the same straight arms-down idle, and in the wide frames the trainer stands right beside each NPC (Oskar, Halda), so the two read as one small pair in the middle distance. The dialogue close-ups look good.
- **Correction (batch 5):** a pose arm already exists and lost. `data/config/npc_post_stances.json` (`enabled: false`, UIPOSES 1 Nov) layers role stances on these villagers; VIS-MEADOWS judged it flat (0.0 from all three judges) after its own post-stand fix, because at the production follow camera the villagers are about 1/6 of frame height and no stance reads (`ralph/reports/LANES/VIS-MEADOWS/READY.md` line 155). A different idle clip faces the same limit.
- Fix class: scene placement (where the NPC stands relative to the trainer and camera), not pose.
- Fix idea: separate each villager from the trainer (2–3 m to the side, facing the camera) so the NPC reads as its own figure at its post; stances only after that.
- Expected gain: low-medium (pose work is proven flat at this frame size).

### F39#30 The biome frame matrix (Tidewake)
- Last: 5.75 (board; VIS-TIDEWAKE CPU, F39#30a golden 6.18 / F39#30b 5.75).
- Judges' last asks (`ralph/reports/LANES/VIS-TIDEWAKE/READY.md`, status 19:45 and look/r26–r27): golden-hour diagonal stripes on the sand (a terrain shadow), a night shallow-water colour (the cyan band does not darken), a rain cloud grade, and a Veilfall rebuild.
- Today (`capture_tidewake_f13_5.gd`, F39-look set, 11 views, 1280x720 Low):
  - **Golden stripes: still true.** shore-golden shows hard parallel diagonal shadow bands across the whole beach.
  - **Night water: still true.** shore-night shows bright cyan shallows and pale grey-white sand under a dark sky; the shore reads as moonlit snow.
  - Rain: streaks and a darker grade read; blue sky gaps remain in the cloud.
  - Veilfall: veilfall-vista is the beige crag spire with one white fall and the ring of pale rest-shoal discs in the sea below; veilfall-near puts the camera on grey slab faces with a flat white fall sheet.
  - **New observation:** in every First Shore view, the exploration HUD hotbar (slots 1–5) and the Map/Satchel/Build legend sit at about 60% frame height over the horizon, island and dock, and the region banner sits over the sky. A bearded NPC is cut by the right edge and a barrel by the bottom edge of the same stand.
- Fix class: code (night water: a time-of-day input to `water.gdshader`, VIS-TIDEWAKE's own diagnosis), config (golden shadow caster: terrain shadow casting at low sun), owner decision (HUD placement OP21-11), scene placement (move the NPC and barrel off the stand's edges).
- Fix idea, best single one: darken and desaturate the shallow-water band at night through the time-of-day input to `water.gdshader` (the water nightly reads as the brightest thing in shore-night and is a large share of three night frames across F39#30, F13#5).
- Expected gain: medium (night is one of four times; the stripes and HUD remain).

### F39#0 Tidewake re-capture and re-score (unscored)
- This is a process row: re-capture the biome (≥200 frames) on the GPU and re-score its catalogue rows. No build fixes it. GPU-only.

### F13#5 Currents, inhabited docks and Veilfall distance read (T2 matrix)
- Last: 5.87 (board; VIS-TIDEWAKE CPU look/r14–r15).
- Judges' last asks (`ITEM-MESHY-RECHECK-PARKED/READY.md` row 6, `NEAR6-TW/READY.md`): the three dock hamlets share one template (same positions, banner, stall), so they read as one copied set; Veilfall needs a towering, tiered, green, misty mountain; current dashes read as even rows.
- Today (`capture_tidewake_f13_5.gd`, T2-current set): 3 of 4 views captured. **swim-brine-day failed: "Fixed swim view missed the authored current"** (capture-stand bug: the stand no longer lands in its authored current, so that view is missing from any round).
  - swim-away-day / swim-across-day: a clear swimmer ring and white curved current arcs in pale turquoise water; driftwood logs; the HUD hotbar and legend sit over the water at mid-frame.
  - swim-away-night: water is saturated bright blue and the beach pale grey-white, the same night-water defect as F39#30.
  - No dock hamlet is visible from these swim stands.
- Still true? **Yes** for the night water and Veilfall; the dock half cannot be judged from the surviving swim views.
- Fix class: capture-stand bug (re-seat swim-brine-day onto its current), then code (night water), scene placement (hamlet layout variety).
- Fix idea: re-seat swim-brine-day first so the set is complete; then the night shallow-water darkening shared with F39#30.
- Expected gain: low-medium (the dock and Veilfall halves need layout or new-art work the swim stands do not show).

### F41#15 P2-083 dialogue foreground obstruction (Stormwood)
- Last: 5.90 (board); GPU 3.19 (28 Oct).
- Judges: "In both Captain Marrow frames a giant blue lightning-bolt banner fills the screen and the speaker is never seen" (`stormwood/scores-gpu.json`).
- Still true? **No.** Both Marrow dialogue frames (character and Dynamo Core trainer) now show Marrow centred on the deck with the line box below; no banner in the way. Officer Nysa is staged clearly in the Deepwood.
- Remaining: Marrow's armour renders as pale pinkish grey with white hair, low contrast against the pale deck (washed out); a vertical wooden post cuts the left edge of both Marrow frames; Marrow and Nysa wear the same armour body.
- Fix class: GPU-only re-baseline (defect fixed); optional config (Marrow armour value/colour variant).
- Fix idea: GPU re-score. If it lands under 6, a darker Tether armour variant for Marrow (appearance variant, same mesh).
- Expected gain: low as a build (the scored defect is gone; the re-score itself should move a lot from 3.19).

### F41#18 P2-056 uniformed character readability (Stormwood)
- Last: 5.98 (board); GPU 3.91.
- Judges: "Grunt Lieutenant Dace, Lieutenant Varga and Defector Sable are small dark figures lost against dark green-teal grass, with no rim light or uniform accent to pick them out" (`stormwood/scores-gpu.json`).
- Still true? **Partly.** They are no longer dark: Dace and Varga wear pale grey-white armour, Sable a light grey outfit. But each is a small figure (about an eighth of frame height) standing right beside the trainer, so officer and trainer read as one pair, and nothing marks rank or faction: no colour accent at all.
- Fix class: config / installed-asset recolour (appearance variants, the F41#8 recolour tool).
- Fix idea: a Team Tether oxblood accent on the Tether officers' uniforms (sash, shoulder or collar band; red is reserved for Team Tether, so this is on-brand), stronger for the lieutenants and faded for Defector Sable. Same meshes.
- Expected gain: medium-high (a faction colour is exactly what the judges asked for, and it reads even at this distance).

### F41#20 P2-084 named character dialogue reuse (Stormwood)
- Last: 5.64 (board); GPU 6.09 (3/3 FIXED).
- Judges: "Fenn, Oswin and Elder Maud now each have their own line, but Fenn's frame is a black void (Fenn not on screen), Fenn's and Oswin's portraits look alike (bearded, hooded)" (`stormwood/scores-gpu.json`).
- Still true? **Partly.** Fenn is on screen today (no void), lines are distinct. But Fenn and Oswin are the same model in the same blue hood and yellow-green coat, and their dialogue portraits are the same image. Elder Maud is distinct.
- Fix class: config + installed-asset recolour (appearance variant and recoloured portrait, as `ITEM-F41-8` did for Bryn and Maud).
- Fix idea: give Oswin an appearance variant (different hood and coat colour, no red) and a recoloured portrait plate.
- Expected gain: medium (two of three frames show the duplicate; the fix is a proven recipe from F41#8).

### F41#3 P2-092 named wild fight actor spacing (Stormwood)
- Last: 5.98 (board); GPU 5.98.
- Judges: "in tell1-a-start and tell1-e-impact Sparkit still sits in the boss's leg space ... with a dense left-side HUD, so the scene lacks Palworld's clear fighter separation" (`stormwood/scores-gpu.json`).
- Still true? **Yes.** capacitor_alpha today: in i01 and tell1-a-start Sparkit's head and forelegs are inside Voltarach's front legs; in tell1-e-impact Sparkit is almost hidden under the boss's body and the purple strike spikes. i10 and tell2 show clean separation, so it is the opening exchange that overlaps.
- Owner rule (STATE §0, 7 Nov): combat spacing stays; fix the look with a fade or clip tweak.
- Fix class: code/config (occlusion fade of the boss body when it covers the piloted ally, or an ally outline through the boss).
- Fix idea: dither-fade Voltarach's leg and body meshes to about 50% where they cover the active ally (the existing foliage camera-visibility fade is the model), so Sparkit reads through the legs in the opening frames.
- Expected gain: medium (two of three judged frames; spacing itself cannot change).

### F41#22 The biome frame matrix (Stormwood) (unscored)
- No score yet. Captured `capture_stormwood_f10_matrix.gd --stands=forest,giant,glass,rod_line,stormheart --phases=calm,surge --no-aftermath` (production camera stands, CPU Low).
- What the frames show:
  - **Calm and Surge are the same frame at every stand** (only rain density changes), the same defect as F41#2: the storm does not read in the matrix.
  - forest and giant are framed close on huge trunks; the nearest trunk at the forest's right edge is dithered see-through by the camera fade and reads as a ghost pane.
  - glass is open meadow with small distant crystal clusters; rod_line is the charged road with the lattice pylon.
- Fix class: config (per-phase sky/light, shared with F41#2).
- Fix idea: the F41#2 phase grade carries straight into this row (darker, cooler Surge). Fix F41#2 first, then baseline this row on the GPU.
- Expected gain: medium (from F41#2's fix), baseline needed.

### F41#23 Stormheart tree at distance and up close (unscored, outside view)
- The matrix stormheart stand is the one outside view: the gnarled grey Stormheart, with its hut deck in the crown, stands behind the trainer at mid distance. It reads as a big old tree but not as the region's hero: it is pale grey, about the height of the near trees in frame, against the flat lilac sky, with no glow, storm or scale cue. The up-close half is the inside-hollow stands (see F41#1).
- Fix class: scene/config (value and glow on the tree, sky behind it) or capture-stand (a farther stand where it towers over the canopy).
- Fix idea: darken the Stormheart bark and light its crown with the storm (a few bolts striking the crown, cool rim light), so it is the darkest, tallest and only lit shape on the skyline.
- Expected gain: medium (baseline first).

### F41#24 No flat magenta rings or slabs, placeholder materials, floating bodies or clipping (Stormwood) (unscored)
- Seen in today's Stormwood frames:
  - **giant stand: a flat pinkish-mauve square quad** lies on the dark ground right of the trainer (calm and surge). It reads exactly as a placeholder slab. Worth finding its node.
  - giant/forest: clusters of pale cream mushroom caps render flat and unlit, so in the frame they read as flat cream discs or slabs.
  - Glass Sink close: the stone ring's base edge sits above the dark ground (looks unseated).
  - Struck Sentinel / Stormheart approach: the black-and-gold lattice pylon stands in the trainer's sightline (placement, not clipping).
  - Heartstone / Glass Field: dark mirror flood planes with hard edges.
- Fix class: scene placement (find and remove or re-seat the pink quad; seat the ring) and config (mushroom cap shading).
- Fix idea: identify the pink quad at the giant stand (likely a decal or debug plane) and remove it; that is a direct pass on this row's wording.
- Expected gain: medium for this row (clean-up items are binary in the judges' eyes).

### F41#0 Stormwood re-capture and re-score (unscored)
- Process row (GPU re-capture ≥200 frames and re-score). GPU-only; no build. Note the F41 catalogue refuses CPU.

## Batch 3: Cloudreach dialogue, landmarks, captain fight and matrix (captured 8 Nov 15:14–18:01 UTC)

Tools: `quick_judge.py capture F40#9`, `F40#2 F40#3`, `F40#5` and `capture_cloudreach_f40_matrix.gd --piece=3-7 --source-commit=<sha>`. Same source and renderer as batch 1.

### F40#9 P2-068 named NPC post readability (Cloudreach)
- Last: 5.20 (board); GPU 5.50.
- Judges: "The named NPCs are tiny mid-ground figures beside the trainer, half lost in tall grass (Tavi frame), shadow (Sora frame) and the tree trunks (keeper frame), with no post props or poses to say who they are" (`cloudreach/scores-gpu.json`).
- Still true? **Partly.** Props exist now: Tavi stands on a stone pad with a straw training dummy and a wooden rack, Maela beside a stone pedestal on the perch path. But in all three wide frames the NPC is still a small figure right beside the trainer: Tavi's legs are in tall grass, Sora stands in the dark shadow at the foot of the stone arch, Maela is half behind tree trunks. All three use the same arms-down idle. The dialogue close-ups read well.
- Fix class: scene placement (post spots) plus config (grass clearing at posts). Pose work is proven flat at this frame size (see F38#35's correction).
- Fix idea: move Sora 3–4 m out of the arch shadow into the sun, move Maela clear of the trunks to the open side of the pedestal, clear grass in a 2 m disc around Tavi's pad. Skip pose work.
- Expected gain: medium-low (all three judged frames; placement is cheap, but the NPCs stay small at the follow camera).

### F40#2 P2-022 summit aviary (Cloudreach) — also F40#20 Sky Aviary hero landmark (unscored)
- Last: 6.16 (board, NEAR6-CR CPU); `ITEM-F40-2/READY.md` parked (stone-ground and scattered-stone arms lost or were invisible).
- Catalogue defect: "a small skeletal dome on grass beside a separate court instead of a layered stone sanctuary and its night silhouette stays dark" (`job.json`).
- Still true? **Partly.** Today the summit is a solid stone sanctuary: blue glass dome, turrets, blue banners, arched door; at night its windows are lit and the facade reads pale against a deep-blue sky (no longer dark). What remains: it is small in every frame (about 15% of frame height on a flat lawn at the end of the path), the court sits apart at the left, and the **"close" stand is effectively the same distance as "approach"** (the two day frames are nearly the same shot), so "up close" is never shown.
- Fix class: capture-stand (a real close stand at the door) plus config (summit sanctuary scale).
- Fix idea: re-seat the eyrie "close" stand near the sanctuary forecourt so the dome fills the upper frame; then judge whether a 1.3–1.5x scale on the sanctuary still needs doing for the approach view.
- Expected gain: medium for F40#20 (the up-close half is currently not captured at all); low-medium for F40#2.

### F40#3 P2-024 architectural landmark read (Cloudreach)
- Last: 6.46 (board).
- Catalogue defect: "Several Cloudreach destinations present sparse plain or disconnected structures with weak landmark-specific detail" (`job.json`).
- Still true? **Can't tell for 2 of 3 frames: capture-stand bug.** `old_wind_observatory__day__approach` and `broken_skyroad_arch__day__approach` fail today with "no supported production-camera stand among 15 candidates", so two of the row's three frames are missing from any round. Windscar Beacon (the one captured) reads well: a tall white tower with a blue roof and a timber gate arch hung with banners, framed by pillar rocks.
- Fix class: capture-stand bug.
- Fix idea: add reachable stands for the observatory and skyroad arch (the `--spot` form) before any art.
- Expected gain: can't tell until the stands work.

### F40#5 P2-112 captain fight camera orientation (Cloudreach)
- Last: 6.39 (board, GPU).
- Judges: "edge-cropped creatures, a bare dirt ring and heavy HUD panels keep it short of Palworld's boss-fight finish"; catalogue: "the camera repeatedly faces an empty part of the arena or crops the opponent and ally" (`cloudreach/scores-gpu.json`, `job.json`).
- Today (`phase2_capture_cloudreach_live_fight.gd`, Captain Veyra, frames written at about the job's times; ids drift by ~12 ticks): most frames now frame Aeriex and the ally together mid-arena with the trainer behind (1722, 2442, 3162, 3342, and 3522/3702 at the job's 3510 moment, a close two-shot of Bramblebun and Aeriex).
- Still true? **Partly.** live-2802: the camera sits behind a **red-and-cream arena banner post that fills the right half of the frame**, and the piloted Mudsnout is off-screen; only Aeriex and the trainer show. The ring is still bare packed dirt.
- Fix class: config/code (camera occluder fade for arena dressing, like the foliage camera-visibility fade).
- Fix idea: add the Cloudreach arena banner posts to the camera-occluder fade so they dither out when between the camera and the fighters.
- Expected gain: low-medium (one frame of three is obstructed; others are already decent).

### F40#19 The biome frame matrix (Cloudreach)
- Last: 5.61 (board; NEAR6-CR CPU: rain 5.61, night ~5.8).
- Judges' last asks (`ralph/reports/LANES/NEAR6-CR/READY.md`): rain needs wet sheen on path and stone, puddles or splashes, a storm sky without blue gaps and mist at the gate; night needs the gate framed clear of the quest box and minimap, and a hero gate.
- Today (`capture_cloudreach_f40_matrix.gd --piece=3-7`, realm_gate_crag; 16 frames, day/golden × clear/rain × four cameras): the run hit this lane's 66-minute timeout before the night piece, so **night was not re-checked**.
- Still true? **Yes for rain.** In day rain and golden rain the dirt path, the boulder trail and the grass have the same dry, matte colour as in clear weather; there are no puddles, no sheen and no mist at the gate; only streaks and a greyer sky show it is raining. **Yes for the framing**: in every approach frame the gate arch sits right behind the "MAIN STORY" quest box and minimap at top right.
- Also: the gameplay/reverse/detail cameras stand on the boulder trail, which fills the lower half as large lumpy grey rocks rather than a path.
- Fix class: config/code (a rain wetness term on terrain, path and rock: darker albedo, lower roughness) and owner decision (quest box placement).
- Fix idea: in the rain preset, darken and gloss the path, trail stones and grass (wetness hook), and add low gate mist; judge on the day-rain piece.
- Expected gain: medium (rain is half the captured matrix; the visual change is large and global).

### F40#21 No flat magenta rings or slabs, placeholder materials, floating bodies or clipping (Cloudreach) (unscored)
- Seen today across F40#2, #3, #5, #9 and #19 frames: no magenta, no floating bodies. Items worth a look: the boulder trail at the gate reads as loose rubble slabs; the eyrie court sits apart from the sanctuary; in F40#5's live-2802 a foreground arena banner post fills half the frame. The GPU notes for F40#6/#11 (black geometry sliver over the cliff, hard white polygon cloud puffs) were not re-checked yet (ride capture comes in a later batch).
- Fix class: see F40#6/#11 (later batch).
- Expected gain: can't tell yet.

### F40#0 Cloudreach re-capture and re-score (unscored)
- Process row (GPU re-capture ≥200 frames and re-score). GPU-only.

## Batch 4: Tidewake fights (captured 8 Nov 18:01–18:37 UTC)

Tool: `quick_judge.py capture F39#7 F39#11 F39#20` and `F39#21 F39#28` (`phase2_capture_tidewake_fights.gd`, Venn and Nerissa). Same source and renderer as batch 1.

### F39#7 P2-089 fight actor composition (Tidewake)
- Last: 5.65 (board, GPU).
- Judges: "Cannonback and Ripplet still stack into one mass in t-024 and touch in t-023/t-025 on a flat, evenly lit pale beach" (`tidewake/scores-gpu.json`).
- Still true? **No** for the stacking. `phase2_capture_tidewake_fights.gd --trainer=water_trainer_venn` (READER, level 53) today: in t-023, t-024 and t-025 Ripplet and Cannonback stand about a body-length apart with sand between them; nothing intersects.
- Remaining: the left "TEAM 5/5" roster is half-faded in these three frames and the trainer stands right behind it, so the HUD covers the trainer; the beach is flat and evenly lit.
- Fix class: GPU-only re-baseline.
- Fix idea: GPU re-score; if the roster-over-trainer remains, let the roster fade fully or the trainer stand clear of the left 20% (fight staging).
- Expected gain: low as a build (scored defect gone).

### F39#20 P2-090 fight background creature ground contact (Tidewake)
- Last: 6.42 (board); GPU 5.70.
- Judges: "the pale grey Ripplet barely separates from the pale sand, a small blue-white blob still sits in the sand beside it in frames 1-2" (`tidewake/scores-gpu.json`).
- Still true? **Mostly no.** t-000, tell-start-001.25 and t-016 today: Ripplet is a saturated teal against the sand and separates clearly; no buried blob beside it. A small blue creature stands whole on the dune crest at top left of t-016.
- Fix class: GPU-only re-baseline.
- Expected gain: low as a build.

### F39#11 P2-101 Riverdrake fight ground contact (Tidewake)
- Last: 6.42 (board).
- Catalogue defect: "Riverdrake crouch and recoil sink its belly and feet into sand or leave the body hovering above a separate shadow" (`job.json`).
- Today: **capture-stand drift.** The job's frames are tell-ended-180, t-208 and t-216 of the full Venn fight (`--level=55 --pilot=READER --max-frames=150`), but today's run stops at t-172 (the fight resolves or the `--cap-s=240` budget runs out first), so none of the three moments exist. In the nearest Riverdrake frames (t-164, t-172, tell-ended-100) the Riverdrake stands on the sand with its feet and shadow together.
- Still true? **No** in the frames reached; the judged moments cannot be re-shot with this repro.
- Fix class: capture-stand (give the run enough cap to reach t-208/216, or re-pick the frames).
- Expected gain: low.

### F39#21 P2-103 named fight victory hierarchy (Tidewake) (unscored)
- Catalogue defect: "Named fight victory reward panels sit over the full exploration HUD team roster hotbar and active-creature prompt so the payoff has little visual space" (`job.json`).
- Today: **capture-stand bug, no frame exists.** The row's three frames (venn_resolve win-141.53 and aftermath-142.53, nerissa_resolve win-207.25) come from `phase2_capture_tidewake_fights.gd` without `--verified-victory-lifecycle`. Without that flag the tool "never invents win/aftermath tags" (line 118), so today's Venn run ends at fight time 91.6 s (fight over, `active=false`) and the Nerissa run at 32 s with no win or aftermath frame. `quick_judge` and the GPU re-judge both read this repro, so this row can never be scored as it stands.
- Fix class: capture-stand bug (add `--verified-victory-lifecycle` to the three F39#21 repros in `job.json`, like the F41#16 loss-stand fix).
- Fix idea: fix the repro, re-shoot, then judge whether the reward panel needs the exploration HUD hidden behind it.
- Expected gain: can't tell (first baseline).

### F39#28 P2-091 fight boss title overlay (Tidewake)
- Last: 6.02 (board, GPU; 3/3 FIXED).
- Judges: "The boss card now sits top-right clear of Cannonback, but the Nerissa frame is dominated by a giant translucent blue crystal slab that hides half the arena, and the beach frames stay flat and evenly lit" (`tidewake/scores-gpu.json`).
- Still true? **Yes** for the crystal: Nerissa t-000 and tell-ended show a tall translucent blue crystal slab filling the right third of the arena, and the arena hall is very dim (dark stone, small lanterns). The card is clear of the creatures in all frames.
- Fix class: scene placement (move the crystal behind the arena edge or off the fight camera's side) plus config (arena light).
- Fix idea: move Nerissa's arena crystal to the back wall behind the captain, out of the side the fight camera looks across, and raise the arena fill light.
- Expected gain: medium-low (one of three frames; the overlay defect itself is fixed).

## Batch 5: Meadows 6.0–6.5 rows (captured 8 Nov 18:37–20:17 UTC)

Tools: `quick_judge.py capture` for F38#37; F38#29 F38#3 F38#11 (`phase2_capture_fights.gd`, south bridge grunt and Warden); F38#25 F38#1 F38#2 (`phase2_capture_creatures.gd`); F38#14 (`phase2_capture_catch.gd`); F38#21 F38#27 (locations, UI); F38#8 (`phase2_capture_realm_flight.gd`). Same source and renderer as batch 1.

### F38#37 P2-079 Meadows dialogue rock obstruction (Meadows)
- Last: 6.09 (board); GPU 4.64.
- Judges: "The quarry-foreman frame is a dim brown rock box with a second character cut off at the left edge, and in the Garrick frame a black rock face fills the right third while the camera sits behind the player's head with Garrick not visible at all" (`meadows/scores-gpu.json`).
- Still true? **Partly.** Garrick's dialogue frame is fixed: Garrick stands in the open with his pitchfork and straw hat against the meadow, no rock face. The foreman's dialogue frame is still a dim brown rock enclosure with the trainer's head cut by the left edge, though the foreman himself is visible.
- Extra (the same stands' non-dialogue frames, not in this row's set but in the catalogue): at the foreman's post the camera looks past a wooden beam at a **flat, unlit pale-cyan panel wrapped by two black rings** that fills a third of the frame (it reads as a placeholder material); at Garrick's post a large boulder hides Garrick completely from the walk-up camera.
- Fix class: scene placement (open the foreman's post or move it to the quarry mouth, in daylight).
- Fix idea: move the foreman's post 4–6 m out to the lit quarry mouth so the dialogue camera sees him against the cut face and sky; find the cyan ringed panel (likely an unlit prop material) and give it its real material or remove it.
- Expected gain: medium (one of two frames is still the defect; the cyan panel would also hit the Meadows cleanliness row).

### F38#3 P2-062 fight camera and creature scale (Meadows)
- Last: 6.26 (board, GPU).
- Judges: "Creatures now tower over the trainers ... but the ally dog takes a third of the frame and the player overlaps its front legs in grunt-02/03, with flat noon light and no atmosphere" (`meadows/scores-gpu.json`).
- Still true? **Yes.** south_bridge_grunt 01–03 today: the trainer and the grunt both stand in the gap between the boar and Terrapup, at Terrapup's chest and chin, so the two humans overlap the dog's front legs and head in every frame. The light is flat midday.
- Fix class: config (trainer standoff during wild/trainer fights) or code (fight staging).
- Fix idea: push both trainers back behind their own creature by a few metres during the exchange (a standoff tunable), so the middle of the frame is creature vs creature.
- Expected gain: medium (all three judged frames; owner kept combat spacing for F41#3 only, check this applies to trainer stands too).

### F38#11 P2-063 shared fight tell and hit effects (Meadows)
- Last: 6.29 (board); GPU 6.59.
- Judges: "tells still live in the small top-right text and the creatures barely change pose between frames" (`meadows/scores-gpu.json`).
- Still true? **Yes.** Grunt 02/03/05: the tell is the small orange "incoming — move" line under the opponent card; dust puffs show at impact; the boar's pose barely changes across frames (in 05 it has turned away).
- Fix class: config/code (an in-world tell cue at the attacker).
- Fix idea: a short ground flash or rim-glow on the attacking creature during its wind-up, so the tell reads in the scene, not in the HUD.
- Expected gain: low-medium.

### F38#29 P2-065 trainer defeated presentation (Meadows)
- Last: 6.18 (board; NEAR6-MS CPU, `beaten_trainer_stance.immediate_1104` and `silent_victory_shot_1104` ON).
- Judges: "the grunt stands in the same neutral pose before and after while the 'Tether Grunt defeated' banner does all the work" (`meadows/scores-gpu.json`).
- Still true? **Partly.** In today's 99-after the grunt is down on his knees with head bowed (crop confirms the shipped kneel), but he is a small figure between the trainer and Terrapup and a foreground bush covers his legs, so at frame size the kneel barely reads. In a01 the grunt is hidden behind Terrapup's chest. The victory push-in shot (`silent_victory_shot_1104`) is not visible in the captured set.
- Fix class: capture-stand (the row's frames do not include the aftermath push-in that the shipped arm creates) / GPU-only.
- Fix idea: re-pick the row's frames to include the silent-victory push-in moment, then re-score on the GPU.
- Expected gain: low-medium.

### F38#1 P2-015 creature collapse and rest (Meadows)
- Last: 6.30 (board); GPU 5.93 (captured before the 4 Nov pose-still fix, TECHNICAL §8.1).
- Judges: "the fainted terrapup is a tiny pale smear indistinguishable from its resting pose and the verdian still reads upright" (`meadows/scores-gpu.json`).
- Still true? **Partly.** `phase2_capture_creatures.gd` today (Meadows stage, post-fix): Veridian's fainted frame is now lying flat (no longer upright), but renders pale and washed-out, close to a translucent smear. **Terrapup fainted and Terrapup resting are the same lying-on-its-side pose** at this distance, so the two states still cannot be told apart.
- Stand: every stage frame is wide: the creature is about a sixth of frame height beside the trainer's back, with a dark bush and grass filling the right foreground.
- Fix class: config/animation choice (a resting pose distinct from the faint: curled or sitting with head up), plus Veridian's faint material (no washout).
- Fix idea: give resting a curled or sternal (lying upright, head raised) pose for Terrapup so rest and faint differ in silhouette; check why Veridian's fainted body loses its colour (likely the faint desaturation on a pale remake).
- Expected gain: medium-low (subjects stay small in this stand).

### F38#2 P2-016 creature hurt and movement poses (Meadows)
- Last: 6.40 (board); GPU 5.52 (also before the 4 Nov fix).
- Judges: "Nightburrow's hurt and moving frames are hard to tell apart at gameplay size, and the low camera spends half the frame on blown-up foreground grass blades" (`meadows/scores-gpu.json`).
- Still true? **Yes.** Nightburrow hurt and Nightburrow moving are both front-facing standing poses of the same size; the difference is not readable. Terrapup hurt shows its head dropped but the body flashes pale grey-white. The foreground grass and bush still take the lower right of every frame.
- Fix class: animation (a stronger hurt recoil) / capture-stand (foreground bush).
- Fix idea: a bigger hurt recoil for Nightburrow (head thrown back, body sideways) so it differs from its walk at this size.
- Expected gain: low-medium (CPU wins on P2-016 already failed on GPU twice, TECHNICAL §8.1).

### F38#25 P2-018 shiny palette distinction (Meadows)
- Last: 6.21 (board); GPU 6.06.
- Judges: "Shiny Nightburrow's icy pale blue reads clearly against the dark normal form, but the shiny Stormtrail is a small washed-out cream figure with no normal to compare against, and a third of each frame is a near-camera grass carpet" (`meadows/scores-gpu.json`).
- Still true? **Yes.** Shiny Nightburrow (icy blue) vs normal (brown-white with purple mask) reads well. Shiny Stormtrail is a small pale cream coyote with no normal Stormtrail in the set.
- Fix class: capture-stand (the set lacks Stormtrail's normal frame) / Blender art (a more distinct Stormtrail shiny palette).
- Fix idea: give shiny Stormtrail a clearly different hue (not cream; e.g. slate-blue with pale storm markings, no red), and add `stormtrail__idle` to the row so it has a comparison.
- Expected gain: medium-low.

### F38#14 P2-060 catch effect finish (Meadows)
- Last: 6.23 (board); GPU 6.06.
- Judges: "the effect is still a flat translucent yellow bubble and over-bright white orb that change little from strike to absorbing, half-hidden behind the player creature's back" (`meadows/scores-gpu.json`).
- Today: **capture-stand bug.** In `phase2_capture_catch.gd --biome=meadows`, frames 02-orb-in-flight, 03-strike and 03-absorbing all show the large "Bramblebun broke free / Weaken it more, then throw again" card across the top, and no capture bubble at all; only a small faint orb shows beside Bramblebun in 03-strike. The same tool on Tidewake (batch 1) showed the card on 03-absorbing through 06-breakout and over 07-aiming-weakened. So the broke-free card is on screen in frames that should show the throw and the absorb.
- Likely cause (to confirm, not proven): the verdict-card hold added for 06-breakout (`ITEM-CAPTURE-FIXES`, `_on_capture_resolved` / `_top_up_verdict_card`, which tops the card's timer up every process frame from the resolve to the verdict shot) keeps a card from an earlier resolve alive into the next throw's frames.
- Still true? **Can't tell**: the effect is not in today's frames.
- Fix class: capture-stand bug (catch tool), shared with F39#9 and any row using catch frames 02–05.
- Fix idea: make sure the held card is released and expired before the next throw's 01–05 frames, then re-shoot both biomes before any effect work.
- Expected gain: can't tell (would unblock F38#14 and F39#9 scoring).

### F38#21 P2-005 ground cover (Meadows)
- Last: 6.23 (board); GPU 6.06.
- Judges: "one even yellow-green grass carpet with evenly sprinkled white flowers and almost no rock, colour clusters or edge-of-grove breaks" (`meadows/scores-gpu.json`).
- Still true? **Partly.** Stronghold approach is still a broad even green field with evenly spread small shrubs; the Burrow Warrens approach now has the hill shell, a burrow mouth, flower variety and grove edges and reads well; Old Mill close has a path, slope and dense varied foliage.
- Fix class: scene placement (installed rock and flower-clump clusters).
- Fix idea: at the stronghold approach, add three or four clustered patches (a rock outcrop with tall grass, a dense flower clump, a darker clover patch) in the mid-ground either side of the path, so the field has clusters instead of an even sprinkle.
- Expected gain: low-medium (one of three frames still matches the complaint).

### F38#27 P2-031 settings and binding instructions (Meadows)
- Last: 6.32 (board, GPU).
- Judges: "tiny grey body text, '[Q] Previous tab [Tab] Next tab' literal key labels and a clipped 'Fighting' section" (`meadows/scores-gpu.json`).
- Still true? **Partly.** Body text is now white and readable; gamepad glyphs show beside keyboard keys. Still there: the footer reads "[Q] Previous tab  [Tab] Next tab" in literal brackets next to glyph prompts; and the controls list shows only three rows (Walk forward, Walk back, Step left) before "More below", with a tall empty band under it, so most of the panel is blank and the sections below are cut off. Quick bindings shows five rows and the same empty band.
- Fix class: config/UI layout (list height inside the panel; footer prompt glyphs).
- Fix idea: let the bindings list fill the panel's height (about twice as many rows visible) and render the footer tab prompts as glyphs (LB/RB) like the rest.
- Expected gain: medium (both judged frames; it is a layout fix, no art).

### F38#8 P2-119 Fly carrier grip pose (Meadows)
- Last: 6.12 (board, GPU).
- Judges: "The sky and Galecrest's silhouette are good, but the rigid ladder-hang pose and the blurred, featureless terrain far below sink it" (`meadows/scores-gpu.json`).
- Still true? **Yes for the pose.** `phase2_capture_realm_flight.gd` today: in 01-launch and 02-glide the trainer hangs under Galecrest's talons with both arms straight up and legs straight down, a stiff vertical figure. In 02-glide the pair is only a few metres up beside a boulder (the shadow sits well away on the grass), so it reads as standing with arms raised more than flying; the "terrain far below" is not in this frame.
- Fix class: config/animation (trainer fly-grip pose offsets) plus capture-stand (glide frame taken too early, before altitude).
- Fix idea: bend the elbows and let the legs trail back with knees bent in the fly-grip pose (bone offsets like `post_stance.gd`), and take the glide frame once the carrier is at cruise height.
- Expected gain: medium (both frames are the subject; pose and timing are cheap).

## Batch 6: Tidewake 6.0–6.5 rows (captured 8 Nov 20:17–21:05 UTC)

Tools: `quick_judge.py capture` for F39#5 (swimming), F39#27 F39#29 (dialogue), F39#6 (creatures fainted), F39#22 F39#8 (mounted swim), F39#1 (routes, locations). Same source and renderer as batch 1.

### F39#5 P2-071 surface swimming trainer pose (Tidewake)
- Last: 6.20 (board); GPU 5.20.
- Judges: "the trainer is still vertical with both arms thrown up and legs visible below the surface in all three frames, reading as wading or flailing" (`tidewake/scores-gpu.json`).
- Still true? **Mostly no.** `phase2_capture_swimming.gd` today (entry, surface_west, surface_mid): seen from behind, the trainer lies prone with the head above the water inside a ripple ring and the legs trailing back under the surface; no arms thrown up. The legs show as two pale shapes through the very clear water, and the swimmer is small at the bottom centre of a large flat turquoise plane.
- Fix class: GPU-only re-baseline; optional config (water clarity near the swimmer, so the submerged legs fade).
- Fix idea: GPU re-score first. If needed, lower shallow-water transparency at depth so submerged limbs fade out.
- Expected gain: low as a build (scored defect gone).

### F39#29 P2-074 dialogue speaker visibility (Tidewake)
- Last: 6.34 (board); GPU 3.54.
- Judges: "frames 2-3 (Captain Nerissa) have the camera buried in a noisy grey rock face and frame 1 shows only the trainer's back on a bare slope, so no speaker is ever on screen" (`tidewake/scores-gpu.json`).
- Still true? **No.** All three dialogue frames today show the speaker centred: Resident Nalia in a sand gully with dune grass, and Captain Nerissa (twice) in the lit stone hall with the line box below. No rock face in front of the camera.
- Remaining: Nerissa wears the same Tether armour body as Stormwood's Captain Marrow and Officer Nysa.
- Fix class: GPU-only re-baseline.
- Expected gain: high from the re-score alone (3.54 was a no-speaker frame); low as a build.

### F39#27 P2-057 grass around named characters (Tidewake)
- Last: 6.23 (board); GPU 5.48 (3/3 FIXED).
- Judges: "Grass is now sparse ankle tufts so silhouettes are clear, but the characters read as backlit near-black figures on bare sand dunes with no grove/edge structure" (`tidewake/scores-gpu.json`).
- Still true? **Partly.** Adair, Bren and Corin are now front-lit and readable (not near-black), but each still stands beside the trainer on an empty pale dune slope with a few grass tufts; there is nothing around the post (no hut, nets, driftwood, rocks). The NPC and trainer read as one small pair.
- Fix class: scene placement (post dressing from installed Tidewake props).
- Fix idea: dress each post with a small cluster (driftwood, a net rack or crate, a clump of dune grass, a rock) a few metres behind the NPC, and stand the NPC 2–3 m apart from the trainer.
- Expected gain: medium-low.

### F39#6 P2-028 creature faint state (Tidewake)
- Last: 6.24 (board); GPU 5.61.
- Judges: "Ripplet and Aquaryn lie flat and read as down, but Riptusk still sits in an upright crouch with its head raised, and all three are small, low-contrast shapes on the shoreline" (`tidewake/scores-gpu.json`).
- Still true? **Partly, with a new defect.** `phase2_capture_creatures.gd --biome=water --poses=fainted` today: Riptusk now lies on its side (fixed). **Aquaryn's fainted body floats**: a crop shows it tipped on its back about half a body-height above the sand, with its shadow lying separately on the ground below. Ripplet lies flat but is pale white on pale sand. All three are still small at the shoreline beyond the trainer.
- Fix class: animation/config (Aquaryn faint grounding, like the 4 Nov pose-still seating and `ground_clip.py` on other remakes).
- Fix idea: seat Aquaryn's faint end pose on the ground (root offset or ground-clip pass on its faint clip), so its body meets its shadow.
- Expected gain: medium (a floating body is a hard defect judges always call; one of three frames).

### F39#8 P2-108 Aquaryn mounted-water pose (Tidewake)
- Last: 6.38 (board); GPU 4.97. Current lane work: `ITEM-F39-8/READY.md` (land).
- Judges: "Aquaryn standing upright on the water surface in an identical pose across frames 03-05 with no splash or wake and a long hard shadow cast onto the water, so it reads as walking on glass" (`tidewake/scores-gpu.json`).
- Still true? **Mostly no.** `phase2_capture_tidewake_mounted_swim.gd` today: in 03–05 Aquaryn rides low with its body half under the surface and the rider seated on its back; 04 is a side view of a horizontal swimming body. No hard shadow on the water. Still missing: a wake or splash (only a faint ring), and the submerged legs show as pale shapes through the clear water.
- Fix class: GPU-only re-baseline; optional VFX (bow wake).
- Expected gain: low as a build until the GPU re-score.

### F39#22 P2-109 Aquaryn dismount camera obstruction (Tidewake)
- Last: 6.28 (board); GPU 5.62 (3/3 FIXED).
- Judges: "a ghostly translucent mount mesh hovers around the trainer and a large detached dark shadow fills the foreground over flat, featureless sand" (`tidewake/scores-gpu.json`).
- Still true? **No** for the ghost mesh and shadow: frames 11–13 show the trainer alone on the beach with a normal shadow; the companion stands a few metres off. The sand is still flat and empty.
- Fix class: GPU-only re-baseline.
- Expected gain: low as a build.

### F39#1 P2-008 shore landforms (Tidewake)
- Last: 6.44 (board); GPU 5.56.
- Judges: "repeated smooth sand domes, a hard grass-blade carpet edge in frame 3 and a floating white slab in the water in frame 1 keep the shore from reading layered" (`tidewake/scores-gpu.json`).
- Still true? **Partly.** Brine Steps walk_03 now has the trainer swimming beside the dock with a rowing boat in the foreground; no floating white slab is visible. First Shore welcome beacon and horizon stones still show the same smooth, featureless sand domes, and the horizon-stones frame still has a hard straight edge where the grass-blade carpet stops on the sand (right side).
- Fix class: scene placement (break the grass edge with scattered tufts) / terrain (dune form).
- Fix idea: feather the dune-grass carpet edge with scattered tufts and a few rocks and driftwood along it, so the edge is ragged.
- Expected gain: low-medium.
