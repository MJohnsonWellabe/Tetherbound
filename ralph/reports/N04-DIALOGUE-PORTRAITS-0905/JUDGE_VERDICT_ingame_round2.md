# Blind visual verdict — in-game conversations, round 2

Source: one contact sheet, two 1280x800 in-game frames stacked (frame 1 = top,
y 0–799; frame 2 = bottom, y 800–1599). All coordinates below are sheet
coordinates. All RGB values are sampled from the PNG, not estimated.

No score, per the rubric.

---

## A. Does each portrait plate read as the person standing in the scene?

**Frame 1 — "Halda". Yes, the identity reads.** Feature by feature:

| Feature | Plate (x 157–289, y 612–744) | Standing NPC | Match |
| --- | --- | --- | --- |
| Hair colour | crown mean **(138,135,142)**, a silver with a slight violet lean | crown mean **(182,184,179)**, silver, near-neutral; darks fall to (97,105,115) and (69,81,96) | Same silver family. World is brighter because it is sunlit; the plate is a touch more violet. |
| Hair shape | chin-length bob, parted fringe with a peak, a lock hanging in front of each ear | same chin-length bob, same forward ear-locks; fringe here sweeps across and covers the far brow | Same haircut, different angle |
| Clothing | olive-green hooded jacket, gold/tan frogging and a knotted cord at the throat, cream underlayer | same olive-green hood, the same gold knot and trim at the throat, cream shift, brown belt and pouch below | Match, and the gold throat-knot is specific enough to be conclusive |
| Face | warm tan skin, dark brows, brown eyes, closed smile | pale, near-neutral skin; one visible dark eye; mouth buried under a grey wash (see C) | Structure matches, **colour does not** |

The one real discrepancy is skin chroma. Plate cheek mean **(191,159,139)** —
R−B = **+52**, a warm tan. World cheek mean **(191,184,177)** — R−B = **+14**.
Identical luminance, roughly a quarter of the chroma. Side by side, the portrait
looks healthy and the model looks ashen. It does not break the identity, but it
is the kind of mismatch a player registers as "the portrait is nicer than her".

**Frame 2 — "Oskar". Yes, and this one is cleaner.**

| Feature | Plate (x 157–289, y 1412–1544) | Standing NPC | Match |
| --- | --- | --- | --- |
| Hair colour | crown mean **(67,46,31)** — a readable dark warm brown with a visible highlight | crown mean **(15,9,2)**, median **(11,5,0)** | Same intent, but see C — the world hair is crushed to black |
| Hair shape | short side-parted bowl cut, straight fringe edge above the brow | identical bowl cut and fringe line | Match |
| Clothing | cream collared shirt under a brown leather waistcoat with tan piping | same cream rolled-sleeve shirt, same brown waistcoat with tan piping and an embossed chest motif, brown belt, brown breeches | Match, unambiguous |
| Face | pale skin, heavy dark brows, dark eyes, straight mouth | same heavy brows, same face; skin cheek **(144,142,139)** vs plate **(209,178,155)** | Structure matches; he is in tree shade, so most of the gap is legitimate lighting |

**Names.** "Halda" over the silver-haired woman, "Oskar" over the dark-haired
boy. Both correct. Nothing is mislabelled.

---

## B. Are the two plates two different people? Could either be the player?

**Two clearly different people.** Silver bob + olive-green hood versus dark
bowl cut + brown leather waistcoat. Hair value alone separates them by a factor
of two (138 vs 67 crown mean), and the garment colours do not overlap. They
still read as different at 30% zoom, which is the harder test.

**Neither is the player, but Oskar is the near miss.** The player (right of
frame, backpack, white fur collar) has voluminous shaggy mid-brown hair —
frame 1 sample mean **(86,58,33)**, 95th percentile (167,124,92) — over a teal
tunic. Oskar's plate is brown hair (67,46,31) over cream and brown. Same
hair family, same pale young face; what saves it is silhouette (neat bowl vs
shaggy mass) and the teal, which nothing else in either frame wears. At
thumbnail size the pair reads as "two brown-haired boys", which is thinner
separation than I would want from a cast this small. Halda is in no danger of
being confused with anyone.

---

## C. The standing NPCs' heads, close

### Frame 1 — Halda (crop x 540–625, y 300–400)

**Hair — clean. This is the best-rendered thing in either frame.**

- Not one flat colour. Luminance runs **57 to 208** across the mass: the crown
  is a bright near-neutral silver (190,190,191), the side masses fall to
  (97,105,115) and the deepest fringe to (69,81,96). The darks shift **cool
  blue**, which is a correct and deliberate-looking choice against warm skin.
- Strand structure is present and readable at 6x: fine diagonal striations run
  along the sweep of the crown and down the ear-locks, and the part line reads
  as a slightly darker channel rather than a drawn line.
- **No seams, no patches of a foreign colour, no thin dark lines.** I scanned
  the whole hair mass (x 556–608, y 312–345, ~1700 px) for pixels with R−B > 16
  that were not grass. Twenty-two hits, every one of them on the silhouette
  edge (x 556–565 and x 601–607) — antialiasing against the grass behind, not
  colour in the hair. The one dark speck near the crown at **(604,314) =
  (91,103,118)** is the same cool blue-grey as the rest of the shadowed hair;
  it is a strand gap, not a hole or a stray texel.
- Versus the plate: same colour family and same shape, world brighter and
  slightly less violet. No complaint.

**Face — there is a problem, and it is the loudest thing on this character.**

A large **flat, neutral grey region** covers her left cheek, jaw, **the whole
mouth**, and spills onto the neck. Measured:

- Inside the region: **(131,130,129)**, and it stays there — (131,130,130),
  (131,130,129), (130,129,129), (131,129,129) across six consecutive pixels at
  y 374, over a curved cheek.
- Lit skin two pixels away: **(205,198,190)**.
- The transition is **one pixel wide**: at y 370, x 597 = (176,168,161) →
  x 598 = (131,130,130). At y 374, x 591 = (165,157,151) → x 592 = (131,130,129).

Two things make it read as a grey patch stuck on her face rather than as
shading. First, the interior has **zero gradient** — a shaded cheek is curved
and should fall off. Second, it has **zero hue**: R−B = +1. Every other shadow
in the frame keeps its hue — her own under-chin shadow is **(118,103,92)**,
R−B = +26, and the player's shadowed jaw in the same frame is **(130,116,106)**,
R−B = +24, at the same brightness. Whatever the cause (it is shaped and edged
like a hard shadow-map cast from her own fringe, landing on an already
low-chroma skin albedo), the on-screen result is that **half her face is a flat
grey slab and her mouth is inside it.** Her expression is gone. This is the
single most damaging defect in either frame's character rendering.

**Colour on the skin that should not be there:** yes, on the throat. Cream skin
**(204,183,165)** carrying irregular mid-brown blotches — **(106,90,79)** and
**(130,110,95)** — in two soft-edged blobs that do not follow the jaw line the
way an under-chin shadow would. They read as dirt smudges. There is a matching
but much smaller warm smudge on the plate's left cheek (**(171,150,140)** mean
against (191,159,139) skin), so a smudge appears to be authored into the face —
but on the model it is bigger, greyer, and lands on the neck.

### Frame 2 — Oskar (crop x 540–620, y 1090–1180)

**Hair — crushed.** Median **(11,5,0)**. **28% of the hair pixels are pure
black** (channel sum ≤ 6). Mean (22,21,13). There is no strand structure and no
light-to-dark shading to speak of — it is one black mass with a barely-there
warm edge at the crown. The plate's version of the same hair is a legible dark
brown at (67,46,31) with a highlight. For scale, the player's hair in the same
frame, at the same time of day, means **(94,65,42)** and reads as brown. So this
is not the scene being dark; this hair specifically is clipping to zero. At any
distance it is a hole in the character's silhouette.

**Face — clean of patches.** Evenly lit, no grey slab, no smudges, no seams.
Skin is **(144,142,139)** — near-neutral. He stands in tree shade, so low
brightness is expected, but the player's shaded skin in the same frame is
**(145,127,112)** at the same luminance and stays warm. Oskar's skin is greyer
than the player's for no visible reason. Same direction as Halda.

---

## D. Inside the dialogue box

1. **Halda's line opens by repeating her own name.** The label says "Halda" and
   the first word of the line is "Halda." Oskar's line does not do this. It
   reads like a template artefact, and the repetition is directly stacked —
   name label and first word are 40px apart vertically.
2. **The two portrait plates do not match each other.** Plate 1's background is
   a uniform **(222,222,222)**; plate 2's is **(242,242,242)**. Their subject
   lighting differs too — plate 2 is a full stop brighter and warmer (skin
   209,178,155 vs 151,131,119). They were clearly not rendered in one pass.
3. **The plates punch white holes in the panel.** Both are hard-edged squares
   of near-white sitting on a panel that is **(16,18,16)** — roughly a 14:1
   value jump, with no frame, no corner rounding, no border, no vignette, and
   no attempt to match the panel's language. They look like screenshots pasted
   into a UI rather than part of one.
4. **A background sliver bleeds through inside plate 1's silhouette.** At
   y 692, x 236–238, pure plate background **(214,214,214)** and (213,213,212)
   appears as a 2–3px bright streak in the gap where the hair lock meets the
   shoulder, with dark hair (94,75,70) on one side and dark collar (93,93,90)
   on the other. A bright cut through the middle of the character.
5. **The panel is transparent enough to be noisy.** Grass blades and the
   player's backpack read clearly through it — inside frame 2's panel at
   (700,1500) the value is **(93,95,97)** against (14,16,16) elsewhere. White
   text still clears contrast, but bright blades cross the text field.
6. **Only a keyboard glyph on the advance prompt** — a white "E" key cap next
   to "Continue", with no controller face-button alternative shown.
7. **Layout.** The panel is ~1000px wide and both lines rag well short of it;
   the block bounded by the second line, the right edge and the "Continue" row
   is dead space. Name colour (198,183,122) over white body text is a correct
   hierarchy and the type is legible; those parts are fine.

---

## E. Outside the box, worst first

1. **Frame 2's near tree is confetti, not foliage.** The canopy is a spray of
   individual hard-edged alpha-clipped leaf cards in colours that do not belong
   to one plant: fully clipped pure greens with **both R and B at zero** —
   (0,69,0), (0,85,6), (0,107,13) — mixed with ~4% maroon/brown cards
   (mean 114,74,55) and black gaps between them. There is no canopy mass and no
   silhouette. The distant trees in the same frame are soft round green blobs,
   so near and far foliage do not read as the same species or the same game.
   The tree at the top-left corner has the same problem plus purple flecks.
2. **Untextured grey geometry in shot.** A faceted grey boulder sits directly
   behind Oskar's head (x 505–570, y 1085–1130) like a headrest, flat and
   texture-free with no moss, no wear, and no darkening where it meets the
   grass. A second, larger blue-grey slab fills the lower right of frame 2 —
   completely smooth, two long specular streaks, a hard edge against the grass.
   Both read as placeholders.
3. **Nothing casts a contact shadow.** Halda's boots, Oskar's boots, the
   boulder, the near tree's trunk, the fence posts — all meet the ground with
   no AO and no darkening. The grass under a boot is the same value as the
   grass 30px away. Everything is sitting on the world rather than in it.
4. **Skin is the brightest thing in frame 1.** Halda's bare arm is
   **(212,209,203)**; the sky is (130,149,159) with a max of 187. Her legs and
   arms out-glow the sky, so the eye lands on a shin. The key art puts its
   value peaks in the sky and on lit canopy tops.
5. **The two frames disagree about exposure two in-game minutes apart**
   (08:04 and 08:06). Frame 1 foreground grass means **(86,93,26)**; frame 2
   foreground grass means **(40,26,2)** — a near-black muddy band across the
   bottom third. They do not read as one place at one time of day.
6. **The meadow has almost no blue in it.** Grass means (82,93,28) in frame 1
   and (99,107,17) in frame 2 — the blue channel is nearly absent, so the whole
   ground plane is a two-channel acid olive. The key art's meadow carries cool
   blue-greens in shade against warm yellow-greens in sun; that whole axis is
   missing here.
7. **Ground cover is sparse and procedural-looking.** A flat painted grass
   texture with thin identical billboard blades at even spacing, one repeated
   flower clump, and a blurry crossfade where grass meets dirt. Frame 1's tree
   line is a row of near-identical trees at near-identical heights and tints
   along a ridge. Palworld's ground at the same camera distance is dense enough
   that you cannot see the terrain texture; here the texture is most of what
   you see.
8. **Frame 1's right quarter is a noticeboard plane that reads as UI in the
   world** — a flat cream board with oversized black italic lettering
   ("...VER MEADOW...") and rows of repeated squiggle strokes, clipped by the
   screen edge and half-hidden behind the quest card. Unfinished.
9. **Composition.** In both frames the player is jammed against the right edge,
   cropped by the frame and by the dialogue box, with his lower body poking out
   below the panel; the person actually speaking is at centre-left with a wide
   empty gap between them. Neither frame is composed as a conversation.
10. **Proportions.** Both villagers are about **4.3 heads tall** (Oskar: 70px
    head, ~300px standing height). That is a chibi build, noticeably shorter in
    the head-count than the figures on the key art board, and it sits oddly
    beside the more realistically proportioned player.
11. **Minor artefacts.** A regular dotted line of evenly spaced black specks on
    the grass at the lower right of frame 2 (a tiling or decal seam). Minimap
    pins clipped by the map's rounded frame in both frames. Frame 1's
    mid-distance hill is a bald grey-tan lump with a hard texture transition
    and no rock detail.

---

## Closing, per the rubric

**The three things that most separate these frames from the references**

1. **Foliage that has no mass.** The key art's oaks are dense rounded canopies
   with a readable silhouette from a distance, and the Palworld shots hold that
   at real-time. Frame 2's near tree is loose leaf cards in four unrelated
   colours with black gaps and pure-clipped greens (0,69,0). It is the first
   thing the eye hits and it reads as broken, not stylised.
2. **Nothing is anchored.** Both references put every object on the ground with
   a contact shadow and an occlusion darkening around its base. In both frames
   here — boots, boulder, trunk, fence posts — there is none, so the scene
   reads as props laid on a painted plane. Frame 2's boulder is the clearest
   case.
3. **Value and chroma are inverted.** In the references the sky and lit canopy
   hold the highlights and the ground carries a wide green range. Here bare
   skin (212,209,203 in frame 1) is brighter than the sky, the ground is a
   two-channel olive with no blue, and frame 2's foreground crushes to
   (40,26,2). Frames 1 and 2 do not read as one place.

**The two bar questions**

**A. Do these frames belong to the world of `tetherbound-meadows-keyart.png`?
No.** The subject matter is right — rolling meadow, oak groves, split-rail
fence, a small settlement, villagers in stylised period dress — and the
character designs themselves are on-brief. What sinks it is execution: the
board's meadow is dense with wildflowers and varied greens, its canopies are
solid masses, and its light gives terrain form. These frames give a thin grass
texture with evenly scattered identical blades, canopies made of loose cards,
and flat lighting with no contact shadows.

*Fixable by changing the scene:* ground-cover density and clustering, tree
placement variety, the grass and canopy albedos (get blue back into the greens,
stop clipping to 0,69,0), exposure agreement between locations, contact
shadows, moving the noticeboard and the grey slab out of frame, and composing
the conversation camera so the speaker is not competing with a screen-edge
crop.

*Needs art that is not in the build:* a canopy asset that holds a silhouette,
textured rock, and a fix to the hair shader — Oskar's hair clipping to black
(28% pure black) and Halda's face taking a hard-edged flat grey shadow across
her mouth are both material/shader problems that no amount of scene dressing
will hide.

**B. Beside `palworld-0*.jpg`, would someone say these are trying to be the
same kind of game? Yes** — genre and camera, at least. Third-person, stylised
humanoid cast, chunky readable creatures-and-people language, a HUD with a
minimap and a quest card. Someone would place them in the same shelf.

They would not place them at the same level of finish. The gap they would name
first is ground density and foliage: Palworld's meadow at this camera distance
is thick enough that the terrain texture never shows, and its trees hold a
silhouette. Here the terrain texture is most of the frame and the nearest tree
is the noisiest object in it.
