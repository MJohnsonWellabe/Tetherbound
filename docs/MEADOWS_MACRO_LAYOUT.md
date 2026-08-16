# MEADOWS MACRO LAYOUT — the corridor

**`OW5A`, 2026-08-16.** The authored top-down map plan
`ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §5 asks for before terrain
production begins. This document decides the **shape**. It moves no terrain and
writes no gameplay code — `OW5B`/`OW5C`/`OW5D` do that.

**Model note, recorded honestly:** `OW5` is tagged `model: fable` and §5 says
"START WITH FABLE". The owner has directed that fable-tagged items run at
**opus** for now because he has no Fable usage left. This document was written
at opus. It did not run at its tagged tier and nothing here should be read as
having had a Fable pass.

Companion decisions: `docs/decisions/D50` (the footprint and the 40-minute
target) and `docs/decisions/D51` (the edge grammar that replaces the radial
perimeter).

---

## 0. The directive being implemented

Owner, in the `OW5` backlog entry:

> The meadow needs to read as a long journey away from home ending at the
> stronghold. It's a long trail working progressively further from Grandpa's
> house. You can go off the trail for different tasks. It can wind and fork and
> whatever but this should be the general layout. Walking end to end should take
> several in game days so you have to camp along the way.

Owner, superseding that entry's "the whole area should be a big square", in
conversation 2026-08-16:

> the world should be long but can be narrow with broken land or sea off the
> path in either direction. it doesn't have to be a giant square. it should be
> long as I've stated but can be significantly less wide. like maybe it's five
> minutes of walking from side to side.

> a day from midnight to midnight should take about 10 minutes. a walk from the
> end of the meadows to the other end should take 40 minutes.

Everything below is that, plus §5's quality bar and the spec's bands.

### The one place this and §5 have to be reconciled

§5 says *"Do not target map size for its own sake. Do not force a 10–20 minute
uninterrupted straight-line walk merely to create scale."* The owner has since
asked for forty. These are not actually in conflict, and the reconciliation is
the whole design of this document: **§5 forbids empty scale, not scale.** The
forty minutes is forty minutes of *trail* — winding, forking, and carrying an
authored beat every couple of hundred metres — not forty minutes of holding
forward. §5's density rule (§4 below) is what makes the difference, and the
narrow corridor is what makes the density affordable. Where the two are read as
disagreeing, the owner's later word wins; where §5 sets the quality bar for how
that length is filled, §5 wins.

---

## 1. Measurements, not estimates

Everything in this section was measured on this container by
`tools/_probe_corridor_footprint.gd` and `tools/_probe_terrain_streaming.gd`,
both committed alongside this document. **No full bake was run** — a 36-to-48
region bake is `OW5B`'s job and would have consumed this item's whole budget.
The unit costs below are measured; the totals are extrapolations and are
labelled as such.

### 1.1 The bake cost, finally re-measured

The repo carries three conflicting bake times (5.5 / 12 / 15 min) and none was
re-measured after the river landed. Measured per-pixel cost of
`build_playground_terrain.gd`'s two passes (colour+height, then control):

| tile | µs/pixel | colour pass | control pass |
|---|---|---|---|
| busy centre (village, river, rises all in range) | **2584** | 1270 | 1315 |
| far field at (900, 900), only the noise layers answer | **2523** | 1228 | 1295 |

The probe validates against a known figure: 262,144 px × 2584 µs = **11.3
minutes**, which is the repo's "12 min" number and not its "5.5 min" one. Treat
5.5 as stale.

Projected, at 2584 µs/px:

| footprint | pixels | field work |
|---|---|---|
| current 512 m @ 1.0 (512×512) | 262,144 | 11.3 min |
| 6144 × 1536 @ 2.0 (3072×768) | 2,359,296 | 102 min |
| **8192 × 1536 @ 2.0 (4096×768)** | **3,145,728** | **135 min** |
| 8192 × 1536 @ 1.0 (8192×1536) | 12,582,912 | 542 min |

**The busy tile and the far-field tile cost the same to within 2.4%.** That is
the most useful thing this probe found. The bake's cost is not the river, the
carves or the drains — those are cheap distance rejections. It is the noise
evaluation plus GDScript call and dictionary overhead in the innermost loop:
`slope_degrees_at` calls `height_at` four more times, each of which re-reads
`_config.get("hills")`, `_config.get("detail")`, `_config.get("valley")` and so
on from a Dictionary, and `rock_bias_deg` runs a ridged FBM with a domain warp
on top.

Two consequences, both for `OW5B`:

1. **Bake cost scales with pixel count and nothing else.** You cannot buy it
   back by authoring fewer features, and adding features to fill the corridor
   costs almost nothing at bake time.
2. **There is a large, unclaimed optimisation available.** Hoisting the
   per-call `_config.get(...)` lookups in `playground_heightfield.gd` into typed
   fields at `_init` is a mechanical change with no behaviour risk, and the hot
   path does several of them per sample. This is not measured, so do not treat
   the multiplier as known — but 135 minutes of one-shot bake is worth an hour
   of hoisting before running it, because `OW5B` will not run the bake once.

### 1.2 The carve-resolution question — 2.0 m spacing does NOT destroy the carves

This was the measurement most likely to kill the footprint, and it did not.

Every blocker on this map is a `_carve_depth` trench whose *walls* are the
blocker. Two limits, both real and both already tested:

- `scenes/player/player.tscn` `floor_max_angle` 0.7854 rad = **45°**.
- `scenes/creatures/creature.tscn` gives every creature **55°**, and
  `riding_controller._apply_climb_limit` raises the ridden legendary's body to
  **60°**. `tests/smoke_riding.gd` and `tests/smoke_boss.gd` both assert the
  spoke walls stay above that. **60°, not 45°, is the number a spoke wall has to
  clear**, or riding walks out of the Meadows and breaks D23's carve-out.

The probe builds the piecewise-bilinear surface Terrain3D would actually
reconstruct from samples at each candidate spacing and walks transects over
*that*, rather than reading the analytic field — reading the field would report
the angle the config asks for, which is the number that was never in doubt.

Steepest reconstructed wall angle, by transect and spacing:

| transect | 1.0 m | 1.5 m | 2.0 m | 2.5 m |
|---|---|---|---|---|
| river @ north dry gorge | 78.0° | 77.0° | 76.2° | 76.5° |
| river @ mill narrows (`rim` 3.4, the thinnest on the map) | 81.5° | 80.1° | 80.3° | 75.6° |
| river @ south broad | 70.6° | 70.3° | 69.5° | 68.2° |
| south gully (South Bridge crossing) | 77.9° | 76.6° | 76.5° | 70.2° |
| spoke `river_gorge` | 76.3° | 75.9° | 75.0° | 74.2° |
| spoke `storm_road` ravine | 81.0° | 80.4° | 79.1° | 75.6° |
| spoke `cliff_road` notch | 77.1° | 77.8° | 76.1° | 75.5° |

**Going from 1.0 m to 2.0 m costs 1–2 degrees of wall.** Every carve stays 15°
or more past the ridden 60° limit. Even the mill narrows, whose `rim` is 3.4 m
and therefore under two samples wide at 2.0 m spacing, holds 80°. The footprint
decision does not have to fight the carves.

Three honest caveats:

- **Degradation is phase-dependent, not monotonic.** 2.5 m is sometimes *better*
  than 2.0 m in the table above. That is grid phase — where the sample lines
  happen to fall relative to the trench — and it is a ±few-degree band, not a
  trend. It means a carve that measures fine at one offset can measure worse
  after the world origin moves. `OW5B` must re-run this probe **after** the
  corridor's origin is fixed, not before.
- The *vertical extent* of wall steeper than 60° does shrink, most at
  `cliff_road` (12.7 m at 1.0 m spacing → 9.8 m at 2.0 m) and `river @ south
  broad` (8.3 m → 7.0 m). The wall is still a wall; there is simply less margin
  for the next person who tunes a `rim` value.
- The probe's own "verdict" column compares blocked extent against rim-to-floor
  depth over the whole transect, which for the north gorge includes
  `rises.peaks[0]`'s flank rather than the carve. Read the angle column; the
  verdict column is only meaningful where transect depth ≈ carve depth.

**Rule for `OW5B`, from this measurement:** at 2.0 m spacing keep every carve's
`rim` at **≥ 2 × vertex_spacing** (i.e. ≥ 4.0 m). Today's narrows sits at 3.4 m
and survives; it is the only one that does, and it should be widened to 4.0 m
when the crossing is re-sited, which costs nothing because the `south_bridge`
prefab's 18.4 m span clears a 14 m gap and 4.0 m rim makes that 15.2 m.

### 1.3 Two engineering defects the corridor exposes

Both are `OW5B`'s to fix; recorded here so they are not discovered at bake time.

- **`build_playground_terrain.gd:44` validates the wrong thing.** It asserts
  `world_size % region_size != 0`, but a region covers `region_size ×
  vertex_spacing` **metres**. At spacing 2.0 that check passes for
  `world_size = 6400` (6400 % 256 == 0) while 6400 / 512 = 12.5 — regions
  straddle exactly the way the check exists to prevent. It must become
  `world_size % (region_size * vertex_spacing)`.
- **The bake is square-only.** `world_size` is one number, `size = world_size /
  spacing` is used for both axes, and `import_images` centres the maps on the
  world origin. A corridor needs an explicit two-axis extent. The layout below
  is therefore specified as **authored world bounds**, not as a centred square:
  `x ∈ [-768, +768]`, `z ∈ [-512, +7680]`.

---

## 2. The footprint

**8192 m long × 1536 m wide**, `region_size` 256, `vertex_spacing` **2.0** →
512 m per region → **16 × 3 = 48 regions**. Bounds `x ∈ [-768, +768]`,
`z ∈ [-512, +7680]`. Long axis is **+Z**, running south, away from home.

### The arithmetic, verified

`data/config/art.json` `day_length_seconds = 600`. `data/config/movement.json`
`walk_speed = 5.0`, `sprint_speed = 8.6`.

- 40 min at 5.0 m/s = **12,000 m of trail**. The authored spine in §3 measures
  **11,594 m** = **38.6 min walking** = **3.86 in-game days**. Camping is
  forced, which is what `camp` has been waiting for.
- Sprinting the whole way would be 22.5 min, but `stamina.sprint_drain_per_
  second` 12 against `max` 100 buys 8.3 s of sprint per 5 s of recovery, so the
  sustained rate is much nearer the walk. Riding (Band 3/4) is the intended
  fast return, per spec §3 Band 4.
- 5 min side to side at 5.0 m/s = **1500 m**. 1536 is that, rounded up to three
  whole regions.

### Why not the coordinator's 6144 × 1536

6144 m of corridor for 12,000 m of trail is **tortuosity 1.95**. A path that
long over that little advance has to swing roughly ±500 m every 600 m of
progress — which consumes the entire width. The width would stop being "off the
trail for different tasks" and become the trail. 8192 m gives **tortuosity
1.53**, and the authored spine's x range is **−430 … +450**, leaving over 300 m
of genuinely off-trail land on both flanks the whole way down. That is the
owner's "off the path in either direction" actually existing.

The cost of the extra 2048 m is 33 more minutes of one-shot bake (135 vs 102)
and 3.1 km² more land to keep dense. The first is cheap and offline. The second
is the real price and §4 is how it gets paid.

### What this is, in area terms

12.58 km², against today's 0.262 km². **48× the current world.** Hold that
number: it is what §5 below is about.

---

## 3. The spine

Coordinates are world metres, `(x, z)`, in the existing frame. **Band 0 and the
whole of the shipped village do not move at all** — §0.6 says relocate shipped
work rather than reconstruct it, and the cheapest relocation is none. Grandpa's
house, the village square, the well, the workshop, the cottages, the junction
signpost, the road gate, the Practice Meadow and The Rise all keep their exact
current coordinates. Everything from the South Bridge southward moves.

| band | trail m | z from | z to | corridor advance | tortuosity |
|---|---|---|---|---|---|
| 0 — Homebound | 96 | −40 | −16 | — | — |
| 1 — Lower Meadows | 2,384 | −16 | 1,360 | 1,376 | 1.73 |
| 2 — Stone & Root | 2,653 | 1,360 | 3,180 | 1,820 | 1.46 |
| 3 — The River Lock | 2,372 | 3,180 | 4,760 | 1,580 | 1.50 |
| 4 — Upper Meadows / Ironwood | 3,436 | 4,760 | 7,000 | 2,240 | 1.53 |
| Stronghold approach | 651 | 7,000 | 7,560 | 560 | 1.16 |
| **total** | **11,594** | −40 | 7,560 | 7,576 | **1.53** |

Band 0's 96 m is not an error and not a failure of the 20–40 minute target: the
spec's Band 0 is waking up, Grandpa, the starter, the first catch and reaching
the village. It is dialogue and a first fight, not walking. Nothing about it
changes.

### 3.1 Waypoints

Authored polyline, band by band. These are the **spine**; the loops in §3.2
hang off them and are not counted in the 11,594 m.

**Band 0 — Homebound** (unchanged from today)
```
(-22,-16) (-4,-13) (10,-10) (18,-24) (30,-40) (22,-26) (27.5,-16)
```
House → village square → Practice Meadow → road gate. Existing
`paths.routes` and `flats` already describe this exactly.

**Band 1 — Lower Meadows** — farm paths, oak grove, starter stream, the pond,
the trainer circuit, ending at the South Bridge
```
(27.5,-16) (14,20) (8,90) (-40,180) (-120,270) (-230,330) (-360,400)
(-430,510) (-330,590) (-190,650) (-50,700) (90,760) (230,830) (360,910)
(430,1020) (330,1130) (180,1200) (30,1250) (-40,1310) (0,1360)
```
The western swing (x −430 at z 510) is the pond and the starter stream; the
eastern swing (x +430 at z 1020) is the oak grove and the trainer road. The
trail crosses the corridor twice, which is what gives Band 1 its 1.73 — the
highest on the map, and correct there: the first two thousand metres should
feel like wandering the fields around home, not marching.

**Band 2 — Stone & Root** — Old Quarry, ridge trails, abandoned ranger camp,
Burrow Warrens, deeper oak forest
```
(0,1360) (70,1450) (190,1540) (310,1660) (400,1800) (330,1950) (180,2050)
(20,2130) (-150,2210) (-310,2320) (-420,2470) (-330,2630) (-180,2730)
(-40,2840) (90,2960) (60,3090) (0,3180)
```
Quarry east at (400,1800); Warrens mouth west at (−420,2470). The band is a
single long S, so the two dungeons sit on opposite flanks and the ridge trail
between them is the connective tissue.

**Band 3 — The River Lock** — river approach, Tether Relay Station, Old Mill
Crossing, far bank
```
(0,3180) (-110,3290) (-160,3420) (-60,3520) (90,3600) (230,3670) (350,3760)
(280,3900) (130,3980) (-30,4060) (-150,4170) (-150,4235) (-100,4350)
(30,4460) (160,4570) (110,4690) (0,4760)
```
The river runs **across the corridor** at z ≈ 4,200 (see §5). The crossing is
the two waypoints at (−150,4170) → (−150,4235). The relay is the eastern lobe
at (350,3760), on the near bank, which is what makes it a place you must clear
before the gate opens rather than a detour past it.

**Band 4 — Upper Meadows / Ironwood** — old-growth, wind ridge, high pasture,
ruined watchtower, three regional captains
```
(0,4760) (-140,4870) (-300,4990) (-420,5140) (-330,5310) (-170,5410)
(0,5490) (170,5590) (330,5700) (450,5860) (390,6040) (230,6140) (60,6230)
(-110,6340) (-280,6460) (-210,6620) (-70,6720) (80,6820) (40,6930) (0,7000)
```
Ironwood old-growth west at (−420,5140); Field Captain at (170,5590); wind
ridge climb east at (450,5860); high pasture at (60,6230); ruined watchtower
and Ridge Captain west at (−280,6460). Riverwatch Captain sits off-spine on
the Band 3/4 seam (§3.2).

**Stronghold approach**
```
(0,7000) (-80,7120) (-20,7250) (80,7370) (20,7480) (0,7560)
```
Deliberately the straightest band on the map (1.16). After eleven kilometres
of winding, the last six hundred metres reading as a direct approach is the
arrival.

### 3.2 The regional loops

§5 is explicit that the mental model is "a connected adventure through several
real places", not "a road with content placed beside it". Each band therefore
opens into a loop that leaves the spine and rejoins it. These are roads in the
`road_polylines()` sense — painted soil, vegetation held off, path stones,
verge fringe — not invisible suggestions.

| band | loop | leaves | rejoins | why you take it |
|---|---|---|---|---|
| 1 | **Pond circuit** | (−360,400) | (−190,650) | the mill, the ranger station, the water species, and the first place you would choose to camp |
| 1 | **Oak grove ring** | (230,830) | (330,1130) | Duskhush at night, the trainer circuit's second fight, wood at scale |
| 2 | **Quarry rim overlook** | (310,1660) | (330,1950) | the whole quarry floor read from above before you walk into it; the drained ground is visible as a shape |
| 2 | **Ranger camp spur** | (−150,2210) | (−310,2320) | the abandoned camp, and the first evidence Team Tether has been moving material |
| 2 | **Warren undertrail** | (−420,2470) | (−180,2730) | the dungeon's second mouth, so the Warrens are a through-route once cleared, not a cul-de-sac |
| 3 | **Relay approach loop** | (230,3670) | (130,3980) | the compound seen from its own picket line before you are inside it |
| 3 | **Near-bank river walk** | (−30,4060) | (−100,4350) *(gated)* | walks the near bank downstream, shows the far side you cannot reach yet, and dead-ends at the crossing you have to earn |
| 4 | **Wind ridge traverse** | (330,5700) | (230,6140) | the highest ground in the Meadows and the vista that shows the whole journey behind you |
| 4 | **High pasture loop** | (60,6230) | (−110,6340) | Meadowhart herd, the riding payoff, open ground after the old-growth |
| 4 | **Watchtower spur** | (−280,6460) | (−210,6620) | the ruin, the Ridge Captain, and the first clear sight of the stronghold |

Two more reconnects that are not loops but shortcuts, both one-way until
earned, both §5's "alternate return routes":

- **Quarry haul road** — (400,1800) back to (8,90), the old cart road the
  quarry's stone left on. Opens when the quarry is cleared. Turns a 2.4 km
  return into 600 m and is the first time the world rewards knowing it.
- **River ferry landing** — (−100,4350) to (90,760). Not a fast-travel menu; a
  boat that exists at one place and goes to one other place, unlocked with the
  crossing.

---

## 4. Interesting-decision density — the budget that makes 12 km legal

§5: *"Long stretches of simply holding forward through procedural scenery are a
failure even if the terrain is visually attractive."* This is the constraint
that the length has to buy its way past, so it gets a number.

**One authored beat every 150–250 m of spine.** At 5 m/s that is something
worth noticing or deciding every 30–50 seconds. Over 11,594 m that is **46–77
beats on the spine**, plus each loop carrying its own.

A beat is any of §5's list: a fork, a resource opportunity, creature behaviour,
a vista, environmental story, a ruined object, an alpha silhouette, an optional
path, a hidden cache, a landmark, a climbable rise, an NPC, a traversal
shortcut, a safe camp location, a combat risk, a gatherable cluster.

Two rules that follow, and they are the ones that will actually get broken:

- **No spine segment longer than 250 m may pass without a beat.** This is
  checkable from data and should become a test in `OW5C`/`OW5D`: walk
  `road_polylines()`, and for each 250 m window assert at least one entry from
  the beat sources (`harvest.json`, `spawns.json`, `props.json` clusters,
  `map_landmarks.json`, `trainers.json`, the fork points above) falls within
  40 m of it. A layout document nobody can fail is a layout document nobody
  follows.
- **Beats are not evenly spaced.** 250 m is the ceiling, not the target. Bands
  cluster: the quarry rim and the relay picket should be dense, and the wind
  ridge traverse should be sparse on purpose so the vista lands.

The corridor is what makes this affordable. 12.58 km² of narrow land has far
less interior than a square of the same length, and 1,100 m of the 1,536 m
width is either flank (§5) rather than fillable interior. The land that has to
carry beats is roughly the 400 m band the trail wanders within, not the whole
footprint.

---

## 5. Regional identity — five real places, one biome

Still Meadows. Never a second biome (`CLAUDE.md` hard rule; D23's carve-out).
Differentiated the way §5 asks — landform, vegetation structure, openness, path
geometry, water, rock exposure, elevation, ruins, human occupation.

**Band 1 — Lower Meadows.** Open, low relief (the existing `hills` layer,
amplitude 15), hedged field boundaries, wide soft-edged paths, the pond and the
starter stream. Human occupation is *lived in*: fences that are maintained, a
working mill, a ranger station with someone in it. Vegetation: scattered
standards and hedgerow, high sky. This is the band that must not change much,
because it is the shipped one.

**Band 2 — Stone & Root.** Rock exposure arrives. The `rock_form` layer that
today only dresses the rises becomes the band's signature: ribbed, terraced
grey stone breaking through the turf, quarried faces, spoil heaps. Paths
narrow and start to switchback. Vegetation goes from scattered to *closed* —
deeper oak, low canopy, less sky. Human occupation is *abandoned*: the quarry
is worked out, the ranger camp is empty, and D41's drained ground is the first
thing in the world that is visibly wrong.

**Band 3 — The River Lock.** Water is the whole identity. The corridor's width
is crossed by the river; the land is low, wet, reed-edged, with the gorge
walls as the only steep thing for a kilometre. Openness returns but at ground
level rather than upward — long sightlines along the bank, none across it.
Human occupation is *occupying*: the relay compound is lit, fenced, powered
and staffed, and it is the first place in the Meadows that Team Tether has
actually built rather than broken.

**Band 4 — Upper Meadows / Ironwood.** Elevation. The band climbs roughly 60 m
across its length, so the player is looking back down at where they came from
for the first time. Old-growth Ironwood is the densest vegetation on the map
and the wind ridge is the emptiest; the contrast between them is the band's
shape. Human occupation is *contested*: patrol camps, a ruined watchtower,
three captains, and a stronghold on the skyline that gets closer every time
the trail crests.

**Stronghold approach.** Everything narrows. Straight, walled, drained, dead.
The only band with no loop and no optional content, because that is the point.

Spec §13's wild species fall out of this directly: lower fields
(Bramblebun/Mudsnout/Pipwing) in Band 1, grove (Trailpup/Duskhush/Burrowback)
in Band 1's oak ring and Band 2, quarry/warrens (Burrowback/Mudsnout/Tuskroot)
in Band 2, river (Paddlenewt/Mosshell/Brooktail/Reedwing) in Band 3, upper
ridge (Galecrest/Meadowhart/stronger Trailpup) in Band 4.

### Camps

§5: not a chain of free hotels. Authored camp locations are **places you want
to stop**, not services. The trail's natural stopping points fall out of the
day arithmetic — 3.86 in-game days at 10 minutes each means roughly a night
every 3,000 m of trail — so four are authored, each a different kind:

| at | kind | what it is |
|---|---|---|
| (−330,590) | safe clearing | flat, sheltered, beside the pond. Nothing built. You bring your own fire. |
| (−150,2210) | abandoned ranger camp | a ring of stones, a collapsed lean-to, and someone's kit. Salvage, not shelter. |
| (−100,4350) | ruined camp | the far bank, burned by Team Tether. Story, and a reason not to sleep there. |
| (60,6230) | story camp | high pasture, the Meadowhart herd, and the last flat ground before the stronghold. |

None of them restores anything on its own. `scripts/build/camp.gd` stays the
only thing that makes a camp work, and the player still has to build it. What
these four provide is the *decision* — "is this where I stop tonight?" — which
is what makes the campfire mean anything after the first night.

---

## 6. The edge grammar

This replaces `scripts/world/world_perimeter.gd`'s **circular ring at `RADIUS`
235**, which cannot survive a corridor: it is one continuous ground-sampled
polyline of 40 segments × 18 spans, generated as a closed circle, with its
collision boxes derived from the same points. See `docs/decisions/D51` for the
decision; this section is the design.

Spec §1E is the rule and does not change: *a believable physical perimeter —
fieldstone walls, ranch fencing, hedgerows, terrain ridges, rivers, rock
formations, dense impassable growth, authored Team Tether barriers — with
invisible collision only supporting a visible boundary, never being the
boundary.*

### What it becomes

**Two long edges, authored as polylines rather than generated as a circle**, at
`x = −768` and `x = +768`, following the terrain the way the ring already does.
The existing generator's *through-line* is kept exactly — a continuous earth
bank and fieldstone kerb running the whole length under every dressing style,
with a stone pier at each join, so at any distance the boundary reads as one
built line whose dressing changes. That property was hard-won and is the whole
reason the current perimeter works. Only its **shape** changes: an open
polyline with a style sequence, instead of a closed circle with a cycle.

The style sequence is per-band, and it is how the edge carries regional
identity instead of fighting it:

| band | west edge (x = −768) | east edge (x = +768) |
|---|---|---|
| 1 | hedgerow on bank, ranch fence at gaps | fieldstone wall, the village's own field boundary continued |
| 2 | quarried rock face — the same `rock_form` grammar, run as a scarp | dense impassable growth over a terrain ridge |
| 3 | **water** — the broad marsh the river drains into, reed-choked and unwadeable | rock formation and scree |
| 4 | old-growth Ironwood, impassable by density alone | terrain ridge climbing to the wind ridge's own shoulder |
| approach | authored Team Tether barrier | authored Team Tether barrier |

The owner's phrase was "broken land or sea off the path in either direction".
Both halves are used: **broken land** is Bands 2 and 4 (scarp, ridge,
impassable growth), **sea** is Band 3's marsh, and the transition between them
is the band boundary, so the edge changes when the place changes.

### The two short ends

- **North (z = −512), behind Grandpa's farm.** Fieldstone and hedge, the
  gentlest boundary on the map. It is the back of the home fields and should
  read as "nothing over there", not as a wall.
- **South (z = +7680), past the stronghold.** Team Tether barrier and the
  stronghold's own outer works. The player reaches this last, and by then a
  built wall is the correct answer.

### The rule that must not be lost

Collision follows the visible line and never precedes it. The current
implementation generates its collision boxes from the same polyline that
generates the bank — keep that. A corridor is 19.5 km of perimeter against the
ring's 1.48 km, so this is also a cost item: `OW5B` should build the edge
**per region** and let it stream with the terrain, not build 19.5 km of banks
and MultiMesh at load. §8 covers that.

---

## 7. The seven severed spokes, re-sited

`terrain_playground.json` `spokes` (lines 657–1610). The design is in that
file's own `_comment_spokes` keys and it does not change: **a spoke is a road
that runs the full way out from the village square and then stops at something
the world can show, with land still visible past it. Never a wall built across
a bearing. The sign names where the road used to go and never says it is
closed.**

What changes is that the current blockers sit at 160–200 m from the origin,
inside the 235 m ring, on evenly-ish spread bearings. In a corridor, roads
leave **laterally across the broken land** and **at the far end**. Bearings are
no longer the organising idea; *where the corridor's edge is interesting* is.

| spoke | biome | leaves at | direction | ends at | blocker | kept? |
|---|---|---|---|---|---|---|
| `river_gorge` | water | (−360,400) | west, through the pond valley | (−700,470) | gorge (existing carve, re-sited) | yes, Band 1 |
| `cliff_road` | air | (430,1020) | east, onto the oak grove's high shoulder | (720,1080) | fallen roadbed | yes, Band 1 |
| `mountain_trail` | fire | (400,1800) | east, up the quarry scarp | (740,1860) | rockslide | yes, Band 2 |
| `stone_gate` | psychic | (−420,2470) | west, past the Warrens | (−730,2510) | sealed gate | yes, Band 2 |
| `blighted_road` | dark | (−150,4170) | west, along the marsh edge | (−720,4250) | sealed road | yes, Band 3 |
| `high_pass` | ice | (450,5860) | east, off the wind ridge | (740,5960) | rockslide | yes, Band 4 |
| `storm_road` | electric | (0,7000) | **south, past the stronghold** | (0,7620) | collapsed bridge | **yes — recovered, see §9** |

Six leave laterally, one at the far end. The far-end one is the storm road, and
that placement is deliberate: the last thing the player sees past the
stronghold should be a road going on, not the edge of a level.

Each still needs the property that makes it work: **land visible past it.** The
corridor helps here, because the boundary at x = ±768 is 300+ m past where the
blockers stand, so the ground genuinely continues. Do not move a blocker onto
the boundary line to save a region.

---

## 8. Load-time and residency budget

Added to this item by the coordinator, from the owner's question: *does baking a
map this size break the game? Valheim's map is far larger and nobody sits
through a long load.* The answer is that the terrain is fine and two other
systems are not.

### 8.1 The terrain itself is cheap, and the intuition is wrong

A bigger baked map does **not** mean a longer load, for the terrain:

- **Baked region data is small.** `data/terrain/playground` is **1.4 MB for 4
  regions** — 350 KB per region. 48 regions is **~17 MB on disk**. That is
  nothing.
- **Render cost does not scale with world size.** Terrain3D draws with a
  clipmap (`mesh_lods`, `mesh_size`, `cull_margin` on the node). The mesh drawn
  around the camera is the same mesh whether the world is 4 regions or 48.
- **Map memory is bounded and modest.** 48 regions × 3 maps × 256² × 4 bytes ≈
  **38 MB** of texture-array memory. Fine on an Ally.

So the terrain is resident, small, and does not need streaming. **Say this
plainly to anyone who assumes otherwise.**

### 8.2 Collision is the first real cliff

`scripts/world/playground_world.gd:155` sets `collision_mode = 3` (FULL_GAME) —
real collision shapes across the entire terrain, built at load — and `:320`
sets `collision_shape_size` to `region_size`, so shape granularity scales with
the region.

The comment at `:147–160` is important and easy to misread: FULL_GAME was
chosen to fix a **lifecycle bug**, not because dynamic collision is wrong.
Setting `collision_mode` before the node entered the tree silently reverted it
to 1 (Dynamic/Game), which built collision only inside a 64 m bubble, and
everything looked correct until you walked a couple of hundred metres and fell
through the world.

At 4 regions FULL_GAME is cheap. At 48 it is 12× the shapes and 12× the memory,
all at startup, and at `vertex_spacing` 2.0 each region is 512 m so
`collision_shape_size` must rise to 512 to stay one-shape-per-region — 48
`HeightMapShape3D`s of 256² samples each, ≈ **12.6 MB of shape data plus
broadphase**, built during the load screen.

**Recommendation: dynamic collision, set correctly and asserted.**

`tools/_probe_terrain_streaming.gd` confirms against ClassDB that this build's
`Terrain3D` exposes **`collision_radius`** with `set_collision_radius` /
`get_collision_radius`. The 64 m bubble in the old comment was the *default*,
not a hard limit. So:

- `collision_mode = 1` (Dynamic/Game), `collision_radius = 512`,
  `collision_shape_size = 64`.
- 512 m of radius is **59 seconds at `sprint_speed` 8.6** and 102 s at walk.
  The player cannot outrun it by any margin that matters. 64 m shapes mean the
  incremental rebuild as the camera moves touches small shapes often rather
  than 512 m shapes rarely, which is the shape of hitch you want.
- **How to stop it silently reverting**, which is the actual failure that
  produced FULL_GAME: apply both properties in `_ready()` **after**
  `data_directory` is assigned and the node is in the tree — exactly where
  `collision_mode` is applied today — then **read both back and `push_error` on
  mismatch**, extending the guard that already exists for `collision_mode` to
  `collision_radius`. And add the test the original bug did not have: drive a
  body 600 m down the spine in `smoke_traversal` and assert it never leaves the
  ground. The old bug survived because every test happened inside the bubble.

Numbers above are reasoned from `sprint_speed` and the ClassDB surface, **not
measured** — the frame cost of a dynamic rebuild step at 64 vs 256 shape size
is unmeasured and is the thing `OW5B` must put a number on.

### 8.3 The scatter is the hard prerequisite

`scripts/world/vegetation.gd` `build()` instantiates every MultiMesh instance
for the whole world at startup — about **28,790 today over 0.262 km²**. The
corridor is **12.58 km²**, i.e. **48×**. At the same density that is roughly
**1.38 million instances built during the load screen**, in GDScript, with a
per-instance `height_at` sample.

This is not a tuning problem. **Streaming the scatter is a hard prerequisite
for the corridor, not a follow-up.** The corridor cannot land until it exists.

The file's own header (`:13–16`) already names the answer, and it is correct —
verified against the vendored addon rather than trusted:

`tools/_probe_terrain_streaming.gd` confirms **`Terrain3DInstancer` is a real,
script-reachable class on this build** (Terrain3D 1.0.2, `addons/terrain_3d/`),
exposing `add_transforms`, `add_multimesh`, `add_instances`, `append_region`,
`append_location`, `update_transforms`, `update_mmis`, `clear_by_region`,
`clear_by_location`, `clear_by_mesh`. `Terrain3DRegion` carries an `instances`
property with `get_instances`/`set_instances`/`save`, so instance data is
**stored per region and streams with the region**. And `Terrain3DMeshAsset`
exposes per-mesh `lod0_range` … `lod9_range`, `last_lod`, `last_shadow_lod`,
`shadow_impostor`, `fade_margin` and `density`.

**Recommendation: swap to `Terrain3DInstancer`, not per-region MultiMesh
build/unload.** Both would solve residency. The instancer additionally gives
per-instance LOD and impostors for free, which a hand-rolled MultiMesh path
would have to build, and it puts the instance data in the same region files the
terrain already streams — so there is one residency mechanism instead of two
that can disagree about which region is loaded. The header's claim that this is
"a swap of this file alone" is close to true: `scatter_rules.gd` is pure and
tested and does not change, and `vegetation.gd`'s public surface is `build()`
plus the drain/regrow bookkeeping.

Two things that swap will break and must be planned for, not discovered:

- **`_drained` / `_regrown`** (SG46) holds the exact placements
  `scatter_rules._thin_by_drain` removed, so healing puts back the same
  instances. Instancer indices are per region, so that bookkeeping becomes
  per-region too.
- **Collision.** MultiMesh draws but does not collide, and `vegetation.gd`
  already builds separate collision for the solid props. Whatever streams the
  instances must stream that collision with them, or trees become ghosts at
  range and solid up close.

### 8.4 What is resident at boot, for the recommended footprint

| system | resident at boot | streamed | note |
|---|---|---|---|
| terrain region data | ~17 MB, all 48 regions | — | small; loaded from `data_directory` |
| terrain map memory | ~38 MB texture arrays | — | fine on an Ally |
| terrain mesh | clipmap around camera | yes, by Terrain3D | independent of world size |
| **terrain collision** | **nothing** | **yes — `collision_mode` 1, `collision_radius` 512** | changed by this document; see §8.2 |
| **scatter** | **nothing** | **yes — `Terrain3DInstancer`, per region** | changed by this document; hard prerequisite |
| perimeter edge | nothing | yes, per region | 19.5 km of edge; see §6 |
| structures (village, quarry, relay, stronghold) | all | — | a few dozen prefabs; cheap and they anchor the map |
| NPCs, trainers, harvest nodes, props | all | — | ~60 nodes total; cheap |
| creature spawns | all spawn *points*; bodies on demand | — | already how `spawns.json` works |

`PT-18` records that boot cost already rose sharply on the current 512 m world.
Nothing in this document reduces that; §8.2 and §8.3 stop it from being
multiplied by 48.

### 8.5 What this does to the build order

**Streaming is a prerequisite, so it is a child item ahead of the trail work,
not after it.** The order that follows:

1. Scatter streaming (`Terrain3DInstancer` swap) and dynamic collision, on the
   **current 512 m world**, where a regression is visible in one survey run and
   `smoke_traversal` already covers the ground. Ship it before the footprint
   changes.
2. The footprint and the bake (`OW5B`), including the two defects in §1.3 and
   the `_config` hoist in §1.1.
3. The trail, loops and edges (`OW5C`).
4. Relocation of everything in §10 (`OW5D`).

Doing (1) after (2) means debugging a streaming bug and a 48-region bake at the
same time, with a two-hour turnaround on the bake.

---

## 9. Re-deriving D46 — the river, and the spoke it cost

`docs/decisions/D46` decided that the river really divides the map and that
this costs exactly one spoke: the storm road's collapsed bridge ends up on the
far bank, unreachable until the Old Mill Crossing opens.

**That decision was correct for a 512 m disc and does not survive the
corridor.** Its own reasoning says why: the disc was *demonstrably full*. Every
bearing was searched at 1° and every offset at 2.5 m, and the best compliant
chord left a far side 17 m deep — a verge, not a region. The choice was "divide
it and pay one spoke, or do not divide it."

In a 1536 m-wide corridor that constraint evaporates. A river crossing the
**width** at z ≈ 4,200 divides the map completely and trivially: it needs 1,536
m of course plus overrun past both edges, it crosses every possible route
because there is only one direction of travel, and the far side is 3,400 m
deep. There is no search to run and no chord to compromise.

**Decision: the storm road is recovered.** All seven spokes stand, and the
storm road moves to the far end at (0,7000) → (0,7620), past the stronghold, in
Band 4/approach. D46's cost is repaid.

What is deliberately kept from D46, because it was right about these and they
are not about the disc:

- The river is a **river**, not a dry gorge. D46 rejected the dry gorge and the
  reasoning holds.
- The crossing is sited **on a road**, at narrows where a mill and a bridge
  would actually stand — "cut and given a way over, in one gesture, which is
  the whole grammar of `crossings[]`."
- The **dry-gorge remainder** is kept as a *technique*, not as an accident. D46
  recorded honestly that the north 60 m of the course runs above the water
  plane and is dry. In the corridor the river runs across a low, wet band on
  purpose, so it should be wet end to end — but where the course climbs to meet
  the eastern rock formation, a dry upper gorge feeding the river is a
  legitimate and now-intentional piece of landform.

D46 is superseded on its central claim and is not deleted. `docs/decisions/D50`
records the supersession.

---

## 10. The relocation table

These are duplicated sources of truth. They must move **together** or they
drift, and the drift is invisible until something is standing in a hillside.
"Current" is `main` as of 2026-08-16. "New" is the corridor frame.

Band 0 and the village are **unmoved by design** (§3). Everything else moves.

### 10.1 Unmoved — verify, do not touch

| what | file | coordinate |
|---|---|---|
| Grandpa's house | `playground_world.gd` `HOUSE_AT`, `flats[0]`, `building_aprons.footprints[0]`, `vegetation.footprints[0]`, `village.json` | (−22, −16) |
| village square / well | `flats[1]`, `village.json` `well`, `building_aprons.footprints[4]` | (10, −10) |
| workshop | `village.json` | (2, 2) |
| wagon | `village.json` | (6.5, −1.5) |
| cottage_a / cottage_b | `village.json`, `building_aprons.footprints[2,3]` | (18, −2) / (21, −14) |
| fence runs ×3 | `village.json` | (14,−20) (19.5,−25.5) (3,−18) |
| square oaks ×2 | `village.json` | (25.5,−9.5) (1,10.5) |
| junction signpost | `playground_world.gd` `SIGNPOST_AT` | (13.5, −7) |
| road gate / gate key | `playground_world.gd` `GATE_AT` / `GATE_KEY_AT` | (27.5,−16) / (24,−10) |
| Practice Meadow | `paths.routes[1]`, `vegetation.clearings[3]`, `spawns` bramblebun | (30, −40) |
| The Rise + its trailhead | `flats[3]`, `paths.routes[3]`, `paths.trailheads[0]`, `rises.peaks[0]` | (74,−41) / (140,−90) |
| `spawn_pad` | `terrain_playground.json` | (0, 0) |
| `map_landmarks` `grandpas_village`, `the_rise` | `map_landmarks.json` `regions` | (6,−22) r60 / (88,−43) r55 |
| village NPCs Mira, Oskar, Tam, Sela, Kell | `village_npcs.json` | unchanged |
| harvest nodes ×12 near the village | `harvest.json` | unchanged |

### 10.2 Moved

| what | file(s) | current | new |
|---|---|---|---|
| The Pond + basin | `water.pond_centre`, `valley.centre`, `spawns` paddlenewt/mosshell/brooktail/reedwing, `map_landmarks` `the_pond` | (−145,138) / valley (−120,130) r150 | **(−395, 545)**, valley (−370,560) r180 |
| mill + footbridge | `village.json`, `flats[4]`, `building_aprons.footprints[5]`, `vegetation.footprints[2,3]` | (−132,107) / (−136.3,113) | **(−382, 514)** / (−386, 520) |
| ranger station | `village.json`, `flats[5]`, `vegetation.footprints[4]` | (−100,100) | **(−350, 507)** |
| stream (`water.stream.points`, 25 pts) | `terrain_playground.json` | z 0…140 | re-authored feeding the pond from (−200,300) |
| South Bridge crossing + gully carve + gate | `crossings[0]`, `flats[6,7]`, `vegetation.clearings[7]`, `paths.trailheads[1]`, `map_landmarks` `south_bridge` | carve (5,80) | **carve (0, 1330)**, abutments (0,1317)/(0,1343) |
| Old Quarry (floor, foundations, pylons, drains ×4) | `flats[8]`, `old_quarry.json`, `drains.stations[0..3]`, `vegetation.clearings[8]`, `harvest` ×5, `map_landmarks` `the_old_quarry` | (23,158), drains (27,162)…(41,121) | **(400, 1800)**, drains re-laid along the new haul road |
| Burrow Warrens | `burrow_warrens.json` `site.at` | (70,−140) | **(−420, 2470)** |
| Warrens-area harvest ×5 | `harvest.json` | (60,−136)…(92,−158) | around (−420, 2470) |
| Tether Relay (site, walls, gate, decks, ramps, apparatus, conduits) | `relay_site.json`, `tether_relay.json`, `drains.stations[4..6]`, `map_landmarks` `the_tether_relay` | (108,34) | **(350, 3760)** |
| relay trainers Hess, Orrin, Dell, Captain Vance | `trainers.json` | around (108,34) | around (350, 3760) |
| the river (18-point course) | `river.course` | (211,−87)…(75,246) | **crosses the width at z ≈ 4,200**, x −800…+800 |
| Old Mill Crossing + mill + abutments | `crossings[1]`, `flats[9,10]`, `map_landmarks` `old_mill_crossing`, `the_long_water` | (162.4,42.1) | **(−150, 4200)** |
| Stronghold | `stronghold.json` `site.at`, `map_landmarks` `stronghold`, `playground_world.gd` `SIGIL_GATE_AT` | (141.8,−215.4) / sigil gate (130,−176) | **(0, 7560)** / sigil gate (0, 7400) |
| stronghold trainers Verrick, Solene, Hald, Warden Aldis | `trainers.json` | around (141.8,−215.4) | around (0, 7560) |
| three regional captains Halder, Vess, Oreth | `trainers.json` | unplaced/near village | **(170,5590) / (−280,6460) / (−100,4350)** |
| seven spokes (`road`, `blocker.carve`, `sign`) | `spokes.routes` | radial, 160–200 m | §7 table |
| `rises.peaks[1..4]` | `terrain_playground.json` | (−165,−150) (60,175) (78.4,−184.2) (24.4,−198.8) | re-sited as Band 2 scarp and Band 4 wind ridge |
| all remaining `spawns.json` entries | `spawns.json` | within ±150 m | to their band per spec §13 (§5 above) |
| `props.json` clusters ×5 | `props.json` | near village | per band |
| perimeter | `world_perimeter.gd` | circle r235 | §6, D51 |
| `world_size` / `vertex_spacing` | `terrain_playground.json` | 512 / 1.0 | bounds x[−768,768] z[−512,7680] / 2.0 |
| `WORLD_EDGE` | `tests/smoke_traversal.gd` | 240.0 | corridor bounds |

**New coordinates in this table are the layout's intent, not surveyed ground.**
`height_at` is analytic and unbounded, so every one of them can and must be
probed for slope and clearance before it is written — that is `OW5D`'s first
job, not a formality. Structure sites in particular (`stronghold.json` `skirt`
18, `burrow_warrens.json` `skirt` 10) need ground that will accept a skirt.

### 10.3 Two deferrals the repo booked against the re-bake

Both say "the day the terrain is re-baked", which is `OW5B`. Flagged here so
they are not missed:

- **`terrain_playground.json:656`**: `tether_relay.json`'s `dead_ground.enabled`
  **must** flip to `false` on the first re-bake, or the relay site is tinted
  twice — once by the baked `drains` stations and once by the runtime dead
  ground.
- **`docs/decisions/D45`'s postscript**: the quarry's baked drain colour must be
  **re-evaluated**, not inherited. It was authored against a quarry 158 m from
  the village on a 512 m map; at (400,1800) in a band whose whole identity is
  exposed rock, the same tint against the same near-white base is a different
  picture.

---

## 11. The signpost problem

`scripts/world/signpost.gd` draws **one arm per `paths.routes` entry** and the
post fits four: `ARM_START_HEIGHT` 2.05 stepping down by `ARM_SPACING` 0.44
puts a fifth arm at 0.29 m, in the grass. A 12 km trail cannot be four routes.

**It does not have to be.** `playground_heightfield.road_polylines()` (`:1116`)
is the single definition of "where the roads are", and it already unions three
sources: `paths.routes`, `spokes.routes[].road`, and `crossings[].road`.
Anything in any of them gets painted soil in the control map, vegetation held
off it, path-stone scatter down it and a verge fringe — automatically. Only
`paths.routes` feeds the signpost.

So the corridor's spine and loops are expressed as **new sources unioned into
`road_polylines()`**, not as `paths.routes` entries:

- add `trail.bands[]` (the §3.1 spine, one entry per band) and `trail.loops[]`
  (the §3.2 table) to `terrain_playground.json`;
- union both in `road_polylines()`, exactly as `crossings` already is;
- leave `paths.routes` as the village's own four dirt tracks, forever. The
  four-arm fingerpost by the well keeps naming the four places you can walk to
  from the square, which is what a village junction sign is for.

Wayfinding along the trail is `paths.trailheads` — the existing one-arm
fingerpost object, already used for The Rise and the South Bridge, and already
reused by `severed_spokes.gd` through `signpost.gd`'s `routes_override`. One
per fork. That is the correct object and it needs no redesign; the junction
post needs no redesign either, because it stops being asked to do a job it
was never built for.

---

## 12. Open questions this document does not settle

- **The frame cost of a dynamic collision rebuild step** at
  `collision_shape_size` 64 vs 256. §8.2's radius recommendation is reasoned
  from `sprint_speed`, not measured.
- **Whether the `_config` hoist in §1.1 is worth an hour.** Unmeasured. Measure
  before believing the multiplier.
- **Water level in a corridor.** `water.level` is one flat plane for the pond
  and `river.water_level` another for the river. A corridor 8 km long descending
  through four bands cannot use one plane for everything; Band 3's marsh (§6)
  and the pond are 3,600 m apart. `OW5B` needs a plan for more than two water
  bodies, or an authored per-body level.
- **Whether 1,536 m of width is right after the first band is built.** §5's own
  rule is "only as large as the team can make meaningfully dense". If Band 1's
  flanks come out empty, narrowing to 1,024 m (two regions) is cheaper than
  filling them, and the spine's x range (−430 … +450) survives it.
