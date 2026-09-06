# Cloudreach Cliffs — blind visual judge, AFTER (final)

Frames: `shots/atmos_after4/`, stands 01, 02-broken-causeways, 04, 11, rendered from this
branch's head with `tools/_capture_cloudreach_cliff_options.gd`. The judge was given the
contact sheet, the four full frames and `docs/reference/` only — not the source, the
conversation, or what had changed. It was additionally asked to answer three questions by
name, because the three gaps this lane owns are answerable yes/no and a general verdict
lets them hide.

Reproduced verbatim.

---

# Visual verdict — Cloudreach Cliffs, four frames

## First, and plainly: the cast

**The three characters in these frames belong to three different games.** Frame 11 puts them side by side and the mismatch is unmissable:

- The **blue raptor** (frame 11) is a dense, near-realistic bird — individually modelled overlapping feathers, iridescent blue-teal barbs, a hooked beak and a hard crest. It is the most detailed thing in the four frames by a wide margin. It would sit comfortably in a monster-hunting game.
- The **white owl-creature** (frame 11) is a soft plush toy — a smeared pale-grey wash with no crisp feather forms, wings that are thin flat planes with a gradient painted on them, and a face made of two tiny flat black dots with one highlight and no lid, brow or expression. Set two metres from the blue bird it looks like a different asset library.
- The **trainer** is a third register again: chunky stylised proportions, muddy hand-painted textures, a solid brown low-poly wedge for hair.

Against `palworld-01`, where Mammorest and the human read as one designed family — the same outline weight, the same cel-lit surface, the same saturation discipline — this is not a style. It is a pile.

And **the trainer is in bind pose in all four frames.** Arms out straight, fingers splayed, feet together, identical in 01, 02, 04 and 11. Every Palworld reference has the human doing something — aiming a bow, swinging a staff, crouching by a crate. Even the keyart's DAY and NIGHT panels have him standing with weight on one leg beside a pal. Here he is a mannequin dropped onto a lawn. This one thing does more damage to "is this a game" than any texture in the set.

---

## Ordered defects

**1. Frame 04 is 57% sky and the rest is a bare plane.** Measured: sky-value pixels are 57% of the frame, 29% of it is above luminance 200. The remaining ground is a flat tiling green field carrying three isolated grass tufts, one flower and nothing else, ending in a **perfectly straight razor line** against the sky on the right. No haze, no graduation, no silhouette break, no props, no rocks, no path edge. This frame reads as an unfinished greybox landscape. `palworld-02` shows the same open-field composition doing it properly: turf, bushes, dirt breaks, rock outcrops, trees on the ridge and three pals fighting in the middle distance.

**2. Frame 11: near-black unlit rocks.** 21% of frame 11's pixels are below luminance 40. The boulders behind the owl-creature, the boulder right of the pole cluster, and the fallen log at the pole base render as flat, faceted, pure black-green shapes with no sunlit face at all — while the trainer three metres away casts a long hard sun shadow. They read as holes cut in the ground. This is the frame's dominant read at contact-sheet size.

**3. Frame 11: a swirl artifact smeared across the landmark.** The entire face of the central spire — the region's signature silhouette — is covered in concentric white spiral scratch lines, plus a soft vertical dark band down its centre with no source. This is a projection or detail-map failure, not strata. The one object in the four frames that is supposed to carry the region's identity is wearing a bug.

**4. Frame 02 shows no causeway and no gap.** The wooden ramp runs from the player's hill onto the next hill over **continuous, unbroken grass**. Grass is visible under and beside it for its entire length. Nothing is broken, nothing is spanned, nothing is crossed. A frame captioned "broken causeways" in a vertical cliff region shows a plank ramp lying on a lawn.

**5. Frame 01: an untextured cyan slab on the keep.** A saturated flat turquoise box sits on the battlement between the two towers. It is unlit, untextured, and the only pixel of that hue anywhere in the four frames. It reads as a missing-material placeholder on the region's most prominent building.

**6. Frames 01 and 02: scatter props floating in empty sky.** Small dark vertical dashes and squashed grey discs hover in open blue sky — in 01 well above the horizon and left of the keep, in 02 above and beyond the right-hand cliffs. Nothing is under them. They read as grass cards or small props detached from terrain that isn't drawing.

**7. Frame 01: a hard green wedge painted onto the mesa.** The right face of the keep's mesa carries a bright green triangle with a razor-sharp straight boundary cutting across rock geometry. It reads as a vertex-paint or blend-mask error, not as a grassy slope.

**8. Frame 11: a hard-edged rectangular patch of different grass.** Around the pole bases, a slab of acid yellow-green dense grass sits on the mid-green lawn with an unblended straight-line boundary. Two different grass materials, no transition.

**9. Frame 02: the guy-ropes are rigid sticks that end in nothing.** The left rope is a straight square-section beam with zero catenary sag; it passes *through* the short stub post beside it and terminates in the grass without a tie-off. The stub post itself has no function. The tall gate post's **flat bottom polygon is visible above the grass line** — it sits on the lawn rather than in it, with no dirt, no displacement, no contact shading.

**10. Frame 01: the biggest object in the frame casts no shadow.** The large foreground tree throws nothing onto the meadow it stands in — the grass beneath it is exactly as bright as the grass ten metres away, and there is no contact darkening where the trunk meets the ground. Meanwhile the trainer in 04 and 11 casts a long, hard, correctly-directed one. Across the sheet the frames disagree about whether large objects cast shadows at all.

**11. Every cliff and rock in the set is untextured.** Frame 02's right-hand cliff wall, frame 01's rock band and mesa, frame 11's spire: large faceted masses in a single flat grey or grey-green, with no strata, no colour break, no moss beyond a couple of dabs, no rubble at the base, no scale-giving detail. Green grass sits on their tops as hard-edged flat blobs. `palworld-04` does exactly this shot — a plateau landmark past a stone ruin — and its rock carries banding, warm/cool shift, vegetation on ledges and debris at the foot.

**12. The cloud sea is opaque white cardboard.** In 02 (both sides) and 11 (right) the below-horizon cloud layer is a set of hard-edged, near-pure-white lumps with no internal value and no soft transition. It abuts the cliff geometry on a hard line. It reads as snowdrift or spray foam. In 01 it's worse: flat white ellipses and flat grey-blue triangles, plainly cutouts.

**13. Frame 04: grass cards break into dashed dotted lines** in the middle distance, and a cluster of LOD'd grass renders as black speckles on the left slope. Also on the far left, a dark blue-grey wedge with a hard white rim protrudes from the ground — an untextured, unlit shape with no readable surface, which looks like clipping geometry rather than a rock.

**14. Frame 11: the pickup's glow is a visible rectangle.** The pale-blue glow behind the green crystal has a discernible straight sprite edge that does not wrap the object. The crystal itself is a pure saturated green outside the keyart's swatch row.

**15. Regularity that reads as generated.** Frame 01's ridge trees are identical copies of one broccoli tree at one scale, evenly spaced in a line; the rock band beside them is the same block repeated at one scale along a line. Frame 02's three bells are identical and evenly spaced. Frame 11's poles are the same pole at four scales with no crossbeam, rope, platform or structure connecting any of them — an unfinished scaffold. Frame 01's meadow flowers are flat billboard quads whose flatness is visible wherever one turns edge-on.

**16. Scale — mostly agreeing, with two exceptions.** Using the 1.80 m trainer: in frame 11 the white creature measures ~1.5 m and the blue one ~2.0 m, so the more imposing creature is correctly the larger one — that ordering is right. The exceptions: (a) in frame 01 the foreground tree's **trunk alone is roughly 1.7 m across**, nearly the trainer's full height, while the ridge trees of the same family read at 3–4 m, so one nature family spans a scale range it can't justify; (b) in frame 04 the "high roost" mesa tops out at barely more than the height of the small tree standing in front of it, so the region's destination landmark has no dominance over a sapling.

---

## The three named questions

### 1. Does the horizon carry depth?

**(a) Haze band — partial, and absent where it matters most.** Frames 01, 02 and 11 have a milky white-grey wash on distant cliffs, but it is a flat desaturating veil, not a graded band: it removes value from the far plane without layering it, so the distant rock in 01 and the far cliffs in 11 sit at one uniform low contrast rather than receding through stages. **Frame 04 has no haze band whatsoever** — the grass meets the sky on a hard line with zero atmospheric graduation across the entire right half.

**(b) Cloud layer below eye level — yes in three, no in one.** Frame 02 has it clearly on both sides (a bank of white lumps below the causeway hill's horizon). Frame 11 has it on the right, beyond the grass edge. Frame 01 has it left of the foreground tree, below the grass horizon. **Frame 04 has none**: the small cloud puffs under the floating island sit *above* the terrain horizon line, so nothing in that frame is cloud below eye level.

**(c) Terrain lower than the player's ground — yes in three, no in one.** Frame 01: distant blue-grey mountain forms below the grass horizon on the left, and a drop beyond the rock band on the right. Frame 11: the far cliff shapes at the right edge, below the plate the player stands on. Frame 02: the right-hand cliff wall descends below the player's plane. **Frame 04: nothing anywhere in the image is lower than the ground under the trainer's feet.**

So: two of the three depth ingredients are present in three frames and none of them are in frame 04. But even where present they are rendered as flat cutouts, so the horizon carries *layers* without carrying *depth*.

### 2. Does this read as a high, vertical place? Does the player ever stand at or near an edge with a drop beyond it?

**No, and no.** In all four frames the player stands in the middle of a broad, gently rolling green field. Frame 01: a hillside meadow. Frame 02: a continuous lawn with an unbroken ramp on it. Frame 04: an open field. Frame 11: mid-lawn with the ground's edge roughly thirty metres to his right and the drop itself not visible from where he is.

The only two places the region's verticality appears at all are read from frame corners, not from the player's position: the right edge of frame 11 and the right flank of frame 02. And frame 11's edge actively undermines it — the ground the player stands on terminates as a **thin flat-bottomed disc with a visible smooth grey underside and a dark rim**, a grass platter about one unit thick floating over white. There is no cliff face, no strata, no receding wall, no sense of a fall. Whatever this region is meant to be, four frames of it say "meadow."

### 3. Objects that read as broken, unrendered, or detached

Named, by frame:

- **Frame 01** — the cyan slab on the keep battlement (untextured/unlit placeholder); the hard green triangular wedge on the mesa face (blend-mask error); the dark dashes floating in open sky left of the keep (detached scatter).
- **Frame 02** — the dark dashes and squashed grey discs floating above the right cliffs (detached scatter); the guy-rope clipping through the stub post and terminating in grass; the exposed flat bottom face of the tall gate post; the rightmost bell's suspension rod passing above the crossbeam without an attachment.
- **Frame 04** — the dark blue-grey wedge with a white rim at the far-left ground (untextured, unlit, reads as clipping geometry); grass cards breaking into dashed dotted lines; the black speckle cluster on the left slope.
- **Frame 11** — the concentric white spiral scratches across the whole spire face; the near-black unlit boulders and the pure-black log; the hard-edged rectangular grass patch at the pole bases; small green-capped grey discs hovering in the sky right of the spire and one at left; the visible rectangular sprite edge on the pickup glow; the visible flat underside of the ground plate at the right edge.

**The floating island in frame 04: authored, not a rendering failure.** It has a deliberate, non-random silhouette — a crown of thin vertical spires along the top, terraced flanks stepping down, and a tapering inverted base — and a cluster of small clouds is placed deliberately beneath it. Failures do not produce that shape or that supporting detail. But it currently *fails as a landmark* for reasons that are fixable: it is rendered as one flat dark value with no lit face, no rim light, no green on top, no colour and no scale cue, and it sits at almost exactly the same value as the mesa behind it. A first-time player would read it as a grey smudge on the sky rather than as the place they are about to fly to. Authored, under-lit, under-rendered.

---

## The three things that most separate these frames from the references

**1. Large forms have no surface.** `palworld-04` frames a plateau landmark past a stone ruin, and its rock reads through banding, warm-to-cool shift across the face, plants clinging to ledges and rubble at the base — the surface tells you how big it is. The keyart's stronghold panel and its rune monolith do the same with weathering and moss. In **frame 01** the keep's mesa is one flat grey-green blob with soft lumps, and the rock band right of it is one flat grey; in **frame 11** the central spire is a single blue-grey slab whose only "detail" is a texture artifact. Every landmark in this set is graybox with a stone tint, which is why none of them reads at any distance.

**2. Ground cover.** `palworld-02` and `-03` layer short turf, tall grass, ferns, bushes, scattered rock, dirt breaks and flowers, clustered rather than sprinkled, with a darker under-layer giving the ground depth. **Frame 04** answers with a bare tiling plane, three tufts and one flower under 57% sky. **Frame 11** answers with a flat mown lawn, one hard-edged patch of a different grass, and nothing else. Only **frame 01** has a grass layer at all, and its blades are long single-hue ribbons of uniform length radiating in random directions — thrown straw, not turf.

**3. Nothing is happening and nobody is posed.** All five Palworld shots have an event in them: a boss roaring mid-attack, pals following down a path, a base being assembled — and the human is always in an action pose. The keyart's DAY and NIGHT panels have the trainer standing with a pal, weight shifted, reading the horizon. **Frames 01, 02 and 04** have one bind-posed mannequin alone in an empty field: no creature, no NPC, no animal, no smoke, no water, no motion. Even **frame 11**, the only one with creatures, has both of them standing inert on grass. The world reads uninhabited.

---

## Bar question A — do these belong to the world in `tetherbound-meadows-keyart.png`?

**No.**

*What carries it:* the palette family is genuinely close — the greens, sky blues, creams and warm woods sit inside the keyart's swatch row. **The reserved oxblood is correctly and completely absent**; no danger red has leaked onto a friendly element anywhere in the four frames. The keep in 01 and the bell gate in 02 are recognisable landmark language of the right kind. The tree and grass hues match well enough that the frames and the board read as the same time of day in the same world.

*What sinks it:* the board's own two load-bearing notes are the ones that fail. "Silhouettes and landmarks visible from distance" — these frames have distance but nothing in it, because the far plane is a flat desaturated wash and the landmarks are untextured masses that go to one value the moment they are more than fifty metres away (04's mesa and floating island are the clearest case). "Cozy and inviting, with hints of mystery" — the keyart's cosiness comes from layered undergrowth, dappled light through canopy, streams and ponds, path edges with stones, buildings with smoke. There is **no water, no settlement, no NPC and no dappled light** in any of these four frames; the lighting is a single hard key against a flat ambient, which is why backlit forms in 04 have no rim and rocks in 11 go black.

*Fixable by changing the scene:* ground-cover density and clustering; prop scale variety and breaking up the repeated tree/rock rows; the hard grass-patch seam in 11; the near-black rocks (a material/ambient fix, not new art); the cyan slab in 01; the green wedge on the mesa in 01; the sky-floating scatter in 01/02/11; the spiral artifact on the spire in 11; the rope and post contact in 02; a haze graduation at the far plane; filling frame 04; putting the camera and the player at an actual edge; posing the trainer.

*Not fixable by changing the scene:* the rock and cliff family has no strata or detail texture at all — that needs new rock materials and mesh detailing before any amount of placement helps. The cloud sea needs a real volumetric or a far better card set; no scatter change rescues opaque white lumps. The trainer needs an idle animation and better hair and face art. And the owl-creature and the blue raptor cannot be reconciled by lighting — one of them has to be re-authored or at minimum re-shaded to the other's register.

## Bar question B — beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**No.**

*What carries it:* the third-person over-shoulder framing is right. The trainer's silhouette with the backpack is a legible adventure-game read. The saturated green-and-blue daylight palette is in the same family. And the two creatures in frame 11 — the blue raptor especially — show the right level of creature *ambition*, even though they don't agree with each other.

*What sinks it:* every Palworld frame tells you in a quarter-second that something is underway; not one of these four tells you anything is happening at all. There is no encounter, no motion, no HUD, no companion behaviour, no lived-in clutter — and in frames 02 and 04, over half the image is empty. Palworld's ground is dense and its rock is detailed at every distance; here the ground is bare and the rock is flat. Palworld's cast is one coherent art bible; here it is three. Placed side by side, someone would say Palworld is a shipped game and these are level-blockout screenshots from an engine — which is the honest gap, and most of the top half of it is scene work rather than purchases.
