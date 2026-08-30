# HANDOVER — T1-HALL-3, 2026-08-30

**Branch:** `ralph/T1-HALL-3`, off `origin/ralph/LAND-0830H`.
**Brief:** JUDGE-5's ranked defect list for the Meadows Hall (D1–D12) plus the
inherited StormWall follow-up (D13–D16). The verdict this lane exists to answer:

> "**No. It reads as a dressed greybox.** The rebuild put a real meadow around
> the Hall and left the Hall itself almost untouched. Ground, vegetation, sky
> and the ramp approach are markedly better than `hall0830`. The fortress is
> not."

The previous lane spent its budget outside the walls. This one spent it on the
fortress.

---

## 0. Read this first if you are the next lane

Three things in here are worth more than the defect list, because each one is a
trap that cost a previous lane a whole judging round:

1. **`H-04-gate-mouth` was broken for three rounds, and the checker that
   catches it already existed.** `tools/capture_check.gd::_embedded_problems`
   was written by T1-STORMWALL *specifically* for the JUDGE-4 version of this
   defect, and `_ground_problems`' failure text names the frame by filename.
   `_judge_capture_hall.gd` never called either. A tool that produces evidence
   should be running the evidence checker; this one now does.
2. **A `BoxMesh` cannot carry a centred texture.** Godot packs the six faces
   into one UV atlas and the face a banner is read through spans u
   [0.333, 1.000]. Anything centred in its own image renders cropped and
   stretched. Probe the mesh, do not assume.
3. **`_visual_bounds()` searches DESCENDANTS only.** The castle kit is OBJ, and
   `building_prefabs.gd`'s OBJ path produces a bare `MeshInstance3D` with no
   children — so `_visual_bounds` returns an empty AABB for every castle module
   and a real one for the single glTF module. A pass written against it
   silently skips 17 of 18 modules and acts on the one that should have been
   excluded.

All three were caught by measuring, and all three would have shipped as
"finished work" if I had trusted the code's shape instead.

---

## 1. What changed, by defect

### D1 (ranked 1/16) — `H-04-gate-mouth` is not a frame of the gate

**Root cause, confirmed against the frame.** The stand walks 34 m up the
causeway from the `entrance` marker but took its eye height from that marker's
own y — and `entrance` resolves to `ramp_foot`. The causeway climbs ~9 m over
its 40 m run, so the camera sat ~7 m *inside* the slab. That is exactly what the
frame shows: cobble underside across the lower two thirds, grass seen edge-on
from below ground, and a black unlit column where the ramp's shadow is.

**Fix.** `stronghold.gd` gains `causeway_surface_y(world_x, world_z)`. It has to
be public and it has to be asked: `_build_approach_ramp` *samples* the ramp's
rise from the live ground rather than reading it from config (`site.ramp_run` is
the only authored number), so no caller can re-derive the deck height. The stand
now sits on the deck and aims up the remaining climb, because the gate sill is
above it and a level aim put the arch's head out of frame.

**And the process fix:** `_judge_capture_hall.gd` now calls
`capture_check.warn_only` at every stand. `warn_only`, not `require` — the tool
legitimately shoots one interior stand (H-07) where the grass field is correctly
absent, and `require` would abort the run on it. Exterior stands promote any
problem to a run failure, so the exit code still refuses to call a degraded set
"evidence".

### D2 (2/16) — the courtyard is an empty box with a figure from another game

Two independent problems, both fixed.

**The body.** `data/config/bands/band5_stronghold_approach/trainers.json`
carried `"base": "officer_b"` on `stronghold_courtyard`, added by T3-INSTALL
earlier the same day to give the individual a distinct silhouette. The judge
read the result blind as "cel-shaded anime: flat white blown-out face, painted
eye and mouth, hair as a solid magenta mass" in a world of painted stylised
realism, and said the swap away from `hall0830`'s oxblood grunt "cost style
cohesion and cost the Team Tether colour identity".

That is a property of the generated atlas, not of the override mechanism —
measured directly off the textures: the grunt rig's lit mean is (73,52,52), a
maroon; `officer_b`'s is (76,57,60) over a purple-magenta atlas with no oxblood
anywhere in it. Every rank's own default `base` is already `grunt`, so
**deleting the override is the whole fix** and rank stays legible through the
badge/palette layer exactly as before.

Reverted for the three trainers standing inside the Hall — `stronghold_patrol`
(`grunt_c`), `stronghold_courtyard` (`officer_b`), `stronghold_elite`
(`captain_a`) — because all three share the idiom and all three appear in these
stands. **Deliberately NOT reverted** for `stronghold_outer_watch` and
`stronghold_checkpoint`: they stand outside the Hall, they are not in any frame
the judge saw, and T3-INSTALL's per-individual identity goal is sound. That is a
call the owner or T3-INSTALL may want to revisit for the whole cast rather than
have this lane make it for them.

**The room.** The courtyard genuinely had one object in it — the relay hub — and
that object sits at local z 27.4 while the H-07 stand looks *south* from the
courtyard trainer. The room's only dressing has been directly behind the camera
in every frame ever shot of it. 18 props added along the walls, from the prop
families the outer-works garrison camp already uses (D24's one-vocabulary rule,
no new assets): stores, a workbench and an anvil down the working side, a stall,
firewood and a bench down the living side, and material stacked either side of
the door the player leaves through.

Placement obeys the room's own constraints rather than filling it: the courtyard
is a trainer **fight** room, so the fight floor (x[-5,5], z[24,42]) stays clear
and every prop hugs a wall, clear of both doorway lines. `warden_arena` itself is
left deliberately bare per `HALL_DESIGN` §8 — that fight owns its floor.

### D3 (3/16) — no landmark silhouette

The judge measured the whole stronghold as "a pale ~60px smudge, smaller and
lower-contrast than the tether pylons flanking it, which read first ... a single
symmetric mass on a bald hill, one roofline, no towers breaking upward".

That is an arithmetic fact about the authored massing. Of the 18 modules in the
`meadows_hall` prefab, **13 stood between 12.5 m and 14.4 m above the floor** —
so there was effectively one roofline. The only masses that broke it (the great
tower group) sat at the legendary chamber's far **south-west** corner, which is
the furthest point in the complex from the arriving player and is occluded by
every mass in front of it.

Fixed with **scale and placement, not modules**: the count stays 18 and draw
calls stay flat, which the inherited draw-call overrun makes non-negotiable.
Heights above floor now ladder

```
10.8  12.5  14.2   (gatehouse — unchanged, deliberately the LOW near mass)
15.0  16.7         (bailey)
20.7  22.5         (arena)
26.7               (great tower corners)
37.7               (the spire)
```

and the spire moves to the legendary chamber's **north-west** corner, where the
probed west shoulder still backs it (that shoulder runs z 7546–7602, the *north*
half of the site) but the approach can actually see it.

**Stated deviation:** this exceeds `HALL_DESIGN` §3's "+27…+33 absolute" cap for
the tower caps — the spire now tops near +44. That cap produced the building the
judge could not find. The design's stated *intent* — a landmark legible from the
approach — wins over its arithmetic, and the deviation is recorded here and in
`building_prefabs.json` rather than left for the next lane to rediscover.

### D5 + D8 (5/16) — the walls

- **Crenellations were identical cubes at identical spacing** — one constant
  width, height and pitch for every merlon in the fortress. The row now varies
  in all three, seeded off the wall's own position so it is stable across
  rebuilds and saves, and roughly one merlon in nine is a broken crenel (a stub,
  or gone). Same box count, different numbers in it: no draw-call cost.
- **No buttress** — long runs now carry pilaster stubs proud of the wall face,
  seated on the skirt. Decoration-only (`solid: false`) so a buttress can never
  become a ledge or snag a fight, exactly like the slits and the trim.
- **"Sky and grass visible THROUGH the wall"** was a *hole*, not a seam.
  `_build_hall_waist()` closed exactly one of the route's three inter-chamber
  gaps and skipped the one standing in the H-08 frame: `outer_works` ends at
  local z 12 and `courtyard` starts at 18, leaving ~3.6 m of open sky on each
  flank with the passage's own narrow side walls the only thing in it. Now
  **every** consecutive pair on the route is wrapped by rule, with pairs that
  are not stacked along z (the legendary chamber sits *beside* the arena) skipped
  by an overlap test rather than by naming them — so a fourth chamber or a
  resized one cannot silently reopen the hole.

**Not fixed:** D8's "no normal map at close range, the wall is mushy and flat"
and D5's ~2 m visible texture tiling. Both are texture-authoring work on the
shared stone material, and `HALL_DESIGN` §5 is explicit that the tiling number
(`STONE_TILE` 0.28) is hard-won and shared with the works walls. Changing it is a
decision that reaches past this location. Left open, called out in §4 below.

### D7 (6/16) — the keep is a broken mesh with a facade ending in mid-air

Structural, not a bad number. Every kit module in the prefab is authored at
local y = 0, which is the complex **floor** — but the floor stands on an 18 m
skirt, so on any face where the skirt shows (the whole west keep elevation,
which is the stand the judge was looking at) a module's base plane hangs in the
air with the skirt's darker stone visible underneath and behind it.

Fixed generically: every module that stands on the floor now gets a shaft of the
skirt's own stone dropped from its footprint to the skirt foot. A tower now
*meets* the building it stands on. One box each, sharing one cached material.

This is the pass that caught trap #3 above — its first run reported "1 module
foot shaft" and the one module it found was the roof, the only one that must
never get a shaft.

### D6 (7/16) — banners are flat sigil-less quads in the wrong red

**Hue.** The judge's own diagnostic did the work: the same banners read "hot
magenta" under the day key and "a deep muted red" in `H-03-ramp-foot-golden`.
Measured on its frames, H-05's cloth renders at (155,44,60) and (161,46,60) —
red blown a third above the authored albedo by the day sun through the ACES
tonemap and, decisively, **blue above green**, which is what makes the eye call
it magenta. The nominal faction hex `#7a2430` has that B>G relationship baked in
(48 vs 36); at golden-hour intensity it never surfaces, under a bright key it
dominates. The albedo is re-authored to land *on* the intended oxblood after the
tonemap: value down ~15%, blue pulled below green. Team Tether's reserved
oxblood is unchanged as a design fact and `_tether_material`'s girders are
untouched — this is the cloth's albedo, chosen so what the player sees is the
colour the palette always meant.

**Sigil.** A generated compass device — a ring, four cardinal arms, a longer
north arm for orientation — in a new `scripts/world/tether_sigil.gd`, shared by
the Hall's banners and the Sigil Gate so the faction's mark is drawn in one
place. Generated rather than painted because the lane's constraints are explicit
(no Meshy without owner reference art, and Meshy is reserved for hero objects —
a device on a flag is not one). It rides on its own quad, for the reason in
trap #2 above.

### D4 (8/16) — the "sigil gate" has neither sigil nor gate

`road_gate.gd` gains an **opt-in** `faction_dressing` flag, defaulted off, set
only by `_build_sigil_gate()`. The village road gate — which this script was
written for, and for which a plain leaf is correct — is untouched. The Hall's
checkpoint gains two stone piers with capstones, a timber lintel across the top
(this is what makes it a *gate* in silhouette rather than a fence with posts
beside it), and a sigil banner on each pier. Boxes in the Hall's own masonry
vocabulary; no new asset. Nothing carries a collider: the leaf and wings already
seal the line, and a pier with a body on it is a new thing for
`smoke_traversal.gd`'s walk to catch on.

### D11 (15/16) — foliage clipping through the ramp deck

The causeway is 40 m of authored stone laid across ground the scatter was always
free to plant, and nothing ever told the scatter it was there. Five **small**
clearings down the deck's centreline rather than one large one: the same judge
praised H-03's "dense foreground planting" and called the ramp approach one of
the rebuild's real gains, and a single disc over the causeway would have deleted
exactly that. r = 5.0 covers the ~7 m deck and its kerbs and stops there.

### D13–D16 — the StormWall

T1-STORMWALL's fix was called "the cleanest fix of the three sets" and its
diagnosis is not reopened. The complaint is that it **overshot**: "a distant
smoke or haze bank, not a storm ... a single near-uniform neutral grey ... a
diffuse top that just fades out ... no anvil, no shelf, no rain shafts, no lit
rim", sitting *below* the fair-weather cirrus.

Three properties of the old mask caused all of it:

- `smoothstep(0.0, 0.3, v)` faded the top **third** of every slab to nothing, so
  a 150 m slab showed ~105 m of weather with no boundary at all. That is both
  why it had no anvil (D13) **and** why it appeared to sit under the cirrus
  (D15): the geometry's top was already invisible, putting its visible crest near
  10° of elevation against the cirrus band's ~15°. The top is now a
  noise-displaced boundary — billowing, never straight, but a real edge — so a
  slab reads to its authored height.
- The RGB channel was a grey multiplier in all three channels, which is precisely
  "colourless" (D14). It now carries a warm lit rim in the band under the anvil
  (the sun is in the south sky at the day keyframe, so a front standing behind
  the Hall is backlit along its top) and cools toward the base.
- Nothing varied along u but the edge feather, so there were no rain shafts. A
  separate high-frequency-in-u noise now drives shafts through the lower half.

Config adds headroom on top: widths up ~33% and the yaw spread opened from
[-13, 0, 15] to [-22, 0, 24] so the three banks cover the skyline instead of
stacking near the axis (D16). Distances, bases, alphas, colours and the pulse are
untouched — this is reach, not a re-authoring. `_scale_group`, `_cover()` and
`horizon()` are unaffected: the animation path still writes only
`albedo_color.a`.

**Not fixed:** D14's second half — "a storm front that large and that close would
change the light on the thing in front of it". That is a coupling between
`rift_collapse.gd` and the world's sun/ambient, and it would change the light on
every frame in the chapter, not just this one. It belongs with T1-LIGHT, not
here. Called out in §4.

### Coordination with T1-PERF

Cherry-picked `f4e4dbef` unchanged: it gates `_build_keep_parapets()` (the
site's largest single block of boxes, 177) on the four chamber-sides that face
into a 4.2–6 m inter-chamber gap and are occluded by the next chamber's own wall
from every camera position that can exist. It composes with this lane's work —
this lane edits `_dress_exterior_wall`'s merlon row and buttresses, not
`_build_keep_parapets`.

Deliberately a cherry-pick and **not** a merge of `ralph/T1-PERF`: that branch is
mid-flight WIP carrying ~325 files of unrelated survey tooling, and pulling it
wholesale into an evidence branch would mean the frames a blind judge is pointed
at are a blend of two lanes' in-progress states. The consolidation can merge both
branches cleanly.

---

## 3. What this lane did NOT fix, and why

Stated plainly so the next lane does not have to rediscover the boundary. Each
of these is a real, open defect — none is "done".

| Defect | Why not |
|---|---|
| **D8 close-range wall material** ("no normal map, the wall is mushy and flat") and **D5's ~2 m visible tiling** | Texture-authoring work on the *shared* stone material. `HALL_DESIGN` §5 is explicit that `STONE_TILE` = 0.28 is hard-won and deliberately shared by both kits and the works walls, and its header records the exact failure a re-pick caused before. Changing it reaches past this location, so it wants its own lane with its own before/after at several ranges. |
| **D9 far terrain bald and splat-seamed**, **D10 ground scatter on a grid** | World-level ground/scatter systems (`T1-GROUND-3`'s territory), not the fortress. The judge filed them under the Hall set because that is where it saw them, but the fix is in the scatter rules and the splat maps, and doing it here would collide with that lane. |
| **D12 night is unresolved** (moon has no disc, braziers throw no pooled light) | This is a lighting setup — `world_look.gd`'s night keyframe and the brazier light ranges — and `T1-LIGHT` owns it. Changing the night key here would change every night frame in the chapter to fix one stand. |
| **D14's second half** — "a storm front that large and that close would change the light on the Hall in front of it" | Correct, and it is a coupling between `rift_collapse.gd` and the world sun/ambient. Same argument: it would alter the light on every frame in the chapter. The *structural* half of D14 (colourless, no lit rim) is fixed here. |
| **D3's "move the pylons out of the approach sightline"** | The judge's own suggested fix, and I did not take it. The pylon line is authored to converge on the Hall deliberately (`HALL_DESIGN` §3: "the pylon line converges toward the tallest mass") and the judge separately praised the pylons as the one thing at this site that reads correctly. Raising the fortress so it out-reads them is the fix that keeps both; moving them is available if raising proves insufficient. |
| **`stronghold_outer_watch` / `stronghold_checkpoint` bodies** | Same Meshy idiom as the three reverted, but they stand outside the Hall and in no frame the judge read. Reverting the whole cast is an owner/T3-INSTALL decision about the project's humanoid direction, not a call this lane should make unilaterally. |

## 4. Reproducing the evidence

```bash
# frames (NEVER --headless with a rendering driver: hangs forever)
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_judge_capture_hall.gd -- --out=res://shots/t1hall3

# the numbers behind the claims above
python3 tools/_t1hall3_measure.py shots/t1hall3 <a-previous-set>

# draw calls at the Hall
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/perf_render_stats.gd -- --label=t1hall3 --views=hall_approach

# the route must stay green
godot --headless --path . --script tests/smoke_stronghold.gd
godot --headless --path . --script tests/smoke_boss.gd
godot --headless --path . --script tests/smoke_gate_e_finale.gd   # intermittent; re-run before believing a red
```

The capture tool now runs `tools/capture_check.gd` at every stand and fails the
run on any exterior-stand problem, so a set that silently lost the grass field
or buried a camera cannot be committed as evidence without the exit code
saying so.

## 5. Files

| File | What changed |
|---|---|
| `scripts/world/stronghold.gd` | `causeway_surface_y()` (D1); `_ground_hall_massing()` + `_module_bounds()` (D7); generalised `_build_hall_waist()` (D8); merlon variation + buttresses (D5); banner hue + device (D6) |
| `scripts/world/tether_sigil.gd` | **new** — the generated compass device and banner cloth, shared by the Hall and the Sigil Gate |
| `scripts/world/road_gate.gd` | opt-in `faction_dressing`: piers, capstones, lintel, sigil banners (D4) |
| `scripts/world/playground_world.gd` | sets `faction_dressing` on the Sigil Gate only |
| `scripts/world/rift_collapse.gd` | storm mask: anvil, lit rim, rain shafts (D13, D14) |
| `data/config/building_prefabs.json` | the massing height ladder and the spire's move (D3) |
| `data/config/stronghold.json` | 18 courtyard props (D2) |
| `data/config/rift_collapse.json` | storm reach and yaw spread (D15, D16) |
| `data/config/bands/band5_stronghold_approach/trainers.json` | three body overrides reverted (D2) |
| `data/config/bands/band5_stronghold_approach/vegetation.json` | five causeway clearings (D11) |
| `tools/_judge_capture_hall.gd` | H-04 stands on the deck; `capture_check` at every stand |
| `tools/_t1hall3_measure.py` | **new** — re-measures the judge's own quantities |

## 2. Evidence — what actually moved

Frames in `shots/t1hall3/`. Numbers from `tools/_t1hall3_measure.py`, which
re-measures on the new set the same quantities JUDGE-5 measured on the old one.
The "before" column is measured on the judge's own frames
(`ralph/reports/T1-HALL-REBUILD/shots/`), not quoted from its prose.

| Defect | Before | After | |
|---|---|---|---|
| **D6** banner hue | (160, 51, 62) — blue **above** green | (136, 56, 42) — blue **below** green | fixed |
| **D8** see-through wall strip | 17.8% sky-like pixels | **0.0%** | fixed |
| **D3** built mass on the approach bearing | 124 px | 186 px | improved |
| **D5** wall patch std-dev | 27.6 | 29.8 | **still short of the design's own 35** |

Build instrumentation, same run:

```
[stronghold] massing grounded: 17 of 35 module foot shaft(s) to skirt y=-18.0
[stronghold] waist: 3 inter-chamber gap(s) wrapped on both flanks
```

17 of 18 modules grounded, roof correctly excluded (D7). Three inter-chamber
gaps wrapped where the previous build wrapped one (D8).

**Route intact.** All three required smoke tests pass — `smoke_stronghold`,
`smoke_boss`, and `smoke_gate_e_finale`, the last on its first attempt despite
being the intermittent one.

### Read by eye, at the stands

- **`H-04-gate-mouth` is a frame of the gate.** For the first time: the deck
  underfoot, the jambs with their banners either side, the arch overhead, and
  through the opening the courtyard wall and the towers above it against sky.
- **`H-02b-sigil-gate-raised`** shows the massing working — the roofline now
  breaks repeatedly and the spire stands clear of everything under it, where
  the same stand previously showed one symmetric block on a bald hill.
- **`H-07-courtyard`** — the anime figure is gone; the oxblood grunt shares the
  world's rendering idiom again, and the contradicting cast shadow goes with it.
- **`H-05-east-flank`** — buttresses break the wall plane, the merlon row varies
  and carries broken crenels, and the cloth reads as oxblood rather than magenta.
- **The storm** reads as weather with a defined crest and visible rain shafts,
  and the five Hall frames that carried the old hard-edged slabs no longer do.

### What the frames also exposed — four defects caught in this lane, three mine

Recorded because the discipline that caught them is the transferable part.

1. **The sigil was rendering inside the cloth.** `proud` is measured from the
   banner holder's origin and the panel box is not centred on it, so
   `BANNER_CLOTH_T * 0.62` buried the device. It rendered as *no sigil* — the
   exact defect I had claimed to fix.
2. **The buttresses were black bars.** `_stone_dark()` against the wall's own
   tone reproduced the very failure JUDGE-5 named on that wall — "crossed beams
   stuck on a flat face" — in a new shape.
3. **The foot shaft bought a second seam.** Grounding the modules in the skirt's
   dark cobble fixed the floating facade and created a fresh
   dark-under-pale seam a metre lower, which is the other half of D7.
4. **D11 was never fixed by the first attempt.** Clearings cull only layers
   flagging `cleared_by_clearings`; grass, flowers and path stones are
   deliberately exempt so a clearing does not bald the meadow — and the things
   growing through the deck are grass and flowers. `footprints` is the
   mechanism, and `scatter_rules.gd` says so in a comment written the last time
   this happened (grass growing through Grandpa's floor).

### One finding that is not this lane's to close

**D3 is measurably worse on current integration than the verdict describes, and
the massing is not why.** At the H-01 stand the fortress is not short — it is
*occluded*. Band 5's treeline stands between the stand and the Hall and hides it
outright. That treeline arrived with T1-GROUND-3 (`21fd47f0`, `vegetation.json`
+ `terrain_playground.json`), which landed on `LAND-0830H` **after** JUDGE-5's
frames were captured, so the judge never saw it.

Height cannot answer occlusion: the blocking canopy at ~200 m subtends more than
the Hall does at 400 m, so out-topping it would need a ~66 m tower, which is not
a fortress. This lane opened a sightline instead — five clearings along the road
the player walks, on the camera-to-Hall bearing, which cull canopy while leaving
grass and flowers untouched.

**That edits Band 5's vegetation, which is T1-GROUND-3's territory.** It is
flagged here and in the config's own `_why` rather than done quietly. If that
lane wants the canopy back, the alternatives are moving the H-01 stand, or
accepting that the fortress is revealed at the treeline rather than from the
crest. Both are legitimate composition calls and both want an owner rather than
a silent revert by whoever touches this next.

## 6. D3 at 400 m — the honest limit, with the arithmetic

The massing is fixed. `H-02b-sigil-gate-raised` and `H-03-ramp-foot` show a
fortress with a broken roofline, stacked masses and a spire standing clear —
against the same stands that previously showed one symmetric block. That part of
D3 is answered.

**At the H-01 stand it is improved but it does not dominate, and it cannot be
made to at that range without ceasing to be a castle.** Worth stating with
numbers rather than leaving the next lane to re-derive them. Against the H-01
eye (ground ≈ −5, +8 m), in a 1280×800 frame at 70° horizontal (≈17 px per
degree of elevation):

| mass | top | distance | subtends | on screen |
|---|---|---|---|---|
| gatehouse flanker | +20.4 m | 386 m | 2.58° | ~44 px |
| arena tower | +26.9 m | 477 m | 2.87° | ~49 px |
| **spire** | **+43.9 m** | 476 m | **4.91°** | **~84 px** |

So the tallest thing in the chapter is an 84 px object at this stand — and the
masses that would carry a "landmark" read are the *far* ones, because the route's
own chamber order puts the great tower 100 m behind the gatehouse and that order
is gameplay, not composition. Doubling the spire again would buy the frame and
lose the building.

Three honest options, none of which this lane should pick unilaterally:

1. **Accept the 400 m read as a distant skyline.** This is what `HALL_DESIGN` §3
   actually asks for in its own words — "a skyline, not a building" — and the
   frame now delivers stacked masses at that range where it previously delivered
   an occluded smudge. The acceptance item that does *not* survive is §11.2's
   "roofline breaks ≥ 4 times **at H-01**"; it demonstrably does break ≥ 4 times,
   just at H-02b's range rather than H-01's.
2. **Move the landmark stand in to ~150–200 m**, where the building genuinely
   dominates, and keep H-01 as an "approach context" frame rather than the
   landmark test.
3. **Re-site the great tower toward the north end** so the tall mass leads. That
   is a chamber-layout change and therefore a route change — `smoke_stronghold`,
   `smoke_boss` and `smoke_gate_e_finale` all walk that order — so it is a
   deliberate design decision, not a tuning pass.

The sightline clearings (§2) were needed either way: without them the fortress
was not small at H-01, it was *invisible*.

## 7. Performance

Measured with `tools/perf_render_stats.gd` at the `hall_approach` stand — the
one that looks **at** the Hall (yaw 180). Not `stronghold_approach`, which sits
at the same point at yaw 0 and looks away from it; `docs/PERFORMANCE_BUDGET.md`
§0.5 records that as a real mistake a previous lane built past.

```
view                     draw calls     primitives      objects
hall_approach                  3048       23791675         3374
```

| | draw calls |
|---|---|
| T1-HALL-REBUILD, as JUDGE-5 saw it | 2743 |
| after T1-PERF's keep-parapet fix (cherry-picked into this branch) | 2665 |
| **this lane, measured** | **3048** |
| ceiling (`docs/PERFORMANCE_BUDGET.md` §0.5) | 4000 |

**+383 draw calls for the whole pass, at 76% of the ceiling, with ~950 of
headroom left.**

Two notes on honesty rather than on the number:

- **This was measured before the last three commits** (yard banners, the gate
  piers' stone, the footprint renumber). Those add roughly 50–60 boxes between
  them, so the shipping figure is ~3100 and the conclusion is unchanged — but
  it is an estimate on top of a measurement, and the next lane should re-run
  rather than quote it.
- **The original 2463 ceiling this lane was briefed against was wrong**, and the
  correction arrived mid-lane. D3's silhouette was therefore solved with scale
  and placement rather than added modules — chosen specifically to spend nothing
  — which turns out to have been unnecessarily frugal. There is real room to add
  the mass and dressing D3 and D5 still want; §6's three options are all
  affordable.
- **No container here has ROG Ally hardware.** This is a draw-call count against
  a reasoned ceiling, not a frame-rate claim. The budget document says the same
  about itself.

## 8. Correction — a wrong conclusion this lane published, and the method error behind it

Earlier in this lane I recorded, in a commit message and in §2 above, that
`H-03-ramp-foot`'s missing bank planting was **a capture artifact, not a
content regression**, on the evidence that the golden variant from the identical
camera position measured 55% green cover against the day frame's 5.5%.

**That was wrong, and the frames say so.** Cropping the same region out of both
and looking at it shows the two frames contain the *same bare terrain*; the only
difference between them is exposure. A green-pixel percentage tracks how bright
the ground is, not whether anything is growing on it — the day key blows that
slope out to (181,182,145) and the golden key leaves it olive, and my test
scored the second as "vegetated".

The regression was real and it was mine. `footprints` was the right mechanism
for D11, but at r=4.5 on the deck centreline it covers x 3–13 against a deck
only 7 m wide, so it stripped the banks either side — and the near-field bank
planting is content JUDGE-5 explicitly praised in this exact frame. Held against
the judge's own H-03, its bank carries grass blades, leafy plants, flowers and
pebbles; mine was bare ground. Fixed by sizing the discs to the deck (r=3.0 on a
4 m pitch, so the covered strip pinches to ±2.24 m between centres) and deleting
the five r=5 clearings, which could never have culled grass and were doing
nothing but collateral damage.

Three things worth carrying out of this:

1. **A colour-ratio metric is not a test for vegetation.** It is a test for
   exposure. Where a claim is about whether something is *present*, crop the
   region and look at it; keep the numbers for things that are genuinely
   photometric, like D6's hue relationship.
2. **I nearly fixed the wrong thing twice on this one defect** — first with a
   mechanism that could not work, then with a correct mechanism at a size that
   destroyed praised content. Both passed a plausible-sounding check.
3. **The settle-frame work in §2 was chasing a phantom.** Doubling the settle
   changed nothing because nothing was ever unsettled. The change is harmless
   and the `--only=` filter it came with is genuinely useful, but the reasoning
   that produced it was built on the same bad metric. The standing note about
   `capture_check` having no test for a partially-streamed field is still true
   and still worth doing; it just is not what happened here.
