# Cloudreach Cliffs — blind visual judge, after the ground-truth + aviary pass (round 1 of 2)

Frames: `_sheet_after.png` (twelve production stands, `tools/capture_cloudreach_environment_correction.gd`, Compatibility renderer under software GL). Judge given the sheet, the frames and `docs/reference/` only.

Blind review against `docs/reference/tetherbound-meadows-keyart.png` (art direction) and
`docs/reference/palworld-01..05.jpg` (the owner's bar). Sheet viewed first, then each frame
at full size, then the sheet again at 30%. The 1.80 m trainer is the ruler throughout.
No HUD is present in any frame, so rubric item 6 (interface) is not judged here.

One thing first, because the rubric asks for it: **creatures and the trainer.** The trainer
is consistent across all twelve frames, reads cleanly against every ground, and his
chunky-cartoon proportions are a defensible style. Creatures appear in exactly one of twelve
frames (`11-aerie-ground-connection`). The two that appear are the strongest-looking things in
the survey, and they are also the least at home: the white owl-fox is soft and painterly, the
blue raptor is realistic-feathered, and neither shares the trainer's hard-edged cartoon
finish. The white one stands shorter than the trainer's shoulder. Details in defects 10 and
11 below. A creature-training game that shows creatures in one stand out of twelve is not
showing what it is named for.

---

## 1. Defects, ordered by how much they hurt "finished, lush, vertical cliff-and-sky"

1. **Nothing in any frame says altitude.** There is no drop-off, no look downward, no cloud
   sea, no haze layering, no distant land below. Where the ground ends, it ends at a hard,
   flat, pale grey-blue plane at roughly the same screen height in every frame
   (`02-broken-causeways` left third, `08-upper-cliffhold-east-arrival` behind the cottages,
   `09-final-arena-space` behind the walls, `12-cliffhold-ground-connection` far left,
   `04-high-roost-before-fly` both sides). It reads as the edge of a loaded chunk, not as a
   valley far below. The "cliffs" in `03-windscar-ravine` and `01-arrival-first-reveal` stand
   four to five trainers tall (about 8 m), which is a garden rockery, not a cliff. The
   region is named for clouds and reach, and the sky is a ground-level meadow sky in every
   frame.

2. **The rock language is wrong for the region and is inconsistent with itself.** Two
   families appear. (a) Tan/brown horizontally banded hoodoos with rounded caps, used in
   `01`, `02-broken-causeways`, `02-lower-cliffs-galefoot`, `03`, `08`, `12` — at 30% they
   read as stacked hay bales or pancakes, and their warm tan palette is nowhere on the key
   art's grey-green mossy granite. (b) A dark, angular, blocky mass in
   `05-upper-cloudreach-cliffhold` and the aerie column in `11`, with the strata texture
   visibly stretched vertically across large flat faces. The `05` mass is the worst single
   object in the survey: it reads as an untextured blockout with a bright green flat
   pyramid laid on top at an angle and a tiny stone hut on the summit. Neither family has a
   lit side and a shadow side; both cliffs in `03` are equally lit from the front.

3. **The summit hero (`06-summit-final-approach`) reads as an unfinished blockout, not a
   destination.** The large structure is an open iron-and-wood lattice dome — a birdcage or
   a greenhouse frame under construction — with a white trident ornament and a flat black
   oval at the apex. Beneath it, the gate pillars are two flat, untextured rust-red slabs,
   flanked by translucent cyan rectangles that look like placeholder glass. Behind, a grey
   crenellated wall. The ground in front is a patchwork of hard-edged dark-brown and green
   triangles — the terrain mesh faces are directly visible. This is the most important
   stand in the region and it looks like a level editor mid-session.

4. **Terrain surface artefacts everywhere the ground is bare.** A regular tile grid is
   visible in the grass texture (`02-lower-cliffs-galefoot` lower-left, `04` foreground,
   `12` foreground). Radial seam lines converge on the trainer's feet in `05` (a fan of
   straight lines across the grass). Terrain patches with dead-straight edges in olive and
   dark green sit at the left of `03` and across the whole lower half of `06`. Paths in
   `02-lower-cliffs-galefoot` and `12` have a dashed grey outline drawn along their edge
   like a nav-mesh debug line.

5. **A floating, upside-down chunk of striped rock with debris crumbling from it hangs in
   the sky** at upper-left in `04-high-roost-before-fly` and again above the trees in
   `11-aerie-ground-connection`. It reads as an object that spawned in the wrong place and
   is breaking, not as a floating island. If it is intended, nothing about it (no
   underside, no scale, no vegetation, no shadow) sells it.

6. **The world is empty beyond the foreground.** Grass exists as a ring around the camera
   and stops on a visible line: `01` right side, `02-broken-causeways` whole midground,
   `04` everything past the trainer. `02-lower-cliffs-galefoot` is a flat green carpet with
   five bushes and four boulders. `09-final-arena-space` is 60% flat cobble with nothing
   on it. `08` is a lawn with a row of cottages. Palworld's ground cover runs continuous
   and varied to the horizon; here it is a foreground effect.

7. **The boulders do not read as stone.** They are pale blue-white, faceted, and their
   edges pick up a green glow that makes them look translucent — wax, ice, or marshmallow.
   In `03-windscar-ravine` one such block at the right edge is taller than the trainer.
   Same material in `06` (foreground left), `11` (both sides), `12` (four small ones),
   `02-lower-cliffs-galefoot`. None has a contact shadow, so the ones in `02-lower` and
   `12` sit on the grass like dropped props.

8. **The aerie (`11-aerie-ground-connection`) reads as a striped rock chimney wrapped in
   cobwebs.** The tall banded cylinder is wrapped with thin white wispy lines that read as
   spider silk, not wind, and two bare wooden poles lean on it. A black diagonal spike
   pokes out from the left boulder behind the white creature — it reads as a blade stuck
   in the ground, not a shadow. Above, the floating fragment from defect 5.

9. **Village structures are not finished objects.** The stone towers in
   `02-lower-cliffs-galefoot` (right), `08` (left) and `12` (right edge) are square stone
   stacks with a flat wooden lid that overhangs the walls on all sides — they read as
   chimneys with a tabletop on them. Every cottage in `02-lower`, `08` and `12` has thin
   ropes running from the chimney or ridge down to pegs in the grass, which makes the
   houses read as tents. The foreground building in `12` has a lattice for a front wall
   and reads as a market stall with its walls missing. The cottage models themselves
   (half-timber, slate roof) are the best-finished assets in the survey and match the
   key art's settlement panel.

10. **Creature scale.** In `11`, the white owl-fox stands nearer the camera than the
    trainer and still tops out below his shoulder — roughly 1.2 m against 1.8 m. The blue
    raptor further back is roughly trainer height. Both are flat-lit with no shadow side;
    the white one is close to blown out on its chest.

11. **Creature and character style mismatch.** Trainer: hard-edged cartoon, chunky, flat
    colour. White creature: soft, painterly, fine feathering. Blue creature: realistic
    feather texture. Three finishes in one frame (`11`). Palworld's creatures and hero are
    one drawing hand; these are three.

12. **Lighting is flat and the time of day does not read.** Trees have no shadow side
    (`01`, `03`, `11`). Cliffs have no shadow side (`03`, `02-broken-causeways`). The
    trainer and trees cast decent ground shadows, which is the only cue that there is a
    sun at all. In `04` a white disc sits in a blue midday sky and reads as the moon. The
    trainer's shadow in `04` is long and to the right, while the sky disc is top-left and
    everything else reads as noon.

13. **The path texture is too orange and too busy.** The dirt path in `04`, `08`,
    `02-lower-cliffs-galefoot`, `12` is a high-frequency pebble noise in saturated
    pumpkin-orange; it reads as sand or carpet and fights the green rather than sitting in
    the key art's dusty tan.

14. **The "broken causeways" are not broken.** `02-broken-causeways` shows an intact,
    flat, orange-plank bridge laid on a solid grass slope with no gap, no drop, and no
    void beneath. The rope posts alternate brown and white bands like barber poles. The
    bell gate at the top is a nice silhouette and the one thing in the frame that reads
    as authored.

15. **Sky is the same thin white streaks in all twelve frames.** No cumulus, no cloud
    layer, no gradient toward the horizon. The key art's sky is built of big lit
    cumulus over a hazy horizon; the Palworld shots all have a bright haze band. Here the
    sky is a flat cyan-blue with combed wisps and a hard edge to the world.

16. **One tree model, one foliage tint.** `01`, `03` and `11` reuse the same twisted trunk
    with lime lollipop clumps at different scales. `11` varies it slightly (a darker
    canopy on the right). At 30% the trees are readable as trees, which is good, but
    they are all the same tree.

17. **Danger colour check.** Oxblood is correctly on Team Tether banners in `09` and
    nowhere in the villages. The rust-red gate slabs in `06` are close to that hue on
    what is presumably the summit gate; if the summit is not Team Tether's, that colour
    is leaking. Flagging, not asserting.

18. **The arena (`09-final-arena-space`) does not look like an event.** A vast flat cobble
    plaza (tile scale visibly repeating), a single tiny figure at centre, banners and
    apparatus pushed to the walls. Palworld's boss frames (`palworld-01`, `-03`) fill the
    frame with the creature and effects; this is a car park.

19. **Grass blades in `07-fly-only-destination` are dark wires** with no leaf width; they
    read as hairs or antennae rather than grass, against otherwise pale ground. The stone
    tiling on the arch and on the low retaining wall is the same texel scale, so the
    3 m arch and the 0.8 m wall read as made of the same size stones.

20. **Every hero object is composed behind the trainer's head.** `01` (gate), `04`
    (roost), `05` (cliff hut), `06` (dome gate), `07` (egg). Survey convention, but the
    landmark is the thing being judged and it is occluded in five of twelve frames.

---

## 2. What a player would notice first, by stand

- **01-arrival-first-reveal** — a toy castle gatehouse dropped on top of a striped boulder,
  with a bright green flat wedge clipping through the boulder's flank.
- **02-broken-causeways** — an intact orange-plank bridge on solid grass, and the world
  ending in a flat grey plane at the left.
- **02-lower-cliffs-galefoot** — nice cottages with tent ropes pegged into a flat green
  carpet; a tower with a tabletop lid at right.
- **03-windscar-ravine** — stacked-pancake cliffs and a giant white waxy block at the
  right edge, taller than the trainer.
- **04-high-roost-before-fly** — an upside-down chunk of rock floating in the sky with
  bits falling off it; then the moon at midday.
- **05-upper-cloudreach-cliffhold** — a dark untextured blocky mass with a green pyramid
  on top, and seam lines fanning out from the trainer's feet.
- **06-summit-final-approach** — a birdcage. Then the patchwork of dark triangles the
  trainer is standing on.
- **07-fly-only-destination** — the floating cyan egg in its rings (the one object that
  reads as magic), framed by wiry black grass.
- **08-upper-cliffhold-east-arrival** — the square stone tower with a wooden lid and a
  yellow flag, on a lawn beside a fog wall.
- **09-final-arena-space** — an empty cobble car park with bunting; a small figure very far
  away.
- **11-aerie-ground-connection** — two creatures at last, both good-looking, standing in
  front of a striped chimney wrapped in cobwebs, with a black spike behind the white one.
- **12-cliffhold-ground-connection** — a half-timbered house with no front wall, ropes to
  the grass, and a stone tower's tabletop lid at the frame edge.

---

## 3. Verdict

### The three things that most separate these frames from the references

1. **Depth and altitude.** The key art and `palworld-04-plateau-landmark` both build
   distance out of haze bands, a lit far landmark, and a horizon that recedes; every one
   of these frames stops at a hard fog plane about two hundred metres out with nothing
   below it. Named frames: `02-broken-causeways`, `08-upper-cliffhold-east-arrival`,
   `09-final-arena-space`, `04-high-roost-before-fly`. For a cliff-and-sky region this is
   the gap that matters most, and it is the one no amount of prop work fixes on its own.

2. **Finish of the landform and hero objects.** The key art's stronghold is solid
   weathered stone with wooden scaffold and integrated banners; its standing stone is a
   single confident silhouette. Here the summit dome (`06`) is scaffolding, the summit
   cliff (`05`) is a stretched-texture blockout with a green plane on top, and the aerie
   (`11`) is a chimney in cobwebs. These are the three stands the region is built
   toward, and they are the three least finished frames.

3. **Ground density and grounding.** `palworld-02`, `-03` and `-05` show continuous,
   varied cover — grass, clover, flowers, dirt scuffs — with every object casting a
   contact shadow. Here grass is a foreground ring that ends on a line (`01`,
   `02-broken-causeways`, `04`), the ground beyond is a tiled texture with a visible grid
   (`02-lower-cliffs-galefoot`, `12`), and boulders sit on it without contact shadows.
   The village stands (`02-lower`, `08`, `12`) are where this shows most because the
   cottages themselves are finished enough to make the lawn look unfinished by contrast.

### Bar question A — do these frames belong to the world in the key art?

**No.** What carried it: the cottage models and their slate-and-timber language match the
STARTING SETTLEMENT panel; the oxblood is kept on Team Tether banners in `09`; the trainer
reads like a member of the cast; the frames agree with each other about sky and light, so
they are one place. What sank it: the rock palette is tan-orange banding where the key art
is grey-green mossy granite, so the single largest surface in the region is off-board; the
value range is one bright noon mid-key with no shadow side on trees or cliffs and no haze,
where the board's mood — cozy, inviting, hint of mystery — is made of deep shade and lit
distance; and the landmarks (dome, aerie, summit hut) do not have the board's solid,
weathered, story-carrying language. The palette is in the right family; the world it is
painted onto is not.

### Bar question B — beside the Palworld shots, same kind of game?

**No, narrowly, on eleven of twelve frames.** `11-aerie-ground-connection` would pass: a
stylised trainer, two appealing creatures at combat distance, trees framing a landmark. Put
that one frame beside `palworld-03` and someone would say yes. The other eleven have no
creatures, no HUD, no event, and read as a walkthrough of a blockout. `09` is the frame that
should have answered this question and it is the emptiest one. What sank it is not style —
the stylisation is compatible — it is that the frames show an unpopulated set.

### What is fixable by scene work vs what needs art not in the build

**Scene work (density, palette, lighting, composition, scatter):**

- A horizon: distance fog gradient with a lit haze band, a cloud layer plane below the
  cliff edge, and a far landform silhouette, so the fog plane in `02-broken`, `08`, `09`,
  `12` becomes a valley (defects 1, 15).
- Sun angle lowered to give trees and cliffs a shadow side; remove or move the white disc
  in `04`; add contact shadows / darkened bases under boulders (12, 7).
- Remove the floating fragment in `04` / `11` or give it a real underside and shadow (5).
- Grass extent pushed out with clustering, and the sharp cutoff line broken; ground cover
  variety (flowers, clover, dirt scuffs) beyond the foreground (6).
- Grass tile grid, radial seams in `05`, hard-edged terrain patches in `03` / `06`, dashed
  path outlines in `02-lower` / `12` — all fixable in terrain material and mesh (4).
- Path albedo pulled from pumpkin-orange toward the board's dusty tan; texture frequency
  lowered (13).
- Boulder material: opaque, cooler grey with a rougher normal, no green rim (7).
- Tree canopy tint variation and scale variety; a second silhouette if one exists in the
  build (16).
- Remove the roof guy-ropes; fix or hide the tower lid overhangs; give the `12` stall a
  front wall or dress it as a stall on purpose (9).
- Dress `09`: props on the floor, creatures, banners nearer the centre, a raised platform
  — make the arena an event (18).
- Cut a gap in the `02-broken-causeways` bridge, or rename the stand (14).
- Check the `06` gate slab colour against the reserved oxblood (17).
- Recompose the survey cameras so landmarks are not behind the trainer's head (20).

**Needs art that is not in the build:**

- A cliff rock set with tall vertical faces, ledges and overhangs. The banded hoodoo kit
  is the wrong landform for sheer cliffs; retinting will not make an 8 m pancake stack
  read as a precipice (defect 2, all cliff frames).
- The summit hero object. The lattice dome in `06` is not a finished thing that can be
  dressed into one; it needs a designed structure (3).
- The aerie as a landmark: the striped column in `11` needs a real aerie mesh or a
  modelled nest / perch structure, not wisps wrapped on a cylinder (8).
- A single, shared creature finish: the two creatures and the trainer need one shading and
  texture treatment, and the white creature needs to be sized up past the trainer (10, 11).
- Grass blade cards with leaf width for the `07` variant (19) — small, but it is a new
  asset.
- Creature coverage across stands is a content gap, not a rendering one: one creature
  frame in twelve is the loudest absence in the survey.
