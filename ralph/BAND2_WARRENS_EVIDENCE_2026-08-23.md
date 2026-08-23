# BAND2-63-WARRENS — the Burrow Warrens, walked

Lane D2 (Quarry / Burrow Warrens), continuing `docs/ralph-prompts/63-BAND2-finished-quarry-warrens.md`
from the state `ralph/lanes/START_D2.md` describes. Branch head before this pass:
`6ef491e`.

The lane brief listed four things left: a real blind visual pass, the Warrens'
dungeon quality against prompt 63, the Mudsnout → Tuskroot lead, and a driven
run. Three of the four are done here. The fourth — the blind pass — has its
frames and deliberately has no verdict from me.

## What the driven run found

`tests/smoke_warrens.gd` was green and had been green through two relocations.
It teleports the player into each chamber and pushes at walls, which is the
right test for walls and cannot see the thing that was actually wrong.

`tools/_probe_warrens_run.gd` (new) drives the player's own controller instead,
through the doorways, from the road. On the shipped branch it walked 30 m into
the cave and wedged solid at local z=27.5 against a collider named `Terrain`,
five metres short of the passage to the den. **The chapter's one required
dungeon could not be entered on foot.** The guardian, the `warrens_cleared`
flag, the heartstone and the Tuskroot gate behind it were all unreachable.

The cause was written down in the file it broke a relocation earlier.
`burrow_warrens.json`'s `_comment_ow5d_relocation` records that OW5D translated
a cave whose geometry had been measured against a specific steep flank at
(70,-140) onto ground nobody had probed, kept the bearing derived for the old
flank, and flagged that the 10 m `skirt` needed ground that would accept it.
At (-420,2470) the ground rolls. It does not rise. The terrain surface ran
straight through the hall and the den.

One detail worth keeping: the first version of the probe drove `velocity`
directly with `_physics_process` suspended, the way `smoke_warrens.gd::_push`
does, and reported the player stuck 6.5 m short of the MOUTH — a cave you
cannot walk into at all. That was the harness, not the cave:
`player_controller.gd::_try_step_up()` is what gets a CharacterBody3D over the
doorway sill and it runs in `_physics_process`. Duration and route evidence has
to come from the body the player actually drives.

## What was ruled out, with measurements

`tools/_probe_warrens_site.gd` (new) samples the world heightfield across each
chamber's own footprint and reports the worst point, because the worst point is
where the ground surfaces inside the room.

| Fix tried | Mode | Result |
|---|---|---|
| A different bearing | `--scan` | best of 72 bearings still 6.6 m short |
| A different site | `--sites` | nothing on a 25 m grid out to 300 m clears, from the warrens OR from the Old Quarry (`--origin=400,1800`); best anywhere 2.6 m short |
| Make the cave descend | `--plan` | buries the deep rooms; the ground surface then cuts through the entry corridor and the player walks up it into the ceiling |
| Stand it in flat ground | `--mound` | works |

There is no flank in this part of the Meadows steep enough to bury a 47 m cave.
So the cave stops needing one: it stands where the terrain never rises above
its floor, and what shows above ground is a rock knoll with a hole in it —
which is what this file's own site comment always claimed the entrance was, and
what `skirt` was built to hide the underside of.

The first such site, (-382,2510), cleared the footprint and failed the half
nobody had checked: the driven run walked 30 m from the road and stopped 25 m
short of the entrance against a 50-degree bank. `--best` scores both halves at
once — footprint clear, the 40 m in front of the mouth walkable, site near the
spine, and the solid scatter actually in the way counted from the scatter's own
placement lists (its colliders only stream in near the player, so a ray from an
empty probe reports a clear doorway a player then walks into).

**Shipped site: (-357,2610), bearing 315°.** Footprint clear by 0.43 m,
approach 6.9°, 14 m off the `warren_undertrail` loop `terrain_playground.json`
already runs past the warrens. The mouth faces back down that loop.

## The route, measured

`tools/_probe_warrens_run.gd`, live build, player's own controller:

```
approach   69.8 m   14.9 s   [arrived]     road -> entrance
mouth       7.1 m    1.7 s   [arrived]
hall       15.9 m    3.2 s   [arrived]     doorway, then room
den        18.0 m    3.6 s   [arrived]     doorway, then room
vault      12.5 m    2.6 s   [arrived]     past the branch door
-----------------------------------------
123 m, 26 s of walking, one way, no fights
```

With the five resident fights and the guardian at ~45–60 s each and four
rootstone deposits to break out, a played clear lands around **5–9 minutes**.
That is the dungeon-duration figure the lane brief said was missing.

Chamber navigation reads: each room is entered through one doorway, the branch
is the only shut door, and the deepest room is the one the guardian is in.
The region's objective is legible while playing it — `objectives.json`'s main
chain already carries "Clear the Burrow Warrens beneath the Old Quarry", Pell
stands 35 m from the mouth telling the player whose hole it is, and the map
region pin moved with the site.

## What else prompt 63 was missing

**Team Tether evidence inside the dungeon.** Prompt 63's required-dungeon list
names it and the band had none in the cave — the only trace in the region was
the ranger-camp supply cache, which a player who walks to the mouth and goes
straight down never sees. Nine props now stage a load somebody was cutting and
left: an empty crate four paces inside the mouth, a stacked pile with a barrel,
a pickaxe and a pack in the hall, and a crate, a tipped bucket and a barrel in
the den a metre and a half from its rootstone deposit and across the room from
the guardian. Evidence, not explanation: no note, no interactable, nobody down
here who knows what the seam is for — the rule `old_quarry.json`'s own
`_comment_evidence` states for the quarry. Every model is from the one prop
family the settlement already uses, and they are placed through `props.gd`'s
own placer so they get the same collider and sink behaviour as every authored
prop above ground.

**A guardian that reads as one.** It was a Burrowback with a bigger number: the
world prompt said `Engage Burrowback`, the combat plate said `Burrowback`, and
it stood the same height as the level-11 Trailpup one room back. It is now
named on both (the prompt reads the body's `display_name`, the plate reads the
instance through `label()`, which is why the name goes on two objects) with the
species kept underneath so catching it does not lose what it is, and its
silhouette is 1.4×. The capsule, the hit cone's reach and the catch bonus come
from `species.json` and are untouched — scaling them would have retuned the
fight.

**The Mudsnout → Tuskroot lead.** It was legible only to a player who opened
the satchel and read the item description, or who owned a Mudsnout and pressed
G to be told "Mudsnout needs a Heartstone to evolve". Both still work. The
pickup line now also carries it, in `items.json`'s own words, at the one moment
every player who takes the stone is looking at it. No rule changed: the gate is
still level 15 + bond 55 + heartstone.

## The scatter, and one shared-file change

The cave moved into forest. 93 collidable scatter instances stood inside the
site and one of them was a tree in the doorway. The clearing that removes them
is authored (`bands/band2_stone_and_root/vegetation.json` order 2002, radius
30) and **cannot take effect until the coordinator re-bakes** — a band clearing
does not invalidate the bake, `GATE_D_LANE_CONTRACT.md` §4, inherited by every
lane.

Handing over a dungeon nobody can enter on the promise of somebody else's bake
is not a state to ship, so `vegetation.gd` gains `clear_area()` and the cave
calls it at build time with the same radius the clearing authors. Per-placement
removal at each stored position — the same reliable path harvest already uses,
never one big brush, because `HARVEST_REMOVE_RADIUS`'s own comment records that
`remove_instances()` is a probabilistic editor brush and only the exact-position
case is trusted here. **This is not the fingerprint fix and does not replace
it.** It touches only collidable layers, it runs every boot, and when the
re-bake lands it has nothing left to remove.

## Visual state — two blind rounds, judged by an independent critic

`tools/capture_warrens_63.gd` renders seven frames to `shots/warrens_63/`: two
exterior stands found by measurement (the ring is cast at the mound and only
stands that can see it are kept), the mouth, the hall dressing from two angles,
the den with the guardian, and the den dressing. Both rounds were judged by an
independent critic that never saw this branch, this report, or a word about
what had changed — only the frames, the contact sheet and the two references
`ralph/conventions.md` names.

**Round 1 was mostly a verdict on my own harness, which is worth writing down
as the lesson it is.** Three of its findings were capture bugs, not the world:

- Five of seven frames came back flooded red, and the critic reasonably read
  that as a colour grade spent on ambience. It was the **player's damage
  vignette**: the harness parked the player 500 m under the world to keep them
  out of shot (the trick `capture_band2_63.gd` uses), so they fell into the
  kill volume, took damage, and every frame after the first two rendered
  through a hurt overlay. The player is now parked far away on the ground,
  hidden, with physics off.
- The interiors were shot with no torch, in a cave whose own
  `_comment_lights` says it is dark on purpose and readable by the torch the
  player carries. A stand-in torch now rides the camera on interior shots.
- Two frames on the sheet were the camera's nose against a cliff. The stand
  finder now rejects any position whose ray dies within 12 m.

A harness that lies costs a critic's whole round. Round 1 spent three of its
findings on my capture code and its two bar answers were decided partly by it.

**What round 1 found that was real, and what was done about it:**

| Finding | Action |
|---|---|
| A full-canopy tree standing in the cave doorway | It was one of this band's own **ironwood harvest nodes**: OW5D-style uniform translation had carried five of them onto the new site, one *inside* the knoll and three in the doorway corridor, the nearest 8.5 m dead in front of the mouth. Re-arranged into a stand ringing the site at 34–46 m, ≥26 m off the doorway axis. |
| The entrance is invisible from outside; the mouth is a flat textured plane with straight cut edges | `skip_front_m` 9 → 6, so the outcrop runs across the front of the cave and the opening reads as a hole in a rock face instead of a panel with a hole in it. |
| The boulders read as "a heap of enormous cabbages" — one repeated module, mint-green against the cave's warm stone | Albedo now multiplied toward the cave's own rock colour, and the rock runs in three courses from below the plinth to the roof. |
| The cave floor is "a single untextured flat tone … no floor material in the readable sense" | The floor slab is textured with the same stone the walls use, a shade darker. |
| The den is bare — "a den should show occupation" | Three more pieces, deliberately scattered across the guardian's half of the room rather than added to the tidy pile. |
| Ground density: "a lawn, not a meadow" | Partly mine and partly not — see below. The site clears 30 m of scatter so nothing stands in the cave, which left a bare ring; it now plants its own ground cover (141 pieces, banked against the outcrop, thinning outward). The **corridor-wide** density is a `density_scale` request, recorded below. |

**Round 2, on the fixed frames.** The red flood, the blocked doorway, the
invisible entrance, the flat billboard face and the buried-camera frames are
gone from its list. It found new, more specific things, and two of them were
cheap and mine:

- **A placeholder box appeared in two frames.** Every rootstone deposit in the
  cave had no `model`, and `harvest_node.gd` falls back to an untextured box
  when a spec has none. The critic found it twice without being told what it
  was. The deposits are now rocks from the same family as the outcrop.
- **The guardian was half cropped by the frame edge** in the one shot that
  exists to show it. The camera now aims at the guardian's own body.

**Round 2 still answers NO to both bar questions, and this lane cannot honestly
close that.** Its own split of what is left says why:

- *Material language.* The cave's walls use `terrain_playground.json`'s
  photo-speckle rock — chosen in an earlier pass precisely so the cave would
  match the cliff the player walks past — and the outcrop and meadow around it
  are smooth low-poly nature-pack stone. The critic reads the seam between
  those two languages as the loudest single defect. Reconciling them is an
  art-set decision across the whole corridor, not a Band 2 config change, and
  it cannot be done without new material work.
- *The creature.* The critic says plainly that the guardian's model does not
  belong to this game's style and no staging will fix it. **CLAUDE.md forbids
  this lane from acting on that**: no new creature meshes, no Meshy
  generations, and never one without owner-supplied reference art. Presentation
  is all this lane may change and it has been changed — name, silhouette scale,
  framing. The rest is an owner decision and is flagged, not acted on.
- *Ground density.* Corridor-wide, and coordinator-owned by
  `GATE_D_LANE_CONTRACT.md` §3.

So: **not converged.** The convergence rule in `ralph/conventions.md` is two
consecutive rounds naming no new defect, and round 2 named plenty. What is left
on the list is a material set, a creature, and a shared config — none of them
this lane's to change, all three recorded here.

## Not requested, not changed

- **`density_scale` request for band 2: 0.05 → 0.09.** This reverses the
  previous round's "no request", on evidence it did not have. Two independent
  blind rounds named ground density as the single loudest gap between these
  frames and both references — "a lawn, not a meadow", "flat texture-only grass
  with five flower decals … zero grass blades, zero clumping" against
  Palworld's field shots. The driven run cannot see this and the analytical
  cadence probe cannot either; only frames can. 0.09 is band 1's 0.07 plus a
  step, not a guess at the right number — this band is the first place the
  player leaves the opening meadow, and it should not read thinner than the
  meadow behind it. Coordinator's call and coordinator's single bake.
- **No new creature, mesh, humanoid or mechanic.** The guardian is the same
  Burrowback, differentiated by name and silhouette per CLAUDE.md's own list.
- **No chamber re-authoring.** Layout, sizes, spawns, deposits, dressing and
  prize are unchanged through both relocations — they are authored in the
  site's local frame and rotate with it, which is why the fix is two numbers
  plus the things sited against the mouth.

## Files this pass touched outside the band directory

Flagged because five lanes are in flight:

- `scripts/world/vegetation.gd` — additive `clear_area()`, and one new key in
  the collision-batch dict it reads.
- `scripts/world/props.gd` — `_place()` becomes `place()` and honours an
  optional `name`; behaviour otherwise unchanged.
- `scripts/ui/combat_hud.gd` — the enemy plate reads `label()` instead of
  `display_name`. Identical output for every creature without a nickname,
  which is every creature but the guardian.
- `scripts/world/burrow_warrens.gd`, `data/config/burrow_warrens.json` — this
  lane's own site.
- `tests/smoke_warrens.gd` — two new checks (below) and the removal of its
  "the den is under the hill" assertion, which was never the rule that
  mattered and is false of a cave standing in a knoll of its own.
- `tests/fixtures/band_split_baseline/{harvest,spawns}.json` — the ironwood
  nodes and the resident Burrowback cluster moved with the mouth, mirrored by
  hand at their pinned indices per that fixture's own instruction.
- `data/config/map_landmarks.json` — the warrens region centre.

## The coverage gap that let this ship

Both new checks in `tests/smoke_warrens.gd` were verified to FAIL at the old
site and pass now:

- no chamber may have ground between its floor and its ceiling ("the ground
  surfaces 2.61m inside the 'den' chamber");
- the whole route — entrance, mouth, hall, den, branch — must be walkable by
  the player's own controller, through the doorways ("walking the cave never
  reached the 'den' chamber (stopped 13.3m short)").

## Verification

- `tests/run_tests.gd` — 1301 tests, 713876 assertions, 0 failed.
- `tests/smoke_warrens.gd` — passed, including both new checks.
- `tests/smoke_traversal.gd` — OK.
- `tools/_probe_chapter_map.py` — band 2: 3 trainers, 56 wild clusters (195
  creatures), 19 authored gatherables. Unchanged by this pass except that the
  ironwood nodes moved with the mouth; the density work was the previous round's.
- `tools/_probe_band2_cadence.py` — longest straight-line gap 75 m, one beat
  every ~22 m over 1820 m, every rootstone recipe craftable off the first
  quarry visit.
