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

## 6. What this lane did NOT verify — owed work

- **The blind visual pass is NOT done.** Six captures were produced
  (`shots/band5_approach/`, viewpoints down the route at eye height, all
  looking at the works) specifically so an **independent critic** can judge
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
