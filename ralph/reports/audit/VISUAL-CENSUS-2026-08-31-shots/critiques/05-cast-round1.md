# Area 5 — player character + humanoid NPC cast — blind critique, round 1

Frames: `shots/census/05-cast/` (27 PNGs from `tools/_capture_character_cast.gd`,
copied here as `05-cast/`). Critic given only the sheet, the frames,
`docs/reference/` and the `visual-judge` rubric. Verbatim below.

---

I read the rubric, the key art board, all five Palworld references, the contact sheet, and 20 of the 27 frames at full size. Here is the critique.

---

# Visual critique — `shots/census/05-cast/`

## What these frames are

Twenty-six turntable frames (front + three-quarter) of thirteen humanoids on a two-tone void, plus `14-lineup-all.png`. No terrain, no foliage, no sky. That means criteria 5 (horizon/depth) and 6 (interface) have almost nothing to bite on, and I say so below rather than inventing findings. Criteria 1, 2, 3, 4, 7 and 8 are fully judgeable here, and criterion 8 is where this set does the most damage to itself.

Before anything else, the thing the rubric asks me to say first and say plainly: **`01-trainer-front.png` is the only figure in this cast that would survive being placed next to the character in `palworld-01-boss-fight-forest.jpg`.** It has modelled fingers inside a fingerless glove, real eyeball geometry with a lid and a catchlight, a layered jacket with sculpted sheepskin lining, and a readable teal accent. Everything else in the folder is below it, and several assets are far below it. The gap is not subtle and it is visible in a single glance at `14-lineup-all.png`.

---

## 1. Silhouette and readability at small size

Viewing `_sheet.png` at thumbnail scale, thirteen subjects collapse to roughly six readable silhouettes.

- **`06-grunt-archetype-front.png`, `07-rank-grunt-front.png`, `08-rank-officer-front.png` and `09-rank-captain-front.png` are indistinguishable at sheet scale.** Same mesh, same cap, same mask, same belt, same stance. The entire rank ladder is carried by one chest ornament: absent in 06, a ~10 px red bead in 07, a slightly larger bead in 08, a red disc in a gold ring in 09. On the contact sheet that bead is two to three pixels. A player will never read rank off these at combat distance, which is the only distance that matters.
- **`12-captain-ridge-front.png` and `13-captain-riverwatch-front.png` are the same character.** Same bearded head, same beard shape, same pauldrons, same magenta chest crest, same pink cape, same boots, same pose. Two named regional captains are one asset with two filenames. At sheet scale, and at full size, I cannot tell them apart.
- **`03-warden-front.png` and `10-rank-warden-front.png`** differ only by an added chest medallion. The chapter's final boss and his "rank" presentation are the same silhouette.
- **`04-villager-male-front.png` and `05-villager-female-front.png`** share a head shape, a body proportion and a value range; at thumbnail they are "small brown person" and "small olive person."
- Trainer (`01`), Grandpa (`02`), Warden (`03`) and the field captain (`11`) do read distinctly — Grandpa on white hair and a green vest, the Warden on a long coat and high collar, `11` on white hair and a wide-shouldered coat. That is four out of thirteen.

Compare `palworld-03-field-boss-meadow.jpg`: five separate actors in frame — a player, a purple boss, a red-orange pal, a blue-purple flier, a yellow-green pal — and every one is a different silhouette *and* a different hue. Nothing in this cast supports that.

Second readability failure: **every single figure is in the identical arms-down neutral idle with the same stance width, and not one carries a weapon, tool, staff, pack or gesture.** `14-lineup-all.png` therefore reads as an asset dump, not a cast. In `palworld-02-open-field-path.jpg` the player's bow, pack and hair mass are the silhouette; here the silhouette is thirteen copies of the letter "I."

---

## 2. Colour and value structure

The cast occupies one narrow mid-dark band of brown, olive, maroon and grey. Excluding the trainer's cream shirt and Grandpa's white hair, there is essentially no light value anywhere and no saturated value anywhere.

- Set `14-lineup-all.png` beside `tetherbound-meadows-keyart.png`. The board's palette strip carries a strong leaf green, a saturated gold-yellow and a warm tan. **No garment in this cast uses the gold or the leaf green.** The Warden's gold is a 2 px trim line; Grandpa's and the female villager's greens are drab olive, not the board's green.
- **The oxblood is half-respected and half-broken.** It is correctly reserved to Team Tether in `06`–`10`, which is right. But it has been desaturated to a dusty mauve-pink — see `06-grunt-archetype-front.png`, where the tunic reads as faded laundry rather than a danger colour. And then the leadership tier abandons it: **`12-captain-ridge-front.png` and `13-captain-riverwatch-front.png` wear brown armour with a magenta/lilac/cyan chest crest and a pale pink cape.** Magenta and cyan appear nowhere on the key art palette strip. A player cannot read "Team Tether" off the captains at all — they are a different faction visually from the grunts they command.
- **A value/saturation drift inside the rank ladder that reads as a bug, not a rank.** In `14-lineup-all.png`, positions 6 and 9 (`06-grunt-archetype`, `09-rank-captain`) are clearly maroon, while positions 7 and 8 (`07-rank-grunt`, `08-rank-officer`) render noticeably greyer and more desaturated. If that is a per-rank material variant it is going the wrong direction (the mid ranks are the drabbest); if it is not intentional, it is a material assignment error.
- The one saturated element in the entire set is the red bead/disc on `08-rank-officer-front.png` and `09-rank-captain-front.png`. Because nothing else is saturated, that bead is the loudest thing in the frame — and it is the least well-made thing in the frame (see §7).

---

## 3. Intentionality — authored or generated?

Two places where this reads as parameter output rather than design.

- **The rank ladder `06` → `07` → `08` → `09` is a scale slider on a sphere.** Nothing else changes: no extra shoulder armour, no coat length, no headgear change, no belt loadout, no colour promotion. That is exactly the "regular intervals, uniform scale, evenly scattered" tell the rubric names, applied to characters instead of props.
- **`12` and `13` are one file used twice.** Naming an asset after two different locations does not make it two characters.

Against this, `01-trainer-*` and `02-grandpa-*` do read as authored: Grandpa has a specific pouch loadout, rolled sleeves, a moss-collar scarf and folded boot tops that nothing else shares. `03-warden-*` also reads authored — the asymmetric coat closure and shoulder frogging are deliberate. So the problem is not that nobody authored anything; it is that the authored figures and the swept-parameter figures are in the same lineup.

---

## 4. Lighting

One three-quarter key from the front-left, very heavy ambient fill, and **no rim or back light anywhere in the set.**

- Consequence in `03-warden-front.png`: the dark green coat has almost no form. The chest panel, the belt, the hanging pouches and the coat skirt merge into one dark mass; you cannot tell the costume is layered until you get to `03-warden-threequarter.png`. The game's final boss is the least legible figure in the folder.
- Same in `14-lineup-all.png`: the four dark Team Tether figures merge into each other and into their own shadows below the knee.
- `palworld-01-boss-fight-forest.jpg` does the opposite — a hard warm key plus a bright green rim on the Mammorest, so a large dark creature separates cleanly from a dark forest. `palworld-04-plateau-landmark.jpg` gives every pal a sky-lit top edge. Nothing here has any separation light, which is a large part of why the silhouettes fail at thumbnail.
- Ambient fill is so high that skin has no core shadow: `04-villager-male-front.png`'s face is nearly flat-lit, and its cheek and jaw carry no shading turn at all.

---

## 5. Horizon and depth

Not really testable in a void-background census, and I will not manufacture findings. Two things the frames do show:

- The ground/backdrop join is a **hard aliased horizon seam** at a constant height in every frame, with no gradient blend — visible across `01-trainer-front.png` through `13-captain-riverwatch-front.png`.
- The ground plane carries **faint horizontal banding**, most visible in `05-villager-female-threequarter.png` and `09-rank-captain-threequarter.png`. Probably 8-bit gradient banding on the backdrop; harmless for a census, worth knowing if this backdrop material is shared with anything in-world.

---

## 6. Interface

Only the census overlay exists. It is legible and safely inset (~24 px, top-left). Two notes:

- It is unstyled white debug text with no plate or shadow. On this dark backdrop it reads; on a light one it would disappear.
- **`14-lineup-all.png` has no height annotation at all** — the label is just `14-lineup-all`. That is the one frame where relative scale is the entire point, and it is the one frame with the ruler removed. Every other frame carries `(trainer = 1.80 m)`. Put per-figure height ticks or a labelled 1.80 m gridline into the lineup.

---

## 7. Artefacts

Concrete, each with a frame.

- **`11-captain-field-front.png` — detached hair.** A white hair fin sits above the crown (around x≈610–660, y≈95–125) with a visible gap between it and the scalp. `11-captain-field-threequarter.png` confirms it: from three-quarter it is a separate flat card floating off the skull.
- **`11-captain-field-front.png` — the face is a flat mask.** Near-white, essentially unshaded, no nose projection, no cheekbone turn; the eye patch and the visible eye are both painted, with no eyeball geometry. The three-quarter frame shows the face plane does not curve.
- **`11-captain-field-front.png` — skin material mismatch.** The face renders near-white while the hands on the same body render dark gold-brown. Head and hands do not belong to the same person.
- **Yellow-gold fingertips on `11-captain-field-front.png`, `12-captain-ridge-front.png` and `13-captain-riverwatch-front.png`.** The glove fingers terminate in bright saturated gold tips that read as an unassigned or wrongly-assigned material — or skin punching through the glove mesh — rather than as claws or metal caps.
- **`09-rank-captain-threequarter.png` — the rank insignia is not attached to the body.** The red disc and gold ring sit on their own plane, floating clear of the bandolier, and in three-quarter it is an ellipse hanging in front of the chest rather than following the torso surface. `08-rank-officer-front.png` is worse: a plain glossy red sphere with a specular hotspot, no bezel, no cloth interaction — it reads as a debug gizmo left in the scene.
- **`12-captain-ridge-front.png` / `13-captain-riverwatch-front.png` — the chest crest is an unlit decal.** The magenta-to-cyan gradient plate does not respond to the scene's directional light at all while the leather around it does, so it reads as UI pasted onto the armour.
- **`13-captain-riverwatch-front.png` — the cape is two different surfaces.** Its outer sides are textured brown leather; the panel visible between the legs is a flat, untextured, unshaded pale-pink fill with no gradient. Same garment, two materials.
- **`13-captain-riverwatch-front.png` / `12-captain-ridge-front.png` — throat gap.** A bright tan wedge sits between the beard and the collar and reads as a hole in the collar geometry showing skin behind it.
- **`03-warden-threequarter.png` — single-sided cloth.** The coat tails are thin planes; the left-hand tail (around x≈530–560, y≈470–590) has a hard flat silhouette with no thickness. Same problem on the hanging leather straps in `11-captain-field-front.png`.
- **`02-grandpa-front.png` / `02-grandpa-threequarter.png` — fused hands and short arms.** Both hands are mitten blobs with no separated fingers, and they interpenetrate the hip pouch geometry. The forearms read truncated; the hands stop at mid-thigh.
- **`04-villager-male-front.png` / `05-villager-female-front.png` — mitten hands, painted faces.** The hands are undifferentiated flesh paddles. The eyes are painted discs on a flat surface with hard-edged sclera, no lid geometry. Shirt buttons, vest stitching and belt hardware are all painted into the texture with no modelled relief, and the face texture is visibly lower-resolution/softer than `01-trainer-front.png`'s at the identical screen size.
- **Shadow quality.** The cast shadow is a low-resolution blurred blob with visible stair-stepping — clearest in `11-captain-field-front.png` around x≈690–780, y≈590–660, and along the edge in `01-trainer-front.png` around y≈590–640. There is also no contact darkening directly under the feet; in `03-warden-front.png` and `12-captain-ridge-front.png` the blob is offset far enough right that the left boot has no occlusion under it and the figure reads slightly detached from the ground.

---

## 8. Scale agreement — the loudest problem

The ruler is in the picture, so I measured head heights against total height in the front frames.

| Frame | Labelled height | Measured heads-tall |
|---|---|---|
| `02-grandpa-front.png` | 1.72 m | ≈ 4.3 |
| `01-trainer-front.png` | 1.80 m | ≈ 5.0 |
| `04-villager-male-front.png` | 1.78 m | ≈ 5.0 |
| `05-villager-female-front.png` | 1.75 m | ≈ 5.0 |
| `06-grunt-archetype-front.png` | 1.80 m | ≈ 5.3 |
| `11-captain-field-front.png` | 1.90 m | ≈ 5.8 |
| `12-captain-ridge-front.png` | 1.90 m | ≈ 6.8 |
| `03-warden-front.png` | 1.85 m | ≈ 7.5 |

**The cast spans 4.3 to 7.5 heads tall while all being labelled within 10 % of the same height.** That is not a stylistic range; that is three different character pipelines standing in one line. `14-lineup-all.png` shows it without any measuring: Grandpa (position 2) has a head visibly ~1.5× the width of the Warden's (position 3) standing immediately beside him, at the same shoulder height. Grandpa and the villagers read as stylised near-chibi adults; the Warden reads as a 7.5-head realistic figure; the captains sit between. Palworld holds one proportion across its whole human cast — the player in `palworld-02`, `palworld-03` and `palworld-05` is recognisably the same build every time.

A related scale reading, offered as observation rather than a design judgement: in `14-lineup-all.png` **the Warden does not read as the apex of his faction.** The frame labels put him at 1.85 m against 1.90 m for `11`/`12`/`13`, and the captains are also visibly broader through the shoulder and pauldron. The boss of the chapter is the shortest and narrowest of the leadership tier. Whether the Warden *should* be physically largest is yours to decide; what a still frame can tell you is that right now nothing in his massing says "final."

The villagers' *body* proportions are also at odds with their labels: `04-villager-male-front.png` at 1.78 m has a child's torso-to-leg ratio, a child's arm length and a child's head. Standing next to `01-trainer-front.png` at 1.80 m, they do not look like two adults of the same height.

---

# Verdict

## The three things that most separate these frames from the references

**1. This is not one cast — it is three character pipelines in one lineup.** `14-lineup-all.png` puts a 4.3-head Grandpa, a 5.0-head painted-eye villager pair, a 5.3-head Team Tether grunt, a 5.8-head flat-masked captain and a 7.5-head Warden shoulder to shoulder, all labelled 1.72–1.90 m. Every Palworld reference — `palworld-02`, `palworld-03`, `palworld-05` — holds a single consistent human proportion, and holds it across creatures too. The key art's DAY and NIGHT panels likewise show one figure language. Concretely: the references never make you ask which studio made which character; `14-lineup-all.png` makes you ask it four times.

**2. Identity is unreadable — four ranks and two captains are two models.** `06`/`07`/`08`/`09` are one mesh separated by a chest bead that is 2–3 px on the contact sheet; `12` and `13` are the same asset named twice; `03` and `10` are the same asset plus a medallion. In `palworld-03-field-boss-meadow.jpg` five actors are simultaneously distinguishable by silhouette *and* hue at combat distance. Here, four Team Tether ranks are not distinguishable at any distance.

**3. No separation light and no colour, so nothing pops.** There is no rim light in the entire folder, and the whole cast sits in one narrow desaturated brown-olive-maroon band. `03-warden-front.png` — the boss — loses its entire layered coat into one dark mass. `palworld-01-boss-fight-forest.jpg` uses a hard key plus a bright rim to separate a dark creature from a dark forest; `tetherbound-meadows-keyart.png` promises "vibrant, readable colours" and carries a saturated leaf green and gold in its palette strip that no garment here uses. Instead the only saturated colours in the cast are a plastic red bead (`08`) and a magenta/cyan crest (`12`, `13`) that belongs to no established faction palette.

## The two bar questions

### A. Do these read as belonging to the world of `tetherbound-meadows-keyart.png`?

**No.**

What carried: `01-trainer-front.png` / `01-trainer-threequarter.png` is genuinely on-board — the teal jacket, the cream shirt, the brown leather and the key pendant sit inside the board's palette and match the figure standing in the DAY panel. `02-grandpa-*` is close behind. `03-warden-*` is a defensible read of a Team Tether officer.

What sank it: the captains. `11-captain-field-front.png`, `12-captain-ridge-front.png` and `13-captain-riverwatch-front.png` are generic fantasy-MMO knights with magenta/cyan heraldry and pink capes; those hues do not exist on the board's palette strip, and the board reserves its one red for Team Tether stronghold banners. The villagers (`04`, `05`) are a lower-fidelity doll style with painted eyes and mitten hands that the board's rendered figures do not share. And the board's whole promise is "vibrant, readable colours" — `14-lineup-all.png` is thirteen shades of mud.

### B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**No.**

The trainer alone would pass. The set would not. Shown `14-lineup-all.png` next to `palworld-04-plateau-landmark.jpg`, the honest reading is "a good hero character plus an asset-store supporting cast." The specific tells are the mitten hands and painted eyes on `04`/`05`, the flat unshaded mask-face and detached hair card on `11`, the primitive-sphere rank insignia on `08`/`09`, the duplicated captain across `12`/`13`, and the fact that thirteen characters share one pose and hold nothing.

## Fixable by changing the scene vs. needs art that is not in the build

**Fixable by scene/config change — this half is work you can schedule now:**

- **Add a rim/back light and cut ambient fill.** Single largest readability win; directly fixes `03-warden-front.png`'s formless coat and the merged dark figures in `14-lineup-all.png`.
- **Shadow rig:** raise shadow map resolution / fix bias to kill the stair-stepping in `11-captain-field-front.png` and `01-trainer-front.png`, and add contact darkening so `03-warden-front.png` and `12-captain-ridge-front.png` stop reading as detached from the ground.
- **Palette grade on the faction.** Push the grunt oxblood back toward the board's reserved red instead of dusty mauve (`06-grunt-archetype-front.png`), and reconcile the grey drift on `07-rank-grunt-front.png` / `08-rank-officer-front.png` so the mid ranks are not the drabbest of the four.
- **Restage the captains onto the faction palette.** Recolouring `12`/`13`'s magenta/cyan crest and pink cape to oxblood-and-gold is a material change and would immediately restore the "these command those grunts" read.
- **Pose and prop variation in `14-lineup-all.png` and the individual frames.** Give each figure its idle, its stance and its held object. This is scene work, and it recovers a large share of the silhouette failure without a single new mesh.
- **Put a labelled 1.80 m gridline / per-figure height ticks into `14-lineup-all.png`**, which currently has the ruler stripped out of the one frame that needs it.
- **Make the Warden's massing read as apex** — scale, or at least stop the captains out-shouldering him — insofar as that is a transform rather than a remodel.

**Needs art that is not in the build — this half is evidence for what has to be made or bought:**

- **The 4.3-to-7.5-head proportion spread.** No lighting or grading fixes this. Grandpa and the two villagers need remodelled heads/bodies to sit in the same proportion family as the trainer, or the trainer has to move to theirs. This is the single most expensive finding and the one that most decides question A.
- **Villager faces and hands** (`04-villager-male-front.png`, `05-villager-female-front.png`): modelled fingers, eyeball geometry with lids, and a face texture at the trainer's resolution. Not recoverable by rendering.
- **`11-captain-field-*`'s head**: the flat unshaded mask-face, the missing nose/cheek forms, and the detached hair card all need remodelling. Also the head/hand skin material mismatch.
- **A second captain.** `12` and `13` being one asset cannot be fixed by any scene change; one of the two regional captains does not exist yet.
- **An authored rank ladder.** Replacing a scaled sphere with real rank language — shoulder armour, coat length, headgear, belt loadout, a promoted accent colour — is modelling and texturing work. A bigger bead will not fix `06`→`09`, and neither will a brighter light.
- **Cloth thickness** on the Warden's coat tails (`03-warden-threequarter.png`), `11`'s hanging straps and `13`'s cape — currently single-sided planes.
- **`12`/`13`'s throat gap and gold-tipped glove fingers** — these look like mesh/material authoring errors in the source asset, not scene state.
