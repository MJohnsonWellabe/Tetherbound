# Band 1 composition plan — village → the Rise → the Pond → South Bridge

**Status:** design output for `docs/ROADMAP.md` Gate 2 task 2.1, written 2026-09-03 on
`ralph/BAND1-COMPOSITION-0903` from real renders of the tree that carries the three
world lanes (WORLD-TREES-0903, WORLD-LIFE-0903, WORLD-CONTENT-0903). It serves
`docs/VISUAL_BIBLE.md` §2 pillar D (layered composition per view) and is judged by §3.
Tasks 2.2 (mid-layer), 2.3 (tree silhouettes), 2.5 (ecology and trainers) and 2.6
(points of interest) implement it. It does not adjust a single density number; it says
what sits at each depth in each frame and why.

`docs/specs/BAND1_ROUTE_CONTRACT.md` is the route this serves and its five places are
this plan's five places. Where the two disagree, this plan is later and more specific,
and the contract's rules still bind (no new meshes, one nature family, creatures loom,
the Pond's density is the reference and does not spread, perf proxy unchanged).

## 1. Evidence

### 1.1 What was rendered

Sixteen stands from this branch, after a fresh `--import`, with the Compatibility
renderer under software GL (`tools/survey.sh` rules: trust composition, silhouette,
colour relationships, scale and geometry; do not trust fine lighting or post):

| Set | Tool | Frames | Sheet |
|---|---|---|---|
| Survey | `tools/survey.sh` | `01-spawn-outward` … `05-spawn-low-sun` | `ralph/reports/BAND1-COMPOSITION-0903/_sheet_survey_before.png` |
| Places | `tools/_capture_band1_places.gd` | `place1-gate-meadow` … `place5-bridge-approach` | `…/_sheet_places_before.png` |
| Composition | `tools/_capture_band1_composition.gd` (new) | `comp1-village-approach`, `comp2-route-out`, `comp3-rise-overlook-pond`, `comp4-rise-look-back`, `comp5-pond-arrival`, `comp6-bridge-approach`, `comp7-pond-reveal`, `comp8-bridge-rim` | `…/_sheet_composition_before.png` |

The composition stands are eye/look pairs on the road, sited from the heightfield with
`tools/_probe_band1_composition.gd` (ground height every 25 m of arc with lateral
samples at ±15/30/60 m), not from config. They are the stands 2.2–2.6 re-render to prove
their work, and they are meant to be kept: changing a stand invalidates the comparison.

### 1.2 What the code-blind judge said

A sub-agent with no code, config or conversation context judged all sixteen frames
against `docs/reference/` under `.claude/skills/visual-judge/SKILL.md`, and was asked
two extra questions per frame: where the eye lands first and second, and what the frame
is asking the viewer to look at. Its full report is
`ralph/reports/BAND1-COMPOSITION-0903/JUDGE-before.md`. The per-stand sections below
quote it; the summary is in §1.3.

### 1.3 Judge summary

Bar A **no**, Bar B **no**. Its three ranked gaps, in its own words:

1. **"Nothing to look at."** Every reference stages a subject at 5–40 m and puts a
   landmark on the sightline; of sixteen frames one (`comp4`) has a landmark on the
   road's sightline, "and it is a bare grey mound with three roofs". Zero readable
   creatures in sixteen frames ("this is a creature game"). Worst: `comp2`, `comp3`,
   `comp6`, `place4`, `03`, `04`.
2. **"One tree, one rock, one plant, one ground."** One lollipop at one height, black
   featureless wedges for rocks, one flowering plant as the whole understorey; "at 30 %
   everything collapses into two bands and dots; you cannot tell the tree line from the
   field."
3. **"Depth and light."** Distance is a pale void with a fog/sky mismatch; no hedgerows,
   groves or hill folds structure the mid-ground; only `comp4` and `comp5` attempt three
   layers "and neither has a distant subject to land on."

It named `comp4-rise-look-back` as "the composition the other five stands should
have" and `place5`'s banks as "the one compositional device in Set B that functions"
(a funnel whose target does not read). It found five capture or placement bugs that are
not composition: a foreground NPC sliced by the frame edge in `01`/`05`; `place3` shot
against the mill wall; two orphaned fence panels in `place4`/`comp6`; a texture-stretch
seam on `place5`'s bank; a row of impostor blocks on `03`'s horizon.

Its "needs art" list is longer than this plan's §7 and is answered there: some of it is
real (rock surface detail, a spreading dark-canopy oak, a grass material with
structure); some of it the kit can meet and has not been asked to (three tree
silhouettes exist in the family and the frames show one because corridor fill draws
three similar CommonTrees at similar scale; a windmill exists at the Pond and is in no
frame; the installed creatures were in one frame at 35 m as five-pixel dots).

**What this changed in the plan.** Every stand now names a creature at 5–30 m from the
eye, not only at 60–100 m (§5, "Life"); the mound gets a dark foot copse on the face
the route sees (5.1); the bridge parapet is composed against a dark treeline so the
funnel has a target (5.7); and the fence line is rebuilt as a line (5.7).

### 1.4 What the route's ground actually does (probe)

Water level −17.0. Heights are metres; arc is metres walked from the village square.

| Arc | Where | Centreline h | What it means for composition |
|---|---|---|---|
| 0–110 | square → road gate → Gate Meadow | +0.9 → −3.1 | the road leaves the village *downhill* into a shallow bowl; the village is above and behind the walker |
| 130–180 | Gate Meadow | −3.1 → −1.7 | a knoll 60 m east of the road rises to **+13.5** at about (47,130): the only landform in the first 400 m |
| 250–330 | first bend | +0.2 → +2.3 | the road turns south-west onto a low shelf; the first-bend copses at (−136,289) and (−95,292) sit on it |
| 400–451 | climb to the crest | +2.9 → **+10.6** | the Rise: the road tops out at (−225,327), the hero TwistedTree at (−224,336) is the local high point (11.4); the ground 15–30 m right of the road is *higher* than the road (7–9 m) from arc 476–526 |
| 476–654 | the descent | +5.9 → −12.6 | 23 m of fall in 200 m; the left (basin) side falls faster than the road |
| 654–730 | basin floor | −12.6 → −15.5 | the pocket's grove closes in; the water is 3–5 m below the road |
| 730–830 | the crossing | −15.5 → −18.4 | the road runs *through* the pond's arm on the Old Mill Crossing; both sides are water |
| 830–1080 | climb out | −18 → +5.6 | the Long Field's first grove at (−120,650) stands on the top of this climb, h 6.3 |
| 1080–1300 | the Long Field | +5.6 → −10.6 → −7 | a broad dip; the trail camp at (344,935) is on the far shelf |
| 2054–2253 | bridge approach | +0.5 → +2.5 | a ridge 60 m to the *left* (north) of the road runs 5–7 m higher for 150 m; the fence line runs on this side |
| 2253–2330 | the rim | +2.5 → −5.5 | the ground breaks toward the gully; a 15 m sample 15 m left at arc 2330 hits **−15.8** (the entombment hole) |
| 2355–2402 | South Bridge | −2.5 / −10.5 / −2.1 | the bridge spans a 9 m deep gully; it is invisible until the rim |

Two consequences drive the whole plan. First, **the only overlook on the route is the
Rise crest, and the basin it should overlook is hidden from it** by the crest's own
convex shoulder on the right and by the crest grove on the left. Second, **the South
Bridge cannot be the subject of its own approach**, because it is in a hole; the
approach has to be composed around the rim and what stands beyond it.

## 2. The grammar the references use and the frames do not

Read across the key art, the five Palworld frames and the two Moong frames, every
reference obeys the same five rules. The current frames break at least three of them
in every stand.

1. **One near element, one side.** A trunk, a rock, a fence post or a creature's flank
   sits within 3–10 m, on one side of the frame only, and is cut by the frame edge. It
   gives the eye a scale and a place to stand. Never centred, never both sides (that is
   a tunnel), never the same object twice on the route.
2. **A living or built subject at 15–80 m.** A creature, a person, a house, a bridge, a
   mill. The subject is what the frame is *about*; the near element and the far mass
   only point at it. A frame with no subject is scenery, and the owner's complaint
   ("nothing to see") is a complaint about subjects, not density.
3. **A mass at 150–600 m with its own value.** A grove, a hill, a treeline against sky,
   a distant roof. It must be darker or lighter than the mid-ground so it reads at 30 %
   size, and it must not be a uniform row. Fog helps it separate; it must not erase it.
4. **The road is the rail.** The eye enters on the road at the bottom of the frame and
   is carried by it to the subject, then released to the mass. A road that leaves the
   frame edge in the first 10 m, or vanishes behind a shoulder, drops the eye on the
   grass.
5. **The horizon sits low and something crosses it.** Reference horizons are at 20–35 %
   of frame height and a silhouette (tree crown, tower, peak, creature) always breaks
   the line. A clean horizon is a defect.

Put against the frames: the same dark boulder is the near element in four of sixteen
stands (`01`, `02`, `05`, `comp1`); nine of sixteen have no subject at 15–80 m; the
distant mass is a fog-flat plain in `03`, `comp2`, `comp3`, `comp6`; the road leaves the
frame edge or vanishes in `comp3`, `comp4`, `place2`; and the horizon is unbroken in
`03`, `comp3`, `comp6`.

## 3. The kit, and what each piece is for

Everything below is in the installed nature family
(`assets/environment/stylized_nature`), already wired into `data/config/vegetation.json`
layers, or an installed prop already placed in this band. Nothing new. Roles are fixed
so that 2.2 and 2.3 do not have to reinvent them per stand.

| Role in a frame | Model(s) | Layer | Scale | Rules |
|---|---|---|---|---|
| **Hero** (the one tree a frame is named after) | `TwistedTree_2` (tallest form, ~19 m at 1.0), `CherryBlossom_3` (the wide crown, the only non-green canopy) | `grove` anchor, `count: 1` | 1.1–1.35 | one per place, 220 m+ apart, always in a clearing so its silhouette is whole; never two heroes in one frame |
| **Frame trunk** (the near element) | `CommonTree_1/_3` | `trees` anchor, `count: 1–2` | 1.3–1.6 | 3–8 m from the eye line, one side; the canopy must be cut by the top edge, the trunk must reach the ground in frame |
| **Copse** (a mid-distance mass) | `CommonTree_1/_2/_3` mixed | `trees` anchor, `count: 6–10`, `radius: 9–14` | 0.5–1.6 | never a row; one tree at ≥1.4, two at ≤0.7, the rest between, so the outline has a peak and a shoulder |
| **Edge** (young trees on a copse's open side) | `CommonTree_4/_5` | `saplings` anchor | 0.25–0.5 | 3–5 on the side facing the road, 6–12 m out from the copse trunks; these are what make a copse read as a wood and not trees on a lawn |
| **Punctuation** (a grey vertical in a green line) | `DeadTree_1/_2/_3` | `deadfall` anchor, `count: 1` | 0.85–1.2 | one per copse at most, on the skyline side; also the discovery marker |
| **Understorey** | `Bush_Common`, `Bush_Common_Flowers`, `Fern_1`, `Plant_7(_Big)` | `bushes` anchor | 0.45–1.0 | banked at trunk bases and along a copse's shaded side, never in the open sightline window |
| **Rock line** | `Rock_Medium_1/_2/_3` | `rocks` anchor, `min_slope_deg: 0`, `sink: 0.3–0.5` | 0.5–1.2, one at 1.6–2.0 | three to five stones in a line or arc that *points*; never a single boulder; each one rotated differently; the Pebble models as their skirt |
| **Outcrop** (a landform made of stone) | `Rock_Medium_3`, `Rock_Medium_1` | `rocks` anchor, `max_slope_deg: 60`, `sink: 0.6` | 1.6–2.4 | only on ground steeper than 25°: the gully rim, the knoll crown, the crest shoulder |
| **Reeds** | `Grass_Wide_Tall`, `Grass_Wheat` | `drygrass`/`grass` anchor | 0.6–1.0 | water's edge only |
| **Built subject** | mill and footbridge (village.json), fence kit (`quaternius_medieval`), bench/firepit (`quaternius_survival`, `generated_camp`), signposts (`signpost.gd` trailheads) | props / village | as placed | a built thing is the strongest mid-ground subject the kit has; every stand gets at most one |
| **Living subject** | Trailpup herd, Galecrest pair, Meadowhart pair, Dara, Gil, the fisher, the grunt | spawns / trainers / NPCs | never shrunk | sited so they cross the eye line at 15–60 m from the stand, wander 15–20 m where the contract already allows it |

Mechanics the implementing lanes must respect (all already in the code, none new):

- **Anchors are the only tool.** `layer_anchors` in
  `data/config/bands/band1_lower_meadows/vegetation.json`, one per element group, each
  with a `_why` naming the stand and the depth it serves. An anchor may override
  `models`, `scale_min/max`, `max_slope_deg`, `min_slope_deg`, `sink` for its own draws.
  Anchors are RNG-isolated from each other and from corridor fill (VP4-CORRIDOR round 2),
  so adding one does not move anything else.
- **Clearings are the second tool.** A sightline window is a clearing, not a lower
  density. `clearings` in the same band file; grass and flowers are exempt from them,
  trees, bushes and rocks are not.
- **Corridor-wide levers are forbidden here.** `trail_offset_min`, `density_scale`,
  `heroes.count` and `heroes.spacing` shift the shared RNG stream and moved a hero tree
  off the bridge ridge last time (WORLD-TREES JUDGE.md). This plan places every
  landmark tree with an anchor so it cannot move.
- **Water floors.** Every layer's `min_height` is already clamped to `water_level − 0.5`;
  reeds and shore rocks want `min_height` overridden per anchor down to −17.5.
- **Ranges.** Scatter renders at any distance (Terrain3D's instancer keeps every region
  resident; `scatter_lod_ranges` is false so `lod_range` is inert). Props cull at 300 m,
  structures at 700 m, the mill at 1000 m. Fog density 0.00055 leaves 87 % contrast at
  250 m and 72 % at 600 m: a distant mass survives if it has value contrast to start
  with.
- **Creature sizes** (`docs/CREATURE_DESIGN.md`): Trailpup 1.28 m, Galecrest 2.10 m,
  Meadowhart 2.05 m, Bramblebun 1.00 m, Mudsnout 0.95 m. The trainer is 1.80 m. A
  Trailpup at 40 m is 1.8 % of frame height; a herd of five is a subject, one is not.

## 4. The route as a sequence, and the one decision

The route is a single sentence with a hinge in the middle, and the hinge is where the
plan spends its effort:

> leave the village downhill through a gate of trees → the first bend compresses the
> view → the climb opens it → **at the crest the world is shown**: the water, the mill,
> the far grove, and the road going down to them → the basin closes around the walker
> → the water is crossed at the mill → the Long Field's two groves keep time → the fence
> line gathers the road → the rim → the bridge.

**The single most important composition decision in this plan: the Rise crest is
rebuilt as a window, not a grove.** Today the crest is the one place on the route with
30 m of height over the destination, and the render shows it overlooking a pale flat
nothing: the hero TwistedTree and the corridor fill drawn to 6 m off the road have put
a screen of canopy on the basin side, and the shoulder to the right is higher than the
road. Nothing else in Band 1 can give the player the "there is the Pond, that is where I
am going" beat, and without it the descent is dead travel and the Pond is a surprise
instead of a promise. So: the hero tree stays and becomes the only near element, on the
left; a 14 m clearing on the basin side of the road (centre (−244,346)) removes every
other tree from the sightline between the crest and the mill; the second and third
crest trees move to the *right* of the road where the shoulder already hides the view;
the shepherd Dara moves from the basin floor up to the descent shoulder (arc ~540) so a
person with two Trailpups stands on the road *in* the window at 95 m; and the far side
of the basin gets a dark grove mass behind the mill so the mill reads as a light shape
against a dark one. Every other stand in §5 is built to lead to or away from this one.

## 5. The stands

Format for every stand: **Eye** (where a walking player stands; the capture stand),
**Look** (what the composition is asking them to look at), **Now** (what the render
shows), **Judged** (the blind judge's own words, from `JUDGE-before.md`), **Plan** (what
sits at each depth), **Life**, **Owner** (which task builds it), **Proof** (what the
re-render must show; measured where it can be).

Coordinates are world XZ metres. "left/right" is screen-left/right from the eye. Lanes
probe every position before placing (`tools/_probe_band1_worldtrees.gd` or the
composition probe); a value here is the intent to within 3 m, not a magic number.

### 5.1 Village approach — the road looking home

**Eye:** `comp1-village-approach`, on the road at arc 230, (−52,194), h −0.7, looking
north-east at the square 214 m away. This is the frame every player sees returning from
the Pond and from the bridge, and it is also what survey stand `03-rise-overlook` is
looking *down* at from the tutorial mound, so it fixes two frames at once.

**Look:** the eye should land on the **tutorial mound** (peak (140,−90), h 49, 300 m):
the biggest landform in Band 1 and the key art's "village under a hill". Second, the
village roofs at its foot. The road should carry the eye there.

**Now:** the near element is the generic dark boulder at 6 m on the right, the fourth
frame it dominates; the treeline on the left at 120 m is a flat even row with no peak;
the roofs are two red dots; the road turns right and leaves the frame within 15 m; the
mound reads well but nothing frames it. There is no subject between 10 and 200 m.

**Judged:** "It asks you to look at the village and shows you a rock." Eye lands on
"the black boulder, centre-right, ~6 m", second the trainer; "the village is fourth or
fifth." The mound is "a grey speckled dome taller than the village, reading as a slag
heap"; the tree line at left "a dozen identical trees at one height, evenly spaced". It
credits this as "the only frame in Set C whose road goes where the camera looks."

**Plan:**

| Depth | Element | Kit | Placement | Why |
|---|---|---|---|---|
| Near, left, 4–7 m | frame trunk | `CommonTree_3` ×1, scale 1.5 | anchor at (−58,199), r 2 | one trunk cut by the top-left edge, canopy over the eye; replaces the boulder as the ruler |
| Near, right shoulder, 6–12 m | rock line | `Rock_Medium_2/_3` ×4, 0.5–1.1, one `_3` at 1.6, `sink` 0.4, `min_slope_deg` 0 | anchor at (−44,203), r 5, plus `Pebble_Round_*` ×6 skirt | the stones lie in an arc that points up the road toward the village; the boulder anchor currently here is removed |
| Mid, 60–110 m | the Gate Meadow's west flank copse, re-shaped | existing `trees` anchor (−5,95) → move to (−4,58), count 6, scale 0.5–1.4 | see 5.2; from here it is the dark mass left of the road with the village behind it | the first mid-distance mass; with the east flank it forms the gate the road passes through |
| Mid, 100 m | the Trailpup herd on the shoulder | spawns order 1075 at (5.9,113), unchanged | crosses the road inside the 20 m wander | the only living subject on the return; it stays |
| Distance, 300 m | the mound | terrain, unchanged | | the landmark; keep the sightline from (−52,194) to (140,−90) free of any tree taller than scale 1.0 within 60 m of the eye |
| Distance, 260 m | the mound's **foot copse** | existing `trees` anchor[2] "south-west foot: just a pair" at (60.5,−133.7) → count 7, r 10, scale 0.7–1.6, plus `deadfall` ×1 | the south-west foot, the face this eye and `comp4` see | the mound reads as "a bare lump" from every angle; trees cannot stand on its 46° flank, so the dark mass goes at its foot where the slope allows, and the lump gets a base and a value step |
| Mid, 15–25 m, left | Bramblebun cluster | spawns order 1010 (arc 275, 27 m left, ×4) → centre (−70,205), r 10, wander 20 | on the left verge, between the frame trunk and the road | the creature at 5–30 m the judge found in no frame; four rabbits crossing a road are a subject, and they are what the returning player meets first |
| Distance, 214 m | the village roofs | unchanged | | read against the mound's flank, not the sky; no tree between the roofs and the eye above scale 1.0 |
| Distance, 250–320 m, right | knoll crown | `CherryBlossom_3` ×1 on the knoll at (42,128) (see 5.2) | | the one light crown on the skyline right of the mound; breaks the horizon at 30 % size |

**Life:** the Bramblebun cluster at 15–25 m (above), the herd at 100 m. No trainer;
this stand is about arriving.

**Owner:** 2.2 (rock line, understorey), 2.3 (frame trunk, flank copse reshape, knoll
crown, the mound's foot copse), 2.5 (the Bramblebun move; the herd stays).

**Proof:** re-render `comp1`; the darkest 5 % of the frame must be a tree trunk, not a
boulder; the horizon line must be crossed by at least two silhouettes (mound, cherry);
the village roofs must sit below the mound's outline in the frame, not on the sky.

### 5.2 Route out — the Gate Meadow

**Eye:** `comp2-route-out`, just outside the road gate at arc 60, (9,40), h −0.7, aimed
at the Rise crest (−225,327) 360 m away. Also `place1-gate-meadow` (9,25)→(9,90) and
survey `01`/`05` look across this ground.

**Look:** first, the **gate**: two flank copses the road passes between at 50–70 m,
different heights, so the exit from the village is a threshold; second, the **knoll
crown** to the left at 90 m; last, the Rise crest's silhouette on the horizon, which is
where the road is going. The frame asks "go through, then up".

**Now:** the two flank stations are staggered 45 m apart on opposite sides (east (20,50)
r 9, west (−5,95) r 6), so they read as two separate copses, not a gate; a single big
tree stands alone in the centre at ~45 m; the road leaves the frame edge at left within
20 m; brown boulders again on the right at 60–80 m; the far treeline is even; the crest
is not distinguishable from the horizon at 360 m; the horizon is a clean line.

**Judged:** `comp2`: "No route is visible; the frame has no subject." The road "is at
the far-left edge running out of frame; the trainer stands in the meadow, not on the
road"; the centre tree "is the only vertical; the tree line behind it is one height,
like a hedge"; distance "nothing". `place1`: "It half-asks you to follow the road, then
hides where it goes"; "four tiny brown quadrupeds at ~35 m … each ~5 px, unreadable as
a species. They are the only creatures in sixteen frames and they do not read"; "the
canopies are the same green as the grass, so at 30 % the tree line and the field merge
into one band"; the knoll "reads as a grey egg".

**Plan:**

| Depth | Element | Kit | Placement | Why |
|---|---|---|---|---|
| Near, right, 3–6 m | the gate post and fence corner | village.json boundary, unchanged | | the built near element; the boundary fence is already here and is the right ruler |
| Near, left, 8 m | rock pair | `Rock_Medium_1` ×1 at 1.4 + `Pebble_Round_*` ×4, `sink` 0.4 | anchor at (2,47), r 2 | one stone, not a line: the village side of the road is tidy, the wild side is not |
| Mid, 50–70 m | **the gate**: east flank | existing anchor (20,50) r 9, count 5 → count 6, scale 0.6–1.6, plus `saplings` ×4 at (14,60) r 5 | keep | the taller side |
| Mid, 50–70 m | **the gate**: west flank | move existing anchor (−5,95) → (−4,58), r 7, count 5, scale 0.5–1.1, plus `saplings` ×3 at (−2,66) | | the shorter side; the two now straddle the road at the same arc with a 16 m gap the road runs through |
| Mid, 20–40 m | the Trailpup herd | order 1075 → (4,78), r 8, wander 20 (see Life) | grazing in the gate gap | the subject; the gate frames it |
| Mid-far, 90 m, left | the **knoll crown** | `CherryBlossom_3` ×1, `grove` anchor at (42,128), r 3, scale 1.25, `max_slope_deg` 30 | on the knoll's top (h 13.5, the only landform in the first 400 m) | the first landmark out of the gate: a pale wide crown on a green hump against sky, 25 m above the road. Note: from this eye it is screen-*right*; from 5.1 it is right of the mound. One cherry in Band 1, here, and nowhere else |
| Mid-far, 90 m, left | knoll outcrop | `Rock_Medium_3` ×2 at 1.8–2.2, `max_slope_deg` 60, `sink` 0.6, anchor at (50,124) r 4 | on the knoll's south face | stone where the slope is steepest, so the knoll is a landform and not a bump |
| Distance, 270 m | the first-bend copses | existing anchors (−136,289) and (−95,292), reshape per §3 (one tree ≥1.4, two ≤0.7) | | the mid-distance mass the road bends behind |
| Distance, 360 m | the Rise crest | hero `TwistedTree_2` (−224,336) 1.1–1.15 → **1.3**, plus `CommonTree_1` ×2 at 1.3 at (−232,330) r 4 (right of the road, see 5.3) | | at 360 m a 19 m tree is 3° tall; a crown of three on a 10 m crest against sky reads, one does not |

Remove: the corridor-fill boulders that land 60–80 m right of this eye are the `rocks`
layer's default forms; with the rock-line and outcrop anchors above in place, 2.2 sets a
band-1 rocks `model_scale` that keeps `Rock_Medium_1` under 1.0 in open ground (the
WORLD-TREES `_why_model_scale_world_trees_0903` note already started this).

**Life:** the herd is at 70 m from `comp2`'s eye and 90 m from `place1`'s, which is
where the judge saw five-pixel dots. It moves 40 m nearer the gate: order 1075 centre
(5.9,113) → (4,78), r 8, wander 20, so the five Trailpups graze *in the gate gap* at
20–40 m from both eyes and the gate frames them. Nothing else in the first 120 m
changes. Galecrest order 1009 (arc 220, 15 m right) is the first aggressive creature
seen on the route: keep it; from this eye it sits just past the gate on the right, which
is correct.

**Owner:** 2.3 (gate flanks, knoll crown, crest crown), 2.2 (rock pair, outcrop,
saplings, rocks model_scale), 2.6 (a signpost at the gate is already the junction
fingerpost; nothing to add).

**Proof:** re-render `comp2` and `place1`; the road must be visible from the bottom
edge to the gate gap; the two flank masses must differ in height by at least 30 % in
frame; the cherry crown must be identifiable at 30 % size; survey `01` and `05` must
show a tree, not the boulder, as the nearest large object.

### 5.3 The Rise — the crest, forward

**Eye:** `comp3-rise-overlook-pond`, on the road at arc 443, (−218,324), h 10.3, the
hero tree 13 m ahead-left, looking south-west along the road toward the mill (−383.5,517)
247 m away and 27 m below. `place2-the-rise` is the approach to this eye from below.

**Look:** the eye lands on the **hero TwistedTree** (near, left, cut by the frame),
goes to **Dara and her two Trailpups on the road at 95 m** (a fight you can see coming,
the contract's own phrase), then to **the water and the mill** in the basin, and the
dark grove behind them. The frame asks "that is where you are going, and there is
someone in the way".

**Now:** the hero tree is a good near element, the best in the set; everything else
fails. The crest grove (hero anchor plus corridor fill at 6 m offset) screens the
basin side; the shoulder right of the road is higher than the road and hides the rest;
the road vanishes over the crest within 10 m; the distance is a fog-pale plain with a
single lone dead tree (the WORLD-TREES marker at (−276,320)) at 60 m right; no water, no
mill, no far grove is visible; the horizon is unbroken. The one overlook on the route
overlooks nothing.

**Judged:** `comp3`: "No pond in frame." "It asks you to look over the crest at what
the trainer sees; the answer is haze." The trainer on the crest is "the best character
readability in any frame"; the great tree "a massive dark trunk cropped at the top, no
canopy; behind it the lollipop hedge"; distance "pale green fading to white, one dead
tree, no water, no landmark". "The framing device (tree) and the subject (trainer)
work; the reward is missing." `place2`: "No subject." "The right half is empty at every
depth beyond 20 m"; the tree line at left "a hedge of lollipops".

**Plan:**

| Depth | Element | Kit | Placement | Why |
|---|---|---|---|---|
| Near, left, 8–14 m | the hero | `TwistedTree_2` anchor (−224,336), scale → 1.3 | keep, grow | the one near element; its canopy over the top-left, its trunk to the ground |
| Near, right, 4–8 m | crest outcrop | `Rock_Medium_3` ×2 at 1.6–2.0, `max_slope_deg` 60, `sink` 0.6, anchor at (−212,318) r 3 | on the shoulder that is already higher than the road | the shoulder becomes stone and is *meant* to block; the eye is pushed left into the window |
| **Window**, 10–120 m, left of road | **clearing** | `clearings` entry, centre (−244,346), r 14, `_why` naming this stand | basin side of the road from the crest to arc 520 | no tree, bush or rock may stand in the sightline (−218,324)→(−383.5,517); the two `trees` corridor instances now here go |
| Mid, 30 m, right of road | the crest's other two trees | `CommonTree_1` ×2, scale 1.3, anchor (−232,330) r 4 | *right* of the road, behind the outcrop | they make the crest a crown from 360 m (5.2) without entering the window |
| Mid, 95 m, on the road | **Dara + two Trailpups** | trainers.json `shepherd_the_rise` → move from (−377,456.8) to (−300,372) (arc ~540, h ≈ 0, on the descent shoulder, 6 m off the centreline) | | the living subject; a person standing in the window. The contract said "the shepherd on the Rise"; the basin floor is not the Rise |
| Mid, 60 m, right | the discovery marker | **remove** `deadfall` anchor (−276,320) | | see §6.1: there are two lone dead trees; the one at the cache is the marker, this one is 107 m from the cache and lies |
| Mid-far, 170 m, right of the window | the **real** marker | props `rise_cache_marker` `DeadTree_2` at (−382.8,355.5), scale 0.9 → **1.3**, plus `rocks` anchor ×3 at 0.6–1.0 at its foot | at the cache | from the crest it is a grey vertical 30° right of the road, alone on the slope; the discovery is seen from the overlook |
| Distance, 250 m | the water and the mill | unchanged | | the reward of the window; the mill's pale wall is the light shape |
| Distance, 300–330 m, behind the mill | **basin far-side grove** | `trees` anchor at (−420,560) r 16 count 10, scale 0.8–1.6, plus `deadfall` ×1 at (−432,548) | on the far bank behind the mill, inside the Pond pocket's existing density (this adds no density where the reference already holds; it shapes the bank the mill is seen against) | the dark mass the light mill reads against; the pocket's own grove already stands here and this only guarantees a peak behind the mill |

**Life:** Dara + pups on the road (above). The Galecrest pair (order 1013, currently at
(−372,447) with wander 15) moves to the cache side at (−360,350), wander 15, so it
circles over the marker: the discovery gets a sky element and the crest frame gets a
second living thing on its right. Bramblebun order 1014 (arc 495, 39 m left) sits in
the window; move it 20 m further left to (−262,372) so it is seen *in* the window from
the crest, not in the road.

**Owner:** 2.3 (hero scale, crest pair, far-side grove), 2.2 (outcrop, clearing, marker
rocks, removal of the stray deadfall), 2.5 (Dara's move, the Galecrest and Bramblebun
moves), 2.6 (marker scale; the Rise signpost is the "Pond Circuit" trailhead at
(−357.8,401.1), which is *past* the crest on the descent: move it to the crest at
(−228,331) so the sign stands in the window and says where the road goes).

**Proof:** re-render `comp3`; the water must be visible as a distinct lighter band; the
mill wall must be identifiable at 30 % size; Dara must be visible on the road; the
darkest 5 % of the frame must lie in the near hero's trunk or the far-side grove, not in
open ground; the dead tree at (−276,320) must be gone.

### 5.4 The Rise — the crest, looking back

**Eye:** `comp4-rise-look-back`, just past the crest, (−236,334), h 10.4, looking
north-east at the square 415 m away with the mound behind it.

**Look:** the **mound** with the village roofs at its foot, framed on the left by the
first-bend copse and on the right by the trainer on the knoll. This is the key art's
top-left panel and it already nearly works.

**Now:** the best frame in the set. A left near tree, the first-bend copse as a
mid-distance mass, the mound with roofs centre, the trainer top-right on the knoll.
Defects: the road is hidden by the knoll the trainer stands on; the copse is a flat
row; the mound's flank is bare and the roofs are two dots; no living thing.

**Judged:** "The best-composed frame of the sixteen … This is the composition the other
five stands should have, with a landmark worth looking at." Defects: the dome "still a
bare grey speckled lump", the village "three red roofs at ~200 m, ~1 % of frame
height", the tree line "one species at one height".

**Plan:**

| Depth | Element | Kit | Placement | Why |
|---|---|---|---|---|
| Near, left, 6 m | the existing near tree | corridor fill; pin it with a `trees` anchor ×1 at (−243,338) scale 1.4 | | so a re-bake cannot lose it |
| Mid, 100 m | first-bend copse | reshape per §3 (peak + shoulder), add `saplings` ×4 on the road side | | the mass stops being a row |
| Mid, 20–60 m | the road | unchanged; the knoll the actor stands on is the crest shoulder | | the eye is on the road in play; the capture actor position is the only thing on the knoll |
| Distance, 415 m | roofs under the mound | unchanged | | |

**Life:** none needed; the return view is quiet on purpose.

**Owner:** 2.3. **Proof:** re-render `comp4`; no regression against the before frame;
the copse outline must have one clear peak.

### 5.5 The Pond pocket — reveal, arrival, shore

The Pond is the approved lush reference and its density does not change. What changes
is *where the water is allowed to be seen from*, because today it is seen from nowhere
on the road: the crest (5.3) is screened, the arrival (`comp5`) sees it through trunks,
and the place stand (`place3`) is shooting the mill wall from 3 m.

**Eyes:**
- `comp7-pond-reveal`, on the road at arc 560, (−320,378), h −1.5, 152 m from the
  mill. The first siting of this stand, at arc 600, rendered a lesson: the pocket's
  grove edge already stands 15–40 m ahead there and the "Pond Circuit" trailhead post
  is 2.5 m from the lens, so the water is hidden before it is reached. The profile
  says the window is earlier: from arc 540 to 575 the ground left of the road already
  falls toward the basin (−3.5 at 30 m, −6.2 at 60 m) and the sightline to the mill
  passes 25–30 m left of the grove's road-side edge.
- `comp5-pond-arrival`, arc 654, (−387,442), h −12.6, 76 m from the mill, Dara's old
  spot 15 m ahead-right.
- the shore: `place3-pond-pocket` is **re-sited** to the fisher's camp, eye (−398,588),
  h −14.6 + 2.2, looking north across the water at the mill (−383.5,517) 72 m away
  (bench and firepit in the near-left, water mid, mill and footbridge far, far-bank
  grove behind). The current place3 eye (−390,510) stands inside the mill's clearing 3 m
  from its wall and shows a stone wall; that is a capture defect, not a world one, and
  the stand is wrong, not the mill.

**Look:** at the reveal, **the water sheet** with the mill's pale wall on it and the
footbridge's dark line; at the arrival, the **footbridge** through a window in the
trunks; at the shore, the **fisher on the bench** with the mill across the water.

**Now (reveal, first siting at arc 600):** two signpost posts fill the centre at 1 m,
a trunk behind them, the grove's near edge across the whole right half at 15–40 m, the
road at right, no water anywhere; the far ridge at left is bare. The stand was in the
wrong place and it proved where the right place is. **Now (reveal, arc 560):** the profile was right about the ground and the plan is
right about the window. The road descends right, an open slope rises left, the pocket's
grove line runs across the whole distance and **the mill's red roof shows above it at
centre**, 150 m away, the first built thing on the sightline since the village; the
water is still not visible, because the grove's road-side edge between arc 590 and 650
stands between the eye and the sheet. The trainer is 6 m ahead on the road. No creature.
The far ridge left is bare. The second judge's read is in `JUDGE-before.md` ("Second
pass"). **Now (arrival):**
a dense grove of same-height red trunks fills the frame, the water is a strip glimpsed
between trunks, Dara stands among the trees on the left, a fallen branch is the right
near element; there is no window to the water and the footbridge is not visible. **Now
(shore):** a stone wall.

**Judged:** `comp5`: "It asks you to walk toward the water, and hides the water."
"The densest frame; the grove gives real layered depth (trunks at roughly 3, 8, 15 and
30 m)" but "every trunk is the same red-orange with the same ~0.7 m diameter … the grove
reads as one tree instanced"; the pond "a turquoise sliver at ~40 m … about 1 % of the
picture"; Dara "a second character … unreadable as anyone in particular"; the root at
frame right "reads as a detached hook rather than part of a tree". "This is the right
idea, executed with one tree." `place3`: "It asks you to look at a wall … the camera is
on the wrong side of the building"; also two timber braces overhanging the wall and a
floating plinth on the mill itself (a village-kit item, not this plan's).

**Plan:**

| Depth | Element | Kit | Placement | Why |
|---|---|---|---|---|
| Reveal, near, right, 4–8 m | rock line down the bank | `Rock_Medium_2/_3` ×4, 0.5–1.0, `sink` 0.3, anchor at (−312,383) r 4 | the bank on the road's high (right) side | the descent reads as a cut into a slope; the eye is pushed left toward the water |
| Reveal, mid, 40 m, right of road | the "Pond Circuit" trailhead | `paths.trailheads` (−357.8,401.1), unchanged | at the road's edge where the grove begins | the built mid element; a sign that says "Pond" at the moment the pond appears |
| Reveal, **window**, 20–150 m, left of road | **clearing** | `clearings` entry, centre (−345,432), r 18 | the basin side of the road from arc 570 to 650, between the road and the water | no tree, bush or rock in the sightline (−320,378)→(−383.5,517); corridor fill at 6 m offset currently screens it. This is a sightline, not a thinning of the pocket: it lies on the pocket's road-side edge, and the pocket's density behind it is untouched |
| Reveal, mid, 60–90 m | the pocket's edge, right of the window | existing corridor trees; add `saplings` ×5 at (−372,430) r 8 and `bushes` ×8 at (−368,426) r 8 | the grove's road-facing edge | an edge with young trees and understorey is what says "wood"; it is the window's right frame |
| Reveal, distance, 152 m | mill, footbridge, water | unchanged | | the reward, first seen here, 14 m below the eye |
| Arrival, **window**, 20–40 m | clearing centre (−378,470), r 10 | between the road and the water at arc 640–690 | | the second window, the one `comp5` looks through; same rule as above |
| Arrival, near, right, 3 m | the fallen branch | the existing `deadfall` piece; pin with an anchor ×1 (`DeadTree_3`, scale 0.6, `sink` 0.5) at (−381,447) | | keep it; it is the right near element |
| Arrival, mid, 30 m | the window (above) | | | the footbridge appears between two trunks |
| Arrival, mid, 20–40 m | Paddlenewt ×2 (order 6) and Brooktail (order 1045) | wander 20 already; move Paddlenewt centre from its current to the window's water edge (−382,478) | | something moving in the window |
| Shore, near, left, 2–4 m | bench, firepit, the fisher | props `pond_fisher_camp` unchanged; fisher NPC on the bench | | the built and living near subject in one |
| Shore, near, right, 3–6 m | reeds | `drygrass` anchor `Grass_Wide_Tall` ×10, scale 0.8–1.0, `min_height` −17.5, at (−392,586) r 4 | water's edge | the shore has an edge |
| Shore, mid, 72 m | mill and footbridge | unchanged | | |
| Shore, distance, 120 m+ | far-bank grove (5.3's anchor at (−420,560) is on this bank) | | | the mass the mill reads against, from both the crest and the shore |
| Shore, sky | Reedwing ×2 (order 11) | wander 20 already | | a silhouette across the horizon |

**Life:** the fisher (dialogue only), the water species with their 20 m wander, the
elder Mosshell's hollow at (−490,555) is 100 m west and stays off-frame on purpose.

**Owner:** 2.2 (rock line, saplings, bushes, reeds, the two clearings), 2.5 (Paddlenewt
move), WORLD-TREES' capture tool owner for the `place3` re-site (a one-line stand
change in `tools/_capture_band1_places.gd`; do it in 2.2's branch since 2.2 re-renders
it).

**Proof:** re-render `comp5`, `comp7`, `place3`; water must be visible in all three
as a band at least 8 % of frame height; the footbridge must be identifiable in `comp5`;
`place3` must show the bench, the water and the mill in one frame.

### 5.6 The Long Field — the two groves

Not one of the task's five stands, but 2.2/2.3 touch it and `place4-long-field` judges
it. **Eye:** `place4` (25,1252)→(5,1235). **Look:** the grove's edge with the trainer
under it. **Now:** the best of the WORLD-TREES results: a real small grove, trainer at a
believable scale. Defects: no understorey, no edge saplings, every trunk the same
girth, a brown hut-shape at the right edge (the Tether waypost crate at (156,1227) seen
end-on). **Judged:** "It asks you to look at the trainer, who is looking at nothing";
"a 'long field' in the references ends at something — a peak, a tower, a cliff; this one
ends in fog"; "a two-panel pale fence at right, ~20 m, attached to nothing" (the
bridge-approach fence's first section, 5.7). The stand's distance is the bridge ridge
and the far-rim treeline of 5.7, which is what this field must end at.

**Plan:** both groves ((−120,650) r 14 and (5,1235) r 14) get the §3 copse recipe:
one tree ≥1.4, two ≤0.7, `saplings` ×5 on the road side, `bushes` ×10 banked on the
shaded side, one `DeadTree` on the skyline side, and their glade clearings (1902, 1903)
stay. The trail camp at (344,935) is the built subject of the field's middle and Gil
(wanderer, (328,905)) its living one; both stay. Bramblebun/Mudsnout clusters already
moved to 12–15 m with 20 m wander (WORLD-LIFE) stay.

**Owner:** 2.2/2.3. **Proof:** re-render `place4`; three distinct trunk girths visible;
understorey present under the canopy.

### 5.7 The bridge approach — the fence, the rim, the gate

**Eyes:**
- `comp6-bridge-approach`, on the road at arc 2150, (105,1226), h −0.6, where the fence
  line begins on the left shoulder, aimed between the bend and the bridge, 143 m.
- `comp8-bridge-rim`, on the road at arc 2253, (11,1266), h 2.45, the true rim,
  looking at the bridge 64 m ahead and 5 m below across the hollow. The first siting
  of this stand, at arc 2300, was the bottom of that hollow (h −5.5) with a
  corridor-fill boulder 5 m ahead, and it proved the profile: the road crests at
  2253, drops to −5.5 at 2303, climbs to the near abutment at −2.5 (arc 2355), crosses
  the 9 m gully and lands at −2.1. The gate is a double dip, and the rim is the first
  crest.
- `place5-bridge-approach`, (−20,1318)→(8,1330), at the gully edge.

**Look:** at the approach, the eye should be *gathered*: the fence on the left and a
rock line on the right converge on the notch where the road drops out of sight, and
the grunt stands at the notch; at the rim, the **bridge** with the far rim's treeline
behind it and the Meadowhart pair on the left slope; the frame asks "this is a gate".

**Now (approach):** an open plain; the second Long Field grove sits on the ridge to
the left at 100 m and reads as the frame's mass, which is right; the fence's four
sections at 20 m spacing read as three tiny pale fragments scattered in the grass, not
a line; the near element is bare road; the road curves away and no notch, no gate, no
grunt is visible; the horizon is unbroken; a brown block (the waypost crate) sits at the
right edge. **Now (rim, first siting at arc 2300):** a 4 m pale boulder at 5 m fills the centre
with the trainer behind it; a dead tree on the far skyline; groves left and right; no
bridge. A corridor-fill rock happens to stand exactly where this plan wants an authored
upright, which says the instinct is right and the object is wrong. **Now (rim, arc
2253):** the road runs straight through the second Long Field grove (anchor (5,1235),
r 14, 30 m from the eye): trunks both sides, canopy over the top edge, a Bramblebun
pale against the shade on the left at 40 m, and at the far end of the road's gap a
small orange shape at 64 m that is the bridge's timber, with the far bank's slope
behind it. The grove was placed by WORLD-TREES as a thin-leg fill 12–13 m off the
trail; the trail's bend at (30,1250) brings the road through it, and by accident it is
the best gate on the route. The second judge's read is in `JUDGE-before.md` ("Second
pass"). **Now (place5):** the gully's cut
walls are hard-edged grass planes, the road runs into a trench, a bare dead tree stands
on the far skyline, the bridge itself is not in frame.

**Judged:** `comp6`: "No bridge in frame." "No subject." "Two orphaned two-panel fence
segments at ~40 and ~60 m right of centre, attached to nothing; a pale tan block at
~80 m centre (hay? crate?), unreadable"; the road "a faint orange smear … doesn't read
as a road at 30 %"; "the mid-ground is empty where palworld-02 has a cliff, a cave
mouth and two creatures." `place5`: "The road runs into a cutting between two raised
banks; both are steep and flat-topped and read as engineered berms"; the bridge "a low
wooden railing at ~60 m, ~3 % of frame height … reads as a fence across the road"; "the
banks work as a funnel — the one compositional device in Set B that functions … what it
funnels to doesn't." Also a texture-stretch seam on the right bank (terrain, not this
plan's). `comp8` was rendered after the judge's pass; see §1.3.

**Plan:**

| Depth | Element | Kit | Placement | Why |
|---|---|---|---|---|
| Approach, near, left, 4–8 m | the **fence line**, rebuilt | props `bridge_approach_fence`: 4 sections → **8**, spacing 7 m, 5–6 m off the centreline (was 8–10), from arc 2140 to 2200, one section toppled (the third, as now), one missing (the sixth) | left shoulder | at this FOV 10 m off is the frame edge; 5–6 m is the near element. Eight posts at 7 m read as a line with two breaks; four at 20 m read as litter |
| Approach, near, right, 6–12 m | rock line | `Rock_Medium_1/_2` ×5, 0.5–1.2, `sink` 0.4, anchor at (98,1236) r 6 | right shoulder, converging with the fence | the two lines gather the road |
| Approach, mid, 60 m | the Tether waypost | props `tether_waypost` at (156,1227): rotate the crate and banner so the banner's face is toward this eye (`yaw_deg` 15 → ~105) | | the oxblood banner is the one faction colour on the route; end-on it is a brown block |
| Approach, mid, 100 m, left | the second grove | 5.6 recipe | on the ridge | the mass; already there |
| Approach, mid-far, 100 m | **the grove is the gate** | existing `trees` anchor (5,1235) r 14 count 10: keep; add a road-gap rule: no trunk within 5 m of the centreline through it (a `clearings` entry centre (12,1258) r 5 on the road only); §3 copse recipe (one ≥1.4, two ≤0.7); `saplings` ×4 on its approach side at (40,1240) r 6 | the rim at arc 2253, where the road already passes through this grove | from the approach the eye is gathered by the fence and the rock line to a dark canopy mass with a light gap in it where the road goes; that gap is the notch. No stone uprights are needed: the trunks are the uprights. The accidental corridor boulder at about (−25,1295) in the hollow is removed by a clearing (centre (−27,1297), r 8) so the hollow stays a hollow |
| Approach, distance, 200 m+ | the far rim's treeline | `trees` anchor at (15,1385) r 14 count 9, scale 0.8–1.6, plus `deadfall` ×1 at (30,1378) | on the far bank behind the bridge, south of the trail's end (0,1360) | the dark mass behind the pale bridge parapet; breaks the horizon |
| Rim, near, both sides, 3–8 m | the grove's trunks (above) | | | the one place on the route where both sides carry a near element, because a gate is a tunnel on purpose; the canopy must close over the top edge and the road's gap must show the bridge at its end |
| Rim, mid, 64 m | the bridge parapet | `crossings` south_bridge, unchanged | at the end of the road gap | it must read as timber, not as "a fence across the road" (judge): 2.6 checks the parapet's retint against the fence kit so the two are not the same pale yellow, and the far-rim grove (below) is the dark ground it sits on |
| Rim, mid, 20–50 m | the hollow | terrain, unchanged; `bushes` ×8 and `drygrass` on its floor by anchor at (−20,1300) r 12 | between the rim and the abutment | the dip reads as a dip because its floor is a different texture from the slopes |
| Rim, near, 0–15 m, the cut walls | rock skirt | `rocks` anchor along the rim, `Rock_Medium_2` ×8, 0.6–1.2, `max_slope_deg` 70, `min_slope_deg` 25, `sink` 0.5, at (−10,1318) r 22 | the gully's walls | the walls become stone; grass at 45° is the defect the judge saw in `place5` |
| Rim, mid, 20 m | the grunt | trainers `south_bridge_grunt` at (14,1314), unchanged | on the near abutment | the living subject; he is the gate's keeper |
| Rim, mid, 45 m | the bridge | unchanged | | |
| Rim, mid, 56 m, left slope | Meadowhart pair | order 1005 at (−55.3,1346.9), unchanged (WORLD-LIFE's 40 m siting) | | seen before it can be fought, the contract's beat |
| Rim, distance | far-rim treeline (above) | | | |

The entombment hole at (7.9,−3.4,1319) and the −15.8 m sample 15 m left of the road at
arc 2330 are a terrain defect owned by the traversal lane; the rock skirt above does
not fix a hole and must not be used to hide one.

**Owner:** 2.6 (fence rebuild, waypost rotation; signpost "South Bridge" trailhead at
(14.1,1256.2) stays), 2.2 (rock lines, uprights, skirt), 2.3 (far-rim grove), 2.5
(grunt and Meadowhart stay).

**Proof:** re-render `comp6`, `comp8`, `place5`; in `comp6` the fence must read as one
line with breaks at 30 % size and the uprights must be visible at the notch; in `comp8`
the bridge parapet must sit against a dark treeline, not sky; in `place5` the darkest
5 % must be stone or shadow under trees, not the cut wall.

### 5.8 The survey stands

`01-spawn-outward` and `05-spawn-low-sun` (same eye) are fixed by 5.2's rock changes
and the Gate Meadow flanks; the shadow wedge the previous judge named is a lighting-rig
item outside this plan. `02-valley-floor` looks from (−120,130) toward (40,40): the
boulder at 6 m in front of it is the same default form and goes with the band-1 rocks
model_scale in 5.2; the first-bend and gate copses become its mid-distance masses.
`03-rise-overlook` looks from the mound at (−60,60), which is the Gate Meadow: the gate
flanks, the knoll crown and the first-bend copses are the "groves, tree lines,
mid-distance masses" VISUAL_BIBLE §4 item 1 says it lacks, so it is fixed by 5.1/5.2
without any change of its own. `04-three-quarter` already has a near tree and a built
subject; 2.3's row-breaking applies to the trees behind the cottage.

## 6. Decisions and corrections this plan makes

### 6.1 One dead tree, at the cache

WORLD-TREES anchored a lone dead tree at (−276,320) "54 m from the crest" as the
discovery marker; WORLD-CONTENT placed one at the cache itself, (−382.8,355.5), which is
where `playground_world.gd` `CACHE_AT["tm_rock_throw"]` puts the pickup. They are 107 m
apart and only one can be true. The marker is at the cache. 2.2 removes the `deadfall`
anchor at (−276,320); 2.6 scales the prop at the cache to 1.3.

### 6.2 The shepherd stands on the Rise

`shepherd_the_rise` (Dara) was placed at (−377,456.8), on the basin floor at arc ~660,
h −13.9. That is not the Rise and it is not visible from it. 2.5 moves her to the
descent shoulder at (−300,372), arc ~540, with her two Trailpups, so she is the
mid-ground subject of the crest window at 95 m and is seen before she is fought. The
Galecrest pair moves with the discovery, not with her (5.3 Life).

### 6.3 The pond capture stand

`place3-pond-pocket`'s eye is inside the mill clearing 3 m from the wall. It is re-sited
to the fisher's camp (5.5). This is a stand change and invalidates comparison with the
WORLD-TREES before/after sheet for that one frame; the two before frames of the old
stand are the record of why.

### 6.4 One cherry

`CherryBlossom_3` is the only non-green canopy in the kit and the hero list already
includes it. This plan spends it once, on the Gate Meadow knoll, where it is the first
landmark out of the village and the skyline accent of the return view. Nowhere else in
Band 1.

### 6.5 The boulder is retired as a default

The single dark `Rock_Medium_1` at 1.15 model scale is the near element in four
stands and the previous judge's third-ranked gap. Rocks in this band are placed as
lines, pairs, skirts and outcrops by anchor, and the open-ground default is kept small
(2.2 sets the band-1 rocks `model_scale` so `Rock_Medium_1` stays under 1.0 in corridor
fill).

### 6.6 Capture defects, not world defects

Three of the judge's findings are the harness's: the NPC sliced by the left edge of
`01`/`05` (the survey actor stands 6 m from Grandpa's morning position; a
`tools/survey.gd` item), `place3`'s eye against the mill wall (6.3), and the row of
impostor blocks on `03`'s horizon (a distant-prop rendering artefact to be reproduced
before it is called a world defect). They are recorded so the after-judge is not asked
to re-find them.

## 7. Ceilings this plan does not pretend to lift

The judge's "needs art" list, sorted honestly:

- **Real, and out of scope by hard rule:** rock surface detail (faces, cracks, moss); a
  spreading, dark, interior-shadowed oak canopy; a grass material with structure; a
  road material with ruts. No new meshes for the Meadows; §3 works with what is
  installed and 2.3's after-judge will say how far scale, rotation, clustering and the
  dead-tree accent get.
- **Not art; not yet asked of the kit:** "a second and third tree" (the family has five
  CommonTree forms, two TwistedTrees and the CherryBlossom; corridor fill draws three
  similar CommonTrees at similar scale, which is why one tree shows); "a landmark
  object in the key art's own language: windmill, tower" (the mill stands at the Pond
  and is in no frame; 5.3 and 5.5 put it in three); "a creature that reads at 30 m"
  (every installed species is 0.95–2.10 m; at 30 m a Galecrest is 4 % of frame height
  and reads; the frames showed creatures only at 35–100 m).
- **Lighting and terrain, owned elsewhere:** the low-sun frame that darkens instead of
  lighting; the fog/sky mismatch band; the jagged terrain-triangle shadow edges; the
  bank texture stretch and seam; the gully hole.

- **Canopy structure.** Every tree is one of five CommonTree forms, two TwistedTree
  forms and one CherryBlossom; asymmetry comes from scale, rotation, clustering and a
  dead tree, not from new silhouettes. That is the hard rule and 2.3's whole job.
- **Fog at range.** 0.00055 density is a deliberate value with a measured history; the
  plan gives distant masses value contrast rather than asking for less fog.
- **The gully hole.** Composition cannot fill a terrain hole; the traversal lane owns
  it.
- **Creature material and contact shadow.** 2.4's work; this plan sites creatures where
  they will be seen and says nothing about how they are lit.

## 8. Acceptance for 2.2, 2.3, 2.5, 2.6 against this plan

1. Re-render the same sixteen stands (`tools/survey.sh`,
   `tools/_capture_band1_places.gd` with the 5.5 re-site, `tools/_capture_band1_composition.gd`),
   same settle, same times of day; sheet each set.
2. Hand the before sheets in `ralph/reports/BAND1-COMPOSITION-0903/` and the after
   sheets to a code-blind judge with the same two extra questions (where the eye lands;
   what the frame asks). Tell it nothing else.
3. Pass when, for every stand in §5, the judge's "eye lands first" matches the plan's
   **Look**, the frame has a named element at all three depths, and the **Proof** line's
   measurable condition holds. Fail on any stand where the judge names a new defect that
   was not in `JUDGE-before.md`.
4. Perf proxy at `band1_open` stays ≤ 7,500 draws / 12.0 M prims. Every element above
   is an anchor of one to ten instances or a clearing; the total added across the route
   is under 120 instances.
