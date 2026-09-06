# Blind visual judgement — Meadows Hall interiors (hall_rooms6)

Three 1280x720 software-GL frames, night, interiors. Judged against
`docs/reference/tetherbound-meadows-keyart.png` (palette/mood, and its own
"TEAM TETHER STRONGHOLD (MEADOWS HALL)" and "NIGHT" panels) and
`docs/reference/palworld-0*.jpg` (value range, source legibility, character
readability only — none of them is an interior).

All luma is Rec.709 on the PNGs, 0-255.

---

## Measurements

| region | T-01 approach | T-02 warden arena | T-03 legendary wall |
|---|---|---|---|
| **full-frame median Y** | **36.7** | **24.4** | **16.3** |
| **floor band median Y** (bottom 38%) | **22.2** | **19.8** | **13.2** |
| floor band L / C / R thirds | 24.5 / 14.3 / 32.3 | 9.9 / 14.9 / 34.5 | 13.6 / 18.4 / 9.2 |
| bottom 60 rows (nearest floor) | ~11 | ~7 | ~9 |
| % of frame below Y=8 | 9.9% | 20.5% | 27.6% |
| % of floor band below Y=8 | 13.5% | 27.3% | 29.9% |
| brightest torch flame (max Y) | 231 | 228 | 236 |
| brightest object in frame | left machine's white panel, RGB 238/228/238 at x≈0-40 | **cage/machine window pane, RGB 239/239/239 at x≈880-950 y≈330-400**, median 143 max 240 | white sliver artifact + teal conduit |
| teal share of pixels / of total frame luma | 0.80% / **2.2%** | 0.27% / **1.2%** | 3.20% / **15.8%** |
| teal median Y vs frame median Y | 143 vs 37 | 176 vs 24 | **131 vs 16 (8x)** |
| shadow hue, mean RGB of Y<8 | 13 / 0.9 / 0.7 (R/B **18.9**) | 14 / 0.7 / 0.8 (R/B 18.6) | 10 / 1.4 / 1.7 (R/B 5.9) |

Reference anchors for the same measurements: keyart NIGHT panel ambient is
RGB **17 / 36 / 59** (R/B **0.30**), median Y 29 — a *blue* night with one
small warm campfire. The keyart stronghold's cut stone is RGB **80 / 79 / 71**
(R/B **1.12**) — neutral grey granite. These frames' whole-frame mean is
87 / 44 / 26 (T-01), R/B **3.4**.

**Exposure verdict: this round moved.** Frame medians went from a reported
2-11 to 16-37, and the floor band from "dead black" to 13-22. That is a real
3-15x lift and it is visible: in T-01 and T-02 I can read individual cobbles
across most of the floor. The lift is not finished — see the falloff-direction
defect below — but the previous round's headline complaint is substantially
answered.

---

## Per frame

### T-01 approach room — torch-lit, yes

**Torch-lit or dark/cold/institutional?** Torch-lit. Warm pixels are 84.8% of
the frame and carry 93.5% of the luma. Wall value falls off correctly around
each sconce: the column through the left torch at x≈300-380 reads 104 at the
flame (y≈340) → 68 at y≈380 → 30 at y≈500. That is a real point light with
real falloff, not a warm-tinted flat wash.

**Is there a visible fixture?** Yes, and this is the round's biggest single
win versus the previous verdict. There are torch fixtures at x≈340 y≈350 and
x≈935 y≈350 (and one clipped at the right edge x≈1265). But they are weak as
props: each is a **thin brown rod that hangs downward below the flame** with a
tiny pale-yellow blob at the top and no bracket, no cup, no sconce plate, and
no flame silhouette — it reads as a matchstick pushed into the wall, not a
torch in an iron ring. The flame's own colour (mean RGB 151/92/50 at the left
one) is paler and less orange than the wall pool it is casting.

**Anything unreadably dark?** Two things. (1) The **near floor**: rows y=610
to 720 sit at median 15.8 → 11.3, with the centre third of the floor band
(x 427-853) at median 14.3 and 57% of its pixels below Y=16. (2) The **Team
Tether grunt at x≈545-580, y≈348-443** — body median 33, standing on floor at
median 22 — a dark-on-dark figure whose only readable edge is where he
overlaps the pale door behind him. Move him a metre left and he disappears.

**Teal secondary or dominant?** Secondary, clearly. 0.8% of pixels, 2.2% of
luma. The two ceiling-line conduits and the floor strip read as installed
hardware. This is the correct balance.

**But the brightest thing in the frame is not a torch.** The top 0.1% of
pixels centroid at (19,360) — the **white/lavender panel on the left-hand
Tether machine**, RGB 238/228/238. It is a hard-edged neutral-white rectangle
that outshines every flame and belongs to neither reserved accent (not teal,
not oxblood).

**Artifact:** the doorway at the end of the hall (x 610-690, y 300-410) is a
**flat untextured slab**, per-channel std 5.3-5.8, uniform RGB 100/58/49 at
Y≈67 — brighter than any stone at that depth and therefore the compositional
focal point of the whole shot. It has no bevel, no boards, no handle, no
material. It reads as a missing texture.

### T-02 warden arena — torch-lit, but the machine still wins

**Torch-lit?** Yes. 73.7% warm pixels, 91.5% of luma. The best torch
language in the whole set is the **pair of braziers on the table at x≈1050-1180,
y≈370-410**: small warm orbs with spark particles throwing a genuine warm pool
onto the stone behind them (dot cluster median 123, max 236). That is what a
torch should do.

**Is the fixture legible?** Partly. Those two braziers are pure glow with **no
fixture geometry at all** — you see the light, never the lamp. The two
mid-distance sconces at x≈480 y≈355 and x≈625 y≈355 do have geometry (one a
horizontal bracket, one a vertical post) but at 30-40px they are smudges.

**Anything unreadably dark?** Yes, worse than T-01. The **near cobbles**
(x 300-1000, y 600-720) run median 9.5 → 7.2, mean RGB 35/7.5/1.4 — that is
functionally black with a red tint, and it is roughly the bottom quarter of the
frame. The **left third of the floor band is median 9.9 with 43% of pixels
below Y=8**. The two stools under the brazier table (x≈1040-1160, y≈430-500)
are solid black silhouettes with zero form.

**Teal secondary or dominant?** Secondary and well-behaved — 0.27% of pixels,
1.2% of luma, two floor conduit strips crossing the mid-ground. Good.

**But the previous round's specific complaint still stands.** The **cage /
machine at x≈855-950, y≈290-440 is still the brightest object in the frame**:
its window pane has median Y **143** and max **240**, and the top 0.1% of all
pixels in the frame centroid inside it at (966,390) at RGB 239/239/239. It has
merely changed hue from teal to **blown neutral white**. It is a hard-edged
flat white rectangle that casts **nothing** — the stone immediately beside it
is far darker than the pane, and the floor under it shows no pool at all — so
it reads as an emissive decal, not a light. Recolouring the offender did not
fix the offence.

**Palette leaks:** (a) the machine carries a **saturated fire-engine red ring
at (866,398) and a red block at (900,320)** — that is not oxblood, and bright
red on Tether hardware competes with the banner's reserved oxblood. (b) The
**oxblood banner occupies most of the left quarter** (x 0-300) and its lower
half (y 320-540) is a **completely flat slab**, median 22, p95 24, max 25 —
i.e. no texture, no fold, no gradient across 220 rows. The upper panel with the
white circle-cross sigil is good and matches the keyart's banner sigil exactly;
the lower slab reads as a clipping plane. (c) Bottom-right corner at
(1230-1280, 480-540) has a **white wedge artifact**, max Y 240 — a stray
polygon or near-plane clip.

**Odd for the fiction:** heavy **green ivy across the ceiling and upper right
(x 480-1000, y 0-300)** of an interior arena. It is the only saturated green in
the set and it pulls the eye upward, away from the arena floor.

### T-03 legendary side wall — the weakest, and teal is still winning here

**Torch-lit?** Half. This is the only frame where warm does not dominate: warm
pixels 36.4%, warm luma share 50.7%, and the frame median is **16.3** — dark
enough that 49.4% of the whole image and 58.9% of the floor band are below
Y=16. The two torches at x≈490 y≈355 and x≈690 y≈355 are the best-formed
fixtures in the set (a real ring bracket with a glow, and a legible warm pool
falling from 100 at x=700 to 40 at x=750 to **6.7 at x=800**) — but they light
a strip of one wall and nothing else. Everything more than about 2 m from them
is at Y 12-17.

**Teal secondary or dominant?** **Dominant.** 3.2% of pixels carrying **15.8%
of the frame's total luma**; the conduit's median Y is 131 against a frame
median of 16 — an 8:1 ratio. Of the brightest tier of the image (Y>120, 4.7%
of pixels) the mean colour is **145/163/147 — greenish-neutral, R/B 0.99**.
The single strongest graphic line in the composition is the teal conduit
running from (360,500) to (1280,700). Against these torches, the teal is the
key light of this frame, not the accent.

**Anything unreadably dark?** Extensively. The right wall away from the torches
(x 950-1280, y 100-400) is median 16.5; the right third of the floor band is
median **9.2 with 74% of pixels below Y=16**; the floor beyond the conduit
(x 1150-1280, y 600-720) is median 11.7. Roughly the right half of the frame
is undifferentiated brown-black.

**The legendary machine (x 60-520, y 20-520) is the problem asset.** Median Y
26, mean RGB 50/37/34 — a **grey-green** mass in an orange room, receiving no
warm light and reading as if it were lit by a different scene. Its surface is
dense high-frequency noise-normal detail with a gothic-spire silhouette that
does not match the flat, painterly, large-shape cut stone of the walls beside
it. At 30% zoom it is a dark blob you cannot name: not obviously a machine,
not obviously an altar, not obviously important. The single most story-critical
object in the chapter has the least readable silhouette in the set.

**Artifact:** a **white triangular sliver at (0-70, 40-110)**, max Y 240 in an
area whose median is 6.4 — a stray unlit polygon, a gizmo, or a light-mesh
edge. It is the brightest thing in the top-left of the frame.

---

## Rank

1. **T-02 warden arena.** Best sense of an inhabited, authored room: banner,
   ivy, table, braziers with real spark VFX and real warm pools, a genuine
   depth read from foreground banner → mid conduits → lit doorway. Also carries
   the most defects (blown cage, flat banner slab, black near floor).
2. **T-01 approach room.** Cleanest and best-exposed (median 36.7, the only
   frame where the floor is legible across its width), with the most honest
   torch falloff on the walls. Loses to T-02 on emptiness — it is a symmetrical
   brick box with two props — and on the flat untextured door dominating the
   vista.
3. **T-03 legendary side wall.** Darkest, teal-keyed, and the frame where the
   hero prop is style-mismatched and unreadable. Also the frame where the
   camera is pointed at the largest area of nothing (right half).

---

## The three things that most separate these frames from the references

**1. The ambient/fill is warm red, so nothing reads as *fire* — it reads as a
room made of hot brick.** In every frame the shadow term is a saturated red:
pixels below Y=8 average RGB **13/0.9/0.7, R/B ≈ 19** (T-01, T-02). The keyart
NIGHT panel does the exact opposite — its ambient is **17/36/59, R/B 0.30**, a
blue night, and the single small campfire is warm *because everything around it
is cool*. Ours has warm key on warm fill, so the torches are only slightly
brighter patches of an already-orange room; there is no complementary contrast
to sell them as flame. This is also why the keyart's **neutral grey granite
(80/79/71, R/B 1.12)** has become terracotta here (whole-frame 87/44/26,
R/B 3.4): the "old cut stone" reads as fired brick and adobe, not the mossy
grey castle in the keyart's own MEADOWS HALL panel.

**2. Light falls off in the wrong direction — the floor gets darker toward the
camera.** T-01 floor rows: 38.5 at y=430 → 11.3 at y=700. T-02: 51.1 → 7.2.
T-03: 31.5 → 8.7. Meanwhile in T-01 the *ceiling* holds median 100-135 across
its whole span, 4-8x the floor beneath it, with no per-torch variation — that
is an overhead ambient term, not torch bounce. So the largest single region of
every frame, the near floor the player actually walks on, is the darkest thing
in it, and the room reads as lit from above rather than by its sconces. No
Palworld shot has a foreground that dark; even `palworld-01`'s shaded forest
floor holds mid-tones under the character's feet, which is what makes the
creature and the sparks pop.

**3. Torch fixtures are invisible at reading size, and the brightest object in
two of three frames is a piece of white machine hardware.** Downsampled to 30%
(384x216, roughly a thumbnail), T-01's torches are two orange smudges with no
discernible fixture and the **teal conduits are the only crisp graphic in the
frame**; T-03 is the teal diagonal plus two orange smudges. Meanwhile the
frame-brightest pixel cluster is the left machine panel (T-01, RGB 238/228/238)
and the cage window (T-02, RGB 239/239/239, median 143) — both hard-edged
neutral-white rectangles that cast no light onto anything. The keyart's
stronghold panel keeps its Tether glow **small, deep-set and blue, inside the
archway**, subordinate to the stone; here the hardware is the brightest and
crispest element and the fire is the softest.

---

## The two bar questions

**A. Do these frames read as belonging to the world of the keyart? — YES,
narrowly, for T-01 and T-02; NO for T-03.**

What carried it: the banner sigil is the keyart's circle-cross, in the keyart's
oxblood; the stone-block language, ivy and timber lintels match the keyart's
MEADOWS HALL panel; the teal is being used as the keyart uses its archway glow
— installed, linear, cold, secondary. What weakens it: the keyart's stronghold
is **grey granite**, and these interiors are terracotta-orange at R/B 3.4, so
the material identity of the building has drifted. T-03 fails the question on
its own: the grey-green gothic spire prop is not in the keyart's vocabulary at
any point, and the frame is keyed teal rather than torch.

**B. Would someone say these are trying to be the same kind of game as
Palworld? — NO.**

What sank it: value range and foreground exposure. Every Palworld reference
holds readable mid-tones across the *whole* frame including the ground the
character stands on, with saturated local colour (green foliage, orange sparks,
character costume) sitting on it. Here 20-28% of T-02 and T-03 is below Y=8 and
the near floor runs Y 7-15, so the bottom third is a red-black void.
`palworld-01` also answers the character question directly: its trainer is a
high-contrast bespoke figure — orange hair, cream/tan costume — legible against
a busy forest. Our only figure, the grunt in T-01 at x≈545-580, is body-median
33 against floor-median 22 and survives only because a pale door happens to be
behind him. And Palworld's frames are *dense*: props, foliage, particles,
creatures. T-01 is a symmetrical empty box with two floor props; T-03's right
half is bare wall.

---

## Fixable by lighting/scene vs needs new art

### Fixable by lighting and scene setup (do these first)

- **Recolour the ambient/fill to cool slate-blue** (target something near the
  keyart night panel's R/B ≈ 0.3-0.6 in the shadow tier, not 19). This single
  change does four jobs at once: it makes the torches read as fire by contrast,
  it lifts the black floor into a readable cool mid-tone without touching the
  warm key, it restores the grey-granite identity of the stone, and it gives
  the reserved teal a cool field to belong to instead of being the only
  non-orange thing on screen.
- **Add near-camera torch coverage / raise light radius so falloff reaches the
  bottom of frame.** Target floor-band medians of roughly 25-35 with the near
  rows no lower than the mid rows. Sconces need to continue down the wall
  toward the camera in T-01 and T-02, and along the right wall in T-03.
- **Cut the ceiling ambient in T-01.** A ceiling at 4-8x the floor with no
  per-torch variation is the tell that the room is lit from above.
- **Cap the cage/machine emissives (T-02 x 855-950; T-01 machine panel x 0-40)
  well below the torch peak**, and make them *cast* — a warm-neutral pool on the
  adjacent stone and floor. Nothing at 240 that lights nothing should exist in
  a room whose premise is torches.
- **Rebalance T-03**: it needs at least two more torches on the right wall
  (x 900-1280) and one raking the legendary prop. Bring the conduit's emissive
  down so its median is closer to the torch pools than 8x the frame median.
- **Fix the flat door slab in T-01 (610-690, 300-410)** — assign a material or
  put a lit room behind it. As-is it is the vista of the shot.
- **Fix the flat lower half of the T-02 banner (0-300, 320-540)** — it is a
  220-row region with a max-min range of 3 luma values.
- **Fix the T-03 white sliver at (0-70, 40-110) and the T-02 white wedge at
  (1230-1280, 480-540).** Both are the brightest pixels in their neighbourhood
  and both read as bugs.
- **Recolour the T-02 machine's bright red ring/block (866,398 and 900,320) to
  oxblood**, or drop the red entirely — Team Tether red should be reserved.
- **Reposition or rim-light the grunt in T-01** so he does not depend on a pale
  door for his silhouette.
- **Dress T-01.** Crates, racks, a bedroll, sacks, hanging chains — anything
  that breaks the symmetry of an empty brick box.
- Reconsider the interior ivy in T-02 (x 480-1000, y 0-300); if it stays,
  motivate it with a hole to the sky.

### Needs art that is not in the build

- **A real torch fixture.** The current one is a bare rod with a pale blob and
  it disappears below about 50% zoom. What is needed: an iron bracket or ring
  sconce with a visible cup, a flame with an animated silhouette and a warm
  orange core (not a pale white blob), and a soft glow card so the source is
  legible as a source at thumbnail size. This is the owner's literal ask
  ("flames/sconces legible as the source") and it cannot be solved by turning
  lights up.
- **The legendary prop in T-03.** The grey-green high-frequency gothic spire is
  a different art style from the flat painterly stone around it, does not
  respond to the room's light, and has no readable silhouette. Regrading and
  relighting will help it but will not make it the same game as the walls
  beside it.
- **A stone material set that is neutral in albedo.** Some of the R/B 3.4 drift
  is lighting, but the wall texture itself is a warm terracotta; matching the
  keyart's grey mossy granite likely needs the albedo desaturated toward
  neutral so torchlight can supply the orange rather than the material.
- **Character contrast.** The grunt is dark-on-dark. Palworld's bar is bespoke,
  high-contrast costume design. That is an asset decision, not a lighting one.
- **Interior set dressing.** T-01's emptiness against `palworld-05` and
  `palworld-01` is a density gap that needs props to exist before they can be
  placed.

