# Area 6 — camps / rest points / build structures — blind critique, round 1

Frames: `shots/census/06-build-camp/` — 6 PNGs from `tools/capture_build_pieces.gd`
(`build_pieces_lineup`, `build_pieces_corner`), `tools/capture_creature_bed.gd`
(`creature_bed_alone`, `creature_bed_scale_check`) and
`tools/_capture_creature_bed_rest.gd` (`06-creature-resting`,
`07-creature-resting-far-side`). Critic given only the sheet, the frames,
`docs/reference/` and the rubric, plus factual rig context (bare presentation
stage, so "the world is empty" is not a defect). Verbatim below.

---

I have read the rubric, all six references, the contact sheet, all six frames at full size, plus targeted zooms and pixel samples. Here is the critique.

---

# Visual critique — `shots/census/06-build-camp/`

Six frames: two of a creature on a rest mat, four of building/furniture pieces on a black void stage.

## Up front: the creature

The badger in **`06-creature-resting.png`** is the strongest asset in this set by a wide margin, and I want to say that before the criticism so the criticism lands in the right place. It has a bespoke hand-painted look, a strong two-value pattern (dark umber body, cream facial blaze), an appealing large-iris face with a real catchlight, and a genuine design hook — the mossy grey-green stone plates on shoulder and forepaw. Against `palworld-01-boss-fight-forest.jpg` it is less bold and less exaggerated, but it is trying to be the same kind of thing. It is not sourced-generic and it does not need excusing.

Its problem is that it only works from one angle. **`07-creature-resting-far-side.png`** is the same creature from behind and it is a featureless brown mound: no readable silhouette, no blaze, the stone plates flattened into olive mud. Palworld's creatures read from every angle — that is a large part of why they work as things you fight and command. Sampled pixels in `07-creature-resting-far-side.png` come back at literally **(0,0,0)** on the fur and **(37,51,45)** on the plates; 1.4% of that frame is pure crushed black. The rear silhouette is not merely dark, it is clipped to zero with no recoverable form.

---

## 1. Silhouette and readability at small size

Viewing `_sheet.png` at thumbnail:

- **`06-creature-resting.png`** passes. Badger reads instantly.
- **`07-creature-resting-far-side.png`** fails. It reads as an unidentifiable dark lump with a large shadow. Nothing about it says "badger," "creature," or even "animal."
- **`build_pieces_lineup.png`** fails hardest. At thumbnail it is four disconnected pale shapes on black that do not resolve into objects: the wall reads as a blank envelope, the roof as an orange chevron, the fence as a stray twig, the floor as a tan parallelogram. Nothing in this kit has a memorable silhouette.
- **`build_pieces_corner.png`** reads as "a floating fragment of a house," which is close to correct, but the roof detaching from the wall (see §7) makes the thumbnail read as debris rather than a structure.
- **`creature_bed_alone.png`** and **`creature_bed_scale_check.png`** pass — bed and bench both read as furniture at thumbnail. These are the only build-kit pieces with silhouette identity, and it comes from their carved skirt cutouts and chunky rail profile.

The kit-wide failure: door, wall, floor slab, fence and roof rafters are all pale warm rectangles of near-identical value. Put four of them on screen and they merge. `palworld-05-base-building.jpg` at the same scale still lets you pick out the palisade, the stone pillars, the crate-and-basket workstation, and the wooden platform, because each has a distinct proportion and a distinct value.

## 2. Colour and value structure

**There is no value range.** `build_pieces_lineup.png` has **9.4% of its pixels with a clipped channel** — and since most of that frame is empty void, that means a very large fraction of the actual object surface is blown to white. Confirmed samples: plaster `(255,255,209)`, fence rail `(255,230,164)`, wall frame top rail `(255,187,104)`, roof tile ridge `(255,153,84)`. `creature_bed_scale_check.png` bench top clips at `(255,168,104)`. Meanwhile `07-creature-resting-far-side.png` crushes to `(0,0,0)`. The set has blown highlights and crushed shadows simultaneously, with the entire build kit sitting in a narrow high band between them. Nothing in `build_pieces_lineup.png` or `build_pieces_corner.png` is dark: no shadowed recess, no dark under-eave, no iron, no soot. That is why the pieces have no weight.

**Wood tints do not agree.** Sampled across `build_pieces_lineup.png` alone: floor slab `(199,123,75)` desaturated red-brown, door `(182,116,76)` cooler mid-brown, wall top rail `(255,187,104)` orange-tan, fence rail `(255,230,164)` bleached pale yellow, rafters yellow-ochre with green-tinged grain. Five wood hues in one frame that is supposed to be one buildable kit. `creature_bed_alone.png` bed `(198,123,69)` and `creature_bed_scale_check.png` bench `(192,118,64)` do agree with each other — those two are one family — but neither matches the structural kit.

**Two colours are off the board.** The roof tile in `build_pieces_lineup.png` and `build_pieces_corner.png` is a hot fluorescent orange that has no counterpart anywhere on the keyart palette strip, which runs greens → ochre → sand → grey → steel blue → violet → mauve → dull maroon. The keyart's own roofs (STARTING SETTLEMENT panel, and the village in the top-left panel) are a muted brown-terracotta. This tile is the loudest object in the entire set — louder than any danger element should be allowed to be, which is a problem in a project that reserves oxblood for Team Tether. The second offender is the duvet in `creature_bed_alone.png` at `(133,213,216)` — a bright pool-cyan with no entry on the palette strip either.

**Do these read as one place?** No. The two creature frames sit on flat unlit green `(123,172,101)` under a neutral grey sky; the four kit frames sit on a black void. That's the rig and I'm not counting it. But even within the kit frames, `creature_bed_*` and `build_pieces_*` are lit and textured differently enough that they do not read as one shoot.

## 3. Intentionality — does this read as one authored kit?

Three families, not one.

1. **Furniture family** — bed and workbench in `creature_bed_scale_check.png`. Genuinely cohesive: same honey wood, same chunky chamfered stock, same carved cutout silhouette, same grey iron fittings, same hand-painted grain. This one works.
2. **Structural family** — wall, door, roof, floor, fence in `build_pieces_lineup.png`. Flatter shading, hard-edged near-photographic grain rather than painted grain, no carved silhouette language, and the five wood hues noted above. This does not belong with family 1.
3. **The rope rest mat** under the badger in `06-creature-resting.png` — a woven wicker disc ringed by a coiled cool grey-blue rope. That grey-blue shares a hue with nothing else in the set, and the woven treatment appears on no other piece.

Additionally: the plank bed in `creature_bed_alone.png` is unmistakably a **human** bed — pillow, sheet, duvet, headboard, roughly 2m. The badger's bed in `06-creature-resting.png` is a rope basket. The filename says both are creature furniture; the art says one is a bedroom prop and the other is a pet basket. Someone building a camp will place both and they will not look like the same designer made them.

The kit also has **no joint language**. Look at `build_pieces_corner.png`: nothing on any piece — no peg, no notch, no bracket, no socket — communicates how the wall meets the floor or the roof meets the plate. `palworld-05-base-building.jpg`'s structures read as buildable because the pieces show visible framing joints.

## 4. Lighting

**The two creature frames disagree about the light.** In `06-creature-resting.png` the key is almost head-on from camera and the badger casts essentially no contact shadow — a faint smear behind the right hip only, nothing under the front paws or the rope ring, so the creature reads as floating a few centimetres off the ground. In `07-creature-resting-far-side.png` the same subject on the same stage throws a long, dense, correctly-grounded shadow toward camera-left. Same asset, same rig, two different lighting setups. That pair cannot be used as an A/B of anything.

`07-creature-resting-far-side.png` is additionally underexposed to the point of destroying the asset — see §1.

**The build frames are lit with a key and no fill.** In `build_pieces_corner.png` the roof casts a hard-edged triangular shadow across the plaster wall with zero penumbra and zero ambient lift; the shaded half goes flat grey-blue and reads as a painted stripe on the texture rather than as shadow. Every under-surface in `creature_bed_alone.png` — the underside of the side rail, the inside of the skirt cutout, the mattress-to-frame junction — is the same brightness as the lit top faces. No ambient occlusion anywhere. Objects with no contact darkening have no mass, and that is the largest single reason these props look lighter and cheaper than anything in `palworld-05-base-building.jpg`.

## 5. Depth

(Fog/horizon question skipped per instruction — these are void-stage frames.)

No LOD or chunk seams visible. But note that **nothing in the four kit frames has any depth cue at all**: no ground plane, no contact shadow, no perspective anchor. In `build_pieces_lineup.png` the four pieces float at unknowable distances, which is precisely why the frame fails as a lineup — you cannot compare pieces whose depth you cannot establish. This directly poisons the scale check in §8.

## 6. Interface

(Skipped — no UI in these frames.)

## 7. Artefacts

These are the concrete, actionable bugs.

- **`build_pieces_lineup.png` — severe texture aliasing / moiré.** The wall's lower V-brace, the wall's top and bottom rails, and the floor slab all break into shimmering dotted stripe interference. On the floor slab in `build_pieces_corner.png` this is worst: the plank lines dissolve into a regular dashed dot-field across the whole surface, which at thumbnail reads as gravel or rust rather than wood. This is either missing mipmaps or a grain texture at far too high a frequency for the texel density. **It is the most visible defect in the set.**
- **`build_pieces_lineup.png` — the wall's plaster panel is a separate offset card.** A pale sliver of plaster protrudes past the timber frame along the top-right and down the entire right edge, and the frame casts a shadow onto the panel behind it, exposing the gap. The wall reads as two stacked decals, not a wall.
- **`build_pieces_lineup.png` / `build_pieces_corner.png` — the roof is single-sided.** Only one slope carries tiles. In `build_pieces_corner.png` the left slope shows dark unfinished brown planking, which means this is the *underside* with no soffit treatment. Anyone standing inside a built house will see that raw brown plane as their ceiling.
- **`build_pieces_corner.png` — green fringe pixels** along the ridge and at the right-hand tile end where tile meets rafter. UV atlas bleed / insufficient edge padding.
- **`build_pieces_corner.png` — the roof does not sit on the wall.** There is visible black void between the left rafter's lower edge and the top plate beam, and the beam's own left end hangs over empty space with a sawn face exposed. The roof also overhangs the wall by several times the wall's width with nothing beneath it.
- **`build_pieces_corner.png` — the floor slab intersects the door and the wall.** The slab passes through the wall's V-brace, occludes the door's lower-left corner, and its far edge cuts a hard line across the plaster.
- **`build_pieces_corner.png` — the fence post is planted through the floor slab**, with slab visible on both sides of it. The fence also dead-ends in mid-air and its far-right post is clipped by the frame edge.
- **`build_pieces_corner.png` — the floor slab has zero thickness.** Its near edge is a literal 2D plane. Any floor-to-wall junction in the built camp will show a paper seam.
- **`creature_bed_alone.png` — the cloth is a different rendering language from the wood.** The turquoise duvet is one smooth gradient with a single specular smear, no fold geometry, no seam, no texture; the white sheet is flat `(255,255,255)` with two hard creases and the pillow reads as a folded card. Beside the hand-painted wood grain 20cm away, the cloth looks like injection-moulded plastic. The duvet's right-hand overhang is a flat card with a hard straight bottom edge and no drape or thickness.
- **`creature_bed_alone.png` — the iron studs are painted-on.** Flat grey circles with one lighter dot, no bevel, no cast shadow, no seating recess.
- **`creature_bed_alone.png` / `creature_bed_scale_check.png` — the carved skirt bottoms read as damage.** The footboard's lower profile and the left leg in `creature_bed_scale_check.png` are jagged notched silhouettes that at small size read as splintered/broken rather than as intentional carving.
- **`creature_bed_scale_check.png` — visible tiling seam** on the bench top where the plank surface meets the metal end strap, and the top's dark dash pattern repeats at a fixed interval that reads as a tile artefact.
- **`06-creature-resting.png` — the rope mat's woven interior is a muddy low-res blur** with no discernible weave, at visibly lower texel density than both the rope ring around it and the creature on top of it.
- **`06-creature-resting.png` — the badger's fur is entirely painted colour** with no rim light, no fuzz, no silhouette breakup; the ear interior is a flat black hole with no inner-ear geometry.

## 8. Scale agreement

**There is no ruler anywhere in this set.** The trainer does not appear in any of the six frames — including the one named `creature_bed_scale_check.png`. That frame checks a bed against a bench. It does not check either against the 1.80m human who will stand next to them, or against the creature that is supposed to sleep in one.

Worse: **the two objects that most need to be scale-checked against each other never share a frame.** The badger is in `06-creature-resting.png`. The bed is in `creature_bed_alone.png`. Nothing establishes that they belong to the same camp at the same scale.

What is checkable:

- **`06-creature-resting.png` — the creature does not fit its own bed.** The rope ring is roughly 1.15× the badger's body length and the creature's hindquarters and rear paws hang outside it, with the front paws resting on the rope rim rather than inside. Either the mat is one size too small or the creature one size too large. As a "creature at rest in camp" beat this currently reads as an animal that has been put in the wrong basket.
- **`creature_bed_scale_check.png` — the frame does not answer its own question.** The bed sits nearer-left and the bench further-right at a different depth, so their apparent sizes are perspective-dependent. Put both on a common baseline at equal camera distance, with the trainer standing between them, and the frame becomes usable.
- **`creature_bed_scale_check.png` — the bench's iron end-straps are enormous.** Each band is roughly 30cm wide on a ~1.6m bench, making them the second-largest shape on the object. In `palworld-05-base-building.jpg` the metal fittings on the built furniture are small punctuation. These read as structural banding on a shipping crate.
- **`build_pieces_corner.png` — the fence is wrong in section and in height.** Using the door as the only implicit human dimension (~2.0m), the fence's top rail sits at about door-knob height (~1.0m) while its posts are roughly 20cm square. That is a waist-high garden fence built out of structural piers.
- **`build_pieces_corner.png` — the wall/door ratio is fine.** Wall panel reads at ~1.25 door-heights, ~2.5m. That one checks out.

---

# Verdict

## The three biggest gaps vs. the references, ranked

**1. Nothing in the build kit has weight, because nothing has a dark.**
`palworld-05-base-building.jpg` gets its solidity almost entirely from value: dark under-eaves, dark shadow inside the thatch, dark metal, dark ground contact under every object. Every structure there is anchored. In `build_pieces_lineup.png`, 9.4% of pixels have a clipped channel, the plaster/fence/top-rail are all blown to 255, and there is no dark accent anywhere on any piece. In `creature_bed_alone.png` the rail undersides and skirt interior are the same brightness as the lit top faces. The result is that these props look like flat cutouts and the reference's look like objects. This is the single largest separator and it is not a modelling problem.

**2. These are three kits pretending to be one, and the structural kit is the weak one.**
`palworld-05-base-building.jpg` shows a camp where the palisade, the platform, the workstation and the storage all share one wood, one grain treatment and one joinery language. Here `creature_bed_scale_check.png` shows a cohesive furniture pair, `build_pieces_lineup.png` shows five pieces in five different wood hues with a different grain treatment and no joint language at all, and `06-creature-resting.png` adds a rope-and-wicker family that matches neither. A player who builds a camp out of these will see the seams immediately.

**3. The set contains no human, so its central claim — that these are camp objects at a shared scale — is untested.**
Every Palworld reference has the player character in frame as a ruler; `palworld-05-base-building.jpg` in particular lets you read the fence height, the workstation height and the barrel size against a person in one glance. Not one of these six frames does that, and `creature_bed_scale_check.png` is named for the job it does not do. The one relative-scale relationship that *is* visible — badger vs. rope mat in `06-creature-resting.png` — is wrong: the creature overflows its bed.

## Bar question A — Do these read as belonging to the world of `tetherbound-meadows-keyart.png`?

**No.**

What carried: the bed and workbench in `creature_bed_scale_check.png` are close. Warm honey wood, carved chunky stock, grey iron — that is the right register for the STARTING SETTLEMENT panel. The badger in `06-creature-resting.png` is in the right register for the board's creature silhouette row and its wildlife panels.

What sank it:
- The roof tile in `build_pieces_lineup.png` is a hot saturated orange that appears nowhere on the board's palette strip and is far brighter than the muted terracotta roofs in the board's own STARTING SETTLEMENT and village panels. It is the loudest thing in the set.
- The duvet cyan `(133,213,216)` in `creature_bed_alone.png` is likewise off the strip entirely.
- The board's note is "vibrant, readable colours" — readable means value structure. `build_pieces_lineup.png` is one blown-out high band with no darks. The board's own panels have deep tree shadow, dark building interiors and dark stone under every structure.
- The board's buildings are timbered with visible joinery and dark recesses; the kit in `build_pieces_lineup.png` has neither.

## Bar question B — Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game?

**Yes, but only on the strength of `06-creature-resting.png`.**

The badger is a genuinely bespoke, appealing, stylised creature with a design hook, and set beside `palworld-01-boss-fight-forest.jpg` it reads as an attempt at the same category. That alone carries the answer.

Nothing else does. Set `build_pieces_lineup.png` beside `palworld-05-base-building.jpg` and the honest read is "asset-store prop dump" versus "shipped stylised base-building game" — because of the blown values, the moiré, the five wood tints, the single-sided roof, and the total absence of joinery. And `07-creature-resting-far-side.png` would actively hurt the comparison: it is the same creature rendered as an unreadable black lump.

## What is fixable by changing the scene, and what needs art not in the build

**Fixable by changing the scene / lighting / rig — do these first:**
- Fix the exposure. `build_pieces_lineup.png` clipping 9.4% and `07-creature-resting-far-side.png` crushing to `(0,0,0)` are both exposure, not asset quality. Bring the key down and add fill.
- Add ambient occlusion or a bounce/fill light. Every "no weight" complaint in §4 is this one change.
- Make `06-creature-resting.png` and `07-creature-resting-far-side.png` use the *same* light rig. Right now they disagree, which makes both frames untrustworthy.
- Turn on mipmaps / lower the grain frequency. The moiré on the floor slab and wall braces in `build_pieces_lineup.png` and `build_pieces_corner.png` is a sampling setting, not a texture rebuild.
- Reshoot `creature_bed_scale_check.png` properly: both objects on one baseline at equal camera distance, **with the trainer in frame**, and add the badger. That is a rig change and it converts a useless frame into the most valuable one in the set.
- Fix the assembly in `build_pieces_corner.png`: close the roof-to-plate gap, lift the floor slab out of the door and the wall, move the fence off the slab. These are transform errors in the shot, not modelling errors.
- Recolour the roof tile toward the board's terracotta and the duvet toward the board's steel-blue or sand. Both are material-tint edits.
- Add a ground plane and contact shadows to the four void-stage frames so depth and scale can be read at all.

**Needs art that is not in the build:**
- **Value in the structural kit.** Dark under-eaves, dark beams, iron strapping, shadowed recesses — these have to be authored into the textures and geometry. Lighting alone will not rescue a kit whose albedo is uniformly pale.
- **One wood family.** Retexturing wall / door / floor / fence / rafters onto the bed-and-bench wood is texture work, not a lighting pass.
- **Joinery language.** Pegs, notches, brackets, sockets — the pieces need geometry that says how they connect. This is modelling.
- **The roof's second slope and its interior soffit.** Currently there is no art on that face at all.
- **Cloth.** The duvet, sheet and pillow in `creature_bed_alone.png` need fold geometry and a painted texture in the same language as the wood. This is a remodel of the bedding, not a shader tweak.
- **The badger's rear silhouette.** `07-creature-resting-far-side.png` shows there is nothing back there. A tail, a plate ridge running down the spine, or a rear pattern break — something the rear read can hang on. This is creature art.
- **A decision on the two beds.** The human plank bed and the rope pet basket cannot both be "the creature bed." One of them needs to be replaced or redesigned so the camp has one bedding language.
- **A creature bed sized for the creature.** Or the reverse. Currently they do not fit each other and no amount of relighting changes that.
