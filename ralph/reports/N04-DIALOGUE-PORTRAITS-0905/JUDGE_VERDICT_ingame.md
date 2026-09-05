# Visual judge — in-game conversation frames

Contact sheet: `ingame_conversations.png`, two 1280x800 frames stacked.
Frame 1 = top (name **Halda**, `Day 1 · 08:04`). Frame 2 = bottom (name **Oskar**, `Day 1 · 08:06`).
Judged from pixels only. No score.

---

## A. Does the plate read as the person standing in the scene?

**Frame 1 — Halda: yes, identity matches; the world figure is the broken one.**

Matched, feature by feature:

- **Garment.** Plate: olive-green hooded jacket, hood folded back over the shoulders, two
  gold/brass ornamental clasps flanking a gold centre knot, cream front panel beneath.
  World: identical olive hood with the same gold centre knot and the same pair of brass
  clasps, same cream tunic under it. This is a strong, unambiguous match — the clasp
  ornament is distinctive and it is the same ornament.
- **Hair shape.** Both are a chin-length bob, parted so a wedge falls over the right brow,
  with a longer sidelock in front of the ear. Same silhouette.
- **Face.** Same heavy dark eyebrows, same wide dark iris, same small nose, same young
  round jaw.
- **Skin.** Plate skin is warm (≈`197,165,144`). World skin on the lit cheek is warm but
  much paler and higher-key (≈`206,198,191`) — she reads chalky in world, warm in the plate.

Failed to match:

- **Hair colour.** Plate crown samples ≈`146,143,149` — a mid lavender-grey with visible
  strand shading. World crown samples ≈`197,199,203` — a near-white, almost neutral pale
  grey with essentially no value modelling. That is roughly 50 levels brighter and
  desaturated. Same character, but the world hair is a different, flatter, whiter material.
- **The face damage** (see C) exists in both, large in the world figure and small in the plate.

Name/subject consistency: the line is self-identifying ("Halda. I keep the board and I keep
the draw honest") and the woman in frame is the only NPC present. Consistent.

**Frame 2 — Oskar: yes, and cleanly.**

- **Garment.** Plate: cream collared shirt, buttoned placket, brown leather waistcoat with a
  dark outline and a scrolled/heart embroidered motif on the chest panel. World: the same
  cream shirt with rolled short sleeves, the same brown waistcoat, and the same scrolled
  motif in the same place on the chest. Match.
- **Hair.** Dark brown bowl cut with a straight fringe and a sidelock in front of the ear, in
  both. Same colour family, plate slightly warmer/lighter (`103,74,48`) than the world
  figure's near-black lit-side (`13,8,1`) — the world Oskar is standing in shade, which
  accounts for most of it.
- **Face.** Same heavy straight brows, same narrow flat mouth, same jaw. Match.

The name **Oskar** and the line ("Bridgehand's my trade") are consistent with the single male
villager in the frame. Nothing contradicts.

---

## B. Two portraits, or one image twice? And could either be the player?

**Two different people, unmistakably.** Halda: pale silver-lavender bob, green hood, gold
clasps, smiling. Oskar: dark brown bowl cut, cream shirt, brown embroidered waistcoat,
neutral mouth. Different hair colour, different hair shape, different garment, different
expression, different framing within the plate. There is no risk of reading these as the
same asset.

**Neither could be mistaken for the player.** The player (right of frame, both shots) has
tousled/spiky mid-brown hair falling over the ear and forehead, a teal-blue jacket with a
thick white sheepskin collar and cuffs, a leather chest strap, and a cream canvas backpack.

- Halda shares nothing with that — different hair colour entirely.
- Oskar is the closer call, because the hair colour is in the same brown family
  (plate `103,74,48` vs player `118,78,40`). But the *shape* separates them at a glance: Oskar
  is a flat, neat, blunt bowl cut with a straight fringe; the player is layered and spiky with
  hair sweeping past the ear. And the clothing is unambiguous — brown waistcoat over a cream
  collared shirt versus a teal jacket with a white fur collar. No confusion.

---

## C. NPC hair in the world vs hair in the plate

**Frame 2 (Oskar): clean.** Dark brown in both, same bowl silhouette, a legible highlight
band across the crown, one small white speck near the right temple (sub-pixel, ignorable). No
patchiness, no bleed, no seams. This head is fine.

**Frame 1 (Halda): the world head is badly broken. Three separate defects.**

1. **A seam lattice printed across the hair.** Crop tight on the crown (roughly x 550–625,
   y 305–360). Running across the pale dome is a network of thin, one-pixel dark lines in
   straight angular runs — a hairline arc across the top of the skull, a diagonal from the
   crown to behind the ear, a shorter run above the temple — plus isolated dark-brown specks
   scattered in the same region. These do not follow the hair's flow and they do not look like
   stylised strands; they read as UV-island edges or a wireframe baked into the texture. At
   1:1 they are visible as dirt on the head; at 8x they are obviously geometric.

2. **Hair colour bleeding onto skin — the worst of the three.** The right half of Halda's
   face, from the brow line down over the cheek, the side of the nose, the corner of the mouth
   and the whole jaw, and continuing down onto the neck and under the chin, is covered by a
   flat, **perfectly neutral** mid-grey. Sampled values in that region are `131,130,130`,
   `132,130,130`, `130,128,129` — R, G and B within two levels of each other. The skin
   immediately beside it is warm: `203,190,179`, `186,155,130`. A shadow on skin keeps the
   warm hue ratio and only lowers the value; this does not — it is a desaturated grey material
   pasted over the skin, the same grey as the hair. The boundary is a hard, stair-stepped
   diagonal running from beneath the eye to the jaw, not a soft terminator. Half her face is
   painted with her hair.

3. **The hair has no form.** Even setting the artifacts aside, the world hair is a flat
   near-white shell with almost no light-to-dark range across a curved surface. It reads as a
   latex swim cap or a helmet, not hair. The plate version of the same hair has proper shading
   and separates into strands; the world version does not. Compare directly against Oskar's
   world hair in frame 2, which has a real dark base and a highlight — the difference is not
   the lighting, it is the material.

Related, same defect family, outside the head: Halda's bare right calf carries a hard-edged
pale-grey patch (crop x 520–680, y 520–610) that matches nothing anatomical. Whatever is
leaking onto her face is leaking onto her legs too.

**The plate is not clean either — it carries a smaller copy of defect 2.** In the portrait,
Halda's right cheek has a dark grey-brown streak (`98,89,89`, `86,73,69`) sitting on warm skin
(`180,158,146`), running from below the eye toward the jaw, plus dark brown flecks in the hair
at the right jawline. Same artifact, same place on the face, roughly a third the size. So the
plate is a render of the same broken head at a friendlier angle — the portrait pipeline is not
the problem, the head asset is.

---

## D. Inside the dialogue box

Geometry is consistent and correct: both plates are exactly 133x133 px at the same screen
position (x 157–289). That part is right. What is wrong:

1. **The plate ground is a flat light grey slammed against a near-black panel.** Panel is
   ≈`16,19,16`. Halda's plate ground is `223,223,223`; Oskar's is `242,242,242`. That is a
   near-maximum value jump with no transition — the plate reads as a passport photo taped to a
   dark panel, and in a dark scene it is the brightest object on screen, brighter than any
   part of the world. It pulls the eye off the name and the line, which is the wrong hierarchy.
2. **The two plate grounds are not even the same grey** (`223` vs `242`). Whatever generated
   them was not colour-managed against a single value. Side by side in a conversation chain
   this will visibly flicker between speakers.
3. **No frame, no border, no rounding.** The plate is a bare hard-edged square. The panel
   around it has a soft dark gradient and a thin light outline; the plate ignores both. Nothing
   ties the portrait to the UI it sits in.
4. **Framing is inconsistent between the two.** Halda's subject spans 98 px of the 133 px
   plate width starting 5 px down; Oskar's spans 110 px starting 8 px down, and his head reads
   noticeably larger and sits nearer the top edge. Portraits in a chain should share a crop
   rule — same head height, same eyeline, same headroom. These do not.
5. **The panel is translucent over a busy background.** Grass blades and, on the right, the
   player's backpack and belt gear are clearly visible through the panel in both frames. The
   "Continue" prompt in particular sits over the player's kit rather than over a solid ground.
   It is legible today because the text is heavy white, but it is legible in spite of the panel,
   not because of it.
6. **Style mismatch.** The plate is a lit 3D render with soft shadows and a photographic
   background sweep; the panel is flat matte UI. Nothing in the plate is stylised toward the
   panel — no rim, no vignette, no palette tie.

---

## E. Outside the box, worst first

1. **A parchment notice board is jammed against the camera in frame 1**, filling the right
   quarter of the screen with a flat cream slab and unreadable black bracket glyphs. It occludes
   the player's shoulder and dominates a shot that is supposed to be about a conversation.
2. **The location banner is cut off by the screen edge in frame 1** — "…VER MEADOWS" runs off
   the right side of the frame, and what remains of it is half-hidden behind the MAIN STORY
   card. Two UI elements colliding, one of them outside the safe area.
3. **Neither NPC casts a contact shadow.** Halda's boots sit on top of the grass with no
   darkening at all beneath them; Oskar the same on bare dirt. Both figures read as pasted onto
   the ground rather than standing on it. The keyart's characters (DAY/NIGHT panels) sit in the
   grass with a shadow anchoring them.
4. **The two frames disagree about lighting two in-game minutes apart.** Frame 1 is bright and
   high-key to the point that Halda's bare legs are nearly blown out; frame 2 is murky, with
   Oskar's shirt and the ground both dropped into brown mud. Same village, 08:04 and 08:06.
   They do not read as one place at one time of day.
5. **The hero tree in frame 2 is a different palette from every other plant in the shot** — a
   near-neon saturated green with hard black voids between the foliage cards, next to muted
   olive background trees. It reads as a different asset family, or an LOD that never blends.
6. **Foliage colour noise in the frame 2 foreground canopy** — navy-blue and maroon leaf cards
   mixed into the green at the top-left, seen edge-on. Reads as a bug, not autumn.
7. **Distant terrain has no material.** The hillside behind the tree in frame 2 and the mountain
   in frame 1 are smooth untextured grey-green masses with hard silhouette edges and visible
   flat-shaded facets. No rock, no cliff, no landmark language.
8. **Tree scatter reads as generated in frame 1** — a line of near-identical trees at similar
   height and tint strung along the ridge, no clustering, no clearings, no scale variety.
9. **Ground cover is thin.** Sparse grass cards over a flat green texture, with a hard-edged
   transition to bare brown dirt under Oskar. Against `palworld-02` / `palworld-03`, the
   mid-ground here is mostly empty.

---

## The three things that most separate these frames from the references

1. **Halda's head is visibly broken art shipped as final** (frame 1) — hair colour painted over
   half her face, a seam lattice across the crown, and a flat white cap where hair should be.
   Nothing in `tetherbound-meadows-keyart.png` or any `palworld-0*.jpg` has a character whose
   texture is bleeding onto their skin. This is not a stylisation gap, it is a defect, and it is
   present in miniature in the portrait plate too.
2. **Characters do not sit in the world** (both frames) — no contact shadow under either NPC,
   and no shadow under the player. The keyart's DAY and NIGHT panels place figure and creature
   on the ground with a shadow; `palworld-05` grounds its character and its Lamball the same way.
   Here they hover.
3. **The frames do not agree that they are one place** (frames 1 vs 2) — high-key washed grass
   and near-white skin in one, muddy brown ground and crushed shadow two minutes later in the
   other, plus one neon tree that belongs to neither. The keyart board's whole point is a
   consistent natural palette across six panels; these two cannot hold it across two.

## The two bar questions

**A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?**
**No.** The silhouette language is close — rolling green hills, oak-shaped trees, split-rail
fence, timber props, and the villagers' costume design genuinely is the board's costume design.
But the board's value structure (deep shadowed groves against sunlit meadow, warm-to-cool depth)
is absent: frame 1 is one bright mid-tone with no shadow anywhere, frame 2 is one dark mid-tone.
Fixable by changing the scene: lighting and exposure consistency, contact shadows, the neon tree's
material, foliage colour noise, tree scatter and clustering, ground-cover density, and the notice
board's placement relative to the conversation camera. Not fixable by scene changes: Halda's head
texture and the flat hair material — that needs the asset repaired.

**B. Would someone say these are trying to be the same kind of game as `palworld-0*.jpg`?**
**Yes, narrowly.** The character art style, the stylised proportions, the third-person
over-the-shoulder conversation framing and the HUD furniture (minimap, quest card, prompt chip)
all read as the same genre and the same ambition. What separates them is finish, not intent:
Palworld's ground is dense and its characters are grounded and clean. The one thing here that
would break the comparison for a viewer is Halda's face — a shipping game does not have grey
paint across half an NPC's cheek.

