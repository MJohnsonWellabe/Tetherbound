# Visual census — 2026-08-31

**Lane:** `ralph/VISUAL-CENSUS-2026-08-31`, branched from `origin/main` at `721893a4`.
**Scope rule this lane ran under:** *diagnosis and cataloguing only.* No game
code, data, shader, asset or config was changed. The only files this branch
touches are this report, `BACKLOG-FROM-AUDIT-2026-08-31.md`, and the committed
contact sheets and critiques under `VISUAL-CENSUS-2026-08-31-shots/`.

Every fix named below is for a **later, separate session**. That split is
deliberate: a lane that both finds and fixes stops finding.

---

## Method

`ralph/conventions.md` — *"Visual-affecting work needs a blind pass, not a
look"* — plus `.claude/skills/visual-judge`. The skill is normally pointed at
one change; here its machinery is pointed at the whole game, one subject area
at a time.

Per subject area:

1. Real frames rendered from the actual build with the existing `tools/`
   capture library. **No new capture scripts were written** — every frame in
   this census came from a tool that already existed.
2. Frames assembled into one contact sheet with `tools/contact_sheet.gd`.
3. A **fresh sub-agent per round**, given only the sheet, the individual
   frames, `docs/reference/` and the `visual-judge` rubric. Told nothing about
   what the frames depict beyond what is in them, nothing about what changed,
   nothing about what answer was hoped for, and explicitly forbidden from
   reading any other file in the repo (no source, no design docs, no `ralph/`,
   no git).
4. Where a rig would otherwise produce a *false* defect — an isolated
   presentation stage reading as "the world is empty" — the critic was given
   one factual sentence about the rig and nothing else. That is context about
   the camera, not about the answer.

**Capture invocation** (`ralph/conventions.md`'s art-pipeline trap — never
`--headless` with a real rendering driver):

    xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
      --rendering-driver opengl3 --resolution 1280x720 --script tools/<capture>.gd

Godot 4.7.stable, Compatibility renderer, llvmpipe software rendering, in a
fresh container with the import cache built from scratch
(`godot --headless --path . --import`, ~30 minutes).

### Honest limits, which belong in every judgement below

- **Compatibility is what the game ships** (D01), so this is the same pipeline
  players see — but it is software-rendered here. No SSAO, no volumetric fog,
  shadows implemented differently, frame times meaningless. Composition,
  silhouette, colour relationships, scale, material read and geometry
  artefacts are trustworthy. **Fine lighting judgements are not, and are not
  made.** Where a critic's finding is about lighting, it is flagged below as
  needing confirmation on real hardware before a fix session spends time on it.
- **Frames were sanity-checked for real content before being judged.** The
  world-build log for each boot shows real scatter, real grass, real village
  structures and real NPCs, and this lane read several frames directly (see
  `01-village-approach-day.png`) and confirmed real grass geometry, real
  buildings and the trainer in frame. The "bad shot, not the actual game"
  failure that `tools/capture_check.gd` exists for did not occur.
- **Static frames.** Popping, aliasing in motion and traversal feel are
  invisible in a still. A human on the Ally remains the real test.

### The stopping rule, and how it applies to a diagnosis-only lane

`ralph/conventions.md`'s rule is *convergence, not a count*: a round counts as
improvement if the critic names a **new** defect, or `frame_stats.py` shows
measured movement on an axis the critique is about; stop after two consecutive
rounds with neither.

**That rule assumes fixes happen between rounds, and this lane is forbidden to
fix.** Re-running an identical critic over identical frames cannot produce
movement, so it would be a fake round. What *can* produce a new defect is a
fresh critic on a **different rig** for the same subject — a different camera,
a different reference in frame, a different distance. That is the only honest
form of round 2 available here, and it is what area 3 got.

So: **every area covered below records one real blind round; area 3 records
two.**
Areas that plainly warrant more are named as such rather than declared
converged. No area in this census converged, because none was given the chance
to — that is the correct reading, not a failure.

---

## Coverage

| # | Subject area | Frames | Capture tool(s) | Blind rounds |
|---|---|---|---|---|
| 1 | Open-world environment | 10 | `_capture_locations.gd` | 1 |
| 2 | Village (Band 0) | 7 | `_capture_locations.gd`, `capture_village_npcs.gd` | 1 |
| 3 | Creature roster | 50 + 70 | `capture_creature_presentation.gd`, `_capture_creature_roster.gd` | 2 |
| 4 | Combat (wild encounter) | 5 | `survey_combat.gd` | 1 |
| 5 | Player + humanoid NPC cast | 27 | `_capture_character_cast.gd` | 1 |
| 6 | Camps / rest points / build | 6 | `capture_build_pieces.gd`, `capture_creature_bed.gd`, `_capture_creature_bed_rest.gd` | 1 |
| 7 | HUD / UI | 4 (exploration HUD + 3 UI states) + 5 live-HUD combat frames | `capture_exploration_hud.gd`, `capture_ui_suite.gd`, `survey_combat.gd` | 1, plus area 4's independent pass |
| 8 | Terrain / material quality | folded into 1 & 2 | `_capture_locations.gd` | via 1 & 2 |

### Gaps in this census, stated plainly

These are gaps in the **evidence**, not findings about the game. A follow-up
session should close them before the catalogue below is treated as complete.

- **Area 4 covers the wild encounter only.** `tools/survey_combat.gd`
  delivered five frames of a real fight in progress (approach, arena opening,
  closing, enemy wind-up, attack landing) and they got a full blind round. No
  **trainer or tournament battle** was captured — `capture_combat_actions.gd`
  did not reach the front of the serial queue — so the staged-duel half of
  area 4 is still an evidence gap.
- **Area 7 (HUD/UI) got a real round, but not the whole suite.**
  `tools/capture_exploration_hud.gd` delivered `hud_full.png` — the current
  exploration HUD, carrying **this week's changes**: the health bar at the
  lower-left, the `Day 1 · 00:00` tracker top-centre, and the shrunk MAIN STORY
  card. That plus three inventory/prompt states got a full blind round
  (defects 142–168), and the five combat frames got the same HUD judged
  independently from a different rig (defects 127–133). The two rounds agreed
  on the input-glyph failure without seeing each other.

  What is **still unjudged**: the map tab, the creatures tab, the tournament
  board, the build menu, the placement ghost and the catch states.
  `capture_ui_suite.gd` walks twelve UI states at 1920×1080 and was **measured
  at ~450 s per frame** under llvmpipe — about 90 minutes for the set, which
  starved every other subject area — so it was stopped after three frames and
  its slot given to combat. `capture_map_tab.gd` and
  `_capture_tournament_board.gd` did not run. A follow-up should run that suite
  at **1280×720, not 1920×1080**; that is the single cheapest thing that would
  have made this census complete.
- **Area 1 covers Bands 1–3 only.** The `_capture_locations.gd` run was cut off
  by this lane's own 40-minute `timeout` wrapper part-way through the Relay
  Camp, so sites 6–11 (Tether Relay, Mill Crossing, Ridge Camp, Waystop,
  Stronghold, Castle Landmark) have no fresh frames. **Bands 4 and 5 are
  unjudged.** The timeout has been raised in the lane's own helper; the
  remaining sites are a `--only=06-relay,07-mill-crossing,08-ridge-camp,09-waystop,10-stronghold,11-castle-landmark`
  re-run away.
- **Area 8's specific asks are partly unanswered.** Ground seams, water and
  weather were to be captured by `_audit_d_seam_probe.gd`, `capture_water.gd`
  and `capture_weather.gd`; none ran. The **Stormwall Hall exterior silhouette**
  (`J1`/`J2`, flagged as regressed from +33.1 to +11.6) was to be re-measured
  with `tools/_judge_capture_hall.gd`, which also did not run. **This census
  therefore neither confirms nor clears the J1/J2 regression.** What area 8 did
  get is folded into areas 1 and 2, which found terrain, material, LOD and
  horizon defects in quantity.

### One incidental finding, outside the visual scope

Building the import cache from scratch made Godot generate **seven `.gd.uid`
sidecar files that are missing from `main`**:

    tests/smoke_creatures_tab_controller.gd.uid
    tests/test_tutorial_faint_floor.gd.uid
    tools/_audit_d6_debug_overlay_probe.gd.uid
    tools/_audit_d6_mipfilter_probe.gd.uid
    tools/_audit_i6_minimap_heading_probe.gd.uid
    tools/_diag_ness_time_ab.gd.uid
    tools/_probe_cap1_faint_floor.gd.uid

`.uid` files **are** tracked in this repo — 870 of them — and are not
gitignored, so these seven are a gap, not a convention. Each belongs to a `.gd`
file committed on 2026-08-31 by another lane (`BACKLOG-I7-CREATURES-TAB-TEST`,
`BACKLOG-D6-SEAM-PROBE`, `CAP-1` and neighbours) whose commit did not include
the sidecar. Godot assigns a fresh random UID on first import, so today every
fresh checkout generates its own and they drift per machine.

**This lane did not commit them** — a diagnosis-only census branch is the wrong
place for game-adjacent files, and they are not this lane's to author. They were
deleted so the tree matches what this lane found. Recorded here so a coordinator
can assign the one-line fix to whoever owns those files.

**Why the queue was so short.** A single Meadows boot peaks at **~7 GB RSS** on
this 16 GB box; two concurrent boots OOM-killed a run early in the session
(`dmesg`: "Memory cgroup out of memory: Killed process ... (godot)
anon-rss:6934468kB"). Every world capture after that ran strictly serially, and
under llvmpipe each costs roughly ten minutes of world build before its first
frame. That measurement is the useful part of the gap: **a future full-game
capture sweep needs either a bigger box or several sessions, not more
parallelism.**

---

## Cross-cutting findings

Four things were named independently by critics who could not see each other's
frames or each other's reports. Independent convergence is the strongest signal
in this census, and these four should be read as the headline.

1. **Shading incoherence across the cast and roster.** The area-5 critic
   measured a **4.3-to-7.5 head-height spread** across thirteen humanoids all
   labelled 1.72–1.90 m. The area-3 round-1 critic sorted twenty-five creatures
   into **four incompatible material languages**. The area-3 round-2 critic
   independently sorted them into four again and named the shared automated
   texture pass connecting six of them. The area-1 critic, looking at world
   frames with no knowledge of either, counted **three humanoid idioms and two
   creature idioms** standing in the same places. Four critics, four rigs, one
   finding.

2. **Missing shadow and missing ambient fill — with an important qualification
   this lane found itself.** Area 2 reports "no cast shadows
   anywhere in any of the six world frames." Area 1 reports shadows that work
   in the near field and stop before the mid-ground — with the tree in
   `02-mill-pond-approach-day.png` casting a correct soft shadow, which proves
   capability and localises the fault to **range**. Area 3 round 2 measured
   **41.9 % pure-black pixels** on `07-burrowback-shiny.png` and **31.9 % pure
   white** on `14-duskhush-shiny.png` against **0.00 % / ≤0.01 %** on every
   Palworld creature sampled. Area 6 found the same crush at `(0,0,0)`.
   **The qualification:** `shots/_diag/hud_full.png`, captured late in this
   session by `tools/capture_exploration_hud.gd` and read directly by this lane
   rather than by a critic, **plainly shows cast shadows** — the trainer's own
   shadow and a large soft shadow band across the meadow. So "there are no cast
   shadows" as a flat statement is **wrong**, and this report does not carry it.
   What the evidence actually supports is narrower and matches area 1's own
   reading: shadows exist and work in the near field, and stop or thin out
   before the mid-ground, which is why a 10 m rock massif and a whole ridge
   tree line cast nothing while a foreground tree casts correctly. That is a
   **range** finding.

   **It still needs hardware confirmation before a fix lane spends on it** —
   software rendering is exactly where a shadow judgement is least trustworthy,
   and three critics reporting "no shadows" on frames that demonstrably contain
   some is itself a reason for caution. The clipping and crushing percentages
   are albedo/exposure and are trustworthy now.

3. **No aerial perspective, and visible world edges.** Area 1 and area 2 both
   report distant foliage rendering at the same saturation, value and contrast
   as foreground foliage, and both report a hard scatter-cull ring beyond which
   the terrain is bare shell. Both name the same reference behaviour
   (`palworld-04`, `palworld-05`) as the thing that is missing.

4. **Scatter that reads as generated rather than authored.** Uniform density,
   uniform scale, no clustering, no clearings, no trodden ground — named for
   the village (area 2), the relay camp and the quarry (area 1). Area 2 adds
   the sharpest version: grass at ~0.9–1.0 m grows up to the doorsteps and
   through the paving, so the settlement has no cleared negative space, and
   waist-high grass would swallow the small creatures the roster does not yet
   have.

---

## Per-area rounds

Full verbatim critiques are committed under
`VISUAL-CENSUS-2026-08-31-shots/critiques/`. Contact sheets are under
`VISUAL-CENSUS-2026-08-31-shots/sheets/` as JPG (the `shots/` tree itself is
gitignored, so the sheets are the durable evidence).

| Area | Critique file | Sheet | Bar A (key art) | Bar B (Palworld) |
|---|---|---|---|---|
| 1 — world sites | `01-world-sites-round1.md` | `01-world-sites.jpg` | **yes** | **no** |
| 4 — combat | `04-combat-round1.md` | `04-combat.jpg` | **no** | yes |
| 7 — HUD / UI | `07-ui-round1.md` | `07-ui.jpg` | **no** | yes, weakly |
| 2 — village | `02-village-round1.md` | `02-village.jpg` | **no** | yes, weakly |
| 3 — creatures r1 | `03-creatures-round1.md` | `03-creatures-presentation.jpg` | **no** | **no** |
| 3 — creatures r2 | `03-creatures-round2.md` | `03-roster-world.jpg` | **no** | yes, half |
| 5 — cast | `05-cast-round1.md` | `05-cast.jpg` | **no** | **no** |
| 6 — build/camp | `06-build-camp-round1.md` | `06-build-camp.jpg` | **no** | yes, on one asset |

Area 3 did **not** converge. Round 2 named a large set of defects round 1 had
not — the shiny hue-rotation system collapsing internal silhouettes, the full
measured scale table, `galecrest-alpha` floating off the ground, a 36 % size
mismatch for `pipwing` between its own frame and the lineup, and the clipping
percentages. By the convention's own rule that is improvement, so area 3 was
still moving when the session ran out of budget and warrants at least one more
round.

Areas 1, 2, 4, 5, 6 and 7 each have exactly one round and are therefore **not**
converged either; a second round on a different rig is owed for each.

Area 7 is the interesting case, and it is worth naming because it is the
closest thing this census has to a validated finding. The HUD was judged
**twice, blind, from two unrelated rigs** — once in combat (area 4) and once in
exploration (area 7) — by critics who saw neither each other's frames nor each
other's reports. Both independently reported the input-glyph failure. When two
blind readers converge on the same defect from different pictures, that defect
is real, and `BACKLOG-VISUAL-INPUT-GLYPH-LANGUAGE` should be treated
accordingly.

---

## Numbered defect catalogue

Each entry names its subject area, the exact frame or asset, whether it is
bite-sized, and a `BACKLOG-VISUAL-<id>` name for a future fix session.

**Sizing key**
- **bite-sized** — one material, scale, transform, lighting or placement value;
  a focused session can close it.
- **needs owner decision** — a real cheap fix exists but which fix is the
  owner's call.
- **needs owner-supplied reference art** — closing it requires a new creature
  or humanoid mesh or a Meshy generation. `CLAUDE.md` gates every one of these
  on owner-supplied reference art, so **none of them is proposed here**; they
  are recorded as blocked and belong in `BLOCKED.md`, not in a fix queue.
- **not bite-sized** — real, cited, but multi-day art/design work that needs no
  new generation.

### Area 1 — open-world environment

1. **`03-quarry-approach-day.png` is a broken capture stand** — the camera sits
   inside foliage/terrain; ~95 % of the frame is near-black. The Old Quarry's
   announcement shot cannot be judged at all. Tool-side defect in
   `tools/_capture_locations.gd`'s eye for that stand. **bite-sized** —
   `BACKLOG-VISUAL-QUARRY-APPROACH-STAND`
2. **Shadow draw distance cuts off before the mid-ground.** The ~10 m Warrens
   massif in `04-warrens-approach-day.png` casts nothing on the meadow at its
   base; the ridge tree line in `05-relay-camp-approach-day.png` casts nothing.
   The near-field tree in `02-mill-pond-approach-day.png` casts correctly, so
   this is range, not capability. **bite-sized (config), but confirm on real
   hardware first** — `BACKLOG-VISUAL-SHADOW-RANGE`
3. **No aerial perspective.** Distant tree lines in
   `05-relay-camp-approach-day.png` and `03-quarry-standing-day.png` match
   foreground foliage in saturation, value and contrast. **needs owner
   decision** — an audit item (`D7`) already has an open fog decision, and this
   is the same lever — `BACKLOG-VISUAL-AERIAL-PERSPECTIVE`
4. **Visible world edge at the horizon.** `03-quarry-standing-day.png` (left
   horizon, x 0–260), `02-mill-pond-approach-day.png` (left third),
   `05-relay-camp-approach-day.png` (right edge plateau cut). **not
   bite-sized** — needs distant-terrain silhouettes —
   `BACKLOG-VISUAL-HORIZON-CLOSURE`
5. **Tree LOD trunk tint mismatch.** In `02-mill-pond-approach-day.png` the
   foreground trunk is bright terracotta-orange and the same species at 30 m is
   near-black. **bite-sized** — `BACKLOG-VISUAL-TREE-LOD-TINT`
6. **`02-mill-pond-wheel-day.png` contains no water wheel**, despite being the
   stand named for it — the mill's water-facing elevation is blank stone. (The
   tool's own header already records that the recipe contains no wheel module.)
   **needs owner decision** — add the module or rename/repoint the stand —
   `BACKLOG-VISUAL-MILL-WHEEL`
7. **Sunken outbuilding at the mill.** In `02-mill-pond-wheel-day.png` the left
   outbuilding's eaves sit at ground level with its walls buried in terrain.
   **bite-sized** — `BACKLOG-VISUAL-MILL-OUTBUILDING-SEAT`
8. **Wide-FOV keystoning on the mill stands.** `02-mill-pond-standing-day.png`
   and `02-mill-pond-wheel-day.png` splay the mill's verticals and give 55–65 %
   of frame to empty sky. Capture-rig defect. **bite-sized** —
   `BACKLOG-VISUAL-MILL-STAND-FRAMING`
9. **Warrens interior and exterior are one grey noise texture at one UV
   scale.** `04-warrens-approach-day.png` and `04-warrens-standing-day.png`:
   floor, walls and overhangs identical; boxy right-angle intersections; no
   moss, no waterline, no base dirt. The critic's words: "does not look like
   art; it looks like a greybox someone applied one material to." **not
   bite-sized** — `BACKLOG-VISUAL-WARRENS-SURFACING`
10. **Warrens ceiling beams carry the rock texture**, and the leftmost beam
    enters the wall with no bracket (`04-warrens-den-day.png`). **bite-sized**
    — material assignment — `BACKLOG-VISUAL-WARRENS-BEAM-MATERIAL`
11. **Unsourced emissive slab on the Warrens left wall** (`04-warrens-den-day.png`,
    approx. x 145–165) — no geometry, no falloff, no emitter. **bite-sized** —
    `BACKLOG-VISUAL-WARRENS-EMISSIVE-SLAB`
12. **Trainer interpenetrates the badger** in `04-warrens-den-day.png` — torso
    and backpack through the creature's foreleg and chest, front and centre.
    **bite-sized** — capture stand placement — `BACKLOG-VISUAL-WARRENS-DEN-STAND`
13. **Z-fighting sliver on the Warrens rock face** (`04-warrens-standing-day.png`,
    approx. x 1050–1230, y 500–590). **bite-sized** —
    `BACKLOG-VISUAL-WARRENS-ZFIGHT`
14. **Hard sand/grass material boundary with no transition fringe**
    (`03-quarry-standing-day.png`, mid-ground). **bite-sized** —
    `BACKLOG-VISUAL-SPLAT-TRANSITION`
15. **The quarry contains nothing that has been quarried.**
    `03-quarry-standing-day.png` is props on sand at even intervals — no cut
    face, no benched steps, no spoil heap, no dressed blocks, no wear paths.
    **not bite-sized** — needs quarry-specific geometry —
    `BACKLOG-VISUAL-QUARRY-IDENTITY`
16. **Slab path begins and ends in open sand** (`03-quarry-conduit-head-day.png`),
    squared off at the lower left, connecting nothing. **bite-sized** —
    `BACKLOG-VISUAL-QUARRY-PATH-TERMINUS`
17. **Floating branch with no trunk** in `03-quarry-conduit-head-day.png`'s
    top-right corner. **bite-sized** — `BACKLOG-VISUAL-QUARRY-FLOAT-BRANCH`
18. **The tether ribbon does not read as energy** — flat, constant-width,
    unlit, with visible polygon kinks (`03-quarry-standing-day.png`,
    `03-quarry-conduit-head-day.png`). It is also the only VFX in the survey.
    **not bite-sized** — needs an energy shader —
    `BACKLOG-VISUAL-TETHER-RIBBON-SHADER`
19. **Team Tether hardware is teal-and-cyan and reads inviting, not hostile**
    (`03-quarry-standing-day.png`). The oxblood reserve is intact, but nothing
    in ten frames signals danger. **needs owner decision** —
    `BACKLOG-VISUAL-TETHER-DANGER-PALETTE`
20. **Signpost text is illegible at any scale** — sub-pixel dark smear
    (`03-quarry-standing-day.png`, `03-quarry-conduit-head-day.png`).
    **bite-sized** — `BACKLOG-VISUAL-SIGN-LEGIBILITY`
21. **Wicker basket disagrees with itself across two frames** — ~1.2 m in
    `03-quarry-standing-day.png`, ~0.6 m in `03-quarry-conduit-head-day.png`.
    **bite-sized** — `BACKLOG-VISUAL-BASKET-SCALE`
22. **One tree asset scaled across a 5:1 range**, so 2.5 m instances read as
    bonsai beside 12 m ones of identical silhouette
    (`04-warrens-approach-day.png`). **not bite-sized** — needs a second
    canopy silhouette and a mid-storey — `BACKLOG-VISUAL-TREE-VARIETY`
23. **4 m boulder carries the same texel density as the 1 m rocks beside it**
    (`03-quarry-conduit-head-day.png`) — reads as a small rock scaled 4×.
    **bite-sized** — `BACKLOG-VISUAL-BOULDER-TEXEL-DENSITY`
24. **Uniform scatter with no size jitter and no clustering**
    (`05-relay-camp-approach-day.png`: one plant at ~1.5 m spacing across the
    whole lower frame; same plant the same size at 3 m and 25 m).
    **not bite-sized** — overlaps the existing `D3` placement-rule item —
    `BACKLOG-VISUAL-SCATTER-CLUSTERING`
25. **Neither the Warrens nor the Relay Camp announces itself.**
    `04-warrens-approach-day.png` reduces at thumbnail to one grey lump;
    `05-relay-camp-approach-day.png` to a green rectangle with a 40-pixel
    banner. **not bite-sized** — needs landmark silhouettes —
    `BACKLOG-VISUAL-SITE-LANDMARKS`
26. **Foreground leaf cards show hard black alpha edges and inter-card slivers**
    (`02-mill-pond-approach-day.png`, right side of canopy). **bite-sized** —
    `BACKLOG-VISUAL-LEAF-ALPHA-EDGES`
27. **Sun disc is a hard-edged white circle with no bloom or scatter**, over a
    low-resolution cream-brown cloud smear (`02-mill-pond-standing-day.png`).
    **bite-sized (sun)** / **not bite-sized (sky texture)** —
    `BACKLOG-VISUAL-SUN-AND-SKY`
28. **The badger in the Warrens den gets no key, no rim and no bounce**
    (`04-warrens-den-day.png`) — a large creature in a dark room, flat-lit.
    **bite-sized** — `BACKLOG-VISUAL-DEN-LIGHTING`

### Area 2 — village (Band 0)

29. **No cast shadows in any of the six village frames** — not from buildings,
    not from characters, not from trees, not from props. The trainer on the
    flagstone in `01-village-route-out-day.png` has zero contact shadow.
    Same root as defect 2; recorded separately because the village frames show
    it at close range where a range limit should not apply. **bite-sized**, but
    confirm on real hardware first — `BACKLOG-VISUAL-SHADOW-RANGE`
30. **Daylight ground-glow blobs with no emitter** — yellow-white circular
    patches at the base of the right house in `01-village-twins-day.png`, at
    the tree base in `01-village-approach-day.png`, and at the left edge of
    `01-village-grandpa-yard-day.png`. Reads as debug lights left on.
    **bite-sized** — `BACKLOG-VISUAL-DAYLIGHT-GLOW-BLOBS`
31. **Grass grows to the doorsteps and through the paving.**
    `01-village-twins-day.png`, `01-village-grandpa-yard-day.png`, and blades
    through the flagstone in `01-village-route-out-day.png`. The settlement has
    no cleared negative space. **bite-sized** — a grass-suppression mask around
    structures and paths — `BACKLOG-VISUAL-VILLAGE-GRASS-CLEARANCE`
32. **Grass is ~0.9–1.0 m everywhere** — hip height on a 1.80 m figure, uniform
    across meadow, yards and square. Directly relevant to creature readability.
    **needs owner decision** — height is a deliberate value with gameplay
    consequences — `BACKLOG-VISUAL-GRASS-HEIGHT`
33. **Purple flower prop is 4–6× oversized** — petals ~0.28 m, clump ~1.2 m
    across, and the single loudest object on the whole census contact sheet
    (`01-village-grandpa-yard-day.png`). **bite-sized** —
    `BACKLOG-VISUAL-FLOWER-SCALE`
34. **Four houses in a near-straight line at similar spacing, all facing the
    same way** (`01-village-approach-day.png`), and `01-village-twins-day.png`
    is two near-identical houses differing only in roof tint. **not
    bite-sized** — overlaps the queued `BACKLOG-VILLAGE-LAYOUT` —
    `BACKLOG-VISUAL-VILLAGE-MASSING`
35. **Roof hue inconsistency between adjacent buildings** — strong red left,
    salmon-orange right in `01-village-twins-day.png`. **bite-sized** —
    `BACKLOG-VISUAL-ROOF-TINT`
36. **Chimneys and the well clip toward pure white**
    (`01-village-standing-day.png`, `01-village-route-out-day.png`) — brighter
    than the sky, which the key art never does. **bite-sized** —
    `BACKLOG-VISUAL-VILLAGE-STONE-VALUE`
37. **Floating paving slabs with a ~10 cm lip and a dark gap beneath**, cobble
    pattern cut mid-stone at the seams (`01-village-route-out-day.png`).
    **bite-sized** — `BACKLOG-VISUAL-PAVING-SEAT`
38. **Floating house plinth** — the right house in `01-village-twins-day.png`
    sits on a thin grey slab hovering above the terrain. **bite-sized** —
    `BACKLOG-VISUAL-HOUSE-PLINTH-SEAT`
39. **Ivy alpha cards float off the masonry** with jagged edges and green
    fringing (`01-village-route-out-day.png`, `01-village-standing-day.png`).
    **bite-sized** — `BACKLOG-VISUAL-IVY-CARDS`
40. **Chimney sits on the tiles with a visible gap and no flashing**, plus a
    second undersized pale object further along the same ridge
    (`01-village-standing-day.png`). **bite-sized** —
    `BACKLOG-VISUAL-CHIMNEY-SEAT`
41. **Three texel densities on one façade** — cobble, white brick panels and
    plaster, plus two tile densities across the two roofs in frame
    (`01-village-standing-day.png`). **not bite-sized** —
    `BACKLOG-VISUAL-FACADE-TEXEL-DENSITY`
42. **Visible tiling** — roof moss speckles repeat at a fixed interval, ground
    cobble repeats (`01-village-twins-day.png`, `01-village-standing-day.png`).
    **bite-sized** — `BACKLOG-VISUAL-TILING-BREAKUP`
43. **Two dead leafless branch props stand in high summer** beside fully-leafed
    trees (`01-village-approach-day.png`, repeated at the right edge of
    `01-village-twins-day.png`). **bite-sized** —
    `BACKLOG-VISUAL-DEAD-BRANCH-PROPS`
44. **Flat unlit orange spiky plant reads as a broken asset**
    (`01-village-tournament-day.png`, bottom left). **bite-sized** —
    `BACKLOG-VISUAL-ORANGE-PLANT`
45. **Hard-edged rectangular terrain splat patch with 90° corners** on the
    hillside right of the mountain (`01-village-tournament-day.png`).
    **bite-sized** — `BACKLOG-VISUAL-SPLAT-RECTANGLE`
46. **Scatter-cull ring** — grass and shrubs stop abruptly ~40 m out and the
    world beyond is bare green shell (`01-village-tournament-day.png`,
    `01-village-approach-day.png`, `01-village-twins-day.png`). **needs owner
    decision** — distance-scatter band vs. impostors is a performance call the
    Ally has to arbitrate — `BACKLOG-VISUAL-SCATTER-CULL-RING`
47. **Signpost labels read as floating UI, at four different text sizes**, one
    clipped by and intersecting the cottage door frame
    (`01-village-standing-day.png`). **bite-sized** —
    `BACKLOG-VISUAL-SIGNPOST-STYLE`
48. **The tournament notice board is a white plane at the wrong scale and
    depth**, illegible, with the trainer's hair rendering through it
    (`01-village-tournament-day.png`). **bite-sized** —
    `BACKLOG-VISUAL-NOTICE-BOARD`
49. **No landmark anywhere in the village** — at 30 % the six frames read as
    repetitions of one roofline, and the arrival shot gives the player nothing
    to aim at. **not bite-sized** — needs a landmark asset (mast, tower,
    windmill, hero tree) — `BACKLOG-VISUAL-VILLAGE-LANDMARK`
50. **Zero creatures in six frames of the home village of a creature-training
    game.** Every Palworld reference and two key-art panels put a creature front
    of frame. **needs owner decision** — whether village ambient creatures
    exist at all is design, not art — `BACKLOG-VISUAL-VILLAGE-CREATURES`
51. **The elder NPC is ~1.3–1.4 m and a different proportion family** — stands
    further from camera than the trainer yet tops out at his shoulder
    (`01-village-route-out-day.png`). **bite-sized (transform)** — but see
    defect 57, of which this is one instance —
    `BACKLOG-VISUAL-ELDER-SCALE`
52. **Cobbles at ~35–40 cm per stone on otherwise semi-realistic buildings**,
    beside timber joinery detailed at near-realistic scale
    (`01-village-twins-day.png`). **not bite-sized** —
    `BACKLOG-VISUAL-MASONRY-SCALE`
53. **Trees top out at ~4–5 m — a leaf ball on a bare unbranched pole.** The key
    art's defining feature is oak canopies that dwarf the cottages.
    **not bite-sized** — same asset gap as defect 22 —
    `BACKLOG-VISUAL-TREE-VARIETY`
54. **The well is a solid capped stone box** — no shaft, no rope, no winch; the
    bucket rests on the lid (`01-village-route-out-day.png`). **not
    bite-sized** — needs a real well asset — `BACKLOG-VISUAL-WELL-ASSET`
55. **`village_npcs.png` fills five slots with two characters**, unaltered —
    three of one female, two of one male, sharing one hair mesh, one face, one
    boot, one belt rig. **needs owner-supplied reference art** for genuinely new
    bodies; **bite-sized** for pulling more of the 28 already-installed
    humanoids into the village (`docs/art/HUMANOID_ASSET_INVENTORY.md` records
    four finished bodies standing nowhere in the game) —
    `BACKLOG-VISUAL-VILLAGE-NPC-VARIETY`
56. **Villager silhouettes collide with the player's** — same proportions,
    boots, belt and vest cut, so at distance an NPC is indistinguishable from
    the player. **needs owner decision** — a costume/palette rule, not a mesh —
    `BACKLOG-VISUAL-PLAYER-SILHOUETTE-SEPARATION`

### Area 3 — creature roster

57. **The roster is four incompatible material languages.** Hand-painted
    (`meadowhart`, `burrowback`, `mosshell`), semi-photoreal (`frostclaw`,
    `trailpup`, `stormtrail`, `ashtusk`), glossy plastic (`paddlenewt`,
    `riftfrill`, `reedwing`, `ripplet`), and unresolved generated mass
    (`bramblebun`, `shadelet`). Named independently by both rounds.
    **needs owner-supplied reference art** for the restyle —
    `BACKLOG-VISUAL-CREATURE-STYLE-UNIFICATION`
58. **Six species share one hard-edged two-tone blotch mask** with no fur grain
    beneath it, and on `13-galecrest-alpha.png` the mask's edges stair-step
    because it is lower-resolution than the model it wraps. **needs
    owner-supplied reference art** — replacing a procedural mask with authored
    markings is a texturing pipeline decision —
    `BACKLOG-VISUAL-BLOTCH-MASK-REPLACEMENT`
59. **`bramblebun` has no face.** No eyes, no nose, no mouth findable at 3×
    zoom, in either rig (`bramblebun_portrait.png`, `04-bramblebun.png`), plus
    stray magenta specks and visible alpha-card intersections. Both rounds
    independently called it not shippable. **needs owner-supplied reference
    art** — `BACKLOG-VISUAL-BRAMBLEBUN-FACE` *(note: `BACKLOG-B2-GRASS-SEPARATION`
    already concluded this mesh needs new art; this is the same asset failing a
    second, independent way)*
60. **`07-burrowback-rear.png` has no rear.** No tail, no rear anatomy; reads as
    a boulder at thumbnail. **needs owner-supplied reference art** —
    `BACKLOG-VISUAL-BURROWBACK-REAR`
61. **The shiny system applies one hue rotation to every material slot at
    once**, so `09-tuskroot-shiny.png` loses both its moss crest and its ivory
    tusks into one mint green and reads *worse* than the base; same on
    `01-terrapup-shiny.png` and `17-veridian-shiny-rear.png`. **bite-sized** —
    recolour the body slot only — `BACKLOG-VISUAL-SHINY-SLOT-SCOPE`
62. **A shiny variant wears the Team Tether oxblood.**
    `16-reedwing-shiny.png` renders a friendly duck at rgb (106,37,46), the
    board's reserved banner hue at higher chroma; `11-mosshell-shiny.png` is
    adjacent. **bite-sized** — exclude the oxblood family from the shiny hue
    range — `BACKLOG-VISUAL-SHINY-OXBLOOD-EXCLUSION`
63. **Creature albedos clip and crush.** 31.9 % pure white on
    `14-duskhush-shiny.png`, 26.4 % on `03-galewisp.png`, 41.9 % pure black on
    `07-burrowback-shiny.png`, 37.9 % on `17-veridian.png` — against 0.00 % /
    ≤0.01 % on every Palworld creature sampled. **bite-sized** —
    `BACKLOG-VISUAL-CREATURE-ALBEDO-CLIPPING`
64. **Both starters are taller than the 1.80 m player.** `01-terrapup.png`
    1.92 m, `02-ripplet.png` 1.93 m — and `ripplet` is designed as a chibi
    pocket mascot with stub mitts for hands. **bite-sized** — transform values —
    `BACKLOG-VISUAL-STARTER-SCALE`
65. **The badger cub outranks the badger adult.** `01-terrapup` 1.92 m vs
    `07-burrowback` 1.66 m. **bite-sized** — `BACKLOG-VISUAL-BADGER-LINE-SCALE`
66. **There is no small tier.** Sixteen of seventeen species measure ≥0.97 m and
    twelve sit inside one 0.97–2.08 m band. Nothing could sit on a shoulder or
    scurry underfoot. **needs owner decision** — the roster's size distribution
    is design — `BACKLOG-VISUAL-ROSTER-SCALE-SPREAD`
67. **The alpha is only 1.14× a common field boar.** `13-galecrest-alpha.png`
    at 2.85 m vs `09-tuskroot.png` at 2.08 m. Scale alone is bite-sized; making
    it read as a boss is not. **bite-sized (scale)** —
    `BACKLOG-VISUAL-ALPHA-SCALE`
68. **`13-galecrest-alpha.png` floats** — lit ground visible under and between
    every claw, rearmost toe in mid-air, shadow offset behind. **bite-sized** —
    `BACKLOG-VISUAL-ALPHA-GROUNDING`
69. **`15-pipwing` renders at two different sizes** — 0.77 m in its own frame,
    1.05 m in `00-lineup.png`, a 36 % discrepancy, while the other four lineup
    subjects reconcile to within 2–4 %. **bite-sized** —
    `BACKLOG-VISUAL-PIPWING-LINEUP-SCALE`
70. **Five off-board saturated colours.** `10-paddlenewt` at S=0.91 with 70 % of
    its pixels >110 (L1) from any key-art swatch; `11-mosshell`'s head
    rgb(35,195,194); `16-reedwing` cobalt-and-chrome-yellow; `02-ripplet`
    cobalt; `13-galecrest` highlighter green and cyan. The board's strip
    contains no cyan at all. **bite-sized** — material hue/saturation values —
    `BACKLOG-VISUAL-CREATURE-PALETTE-CONFORMANCE`
71. **One recoloured soft-circle particle does ember, spark and shadow-magic
    duty** across `ashtusk`, `stormtrail`, `nightburrow` and `riftfrill`, and
    reads as lens dust in all four. **bite-sized** —
    `BACKLOG-VISUAL-PARTICLE-SPRITE`
72. **`cindercub`'s fur is a visibly tiled dot lattice**, repeating on a regular
    grid across body, legs and face; reads as reptile scale. **needs
    owner-supplied reference art** — the lattice is baked into the texture —
    `BACKLOG-VISUAL-CINDERCUB-RETEXTURE`
73. **`shadelet`'s whole body texture is out of focus** and its eyes are flat
    yellow lozenges with no pupil or highlight. **needs owner-supplied
    reference art** — `BACKLOG-VISUAL-SHADELET-TEXEL-DENSITY`
74. **Four species collapse to one upright-ovoid silhouette** — `02-ripplet`,
    `14-duskhush`, `15-pipwing`, `16-reedwing`. **needs owner-supplied
    reference art** — silhouette is geometry —
    `BACKLOG-VISUAL-EGG-SILHOUETTE-SEPARATION`
75. **Nine of twenty-five roster entries are material-only recolours of four
    base meshes** — three badgers, two boars, two newts, two canines. **needs
    owner-supplied reference art** — `BACKLOG-VISUAL-RECOLOUR-DIFFERENTIATION`
76. **Clipped-on props that read as attachments, not anatomy** —
    `07-burrowback`'s spine plate, `09-tuskroot`'s flat moss slab with a hard
    seam, `08-meadowhart-rear.png`'s shoulder card-fan that reads as a saddle on
    a wild creature. **bite-sized** — reseat and blend —
    `BACKLOG-VISUAL-CREATURE-PROP-SEATING`
77. **`12-brooktail`'s named feature is invisible from the front**, and from
    behind the teal paddle tail is a different material and hue from the brown
    fur with a hard unblended seam plus a stray orange dot at the tail base.
    **bite-sized (seam and dot)** — `BACKLOG-VISUAL-BROOKTAIL-TAIL-SEAM`
78. **`17-veridian-shiny-rear.png` shows a see-through gap between the shoulder
    mantle and the neck**, and its tail is a leaf card on a bare stalk.
    **bite-sized (gap)** — `BACKLOG-VISUAL-VERIDIAN-MANTLE-GAP`
79. **The legendary stag's body is smaller than the starter deer's.**
    `veridian` shoulder height ~0.72 bar vs `meadowhart` ~0.85 bar; all its
    apparent size is antlers. **needs owner decision** —
    `BACKLOG-VISUAL-VERIDIAN-MASSING`
80. **`05-mudsnout`'s crown leaf card shows an untextured white/grey backface
    fringe.** **bite-sized** — `BACKLOG-VISUAL-MUDSNOUT-LEAF-BACKFACE`

### Area 5 — player character and humanoid NPC cast

81. **The cast spans 4.3 to 7.5 head-heights while all labelled 1.72–1.90 m.**
    Grandpa 4.3, trainer/villagers 5.0, grunt 5.3, field captain 5.8, ridge
    captain 6.8, Warden 7.5. **needs owner-supplied reference art** — the single
    most expensive finding in the census —
    `BACKLOG-VISUAL-HUMANOID-PROPORTION-FAMILY`
82. **`12-captain-ridge` and `13-captain-riverwatch` are the same asset twice.**
    Same head, beard, pauldrons, crest, cape, boots, pose. **needs
    owner-supplied reference art** for a genuinely second captain; **bite-sized**
    for reassigning one of the four installed-but-unused bodies
    (`officer_b`, `wandering_trainer`, `rival_trainer`, `young_trainer`) —
    `BACKLOG-VISUAL-CAPTAIN-DUPLICATE`
83. **The Team Tether rank ladder is a scale slider on a sphere.** `06`→`07`→
    `08`→`09` differ only by a chest bead that is 2–3 px on the contact sheet;
    no shoulder armour, no coat length, no headgear, no promoted accent colour.
    **not bite-sized** — needs authored rank language —
    `BACKLOG-VISUAL-RANK-LADDER-LANGUAGE`
84. **The rank insignia is a primitive.** `08-rank-officer-front.png` is a plain
    glossy red sphere with a specular hotspot; `09-rank-captain-threequarter.png`
    shows the disc floating clear of the bandolier on its own plane.
    **bite-sized** — `BACKLOG-VISUAL-RANK-INSIGNIA`
85. **Value/saturation drift inside the rank ladder** — positions 6 and 9 read
    maroon, 7 and 8 noticeably greyer, so the mid ranks are the drabbest.
    **bite-sized** — `BACKLOG-VISUAL-RANK-PALETTE-DRIFT`
86. **The captains wear magenta/lilac/cyan heraldry and a pale pink cape**
    (`12`, `13`) — hues that appear nowhere on the key-art strip — so they read
    as a different faction from the grunts they command. **bite-sized** —
    material recolour — `BACKLOG-VISUAL-CAPTAIN-FACTION-PALETTE`
87. **The captains' chest crest is an unlit decal** — it does not respond to the
    scene light while the leather around it does. **bite-sized** —
    `BACKLOG-VISUAL-CAPTAIN-CREST-UNLIT`
88. **Gold-tipped glove fingers on `11`, `12`, `13`** — reads as an unassigned
    material or skin punching through the glove. **bite-sized** —
    `BACKLOG-VISUAL-GLOVE-FINGERTIP-MATERIAL`
89. **Throat gap on `12` / `13`** — a bright tan wedge between beard and collar
    reading as a hole in the collar geometry. **bite-sized** —
    `BACKLOG-VISUAL-CAPTAIN-THROAT-GAP`
90. **`11-captain-field`'s face is a flat unshaded mask** with no nose
    projection or cheekbone turn, painted eyes with no eyeball geometry, and a
    **detached hair card floating off the crown**; its face renders near-white
    while its hands render dark gold-brown. **needs owner-supplied reference
    art** for the head; **bite-sized** for the skin material mismatch —
    `BACKLOG-VISUAL-FIELD-CAPTAIN-HEAD`
91. **The Warden's coat tails are single-sided planes** with no thickness
    (`03-warden-threequarter.png`); same on `11`'s hanging straps and `13`'s
    cape. **not bite-sized** — `BACKLOG-VISUAL-CLOTH-THICKNESS`
92. **Grandpa's hands are fused mitten blobs** that interpenetrate his hip pouch,
    with forearms reading truncated. **needs owner-supplied reference art** —
    `BACKLOG-VISUAL-HUMANOID-HANDS`
93. **Villager faces are painted discs with hard-edged sclera and no lid
    geometry**, at visibly lower texture resolution than the trainer's at the
    same screen size; buttons, stitching and belt hardware all painted with no
    relief. **needs owner-supplied reference art** —
    `BACKLOG-VISUAL-VILLAGER-FACE-FIDELITY`
94. **The Warden does not read as the apex of his faction** — labelled 1.85 m
    against 1.90 m for the three captains, and visibly narrower through the
    shoulder. **needs owner decision** —
    `BACKLOG-VISUAL-WARDEN-MASSING`
95. **No rim or back light anywhere in the cast set**, so the Warden's layered
    coat collapses into one dark mass and the four Team Tether figures merge in
    the lineup. **bite-sized (capture rig)**, and **confirm on hardware** for
    the in-game case — `BACKLOG-VISUAL-CAST-RIM-LIGHT`
96. **`14-lineup-all.png` is the one frame where relative scale is the whole
    point and the one frame with the height annotation stripped out.**
    **bite-sized** — capture-tool fix — `BACKLOG-VISUAL-LINEUP-RULER`
97. **Thirteen characters share one arms-down idle and none holds anything**, so
    the lineup reads as an asset dump rather than a cast. **bite-sized** —
    pose/prop variation in the capture rig; **not bite-sized** if it means
    authoring per-character idles — `BACKLOG-VISUAL-CAST-POSE-VARIETY`

### Area 6 — camps, rest points and build structures

98. **The build kit has no dark value.** `build_pieces_lineup.png` clips 9.4 %
    of its pixels; plaster (255,255,209), fence rail (255,230,164), top rail
    (255,187,104), roof ridge (255,153,84). Nothing anywhere on any piece is
    dark, which is why the kit has no weight. **bite-sized (exposure)** /
    **not bite-sized (authored value in the textures)** —
    `BACKLOG-VISUAL-BUILD-KIT-VALUE`
99. **Five wood hues in one kit** — floor (199,123,75), door (182,116,76), top
    rail (255,187,104), fence (255,230,164), rafters yellow-ochre — while the
    bed (198,123,69) and bench (192,118,64) agree with each other and with
    neither. **not bite-sized** — retexture onto one family —
    `BACKLOG-VISUAL-BUILD-KIT-WOOD-FAMILY`
100. **Severe texture moiré on the build kit.** The floor slab in
     `build_pieces_corner.png` dissolves into a regular dashed dot-field; the
     wall's V-brace and rails shimmer. Missing mipmaps or a grain texture far
     above the texel density. Called "the most visible defect in the set."
     **bite-sized** — `BACKLOG-VISUAL-BUILD-KIT-MOIRE`
101. **The roof is single-sided** — only one slope carries tiles; the other
     shows dark unfinished planking, which is what a player standing inside a
     built house sees as their ceiling (`build_pieces_lineup.png`,
     `build_pieces_corner.png`). **not bite-sized** —
     `BACKLOG-VISUAL-ROOF-SECOND-SLOPE`
102. **Roof tile is a hot fluorescent orange with no counterpart on the key-art
     palette strip** — the loudest object in the set, and louder than the
     reserved danger colour. **bite-sized** —
     `BACKLOG-VISUAL-ROOF-TILE-TINT`
103. **The wall's plaster panel is a separate offset card** — a pale sliver
     protrudes past the timber frame along the top-right and the whole right
     edge, with the frame casting onto the panel behind it
     (`build_pieces_lineup.png`). **bite-sized** —
     `BACKLOG-VISUAL-WALL-PLASTER-OFFSET`
104. **UV atlas bleed** — green fringe pixels along the roof ridge and at the
     right-hand tile end (`build_pieces_corner.png`). **bite-sized** —
     `BACKLOG-VISUAL-ROOF-UV-BLEED`
105. **The floor slab has zero thickness** — its near edge is a literal 2D plane
     (`build_pieces_corner.png`), so every floor-to-wall junction in a built
     camp shows a paper seam. **bite-sized** —
     `BACKLOG-VISUAL-FLOOR-SLAB-THICKNESS`
106. **The assembled corner does not assemble** — visible void between the left
     rafter and the top plate, the beam's left end overhanging with a sawn face
     exposed, the floor slab passing through the door and the wall's V-brace,
     and the fence post planted through the slab (`build_pieces_corner.png`).
     Capture-rig transform errors, not modelling errors. **bite-sized** —
     `BACKLOG-VISUAL-BUILD-CORNER-ASSEMBLY`
107. **The kit has no joint language** — no peg, notch, bracket or socket
     communicates how any piece meets any other. **not bite-sized** —
     `BACKLOG-VISUAL-BUILD-KIT-JOINERY`
108. **The bedding is a different rendering language from the wood** — the
     turquoise duvet is one smooth gradient with a single specular smear, no
     fold geometry, no seam; the sheet is flat (255,255,255); the pillow is a
     folded card; the duvet's overhang is a flat card with a hard straight
     bottom edge (`creature_bed_alone.png`). **not bite-sized** —
     `BACKLOG-VISUAL-BED-CLOTH`
109. **The duvet is pool-cyan (133,213,216)**, off the key-art strip.
     **bite-sized** — `BACKLOG-VISUAL-DUVET-TINT`
110. **The bed's iron studs are painted-on** — flat grey circles with one
     lighter dot, no bevel, no cast shadow, no seating recess. **bite-sized** —
     `BACKLOG-VISUAL-BED-STUDS`
111. **The carved skirt bottoms read as splintered damage** at small size
     (`creature_bed_alone.png`, `creature_bed_scale_check.png`). **needs owner
     decision** — the carving is presumably deliberate —
     `BACKLOG-VISUAL-BED-SKIRT-PROFILE`
112. **The bench's iron end-straps are ~30 cm wide on a ~1.6 m bench** — the
     second-largest shape on the object (`creature_bed_scale_check.png`).
     **bite-sized** — `BACKLOG-VISUAL-BENCH-STRAP-SCALE`
113. **The creature does not fit its own bed.** The rope ring in
     `06-creature-resting.png` is ~1.15× the badger's body length, with
     hindquarters and rear paws outside it and front paws on the rim. **This is
     `BACKLOG-BED-SCALE-POSE`'s own subject, and it is still failing after that
     lane's change.** **bite-sized** — `BACKLOG-VISUAL-BED-FITS-CREATURE`
114. **Two beds, two design languages** — the plank bed in
     `creature_bed_alone.png` is unmistakably a human bed (pillow, sheet,
     duvet, headboard, ~2 m); the rest mat in `06-creature-resting.png` is a
     rope pet basket. **needs owner decision** —
     `BACKLOG-VISUAL-BED-LANGUAGE-CHOICE`
115. **`creature_bed_scale_check.png` does not perform its own check** — no
     1.80 m figure in frame, the two objects at different depths so their
     apparent sizes are perspective-dependent, and the creature that sleeps in
     the bed is in a different frame entirely. **bite-sized** — capture-tool fix
     — `BACKLOG-VISUAL-BED-SCALE-RIG`
116. **The two bed-rest frames disagree about the light.**
     `06-creature-resting.png` has an almost head-on key and essentially no
     contact shadow; `07-creature-resting-far-side.png` throws a long dense
     grounded shadow. Same asset, same stage — so the pair cannot be used as an
     A/B of anything. **bite-sized** — capture-tool fix —
     `BACKLOG-VISUAL-BED-REST-LIGHT-RIG`
117. **`07-creature-resting-far-side.png` crushes the creature to (0,0,0)** —
     1.4 % of the frame is pure black, and the rear silhouette carries no
     recoverable form. **bite-sized (exposure)** —
     `BACKLOG-VISUAL-BED-REST-EXPOSURE`
118. **The badger's rear has nothing to read.** No tail, no spine ridge, no rear
     pattern break (`07-creature-resting-far-side.png`) — the same asset gap
     defect 60 names from a different rig. **needs owner-supplied reference
     art** — `BACKLOG-VISUAL-BURROWBACK-REAR`
119. **The rest mat's woven interior is a muddy low-res blur** at visibly lower
     texel density than the rope ring around it or the creature on it.
     **bite-sized** — `BACKLOG-VISUAL-REST-MAT-TEXEL-DENSITY`
120. **Visible tiling seam on the bench top** where the plank surface meets the
     metal end strap, plus a fixed-interval dash repeat
     (`creature_bed_scale_check.png`). **bite-sized** —
     `BACKLOG-VISUAL-BENCH-TOP-TILING`

### Area 4 — combat (and the only live-HUD evidence in this census)

These come from `tools/survey_combat.gd`'s five wild-encounter frames, shot
through the game's own combat camera with the HUD on. The camera is therefore
itself under judgement, and defects 126–133 are the census's **only** real
evidence for subject area 7.

121. **The opponent is not in the frame.** `02-arena-opens.png` and
     `03-closing-in.png` both display a `LEVEL 2 / Bramblebun / GROUND` boss
     nameplate with a full health bar while Bramblebun is nowhere in the
     picture — the critic searched both at full size and found only a floating
     ground chevron over empty grass. A boss bar with no boss on screen is the
     single loudest defect in the census. **bite-sized** — encounter placement
     or camera framing — `BACKLOG-VISUAL-COMBAT-ENEMY-OFFSCREEN`
122. **The combat camera frames the wrong subject in all five frames.** The
     ally's back and rump fill the lower-left quadrant of `02`, `03` and `04`;
     in `05-quick-attack-lands-offaxis.png` the ally is cropped to shell and
     one leg in the corner while the action sits small in the middle distance;
     in `01-approach.png` the ally's skull occupies bottom-centre and is cropped
     by the frame edge. It never gets both combatants into one readable
     composition. **bite-sized** — camera height, distance and look target —
     `BACKLOG-VISUAL-COMBAT-CAMERA-FRAMING`
123. **The two combatants are 4–6× apart in linear size, in the ally's
     favour.** Measured against the 1.80 m trainer: Terrapup ≈1.25 m at the
     shoulder and ≈2.5 m long; Bramblebun ≈0.30–0.35 m. In both Palworld fight
     references the opponent is the largest thing in frame. **bite-sized** for
     the scale values (and it is the same underlying fault as defects 59, 64);
     the colourway half is a design call — `BACKLOG-VISUAL-COMBAT-SIZE-RATIO`
124. **Bramblebun is the same straw colour as the dry grass tufts around it**,
     so even when it is in frame it is not separable from ground scatter.
     **needs owner decision** — a high-contrast colourway is a design choice,
     and the mesh itself is already blocked (defect 59) —
     `BACKLOG-VISUAL-BRAMBLEBUN-FIELD-SEPARATION`
125. **There is not one combat VFX in the set.** No hit spark, impact ring,
     dust, damage number, flinch, motion trail or ground telegraph decal — in a
     frame whose own filename says an attack landed. **not bite-sized** — this
     is a whole missing art package and the critic ranked it the second-largest
     gap — `BACKLOG-VISUAL-COMBAT-VFX-LIBRARY`
126. **Nobody in any frame is exerting force.** The trainer is in a neutral
     standing idle in `02`, `03` and `05`, looking off to the right while the
     HUD says "it's open — hit it"; the Terrapup has no attack pose.
     **not bite-sized** — wind-up, attack, flinch and recoil animation —
     `BACKLOG-VISUAL-COMBAT-ANIMATION`
127. **The hostile health bar is the same green as the ally bars**, so nothing
     in the frame is colour-coded as a threat. **bite-sized** — a HUD colour,
     and not the reserved oxblood — `BACKLOG-VISUAL-HOSTILE-BAR-COLOUR`
128. **The boss nameplate is a large opaque slab dead-centre top**, occluding
     exactly the band where the arena's far edge and the terrain behind the
     fight would establish the encounter; both references use a thin strip
     about a fifth the height. **bite-sized** —
     `BACKLOG-VISUAL-BOSS-NAMEPLATE-SIZE`
129. **Keyboard and mouse glyphs in a controller-first project.**
     `01-approach.png` prompts `E  Engage Bramblebun`; `02`–`05` show `F`, `C`
     and mouse-button icons on the ability tray. `CLAUDE.md`'s hard rules say
     controller first, so this is a rule violation visible in a still, not just
     a polish item. **bite-sized** — `BACKLOG-VISUAL-CONTROLLER-GLYPHS`
130. **The telegraph is prose in a box.** "it's open — hit it" and
     "! incoming — move" carry information the animation and the ground decal
     do not; neither reference uses a word of prose for a wind-up. **not
     bite-sized** — it depends on 125 and 126 — `BACKLOG-VISUAL-TELEGRAPH-LANGUAGE`
131. **The arena decal reads as UI, not world.** A flat unlit mint gradient
     band with hard edges that passes through the fence posts without
     conforming to them (`03-closing-in.png`), clips off at a hard diagonal at
     the frame edge (`05`), and whose near edge is off-frame in `02` and `03`
     so the arena's shape cannot be read at all. Its hue is close enough to the
     grass to be simultaneously intrusive and uninformative. **bite-sized** —
     `BACKLOG-VISUAL-ARENA-DECAL`
132. **The target chevron floats over nothing.** `02-arena-opens.png` (≈355,
     310) over empty grass; `04` hovering well above the tuft it marks; worst
     in `05`, where it sits at the far-left edge while the action is
     centre-frame. **bite-sized** — anchor it to the target —
     `BACKLOG-VISUAL-TARGET-CHEVRON-ANCHOR`
133. **Unidentified placeholder geometry in the open world** — a dark grey box
     at approximately (730, 240) beyond the fence in
     `05-quick-attack-lands-offaxis.png`, plus a small pale dome at (620, 240).
     **bite-sized** — `BACKLOG-VISUAL-COMBAT-STRAY-GEOMETRY`
134. **The five frames of one continuous fight are lit two different ways.**
     `01-approach.png` has warm dusk light, structured cloud, a lit and shaded
     hill face and real ridge haze; `02`–`05` have a flat blown-out grey-white
     sky, no directional light and no haze. Same fence, same hill. This is the
     defect the contact sheet exists to catch, and it also proves the build can
     produce the good version. **bite-sized** — clock/weather pinning in the
     capture, or a real time-of-day inconsistency — `BACKLOG-VISUAL-COMBAT-LIGHT-CONSISTENCY`
135. **The grass render-distance ring is visible in three of five frames** —
     a hard horizontal line at y≈300 in `01-approach.png`, beyond the fence in
     `05`, and in `04-enemy-winds-up-offaxis.png` the ground around the houses
     carries no grass cards at all while the foreground is fully dense. Third
     independent sighting of defect 46. **needs owner decision** — same
     performance call — `BACKLOG-VISUAL-SCATTER-CULL-RING`
136. **Tiling rock texture on the cliffs**, with a visible ~1 m grid —
     `03-closing-in.png` top-right, `01-approach.png` right-hand hill,
     `05` top-left. **bite-sized** — `BACKLOG-VISUAL-CLIFF-TEXTURE-TILING`
137. **The fence terminates in mid-air with no end post** in
     `01-approach.png`, and elsewhere runs as one unbroken mechanical arc with
     perfectly uniform spacing, no gate, no gap, no lean and no broken rail.
     **bite-sized** — `BACKLOG-VISUAL-FENCE-RUN-AUTHORING`
138. **The starter creature disappears into the field.** Terrapup's mint shell
     scutes sit within a hair of the grass in both hue and value, so its back
     half merges with the meadow in `02-arena-opens.png` and
     `03-closing-in.png`. Every Pal in `palworld-04` is a colour that does not
     exist in its terrain. **bite-sized** — material hue —
     `BACKLOG-VISUAL-TERRAPUP-FIELD-SEPARATION`
139. **The interact prompt is drawn across the creature's face** in
     `01-approach.png`. **bite-sized** — `BACKLOG-VISUAL-PROMPT-OCCLUSION`
140. **The trainer has no contact shadow at all** in `02-arena-opens.png` and
     `05-quick-attack-lands-offaxis.png` and reads as a cut-out pasted onto the
     grass. Third independent rig to find this (see defects 2 and 29), and the
     first to find it on a character at close range. **bite-sized** after the
     hardware check — `BACKLOG-VISUAL-SHADOW-RANGE`
141. **The trainer is not readable as the protagonist.** At sheet scale he
     collapses to a 5–6 px dark tick indistinguishable from the bush rosettes;
     at full size the hair is a solid blob, the face has no discernible
     features, and the costume carries no accent colour and no
     silhouette-breaking prop. Fourth independent sighting of the
     player-separation problem (see defect 56). **needs owner decision** —
     costume and palette, not a mesh — `BACKLOG-VISUAL-PLAYER-SILHOUETTE-SEPARATION`


### Area 7 — HUD / UI

From `hud_full.png` (the current exploration HUD, carrying this week's
lower-left health bar, `Day 1 · 00:00` tracker and shrunk MAIN STORY card) plus
the three inventory/prompt states the UI suite produced before it was stopped.
The rubric forbids comparing UI design against the Palworld screenshots, so
these are judged on their own terms: legibility, hierarchy, safe area, and
whether a player can read their own state in one look on a handheld.

142. **The FOOD bar is effectively invisible.** Drawn at roughly 15% opacity
     with ochre text on an ochre fill, a fence rail and individual grass blades
     reading straight through it (`hud_full.png`, x 10–210 / y 300–355).
     **Downscaled to 35% it disappears from the frame entirely** — on a 7-inch
     screen the player has no satiety readout. **bite-sized** —
     `BACKLOG-VISUAL-FOOD-BAR-LEGIBILITY`
143. **The health bar is barely more legible.** "100 / 100" is light grey on a
     mid-green fill, and the track is barely darker than the fill, so it reads
     as one green lozenge with a ghost of a number. At 35% it is a green smear.
     **bite-sized** — `BACKLOG-VISUAL-HEALTH-BAR-CONTRAST`
144. **The two vitals are never in the same glance** — health at the extreme
     bottom-left, food 350 px above it in `hud_full.png` and 500 px above it in
     `ui_explore_prompt.png`. **bite-sized** —
     `BACKLOG-VISUAL-VITALS-COLOCATION`
145. **Safe area is violated on every edge.** Measured: health bar 14 px from
     the left and 22 px from the bottom (0.7% / 2.0%), FOOD panel 18 px, minimap
     35 px, footer legend ~24 px. Nothing sits inside a 5% title-safe box and
     several elements are inside 1% — on a handheld with rounded corners these
     are the first things clipped. **bite-sized** —
     `BACKLOG-VISUAL-HUD-SAFE-AREA`
146. **The HUD re-flows with resolution instead of anchoring.** Between
     `hud_full.png` (720p) and `ui_explore_prompt.png` (1080p) the TEAM roster
     panel is present in one and entirely absent in the other, the FOOD bar
     moves to a free-floating mid-left position, and the quickbar grows from
     ~370 px to ~555 px. Neither frame can be trusted as *the* HUD. **bite-sized**
     — `BACKLOG-VISUAL-HUD-ANCHORING`
147. **The interact prompt is missing from the frame named for it.** In
     `ui_explore_prompt.png` the trainer stands beside the intended harvest node
     with no prompt, no glyph, no highlight and no outline anywhere near it.
     **bite-sized** — either a real prompt bug or a capture-timing one, and
     worth telling apart — `BACKLOG-VISUAL-INTERACT-PROMPT-MISSING`
148. **The build speaks five different input languages at once, and the
     controller half is the illegible half.** The exploration HUD shows keycaps
     only (`M` Map, `I` Satchel, `R` Call Out, `C` Change Creature, quickbar
     slots `1`–`5`) with **no gamepad glyph anywhere**; the inventory footer
     uses plain text pairs ("A / Enter Select"); the tooltip uses pictorial
     glyphs including a **mouse-click icon with no controller equivalent**; and
     `ui_inventory_selected.png` adds bracketed ASCII ("J / [L3]"). The two
     pictorial gamepad glyphs do not resolve into recognisable buttons at any
     zoom. Two of these contradict each other on one screen: the quickbar panel
     says "pick a stack up with ▣, then press a slot" while a tooltip 250 px
     away says "J / [L3] Put on the quick bar". `CLAUDE.md` says controller
     first; this is that rule failing in four places at once, and it is the same
     defect the combat round found independently (129). **bite-sized** for
     unifying the language (data/config); **needs owner-supplied reference art**
     only for redrawing the two unreadable glyphs —
     `BACKLOG-VISUAL-INPUT-GLYPH-LANGUAGE`
149. **The modal inventory does not suppress or dim the HUD, and loses to it.**
     The exploration minimap is drawn **on top of** the Satchel panel, with the
     panel's own "Day 1" label printed inside the minimap ring and the player
     triangle showing through the text; the "Settings" tab label is partially
     covered; the MAIN STORY card bleeds through the panel edge. **bite-sized** —
     `BACKLOG-VISUAL-MODAL-HUD-SUPPRESSION`
150. **The inventory footer legend sits outside the panel it belongs to**
     (panel bottom ≈ y 1035, legend baseline ≈ y 1056), floating on the world
     and overlapping the still-live health bar. **bite-sized** —
     `BACKLOG-VISUAL-INVENTORY-FOOTER-PLACEMENT`
151. **Six panel styles, three corner radii, no shared system.** Team rows
     (near-opaque, tight radius, cyan border) / FOOD (~15%, large radius, no
     border) / health (~40%, large radius, thin border) / minimap (near-opaque
     near-black, **hard square corners** around an inset **rounded** ring) /
     MAIN STORY (~70%) / quickbar and action bar (~75%) / Satchel (~92%).
     **bite-sized** — `BACKLOG-VISUAL-PANEL-STYLE-SYSTEM`
152. **The minimap is the heaviest object on screen and carries no map.** Its
     interior is empty — no terrain, no path, no water, no fence, no landmark,
     none of the tree, barn or boulders 30 m away in the same frame. It has four
     symmetric cyan dots that cannot all be POIs, four edge ticks with **no
     N/E/S/W letters** so north is unknowable, a player marker that reads as a
     fir tree rather than a heading arrow, and **a second white triangle cut in
     half by the ring**. It is also the darkest object in the whole build,
     giving the most visual weight to the least information. **bite-sized** —
     `BACKLOG-VISUAL-MINIMAP-CONTENT`
153. **Five item icons in four unrelated idioms, one unidentifiable.** Wood is
     orange line-art rings; stone is a **pink** faceted hexagon that reads as
     fruit; berries are a flat red-pink blob; the flask is a flat cream circle;
     and the Axe is a pale **blue** diamond on a stem that reads as a tuning
     fork or a lollipop — and stays unreadable at 90 px in the preview pane. The
     Axe is also the only cool-coloured icon in the row, which signals "different
     rarity" when it only means "different artist". **needs owner-supplied
     reference art** — small and cheap, but art —
     `BACKLOG-VISUAL-ITEM-ICON-SET`
154. **Stack counts straddle the cell border with no background chip** — "24"
     pushes into the selected cell's cyan outline, and at 35% all four are
     unreadable smudges. A light icon behind one would erase it. **bite-sized** —
     `BACKLOG-VISUAL-STACK-COUNT-CHIP`
155. **The selection state destroys the quickbar-assigned state.** In
     `ui_inventory.png` the Axe carries a green underline; in
     `ui_inventory_selected.png` the Axe takes the cyan selection outline and
     **the green underline vanishes**, so you cannot see whether the item you
     have selected is quickbar-assigned. Neither marker is legended, and at 35%
     the green bar reads as a durability meter. **bite-sized** —
     `BACKLOG-VISUAL-ITEM-STATE-MARKERS`
156. **Four right-anchored HUD elements have four different right edges**
     spanning 23 px (quickbar x≈1863, action bar x≈1855, MAIN STORY x≈1862,
     minimap x≈1878), and the action bar's centre is neither screen-centre nor
     aligned to anything. In `hud_full.png` the world prompt and the action bar
     are centred on axes 270 px apart. **bite-sized** —
     `BACKLOG-VISUAL-HUD-ALIGNMENT`
157. **The clock says `Day 1 · 00:00` — midnight — over a bright midday sky
     with a long low sun shadow** (`hud_full.png`, `ui_explore_prompt.png`).
     The HUD is stating something the frame contradicts. This is very likely the
     same root cause as the owner's own playtest items 9/18/22/23 about the
     day/rest/clock. **bite-sized** — `BACKLOG-VISUAL-CLOCK-VS-SKY`
158. **The empty roster slots are nearly invisible.** "OPEN SLOT" rows 4 and 5
     are drawn at ~25% opacity with grass and a fence reading through the text.
     An empty slot is the five-creature limit made visible and it is the second
     least legible thing on the HUD. **bite-sized** —
     `BACKLOG-VISUAL-OPEN-SLOT-LEGIBILITY`
159. **The KO chip is jammed with ~2 px clearance** between "Lv 1" and the
     health bar, and its bright coral is a **second danger red** that does not
     match the oxblood the key art reserves for Team Tether. **bite-sized** —
     `BACKLOG-VISUAL-KO-CHIP`
160. **The quickbar's count hangs outside its cell.** "x12" is drawn *below*
     slot 1 rather than inside it, so the slot stacks icon / keycap / count as
     three separated elements; cell dividers are near-invisible, so slots 2–5
     read as one long empty box. **bite-sized** —
     `BACKLOG-VISUAL-QUICKBAR-CELL-LAYOUT`
161. **Disabled state reads as a rendering inconsistency.** "Change Creature"
     is disabled but signals it only through ~40% opacity plus a keycap chip
     that changes from white to pale blue-grey. **bite-sized** —
     `BACKLOG-VISUAL-DISABLED-STATE`
162. **The same data is formatted two ways.** The inventory header says
     "Day 1"; the HUD says "Day 1 · 00:00". **bite-sized** —
     `BACKLOG-VISUAL-DATE-FORMAT-CONSISTENCY`
163. **Inventory space allocation does not follow content.** The centre preview
     pane is ~480×650 px, ~93% empty, holding one 90 px icon and one word, while
     the satchel grid is squeezed into six columns and the tab row is justified
     with irregular gaps. **bite-sized** —
     `BACKLOG-VISUAL-INVENTORY-LAYOUT-WEIGHTING`
164. **Durability is plain text where a bar would read faster** ("40/40
     durability"), while the two readouts that *are* bars are the two that are
     illegible. **bite-sized** — `BACKLOG-VISUAL-DURABILITY-READOUT`
165. **A boulder with a right-angled notch and a pure-black unlit face**
     (`ui_explore_prompt.png`, x 1150–1350 / y 150–330) — reads as a failed
     boolean or inverted normals, and the critic called it the most obviously
     broken object in the set. Two metres in front of it, a second rock uses a
     completely different material language. **bite-sized** —
     `BACKLOG-VISUAL-NOTCHED-BOULDER`
166. **The harvest sapling intersects the trainer's arm**
     (`ui_explore_prompt.png`) — geometry through geometry on the hero of the
     frame. **bite-sized** — `BACKLOG-VISUAL-SAPLING-INTERSECTS-PLAYER`
167. **A right-angled terraced step with a flat top in the terrain**
     (`hud_full.png`, x≈900–1100 / y≈250–300) — an unsculpted heightmap edge,
     not a designed ledge. **bite-sized** —
     `BACKLOG-VISUAL-HEIGHTMAP-STEP`
168. **The thing you chop is a 1.93 m leafless twig, and the game calls it an
     oak.** Measured against the trainer at 123 px/m, the harvest node is
     chest-to-head height, while the Wood tooltip says "rough-cut lengths from
     the meadow's oaks" and the Axe tooltip says it "takes a full swing off an
     oak". A scale-and-identity mismatch visible in a still, and the same tree
     asset also stands on the horizon as scenery. **needs owner decision** —
     the fix is either a real oak (blocked on art, defect 22/53) or different
     copy — `BACKLOG-VISUAL-HARVEST-NODE-IS-NOT-AN-OAK`


---

## Totals

| Sizing | Count |
|---|---|
| **bite-sized** | 114 |
| **needs owner decision** | 16 |
| **needs owner-supplied reference art** (blocked per `CLAUDE.md`) | 16 |
| **not bite-sized** (multi-day, no new generation needed) | 22 |
| **total** | **168** |

Counted by each entry's leading classification. Several entries are split — a
bite-sized half and a blocked or multi-day half — and both halves are stated in
the entry; the count follows the leading half only, so the blocked and
multi-day totals are floors, not ceilings.

Six ids appear against more than one numbered defect because separate rigs
found the same underlying fault independently, and that repetition is the
census's strongest signal rather than noise:
`BACKLOG-VISUAL-SHADOW-RANGE` (defects 2, 29, 140 — three rigs),
`BACKLOG-VISUAL-SCATTER-CULL-RING` (46, 135),
`BACKLOG-VISUAL-PLAYER-SILHOUETTE-SEPARATION` (56, 141),
`BACKLOG-VISUAL-TREE-VARIETY` (22, 53),
`BACKLOG-VISUAL-BURROWBACK-REAR` (60, 118) and
`BACKLOG-VISUAL-COMBAT-SIZE-RATIO` (which restates 64's starter-scale fault
from the fight's point of view). The Wave 3 table in
`BACKLOG-FROM-AUDIT-2026-08-31.md` therefore carries fewer distinct ids than
there are bite-sized defects. Both numbered entries are kept in every case,
because independent rediscovery is evidence.

---

## What a follow-up session should do first

Not a plan, just what the evidence supports. Ranked by how many separate
findings one fix would close:

1. **Confirm or refute the shadow finding on real hardware** (defects 2, 29,
   and contributing to 95). Two independent critics called it the highest-
   leverage single change in the build; software rendering is the one place
   that finding is least trustworthy; and it is cheap to check on the Ally.
   Everything else in the lighting group waits on that answer.
2. **The capture-tool fixes** (defects 1, 8, 12, 96, 106, 115, 116) — seven
   defects that are not in the game at all, only in the evidence. Fixing them
   makes every future census cheaper and more trustworthy, and `03-quarry-
   approach-day.png` currently makes one whole site unjudgeable.
3. **The creature scale table** (defects 64, 65, 67, 68, 69) — five defects,
   all transform values, all measured with a ruler in frame, closable in one
   session.
4. **The combat-camera and enemy-framing pair** (defects 121, 122) — a boss
   nameplate displayed for a creature that is not on screen is the loudest
   single thing in the census, and both halves are camera/placement values.
5. **The controller-glyph pass** (defects 129, 148) — the only finding in the
   census that two blind critics reached independently from different rigs, and
   a direct `CLAUDE.md` hard-rule violation ("controller first") rather than a
   matter of taste. The exploration HUD shows **no gamepad glyph at all**.
6. **Close the remaining census gaps** — the trainer/tournament battle, the
   dedicated UI suite (at 1280×720, not 1920×1080), Bands 4–5, water, weather,
   the ground-seam probe, and the J1/J2 Hall silhouette re-measurement. Until
   those run, this catalogue is six-eighths of a census, not a whole one.
