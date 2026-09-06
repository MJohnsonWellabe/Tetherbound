# Burrow Warrens — Visual Judge, Round 6

Blind pass over `shots/warrens_63/` (sheet plus eight frames) against
`docs/reference/tetherbound-meadows-keyart.png` and `docs/reference/palworld-0*.jpg`.
Software GL: composition, silhouette, colour relationships, scale and geometry are
judged; fine lighting and frame time are not. No trainer appears in any frame, so the
only ruler in the picture is the Team Tether lamp post at the threshold (2.6 m) and, by
the brief, the doorway (3.4 m).

## Exterior (frames 00–03), judged first and hardest

### Does the bank read as a landmark from 60 m? (00)

Partly. At full size the dome is centred, sits above the horizon and is flanked by
trees, so the eye finds it. At 30% it survives only as "a grey-green lump between
trees": it is the same hue and nearly the same value as the meadow it sits on, and the
dark boulders at its foot are the only thing separating it from the ground. Nothing
about the lump says *entrance*. The mouth itself is a dark notch a few pixels wide.

What does read from 60 m is the wrong thing: **two bright vertical slits in the face of
the mound directly above the arch, and a lit yellow-green patch between them**. They are
the brightest values on the landmark and the eye goes straight to them. They are also
visible in 03 at full size (sun-lit stripes at roughly x≈550 and x≈720, y≈100–250),
where they are clearly gaps in the mound shell showing lit terrain behind it. This is a
geometry seam, not a feature, and it is the first thing a player will see.

### Does the entrance read as something dug into earth? (00–03)

No. Three separate reasons, each addressable:

1. **The mound is a smooth, grass-textured paraboloid.** In 01 and 02 it is a clean
   mathematical dome / ridge with the *same* speckled grey-green material as the meadow,
   no dark soil, no slumping, no exposed roots, no secondary holes, no claw or drag marks.
   It reads as a turf hill or a very large boulder under moss, and trees grow straight out
   of its summit (00, 03), which reinforces "natural hill" and works against "bank that
   something dug into".
2. **The arch is a lumpy chocolate-brown tube** (03). It reads as melted plastic or an
   over-thick root pretzel rather than compacted earth or exposed roots; its surface is
   flat-shaded and has no relation to the mound's material above it or the boulders
   beside it.
3. **The brown ground apron only exists at the threshold** (03). From the approach
   (00–02) the mound sits directly on grass with no spoil heap, no darker earth fan and
   no trampled path leading to the mouth. There is no road visible in 00 at all, despite
   the frame being taken "along the approach road".

### Does the earth read as displaced? (00–03)

No. In 03 the lower half of the frame is a single, uniform, untextured brown plane with
no relief. It is the one place earth is visible and it reads as an unfinished floor
mesh, not a spoil apron. Boulders in 01/02/03 are low-poly blocks with a flat bright
green polygon painted on top ("grass caps") — they look set down, not dug out or
pushed aside.

### Does anything steal focus from the entrance?

Yes, in order of loudness:

- The slit/lit-patch artefact above the arch (00, 03) — see above.
- In 03, **a hard-edged white strip on the ground across the threshold**
  (roughly x 500–900, y 460–530, with a second one right of centre). It is the brightest
  ground value in the frame and reads as a z-fighting plane or an untextured mesh.
- In 00, the near-left tree trunk is a saturated red-orange more intense than anything in
  the key art, and the rust/orange grass tufts lower right are the most saturated element
  in the frame; both out-pull the entrance.
- In 01, a **giant slab boulder cantilevered off the mound's right shoulder** with air
  under half of it. In 02, a **flat disc-shaped rock hanging at the top-left edge** of
  the frame and another slab projecting horizontally off the mound's right side. Floating
  rocks read as bugs and pull attention.

### Is scale legible?

From 60 m, no — there is no human-scale cue. The lamp post is three pixels; no trainer,
no fence, no track. The mound could be 6 m or 30 m.

At the threshold (03), the lamp post gives a measurement, and it cuts the wrong way.
The post spans ~155 px (2.6 m). The arch opening, at slightly greater depth, spans
~130 px from ground to underside. Allowing for the depth difference, the mouth reads as
roughly 2.5–3 m, i.e. about lamp-post height — not a 3.4 m doorway and certainly not
a hole *dug by* a creature 3.2 m at the shoulder. A burrow mouth should read clearly
larger than the thing that made it; this one reads person-and-a-half.

The boulders beside the arch are ~2× the post (≈5 m), which is fine for a bank.

### Other exterior defects

- **Ground palette.** All four exterior frames have a pale, desaturated, whitish
  grey-green ground with white highlights. It reads as frost, or an overexposed dead
  meadow. The key art meadow is a saturated warm green with dark shadow values;
  palworld-02/03 are warm yellow-green. This is the single biggest colour gap and it is
  present in every exterior frame.
- **Procedural scatter.** 01's lower half is the same cactus-like green sprig repeated at
  the same scale ~15 times at near-even spacing. 02 the same. Reads as generator output.
- **Tree trunk colour drifts within one grove**: red-orange (00 left), grey-blue (01),
  pink (02), grey-white (03 right). One grove should share a bark family.
- **No warm light at the mouth.** The brief describes a warm-lit entrance; no exterior
  frame shows one. The mouth is a dark hole and the lamp bulb is unlit white in daylight.
- **The boss is visible from the threshold** (03, through the mouth): the guardian and
  a straight corridor of square-cut grey stone jambs are in direct sightline from
  outside. That removes the mystery the key art asks for and previews the interior's
  architecture problem (below) before the player is inside.
- Sky and cloud painting are good and do belong to the key art's world. Tree canopy
  silhouettes (00) are the best-reading exterior element.

## Interior (04–07), briefly

- **Architecture contradicts the premise.** 04, 05, 06 and 07 all show flat planar
  walls, a flat sand floor, granite-textured ceiling slabs and rectangular
  cross-section beams and pillars — in 07 the beams are set into the wall as a
  stone Tudor frame. This is a quarried mine or dungeon corridor, not a warren dug by
  animals. Nothing in the interior is round, sloped or earthen.
- **Materials do not connect to the outside.** Exterior: grey-green turf, chocolate
  arch, dark-brown low-poly boulders. Interior: granite, flat matte brown wall planes,
  pale beach-sand floor with green mould splodges. No material crosses the threshold in
  either direction, so the two halves do not read as one place.
- **04**: the camera is half inside a wall — a foreground slab occupies the left 45% of
  the frame. A dark rectangular patch on the back wall (≈600–680, 160–250) reads as a
  decal error. Barrel and crate are correctly scaled (barrel ≈0.9 m) and are the best
  props in the set.
- **05**: the mushrooms are the right idea (the only thing in the interior that says
  "living burrow") but are flat-shaded uniform mint with no gills, caps intersecting each
  other and stems passing through caps; they read as paper cut-outs and are the size of
  a person. The corridor is a straight rectilinear tube with square lintels.
- **06/07**: the dead-branch sprites stuck to the walls and ceiling read as black
  spiders at any size.
- Lighting is flat and even everywhere; there is no visible source, no pool of light,
  no dark pockets. Value range in every interior frame is a narrow mid-dark band.

### The guardian, measured (05, 06)

- **Scale agrees with the brief.** In 05 the guardian sits inside the far doorway with
  its back just below the lintel — roughly 85–90% of the opening, consistent with
  3.2 m to the shoulder against 3.4 m. In 06 it spans ~215 px against a doorway at
  slightly greater depth spanning ~200 px, again consistent. No scale defect.
- **Posture is a defect.** In 06 the creature **floats**: all four paws are tucked up in
  a pounce/swim pose, the feet hang ~30 cm above the floor, and its contact shadow is a
  blob displaced down-left of the body. As a boss idle in its own den it reads as a
  plush toy suspended on a wire.
- **Appeal.** Head is ~40% of body length with a cub-like profile; the mossy shell on the
  back is a good burrowback idea but is small and low-contrast. Against palworld-01's
  Mammorest — mass, horns, a planted stance, a fight that fills the frame — this reads
  as a cub, not a guardian. Style also clashes: hard black ink outlines and a
  high-contrast speckled texture on the creature against photo-textured matte walls,
  plus a single hyper-saturated lime grass sprite behind it that is the only saturated
  green in the whole interior.

## The three things that most separate these frames from the references

1. **The landmark is not made of earth (00, 01, 02, 03).** Palworld-02 cuts its cave
   mouths into a cliff whose rock is a distinct darker material from the grass, with a
   worn earth fan spilling out of each mouth; the key art's standing stone reads as a
   landmark purely by material and value contrast with the meadow. Here the mound is the
   meadow's own texture stretched over a smooth dome, the only earth is a flat brown
   plane at the threshold, and the brightest thing on the bank is a geometry gap.
2. **The ground colour is wrong in every exterior frame (00–03).** The key art and
   palworld-02/03 meadows are saturated warm greens with a real shadow value; these are
   pale, whitish grey-green with no dark. Everything on top of the ground — mound,
   boulders, trees — inherits the flatness.
3. **The interior and its boss do not look like an event (05, 06, 07).** Palworld-01
   makes a boss room out of mass, a planted creature and a dark backdrop it pops against.
   Here a floating, cub-proportioned creature idles in a flat-lit rectilinear stone
   corridor that could be any mine; nothing says "the thing that dug the hill lives here".

## Bar questions

**A. Do these frames read as belonging to the world in the key art?** — **No.**
The sky, cloud painting and tree canopy silhouettes (00) do belong. What sinks it is the
ground palette (desaturated whitish green in every exterior frame), the smooth
untextured landmark, and an interior that shares no material or shape language with
anything on the board.

**B. Beside the Palworld shots, would someone say these are trying to be the same kind
of game?** — **No.** Frame 03 (a cave mouth in a bank, a lamp post, boulders) is the
closest in intent to palworld-02. Everything else — the flat brown plane, floating
slabs, painted grass caps, the white strip, the square-cut interior, and a boss that
hovers — reads as blockout, and no Palworld frame reads as blockout.

### Fixable by changing the scene

- Ground palette and value range (saturation, darker shadow tone) — every exterior frame.
- Mound material: a dark soil/earth material on the mound with turf only on the crown;
  a spoil apron and darker earth fan from the mouth out to the approach; a visible track.
- Close the two slits in the mound shell above the arch (00, 03).
- Remove the white threshold strip (03); ground the cantilevered slab (01) and the disc
  and projecting slab (02).
- Enlarge the mouth so it clearly exceeds the guardian's height, or shrink nothing —
  grow the opening.
- Warm light at the mouth; lit lamp; a light pool inside the door.
- Break the sightline from threshold to boss.
- Vary sprig scale and cluster the scatter; unify bark colour within the grove.
- Interior: replace planar walls / square beams with rounded earthen tunnel sections and
  exposed roots; add a light source and dark pockets; retire the wall-spider sprites.
- Guardian: plant it on the floor with a correct contact shadow; give it a standing or
  crouched idle; swap the lime grass sprite for something in the interior palette.

### Not fixable by scene work (needs art not in the build)

- The guardian's proportions (cub head-to-body ratio) and the absence of a
  boss-weight idle animation — rig/animation and, likely, a proportion pass on the mesh.
- The ink-outline/speckled-texture style of the guardian versus the world — a
  shader/material decision that must be made once for all creatures, not per scene.
- Mushrooms with gills and a real cap profile, and a burrow-arch mesh that reads as
  compacted earth and roots rather than tubes.
