# Visual judgement — GATE2-EVIDENCE-0903 / G2C route

I was given one contact sheet (`_sheet_gate2_route.png`) and sixteen in-game frames from
`run/G2C/shots/` (`_preflight.png` ignored as an instrument self-test), the project's own art
direction board `docs/reference/tetherbound-meadows-keyart.png`, and the five
`docs/reference/palworld-0*.jpg` shipping screenshots that the owner set as the bar. I read the
sheet whole first, then each frame at full size. I have not read the code, the config, the
history, or any prior review. Limits that belong on the record: these are rendered with the
**Compatibility renderer under software rendering (llvmpipe)** — the same renderer the game ships,
but with no SSAO and no volumetric fog, so fine shadow-softness and ambient-occlusion judgements
are safer made on real hardware, and I have flagged where a call depends on that. Frame times are
meaningless here and are not quoted. These are **static frames**, so popping, aliasing in motion
and traversal feel are invisible to me. The camera positions are **recorded from a played session,
not posed**, so where a framing is an accident of where the player was standing I say so rather
than counting it as composition. All sixteen were rendered at roughly **08:30**, so this set says
nothing about time-of-day variation and I draw no conclusion from the uniform hour.

---

## 0. The thing to say first: the creatures

The game is named for a bond with creatures. **In sixteen frames, not one creature appears at a
size where you could describe it.**

- **The player's own creature is never on screen.** `G2-S04-0000-region-change` and
  `G2-S05-0000-region-change` show a HUD panel reading `TEAM 5/5` — Moss, three Bramble-somethings,
  Mudsnout, three of them KO'd. Nothing is out. Nothing follows the trainer across fourteen
  outdoor frames. The keyart board's own DAY and NIGHT panels both put a companion creature
  *shoulder to shoulder with the trainer* as the composition; `palworld-04-plateau-landmark.jpg`
  has three pals filling the lower third of frame and one being ridden. This build shows a lone
  human walking through empty grass.
- **Three of five team slots are the same species.** The roster panel in `G2-S04-0000` lists
  `Brambl…`, `Bramblebun`, `Brambl…` — in a five-creature-total game that reads as a placeholder
  roster, not a team you built.
- **The team portraits are illegible.** At ~16 px in `G2-S04-0000` the five icons are
  indistinguishable grey-green smudges. Palworld's party icons are readable species at the same
  size because each pal has a distinct head shape and a saturated key colour.
- **Wild creatures read as scenery, not as creatures.** Pale pink rabbit forms appear only in the
  far mid-ground of `G2-S04-0206`, `G2-S04-0249`, `G2-S04-0361` and `G2-S04-0400` — at that size
  they are pink dots that a player will read as flowers. Brown quadrupeds appear on the ridge in
  `G2-S05-0670` and `G2-S05-0722`; they are the same salmon-brown as the tree trunks and the same
  value as the sunlit grass behind them, have no visible face, limb separation or feature, and
  read as rocks or stumps. Four of them stand in a row at identical scale along the tree line in
  `G2-S05-0722` — one mesh, one size, one rotation.
- **Nothing marks a creature as a creature.** No nameplate, no level tag, no health bar, no rim
  light, no outline. Every Palworld reference tags encounterable pals
  (`palworld-02`, `palworld-03`, `palworld-04`), which is what makes a distant blob legible as a
  thing you can fight or catch.
- **The two frames labelled `fight-starts` contain no fight.** `G2-S04-0249-fight-starts` is the
  trainer standing beside a berry bush with a `Pick berries` prompt up. `G2-S05-0502-fight-starts`
  is the trainer standing alone in grass. No combatant, no VFX, no enemy plate, no camera framing
  change. `palworld-01-boss-fight-forest.jpg` reads as an event from a thumbnail: a creature
  filling half the frame, a named health bar across the top, muzzle flash, impact sparks, a second
  pal mid-attack. `palworld-03-field-boss-meadow.jpg` does the same with a magenta boss, a `Lv 17
  Grintale` banner, and beam trails. Whatever the combat system does, **it currently produces no
  picture**.
- **`G2-S05-0522-level-up` is visually identical to `G2-S05-0502-fight-starts` three minutes
  earlier** — same camera, same pose, same grass. A level-up is a reward beat and there is no
  banner, no burst, no XP bar, no stat callout. `palworld-05-base-building.jpg` puts a persistent
  `You have unused Stat Points` bar on screen for exactly this.

The trainer is the one character asset that holds up, and only partly. In the close-up
`G2-S04-0000-region-change` the model is competently stylised — spiky brown hair, fur-collared
blue jacket, satchel, gloves — and sits in roughly the right family as Palworld's human. But the
face is a flat mask: two dark eye decals, no nose, no mouth, no brow. The hair is a low-poly
clump with visible facets. And **the NPC is the same body**: Halda in `G2-S04-0400-dialogue` and
`G2-S05-0180-route` is the player's silhouette with a beige tunic swapped in — same height, same
build, same ponytail, same boots. The cast does not read as different people.

None of the above is excused by an asset being a stand-in. It is being shown as the game's look.

---

## 1. Silhouette and readability at small size

Read the sheet as if at 30%.

- **What survives:** the terracotta roof of the village house (rows 2–3), the orange dirt path,
  the dark tree masses, the HUD panels. That is four things.
- **What does not:** every creature; the Team Tether grunt; the bridge; the objective landmark;
  the difference between a tree, a bush and a rock.
- **`G2-S05-0335-region-change` is a solid green rectangle at thumbnail size.** The camera has
  clipped inside a shrub and flat leaf cards fill the left 60% of frame. The player is entirely
  occluded. See §7 — this is a camera/foliage fade defect, not a framing accident, because the
  camera is behind the player and should have pushed out or faded the near foliage.
- **The player is hard to find in the woodland frames.** In `G2-S05-0502`, `G2-S05-0522` and
  `G2-S05-0451` the trainer is a small dark-navy-and-brown figure standing in dappled shadow on
  mid-green grass. His two brightest features — the cream jacket panels — are ~10 px wide. There
  is no rim light, no ground-contact ring, no silhouette-preserving value break. Palworld's
  characters carry a strong saturated accent (orange hair, blue sash, white gi) that survives
  thumbnailing; this trainer does not.
- **Trees have no silhouette language.** Across `G2-S05-0451`, `G2-S05-0502`, `G2-S05-0522` and
  `G2-S05-0722` the trees are a plain tapered salmon cylinder joined directly to a green blob,
  with **no visible branch structure below the canopy**. The keyart's whole identity for this
  biome is "oak groves" — panels 3 and 5 of the board are built on gnarled spreading oak
  branching that is legible as a shape. Only `G2-S05-0271-route` has a tree with real branch
  structure, and it is the best silhouette in the set.
- **Rock vs bush vs prop is undecidable at small size.** In `G2-S05-0578-landmark` and
  `G2-S05-0722-route` the white flower props, the small grey stones and the distant creatures all
  resolve to the same ~6 px light speck.

---

## 2. Colour and value structure

- **The sheet splits into two palettes that do not read as the same morning.** Rows 1–3
  (`G2-S04-0206`, `G2-S04-0249`, `G2-S04-0361`, `G2-S04-0400`, `G2-S05-0180`) are high-key: acid
  yellow-green grass, saturated orange dirt, vermilion roof, pale blue sky. Rows 4–6
  (`G2-S05-0271`, `G2-S05-0451`, `G2-S05-0502`, `G2-S05-0522`, `G2-S05-0670`) are dark and cool:
  olive-green, near-black tree masses, a duller sky. Side by side on the sheet they look like
  different hours, though both are 08:30 and neither is far from the other in the world. This is a
  sheet-level finding no single frame shows.
- **The grass highlight is acidic.** The lit grass in `G2-S05-0522` and `G2-S04-0361` goes to a
  lime/mustard yellow-green. The keyart board's palette strip runs olive → sage → warm gold →
  cream; there is no lime in it. Palworld's meadow in `palworld-03` is a warm mid-green with a
  desaturated tan; nothing in it is this chromatic.
- **Value range exists but is bimodal, not graded.** `G2-S05-0451` and `G2-S05-0271` have a deep
  black-maroon tree mass and a bright yellow-green ground and very little in between; the mid-tones
  that would give the terrain form are missing. The interiors (`G2-S04-0000`, `G2-S05-0000`) are
  the opposite — everything sits in one flat cream-to-grey mid-band with no darks at all.
- **The reserved danger colour has inverted.** The reddest objects in this world are the
  **village roofs** (`G2-S04-0400`, `G2-S05-0180`, `G2-S04-0361`) and the **tree trunks**, which
  across every woodland frame are a salmon/terracotta with no bark texture. Red also appears on the
  friendly HUD: the KO badges in `G2-S04-0000`, the berry icon, the health-potion icon and the tool
  durability ticks. Meanwhile the **Team Tether grunt in `G2-S05-0755-objective` wears near-black
  with no red at all** — the one hostile element in sixteen frames carries none of the faction's
  oxblood, while forests and friendly houses carry it everywhere. The keyart's Team Tether
  stronghold panel is defined by two oxblood banners against grey stone; that reading is currently
  unavailable in-game because the colour is not reserved.
- **Pastel pink is off-palette.** The rabbit creatures in `G2-S04-0361` and `G2-S04-0249` are a
  candy pink that appears nowhere in the board's palette strip and does not sit inside "natural
  palette".

---

## 3. Intentionality — authored or generated?

This reads as generator output almost everywhere.

- **`G2-S04-0206-dialogue`, top-left:** roughly twelve trees stand in a near-straight line along
  the ridge at even intervals, all the same height, same trunk width, same canopy tint. The same
  row appears in `G2-S04-0249` and `G2-S04-0361`. Nothing in a real grove is spaced like that.
- **`G2-S05-0502` / `G2-S05-0522`:** the tree line across the top of frame is one mesh repeated
  along a contour with near-zero scale variance, forming a wall rather than a wood with a mouth.
- **`G2-S05-0722-route`:** four identical creatures at identical scale in a row; two identical
  fern props at (620,370) and (785,270); three identical purple flower clumps stepping down the
  right side. No clustering, no clearing, no anchor.
- **Flower scatter is uniform-random, not clustered.** In `G2-S05-0522` the white flower props are
  spread at roughly constant density across the entire visible meadow with no bare patches and no
  dense drifts. `palworld-01` and `palworld-03` both use dense drifts of one flower species with
  real bare ground between — that reads as a place someone laid out.
- **The one authored-looking frame is `G2-S05-0271-route`:** a big branching tree framing the left,
  a shaft of light down the middle, a receding meadow. That is what the rest of the set needs.
- **No landmark language anywhere.** `G2-S05-0578-landmark` and `G2-S05-0670-landmark` are named
  for landmarks and contain none — rolling green, scattered trees, a dirt track. The keyart board
  supplies four candidate landmark types (windmill, watchtower, carved standing stone, stronghold
  gate) and `palworld-04-plateau-landmark.jpg` builds an entire frame around a single blue-lit
  tower silhouette visible from a long way off. This world gives the player nothing to navigate by.
- **The story's own landmark is unbuilt.** The objective reads "Reach South Bridge — Team Tether
  holds the crossing" in all sixteen frames. In `G2-S05-0755-objective` the bridge is a bare wooden
  frame and a flat grey stone deck, half off the bottom-left corner, with no gate, no barricade, no
  banners, no guard post — nothing that says a faction holds it.

---

## 4. Lighting

Caveat: llvmpipe, no SSAO, no volumetric fog. Softness and contact-occlusion calls below should be
re-checked on hardware. The structural ones stand regardless.

- **Cast shadows are decal blobs, not shadows.** `G2-S04-0361-route`: the shadow under the tree is
  a large soft ellipse spreading from roughly (250,340) to (620,620) — far wider than the canopy's
  footprint, offset down-left of the trunk, and carrying none of the canopy's shape or dappling.
  The same blob appears in `G2-S04-0249` and `G2-S04-0206`. It does not place the tree on the
  ground; it puts a stain near it.
- **The berry bush has no contact shadow of its own** in `G2-S04-0361` — it sits inside the tree's
  blob, so there is no visual cue about whether it is on the ground or floating.
- **The trainer barely casts.** In `G2-S05-0180` and `G2-S04-0400` there is at best a faint
  darkening under his feet; Halda has none I can find. In `G2-S05-0502` there is a small contact
  patch, so the feature exists and is inconsistent.
- **Terrain has no form.** In `G2-S04-0361` the hill at (700–1000, 200–260) shows visible **facet
  banding** — the lighting steps in flat bands across the mesh instead of grading. The same
  stepping is on the ridge in `G2-S05-0335`.
- **Interiors are flat-lit.** `G2-S04-0000` and `G2-S05-0000`: no corner darkening, no light pool
  from the window on the floor, no directional falloff. The room is one ambient value. Worse, **the
  window is an emissive cream rectangle** rather than a view onto the exterior — from inside the
  house you cannot see the world.
- **Foliage is unlit in the near field.** In `G2-S05-0335` the leaf cards filling the left of frame
  are a single flat poster-green with no shading variation at all across a 600 px span.
- **What does work:** the dappled light through canopy in `G2-S05-0271-route` and the long
  raking shadow across the meadow in `G2-S05-0502`/`G2-S05-0522` genuinely read as morning. That
  is the best lighting in the set and it is worth protecting.

---

## 5. Horizon and depth

- **Fog eats the world.** In `G2-S05-0271` everything past roughly y=140 collapses into a flat
  pale blue-green band with zero internal detail. In `G2-S05-0578-landmark` the distant hills are
  featureless mounds with two indistinct white bumps where mountains should be. The keyart's own
  panel 2 keeps crisp snow-capped peaks with structure at the far plane, and `palworld-04` holds a
  readable tower, cliffs and layered rock at distance. Here the far plane is a wash, so there is
  no destination and no depth cue beyond ground perspective.
- **The distance is empty of anything to walk toward.** `G2-S05-0578`, `G2-S05-0722`,
  `G2-S05-0755` all put the far third of frame on rolling green with nothing in it.
- **Fog also flattens the mid-ground.** In `G2-S04-0206` the hill mass at centre (400–1000, 0–160)
  is a low-contrast grey-green lump with a smeared rock texture; it is the largest object in frame
  and it reads as a backdrop card.
- **A ground seam is visible in `G2-S05-0755-objective`:** a hard-edged pale rectangular patch on
  the grass to the player's right, roughly (700–870, 490–560), where the bridge deck's terrain
  blend does not match the surrounding ground.
- **Blotchy terrain-texture blending** rather than seams proper: `G2-S04-0361` has hard-edged
  mustard patches at (0–300, 180–260) and (830–1010, 180–280) that read as blend artefacts, not as
  ground variation.

---

## 6. Interface

Judged as interface, not against Palworld's UI.

- **Screen occupancy.** In `G2-S05-0502` the dark HUD panels — objective card, minimap, hotbar,
  action strip, health/food — cover roughly a third of the frame, and the objective card alone owns
  the right quarter. It sits over the tree line and would sit over a creature.
- **Safe area.** The `FOOD 100%` bar runs to about 15 px from the bottom edge in every frame
  (`G2-S04-0000` shows it clearly). That is a ~2% margin; a 5% TV/handheld overscan crop takes it.
  The interact pill in `G2-S04-0206` also runs close to the bottom edge.
- **Hierarchy is flat.** Every element is the same dark-navy rounded panel at the same opacity: the
  objective, the hotbar, the action strip, the interact prompt. Nothing is primary. The objective
  text is set as one unbroken block with a raw `--` in the middle of it ("Reach South Bridge -- Team
  Tether holds the crossing") — an em-dash never got typeset.
- **Two competing prompt rows.** The persistent action strip (`Map / Satchel / Build / Call Out /
  Change Creature`) and the contextual interact pill (`Pick berries`, `Chop`, `Greet Halda`) stack
  in the lower centre as two similar dark pills. In `G2-S05-0755` the `Try the bridge gate` pill
  sits directly over the bridge gate the objective is telling you to look at.
- **Legibility.** The `100 / 100` health text is light green on a green bar. The tool durability
  ticks under each hotbar icon (`33/40`, `37/40`, `32/40`) are ~3 px red-and-white marks that
  cannot be read at a glance.
- **The minimap carries almost no information.** In `G2-S05-0451`, `G2-S05-0502` and `G2-S05-0522`
  it is a near-uniform mint rectangle with a teal arrow. No terrain, no tree line, no landmark, no
  legend for the white/teal dots.
- **The team panel is inconsistent.** It appears in `G2-S04-0000` and `G2-S05-0000` and in no other
  frame, so the player's most important state — five creatures, three of them KO — is invisible for
  fourteen of sixteen frames.

---

## 7. Artefacts

- **`G2-S04-0400-dialogue` and `G2-S05-0180-route`:** the plank Halda carries passes straight
  through her torso, entering at one side and exiting the other at chest height. Unambiguous
  geometry intersection.
- **`G2-S05-0335-region-change`:** the camera near-plane is inside a shrub. Flat leaf cards fill
  the left 60% of frame at a scale implying a single leaf larger than a person, the player is
  entirely hidden, and the leaf edges show hard polygon jaggies with no alpha coverage. Near-camera
  foliage is neither faded nor pushed away.
- **`G2-S05-0000-region-change`:** green ivy/leaf planes at roughly (130–280, 120–300) intersect
  the stone archway rather than sitting on it, and an NPC stands in the doorway with the head cut
  off by the arch geometry.
- **`G2-S04-0000` / `G2-S05-0000`:** the window is a flat emissive cream panel, not a view; the
  wall/ceiling junction shows a bright hard seam; the wall material is an untextured cream with
  faint blotches.
- **`G2-S05-0670-landmark`:** the dirt path at left is a hard-edged blotchy dark decal with
  low-resolution, stretched texel density where it stretches uphill.
- **`G2-S05-0755-objective`:** the ground patch seam noted in §5.
- **`G2-S04-0361` / `G2-S05-0335`:** terrain facet banding noted in §4.
- **Sheet-level:** `G2-S04-0000-region-change` and `G2-S05-0000-region-change` are the same camera
  in the same empty room eleven minutes apart. Two of sixteen frames are duplicates.

---

## 8. Scale agreement

Ruler: the trainer is 1.80 m.

- **Trees are roughly a third the height their canopy shape implies.** `G2-S04-0361-route`: the
  trainer measures ~145 px head-to-heel; the tree beside him has its trunk base at ~y=335 and its
  canopy running off the top of frame, so ~≥2.3× the trainer — call it 4–5 m for a tree that is
  shaped like a mature broadleaf. `G2-S04-0206-dialogue`: same tree type, base occluded at ~y=400,
  crown at ~y=30, ~2.5× the trainer, ~4.5 m. `G2-S05-0451-route`: the tree directly behind the
  player spans ~y=140 to ~y=470 against the trainer's 145 px — again ~2.3×. **A "grove of oaks"
  the player can nearly reach the crown of is the loudest scale error in the set**, and it is why
  the woodland frames read as scrub rather than as the board's cathedral-canopy oak groves. Per the
  project's own stated preference this is fixed by growing the trees, not shrinking the trainer.
- **Trunk diameter disagrees with trunk height.** `G2-S05-0451`: mid-ground trunks at
  (230–560, 230–330) are ~50–70 px wide but only ~100 px of visible trunk before the canopy. That
  ratio belongs to a redwood stump, not to a 4-metre tree. The result is that the trunks read as
  salmon columns rather than as trees, which compounds §1.
- **Mid-distance trees are shrub-sized against a person.** `G2-S05-0578-landmark`: the NPC on the
  track at ~(755,180) measures ~25 px; the trees immediately around him at ~(700,175) measure
  ~30–40 px. That is a tree ~1.5× a human — under 3 m. Meanwhile the foreground trees in the same
  frame are ~7 m. Two things that should be the same kind of object differ by more than 2× within
  one frame.
- **Creature scale is unassessable and that is itself the finding.** No creature in sixteen frames
  stands near enough to the trainer to be measured against him. The closest reads are the
  quadrupeds in `G2-S05-0722` at ~35×30 px on a ridge with no human in the same depth band. I
  cannot tell you whether the creature you fight alongside is bigger than the one you practise on,
  because neither is ever in frame with the ruler. **A creature-training game whose creatures never
  share a frame with the trainer cannot be scale-checked at all.**
- **What is in agreement:** the buildings, fences, barrels and the bridge deck in `G2-S04-0400`,
  `G2-S05-0180` and `G2-S05-0755` all sit plausibly against the trainer. Halda at ~100 px against
  the trainer's 145 px at her greater depth is consistent. Human-scale props are fine; natural
  scale is not.

---

## Per-frame: where the eye lands, and what the frame is asking

| Frame | Eye lands 1st / 2nd | What it appears to be asking you to look at |
|---|---|---|
| `G2-S04-0000-region-change` | The bright window rectangle / the trainer's face | The trainer close up, and the `TEAM 5/5` roster panel |
| `G2-S04-0206-dialogue` | The purple flower bush / the terracotta roof-less ridge of even trees | A berry bush, despite the frame being tagged dialogue |
| `G2-S04-0249-fight-starts` | The isolated tree and its shadow blob / the purple bush | The `Pick berries` prompt. Nothing about a fight |
| `G2-S04-0361-route` | The purple bush / the tree's oversized shadow ellipse | The same berry bush from a second angle |
| `G2-S04-0400-dialogue` | The red roof / Halda and the plank through her chest | Greeting Halda — but she is small and off-centre; mid-walk framing |
| `G2-S05-0000-region-change` | The window / the NPC in the archway | Duplicate of frame 1; nothing new is offered |
| `G2-S05-0180-route` | The red roof / the orange path | Halda again, closer. Composition is an accident of a walking pause |
| `G2-S05-0271-route` | The big branching tree at left / the light shaft down the middle | A choppable tree. Best-composed frame in the set |
| `G2-S05-0335-region-change` | The wall of flat green leaves / the sliver of meadow at right | Nothing legible — the camera is inside a bush |
| `G2-S05-0451-route` | The stubby salmon trunks / the small dark trainer | A choppable tree, unmarked among identical neighbours |
| `G2-S05-0502-fight-starts` | The tree-line wall across the top / the raking shadow at right | Empty grass. There is no fight in the frame |
| `G2-S05-0522-level-up` | Identical to the above | Nothing. A reward moment with no visual event |
| `G2-S05-0578-landmark` | The near tree at left / the pale washed horizon | An open meadow. There is no landmark in it |
| `G2-S05-0670-landmark` | The dark dirt track / the trainer | A slope and a track. No landmark; two creatures easily missed |
| `G2-S05-0722-route` | The bright grass crest / the tree line | The ridge — the four creatures on it are the last thing you notice |
| `G2-S05-0755-objective` | The orange path / the wooden frame bottom-left | The bridge gate, which is half off-frame and behind the prompt |

---

## Verdict

### 1. The three things that most separate these frames from the references

**1 — The references put creatures in frame at size; these frames have none.**
`palworld-01-boss-fight-forest.jpg` gives half the screen to a single named creature with a health
bar and impact VFX. `palworld-04-plateau-landmark.jpg` has three distinct pals in the lower third,
one ridden. The keyart board puts a companion beside the trainer in both its DAY and its NIGHT
panels and prints a six-species silhouette strip along the bottom as the promise. Against that:
`G2-S05-0502-fight-starts` and `G2-S05-0522-level-up` — the two frames that should have been the
most creature-forward moments in the route — contain a lone human standing in grass with no
creature, no opponent, no effect and no plate. This is the gap, and every other gap is smaller.

**2 — The references build the far distance into something you want to walk to; these dissolve it.**
`palworld-04` anchors the frame on a blue-lit tower over a ruin on a plateau, with layered cliffs
behind. The keyart board offers a windmill, a watchtower, a carved standing stone and a stronghold
gate, and keeps crisp snow peaks at the far plane. In `G2-S05-0578-landmark` and `G2-S05-0722-route`
the far third is featureless rolling green fading to a flat pale wash; in `G2-S05-0271-route`
everything past y≈140 has no internal detail at all. The route's own named destination is unbuilt:
`G2-S05-0755-objective` shows "South Bridge, held by Team Tether" as a bare plank frame on a grey
deck, half off the corner, with no gate, no banner and no guard.

**3 — The references look laid out by a person; these look scattered by a rule.**
`palworld-03-field-boss-meadow.jpg` clusters flowers into drifts with real bare ground between, and
`palworld-01` uses a dense pink groundcover under a clear fighting space. Here, `G2-S04-0206` has
twelve identical trees in an evenly spaced row along the ridge; `G2-S05-0502` and `G2-S05-0522`
have a tree line of one repeated mesh at near-zero scale variance forming a wall with no mouth;
`G2-S05-0722` has four identical creatures at identical scale in a line plus repeated fern and
flower props; and `G2-S05-0522`'s flowers sit at constant density across the whole meadow with
neither a clearing nor a drift. Compounding it, the trees are ~4–5 m against a 1.80 m trainer
(`G2-S04-0361`, `G2-S05-0451`) with no branch structure below the canopy, so the "oak grove"
identity the board is built on is simply not present.

### 2. The two bar questions

> **A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?**

**No.**

What carried part of it: the *subject matter* is right. Rolling hills, a half-timbered village with
a warm roof, a dirt track, wildflower meadow, oak-ish groves, a morning sky — the board's
vocabulary is present. `G2-S05-0271-route` genuinely evokes the board's oak-grove panel: branching
canopy, dappled light, a path receding. The trainer's stylisation is in the board's family.

What sank it: the board's identity is **oak groves you walk under**, and this build has 4–5 m
shrubs with bare cylinder trunks and no branch structure (`G2-S04-0361`, `G2-S05-0451`,
`G2-S05-0722`). The board's palette strip has no lime and no candy pink; the grass highlight goes
acid yellow-green (`G2-S05-0522`) and the rabbits are pastel pink (`G2-S04-0361`). The board keeps
crisp mountain structure at the far plane; here fog erases it (`G2-S05-0578`, `G2-S05-0271`). The
board makes Team Tether legible through oxblood banners on grey stone; in-game the oxblood has
leaked onto village roofs, tree trunks and friendly HUD icons while the one Team Tether grunt in
`G2-S05-0755` wears unrelieved black. The board's streams and ponds — a named headline feature —
appear once, as a small flat blue shape at the far left of `G2-S04-0206` with no shore transition
and no reflection. And the board's two hero panels both centre a companion creature that this build
never puts on screen.

> **B. Shown these frames beside the `palworld-0*.jpg` shots, would someone say these are trying to
> be the same kind of game?**

**No.**

They would say it is a third-person open-world game with a survival HUD, which is a genre and not
this genre. Nothing in sixteen frames signals creature collection or creature combat: no creature
at readable size, no companion following, no nameplate or level tag over anything, no catch
affordance, no combat VFX, and the two `fight-starts` frames and the one `level-up` frame contain
no fight and no level-up. Every Palworld reference tells you what kind of game it is inside one
second, from the pals alone. The one HUD string that hints at the genre is the `Change Creature`
button on the action strip.

Secondary but real: Palworld's frames are dense and lived-in — props, structures, multiple actors,
layered distance — where this world's most-populated interior (`G2-S04-0000`, `G2-S05-0000`) is an
empty plaster box with one window and no furniture, and its meadows are grass, evenly-spaced
flowers and repeated trees.

### What is fixable in the scene, and what needs art that is not in the build

**Fixable by changing scene, scatter, palette, lighting and composition — this is work, not a purchase:**

- Grow the trees. Raise tree height to 12–18 m against the 1.80 m trainer and fix the
  trunk-diameter-to-height ratio (`G2-S04-0361`, `G2-S05-0451`, `G2-S05-0578`). Grow, do not shrink.
- Break the procedural scatter: cluster the tree line into groups with clearings and a mouth,
  introduce ≥3× scale variance per prop family, drift the flowers into patches with bare ground
  between (`G2-S04-0206`, `G2-S05-0502`, `G2-S05-0522`, `G2-S05-0722`).
- Pull the grass highlight off lime and back onto the board's warm olive/sage; take the rabbits off
  candy pink (`G2-S05-0522`, `G2-S04-0361`).
- Re-reserve the red family: desaturate the village roofs and the salmon trunk material, and put
  oxblood back on Team Tether (`G2-S05-0755`, `G2-S04-0400`).
- Push the fog far plane out and let distant terrain keep silhouette and value structure
  (`G2-S05-0271`, `G2-S05-0578`).
- Replace the blob shadow decal under trees with a shadow that carries canopy shape, and give the
  trainer and NPCs a consistent contact shadow (`G2-S04-0361`, `G2-S05-0180`).
- Give the trainer a silhouette-preserving value or rim break so he survives dappled shadow
  (`G2-S05-0502`, `G2-S05-0451`).
- Fade or push out near-camera foliage so the camera cannot render from inside a bush
  (`G2-S05-0335`).
- Fix the plank/torso intersection on Halda and the ivy/arch intersection (`G2-S04-0400`,
  `G2-S05-0180`, `G2-S05-0000`).
- Make the window a view rather than an emissive card, and dress the interior with existing prop
  assets (`G2-S04-0000`, `G2-S05-0000`).
- Fix the terrain-blend patch seam and the facet banding (`G2-S05-0755`, `G2-S04-0361`).
- UI: pull the food bar into a 5% safe area, differentiate objective/action/interact hierarchy,
  raise health-text contrast, keep the team panel persistent, typeset the em-dash, and stop the
  interact pill covering the object it names (`G2-S05-0755`).
- **Compose the beats.** A fight frame must contain a fight; a level-up must produce something on
  screen; a landmark frame must contain a landmark. Nameplates, level tags and health bars over
  creatures are UI work, not asset work, and they are what makes a distant blob legible as an
  encounter.

**Not fixable by scene work — this is evidence for what must be made or bought:**

- **Creature art that reads at distance and at 16 px.** The two species visible read as rocks and as
  flowers. They need distinct head/body silhouettes and a saturated key colour per species. Scale,
  material and animation variation on the installed meshes may get part of the way, but the
  silhouette problem in `G2-S05-0722` and `G2-S05-0670` is a mesh-shape problem, not a tint problem.
- **A companion creature actually present beside the trainer.** Whatever it takes to put one on
  screen — this is the single largest gap and no amount of scatter tuning touches it.
- **Combat and reward VFX.** There is no impact, no muzzle, no beam, no burst, no level-up flourish
  anywhere in the set. `palworld-01` and `palworld-03` are legible as fights almost entirely because
  of VFX.
- **Tree meshes with branch structure below the canopy.** The current trunk-plus-blob cannot be
  scaled into an oak; the board's grove identity needs branching silhouettes.
- **At least one landmark structure for the Meadows** — the board offers windmill, watchtower,
  standing stone, stronghold gate. Currently the region has nothing to navigate by.
- **A built South Bridge with Team Tether presence** — gate, barricade, oxblood banners, guards.
  The story's stated obstacle is currently a plank frame.
- **A distinct NPC body or at least distinct silhouettes across the cast.** Halda is the player
  recoloured (`G2-S04-0400`, `G2-S05-0180`).
- **Facial detail on the trainer** — the flat two-decal face is visible in the only close-up
  (`G2-S04-0000`) and will be visible in every dialogue camera.
