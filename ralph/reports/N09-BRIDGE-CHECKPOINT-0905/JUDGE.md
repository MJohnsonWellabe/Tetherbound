# Visual judgement — signpost & bridge A/B sheets

Judged blind from the two contact sheets and board 18. All pixel numbers are measured
on the sheets; the sheets are 2× downsampled from 1280×800, so "@1280" figures are the
sheet measurement doubled.

Sheets contain:

- `_sheet_signpost_ab.png` — 3 rows: `south-bridge-trailhead` (in-world),
  `signpost-three-quarter` (studio), `signpost-front` (studio).
- `_sheet_bridge_ab.png` — 6 rows: `bridge-approach-played`, `place5-bridge-approach`,
  `bridge-checkpoint-shoulder`, `bridge-deck-far-side`, `deck-rail-close` (studio),
  `deck-three-quarter` (studio).

**A structural fact first, because it changes what several of the questions can mean.**
I differenced the two halves of each sheet. `deck-rail-close` and `deck-three-quarter`
are **pixel-identical between A and B except for one 27×20 px and one 22×16 px patch —
both of which contain the distant background signpost.** In `bridge-deck-far-side` the
deck-and-rail region differs by a mean of 2.4/765 with **zero** pixels over threshold;
the frame's differences are foliage wind and the far-end dressing. So on the deck rows
there is nothing to choose: A and B are the same bridge. The real A/B change lives in
the signpost lettering and in the checkpoint barricades.

---

## 1. Signpost rows vs board 18 "Directional (Multi)"

**Row `signpost-front` (studio) — A is closer, decisively.**
B sets larger type on every arm and pays for it by **clipping the destination**:
"Relay Station" renders as "Relay Statio", the final glyph swallowed by the post and the
arm bracket. A fits all four names inside their planks with margin, which is what the
board shows — every name on the board's directional sits fully inside its plank with a
clear border of wood on both ends. Shipping a truncated place name is a hard fail and it
outweighs B's size advantage.

**Row `signpost-three-quarter` (studio) — A is closer, same reason.**
Same clip: B's "Relay Station" loses its last letter behind the post; B's "Grandpa's
House" runs from the arrow barb to the bracket with no margin either side; B's "South
Bridge" overruns to the plank's right edge. A's four names all fit. Measured widths:
"Relay Station" A 86 px / B 94 px on an identically-sized plank.

**Row `south-bridge-trailhead` (in-world) — neither, and they are near-identical.**
The whole-frame difference here (15.7% of pixels) is grass and canopy wind at a different
phase; the sign-arm region differs by a mean of 7.5/765. B's glyphs are marginally
larger blobs. Neither reads.

### Legibility, measured

**Studio rows — both legible, comfortably.**
- `signpost-front` A "Relay Station": cap height 19 px on sheet = **38 px @1280×800**,
  text (250,243,222) on plank (64,44,30) = **11.9:1**.
- `signpost-three-quarter` A "Relay Station": 20 px = **40 px @1280**, **6.8:1**.
  B: 21 px = **42 px @1280**, **7.6:1**.
- B's type is roughly 10–25% larger throughout — which would be the right instinct if it
  did not break the words.

**In-world row — neither is legible, and it is not close.**
- Cap height **≈6 px on sheet = ≈12 px @1280×800** in both A and B.
- Text-to-plank contrast **≈2.6:1 (A) / 2.7:1 (B)** — measured on the plank interior, so
  this is the real figure, not a background artefact.
- Glyph strokes are one sheet pixel (two native pixels) wide over a noisy wood diffuse.
  Pixel-dumping the plank shows the lettering as an unresolved 150–185-luminance smear on
  a 100–130 ground. You cannot read "South Bridge" or anything else off it.

The board's own note for this asset is "**Stylized, readable from distance**." The
in-world frame is the only frame that tests that note, and both columns fail it.

There is a second reason the in-world sign fails that has nothing to do with type size:
**from the approach only one of the four arms faces the player.** Measured on the sheet,
the post runs from y209 (finial) to y304 (base); the single visible arm ends at y232.
**76% of the visible signpost is bare pole.** On board 18 the three arms are stacked
tightly and the bare pole below the lowest arm is about **27%** of the post. The board's
signpost reads as a signpost in silhouette; this one reads as a fence stake with a chip
on top.

---

## 2. Bridge deck rows vs board 18 "Bridge Plank & Rail"

**A and B are the same deck.** `deck-rail-close` and `deck-three-quarter` are identical
apart from the distant signpost; `bridge-deck-far-side`'s deck region has no differing
pixels. Neither is closer. What follows is how *the* deck compares to the board.

**Where it matches:** deck diffuse colour (137,94,63) is a good hit against the board's
first palette swatch (125,89,66). Post silhouette — square shaft, chunky cap slab — is in
the right family. Deck-width-to-rail-height reads about 0.66 against the board's stated
2 m wide / 1–1.2 m rail (0.55); close enough not to be a defect.

**Where it misses, in order of loudness:**

1. **The planks run the wrong way.** Zooming the deck surface in `deck-rail-close`, every
   seam runs *parallel to the direction of travel* and there are no cross-seams at all.
   The board's Straight Section module and its hero painting both lay planks **across**
   the span. Lengthwise on a ~24 m causeway implies 24 m timbers, which is why it reads
   as a texture rather than as boards.
2. **No metal, anywhere.** The board's signature detail on this asset is dark iron —
   collars and riveted brackets at every post head, at every post foot, and at the four
   deck corners (visible in the Modules panel, the End Post, the Middle Post and the Top
   view). The in-game piece has none. The rope wrap sits exactly where the board puts the
   iron band.
3. **The post-base blocks are near-white and are the brightest thing in the frame.**
   Median **(219,211,194), luminance 212** — brighter than the sky (189) and the grass
   (186), against a deck at 101. They are untextured, they overhang the deck fascia, and
   in `bridge-deck-far-side` several visibly intersect the edge board. The board puts
   grey cut stone there (palette greys 97 and 109).
4. **Post value is far too dark.** In-world post body **lum 36** against deck **lum 101**
   (ratio 0.36). On the board's front elevation the post is **117** against a deck of
   **123** (ratio 0.95). The rail therefore reads as a black iron picket fence rather
   than as warm timber, and the whole crossing loses the board's honey-oak warmth.
5. **It is a causeway, not a bridge.** `deck-three-quarter` shows ~12 bays, dead flat,
   dead straight, lying directly on the grass — no piers, no abutments, no camber, no
   sag, grass touching the fascia along the whole length. The board's asset is a short
   span carried on stone piers over water, with the deck lifted clear.
6. **Near and far rail posts are staggered by half a bay.** Visible throughout
   `deck-three-quarter`. The rope swags on the two sides do not rhyme. That reads as a
   modular placement error, not a choice.
7. **The rope is a smooth tube.** Uniform diameter, identical torus wraps at every post,
   identical sag in every bay, no twist, no fibre, no fray. The board's rope has visible
   lay and a hand-tied look.
8. **The stone apron is two incompatible materials, both too bright.** A cartoon-outlined
   near-white cobble rectangle butted against a completely textureless flat grey slab,
   both terminated by razor-straight edges cutting the grass and the dirt. In
   `bridge-deck-far-side` this is the loudest thing on screen and it is not the bridge.
9. **No mid-rail.** The board's straight section has a rope top rail *and* a timber mid
   rail. In game there is one rope.

---

## 3. Bridge approach — does the crossing read as HELD?

**Partly in A, less in B, and for the same reason in both: the banners are carrying the
entire idea on their own.**

**Barricades — textured vs blockout.** This is the single clearest A/B difference on
either sheet, and it is a regression in B.
- **A:** fully textured timber. Visible grain, knots, weathering, saw-cut ends, bevelled
  edges. Reads as the same material family as the crate, the hay bales and the gate
  standing beside it.
- **B:** **untextured blockout.** Flat, uniform, desaturated taupe-mauve prisms with
  smooth-shaded facets, zero grain, zero variation. Beside an A-quality crate and hay
  bale they read as primitives someone has not got to yet. B also scales them up and
  pushes one into the centre of frame where it occludes the lower half of the gate.

**Do they control passage? No — in neither column.** In both `bridge-approach-played`
and `bridge-checkpoint-shoulder` the barricades stand **beside** the road: one on the
grass verge to the left, one on the grass to the right. The dirt lane runs clean and
unobstructed between them and continues past the guard. Nothing is across the traffic
surface, and the gap between the two pieces is wide enough to drive a cart through. They
are dressing standing near a road, not a checkpoint controlling one. The gate is the only
actual barrier and it is set back and offset from the lane, so the read is "there is a
gate over there and some sawhorses in the grass," not "you must stop here."

**The guard — does she wear the faction colour? No, in neither column.**
- Banner oxblood: **(146,58,44)** — R/B ratio 3.35.
- Guard torso **A: (91,61,53)** — a warm brown, R/B 1.72. Closest of the two, but it is
  brown, not oxblood.
- Guard torso **B: (83,74,68)** — effectively **neutral grey-black**, R/B 1.22. Furthest
  from the faction colour of anything in frame.
- Neither carries a sash, armband, tabard, crest or the banner's white ring emblem. She
  stands in a slack idle beside a barrel, angled away from the road, with no visible
  weapon and no posture of challenge. Cropped at 10× she reads as a passer-by who happens
  to be standing there.

**A light? No.** There is a lantern prop on the right gate upright. Its panel is a **flat
cyan (100,173,174), luminance 158** — no emissive, no bloom, no pool of light on the
ground, no warm hue. It is a cold sticker on a warm structure, and cyan is outside both
the board's palette and the faction's oxblood.

**Banners — the one thing that works.** Two oxblood banners with a white ring-and-cross
emblem, well-shaped, correct colour, occupying **3.1%** of the approach frame. They are
the only element that says a faction is here. They are undercut by a second cloth colour:
slate navy **(39,64,88)** hanging on both gate uprights, which introduces a competing
livery at the same checkpoint and muddies the read.

**Summary:** in **A**, the crossing reads as *manned but not yet held* — flags up,
timber dressing in place, road wide open, guard out of uniform. In **B**, it reads as
*flags over a blockout* — same open road, same out-of-uniform guard, plus untextured
placeholder geometry front and centre.

---

## 4. What is still wrong in the better column (A), worst first

1. **Nothing controls passage at the checkpoint.** Both barricades sit on grass beside
   the lane; the dirt road is completely clear between them.
   (`bridge-approach-played` / A, `bridge-checkpoint-shoulder` / A)
2. **The guard is not in the faction's colour and is not behaving like a guard.** Torso
   (91,61,53) against banner (146,58,44); no sash, emblem, weapon or challenge posture;
   angled away from the road. (`bridge-approach-played` / A)
3. **The bridge deck planks run lengthwise, contradicting the board's straight section.**
   (`deck-rail-close`, `bridge-deck-far-side`, `deck-three-quarter`)
4. **Post-base blocks are near-white untextured cubes (219,211,194, lum 212), brighter
   than the sky, overhanging and intersecting the deck fascia.** They are the first thing
   the eye finds in every deck frame. (all three deck rows)
5. **The bridge has no iron.** No post collars, no corner brackets, no rivets — the
   board's defining detail for this asset is absent entirely.
6. **Post-to-deck value ratio 0.36 vs the board's 0.95.** The rail reads black.
   (`bridge-deck-far-side`, `deck-rail-close`)
7. **The span is a flat ~12-bay causeway on the ground with no piers, camber or
   substructure.** (`deck-three-quarter`)
8. **Near and far rail posts staggered half a bay apart.** (`deck-three-quarter`)
9. **The stone apron: outlined near-white cobble against a textureless grey slab, both
   with razor-straight edges into grass.** (`bridge-deck-far-side`, `deck-three-quarter`)
10. **In-world signpost is illegible: cap height ≈12 px @1280×800, contrast ≈2.6:1.**
    (`south-bridge-trailhead` / A)
11. **76% of the in-world signpost is bare pole and only one of four arms faces the
    approach** (board: ~27% bare, all arms readable). (`south-bridge-trailhead` / A)
12. **Cyan unlit lantern (100,173,174) on a warm oxblood-and-oak structure.**
    (`bridge-approach-played` / A)
13. **Competing navy livery (39,64,88) on both gate uprights** alongside the oxblood.
14. **Rope is a smooth uniform tube** with identical wraps and identical sag every bay.
15. **Signpost arm brackets are plain dark boxes intersecting the post**, with no bolt,
    peg or lashing; the board notches the arms into the post.
    (`signpost-front` / A, `signpost-three-quarter` / A)
16. **The signpost finial is a stack of pale cream discs** reading as washers, and it is
    the brightest element on the prop. The board has a carved cap with a brass/green
    collar. (`signpost-three-quarter` / A)
17. **White untextured cubes scattered at the signpost base** in both studio rows.
18. **Signpost arms are thin flat wedges with smooth gradient shading and almost no
    grain**; the board's arms are chunky, show plank thickness, and are visibly weathered.
19. **A's type is small in its planks** — every arm carries a wide empty tail. B's
    instinct to enlarge was right; it just needs the plank to grow with the string, or
    the string to be measured against the plank.

---

## SHIP / DO NOT SHIP, for a first playable

### (a) Bridge deck and rail — **DO NOT SHIP**

A and B are the same asset, so there is no better column to ship. The silhouette and the
deck colour are right; everything that makes the board's bridge read as a *built* object
is missing or inverted.

**Split of remaining work:**
- **Scene / material work with what exists (the majority):** rotate the deck UVs 90° so
  planks cross the span; darken and grey the post-base blocks out of the 212-luminance
  range into the board's stone greys, and reseat them inside the fascia; lift the post
  albedo so post and deck sit within ~10 luminance of each other rather than 65 apart;
  pair the near and far posts; shorten the span or break it into a shorter authored
  crossing with a camber; replace the outlined-cobble and flat-grey apron with one stone
  material and stop cutting it as a rectangle.
- **Art that must be made (small but unavoidable):** the iron collar / corner-bracket set
  and a stone pier or abutment module. Without them this cannot look like board 18 no
  matter how it is lit — the board's read is *timber banded in iron on stone*, and two of
  those three materials do not exist in the frames.

### (b) Signpost — **DO NOT SHIP as placed.** The asset is closer than the placement.

At studio distance A is legible and correctly typeset (38–40 px caps, 7–12:1). B must not
ship at all: it truncates a destination name in two separate rows. In world, neither
column does the job the board asks for.

**Split of remaining work:**
- **Scene / material work with what exists (almost all of it):** raise the type size to
  B's scale *and* widen the planks so the strings fit; darken the plank ground or add an
  outline so contrast holds at distance; orient the arms so more than one faces the
  approach; shorten the post or raise the arm cluster so the bare pole drops from 76%
  toward the board's ~27%; place the post nearer the path so it is not read at 12 px caps;
  delete the white cubes at the base.
- **Art that must be made (small):** the base collar band, a carved finial to replace the
  disc stack, and grain on the arm planks. All modest, all optional for a first playable
  if the placement work above is done.

### (c) Checkpoint dressing (barricades, guard, banners) — **DO NOT SHIP**

The banners are genuinely good and should stay. Everything else at the checkpoint is
either not doing its job or not finished. **B's barricades specifically must not ship in
any form** — they are untextured blockout standing next to finished props.

**Split of remaining work:**
- **Scene / material work with what exists (nearly all of it):** A already proves the
  textured barricade exists, so B's version is a material regression to undo, not art to
  make. Move the barricades **across** the lane leaving a single controlled gap; retint
  the guard's existing costume into the banner oxblood, or give her the ring emblem;
  turn her to face the road and give her a challenge idle; make the lantern emissive and
  warm, or remove it; drop the navy cloth so one livery flies here.
- **Art that must be made (small, and can wait):** a faction sash or armband if retinting
  the costume is not enough, and a gate-bar or chain prop if the barricades alone are not
  meant to be the stopping line.
