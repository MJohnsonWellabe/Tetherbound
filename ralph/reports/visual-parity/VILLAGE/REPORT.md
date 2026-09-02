# VP5 — VILLAGE lane report (village, tournament ground, camps)

Branch `claude/vp-village`, off program branch `claude/coordination-subagents-3fhz1x` @ `1ef3878a`.
Final SHA: (filled at the end).

Owned files touched: `data/config/village.json`, `data/config/village_boundary.json`,
`data/config/building_prefabs.json` (village prefabs `well`, new `doorstep` only),
`data/config/bands/band1_lower_meadows/props.json`, `data/config/bands/band3_the_river_lock/props.json`,
`data/config/bands/band4_upper_meadows_ironwood/props.json`, `data/config/bands/band5_stronghold_approach/props.json`.
Not touched: any script, any terrain/vegetation/grass file, NPC placement (owner: "still too many people in
the village" — no villager added, none moved), the capture tools, the tests.

## 1. What was measured before anything changed

### 1a. The village gate (owner playtest 2026-09-01, correction of the same day)

Reproduced live with a scratch probe (`00-before/escape_probe_before.log`: teleport a keyless player 3 m inside
the fence, push outward for 200 frames at 0.5 m offsets along every gate leaf and at every fence panel, plus a
running jump at each gate and every fourth panel; polygon containment is the verdict):

| finding | evidence |
|---|---|
| A third road leaves the village with **no gate**: the corridor spine (`terrain_playground.json` `trail.bands[0]`, `[27.5,-16] -> [14,20] -> [8,90]`) crosses the old north fence run at (13.79, 22.40), 34.8 m from the nearest gate | layout simulation of `_build_fence` (`boundary_geom.py`) and the same crossing check the V2 probe does, extended to `trail.bands` (the V2 probe and `test_village_boundary.gd` only walk `paths.routes`, which is why both said "all roads gated") |
| The RoadGate's **north-east jamb is a 1.9 m hole**: the panel layout skipped the whole 6.32 m gate edge, the leaf is 4.07 m, and the next edge's first collider starts 2.08 m past the leaf's end | probe: walked out at leaf offsets +2.5, +3.0, +3.5, +4.5, +6.0 m (13 m past the line) and jumped out at +2.6 m. 6 escapes, all on that jamb; every other panel and the PondGate held |

### 1b. Baseline frames

`00-before/locations/` — `01-village` (6 stands, day + night), `05-relay-camp`, `08-ridge-camp` (day + night),
`09-waystop`, captured from the starting commit with `tools/_capture_locations.gd` at 1280x720, carpet on.
Contact sheet `00-before/_sheet_locations.png`. Perf proxy `00-before/perf_render_stats.txt`.

Also measured before changing anything (a scratch layout probe printing every village structure's collider
extents, door node, marker and prop position — `layout_before.log`): two of the earlier E1 daytime fixes were
standing INSIDE buildings. The inn's bench and barrel at (0,-9.6)/(-0.8,-10.2) were inside the inn's common room
(the inn's walls span x -6.5..3.5, z -12..-6; the door is on the EAST face at (3.5,-9)), and Grandpa's woodpile at
(-19.2,-15.6) was inside his house (walls x -26.8..-17.2). The E1 east tournament bench stood 0.4 m from Halda's
own standing spot.

## 2. What changed and why

### Village boundary (`village_boundary.json`)
- **TrailGate** added at (13.79, 22.40), yaw 175.1, on the corridor spine — same key, flag, leaf and prompt as the
  other two; `village_boundary.gd` already syncs every gate on the frame one opens.
- **Outline re-authored around every gate** so the jambs seal by geometry rather than by luck: each gate is the
  midpoint of its own 4.4 m edge (one panel, skipped) and both neighbouring edges are multiples of the 6.15 m
  panel (±0.3), so the neighbour's collider ends 0.02–0.18 m from the leaf's end and its visible prefab reaches
  the corner (a shorter neighbour edge would run the 6.15 m prefab straight through the gate opening; a longer
  one leaves a visible hole). 22 -> 26 points. Every pin in `test_village_boundary.gd`, all 28 village harvest
  nodes, the practice disk's 2.4 m clearance (2.45 m) and the (48,-58) catch stand re-checked first.
- Nothing about `vault_guard_m` changed (V2's anti-jump pad is kept).

### Village (`village.json`, `building_prefabs.json`, band1 `props.json`)
- Well: `MI_RockTrim` multiply #f0e2c4 -> #a39d8e and a first `MI_Brick` multiply (#b9b1a2) — owner: "the well
  pad reads as clean white stone, weather it".
- New `doorstep` prefab (two of the well's own paving tiles) outside cottage_a, cottage_b and the inn: worked
  ground at every door, and it carries `Floor_` modules so the runtime grass ring stops growing through it.
- Grandpa's kitchen garden (farm.json's six plots) fenced on its north and west with `fence_run`, a cart beside
  it, a picking crate and bucket at its open east side: a fence that encloses something.
- A second cart behind cottage_b, between it and the practice-meadow fence run, with a woodpile against the
  cottage's south wall: that fence line now fences a yard.
- A yard rail between the inn's west gable and the garden, closing the empty lawn the `twins` frame sees.
- Inn frontage moved OUTSIDE the inn: bench north of the door along the wall, two barrels south of it.
- Grandpa's woodpile moved OUTSIDE the house, against the east wall south of the door.
- Three village-edge oaks (east, north, south) inside the fence, clear of every path, node and NPC.

### Tournament ground (band1 `props.json` cluster 1006)
- Three green banners (`quaternius_castle` `Banner`, retinted to the key art's settlement green, never oxblood):
  a pair flanking the corridor road where it enters the field from the square, one on the ring's west side.
- The two spectator benches re-sited to face the ring from outside the trainers' axis (east one 3.2 m from
  Halda instead of 0.4 m), a water barrel by the east bench.
- A staging pile (crate, bucket, pack) by the board for the team waiting its bout.
- Everything solid ≥ 7 m from the arena centre except the staging pile (4.5 m off the fight axis).

### Camps (band3/4/5 `props.json`; edits made by a delegated agent to this lane's spec)
- **Relay checkpoint** (`relay_approach_checkpoint`): fire kept where the capture aims, scaled 0.38 -> 0.45 with
  `glow_scale` 1.5 and a bigger ring; bench turned tangential; the second supply pile brought from 7 m out to a
  touching pile 3.5 m NE of the fire; a log seat opposite the bench; the grunt's tent 5 m SE. The road post
  (banner + three containers) stays on the road.
- **Ridge camp** (`ridge_patrol_camp`): the straight line of containers becomes a pile W-SW of the fire; stool,
  log seat and firewood arranged around the fire; the fire ring 0.55 -> 0.85; grindstone moved off the pile; and
  the camp gains a `rest` block with a creature bed (index -16) — it was the only authored camp in the chapter
  the player could not use.
- **Waystop** (`the_waystop`): bench pulled in to 2.6 m and turned tangential, bag against its end, anvil and
  bucket grouped with a new barrel + crate pair (the smith's reason to stop), a log seat east of the fire, a tent
  west, `glow_scale` 1.4.

## 3. Evidence

(filled per round)

## 4. Judge verdicts

(verbatim, per round)

## 5. Perf

(before/after `tools/perf_render_stats.gd`, `--settle=120 --resettle=60 --sample=20`)

## 6. Tests and playability guard

(filled)

## 7. Unresolved / judgement calls / next step

(filled)
