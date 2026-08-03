# MA-02 — blind visual review, round 2

Run against the survey taken after the MA2 art swap: Quaternius rigged creatures
replacing the Poly Pizza scans, the KayKit Ranger replacing Kenney's blocky
trainer, ambientCG PBR ground replacing Terrain3D's `show_colormap` debug view,
`world_look.gd` finally making `art.json` mean something, and vegetation
collision so the camera stops burying itself in a bush.

The critic saw none of that. It saw ten PNGs and two reference sets.

**Both bar questions: no.** Full text below, unedited.

## What moved since MA-01

Worth naming, because the point of committing failed rounds is to see the
trajectory:

- **Value range is now fine.** MA-01 measured "the darkest 1% of an entire
  exploration frame is luminance 129". This round: a 1–99 percentile spread of
  0.62–0.87, which *brackets the references*. That was the single
  highest-leverage item on MA-01's list and it landed.
- **Cast shadows work.** "Cast shadows do exist in the combat frames and they do
  sit objects on the ground — that part works."
- **The camera is no longer inside a bush.** `combat/07` and `08` show the fight.
  They have other problems, but they show it.
- **Flat-fill is no longer the headline.** MA-01's "78–91% featureless flat fill
  in the lower half of frame" does not appear in this review at all. The PBR
  ground replaced it — with a *new* complaint (high-frequency mottled noise with
  no blade direction), which is a different and smaller problem.

## What did not move

The lead complaint is the same complaint, in harder numbers. MA-01: "the roster
is one adequate stock mesh, one blob, and a Minecraft skin." MA-02: "two
untextured meshes intersecting each other on a flat khaki stripe."

Swapping one set of sourced assets for a better set of sourced assets did not
close it and was never going to. The critic's own summary: *"roughly two thirds
of the list above is scene work you can do this week, and it will visibly move
the contact sheet. But gap #1 — the creatures and the trainer — is the one the
owner's bar is actually about, and it will still be there afterwards."*

That is the plateau the MA2 plan predicted under "Risk, stated plainly".

---

# Visual review — Tetherbound Meadows survey

## First, plainly: the characters and creatures are the biggest problem in this build

The rubric asks me to lead with this, and it deserves the lead.

**The trainer (`combat/02`, `03`, `06`, `07`, `08`) is not shippable as the game's look.** Measured off `combat/02-arena-opens.png`, the head occupies ~44% of total figure height — roughly a 1:2.2 head-to-body ratio. The Palworld trainer in `palworld-03` and `palworld-05` measures around 1:4. The key art's own DAY and NIGHT panels show a normal-proportioned young adult at roughly 1:6.5. So the trainer in the build is not "between Valheim and Palworld" — it is two full stylisation registers away from **both** references, on the doll/Funko end. Beyond proportion, in the 4× crop of `combat/02`: the hair and the face are the *same hue and nearly the same value* (both salmon, RGB ~230/180/160), so the head reads as one undifferentiated skin-coloured helmet with a single black dot punched into it; the armour is untextured white-grey rounded blobs with no material identity; the hand holding the strap in `combat/06` is a smooth sausage with no fingers resolved. This is not a placeholder capsule I'm being unfair to. It is finished-looking asset in the wrong style.

**The two creatures are visibly from two different asset families and neither is designed.** In the `combat/02` 3× crop, "Bramblit" is hard-edged flat-shaded low-poly — you can count the triangles on its shoulder — in a single desaturated blue-grey with **zero albedo variation across the entire body**. The "Meadow Hopper" beside it is smooth-shaded, an order of magnitude denser, uniform mint green, also with zero texture, and its only feature is one flat red disc for an eye. Put them side by side and they read as two downloads. Compare `palworld-01`: Mammorest has a carved wooden face, layered leaf canopy, tusks, painted eye whites, and a distinct silhouette from every angle. Nothing in these frames has a second material.

**The roster does not match the project's own acceptance test.** `docs/reference/README.md` §4 names the silhouette row as the creature-pack acceptance test: rabbit, boar, deer, raptor, turtle, canine. The build ships a **frog** — named "Meadow Hopper", which reads like the rabbit slot — and a grey antlered quadruped that is somewhere between the deer and canine slots. Neither is on the board. Either the pack changes or `GAME_DESIGN.md` §26 changes, but right now the frames do not test against the board at all.

---

## 1. Silhouette and readability at 30%

Viewed at contact-sheet size, `shots/_sheet.png` is five near-identical images. I could not tell frames 01, 04 and 05 apart without the filenames. All five resolve to: blue gradient on top, a pale-green band, a dark green mound at the bottom. **Nothing in any of the five is identifiable as an object.** Trees vs rocks vs bushes vs the stone monoliths are indistinguishable — they are all small pale-green or pale-grey stamps of roughly equal size on the same value.

Measured: below the horizon, pixels with saturation > 0.25 that are **not** in the green/cyan hue band account for `03-rise-overlook` **0.000%**, `04-three-quarter` 0.002%, `05-spawn-low-sun` 0.004%, `01-spawn-outward` 0.006%, `02-valley-floor` 0.035%. The design brief says "wildflower meadows". In `03-rise-overlook.png` there are literally zero non-green chromatic pixels below the horizon out of 921,600.

The player is not readable against the ground because **the player is not in any of the five exploration frames**. Criterion 1's central question cannot be answered by this survey. That is a survey-framing failure as much as a rendering one.

In combat it is worse than the sheet suggests. In `combat/05-quick-attack-lands.png` the grey quadruped's body measures L=0.275 against ground at L=0.141 — a luminance delta of **0.134**, with essentially no hue separation (grey against green). Palworld's Grintale in `palworld-03` has an even smaller luminance delta (0.102) but survives because it is *magenta on yellow-green* — a ~180° hue offset. Palworld separates creatures from terrain with **hue and chroma**; Bramblit has neither, so at combat distance it dissolves into the grass.

## 2. Colour and value structure

Value range is not the problem — the frames measure a 1–99 percentile luminance spread of 0.62–0.87, which brackets the references. **Hue count is the problem.** Counting hue families occupying >5% of the chromatic pixels:

| | families >5% |
|---|---|
| key art | 6 |
| Palworld 01–05 | 3, 3, 4, 5, 3 |
| `01`–`05` exploration | 3, 3, **2**, 3, **2** |
| `combat/02`–`08` | **2** in six of seven frames |

Every combat frame from `02-arena-opens` onward is 70–79% yellow + 14–39% chartreuse and effectively nothing else. The key art palette strip carries eleven swatches — deep green, olive, gold, cream, warm sand, grey, slate blue, indigo, violet, mauve and two oxbloods. The build uses about three of them. The blue, violet, mauve and gold ends of the project's own sampled palette appear **nowhere** below the horizon in any frame.

The frames do not read as one place. Near-field ground luminance across the five exploration frames: `05` 0.051, `01` 0.112, `02` 0.139, `03` 0.210, `04` 0.246. That is a 4.8× swing in the same biome. `03-rise-overlook` in particular is a different game — fog has washed the whole frame to a mean luminance of 0.584 and dropped mean saturation to 0.235, against 0.51 in `02-valley-floor`. On the contact sheet frame 03 reads as an overexposed error.

**On the reserved oxblood:** it has not leaked onto friendly *elements*, but it has leaked onto a *creature*. The Meadow Hopper's eye samples RGB 233/104/80 and is the single most saturated feature in the entire combat set — the reserved danger colour is now the read on a catchable wild pal. Meanwhile the actual danger colour on the enemy HP bar (`combat/06`, RGB 163/69/51) is a near-identical red, so the eye and the "you are winning" bar say the same thing.

## 3. Intentionality

These read as generator output, not level design.

- `01-spawn-outward.png`, midfield: the tree band is one blob mesh, one green, one approximate scale, at near-regular spacing along the ridge. There is no clustering, no clearing, no scale hierarchy — nothing that says a designer put a grove here and left that hill bare. Compare `palworld-04`, where a ruin, a spire and a rock arch stack into a legible landmark composition at three depths.
- `02-valley-floor.png`, the hero tree at (350, 350): it is a **single flat-shaded polyhedron of one green** — no branch structure, no canopy break-up, no second leaf tone — on a trunk that is unlit salmon-pink (the same hue family as the trainer's face, which is not a bark colour).
- The key art's own icon row is Rolling Hills / Streams & Ponds / Oak Groves / Wildlife / Settlements. The build delivers **one of five**. There is no water in any frame, no grove (a band of separated blobs is not a grove), no structure, no path except the arena decal. The two named framings on the board — STARTING SETTLEMENT and TEAM TETHER STRONGHOLD — have no counterpart in the survey at all.
- `combat/02`–`06`: the arena boundary is a hard-edged flat khaki band splatted onto the terrain with no falloff, no edge tufts, no props marking it. It is the second-largest colour mass in those frames and it reads as a texture-splat bug, not a boundary. It is also in the same yellow-ochre family as the distant hills, so it fights the depth read as well.

## 4. Lighting

**The "low sun" frame is not a different lighting condition.** `01-spawn-outward.png` and `05-spawn-low-sun.png` are **pixel-identical across the top 200 rows** — max channel difference 0, 100% of pixels identical — and 46.8% of the entire frame is bit-identical between them. The sun disc, sky gradient, horizon haze and fog colour do not move. Only terrain shading darkens (foreground L 0.112 → 0.051). The key art's stated requirement is "day and night create different moods"; a sky that does not participate in the time of day cannot deliver that. Compare the key art's sunset panel, where the entire sky, the fog, the rim on the monolith and the ground bounce all shift together.

Terrain form is weak in the wide frames. In `03-rise-overlook.png` and `04-three-quarter.png` the mid-ground hills have almost no terminator — they are flat-lit domes. Only the near-field mound gets any shaping, and that comes from the noise texture rather than from the light.

Cast shadows do exist in the combat frames and they do sit objects on the ground — that part works. But in `02-valley-floor.png` the hero tree's shadow is a hard black blob and the trunk base sits in a dark pit measuring L=0.247 against surrounding ground at L=0.368. It reads as the trunk punching a hole in the terrain rather than meeting it.

## 5. Horizon and depth

The single most measurable composition failure: **sky occupies 39.8%–52.4% of every exploration frame** (mean 47%). The Palworld references: 2.2%, 2.5%, 8.1%, 13.4%, 21.1% (mean 9.5%). The key art: 17.8%. Half of each frame is an empty two-stop gradient carrying no information. The horizon sits at 46–52% of frame height in four of five shots — dead centre, the least interesting place it can be.

Fog is eating the world rather than describing depth. In `03-rise-overlook.png` mean saturation collapses to 0.235 and every object beyond ~150m is a grey stamp. Palworld's `palworld-04` uses comparable haze but keeps a saturated dark green tree band and a strong blue spire in front of it, so haze reads as *distance* rather than as *loss*.

**Hard artefact — chunk/dome seam in `03-rise-overlook.png`.** There is a band spanning the entire 1280px width. Row-mean luminance ramps down from 0.827 at row 237 to 0.668 at row 251, then **snaps to 0.847 at row 253** — a 0.18 step in a single pixel row, full frame width. It reads as the fog dome or a distant terrain clip plane intersecting the camera frustum. This is a bug, and on the contact sheet it is the first thing the eye finds in that tile.

## 6. Interface

- **Text contrast is failing, measured.** "Meadow Hopper" in `combat/02` and `combat/06`, and "! incoming — move" in `combat/04`, are unplated, un-outlined white over pale terrain. Measured contrast ratios: **1.45:1**, **1.38:1**, **1.45:1**. The large-text minimum is 3:1. In `combat/04` the em dash and the start of "move" are functionally invisible against the hillside. Every text element in the Palworld references sits on a dark plate or has a heavy outline.
- **Debug strings are in the HUD.** `combat/03`, `07` and `08` display a bare lowercase **`open`** under the boss health bar. That is a state-machine identifier, not player copy.
- **`combat/06`: the enemy health bar is transparent enough to see tree trunks and canopy through its interior**, and there is a smear of illegible sub-6px text baked inside it. The bar top is also clipped by the frame edge.
- **Unlabelled second bar.** `combat/02` shows an empty black bar under "Bramblit"; `combat/05`–`08` show it partly filled in tan. Two stacked bars, one label. What the second one measures is unguessable.
- **`combat/05`: the trainer is bisected by the left frame edge** — half a figure, cropped at the bottom too — and the "Bramblit" label overlaps his shoulder. The camera framed the creatures and abandoned the character during the beat labelled "quick attack lands".
- The bottom prompt row (`[A] Quick  [ ] Charged  [F] Throw  [B] Run`) shows **`[ ]`** — an empty glyph where a button icon should be, in every combat frame. In `combat/05` and later, even `[A]` has degraded to `[ ]`.

## 7. Artefacts

- **`03-rise-overlook.png`**: the full-width horizon seam described above (rows 238–253).
- **`combat/02` and `combat/03`**: the two creatures interpenetrate. Bramblit's head and shoulder are *inside* the Hopper's flank, with a green fringe where the meshes intersect. `combat/06` shows the same, worse — Bramblit's antlers emerge from the Hopper's back.
- **`combat/07` and `combat/08`**: the trainer's model is *inside* the Hopper — his head occludes its chest with no contact resolution — while the HUD says "your pal is undefended". Reads as a bug, not staging.
- **`02-valley-floor.png`**: the dark pit under the hero tree trunk (measured above).
- **`01-spawn-outward.png` around x=845, y=350**: at 8× there is at least one canopy with no trunk beneath it, sitting above the ridge line with ground visible under it.
- **Ground texture is high-frequency mottled noise, not grass.** In `combat/06` and `01-spawn-outward` the near-field terrain has visible tiling and a marbled, lichen-like albedo with no blade direction and no scale cue. It is why the bottom third of `04-three-quarter` measures a *higher* edge density (busy>5%: 62.3%) than `palworld-03` (47.6%) while looking far emptier — the detail is noise, not content.
- **`combat/05-quick-attack-lands.png` and `combat/06-charged-attack-lands.png` contain no impact effect at all.** Counting bright warm pixels (S>0.5, V>0.7, orange/yellow hue), excluding HUD bands: `combat/05` = **10 pixels (0.0011%)**, `combat/06` = 295 px (0.032%). `palworld-01-boss-fight-forest.jpg` = **24,623 px (10.66%)**. A blow landing produces roughly ten thousand times less visual energy than the reference. The only difference between `04` and `05` outside the HUD is that the creatures moved.
- **`combat/08-orb-in-flight.png` contains no visible orb.** I diffed it against `combat/07` at 64px block granularity; the largest changes are at (128,192) and (192,192) — the grey quadruped repositioning. There is no projectile, no trail, no throw arc anywhere in the frame. The catch throw — a signature mechanic — is currently invisible.

---

# The verdict

## 1. The three things that most separate these frames from the references

**1. The creatures and the trainer are not the game's art.** `palworld-01` is a bespoke boss with layered materials, a designed face and a readable silhouette; `palworld-04` fields four distinct creature designs in one frame and every one is identifiable at thumbnail size. `combat/02-arena-opens.png` fields a flat-shaded untextured grey quadruped, a smooth untextured mint frog from an obviously different pipeline, and a 1:2.2-proportion doll trainer whose hair and face are the same colour. Nothing here would survive being put beside the reference sheet. This is the gap that no scene change can close.

**2. Half of every exploration frame is empty and the other half is one colour.** `palworld-02-open-field-path.jpg` gives 2.5% of frame to sky and fills the rest with a cliff face, a cave mouth, a worn path, three tree species, tall grass at two heights, and four creatures. `01-spawn-outward.png` gives 46.8% to sky and fills the rest with one green, one blob-tree mesh repeated, and 0.006% non-green chroma. Even `palworld-04`, the airiest reference, holds 5 hue families to frame 03's 2.

**3. A fight does not look like an event.** `palworld-01` puts 10.66% of its pixels into impact sparks and swirl VFX around the moment of contact. `combat/05-quick-attack-lands.png` puts 10 pixels into it — the health bar shortens and nothing else happens. `combat/08-orb-in-flight.png` shows no orb. There is no camera push, no hit flash, no dust, no arena dressing beyond a flat khaki decal, and the trainer is half out of frame in `combat/05`.

## 2. The bar questions

> **A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?**

**No.**

What sank it: the board's five promised features are Rolling Hills, Streams & Ponds, Oak Groves, Wildlife, Settlements, and the build delivers rolling hills plus two creatures that are not on the board's silhouette row. There is no water, no grove, no structure. The board's eleven-swatch palette is represented by about three swatches, with zero non-green chroma below the horizon in `03-rise-overlook`. The board's "day and night create different moods" note is contradicted by `01` and `05` sharing a bit-identical sky. And the board's human is a 1:6.5 young adult; the build's is a 1:2.2 doll. What *did* carry: the terrain's rolling-hill language and the general green-and-blue key are right, and the near-field terrain silhouette in `05-spawn-low-sun` has genuinely pleasant shape.

> **B. Shown these frames beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?**

**No.**

They would identify the genre — there is a creature, an opponent, a trainer, health bars and a throw prompt, so the *shape* of the game reads. But asked whether the two sets are aiming at the same bar, the answer is no, and `combat/02-arena-opens.png` beside `palworld-03-field-boss-meadow.jpg` is the pair that decides it: same framing, same meadow, same beat, and one has a designed monster mid-attack with a beam, an impact burst and three allies in frame, while the other has two untextured meshes intersecting each other on a flat khaki stripe.

## What is fixable by changing the scene, and what is not

**Fixable in-engine, no new art required:**
- Sky fraction. Drop the horizon to ~25–30% of frame height in the survey cameras and reframe. This alone changes the contact sheet more than anything else on the list.
- The `03-rise-overlook` full-width seam at rows 238–253 — a real bug, and the fog/sky dome is where to look.
- Fog. `03` at mean saturation 0.235 is over-fogged by roughly a factor of two against `02`; pull density and add a saturated near-field band so haze reads as distance.
- Scatter authoring. Cluster the trees, cut clearings, vary scale 3–4×, break the regular ridge-line spacing, and stop placing every prop at the same height.
- Chroma below the horizon. Getting from 0.006% to even 1–2% non-green — wildflowers, dirt, exposed rock, a stream — is a scatter and material task, not a modelling one, and the key art palette already holds the golds, mauves and slate blues to do it with.
- The five-frame ground-tone drift (0.051 → 0.246) and the identical `01`/`05` skies. Bind the sky, fog and sun to one time-of-day value.
- The arena decal: soften the edge, drop it out of the terrain's own hue family, dress the rim.
- Every HUD item in §6: contrast plates (1.4:1 → ≥4.5:1), removing the `open` debug string, fixing the transparent bar in `combat/06`, labelling the second bar, fixing the `[ ]` glyphs, keeping the trainer in frame in `combat/05`.
- Creature/trainer interpenetration in `combat/02`, `03`, `06`, `07`, `08` — collision radii and attack spacing.
- Hit feedback and the throw. Impact flash, sparks, a screen-shake proxy, a visible orb with a trail. This is VFX and code, not character art, and it closes gap #3 cheaply.
- Bramblit's silhouette contrast: shifting its albedo off neutral grey into something with hue offset from the grass buys most of the 0.134 dL problem back without a new mesh.

**Not fixable in the scene — this needs art that is not in the build:**
- **The trainer.** Proportion, face, hair/skin separation, hands, and material definition. No lighting or scatter change touches it. This has to be replaced.
- **The creature pack.** Two assets from two different pipelines, both untextured, neither on the key art's silhouette row. The board's own acceptance test (rabbit, boar, deer, raptor, turtle, canine, cohesive) is currently unmet by 0 of 6.
- **The tree.** A single flat-shaded polyhedron with a salmon trunk is not an oak, and "Oak Groves" is one of the biome's five named features. Needs a tree set with at least canopy break-up, two leaf tones, and 3–4 silhouette variants.
- **Ground material.** The mottled noise albedo is a texture problem; a grass material with blade direction, scale cue and a non-tiling macro variation has to be authored or bought.
- **Landmarks.** `palworld-04`'s spire and ruin, and the key art's rune monolith, windmill and stronghold, are *content*. The build has grey slabs. Nothing in the scatter system produces a landmark.

The honest read: roughly two thirds of the list above is scene work you can do this week, and it will visibly move the contact sheet. But gap #1 — the creatures and the trainer — is the one the owner's bar is actually about, and it will still be there afterwards.

*Caveat on my own limits: these are static frames. Popping, aliasing in motion, traversal feel and animation quality are invisible here, and I have not judged frame rate or fidelity. The lighting findings above are structural (sun/sky coupling, fog density, shadow contact), not fine shading judgements.*

---

## What this becomes

Everything under "fixable in-engine" is MA3 work, ordered by the critic's own
leverage estimate. Everything under "not fixable in the scene" is the evidence
the owner asked for when they chose *"free art only, report the gap"* — it is
the shopping list, written by someone who was not told there would be one.
