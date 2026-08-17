# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `🔒` needs Meshy credits. `model:` the cheapest tier that can do the
job. `tests:` exactly what to run.

**Owner play gates were retired 2026-08-16.** Every `▶` gate (`R2.9`, `R4.12`,
`R6.3`, `MQ1-gate`, `SH53`, and the `R9.5` exit gate) is gone by owner
directive, along with the pointer to the owner-only blind-playtest protocol.
`docs/decisions/D21` stays as history and reads as superseded, not violated.
The loop no longer parks on a gate — see `ralph/PROMPT.md` for what it does at
the end of the backlog.

**`model: fable` (owner directive, 2026-08-12) is not "the cheapest tier that
can do the job" — it is a hard floor.** These items are ceiling-setting
narrative or aesthetic authorship (world-building, story beats, dialogue, or
"does this actually look right" visual-direction judgment calls) where a
weaker first pass becomes the ceiling a later pass can't rescue. **Any firing
that reaches a `model: fable` item must not do the creative work in its own
session, regardless of which lane it is** — see `ralph/PROMPT.md`'s
"Fable-tagged items" section for the dispatch rule.

**MODEL FLOOR SUSPENDED, owner directive 2026-08-17: "drop to sonnet for
everything."** Taken to protect the account's seven-day rate limit, which was at
`allowed_warning` with a reset of 2026-08-22 03:00 UTC while the owner asked for
the first two bands of content finished before it hits. **The newer word wins**
over the `model: fable` floor above, the same way `D23` lets the owner's later
word win over the spec — so `model:` lines in this file now read as a *ceiling*,
not a floor, and a `fable` tag means "this is ceiling-setting work, be
conservative" rather than "dispatch fable".

What that costs is real and is recorded rather than papered over: the fable
floor exists because a weaker first pass becomes a ceiling a later pass cannot
rescue, and `MQ2B` is exactly that kind of item. A lane working a `fable`-tagged
item under this directive should prefer arranging and connecting what exists
over inventing new fiction, keep new named things few and small, and write down
in `ralph/NOTES.md` anything that genuinely wanted a stronger pass.

**Standing task, every visual milestone:** re-shoot the website's screenshots
after any milestone that changes how the game looks. `model: haiku` when it is
just screenshots.

---

## RECONCILED 2026-08-17 (OPS1) — 35 items closed in one pass

**This file had drifted badly and this note exists so the drift is legible
rather than silently tidied.** Across 2026-08-16/17 a coordinated run landed 76
commits to `main`; almost none of them were marked here, because bookkeeping was
centralised on a coordinator that then spent the night on merges instead. That is
`OPS1`'s own failure mode, happening while `OPS1` sat open.

Closed in this pass, verified against `git log origin/main` rather than against
anyone's memory: `OW1` `OW2` `OW4` `OW7` `OW8` `OW9` `OW10` `OW11` — the whole
owner-reported ROG list — plus `PERF1` `PERF2` `WALL1` `TEST1` `EXP1` `MERGE1`
`LANE1` `UI-PAD1` `UI-PAD2` `PT-03` `PT-04` `PT-15` `PT-17` `PT-18` `PT-19`
`PT-23` `OF18` `EV10` `MQ1B` `R7.3` `R7.6` `R7.7` `R7.8` `R7.9` `OW5A-rework`.

Four more are **shipped and in flight** on `ralph/integrate-3` — `OW3`, `OW12`,
`OW1-remainder` and the collision-streaming work — each marked in place rather
than closed, because a branch that has not landed is not done no matter how
green it is.

**The rule that made the difference, and it is worth keeping:** a shipped item
is one whose content is an ancestor of `main`. Not a green branch, not a lane
saying so, not a branch ref that looks right — `UI-PAD1`'s ref had moved and an
ancestor check called it missing while its code was demonstrably in the tree.
Check the tree.

---

## Phase -1.5 — the owner played the ROG build (owner-reported, 2026-08-16)

Reported from the real handheld, which is the instrument no test in this repo
substitutes for. **Three of these have been "fixed" before** — check the current
build before rebuilding, then fix the mechanism rather than the symptom, because
the symptom has come back every time so far.

The owner also asked whether they were on an old build. Partly answered here:
`OW3`'s fog does not exist in code at all, and `OW1`'s hotbar has no separate
section *by design* — so those two are real regardless of build age.

### OW12 — The torch should be a carried item, not a thing you build
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in the corridor merge `d4de94a3`. Verified in the tree, not by branch ref.

`model: sonnet` · `tests: smoke_playground, test_inventory` · `area: ui`
Owner, 2026-08-16: *"torches need to be a carry able item not placeable one."*

**Both halves already exist, which makes this smaller than it sounds.** A carried
torch is real — `scripts/player/torch.gd` bone-attaches it, and `items.json:550`
names it as the pattern `tool_hold.gd` copied for tools. A placeable torch is
also real — `buildables.json:121-133`, free to build.

**This supersedes `OF24`, and that should be said out loud rather than quietly
undone.** `OF24` was itself an explicit owner directive — *"Torch building should
be free"* — and `buildables.json:133` records it verbatim. The newer word wins
(the same rule D23 applies to the spec), but leave the old `_comment_free` in
place with a note naming this item, so the reversal is legible to whoever reads
that file next.

Working assumption, cheap for the owner to reverse in one line: the carried torch
becomes the real one and reaches the hand from the inventory the way a tool does;
the buildable is retired rather than kept as a second path. If retiring it
strands camp lighting at night, say so instead of inventing a replacement.

**Done when** a player can take a torch out of the backpack and carry it lit,
and is not offered a torch to build.

### OW3 — The whole map is revealed before you explore anything
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in the corridor merge `d4de94a3`. Verified in the tree, not by branch ref.

`model: sonnet` · `tests: smoke_menu` · `area: ui`
Owner: *"The full map is rendered before I explore anything."*

**Confirmed in code, not just reported:** `scripts/world/map_baker.gd` contains
no fog, reveal, explored or discovery logic of any kind. Spec §16's rule — the
map reveals explored areas and landmarks and *never reveals everything
automatically* — was never built. This is the surviving half of `R7.4` and the
owner has now hit it; do that item's remainder here.

### OW5 — The Meadows should be a long journey from home, not a compact square
`model: fable` · `tests: smoke_traversal` · `area: terrain`
**The owner's world-shape directive, and the largest item in this phase.**

Owner: *"The meadow needs to read as a long journey away from home ending at the
stronghold. But the whole area should be a big square. It's a long trail working
progressively further from Grandpa's house. You can go off the trail for
different tasks. It can wind and fork and whatever but this should be the
general layout. Walking end to end should take several in game days so you have
to camp along the way."*

**SUPERSEDED IN PART, 2026-08-16, by the owner in conversation. The square is
gone.** Recorded here because it existed only in a chat thread, and a decision
document was already citing it while this entry still said the opposite — the
same failure that made a sibling session paint the roster against boards it
could not see (`docs/HANDOFF_2026-08-16_colour_and_brief.md`). His words:

> *"the world should be long but can be narrow with broken land or sea off the
> path in either direction. it doesn't have to be a giant square. it should be
> long as I've stated but can be significantly less wide. like maybe it's five
> minutes of walking from side to side."*

> *"a day from midnight to midnight should take about 10 minutes. a walk from
> the end of the meadows to the other end should take 40 minutes."*

At `walk_speed` 5.0 and `day_length_seconds` 600 that is **~12,000 m of trail**
and **~1,500 m of width**. Everything else below stands.

One arithmetic caution for whoever sizes it: 40 minutes is a *walking* figure,
and a player who cycles sprint sustains about 7.0 m/s once
`stamina.regen_delay` 1.1 and `regen_per_second` 18 are both counted — roughly
28 minutes for the same trail. Size to the directive, but know the spread.

So: a long, narrow **corridor**, with a winding, forking **trail** through it
that carries the player progressively away from home and ends at the stronghold.
Off-trail is where optional work lives, and the flanks are broken land or sea.
The end-to-end walk must be long enough that camping on the way is forced rather
than optional — which is what finally gives `camp` a job beyond the first night,
and what makes the stronghold read as far away instead of nearby.

This supersedes `R7.3`'s framing. R7.3 keeps only its bake-and-capacity half
(does the terrain footprint and Terrain3D region count support this, and what
does it cost on the Ally). **The shape is this item.**

Read `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §5 (`MQ2A`, the Meadows
macro-world redesign) before starting — it is the existing quality brief for
exactly this work and it says START WITH FABLE.

**Done when** walking the trail end to end takes several in-game days, the
stronghold is visibly the far end of a journey rather than a neighbour, and the
existing regions (quarry, warrens, river, relay, Ironwood) hang off a trail
rather than sitting near the start.


**A constraint `OW5C` inherits from `OF15` (added 2026-08-16).** The player's
`floor_max_angle` is 45 deg, and a confirmed wedge at (60, -106) on the rocky rise
turned out most likely to be slope rather than props — a route crossing ground the
character controller refuses to climb. **No trail segment may cross ground steeper
than `floor_max_angle`.** Assert it with a probe over the candidate route *before*
the bake, not by walking it afterwards: `height_at` is analytic and unbounded, so
the whole spine can be sampled without baking anything, and at hours per bake that
is not optional. A trail that is 12 km long has 12 km of chances to make this
mistake once.


**STATUS, 2026-08-17. The corridor is BUILT and does not yet land.**

- `OW5A` — the macro layout, measured and region-aligned. **Landed.**
- `OW5B` — the footprint and the bake. **Built.** 8192 x 2048 m, `world_bounds`
  x [-1024,1024] z [-512,7680], **64 baked region files committed** against
  main's 4. The bake was also factored to take a region set, with a bit-identity
  test, so a future edit costs ~143 s a region instead of 153 minutes.
- `OW5C` — the trail, the loops, the edges. **Built.** `trail.bands[]` is the
  spine, `trail.loops[]` the regional loops, `trail.shortcuts[]` the quarry haul
  road and the river ferry; they join the road set through
  `playground_heightfield.road_polylines()`, never as `paths.routes` entries,
  because `signpost.gd` fits four arms.
- `OW5D` — the §10 relocation. **Built**, and honest about its own gap: its
  `spawns.json` comment records that *"Ground truth at every new site was NOT
  re-probed by this pass"* and that test files were out of scope.
- `OW5E` — **OPEN, and the only thing between the corridor and `main`.** See its
  own entry below.
- **The end-to-end check is still owed** and is the thing that proves this
  worked: walk the trail in-engine with a probe measuring real path length,
  side-to-side width and elapsed in-game days, and confirm 40 minutes end to end
  and about 5 side to side **against the actual route**, not the design document.
  Filed as `OW5-walk`.


### OW5E — make the relocated world pass its own tests
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in `d4de94a3`, CI run 1349 green
on all 19 jobs — the first fully green run the corridor has ever had. All six
jobs fixed. Two of them were not the corridor's fault and are worth keeping in
mind: `verify-unit-tests` was two stale test assertions (`test_map_state.gd`
failed to PARSE on a removed `GRID` const, silently skipping all 21 map-state
tests including the save-format ones), and the duplicate `vegetation.build()`
it found came from a coordinator merge resolution, not a lane. Two further real
bugs were found by walking the re-baked ground: `world_perimeter.gd` queried
height exactly on the baked grid's EXCLUSIVE edge, so all 55 south-cap collision
segments took one flat wrong height and a player could step over the wall into
the void; and `smoke_boss.gd`'s `BARRIER_LIMIT_M` had been computed from carve
config that postdated the only bake in existence, never measured.

`model: sonnet` · `tests: the six failing jobs` · `area: terrain, tests`
**The corridor cannot reach `main` until this closes.** `ralph/integrate-3` is 24
commits ahead and 6 of 19 CI jobs fail (run 32023204240). They are not the
`verify-aggression` intermittency; they are real, and they split three ways:

**Tests still asserting the pre-corridor world.** `verify-settings`: *"The Pond
is listed at (-342.0,507.0), expected (-92.0,100.0)"*, same for River Road and
Mountain Road. The landmarks moved correctly; the test hardcodes old
coordinates. Derive the expectation from config the way `OW3` just taught
`test_map_state.gd` to, or this breaks again at `OW6`.

**The world genuinely wrong at a new site.** `verify-warrens`: *"the deepest
chamber is not under the hill (terrain y=-4.2 vs floor y=-3.8)"* — a dungeon
poking out of a hillside. `verify-relay`: *"the player climbed onto the
apparatus pad from the yard; the traversal is not the route"*. `verify-boss`:
D41's regrowth clause unpaid. `verify-traversal`: fell through the world at the
south cap; the river divides nothing at two stations; the Old Mill Crossing
cannot be crossed. **Fix the world, not the assertion** — `verify-relay`'s check
is a real design guarantee.

**Probably a test bug — check before touching either side.** `verify-traversal`
probes the river's near bank at **x=1027**, which is outside `world_bounds`
max_x of 1024. And `verify-unit-tests` exits 1 on *"31 resources still in use at
exit"* with RID leaks, which may be shutdown noise (`D06`) rather than a failed
test.

Also surfaced by the same run and worth its own commit: `verify-settings`
reports *"Map is now I — so is Open the satchel. Both will fire."*

### OW5-walk — walk the corridor and prove the forty minutes
**CLOSED 2026-08-17 (OPS11).** Landed on `main` (`86ed571f`..`ee811226`).
The corridor has now been walked with a real `CharacterBody3D` driven through
the shipped `player_controller.gd` — real capsule, real `floor_max_angle`, real
`_try_step_up`, real `move_and_slide()`, steering by writing `camera_rig.yaw`
and holding `move_forward`. `ground_height_at` was used only to place the body
and never consulted about progress.

**The three numbers, measured:**

| | measured | at `walk_speed` 5.0 |
|---|---|---|
| end-to-end spine, WALKED | **11,316.6 m** | **37.7 min** |
| config polyline, for comparison | 11,516.4 m | 38.4 min |
| in-game days end to end | | **3.77** at `day_length_seconds` 600 |
| width at z 910 / 3600 / 6340 | ~2,041.9 m each | **6.81 min** |

**Length passes: 37.7 against the owner's 40**, 6% short, and the walk tracks
the authored polyline at 0.983 walked/config — so the arithmetic was never wrong
about distance. **Width misses: 6.8 min against "maybe five minutes", 36% too
wide**, uniformly at all three stations. See `OW5-width`.

**Two probe traps worth keeping**, both of which produced a wrong number before
the lane caught them: the world *moves* the body (`CarveFailsafe` writes
`global_position`) and a naive displacement sum credits every recovery to the
corridor's length — steps above 2 m in one tick are now counted separately, and
that count is what named the river defect. And an escape that must be repeated
is not an escape: the unstick routine reported success 653 times at one spot,
frame-by-frame honest and completely useless.

**Runtime, for whoever walks it next:** headless throughput measured at 56–73
physics frames/sec, so 11.5 km at the real walk speed costs ~30 minutes of wall
clock. No speed scaling or teleporting was needed. Keep it a `tools/_probe_*`;
do not extend `smoke_traversal.gd` to do it.

**What it did not cover:** the spine only — not the 10 loops or 2 shortcuts —
and the spine starts at z −16 while the world runs 496 m further north.

### OW5-walk — the original entry
**START HERE (OPS4, 2026-08-17).** `OW5E` has landed, so this is unblocked and
it is the corridor's exit gate: the whole 8192x2048 m world is now on `main` and
**nobody has walked it end to end.** Every number behind it is still arithmetic.
Until this runs, `OW6` (the captain onto the trail) and `MQ2B` are building on an
unverified route.

`model: sonnet` · `tests: new probe` · `area: terrain`
The owner's original ask, in his own words, and still unverified against
anything but arithmetic. Once `OW5E` lands: drive a body along the real trail
and measure **actual path length, actual side-to-side width, and elapsed
in-game days**, then compare against 40 minutes end to end and ~5 minutes across.

Do not measure the design document. `OW5A` computed an 11,594 m spine and a
27.9-degree worst slope from the config; this item exists because a route that
computes correctly can still fail to be walkable — which is exactly what the
phantom wall turned out to be, three wrong diagnoses deep.

### RIVER-GATE — the river is a one-way wall, and the authored crossing cannot be crossed
`model: opus` · `tests: smoke_traversal, new` · `area: terrain, world`
**NEEDS AN OWNER DECISION BEFORE THE FIX. Filed 2026-08-17 (OPS11) from
`OW5-walk`, and it closes `OW5C`'s three-failed-fixes entry — it was never a
seam.**

At Old Mill Crossing `(-145.5, 4195.7)` the first end-to-end run logged **712
recovery teleports at one spot** and would have looped until timeout.
`get_slide_collision()` returns **zero colliders** — nothing is touching the
body — because the thing stopping it is not a collider. `river.gd:60-101` builds
a chain of abutting `CarveFailsafe` **Area3D** volumes along the *entire* river
course via `severed_spokes.gd::_add_carve_failsafe`, each writing
`global_position` on `body_entered` to put the player back on the village bank.
The spine's crossing walks straight into that chain, and recovery always aims at
`VILLAGE`, so **the river cannot be crossed southward here in either lock
state.**

**This reframes `OW5C`'s other river finding rather than contradicting it.**
"The river divides nothing" at the open-water stations and "the river is
absolute at the crossing" are both true: the failsafe chain spans the channel
between the rims, so a body on the open bank never enters it and a body that
descends at the authored crossing always does. Section 9's premise is not
un-built — it is **inverted**. The barrier works where it should not, and the
crossing does not work at all.

**NO OWNER DECISION IS NEEDED — corrected 2026-08-17 (OPS12), after actually
reading the docs.** This entry and the coordinator's report both said the fix
needed a design call. That was wrong: the design is fully specified and almost
entirely built, and what is missing is one hole in one volume chain.

**The plan, from the documents:**

- `docs/decisions/D46` — *"The only ground link between the near Meadows and the
  far bank is the Old Mill Crossing (`SE22`), which is shut until the Mill
  Bridge Gear is in the satchel."* The river dividing absolutely is the whole
  point of D46; it deliberately cost one severed spoke (the storm road) to
  achieve, chosen by searching every bearing at 1° and every offset at 2.5 m.
- Spec §Band 3 (The River Lock) — Team Tether holds the crossing, the bridge
  keeper is captured; clearing the **Tether Relay Station** frees the captive,
  who *"restores or provides the Upper Crossing Key / Mill Bridge Gear"* and
  **the crossing opens**.
- Spec Gate 1 — the earlier **South Bridge** is the same grammar: *"a physical
  key/mechanism, not a UI level lock"*, its key from Oskar the Bridgehand.

**And the machinery already exists.** `scripts/world/gated_crossing.gd` is the
shared base with `key_item_id` and an open flag; `south_bridge.gd` passes
`("south_bridge", "south_bridge_key", "south_bridge_open")`; `mill_crossing.gd`
declares `MILL_KEY_ITEM := "mill_bridge_gear"`; and `data/dialogue/relay.json:26`
grants it — `give:mill_bridge_gear:1` — on the rescue line, gated on the relay
captain's defeat flag (`relay_site.json:42` explains that wiring in full). The
whole intended chain is built.

**So the defect is narrow and mechanical.** `river.gd:60-101` adds one
`CarveFailsafe` volume per course segment with `end_fade: 0.0` so consecutive
volumes **abut** — deliberately gapless, *"or a player lands in the gap between
two boxes and the failsafe that exists for exactly that never fires."* Nothing
excepts the authored crossing. `old_mill_crossing`'s `channel.failsafe: false`
only stops `_crossing_carve` adding a **second** failsafe; it does not subtract
the river's. So the river's chain spans the one gap the crossing exists to
provide, and recovery always aims at `VILLAGE`.

The file's own header states the intent it then fails to honour: *"Fall in, wake
up on the side you started from, walk to the Old Mill Crossing like everyone
else."* Today there is no walking to it.

**The fix: punch a hole in the chain at each authored crossing, and let the
existing gate do the gating.** Two mechanical questions for the implementer, not
for the owner — exclude the crossing's deck footprint from the chain, or cap the
volume ceiling below the deck (`lip_y - LIP_CLEARANCE`); and keep catching a
player who falls in *beside* the deck, so the hole is the deck's footprint and
not the whole segment. Acceptance is both lock states: locked stops the player,
unlocked lets them across.

### SPINE-WEDGE — bodies stop on walkable ground at four places on the spine
`model: sonnet` · `tests: smoke_traversal, new probe run` · `area: terrain, collision`
Filed 2026-08-17 (OPS11) from `OW5-walk`. **This is the `WALL1` class of defect
again, and this time there are coordinates and normals for every instance.** All
four are terrain, all at angles well inside the player's 45° `floor_max_angle`,
and the worst ends with `on_floor=false` and **zero colliders**:

| where | surface | normal from up | trail lost |
|---|---|---|---|
| stronghold gate approach, six wedges at (−30..−34, 7513..7519) | `Terrain` | 12–17° | **57.6 m — the last 57 m to the gate** |
| South Bridge (5.5, **−13.0**, 1333.7) — the body is down *in* the gully | `Terrain` | 16° | 26.9 m |
| (336.3, 5.7, 3749.8) | `Terrain` | **4.6°, nearly flat** | 17.0 m |
| (−417.0, −3.1, 2465.9) | `Terrain` | 11.6° | 5.1 m |

South Bridge is not a regression of `OW5C`'s lock fix — that fix measured a real
before/after and is not in question; walking end-to-end simply arrives
differently, falls into the gully and cannot climb out.

**Do not sample `ground_height_at()` to investigate this** — that scalar misled
three separate investigations of the phantom wall. Re-run
`tools/_probe_ow5_walk.gd` (`--mode=spine --z_from/--z_to` walks a window, ~30
min for the whole spine, far less for one window) and read what the physics
engine reports.

**The stronghold one is the most urgent** because `OW6` places the captain along
that route, and today the final approach to the gate is not walkable.

### SPINE-LAYOUT — the trail runs through a building and past a post standing on it
`model: fable` · `tests: smoke_traversal` · `area: terrain, village`
Filed 2026-08-17 (OPS11) from `OW5-walk`. Both are authored placement, i.e.
layout questions rather than bugs, which is why the walking lane correctly left
them alone:

- **The spine runs into the Burrow Warrens' own structure.** Between wp30
  `(-420, 2470)` and wp31 `(-330, 2630)`, collider
  `BurrowWarrens/@StaticBody3D@3458`, contact normal 90° from up — a vertical
  wall. **173.4 m skipped, the single largest gap on the spine.** Not terrain,
  not scatter: the building. Either the trail routes around the Warrens or the
  Warrens gains a way through.
- **A signpost stands on the trail it labels.** `TrailheadSignpost_14/Post_Collision`
  collides at `(0.2, 6999.5)`; spine waypoint 71 is `(0, 7000)`. The body got
  around it, so it is an annoyance rather than a blockage — but it is a post on
  the centreline of its own road.

### RIVER-OVERHANG — the river is authored past the edge of the baked world
`model: sonnet` · `tests: none` · `area: terrain`
Filed 2026-08-17 (OPS11) from `OW5-walk`. `river.course` runs to x ±1150 while
the baked region grid is valid to ~±1022, so three course points sit outside the
world and every boot prints `carve failsafe at (1090.0, 4100.0) has no ground to
measure; skipped`.

**This fully explains `OW5C`'s "a third station reports no ground at all
(1027,4101)"** — that reading is the authoring overhang, not a hole in the
world. Nothing is red today because `smoke_traversal.gd::_pick_river_stations`
excludes it via `RIVER_EDGE_MARGIN` 40. Clamp the course to the baked extent and
the boot noise goes with it.

### OW5-width — the corridor is 36% wider than the owner asked for
**CLOSED 2026-08-17 (OPS12) by the owner: "the width is fine as is."** The
measurement stands — 2,041.9 m, 6.81 min, at all three stations — and the
five-minute figure is superseded rather than missed. **Do not narrow the world
or re-bake for width.** What the measurement still buys is the flanks: 500 m of
currently-bare ground either side of the trail is `VEG-CORRIDOR`'s and `MQ3`'s
problem now, not a reason to change the footprint.

`model: fable` · `tests: smoke_traversal` · `area: terrain`
**Filed 2026-08-17 (OPS11) from `OW5-walk`'s measurement.** Owner's words: *"maybe it's five minutes of walking from side to
side."* Walked: **2,041.9 m, 6.81 min**, at all three stations, agreeing to
0.1 m — the body walked a dead straight line across the corridor everywhere and
nothing blocked it, so this is the authored width, not an obstacle artefact.

**Nobody ever chose 2,048 m.** `world_bounds` x [−1024, 1024] is simply where
the perimeter went when the footprint was made region-aligned, and nothing
measured it against the five minutes until now. The owner's figure implies
~1,500 m.

It misses in the direction that costs most: **1.4 extra minutes of empty walking
per crossing, in a corridor whose length is already right** — and the flanks are
currently bare (`VEG-CORRIDOR`), so that width is 500 m of nothing on each side.

**Three options, and the choice is the owner's:** narrow the world (a re-bake,
and 2,048 → 1,536 is not region-aligned — 1,024 is, so this is not a free dial);
keep the width and fill the flanks so the crossing earns its time; or accept
6.8 min and treat the five-minute figure as superseded. **Do not re-author the
world to make a number come out right without asking.**

### OW6 — The captain you can challenge is too close to the start
`model: sonnet` · `tests: none` · `area: village`
Owner: *"The captain to challenge is way too close to where you start. You need
to work to find him."* Positions are data (`data/config/trainers.json`), so this
is a placement change once `OW5` establishes the trail — sequence it after, or
it gets moved twice.

**UNBLOCKED but constrained, 2026-08-17 (OPS11).** `OW5-walk` has measured the
route: 11,316.6 m walked, 37.7 min, so there is a real trail to place against
and the distance is trustworthy (walked/config 0.983). Two things it found bear
directly on where the captain can go:

- **The last 57.6 m to the stronghold gate is not walkable** (`SPINE-WEDGE`, six
  wedges at (−30..−34, 7513..7519)). Do not place him past that until it clears.
- **The spine cannot be walked south past Old Mill Crossing at all**
  (`RIVER-GATE`). A captain placed beyond z 4196 is currently unreachable on
  foot, however far along the trail he looks in the config.

`trainers.json` is also now band-split (`BAND-SPLIT`) — edit the band file, and
take an `order` from that band's reserved range.

## Phase -1.45 — measured performance, and what three blind reviews found

Filed 2026-08-16 by the coordinating session. Everything here is measured, not
suspected; the numbers are in each item.

### CAP1 — a capture scene for interiors, so a room does not cost a world
**CLOSED 2026-08-17 (OPS8).** Landed on `main` in `cab638ae`.
`tools/capture_interior.gd` builds only what an interior needs — the sky/sun/fog
rig, the camera rig and its `set_target(target, profile)` seam, a bare player
body, and `grandpa_house.gd` at the origin. Measured warm, same import cache
both paths so only the world-build step differs: **10m35s → 1m12s for three
frames, 8.8x.** `PT-03`'s 24–32 min figure was cold, where the gap is larger.

`model: sonnet` · `tests: none` · `area: perf`
`PT-03` spent **24–32 minutes booting the whole Meadows** — terrain, 23,707
scatter instances, the village — to photograph the inside of one room. Every
future interior task pays that, which is the kind of cost that quietly stops
people taking frames at all. A scene that instantiates only the interior under
test plus its camera profile would boot in seconds. `grandpa_house.gd`'s
kit-owns-the-exterior/script-owns-everything-else split is what makes this
possible; `tools/capture_loft_exit.gd` is the worked example to generalise.

### PT-03-remainder — the stair affordance failed its blind pass
`model: fable` · `tests: smoke_opening` · `area: village`
`PT-03`'s root cause is correct and settled — the loft slab occludes every tread
from a standing eye, so no light could ever have worked, and `D52` records the
measured sightlines. **The affordance does not.** A blind critic given the pair
unlabelled: *"a post is not an exit — it doesn't say down, it doesn't say
through, it doesn't say walkable. 0/10 before, 2/10 after. That is not the
difference between lost and found."* A frame aimed **straight down the −51°
bearing at the stair head** still shows no treads, no descending rail and no
opening — so this is not "the player is facing the wrong way."

The evidence says the honest question is not a stronger rail but whether **the
loft slab's edge has to change shape** — a cut-back, a visible stairwell
opening, or the camera bias that was rejected. That is a decision about the
room, and it is the owner's.

Also open from the same pass, and separate: the interior camera profile spends
the bottom half of frame on empty floor with the player's head at the very
bottom edge. Predates this item.

### OW1-remainder — the backpack's remaining legibility defects
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in the corridor merge `d4de94a3`. Verified in the tree, not by branch ref.

`model: sonnet` · `tests: smoke_menu` · `area: ui`
From the blind usability pass, judged at 40% scale as a seven-inch proxy. Two
are genuine defects rather than opinions: **nothing shows *what* you are
holding** (the source tile keeps its full count, no ghost, no cursor — so a
player who misses the text thinks nothing happened), and **the quick bar gives
all five chips the same cyan** while a stack is held, so "cursor is here" and
"valid target" are the same colour — `_refresh_quick_bar()`'s
`_slot_style(_bar_focused == i or _held >= 0)`, a two-line fix.

The rest: Escape silently stops meaning Close while holding; the 1–5 badges are
4–5 px and the font renders "4" like a Cyrillic Ч; "6 of 24 slots used" and
"GEAR" are unreadable at 40%; the held state is announced in four places; "6
Orb" should be "6 Orbs"; the screen is Backpack while the grid inside is
Satchel; and `Menu + View held, or F10 Reset all controls` is a leftover from a
controls screen sitting in an inventory footer.

---

## Phase -1.40 — the phantom wall, and three diagnoses that were wrong

Filed 2026-08-17. **Every item in this phase corrects an earlier confident
answer, including two of the coordinator's own.** Recorded that way on purpose:
the sequence of wrong diagnoses is the most useful thing here, because each was
plausible and each cost work.

> **CHECK THE TREE BEFORE WORKING ANY ITEM IN PHASES −1.40 THROUGH −1.45.**
> Added 2026-08-17 (OPS9), after it caught two lanes in one hour. These phases
> were filed in a burst on 2026-08-16/17 during a run that was landing a commit
> every few minutes, and **several items were fixed by commits that landed
> within the hour while the entry still read as open.** `TEST2` was filed at
> `bbc6b850` and `UI-PAD1` — the very next commit, 40 minutes later — closed
> two of its four named gaps; the `TEST2` lane found this only because it
> checked each one against `main` first. `UI-PAD3` then turned out to be
> shipped in full. Neither is a bookkeeping slip to tidy: an item that reads
> open and is done sends a lane to write code that already exists, and the
> lane will usually write it rather than argue with the queue.
>
> So the first step on any item here is `git log`/`git grep` against `main` for
> the thing the item says is missing. **Reporting "already shipped, here is the
> SHA" is a complete and valued outcome**, and is faster than the work.

### UI-PAD3 — `ui_accept` cannot replace a poll on a screen with no Button to press
**CLOSED 2026-08-17 (OPS9). It was already shipped when it was filed** — verified
in the tree, four checks, not by a branch ref:

- `tab_backpack.gd`'s `menu_confirm` **poll is gone**; the only two remaining
  mentions are footer label strings (`:1083`, `:1319`), which is exactly the one
  removal this item prescribed.
- `starter_picker.gd`, `combat_hud.gd`, `name_prompt.gd` and `tab_creatures.gd`
  all still carry their polls, which is what the item says must happen.
- `test_controls.gd` carries both `test_no_two_menu_context_actions_share_a_button`
  (widened past keyboard, :308) and `test_ui_accept_still_answers_the_keyboard`
  (:362) — the trap-guard this item named.

`model: sonnet` · `tests: test_controls` · `area: ui`
**Corrects `UI-PAD1` as filed by the coordinator**, which said: add the joypad
binding, then remove each now-redundant `menu_confirm` poll in the same change.
The lane checked before deleting and found **four of the five polls must stay** —
removing them would have broken three working screens:

| screen | why |
|---|---|
| `starter_picker.gd` | 0 Buttons — the orbs are custom-drawn. The poll is the only input it has. |
| `combat_hud.gd` | 0 Buttons — the switch selector is custom-drawn. Same. |
| `name_prompt.gd` | 0 Buttons — on-screen keyboard, already device-guarded. |
| `tab_creatures.gd` | Has Buttons, but `_begin_evolution` sets `_list.visible = false`, so nothing is focusable during the ceremony. `_end_evolution` re-grabbing focus is the tell. |
| `tab_backpack.gd` | Has Buttons **and** the rows are focused. The only genuinely redundant one. Removed. |

**The rule:** `ui_accept` can only replace a poll on a screen that has a
focusable `Button` for it to press. Check for `Button.new()` before deleting
anything.

**And the double-confirm everyone braced for does not arise**, for a reason
worth keeping: **Enter has always been both `ui_accept` and `menu_confirm` on
the keyboard.** Any screen with a focused Button beside a `menu_confirm` poll
would already have been firing twice for every keyboard player — and none was.
Adding JOY:0 makes the pad behave exactly as the keyboard already did. *When
weighing whether a new pad binding will double-fire, ask what the keyboard
already does first; it is usually already the answer.*

**One trap, now pinned by a test:** listing a built-in `ui_*` action in
`project.godot` **replaces** the engine defaults rather than adding to them.
`ui_accept`'s Enter / KP-Enter / Space survive only because `UI-PAD1` restated
them by hand; dropping one would quietly take Enter away from every menu in the
game. `tests/test_controls.gd::test_ui_accept_still_answers_the_keyboard` holds
that line.

### PT-17-test — the rename flow has no test for its own trigger path
`model: sonnet` · `tests: new` · `area: ui`
Flagged by the lane that rebased `PT-17`, about work it did not write: the
original commit added no dedicated test for the `tab_creatures.gd` rename flow
itself — H-key → prefilled `name_prompt` → `set_nickname`. Existing tests cover
the nickname mechanism generically, not that trigger path. The gap predates the
rebase and was correctly judged outside "make it landable".

### OPS3 — the unit suite takes nine minutes under load, and looks hung
`model: none (note)` · `area: ops`
`tests/run_tests.gd` took **over 500 s** on a loaded container and was killed
once by a lane that believed a global input change had deadlocked it. It had
not: it completed in ~9 minutes reporting 959 tests / 80,924 assertions / 0
failed. Companion to `OPS2` (concurrent headless runs corrupting each other's
script loading). **Give the suite room before concluding it hung**, and
serialise runs.

---

## Phase -1.41 — what the UI lane found on its way out

The four owner-reported UI items shipped in one lane on 2026-08-16 (`OW11`,
`OW10`, `OW4`, `OW8`). On finishing, that lane was asked to write down what it
had learned that did not belong in a diff. **What came back was larger than the
four items it had just closed**, and none of it would have survived otherwise —
which is the whole argument for `LANE1`'s notepad. Verbatim record in
`ralph/NOTES.md` on `ralph-status`.

### TEST2 — four tests that passed while the thing they name was broken
`model: sonnet` · `tests: the ones named here` · `area: tests`
Companion to `TEST1`, which asks the same question of the smoke suite generally.
These four are specific, found the hard way, and each is a distinct shape:

1. **No test in this repo chooses a build piece through input.**
   `tests/smoke_free_build.gd` calls itself "the menu-driving shortcut of arming
   `pending_build` directly" (~:152), and `tests/smoke_build_menu_footprint.gd`
   calls `menu.call("_select_category", i)`. That is exactly why a build menu no
   controller can operate has been green this whole time.
2. **`InputEventAction` hides every binding bug.** `tests/smoke_menu.gd` drives
   the backpack target picker end to end and asserts the heal lands — and passes
   on code where a pad could not confirm at all, because `InputEventAction` names
   the action directly and never travels the `InputMap`. **Any test asserting
   "the player can do X" with an action event asserts something weaker than it
   reads.** `tests/smoke_backpack_pad_target.gd` is the pattern to copy: real
   joypad events, button indices read from the live `InputMap`.
3. **`test_controls.gd::test_no_two_menu_context_actions_share_a_keyboard_key`
   only sees keyboard.** It does `var key := event as InputEventKey` and
   `continue`s on anything else, so joypad collisions are invisible. Its own
   failure message talks about a verb being "dead" — the exact bug that then went
   unnoticed on the pad side. Widening it to joypad buttons is cheap.
4. **`OW8`'s own test is weaker than it looks, recorded by its author.**
   `tests/smoke_prompt_hotbar_dock.gd` fails on pre-`OW8` code *only* on its
   structural assertion; all four rect-intersection cases pass there, because
   `_reflow_prompt` recomputes from the hotbar's live rect on `resized` and the
   harness grants the frames. **That is why the two previous OW8 fixes tested
   green and still failed on the owner's hardware, twice.** Anyone judging that
   fix by the rect cases alone concludes there was never a bug. The shared-parent
   assertion is the load-bearing one.

### OPS2 — two concurrent headless Godot runs corrupt each other's script loading
`model: sonnet` · `tests: none` · `area: ops`
Two concurrent headless runs on a four-core container produced
`Attempt to open script ... resulted in error 'File not found'` for a file
present on disk; re-running serially passed. Every lane brief now says serialise
your runs, but that is instruction, not enforcement. **If a smoke test dies with
a missing-script error, check what else was running before believing it** — this
is a plausible source of "flaky" CI that is not flaky at all.

---

## Phase -1.42 — the tourniquets, and the questions nobody asked

Filed 2026-08-16 by the coordinating session, as a self-audit rather than as
new work discovered. Every item here exists because a fix that shipped today
was a *workaround*, and the thing it worked around is still standing. They are
filed so the workarounds cannot quietly become the design.

## Phase -1.4 — the blind playtest's open findings (2026-08-15/16)

Full record in `docs/reviews/2026-08-15-full-blind-playtest/`. The six repairs
that pass already shipped; these are §7's leftovers. `PT-03` is the one the
report calls the highest-value remaining fix for a first-time player.

## Phase 7 — the village lives, the meadow reads

### R7.4 — Map reveal rule · `model: sonnet` · `tests: smoke_menu` · §23
**CLOSED 2026-08-17 (OPS7), on this item's own terms.** Its last line says to
close it if the fog already behaves, and it does: `5cb90968` ("OW3: the map
hides what you have not walked, and walking reveals more of it") is an ancestor
of `main`.

**The check below sends you to the wrong file, which is worth keeping rather
than quietly deleting.** `map_baker.gd` still contains no fog, reveal or
explored logic — grepping it, exactly as instructed, returns nothing and would
have you conclude the feature was never built. `OW3` put the reveal in
`tab_map.gd` and `minimap.gd` instead, which is the right place: the baker
renders the world once, and what the *player* has seen is view state, not
terrain. A closing check that names a file rather than a behaviour will keep
doing this.

**Re-scoped 2026-08-16.** The old text said the `map` action was "read by
nobody" — false since the map button was wired. The map, the minimap and the
player's heading arrow all exist and work.

What survives is only spec §16's rule: the map reveals explored areas and
landmarks and **never reveals everything automatically**. Check
`scripts/world/map_baker.gd` before writing anything — if the fog already
behaves, close this item.

### OF15 — Geometry snags: player can get stuck in places
`model: sonnet` · `tests: smoke_traversal (extend)`
Owner-reported, 2026-08-15. Movement getting wedged/blocked rather than passing
through. Needs locations logged from a fresh playthrough before a fix can be
scoped.

**CLOSED 2026-08-17 (OPS4).** The detector landed on `main` in `05264fda`, and
porting it taught something worth keeping: **its exclusions had to be re-derived,
not copied.** `STUCK_EXCLUDE_RADIUS` was a 200 m radius because the world was a
disc with a ring fence; the corridor has no centre. And it had no slope
exclusion at all — it never needed one on the old gentle disc, but the corridor
is built out of deliberately unclimbable rises, and ported as-is it reported
three wedges on correct terrain near (62,-105), where the ground climbs 7.1 m
over 8 m and a shape query finds no prop at all. Now excluded by edge margin and
by a slope probe sampled at **both** 4 m and 8 m — one ring is not enough.

**SOLVED 2026-08-17 — it was Captain Halder, and it took four diagnoses.**
`WALL1` found it: `spawns.json`'s seeded rng resolved Galecrest's home to 3.15 m
from a captain `trainers.json` hand-places at `[52.0,-122.0]` with a real
0.36 m capsule collider. The chase ran through his body. `is_on_wall()` was
true because there really was a wall — just not a terrain one, which is why
every terrain-side investigation came back clean. A frame-by-frame slide dump
named `Captain Halder/Body` on every residual frame.

The three wrong answers before it, kept because the sequence is the lesson:
props (a spacing filter was built and measured working, and the wedge survived
it); terrain slope (disproved — the ground reads 5-11 degrees and the wedged
body ran a MORE permissive 55-degree limit than the player's 45); collision
shape seams (a real and independent defect — `collision_shape_size` had been
silently stuck at 16 m, never the 256 the code believed, because the setter is
a no-op out of the tree — worth fixing on its own and it halved the residual,
but not the cause).

Closing this item. What survives it is a rule now in `OW5`: **a route is not
proven walkable by sampling the heightfield.** `ground_height_at()` lied to
three separate investigations. Walk a body and read what the physics engine
reports.

Superseded detail from 2026-08-16, kept for the record: A lane confirmed
the wedge at **(60, -106)** and **(65, -108)** and blamed clumped tree colliders.
A cross-layer spacing filter was built against that diagnosis, measured working
(23,707 placements to 23,650; rocks 345 to 300, trees 129 to 118) — **and the
player still wedges at (60, -106).** So the diagnosis was wrong. The evidence
points at terrain slope on the rocky rise instead: an earlier traversal run ended
that leg at exactly `(60.0, 0.2, -106.3)` after 46 m of a 190 m walk, and a review
of the same ground noted it "snags on the rocky rise". The player's
`floor_max_angle` is 45 deg, so the test may be flagging correct behaviour at a
place a route should never have crossed.

It is parked because **that ground is about to be rewritten.** `OW5B`/`OW5C`
rebake the world and lay a new trail; fixing terrain that is being replaced this
week is wasted work. The durable outcome is a constraint, not a repair, and it is
recorded on `OW5` rather than here: **no trail segment may cross ground steeper
than `floor_max_angle`, and a probe must assert it before the trail is committed.**
Re-open this item only if the wedge survives the rebake.

## Phase 6.5 — the quality plan's own items (owner's quality plan)

**Filed as backlog entries 2026-08-17 (OPS7), after a fresh coordinator found
they were missing.** `MQ1A` and `MQ1B` shipped and were closed out of this
phase, which left the header empty — and `MQ2B`, `MQ3` and `PW2` had never been
transcribed here at all. They existed only in
`ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md`.

**That made this file wrong about the thing it claims to be.** Its first line
says it is the state of the project. A session reading it top to bottom today
would count fifteen open items, most of them small, and conclude the game is
nearly done — while the largest block of remaining work on the project sat in a
planning document with no entry anywhere in the queue. The previous
coordinator's own handover named `MQ2B` and the `MQ3` umbrella as the work after
`OW6`, citing IDs this file did not contain.

The plan stays authoritative for what these mean and what "done" is; these
entries exist so the queue stops omitting them. Do not duplicate the plan's
prose here — read §6, §7 and §8 there.

### BAND-SPLIT — one content file per band, so bands can be authored concurrently
`model: opus` · `tests: run_tests, smoke_playground, smoke_traversal, a new identity test` · `area: data, world`
**Owner-requested, 2026-08-17:** *"can you fan out agents to do the corridor
design work concurrently. so each agent builds a separate band then they all
come back and we have the full corridor?"*

That is the right end state and the bake already supports its terrain half —
`OW5B` factored the bake to take a region set with a bit-identity test, because
every pixel is computed from its own coordinate and nothing else, so adjacent
regions baked independently agree exactly at the boundary.

**What blocks it is data layout, not agents.** All Meadows content lives in four
monolithic top-level arrays — `spawns.json` (`spawns`), `props.json`
(`clusters`), `harvest.json` (`nodes`), `trainers.json` (`trainers`). Every
band's content goes in the same arrays in the same files, so five band agents
would edit all four files continuously and conflict on every one. **File
exclusions are the mechanism that actually keeps this project's lanes off each
other, and they cannot help when the unit of exclusion is a file and the unit of
work is a band.** This item makes the unit of ownership match the unit of work.

**The load-bearing requirement is identity, not tidiness.** The merged result
must load identically to today — same entries, same values, **same order**.
Order is not cosmetic here: `spawns.json` resolves creature homes through a
seeded RNG, and `WALL1` was ultimately a spawn landing 3.15 m from a hand-placed
trainer. A merge that changes iteration order moves seeded placement, and the
world changes with nobody editing content. Prove it with a test that is
demonstrated failing, not by reading the diff.

**Scope guards.** Author no content — not one spawn, prop, node or trainer; that
is `MQ2B`/`MQ3` and it is fable work. Keep genuinely global keys (`trainers.json`'s
`flow`/`prompts`, `spawns.json`'s `respawn_seconds`/`roles`) in one place rather
than sharding them into five copies that can drift. `vegetation.json` is scatter
*rules*, not placements — leave it alone; its problem is `VEG-CORRIDOR`.

**Done when** five disjoint file sets exist, one per band, an identity test holds
the merge honest, and the next coordinator can hand five agents five bands
without a shared file between them.

### CI-BOSS — `verify-boss` is intermittent, and it has now cost two innocent branches
`model: sonnet` · `tests: smoke_boss.gd itself` · `area: tests, ops`
Filed 2026-08-17 (OPS13). **This is `TEST1`'s question answered by a second
example, and it is no longer a suspicion.**

| branch | its own diff | run | outcome |
|---|---|---|---|
| `ralph/TEST2` | two test files, `project.godot` untouched | dispatch failed, **green on re-run** | not its diff |
| `ralph/PT-17-test` | one new rename test | dispatch failed, re-run requested | not its diff |

Both were green on all 19 jobs on their own push and red only on the
`ralph-merge` dispatch of the same tree. The root failure is a single line —
**"the boss fight never resolved inside 9000 frames"** — and the six `FAIL`s
after it are all consequences of that one, not six independent failures.

**"Never resolved inside N frames" is a timing-dependent assertion**, which is
exactly the shape `TEST1` asks about: which smoke tests depend on a position, a
spawn, a timing window or an RNG draw they do not control? `verify-aggression`
was the first (fixed by `CI-AGGRESSION`); `verify-boss` is the second.

**Why this is worth a lane rather than a shrug:** `ralph-merge.yml` only
fast-forwards fully-green branches, so an intermittent job does not annoy
anyone — it silently stops healthy work from shipping and leaves no trace
saying so. It has now delayed two landings in one evening, and the next lane to
hit it may "fix" its own innocent diff to make the red go away.

**Do not just raise the frame budget.** Find what the fight is actually waiting
on — whether the boss can fail to engage from a given start position, or a
timing window depends on load. The container was under four concurrent lanes
both times, which is itself a clue.

### BAND-SPLIT-2 — the rest of what still makes five band agents collide
`model: sonnet` · `tests: run_tests, an identity test per split` · `area: data, world`
Filed 2026-08-17 (OPS11) from the `BAND-SPLIT` lane's own answer to "will five
agents authoring five bands actually work now?" — *"for the four configs I
split: yes, today. For 'and then combine them into a finished world': not yet."*
**A band author who can add a creature, a prop, a harvest node and a trainer but
cannot add a clearing, a footprint or a landmark can only populate terrain that
already exists.** In the lane's own fix order:

1. **`vegetation.json`'s `clearings` (9) and `footprints` (7)** are positional
   arrays in a monolith — exactly the shape just split — and all sit near the
   origin. Every building, camp or structure a band places needs a footprint or
   grass grows through its floor. A guaranteed five-way collision on one file,
   ~an hour, mechanical: same `order` + per-band treatment, leaving the scatter
   *rules* alone. **Distinct from `VEG-CORRIDOR`** — same file, different
   problem, neither blocks the other.
2. **`data/dialogue/` is already multi-file and already uses this pattern** (an
   explicit const path list merged in `dialogue_runner.gd:32-45`) but is split
   by chapter beat, not band. Every new trainer's conversation lands in one
   `trainers.json` and Band 2 has no file at all. Adding
   `data/dialogue/bands/<band>.json` to that list is small. Do it with (1).
3. **`terrain_playground.json` is the real gate** and is harder: the spine is
   genuinely global — Band N's first point is Band N−1's last — so
   `trail.bands[]` cannot be partitioned. The lane's *guess*, explicitly flagged
   as a guess, is that the derived/decorative arrays (anchors, landmarks, rises)
   are band-local and could be cut the same way while the spine stays whole and
   coordinator-owned. **Measure which arrays are actually band-local before
   committing to it.**
4. **`docs/decisions/` is already colliding on `main` today** with no fan-out at
   all: two `D50-` files and two `D53-` files exist. Five agents each writing a
   decision doc will keep minting duplicates. Cheapest fix is **the coordinator
   assigning the number in the brief**.
5. **The `order` reserved ranges (Band N → `N000`–`N999`) are documented, not
   enforced at author time.** The uniqueness test catches a collision at CI
   time on whichever branch merges second — loud rather than silent, which is
   the right failure mode. **Put each band's range in its brief** rather than
   relying on the author reading a comment.

### VEG-CORRIDOR — the scatter still only dresses a 512 m square at the origin
`model: opus` · `tests: smoke_playground, run_tests, a placement-extent test` · `area: vegetation, terrain, perf`
**Blocks `MQ2B`, and was found by asking what the corridor actually looks like
today rather than what the bake produced.** Verified in code, not inferred:

`playground_world.gd:597` passes `config.get("world_size", 512)` into
`vegetation.build()`, and `scatter_rules.all_placements` → `placements_for`
samples every clump and stray inside `[-half, +half]` on **both** axes, where
`half = world_size * 0.5 = 256`. `world_size` is still 512 on purpose —
`terrain_playground.json`'s own `_comment_world` records `OW5B` keeping it there
because vegetation, the minimap and the map baker all assumed the old square.

The map half of that has since been fixed: `map_baker.gd` and `minimap.gd` now
go through `world_extent.gd`, which reads the corridor's real asymmetric bounds.
**Vegetation is what is left.**

`OW5E` widened exactly one part of this and said so in its own comment
(`scatter_rules.gd:531-546`): an authored **anchor** may now be placed anywhere
in the corridor, checked against `field.world_bounds()` — which is what fixed
the quarry `deadfall` at (403,1803) being silently rejected on every attempt and
`smoke_boss.gd`'s D41 regrowth check finding nothing drained. That comment ends
"This widens what an ANCHOR may pass, not what a clump/stray may sample."

So today: the corridor runs z −512 to 7680, and **all ~23.7k scattered instances
sit in z −256 to +256** — roughly the first 3% of a 7,560 m trail. Everything
past it is correctly-shaped, correctly-baked bare landform with a handful of
authored anchors on it. That is not a quality problem to be tuned; it is a
bound.

**This is why it cannot simply be widened to the corridor and shipped.** Density
that reads well over 512 m becomes ~30x the instance count over 8192 x 2048 m if
naively scaled, and boot already cost 3m08s before the corridor existed
(`PERF2`), with scatter alone at 45 s. The answers interact with the streaming
work already on `main`. Expect this to need per-band density that is authored,
not uniform, and to be measured on the Ally rather than assumed.

**Sequence it after `OW5-walk`.** That lane is measuring real traversal over the
whole corridor right now, and what it reports about distance, collision and
streaming is the input to how this should be bounded. Do not start it blind.

**Done when** the trail is dressed for its whole length, per-band, with the
instance count and boot cost measured before and after and stated as numbers —
and when a placement-extent test fails if the scatter ever silently reverts to a
square again.

### MQ2B — prove one region at finished quality before scaling
**STOPPING RULE CHANGED BY THE OWNER, 2026-08-17 (OPS15).** Verbatim:

> *"the current band we are working on should work until a blind review agent
> determines there's nothing else we can do to make it work more like palworld
> with our current terrain system and assets."*

**So a band is not one authoring pass. It is a loop that a blind critic ends.**
Author, render real frames of the band (day *and* night, real eye height), run
`.claude/skills/visual-judge` told nothing about what changed or what answer is
wanted, fix the defects it names, re-render, repeat.

**The instrument already existed and already does exactly this.** `visual-judge`
compares frames against `docs/reference/palworld-0*.jpg` — five real Palworld
screenshots — and its Bar B is *"Shown these frames beside
`docs/reference/palworld-0*.jpg`, would…"*. Nothing new needed building for this
directive; it named the bar the skill was already using.

**Stop on convergence, not on a round count** (`ralph/conventions.md`): a round
counts as improvement only if the critic names a **new** defect or
`tools/frame_stats.py` shows measured movement on an axis the critique is about.
**Stop after two consecutive rounds with neither** — two, not one, because a
single flat round is often a fix that has not landed yet. Reordered defects,
reworded defects and "still not fixed" are not improvement.

**"With our current terrain system and assets" is the owner's own bound, and it
is the load-bearing half.** It makes *"this needs art that is not in the build"*
a legitimate stopping point rather than a failure. `R9.4` is the precedent: four
uncapped rounds, four blind critics, every measurable axis moved, and both
critics still ranked "needs art that is not in the build" first. It had not
stopped early — it had run out of what tuning could reach. A defect needing a new
mesh, a Meshy generation or a terrain-system change **is the wall**; record it
(`BLOCKED.md` or a labelled remainder) with the round count and what the last two
rounds failed to move, and do not chase past the bound. `CLAUDE.md`'s no-new-
Meadows-meshes and no-generation-without-owner-reference-art rules still bind.

**This rule applies to whichever band is current**, not only Band 2 — it is how a
band is finished from now on.

### MQ2B — the original entry

`model: fable` · `tests: none (playtest gate)` · `area: terrain, world-layout, content`
Plan §6. **Starts with fable — it is ceiling-setting authorship.** Take the first
appropriate Meadows region and finish it to production standard: terrain
composition, vegetation structure, readable paths, a major landmark, an
exploration loop, a reconnect or shortcut, meaningful gatherable placement,
creature habitat, an optional discovery, a memorable encounter, day and night
readability, and no empty filler stretches.

This is the production recipe, not one region's decoration. The plan's expansion
rule is explicit: only after this region passes may its principles be used to
author the remaining bands, and what gets copied is the quality bar, never the
layout.

**Sequence it after `OW5-walk`.** Finishing a region to production standard
along a route whose real length nobody has measured is how content gets placed
twice — the same reason `OW6` waits.

**Done when** a blind playtest spends meaningful time exploring the region
voluntarily rather than following the critical path through it, and can say what
made it visually distinct, what made it mechanically interesting, where they
chose to leave the path, and what landmark they navigated by.

### MQ3 — the Meadows content umbrella
`model: fable` per major content beat · `tests: per unit` · `area: content, quests`
Plan §7. **This is not one task and must not be taken as one.** It is the
creative umbrella over the existing progression-sized units; break implementation
into those units and author them in unlock order, so each section can be played
and judged before later content depends on it. Build progression plumbing first
where still unbuilt — state tracking, keys and gates, quest log, objective
transitions — without over-generalising for a second biome that is forbidden
until the Meadows passes its exit gate.

**The corridor is what makes this large.** The world went from a 512 m square to
8192 x 2048 m yesterday, and `OW5D` relocated the already-approved content into
it rather than adding any. So bands beyond the first are, today, mostly empty
ground. Each region owes a clear entry, a clear purpose, recognisable geography,
one meaningful critical-path objective, an optional discovery, a memorable
encounter, working navigation, day/night usability, a real reason to explore,
and a clear transition to the next.

Side content may be authored before the XP economy exists; reward wiring can land
later, and per the plan the design must not be hardcoded around XP per hour
before `R4.1` provides levels.

### PW2 — alpha / elder wild variants
`model: fable` · `tests: per encounter` · `area: creatures, content`
Plan §8. Folds into `MQ3`'s regional content rather than running as its own pass.
Rare landmark encounters that give optional paths a reason to exist. **No new
Meadows creature meshes** (`CLAUDE.md`, D23) — and explicitly not "normal
creature, larger scale, more HP": each needs at least one real behavioural or
encounter difference, such as a different aggression pattern, altered cadence,
group behaviour, unique habitat, environmental advantage, a move variant, a
special arena, or unusual time-of-day presence.

## Phase -0.6 remainder — the look

### EV9 — Rebuild the HUD, remainder
`model: opus` · `tests: smoke_menu` · `area: ui`
Bible §16–§18. Most of this item shipped across four slices. **Tested at
physical 7-inch scale, not on a desktop monitor** — §17 is explicit.

Genuinely still open:
- `orb_capture` icon has no mount point — there is no orb-count panel anywhere
  in the current HUD to hang it on. Needs a panel first, or the owner naming a
  different place it belongs.
- A branded display font matching the "TETHERBOUND" key-art logotype, and
  gradient/beveled bar fills. The owner supplied a style board
  (`ev9_display_lettering_style_guide.png`) but there is nowhere to apply it:
  the game boots straight into the world (D18) and renders no wordmark
  anywhere. Needs a title screen to exist first, or a different mount point.
- Compass — the bible says "if it exists"; it doesn't, and inventing one is not
  this item's job.

## Phase 8.5 — the chapter's own audit

### SH54 — Audit: nothing in the chapter assumed new creature credits
`model: haiku` · `tests: none`
Spec §38 step 54, §20. Walk every item shipped for this chapter and confirm none
of them installed, requested or planned a new creature mesh. Cheap, and worth
doing once at the end, because the constraint is a budget the owner holds and a
single quiet violation spends it.

---

## Phase 9 — polish

### R9.1 — Input feel, combat cadence, catch feel, camera · `model: sonnet`
### R9.2 — Controller UI readability on the Ally · `model: sonnet`
### R9.3 — Performance on target hardware · `model: sonnet`

---

## Ops

### OPS1 — Backfill `DONE.md`, and fix what let it drift
`model: haiku` · `tests: none`
`DONE.md`'s newest entry is `SG44+SG46+R8.5+R8.6`, and it has **no entries** for
OF19–OF33, SC12–SC15, SD16–SD18, SE21–SE30, SF31/SF34, SG38/SG40, R8.1–R8.4,
SH47 or the playtest repairs — roughly 25 shipped items. The loop's
"move it to DONE.md when you ship" contract is broken, and that is the root
cause of the 2026-08-16 prune that produced this file. Backfill from `git log`,
then state in `PROMPT.md` what a firing owes when it ships.

Also record the work that shipped with **no backlog item at all**, so it is not
re-done: elixirs (D45), tonics (D47), moves becoming non-interchangeable, the
workbench becoming a real crafting station with craftable tools, and
tool-in-hand + assignable hotbar + the map button (save format 6→7).

---

## Found along the way — small, unscheduled

- **Spec §6 — 6–10 optional activities, not forty shallow quests.** Lost Pal,
  Broken Cart, Night Watch, The Old Champion, Deep Warren, River Nest, Team
  Tether patrols, Meadowhart Herd. Each wants a home in Phase 8's bands rather
  than a list of its own; promote individually when the band it belongs to is
  built. `model: sonnet`
- **Spec §14 — home must stay relevant.** Grandpa's dialogue evolves per band,
  creature beds and recovery, storage and crafting, villagers updating what they
  know, the rescued NPC returning, story check-ins. The farmhouse should not
  become a room you never re-enter after the first twenty minutes. `R7.6`'s
  berry farm is the first answer to this. `model: sonnet`

---

## Done

Ids only. `git log` and `DONE.md` are the record; this list exists so a firing
can tell at a glance that an id is spent.

- OF15 — done
- EV10 — done
- EXP1 — done
- LANE1 — done
- MERGE1 — done
- MQ1B — done
- OF18 — done
- OW1 — done
- OW10 — done
- OW11 — done
- OW2 — done
- OW4 — done
- OW5A-rework — done
- OW7 — done
- OW8 — done
- OW9 — done
- PERF1 — done
- PERF2 — done
- PT-03 — done
- PT-04 — done
- PT-15 — done
- PT-17 — done
- PT-18 — done
- PT-19 — done
- PT-23 — done
- R7.3 — done
- R7.6 — done
- R7.7 — done
- R7.8 — done
- R7.9 — done
- TEST1 — done
- UI-PAD1 — done
- UI-PAD2 — done
- WALL1 — done
- BG1 — done
- BG2 — done
- CO1 — done
- EV1-remainder — done
- EV2 — done
- EV2-trunk-colour — done
- EV3 — done
- EV3-remainder — done
- EV3-remainder-2 — done
- EV3-remainder-3 — done
- EV3-remainder-4 — done
- EV3-remainder-5 — done
- EV4 — done
- EV4-hillside-seam — done
- EV4-hillside-seam-remainder-2 — done
- EV4-hillside-seam-remainder-3 — done
- EV4-hillside-seam-remainder-4 — done
- EV4-textures — done
- EV4-textures-lighting — done
- EV4-textures-remainder — done
- EV5 — done
- EV5-remainder-2 — done
- EV6 — done
- EV6-remainder — done
- EV6-remainder-well-rocktrim-shadow — done
- EV7 — done
- EV7-remainder — done
- EV8 — done
- EV9-double-prompt — done
- HD1 — done
- HD1-remainder — done
- HD2 — done
- HD2-remainder — done
- LP1 — done
- LP4 — done
- LP7 — done
- LP8 — done
- LP9 — done
- MQ1A — done
- NP1 — done
- NP2 — done
- NP3 — done
- NP4 — done
- NP4-rig — done
- NP4-uv-split — done
- NP6 — done
- NP7 — done
- OF1 — done
- OF2 — done
- OF3 — done
- OF4 — done
- OF4-rebuild — done
- OF4-remainder-mound — done
- OF5 — done
- OF6 — done
- OF7 — done
- OF8 — done
- OF9 — done
- OF10 — done
- OF10-remainder — done
- OF11-remainder — done
- OF12-remainder — done
- OF13 — done
- OF16 — done
- OF19 — done
- OF20 — done
- OF21 — done
- OF22 — done
- OF23 — done
- OF24 — done
- OF25 — done
- OF26 — done
- OF27 — done
- OF28 — done
- OF29 — done
- OF30 — done
- OF31 — done
- OF32 — done
- OF33 — done
- R0.11 — done
- R1.1 — done
- R2.1 — done
- R2.2 — done
- R2.3 — done
- R2.4 — done
- R2.5 — done
- R2.7 — done
- R2.8 — done
- R3.1 — done
- R3.1-remainder — done
- R3.2 — done
- R3.3 — done
- R4.1 — done
- R4.1-remainder — done
- R4.2 — done
- R4.3 — done
- R4.4 — done
- R4.5 — done
- R4.6 — done
- R4.7 — done
- R4.8 — done
- R4.9 — done
- R4.10 — done
- R4.11 — done
- R5.2 — done
- R5.3 — done
- R6-village-notification-freed-instance — done
- R6.1 — done
- R6.2 — done
- R7.5 — done
- R8.1 — done
- R8.2 — done
- R8.3 — done
- R8.4 — done
- R8.5 — done
- R8.6 — done
- R9.4-remainder-2 — done
- R9.4-remainder-6 — done
- R9.4-remainder-8-rocks-repeat — done
- R9.4-remainder-9 — done
- R9.4-remainder-9-combat — done
- RB1 — done
- SA0 — done
- SA0-orbs — done
- SA1 — done
- SA1-lod — done
- SA2 — done
- SA2-flake — done
- SA3 — done
- SA4 — done
- SA5 — done
- SA6 — done
- SA7 — done
- SA8 — done
- SB9 — done
- SB10 — done
- SB11 — done
- SC12 — done
- SC13 — done
- SC14 — done
- SC15 — done
- SD16 — done
- SD17 — done
- SD18 — done
- SE21 — done
- SE22 — done
- SE23 — done
- SE25 — done
- SE27 — done
- SE30 — done
- SF31 — done
- SF33 — done
- SF33-remainder — done
- SF34 — done
- SG38 — done
- SG40 — done
- SG44 — done
- SG46 — done
- SH47 — done
