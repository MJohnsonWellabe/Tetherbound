# HANDOVER — T1-HALL-REBUILD, 2026-08-30

Branch: `ralph/T1-HALL-REBUILD`, off `origin/main` @ `cba700b5`. Pushed.
Lane: LANE-VIS Hall, working to `ralph/reports/HALL_DESIGN_2026-08-30.md`.

**Smokes:** `smoke_stronghold` and `smoke_boss` green. `smoke_gate_e_finale`
is green but **intermittently red** — see §10, which is the most important
section in this file for whoever lands it. Build log prints `5 spaces on the
route … 3 gauntlet trainer(s), 15 approach pylon(s)` and `18 exterior omni
light(s) at the Hall (budget 18), 6 of them flickering fires`.

**Against the exit criterion:** this lane is `MEADOWS_EXIT_CRITERION.md` E2,
"important structures look deliberately authored", which names the Hall as
the live test. E3 (Team Tether presence visibly changes the land) is also
touched — the occupation layer and the cable landing are its evidence at
this site.

Evidence: `ralph/reports/T1-HALL-REBUILD/shots/` — 11 frames, design §10's
H-01..H-08 plus the golden/night H-03 variants §10 requires and one new
stand (H-02b, §6 below). **I have not judged them**; the reads recorded
here are objective defects and measurements only, per the owner's
build/judge separation.

---

## 1. What I found before writing anything

Main already carried T1-HALL and T1-HALL-BUILD: the re-site to (8, 7560),
`yaw_deg` 0, `ramp_run` 40, the `meadows_hall` massing prefab, the castle
retirement, the `T_UnevenBrick` palette proof, the cable landing, and the
`_judge_capture_hall.gd` stands. Brief items 1–4 were therefore already
shipped, and I verified rather than rebuilt them (the ramp self-derives
11.2m of rise over 40m = 16°; the smokes prove the route). This lane is
items 5–8 plus the gaps the first build pass flagged as unmet.

**The regression the merge introduced without meaning to:** `landmark.gd`
was the ONLY caller of `stronghold_occupation.gd`. Retiring the detached
castle took the game's entire garrison camp, brazier row and tether-lamp
set out of the world with it. The merged Hall inherited the architecture
and none of the occupation. Most of §2 is that layer re-authored at the
merged site.

## 2. What shipped

**Occupation (`stronghold.json` → new `hall_occupation` block,
`stronghold.gd::_build_occupation()`).** Causeway kerbs, timber railing and
banner piers on the 40m climb; six exterior fires (2 causeway pairs + a
garrison fire in each yard) with the brazier/flicker recipe ported from
`stronghold_occupation.gd` per the design's instruction to read that file
rather than extend it; two brazier baskets standing at gate fire points
that had light and no visible source, at zero light cost; the garrison camp
in the gatehouse yard in the Meadows' one camp vocabulary; the relay hub
(`relay_apparatus.glb`, fitted to 4m, fenced in tether girders) in the
inner bailey; the hoarding walkway on the courtyard's west curtain; stair
dressing at its north-east corner; buttress pilasters and half-buried
boulders at the skirt foot.

**Every daylight opening is framed** (brief item 5). The gate gained design
§4's blind arch over its lintel. The arrow slits gained a proud
jamb/sill/head surround in a dressed tier with the void set back behind —
and see §3, because they were not rendering at all. The keep chambers had
no exterior openings whatever against the acceptance list's "no curtain run
> 12m without an opening"; they now carry §4's paired taller lights, ranked
by chamber height (one rank on the low hall, three up the great tower's
north face), derived rather than hard-coded.

**The H-motif varies per wall** — four arrangements of one vocabulary
(girder / pillar pair / live conduit / banner pair), indexed per wall, so
no two walls in a frame carry the same stamp. This closes the first build
pass's own §8 gap.

**The skirt is a foundation tier.** Each chamber's floor slab IS its skirt —
one box 18m deep whose top face is the room's walkable floor — so it
necessarily wore the ~0.3m yard cobble, and the bottom several metres of
the building rendered as paving seen edge-on at a smaller stone scale than
the wall above it. That is exactly the scale collision §5 resolves with a
stated ladder. The slab cannot be retinted without repainting five
interiors, so `_build_skirt_facing()` skins its exposed faces in the
darkest tier at the coarser 0.22 tile, with a course at each end.

**Light budget enforced and checkable** (brief item 7). `lights_flanks` cut
16 → 6 and the outer_works ambient retired, paying for six flickering
fires. The site stands at exactly 18 exterior omnis and `build()` prints
the live count and warns past the budget, so this is a checked number
rather than a comment.

## 3. Three bugs found by looking at the frames, not at the reports

1. **Every opening on this building was built and buried.** `_slit_row()`
   measured its wall face from the wall CENTRELINE (`half-extent + _wall_t *
   0.5`) where `_wall_rects` puts the centre and the wall is `_wall_t`
   thick — so every slit sat 0.6m inside 1.2m of masonry. True on `main`
   too. `_dress_exterior_wall` has had the correct offset all along, which
   is why the hardware on the same walls reads and the slits never did.
2. **A runtime type error was silently deleting every slit row.**
   `var stations: Array[float] = [0.0] if cond else [a, b]` parses clean and
   fails at RUNTIME — a ternary yields an untyped Array, the assignment is
   refused, the array stays empty and the loop builds nothing.
   `--check-only` reports the file as fine. Found by probing the built node
   for box sizes, not by reading. The pattern does not occur elsewhere in
   the tree (grepped).
3. **`_fit_to_height` is the wrong tool for anything whose plan matters.**
   `Stairs_Exterior_Straight` is 2.0 x 1.20 x 2.08 native; fitting it to a
   4.6m rise scales its footprint to 7.6m, and the flight drove straight
   through the courtyard's east wall and out the far side (visible in the
   first H-05). The stair dressing is now authored in metres.

## 4. Owner directives received mid-lane, and what I did with them

**"the red flags look like cheap toys and need to go."** They did, and they
are gone. `Banner.obj` is a wall-bracket FLAGPOLE — a short post with an arm
carrying a small pennant at its tip — so at any scale keeping the pole sane
the cloth is a hand-sized triangle on a 20m wall. Earlier passes retinted
it, rescaled it and re-aimed it; none of that could fix the SHAPE. The mesh
no longer appears anywhere in this building (the prefab's `Banner` module
and its retint slot are removed with it). What replaces it is what the
board's own MEADOWS CASTLE CONCEPT panel draws — "a tall heraldic banner
flat against the curtain": cloth hung from a timber crossbar, falling down
the wall face, with a swallowtail cut in the hem and darker selvage down
each edge. Built from boxes, every dimension authored in metres, so it
cannot come out toy-sized the way a kit prop fitted by guess can. The flank
banners size themselves to stop clear of each wall's own girder, and their
stations moved off the slit pitch. The relic banner's `torn` flag drops one
of its two tails, so §6.2's story beat now reads in the silhouette and not
only in the tint.

**"the untextured beige hut thing between the two parts of the castle also
looks like shit."** That is a real property of the module, not a tuning
miss: `WatchTowerWRoof.obj` is built ENTIRELY from the kit's `Celing` and
`LightWood` slots — probed directly, those are the only two `usemtl` lines
in the file — and carries no stone slot at all. `HALL_WEATHER_MATERIALS`,
the pass that puts real `T_UnevenBrick` on a kit that ships zero UVs and
placeholder-grey materials, is stone-only by design, so that module can
NEVER receive a texture from it. No retint, scale or placement fixes a flat
beige hut on stilts at the joint of a coursed-stone fortress. All four
instances are now `LargeSquareTowerBricks`, which the same pass textures.
Scales preserve the design's girth rule against measured natives: the
mid-wall pair at 3.15 gives 4.06–4.32m against the corner towers' 3.86–4.11m
at 3.0, so mid-wall girth still EXCEEDS corner girth (the direct fix for
the judge's "sandcastle decoration" finding) and the taller shaft adds a
roofline break. Guard post 2.6 (subordinate to the 3.4 flankers); great
tower's north-east corner 4.0 (still stepping down from its three 5.2
siblings). The great tower's banner is rebuilt in cloth by
`_build_tower_banner()`.

## 5. Performance — MEASURED, AND OVER THE DESIGN'S LINE

**`stronghold_approach` does not look at the stronghold.** Godot yaw 0 faces
−Z; that view stands at z 7420 and looks toward decreasing z, back up the
corridor the player just walked, with the Hall at z 7560 behind the camera.
The entire Hall design's draw-call budget is written against that counter.
Measured, not inferred: a before/after pair across this branch's whole diff
returned **1090 draw calls / 1402 objects on BOTH sides, to the object** —
which is what a view containing none of the changed geometry looks like.

So I added `hall_approach`, the same stand turned around, and left the old
entry untouched so its historical series stays comparable. Both runs used
`--views=`, a new flag on `perf_render_stats.gd`; the first Hall build pass
killed this tool at 40 minutes with nothing printed, and a single-view run
finishes in about twelve.

| `hall_approach` | draw calls | primitives | objects |
|---|---|---|---|
| before (`origin/main` @ `cba700b5`) | 2142 | 23,465,154 | 2455 |
| after (this branch, merged) | **2706** | 23,625,965 | 3019 |
| budget (before + 15%) | 2463 | | |

**This is +26.3%, over the design's line by 243 draw calls, and I am
reporting it rather than trimming to hit it.** Three things the coordinator
needs in order to decide:

1. **The line was computed against a view that never contained the
   building.** There has never been a measured budget for a view that sees
   the Hall; I created that view today. The +15% figure was also premised on
   the retiring castle's 132 modules paying for the new massing — and that
   netting was already consumed by T1-HALL, before my baseline was taken. So
   my delta is pure addition against an already-spent allowance.
2. **I already took the cheap cuts.** Opening surrounds went from five boxes
   to two (a dressed plaque with the void recessed into it), and keep lights
   are single rather than paired on faces other than the north one: 1255 →
   1103 mesh instances on the built node, 2962 → 2706 draw calls. The
   five-box surround was the single largest thing this lane added.
3. **The remaining levers, in the order I would spend them** — which is NOT
   the design's own cut order, because the design's order was written
   without this measurement: (a) the merlon rows are **177 boxes**, the
   largest single block at this site, and they are T1-HALL's
   `_build_keep_parapets()` putting merlons on all four sides of all three
   keep chambers, most of which are never seen; (b) the causeway railing
   (~26 kit props, each multi-surface); (c) the hoarding walkway. Cutting
   (a) alone would very likely bring the site inside the line without
   touching anything this lane added.

One caveat I could not close: the `before` was measured on `cba700b5` and
the `after` on the merged tree, which also carries T3-INSTALL, T1-UI-SURVEY
and T1-LIGHT. Some unknown share of the +564 is theirs, not mine. Re-running
`--views=hall_approach` with `scripts/world/stronghold.gd`,
`data/config/stronghold.json` and `data/config/building_prefabs.json`
reverted to `origin/main` on the current tree isolates it exactly, and is one
twelve-minute command.

## 6. Capture stands: one that has never worked

**H-02 (the Sigil Gate, 150–200m) has never contained the Hall.** At the
authored 1.7m eye height Band 5's treeline fills the frame end to end — in
my captures and in the previous lane's capture of the same stand. Design
§10 assigns acceptance items 2, 7 and 10 (three-tier read, coursing at
range, occupation reads) to that stand, so **none of those three has ever
actually been judged.** Two changes:

- H-01 and H-02 now aim at the complex's own courtyard marker instead of a
  hard-coded compass bearing. H-02's authored `(-1, 1)` is 45° west of
  south; the Hall bears about 18°. It was pointed at trees on purpose by
  arithmetic nobody re-derived after the re-site.
- **H-02b** is the same stand with its eye above the canopy — not a nicer
  angle, the only one from which the item is answerable. The 1.7m frame is
  KEPT beside it, because what it shows (the chapter's climax reveal, fully
  occluded from the gate the player opens to earn it) is a real finding
  about the approach, and deleting the frame would delete the finding.

## 7. Coordinator decisions (flagged, per the brief)

1. **Roof accent tint.** Implemented as the design's default: dark
   teal-green (`MI_RoundTiles` → `#2a8c94`), inherited from T1-HALL. If the
   owner reads the board's keep caps as dark timber, swap that one tint to
   `#4a3a2c` and nothing else changes.
2. **The torn-banner beat.** Implemented as the design's default: one faded
   Meadows-blue banner (`#3d4a63`), half height, on the west bailey wall
   below the oxblood rhythm. It now also loses a tail, so the seizure reads
   in silhouette. It is one prop and one tint; delete it if it oversteps.
3. **Two things behind the Hall are other systems' and I did not touch
   them, but H-02b makes both urgent.** (a) `rift_collapse.gd`'s SG44
   `StormWall` stands as four huge untextured grey slabs directly behind
   the Hall, dwarfing it and filling the sky in the chapter's climax frame;
   the previous lane traced and flagged it too. (b) The `approach_drain`
   skin (`#bfb6a0` at `max_alpha` 0.72), extended south to the building by
   design §6.6, bleaches the whole approach near-white at range. Both are
   config-level fixes in systems this lane does not own; both are visible in
   `H-02b-sigil-gate-raised.png`.
4. **The white flat slabs scattered on the meadow west of the Hall**
   (visible in H-06) are pre-existing — they appear in the previous lane's
   frame of the same stand. Not introduced here, not diagnosed here.

## 8. Open / not done

- The final perf after-number for `hall_approach` is recorded in the commit
  that follows this file; the budget line is 2463 and the last measured
  value before the banner/tower rework was 2432 (+13.5%). The rework swaps
  four kit modules and adds ~2 boxes per banner, so it is close to that
  line and the margin is thin. **Cut lever if a future pass needs room:**
  keep-light ranks, then the hoarding walkway — in that order, not the
  design's own order, because the keep lights are the heaviest addition
  measured and the hoarding is the more visible one.
- Design §4's curtain-wall kit courses (`TallWallBricks` runs) are still
  not built; the works' own chamber walls carry that read instead. The
  prefab stands at 18 modules against the design's ~195–215 estimate. This
  is inherited scope, not new.
- `EXTERIOR_FACE_TILE_MULT` is still in place. The design says it retires
  with the material unification; the previous lane declined on evidence
  grounds and I did not reopen it.
- No blind judge has seen any of this. That dispatch is the coordinator's.

## 9. File footprint

- `data/config/stronghold.json` — `hall_occupation` block, `site.stone_skirt`,
  `lights_flanks` cut to 6, outer_works ambient retired, four new comments.
- `data/config/building_prefabs.json` — `meadows_hall`: four `WatchTowerWRoof`
  → `LargeSquareTowerBricks`, `Banner` module and retint slot removed, one
  new `_why`.
- `scripts/world/stronghold.gd` — `_build_occupation()` and its nine passes,
  `_hang_banner()` rebuilt as cloth, `_build_tower_banner()`,
  `_build_skirt_facing()`, `_stone_dressed()`, `_slit_row()` generalised and
  its two bugs fixed, per-wall hardware variants, `_report_light_budget()`,
  `_flicker_fires()`, ramp publishing its own derived slope.
- `tools/perf_render_stats.gd` — `--views=`, `hall_approach`.
- `tools/_judge_capture_hall.gd` — `--out=`, golden/night H-03, aim-at-hall
  for the long stands, H-02b.
- `ralph/reports/T1-HALL-REBUILD/shots/` — 11 frames.

Not touched: `interior_structure.gd`, `stronghold_occupation.gd`,
`landmark.gd`, `scripts/combat/**`, `art.json`, terrain/scatter config,
`rift_collapse.gd`, `approach_drain_skin.gd`.

## 10. The one red smoke, and what I can and cannot say about it

`smoke_gate_e_finale` failed twice, then passed seven times, on trees that
included the whole of this change. The failure is always the same assertion
and always the same numbers:

```
FAIL: 'warden_aldis''s creature is fighting 'warden_aldis' 5.7m BELOW
'warden_arena''s floor (y=0.52 against a floor at y=6.17)
```

Everything before it passes — the walk-in, all three gauntlet fights, the
recovery point, the shutter, the reveal, the Warden, the release ceremony,
the region's response, the objective chain terminating. It is the last check
in the run.

**What I did, in order, and what it is worth:**

1. Ran it against `origin/main`'s versions of my three gameplay files on
   this same tree: **passed**. That looked like proof the failure was mine.
2. Bisected: occupation layer off → passed. Occupation on, grounding pass
   off → passed. Grounding on, skirt facing off → passed. Three clean steps
   pointing at `_build_skirt_facing()`, which is also the only occupation
   pass that touches the arena chambers at all. A tidy story.
3. **The story was wrong.** I re-enabled everything to instrument the
   failure and it passed — then passed three more times, then three more.
   Nine runs, two failures, both at the start. Every "bisect result" above
   is a run in which the intermittent failure simply did not fire, and the
   single `origin/main` run that "cleared" main is worth exactly as much.

So: **I have not established that this branch causes it, and I have not
established that it doesn't.** The two identical failures are suggestive of
determinism and the seven passes contradict that; I could not reconcile
them in the runs I had.

**What the failure most likely is.** `handover-T1-HALL-2026-08-30.md` §4
documents this exact class already: `combat_manager.gd::_place_fighters()`
re-anchors each round from wherever the previous round's fighter ended up
(`deploy_offset + separation`, ~7.6m a round), so a multi-creature battle in
a tight room can walk several metres past a wall. That lane treated the
symptom by widening `built_floor_height_at()`'s claim margin to 10m and said
plainly that the cause lives in `scripts/combat/**`, which neither that lane
nor this one owns. A drift that only sometimes exceeds 10m is exactly what
an intermittent version of this failure looks like.

**What the coordinator should know before landing:**

- `ci.yml` gives `gate_e_finale` a single attempt. At the rate observed here
  it will redden CI intermittently, on this branch or any other.
- I did not skip, quarantine or retry-wrap the test, and I did not widen the
  margin again to make it go away — widening a symptom threshold twice, on a
  cause nobody has looked at, is how the margin got to 10m.
- The failure message now carries the fighter's position and the building's
  own floor claim at that position (`tests/smoke_gate_e_finale.gd`). One run
  that reproduces it will now say whether the fighter drifted outside the
  claimed footprint or the claim itself is wrong — the difference between a
  combat bug and a building bug. That is the cheapest next step and it needs
  someone who owns `scripts/combat/**`.

## 11. Capture harness: the grass defect is fixed, with evidence

The coordinator flagged a known defect where frames come out with no grass
geometry and a milky haze. It has a cause: `grass_field.gd` builds its tuft
ring around the **player** (72m radius, per its own build log) and
Terrain3D's streaming bubble follows the player too — and this capture tool
parked the player in Band 2 and then shot the Hall at z 7560, four
kilometres away. Every stand rendered on bare far-cover ground.
`perf_render_stats.gd` had already solved the same problem and says so in
its own comment: the player goes where the camera goes.

The player now travels to each stand (still hidden, still frozen) and the
per-stand settle went 8 → 40 physics frames. **Verified by eye** on H-03's
foreground before treating the frames as evidence: real tuft geometry —
individual blades, leaf clusters, a flower — not far-cover. The committed
frames are clean and the judge can use them.

One thing the frames show that I did not fix: grass grows over the causeway
cobbles. The design asks for a worn-earth suppression ring at the ramp foot
(`props.json` clearing orders) and that was never authored. Small, and not
attempted here.
