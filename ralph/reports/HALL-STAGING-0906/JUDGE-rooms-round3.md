# Blind visual judgement — Meadows Hall interiors, round 3

Frames judged: `b/T-01-approach-room.png`, `b/T-02-warden-arena.png`,
`b/T-03-legendary-side-wall.png`, sheet `b/_sheet_hall_rooms3.png`.
References: `docs/reference/tetherbound-meadows-keyart.png`,
`docs/reference/palworld-0*.jpg`.

I have not seen the code or the previous round's frames. Where I quote numbers they
are measured off the PNGs (Rec.709 luma, 0–255) so they can be re-measured after a
fix. Software-GL caveat applies to fine shadow quality; it does not excuse exposure,
because exposure is in the file.

## Measured baseline (this is the spine of the whole report)

| | median luma | % pixels < 8 | floor band (bottom 38%) median | bright-warm px (L>150, R>B+40) | bright-cool px (L>150, B>R+30) |
|---|---|---|---|---|---|
| T-01 | 11 | 44% | 4.5 | 1,447 | 1,315 |
| T-02 | 1.8 | 71% | 0.6 | 268 | 1,314 |
| T-03 | 5.1 | 59% | 3.8 | 447 | 13,235 |
| palworld-01 | 126 | 0.4% | 114 | — | — |
| palworld-05 | 109 | 0.0% | 73 | — | — |

Two things fall out of that table before any taste is involved.

1. **The hue changed; the exposure did not.** T-01 is now 36% warm pixels against 1%
   cool, so the *tint* brief landed. But the median pixel in these rooms is 2–11 out
   of 255. The reference bar sits at 109–126 with essentially no crushed black. These
   frames are 10–60× darker at the median than the thing they are being compared to.
2. **"Torch light reaches the floor" has not happened in any of the three.** Floor-band
   medians are 4.5 / 0.6 / 3.8. The floor is still black; what changed is that the
   *walls and ceiling* went warm. In T-03 the floor band's p95 is 122 — and that is
   the teal conduit, not firelight.

---

## T-01 — approach room

**Reads:** warm, and by a clear margin the best of the three. Wall stone (x 60–380 and
x 900–1240), the ceiling coffers (y 0–200) and the beams are a consistent amber-brown;
36:1 warm:cool by pixel count. If the ask was "stop the room being teal", T-01 answers it.

**But it does not read torch-*lit* — it reads torch-*tinted*.** There is no torch in
this frame. I scanned for bright warm blobs; the only clusters are the fire-pit disc at
x 840–920 / y 400–440 and specular hits on the left machine. Nothing on either side
wall, nothing on the pillars, nothing at head height. So the room is a uniform amber
ambient with no source, and it is brightest at the *ceiling* (centre ceiling mean L 40)
while the floor under it sits at L 3.4 — exactly inverted from torches on walls. Along
the whole 12 m of the left wall the brightness is flat: no bright pool, no dark gap
between pools, no rhythm. That absence of rhythm is the single reason it still reads as
a tinted box rather than a lit hall.

**The fire pit is not on fire.** Zoomed 3×, the object at x 780–960 / y 405–465 is a low
oval stone kerb around a flat cream-tan disc. No flame geometry, no coals, no ember
particles, no halo, and — decisively — the floor immediately around it is unchanged
(L 3–5). It is the second-brightest large object in frame and it emits nothing. Right
now it reads as an empty basin or a filled-in pit, not a hearth. A player will not read
that as the light source.

**A third Tether colour has appeared.** The machine at x 0–140 / y 240–500 is the
single brightest object in the frame (peak L 231) and it is a near-white lilac screen
plus a lavender tank. That is neither the reserved teal nor the reserved oxblood. Teal
was demoted here, but the key-accent job was handed to white-violet rather than
retired, so the brightest pixel in the room still belongs to Team Tether hardware.

**Unreadably dark:** the near foreground, x 300–900 / y 520–720, mean L 3.4. The bottom
quarter of the frame is a black band with a faint cobble pattern in it. Bottom-left and
bottom-right corners are 0.

**Teal:** secondary in area, not in punch. The two wall rails (left x 0–400 / y 140–275,
right x 880–1280 / y 145–270) and the floor run at x 440–560 / y 420–480 are still
fully saturated cyan against a desaturated room, and the floor run out-punches the fire
pit. Bright-warm to bright-cool pixels is 1,447 : 1,315 — roughly parity. "Secondary"
should not be parity.

**Other:** the doorway at x 595–700 / y 285–410 is a flat unlit slab with no depth cue
and no light spill through it — it reads as a hole cut in the render. The trainer at
x 545–575 / y 350–440 is a dark silhouette with no rim or key on him at all; he is
hard to find at sheet size and impossible to read as a character. Stone texture tiles
visibly at the same scale on floor, wall and ceiling.

## T-02 — warden arena

**Reads:** cold and mostly empty. Median luma 1.8; 71% of the frame is below L 8. There
is a genuinely nice warm passage — the ceiling and upper wall from x 300–700 / y 0–260
are a convincing peach-lit vault, the best *surface* in the whole set — but it occupies
maybe a sixth of the frame and everything below y 420 is black.

**Unreadably dark, and this is the frame's biggest problem:**
- x 0–300 / y 300–720: a flat plane at mean L 1.3, max 3.8. A quarter-million pixels of
  literal black with no information in them. Whatever it is (the banner's lower half? a
  wall?), it is a dead rectangle anchoring the lower-left corner.
- x 995–1130 / y 120–600: a black column at mean L 1.3. It occupies the right third of
  the room and reads as a missing object.
- The whole floor: band median 0.6. There is no floor here, only the two conduit strips
  drawn on top of nothing.

**Flames are legible but too small and too weak to be believed as the source.** At 3×
there are two fixtures: x 478–492 / y 348–362 (a small lantern box with a warm pool on
the pillar face) and x 630–645 / y 345–360. Both are real and readable as lamps — that's
progress — but each is roughly 15 px, together they contribute 268 bright-warm pixels in
the whole frame, and neither casts anything onto the floor 3 m below it. Meanwhile the
ceiling 4 m *above* them is far brighter than the wall beside them. The eye does the
arithmetic and concludes the light is coming from off-screen above.

**Teal is still dominant where it counts.** Bright-cool 1,314 px vs bright-warm 268 —
5:1. The largest bright cluster in the entire frame is the cyan wedge at
x 1230–1280 / y 470–560 (883 px above L 150), which is a saturated neon shape sitting in
the corner with no object attached to it; then the floor conduits at x 320–660 /
y 405–470. Against a room at median L 1.8, three cyan strips are not an accent, they are
the composition.

**The cage light** at x 855–950 / y 300–410 is better than "blown-out white" — it now has
a violet cast and a frame around it — but it is still the brightest single fixture (peak
L 238), still cool, and still the thing your eye lands on first on the right half.

**Other:** the oxblood banner (x 0–300 / y 130–300) is the correct colour used correctly
for faction danger, and the ring emblem is legible at sheet size — the strongest piece
of authored intent in the set. It is undercut by its own bottom half falling into the
dead black plane, so it reads as a rectangle floating in a void. The vine mass at
x 500–950 / y 0–190 is flat dark-olive cutout foliage, quite noisy, and at night it
neither reads as ruin-overgrowth nor as anything else. The doorway at x 690–760 /
y 262–400 is the same flat unlit slab defect as T-01, and it is the second-brightest
area of the frame.

## T-03 — legendary side wall

**Reads:** cold and institutional. This is the one that has not moved. Bright-cool
13,235 px against bright-warm 447 — **30:1**. Teal is not secondary here by any
measure; it is the frame.

**The conduit is the subject.** The bar from x 355 / y 495 to x 1280 / y 715 is a hard,
fully saturated cyan neon strip running diagonally across the bottom third — peak L 188
against a floor at L 3.8. Nothing else in the frame is within reach of it. Wherever the
camera is meant to be pointing, the eye goes to the strip.

**The machine is no longer emissive teal but it is still cold and still dominant.** The
mass at x 0–520 / y 0–600 is a pale grey-green spire catching a hard cold light from
off-screen upper-left; it is the brightest large region (top-0.2% centroid falls inside
it, 78% of those pixels cool). Demoting it from glowing to lit-cold changed its colour
job, not its compositional job. Its surface also reads worst of anything in the set —
smeary, low-contrast, hard to tell stone from metal from cloth, and the shapes at
x 60–200 / y 100–260 don't resolve into anything nameable.

**One torch, and it is the most honest lighting in the whole set — and also the most
broken.** The sconce at x 695–712 / y 340–372 is a small yellow flame-ish blob with a
warm pool spreading up and right onto the stone. At 3× the pool has a hard, lopsided
boundary — a straight vertical cut on its left edge at x ≈ 690 and an abrupt stop at
x ≈ 800 — and there is an unexplained dark vertical bar directly beneath the fixture.
That does not read as a point light with falloff; it reads as a decal or a clipped
projector. Below it the floor at x 620–830 / y 400–460 sits at mean L 18 — the only
place in three frames where firelight arguably touches the ground, and it dies within
one metre.

**Unreadably dark:** x 500–940 / y 0–200 (mean L 4.3) — the top half of the mid wall is
gone; x 0–340 / y 560–720 (mean L 8) — the near foreground; and everything between the
machine and the sconce.

---

## Ranking

1. **T-01** — the only frame where "torch-lit" is even arguable. Warm wins the hue
   fight decisively and the space is legible. Fails on having no visible source, a dead
   fire pit, a black floor and a white-violet machine owning the brightest pixel.
2. **T-02** — has the best-lit surface in the set (that upper-left vault) and the best
   piece of authored art (the banner), but 71% of it is below L 8 and cool light still
   out-punches warm 5:1.
3. **T-03** — did not move. 30:1 cool, a neon bar for a subject, a smeary cold machine
   for a focal point, and one clipped torch pool. If the round is being assessed on the
   owner's ask, this frame is the counter-example.

## The three biggest gaps vs the references

**1. Value range and black point — the whole set, worst in T-02.** Both Palworld shots
run a median around 110–126 with effectively zero crushed black; even
`palworld-01`, a dark forest fight, keeps its shadowed ground at a median of 114 and
still shows leaf litter, roots and grass in it. T-02's floor median is 0.6 and T-01's is
4.5. The references never trade information for mood; these frames trade all of it. A
night interior does not have to be bright, but it has to have *something* in the darks —
the key art's own night panel (bottom-right of the board) is dark blue and still shows
grass blades, a creature's silhouette, hillside, and a campfire's throw on the ground.

**2. The light has no visible cause, and where it does the cause is too small.**
`tetherbound-meadows-keyart.png` — the Meadows Hall panel specifically — puts a lit blue
archway and hanging red banners at eye height and lets the light fall *from* them;
`palworld-01` puts its brightest values on the muzzle flash and the impact sparks, the
things actually emitting. In T-01 there is no fixture at all and the ceiling is brighter
than the wall below it. In T-02 the two lanterns contribute 268 bright pixels against
1,314 cool ones. In T-03 the single pool is hard-edged and clipped. The fix is not more
ambient warmth — the fix is fewer, bigger, closer sources with visible flame, a halo,
and pools that alternate with darkness along a wall so the rhythm reads.

**3. Team Tether hardware still owns the highlight in two of three frames.** The brief
says teal is a secondary accent. Measured: T-01 parity (1,447 warm : 1,315 cool bright),
T-02 1:5, T-03 1:30. On top of that, T-01 introduces a white-lilac machine panel at peak
L 231 that is off both reserved colours. In the key art's stronghold panel the faction
colour is oxblood banners and one blue-lit door against a mass of grey stone and green
overgrowth — the hardware is a garnish on architecture. Here the architecture is a
backdrop for the hardware. T-02's banner is proof the project can do this correctly.

*(Runner-up, worth listing because it is cheap: the flat unlit doorway slabs in T-01
x 595–700 / y 285–410 and T-02 x 690–760 / y 262–400 are, in a room with a black floor,
among the brightest large shapes on screen and they read as render holes.)*

## The two bar questions

**A. Do these read as belonging to the world of `tetherbound-meadows-keyart.png`?**

**No** — but T-01 is close, and this is the nearest the set has come. What carries: the
warm cut-stone tone in T-01, the oxblood banner and ring emblem in T-02, and the vine
overgrowth idea, all of which are lifted straight from the board's stronghold panel.
What sinks it: the board's world is *legible in its darks* and colour-varied — grey
stone, green moss, brown timber, red cloth, one blue accent. These rooms are a single
brown hue over black, with cyan drawn on top. And T-03 is not in that world at all — a
cold grey-green spire lit by a neon strip belongs to a different, more sci-fi game than
the one on the board.

**B. Beside `palworld-0*.jpg`, would someone say this is trying to be the same kind of
game?**

**No.** Palworld's frames are bright, saturated, dense with readable props, and the
characters and creatures are the highest-contrast things on screen — in `palworld-01`
the Mammorest and the trainer's hair read instantly at thumbnail size. At sheet size
here, T-01's trainer is a 25-px dark smudge you have to hunt for and T-02 and T-03 have
no character at all. There is also nothing alive in any of the three frames: no
creature, no prop clutter beyond a few loose rocks, no evidence anyone occupies this
stronghold. Palworld's base shot is *full of stuff people put there*. These rooms are
empty corridors with lighting on them. Interiors are not represented in the refs, so I
am judging density, value range and character readability, not layout — and on all
three the answer is the same.

## Fixable by lighting/scene vs needs new art

**Fixable by lighting, placement and scene work (most of the list):**
- Raise the black point so the floor band lands somewhere around L 25–45 instead of
  0.6–4.5. Every "unreadably dark" region above is this one change.
- Kill the ambient warm wash and replace it with 3–5 *actual* torch lights per room at
  1.8–2.2 m on the walls, spaced so pools alternate with shadow. T-01 currently has
  zero; adding them and lowering the flat term is the entire "torch-lit" ask.
- Make every source cast to the floor. Right now only T-03's does, for one metre.
- Demote teal: drop conduit emissive strength and saturation until bright-warm beats
  bright-cool in all three frames (target roughly 3:1 warm, currently 1:1 / 1:5 / 1:30).
  T-03's diagonal bar is the first thing to cut.
- Delete or dim the T-02 corner wedge at x 1230–1280 / y 470–560 — it is the brightest
  cluster in the frame and has no object attached.
- Retint the T-01 machine panel off white-lilac onto reserved teal, and drop its
  intensity below the room's warm key.
- Give the doorway slabs light spill or a dark interior so they stop reading as holes.
- Put a key/rim on the trainer in T-01 so he reads at thumbnail size.
- Recompose T-03 so the machine is not the value focus, or push a torch in front of it.
- Fix the hard-clipped pool boundary on the T-03 sconce (x 690 / x 800 cuts) — that is a
  light-setup or lightmap artefact, not an art problem.

**Needs new or reworked art:**
- **A real fire.** T-01's pit at x 780–960 / y 405–465 has no flame, coals or embers, and
  T-02's lanterns are 15-px boxes. Torch-lit rooms need a flame mesh + particle + glow
  card that survives at 30% zoom. Nothing in these frames can be turned into that by
  changing a light.
- **The T-03 machine's surface.** Smeary, unreadable material at x 0–520 / y 0–600;
  it does not resolve into stone, metal or cloth at any distance. Relighting will not
  fix an unreadable material.
- **Occupancy props.** Bedrolls, crates, cabling, tools, banners at floor level, spent
  fires — the thing that makes Palworld's base shot read as inhabited. Three of three
  frames are bare.
- **Floor material.** Even correctly exposed, the floor is one tiling cobble at the same
  texel scale as the walls and ceiling; the references vary material and scale between
  ground and wall.
