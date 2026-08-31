# Area 3 — creature roster — blind critique, round 1 (presentation rig)

Frames: `shots/census/03-creatures-presentation/` — 50 PNGs from
`tools/capture_creature_presentation.gd` (25 species × portrait + field). The
field frames are shot at gameplay distance with a fixed-height reference bar
beside each subject, on a flat ground plane keyed to the meadow grass value.
Critic given only the sheet, the frames, `docs/reference/` and the rubric, plus
factual rig context (isolated presentation stage, so "the world is empty" is
not a defect). Verbatim below.

---

I read the rubric, the key art, all five Palworld shots, the contact sheet, and 30 individual frames (16 portraits, 14 field). Measurements below come from the frames themselves, using the fixed-height bar as the ruler (bar = 108 px in every field frame; all field frames share one camera).

---

# Visual critique — creature presentation set

## 1. Silhouette and readability at small size

Viewed as the contact sheet (i.e. small), the field frames split into three legibility tiers, and the bottom tier is a real problem.

**Reads clearly small:** `meadowhart_field.png` (antler + slim leg silhouette, warm tan against green — instantly a deer), `mosshell_field.png` (dome-over-low-body is unmistakable), `galecrest_field.png` (spread wing shape), `veridian_field.png` (antler rack is the strongest silhouette in the set), `ashtusk_field.png` and `tuskroot_field.png` (tusk + hunched mass).

**Reads as a coloured smudge:** `bramblebun_field.png` is a 54 px brown lump with hair-thin twigs coming off it — the twigs are sub-pixel and vanish, and what is left is a shapeless blob you cannot identify as a rabbit or anything else. `sparkit_field.png` (50 px) loses everything except two ear triangles. `mudsnout_field.png` (56 px) and `brooktail_field.png` (62 px) are both undifferentiated brown ovals. `pipwing_field.png` at 43 px is a pale fleck.

**Reads as the wrong creature:** `nightburrow_field.png` and `burrowback_field.png` are, at this size, the same animal. Same mesh, same pose, same black-body/white-striped-face value pattern; the only difference visible small is that nightburrow has three purple dots floating above it. If a player has to read "which badger is this" off a particle colour, the silhouette work has not been done. `terrapup_field.png` is a third instance of that same badger, brown. Likewise `trailpup_field.png` and `stormtrail_field.png` are one canine mesh in two colours, and `paddlenewt_field.png` / `riftfrill_field.png` are one newt mesh in cyan and violet — at field size they are the same shape with a hue swap.

Compare the reference: in `palworld-02-open-field-path.jpg` there are four pals at genuinely small screen size and each one is a distinct blob shape — a striped quadruped, a spiky biped, a round one. In `palworld-04-plateau-landmark.jpg` the three flanking pals differ in silhouette before you can see a single texture detail. This set does not have that discipline; the roster relies on colour to do the work silhouette should be doing.

**The single worst readability failure is at full size, not small.** In `bramblebun_portrait.png` the creature has no findable face. The head is a beige lump at frame centre with a brown smear on it; there are no eyes, no nose, no mouth I can locate. I zoomed 3× and still cannot. Every other subject in the set has a face. Whatever else is true of this asset, a creature you cannot make eye contact with at 2 m is not shippable.

## 2. Colour and value structure

There is no palette discipline across the roster — measured, not impression. Mean per-pixel saturation of the subject runs from 0.14 (`nightburrow_portrait.png`) to 0.61 (`riftfrill_portrait.png`, `mudsnout_portrait.png`), i.e. more than 4×. Median subject luminance runs from 34 (`stormtrail_portrait.png`) to 167 (`galewisp_portrait.png`). Those are two different games' colour scripts sitting side by side.

Specific off-board colours, against the swatch strip at the bottom of `tetherbound-meadows-keyart.png` (olive/moss greens, wheat, cream, slate, a muted steel blue, dusty violet, oxblood):

- `reedwing_portrait.png` — cobalt blue body with chrome-yellow beak and feet. Neither hue exists on the board strip. It reads as a rubber bath toy, and its yellow is the most aggressive colour anywhere in the set.
- `ripplet_portrait.png` — the same cobalt, in hard-edged blotches that ignore the anatomy: the blue crosses the ear, the muzzle bridge and the chest as if paint were spilled on it. There is no relationship between marking and form.
- `galecrest_portrait.png` — highlighter green around the eyes and electric cyan patches on the breast and legs. The cyan is the single most saturated pixel region in the whole set and it sits on the creature that most needs to read as a natural raptor.
- `paddlenewt_portrait.png` / `riftfrill_portrait.png` — pool-toy cyan and violet, both above 0.60 saturation.

Value structure: six subjects have p05 luminance of exactly 0 — `ashtusk`, `burrowback`, `nightburrow`, `stormtrail`, `terrapup`, `veridian`. Their shadow sides are clipped to pure black with no ambient fill, so all form information in the shaded half is gone. `stormtrail_portrait.png` is the clearest case: the dog's entire body is a flat black shape and the only thing breaking it up is the yellow markings. `nightburrow_portrait.png` loses its whole left flank the same way. The references never do this — even the very dark pal in `palworld-04-plateau-landmark.jpg` holds a readable blue bounce on its shadow side.

**Reserved danger colour:** the hottest reds in the set are on `ashtusk_portrait.png` (glowing orange-red fissures across the snout and brow) and `cindercub_portrait.png` (orange ember markings). They are orange rather than the board's oxblood, so I would not call it a leak — but they are the two most alarm-coloured subjects in a roster where the villain colour is supposed to be the alarm, and they are wild fauna. Worth a deliberate decision rather than an accident.

## 3. Intentionality

This is where the set fails hardest, and it is a roster-authorship problem, not a scene problem. **These twenty-five subjects were not made by one hand, and it is obvious in one glance at the sheet.** I can sort them into four rendering languages:

- **Hand-painted matte, dark ink-like line work in the texture:** `meadowhart_portrait.png`, `burrowback_portrait.png`, `terrapup_portrait.png`, `mudsnout_portrait.png`, `brooktail_portrait.png`, `mosshell_portrait.png`, `tuskroot_portrait.png`, `galewisp_portrait.png`, `pipwing_portrait.png`, `duskhush_portrait.png`. This group is the good one and it is genuinely close to the board's stylisation.
- **Semi-photoreal animal, realistic proportion, photographic fur:** `frostclaw_portrait.png` is a snow leopard with scanned-looking spot fur and no stylisation whatsoever; `trailpup_portrait.png` is a coyote; `stormtrail_portrait.png` is the same coyote in black; `ashtusk_portrait.png` is a naturalistic warthog. Beside `meadowhart_portrait.png` these look like they came out of a different store.
- **Glossy plastic with a hard specular hit:** `paddlenewt_portrait.png` and `riftfrill_portrait.png` have wet-looking speculars on the skull; `reedwing_portrait.png` and `ripplet_portrait.png` are flat vinyl with no surface detail at all. `ripplet` in particular has zero fur texture — it is an untextured matte solid with decals.
- **Muddy generated mass:** `bramblebun_portrait.png` (a melted composite of fur, leaf, twig and flower with no clean separation between any of them, plus random magenta and violet flecks that read as noise) and `shadelet_portrait.png`.

In `palworld-01-boss-fight-forest.jpg` and `palworld-04-plateau-landmark.jpg` you can put a hulking boss and a small mount in the same frame and they obviously come from the same studio: same shading response, same edge-light treatment, same eye construction, same level of surface abstraction. Nothing in this set has that unity.

The recolour pairs compound it. Same mesh, two entries: `ashtusk` / `tuskroot` (identical boar — same tusk curve, same brow ridge, same dorsal lumps, same stance); `paddlenewt` / `riftfrill`; `trailpup` / `stormtrail`; `burrowback` / `nightburrow` / `terrapup` (three). That is nine of twenty-five entries built from four base meshes, and the variation applied is material only — no proportion change, no silhouette change, no pose change.

## 4. Lighting

**No shadows at all.** Not a soft one, not a contact darkening, nothing — in any of the thirty frames. `mudsnout_portrait.png`, `meadowhart_portrait.png`, `terrapup_portrait.png` and `mosshell_portrait.png` all have feet planted on flat green with the ground under the paw exactly as bright as the ground a metre away. The reference bar casts none either, so this is the lighting setup, not one bad asset. Consequence: nothing is attached to the ground. `galewisp_field.png` and `pipwing_field.png` in particular look pasted onto the frame rather than standing on it. Both `palworld-03-field-boss-meadow.jpg` and `palworld-04-plateau-landmark.jpg` have clear contact shadows under every pal, and that is most of why their creatures sit in the world.

Form: with no shadow, no visible AO and heavy uniform ambient, the shading is doing almost nothing. `tuskroot_portrait.png` has a large barrel body rendered with essentially no top-to-bottom falloff — the belly is as bright as the spine. `mosshell_portrait.png`'s shell dome has no occlusion where it overhangs the neck. What form-reading remains comes from the diffuse texture, which is why the hand-painted group (`meadowhart`, `burrowback`) survives and the untextured group (`ripplet`, `reedwing`) reads as flat vinyl.

Time of day does not read as anything in particular — direction is roughly frontal-above, colour is neutral. The board asks for day and night to create different moods; this is a null lighting state.

The one sky element, the sun in `ashtusk_portrait.png` (top centre), is a soft blurry yellow blob with no core, reading as a lens smudge rather than a sun.

## 5. Horizon and depth *(fog/horizon question skipped per instruction)*

Nothing to report beyond one artefact noted below.

## 6. Interface — *skipped, not shown.*

## 7. Artefacts

- `cindercub_portrait.png` — the fur is a tiled, blurred dot pattern repeating on a visibly uniform grid across the whole body (I upsampled the left forelimb region; it is a regular lattice). It reads as reptile scale, not canine fur, and it is the same repeat on the legs, chest and face.
- `shadelet_portrait.png` — the entire body texture is out-of-focus. The scale mottling has no crisp edge anywhere, and the crest spines smear into the head. This looks like a texture that is far below the resolution its screen size needs, or a mip being forced. The eyes are flat yellow lozenges with no pupil or highlight, so the face has no focal point.
- `bramblebun_portrait.png` — beyond the missing face: stray hot-pink and magenta flecks scattered over the flank and rear foot that correspond to no feature, and twig geometry that intersects the body with no clean junction.
- `veridian_portrait.png` — acid-green markings that sit on the surface like unblended vertex paint, most obviously the green blob on the throat and the green speckles on the antler tips, which follow neither the antler form nor any pattern logic. There is also a cream-coloured tuft at roughly (620, 400) on the left of the neck that reads as a detached piece of geometry poking out rather than fur.
- `galecrest_portrait.png` — the cyan breast patches have hard stencil edges that cut across feather groups, and the wing-tip feathers are smeared where the texture runs out.
- `burrowback_portrait.png` / `nightburrow_portrait.png` — the white facial stripe has stair-stepped, jagged edges clearly visible at portrait range; the texture is under-resolved for the mesh.
- `trailpup_portrait.png` — a green stain smeared across the chest and throat that has no design read; it looks like a texture-bleed or a wrongly-tinted mask, not markings.
- **Shared particle sprite.** The same soft white circular blob is used, recoloured, on at least four creatures: purple in `nightburrow_portrait.png` and `nightburrow_field.png`, white-yellow in `stormtrail_portrait.png`, white in `riftfrill_portrait.png`, pale grey in `ashtusk_field.png`. It is a plain out-of-focus dot with no motion shape, no core, no directionality. In `stormtrail_portrait.png` it is supposed to be doing electrical work and reads as dust on the lens. In `ashtusk_field.png` the two specks above the boar read as dirt on the monitor rather than embers.
- `stormtrail_portrait.png` — the yellow markings are amorphous smears with no bolt, fork or crackle language, and they stop dead at the neck, so the face is unmarked black. The creature's identity is carried entirely by a shape that looks like a texture accident.

## 8. Scale agreement

All field frames share one camera and one 108 px reference bar, so these are directly comparable. Subject height as a multiple of the bar:

| ×bar | subject |
|---|---|
| 0.40 | pipwing |
| 0.46 | sparkit |
| 0.50 | bramblebun |
| 0.52 | mudsnout |
| 0.57 | brooktail |
| 0.64 | paddlenewt |
| 0.65 | riftfrill |
| 0.68 | trailpup |
| 0.69 | duskhush |
| 0.76 | cindercub |
| 0.79 | stormtrail |
| 0.80 | mosshell |
| 0.81 | reedwing |
| 0.93 | shadelet |
| 0.95 | burrowback |
| 1.00 | galewisp |
| 1.07 | ripplet |
| 1.10 | meadowhart |
| 1.13 | terrapup |
| 1.15 | frostclaw |
| 1.15 | galecrest |
| 1.19 | tuskroot |
| 1.39 | nightburrow |
| 1.40 | ashtusk |
| 1.41 | veridian |

Three findings:

**(a) The whole roster spans only 3.5×, and twenty of twenty-five sit inside a single 2× band (0.5–1.2).** That is a flat roster. In `palworld-01-boss-fight-forest.jpg` the Mammorest towers over the player and the small pal beside it by roughly 5–8×, and *that size difference is the entire reason the frame reads as a boss fight*. Nothing in this set could produce that frame. There is no event-scale creature here at all — the largest thing (`ashtusk_field.png` at 1.40) is only 1.2× the deer you would meet in the first ten minutes.

**(b) Same mesh, two sizes, no design read.** `nightburrow_field.png` is 1.39 bar and `burrowback_field.png` is 0.95 bar — the identical badger at a 1.46× difference. Nothing in either presentation explains why one badger is half again as tall as the other, and since they are visually the same animal, a player will read it as an inconsistency rather than as two species.

**(c) Species scale relative to each other is not credible.** `nightburrow_field.png` (badger) is the joint-largest thing in the game, tied with `ashtusk_field.png` (boar) and `veridian_field.png` (legendary stag). `frostclaw_field.png` (big cat) at 1.15 is the same size as `meadowhart_field.png` (deer) at 1.10 and `galecrest_field.png` (raptor bird) at 1.15. `mosshell_field.png` (turtle) at 0.80 is the same size as `reedwing_field.png` (duck) at 0.81. If the bar is a person-height reference, then the deer's head is above a person's, the badger is roughly two and a half metres tall, and the raptor standing on the ground is eye-to-eye with you. These are the kind of relative-size errors a still frame shows perfectly, and this frame set shows them.

Also worth checking on the veridian: its **shoulder height** (about 0.72 bar, measured from feet to the top of the back in `veridian_field.png`) is *lower* than `meadowhart_field.png`'s (about 0.85 bar). The legendary stag has a smaller body than the starter deer and gets all its apparent size from the antlers. That may be intended; it does not read as intended.

---

# Verdict

## The three things that most separate these frames from the references, ranked

**1. There is no single hand behind this cast — four incompatible material languages sit in one roster.** `meadowhart_portrait.png` is a hand-painted stylised deer with ink-dark texture line work. `frostclaw_portrait.png` is a semi-photoreal snow leopard with scanned spot fur and naturalistic proportions. `reedwing_portrait.png` is flat cobalt-and-yellow vinyl with no surface detail. `bramblebun_portrait.png` is a blurred generated mass with no findable face. Put those four side by side and no one would say they belong to the same product. The references do the opposite: `palworld-01`, `-03` and `-04` show six different creatures across three shots and every one shares the same shading response, the same eye construction, the same degree of surface abstraction. This is the gap that matters most, because it is the one a player notices in the first minute and cannot un-notice.

**2. No creature in the set is big enough or authored enough to make a fight an event, and nine of twenty-five are recolours.** `palworld-01-boss-fight-forest.jpg` is a boss fight because the boss is 5–8× the things around it and is built as a landmark. The largest subject here, `ashtusk_field.png` at 1.40 bar, is 1.2× a common deer, and the legendary `veridian_field.png` has a smaller body than that deer. Meanwhile `nightburrow`/`burrowback`/`terrapup` are one badger three times, `ashtusk`/`tuskroot` one boar twice, `trailpup`/`stormtrail` one canine twice, `paddlenewt`/`riftfrill` one newt twice — and the variation is material-only, so at the gameplay distance of the `_field` frames they read as duplicates.

**3. Markings and textures are applied to the surface rather than derived from the form, and several are below usable resolution.** `ripplet_portrait.png`'s cobalt patches cross the ear, muzzle and chest with no anatomical logic. `galecrest_portrait.png`'s cyan blotches cut across feather groups with stencil edges. `stormtrail_portrait.png`'s yellow "lightning" is amorphous smear that stops at the neck. `veridian_portrait.png`'s acid green sits on top of the model like unblended paint. `cindercub_portrait.png` is a visibly tiled dot lattice; `shadelet_portrait.png` is uniformly out of focus. In `palworld-03-field-boss-meadow.jpg` the Grintale's pink-to-cream transition follows the muscle and the dark dorsal band follows the spine — every marking is a form statement. None of these are.

*(Close fourth, and cheap to fix, so I am naming it: there is not one shadow in thirty frames. Every creature floats.)*

## The two bar questions

### A. Do these read as belonging to the world in `tetherbound-meadows-keyart.png`? — **No.**

About ten of them do, and they are good. `meadowhart_portrait.png`, `mosshell_portrait.png`, `galewisp_portrait.png`, `mudsnout_portrait.png`, `brooktail_portrait.png`, `pipwing_portrait.png`, `duskhush_portrait.png`, `burrowback_portrait.png`, `terrapup_portrait.png` and `tuskroot_portrait.png` all sit inside the board's palette strip and share its warm, slightly-painted stylisation. `galewisp_portrait.png` and `meadowhart_portrait.png` would not look out of place next to the yellow companion in the board's DAY panel. The board's own silhouette row — rabbit, boar, deer, raptor, turtle, canine — is covered on paper.

It fails on the other half. `reedwing_portrait.png`'s cobalt and chrome yellow, `ripplet_portrait.png`'s cobalt, `paddlenewt_portrait.png`'s pool cyan, `riftfrill_portrait.png`'s violet and `galecrest_portrait.png`'s highlighter green are outside the board's swatch strip entirely — they are toy-aisle colours dropped into a natural palette. And `frostclaw_portrait.png`, `trailpup_portrait.png`, `stormtrail_portrait.png` and `ashtusk_portrait.png` are a *different rendering philosophy* from the board, which is painted stylisation, not naturalistic animal. A world can absorb one outlier. It cannot absorb nine.

### B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of game? — **No.**

The genre reads. The subjects — a cute newt, a chunky turtle, a winged fox, a badger — are recognisably the same category of thing, and `galewisp_portrait.png`, `mosshell_portrait.png` and `meadowhart_portrait.png` individually would not embarrass themselves in a Palworld frame.

But shown the *set*, the honest read is "a folder of purchased assets", not "a designed cast". Three things sink it. The four incompatible material languages (criterion 3). The 3.5× total scale range with no boss-scale creature, when the reference's whole visual identity is built on scale contrast (`palworld-01`). And the total absence of contact shadow, which is the single cheapest thing separating "creature standing in a world" from "creature pasted over a background" — `palworld-03` and `palworld-04` both have it under every pal.

## What is fixable by changing the scene, and what needs art that is not in the build

**Fixable in the build — scene, lighting, materials, data:**

- Turn shadows on. Directional shadow plus a contact/AO term. Currently zero shadows in thirty frames, and it is the largest single-line improvement available.
- Add ambient fill so shadow sides stop clipping to RGB 0 — `stormtrail_portrait.png`, `nightburrow_portrait.png`, `veridian_portrait.png`, `ashtusk_portrait.png`, `burrowback_portrait.png`, `terrapup_portrait.png` all lose their whole shaded half.
- Retune the off-board material colours toward the key art strip: `reedwing`, `ripplet`, `paddlenewt`, `riftfrill`, `galecrest`. These are hue/saturation values, not new art.
- Normalise surface response. Kill the plastic specular on the newt/otter/duck group and bring their roughness in line with the hand-painted group. This alone would close a good part of the "four art languages" gap without touching a mesh.
- Fix the scale table. Give `nightburrow` and `burrowback` a reason to differ or make them the same size; pull `frostclaw`, `galecrest` and `terrapup` off the deer's height; and decide deliberately what the biggest creature in the Meadows is, because right now nothing is more than 1.2× a common deer.
- Replace the shared soft-circle particle. One recoloured blob is doing ember duty, spark duty and shadow-magic duty across `ashtusk`, `stormtrail`, `nightburrow` and `riftfrill`, and it reads as lens dust in all four.
- The sun sprite in `ashtusk_portrait.png` needs a core.

**Needs art that is not in the build:**

- `bramblebun` — not salvageable by scene work. It has no face, its silhouette does not read as a rabbit at any distance, and its surface is a blur of unresolved material. This one needs remaking or replacing.
- `shadelet` — the texture is below usable resolution and the eyes have no pupils. Needs a repaint at proper texel density.
- `cindercub` — the tiled dot lattice is baked into the texture. Needs a retexture.
- `frostclaw`, `trailpup`, `stormtrail`, `ashtusk` — these are naturalistic animals in a painted-stylisation game. Restyling them to match the `meadowhart`/`burrowback` group is texture-and-proportion work, not a material tweak.
- Differentiating the three badgers, two boars, two newts and two canines. A hue swap on one mesh is not two creatures. This needs sculpt-level variation — different proportion, different head shape, different silhouette element — and there is no way to fake it from the scene.
- `veridian` as a legendary. Its body is smaller than the starter deer's and its markings look like paint spills. A roster-topping creature has to be built as one; nothing in the lighting or the scale table will make this frame feel like `palworld-01-boss-fight-forest.jpg`.
- A genuine event-scale creature, at three to four times the largest thing currently in the set. There isn't one, and the reference's most characteristic frame depends on having one.
