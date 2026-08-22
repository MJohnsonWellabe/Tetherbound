# D5 — Stronghold Approach: lane report and evidence

Branch: `claude/start-d5-abf6zi`. Owning prompt:
`docs/ralph-prompts/66-BAND5-finished-stronghold-approach.md`. Region: z 7000 →
7680, 651 m of authored spine.

This lane's own final report was never written by the session that did the
first content pass, so §1 establishes ground truth from the branch rather than
from the START file's account of it.

## 1. Ground truth on arrival

`python3 tools/_probe_chapter_map.py`, before any change this session made:

```
band5_stronghold_approach   z < 1000000
  team expected 16 -> 20 (5 members)   wild band [14, 17]   trainer band [15, 20]
  trainers (6)      wild clusters (22, 75 creatures)      authored gatherables (6 nodes)
```

Already shipped by the earlier pass and verified present: the density directive
(22 clusters / 75 creatures, inside the owner's 18–28 / 70–110 target), two
trainers moved out onto the approach (Corr at z 7140, Ness at z 7440), six
gatherables, two prop clusters, one vegetation clearing, `the_waystop` landmark,
dialogue for both new trainers, and the `STRONGHOLD-MAT` texture fix in
`stronghold.gd::_material`. **Density is done; nothing about it was changed.**

Genuinely missing, and the subject of this session:

| Prompt 66 item | State on arrival |
|---|---|
| Navigation spine / pylon readability | **absent** — no tether machinery anywhere in the band |
| Environmental storytelling (drained ground) | **absent** — no `drains.stations` entry in the band |
| Gated crossing | present but **55.9 m off the road** (§4) |
| Dead travel | **123 m** worst interval (§5) |

## 2. The navigation spine — 15 lit pylons

The chapter's conduit network stopped at the relay (z 3749) and the quarry
(z 1790). The last 680 m, the approach to the machine the whole network feeds,
was open meadow with a castle on the skyline.

`stronghold.json::approach_pylons` now runs an unbroken **lit** trunk line from
(-40, 7010) to (-8, 7505), built by `stronghold.gd::_build_approach_conduits`,
which borrows `severed_spokes.gd::_build_pylons` exactly as `old_quarry.gd`
does. Verified standing in the live world: `[stronghold] … 15 approach
pylon(s)`.

**Straight, beside the wandering road rather than on it.** The spine swings
±80 m either side of x=0; a line that followed it would be a handrail — the
"magical GPS" the prompt names. A straight line the road keeps crossing is a
*bearing*: the player loses it around every rise, meets it again, and it always
points the same way. The direction comes from the line's own convergence in
perspective and needs no marker or minimap.

**Sited by measurement.** `tools/_probe_band5_pylon_line.gd` exists because
`_conduit_span` sags the cable `distance × 0.05` below an attachment computed
from *each pylon's own base*, so ground rising mid-span pushes itself into a
cable derived from the two ends. The first candidate (13 stations, 9 m) put the
cable **1.74 m** above the ground on span 4→5 — head height on a 1.8 m player,
a defect that shows only in a render. The probe swept height against station
count; **15 stations at 10.0 m is the smallest height that clears comfortably,
worst clearance 3.14 m.** Relief across the run is 11.77 m, which is why this
had to be measured at all. Re-run the probe before moving any station.

**The ending pays this off for free.** `meadow_healing.json::tether_lights`
finds lit Team Tether fittings by *what their material is*, not by node name, so
all fifteen go dark on the walk home from the Warden alongside the quarry's four
and the relay's ten. No ending work was needed and none was added.

## 3. Drained ground — shipped code, requested data

`terrain_playground.json::drains.stations` holds seven entries: four at the
quarry (z ~1790) and three at the relay (z ~3749). **There is not one anywhere
in Band 5.** The drained ground got *weaker* the closer the player walked to the
machine draining it.

`scripts/world/approach_drain_skin.gd` ships the runtime half now — the same
technique `tether_relay.gd::_build_dead_ground` uses, its alpha being
`playground_heightfield.drain_factor()` itself so it paints exactly the contour
the bake will and nothing anywhere else. It is a separate node rather than a
method on `stronghold.gd` because that file's `_process` already runs the door
sync and a healing routine calling `set_process(false)` there would silently
stop the Warden Arena shutter tracking its flag. It exposes `heal()` and
`dead_ground_visible()`, so `meadow_healing.gd` finds it by duck-typing with no
file naming the other.

**It renders nothing today and says so in the build log**, because
`drains.stations` lives in a file no Gate D lane may edit:

```
[approach-drain] no drained ground on the approach: drain_factor() is 0 across the
corridor (terrain_playground.json `drains.stations` has no Band 5 entry)
```

### REQUEST 1 — coordinator: eight `drains.stations` entries

Escalating toward the works, the mirror of the quarry run's fade-with-distance,
because here the source is *ahead* of the player. Centres are the pylon
stations; the last is the works itself.

| id | centre | radius | inner | strength |
|---|---|---|---|---|
| `approach_mouth` | (-35.4, 7080.7) | 18 | 5 | 0.30 |
| `approach_run_1` | (-30.9, 7151.4) | 18 | 5 | 0.38 |
| `approach_run_2` | (-26.3, 7222.1) | 18 | 5 | 0.46 |
| `approach_run_3` | (-21.7, 7292.9) | 20 | 6 | 0.56 |
| `approach_run_4` | (-17.1, 7363.6) | 20 | 6 | 0.66 |
| `approach_run_5` | (-12.6, 7434.3) | 22 | 7 | 0.78 |
| `approach_run_6` | (-8.0, 7505.0) | 24 | 8 | 0.90 |
| `stronghold_works` | (0.0, 7560.0) | 42 | 18 | 1.00 |

The code is shipped ahead of the data deliberately, so granting this is one edit
to one file rather than an edit plus a code change. `approach_drain.bounds`
already covers all eight.

## 4. The three-Sigil gate was not on the road

**This is the most consequential thing the driven run found.**
`tools/_probe_band5_approach.gd` measured the gate at (0, 7400) sitting **55.9 m
from the nearest point of the authored spine**. The region's one physical
progression checkpoint stood in open meadow beside the route; the road never
passed it, and the objective that completes on `hall_approach_open` waited on a
thing the player had no reason to walk to.

`playground_world.gd`'s own comment had already flagged this and deferred it:

> `SIGIL_GATE_YAW_DEG` … is almost certainly wrong for the new site … this yaw
> needs fresh tuning against the real approach **once it is built** — flagged
> rather than guessed at. Ground truth at (0,7400) was **NOT** re-probed.

It is built. Both constants are now measured
(`tools/_probe_band5_sigil_gate.gd`):

- **(0, 7400) → (63.6, 7400)**, where the spine actually crosses that latitude.
  Ground relief 2.25 m over a 16 m pad against 2.08 m at the old point — the
  same quality of ground, so nothing is traded. Clearances: 44.1 m to Ness
  (his 4.0 m prompt and the gate's 4.2 m never contest), 32.9 m to the nearest
  wild cluster, 95 m+ to everything else.
- **-17.6° → -28.6°**, `atan2(bearing.x, bearing.z)` of the road's heading
  there. The leaf's span axis was **measured, not assumed**
  (`tools/_probe_gate_leaf_axis.gd`): `road_gate_leaf`'s local AABB is
  4.07 × 1.46 × 0.12, so the panel spans local X and `rotation.y = θ` puts it
  perpendicular to the bearing exactly when θ = atan2(dx, dz).

Two stale comments written against the old site were corrected rather than left
to rot: Warder Ness's `_why_here` (claimed "25 m past the Sigil gate"; he was
60.2 m from it, and is now 44.1 m past it along the player's own travel) and
pylon 11's `_why`.

### REQUEST 2 — coordinator: the gate still does not constrain travel

Prompt 66 asks that "a physical gorge/barrier must actually constrain travel."
It does not, and moving it did not change that: it is a **4.07 m leaf on open
ground**, so it is a key-use point and staging, not a barrier, and a player who
wants to walk around it can. Making it real needs flanking terrain — a
`crossings`-style carve or a wall run in `terrain_playground.json`, which no
lane may edit. Suggested shape, matching `south_bridge`'s own arithmetic: a
carve centred (63.6, 7400) on `axis_deg` ≈ 61.4 (across the road), `half_length`
~40, `end_fade` ~14, `half_width` ~4, `rim` ~3.4, `depth` ~11 — 72° walls,
well past the player's 45° `floor_max_angle`. **Not authored here**; it changes
the heightfield and forces the re-bake the contract reserves to integration.

## 5. Dead travel — 123 m → 63 m

The driven run measures, for every metre of the spine, the distance to the
nearest reason to stop (a cluster's own radius, a trainer's or gatherable's or
prop's reach, the gate). The longest run of metres with nothing in reach is the
region's worst empty stretch.

**Before: 123 m**, the whole eastward diagonal from (-6, 7267) to (73, 7361) —
the leg the player crosses immediately before the gate. The density pass had
added 65 creatures but sited six clusters off-spine on purpose, and this leg is
where that left the road itself bare.

Three beats placed into it, all inside this lane's own files: a duskhush cluster
on the leg (`spawns` 5022), a stone node (`harvest` 5006), and `road_watch_drop`
(`props` 5002) — a Team Tether supply load left on the road for somebody who has
not come back for it. A drop rather than a third body, because prompt 66 says
explicitly not to spend every combat beat before the stronghold; the occupation
is present in the props where nobody is standing.

**After: 63 m**, and that interval is the final approach to the works, ending at
651 m. That one is deliberate breathing room — the doorstep gauntlet is Gate E's
and begins the moment it ends.

Cadence after the fix, one beat roughly every 40 m:

```
  28 wild burrowback ·  69 wild galecrest · 108 gather fiber · 133 wild burrowback
 146 trainer Corr    · 148 props outer_watch_cache · 238 wild mudsnout
 270 wild galecrest  · 309 props road_watch_drop · 346 wild duskhush
 370 gather stone    · 433 wild duskhush · 500 trainer Ness · 558 wild trailpup
```

Note 14 of 36 authored points are within reach *of the road*; the other 22 are
deliberately off-spine (the density pass's own pockets, and the `tm_heavenfall`
special encounter at (140, 7300), which is meant to be a detour).

## 5a. `22-SKY-PLANES` — reproduced, and root-caused

**Reproduced on this branch**, which is the first thing prompt 22 asks for.
`shots/band5_approach/01-band-mouth.png`, `04-before-the-gate.png` and
`06-the-waystop.png` all show several large translucent rectangles hanging above
and behind the stronghold. This is not stale bug prose, and it is worst on
exactly the sightline this region is built around: the player looking at the
works.

**The producer is `scripts/world/rift_collapse.gd`'s `StormWall` group**, built
from `data/config/rift_collapse.json::storm_wall.slabs`.
`tools/_probe_band5_sky_planes.gd` walked every visible MeshInstance3D within
900 m of the approach and sorted by height above ground. Exactly three large
**transparent** meshes exist, and they are all storm slabs:

```
ABOVE     NODE                            MESH/SIZE          AT                 TRANS
 47.4     RiftCollapse/StormWall/…Wall_1  Quad 460x190x0     (  33, 47, 7968)   true
 22.4     RiftCollapse/StormWall/…Wall_0  Quad 420x150x0     ( -46, 27, 7919)   true
 13.9     RiftCollapse/StormWall/…Wall_2  Quad 360x122x0     (-112, 13, 7870)   true
```

Every other big mesh in range is a `Stronghold/` box and every one of them is
opaque. So the candidate families prompt 22 lists — a bad LOD/impostor, a
missing texture, a stray debug plane, a transform error — are all **ruled out**.
This is intended geometry, correctly placed, seen from a viewpoint it was never
sized for.

**Why it fails here, specifically.** `storm_wall`'s own comment states the
intent: *"The rift, from 200m of open meadow away: a slate wall of weather
standing across the whole eastern sky behind the broken bridge, with land
visible nowhere past it… three overlapping slabs… so the near edge does not read
as a billboard."* That works because it is authored for one viewpoint at one
distance — the slabs sit 262–356 m from the rift, where a 420 × 150 m card
subtends roughly 70° × 28° and genuinely fills the sky.

Band 5's approach looks at their **flank, from much further away**. Measured
from this lane's own capture eyes to `StormWall_1`: **968 m** at the band mouth,
619 m before the gate, 506 m at the Waystop. At 506 m that slab subtends about
49° wide but only ~20° tall, with open sky above it and horizon visible past its
ends — so the one property the design depends on ("land visible nowhere past
it") is exactly what breaks, and a wall of weather becomes a rectangle of glass.
OW5D put the stronghold at z 7560 and left the storm wall at z 7870–7968, 310–410 m
directly behind it on the player's bearing; the corridor created a sightline the
slabs were never authored against.

**Not fixed here, deliberately.** `rift_collapse.json`/`rift_collapse.gd` are not
this lane's files, and the storm wall is a hero visual whose own job is to close
the horizon beyond the Meadows — making it invisible from the approach could
break the thing it exists for, which is a design call rather than a defect fix
(`CLAUDE.md`, "ask instead of inventing"). The diagnosis is complete and the
options are cheap to state:

1. **Occlude rather than resize** — the slabs' bases sit at y = -46 and the
   approach ground runs 0–8 m; raising the base so the ground and the works
   occlude their lower edge from the south costs nothing on the rift's own
   viewpoint, which looks along the slabs rather than at them.
2. **Scale with distance** — widen/heighten the slabs so they still fill the sky
   at ~1 km, which preserves "land visible nowhere past it" from both viewpoints
   at the cost of geometry the rift viewpoint does not need.
3. **A second, further group** authored for the corridor's own bearing, leaving
   the rift's three untouched.

Re-run `tools/_probe_band5_sky_planes.gd` to confirm whichever lands.

## 5b. `23-BILLBOARD-WHITE` — does NOT reproduce on this route

Prompt 23's symptom is "upright white rectangular cards visible among trees near
the storm road". The six captures cover the whole Band 5 route at player eye
height, several of them through stands of trees (`04-before-the-gate.png` most
directly). **No white or default-material cards appear in any of them**, and the
sky-plane probe found no untextured large geometry other than the storm slabs
already accounted for above.

This is a negative result on **this route only**. The defect was reported on the
storm road, which is a Band 1 spoke and not Band 5's ground, so this does not
close prompt 23 — it removes Band 5 from its scope. The lane that owns the storm
road should reproduce it there.

## 5c. The stronghold silhouette is 7.7 km from the stronghold

Prompt 66 asks whether "the stronghold grows in visual dominance" as the player
approaches, and lists "stronghold silhouette dominance" under regional identity.
It cannot, and the reason is not this region's content.

`scripts/world/landmark.gd` builds the assembled Quaternius castle — the
`StrongholdSilhouette` node, the thing the whole chapter has been walking toward
— at `RISE_CENTRE + OFFSET` = **(229.8, -144.4)**, hard-coded, sited by a probe
against sightlines from the village square. `stronghold.json`'s `site.at` was
moved by OW5D to **(0, 7560)**. Those are **7,704 m apart**.

`stronghold.json::_comment_where` still describes the relationship the two were
built to have: *"The route is the WORKS BEHIND the castle… this complex stands
on the flat ground south of it and the player works east and then north until
the Legendary Chamber sits directly behind the castle's own footprint."* That
relationship no longer exists. `map_landmarks.json` agrees with the works
(`stronghold` at [0, 7560]); only the castle mesh stayed behind.

Confirmed two ways: by arithmetic from the constants, and by
`tools/_probe_band5_sky_planes.gd`, which found **no castle or plinth geometry
of any kind within 900 m of the approach** — the largest structures in range are
all `Stronghold/` boxes, the works' own walls.

What the player gets today: a castle standing near the village in Band 1, walked
past in the first hour and never returned to, and a final approach whose climax
building is a low dark wall with nothing rising behind it.

**Not fixed here.** Moving the castle is a world-layout decision that would
change the Band 1 sightlines `landmark.gd` was measured against, and it is
genuinely two different chapters depending on the answer — one silhouette
relocated behind the works, or an early distant landmark plus a separate arrival
building. That is on `CLAUDE.md`'s "ask instead of inventing" list. **Owner or
coordinator call, and the single largest player-facing gap left in this region.**

## 5d. The final preparation point did not fund a rest

I reported the Waystop as done on the strength of reading its config. Playing the
arithmetic instead of the prose found a real gap.

Prompt 66 asks the final preparation point to let the player "stop, adjust the
five, rest/camp", and warns against "an automatic free heal". The Waystop's
answer to that is the right one — a cleared 14 m nook with materials in reach, so
the player *builds* the rest rather than being handed it. But the numbers did not
close:

| | wood | stone | fiber |
|---|---|---|---|
| Waystop's five nodes paid | 8 | 6 | **4** |
| `creature_bed` costs | 6 | — | **8** |
| `camp` costs | 12 | 8 | 10 |

**Half the fiber for the one object the place exists to enable** — and the
clearing that makes the site buildable is the same clearing that keeps the
bushes off it, bushes being the only renewable fiber in the game
(`vegetation.json::_comment_harvest_fiber`).

Raised order 5005 from 4 to 8. That funds **exactly one creature bed** and
leaves `camp` out of reach, which is the intended shape rather than a shortfall
padded for comfort: the last stop before the assault heals one of the five, so
which one is a real choice, and it is still gathered and built rather than
granted.

## 5e. Night readability — there are no torches, and that has a consequence

Prompt 66's last visual-cleanup item is "torch/night readability on the final
route". Reproduce-first found there is nothing to reproduce **and** something
worse underneath it.

`tools/_probe_band5_approach.gd` now runs the same six eyes twice, day and
night (`world_look.gd::apply_time`), so the two sheets differ in exactly one
variable. Findings from the night sheet:

- **There is not one torch in Band 5.** Zero matches across all five of the
  band's config files, and the shipped prop family has no torch model to place
  either. So the "torch readability" half of the item is empty: there are no
  torches whose readability could be bad.
- **The pylon run is the entire night lighting of the region**, and it works —
  in `03-mid-route-night.png` the lit pylons and the glowing conduit are the
  only legible features in the frame, and the cable traces the bearing to the
  works when the ground, the scatter and the horizon have all gone black. That
  is an unplanned benefit of §2 and the strongest evidence the spine does its
  job: it navigates in the condition where nothing else can.
- **`22-SKY-PLANES` is worse at night, not better.** The storm slabs read as
  crisply delineated pale rectangles against a black sky. Confirmed in both
  lighting states, which rules out any explanation that depends on daylight.

### The consequence, which is a real one

`meadow_healing.json::tether_lights` turns off **every lit Team Tether fitting**
when the machinery dies — deliberately, and my fifteen pylons are correctly in
scope for it. But since they are also the region's only light source, the
arithmetic is: **after the Warden, at night, the 651 m walk back through Band 5
has no light at all.**

That file's own comment says "nothing warm is touched, which is why the freed
legendary's own #e8d79a light survives it" — so warm light surviving the
ending is explicitly part of the design. The approach simply has no warm light
to survive.

**Not fixed here.** Adding a warm light source to the post-victory route means
either a prop family that does not ship a torch, or inventing lighting canon for
a beat (`the walk home`) that belongs to Gate E's finale, not to this region.
Flagged for the coordinator and for `69-STRONGHOLD-chapter-finale.md`: if the
walk home is meant to be walkable at night, this route needs a warm source that
the healing pass leaves alone. Before this lane's work the region was unlit at
night in every state; it is now lit during the chapter and dark after, which is
an improvement plus a newly visible gap rather than a regression.

## 6. What this lane did NOT verify — owed work

- **The blind visual pass is NOT done.** Twelve captures were produced
  (`shots/band5_approach/`, six viewpoints down the route at eye height all
  looking at the works, each rendered at day and at night) specifically so an **independent critic** can judge
  whether the pylon line reads as a bearing and whether the stronghold grows in
  visual dominance. Per `ralph/lanes/COMMON.md` §8 this lane does not grade its
  own frames, and it has not. **Coordinator: dispatch the critic.**
- **`22-SKY-PLANES` and `23-BILLBOARD-WHITE` are not closed.** They need
  reproduce-first judgement on rendered frames from this route; the captures
  exist for it, the verdict is owed with the critic's pass.
- `smoke_art.gd`'s eleven inherited failures are the base's, per the lane
  contract §4 — not touched, not re-fixed.

### REQUEST 3 — `density_scale` for band5

Band 5 sits at **0.03**, the chapter floor, with bands 3 and 4. Whether it
*reads* bare is the critic's call, not this lane's. But there is an argument
independent of taste: once REQUEST 1 lands, `scatter_rules.gd` reads `drains` at
run time and starts **removing** vegetation here, so a floor-density band gets
thinner, not thicker — and drained ground is only legible as *damage* if healthy
ground survives beside it to compare against. **Recommend 0.05**, granted
together with the drain stations rather than before them, then re-judged.

## 7. Clearings added

Nothing new this session. The earlier pass added one clearing
(`vegetation.json` order 9, `the_waystop`), and per lane contract §4 the scatter
bake's fingerprint does not hash band vegetation files, so it takes effect at
the coordinator's single integration re-bake and not on a local run.

## 8. Files touched outside this band's own directory

Declared for integration:

- `data/config/stronghold.json` — `approach_pylons`, `approach_drain` (approach
  and exterior keys, this lane's per START_D5).
- `scripts/world/stronghold.gd` — two builders, a counter, two accessors.
- `scripts/world/approach_drain_skin.gd` — new.
- `scripts/world/playground_world.gd` — **two constants only**
  (`SIGIL_GATE_AT`, `SIGIL_GATE_YAW_DEG`), the tuning that file's own comment
  deferred to this lane. Expect a trivial conflict at most.
- `tools/_probe_band5_approach.gd`, `_probe_band5_pylon_line.gd`,
  `_probe_band5_sigil_gate.gd`, `_probe_gate_leaf_axis.gd` — new probes.
